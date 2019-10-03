function configs = modelConfigs(usrConfig)

% This function takes a partially defined model configurations and gives
% back a full configs struct populated with defaults where not defined.
% This is also where defautls are set for future changes. The resulting
% configsa can be used for running part of the modeling pipeline by
% generating to configs file that will give you anything that you need.
%
%% Each of the possible configs is given with the default confiuration. In
% general defaults are not the most "reasonable choice" but the most
% minimal choice.

%% Folder configs
% configs.modelName = '';       
%   Manually configure model name. If kept empty, model name will follow
%   default guidelines -
%   task-<taskName>_conditions-<condKey>_space-<space>_smooth-<FWHM> where
%   <taskName> is the task name for analysis
%   <condKey> is either 'events' if conditions are taken directly from
%       events file or name of collapsed conditions if configs.collapse is
%       being used
%   <space> - either MNI or T1w for native space registerd to 
%       prepreocessed anatomical
%   <FWHM> - the fwhm for smoothin kernel. 0 is unsmoothed data
%
% configs.overWrite = '';      % Possible 'yes' or 'archive', 'keepSupp'
%   What to do if model folder exists. If left empty, the subject will be
%   skipped and nothing will happen. If 'yes', the folder will be deleted
%   and things will start from new. If 'archive', the folder will be
%   archived with the name archive_<model-Name>_<archiving date>. If
%   'keepSupp' than all the assembled fileswill remain in supportFiled dir
%   but everything else will be done again. This is recommended if you
%   already unzipped and/or smoothed and don't want to repeat those steps.
%   
%% Input files configs
% configs.space = 'MNI';      % Choose MNI or T1w (native) space
%   If MNI, will search for preprocessed runs in MNI space (MNI default
%   template of fmriprep is MNI152NLin2009cAsym. If T1w, will search for
%   native space preprocessed runs - coregistered to the anatomical
%
% configs.smooth = 0;         
%   FWHM smoothing kernel in mm to use on data before modeling (fmriprep
%   does not smooth). If 0, nothing will occur. If single numeber, and
%   isotropic kernel will be used. If [x y z] a non-isotropic kernel will
%   be used with the values defined by x,y,z
%
% configs.TR = [];             
%   Manually define TR. If left at empty it will extract TR from nifti
%
% configs.volumes = {};       
%   Limit volumes used for model (cell per run). For each run the volumes
%   to include will be an array of volume indexes (starting from 1) e.g.
%   {[10:200],[10:200]} will take the 10th to 200th volumes of the first
%   two runs and toss all preceeding and exceeding volumes. If conditions 
%   are being defined, the timing of events will be adjusted accordingly.
%   The volumes used will be the input for the model, therefore it is 
%   highly not recommended to toss volumes from the middle of the run as
%   that will mess things up with timing and temporal filters etc.
%
%% Design configs
% configs.noEvents = 0;    
%   If 0, run standard model based on events file. If 1, it will ignore all
%   conditions and just include user regressors if defined and  confounds 
%   using SPM model (with hpf)
%
% configs.eventsName = '';
%   If empty, will search for default event files in the fmriprep folder. 
%   If specified, will use as a filter and search the fmriprep folder for a
%   file with standard bids name modified to be _<eventsName>-events.tsv
%
% configs.collapse = {};      
%   Struct for collapsing across conditions. If used, collapse is a struct 
%   array with fields fromconds and tocond. Each index of the array
%   represent a final condition whose name defined in the tocond field. The
%   corresponding fromconds field is a cell array with all the conditions
%   to be collapsed together. If there are conditions in the original
%   events file that are not defined under any of the fromconds, they will
%   not be altered and will be included in the model as is.
%       Example collapse:
%   If I have 5 event types: (1) prompt, (2) reg neg, (3) reg neut, 
%   (4)look neg, (5) look neut. The following configs will create a 
%   design with 3 conditions - (1) prompt, (2) regulate, (3) look 
%       configs.collapse(1).fromconds = {'reg neg','reg neut'};
%       configs.collapse(1).tocond = 'regulate';
%       configs.collapse(2).fromconds = {'look neg','look neut'};
%       configs.collapse(2).tocond = 'look';
%
% configs.pmods = {};         
%   Struct for adding parametric modulations for conditions. If used, pmods
%   is a 1xC struct array where C is the number of conditions that need to 
%   be parametrically modulated. The required fields are name, forcond, 
%   valueCol, poly. Where name is the name of the modulation regressor, 
%   forcond is the name of the modulated condition, valueCol is the name of
%   the column in the event files that hold the parametric modulation 
%   value, and poly is the desired  polinomial expansion (default to 1 if 
%   not specified).
%       Example pmods
%   In my even file there are conditions neg and neut and there's a valence
%   column with a value per stimuli which I want to include as a parametric
%   regressor by the type of image.
%       configs.pmods(1).forcond = 'neg';
%       configs.pmods(1).valueCol = 'valence';
%       configs.pmods(1).name = 'val';
%       configs.pmods(1).poly = 2; % quadratic effect
%       configs.pmods(2).forcond = 'neut';
%       configs.pmods(2).valueCol = 'valence';
%       configs.pmods(2).name = 'val';
%       configs.pmods(2).poly = 1; % linear effect
%
% configs.tmods = {};         
%   Struct for adding timer modultaions for condition. If used tmods is a
%   1xC struct where C is the number of condition that need to be time
%   modulated. The required fields are name, forcond, val. Where forcond 
%   is the name of the modulated condition, and val is the order of time 
%   modulation.
%       Example tmods
%   I have a regualte condition to which I want a first order time
%   modulation.
%       configs.tmods(1).forcond = 'regulate';
%       configs.tmods(1).val = 1;
%
%% user regressors
% configs.userRegs = {};
%   struct for adding user regressors from a regressors tsv file that is
%   not the confound regressors. The struct should specify the search
%   string for the user regressors file and the name(s) of the columns in
%   the tsv file containing the regressors. The regressors will be added
%   after the regular conditions but before the confounds in the model. If
%   you want multiple regressors, make sure that they all exist in the same
%   tsv file
%       Example:
%   This will look for files named sub-*_task-*_run-*_desc-myRegs_regressors
%   and will pick the myReg1 and myReg2 columns from it.
%       configs.userRegs.desc = 'myRegs';
%       configs.userRegs.regNames = {'myReg1','myReg2'};
%
%% confound configs
% configs.confounds = {};     
%   struct for choosing confound regressors to be included in the model.
%   The confounds are based on columns in the confound .tsv file generated
%   by fmriprep. The required fields are name, deriv. Where name is the
%   name (regexp optional) of the column to be included and the deriv is a
%   cell array for defining derivatives or special cases to be included. 
%   In general names will be looked up as column names (or regexp) to
%   choose columns, but some special names are permitted:
%       - 'motion' is a special name for all 6 motion paremeters (3
%       translations and 3 rortation).
%       - 'scrub' is a special name for adding censoring/delta regressors
%       for timepoints that exceed a threshold of FramewiseDisplacement.
%       The threshold is defined in the corresponding deriv field.
%   For full list of possible regressors, look at the column names in you
%   tsv files...
%   The deriv array recognizes 3 types of derivatives - 'd' for first
%   derivative of regressor, 's' for squared regressor and 'ds' for squared
%   of the first derivative regressor. The derivative choice will be
%   applied for all the regressors chosen by the corresponding name field.
%   (e.g. if added to motion than applied to all 6 motion regressors). 
%       Example confounds
%   This will add 24 motion regressors, esitmated framewise displacement 
%   (FD), all the anatomical CompCor regrerssors and delta regressors for 
%   every timepoint where FD > 0.8
%       configs.confounds(1).name = 'motion';
%       configs.confounds(1).deriv = {'d','s','ds'};
%       configs.confounds(2).name = 'framewise_displacement';
%       configs.confounds(2).deriv = {};
%       configs.confounds(3).name = 'a_comp_cor*';
%       configs.confounds(3).deriv = {};
%       configs.confounds(4).name = 'scrub';  
%       configs.confounds(4).deriv = {0.8};
%
% configs.hpf = 128;          
%   High Pass Filter cut off frequency in seconds
%
%% output configs
% configs.saveResiduals = 0;  
%   If 1 it will save residuals after estimating model. The residuals will
%   be saved as 4d nifti file per run. The mean residual that SPM generates
%   will always be saved regardless if you save the full residual
%   timecourse or not.
%
% configs.contrasts = {};     
%   Struct for adding predefined contrasts. If used, contrasts is a struct 
%   array with fields name, posConds, negConds and rep. Each index of the
%   array represents a single contrast to be computer. name is the name of
%   the contrast. posConds are the conditions to be included with positive
%   coefficients. negConds are the conditions to be included with negative 
%   coefficients. posConds and negConds can be strings for single condition
%   name, or cell array for multiple conditions. conditions that are not
%   defined as positive or negative will have a coefficient of 0. The 
%   script will automatically calculate the contrast vector accounting for 
%   number of pos/neg conditions and creating a balanced contrast. In case 
%   of only pos or neg conds, it will assume that you want a main effect 
%   and will not scale or change the conditions. rep is the instruction for
%   how to treat multiple runs. It has the follwoing options:
%     'repl' -  replicate the same coefficitns per run (default)
%     'replsc' - replicate the same coefficitns per run and 
%                 scale by number of runs
%     'sess' - create seperate contrast per run (i.e. each run is
%               treated as a different unit with seperate statistical
%               result) This will create nRuns contrasts
%     'both' - like repl + sess. creates one contrast across all runs and
%               individual run contrast. total of nRuns + 1 contrasts
%     'bothsc' - repl + sess. same as above but the across runs contrast is
%                 scaled by number of runs
%
%       Example contrasts:
%   This will create a single contrast across runs contrasting the 'sles'
%   condition and the 'sble' condition.
%     configs.contrasts(1).name = 'sles_v_sble';
%     configs.contrasts(1).posConds = 'sles';
%     configs.contrasts(1).negConds = 'sble';
%     configs.contrasts(1).rep = 'repl';
%


%% Parse options struct
% Folder configs
configs.modelName = '';     % Manually configure model name. otherwise it uses configs
configs.overWrite = '';      % Possible 'yes' or 'archive'
% Input files configs
configs.space = 'MNI';      % Choose MNI or T1w (native) space
configs.smooth = 0;         % FWHM smoothing kernel to use on data before modeling (fmriprep does not smooth)
configs.TR = [];            % Manually define TR. If left at empty it will attempt to extract from nifti
configs.volumes = {};       % Limit volumes used for model (array per run)
% Design configs
configs.noEvents = 0;       % If 1, it will ignore all conditions in event files (with hpf)
configs.eventsName = '';    % If named will search for special event Names (Can be used instead of collapse, or to create item analysis, etc')
configs.collapse = {};      % Struct for collapsing across conditions
configs.pmods = {};         % Struct for adding parametric modulations for conditions
configs.tmods = {};         % Struct for adding timer modultaions for condition
configs.userRegs = {};      % Struct for adding user regresors
% confound configs
configs.confounds = {};     % List of confounds desired to include in the model form the confound list
configs.hpf = 128;          % High Pass Filter cut off frequency in seconds
%output configs
configs.saveResiduals = 0;  % Save residuals after estimating model
configs.contrasts = {};     % Struct for adding predefined contrasts?


configFields = fieldnames(configs);
for cc = 1:length(configFields)
    if isfield(usrConfig,configFields{cc})
        configs.(configFields{cc}) = usrConfig.(configFields{cc});
        % do we want to check that they are of a correct form?
    end
end
