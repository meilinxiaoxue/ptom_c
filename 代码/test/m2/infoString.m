function s =infoString (key ,varargin )



tag =['stats:classreg:learning:paramoptim:paramoptim:' ,key ]; 
s =message (tag ,varargin {:}).getString ; 
end
