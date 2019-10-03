function fslmerge(dim, outfile, varargin)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This is a wrapper for FSL fslmerge command that concatenates files to a
% single file in the desired dimension
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% dim is the dimension of concatenation. Accepted as 1,2,3,4 or a string
% matching the fsl input options.
% 
% outfile is the output merged file name
%
% varagin stands for all the files to be concatenated. should be strings
% (per file) or a single cell array with all filenames
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if nargin == 0
    help('fslmerge');
    system('fslmerge');
    return
end

dims = {'x', 'y', 'z', 't'}; 
if isnumeric(dim)
    try
        dim = dims{dim};
    catch
        error('if using numerical dimension it should be 1-4')
    end
end

if iscell(varargin{1})
    varargin = varargin{1};
end

infiles = '';
for i = 1:numel(varargin)
    infiles = sprintf('%s %s',infiles,varargin{i});
end
command = sprintf('fslmerge -%s %s %s',dim, outfile, infiles);
system(command);
end