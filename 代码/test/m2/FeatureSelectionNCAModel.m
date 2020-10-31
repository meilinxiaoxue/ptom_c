classdef (Abstract )FeatureSelectionNCAModel <classreg .learning .internal .DisallowVectorOps 












properties (Constant ,Hidden )
SolverLBFGS =classreg .learning .fsutils .Solver .SolverLBFGS ; 
SolverSGD =classreg .learning .fsutils .Solver .SolverSGD ; 
SolverMiniBatchLBFGS =classreg .learning .fsutils .Solver .SolverMiniBatchLBFGS ; 
BuiltInSolvers ={classreg .learning .fsutils .FeatureSelectionNCAModel .SolverLBFGS ,...
    classreg .learning .fsutils .FeatureSelectionNCAModel .SolverSGD ,...
    classreg .learning .fsutils .FeatureSelectionNCAModel .SolverMiniBatchLBFGS }; 

LineSearchMethodBacktracking =classreg .learning .fsutils .Solver .LineSearchMethodBacktracking ; 
LineSearchMethodWeakWolfe =classreg .learning .fsutils .Solver .LineSearchMethodWeakWolfe ; 
LineSearchMethodStrongWolfe =classreg .learning .fsutils .Solver .LineSearchMethodStrongWolfe ; 
BuiltInLineSearchMethods ={classreg .learning .fsutils .FeatureSelectionNCAModel .LineSearchMethodBacktracking ,...
    classreg .learning .fsutils .FeatureSelectionNCAModel .LineSearchMethodWeakWolfe ,...
    classreg .learning .fsutils .FeatureSelectionNCAModel .LineSearchMethodStrongWolfe }; 

StringAuto =classreg .learning .fsutils .Solver .StringAuto ; 
end



properties (Constant ,Hidden )
RobustLossL1 ='mad' ; 
RobustLossL2 ='mse' ; 
RobustLossEpsilonInsensitive ='epsiloninsensitive' ; 
BuiltInRobustLossFunctionsRegression ={classreg .learning .fsutils .FeatureSelectionNCAModel .RobustLossL1 ,...
    classreg .learning .fsutils .FeatureSelectionNCAModel .RobustLossL2 ,...
    classreg .learning .fsutils .FeatureSelectionNCAModel .RobustLossEpsilonInsensitive }; 

RobustLossMisclassError ='classiferror' ; 
BuiltInRobustLossFunctionsClassification ={classreg .learning .fsutils .FeatureSelectionNCAModel .RobustLossMisclassError }; 
end



properties (Constant ,Hidden )
MethodRegression ='regression' ; 
MethodClassification ='classification' ; 
BuiltInMethods ={classreg .learning .fsutils .FeatureSelectionNCAModel .MethodRegression ,...
    classreg .learning .fsutils .FeatureSelectionNCAModel .MethodClassification }; 
end



properties (Constant ,Hidden )
MISCLASS_LOSS =1 ; 
L1_LOSS =2 ; 
L2_LOSS =3 ; 
EPSILON_INSENSITIVE_LOSS =4 ; 
CUSTOM_LOSS =5 ; 
end



properties (Constant ,Hidden )
FitMethodNone ='none' ; 
FitMethodExact ='exact' ; 
FitMethodDivideAndConquer ='average' ; 
BuiltInFitMethods ={classreg .learning .fsutils .FeatureSelectionNCAModel .FitMethodNone ,...
    classreg .learning .fsutils .FeatureSelectionNCAModel .FitMethodExact ,...
    classreg .learning .fsutils .FeatureSelectionNCAModel .FitMethodDivideAndConquer }; 
end



properties (Constant ,Hidden )
PriorUniform ='uniform' ; 
PriorEmpirical ='empirical' ; 
BuiltInPriors ={classreg .learning .fsutils .FeatureSelectionNCAModel .PriorUniform ,...
    classreg .learning .fsutils .FeatureSelectionNCAModel .PriorEmpirical }; 
end



properties (Constant ,Hidden )
ComputationModeMex ='mex-outer-tbb' ; 
ComputationModeMatlab ='matlab-inner-vector' ; 
BuiltInComputationModes ={classreg .learning .fsutils .FeatureSelectionNCAModel .ComputationModeMex ,...
    classreg .learning .fsutils .FeatureSelectionNCAModel .ComputationModeMatlab }; 
end



properties (Constant ,Hidden )
ClassificationSubClassName ='FeatureSelectionNCAClassification' ; 
RegressionSubClassName ='FeatureSelectionNCARegression' ; 
end


properties (GetAccess =public ,SetAccess =protected ,Dependent )




























FitInfo ; 













FeatureWeights ; 









Mu ; 









Sigma ; 
end

methods 
function fitInfo =get .FitInfo (this )
fitInfo =this .Impl .FitInfo ; 
end

function featureWeights =get .FeatureWeights (this )
featureWeights =this .Impl .FeatureWeights ; 
end

function mu =get .Mu (this )
mu =this .Impl .Mu ; 
end

function sigma =get .Sigma (this )
sigma =this .Impl .Sigma ; 
end
end


properties (Abstract ,GetAccess =public ,SetAccess =protected ,Dependent )






Y ; 
end

properties (Abstract ,GetAccess =public ,SetAccess =protected ,Hidden ,Dependent )



PrivY ; 
end

properties (Abstract ,Hidden )




Impl ; 
end


properties (GetAccess =public ,SetAccess =protected ,Dependent )





X ; 
end

properties (GetAccess =public ,SetAccess =protected ,Hidden ,Dependent )





PrivX ; 
end

properties (GetAccess =public ,SetAccess =protected ,Dependent )



W ; 
end

properties (GetAccess =public ,SetAccess =protected ,Hidden ,Dependent )



PrivW ; 
end

properties (GetAccess =public ,SetAccess =protected ,Dependent )








ModelParameters ; 
end

properties (GetAccess =public ,SetAccess =protected ,Hidden ,Dependent )




ModelParams ; 
end

methods 
function X =get .X (this )
X =this .Impl .X ; 
end

function privX =get .PrivX (this )
privX =this .Impl .PrivX ; 
end

function W =get .W (this )
W =this .Impl .W ; 
end

function privW =get .PrivW (this )
privW =this .Impl .PrivW ; 
end

function mp =get .ModelParameters (this )
mp =toStruct (this .Impl .ModelParams ); 
end

function mp =get .ModelParams (this )
mp =this .Impl .ModelParams ; 
end
end

properties (GetAccess =public ,SetAccess =protected ,Dependent )






Lambda ; 















FitMethod ; 










Solver ; 





GradientTolerance ; 




IterationLimit ; 





PassLimit ; 















InitialLearningRate ; 














Verbose ; 












InitialFeatureWeights ; 




NumObservations ; 
end

properties (GetAccess =public ,SetAccess =protected ,Hidden ,Dependent )



NumFeatures ; 
end

methods 
function lambda =get .Lambda (this )
lambda =this .ModelParams .Lambda ; 
end

function fitMethod =get .FitMethod (this )
fitMethod =this .ModelParams .FitMethod ; 
end

function solver =get .Solver (this )
solver =this .ModelParams .Solver ; 
end

function gradientTolerance =get .GradientTolerance (this )
gradientTolerance =this .ModelParams .GradientTolerance ; 
end

function iterationLimit =get .IterationLimit (this )
iterationLimit =this .ModelParams .IterationLimit ; 
end

function passLimit =get .PassLimit (this )
passLimit =this .ModelParams .PassLimit ; 
end

function initialLearningRate =get .InitialLearningRate (this )
initialLearningRate =this .ModelParams .InitialLearningRate ; 
end

function verbose =get .Verbose (this )
verbose =this .ModelParams .Verbose ; 
end

function initialFeatureWeights =get .InitialFeatureWeights (this )
initialFeatureWeights =this .ModelParams .InitialFeatureWeights ; 
end

function N =get .NumObservations (this )
N =size (this .PrivX ,1 ); 
end

function P =get .NumFeatures (this )
P =size (this .PrivX ,2 ); 
end
end


methods (Abstract )
predict (this ,XTest )
loss (this ,XTest ,YTest )
end


methods 
function this =refit (this ,varargin )






































































[varargin {:}]=convertStringsToChars (varargin {:}); 

dfltLambda =this .Lambda ; 
dfltFitMethod =this .FitMethod ; 
dfltSolver =this .Solver ; 
dfltGradientTolerance =this .GradientTolerance ; 
dfltIterationLimit =this .IterationLimit ; 
dfltPassLimit =this .PassLimit ; 
dfltInitialLearningRate =this .InitialLearningRate ; 
dfltVerbose =this .Verbose ; 
dfltInitialFeatureWeights =this .InitialFeatureWeights ; 


paramNames ={'Lambda' ,'FitMethod' ,'Solver' ,'GradientTolerance' ,'IterationLimit' ,'PassLimit' ,'InitialLearningRate' ,'Verbose' ,'InitialFeatureWeights' }; 
paramDflts ={dfltLambda ,dfltFitMethod ,dfltSolver ,dfltGradientTolerance ,dfltIterationLimit ,dfltPassLimit ,dfltInitialLearningRate ,dfltVerbose ,dfltInitialFeatureWeights }; 
[lambda ,fitMethod ,solver ,gradientTolerance ,iterationLimit ,passLimit ,initialLearningRate ,verbose ,initialFeatureWeights ]=internal .stats .parseArgs (paramNames ,paramDflts ,varargin {:}); 





this .Impl .ModelParams .Lambda =lambda ; 
this .Impl .ModelParams .FitMethod =fitMethod ; 
this .Impl .ModelParams .Solver =solver ; 
this .Impl .ModelParams .GradientTolerance =gradientTolerance ; 
this .Impl .ModelParams .IterationLimit =iterationLimit ; 
this .Impl .ModelParams .PassLimit =passLimit ; 
this .Impl .ModelParams .InitialLearningRate =initialLearningRate ; 
this .Impl .ModelParams .Verbose =verbose ; 
this .Impl .ModelParams .InitialFeatureWeights =initialFeatureWeights ; 
this .Impl .ModelParams .DoFit =true ; 



this .Impl =buildModel (this .Impl ); 
end
end


methods (Hidden )
function disp (this )

internal .stats .displayClassName (this ); 

s =propsForDisp (this ,[]); 
disp (s ); 

internal .stats .displayMethodsProperties (this ); 
end

function s =propsForDisp (this ,s )






if(nargin <2 ||isempty (s ))
s =struct ; 
end


s .NumObservations =this .NumObservations ; 
s .ModelParameters =this .ModelParameters ; 
s .Lambda =this .Lambda ; 
s .FitMethod =this .FitMethod ; 
s .Solver =this .Solver ; 
s .GradientTolerance =this .GradientTolerance ; 
s .IterationLimit =this .IterationLimit ; 
s .PassLimit =this .PassLimit ; 
s .InitialLearningRate =this .InitialLearningRate ; 
s .Verbose =this .Verbose ; 
s .InitialFeatureWeights =this .InitialFeatureWeights ; 
s .FeatureWeights =this .FeatureWeights ; 
s .FitInfo =this .FitInfo ; 
s .Mu =this .Mu ; 
s .Sigma =this .Sigma ; 
s .X =this .X ; 
end
end


methods (Hidden )
function this =doFit (this ,X ,Y ,varargin )





paramNames ={'Weights' }; 
paramDflts ={[]}; 
[Weights ,~,otherArgs ]=internal .stats .parseArgs (paramNames ,paramDflts ,varargin {:}); 

if(isempty (Weights ))
Weights =ones (size (X ,1 ),1 ); 
end




[X ,privY ,privW ,yLabels ,yLabelsOrig ]=setupXYW (this ,X ,Y ,Weights ); 


modelParams =setupModelParams (this ,X ,privY ,otherArgs {:}); 


this .Impl =makeImpl (this ,X ,privY ,privW ,modelParams ,yLabels ,yLabelsOrig ); 
end

function this =doReFit (this ,XSub ,YSub ,WSub ,modelParams )








[XSub ,privY ,privW ,yLabels ,yLabelsOrig ]=setupXYW (this ,XSub ,YSub ,WSub ); 


modelParams .NumObservations =size (XSub ,1 ); 


this .Impl =makeImpl (this ,XSub ,privY ,privW ,modelParams ,yLabels ,yLabelsOrig ); 
end
end


methods (Hidden )
function impl =makeImpl (this ,X ,privY ,privW ,modelParams ,yLabels ,yLabelsOrig )
isClassification =isa (this ,classreg .learning .fsutils .FeatureSelectionNCAModel .ClassificationSubClassName ); 
ifisClassification 
impl =classreg .learning .fsutils .FeatureSelectionNCAClassificationImpl (X ,privY ,privW ,modelParams ,yLabels ,yLabelsOrig ); 
else
impl =classreg .learning .fsutils .FeatureSelectionNCARegressionImpl (X ,privY ,privW ,modelParams ); 
end
impl =standardizeDataAndBuildModel (impl ); 
end
end


methods (Hidden )
function lossVals =cvLossVector (this ,cvp ,varargin )











numTestSets =cvp .NumTestSets ; 
lossVals =zeros (numTestSets ,1 ); 

fork =1 :numTestSets 

trainIdx =cvp .training (k ); 
XTrain =this .X (trainIdx ,:); 
YTrain =this .Y (trainIdx ,:); 
WTrain =this .W (trainIdx ,:); 


testIdx =cvp .test (k ); 
XTest =this .X (testIdx ,:); 
YTest =this .Y (testIdx ,:); 


modelParams =this .ModelParams ; 
modelParams .DoFit =true ; 
nca =doReFit (this ,XTrain ,YTrain ,WTrain ,modelParams ); 

lossVals (k )=loss (nca ,XTest ,YTest ,varargin {:}); 
end
end

function lossVals =cvLoss (this ,varargin )






























[cvp ,extraArgs ]=makeCVPartitionObject (this .Impl ,varargin {:}); 


lossVals =cvLossVector (this ,cvp ,extraArgs {:}); 
end
end


methods (Hidden ,Abstract )
[X ,PrivY ,PrivW ,YLabels ,YLabelsOrig ]=setupXYW (this ,X ,Y ,W )
end

methods (Hidden )
function modelParams =setupModelParams (this ,X ,PrivY ,varargin )


isClassification =isa (this ,classreg .learning .fsutils .FeatureSelectionNCAModel .ClassificationSubClassName ); 
ifisClassification 
method =classreg .learning .fsutils .FeatureSelectionNCAModel .MethodClassification ; 
else
method =classreg .learning .fsutils .FeatureSelectionNCAModel .MethodRegression ; 
end
modelParams =classreg .learning .fsutils .FeatureSelectionNCAParams (method ,X ,PrivY ,varargin {:}); 
end
end


methods (Static ,Hidden ,Abstract )
[yid ,labels ,labelsOrig ]=validateY (Y )
isok =checkYType (Y )
end

methods (Static ,Hidden )
function X =validateX (X )
isok =classreg .learning .fsutils .FeatureSelectionNCAModel .checkXType (X ); 
if~isok 
error (message ('stats:classreg:learning:fsutils:FeatureSelectionNCAModel:BadX' )); 
end
end

function isok =checkXType (X )
isok =isfloat (X )&&isreal (X )&&ismatrix (X ); 
end

function wobs =validateW (wobs )
[isok ,wobs ]=classreg .learning .fsutils .FeatureSelectionNCAParams .isNumericRealVectorNoNaNInf (wobs ,[]); 
isok =isok &&all (wobs >=0 ); 
if~isok 
error (message ('stats:classreg:learning:fsutils:FeatureSelectionNCAModel:BadWeights' )); 
end
end

function [X ,yid ,W ,badrows ]=removeBadRows (X ,yid ,W )
















badrowsX =any (isnan (X ),2 ); 


badrowsY =isnan (yid ); 


badrowsW =isnan (W ); 


if(isempty (W ))
badrows =badrowsX |badrowsY ; 
else
badrows =badrowsX |badrowsY |badrowsW ; 
end


X (badrows ,:)=[]; 
yid (badrows )=[]; 

if(~isempty (W ))
W (badrows )=[]; 
end
end

function T =convertToDouble (T )
if(~isa (T ,'double' ))
T =double (T ); 
end
end

function T =convertToSingle (T )
if(~isa (T ,'single' ))
T =single (T ); 
end
end
end
end