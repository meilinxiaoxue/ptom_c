function s = structToClassif(s)

%   Copyright 2016 The MathWorks, Inc.

% Clean up codegen struct to make it compatible with compact classification
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

% class summary
classSummary = s.ClassSummary;

% If class names were cellstr, convert from a char array.
% See classifToStruct for a list of label types.
if classSummary.ClassNamesType == int8(2)
    classSummary.ClassNames = cellstr(classSummary.ClassNames);
    classSummary.ClassNames = ...
        arrayfun( @(x,y) x{1}(1:y), ...
        classSummary.ClassNames, ...
        classSummary.ClassNamesLength, ...
        'UniformOutput',false );
    
    classSummary.NonzeroProbClasses = cellstr(classSummary.NonzeroProbClasses);
    classSummary.NonzeroProbClasses = ...
        arrayfun( @(x,y) x{1}(1:y), ...
        classSummary.NonzeroProbClasses, ...
        classSummary.NonzeroProbClassesLength, ...
        'UniformOutput',false );
end

classSummary.ClassNames = ...
    classreg.learning.internal.ClassLabel(classSummary.ClassNames);
classSummary.NonzeroProbClasses = ...
    classreg.learning.internal.ClassLabel(classSummary.NonzeroProbClasses);

classSummary = rmfield(classSummary,'ClassNamesType');
classSummary = rmfield(classSummary,'ClassNamesLength');
classSummary = rmfield(classSummary,'NonzeroProbClassesLength');

s.ClassSummary = classSummary;

% score transform
s.ScoreTransform = str2func(s.ScoreTransform);

% DefaultLoss
if isfield(s,'DefaultLoss')
    s.DefaultLoss = str2func(s.DefaultLoss);
end

% LabelPredictor
if isfield(s,'LabelPredictor')
    s.LabelPredictor = str2func(s.LabelPredictor);
end

end
