function out = iscellarray(classNamesType) %#codegen
% ISCELLARRAY Returns true if the input label is a cell array.

% The 'ClassNamesType' property of the object contains an integer value
% that encodes whether the input is cell array or not. When input labels 
% are numeric or logical or char array the value is int8(1). When the input
% label is a cell array the value is int8(2). Categorical labels are not
% supported.

%   Copyright 2016 The MathWorks, Inc.

coder.inline('always');
out = false;
if isequal(classNamesType,int8(2))
    out = true;
end
end