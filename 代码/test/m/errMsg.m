function m = errMsg(key, varargin)
    
%   Copyright 2016 The MathWorks, Inc.

tag = ['stats:classreg:learning:paramoptim:paramoptim:' key];
m = message(tag, varargin{:});
end
