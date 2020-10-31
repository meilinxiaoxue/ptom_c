function err (key ,varargin )



msg =classreg .learning .paramoptim .errMsg (key ,varargin {:}); 
throwAsCaller (MException (msg .Identifier ,getString (msg ))); 
end