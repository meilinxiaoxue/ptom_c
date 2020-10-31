function err(key, varargin)
    
%   Copyright 2016 The MathWorks, Inc.

msg = classreg.learning.paramoptim.errMsg(key, varargin{:});
throwAsCaller(MException(msg.Identifier, getString(msg)));
end