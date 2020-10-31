classdef Solver <classreg .learning .internal .DisallowVectorOps 



properties (Constant ,Hidden )
SolverLBFGS ='lbfgs' ; 
SolverSGD ='sgd' ; 
SolverMiniBatchLBFGS ='minibatch-lbfgs' ; 
BuiltInSolvers ={classreg .learning .fsutils .Solver .SolverLBFGS ,...
    classreg .learning .fsutils .Solver .SolverSGD ,...
    classreg .learning .fsutils .Solver .SolverMiniBatchLBFGS }; 

LineSearchMethodBacktracking ='backtracking' ; 
LineSearchMethodWeakWolfe ='weakwolfe' ; 
LineSearchMethodStrongWolfe ='strongwolfe' ; 
BuiltInLineSearchMethods ={classreg .learning .fsutils .Solver .LineSearchMethodBacktracking ,...
    classreg .learning .fsutils .Solver .LineSearchMethodWeakWolfe ,...
    classreg .learning .fsutils .Solver .LineSearchMethodStrongWolfe }; 
end

properties (Constant ,Hidden )
StringAuto ='auto' ; 
end

properties 
NumComponents ; 
SolverName ; 


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


Verbose ; 
IterationLimit ; 
StepTolerance ; 
HaveGradient ; 


MiniBatchLBFGSIterations ; 


InitialLearningRateForTuning ; 
ModificationFactorForTuning ; 
end

methods 
function this =Solver (N )











this =fillDefaultSolverOptions (this ,N ); 
end

function results =doMinimization (this ,fun ,x0 ,N ,varargin )


































































































































dfltOutputFcn =[]; 


names ={'OutputFcn' }; 
dflts ={dfltOutputFcn }; 
outfun =internal .stats .parseArgs (names ,dflts ,varargin {:}); 


if(~isempty (outfun ))
assert (isa (outfun ,'function_handle' )); 
end
assert (N ==this .NumComponents ); 


switchlower (this .SolverName )
case lower (this .SolverLBFGS )
results =doMinimizationLBFGS (this ,fun ,x0 ,outfun ); 
case {lower (this .SolverSGD ),lower (this .SolverMiniBatchLBFGS )}
results =doMinimizationSGD (this ,fun ,x0 ,outfun ); 
end
end
end

methods (Hidden )
function this =fillDefaultSolverOptions (this ,N )

if(N >1000 )
dfltSolverName =this .SolverSGD ; 
else
dfltSolverName =this .SolverLBFGS ; 
end


dfltHessianHistorySize =15 ; 
dfltInitialStepSize =this .StringAuto ; 
dfltLineSearchMethod =this .LineSearchMethodWeakWolfe ; 
dfltMaxLineSearchIterations =20 ; 
dfltGradientTolerance =1e-6 ; 


dfltInitialLearningRate =this .StringAuto ; 
dfltMiniBatchSize =min (10 ,N ); 
dfltPassLimit =5 ; 
dfltNumPrint =10 ; 
dfltNumTuningIterations =20 ; 
dfltTuningSubsetSize =min (100 ,N ); 


dfltIterationLimit =1000 ; 
dfltStepTolerance =1e-6 ; 


dfltMiniBatchLBFGSIterations =10 ; 


dfltVerbose =0 ; 


dfltHaveGradient =false ; 


dfltInitialLearningRateForTuning =0.1 ; 
dfltModificationFactorForTuning =2 ; 


this .NumComponents =N ; 
this .SolverName =dfltSolverName ; 
this .HessianHistorySize =dfltHessianHistorySize ; 
this .InitialStepSize =dfltInitialStepSize ; 
this .LineSearchMethod =dfltLineSearchMethod ; 
this .MaxLineSearchIterations =dfltMaxLineSearchIterations ; 
this .GradientTolerance =dfltGradientTolerance ; 
this .InitialLearningRate =dfltInitialLearningRate ; 
this .MiniBatchSize =dfltMiniBatchSize ; 
this .PassLimit =dfltPassLimit ; 
this .NumPrint =dfltNumPrint ; 
this .NumTuningIterations =dfltNumTuningIterations ; 
this .TuningSubsetSize =dfltTuningSubsetSize ; 
this .IterationLimit =dfltIterationLimit ; 
this .StepTolerance =dfltStepTolerance ; 
this .MiniBatchLBFGSIterations =dfltMiniBatchLBFGSIterations ; 
this .Verbose =dfltVerbose ; 
this .HaveGradient =dfltHaveGradient ; 
this .InitialLearningRateForTuning =dfltInitialLearningRateForTuning ; 
this .ModificationFactorForTuning =dfltModificationFactorForTuning ; 


if(strcmpi (this .InitialStepSize ,this .StringAuto ))
this .InitialStepSize =[]; 
end

if(strcmpi (this .InitialLearningRate ,this .StringAuto ))
this .InitialLearningRate =[]; 
end
end

function opts =getLBFGSOptions (this )
opts =struct (); 
opts .TolFun =this .GradientTolerance ; 
opts .TolX =this .StepTolerance ; 
opts .MaxIter =this .IterationLimit ; 

ifthis .HaveGradient 
opts .GradObj ='on' ; 
else
opts .GradObj ='off' ; 
end

if(this .Verbose >0 )
opts .Display ='iter' ; 
else
opts .Display ='off' ; 
end
end

function step =initialStepForLBFGS (this ,x0 )
step =this .InitialStepSize ; 
if(isempty (step ))
step =norm (x0 ,Inf )*0.5 +0.1 ; 
end
end

function results =doMinimizationLBFGS (this ,fun ,x0 ,outfun )

step =initialStepForLBFGS (this ,x0 ); 


memory =this .HessianHistorySize ; 
linesearch =this .LineSearchMethod ; 
maxlinesearchiter =this .MaxLineSearchIterations ; 


opts =getLBFGSOptions (this ); 


if(this .Verbose >0 )
fprintf ('\n o Solver = LBFGS, HessianHistorySize = %d, LineSearchMethod = %s\n' ,memory ,linesearch ); 
end

[xHat ,fHat ,gHat ,cause ]=classreg .learning .fsutils .fminlbfgs (fun ,x0 ,'Memory' ,memory ,'Step' ,step ,...
    'LineSearch' ,linesearch ,'MaxLineSearchIter' ,maxlinesearchiter ,...
    'Options' ,opts ,'OutputFcn' ,outfun ); 


if(cause ~=0 &&cause ~=1 )
warning (message ('stats:classreg:learning:fsutils:Solver:LBFGSUnableToConverge' )); 
end


results =struct (); 
results .xHat =xHat ; 
results .fHat =fHat ; 
results .gHat =gHat ; 
results .cause =cause ; 
end

function opts =getSGDOptions (this )
opts =struct (); 
opts .TolX =this .StepTolerance ; 
opts .MaxIter =this .IterationLimit ; 

ifthis .HaveGradient 
opts .GradObj ='on' ; 
else
opts .GradObj ='off' ; 
end

if(this .Verbose >0 )
opts .Display ='iter' ; 
else
opts .Display ='off' ; 
end
end

function results =doMinimizationSGD (this ,fun ,x0 ,outfun )

miniBatchSize =this .MiniBatchSize ; 
passLimit =this .PassLimit ; 
numPrint =this .NumPrint ; 


opts =getSGDOptions (this ); 


N =this .NumComponents ; 
initialLearningRate =this .InitialLearningRate ; 

if(isempty (initialLearningRate ))
numTuningIterations =this .NumTuningIterations ; 
tuningSubsetSize =this .TuningSubsetSize ; 
verbose =this .Verbose >0 ; 
passLimitForTuning =1 ; 
initialLearningRateForTuning =this .InitialLearningRateForTuning ; 
modificationFactorForTuning =this .ModificationFactorForTuning ; 
initialLearningRate =classreg .learning .fsutils .Solver .tuneInitialLearningRate (fun ,x0 ,N ,miniBatchSize ,passLimitForTuning ,numPrint ,opts ,numTuningIterations ,tuningSubsetSize ,verbose ,...
    initialLearningRateForTuning ,modificationFactorForTuning ); 
end



iterPerPass =ceil (N /miniBatchSize ); 


learnFcn =@(k )initialLearningRate /(floor (k /iterPerPass )+1 ); 


if(strcmpi (this .SolverName ,this .SolverMiniBatchLBFGS ))
usingMiniBatchLBFGS =true ; 
else
usingMiniBatchLBFGS =false ; 
end



ifusingMiniBatchLBFGS 
step =initialStepForLBFGS (this ,x0 ); 
memory =this .HessianHistorySize ; 
linesearch =this .LineSearchMethod ; 
maxlinesearchiter =this .MaxLineSearchIterations ; 
optsLBFGS =getLBFGSOptions (this ); 
if(this .Verbose >1 )
optsLBFGS .Display ='iter' ; 
else
optsLBFGS .Display ='off' ; 
end
optsLBFGS .MaxIter =this .MiniBatchLBFGSIterations ; 

updatefun =@(hfcn ,myx )classreg .learning .fsutils .fminlbfgs (hfcn ,myx ,'Memory' ,memory ,'Step' ,step ,...
    'LineSearch' ,linesearch ,'MaxLineSearchIter' ,maxlinesearchiter ,...
    'Options' ,optsLBFGS ); 
else
updatefun =[]; 
end


if(this .Verbose >0 )
ifusingMiniBatchLBFGS 
fprintf ('\n o Solver = MiniBatchLBFGS, MiniBatchSize = %d, PassLimit = %d\n' ,miniBatchSize ,passLimit ); 
else
fprintf ('\n o Solver = SGD, MiniBatchSize = %d, PassLimit = %d\n' ,miniBatchSize ,passLimit ); 
end
end

[xHat ,cause ]=classreg .learning .fsutils .fminsgd (fun ,x0 ,N ,'MiniBatchSize' ,miniBatchSize ,...
    'MaxPasses' ,passLimit ,'LearnFcn' ,learnFcn ,...
    'NumPrint' ,numPrint ,'Options' ,opts ,'OutputFcn' ,outfun ,'UpdateFcn' ,updatefun ); 





results =struct (); 
results .xHat =xHat ; 
results .cause =cause ; 
end
end

methods (Static ,Hidden )
function etaBest =tuneInitialLearningRate (fun ,x0 ,N ,miniBatchSize ,passLimit ,numPrint ,opts ,numTuningIterations ,tuningSubsetSize ,verbose ,initialLearningRateForTuning ,modificationFactorForTuning )



M =tuningSubsetSize ; 
testfunForFit =classreg .learning .fsutils .Solver .makeTestFunctionToTuneLearningRate (fun ,N ,M ); 
testfun =classreg .learning .fsutils .Solver .makeTestFunctionToTuneLearningRate (fun ,N ,M ); 


factor =modificationFactorForTuning ; 
etaLo =initialLearningRateForTuning ; 
etaHi =factor *etaLo ; 


opts .Display ='off' ; 


sgdfun =@(myeta )classreg .learning .fsutils .fminsgd (testfunForFit ,x0 ,M ,'Options' ,opts ,'MiniBatchSize' ,min (miniBatchSize ,M ),...
    'NumPrint' ,numPrint ,'MaxPasses' ,passLimit ,'LearnFcn' ,@(k )myeta ); 


wLo =sgdfun (etaLo ); 
fLo =testfun (wLo ); 

wHi =sgdfun (etaHi ); 
fHi =testfun (wHi ); 


etaBest =etaLo ; 
fBest =fLo ; 


ifverbose 
tuningMessageStr =getString (message ('stats:classreg:learning:fsutils:Solver:Message_TuningLearningRate' )); 
fprintf (['\n o ' ,tuningMessageStr ,' NumTuningIterations = %d, TuningSubsetSize = %d\n' ],numTuningIterations ,tuningSubsetSize ); 
end

fori =1 :numTuningIterations 
if(fLo <fHi )
etaHi =etaLo ; 
fHi =fLo ; 

if(fLo <fBest )
fBest =fLo ; 
etaBest =etaLo ; 
end

etaLo =etaLo /factor ; 

wLo =sgdfun (etaLo ); 
fLo =testfun (wLo ); 
else
etaLo =etaHi ; 
fLo =fHi ; 

if(fHi <fBest )
fBest =fHi ; 
etaBest =etaHi ; 
end

etaHi =factor *etaHi ; 

wHi =sgdfun (etaHi ); 
fHi =testfun (wHi ); 
end

ifverbose 
if(rem (i ,20 )==1 )
fprintf ('\n' ); 
fprintf ('|===============================================|\n' ); 
fprintf ('|    TUNING    | TUNING SUBSET |    LEARNING    |\n' ); 
fprintf ('|     ITER     |   FUN VALUE   |      RATE      |\n' ); 
fprintf ('|===============================================|\n' ); 
end
fprintf ('|%13d |%14.6e |%15.6e |\n' ,i ,fBest ,etaBest ); 
end
end
end

function z =makeTestFunctionToTuneLearningRate (fun ,N ,M )



idx =randsample (N ,M ); 
idx =idx ' ; 




z =@tunefun ; 
function [f ,g ]=tunefun (w ,S )

if(nargin <2 )
[f ,g ]=fun (w ,idx ); 
else
[f ,g ]=fun (w ,idx (S )); 
end
end
end

function g =getGradient (fun ,theta ,step )








if(nargin <3 )
step =eps ^(1 /3 ); 
end


p =length (theta ); 
g =zeros (p ,1 ); 

fori =1 :p 

theta1 =theta ; 
theta1 (i )=theta1 (i )-step ; 

theta2 =theta ; 
theta2 (i )=theta2 (i )+step ; 

g (i )=(fun (theta2 )-fun (theta1 ))/2 /step ; 
end


g =classreg .learning .fsutils .Solver .replaceInf (g ,realmax ); 
end

function B =replaceInf (B ,value )







assert (isnumeric (B )&ismatrix (B )); 
assert (isnumeric (value )&isscalar (value )); 


absvalue =abs (value ); 


isinfB =isinf (B ); 


B (isinfB &B >0 )=absvalue ; 


B (isinfB &B <0 )=-absvalue ; 
end
end

end