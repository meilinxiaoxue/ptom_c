classdef CompactClassificationSVM <classreg .learning .classif .ClassificationModel 


































properties (SetAccess =protected ,GetAccess =public ,Dependent =true )












Alpha ; 

















Beta ; 













Bias ; 









KernelParameters ; 














Mu ; 














Sigma ; 
















SupportVectors ; 

















SupportVectorLabels ; 
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

function a =get .SupportVectorLabels (this )
a =this .Impl .SupportVectorLabels ; 
end
end

methods (Static ,Hidden )
function obj =fromStruct (s )



ifisfield (s ,'fitPosterior' )
ifs .fitPosterior 
warning (message ('stats:classreg:loadCompactModel:SVMFitPosteriorReset' )); 
s .ScoreTransform ='classreg.learning.transform.identity' ; 
else
s .ScoreTransform =s .ScoreTransformFull ; 
end
end

s =classreg .learning .coderutils .structToClassif (s ); 


impl =classreg .learning .impl .CompactSVMImpl .fromStruct (s .Impl ); 


obj =classreg .learning .classif .CompactClassificationSVM (...
    s .DataSummary ,s .ClassSummary ,s .ScoreTransform ,s .ScoreType ,impl ); 
end
end

methods (Hidden )
function s =toStruct (this )


warnState =warning ('query' ,'all' ); 
warning ('off' ,'MATLAB:structOnObject' ); 
cleanupObj =onCleanup (@()warning (warnState )); 


fh =functions (this .PrivScoreTransform ); 
fitPosterior =false ; 


ifstrcmpi (fh .type ,'anonymous' )

ifcontains (fh .file ,fullfile ('stats' ,'classreg' ,'fitSVMPosterior.m' ))
fitPosterior =true ; 
tempFcnStr =erase (fh .function ,'@(S)' ); 
fitFunctionName =extractBefore (tempFcnStr ,'(' ); 
fitFunctionArguments =extractBetween (tempFcnStr ,',' ,')' ); 
else
error (message ('stats:classreg:learning:coderutils:classifToStruct:AnonymousFunctionsNotSupported' ,'Score Transform' )); 
end
end


try
classreg .learning .internal .convertScoreTransform (this .PrivScoreTransform ,'handle' ,numel (this .ClassSummary .ClassNames )); 
catch me 
rethrow (me ); 
end


s =classreg .learning .coderutils .classifToStruct (this ); 
s .fitPosterior =fitPosterior ; 

ifs .fitPosterior 
s .ScoreTransformFull =char (fitFunctionName ); 
s .ScoreTransform =char (fitFunctionName ); 
arguments =char (fitFunctionArguments ); 
s .ScoreTransformArguments =arguments ; 
arguments =str2num (arguments ); %#ok<ST2NM>               
s .ScoreTransformArgumentsNum =arguments ; 
s .CustomScoreTransform =false ; 
else
s .ScoreTransformFull =s .ScoreTransform ; 
scoretransformfull =strsplit (s .ScoreTransform ,'.' ); 
scoretransform =scoretransformfull {end}; 
s .ScoreTransform =scoretransform ; 



transFcn =['classreg.learning.transform.' ,s .ScoreTransform ]; 
transFcnCG =['classreg.learning.coder.transform.' ,s .ScoreTransform ]; 
ifisempty (which (transFcn ))||isempty (which (transFcnCG ))
s .CustomScoreTransform =true ; 
else
s .CustomScoreTransform =false ; 
end
s .ScoreTransformArguments ='' ; 
s .ScoreTransformArgumentsNum =[]; 
end


s .FromStructFcn ='classreg.learning.classif.CompactClassificationSVM.fromStruct' ; 


impl =this .Impl ; 
ifisa (impl ,'classreg.learning.impl.SVMImpl' )
impl =compact (impl ,true ); 
end
s .Impl =struct (impl ); 
end
end

methods 
function [varargout ]=predict (this ,X ,varargin )














[varargout {1 :nargout }]=...
    predict @classreg .learning .classif .ClassificationModel (this ,X ,varargin {:}); 
end

function [varargout ]=loss (this ,X ,varargin )







































[varargin {:}]=convertStringsToChars (varargin {:}); 
[varargout {1 :nargout }]=...
    loss @classreg .learning .classif .ClassificationModel (this ,X ,varargin {:}); 
end

function [obj ,trans ]=fitPosterior (obj ,X ,Y )
























































Y =convertStringsToChars (Y ); 

adapter =classreg .learning .internal .makeClassificationModelAdapter (obj ,X ,Y ); 
if~isempty (adapter )
error (message ('MATLAB:bigdata:array:FcnNotSupported' ,'FITPOSTERIOR' ))
end

[obj ,trans ]=fitSVMPosterior (obj ,X ,Y ); 
end

function this =discardSupportVectors (this )








this .Impl =discardSupportVectors (this .Impl ); 
end
end

methods (Access =protected )
function cl =getContinuousLoss (this )
cl =[]; 
ifisequal (this .PrivScoreTransform ,@classreg .learning .transform .identity )
cl =@classreg .learning .loss .hinge ; 
elseifstrcmp (this .ScoreType ,'probability' )
cl =@classreg .learning .loss .quadratic ; 
end
end

function this =CompactClassificationSVM (...
    dataSummary ,classSummary ,scoreTransform ,scoreType ,impl )
this =this @classreg .learning .classif .ClassificationModel (...
    dataSummary ,classSummary ,scoreTransform ,scoreType ); 
this .Impl =impl ; 
this .DefaultLoss =@classreg .learning .loss .classiferror ; 
this .LabelPredictor =@classreg .learning .classif .ClassificationModel .maxScore ; 
this .DefaultScoreType ='inf' ; 
this .CategoricalVariableCoding ='dummy' ; 
end

function S =score (this ,X ,varargin )
ifany (this .CategoricalPredictors )
if~this .TableInput 
X =classreg .learning .internal .encodeCategorical (X ,this .VariableRange ); 
end
X =classreg .learning .internal .expandCategorical (X ,...
    this .CategoricalPredictors ,this .VariableRange ); 
end

f =score (this .Impl ,X ,true ,varargin {:}); 

classnames =this .ClassSummary .ClassNames ; 






S =repmat (-f ,1 ,numel (classnames )); 





[~,loc ]=ismember (this .ClassSummary .NonzeroProbClasses ,classnames ); 
ifnumel (loc )==1 
S (:,loc )=f ; 
else
S (:,loc (2 ))=f ; 
end
end

function s =propsForDisp (this ,s )
s =propsForDisp @classreg .learning .classif .ClassificationModel (this ,s ); 
hasAlpha =~isempty (this .Alpha ); 

if~hasAlpha 
s .Beta =this .Beta ; 
end

ifhasAlpha 
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

ifhasAlpha &&numel (this .ClassSummary .NonzeroProbClasses )>1 
s .SupportVectorLabels =this .SupportVectorLabels ; 
end
end

function n =getExpandedPredictorNames (this )
n =classreg .learning .internal .expandPredictorNames (this .PredictorNames ,this .VariableRange ); 
end
end


methods (Hidden ,Static )
function name =matlabCodegenRedirect (~)
name ='classreg.learning.coder.classif.CompactClassificationSVM' ; 
end
end

end
