function result = fslhd(image, xml)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This is a wrapper for FSL fslhd command that reads the header. 
% The fsl command can deal with nii.gz files
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% image is the filename for the image that you want to read the header.

% xml is an option for xml type format of output vs the standard fslhd
% output format. Deafault is non xml.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% results is a struct with all the fields of information
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ~exist('xml','var')
    xml = 0;
end

if xml
    command = sprintf('fslhd -x %s', image);
else
    command = sprintf('fslhd %s', image);
end

[status,output] = system(command);

if status~=0
    result = -1;
    return
end

resultCell = regexp(output,'\n','split')';

if xml
    resultCell = regexp(resultCell,' = ','split');
    for i = 1:length(resultCell)
        if length(resultCell{i}) < 2
            continue
        end
        fname  = resultCell{i}{1}(3:end);
        fname = strrep(fname,' ','_');
        vals = resultCell{i}{2}(2:end-1);
        valn = str2num(vals);
        if ~isempty(valn)
            vals = valn;
        end
        eval(['result.' fname ' = vals;']);
    end
else
    resultCell = regexp(output,'\n','split')';
    fieldNames = cellfun(@(x) x{1}, regexp(resultCell,' ','split'),'UniformOutput',0);
    values = cellfun(@(x) x(2:end), regexp(resultCell,' ','split'),'UniformOutput',0);
    for i = 1:length(fieldNames)
        if isempty(fieldNames{i})
            continue
        end
        fname = strrep(fieldNames{i},':','');
        vals = values{i};
        vals = [vals(cellfun(@(x) ~isempty(x), vals))];
        try
            valn = cellfun(@(x) str2num(x), vals);
            vals = valn;
        end
        if iscell(vals)
            vals = [vals{:}];
        end
        eval(['result.' fname ' = vals;']);
    end
end
    
end