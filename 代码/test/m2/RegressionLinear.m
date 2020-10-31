classdef RegressionLinear <...
    classreg .learning .regr .RegressionModel &classreg .learning .Linear 
























properties (GetAccess =public ,SetAccess =protected ,Dependent =true )






Epsilon ; 
end

methods 
function e =get .Epsilon (this )
e =this .Impl .Epsilon ; 
end
end


methods (Hidden =true )
function this =RegressionLinear (dataSummary ,responseTransform )

if~isstruct (dataSummary )
error (message ('stats:RegressionLinear:RegressionLinear:DoNotUseConstructor' )); 
end

this =this @classreg .learning .regr .RegressionModel (...
    dataSummary ,responseTransform ); 
this =this @classreg .learning .Linear ; 
end

function cmp =compact (this )
cmp =this ; 
end
end


methods (Access =protected )
function s =propsForDisp (this ,s )
s =propsForDisp @classreg .learning .regr .RegressionModel (this ,s ); 
s =propsForDisp @classreg .learning .Linear (this ,s ); 
s =rmfield (s ,'CategoricalPredictors' ); 
end

function S =response (this ,X ,obsInRows )
S =score (this .Impl ,X ,false ,obsInRows ); 
end
end


methods 
function Yfit =predict (this ,X ,varargin )















[varargin {:}]=convertStringsToChars (varargin {:}); 

adapter =classreg .learning .internal .makeClassificationModelAdapter (this ,X ,varargin {:}); 
if~isempty (adapter )
Yfit =predict (adapter ,X ,varargin {:}); 
return 
end

internal .stats .checkSupportedNumeric ('X' ,X ,false ,true ); 


obsIn =internal .stats .parseArgs ({'observationsin' },{'rows' },varargin {:}); 
obsIn =validatestring (obsIn ,{'rows' ,'columns' },...
    'classreg.learning.internal.orientX' ,'ObservationsIn' ); 
obsInRows =strcmp (obsIn ,'rows' ); 


ifisempty (X )
D =numel (this .PredictorNames ); 
ifobsInRows 
str =getString (message ('stats:classreg:learning:regr:RegressionModel:predictEmptyX:columns' )); 
Dpassed =size (X ,2 ); 
else
Dpassed =size (X ,1 ); 
str =getString (message ('stats:classreg:learning:regr:RegressionModel:predictEmptyX:rows' )); 
end
ifDpassed ~=D 
error (message ('stats:classreg:learning:regr:RegressionModel:predictEmptyX:XSizeMismatch' ,D ,str )); 
end
Yfit =NaN (0 ,1 ); 
return ; 
end


Yfit =this .PrivResponseTransform (response (this ,X ,obsInRows )); 
end

function l =loss (this ,X ,Y ,varargin )
































[varargin {:}]=convertStringsToChars (varargin {:}); 

adapter =classreg .learning .internal .makeClassificationModelAdapter (this ,X ,Y ,varargin {:}); 
if~isempty (adapter )
l =loss (adapter ,X ,Y ,varargin {:}); 
return 
end


internal .stats .checkSupportedNumeric ('X' ,X ,false ,true ); 


obsInRows =classreg .learning .internal .orientation (varargin {:}); 
ifobsInRows 
N =size (X ,1 ); 
else
N =size (X ,2 ); 
end
args ={'lossfun' ,'weights' }; 
defs ={@classreg .learning .loss .mse ,ones (N ,1 )}; 
[funloss ,W ,~,extraArgs ]=...
    internal .stats .parseArgs (args ,defs ,varargin {:}); 


[X ,Y ,W ]=prepareDataForLoss (this ,X ,Y ,W ,this .VariableRange ,false ,obsInRows ); 


ifstrncmpi (funloss ,'epsiloninsensitive' ,length (funloss ))
ifisempty (this .Epsilon )
error (message ('stats:RegressionLinear:loss:UseEpsilonInsensitiveForSVM' )); 
end
funloss =@(Y ,Yfit ,W )classreg .learning .loss .epsiloninsensitive (...
    Y ,Yfit ,W ,this .Epsilon ); 
end
funloss =classreg .learning .internal .lossCheck (funloss ,'regression' ); 


Yfit =predict (this ,X ,extraArgs {:}); 


classreg .learning .internal .regrCheck (Y ,Yfit (:,1 ),W ); 


R =size (Yfit ,2 ); 
l =NaN (1 ,R ); 
forr =1 :R 
l (r )=funloss (Y ,Yfit (:,r ),W ); 
end
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


if~isscalar (this .Lambda )
error (message ('stats:ClassificationLinear:toStruct:NonScalarLambda' )); 
end


s .FromStructFcn ='RegressionLinear.fromStruct' ; 


s .Learner =this .Learner ; 


s .ModelParams =classreg .learning .coderutils .linearParamsToCoderStruct (...
    this .ModelParams ); 


s .Impl =toStruct (this .Impl ); 
end
end

methods (Static ,Hidden )
function temp =template (varargin )
classreg .learning .FitTemplate .catchType (varargin {:}); 
temp =classreg .learning .FitTemplate .make ('Linear' ,...
    'type' ,'regression' ,varargin {:}); 
end

function [varargout ]=fit (X ,Y ,varargin )
temp =RegressionLinear .template (varargin {:}); 
[varargout {1 :nargout }]=fit (temp ,X ,Y ); 
end

function [obj ,fitInfo ]=fitRegressionLinear (...
    X ,Y ,W ,modelParams ,dataSummary ,responseTransform )
obj =RegressionLinear (dataSummary ,responseTransform ); 

modelParams =fillIfNeeded (modelParams ,X ,Y ,W ,dataSummary ,[]); 

lossfun =modelParams .LossFunction ; 

switchlower (lossfun )
case 'epsiloninsensitive' 
obj .Learner ='svm' ; 
case 'mse' 
obj .Learner ='leastsquares' ; 
end

lambda =modelParams .Lambda ; 
ifstrcmp (lambda ,'auto' )
lambda =1 /numel (Y ); 
end

obj .Impl =classreg .learning .impl .LinearImpl .make (0 ,...
    modelParams .InitialBeta ,modelParams .InitialBias ,...
    X ,Y ,W ,lossfun ,...
    strcmp (modelParams .Regularization ,'ridge' ),...
    lambda ,...
    modelParams .PassLimit ,...
    modelParams .BatchLimit ,...
    modelParams .NumCheckConvergence ,...
    modelParams .BatchIndex ,...
    modelParams .BatchSize ,...
    modelParams .Solver ,...
    modelParams .BetaTolerance ,...
    modelParams .GradientTolerance ,...
    modelParams .DeltaGradientTolerance ,...
    modelParams .LearnRate ,...
    modelParams .OptimizeLearnRate ,...
    modelParams .ValidationX ,modelParams .ValidationY ,modelParams .ValidationW ,...
    modelParams .IterationLimit ,...
    modelParams .TruncationPeriod ,...
    modelParams .FitBias ,...
    modelParams .PostFitBias ,...
    modelParams .Epsilon ,...
    modelParams .HessianHistorySize ,...
    modelParams .LineSearch ,...
    0 ,...
    modelParams .Stream ,...
    modelParams .VerbosityLevel ); 

modelParams =toStruct (modelParams ); 

modelParams =rmfield (modelParams ,'ValidationX' ); 
modelParams =rmfield (modelParams ,'ValidationY' ); 
modelParams =rmfield (modelParams ,'ValidationW' ); 

obj .ModelParams =modelParams ; 

fitInfo =obj .Impl .FitInfo ; 
fitInfo .Solver =obj .Impl .Solver ; 
end

function obj =makebeta (beta ,bias ,modelParams ,dataSummary ,fitinfo ,responseTransform )




ifisempty (responseTransform )
responseTransform =@classreg .learning .transform .identity ; 
end

obj =RegressionLinear (dataSummary ,responseTransform ); 

switchlower (modelParams .LossFunction )
case 'epsiloninsensitive' 
obj .Learner ='svm' ; 
case 'mse' 
obj .Learner ='leastsquares' ; 
end

obj .ModelParams =modelParams ; 

obj .Impl =classreg .learning .impl .LinearImpl .makeNoFit (modelParams ,beta (:),bias ,fitinfo ); 

end

function [X ,Y ,W ,dataSummary ,responseTransform ]=prepareData (X ,Y ,varargin )


args ={'responsetransform' }; 
defs ={[]}; 
[transformer ,~,crArgs ]=...
    internal .stats .parseArgs (args ,defs ,varargin {:}); 


[X ,Y ,W ,dataSummary ]=classreg .learning .Linear .prepareDataCR (X ,Y ,crArgs {:}); 


if~isfloat (Y )||~isvector (Y )
error (message ('stats:classreg:learning:regr:FullRegressionModel:prepareData:BadYType' )); 
end
internal .stats .checkSupportedNumeric ('Y' ,Y ,true ); 
Y =Y (:); 


ifany (isnan (Y ))
warning (message ('stats:RegressionLinear:prepareData:YwithMissingValues' )); 
end
[X ,Y ,W ,dataSummary .RowsUsed ]=...
    classreg .learning .regr .FullRegressionModel .removeNaNs (...
    X ,Y ,W ,dataSummary .RowsUsed ,dataSummary .ObservationsInRows ); 


W =W /sum (W ); 


responseTransform =...
    classreg .learning .regr .FullRegressionModel .processResponseTransform (transformer ); 
end

function obj =fromStruct (s )



s .ResponseTransform =s .ResponseTransformFull ; 

s =classreg .learning .coderutils .structToRegr (s ); 


obj =RegressionLinear (s .DataSummary ,s .ResponseTransform ); 


obj .Learner =s .Learner ; 


obj .ModelParams =classreg .learning .coderutils .coderStructToLinearParams (s .ModelParams ); 


obj .Impl =classreg .learning .impl .LinearImpl .fromStruct (s .Impl ); 
end

function name =matlabCodegenRedirect (~)
name ='classreg.learning.coder.regr.RegressionLinear' ; 
end
end

end
