function temp =templateDiscriminant (varargin )









































ifnargin >0 
[varargin {:}]=convertStringsToChars (varargin {:}); 
end

classreg .learning .FitTemplate .catchType (varargin {:}); 
temp =classreg .learning .FitTemplate .make ('Discriminant' ,'type' ,'classification' ,varargin {:}); 
end
