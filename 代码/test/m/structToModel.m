function obj = structToModel(compactStruct) %#codegen
% STRUCTTOMODEL Constructs models from
% codegen compatible structs

% Copyright 2016-2017 The MathWorks, Inc.

coder.inline('always');
narginchk(1,1);
coder.internal.errorIf(~coder.internal.isConst(compactStruct),...
    'stats:classreg:coderutils:structToModel:ExpectedConstStructForCodegen');

% classification structs
validKNNStruct = 'ClassificationKNN.fromStruct';
validCDiscrStruct = 'classreg.learning.classif.CompactClassificationDiscriminant.fromStruct';
validCSVMStruct = 'classreg.learning.classif.CompactClassificationSVM.fromStruct';
validECOCStruct = 'classreg.learning.classif.CompactClassificationECOC.fromStruct';
validCTreeStruct = 'classreg.learning.classif.CompactClassificationTree.fromStruct';
validCLinearStruct = 'ClassificationLinear.fromStruct';
validCEnsembleStruct = 'classreg.learning.classif.CompactClassificationEnsemble.fromStruct';
validCStructs = {validCSVMStruct, validECOCStruct, validCLinearStruct, validCTreeStruct,validCEnsembleStruct,validCDiscrStruct,validKNNStruct};

% regression structs
validRSVMStruct = 'classreg.learning.regr.CompactRegressionSVM.fromStruct';
validGLMStruct = 'classreg.regr.CompactGeneralizedLinearModel.fromStruct';
validLMStruct = 'classreg.regr.CompactLinearModel.fromStruct';
validRTreeStruct = 'classreg.learning.regr.CompactRegressionTree.fromStruct';
validRLinearStruct = 'RegressionLinear.fromStruct';
validREnsembleStruct = 'classreg.learning.regr.CompactRegressionEnsemble.fromStruct';
validRGPStruct = 'classreg.learning.regr.CompactRegressionGP.fromStruct';
validRStructs = {validRSVMStruct,validGLMStruct, validLMStruct,validRLinearStruct,validRTreeStruct,validREnsembleStruct,validRGPStruct};

% searcher structs
validExhaustiveSearcherStruct = 'ExhaustiveSearcher.fromStruct';
validKDTreeSearcherStruct = 'KDTreeSearcher.fromStruct';
validSStructs = {validExhaustiveSearcherStruct,validKDTreeSearcherStruct};
isValidCModel = isfield(compactStruct,'FromStructFcn') && ...
    any(strcmp(compactStruct.FromStructFcn,validCStructs));

isValidRModel = isfield(compactStruct,'FromStructFcn') && ...
    any(strcmp(compactStruct.FromStructFcn,validRStructs));

isValidSModel = isfield(compactStruct,'FromStructFcn') && ...
    any(strcmp(compactStruct.FromStructFcn,validSStructs));


coder.internal.errorIf(~(isValidCModel || isValidRModel || isValidSModel),...
    'stats:classreg:coderutils:structToModel:UnsupportedStructForCodegen');

fromStructFcn = str2func(compactStruct.FromStructFcn);
obj = fromStructFcn(compactStruct);


