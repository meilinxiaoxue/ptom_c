function [obj ,varargout ]=fitcecoc (X ,Y ,varargin )
































































































































































































































































internal .stats .checkNotTall (upper (mfilename ),0 ,X ,Y ,varargin {:}); 

ifnargin >1 
Y =convertStringsToChars (Y ); 
end

ifnargin >2 
[varargin {:}]=convertStringsToChars (varargin {:}); 
end

[IsOptimizing ,RemainingArgs ]=classreg .learning .paramoptim .parseOptimizationArgs (varargin ); 
ifIsOptimizing 
[obj ,OptimResults ]=classreg .learning .paramoptim .fitoptimizing ('fitcecoc' ,X ,Y ,varargin {:}); 
ifnargout >1 
varargout {1 }=OptimResults ; 
end
else
varargin =RemainingArgs ; 

[learners ,~,~]=internal .stats .parseArgs ({'learners' },{'' },varargin {:}); 

isLinear =false ; 

if~isempty (learners )
if~ischar (learners )...
    &&~isa (learners ,'classreg.learning.FitTemplate' )...
    &&~iscell (learners )
error (message ('stats:classreg:learning:modelparams:ECOCParams:make:BadLearners' )); 
end

ifischar (learners )
learners =classreg .learning .FitTemplate .make (learners ,'type' ,'classification' ); 
end

ifisa (learners ,'classreg.learning.FitTemplate' )
learners ={learners }; 
end

ifiscell (learners )
f =@(x )isa (x ,'classreg.learning.FitTemplate' ); 
isgood =cellfun (f ,learners ); 
if~all (isgood )
error (message ('stats:classreg:learning:modelparams:ECOCParams:make:BadCellArrayLearners' )); 
end
end

f =@(x )x .Method ; 
meth =cellfun (f ,learners ,'UniformOutput' ,false ); 
isLinear =false ; 
ifany (strcmp ('Linear' ,meth ))
isLinear =true ; 
end
ifisLinear &&~all (strcmp ('Linear' ,meth ))
error (message ('stats:fitcecoc:LinearDoesNotMixWithOtherLearners' )); 
end

end

ifisLinear 

internal .stats .checkSupportedNumeric ('X' ,X ,false ,true ); 


[X ,varargin ]=classreg .learning .internal .orientX (X ,false ,varargin {:}); 
ecocArgs =[varargin ,{'ObservationsIn' ,'columns' }]; 
else

[X ,varargin ]=classreg .learning .internal .orientX (X ,true ,varargin {:}); 
ecocArgs =varargin ; 
end

obj =ClassificationECOC .fit (X ,Y ,ecocArgs {:}); 

ifisa (obj ,'ClassificationECOC' )
ifisLinear 
obj =compact (obj ); 
end
end

ifnargout >1 
varargout {1 }=[]; 
end
end
end