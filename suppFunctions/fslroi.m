function fslroi(infile, outfile, varargin)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This is a wrapper for FSL fslroi which extracts roi out of 4d image 
% and saves it as a new image. It can extract a limited extent in space and
% or time from the original.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% infile is the filename for original image
% 
% outfile is the output file name
%
% varagin is the definitions of extractions in all dimensions. It comes as
% pairs of numbers indexing the starting point and extent. indexing always
% starts at 0 so to extract the 12 timepoints you define 11,1 (start at 11
% and take one image). There shuold be either 2, 6, or 8 numbers following
% the outfile. 
% If 2 than fslroi will treat them as time indexing
% If 6 than they will be treated as x,y,z indexing
% If 8 than they will be treated as x,y,z,t indexing
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if nargin == 0
    help('fslroi');
    system('fslroi');
    return
end

if ~ismember(numel(varargin),[2,6,8])
    help('fslroi');
    error('wrong number of indexes defined');
end

inds = '';
for i = 1:numel(varargin)
    inds = sprintf('%s %i',inds,varargin{i});
end

command = sprintf('fslroi %s %s %s',infile, outfile, inds);
system(command);
end