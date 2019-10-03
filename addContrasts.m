function addContrasts(targDir, configs, deleteExistCons)

% function addContrasts(targDir, configs, deleteExistCons)
%
% This function is a part of the modeling package.
%
% This function adds contrasts defined in configs to the model directory in
% targDir. It can be easily used after initial modeling with a configs file
% that includes the contrasts struct array (configs.contrasts). New
% contrasts can be added to existing ones, or existing could be delete by
% setting deleteExistCons to 1. The function will make sure that contrasts
% are either main effects or well balanced.
%
% Required configs fields: contrasts

if nargin < 3
    deleteExistCons = 0;
end

if isempty(configs.contrasts)
    addToModelReport(targDir,'\nno contrasts were requested\n\n\n');
    return
end 

spmFile = findfiles(targDir,'SPM.mat');
spmS = load(spmFile{1});
condNames = {};
if ~isempty(spmS.SPM.Sess(1).U)
    condNames = [spmS.SPM.Sess(1).U.name];
else
    condNames = [spmS.SPM.Sess(1).C.name];
    condNames = condNames(~contains(condNames,'outlier'));
end
condsString = sprintf('%s, ',condNames{:});

if numel(spmS.SPM.xCon)
    addToModelReport(targDir,sprintf(['\nAdding contrasts to model %s,\n',...
        '\tnumber of existing contrasts: %i\n',...
        '\texisting conditions will be delted: %s\n',...
        '\tconditions entering contrast: [%s]\n\n'],...
        datetime, numel(spmS.SPM.xCon),...
        mat2str(logical(deleteExistCons)),condsString(1:end-2)));
else
    addToModelReport(targDir,sprintf(['Creating contrasts for model\n',...
        '\tconditions entering contrast: [%s]\n\n'],condsString(1:end-2)));
end

contrastStruct.spmmat = spmFile;
contrastStruct.delete = deleteExistCons;

for cc = 1:numel(configs.contrasts)
    pvals = ismember(condNames,configs.contrasts(cc).posConds);
    nvals = ismember(condNames,configs.contrasts(cc).negConds);
    if sum(pvals)*sum(nvals) % if true than you only need main effect. no need to adjust
        if sum(pvals) > sum(nvals) % scale down positives
            pvals = pvals*sum(nvals)/sum(pvals);
        elseif sum(nvals) > sum(pvals)  % scale down negatives
            nvals = nvals*sum(pvals)/sum(nvals);
        end
%     else % if included, it will make sure that the main effect is always scaled within run. do i need this?
%         pvals = pvals/sum(pvals);
%         nvals = nvals/sum(nvals);
    end
    c = pvals - nvals; 

    contrastStruct.consess{cc}.tcon.name = configs.contrasts(cc).name;
    contrastStruct.consess{cc}.tcon.weights = c;
    if ~isfield(configs.contrasts,'rep') || isempty(configs.contrasts(cc).rep)
        contrastStruct.consess{cc}.tcon.sessrep = 'repl';
    else       
        contrastStruct.consess{cc}.tcon.sessrep = configs.contrasts(cc).rep;
    end
    addToModelReport(targDir,sprintf('\tcontrast %i: %s\n\t\tcalculated contrast vector: %s\n',...
        cc,configs.contrasts(cc).name,mat2str(c,3)));
end

matlabbatch{1}.spm.stats.con = contrastStruct;
save(fullfile(targDir,'supportFiles','contrastBatch'),'matlabbatch');
spm_jobman('run',matlabbatch);
addToModelReport(targDir,'\ncontrasts estimated succesfully\n\n\n');