classdef RegressionKernel <...
    classreg .learning .regr .RegressionModel &classreg .learning .Kernel 
























properties (GetAccess =protected ,SetAccess =protected ,Hidden =true )
FitInfo =[]; 
end

properties (GetAccess =public ,SetAccess =protected )






Epsilon =[]; 











BoxConstraint =[]; 
end

methods (Hidden )
function this =RegressionKernel (dataSummary ,responseTransform )

if~isstruct (dataSummary )
error (message ('stats:RegressionKernel:DoNotUseConstructor' )); 
end

this =this @classreg .learning .regr .RegressionModel (...
    dataSummary ,responseTransform ); 
this =this @classreg .learning .Kernel ; 
end

function cmp =compact (this )
cmp =this ; 
end

end

methods (Access =protected )
function s =propsForDisp (this ,s )
s =propsForDisp @classreg .learning .regr .RegressionModel (this ,s ); 
s =propsForDisp @classreg .learning .Kernel (this ,s ); 
ifstrcmp (this .Learner ,'svm' )
s .BoxConstraint =this .BoxConstraint ; 
s .Epsilon =this .Epsilon ; 
end
s =rmfield (s ,'CategoricalPredictors' ); 
ifstrcmp (s .ResponseTransform ,'none' )
s =rmfield (s ,'ResponseTransform' ); 
end
end

function S =response (this ,X )



X =X ' ; 
[n ,p ]=size (X ); 
ifp ~=this .FeatureMapper .d 
error (message ('stats:RegressionKernel:XSizeMismatch' ,this .FeatureMapper .d ))
end

maxChunkSize =RegressionKernel .estimateMaxChunkSize (this .FeatureMapper .n ,this .ModelParams .BlockSize ,false ); 
numberChunks =ceil (n /maxChunkSize ); 

ifnumberChunks <=1 
Xm =map (this .FeatureMapper ,X ,this .KernelScale ); 
S =score (this .Impl ,Xm ,false ,true ); 
else

S =cell (numberChunks ,1 ); 
j =1 ; 
fori =1 :numberChunks 
k =min (n ,j +maxChunkSize -1 ); 
Xm =map (this .FeatureMapper ,X (j :k ,:),this .KernelScale ); 
S {i }=score (this .Impl ,Xm ,false ,true ); 
j =j +maxChunkSize ; 
end
S =cell2mat (S ); 
end
end
end

methods 
function [model ,fitinfo ]=resume (this ,X ,Y ,varargin )































args ={'weights' ,'betatolerance' ,'gradienttolerance' ,'iterationlimit' }; 
defs ={[],this .ModelParameters .BetaTolerance ,this .ModelParameters .GradientTolerance ,[]}; 
[W ,betaTolerance ,gradientTolerance ,iterationLimit ]=internal .stats .parseArgs (args ,defs ,varargin {:}); 
temp =RegressionKernel .template ('Weights' ,W ,...
    'BetaTolerance' ,betaTolerance ,...
    'GradientTolerance' ,gradientTolerance ,...
    'Epsilon' ,this .Epsilon ,...
    'FitBias' ,this .ModelParameters .FitBias ,...
    'HessianHistorySize' ,this .ModelParameters .HessianHistorySize ,...
    'Learner' ,this .ModelParameters .Learner ,...
    'Lambda' ,this .Lambda ,...
    'LineSearch' ,this .ModelParameters .LineSearch ,...
    'LossFunction' ,this .ModelParameters .LossFunction ,...
    'Regularization' ,this .ModelParameters .Regularization ,...
    'Solver' ,this .ModelParameters .Solver ,...
    'RandomStream' ,this .ModelParameters .Stream ,...
    'Verbose' ,this .ModelParameters .VerbosityLevel ,...
    'NumExpansionDimensions' ,this .NumExpansionDimensions ,...
    'KernelScale' ,this .KernelScale ,...
    'Transformation' ,this .ModelParameters .Transformation ,...
    'BlockSize' ,this .ModelParameters .BlockSize ,...
    'ADMMIterationLimit' ,0 ,...
    'Consensus' ,this .ModelParameters .Consensus ,...
    'InitialStepSize' ,this .ModelParameters .InitialStepSize ); 







if~isempty (iterationLimit )
tempDummy =RegressionKernel .template ('iterationLimit' ,iterationLimit ); 
temp .ModelParams .IterationLimit =tempDummy .ModelParams .IterationLimit ; 
temp .ModelParams .IterationLimitBlockWise =tempDummy .ModelParams .IterationLimitBlockWise ; 
end


temp .ModelParams .InitialBeta =this .Beta ; 
temp .ModelParams .InitialBias =this .Bias ; 
temp .ModelParams .FeatureMapper =this .FeatureMapper ; 

ifthis .FeatureMapper .d ~=gather (size (X ,2 ))
error (message ('stats:RegressionKernel:XSizeMismatch' ,this .FeatureMapper .d ))
end
ifistall (X )||istall (Y )||istall (W )
[model ,fitinfo ]=fitrkernel (X ,Y ,temp ); 
else
[model ,fitinfo ]=fit (temp ,X ,Y ); 
end



if~isempty (this .FitInfo .History )
ifisempty (fitinfo .History )


fitinfo .History =this .FitInfo .History ; 
else

fns =fieldnames (fitinfo .History ); 
fori =1 :numel (fns )
fitinfo .History .(fns {i })=[this .FitInfo .History .(fns {i }); fitinfo .History .(fns {i })]; 
end
end
model .FitInfo .History =fitinfo .History ; 
end

end

function [varargout ]=predict (this ,X ,varargin )












if~istall (X )
internal .stats .checkSupportedNumeric ('X' ,X )
end

[varargout {1 :nargout }]=predict @classreg .learning .regr .RegressionModel (this ,X ,varargin {:}); 
end

function l =loss (this ,X ,Y ,varargin )































adapter =classreg .learning .internal .makeClassificationModelAdapter (this ,X ,Y ,varargin {:}); 
if~isempty (adapter )
l =loss (adapter ,X ,Y ,varargin {:}); 
return 
end


internal .stats .checkSupportedNumeric ('X' ,X ,false ,true ); 

obsInRows =true ; 
N =size (X ,1 ); 

args ={'lossfun' ,'weights' }; 
defs ={@classreg .learning .loss .mse ,ones (N ,1 )}; 
[funloss ,W ,~,extraArgs ]=internal .stats .parseArgs (args ,defs ,varargin {:}); 


[X ,Y ,W ]=prepareDataForLoss (this ,X ,Y ,W ,this .VariableRange ,false ,obsInRows ); 


ifstrncmpi (funloss ,'epsiloninsensitive' ,length (funloss ))
ifisempty (this .Epsilon )
error (message ('stats:RegressionKernel:UseEpsilonInsensitiveForSVM' )); 
end
funloss =@(Y ,Yfit ,W )classreg .learning .loss .epsiloninsensitive (...
    Y ,Yfit ,W ,this .Epsilon ); 
end
funloss =classreg .learning .internal .lossCheck (funloss ,'regression' ); 


Yfit =predict (this ,X ,extraArgs {:}); 


classreg .learning .internal .regrCheck (Y ,Yfit (:,1 ),W ); 


l =funloss (Y ,Yfit ,W ); 

end

end

methods (Static ,Hidden )

function [lambda ,bc ]=resolveAutoLambdaOrEmptyBoxConstraint (lambda ,bc ,n )
ifstrcmp (lambda ,'auto' )
lambda =1 /bc /n ; 
elseifisempty (bc )
bc =1 /lambda /n ; 
end
end

function numExpansionDimensions =resolveAutoNumExpansionDimensions (numExpansionDimensions ,d )
ifstrcmp (numExpansionDimensions ,'auto' )
numExpansionDimensions =2 .^ceil (min (log2 (d )+5 ,15 )); 
end
end

function epsilon =resolveAutoEpsilon (epsilon ,lossFunction ,Y )
ifstrcmp (epsilon ,'auto' )
switchlossFunction 
case 'epsiloninsensitive' 
epsilon =iqr (Y )./13.49 ; 
ifepsilon ==0 
epsilon =1 ; 
end
case 'mse' 
epsilon =[]; 
end
end
end

function kernelScale =resolveAutoKernelScale (kernelScale ,X ,Y ,type )
ifstrcmp (kernelScale ,'auto' )
kernelScale =classreg .learning .svmutils .optimalKernelScale (X ,Y ,type ); 
end
end

function featureMapper =resolveEmptyFeatureMapper (featureMapper ,d ,expDim ,transformation ,stream )
ifisempty (featureMapper )
featureMapper =classreg .learning .rkeutils .featureMapper (stream ,d ,expDim ,transformation ); 
end
end

function initialBeta =resolveEmptyInitialBeta (initialBeta ,expDim )
ifisempty (initialBeta )
initialBeta =zeros (expDim ,1 ); 
end
end

function initialBias =resolveEmptyInitialBias (initialBias ,lossFunction ,Y ,W ,epsilon )
ifisempty (initialBias )
switchlossFunction 
case 'epsiloninsensitive' 


epsilon =0 ; 
initialBias =classreg .learning .linearutils .fitbias (...
    'epsiloninsensitive' ,Y ,zeros (numel (Y ),1 ,'like' ,Y ),W ,0 ); 
case 'mse' 
initialBias =sum (W ' *Y )/sum (W ); 
end
end
end

function maxChunkSize =estimateMaxChunkSize (numExpansionDimensions ,blockSize ,isFitting )
memoryPerExpandedRow =numExpansionDimensions *8 ; 
memoryBlock =blockSize *1e6 ; 
maxChunkSize =floor (memoryBlock ./memoryPerExpandedRow ); 
ifisFitting &&maxChunkSize <1000 
error (message ('stats:RegressionKernel:FewObservationsPerBlock' ))
end
end

function temp =template (varargin )
classreg .learning .FitTemplate .catchType (varargin {:}); 
temp =classreg .learning .FitTemplate .make ('Kernel' ,...
    'type' ,'regression' ,varargin {:}); 
end

function [varargout ]=fit (X ,Y ,varargin )
temp =RegressionKernel .template (varargin {:}); 
[varargout {1 :nargout }]=fit (temp ,X ,Y ); 
end

function [X ,Y ,W ,dataSummary ,responseTransform ]=...
    prepareData (X ,Y ,varargin )

[X ,Y ,W ,dataSummary ,responseTransform ]=...
    RegressionLinear .prepareData (X ,Y ,varargin {:}); 

internal .stats .checkSupportedNumeric ('X' ,X ,false ,false ,false )
end

function obj =makeNoFit (beta ,bias ,lambda ,featureMapper ,kernelScale ,boxConstraint ,epsilon ,modelParams ,dataSummary ,fitinfo ,responseTransform )




ifisempty (responseTransform )
responseTransform =@classreg .learning .transform .identity ; 
end

obj =RegressionKernel (dataSummary ,responseTransform ); 
obj .DefaultLoss =@classreg .learning .loss .mse ; 

switchlower (modelParams .LossFunction )
case 'epsiloninsensitive' 
obj .Learner ='svm' ; 
case 'mse' 
obj .Learner ='leastsquares' ; 
end

modelParamsStruct =toStruct (modelParams ); 

obj .Epsilon =epsilon ; 
obj .KernelScale =kernelScale ; 
obj .FeatureMapper =featureMapper ; 
obj .BoxConstraint =boxConstraint ; 

modelParams .Lambda =lambda ; 
obj .Impl =classreg .learning .impl .LinearImpl .makeNoFit (modelParams ,beta ,bias ,fitinfo ); 

modelParamsStruct =rmfield (modelParamsStruct ,'ValidationX' ); 
modelParamsStruct =rmfield (modelParamsStruct ,'ValidationY' ); 
modelParamsStruct =rmfield (modelParamsStruct ,'ValidationW' ); 
modelParamsStruct =rmfield (modelParamsStruct ,'FeatureMapper' ); 
obj .ModelParams =modelParamsStruct ; 




obj .FitInfo =fitinfo ; 
end

function [obj ,fitInfo ]=fitRegressionKernel (...
    X ,Y ,W ,modelParams ,dataSummary ,responseTransform )

modelParams =fillIfNeeded (modelParams ,X ,Y ,W ,dataSummary ,[]); 
obj =RegressionKernel (dataSummary ,responseTransform ); 

obj .DefaultLoss =@classreg .learning .loss .mse ; 

switchlower (modelParams .LossFunction )
case 'epsiloninsensitive' 
obj .Learner ='svm' ; 

case 'mse' 
obj .Learner ='leastsquares' ; 
end

[d ,n ]=size (X ); 






[lambda ,obj .BoxConstraint ]=RegressionKernel .resolveAutoLambdaOrEmptyBoxConstraint (modelParams .Lambda ,modelParams .BoxConstraint ,n ); 
numExpansionDimensions =RegressionKernel .resolveAutoNumExpansionDimensions (modelParams .NumExpansionDimensions ,d ); 
obj .FeatureMapper =RegressionKernel .resolveEmptyFeatureMapper (modelParams .FeatureMapper ,d ,numExpansionDimensions ,modelParams .Transformation ,modelParams .Stream ); 
obj .KernelScale =RegressionKernel .resolveAutoKernelScale (modelParams .KernelScale ,X ' ,Y ,0 ); 
obj .Epsilon =RegressionKernel .resolveAutoEpsilon (modelParams .Epsilon ,modelParams .LossFunction ,Y ); 


initialBeta =RegressionKernel .resolveEmptyInitialBeta (modelParams .InitialBeta ,numExpansionDimensions ); 
initialBias =RegressionKernel .resolveEmptyInitialBias (modelParams .InitialBias ,modelParams .LossFunction ,Y ,W ,obj .Epsilon ); 


maxChunkSize =RegressionKernel .estimateMaxChunkSize (numExpansionDimensions ,modelParams .BlockSize ,true ); 
numberChunks =ceil (n /maxChunkSize ); 

ifnumberChunks ==1 

ifmodelParams .IterationLimit ==0 
error (message ('stats:RegressionKernel:InvalidIterationLimit' ))
end

Xm =map (obj .FeatureMapper ,X ' ,obj .KernelScale )' ; 

obj .Impl =classreg .learning .impl .LinearImpl .make (0 ,...
    initialBeta ,initialBias ,...
    Xm ,Y ,W ,...
    modelParams .LossFunction ,...
    strcmp (modelParams .Regularization ,'ridge' ),...
    lambda ,...
    [],...
    [],...
    [],...
    [],...
    [],...
    modelParams .Solver ,...
    modelParams .BetaTolerance ,...
    modelParams .GradientTolerance ,...
    1e-6 ,...
    [],...
    [],...
    modelParams .ValidationX ,modelParams .ValidationY ,modelParams .ValidationW ,...
    modelParams .IterationLimit ,...
    [],...
    modelParams .FitBias ,...
    modelParams .PostFitBias ,...
    obj .Epsilon ,...
    modelParams .HessianHistorySize ,...
    modelParams .LineSearch ,...
    0 ,...
    [],...
    modelParams .VerbosityLevel ); 

modelParamsStruct =toStruct (modelParams ); 

fiHis =obj .Impl .FitInfo .History ; 
ifisempty (fiHis )
fiHisNew =[]; 
else


fiHisNew =struct ('ObjectiveValue' ,fiHis .Objective ,...
    'GradientMagnitude' ,fiHis .Gradient ,...
    'Solver' ,categorical (repmat ({'LBFGS-fast' },numel (fiHis .Solver ),1 )),...
    'IterationNumber' ,fiHis .NumIterations ,...
    'DataPass' ,cumsum (fiHis .NumPasses ),...
    'RelativeChangeInBeta' ,fiHis .RelativeChangeInBeta ,...
    'ElapsedTime' ,[nan (numel (fiHis .Solver )-1 ,1 ); obj .Impl .FitInfo .FitTime ]); 
end

fitInfo =struct ('Solver' ,'LBFGS-fast' ,...
    'LossFunction' ,modelParams .LossFunction ,...
    'Lambda' ,lambda ,...
    'BetaTolerance' ,modelParams .BetaTolerance ,...
    'GradientTolerance' ,modelParams .GradientTolerance ,...
    'ObjectiveValue' ,obj .Impl .FitInfo .Objective ,...
    'GradientMagnitude' ,obj .Impl .FitInfo .GradientNorm ,...
    'RelativeChangeInBeta' ,obj .Impl .FitInfo .RelativeChangeInBeta ,...
    'FitTime' ,obj .Impl .FitInfo .FitTime ,...
    'History' ,fiHisNew ); 

else
if(modelParams .IterationLimit +modelParams .ADMMIterationLimit )==0 
error (message ('stats:RegressionKernel:InvalidIterationLimitADMM' ))
end

X =X ' ; 
ifmodelParams .VerbosityLevel >0 
fprintf (getString (message ('stats:RegressionKernel:FoundNBlocks' ,numberChunks )))
end

Beta =[initialBias ; initialBeta ]; 

doridge =strcmp (modelParams .Regularization ,'ridge' ); 
rho =modelParams .Consensus ; 

chunkIDs =arrayfun (@(x )sprintf ('P0C%d' ,x ),(1 :numberChunks )' ,'uniform' ,false ); 
chunkMap =containers .Map (chunkIDs ,1 :numberChunks ); 

Wk =zeros (numberChunks ,1 ); 
h =0 ; 
fori =1 :maxChunkSize :n 
h =h +1 ; 
j =min (i +maxChunkSize -1 ,n ); 
Wk (h )=sum (W (i :j ,:),1 ); 
end
hfixedchunkfun =@fixedchunkfun ; 

betaTol =modelParams .BetaTolerance ; 
gradTol =modelParams .GradientTolerance ; 
admmIterationLimit =modelParams .ADMMIterationLimit ; 
tallPassLimit =intmax ; 
verbose =modelParams .VerbosityLevel ; 

doBias =modelParams .FitBias ; 
lossfun =modelParams .LossFunction ; 


iterationlimit_ADMMLBFGS =[modelParams .WarmStartIterationLimit ,modelParams .ADMMUpdateIterationLimit ]; 
hessianHistorySize_ADMMLBFGS =15 ; 
dowolfe_ADMMLBFGS =true ; 
doBias_ADMMLBFGS =doBias ; 
gradTol_ADMMLBFGS =gradTol ; 
betaTol_ADMMLBFGS =betaTol ; 
doridge_ADMMLBFGS =doridge ; 
lossfun_ADMMLBFGS =lossfun ; 


expType =modelParams .Transformation ; 
objgraF =makeobjgradF (X ,Y ,W ,lossfun ,lambda ./numberChunks ,maxChunkSize ,obj .FeatureMapper ,obj .KernelScale ,obj .Epsilon ); 

hclientfun =@(x )(x ); 
keepHist =true ; 
progressF =classreg .learning .linearutils .linearSolverProgressFunction (objgraF ,false ,admmIterationLimit >1 ,verbose >0 ,keepHist ,hclientfun ); 



Beta =classreg .learning .linearutils .ADMMimpl (X ,Y ,W ,Beta ,rho ,lambda ,doridge ,...
    chunkMap ,Wk ,maxChunkSize ,hfixedchunkfun ,...
    betaTol ,gradTol ,admmIterationLimit ,tallPassLimit ,progressF ,verbose ,...
    {lossfun_ADMMLBFGS ,obj .Epsilon },betaTol_ADMMLBFGS ,gradTol_ADMMLBFGS ,...
    iterationlimit_ADMMLBFGS ,doridge_ADMMLBFGS ,...
    hessianHistorySize_ADMMLBFGS ,dowolfe_ADMMLBFGS ,doBias_ADMMLBFGS ,...
    obj .FeatureMapper ,expType ,obj .KernelScale ); 


hessianHistorySize =modelParams .HessianHistorySize ; 
lineSearch =modelParams .LineSearch ; 
iterationlimit =modelParams .IterationLimitBlockWise ; 
initialStepSize =modelParams .InitialStepSize ; 

Beta =classreg .learning .linearutils .LBFGSimpl (Beta ,progressF ,verbose ,...
    betaTol ,gradTol ,iterationlimit ,tallPassLimit ,...
    hessianHistorySize ,lineSearch ,initialStepSize ); 

beta =Beta (2 :end); 
bias =Beta (1 ); 

ifverbose >0 
printLastLine (progressF ); 
end

modelParamsStruct =toStruct (modelParams ); 
modelParams .Lambda =lambda ; 

obj .Impl =classreg .learning .impl .LinearImpl .makeNoFit (modelParams ,beta ,bias ,progressF .History ); 

fiHis =obj .Impl .FitInfo ; 
ifverbose >0 


fiHisNew =struct ('ObjectiveValue' ,fiHis .ObjectiveValue (:),...
    'GradientMagnitude' ,fiHis .GradientMagnitude (:),...
    'Solver' ,categorical (repmat ({'LBFGS-blockwise' },numel (fiHis .Solver ),1 )),...
    'IterationNumber' ,fiHis .IterationNumber (:),...
    'DataPass' ,fiHis .DataPass (:),...
    'RelativeChangeInBeta' ,fiHis .RelativeChangeBeta (:),...
    'ElapsedTime' ,fiHis .ElapsedTime (:)); 
else
fiHisNew =[]; 
end

fitInfo =struct ('Solver' ,'LBFGS-blockwise' ,...
    'LossFunction' ,modelParams .LossFunction ,...
    'Lambda' ,modelParams .Lambda ,...
    'BetaTolerance' ,modelParams .BetaTolerance ,...
    'GradientTolerance' ,modelParams .GradientTolerance ,...
    'ObjectiveValue' ,obj .Impl .FitInfo .ObjectiveValue (end),...
    'GradientMagnitude' ,obj .Impl .FitInfo .GradientMagnitude (end),...
    'RelativeChangeInBeta' ,obj .Impl .FitInfo .RelativeChangeBeta (end),...
    'FitTime' ,obj .Impl .FitInfo .ElapsedTime (end),...
    'History' ,fiHisNew ); 


end

modelParamsStruct =rmfield (modelParamsStruct ,'ValidationX' ); 
modelParamsStruct =rmfield (modelParamsStruct ,'ValidationY' ); 
modelParamsStruct =rmfield (modelParamsStruct ,'ValidationW' ); 
modelParamsStruct =rmfield (modelParamsStruct ,'FeatureMapper' ); 
obj .ModelParams =modelParamsStruct ; 




obj .FitInfo =fitInfo ; 

end

end

end

function objgraF =makeobjgradF (X ,Y ,W ,lossfun ,lambdaK ,maxChunkSize ,FM ,kernelScale ,epsilon )
objgraF =@fcn ; 
function [obj ,gra ]=fcn (Beta )
[~,obj ,gra ]=fixedchunkfun (@(info ,x ,y ,w )...
    chunkObjGraFun (info ,Beta ,x ,y ,w ,lossfun ,lambdaK ,FM ,kernelScale ,epsilon ),...
    maxChunkSize ,{[],[],[]},X ,Y ,W ); 
obj =sum (obj ,1 ); 
gra =sum (gra ,1 ); 
end
end

function varargout =fixedchunkfun (fcn ,FixedNumSlices ,~,varargin )






info =struct ('PartitionId' ,0 ,'FixedSizeChunkID' ,0 ,'IsLastChunk' ,true ); 
bi =cellfun (@(x )isa (x ,'matlab.bigdata.internal.BroadcastArray' ),varargin ); 
n =size (varargin {find (~bi ,1 )},1 ); 
nia =numel (varargin ); 
varargout =cell (1 ,nargout ); 
h =0 ; 
fori =1 :FixedNumSlices :n 
h =h +1 ; 
info .FixedSizeChunkID =h ; 
j =min (i +FixedNumSlices -1 ,n ); 
invar =cell (1 ,nia ); 
outvar =cell (1 ,nargout ); 
fork =1 :nia 
ifbi (k )
invar {k }=varargin {k }; 
else
invar {k }=varargin {k }(i :j ,:); 
end
end
[~,outvar {:}]=fcn (info ,invar {:}); 
fork =1 :nargout 
varargout {k }(h ,:)=outvar {k }; 
end
end

end

function [hasFinished ,id ,obj ,gra ]=chunkObjGraFun (info ,Beta ,x ,y ,w ,lossfun ,lambda ,FM ,kernelScale ,epsilon )
hasFinished =info .IsLastChunk ; 
id ={sprintf ('P%dC%d' ,info .PartitionId ,info .FixedSizeChunkID )}; 
useBias =true ; 
doridge =true ; 
ifisempty (x )
obj =(Beta (2 :end)' *Beta (2 :end))*lambda /2 ; 
gra =[0 ; Beta (2 :end)*lambda ]' ; 
else
xm =map (FM ,x ,kernelScale ); 
[obj ,gra ]=classreg .learning .linearutils .objgrad (Beta (2 :end),Beta (1 ),xm ' ,y ,w ,...
    lossfun ,doridge ,lambda ,epsilon ,useBias ,...
    zeros (numel (Beta )-1 ,1 ,'like' ,Beta ),0 ,0 ); 
gra =[gra (end); gra (1 :end-1 )]' ; 


end
end