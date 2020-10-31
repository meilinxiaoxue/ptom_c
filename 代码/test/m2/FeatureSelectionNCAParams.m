classdef FeatureSelectionNCAParams <classreg .learning .internal .DisallowVectorOps 








properties 

Method ; 
FitMethod ; 
NumPartitions ; 
DoFit ; 
Lambda ; 
LengthScale ; 
InitialFeatureWeights ; 
Prior ; 
Standardize ; 
Verbose ; 
Solver ; 


LossFunction ; 
Epsilon ; 


HessianHistorySize ; 
InitialStepSize ; 
LineSearchMethod ; 
MaxLineSearchIterations ; 
GradientTolerance ; 


InitialLearningRate ; 
MiniBatchSize ; 
PassLimit ; 
NumPrint ; 
NumTuningIterations ; 
TuningSubsetSize ; 


IterationLimit ; 
StepTolerance ; 


MiniBatchLBFGSIterations ; 


ComputationMode ; 
GrainSize ; 
CacheSize ; 


NumObservations ; 
NumFeatures ; 
end

properties 

Filled ; 


Version ; 
end


methods 

function this =set .Method (this ,method )
method =this .validateMethod (method ); 
this .Method =method ; 
end

function this =set .FitMethod (this ,fitMethod )
fitMethod =this .validateFitMethod (fitMethod ); 
this .FitMethod =fitMethod ; 
end

function this =set .NumPartitions (this ,numPartitions )
numPartitions =this .validateNumPartitions (numPartitions ); 
this .NumPartitions =numPartitions ; 
end

function this =set .DoFit (this ,dofitting )
dofitting =this .validateDoFit (dofitting ); 
this .DoFit =dofitting ; 
end

function this =set .Lambda (this ,lambda )
lambda =this .validateLambda (lambda ); 
this .Lambda =lambda ; 
end

function this =set .LengthScale (this ,lengthScale )
lengthScale =this .validateLengthScale (lengthScale ); 
this .LengthScale =lengthScale ; 
end

function this =set .InitialFeatureWeights (this ,initialFeatureWeights )
initialFeatureWeights =this .validateInitialFeatureWeights (initialFeatureWeights ); 
this .InitialFeatureWeights =initialFeatureWeights ; 
end

function this =set .Prior (this ,prior )
prior =this .validatePrior (prior ); 
this .Prior =prior ; 
end

function this =set .Standardize (this ,standardize )
standardize =this .validateStandardize (standardize ); 
this .Standardize =standardize ; 
end

function this =set .Verbose (this ,verbose )
verbose =this .validateVerbose (verbose ); 
this .Verbose =verbose ; 
end

function this =set .Solver (this ,solver )
solver =this .validateSolver (solver ); 
this .Solver =solver ; 
end


function this =set .LossFunction (this ,lossFunction )
lossFunction =this .validateLossFunction (lossFunction ); 
this .LossFunction =lossFunction ; 
end

function this =set .Epsilon (this ,epsilon )
epsilon =this .validateEpsilon (epsilon ); 
this .Epsilon =epsilon ; 
end


function this =set .HessianHistorySize (this ,hessianHistorySize )
hessianHistorySize =this .validateHessianHistorySize (hessianHistorySize ); 
this .HessianHistorySize =hessianHistorySize ; 
end

function this =set .InitialStepSize (this ,initialStepSize )
initialStepSize =this .validateInitialStepSize (initialStepSize ); 
this .InitialStepSize =initialStepSize ; 
end

function this =set .LineSearchMethod (this ,lineSearchMethod )
lineSearchMethod =this .validateLineSearchMethod (lineSearchMethod ); 
this .LineSearchMethod =lineSearchMethod ; 
end

function this =set .MaxLineSearchIterations (this ,maxLineSearchIterations )
maxLineSearchIterations =this .validateMaxLineSearchIterations (maxLineSearchIterations ); 
this .MaxLineSearchIterations =maxLineSearchIterations ; 
end

function this =set .GradientTolerance (this ,gradientTolerance )
gradientTolerance =this .validateGradientTolerance (gradientTolerance ); 
this .GradientTolerance =gradientTolerance ; 
end


function this =set .InitialLearningRate (this ,initialLearningRate )
initialLearningRate =this .validateInitialLearningRate (initialLearningRate ); 
this .InitialLearningRate =initialLearningRate ; 
end

function this =set .MiniBatchSize (this ,miniBatchSize )
miniBatchSize =this .validateMiniBatchSize (miniBatchSize ); 
this .MiniBatchSize =miniBatchSize ; 
end

function this =set .PassLimit (this ,passLimit )
passLimit =this .validatePassLimit (passLimit ); 
this .PassLimit =passLimit ; 
end

function this =set .NumPrint (this ,numPrint )
numPrint =this .validateNumPrint (numPrint ); 
this .NumPrint =numPrint ; 
end

function this =set .NumTuningIterations (this ,numTuningIterations )
numTuningIterations =this .validateNumTuningIterations (numTuningIterations ); 
this .NumTuningIterations =numTuningIterations ; 
end

function this =set .TuningSubsetSize (this ,tuningSubsetSize )
tuningSubsetSize =this .validateTuningSubsetSize (tuningSubsetSize ); 
this .TuningSubsetSize =tuningSubsetSize ; 
end


function this =set .IterationLimit (this ,iterationLimit )
iterationLimit =this .validateIterationLimit (iterationLimit ); 
this .IterationLimit =iterationLimit ; 
end

function this =set .StepTolerance (this ,stepTolerance )
stepTolerance =this .validateStepTolerance (stepTolerance ); 
this .StepTolerance =stepTolerance ; 
end


function this =set .MiniBatchLBFGSIterations (this ,miniBatchLBFGSIterations )
miniBatchLBFGSIterations =this .validateMiniBatchLBFGSIterations (miniBatchLBFGSIterations ); 
this .MiniBatchLBFGSIterations =miniBatchLBFGSIterations ; 
end


function this =set .ComputationMode (this ,computationMode )
computationMode =this .validateComputationMode (computationMode ); 
this .ComputationMode =computationMode ; 
end

function this =set .GrainSize (this ,grainSize )
grainSize =this .validateGrainSize (grainSize ); 
this .GrainSize =grainSize ; 
end

function this =set .CacheSize (this ,cacheSize )
cacheSize =this .validateCacheSize (cacheSize ); 
this .CacheSize =cacheSize ; 
end


function this =set .NumObservations (this ,numObservations )
numObservations =this .validateNumObservations (numObservations ); 
this .NumObservations =numObservations ; 
this =this .modifyModelParamsForNumObservations (numObservations ); 
end

function this =set .NumFeatures (this ,numFeatures )
numFeatures =this .validateNumFeatures (numFeatures ); 
this .NumFeatures =numFeatures ; 
end
end


methods 
function this =FeatureSelectionNCAParams (method ,PrivX ,PrivY ,varargin )

this .Filled =false ; 


[N ,P ]=size (PrivX ); 
this .Method =method ; 
this .NumObservations =N ; 
this .NumFeatures =P ; 


this =setupModelParams (this ,PrivX ,PrivY ,varargin {:}); 


this .Version =classreg .learning .fsutils .FeatureSelectionNCAParams .expectedVersion (); 
end
end


methods 
function out =toStruct (this )

warning ('off' ,'MATLAB:structOnObject' ); 
out =struct (this ); 
warning ('on' ,'MATLAB:structOnObject' ); 
out =rmfield (out ,'Filled' ); 
out =rmfield (out ,'Version' ); 
out =rmfield (out ,'ComputationMode' ); 
out =rmfield (out ,'GrainSize' ); 
end
end


methods (Hidden )
function this =modifyModelParamsForNumObservations (this ,numObservations )







ifthis .Filled 
this .MiniBatchSize =min (this .MiniBatchSize ,numObservations ); 
this .TuningSubsetSize =min (this .TuningSubsetSize ,numObservations ); 
this .NumPartitions =max (2 ,min (this .NumPartitions ,numObservations )); 
end
end
end


methods (Hidden )
function this =setupModelParams (this ,PrivX ,PrivY ,varargin )


N =this .NumObservations ; 
P =this .NumFeatures ; 
dfltLambda =1 /N ; 
dfltLengthScale =1 ; 
dfltInitialFeatureWeights =ones (P ,1 ); 
dfltPrior =classreg .learning .fsutils .FeatureSelectionNCAModel .PriorEmpirical ; 
dfltStandardize =false ; 
dfltVerbose =0 ; 
if(N >1000 )
dfltSolver =classreg .learning .fsutils .FeatureSelectionNCAModel .SolverSGD ; 
else
dfltSolver =classreg .learning .fsutils .FeatureSelectionNCAModel .SolverLBFGS ; 
end

dfltHessianHistorySize =15 ; 
dfltInitialStepSize =classreg .learning .fsutils .FeatureSelectionNCAModel .StringAuto ; 
dfltLineSearchMethod =classreg .learning .fsutils .FeatureSelectionNCAModel .LineSearchMethodWeakWolfe ; 
dfltMaxLineSearchIterations =20 ; 
dfltGradientTolerance =1e-6 ; 

dfltInitialLearningRate =classreg .learning .fsutils .FeatureSelectionNCAModel .StringAuto ; 
dfltMiniBatchSize =min (10 ,N ); 
dfltPassLimit =5 ; 
dfltNumPrint =10 ; 
dfltNumTuningIterations =20 ; 
dfltTuningSubsetSize =min (100 ,N ); 


dfltIterationLimit =1000 ; 
dfltIterationLimitSGD =10000 ; 
dfltStepTolerance =1e-6 ; 

dfltMiniBatchLBFGSIterations =10 ; 

ifissparse (PrivX )||issparse (PrivY )
dfltComputationMode =classreg .learning .fsutils .FeatureSelectionNCAModel .ComputationModeMatlab ; 
else
dfltComputationMode =classreg .learning .fsutils .FeatureSelectionNCAModel .ComputationModeMex ; 
end
dfltGrainSize =1 ; 
dfltCacheSize =1000 ; 

dfltFitMethod =classreg .learning .fsutils .FeatureSelectionNCAModel .FitMethodExact ; 
dfltDoFit =true ; 
dfltNumPartitions =max (2 ,min (10 ,N )); 


paramNames ={'Lambda' ,...
    'LengthScale' ,...
    'InitialFeatureWeights' ,...
    'Prior' ,...
    'Standardize' ,...
    'Verbose' ,...
    'Solver' ,...
    'HessianHistorySize' ,...
    'InitialStepSize' ,...
    'LineSearchMethod' ,...
    'MaxLineSearchIterations' ,...
    'GradientTolerance' ,...
    'InitialLearningRate' ,...
    'MiniBatchSize' ,...
    'PassLimit' ,...
    'NumPrint' ,...
    'NumTuningIterations' ,...
    'TuningSubsetSize' ,...
    'IterationLimit' ,...
    'StepTolerance' ,...
    'MiniBatchLBFGSIterations' ,...
    'ComputationMode' ,...
    'GrainSize' ,...
    'CacheSize' ,...
    'FitMethod' ,...
    'DoFit' ,...
    'NumPartitions' }; 
paramDflts ={dfltLambda ,...
    dfltLengthScale ,...
    dfltInitialFeatureWeights ,...
    dfltPrior ,...
    dfltStandardize ,...
    dfltVerbose ,...
    dfltSolver ,...
    dfltHessianHistorySize ,...
    dfltInitialStepSize ,...
    dfltLineSearchMethod ,...
    dfltMaxLineSearchIterations ,...
    dfltGradientTolerance ,...
    dfltInitialLearningRate ,...
    dfltMiniBatchSize ,...
    dfltPassLimit ,...
    dfltNumPrint ,...
    dfltNumTuningIterations ,...
    dfltTuningSubsetSize ,...
    dfltIterationLimit ,...
    dfltStepTolerance ,...
    dfltMiniBatchLBFGSIterations ,...
    dfltComputationMode ,...
    dfltGrainSize ,...
    dfltCacheSize ,...
    dfltFitMethod ,...
    dfltDoFit ,...
    dfltNumPartitions }; 
[lambda ,...
    lengthScale ,...
    initialFeatureWeights ,...
    prior ,...
    standardize ,...
    verbose ,...
    solver ,...
    hessianHistorySize ,...
    initialStepSize ,...
    lineSearchMethod ,...
    maxLineSearchIterations ,...
    gradientTolerance ,...
    initialLearningRate ,...
    miniBatchSize ,...
    passLimit ,...
    numPrint ,...
    numTuningIterations ,...
    tuningSubsetSize ,...
    iterationLimit ,...
    stepTolerance ,...
    miniBatchLBFGSIterations ,...
    computationMode ,...
    grainsize ,...
    cachesizeMB ,...
    fitMethod ,...
    dofitting ,...
    numPartitions ,supplied ,extraArgs ]=internal .stats .parseArgs (paramNames ,paramDflts ,varargin {:}); 


this .Lambda =lambda ; 
this .LengthScale =lengthScale ; 
this .InitialFeatureWeights =initialFeatureWeights ; 
this .Prior =prior ; 
this .Standardize =standardize ; 
this .Verbose =verbose ; 
this .Solver =solver ; 
this .HessianHistorySize =hessianHistorySize ; 
this .InitialStepSize =initialStepSize ; 
this .LineSearchMethod =lineSearchMethod ; 
this .MaxLineSearchIterations =maxLineSearchIterations ; 
this .GradientTolerance =gradientTolerance ; 
this .InitialLearningRate =initialLearningRate ; 
this .MiniBatchSize =miniBatchSize ; 
this .PassLimit =passLimit ; 
this .NumPrint =numPrint ; 
this .NumTuningIterations =numTuningIterations ; 
this .TuningSubsetSize =tuningSubsetSize ; 
this .IterationLimit =iterationLimit ; 
this .StepTolerance =stepTolerance ; 
this .MiniBatchLBFGSIterations =miniBatchLBFGSIterations ; 
this .ComputationMode =computationMode ; 
this .GrainSize =grainsize ; 
this .CacheSize =cachesizeMB ; 
this .FitMethod =fitMethod ; 
this .DoFit =dofitting ; 
this .NumPartitions =numPartitions ; 

dosgd =strcmpi (this .Solver ,classreg .learning .fsutils .FeatureSelectionNCAModel .SolverSGD ); 
if(dosgd &&~supplied .IterationLimit )
this .IterationLimit =dfltIterationLimitSGD ; 
end


ifstrcmpi (this .Method ,classreg .learning .fsutils .FeatureSelectionNCAModel .MethodClassification )
this =setupExtraModelParamsClassification (this ,PrivX ,PrivY ,extraArgs {:}); 
else
this =setupExtraModelParamsRegression (this ,PrivX ,PrivY ,extraArgs {:}); 
end


this .Filled =true ; 


ifissparse (PrivX )||issparse (PrivY )
this .ComputationMode =classreg .learning .fsutils .FeatureSelectionNCAModel .ComputationModeMatlab ; 
end
end

function this =setupExtraModelParamsRegression (this ,~,PrivY ,varargin )

dfltLossFunction =classreg .learning .fsutils .FeatureSelectionNCAModel .RobustLossL1 ; 
dfltEpsilon =iqr (PrivY )/13.49 ; 


paramNames ={'LossFunction' ,'Epsilon' }; 
paramDflts ={dfltLossFunction ,dfltEpsilon }; 
[lossFunction ,epsilon ]=internal .stats .parseArgs (paramNames ,paramDflts ,varargin {:}); 


lossFunction =this .validateLossFunction (lossFunction ); 
epsilon =this .validateEpsilon (epsilon ); 


this .LossFunction =lossFunction ; 
this .Epsilon =epsilon ; 
end

function this =setupExtraModelParamsClassification (this ,~,~,varargin )

dfltLossFunction =classreg .learning .fsutils .FeatureSelectionNCAModel .RobustLossMisclassError ; 
dfltEpsilon =0.1 ; 


paramNames ={'LossFunction' ,'Epsilon' }; 
paramDflts ={dfltLossFunction ,dfltEpsilon }; 
[lossFunction ,epsilon ]=internal .stats .parseArgs (paramNames ,paramDflts ,varargin {:}); 


lossFunction =this .validateLossFunction (lossFunction ); 
epsilon =this .validateEpsilon (epsilon ); 


this .LossFunction =lossFunction ; 
this .Epsilon =epsilon ; 
end
end


methods (Static ,Hidden )
function v =expectedVersion ()

v =1 ; 
end
end


methods (Hidden )
function method =validateMethod (this ,method )
method =internal .stats .getParamVal (method ,classreg .learning .fsutils .FeatureSelectionNCAModel .BuiltInMethods ,'Method' ); 
ifthis .Filled 
error (message ('stats:classreg:learning:fsutils:FeatureSelectionNCAParams:CannotResetMethod' )); 
end
end

function numPartitions =validateNumPartitions (this ,numPartitions )
N =this .NumObservations ; 
[isok ,numPartitions ]=this .isNumericRealVectorNoNaNInf (numPartitions ,1 ); 
isok =isok &&internal .stats .isScalarInt (numPartitions ,2 ,N ); 
if(~isok )
error (message ('stats:classreg:learning:fsutils:FeatureSelectionNCAParams:BadNumPartitions' ,N )); 
end
end

function w0 =validateInitialFeatureWeights (this ,w0 )
P =this .NumFeatures ; 
[isok ,w0 ]=this .isNumericRealVectorNoNaNInf (w0 ,P ); 
isok =isok &&all (w0 >0 ); 
if(~isok )
error (message ('stats:classreg:learning:fsutils:FeatureSelectionNCAParams:BadInitialFeatureWeights' ,P )); 
end
end

function prior =validatePrior (this ,prior )
ifinternal .stats .isString (prior )
prior =internal .stats .getParamVal (prior ,classreg .learning .fsutils .FeatureSelectionNCAModel .BuiltInPriors ,'Prior' ); 
elseifisstruct (prior )
tf =isfield (prior ,{'ClassProbs' ,'ClassNames' }); 
if~all (tf )
error (message ('stats:classreg:learning:fsutils:FeatureSelectionNCAParams:BadPriorFields' )); 
end

classProbs =prior .ClassProbs ; 
[isok ,classProbs ]=this .isNumericRealVectorNoNaNInf (classProbs ,[]); 
isok =isok &&all (classProbs >0 ); 
if(~isok )
error (message ('stats:classreg:learning:fsutils:FeatureSelectionNCAParams:BadClassProbs' )); 
end

classNames =prior .ClassNames ; 
[G ,GN ]=grp2idx (classNames ); 
ifany (isnan (G ))
error (message ('stats:classreg:learning:fsutils:FeatureSelectionNCAParams:BadClassNamesNoMissing' )); 
end
iflength (G )~=length (unique (G ))
error (message ('stats:classreg:learning:fsutils:FeatureSelectionNCAParams:BadClassNamesNoRepeats' )); 
end
iflength (G )~=length (classProbs )
error (message ('stats:classreg:learning:fsutils:FeatureSelectionNCAParams:BadPriorFieldLengths' )); 
end
classNames =GN (G ); 
classNames =classNames (:); 

prior =struct ; 
prior .ClassProbs =classProbs ; 
prior .ClassNames =classNames ; 
else
error (message ('stats:classreg:learning:fsutils:FeatureSelectionNCAParams:BadPrior' )); 
end
end

function lossFunction =validateLossFunction (this ,lossFunction )
if(internal .stats .isString (lossFunction ))
ifstrcmpi (this .Method ,classreg .learning .fsutils .FeatureSelectionNCAModel .MethodClassification )
lossFunction =internal .stats .getParamVal (lossFunction ,classreg .learning .fsutils .FeatureSelectionNCAModel .BuiltInRobustLossFunctionsClassification ,'LossFunction' ); 

elseifstrcmpi (this .Method ,classreg .learning .fsutils .FeatureSelectionNCAModel .MethodRegression )
lossFunction =internal .stats .getParamVal (lossFunction ,classreg .learning .fsutils .FeatureSelectionNCAModel .BuiltInRobustLossFunctionsRegression ,'LossFunction' ); 

else
error (message ('stats:classreg:learning:fsutils:FeatureSelectionNCAParams:BadLossFunctionString' )); 
end
else
isok =isa (lossFunction ,'function_handle' ); 
if(~isok )
error (message ('stats:classreg:learning:fsutils:FeatureSelectionNCAParams:BadLossFunction' )); 
end
end
end

function miniBatchSize =validateMiniBatchSize (this ,miniBatchSize )
N =this .NumObservations ; 
[isok ,miniBatchSize ]=this .isNumericRealVectorNoNaNInf (miniBatchSize ,1 ); 
isok =isok &&internal .stats .isScalarInt (miniBatchSize ,1 ,N ); 
if(~isok )
error (message ('stats:classreg:learning:fsutils:FeatureSelectionNCAParams:BadMiniBatchSize' ,N )); 
end
end

function tuningSubsetSize =validateTuningSubsetSize (this ,tuningSubsetSize )
N =this .NumObservations ; 
[isok ,tuningSubsetSize ]=this .isNumericRealVectorNoNaNInf (tuningSubsetSize ,1 ); 
isok =isok &&internal .stats .isScalarInt (tuningSubsetSize ,1 ,N ); 
if(~isok )
error (message ('stats:classreg:learning:fsutils:FeatureSelectionNCAParams:BadTuningSubsetSize' ,N )); 
end
end

function numFeatures =validateNumFeatures (this ,numFeatures )
isok =internal .stats .isScalarInt (numFeatures ,1 ,Inf ); 
if(~isok )
error (message ('stats:classreg:learning:fsutils:FeatureSelectionNCAParams:BadNumFeatures' )); 
end
ifthis .Filled 
error (message ('stats:classreg:learning:fsutils:FeatureSelectionNCAParams:CannotResetNumFeatures' )); 
end
end
end


methods (Static ,Hidden )
function fitMethod =validateFitMethod (fitMethod )
fitMethod =internal .stats .getParamVal (fitMethod ,classreg .learning .fsutils .FeatureSelectionNCAModel .BuiltInFitMethods ,'FitMethod' ); 
end

function dofitting =validateDoFit (dofitting )
[isok ,dofitting ]=classreg .learning .fsutils .FeatureSelectionNCAParams .isTrueFalseZeroOne (dofitting ); 
if(~isok )
error (message ('stats:classreg:learning:fsutils:FeatureSelectionNCAParams:BadDoFit' )); 
end
end

function lambda =validateLambda (lambda )
[isok ,lambda ]=classreg .learning .fsutils .FeatureSelectionNCAParams .isNumericRealVectorNoNaNInf (lambda ,1 ); 
isok =isok &&(lambda >=0 ); 
if(~isok )
error (message ('stats:classreg:learning:fsutils:FeatureSelectionNCAParams:BadLambda' )); 
end
end

function lengthScale =validateLengthScale (lengthScale )
[isok ,lengthScale ]=classreg .learning .fsutils .FeatureSelectionNCAParams .isNumericRealVectorNoNaNInf (lengthScale ,1 ); 
isok =isok &&(lengthScale >0 ); 
if(~isok )
error (message ('stats:classreg:learning:fsutils:FeatureSelectionNCAParams:BadLengthScale' )); 
end
end

function standardize =validateStandardize (standardize )
[isok ,standardize ]=classreg .learning .fsutils .FeatureSelectionNCAParams .isTrueFalseZeroOne (standardize ); 
if(~isok )
error (message ('stats:classreg:learning:fsutils:FeatureSelectionNCAParams:BadStandardize' )); 
end
end

function verbose =validateVerbose (verbose )
[isok ,verbose ]=classreg .learning .fsutils .FeatureSelectionNCAParams .isNumericRealVectorNoNaNInf (verbose ,1 ); 
isok =isok &&internal .stats .isScalarInt (verbose ,0 ); 
if(~isok )
error (message ('stats:classreg:learning:fsutils:FeatureSelectionNCAParams:BadVerbose' )); 
end
end

function solver =validateSolver (solver )
solver =internal .stats .getParamVal (solver ,classreg .learning .fsutils .FeatureSelectionNCAModel .BuiltInSolvers ,'Solver' ); 
end

function epsilon =validateEpsilon (epsilon )
[isok ,epsilon ]=classreg .learning .fsutils .FeatureSelectionNCAParams .isNumericRealVectorNoNaNInf (epsilon ,1 ); 
isok =isok &&(epsilon >=0 ); 
if(~isok )
error (message ('stats:classreg:learning:fsutils:FeatureSelectionNCAParams:BadEpsilon' )); 
end
end

function hessianHistorySize =validateHessianHistorySize (hessianHistorySize )
[isok ,hessianHistorySize ]=classreg .learning .fsutils .FeatureSelectionNCAParams .isNumericRealVectorNoNaNInf (hessianHistorySize ,1 ); 
isok =isok &&internal .stats .isScalarInt (hessianHistorySize ,1 ); 
if(~isok )
error (message ('stats:classreg:learning:fsutils:FeatureSelectionNCAParams:BadHessianHistorySize' )); 
end
end

function initialStepSize =validateInitialStepSize (initialStepSize )
ifinternal .stats .isString (initialStepSize )
isok =strcmpi (initialStepSize ,classreg .learning .fsutils .FeatureSelectionNCAModel .StringAuto ); 
if(~isok )
error (message ('stats:classreg:learning:fsutils:FeatureSelectionNCAParams:BadInitialStepSizeString' )); 
end
initialStepSize =[]; 
elseif(~isempty (initialStepSize ))
[isok ,initialStepSize ]=classreg .learning .fsutils .FeatureSelectionNCAParams .isNumericRealVectorNoNaNInf (initialStepSize ,1 ); 
isok =isok &&(initialStepSize >0 ); 
if(~isok )
error (message ('stats:classreg:learning:fsutils:FeatureSelectionNCAParams:BadInitialStepSize' )); 
end
else
initialStepSize =[]; 
end
end

function lineSearchMethod =validateLineSearchMethod (lineSearchMethod )
lineSearchMethod =internal .stats .getParamVal (lineSearchMethod ,classreg .learning .fsutils .FeatureSelectionNCAModel .BuiltInLineSearchMethods ,'LineSearchMethod' ); 
end

function maxLineSearchIterations =validateMaxLineSearchIterations (maxLineSearchIterations )
[isok ,maxLineSearchIterations ]=classreg .learning .fsutils .FeatureSelectionNCAParams .isNumericRealVectorNoNaNInf (maxLineSearchIterations ,1 ); 
isok =isok &&internal .stats .isScalarInt (maxLineSearchIterations ,1 ); 
if(~isok )
error (message ('stats:classreg:learning:fsutils:FeatureSelectionNCAParams:BadMaxLineSearchIterations' )); 
end
end

function gradientTolerance =validateGradientTolerance (gradientTolerance )
[isok ,gradientTolerance ]=classreg .learning .fsutils .FeatureSelectionNCAParams .isNumericRealVectorNoNaNInf (gradientTolerance ,1 ); 
isok =isok &&(gradientTolerance >0 ); 
if(~isok )
error (message ('stats:classreg:learning:fsutils:FeatureSelectionNCAParams:BadGradientTolerance' )); 
end
end

function initialLearningRate =validateInitialLearningRate (initialLearningRate )
ifinternal .stats .isString (initialLearningRate )
isok =strcmpi (initialLearningRate ,classreg .learning .fsutils .FeatureSelectionNCAModel .StringAuto ); 
if(~isok )
error (message ('stats:classreg:learning:fsutils:FeatureSelectionNCAParams:BadInitialLearningRateString' )); 
end
initialLearningRate =[]; 
elseif(~isempty (initialLearningRate ))
[isok ,initialLearningRate ]=classreg .learning .fsutils .FeatureSelectionNCAParams .isNumericRealVectorNoNaNInf (initialLearningRate ,1 ); 
isok =isok &&(initialLearningRate >0 ); 
if(~isok )
error (message ('stats:classreg:learning:fsutils:FeatureSelectionNCAParams:BadInitialLearningRate' )); 
end
else
initialLearningRate =[]; 
end
end

function passLimit =validatePassLimit (passLimit )
[isok ,passLimit ]=classreg .learning .fsutils .FeatureSelectionNCAParams .isNumericRealVectorNoNaNInf (passLimit ,1 ); 
isok =isok &&internal .stats .isScalarInt (passLimit ,1 ); 
if(~isok )
error (message ('stats:classreg:learning:fsutils:FeatureSelectionNCAParams:BadPassLimit' )); 
end
end

function numPrint =validateNumPrint (numPrint )
[isok ,numPrint ]=classreg .learning .fsutils .FeatureSelectionNCAParams .isNumericRealVectorNoNaNInf (numPrint ,1 ); 
isok =isok &&internal .stats .isScalarInt (numPrint ,1 ); 
if(~isok )
error (message ('stats:classreg:learning:fsutils:FeatureSelectionNCAParams:BadNumPrint' )); 
end
end

function numTuningIterations =validateNumTuningIterations (numTuningIterations )
[isok ,numTuningIterations ]=classreg .learning .fsutils .FeatureSelectionNCAParams .isNumericRealVectorNoNaNInf (numTuningIterations ,1 ); 
isok =isok &&internal .stats .isScalarInt (numTuningIterations ,1 ); 
if(~isok )
error (message ('stats:classreg:learning:fsutils:FeatureSelectionNCAParams:BadNumTuningIterations' )); 
end
end

function iterationLimit =validateIterationLimit (iterationLimit )
[isok ,iterationLimit ]=classreg .learning .fsutils .FeatureSelectionNCAParams .isNumericRealVectorNoNaNInf (iterationLimit ,1 ); 
isok =isok &&internal .stats .isScalarInt (iterationLimit ,1 ); 
if(~isok )
error (message ('stats:classreg:learning:fsutils:FeatureSelectionNCAParams:BadIterationLimit' )); 
end
end

function stepTolerance =validateStepTolerance (stepTolerance )
[isok ,stepTolerance ]=classreg .learning .fsutils .FeatureSelectionNCAParams .isNumericRealVectorNoNaNInf (stepTolerance ,1 ); 
isok =isok &&(stepTolerance >0 ); 
if(~isok )
error (message ('stats:classreg:learning:fsutils:FeatureSelectionNCAParams:BadStepTolerance' )); 
end
end

function miniBatchLBFGSIterations =validateMiniBatchLBFGSIterations (miniBatchLBFGSIterations )
[isok ,miniBatchLBFGSIterations ]=classreg .learning .fsutils .FeatureSelectionNCAParams .isNumericRealVectorNoNaNInf (miniBatchLBFGSIterations ,1 ); 
isok =isok &&internal .stats .isScalarInt (miniBatchLBFGSIterations ,1 ); 
if(~isok )
error (message ('stats:classreg:learning:fsutils:FeatureSelectionNCAParams:BadMiniBatchLBFGSIterations' )); 
end
end

function computationMode =validateComputationMode (computationMode )
computationMode =internal .stats .getParamVal (computationMode ,classreg .learning .fsutils .FeatureSelectionNCAModel .BuiltInComputationModes ,'ComputationMode' ); 
end

function grainsize =validateGrainSize (grainsize )
[isok ,grainsize ]=classreg .learning .fsutils .FeatureSelectionNCAParams .isNumericRealVectorNoNaNInf (grainsize ,1 ); 
isok =isok &&internal .stats .isScalarInt (grainsize ,1 ); 
if(~isok )
error (message ('stats:classreg:learning:fsutils:FeatureSelectionNCAParams:BadGrainSize' )); 
end
end

function cachesizeMB =validateCacheSize (cachesizeMB )
[isok ,cachesizeMB ]=classreg .learning .fsutils .FeatureSelectionNCAParams .isNumericRealVectorNoNaNInf (cachesizeMB ,1 ); 
isok =isok &&internal .stats .isScalarInt (cachesizeMB ,1 ); 
if(~isok )
error (message ('stats:classreg:learning:fsutils:FeatureSelectionNCAParams:BadCacheSize' )); 
end
end

function numObservations =validateNumObservations (numObservations )
isok =internal .stats .isScalarInt (numObservations ,3 ,Inf ); 
if(~isok )
error (message ('stats:classreg:learning:fsutils:FeatureSelectionNCAParams:BadNumObservations' )); 
end
end

function [isok ,x ]=isNumericRealVectorNoNaNInf (x ,N )












isok =isnumeric (x )&&isreal (x )&&isvector (x )&&~any (isnan (x ))&&~any (isinf (x )); 
if(isempty (N ))

else

isok =isok &&(length (x )==N ); 
end
if(isok &&(size (x ,1 )==1 ))

x =x ' ; 
end
if(isok &&isinteger (x ))
x =cast (x ,'double' ); 
end
end

function [isok ,x ]=isTrueFalseZeroOne (x )






if(isscalar (x )&&islogical (x ))
isok =true ; 
return ; 
end

isint =internal .stats .isScalarInt (x ); 
if(isint )
if(x ==1 )
isok =true ; 
x =true ; 
elseif(x ==0 )
isok =true ; 
x =false ; 
else
isok =false ; 
end
else
isok =false ; 
end
end
end
end

