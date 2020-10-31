classdef KernelParams <classreg .learning .modelparams .ModelParams 







































properties 
ADMMIterationLimit ; 
ADMMUpdateIterationLimit ; 
BetaTolerance ; 
BlockSize ; 
BoxConstraint ; 
Consensus ; 
Epsilon ; 
NumExpansionDimensions ; 
FeatureMapper ; 
FitBias ; 
GradientTolerance ; 
HessianHistorySize ; 
InitialBeta ; 
InitialBias ; 
InitialStepSize ; 
IterationLimit ; 
IterationLimitBlockWise ; 
KernelScale ; 
Lambda ; 
Learner ; 
LineSearch ; 
LossFunction ; 
PostFitBias ; 
Regularization ; 
Solver ; 
Stream ; 
Transformation ; 
ValidationX ; 
ValidationY ; 
ValidationW ; 
VerbosityLevel ; 
WarmStartIterationLimit ; 
end

methods (Access =protected )
function this =KernelParams (type ,learner ,lossfun ,...
    fitbias ,regularizer ,lambda ,maxiter ,maxiterbw ,...
    solver ,betaTol ,gradTol ,boxConstraint ,...
    epsilon ,historysize ,linesearch ,...
    rsh ,verbose ,numexpansiondimensions ,...
    kernelscale ,transformation ,blocksize ,...
    admmiterationlimit ,admmupdateiterationlimit ,...
    warmstartiterationlimit ,initialstepsize ,consensus )

this =this @classreg .learning .modelparams .ModelParams ('Kernel' ,type ); 

this .Learner =learner ; 
this .LossFunction =lossfun ; 
this .FitBias =fitbias ; 
this .Regularization =regularizer ; 
this .Lambda =lambda ; 
this .IterationLimit =maxiter ; 
this .IterationLimitBlockWise =maxiterbw ; 
this .Solver =solver ; 
this .BetaTolerance =betaTol ; 
this .GradientTolerance =gradTol ; 
this .BoxConstraint =boxConstraint ; 
this .Epsilon =epsilon ; 
this .HessianHistorySize =historysize ; 
this .LineSearch =linesearch ; 
this .Stream =rsh ; 
this .VerbosityLevel =verbose ; 
this .NumExpansionDimensions =numexpansiondimensions ; 
this .KernelScale =kernelscale ; 
this .Transformation =transformation ; 
this .BlockSize =blocksize ; 
this .ADMMIterationLimit =admmiterationlimit ; 
this .ADMMUpdateIterationLimit =admmupdateiterationlimit ; 
this .WarmStartIterationLimit =warmstartiterationlimit ; 
this .InitialStepSize =initialstepsize ; 
this .Consensus =consensus ; 
end
end

methods (Static ,Hidden )

function [holder ,extraArgs ]=make (type ,varargin )



args ={'beta' ,'bias' ,'learner' ,'lossfunction' ,'lambda' ...
    ,'iterationlimit' ,'regularization' ,'solver' ...
    ,'betatolerance' ,'gradienttolerance' ...
    ,'fitbias' ,'epsilon' ,'validationdata' ...
    ,'hessianhistorysize' ,'linesearch' ...
    ,'randomstream' ,'verbose' ,{'numexpansiondimensions' ,'expansiondimension' }...
    ,'kernelscale' ,'transformation' ,'blocksize' ...
    ,'admmiterationlimit' ,'admmupdateiterationlimit' ...
    ,'warmstartiterationlimit' ,'initialstepsize' ...
    ,'consensus' ,'boxconstraint' }; 
defs =repmat ({[]},1 ,numel (args )); 
[beta0 ,bias0 ,learner ,lossfun ,lambda ,...
    maxiter ,regularizer ,solvers ,...
    betatol ,gradtol ,...
    fitbias ,epsilon ,valdata ,...
    historysize ,linesearch ,...
    rsh ,verbose ,numexpansiondimensions ,...
    kernelscale ,transformation ,blocksize ,...
    admmiterationlimit ,admmupdateiterationlimit ,...
    warmstartiterationlimit ,initialstepsize ,...
    consensus ,boxconstraint ,~,extraArgs ]=...
    internal .stats .parseArgs (args ,defs ,varargin {:}); 






if~isempty (beta0 )
error (message ('stats:classreg:learning:modelparams:KernelParams:NotAllowedBeta' ))
end
if~isempty (bias0 )
error (message ('stats:classreg:learning:modelparams:KernelParams:NotAllowedBias' ))
end

if~isempty (epsilon )
ifstrcmpi (type ,'classification' )
error (message ('stats:classreg:learning:modelparams:KernelParams:NotAllowedEpsilon' ))
end
end

if~isempty (valdata )
error (message ('stats:classreg:learning:modelparams:KernelParams:NotAllowedValidationData' ))
end





if~isempty (betatol )
internal .stats .checkSupportedNumeric ('BetaTolerance' ,betatol ); 
if~isscalar (betatol )||betatol <0 ||isnan (betatol )||~isreal (betatol )
error (message ('stats:classreg:learning:modelparams:KernelParams:BadBetaTolerance' )); 
end
betatol =double (betatol ); 
end

if~isempty (blocksize )
internal .stats .checkSupportedNumeric ('BlockSize' ,blocksize ,true ); 
if~isscalar (blocksize )||blocksize <1 ...
    ||round (blocksize )~=blocksize ||~isreal (blocksize )
error (message ('stats:classreg:learning:modelparams:KernelParams:BadBlockSize' )); 
end
blocksize =double (blocksize ); 
end

if~isempty (boxconstraint )
internal .stats .checkSupportedNumeric ('BoxConstraint' ,boxconstraint ); 
if~isscalar (boxconstraint )||boxconstraint <=0 ||isnan (boxconstraint )||~isreal (boxconstraint )
error (message ('stats:classreg:learning:modelparams:KernelParams:BadBoxConstraint' )); 
end
boxconstraint =double (boxconstraint ); 
end

if~isempty (epsilon )
ifischar (epsilon )
if~strncmpi (epsilon ,'auto' ,length (epsilon ))
error (message ('stats:classreg:learning:modelparams:KernelParams:BadEpsilon' )); 
end
epsilon ='auto' ; 
else
internal .stats .checkSupportedNumeric ('Epsilon' ,epsilon ); 
if~isscalar (epsilon )||epsilon <0 ||isnan (epsilon )||~isreal (epsilon )
error (message ('stats:classreg:learning:modelparams:KernelParams:BadEpsilon' )); 
end
epsilon =double (epsilon ); 
end
end


if~isempty (numexpansiondimensions )
ifischar (numexpansiondimensions )
if~strncmpi (numexpansiondimensions ,'auto' ,length (numexpansiondimensions ))
error (message ('stats:classreg:learning:modelparams:KernelParams:BadNumExpansionDimensions' )); 
end
numexpansiondimensions ='auto' ; 
else
internal .stats .checkSupportedNumeric ('NumExpansionDimensions' ,numexpansiondimensions ,true ); 
if~isscalar (numexpansiondimensions )||numexpansiondimensions <1 ...
    ||round (numexpansiondimensions )~=numexpansiondimensions ||~isreal (numexpansiondimensions )
error (message ('stats:classreg:learning:modelparams:KernelParams:BadNumExpansionDimensions' )); 
end
numexpansiondimensions =double (numexpansiondimensions ); 
end
end

if~isempty (gradtol )
internal .stats .checkSupportedNumeric ('GradientTolerance' ,gradtol ); 
if~isscalar (gradtol )||gradtol <0 ||isnan (gradtol )||~isreal (gradtol )
error (message ('stats:classreg:learning:modelparams:KernelParams:BadGradientTolerance' )); 
end
gradtol =double (gradtol ); 
end

if~isempty (historysize )
internal .stats .checkSupportedNumeric ('HessianHistorySize' ,historysize ,true ); 
if~isscalar (historysize )||historysize <1 ...
    ||round (historysize )~=historysize ||~isreal (historysize )
error (message ('stats:classreg:learning:modelparams:KernelParams:BadHessianHistorySize' )); 
end
historysize =double (historysize ); 
end

if~isempty (maxiter )
internal .stats .checkSupportedNumeric ('IterationLimit' ,maxiter ,true ); 
if~isscalar (maxiter )||maxiter <0 ||round (maxiter )~=maxiter ||~isreal (maxiter )
error (message ('stats:classreg:learning:modelparams:KernelParams:BadIterationLimit' )); 
end
maxiter =double (maxiter ); 
maxiterbw =maxiter ; 
else
maxiterbw =[]; 
end


if~isempty (kernelscale )
ifischar (kernelscale )
if~strncmpi (kernelscale ,'auto' ,length (kernelscale ))
error (message ('stats:classreg:learning:modelparams:KernelParams:BadKernelScale' )); 
end
kernelscale ='auto' ; 
else
internal .stats .checkSupportedNumeric ('KernelScale' ,kernelscale ); 
if~isscalar (kernelscale )||kernelscale <=0 ||isnan (kernelscale )||~isreal (kernelscale )
error (message ('stats:classreg:learning:modelparams:KernelParams:BadKernelScale' )); 
end
kernelscale =double (kernelscale ); 
end
end


if~isempty (lambda )
ifischar (lambda )
if~strncmpi (lambda ,'auto' ,length (lambda ))
error (message ('stats:classreg:learning:modelparams:KernelParams:BadLambda' )); 
end
lambda ='auto' ; 
else
internal .stats .checkSupportedNumeric ('Lambda' ,lambda ); 
if~isscalar (lambda )||lambda <0 ||isnan (lambda )||~isreal (lambda )
error (message ('stats:classreg:learning:modelparams:KernelParams:BadLambda' )); 
end
lambda =double (lambda ); 
end
end


if~isempty (learner )
learner =validatestring (learner ,{'svm' ,'logistic' ,'leastsquares' },...
    'classreg.learning.modelparams.KernelParams' ,'Learner' ); 
end

if~isempty (rsh )
if~isa (rsh ,'RandStream' )
error (message ('stats:classreg:learning:modelparams:KernelParams:BadStream' ))
end
end

if~isempty (verbose )
internal .stats .checkSupportedNumeric ('Verbose' ,verbose ,true ); 
ifverbose <0 
error (message ('stats:classreg:learning:modelparams:KernelParams:BadVerbose' )); 
end
verbose =double (verbose ); 
end

if~isempty (warmstartiterationlimit )
internal .stats .checkSupportedNumeric ('WarmStartIterationLimit' ,warmstartiterationlimit ,true ); 
if~isscalar (warmstartiterationlimit )||warmstartiterationlimit <1 ...
    ||round (warmstartiterationlimit )~=warmstartiterationlimit ||~isreal (warmstartiterationlimit )
error (message ('stats:classreg:learning:modelparams:KernelParams:BadWarmStartIterationLimit' )); 
end
warmstartiterationlimit =double (warmstartiterationlimit ); 
end





if~isempty (lossfun )
lossfun =validatestring (lossfun ,{'mse' ,'logit' ,'hinge' ,'epsiloninsensitive' },...
    'classreg.learning.modelparams.KernelParams' ,'LossFunction' ); 
end

if~isempty (regularizer )
regularizer =validatestring (regularizer ,{'lasso' ,'ridge' },...
    'classreg.learning.modelparams.KernelParams' ,'Regularization' ); 
assert (strcmpi (regularizer ,'ridge' ),message ('stats:classreg:learning:modelparams:KernelParams:LassoNotAllowed' )); 
end

if~isempty (solvers )

ifiscellstr (solvers )&&numel (solvers )==1 
solvers =solvers {1 }; 
end
solvers ={validatestring (solvers ,{'lbfgs' },'classreg.learning.modelparams.KernelParams' ,'Solver' )}; 
end

if~isempty (fitbias )

fitbias =internal .stats .parseOnOff (fitbias ,'FitBias' ); 
assert (fitbias ,message ('stats:classreg:learning:modelparams:KernelParams:BadFitBias' ))
end

if~isempty (linesearch )
linesearch =validatestring (linesearch ,{'backtrack' ,'weakwolfe' },...
    'classreg.learning.modelparams.KernelParams' ,'LineSearch' ); 
end

if~isempty (transformation )
transformation =validatestring (transformation ,{'KitchenSinks' ,'FastFood' },...
    'classreg.learning.modelparams.KernelParams' ,'Transformation' ); 
end

if~isempty (admmiterationlimit )
internal .stats .checkSupportedNumeric ('ADMMIterationLimit' ,admmiterationlimit ,true ); 
if~isscalar (admmiterationlimit )||admmiterationlimit <0 ...
    ||round (admmiterationlimit )~=admmiterationlimit ||~isreal (admmiterationlimit )
error (message ('stats:classreg:learning:modelparams:KernelParams:BadADMMIterationLimit' )); 
end
admmiterationlimit =double (admmiterationlimit ); 
end

if~isempty (admmupdateiterationlimit )
internal .stats .checkSupportedNumeric ('ADMMUpdateIterationLimit' ,admmupdateiterationlimit ,true ); 
if~isscalar (admmupdateiterationlimit )||admmupdateiterationlimit <1 ...
    ||round (admmupdateiterationlimit )~=admmupdateiterationlimit ||~isreal (admmupdateiterationlimit )
error (message ('stats:classreg:learning:modelparams:KernelParams:BadADMMUpdateIterationLimit' )); 
end
admmupdateiterationlimit =double (admmupdateiterationlimit ); 
end

if~isempty (initialstepsize )
internal .stats .checkSupportedNumeric ('InitialStepSize' ,initialstepsize ,true ); 
if~isscalar (initialstepsize )||initialstepsize <=0 ||isnan (initialstepsize )||~isreal (initialstepsize )
error (message ('stats:classreg:learning:modelparams:KernelParams:BadInitialStepSize' )); 
end
initialstepsize =double (initialstepsize ); 
end

if~isempty (consensus )
internal .stats .checkSupportedNumeric ('Consensus' ,consensus ); 
if~isscalar (consensus )||consensus <=0 ||isnan (consensus )||~isreal (consensus )
error (message ('stats:classreg:learning:modelparams:KernelParams:BadConsensus' )); 
end
consensus =double (consensus ); 
end



if~isempty (boxconstraint )&&~isempty (lambda )
error (message ('stats:classreg:learning:modelparams:KernelParams:LambdaBoxConstraint' )); 
end
if~isempty (boxconstraint )&&(strcmpi (learner ,'logistic' )||strcmpi (lossfun ,'logit' ))
error (message ('stats:classreg:learning:modelparams:KernelParams:OnlySVMBoxConstraint' )); 
end

if~isempty (epsilon )&&(strcmpi (learner ,'leastsquares' )||strcmpi (lossfun ,'mse' ))
error (message ('stats:classreg:learning:modelparams:KernelParams:OnlySVMEpsilon' )); 
end

holder =classreg .learning .modelparams .KernelParams (...
    type ,learner ,lossfun ,...
    fitbias ,regularizer ,lambda ,maxiter ,maxiterbw ,...
    solvers ,betatol ,gradtol ,boxconstraint ,...
    epsilon ,historysize ,linesearch ,...
    rsh ,verbose ,numexpansiondimensions ,...
    kernelscale ,transformation ,blocksize ,...
    admmiterationlimit ,admmupdateiterationlimit ,...
    warmstartiterationlimit ,initialstepsize ,...
    consensus ); 
end

end


methods (Hidden )
function this =fillDefaultParams (this ,~,~,~,~,~)


doclass =strcmp (this .Type ,'classification' ); 
ifisempty (this .Learner )
ifisempty (this .LossFunction )
ifdoclass 
this .Learner ='svm' ; 
this .LossFunction ='hinge' ; 
else
this .Learner ='svm' ; 
this .LossFunction ='epsiloninsensitive' ; 
end
else
ifdoclass 
switchthis .LossFunction 
case 'hinge' 
this .Learner ='svm' ; 
case 'logit' 
this .Learner ='logistic' ; 
otherwise
error (message ('stats:classreg:learning:modelparams:KernelParams:BadLossFunction' )); 
end
else
switchthis .LossFunction 
case 'epsiloninsensitive' 
this .Learner ='svm' ; 
case 'mse' 
this .Learner ='leastsquares' ; 
otherwise
error (message ('stats:classreg:learning:modelparams:KernelParams:UnknownRegressionLoss' )); 
end
end
end
else
ifdoclass 
switchthis .Learner 
case 'svm' 
if~isempty (this .LossFunction )&&~strcmpi (this .LossFunction ,'hinge' )
error (message ('stats:classreg:learning:modelparams:KernelParams:BadLossForClassificationSVM' )); 
end
this .LossFunction ='hinge' ; 
case 'logistic' 
if~isempty (this .LossFunction )&&~strcmpi (this .LossFunction ,'logit' )
error (message ('stats:classreg:learning:modelparams:KernelParams:BadLossForLogisticRegression' )); 
end
this .LossFunction ='logit' ; 
otherwise
error (message ('stats:classreg:learning:modelparams:KernelParams:BadLearnerForClassification' )); 
end
else
switchthis .Learner 
case 'svm' 
if~isempty (this .LossFunction )&&~strcmp (this .LossFunction ,'epsiloninsensitive' )
error (message ('stats:classreg:learning:modelparams:KernelParams:BadLossForRegressionSVM' )); 
end
this .LossFunction ='epsiloninsensitive' ; 
case 'leastsquares' 
if~isempty (this .LossFunction )&&~strcmp (this .LossFunction ,'mse' )
error (message ('stats:classreg:learning:modelparams:KernelParams:BadLossForLeastSquares' )); 
end
this .LossFunction ='mse' ; 
otherwise
error (message ('stats:classreg:learning:modelparams:KernelParams:BadLearnerForRegression' )); 
end
end
end
ifisempty (this .Regularization )
this .Regularization ='ridge' ; 
end
ifisempty (this .Solver )
this .Solver ={'lbfgs' }; 
end
ifisempty (this .VerbosityLevel )
this .VerbosityLevel =0 ; 
end
ifisempty (this .FitBias )
this .FitBias =true ; 
end
ifisempty (this .PostFitBias )
this .PostFitBias =false ; 
end
ifisempty (this .Epsilon )
this .Epsilon ='auto' ; 
end
ifisempty (this .Lambda )&&isempty (this .BoxConstraint )
this .BoxConstraint =1 ; 
this .Lambda ='auto' ; 
elseifisempty (this .Lambda )
this .Lambda ='auto' ; 
elseifisempty (this .BoxConstraint )
ifisnumeric (this .Lambda )
this .BoxConstraint =[]; 
else
this .BoxConstraint =1 ; 
end
end
ifisempty (this .BetaTolerance )
this .BetaTolerance =1e-4 ; 
end
ifisempty (this .GradientTolerance )
this .GradientTolerance =1e-6 ; 
end
ifisempty (this .IterationLimit )
this .IterationLimit =1000 ; 
end
ifisempty (this .IterationLimitBlockWise )
this .IterationLimitBlockWise =100 ; 
end
ifisempty (this .HessianHistorySize )
this .HessianHistorySize =15 ; 
end
ifisempty (this .LineSearch )
this .LineSearch ='weakwolfe' ; 
end
ifisempty (this .KernelScale )
this .KernelScale =1 ; 
end
ifisempty (this .Transformation )
this .Transformation ='FastFood' ; 
end
ifisempty (this .BlockSize )
this .BlockSize =4000 ; 
end
ifisempty (this .ADMMIterationLimit )
this .ADMMIterationLimit =1 ; 
end
ifisempty (this .ADMMUpdateIterationLimit )
this .ADMMUpdateIterationLimit =100 ; 
end
ifisempty (this .WarmStartIterationLimit )
this .WarmStartIterationLimit =this .ADMMUpdateIterationLimit ; 
end
ifisempty (this .InitialStepSize )
this .InitialStepSize =1 ; 
end
ifisempty (this .Consensus )
this .Consensus =0.1 ; 
end
ifisempty (this .NumExpansionDimensions )
this .NumExpansionDimensions ='auto' ; 
end
ifisempty (this .Stream )
this .Stream =RandStream .getGlobalStream ; 
end

end
end

end

