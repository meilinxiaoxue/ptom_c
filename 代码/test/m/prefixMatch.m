function tf = prefixMatch(string, target)
    
%   Copyright 2016 The MathWorks, Inc.

if isempty(string)
    tf = false;
elseif ischar(target)
    tf = strncmpi(string, target, numel(string));
else
    tf = any(cellfun(@(t)strncmpi(string, t, numel(string)), target));
end
end
