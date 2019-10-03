function createRegressorFiles(targDir, configs)

% function createRegressorFiles(targDir, configs)
%
% This function is a part of the modeling package.
%
% This function creates the .mat files to be used for multipleRegressors in
% the spm batch system. It manages all the related handling derivatives of
% confound regressors provided by the fmriprep output files. It can also
% create delta regressors based on framewise displacement thresholds.
%
% Required configs fields: confounds, volumes



%% Find all relevant Files
confFiles = configs.confFiles;
nRuns = numel(confFiles);
if ~isempty(configs.userRegs)
    regFiles = configs.regFiles;
end

%% Start processing runs
for rc = 1:nRuns
    regNames = {};
    R = [];
    if ~isempty(configs.userRegs)
        usrRegs = tdfread(regFiles{rc});
        for cc = 1:numel(configs.userRegs.regNames)
            R = [R usrRegs.(configs.userRegs.regNames{cc})];
            regNames = [regNames, configs.userRegs.regNames{cc}];
        end
        if ~isempty(configs.volumes)
            R = R(configs.volumes{rc},:);
        end
    end
    confounds = tdfread(confFiles{rc});
    confnames = fieldnames(confounds);
    % read the confound files and convert columns that were string (which
    % happens if the first element is a string and they use n/a for nan).
    % also eliminate nans??
    for cc = 1:numel(confnames)
        if ischar(confounds.(confnames{cc}))
            confounds.(confnames{cc}) = cellfun(@(x) str2double(x),...
                regexprep(cellstr(confounds.(confnames{cc})),'^w+','NaN'));
        end
        if isequal(find(isnan(confounds.(confnames{cc}))),1)
            % if it starts with nan by definition, make it the mean of the
            % regressor (least biased value) so that it doesnt crash.
            confounds.(confnames{cc})(1) = nanmean(confounds.(confnames{cc}));
        end
        if ~isempty(configs.volumes)
            confounds.(confnames{cc}) = confounds.(confnames{cc})(configs.volumes{rc});
        end
    end
    
    % now start creating the matrix and names according to all the
    % requested confounds from the configs.confounds struct
    confStruct = configs.confounds;
    for cc = 1:numel(confStruct)
        if strcmp(confStruct(cc).name,'motion')
            curNames = {'trans_x','trans_y','trans_z','rot_x','rot_y','rot_z'}; %fmriprep 1.2.x
%            curNames = {'X','Y','Z','RotX','RotY','RotZ'}; % fmriprep 1.1.x
            curR = [confounds.(curNames{1}), confounds.(curNames{2}), confounds.(curNames{3}),...
                confounds.(curNames{4}), confounds.(curNames{5}), confounds.(curNames{6})]; 
        elseif strcmp(confStruct(cc).name,'scrub')
            motOutliers = find(confounds.framewise_displacement > confStruct(cc).deriv{1});
            curNames = {};curR = [];
            for oc = 1:numel(motOutliers)
                curNames = [curNames {sprintf('outlier%02.f',oc)}];
                deltaReg = zeros(size(confounds.framewise_displacement));
                deltaReg(motOutliers(oc)) = 1;
                curR = [curR deltaReg];
            end
        else
            selectedconfs = find(~cellfun('isempty', regexp(confnames, confStruct(cc).name)));
            curNames = confnames(selectedconfs);
            curR = cellfun(@(x) confounds.(x), curNames,'UniformOutput',0);
            curR = cell2mat(curR');
            curNames = reshape(curNames,1,[]); % make sure the names are a horizontal list
        end
        if sum(strcmp(confStruct(cc).deriv ,'d')) % first derivative required
            curDR = [zeros(1, size(curR,2)); diff(curR, 1, 1)];
            DRnames = cellfun(@(x) ['d' x], curNames,'UniformOutput', 0);
        else
            curDR = [];
            DRnames = {};
        end
        if sum(strcmp(confStruct(cc).deriv ,'s')) % squared regressor required
            curSR = [curR.*curR];
            SRnames = cellfun(@(x) ['sq' x], curNames,'UniformOutput', 0);
        else
            curSR = [];
            SRnames = {};
        end
        if sum(strcmp(confStruct(cc).deriv ,'ds')) % squared regressor required
            curDSR = [zeros(1, size(curR,2)); diff(curR, 1, 1)];
            curDSR = [curDSR.*curDSR];
            DSRnames = cellfun(@(x) ['sqDiff' x], curNames,'UniformOutput', 0);
        else
            curDSR = [];
            DSRnames = {};
        end
        curR = [curR curDR curSR curDSR];
        curNames = [curNames DRnames SRnames DSRnames];
        R = [R curR];
        regNames = [regNames curNames];
    end
    if ~isempty(R)
        names = regNames;
        regsFile{rc} = fullfile(targDir,'supportFiles',sprintf('regressors_run-%02.f',rc));
        save(regsFile{rc},'names','R');
    end
end
if  ~exist('regsFile','var')
    addToModelReport(targDir,sprintf('No Multiple Regresssion Files requested\n'));
else
    addToModelReport(targDir,sprintf('Multiple Regresssion Files succesfully created\n'));
    addToModelReport(targDir,sprintf('\t%s\n',regsFile{:}));
end
addToModelReport(targDir,'\n\n');

end
