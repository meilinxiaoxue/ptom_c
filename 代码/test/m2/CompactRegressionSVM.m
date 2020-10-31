classdef CompactRegressionSVM <classreg .learning .regr .RegressionModel 



























properties (GetAccess =public ,SetAccess =protected ,Dependent =true )












Alpha ; 

















Beta ; 













Bias ; 









KernelParameters ; 














Mu ; 














Sigma ; 
















SupportVectors ; 
end

methods 
function a =get .Alpha (this )
a =this .Impl .Alpha ; 
end

function a =get .Bias (this )
a =this .Impl .Bias ; 
end

function b =get .Beta (this )
b =this .Impl .Beta ; 
end

function p =get .KernelParameters (this )
p .Function =this .Impl .KernelParameters .Function ; 
p .Scale =this .Impl .KernelParameters .Scale ; 



ifstrcmpi (p .Function ,'polynomial' )
p .Order =this .Impl .KernelParameters .PolyOrder ; 
elseifstrcmpi (p .Function ,'sigmoid' )
p .Sigmoid =this .Impl .KernelParameters .Sigmoid ; 
end
end

function a =get .Mu (this )
a =this .Impl .Mu ; 
end

function a =get .Sigma (this )
a =this .Impl .Sigma ; 
end

function a =get .SupportVectors (this )
a =this .Impl .SupportVectors ; 
end

function this =discardSupportVectors (this )









this .Impl =discardSupportVectors (this .Impl ); 
end

function l =loss (this ,X ,varargin )
































[varargin {:}]=convertStringsToChars (varargin {:}); 

adapter =classreg .learning .internal .makeClassificationModelAdapter (this ,X ,varargin {:}); 
if~isempty (adapter )
l =loss (adapter ,X ,varargin {:}); 
return 
end

[Y ,varargin ]=classreg .learning .internal .inferResponse (this .ResponseName ,X ,varargin {:}); 


N =size (X ,1 ); 
args ={'lossfun' ,'weights' }; 
defs ={@classreg .learning .loss .mse ,ones (N ,1 )}; 
[funloss ,W ,~,extraArgs ]=...
    internal .stats .parseArgs (args ,defs ,varargin {:}); 


[X ,Y ,W ]=prepareDataForLoss (this ,X ,Y ,W ,this .VariableRange ,false ); 


ifstrncmpi (funloss ,'epsiloninsensitive' ,length (funloss ))
f2 =@classreg .learning .loss .epsiloninsensitive ; 
funloss =@(Y ,Yfit ,W )(f2 (Y ,Yfit ,W ,this .Impl .Epsilon )); 
end
funloss =classreg .learning .internal .lossCheck (funloss ,'regression' ); 


Yfit =predict (this ,X ,extraArgs {:}); 


classreg .learning .internal .regrCheck (Y ,Yfit ,W ); 


l =funloss (Y ,Yfit ,W ); 

end
end

methods (Static ,Hidden )
function obj =fromStruct (s )


s .ResponseTransform =s .ResponseTransformFull ; 

s =classreg .learning .coderutils .structToRegr (s ); 


impl =classreg .learning .impl .CompactSVMImpl .fromStruct (s .Impl ); 


obj =classreg .learning .regr .CompactRegressionSVM (...
    s .DataSummary ,s .ResponseTransform ,impl ); 
end
end

methods (Hidden )
function s =toStruct (this )


warnState =warning ('query' ,'all' ); 
warning ('off' ,'MATLAB:structOnObject' ); 
cleanupObj =onCleanup (@()warning (warnState )); 

fh =functions (this .PrivResponseTransform ); 
ifstrcmpi (fh .type ,'anonymous' )
error (message ('stats:classreg:learning:coderutils:classifToStruct:AnonymousFunctionsNotSupported' ,'Response Transform' )); 
end

s =classreg .learning .coderutils .regrToStruct (this ); 


try
classreg .learning .internal .convertScoreTransform (this .PrivResponseTransform ,'handle' ,1 ); 
catch me 
rethrow (me ); 
end

s .ResponseTransformFull =s .ResponseTransform ; 
responsetransformfull =strsplit (s .ResponseTransform ,'.' ); 
responsetransform =responsetransformfull {end}; 
s .ResponseTransform =responsetransform ; 



transFcn =['classreg.learning.transform.' ,s .ResponseTransform ]; 
transFcnCG =['classreg.learning.coder.transform.' ,s .ResponseTransform ]; 
ifisempty (which (transFcn ))||isempty (which (transFcnCG ))
s .CustomResponseTransform =true ; 
else
s .CustomResponseTransform =false ; 
end



s .FromStructFcn ='classreg.learning.regr.CompactRegressionSVM.fromStruct' ; 


impl =this .Impl ; 
ifisa (impl ,'classreg.learning.impl.SVMImpl' )
impl =compact (impl ,true ); 
end
s .Impl =struct (impl ); 
end
end

methods (Access =protected )
function this =CompactRegressionSVM (dataSummary ,responseTransform ,impl )
this =this @classreg .learning .regr .RegressionModel (dataSummary ,responseTransform ); 
this .Impl =impl ; 
this .CategoricalVariableCoding ='dummy' ; 
end

function n =getExpandedPredictorNames (this )
n =classreg .learning .internal .expandPredictorNames (this .PredictorNames ,this .VariableRange ); 
end

function s =propsForDisp (this ,s )
s =propsForDisp @classreg .learning .regr .RegressionModel (this ,s ); 
hasAlpha =~isempty (this .Alpha ); 
if~hasAlpha 
s .Beta =this .Beta ; 
else
s .Alpha =this .Alpha ; 
end

s .Bias =this .Bias ; 
s .KernelParameters =this .KernelParameters ; 
if~isempty (this .Mu )
s .Mu =this .Mu ; 
end
if~isempty (this .Sigma )
s .Sigma =this .Sigma ; 
end
ifhasAlpha 
s .SupportVectors =this .SupportVectors ; 
end

end

function r =response (this ,X ,varargin )

r =score (this .Impl ,X ,false ,varargin {:}); 
end
end

methods (Hidden ,Static )
function name =matlabCodegenRedirect (~)
name ='classreg.learning.coder.regr.CompactRegressionSVM' ; 
end
end


end


