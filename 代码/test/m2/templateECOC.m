function temp =templateECOC (varargin )




















































ifnargin >0 
[varargin {:}]=convertStringsToChars (varargin {:}); 
end

temp =classreg .learning .FitTemplate .make ('ECOC' ,varargin {:}); 
end
