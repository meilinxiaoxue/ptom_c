classdef GPParams <classreg .learning .modelparams .ModelParams 



































properties (Constant ,Hidden )
Exponential ='Exponential' ; 
ExponentialARD ='ARDExponential' ; 
SquaredExponential ='SquaredExponential' ; 
SquaredExponentialARD ='ARDSquaredExponential' ; 
Matern32 ='Matern32' ; 
Matern32ARD ='ARDMatern32' ; 
Matern52 ='Matern52' ; 
Matern52ARD ='ARDMatern52' ; 
RationalQuadratic ='RationalQuadratic' ; 
RationalQuadraticARD ='ARDRationalQuadratic' ; 
CustomKernel ='CustomKernel' ; 
BuiltInKernelFunctions ={classreg .learning .modelparams .GPParams .Exponential ,...
    classreg .learning .modelparams .GPParams .ExponentialARD ,...
    classreg .learning .modelparams .GPParams .SquaredExponential ,...
    classreg .learning .modelparams .GPParams .SquaredExponentialARD ,...
    classreg .learning .modelparams .GPParams .Matern32 ,...
    classreg .learning .modelparams .GPParams .Matern32ARD ,...
    classreg .learning .modelparams .GPParams .Matern52 ,...
    classreg .learning .modelparams .GPParams .Matern52ARD ,...
    classreg .learning .modelparams .GPParams .RationalQuadratic ,...
    classreg .learning .modelparams .GPParams .RationalQuadraticARD }; 
end

properties (Constant ,Hidden )
BasisNone ='None' ; 
BasisConstant ='Constant' ; 
BasisLinear ='Linear' ; 
BasisPureQuadratic ='PureQuadratic' ; 
BuiltInBasisFunctions ={classreg .learning .modelparams .GPParams .BasisNone ,...
    classreg .learning .modelparams .GPParams .BasisConstant ,...
    classreg .learning .modelparams .GPParams .BasisLinear ,...
    classreg .learning .modelparams .GPParams .BasisPureQuadratic }; 
end

properties (Constant ,Hidden )
FitMethodNone ='None' ; 
FitMethodExact ='Exact' ; 
FitMethodSD ='SD' ; 
FitMethodFIC ='FIC' ; 
FitMethodSR ='SR' ; 
BuiltInFitMethods ={classreg .learning .modelparams .GPParams .FitMethodNone ,...
    classreg .learning .modelparams .GPParams .FitMethodExact ,...
    classreg .learning .modelparams .GPParams .FitMethodSD ,...
    classreg .learning .modelparams .GPParams .FitMethodFIC ,...
    classreg .learning .modelparams .GPParams .FitMethodSR }; 
end

properties (Constant ,Hidden )
PredictMethodExact ='Exact' ; 
PredictMethodBCD ='BCD' ; 
PredictMethodSD ='SD' ; 
PredictMethodFIC ='FIC' ; 
PredictMethodSR ='SR' ; 
BuiltInPredictMethods ={classreg .learning .modelparams .GPParams .PredictMethodExact ,...
    classreg .learning .modelparams .GPParams .PredictMethodBCD ,...
    classreg .learning .modelparams .GPParams .PredictMethodSD ,...
    classreg .learning .modelparams .GPParams .PredictMethodFIC ,...
    classreg .learning .modelparams .GPParams .PredictMethodSR }; 
end

properties (Constant ,Hidden )
ActiveSetMethodSGMA ='SGMA' ; 
ActiveSetMethodEntropy ='Entropy' ; 
ActiveSetMethodLikelihood ='Likelihood' ; 
ActiveSetMethodRandom ='Random' ; 
BuiltInActiveSetMethods ={classreg .learning .modelparams .GPParams .ActiveSetMethodSGMA ,...
    classreg .learning .modelparams .GPParams .ActiveSetMethodEntropy ,...
    classreg .learning .modelparams .GPParams .ActiveSetMethodLikelihood ,...
    classreg .learning .modelparams .GPParams .ActiveSetMethodRandom }; 
end

properties (Constant ,Hidden )
OptimizerFminunc ='fminunc' ; 
OptimizerFmincon ='fmincon' ; 
OptimizerFminsearch ='fminsearch' ; 
OptimizerQuasiNewton ='quasinewton' ; 
OptimizerLBFGS ='lbfgs' ; 
BuiltInOptimizers ={classreg .learning .modelparams .GPParams .OptimizerFminunc ,...
    classreg .learning .modelparams .GPParams .OptimizerFmincon ,...
    classreg .learning .modelparams .GPParams .OptimizerFminsearch ,...
    classreg .learning .modelparams .GPParams .OptimizerQuasiNewton ,...
    classreg .learning .modelparams .GPParams .OptimizerLBFGS }; 
end

properties (Constant ,Hidden )
DistanceMethodFast ='Fast' ; 
DistanceMethodAccurate ='Accurate' ; 
BuiltInDistanceMethods ={classreg .learning .modelparams .GPParams .DistanceMethodFast ,...
    classreg .learning .modelparams .GPParams .DistanceMethodAccurate }; 
end

properties (Constant ,Hidden )
ComputationMethodQR ='QR' ; 
ComputationMethodV ='V' ; 
BuiltInComputationMethods ={classreg .learning .modelparams .GPParams .ComputationMethodQR ,...
    classreg .learning .modelparams .GPParams .ComputationMethodV }; 
end

properties (Constant ,Hidden )
StringAuto ='auto' ; 
end

properties 
KernelFunction =[]; 
KernelParameters =[]; 
BasisFunction =[]; 
Beta =[]; 
Sigma =[]; 
FitMethod =[]; 
PredictMethod =[]; 
ActiveSet =[]; 
ActiveSetSize =[]; 
ActiveSetMethod =[]; 
Standardize =[]; 
Verbose =[]; 
CacheSize =[]; 
Options =[]; 
Optimizer =[]; 
OptimizerOptions =[]; 
ConstantKernelParameters =[]; 
ConstantSigma =[]; 
InitialStepSize =[]; 
end

methods (Access =protected )
function this =GPParams (...
    kernelFunction ,...
    kernelParameters ,...
    basisFunction ,...
    beta ,...
    sigma ,...
    fitMethod ,...
    predictMethod ,...
    activeSet ,...
    activeSetSize ,...
    activeSetMethod ,...
    standardize ,...
    verbose ,...
    cacheSize ,...
    options ,...
    optimizer ,...
    optimizerOptions ,...
    constantKernelParameters ,...
    constantSigma ,...
    initialStepSize )

this =this @classreg .learning .modelparams .ModelParams ('GP' ,'regression' ); 

this .KernelFunction =kernelFunction ; 
this .KernelParameters =kernelParameters ; 
this .BasisFunction =basisFunction ; 
this .Beta =beta ; 
this .Sigma =sigma ; 
this .FitMethod =fitMethod ; 
this .PredictMethod =predictMethod ; 
this .ActiveSet =activeSet ; 
this .ActiveSetSize =activeSetSize ; 
this .ActiveSetMethod =activeSetMethod ; 
this .Standardize =standardize ; 
this .Verbose =verbose ; 
this .CacheSize =cacheSize ; 
this .Options =options ; 
this .Optimizer =optimizer ; 
this .OptimizerOptions =optimizerOptions ; 
this .ConstantKernelParameters =constantKernelParameters ; 
this .ConstantSigma =constantSigma ; 
this .InitialStepSize =initialStepSize ; 
end
end

methods (Static ,Hidden )
function [holder ,extraArgs ]=make (type ,varargin )%#ok<INUSL> 

paramNames ={'KernelFunction' ,...
    'KernelParameters' ,...
    'BasisFunction' ,...
    'Beta' ,...
    'Sigma' ,...
    'FitMethod' ,...
    'PredictMethod' ,...
    'ActiveSet' ,...
    'ActiveSetSize' ,...
    'ActiveSetMethod' ,...
    'Standardize' ,...
    'Verbose' ,...
    'CacheSize' ,...
    'Regularization' ,...
    'SigmaLowerBound' ,...
    'RandomSearchSetSize' ,...
    'ToleranceActiveSet' ,...
    'NumActiveSetRepeats' ,...
    'BlockSizeBCD' ,...
    'NumGreedyBCD' ,...
    'ToleranceBCD' ,...
    'StepToleranceBCD' ,...
    'IterationLimitBCD' ,...
    'DistanceMethod' ,...
    'ComputationMethod' ,...
    'Optimizer' ,...
    'OptimizerOptions' ,...
    'ConstantKernelParameters' ,...
    'ConstantSigma' ,...
    'InitialStepSize' }; 
paramDflts ={[],...
    [],...
    [],...
    [],...
    [],...
    [],...
    [],...
    [],...
    [],...
    [],...
    [],...
    [],...
    [],...
    [],...
    [],...
    [],...
    [],...
    [],...
    [],...
    [],...
    [],...
    [],...
    [],...
    [],...
    [],...
    [],...
    [],...
    []}; 

[kernelFunction ,...
    kernelParameters ,...
    basisFunction ,...
    beta ,...
    sigma ,...
    fitMethod ,...
    predictMethod ,...
    activeSet ,...
    activeSetSize ,...
    activeSetMethod ,...
    standardize ,...
    verbose ,...
    cacheSize ,...
    regularization ,...
    sigmaLowerBound ,...
    randomSearchSetSize ,...
    toleranceActiveSet ,...
    numActiveSetRepeats ,...
    blockSizeBCD ,...
    numGreedyBCD ,...
    toleranceBCD ,...
    stepToleranceBCD ,...
    iterationLimitBCD ,...
    distanceMethod ,...
    computationMethod ,...
    optimizer ,...
    optimizerOptions ,...
    constantKernelParameters ,...
    constantSigma ,...
    initialStepSize ,...
    ~,...
    extraArgs ]=internal .stats .parseArgs (paramNames ,paramDflts ,varargin {:}); 



import classreg.learning.modelparams.GPParams ; 







if~isempty (kernelFunction )
[isok ,kernelFunction ,isfuncstr ]=GPParams .validateStringOrFunctionHandle (kernelFunction ,GPParams .BuiltInKernelFunctions ); 
if~isok 
str =strjoin (GPParams .BuiltInKernelFunctions ,', ' ); 
error (message ('stats:classreg:learning:modelparams:GPParams:make:BadKernelFunction' ,str )); 
end
ifisfuncstr 
name =kernelFunction ; 
kernelFunction =@(XM ,XN ,THETA )feval (name ,XM ,XN ,THETA ); 
end
end



if~isempty (kernelParameters )
[isok ,kernelParameters ]=GPParams .isNumericRealVectorNoNaNInf (kernelParameters ,[]); 
if~isok 
error (message ('stats:classreg:learning:modelparams:GPParams:make:BadKernelParameters' )); 
end
end







if~isempty (basisFunction )
[isok ,basisFunction ,isfuncstr ]=GPParams .validateStringOrFunctionHandle (basisFunction ,GPParams .BuiltInBasisFunctions ); 
if~isok 
str =strjoin (GPParams .BuiltInBasisFunctions ,', ' ); 
error (message ('stats:classreg:learning:modelparams:GPParams:make:BadBasisFunction' ,str )); 
end
ifisfuncstr 
name =basisFunction ; 
basisFunction =@(XM )feval (name ,XM ); 
end
end



if~isempty (beta )
[isok ,beta ]=GPParams .isNumericRealVectorNoNaNInf (beta ,[]); 
if~isok 
error (message ('stats:classreg:learning:modelparams:GPParams:make:BadBeta' )); 
end
end



if~isempty (sigma )
[isok ,sigma ]=GPParams .isNumericRealVectorNoNaNInf (sigma ,1 ); 
isok =isok &&(sigma >0 ); 
if~isok 
error (message ('stats:classreg:learning:modelparams:GPParams:make:BadSigma' )); 
end
end



if~isempty (fitMethod )
fitMethod =internal .stats .getParamVal (fitMethod ,GPParams .BuiltInFitMethods ,'FitMethod' ); 
end



if~isempty (predictMethod )
predictMethod =internal .stats .getParamVal (predictMethod ,GPParams .BuiltInPredictMethods ,'PredictMethod' ); 
end



if~isempty (activeSet )
ifislogical (activeSet )
if~any (activeSet )
error (message ('stats:classreg:learning:modelparams:GPParams:make:BadActiveSet' )); 
end
else
[isok ,activeSet ]=GPParams .isNumericRealVectorNoNaNInf (activeSet ,[]); 
isok =isok &&internal .stats .isIntegerVals (activeSet ,1 )&&length (activeSet )==length (unique (activeSet )); 
if~isok 
error (message ('stats:classreg:learning:modelparams:GPParams:make:BadActiveSet' )); 
end
end
end



if~isempty (activeSetSize )
[isok ,activeSetSize ]=GPParams .isNumericRealVectorNoNaNInf (activeSetSize ,1 ); 
isok =isok &&internal .stats .isIntegerVals (activeSetSize ,1 ); 
if~isok 
error (message ('stats:classreg:learning:modelparams:GPParams:make:BadActiveSetSize' )); 
end
end



if~isempty (activeSetMethod )
activeSetMethod =internal .stats .getParamVal (activeSetMethod ,GPParams .BuiltInActiveSetMethods ,'ActiveSetMethod' ); 
end



if~isempty (standardize )
[isok ,standardize ]=GPParams .isTrueFalseZeroOne (standardize ); 
if~isok 
error (message ('stats:classreg:learning:modelparams:GPParams:make:BadStandardize' )); 
end
end



if~isempty (verbose )
isok =GPParams .isNumericRealVectorNoNaNInf (verbose ,1 ); 
isok =isok &&internal .stats .isIntegerVals (verbose ,0 ,2 ); 
if~isok 
error (message ('stats:classreg:learning:modelparams:GPParams:make:BadVerbose' )); 
end
end



if~isempty (cacheSize )
[isok ,cacheSize ]=GPParams .isNumericRealVectorNoNaNInf (cacheSize ,1 ); 
isok =isok &&internal .stats .isIntegerVals (cacheSize ,1 ); 
if~isok 
error (message ('stats:classreg:learning:modelparams:GPParams:make:BadCacheSize' )); 
end
end



if~isempty (regularization )
[isok ,regularization ]=GPParams .isNumericRealVectorNoNaNInf (regularization ,1 ); 
isok =isok &&(regularization >0 ); 
if~isok 
error (message ('stats:classreg:learning:modelparams:GPParams:make:BadRegularization' )); 
end
end



if~isempty (sigmaLowerBound )
[isok ,sigmaLowerBound ]=GPParams .isNumericRealVectorNoNaNInf (sigmaLowerBound ,1 ); 
isok =isok &&(sigmaLowerBound >0 ); 
if~isok 
error (message ('stats:classreg:learning:modelparams:GPParams:make:BadSigmaLowerBound' )); 
end
end



if~isempty (randomSearchSetSize )
[isok ,randomSearchSetSize ]=GPParams .isNumericRealVectorNoNaNInf (randomSearchSetSize ,1 ); 
isok =isok &&internal .stats .isIntegerVals (randomSearchSetSize ,1 ); 
if~isok 
error (message ('stats:classreg:learning:modelparams:GPParams:make:BadRandomSearchSetSize' )); 
end
end



if~isempty (toleranceActiveSet )
[isok ,toleranceActiveSet ]=GPParams .isNumericRealVectorNoNaNInf (toleranceActiveSet ,1 ); 
isok =isok &&(toleranceActiveSet >0 ); 
if~isok 
error (message ('stats:classreg:learning:modelparams:GPParams:make:BadToleranceActiveSet' )); 
end
end



if~isempty (numActiveSetRepeats )
[isok ,numActiveSetRepeats ]=GPParams .isNumericRealVectorNoNaNInf (numActiveSetRepeats ,1 ); 
isok =isok &&internal .stats .isIntegerVals (numActiveSetRepeats ,1 ); 
if~isok 
error (message ('stats:classreg:learning:modelparams:GPParams:make:BadNumActiveSetRepeats' )); 
end
end



if~isempty (blockSizeBCD )
[isok ,blockSizeBCD ]=GPParams .isNumericRealVectorNoNaNInf (blockSizeBCD ,1 ); 
isok =isok &&internal .stats .isIntegerVals (blockSizeBCD ,1 ); 
if~isok 
error (message ('stats:classreg:learning:modelparams:GPParams:make:BadBlockSizeBCD' )); 
end
end



if~isempty (numGreedyBCD )
[isok ,numGreedyBCD ]=GPParams .isNumericRealVectorNoNaNInf (numGreedyBCD ,1 ); 
isok =isok &&internal .stats .isIntegerVals (numGreedyBCD ,1 ); 
if~isok 
error (message ('stats:classreg:learning:modelparams:GPParams:make:BadNumGreedyBCD' )); 
end
end



if~isempty (toleranceBCD )
[isok ,toleranceBCD ]=GPParams .isNumericRealVectorNoNaNInf (toleranceBCD ,1 ); 
isok =isok &&(toleranceBCD >0 ); 
if~isok 
error (message ('stats:classreg:learning:modelparams:GPParams:make:BadToleranceBCD' )); 
end
end



if~isempty (stepToleranceBCD )
[isok ,stepToleranceBCD ]=GPParams .isNumericRealVectorNoNaNInf (stepToleranceBCD ,1 ); 
isok =isok &&(stepToleranceBCD >0 ); 
if~isok 
error (message ('stats:classreg:learning:modelparams:GPParams:make:BadStepToleranceBCD' )); 
end
end



if~isempty (iterationLimitBCD )
[isok ,iterationLimitBCD ]=GPParams .isNumericRealVectorNoNaNInf (iterationLimitBCD ,1 ); 
isok =isok &&internal .stats .isIntegerVals (iterationLimitBCD ,1 ); 
if~isok 
error (message ('stats:classreg:learning:modelparams:GPParams:make:BadIterationLimitBCD' )); 
end
end



if~isempty (distanceMethod )
distanceMethod =internal .stats .getParamVal (distanceMethod ,GPParams .BuiltInDistanceMethods ,'DistanceMethod' ); 
end



if~isempty (computationMethod )
computationMethod =internal .stats .getParamVal (computationMethod ,GPParams .BuiltInComputationMethods ,'ComputationMethod' ); 
end


ifisempty (computationMethod )


useQR =[]; 
else


ifstrcmpi (computationMethod ,GPParams .ComputationMethodQR )
useQR =true ; 
else
useQR =false ; 
end
end



if~isempty (optimizer )
optimizer =internal .stats .getParamVal (optimizer ,GPParams .BuiltInOptimizers ,'Optimizer' ); 
end




if~isempty (optimizerOptions )
isok =isa (optimizerOptions ,'optim.options.Fminunc' )||...
    isa (optimizerOptions ,'optim.options.Fmincon' )||...
    isa (optimizerOptions ,'struct' ); 
if~isok 
error (message ('stats:classreg:learning:modelparams:GPParams:make:BadOptimizerOptions' )); 
end
end



if~isempty (constantKernelParameters )
if~islogical (constantKernelParameters )
error (message ('stats:classreg:learning:modelparams:GPParams:make:BadConstantKernelParametersType' )); 
end
end



if~isempty (constantSigma )
if~(islogical (constantSigma )&&isscalar (constantSigma ))
error (message ('stats:classreg:learning:modelparams:GPParams:make:BadConstantSigma' )); 
end
end





if~isempty (initialStepSize )
ifisnumeric (initialStepSize )
[isok ,initialStepSize ]=GPParams .isNumericRealVectorNoNaNInf (initialStepSize ,1 ); 
isok =isok &&(initialStepSize >0 ); 
if~isok 
error (message ('stats:classreg:learning:modelparams:GPParams:make:BadInitialStepSize' )); 
end
else
initialStepSize =internal .stats .getParamVal (initialStepSize ,{GPParams .StringAuto },'InitialStepSize' ); 
end
end



options =struct (); 
options .DiagonalOffset =0 ; 
options .Regularization =regularization ; 
options .SigmaLowerBound =sigmaLowerBound ; 
options .RandomSearchSetSize =randomSearchSetSize ; 
options .ToleranceActiveSet =toleranceActiveSet ; 
options .NumActiveSetRepeats =numActiveSetRepeats ; 
options .BlockSizeBCD =blockSizeBCD ; 
options .NumGreedyBCD =numGreedyBCD ; 
options .ToleranceBCD =toleranceBCD ; 
options .StepToleranceBCD =stepToleranceBCD ; 
options .IterationLimitBCD =iterationLimitBCD ; 
options .DistanceMethod =distanceMethod ; 
options .UseQR =useQR ; 


holder =classreg .learning .modelparams .GPParams (...
    kernelFunction ,...
    kernelParameters ,...
    basisFunction ,...
    beta ,...
    sigma ,...
    fitMethod ,...
    predictMethod ,...
    activeSet ,...
    activeSetSize ,...
    activeSetMethod ,...
    standardize ,...
    verbose ,...
    cacheSize ,...
    options ,...
    optimizer ,...
    optimizerOptions ,...
    constantKernelParameters ,...
    constantSigma ,...
    initialStepSize ); 
end
end

methods (Hidden )
function this =fillDefaultParams (this ,X ,~,~,dataSummary ,classSummary )%#ok<INUSD>             

D =size (X ,2 ); 
N =size (X ,1 ); 
NumXColumns =D ; 
if~isempty (dataSummary )&&~isempty (dataSummary .VariableRange )

D =sum (cellfun (@(c )max (1 ,size (c ,1 )),dataSummary .VariableRange )); 
end


ifisempty (this .KernelFunction )
this .KernelFunction =this .SquaredExponential ; 
end


ifisempty (this .KernelParameters )
ifisa (this .KernelFunction ,'function_handle' )

error (message ('stats:classreg:learning:modelparams:GPParams:fillDefaultParams:CustomKernelParameters' )); 
else


end
else
ifisa (this .KernelFunction ,'function_handle' )


else






switchlower (this .KernelFunction )
case lower (this .Exponential )
isok =(length (this .KernelParameters )==2 )&&(all (this .KernelParameters >0 )); 
if~isok 
error (message ('stats:classreg:learning:modelparams:GPParams:fillDefaultParams:BadExponentialParameters' )); 
end
case lower (this .SquaredExponential )
isok =(length (this .KernelParameters )==2 )&&(all (this .KernelParameters >0 )); 
if~isok 
error (message ('stats:classreg:learning:modelparams:GPParams:fillDefaultParams:BadSquaredExponentialParameters' )); 
end
case lower (this .Matern32 )
isok =(length (this .KernelParameters )==2 )&&(all (this .KernelParameters >0 )); 
if~isok 
error (message ('stats:classreg:learning:modelparams:GPParams:fillDefaultParams:BadMatern32Parameters' )); 
end
case lower (this .Matern52 )
isok =(length (this .KernelParameters )==2 )&&(all (this .KernelParameters >0 )); 
if~isok 
error (message ('stats:classreg:learning:modelparams:GPParams:fillDefaultParams:BadMatern52Parameters' )); 
end
case lower (this .RationalQuadratic )
isok =(length (this .KernelParameters )==3 )&&(all (this .KernelParameters >0 )); 
if~isok 
error (message ('stats:classreg:learning:modelparams:GPParams:fillDefaultParams:BadRationalQuadraticParameters' )); 
end
case lower (this .ExponentialARD )
isok =(length (this .KernelParameters )==(D +1 ))&&(all (this .KernelParameters >0 )); 
if~isok 
error (message ('stats:classreg:learning:modelparams:GPParams:fillDefaultParams:BadARDExponentialParameters' ,D ,D +1 )); 
end
case lower (this .SquaredExponentialARD )
isok =(length (this .KernelParameters )==(D +1 ))&&(all (this .KernelParameters >0 )); 
if~isok 
error (message ('stats:classreg:learning:modelparams:GPParams:fillDefaultParams:BadARDSquaredExponentialParameters' ,D ,D +1 )); 
end
case lower (this .Matern32ARD )
isok =(length (this .KernelParameters )==(D +1 ))&&(all (this .KernelParameters >0 )); 
if~isok 
error (message ('stats:classreg:learning:modelparams:GPParams:fillDefaultParams:BadARDMatern32Parameters' ,D ,D +1 )); 
end
case lower (this .Matern52ARD )
isok =(length (this .KernelParameters )==(D +1 ))&&(all (this .KernelParameters >0 )); 
if~isok 
error (message ('stats:classreg:learning:modelparams:GPParams:fillDefaultParams:BadARDMatern52Parameters' ,D ,D +1 )); 
end
case lower (this .RationalQuadraticARD )
isok =(length (this .KernelParameters )==(D +2 ))&&(all (this .KernelParameters >0 )); 
if~isok 
error (message ('stats:classreg:learning:modelparams:GPParams:fillDefaultParams:BadARDRationalQuadraticParameters' ,D ,D +2 )); 
end
end



ifisrow (this .KernelParameters )
this .KernelParameters =this .KernelParameters ' ; 
end
end
end


ifisempty (this .BasisFunction )
this .BasisFunction =this .BasisConstant ; 
elseifstrcmpi (this .BasisFunction ,this .BasisPureQuadratic )...
    &&D >NumXColumns 

error (message ('stats:classreg:learning:modelparams:GPParams:fillDefaultParams:NoQuadraticCategorical' )); 
end


ifisempty (this .Beta )
ifisa (this .BasisFunction ,'function_handle' )

error (message ('stats:classreg:learning:modelparams:GPParams:fillDefaultParams:CustomBeta' )); 
else

switchlower (this .BasisFunction )
case lower (this .BasisNone )
this .Beta =zeros (0 ,1 ); 
case lower (this .BasisConstant )
this .Beta =zeros (1 ,1 ); 
case lower (this .BasisLinear )
this .Beta =zeros (D +1 ,1 ); 
case lower (this .BasisPureQuadratic )
this .Beta =zeros (2 *D +1 ,1 ); 
end
end
else
ifisa (this .BasisFunction ,'function_handle' )


else

switchlower (this .BasisFunction )
case lower (this .BasisNone )
isok =isempty (this .Beta ); 
if~isok 
error (message ('stats:classreg:learning:modelparams:GPParams:fillDefaultParams:BadBasisNoneBeta' )); 
end
case lower (this .BasisConstant )
isok =(length (this .Beta )==1 ); 
if~isok 
error (message ('stats:classreg:learning:modelparams:GPParams:fillDefaultParams:BadBasisConstantBeta' )); 
end
case lower (this .BasisLinear )
isok =(length (this .Beta )==D +1 ); 
if~isok 
error (message ('stats:classreg:learning:modelparams:GPParams:fillDefaultParams:BadBasisLinearBeta' )); 
end
case lower (this .BasisPureQuadratic )
isok =(length (this .Beta )==2 *D +1 ); 
if~isok 
error (message ('stats:classreg:learning:modelparams:GPParams:fillDefaultParams:BadBasisPureQuadraticBeta' )); 
end
end



ifisrow (this .Beta )
this .Beta =this .Beta ' ; 
end
end
end


ifisempty (this .Sigma )

end


ifisempty (this .FitMethod )
if(N <=2000 )
this .FitMethod =this .FitMethodExact ; 
else
this .FitMethod =this .FitMethodSD ; 
end
end


ifisempty (this .PredictMethod )
if(N <=10000 )
this .PredictMethod =this .PredictMethodExact ; 
else
this .PredictMethod =this .PredictMethodBCD ; 
end
end




if~isempty (this .ActiveSet )
ifislogical (this .ActiveSet )
isok =length (this .ActiveSet )==N ; 
if~isok 
error (message ('stats:classreg:learning:modelparams:GPParams:fillDefaultParams:BadActiveSet' ,N ,N ,N )); 
end
else


activeSet =this .ActiveSet ; 
lenActiveSet =length (activeSet ); 
isok =lenActiveSet >=1 &&lenActiveSet <=N ; 
isok =isok &&all (activeSet >=1 &activeSet <=N ); 
if~isok 
error (message ('stats:classreg:learning:modelparams:GPParams:fillDefaultParams:BadActiveSet' ,N ,N ,N )); 
end
activeSetLogical =false (N ,1 ); 
activeSetLogical (this .ActiveSet )=true ; 
this .ActiveSet =activeSetLogical ; 
end
end



ifisempty (this .ActiveSetSize )
isSRFIC =any (strcmpi (this .FitMethod ,{this .FitMethodSR ,this .FitMethodFIC })); 
ifisSRFIC 
this .ActiveSetSize =min (1000 ,N ); 
else
this .ActiveSetSize =min (2000 ,N ); 
end
else
if(this .ActiveSetSize >N )
error (message ('stats:classreg:learning:modelparams:GPParams:fillDefaultParams:BadActiveSetSize' ,N )); 
end
end
this .ActiveSetSize =max (1 ,min (this .ActiveSetSize ,N )); 


ifisempty (this .ActiveSetMethod )
this .ActiveSetMethod =this .ActiveSetMethodRandom ; 
end


ifisempty (this .Standardize )
this .Standardize =false ; 
end


ifisempty (this .Verbose )
this .Verbose =0 ; 
end


ifisempty (this .CacheSize )
this .CacheSize =1000 ; 
end

























dfltopts =struct (); 
dfltopts .DiagonalOffset =0 ; 

dfltopts .Regularization =[]; 

dfltopts .SigmaLowerBound =[]; 
dfltopts .RandomSearchSetSize =59 ; 
dfltopts .ToleranceActiveSet =1e-6 ; 
dfltopts .NumActiveSetRepeats =3 ; 


dfltopts .BlockSizeBCD =min (1000 ,N ); 
dfltopts .NumGreedyBCD =min (100 ,dfltopts .BlockSizeBCD ); 
dfltopts .ToleranceBCD =1e-3 ; 
dfltopts .StepToleranceBCD =1e-3 ; 
dfltopts .IterationLimitBCD =1000000 ; 
dfltopts .DistanceMethod =this .DistanceMethodFast ; 
dfltopts .UseQR =true ; 













ifisempty (this .Options .DiagonalOffset )
this .Options .DiagonalOffset =dfltopts .DiagonalOffset ; 
else
diagonalOffset =this .Options .DiagonalOffset ; 
[isok ,diagonalOffset ]=this .isNumericRealVectorNoNaNInf (diagonalOffset ,1 ); 
isok =isok &&(diagonalOffset >=0 ); 
if~isok 
error (message ('stats:classreg:learning:modelparams:GPParams:fillDefaultParams:BadDiagonalOffset' )); 
end
this .Options .DiagonalOffset =diagonalOffset ; 
end


ifisempty (this .Options .Regularization )
this .Options .Regularization =dfltopts .Regularization ; 
end


ifisempty (this .Options .SigmaLowerBound )
this .Options .SigmaLowerBound =dfltopts .SigmaLowerBound ; 
end


ifisempty (this .Options .RandomSearchSetSize )
this .Options .RandomSearchSetSize =dfltopts .RandomSearchSetSize ; 
end


ifisempty (this .Options .ToleranceActiveSet )
this .Options .ToleranceActiveSet =dfltopts .ToleranceActiveSet ; 
end


ifisempty (this .Options .NumActiveSetRepeats )
this .Options .NumActiveSetRepeats =dfltopts .NumActiveSetRepeats ; 
end


ifisempty (this .Options .BlockSizeBCD )
this .Options .BlockSizeBCD =dfltopts .BlockSizeBCD ; 
else
blockSizeBCD =this .Options .BlockSizeBCD ; 
isok =internal .stats .isIntegerVals (blockSizeBCD ,1 ,N ); 
if~isok 
error (message ('stats:classreg:learning:modelparams:GPParams:fillDefaultParams:BadBlockSizeBCD' ,N )); 
end
this .Options .BlockSizeBCD =blockSizeBCD ; 
end
this .Options .BlockSizeBCD =max (1 ,min (this .Options .BlockSizeBCD ,N )); 


ifisempty (this .Options .NumGreedyBCD )
this .Options .NumGreedyBCD =dfltopts .NumGreedyBCD ; 
else
numGreedyBCD =this .Options .NumGreedyBCD ; 
isok =internal .stats .isIntegerVals (numGreedyBCD ,1 ,this .Options .BlockSizeBCD ); 
if~isok 
error (message ('stats:classreg:learning:modelparams:GPParams:fillDefaultParams:BadNumGreedyBCD' ,this .Options .BlockSizeBCD )); 
end
this .Options .NumGreedyBCD =numGreedyBCD ; 
end
this .Options .NumGreedyBCD =max (1 ,min (this .Options .NumGreedyBCD ,this .Options .BlockSizeBCD )); 


ifisempty (this .Options .ToleranceBCD )
this .Options .ToleranceBCD =dfltopts .ToleranceBCD ; 
end


ifisempty (this .Options .StepToleranceBCD )
this .Options .StepToleranceBCD =dfltopts .StepToleranceBCD ; 
end


ifisempty (this .Options .IterationLimitBCD )
this .Options .IterationLimitBCD =dfltopts .IterationLimitBCD ; 
end


ifisempty (this .Options .DistanceMethod )
this .Options .DistanceMethod =dfltopts .DistanceMethod ; 
end


ifisempty (this .Options .UseQR )
this .Options .UseQR =dfltopts .UseQR ; 
end


ifisempty (this .Optimizer )
this .Optimizer =this .OptimizerQuasiNewton ; 
end


isemptyStruct =isstruct (this .OptimizerOptions )&&isempty (fieldnames (this .OptimizerOptions )); 
ifisempty (this .OptimizerOptions )||isemptyStruct 

switchlower (this .Optimizer )
case lower (this .OptimizerFminunc )
this .OptimizerOptions =optimoptions ('fminunc' ); 
this .OptimizerOptions .Algorithm ='quasi-newton' ; 
this .OptimizerOptions .GradObj ='on' ; 
this .OptimizerOptions .MaxFunEvals =10000 ; 
this .OptimizerOptions .Display ='off' ; 
case lower (this .OptimizerFmincon )
this .OptimizerOptions =optimoptions ('fmincon' ); 
this .OptimizerOptions .GradObj ='on' ; 
this .OptimizerOptions .MaxFunEvals =10000 ; 
this .OptimizerOptions .Display ='off' ; 
case lower (this .OptimizerFminsearch )
this .OptimizerOptions =optimset ('fminsearch' ); 
this .OptimizerOptions .Display ='off' ; 
case {lower (this .OptimizerQuasiNewton ),lower (this .OptimizerLBFGS )}
this .OptimizerOptions =statset ('fitrgp' ); 


this .OptimizerOptions .GradObj ='on' ; 
this .OptimizerOptions .Display ='off' ; 
end
else

switchlower (this .Optimizer )
case lower (this .OptimizerFminunc )
isok =isa (this .OptimizerOptions ,'optim.options.Fminunc' ); 
if~isok 
error (message ('stats:classreg:learning:modelparams:GPParams:fillDefaultParams:BadOptimizerOptionsFminunc' )); 
end
case lower (this .OptimizerFmincon )
isok =isa (this .OptimizerOptions ,'optim.options.Fmincon' ); 
if~isok 
error (message ('stats:classreg:learning:modelparams:GPParams:fillDefaultParams:BadOptimizerOptionsFmincon' )); 
end
case lower (this .OptimizerFminsearch )
isok =isa (this .OptimizerOptions ,'struct' ); 
if~isok 
error (message ('stats:classreg:learning:modelparams:GPParams:fillDefaultParams:BadOptimizerOptionsFminsearch' )); 
end
this .OptimizerOptions =optimset (optimset ('fminsearch' ),this .OptimizerOptions ); 
case {lower (this .OptimizerQuasiNewton ),lower (this .OptimizerLBFGS )}
isok =isa (this .OptimizerOptions ,'struct' ); 
if~isok 
error (message ('stats:classreg:learning:modelparams:GPParams:fillDefaultParams:BadOptimizerOptionsQuasiNewton' )); 
end
this .OptimizerOptions =statset (statset ('fitrgp' ),this .OptimizerOptions ); 
end
end







ifisempty (this .ConstantSigma )
this .ConstantSigma =false ; 
end



end

end

methods (Static )
function [isok ,func ,isfuncstr ]=validateStringOrFunctionHandle (func ,allowedVals )










isfuncstr =false ; 
ifisa (func ,'function_handle' )
isok =true ; 
elseifischar (func )

tf =strncmpi (func ,allowedVals ,length (func )); 
nmatches =sum (tf ); 
ifnmatches >1 

isok =false ; 
elseifnmatches ==1 

isok =true ; 
func =allowedVals {tf }; 
else

isok =false ; 
end


if~isok 
whichOutput =which (func ); 
if~isempty (whichOutput )&&~strcmpi (whichOutput ,'variable' )
isfuncstr =true ; 
isok =true ; 
end
end
else
isok =false ; 
end
end

function [isok ,x ]=isNumericRealVectorNoNaNInf (x ,N )









isok =isnumeric (x )&&isreal (x )&&isvector (x )&&~any (isnan (x ))&&~any (isinf (x )); 
ifisempty (N )

else

isok =isok &&(length (x )==N ); 
end
ifisok &&(size (x ,1 )==1 )

x =x ' ; 
end
end

function [isok ,x ]=isTrueFalseZeroOne (x )






ifislogical (x )
isok =true ; 
return ; 
end

isint =internal .stats .isScalarInt (x ); 
ifisint 
ifx ==1 
isok =true ; 
x =true ; 
elseifx ==0 
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

