function out = prepareArgValue(elt)
    
%   Copyright 2016 The MathWorks, Inc.

% Convert character vector logicals to logicals, and categoricals to
% character vectors. Pass
% others through.
if isequal(elt, 'true')
    out = true;
elseif isequal(elt, 'false')
    out = false;
elseif iscategorical(elt)
    out = char(elt);
else
    out = elt;
end
end