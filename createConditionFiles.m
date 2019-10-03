function createConditionFiles(targDir, configs)

% function createConditionFiles(targDir, configs)
%
% This function is a part of the modeling package.
%
% The function creates the .mat files to be used for multipleCondition in
% the spm batch system. It manages all the related handling of model
% definitions - conditions, collapsing condition paramteric/time
% modulations. The function also fixes timing in case that the beginning of
% runs have been discraded.
%
% Required configs fields: volumes, collapse, pmods, tmods, noEvents 


%% Find all relevant Files
eventFiles = configs.eventFiles;
nRuns = numel(eventFiles);

%% Start processing runs
for rc = 1:nRuns
    %% Create basic design - conditions and timing
    
    if configs.noEvents
        names = {};
        onsets = {};
        durations = {};
        tmod = {};
        pmod = struct('name',{''},'param',{},'poly',{});
    else
        % read events and confound files (tdfread)
        events = tdfread(eventFiles{rc});
        
        if ~isempty(configs.volumes)
            events.onset = events.onset - configs.TR*(configs.volumes{rc}(1)-1);
        end
        
        % extract unique (possible conditions)
        trialTypes = cellstr(events.trial_type);
        conditions = regexprep(unique(trialTypes), '\s+$', ''); % I think this clears any spaces from the end of condition names
        
        % sanitize condition names
        condnames = conditions;
        for cc = 1:numel(conditions)
            condnames{cc} = matlab.lang.makeValidName(conditions{cc});
        end
        if numel(unique(condnames)) ~= numel(conditions)
            error('Condition names not unique after sanitizing.');
        end
        
        % find rows for each condition
        condrows = struct;
        for cc = 1:numel(conditions)
            condrows.(condnames{cc}) = find(strcmp(trialTypes,conditions{cc})); % find(~cellfun('isempty', regexp(trialTypes, conditions{cc})));
        end
        
        %% Collapse conditions together
        collapse = configs.collapse;    % If collapse is empty it will just continue beyobd this loop
        for cc = 1:numel(collapse)
            
            % select conditions to collapse (from)
            fromconds = find(ismember(conditions,collapse(cc).fromconds));
            % get all the row indices
            rows = [];
            for fcc = numel(fromconds):-1:1
                rows = [rows; condrows.(condnames{fromconds(fcc)})];
                condnames(fromconds(fcc)) = [];
                conditions(fromconds(fcc)) = [];
            end
            
            % store in conditions/condnames (for additional collapsing, etc.)
            conditions{end+1} = collapse(cc).tocond;
            condnames{end+1} = collapse(cc).tocond;
            condrows.(collapse(cc).tocond) = sort(rows);
        end
        
        % convert events struct to names, onsets, durations
        names = condnames;
        onsets = cellfun(@(x) events.onset(condrows.(x)), names,'UniformOutput',0);
        durations = cellfun(@(x) events.duration(condrows.(x)), names,'UniformOutput',0);
        
        if sum(cellfun('isempty', onsets))
            error('some of your collapsed conditions have no onsets');
        end
        
        %% add parametric modulations if required
        pmods = configs.pmods;
        pmod = struct('name',{''},'param',{},'poly',{});
        for cc = 1:numel(pmods)
            condIndex = find(strcmp(conditions,pmods(cc).forcond));
            if isempty(condIndex) % cant find the desired cond
                error('requested parametrically modulated condition %s can not be found',pmods(cc).forcond);
            end
            if ~isfield(events,pmods(cc).valueCol)
                error('requested parametric modulation value column %s can not be found',pmods(cc).valueCol);
            end
            param = events.(pmods(cc).valueCol);
            if ischar(param)
                param = cellfun(@(x) str2double(x), regexprep(cellstr(param),'^w+','NaN')); % check this line w Jochen, might have problem if value is <.num>
            end
            if isempty(pmod)
                pmod(condIndex).name{1} = pmods(cc).name;
            else
                pmod(condIndex).name{end+1} = pmods(cc).name;
            end
            vals = param(condrows.(condnames{condIndex}));
            pmod(condIndex).param{end+1} = vals - nanmean(vals); % remove mean of the modulator
            if isfield(pmods(cc),'poly')
                pmod(condIndex).poly{end+1} = pmods(cc).poly;
            else
                pmod(condIndex).poly{end+1} = 1;
            end
        end
        
        %% add time modulations if reuired
        tmods = configs.tmods;
        tmod = cell(1,numel(names));
        for cc = 1:numel(tmods)
            condIndex = find(strcmp(conditions,tmods(cc).forcond));
            tmod{condIndex} = tmods(cc).val;
        end
    end
    
    condFile{rc} = fullfile(targDir,'supportFiles',sprintf('conditions_run-%02.f',rc));
    save(condFile{rc},'names','onsets','durations','pmod','tmod');
end
addToModelReport(targDir,sprintf('Multiple Condition Files succesfully created\n'));
addToModelReport(targDir,sprintf('\t%s\n',condFile{:}));
addToModelReport(targDir,'\n\n');
end
