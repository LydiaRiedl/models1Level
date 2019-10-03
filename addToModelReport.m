function addToModelReport(targDir,reportLog)

% function addToModelReport(targDir,reportLog)
%
% This function is a part of the modeling package.
%
% This function is a wrapper that adds the formatted string provided in
% reportLog to the report file associated with te model defined by targDir

reportFile = [targDir, '.txt'];

f = fopen(reportFile,'a');

reportLog = strrep(reportLog,targDir,'modelDir');
fprintf(f,reportLog);

fclose(f);
