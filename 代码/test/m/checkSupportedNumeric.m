function checkSupportedNumeric(name,x,okInteger,okSparse,okComplex) %#codegen
%   checkSupportedNumeric(NAME,VAL) checks that the input named NAME has a
%   value VAL of a numeric type supported by code in the
%   Statistics and Machine Learning Toolbox
%
%   checkSupportedNumeric(NAME,VAL,TRUE) marks integer values as okay.
%
%   checkSupportedNumeric(NAME,VAL,OKINT,TRUE) marks sparse values as okay.
%
%   checkSupportedNumeric(NAME,VAL,OKINT,OKSPRS,TRUE) marks complex values as okay.

%   Copyright 2016 The MathWorks, Inc.

coder.internal.errorIf(isobject(x),...
    'stats:internal:utils:NoObjectsNamed',name);
coder.internal.errorIf((nargin<5 || ~okComplex) && ~isreal(x),...
    'stats:internal:utils:NoComplexNamed',name);
coder.internal.errorIf((nargin<4 || ~okSparse) && issparse(x),...
    'stats:internal:utils:NoSparseNamed',name);
coder.internal.errorIf((nargin<3 || ~okInteger) && ~isfloat(x),...
    'stats:internal:utils:FloatRequiredNamed',name);
coder.internal.errorIf(nargin>2 && okInteger && ~isnumeric(x),...
    'stats:internal:utils:NumericRequiredNamed',name);

end

