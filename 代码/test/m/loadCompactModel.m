function compactObj = loadCompactModel(filename) %#codegen
%LOADCOMPACTMODEL Constructs a compact model from a structure saved in
% a file created using saveCompactModel. The compact model can be one of:
% classification model, regression model and nearest neighbor searcher.
%
% COMPACTOBJ = LOADCOMPACTMODEL(FILENAME) constructs a compact model from the
% struct stored in the MAT-file, FILENAME.  The compact model can be one of:
% classification model, regression model and nearest neighbor searcher. FILENAME 
% must be a character vector. The MAT-file FILENAME must be created using 
% saveCompactModel. The MAT-file FILENAME is used during code generation to 
% construct a compact  model at compile-time.
%
% See also SAVECOMPACTMODEL

% Copyright 2016-2017 The MathWorks, Inc.

coder.inline('always');
narginchk(1,1);
 
matFile = coder.load(filename);

% classificationStruct accepted for Backwards Compatibility
% compactStruct introduced in 2017a.
isValidMATFile = isfield(matFile,'compactStruct') || isfield(matFile,'classificationStruct'); 
 
coder.internal.errorIf(~isValidMATFile,...
    'stats:classreg:loadCompactModel:UnsupportedStructForCodegen');

if isfield(matFile,'compactStruct')
    compactObj = classreg.coderutils.structToModel(matFile.compactStruct);
else
    compactObj = classreg.coderutils.structToModel(matFile.classificationStruct);
end
