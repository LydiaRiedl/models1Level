function modelPipeline(varargin)

%configureModel(derivRoot,subjectIDs,task,configs)
%   The function creates first level models assuming BIDS folder structure
%   and files were processed with fmriprep. 
%   The function will create a models1Level in the derivatives folder
%   derivRoot in which it will create a folder for each subject (imitating 
%   the bids folder or the fmriprep folder which should already exist under
%   the derivRoot folder. Inside the subject folder it will create a model
%   folder which reflects the configuration given to this folder. The
%   funnction will collect all relevant files into the model
%   folder, including functional data, mask, event files and confound
%   files. It will eventually use SPM to run the 1st level model.
%
%   derivRoot       (string) full path to the derivatives of the study,
%                   must contain an 'fmriprep' fodler in it
%   subjectIDs      (''/string/cell) cell array of subject IDs. If empty,
%                   the script will search for subject and open dialogue
%                   box to select subjects. If a string is provided, it
%                   will be used as a regexp to lookup subject IDs (no
%                   dialogue box).
%   task            (''/string) If empty, a dialogue box will be given to
%                   select which is the desired task to model (based on
%                   available tasks for the provided subjects). If string
%                   is provided, it should match the task field in the bids
%                   structure (corresponding functional and event files).
%   configs         (struct) This is where everything is defined. Below are
%                   the list of fields and their defaults.
%
% For full list of configs, their option and defaults, 
% please see help modelConfigs
%
% version 1.1 3/25/2019
%
% version 1.2 6/18/2019 changes:
% added configs.eventsName to choose files for differet models on same
% dataset. Changes applied to modelPipeline, modelConfigs, assembleFiles.
%

 
Vers = 1.2;

if nargin < 1
    help modelPipeline
    return
end

%% Parse and go to study root folder
derivRoot = varargin{1};
if ~exist(derivRoot,'dir')
    error('First argument should be a valid path to your derivatives folder');
elseif ~exist(fullfile(derivRoot,'fmriprep'),'dir')
    error('There is no fmriprep folder in your derivatives root folder');
end

%% Parse desired subjects
if numel(varargin) > 1
    subjString = varargin{2};
else
    subjString = '';
end

if isempty(subjString)
    pot_subs = findfiles(fullfile(derivRoot,'fmriprep'),'sub-*','-d1D');
    pot_subs = cellfun(@(x) x{end}, regexp(pot_subs,'/','split'),'UniformOutput',0);
    subjects = pot_subs(listdlg('ListString',pot_subs,'SelectionMode','multiple','PromptString','Please select participants','ListSize',[300,300]));
elseif ischar(subjString)
    subjects = findfiles(fullfile(derivRoot,'fmriprep'),subjString,'-d1D');
    subjects = cellfun(@(x) x{end}, regexp(subjects,'/','split'),'UniformOutput',0);
    subjects = subjects(contains(subjects,'sub-'));
elseif iscell(subjString)
    subjects = subjString;
end
if isempty(subjects)
    error('no matching subjects were found');
end

%% Parse task(s)
if numel(varargin) > 2
    task = varargin{3};
else
    task = '';
end

if isempty(task)
    pot_tasks = {};
    for sc = 1:length(subjects)
        runs = findfiles(fullfile(derivRoot,'fmriprep',subjects{sc}),'sub*preproc_bold.nii.gz'); %fmriprep 1.2.x
%        runs = findfiles(fullfile(derivRoot,'fmriprep',subjects{sc},'func'),'sub*preproc.nii.gz'); %fmriprep 1.1.x
        pot_tasks = unique([pot_tasks; cellfun(@(x) x{end}{1}, regexp(runs,'task-(\w+)_','tokens'), 'UniformOutput',0)]);
    end
    task = pot_tasks(listdlg('ListString',pot_tasks,'SelectionMode','single','PromptString','Please select Task','ListSize',[300,300]));
end
if iscell(task)
    task = task{1};
end

% Now take the user configurations and update every config they wanted
if numel(varargin) > 3
    usrConfig = varargin{4};
else
    usrConfig = struct;
end

configs = modelConfigs(usrConfig);
configs.version = Vers;

if ~exist(fullfile(derivRoot,'models1Level'),'dir')
    mkdir(fullfile(derivRoot,'models1Level'));
end

%% create a structured name for the model given configs

if isempty(configs.modelName)
    if configs.noEvents
        conds = 'noEvents';
    elseif ~isempty(configs.eventsName)
        conds = sprintf('%s-events',configs.eventsName);
    elseif ~isempty(configs.collapse)
        conds = matlab.lang.makeValidName(sprintf('%s ',configs.collapse.tocond));
    else
        conds = 'events';
    end
    if configs.smooth
        smoothing = sprintf('_smooth-%G',configs.smooth);
    else
        smoothing = '';
    end
    modelName = sprintf('task-%s_conditions-%s_space-%s%s',task,conds,configs.space,smoothing);
else
    modelName = configs.modelName;
end

spm_jobman('initcfg');
spm('FnUIsetup');

%% Arrange processing by subject and task and perform one at a time
for sc = 1:length(subjects)
    subConfigs = configs;
    runs = findfiles(fullfile(derivRoot,'fmriprep',subjects{sc}),...
        sprintf('sub*_task-%s_*preproc_bold.nii.gz',task));
    if ~numel(runs)
        fprintf('%s has no runs for task %s, skipping\n',subjects{sc},task);
        continue
    end
    subSes = regexp(runs{1},'/derivatives/fmriprep/(sub-\w*(/ses-\w*)?)/func/','tokens');
    subSes = subSes{1}{1};
    if ~exist(fullfile(derivRoot,'models1Level',subSes),'dir')
        mkdir(fullfile(derivRoot,'models1Level',subSes));
    end
    targDir = fullfile(derivRoot,'models1Level',subSes,modelName);
    if exist(fullfile(targDir,'SPM.mat'),'file')
        if strcmpi(subConfigs.overWrite,'archive')
            newModelName = ['archive_' modelName '_' date];
            fprintf('%s: archiving old model\n',subSes);
            system(sprintf('mv -v %s %s',targDir,fullfile(derivRoot,'models1Level',subSes,newModelName)));
        elseif strcmpi(subConfigs.overWrite,'yes')          
            system(sprintf('rm -rv %s',targDir));
            mkdir(targDir);
%         elseif strcmpi(configs.overWrite,'keepSupp')
%             system(sprintf('rm -v %s/*.*',targDir));
%             system(sprintf('rm -v %s/supportFiles/*.mat',targDir));
        else
            fprintf('%s: model exists, skipping subject\n',subSes);
            continue
        end
    else
        mkdir(targDir);
    end
    try 
        subConfigs = assembleFiles(targDir,task,subConfigs);    % configs - space, smooth
        reportModel(targDir,subConfigs);
        createConditionFiles(targDir,subConfigs);  % configs - volumes, collapse, pmods, tmods, noEvents 
        createRegressorFiles(targDir,subConfigs);  % configs - confounds, volumes
        setModelBatchSPM(targDir,subConfigs);      % configs - hpf, volumes
        runModelBatchSPM(targDir,subConfigs);      % configs - saveResiduals
        addContrasts(targDir,subConfigs);          % configs - contrasts
        addToModelReport(targDir,sprintf('modelPipeline completed succesfully %s',datetime));
    catch logError
        addToModelReport(targDir,sprintf('Error in %s: %s',logError.stack(1).name,logError.message));
    end
end

end




