function fslmaths(infile, outfile, matharg)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This is a wrapper for FSL fslmaths function which performs mathematical
% manipulations on 4d images. You need to know how to use fslmaths in order
% to use this wrapper and build the matharg properly
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% infile is the input file name (string) on whih math is performed
% 
% outfile is the output file resulting
%
% matharg is the math operations and inputs to be performed. This follows
% fslmaths definition and should be a single string built to reflect all
% that you want to do to the images. It will be passed to fsl as is and
% will not be parsed and checked
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if nargin == 0
    help('fslmaths');
    system('fslmaths');
    return
end

command = sprintf('fslmaths %s %s %s',infile, matharg, outfile);
system(command);
