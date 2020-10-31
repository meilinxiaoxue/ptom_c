classdef LinearImpl 



properties (GetAccess =public ,SetAccess =protected )
BatchIndex =[]; 
BatchLimit =[]; 
BatchSize =[]; 
Beta =[]; 
Bias =[]; 
Consensus =[]; 
FitInfo =[]; 
Epsilon =[]; 
HessianHistorySize =[]; 
IterationLimit =[]; 
Lambda =[]; 
LearnRate =[]; 
LineSearch ='backtrack' ; 
LossFunction =[]; 
NumPredictors =[]; 
NumCheckConvergence =[]; 
OptimizeLearnRate =[]; 
OptimalLearnRate =[]; 
PassLimit =[]; 
PostFitBias =[]; 
Ridge =[]; 
Solver =[]; 
Stream =[]; 
TruncationPeriod =[]; 
VerbosityLevel =[]; 
end

methods (Access =protected )
function this =LinearImpl ()
end
end

methods 
function F =score (this ,X ,doclass ,obsInRows )


if~isfloat (X )||~ismatrix (X )
error (message ('stats:classreg:learning:impl:LinearImpl:score:BadX' )); 
end
internal .stats .checkSupportedNumeric ('X' ,X ,false ,true ); 

beta =this .Beta ; 
bias =this .Bias ; 

ifobsInRows 
[N ,D ]=size (X ); 
else
[D ,N ]=size (X ); 
end

ifisempty (beta )
L =numel (this .Lambda ); 
ifdoclass 
F =NaN (N ,L ,'like' ,bias ); 
else
F =zeros (N ,L ,'like' ,bias )+bias ; 
end
return ; 
end

ifD ~=this .NumPredictors 
ifobsInRows 
str =getString (message ('stats:classreg:learning:impl:LinearImpl:score:columns' )); 
else
str =getString (message ('stats:classreg:learning:impl:LinearImpl:score:rows' )); 
end
error (message ('stats:classreg:learning:impl:LinearImpl:score:BadXSize' ,...
    this .NumPredictors ,str )); 
end

ifisa (X ,'double' )&&isa (bias ,'single' )
X =single (X ); 
end

ifobsInRows 
F =bsxfun (@plus ,X *beta ,bias ); 
else
F =bsxfun (@plus ,(beta ' *X )' ,bias ); 
end
end

function this =selectModels (this ,idx )
if~isnumeric (idx )||~isvector (idx )||~isreal (idx )||any (idx (:)<0 )...
    ||any (round (idx )~=idx )||any (idx (:)>numel (this .Lambda ))
error (message ('stats:classreg:learning:impl:LinearImpl:selectModels:BadIdx' ,...
    numel (this .Lambda ))); 
end

this .Lambda =this .Lambda (idx ); 
this .Beta =this .Beta (:,idx ); 
this .Bias =this .Bias (idx ); 
end

function s =toStruct (this )


warnState =warning ('query' ,'all' ); 
warning ('off' ,'MATLAB:structOnObject' ); 
cleanupObj =onCleanup (@()warning (warnState )); 

s =struct (this ); 


fitinfo =s .FitInfo ; 
fitinfo .History =[]; 



fitinfo =rmfield (fitinfo ,'TerminationStatus' ); 

s .FitInfo =fitinfo ; 


if~isempty (s .Stream )
s .Stream =get (s .Stream ); 
end


solver =s .Solver ; 
if~isrow (solver )
solver =solver (:)' ; 
end
s .SolverNamesLength =cellfun (@length ,solver ); 
s .SolverNames =char (solver ' ); 
s =rmfield (s ,'Solver' ); 
end
end

methods (Static )
function obj =fromStruct (s )


obj =classreg .learning .impl .LinearImpl ; 

obj .BatchIndex =s .BatchIndex ; 
obj .BatchLimit =s .BatchLimit ; 
obj .BatchSize =s .BatchSize ; 
obj .Beta =s .Beta ; 
obj .Bias =s .Bias ; 

ifisfield (s ,'Consensus' )
obj .Consensus =s .Consensus ; 
else
obj .Consensus =0 ; 
end

fitinfo =s .FitInfo ; 
fitinfo .TerminationStatus =terminationStatus (fitinfo .TerminationCode ); 
obj .FitInfo =fitinfo ; 

obj .Epsilon =s .Epsilon ; 
obj .HessianHistorySize =s .HessianHistorySize ; 
obj .IterationLimit =s .IterationLimit ; 
obj .Lambda =s .Lambda ; 
obj .LearnRate =s .LearnRate ; 
obj .LineSearch =s .LineSearch ; 
obj .LossFunction =s .LossFunction ; 
obj .NumPredictors =s .NumPredictors ; 
obj .NumCheckConvergence =s .NumCheckConvergence ; 
obj .OptimizeLearnRate =s .OptimizeLearnRate ; 
obj .OptimalLearnRate =s .OptimalLearnRate ; 
obj .PassLimit =s .PassLimit ; 
obj .PostFitBias =s .PostFitBias ; 
obj .Ridge =s .Ridge ; 

obj .Solver =cellstr (s .SolverNames )' ; 
obj .Solver =arrayfun (@(x ,y )x {1 }(1 :y ),...
    obj .Solver ,s .SolverNamesLength ,...
    'UniformOutput' ,false ); 

if~isempty (s .Stream )
obj .Stream =RandStream (s .Stream .Type ); 
set (obj .Stream ,s .Stream ); 
else
obj .Stream =[]; 
end

obj .TruncationPeriod =s .TruncationPeriod ; 
obj .VerbosityLevel =s .VerbosityLevel ; 
end

function this =makeNoFit (param ,Beta ,Bias ,fitinfo )


this =classreg .learning .impl .LinearImpl ; 

this .HessianHistorySize =param .HessianHistorySize ; 
this .IterationLimit =param .IterationLimit ; 
this .Lambda =param .Lambda ; 
this .LineSearch =param .LineSearch ; 
this .LossFunction =param .LossFunction ; 
this .PostFitBias =param .PostFitBias ; 
this .Ridge =strcmp (param .Regularization ,'ridge' ); 
this .Solver =param .Solver ; 
this .VerbosityLevel =param .VerbosityLevel ; 
this .Epsilon =param .Epsilon ; 

this .Beta =Beta ; 
this .Bias =Bias ; 
this .FitInfo =fitinfo ; 

end

function this =make (doclass ,...
    Beta0 ,Bias0 ,X ,y ,w ,lossfun ,doridge ,lambda ,maxpass ,maxbatch ,...
    nconv ,batchindex ,batchsize ,solvers ,betatol ,gradtol ,deltagradtol ,...
    gamma ,presolve ,valX ,valY ,valW ,maxiter ,truncationK ,...
    fitbias ,postfitbias ,epsilon ,historysize ,linesearch ,rho ,rsh ,verbose )






this =classreg .learning .impl .LinearImpl ; 

[D ,N ]=size (X ); 
clsname =class (X ); 

L =numel (lambda ); 
S =numel (solvers ); 

this .NumPredictors =D ; 

solvers =solvers (:)' ; 
dodual =ismember ('dual' ,solvers ); 
doduallast =strcmp ('dual' ,solvers (end)); 
dosgdlast =any (strcmp ({'sgd' ,'asgd' },solvers (end))); 
dononsgdlast =any (strcmp ({'bfgs' ,'lbfgs' ,'sparsa' },solvers (end))); 



passed_deltagradtol =deltagradtol ; 
ifisempty (deltagradtol )
deltagradtol =NaN ; 
end

ifisempty (batchindex )
batchindex =NaN (1 ,L ); 
end

ifisempty (batchsize )
batchsize =NaN ; 
end

passed_maxpass =maxpass ; 
ifisempty (maxpass )
maxpass =NaN ; 
end

passed_maxbatch =maxbatch ; 
ifisempty (maxbatch )
maxbatch =NaN ; 
end

passed_maxiter =maxiter ; 
ifisempty (maxiter )
maxiter =NaN ; 
end

ifisempty (gamma )
gamma =NaN ; 
end

passed_epsilon =epsilon ; 
ifisempty (epsilon )
epsilon =NaN ; 
end

ifisempty (truncationK )
truncationK =NaN ; 
end

ifisempty (nconv )
nconv =0 ; 
end

ifisempty (presolve )
presolve =false ; 
end

ifisempty (historysize )
historysize =NaN ; 
end

this .LossFunction =lossfun ; 
this .Ridge =doridge ; 
this .Lambda =lambda ; 
this .PassLimit =maxpass ; 
this .BatchLimit =maxbatch ; 
this .NumCheckConvergence =nconv ; 
this .BatchSize =batchsize ; 
this .Solver =solvers ; 
this .LearnRate =gamma ; 
this .OptimizeLearnRate =presolve ; 
this .IterationLimit =maxiter ; 
this .TruncationPeriod =truncationK ; 
this .PostFitBias =postfitbias ; 
this .Epsilon =passed_epsilon ; 
this .HessianHistorySize =historysize ; 
this .LineSearch =linesearch ; 
this .Consensus =rho ; 
this .Stream =rsh ; 
this .VerbosityLevel =verbose ; 

ifdoclass ==1 




ifstrcmp (lossfun ,'logit' )
this .Bias =Inf (1 ,L ,clsname ); 
elseifstrcmp (lossfun ,'hinge' )
this .Bias =ones (1 ,L ,clsname ); 
end

this .BatchIndex =zeros (1 ,L ); 
this .Beta =zeros (D ,L ,clsname ); 
this .OptimalLearnRate =repmat (gamma ,1 ,L ); 

fitInfo .Objective =zeros (1 ,L ,clsname ); 

ifdosgdlast ||doduallast 
fitInfo .PassLimit =passed_maxpass ; 
fitInfo .NumPasses =zeros (1 ,L ); 
fitInfo .BatchLimit =passed_maxbatch ; 
end

ifdosgdlast 
fitInfo .BatchIndex =zeros (1 ,L ); 
fitInfo .OptimalLearnRate =repmat (gamma ,1 ,L ); 
end

ifdononsgdlast 
fitInfo .IterationLimit =passed_maxiter ; 
end
fitInfo .NumIterations =zeros (1 ,L ); 

fitInfo .GradientNorm =[]; 
fitInfo .GradientTolerance =repmat (gradtol ,1 ,L ); 

fitInfo .RelativeChangeInBeta =[]; 
fitInfo .BetaTolerance =repmat (betatol ,1 ,L ); 

fitInfo .DeltaGradient =[]; 
fitInfo .DeltaGradientTolerance =repmat (passed_deltagradtol ,1 ,L ); 

fitInfo .TerminationCode =repmat (-13 ,S ,L ); 
fitInfo .TerminationStatus =repmat (...
    {getString (message ('stats:classreg:learning:impl:LinearImpl:make:OneClass' ))},...
    S ,L ); 

ifdoduallast 
fitInfo .Alphas =[]; 
end

fitInfo .History =[]; 
fitInfo .FitTime =0 ; 

this .FitInfo =fitInfo ; 

return ; 
end

isXdouble =isa (X ,'double' ); 
epsX =100 *eps (clsname ); 

orthant =false ; 
sloss =numel (y ); 
slambda =1 ; 

dohist =verbose >0 ; 


beta =zeros (D ,L ,clsname ); 
bias =zeros (1 ,L ,clsname ); 
optlearnrate =NaN (1 ,L ,clsname ); 
ifdodual 
alphas =zeros (N ,L ,clsname ); 
else
alphas =zeros (0 ,L ,clsname ); 
end
alphas0 =[]; 
objective =zeros (1 ,L ,clsname ); 
grad =zeros (1 ,L ,clsname ); 
dbeta =zeros (1 ,L ,clsname ); 
deltagrad =zeros (1 ,L ,clsname ); 
numpass =zeros (1 ,L ); 
numiter =zeros (1 ,L ); 
status =cell (1 ,L ); 
ifdohist 
history =repmat (struct ,1 ,L ); 
else
history =[]; 
end


ifdodual 
lambda =fliplr (lambda ); 
end



mask =true (D ,1 ); 


tstart =tic ; 

forl =1 :L 
domask =l >1 &&~doridge ; 



beta0 =Beta0 (:,1 ); 
bias0 =Bias0 (1 ); 

ifl >1 
if~isvector (Beta0 )


beta0 =Beta0 (:,l ); 
bias0 =Bias0 (l ); 

ifdomask 
mask =beta0 ~=0 ; 
end
elseifany (ismember ({'sgd' ,'asgd' },solvers ))&&~doridge 



beta0 =Beta0 ; 
bias0 =Bias0 ; 



ifdomask 
mask =beta (:,l -1 )~=0 ; 
end
else


beta0 =beta (:,l -1 ); 
bias0 =bias (l -1 ); 

ifdomask 
mask =beta0 ~=0 ; 
end
end


ifdodual 
alphas0 =alphas (:,l -1 ); 
end
end

ifverbose >0 &&L >1 
fprintf ('\n%s Lambda = %13e\n' ,getString (...
    message ('stats:classreg:learning:impl:LinearImpl:make:Lambda' )),...
    lambda (l )); 
end


dowolfe =strcmp (linesearch ,'weakwolfe' ); 



[beta (:,l ),bias (l ),objective (l ),grad (l ),dbeta (l ),deltagrad (l ),...
    numpass (l ),numiter (l ),status {l },...
    batchindex (l ),optlearnrate (l ),alphas (:,l ),...
    hSolver ,hPass ,hIteration ,hObjective ,hStep ,hGradient ,...
    hDeltaBeta ,hNumBeta ,hValidationLoss ]=...
    classreg .learning .linearutils .solve (beta0 ,bias0 ,X ,y ,w ,lossfun ,...
    doridge ,lambda (l ),gamma ,maxpass ,nconv ,batchsize ,solvers ,...
    betatol ,gradtol ,epsilon ,presolve ,epsX ,rho ,...
    valX ,valY ,valW ,batchindex (l ),maxiter ,...
    sloss ,slambda ,isXdouble ,orthant ,...
    truncationK ,mask ,deltagradtol ,alphas0 ,...
    fitbias ,historysize ,dowolfe ,maxbatch ,...
    rsh ,verbose ); 


ifdohist 
history (l ).Solver =hSolver ; 
history (l ).NumPasses =hPass ; 
history (l ).NumIterations =hIteration ; 
history (l ).Objective =hObjective ; 
ifdodual 
history (l ).DeltaGradient =hStep ; 
else
history (l ).Step =hStep ; 
end
history (l ).Gradient =hGradient ; 
history (l ).RelativeChangeInBeta =hDeltaBeta ; 
history (l ).NumNonzeroBeta =hNumBeta ; 
if~isempty (hValidationLoss )
history (l ).ValidationLoss =hValidationLoss ; 
end
end
end



ifdodual 
lambda =fliplr (lambda ); 
alphas =fliplr (alphas ); 
batchindex =fliplr (batchindex ); 
beta =fliplr (beta ); 
bias =fliplr (bias ); 
objective =fliplr (objective ); 
grad =fliplr (grad ); 
dbeta =fliplr (dbeta ); 
deltagrad =fliplr (deltagrad ); 
numpass =fliplr (numpass ); 
numiter =fliplr (numiter ); 
optlearnrate =fliplr (optlearnrate ); 
status =fliplr (status ); 
history =fliplr (history ); 
end

ifpostfitbias 
F =(beta ' *X )' ; 
bias =classreg .learning .linearutils .fitbias (lossfun ,y ,F ,w ,epsilon ); 
end


telapsed =toc (tstart ); 

this .BatchIndex =batchindex ; 
this .Beta =beta ; 
this .Bias =bias ; 
this .OptimalLearnRate =optlearnrate ; 


fitInfo .Lambda =lambda ; 
fitInfo .Objective =objective ; 

ifdosgdlast ||doduallast 
fitInfo .PassLimit =passed_maxpass ; 
fitInfo .NumPasses =1 +numpass ; 
fitInfo .BatchLimit =passed_maxbatch ; 
end

ifdononsgdlast 
fitInfo .IterationLimit =passed_maxiter ; 
end
fitInfo .NumIterations =numiter ; 

fitInfo .GradientNorm =grad ; 
fitInfo .GradientTolerance =gradtol ; 

fitInfo .RelativeChangeInBeta =dbeta ; 
fitInfo .BetaTolerance =betatol ; 

ifisempty (passed_deltagradtol )
fitInfo .DeltaGradient =[]; 
else
fitInfo .DeltaGradient =deltagrad ; 
end
fitInfo .DeltaGradientTolerance =passed_deltagradtol ; 

fitInfo .TerminationCode =cell2mat (status ); 
fitInfo .TerminationStatus =terminationStatus (fitInfo .TerminationCode ); 

ifdosgdlast 
fitInfo .BatchIndex =batchindex ; 
fitInfo .OptimalLearnRate =optlearnrate ; 
end

ifdoduallast 
fitInfo .Alpha =alphas ; 
end

fitInfo .History =history ; 
fitInfo .FitTime =telapsed ; 

this .FitInfo =fitInfo ; 
end
end

end


function status =terminationStatus (termCode )

[S ,L ]=size (termCode ); 
status =cell (S ,L ); 

forl =1 :L 
fors =1 :S 
switchtermCode (s ,l )
case -11 
str =getString (message ('stats:classreg:learning:impl:LinearImpl:make:ObjectiveDoesNotDecrease' )); 
case -10 
str =getString (message ('stats:classreg:learning:impl:LinearImpl:make:SmallLearnRate' )); 
case -3 
str =getString (message ('stats:classreg:learning:impl:LinearImpl:make:NaNorInfObjective' )); 
case -2 
str =getString (message ('stats:classreg:learning:impl:LinearImpl:make:AllPreviousCoeffsZero' )); 
case -1 
str =getString (message ('stats:classreg:learning:impl:LinearImpl:make:AllCoeffsRemainZero' ,10 )); 
case 0 
str =getString (message ('stats:classreg:learning:impl:LinearImpl:make:MaxIterReached' )); 
case 1 
str =getString (message ('stats:classreg:learning:impl:LinearImpl:make:BetaToleranceMet' )); 
case 2 
str =getString (message ('stats:classreg:learning:impl:LinearImpl:make:GradientToleranceMet' )); 
case 3 
str =getString (message ('stats:classreg:learning:impl:LinearImpl:make:ValidationLossIncreases' ,5 )); 
case 4 
str =getString (message ('stats:classreg:learning:impl:LinearImpl:make:DeltaGradientToleranceMet' )); 
otherwise
error (message ('stats:classreg:learning:impl:LinearImpl:make:BadStatus' )); 
end

status {s ,l }=str ; 
end
end
end
