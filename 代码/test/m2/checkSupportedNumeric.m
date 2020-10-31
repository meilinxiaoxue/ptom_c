function checkSupportedNumeric (name ,x ,okInteger ,okSparse ,okComplex )%#codegen 












coder .internal .errorIf (isobject (x ),...
    'stats:internal:utils:NoObjectsNamed' ,name ); 
coder .internal .errorIf ((nargin <5 ||~okComplex )&&~isreal (x ),...
    'stats:internal:utils:NoComplexNamed' ,name ); 
coder .internal .errorIf ((nargin <4 ||~okSparse )&&issparse (x ),...
    'stats:internal:utils:NoSparseNamed' ,name ); 
coder .internal .errorIf ((nargin <3 ||~okInteger )&&~isfloat (x ),...
    'stats:internal:utils:FloatRequiredNamed' ,name ); 
coder .internal .errorIf (nargin >2 &&okInteger &&~isnumeric (x ),...
    'stats:internal:utils:NumericRequiredNamed' ,name ); 

end

