classdef CompactRegressionGP <classreg .learning .regr .RegressionModel 
































properties (SetAccess =protected ,GetAccess =public ,Dependent =true )











































KernelFunction ; 











KernelInformation ; 





























BasisFunction ; 






Beta ; 




Sigma ; 

















PredictorLocation ; 

















PredictorScale ; 













Alpha ; 


















ActiveSetVectors ; 














FitMethod ; 














PredictMethod ; 















ActiveSetMethod ; 






ActiveSetSize ; 
end

methods 
function a =get .KernelFunction (this )
a =this .Impl .KernelFunction ; 
end

function a =get .KernelInformation (this )
a =summary (this .Impl .Kernel ); 
end

function a =get .BasisFunction (this )
a =this .Impl .BasisFunction ; 
end

function a =get .Beta (this )
a =this .Impl .BetaHat ; 
end

function a =get .Sigma (this )
a =this .Impl .SigmaHat ; 
end

function a =get .PredictorLocation (this )
a =this .Impl .StdMu ; 
end

function a =get .PredictorScale (this )
a =this .Impl .StdSigma ; 
end

function a =get .Alpha (this )
a =this .Impl .AlphaHat ; 
end

function a =get .ActiveSetVectors (this )
a =this .Impl .ActiveSetX ; 
end

function a =get .FitMethod (this )
a =this .Impl .FitMethod ; 
end

function a =get .PredictMethod (this )
a =this .Impl .PredictMethod ; 
end

function a =get .ActiveSetMethod (this )
a =this .Impl .ActiveSetMethod ; 
end

function a =get .ActiveSetSize (this )
a =this .Impl .ActiveSetSize ; 
end
end

methods (Access =public ,Hidden =true )
function this =CompactRegressionGP (dataSummary ,responseTransform ,compactGPConfig )
this =this @classreg .learning .regr .RegressionModel (dataSummary ,responseTransform ); 
this .Impl =compactGPConfig ; 
this .CategoricalVariableCoding ='dummy' ; 
end
end

methods (Access =protected )
function r =response (~,~,varargin )
r =[]; 
end
function n =getExpandedPredictorNames (this )
n =classreg .learning .internal .expandPredictorNames (this .PredictorNames ,this .VariableRange ); 
end

function s =propsForDisp (this ,s )









s =propsForDisp @classreg .learning .regr .RegressionModel (this ,s ); 


s .KernelFunction =this .KernelFunction ; 
s .KernelInformation =this .KernelInformation ; 
s .BasisFunction =this .BasisFunction ; 
s .Beta =this .Beta ; 
s .Sigma =this .Sigma ; 
s .PredictorLocation =this .PredictorLocation ; 
s .PredictorScale =this .PredictorScale ; 
s .Alpha =this .Alpha ; 
s .ActiveSetVectors =this .ActiveSetVectors ; 
s .PredictMethod =this .PredictMethod ; 
s .ActiveSetSize =this .ActiveSetSize ; 

end
end

methods (Access =public )
function varargout =predict (this ,X ,varargin )



































































adapter =classreg .learning .internal .makeClassificationModelAdapter (this ,X ); 
if~isempty (adapter )
[varargout {1 :nargout }]=predict (adapter ,X ); 
return ; 
end

ifthis .TableInput ||istable (X )
vrange =getvrange (this ); 
X =classreg .learning .internal .table2PredictMatrix (X ,[],[],...
    vrange ,...
    this .CategoricalPredictors ,this .PredictorNames ); 
end
ifany (this .CategoricalPredictors )
if~this .TableInput 
X =classreg .learning .internal .encodeCategorical (X ,this .VariableRange ); 
end
X =classreg .learning .internal .expandCategorical (X ,...
    this .CategoricalPredictors ,this .VariableRange ); 
end
[varargin {:}]=convertStringsToChars (varargin {:}); 

dfltAlpha =0.05 ; 


paramNames ={'Alpha' }; 
paramDflts ={dfltAlpha }; 


[confalpha ]=internal .stats .parseArgs (paramNames ,paramDflts ,varargin {:}); 


[isok ,confalpha ]=this .validateAlpha (confalpha ); 
if~isok 
error (message ('stats:CompactRegressionGP:predict:BadAlpha' )); 
end



import classreg.learning.modelparams.GPParams ; 
if(nargout >1 &&strcmpi (this .Impl .PredictMethod ,GPParams .PredictMethodBCD ))
error (message ('stats:CompactRegressionGP:predict:NoCIForBCD' )); 
end




D =size (this .ActiveSetVectors ,2 ); 
isok =isnumeric (X )&&isreal (X )&&ismatrix (X )&&(size (X ,2 )==D ); 
if~isok 
error (message ('stats:CompactRegressionGP:predict:BadX' ,D )); 
end


[varargout {1 :nargout }]=predict (this .Impl ,X ,confalpha ); 

end
end

methods (Static ,Access =protected )
function [isok ,alpha ]=validateAlpha (alpha )












isok =isnumeric (alpha )&&isreal (alpha )&&isscalar (alpha ); 
isok =isok &&(alpha >=0 &&alpha <=1 ); 

end
end

methods (Static ,Hidden )
function obj =fromStruct (s )


s .ResponseTransform =s .ResponseTransformFull ; 

s =classreg .learning .coderutils .structToRegr (s ); 


impl =classreg .learning .impl .CompactGPImpl .fromStruct (s .Impl ); 


obj =classreg .learning .regr .CompactRegressionGP (...
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


s .FromStructFcn ='classreg.learning.regr.CompactRegressionGP.fromStruct' ; 


s .Impl =toStruct (this .Impl ); 






s .Impl .KernelParams =this .KernelInformation .KernelParameters ; 
end
end
methods (Hidden ,Static )
function name =matlabCodegenRedirect (~)
name ='classreg.learning.coder.regr.CompactRegressionGP' ; 
end
end
end