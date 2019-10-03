function configs = assembleFiles(targDir,task,configs)

% configs = assembleFiles(targDir,task,configs)
%
% This function is a part of the modeling package.
%
% The function assembles all the relevant files (preprocessed runs,
% confound regressors, events, masks) from the fmriprep output folder. It
% copies the files to the support directory of the model and manges first
% processing of those (unzipping and smoothing) if reuired. If TR is not
% defined in configs, the function will read the TR from nifti files and
% update the configs.
%
% Required configs fields: space, smooth


pathParts = regexp(targDir,'/models1Level/','split');
subSes = fileparts(pathParts{2});
derivRoot = pathParts{1};

fmriprepDir = fullfile(derivRoot,'fmriprep',subSes,'func');
supportDir = fullfile(derivRoot,'support4spm',subSes,'func');
if ~exist(supportDir,'dir')
    mkdir(supportDir);
end

subSes = strrep(subSes,'/','_');
%% Find and process run Files (unzip and smooth if needed)
if configs.smooth(1) > 0
    runFiles = findfiles(supportDir,...
        sprintf('%s_*task-%s_run-*_space-%s*desc-%immSmoothed-preproc_bold.nii*',subSes,task,configs.space,configs.smooth(1)));
    if isempty(runFiles)
        smoothF = true;
    else
        configs.runFiles = runFiles;
    end
else
    smoothF = false;
end

if ~isfield(configs,'runFiles')
    runFiles = findfiles(supportDir,...
        sprintf('%s_*task-%s_run-*_space-%s*desc-preproc_bold.nii*',subSes,task,configs.space));
    if isempty(runFiles)
        runFiles = findfiles(fmriprepDir,...
            sprintf('%s_*task-%s_run-*_space-%s*desc-preproc_bold.nii*',subSes,task,configs.space));
    end
    if strcmp(runFiles{1}(end-2:end),'.gz')
        fprintf('unzipping runs to support directory\n');
        gunzip(runFiles,supportDir);
        runFiles = findfiles(supportDir,...
            sprintf('%s_*task-%s_run-*_space-%s*desc-preproc_bold.nii*',subSes,task,configs.space));
    end
    if smoothF
        for rc = 1:numel(runFiles)
            smoothRuns(runFiles{rc},configs.smooth,supportDir);
        end
        runFiles = findfiles(supportDir,...
            sprintf('%s_*task-%s_run-*_space-%s*desc-%immSmoothed-preproc_bold.nii*',subSes,task,configs.space,configs.smooth(1)));
    end
    configs.runFiles = runFiles;
end

nRuns = numel(runFiles);

if ~nRuns
    error('could not find runs for task "%s"\n',task)
end

if isempty(configs.TR)
    configs.TR = fslval(runFiles{1},'pixdim4');
end

%% find and process mask Files
maskFiles = findfiles(supportDir,...
    sprintf('%s_*task-%s_run*_space-%s*desc-brain_mask.nii*',subSes,task,configs.space));
if isempty(maskFiles)
    maskFiles = findfiles(fmriprepDir,...
    sprintf('%s_*task-%s_run*_space-%s*desc-brain_mask.nii*',subSes,task,configs.space));
end
if ~isequal(nRuns, numel(maskFiles))
    error('mismatch in number of runs and mask files for task "%s"\n',task);
end

if strcmp(maskFiles{1}(end-2:end),'.gz')
    fprintf('unzipping masks to support directory\n');
    gunzip(maskFiles,supportDir);
    maskFiles = findfiles(supportDir,...
        sprintf('%s_*task-%s_run*_space-%s*desc-brain_mask.nii*',subSes,task,configs.space));
end
configs.maskFiles = maskFiles;
 
%% find tsv files (confounds, events, user regressors)
confFiles = findfiles(fmriprepDir,...
    sprintf('%s_*task-%s_run*_desc-confounds_regressors.tsv',subSes,task));
if ~isequal(nRuns,numel(confFiles))
    error('mismatch in number of runs and confound files for task "%s"\n',task);
end
configs.confFiles = confFiles;

if ~(configs.noEvents || strcmpi(task,'rest')) 
    if isempty(configs.eventsName)
        eventFiles = findfiles(fmriprepDir,...
            sprintf('%s_task-%s_*_events.tsv',subSes,task)); 
    else
        eventFiles = findfiles(fmriprepDir,...
            sprintf('%s_task-%s_*_%s-events.tsv',subSes,task,configs.eventsName)); 
    end
    if  ~isequal(nRuns,numel(eventFiles))
        error('mismatch in number of runs and event files for task "%s"\n',task);
    end
    configs.eventFiles = eventFiles;
else
    configs.eventFiles = cell(size(configs.runFiles));
end

if ~isempty(configs.userRegs)
    regFiles = findfiles(fmriprepDir,...
        sprintf('%s_*task-%s_run*_desc-%s_regressors.tsv',subSes,task,configs.userRegs.desc));
    if ~isequal(nRuns,numel(regFiles))
        error('user regressors requested but files cant be found');
    end
    configs.regFiles = regFiles;
end

mkdir(fullfile(targDir,'supportFiles'));
save(fullfile(targDir,'supportFiles','configsFile'),'configs');
end
