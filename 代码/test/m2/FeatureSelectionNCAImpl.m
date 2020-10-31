classdef (Abstract )FeatureSelectionNCAImpl <classreg .learning .internal .DisallowVectorOps 




properties 
FitInfo ; 
FeatureWeights ; 
Mu ; 
Sigma ; 
end

properties 






IsFitted ; 





Partition ; 







PrivObservationWeights ; 
end


properties (Dependent )
X ; 
W ; 
ModelParameters ; 
end

properties 
PrivX ; 
PrivW ; 
ModelParams ; 
end

properties (Abstract ,Dependent )
Y ; 
end

properties (Abstract )
PrivY ; 
end

properties (Dependent )
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
NumFeatures ; 
end


methods 
function X =get .X (this )
if(this .ModelParams .Standardize &&~isempty (this .Mu )&&~isempty (this .Sigma ))
sigmaX =this .Sigma ; 
muX =this .Mu ; 
X =bsxfun (@plus ,bsxfun (@times ,this .PrivX ,sigmaX (:)' ),muX (:)' ); 
else
X =this .PrivX ; 
end
end

function W =get .W (this )
W =this .PrivW ; 
end

function mp =get .ModelParameters (this )
mp =this .ModelParams ; 
end

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


methods 
function this =FeatureSelectionNCAImpl (X ,privW ,modelParams )


this .PrivX =X ; 
this .PrivW =privW ; 
this .ModelParams =modelParams ; 

this .IsFitted =false ; 
this .Mu =[]; 
this .Sigma =[]; 
end
end


methods (Abstract )
fun =makeObjectiveFunctionForMinimization (this )
fun =makeObjectiveFunctionForMinimizationMex (this )
end


methods 
function fun =makeRegularizedObjectiveFunctionForMinimizationRobustMex (this ,X ,y ,lossID ,epsilon )













































lambda =this .ModelParams .Lambda ; 
sigma =this .ModelParams .LengthScale ; 
obswts =this .PrivObservationWeights ; 
grainsize =this .ModelParams .GrainSize ; 
[P ,N ]=size (X ); 
allpoints =1 :N ; 



if(isa (lossID ,'function_handle' ))
lossFcn =lossID ; 
lossID =classreg .learning .fsutils .FeatureSelectionNCAModel .CUSTOM_LOSS ; 
else
lossFcn =[]; 
end




if(isa (X ,'double' ))
convertToDoubleFcn =@(xx )full (classreg .learning .fsutils .FeatureSelectionNCAModel .convertToDouble (xx )); 

y =convertToDoubleFcn (y ); 
P =convertToDoubleFcn (P ); 
N =convertToDoubleFcn (N ); 
allpoints =convertToDoubleFcn (allpoints ); 
lambda =convertToDoubleFcn (lambda ); 
sigma =convertToDoubleFcn (sigma ); 
obswts =convertToDoubleFcn (obswts ); 
lossID =convertToDoubleFcn (lossID ); 
epsilon =convertToDoubleFcn (epsilon ); 
grainsize =convertToDoubleFcn (grainsize ); 
haveDoubleInput =true ; 
elseif(isa (X ,'single' ))
convertToSingleFcn =@(xx )full (classreg .learning .fsutils .FeatureSelectionNCAModel .convertToSingle (xx )); 

y =convertToSingleFcn (y ); 
P =convertToSingleFcn (P ); 
N =convertToSingleFcn (N ); 
allpoints =convertToSingleFcn (allpoints ); 
lambda =convertToSingleFcn (lambda ); 
sigma =convertToSingleFcn (sigma ); 
obswts =convertToSingleFcn (obswts ); 
lossID =convertToSingleFcn (lossID ); 
epsilon =convertToSingleFcn (epsilon ); 
grainsize =convertToSingleFcn (grainsize ); 
haveDoubleInput =false ; 
else
error (message ('stats:classreg:learning:fsutils:FeatureSelectionNCAModel:UnSupportedXType' )); 
end

fun =@ncfsobj ; 
function [obj ,gradobj ]=ncfsobj (w ,T )


if(nargin <2 )
T =allpoints ; 
elseif(~issorted (T ))
T =sort (T ); 
end
M =length (T ); 

ifhaveDoubleInput 
T =convertToDoubleFcn (T ); 
M =convertToDoubleFcn (M ); 
w =convertToDoubleFcn (w ); 
else
T =convertToSingleFcn (T ); 
M =convertToSingleFcn (M ); 
w =convertToSingleFcn (w ); 
end


if(nargout >1 )
wantgrad =true ; 
else
wantgrad =false ; 
end


if(isempty (lossFcn ))

ifhaveDoubleInput 
lossMat =NaN ('double' ); 
else
lossMat =NaN ('single' ); 
end
ifwantgrad 
[obj ,gradobj ]=classreg .learning .fsutils .objgrad (X ,y ,P ,N ,T (:),M ,lambda ,sigma ,w ,lossID ,epsilon ,grainsize ,lossMat ,obswts ); 
else
obj =classreg .learning .fsutils .objgrad (X ,y ,P ,N ,T (:),M ,lambda ,sigma ,w ,lossID ,epsilon ,grainsize ,lossMat ,obswts ); 
end
else

classX =class (X ); 
obj =zeros (1 ,1 ,classX ); 
ifwantgrad 
gradobj =zeros (P ,1 ,classX ); 
end







cacheSizeMB =this .ModelParams .CacheSize ; 
B =max (1 ,floor (cacheSizeMB *1e6 /(8 *N ))); 
numchunks =floor (M /B ); 

forc =1 :(numchunks +1 )
if(c <numchunks +1 )

idx =(c -1 )*B +1 :c *B ; 
else

idx =numchunks *B +1 :M ; 
end

if(~isempty (idx ))
Tc =T (idx ); 
Mc =length (Tc ); 
lossMat =lossFcn (y ,y (Tc (:))); 

isok =all (size (lossMat )==[N ,Mc ]); 
if~isok 
error (message ('stats:classreg:learning:fsutils:FeatureSelectionNCAModel:BadCustomLossFunctionResult' )); 
end

ifhaveDoubleInput 
lossMat =convertToDoubleFcn (lossMat ); 
Tc =convertToDoubleFcn (Tc ); 
Mc =convertToDoubleFcn (Mc ); 
else
lossMat =convertToSingleFcn (lossMat ); 
Tc =convertToSingleFcn (Tc ); 
Mc =convertToSingleFcn (Mc ); 
end

ifwantgrad 
[objc ,gradobjc ]=classreg .learning .fsutils .objgrad (X ,y ,P ,N ,Tc (:),Mc ,lambda ,sigma ,w ,lossID ,epsilon ,grainsize ,lossMat ,obswts ); 
obj =obj +objc *Mc ; 
gradobj =gradobj +gradobjc *Mc ; 
else
objc =classreg .learning .fsutils .objgrad (X ,y ,P ,N ,Tc (:),Mc ,lambda ,sigma ,w ,lossID ,epsilon ,grainsize ,lossMat ,obswts ); 
obj =obj +objc *Mc ; 
end
end
end

obj =obj /M ; 
ifwantgrad 
gradobj =gradobj /M ; 
end
end
end
end

function fun =makeRegularizedObjectiveFunctionForMinimizationRobust (this ,X ,y ,lossFcn )






































lambda =this .ModelParams .Lambda ; 
sigma =this .ModelParams .LengthScale ; 
[P ,N ]=size (X ); 
allpoints =1 :N ; 
obswts =this .PrivObservationWeights ' ; 


if(isa (X ,'double' ))
convertToDoubleFcn =@(xx )classreg .learning .fsutils .FeatureSelectionNCAModel .convertToDouble (xx ); 

y =convertToDoubleFcn (y ); 
P =convertToDoubleFcn (P ); 
N =convertToDoubleFcn (N ); 
allpoints =convertToDoubleFcn (allpoints ); 
lambda =convertToDoubleFcn (lambda ); 
sigma =convertToDoubleFcn (sigma ); 
obswts =convertToDoubleFcn (obswts ); 
haveDoubleInput =true ; 
elseif(isa (X ,'single' ))
convertToSingleFcn =@(xx )classreg .learning .fsutils .FeatureSelectionNCAModel .convertToSingle (xx ); 

y =convertToSingleFcn (y ); 
P =convertToSingleFcn (P ); 
N =convertToSingleFcn (N ); 
allpoints =convertToSingleFcn (allpoints ); 
lambda =convertToSingleFcn (lambda ); 
sigma =convertToSingleFcn (sigma ); 
obswts =convertToSingleFcn (obswts ); 
haveDoubleInput =false ; 
else
error (message ('stats:classreg:learning:fsutils:FeatureSelectionNCAModel:UnSupportedXType' )); 
end

fun =@ncfsobj ; 
function [obj ,gradobj ]=ncfsobj (w ,T )


if(nargin <2 )
T =allpoints ; 
elseif(~issorted (T ))
T =sort (T ); 
end
M =length (T ); 

ifhaveDoubleInput 
T =convertToDoubleFcn (T ); 
M =convertToDoubleFcn (M ); 
w =convertToDoubleFcn (w ); 
else
T =convertToSingleFcn (T ); 
M =convertToSingleFcn (M ); 
w =convertToSingleFcn (w ); 
end


if(nargout >1 )
wantgrad =true ; 
else
wantgrad =false ; 
end


classX =class (X ); 
obj =zeros (1 ,1 ,classX ); 
ifwantgrad 
gradobj =zeros (P ,1 ,classX ); 
end






wsquared =w .^2 ; 

fori =T 

xi =X (:,i ); 
yi =y (i ); 






dist =abs (bsxfun (@minus ,X ,xi )); 






wtdDist =sum (bsxfun (@times ,dist ,wsquared ),1 ); 
wtdDist (i )=inf (classX ); 
wtdDist =wtdDist -min (wtdDist ); 


pij =obswts .*exp (-wtdDist /sigma ); 
pij =pij /sum (pij ); 


lossMat =lossFcn (yi ,y ); 
isok =all (size (lossMat )==[1 ,N ]); 
if~isok 
error (message ('stats:classreg:learning:fsutils:FeatureSelectionNCAModel:BadCustomLossFunctionResult' )); 
end
pijlij =pij .*lossMat ; 


li =sum (pijlij ); 


obj =obj +li ; 



ifwantgrad 
g =sum (bsxfun (@times ,li *pij -pijlij ,dist ),2 ); 
gradobj =gradobj +g ; 
end
end
obj =obj /M ; 
ifwantgrad 
gradobj =((2 *w /sigma ).*gradobj )/M ; 
end


obj =obj +lambda *sum (wsquared ); 
ifwantgrad 
gradobj =gradobj +2 *lambda *w ; 
end
end
end
end


methods 
function XTest =applyStandardizationToXTest (this ,XTest )
if(this .ModelParams .Standardize &&~isempty (this .Mu )&&~isempty (this .Sigma ))
XTest =bsxfun (@rdivide ,bsxfun (@minus ,XTest ,this .Mu ' ),this .Sigma ' ); 
end
end

function this =standardizeData (this )
ifthis .ModelParams .Standardize 
[this .PrivX ,muX ,sigmaX ]=classreg .learning .gputils .standardizeData (this .X ); 
this .Mu =muX ; 
this .Sigma =sigmaX ; 
else
this .Mu =[]; 
this .Sigma =[]; 
end
end

function this =standardizeDataAndBuildModel (this )
this =standardizeData (this ); 
this =buildModel (this ); 
end

function this =buildModel (this )






this .PrivObservationWeights =effectiveObservationWeights (this ,this .PrivW ,this .ModelParams .Prior ); 


if(this .ModelParams .DoFit ==false )
this .FeatureWeights =abs (this .ModelParams .InitialFeatureWeights ); 
this .FitInfo =[]; 
this .IsFitted =false ; 
else
switchlower (this .ModelParams .FitMethod )
case lower (classreg .learning .fsutils .FeatureSelectionNCAModel .FitMethodNone )
this =buildModelNone (this ); 

case lower (classreg .learning .fsutils .FeatureSelectionNCAModel .FitMethodExact )
this =buildModelExact (this ); 

case lower (classreg .learning .fsutils .FeatureSelectionNCAModel .FitMethodDivideAndConquer )
this =buildModelDivideAndConquer (this ); 
end
this .IsFitted =true ; 
end
end

function this =buildModelDivideAndConquer (this )

cvp =makeCVPartitionObject (this ,'kfold' ,this .ModelParams .NumPartitions ); 


numChunks =cvp .NumTestSets ; 
P =this .NumFeatures ; 
featureWeights =zeros (P ,numChunks ); 
fitInfo =cell (numChunks ,1 ); 


fork =1 :numChunks 

testIdx =cvp .test (k ); 
XTest =this .X (testIdx ,:); 
YTest =this .PrivY (testIdx ,:); 
WTest =this .PrivW (testIdx ,:); 




modelParams =this .ModelParams ; 
modelParams .DoFit =true ; 
modelParams .NumObservations =size (XTest ,1 ); 
modelParams .FitMethod =classreg .learning .fsutils .FeatureSelectionNCAModel .FitMethodExact ; 

nca =this ; 
nca .PrivX =XTest ; 
nca .PrivY =YTest ; 
nca .PrivW =WTest ; 
nca .ModelParams =modelParams ; 
nca .Mu =[]; 
nca .Sigma =[]; 
nca =standardizeDataAndBuildModel (nca ); 


featureWeights (:,k )=nca .FeatureWeights ; 


fitInfo {k }=nca .FitInfo ; 
end


this .FeatureWeights =featureWeights ; 
this .FitInfo =cell2mat (fitInfo ); 


this .Partition =cvp ; 
end

function this =buildModelNone (this )

this .FeatureWeights =abs (this .ModelParams .InitialFeatureWeights ); 
this .FitInfo =[]; 
end

function this =buildModelExact (this )

computationMode =this .ModelParams .ComputationMode ; 
usemex =strcmpi (computationMode ,classreg .learning .fsutils .FeatureSelectionNCAModel .ComputationModeMex ); 
ifusemex 
fun =makeObjectiveFunctionForMinimizationMex (this ); 
else
fun =makeObjectiveFunctionForMinimization (this ); 
end


w0 =this .ModelParams .InitialFeatureWeights ; 


[wHat ,fitInfo ]=doMinimization (this ,fun ,w0 ); 


this .FeatureWeights =abs (wHat ); 
this .FitInfo =fitInfo ; 
end

function [wHat ,fitInfo ]=doMinimization (this ,fun ,w0 )















haveLBFGS =strcmpi (this .ModelParams .Solver ,classreg .learning .fsutils .FeatureSelectionNCAModel .SolverLBFGS ); 
ifhaveLBFGS 
haveSGD =false ; 
else
haveSGD =true ; 
end


N =this .NumObservations ; 
solver =classreg .learning .fsutils .Solver (N ); 



solver .NumComponents =N ; 
solver .SolverName =this .ModelParams .Solver ; 
solver .HessianHistorySize =this .ModelParams .HessianHistorySize ; 
solver .InitialStepSize =this .ModelParams .InitialStepSize ; 
solver .LineSearchMethod =this .ModelParams .LineSearchMethod ; 
solver .MaxLineSearchIterations =this .ModelParams .MaxLineSearchIterations ; 
solver .GradientTolerance =this .ModelParams .GradientTolerance ; 
solver .InitialLearningRate =this .ModelParams .InitialLearningRate ; 
solver .MiniBatchSize =this .ModelParams .MiniBatchSize ; 
solver .PassLimit =this .ModelParams .PassLimit ; 
solver .NumPrint =this .ModelParams .NumPrint ; 
solver .NumTuningIterations =this .ModelParams .NumTuningIterations ; 
solver .TuningSubsetSize =this .ModelParams .TuningSubsetSize ; 
solver .IterationLimit =this .ModelParams .IterationLimit ; 
solver .StepTolerance =this .ModelParams .StepTolerance ; 
solver .MiniBatchLBFGSIterations =this .ModelParams .MiniBatchLBFGSIterations ; 
solver .Verbose =this .ModelParams .Verbose ; 
solver .HaveGradient =true ; 


lambda =this .ModelParams .Lambda ; 








history =struct (); 
history .fval =[]; 
history .iter =[]; 
history .acc =[]; 
history .grad =[]; 


function stop =outfun (x ,optimValues ,state )
history .iter =[history .iter ; optimValues .iteration ]; 
history .fval =[history .fval ; optimValues .fval ]; 
history .acc =[history .acc ; optimValues .fval -lambda *(x ' *x )]; 
stop =false ; 
if(haveSGD &&strcmpi (state ,'done' ))
history .grad =optimValues .gradient ; 
end
end


results =doMinimization (solver ,fun ,w0 ,N ,'OutputFcn' ,@outfun ); 


wHat =results .xHat ; 


fitInfo =struct (); 
fitInfo .Iteration =history .iter ; 
fitInfo .Objective =history .fval ; 
fitInfo .UnregularizedObjective =history .acc ; 

ifhaveSGD 
fitInfo .Gradient =history .grad ; 
else
fitInfo .Gradient =results .gHat ; 
end
end
end


methods 
function [cvp ,extraArgs ]=makeCVPartitionObject (this ,varargin )























dfltKFold =10 ; 
dfltHoldout =[]; 
dfltLeaveout =[]; 
dfltCVPartition =[]; 


paramNames ={'KFold' ,'Holdout' ,'Leaveout' ,'CVPartition' }; 
paramDflts ={dfltKFold ,dfltHoldout ,dfltLeaveout ,dfltCVPartition }; 
[kfold ,holdout ,leaveout ,cvp ,setflag ,extraArgs ]=internal .stats .parseArgs (paramNames ,paramDflts ,varargin {:}); 



N =this .NumObservations ; 

if(~isempty (leaveout ))
leaveout =internal .stats .getParamVal (leaveout ,{'on' ,'off' },'Leaveout' ); 
end

if(~isempty (cvp ))
isok =isa (cvp ,'cvpartition' )&&(cvp .NumObservations ==N ); 
if~isok 
error (message ('stats:classreg:learning:fsutils:FeatureSelectionNCAModel:BadCVPartition' ,N )); 
end
end


numSupplied =setflag .KFold +setflag .Holdout +setflag .Leaveout +setflag .CVPartition ; 
if(numSupplied >1 )
error (message ('stats:classreg:learning:fsutils:FeatureSelectionNCAModel:BadCVSelection' )); 
end


ifsetflag .Holdout 

if(strcmpi (this .ModelParams .Method ,classreg .learning .fsutils .FeatureSelectionNCAModel .MethodClassification ))
cvp =cvpartition (this .PrivY ,'HoldOut' ,holdout ); 
else
cvp =cvpartition (N ,'HoldOut' ,holdout ); 
end
elseif(setflag .Leaveout &&strcmpi (leaveout ,'on' ))

cvp =cvpartition (N ,'LeaveOut' ); 
elseifsetflag .CVPartition 

else

if(strcmpi (this .ModelParams .Method ,classreg .learning .fsutils .FeatureSelectionNCAModel .MethodClassification ))
cvp =cvpartition (this .PrivY ,'KFold' ,kfold ); 
else
cvp =cvpartition (N ,'KFold' ,kfold ); 
end
end
end
end


methods (Abstract )
effobswts =effectiveObservationWeights (this ,obswts ,prior )
end


methods (Abstract )
output =predictNCAMex (this ,XTest )
output =predictNCA (this ,XTest )
end

end

