function runModelBatchSPM(targDir, configs)
% function runModelBatchSPM(targDir, configs)
%
% This function is a part of the modeling package.
%
% This function executes the model using SPM. It also makes sure that
% residuals are converted into a 4d nifti files if saved.
%
% Required configs fields: hpf, volumes



batchFile = findfiles(fullfile(targDir,'supportFiles'),'modelBatch.mat');
load(batchFile{1});

spm_jobman('run',matlabbatch);
clear matlabbatch;

fGraph = spm_figure('FindWin','Graphics');
desMatFile = fullfile(targDir,'supportFiles','designMatrix.svg');
fGraph.PaperUnits = 'points';
fGraph.FileName = desMatFile;
filemenufcn(fGraph,'FileSave');
% desMatFile = fullfile(targDir,'supportFiles','designMatrix');
% saveas(fGraph,desMatFile,'svg');
addToModelReport(targDir,sprintf('Model configuration successful\n\tDesign Matrix saved as: %s\n\n\n',desMatFile));

spmFile = findfiles(targDir,'SPM.mat');
estimateStruct.spmmat = spmFile;
estimateStruct.write_residuals = configs.saveResiduals;
estimateStruct.method.Classical = 1;
matlabbatch{1}.spm.stats.fmri_est = estimateStruct;
save(fullfile(targDir,'supportFiles','estimateBatch'),'matlabbatch');
spm_jobman('run',matlabbatch);
addToModelReport(targDir,'Model estimated succesfully\n\n\n');

% if residuals were written, merge them to a single 4d nifti file
if configs.saveResiduals
    fprintf('creating residuals files...');
    residFiles = findfiles(targDir,'Res_*.nii');
    load(spmFile{1});
    if isempty(residFiles)
        error('residual files requested but could not be found');
    end
    volCount = 0;
    for rc = 1:numel(SPM.nscan)
        nVol = SPM.nscan(rc);
        runFile = SPM.xY.VY(volCount+1).fname;
        [~, runName] = fileparts(runFile);
        resName = fullfile(targDir,[runName '_residuals.nii']);
        fslmerge(4,resName,residFiles(volCount+1:volCount+nVol));
        volCount = volCount+nVol;
    end
    % make sure that all the residual files were accounted for before
    % deleting them
    if volCount == numel(residFiles)
        for rc = 1:numel(residFiles)
            system(sprintf('rm %s',residFiles{rc}));
        end
    end
    residFiles = findfiles(targDir,'sub-*_residuals.nii.gz');
    gunzip(residFiles);
    for rc = 1:numel(residFiles)
        system(sprintf('rm %s',residFiles{rc}));
    end
    addToModelReport(targDir,'Residual files successfully created:\n');
    addToModelReport(targDir,sprintf('\t%s\n',residFiles{:}));
    addToModelReport(targDir,'\n\n');
    fprintf('done\n');
end
end