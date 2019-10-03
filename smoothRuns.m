function smoothRuns(targFile,FWHM,targDir)
% This function uses spm function to smooth the functional runs to the
% desired kernel. If FWHM is a single number it will be expanded to [x x x]
% for isotropic kernel.

[origDir, origFile] = fileparts(targFile);
if nargin < 3
    targDir = origDir;
end
    
if numel(FWHM) == 1
    FWHM = [FWHM FWHM FWHM];
end

fprintf('Smoothing functionals...\n');
smoothjob{1}.spm.spatial.smooth = struct(...
    'data', {spm_select('expand',{targFile})},...
    'fwhm', FWHM,...
    'dtype', 0,...
    'im', 0,...
    'prefix', 's');
spm_jobman('run', smoothjob);

newFile = strrep(origFile,'desc-',sprintf('desc-%immSmoothed-',FWHM(1)));

system(sprintf('mv %s/s%s.nii %s/%s.nii',...
    origDir, origFile, targDir, newFile));
end