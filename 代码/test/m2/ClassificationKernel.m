classdef ClassificationKernel <...
    classreg .learning .classif .ClassificationModel &classreg .learning .Kernel 




























properties (GetAccess =protected ,SetAccess =protected ,Hidden =true )
FitInfo =[]; 
end

properties (GetAccess =public ,SetAccess =protected )










BoxConstraint =[]; 
end

methods (Hidden )
function this =ClassificationKernel (dataSummary ,classSummary ,scoreTransform )

if~isstruct (dataSummary )
error (message ('stats:ClassificationKernel:DoNotUseConstructor' )); 
end

this =this @classreg .learning .classif .ClassificationModel (...
    dataSummary ,classSummary ,scoreTransform ,[]); 
this =this @classreg .learning .Kernel ; 
end

function cmp =compact (this )
cmp =this ; 
end

end

methods (Access =protected )
function s =propsForDisp (this ,s )
s =propsForDisp @classreg .learning .classif .ClassificationModel (this ,s ); 
s =propsForDisp @classreg .learning .Kernel (this ,s ); 
ifstrcmp (this .Learner ,'svm' )
s .BoxConstraint =this .BoxConstraint ; 
end
s =rmfield (s ,'CategoricalPredictors' ); 
ifstrcmp (s .ScoreTransform ,'none' )
s =rmfield (s ,'ScoreTransform' ); 
end
end

function S =score (this ,X )



X =X ' ; 
[n ,p ]=size (X ); 
ifp ~=this .FeatureMapper .d 
error (message ('stats:ClassificationKernel:XSizeMismatch' ,this .FeatureMapper .d ))
end

maxChunkSize =ClassificationKernel .estimateMaxChunkSize (this .FeatureMapper .n ,this .ModelParams .BlockSize ,false ); 
numberChunks =ceil (n /maxChunkSize ); 
ifnumberChunks <=1 
Xm =map (this .FeatureMapper ,X ,this .KernelScale ); 
S1 =score (this .Impl ,Xm ,true ,true ); 
else

S1 =cell (numberChunks ,1 ); 
j =1 ; 
fori =1 :numberChunks 
k =min (n ,j +maxChunkSize -1 ); 
Xm =map (this .FeatureMapper ,X (j :k ,:),this .KernelScale ); 
S1 {i }=score (this .Impl ,Xm ,true ,true ); 
j =j +maxChunkSize ; 
end
S1 =cell2mat (S1 ); 
end


K =numel (this .ClassSummary .ClassNames ); 

[~,pos ]=ismember (this .ClassSummary .NonzeroProbClasses ,...
    this .ClassSummary .ClassNames ); 
S =repmat (-S1 ,1 ,K ); 
ifnumel (pos )==1 
S (:,pos )=S1 ; 
else
S (:,pos (2 ))=S1 ; 
end

end
end

methods 
function [model ,fitinfo ]=resume (this ,X ,Y ,varargin )


































args ={'weights' ,'betatolerance' ,'gradienttolerance' ,'iterationlimit' }; 
defs ={[],this .ModelParameters .BetaTolerance ,this .ModelParameters .GradientTolerance ,[]}; 
[W ,betaTolerance ,gradientTolerance ,iterationLimit ]=internal .stats .parseArgs (args ,defs ,varargin {:}); 
temp =ClassificationKernel .template ('Weights' ,W ,...
    'BetaTolerance' ,betaTolerance ,...
    'GradientTolerance' ,gradientTolerance ,...
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
tempDummy =ClassificationKernel .template ('iterationLimit' ,iterationLimit ); 
temp .ModelParams .IterationLimit =tempDummy .ModelParams .IterationLimit ; 
temp .ModelParams .IterationLimitBlockWise =tempDummy .ModelParams .IterationLimitBlockWise ; 
end


temp .ModelParams .InitialBeta =this .Beta ; 
temp .ModelParams .InitialBias =this .Bias ; 
temp .ModelParams .FeatureMapper =this .FeatureMapper ; 

ifthis .FeatureMapper .d ~=gather (size (X ,2 ))
error (message ('stats:ClassificationKernel:XSizeMismatch' ,this .FeatureMapper .d ))
end
ifistall (X )||istall (Y )||istall (W )
[model ,fitinfo ]=fitckernel (X ,Y ,temp ); 
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

[varargout {1 :nargout }]=predict @classreg .learning .classif .ClassificationModel (this ,X ,varargin {:}); 
end

function [varargout ]=margin (this ,X ,varargin )















if~istall (X )
internal .stats .checkSupportedNumeric ('X' ,X )
end

[varargout {1 :nargout }]=margin @classreg .learning .classif .ClassificationModel (this ,X ,varargin {:}); 
end

function [varargout ]=edge (this ,X ,varargin )





















if~istall (X )
internal .stats .checkSupportedNumeric ('X' ,X )
end

[varargout {1 :nargout }]=edge @classreg .learning .classif .ClassificationModel (this ,X ,varargin {:}); 
end

function [varargout ]=loss (this ,X ,varargin )






































if~istall (X )
internal .stats .checkSupportedNumeric ('X' ,X )
end

[varargout {1 :nargout }]=loss @classreg .learning .classif .ClassificationModel (this ,X ,varargin {:}); 
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

function initialBias =resolveEmptyInitialBias (initialBias ,lossFunction ,Y ,W )
ifisempty (initialBias )
switchlossFunction 
case 'hinge' 
initialBias =0 ; 
case 'logit' 
initialBias =sum (W ' *Y )/sum (W ); 
end
end
end

function maxChunkSize =estimateMaxChunkSize (numExpansionDimensions ,blockSize ,isFitting )
memoryPerExpandedRow =numExpansionDimensions *8 ; 
memoryBlock =blockSize *1e6 ; 
maxChunkSize =floor (memoryBlock ./memoryPerExpandedRow ); 
ifisFitting &&maxChunkSize <1000 
error (message ('stats:ClassificationKernel:FewObservationsPerBlock' ))
end
end

function temp =template (varargin )
classreg .learning .FitTemplate .catchType (varargin {:}); 
temp =classreg .learning .FitTemplate .make ('Kernel' ,...
    'type' ,'classification' ,varargin {:}); 
end

function [varargout ]=fit (X ,Y ,varargin )
temp =ClassificationKernel .template (varargin {:}); 
[varargout {1 :nargout }]=fit (temp ,X ,Y ); 
end

function [X ,Y ,W ,dataSummary ,classSummary ,scoreTransform ]=...
    prepareData (X ,Y ,varargin )

[X ,Y ,W ,dataSummary ,classSummary ,scoreTransform ]=...
    ClassificationLinear .prepareData (X ,Y ,varargin {:}); 

internal .stats .checkSupportedNumeric ('X' ,X ,false ,false ,false )
end

function obj =makeNoFit (beta ,bias ,lambda ,featureMapper ,kernelScale ,boxConstraint ,modelParams ,dataSummary ,classSummary ,fitinfo ,scoreTransform )




ifisempty (scoreTransform )
switchlower (modelParams .LossFunction )
case 'hinge' 
scoreTransform =@classreg .learning .transform .identity ; 
case 'logit' 
scoreTransform =@classreg .learning .transform .logit ; 
end
end

obj =ClassificationKernel (dataSummary ,classSummary ,scoreTransform ); 

obj .DefaultLoss =@classreg .learning .loss .classiferror ; 
obj .LabelPredictor =@classreg .learning .classif .ClassificationModel .maxScore ; 
obj .DefaultScoreType ='inf' ; 

switchlower (modelParams .LossFunction )
case 'hinge' 
obj .Learner ='svm' ; 
case 'logit' 
obj .Learner ='logistic' ; 
ifisequal (obj .PrivScoreTransform ,@classreg .learning .transform .identity )
obj .ScoreTransform ='logit' ; 
obj .ScoreType ='probability' ; 
end
end

modelParamsStruct =toStruct (modelParams ); 

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

function [obj ,fitInfo ]=fitClassificationKernel (...
    X ,Y ,W ,modelParams ,dataSummary ,classSummary ,scoreTransform )

modelParams =fillIfNeeded (modelParams ,X ,Y ,W ,dataSummary ,classSummary ); 
obj =ClassificationKernel (dataSummary ,classSummary ,scoreTransform ); 

obj .DefaultLoss =@classreg .learning .loss .classiferror ; 
obj .LabelPredictor =@classreg .learning .classif .ClassificationModel .maxScore ; 
obj .DefaultScoreType ='inf' ; 

switchlower (modelParams .LossFunction )
case 'hinge' 
obj .Learner ='svm' ; 

case 'logit' 
obj .Learner ='logistic' ; 
ifisequal (obj .PrivScoreTransform ,@classreg .learning .transform .identity )
obj .ScoreTransform ='logit' ; 
obj .ScoreType ='probability' ; 
end
end


gidx =grp2idx (Y ,obj .ClassSummary .NonzeroProbClasses ); 
ifany (gidx ==2 )
doclass =2 ; 
gidx (gidx ==1 )=-1 ; 
gidx (gidx ==2 )=+1 ; 
else
doclass =1 ; 
end

[d ,n ]=size (X ); 






[lambda ,obj .BoxConstraint ]=ClassificationKernel .resolveAutoLambdaOrEmptyBoxConstraint (modelParams .Lambda ,modelParams .BoxConstraint ,n ); 
numExpansionDimensions =ClassificationKernel .resolveAutoNumExpansionDimensions (modelParams .NumExpansionDimensions ,d ); 
obj .FeatureMapper =ClassificationKernel .resolveEmptyFeatureMapper (modelParams .FeatureMapper ,d ,numExpansionDimensions ,modelParams .Transformation ,modelParams .Stream ); 
obj .KernelScale =ClassificationKernel .resolveAutoKernelScale (modelParams .KernelScale ,X ' ,gidx ,doclass ); 

initialBeta =ClassificationKernel .resolveEmptyInitialBeta (modelParams .InitialBeta ,numExpansionDimensions ); 
initialBias =ClassificationKernel .resolveEmptyInitialBias (modelParams .InitialBias ,modelParams .LossFunction ,gidx ,W ); 


maxChunkSize =ClassificationKernel .estimateMaxChunkSize (numExpansionDimensions ,modelParams .BlockSize ,true ); 
numberChunks =ceil (n /maxChunkSize ); 

ifnumberChunks ==1 

ifmodelParams .IterationLimit ==0 
error (message ('stats:ClassificationKernel:InvalidIterationLimit' ))
end

Xm =map (obj .FeatureMapper ,X ' ,obj .KernelScale )' ; 

obj .Impl =classreg .learning .impl .LinearImpl .make (doclass ,...
    initialBeta ,initialBias ,...
    Xm ,gidx ,W ,...
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
    [],...
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
error (message ('stats:ClassificationKernel:InvalidIterationLimitADMM' ))
end

X =X ' ; 
ifmodelParams .VerbosityLevel >0 
fprintf (getString (message ('stats:ClassificationKernel:FoundNBlocks' ,numberChunks )))
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
objgraF =makeobjgradF (X ,gidx ,W ,lossfun ,lambda ./numberChunks ,maxChunkSize ,obj .FeatureMapper ,obj .KernelScale ); 

hclientfun =@(x )(x ); 
keepHist =true ; 
progressF =classreg .learning .linearutils .linearSolverProgressFunction (objgraF ,false ,admmIterationLimit >1 ,verbose >0 ,keepHist ,hclientfun ); 



ifdoclass ==1 
ifstrcmp (lossfun ,'logit' )
Beta =[inf ; zeros (numExpansionDimensions ,1 )]; 
elseifstrcmp (lossfun ,'hinge' )
Beta =[1 ; zeros (numExpansionDimensions ,1 )]; 
end
end


Beta =classreg .learning .linearutils .ADMMimpl (X ,gidx ,W ,Beta ,rho ,lambda ,doridge ,...
    chunkMap ,Wk ,maxChunkSize ,hfixedchunkfun ,...
    betaTol ,gradTol ,admmIterationLimit ,tallPassLimit ,progressF ,verbose ,...
    lossfun_ADMMLBFGS ,betaTol_ADMMLBFGS ,gradTol_ADMMLBFGS ,...
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

function objgraF =makeobjgradF (X ,Y ,W ,lossfun ,lambdaK ,maxChunkSize ,FM ,kernelScale )
objgraF =@fcn ; 
function [obj ,gra ]=fcn (Beta )
[~,obj ,gra ]=fixedchunkfun (@(info ,x ,y ,w )...
    chunkObjGraFun (info ,Beta ,x ,y ,w ,lossfun ,lambdaK ,FM ,kernelScale ),...
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

function [hasFinished ,id ,obj ,gra ]=chunkObjGraFun (info ,Beta ,x ,y ,w ,lossfun ,lambda ,FM ,kernelScale )
hasFinished =info .IsLastChunk ; 
id ={sprintf ('P%dC%d' ,info .PartitionId ,info .FixedSizeChunkID )}; 
epsilon =0 ; 
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