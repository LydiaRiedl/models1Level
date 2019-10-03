function setModelBatchSPM(targDir, configs)

% function setModelBatchSPM(targDir, configs)
%
% This function is a part of the modeling package.
%
% This function sets the spm batch instead of using the gui. At the end it
% saves the SPM.mat file which can then be evaluated.
%
% Required configs fields: saveResiduals

runFiles = configs.runFiles;
maskFiles = configs.maskFiles;
condFiles = findfiles(fullfile(targDir,'supportFiles'),'conditions*.mat');
regsFiles = findfiles(fullfile(targDir,'supportFiles'),'regressors*.mat');

modelStruct.dir = {targDir};

modelStruct.timing.units = 'secs';
modelStruct.timing.RT = configs.TR;
modelStruct.timing.fmri_t = 16; % number of bins per scan when upsampling
modelStruct.timing.fmri_t0 = 8; % reference bin when upsampling
for rc = 1:numel(runFiles)
    modelStruct.sess(rc).scans = spm_select('expand',runFiles(rc));
    modelStruct.sess(rc).multi = condFiles(rc);
    if ~isempty(regsFiles)
        modelStruct.sess(rc).multi_reg = regsFiles(rc);
    end
    modelStruct.sess(rc).hpf = configs.hpf;
    if ~isempty(configs.volumes)
        modelStruct.sess(rc).scans = modelStruct.sess(rc).scans(configs.volumes{rc});
    end
        
end
% modelStruct.fact = struct('name','','levels',[]); % this is to configure an automatic factorial design that will already generate contrasts of interest
modelStruct.bases = struct('hrf',struct('derivs',[0 0])); % this can be changed with base function configs. First flag is time derivative and second is Dispersion derivative
modelStruct.volt = 1; % this can be changed with volterra configs 1 is no volterra, 2 adds interaction
modelStruct.global = 'None'; % the 'scaling' option should not be used so I dont want it to be configurable
modelStruct.mthresh = -Inf; % makes sure that SPM uses the given mask as is
modelStruct.mask = maskFiles(1);
modelStruct.cvi = 'none'; % this will change the auto correation options, options are 'none', 'AR(1)', 'FAST'

matlabbatch{1}.spm.stats.fmri_spec = modelStruct;
batchFile = fullfile(targDir,'supportFiles','modelBatch');
save(batchFile,'matlabbatch');
addToModelReport(targDir,sprintf('SPM batch succesfully defined\n\tModel batch file:%s\n\n\n',batchFile));
end