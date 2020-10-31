function s =fitrm (ds ,model ,varargin )

































































internal .stats .checkNotTall (upper (mfilename ),0 ,ds ,model ,varargin {:}); 

ifnargin >1 
model =convertStringsToChars (model ); 
end

ifnargin >2 
[varargin {:}]=convertStringsToChars (varargin {:}); 
end

s =RepeatedMeasuresModel .fit (ds ,model ,varargin {:}); 
