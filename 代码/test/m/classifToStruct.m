function s = classifToStruct(obj)

%   Copyright 2016-2017 The MathWorks, Inc.

% Convert a compact classification object to a struct for codegen

%
% data summary
%
dataSummary = obj.DataSummary;

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

% if dataSummary.TableInput
%     error('stats:classreg:learning:coderutils:classifToStruct:TableInputNotSupported',...
%         'Tables are not supported for codegen.');
% end

% Without categorical predictors, VariableRange is a cell array
% of [] with one element per predictor
dataSummary = rmfield(dataSummary,'VariableRange');

% Save into the output struct
s.DataSummary = dataSummary;

%
% class summary
%
classSummary = obj.ClassSummary;
classnames = labels(classSummary.ClassNames);
nonzeroclasses = labels(classSummary.NonzeroProbClasses);

if ~strcmp(class(classnames),class(nonzeroclasses))
    error(message('stats:classreg:learning:coderutils:classifToStruct:MismatchedClassTypes'));
end

classnamesType = labelType(classnames);

if     classnamesType == int8(1)
    classnamesLength     = ones(size(classnames,1),1);
    if ischar(classnames)
        nonzeroclassesLength = size(nonzeroclasses,2);
    else
        nonzeroclassesLength = ones(size(nonzeroclasses,1),1);
    end
    
elseif classnamesType == int8(2)
    classnamesLength = cellfun(@length,classnames);
    classnames = char(classnames);
    nonzeroclassesLength = cellfun(@length,nonzeroclasses);
    nonzeroclasses = char(nonzeroclasses);
end

classSummary.ClassNames               = classnames;
classSummary.NonzeroProbClasses       = nonzeroclasses;
classSummary.ClassNamesType           = classnamesType;
classSummary.ClassNamesLength         = classnamesLength;
classSummary.NonzeroProbClassesLength = nonzeroclassesLength;

% Save into the output struct
s.ClassSummary = classSummary;

% PrivScoreTransform is always a function handle
s.ScoreTransform = func2str(obj.PrivScoreTransform);

% PrivScoreType is a char vector or empty
s.ScoreType = obj.PrivScoreType; 

% DefaultLoss is always a function handle
s.DefaultLoss = func2str(obj.DefaultLoss);

% LabelPredictor is always a function handle
s.LabelPredictor = func2str(obj.LabelPredictor);

% DefaultScoreType is a char vector
s.DefaultScoreType = obj.DefaultScoreType;

end


function t = labelType(labels)
if     isnumeric(labels) || islogical(labels) || ischar(labels)
    t = int8(1);
elseif iscellstr(labels)
    t = int8(2);
else % must be a categorical array
    error(message('stats:classreg:learning:coderutils:classifToStruct:CategoricalLabelsNotSupported'));
end
end
