function [varargout ]=fitckernel (X ,Y ,varargin )




























































































































































ifnargin >1 
Y =convertStringsToChars (Y ); 
end

ifnargin >2 
[varargin {:}]=convertStringsToChars (varargin {:}); 
end

[varargout {1 :nargout }]=ClassificationKernel .fit (X ,Y ,varargin {:}); 

end