function s = structToRegr(s)

%   Copyright 2016 The MathWorks, Inc.

% Clean up codegen struct to make it compatible with compact regression
% objects

s = rmfield(s,'FromStructFcn');

% data summary
dataSummary = s.DataSummary;

dataSummary = rmfield(dataSummary,'NumPredictors');

if ischar(dataSummary.PredictorNames)
    dataSummary.PredictorNames = cellstr(dataSummary.PredictorNames)';
    if ~isempty(dataSummary.PredictorNamesLength)
        dataSummary.PredictorNames = ...
            arrayfun( @(x,y) x{1}(1:y), ...
            dataSummary.PredictorNames, ...
            dataSummary.PredictorNamesLength, ...
            'UniformOutput',false );
    end
    D = numel(dataSummary.PredictorNames);
else
    % must be a number
    D = dataSummary.PredictorNames;
end
dataSummary = rmfield(dataSummary,'PredictorNamesLength');

dataSummary.VariableRange = repmat({[]},1,D);

s.DataSummary = dataSummary;

% response transform
s.ResponseTransform = str2func(s.ResponseTransform);

% DefaultLoss
if isfield(s,'DefaultLoss')
    s.DefaultLoss = str2func(s.DefaultLoss);
end

% LabelPredictor
if isfield(s,'LabelPredictor')
    s.LabelPredictor = str2func(s.LabelPredictor);
end

end
