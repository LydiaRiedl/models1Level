function result = fslval(image, val)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This is a wrapper for FSL fslval command that reads a value from the 
% header. The fsl command can deal with nii.gz files
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% image is the filename for the image that you want to read the header.
%
% val is the name of the value you are interested in from the list of
% available values.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% results is a number or string depending on the val specified. In case of
% mistakes, missing or wrong values, result is ''.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if nargin == 0
    help('fslval');
    system('fslval');
    return
end

command = sprintf('fslval %s %s', image, val);


[status,output] = system(command);

if status~=0
    result = '';
    return
end

if ~isempty(str2num(output))
    result = str2num(output);
else
    result = output;
end
