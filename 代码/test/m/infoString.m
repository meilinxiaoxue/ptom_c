function s = infoString(key, varargin)
    
%   Copyright 2016 The MathWorks, Inc.

tag = ['stats:classreg:learning:paramoptim:paramoptim:' key];
s = message(tag, varargin{:}).getString;
end
