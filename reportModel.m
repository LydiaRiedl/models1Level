function reportModel(targDir,configs)

% function reportModel(targDir,configs)
%
% This function is a part of the modeling package.
%
% The function initiates the creation of a report (erases old one if
% existed) and manages the reporting of all the settings and parameters for
% the model. This includes printing all the configs before the modeling
% starts.
%
% Required configs fields: all

targParts = strsplit(targDir,'/');
rFile = fopen([targDir, '.txt'],'w');

derivInd = find(strcmp(targParts,'derivatives'));
derivDir = fullfile('/',targParts{1:derivInd});
fprintf(rFile,'Modeling Report %s\n',datetime);
fprintf(rFile,'subject ID: %s\n', targParts{derivInd + 2});
if strcmp(targParts{derivInd + 3}(1:4),'ses-')
    fprintf(rFile,'session: %s\n', targParts{derivInd + 3});
end 
fprintf(rFile,'Model Name: %s\n', targParts{end});

fprintf(rFile,'\n\nInput Files\n');
fprintf(rFile,'\tmodel Directory: %s\n',strrep(targDir,derivDir,''));
for cc = 1:numel(configs.runFiles)
    fprintf(rFile,'\tRun %i:\n',cc);
    fprintf(rFile,'\t\trun file: %s\n',strrep(configs.runFiles{cc},derivDir,''));
    fprintf(rFile,'\t\tmask file: %s\n',strrep(configs.maskFiles{cc},derivDir,''));
    fprintf(rFile,'\t\tevents file: %s\n',strrep(configs.eventFiles{cc},derivDir,''));
    fprintf(rFile,'\t\tconfounds file: %s\n',strrep(configs.confFiles{cc},derivDir,''));
    if ~isempty(configs.userRegs)
        fprintf(rFile,'\t\t user regressors file: %s\n',strrep(configs.regFiles{cc},derivDir,''));
    end
end

fprintf(rFile,'\n\nConfigurations\n');

fprintf(rFile,'\n--Folder configs--\n');
fprintf(rFile,'\tmodelName: %s\t(Forced non-default name)\n',configs.modelName);
fprintf(rFile,'\toverWrite: %s\t(In case model exists)\n',configs.overWrite);

fprintf(rFile,'\n--Input files configs--\n');
fprintf(rFile,'\tspace: %s\t(native(T1w) or MNI)\n',configs.space);
if numel(configs.smooth) == 3
    fprintf(rFile,'\tsmooth: [%G %G %G]\t(smoothing Kernel FWHM [x y z] mm)\n',configs.smooth);
else
    fprintf(rFile,'\tsmooth: %G\t(smoothing Kernel FWHM mm)\n',configs.smooth);
end
fprintf(rFile,'\tTR: %G\t(seconds)\n',1);
if isempty(configs.volumes)
    fprintf(rFile,'\tvolumes: {}\t(include all volumes)\n');
else
    fprintf(rFile,'\tvolumes:\t(limited volumes per run)\n');
    for cc = 1:numel(configs.volumes)
        fprintf(rFile,'\t\trun %i: %i-%i\n',cc,configs.volumes{cc}(1),configs.volumes{cc}(end));
    end
end

fprintf(rFile,'\n--Design configs--\n');
fprintf(rFile,'\tnoEvents: %i\t(if 1 - ignore conditions in event files)\n',configs.noEvents);
if isempty(configs.collapse)
    fprintf(rFile,'\tcollpase:{}\t(conditions as appear in event files)\n');
else
    fprintf(rFile,'\tcollapse:\t(collapse many conditions to few)\n');
    for cc = 1:numel(configs.collapse)
        fprintf(rFile,'\t\tfrom conditions:');
        fprintf(rFile,'%s, ',configs.collapse(cc).fromconds{:});
        fprintf(rFile,'\t to condition %s\n',configs.collapse(cc).tocond);
    end
end
if isempty(configs.pmods)
    fprintf(rFile,'\tpmods: {}\t(no parametric modulations)\n');
else
    fprintf(rFile,'\tpmods:\t(parametric modulations for conditions)\n');
    for cc = 1:numel(configs.pmods)
        fprintf(rFile,'\t\tfor condition:%s,\tmodulation column:%s,\tmodulator name:%s,\tpolynomial expension:%i\n',...
            configs.pmods(cc).forcond,configs.pmods(cc).valueCol,configs.pmods(cc).name,configs.pmods(cc).poly);
    end
end

if isempty(configs.tmods)
    fprintf(rFile,'\ttmods: {}\t(no time modulations)\n');
else
    fprintf(rFile,'\ttmods:\t(time modulations for conditions)\n');
    for cc = 1:numel(configs.pmods)
        fprintf(rFile,'\t\tfor condition:%s,\tmodulation order:%i\n',...
            configs.tmods(cc).forcond,configs.tmods(cc).val);
    end
end

if isempty(configs.userRegs)
    fprintf(rFile,'\tuserRegs: {}\t(no user regressors requested)\n');
else
    fprintf(rFile,'\tuserRegs:\t(user regressors from file)\n');
    fprintf(rFile,'\t\tdesc: %s\t(regressors file desc field)\n',configs.userRegs.desc);
    fprintf(rFile,'\t\tregressors names:');
    fprintf(rFile,' %s',configs.userRegs.regNames{:});
    fprintf(rFile,'\n');
end
    
fprintf(rFile,'\n--Confounds configs--\n');
fprintf(rFile,'\thpf: %G (high pass frequency cutoff in seconds)\n',configs.hpf);
if isempty(configs.confounds)
    fprintf(rFile,'\tconfounds: {}\t(no additional confounding regressors included)\n');
else
    fprintf(rFile,'\tconfounds:\t(confounding regressors included)\n');
    for cc = 1:numel(configs.confounds)
        if strcmp(configs.confounds(cc).name,'scrub')
            fprintf(rFile,'\t\tscrub: FD threshold = %G (timepoints with Framewise dispacement over th will be regressed out)\n',configs.confounds(cc).deriv{1});
        else
            fprintf(rFile,'\t\t%s regressors',configs.confounds(cc).name);
            if sum(strcmp(configs.confounds(cc).deriv,'d'))
                fprintf(rFile,',\tfirst derivative regs included');
            end
            if sum(strcmp(configs.confounds(cc).deriv,'s'))
                fprintf(rFile,',\tsquared regs included');
            end
            if sum(strcmp(configs.confounds(cc).deriv,'ds'))
                fprintf(rFile,',\tsquared first derivative regs included');
            end
            fprintf(rFile,'\n');
        end
    end
end
            
fprintf(rFile,'\n--Output configs--\n');
fprintf(rFile,'\tsaveResiduals: %i\t(if 1, create 4d file for resisuals of all volumes)\n',configs.saveResiduals);
if isempty(configs.contrasts)
    fprintf(rFile,'\tcontrasts:{}\t(no requested contrasts)\n');
else
    fprintf(rFile,'\tcontrasts:\t(requested contrasts)\n');
    for cc = 1:numel(configs.contrasts)
        fprintf(rFile,'\t\tcontrast %i: %s\n',cc,configs.contrasts(cc).name);
        if ischar(configs.contrasts(cc).posConds)
            fprintf(rFile,'\t\t\tpositive conditions: %s\n',configs.contrasts(cc).posConds);
        else
            fprintf(rFile,'\t\t\tpositive conditions: %s',configs.contrasts(cc).posConds{1});
            fprintf(rFile,', %s',configs.contrasts(cc).posConds{:});
            fprintf(rFile,'\n');
        end
        if ischar(configs.contrasts(cc).negConds)
            fprintf(rFile,'\t\t\tnegative conditions: %s\n',configs.contrasts(cc).negConds);
        else
            fprintf(rFile,'\t\t\tnegative conditions: %s',configs.contrasts(cc).negConds{1});
            fprintf(rFile,', %s',configs.contrasts(cc).negConds{2:end});
            fprintf(rFile,'\n');
        end
        fprintf(rFile,'\t\t\tacross sessions instruction: %s\n',configs.contrasts(cc).rep);
    end
end
fprintf(rFile,'\n\n');
end
    

