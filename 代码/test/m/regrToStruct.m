function s = regrToStruct(obj)

%   Copyright 2016 The MathWorks, Inc.

% Convert a compact regression object to a struct for codegen

%
% data summary
%
dataSummary = obj.DataSummary;
dataSummary.RowsUsed = [];
dataSummary.PredictorNamesLength = [];
if isnumeric(dataSummary.PredictorNames)
    dataSummary.NumPredictors = dataSummary.PredictorNames;
else % must be cellstr
    pnames = dataSummary.PredictorNames;
    dataSummary.NumPredictors = numel(pnames);
    dataSummary.PredictorNamesLength = cellfun(@length,pnames);
    dataSummary.PredictorNames = char(pnames);
end

if ~isempty(dataSummary.CategoricalPredictors)
    error(message('stats:classreg:learning:coderutils:classifToStruct:CategoricalPredictorsNotSupported'));
end

% Without categorical predictors, VariableRange is a cell array
% of [] with one element per predictor
dataSummary = rmfield(dataSummary,'VariableRange');

% Save into the output struct
s.DataSummary = dataSummary;

% PrivResponseTransform is always a function handle
s.ResponseTransform = func2str(obj.PrivResponseTransform);


end

