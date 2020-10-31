classdef RegressionEnsemble <...
    classreg .learning .regr .FullRegressionModel &classreg .learning .ensemble .Ensemble ...
    &classreg .learning .regr .CompactRegressionEnsemble 




















































properties (GetAccess =public ,SetAccess =protected )






Regularization =[]; 
end

methods (Hidden )
function this =RegressionEnsemble (X ,Y ,W ,modelParams ,dataSummary ,responseTransform )
this =this @classreg .learning .regr .FullRegressionModel (...
    X ,Y ,W ,modelParams ,dataSummary ,responseTransform ); 
this =this @classreg .learning .ensemble .Ensemble (); 
this =this @classreg .learning .regr .CompactRegressionEnsemble (...
    dataSummary ,responseTransform ,[]); 
nlearn =this .ModelParams .NLearn /numel (this .ModelParams .LearnerTemplates ); 
this =fitEnsemble (this ,nlearn ); 
ifisa (this .ModelParams .Generator ,'classreg.learning.generator.SubspaceSampler' )
this .UsePredForLearner =this .ModelParams .Generator .UsePredForIter ; 
end
end

function l =aggregateLoss (this ,T ,funloss ,combiner ,fpredict ,trained ,...
    varargin )


vrange =this .VariableRange ; 
[X ,Y ,W ]=prepareDataForLoss (this ,this .X ,this .PrivY ,this .W ,vrange ,true ,true ); 
l =classreg .learning .ensemble .CompactEnsemble .aggregateLoss (...
    T ,X ,Y ,W ,[],funloss ,combiner ,fpredict ,trained ,...
    [],[],this .PrivResponseTransform ,NaN ,varargin {:}); 
end
end

methods (Static ,Hidden )
function this =fit (X ,Y ,varargin )
warning (message ('stats:classreg:learning:regr:RegressionEnsemble:fit:Noop' )); 
args ={'method' }; 
defs ={'' }; 
[method ,~,extraArgs ]=...
    internal .stats .parseArgs (args ,defs ,varargin {:}); 
temp =classreg .learning .FitTemplate .make (method ,'type' ,'regression' ,extraArgs {:}); 
this =fit (temp ,X ,Y ); 
end

function [alpha ,lambda ,mse ]=minimizeLasso (X ,Y ,W ,lambda ,tol ,Npass ,maxIter ,oldMSE ,verbose )

W =W (:)/sum (W ); 
WX2 =sum (bsxfun (@times ,X .^2 ,W ),1 ); 


useT =WX2 >0 ; 
if~any (useT )
warning (message ('stats:classreg:learning:regr:RegressionEnsemble:minimizeLasso:AllWX2Zero' )); 
alpha =[]; 
lambda =[]; 
mse =[]; 
return ; 
end
X (:,~useT )=[]; 
WX2 (~useT )=[]; 


ifisempty (lambda )
lambda_max =max (abs (sum (bsxfun (@times ,X ,W .*Y ),1 ))); 
loglam =log10 (lambda_max ); 
lambda =[0 ,logspace (loglam -3 ,loglam ,9 )]; 
else
lambda =lambda (:)' ; 
end


T =size (X ,2 ); 
L =numel (lambda ); 
alpha =zeros (T ,L ); 
mse =NaN (1 ,L ); 


forl =1 :L 
thisAlpha =alpha (:,l ); 
thisLambda =lambda (l ); 

prevAlpha =Inf (T ,1 ); 
prevMSE =oldMSE ; 
setto0 =false (T ,1 ); 
npass =1 ; 
checkActiveSet =false ; 


ifverbose >0 
fprintf ('%s\n' ,...
    getString (message ('stats:classreg:learning:regr:RegressionEnsemble:StartMinimization' ,...
    sprintf ('Lambda=%g' ,thisLambda ),sprintf ('%g' ,prevMSE )))); 
end



whiletrue 

XtimesAlpha =X *thisAlpha ; 
fornumIter =1 :maxIter 
fort =1 :T 
if~checkActiveSet &&setto0 (t )
continue ; 
end


rt =Y -XtimesAlpha +X (:,t )*thisAlpha (t ); 
alphat =(W .*X (:,t ))' *rt ; 
newAlphaT =max (alphat -thisLambda ,0 )/WX2 (t ); 
XtimesAlpha =XtimesAlpha +X (:,t )*(newAlphaT -thisAlpha (t )); 
thisAlpha (t )=newAlphaT ; 
ifthisAlpha (t )==0 
setto0 (t )=true ; 
else
ifcheckActiveSet &&setto0 (t )
setto0 (t :end)=false ; 
checkActiveSet =false ; 
end
end
end

ifall (setto0 )
checkActiveSet =true ; 
break; 
end

ifnorm (thisAlpha -prevAlpha )<tol *norm (thisAlpha )
break; 
else
prevAlpha =thisAlpha ; 
end

ifnumIter ==maxIter 
warning (message ('stats:lasso:MaxIterReached' ,num2str (thisLambda ))); 
end
end

thisMSE =sum (W .*(Y -X *thisAlpha ).^2 ); 
mse (l )=thisMSE ; 


ifverbose >0 
fprintf ('    %s\n' ,...
    getString (message ('stats:classreg:learning:regr:RegressionEnsemble:CompletedPass' ,...
    npass ,sprintf ('Lambda=%g' ,thisLambda )))); 
fprintf ('        %s\n' ,...
    getString (message ('stats:classreg:learning:regr:RegressionEnsemble:MSE' ,...
    sprintf ('%g' ,thisMSE )))); 
fprintf ('        %s\n' ,...
    getString (message ('stats:classreg:learning:regr:RegressionEnsemble:RelativeChangeInMSE' ,...
    sprintf ('%g' ,abs (thisMSE -prevMSE )/thisMSE )))); 
fprintf ('        %s\n' ,...
    getString (message ('stats:classreg:learning:regr:RegressionEnsemble:NumberOfLearners' ,...
    sum (~setto0 )))); 
end

prevMSE =thisMSE ; 


npass =npass +1 ; 
ifcheckActiveSet ||npass >Npass 
break; 
end
checkActiveSet =true ; 
end

ifverbose >0 
fprintf ('    %s\n' ,...
    getString (message ('stats:classreg:learning:regr:RegressionEnsemble:CompletedMinimization' ,...
    sprintf ('Lambda=%g' ,thisLambda )))); 
fprintf ('    %s\n' ,...
    getString (message ('stats:classreg:learning:regr:RegressionEnsemble:ResubstitutionMSE' ,...
    sprintf ('%g' ,oldMSE ),sprintf ('%g' ,thisMSE )))); 
fprintf ('    %s\n' ,...
    getString (message ('stats:classreg:learning:regr:RegressionEnsemble:NumberOfLearnersReduced' ,...
    T ,sum (~setto0 )))); 
end


alpha (:,l )=thisAlpha ; 
end


saveAlpha =alpha ; 
alpha =zeros (T ,L ); 
alpha (useT ,:)=saveAlpha ; 
end
end

methods 
function cmp =compact (this )








cmp =classreg .learning .regr .CompactRegressionEnsemble (...
    this .DataSummary ,this .PrivResponseTransform ,this .UsePredForLearner ); 
ifthis .ModelParams .SortLearnersByWeight 
cmp .Impl =sortLearnersByWeight (this .Impl ); 
else
cmp .Impl =this .Impl ; 
end
end

function partModel =crossval (this ,varargin )



























partModel =crossval @classreg .learning .regr .FullRegressionModel (this ,varargin {:}); 
end

function this =resume (this ,nlearn ,varargin )















ifisempty (nlearn )||~isnumeric (nlearn )||~isscalar (nlearn )||nlearn <=0 
error (message ('stats:classreg:learning:regr:RegressionEnsemble:resume:BadNLearn' )); 
end
nlearn =ceil (nlearn ); 
this .ModelParams .NPrint =classreg .learning .ensemble .Ensemble .checkNPrint (varargin {:}); 
this .ModelParams .NLearn =this .ModelParams .NLearn +...
    nlearn *numel (this .ModelParams .LearnerTemplates ); 
this =fitEnsemble (this ,nlearn ); 
ifisa (this .ModelParams .Generator ,'classreg.learning.generator.SubspaceSampler' )
this .UsePredForLearner =this .ModelParams .Generator .UsePredForIter ; 
end
end

function yfit =resubPredict (this ,varargin )














classreg .learning .ensemble .Ensemble .catchUOFL (varargin {:}); 
yfit =resubPredict @classreg .learning .regr .FullRegressionModel (this ,varargin {:}); 
end

function l =resubLoss (this ,varargin )




























classreg .learning .ensemble .Ensemble .catchUOFL (varargin {:}); 
l =resubLoss @classreg .learning .regr .FullRegressionModel (this ,varargin {:}); 
end
end

methods (Access =protected )
function s =propsForDisp (this ,s )
s =propsForDisp @classreg .learning .regr .FullRegressionModel (this ,s ); 
s =propsForDisp @classreg .learning .ensemble .Ensemble (this ,s ); 
s .Regularization =this .Regularization ; 
end

function this =fitEnsemble (this ,nlearn )

[this ,trained ,generator ,modifier ,combiner ]=...
    fitWeakLearners (this ,nlearn ,this .ModelParams .NPrint ); 


this .ModelParams .Generator =generator ; 
this .ModelParams .Modifier =modifier ; 


this .Impl =classreg .learning .impl .CompactEnsembleImpl (trained ,combiner ); 
end
end

methods 
function this =regularize (this ,varargin )











































args ={'lambda' ,'reltol' ,'npass' ,'Verbose' ,'MaxIter' }; 
defs ={[],1e-3 ,10 ,0 ,1e3 }; 
[lambda ,tol ,npass ,verbose ,maxIter ]=...
    internal .stats .parseArgs (args ,defs ,varargin {:}); 
if~isempty (lambda )&&(~isnumeric (lambda )||~isvector (lambda )||any (lambda <0 ))
error (message ('stats:classreg:learning:regr:RegressionEnsemble:regularize:LassoBadLambda' )); 
end
ifisempty (tol )||~isnumeric (tol )||~isscalar (tol )||tol <=0 
error (message ('stats:classreg:learning:regr:RegressionEnsemble:regularize:LassoBadTol' )); 
end
ifisempty (npass )||~isnumeric (npass )||~isscalar (npass )||npass <=0 
error (message ('stats:classreg:learning:regr:RegressionEnsemble:regularize:LassoBadNpass' )); 
end


ifisempty (this .Trained )
warning (message ('stats:classreg:learning:regr:RegressionEnsemble:regularize:LassoNoTrainedLearners' )); 
return ; 
end


X =this .X ; 
Y =this .Y ; 
W =this .W ; 


N =size (this .X ,1 ); 
T =this .NTrained ; 
Yfit =zeros (N ,T ); 
fort =1 :T 
Yfit (:,t )=predict (this .Trained {t },this .X ); 
end


tfnan =any (isnan (Yfit ),2 ); 
Yfit (tfnan ,:)=[]; 
Y (tfnan )=[]; 
X (tfnan ,:)=[]; 
W (tfnan )=[]; 
ifisempty (Y )
error (message ('stats:classreg:learning:regr:RegressionEnsemble:regularize:LassoAllNaN' )); 
end


oldMSE =loss (this ,X ,Y ,'lossfun' ,@classreg .learning .loss .mse ,'Weights' ,W ); 


this .Regularization =struct ; 
this .Regularization .Method ='Lasso' ; 


[this .Regularization .TrainedWeights ,this .Regularization .Lambda ,this .Regularization .ResubstitutionMSE ]=...
    classreg .learning .regr .RegressionEnsemble .minimizeLasso (...
    Yfit ,Y ,W ,lambda ,tol ,npass ,maxIter ,oldMSE ,verbose ); 
this .Regularization .CombineWeights =@classreg .learning .combiner .WeightedSum ; 
end

function cmp =shrink (this ,varargin )



























args ={'weightcolumn' ,'threshold' ,'lambda' }; 
defs ={1 ,0 ,[]}; 
[wcol ,thre ,lambda ,~,extraArgs ]=...
    internal .stats .parseArgs (args ,defs ,varargin {:}); 
ifisempty (wcol )||~isnumeric (wcol )||~isscalar (wcol )||wcol <=0 
error (message ('stats:classreg:learning:regr:RegressionEnsemble:shrink:BadWeightColumn' )); 
end
wcol =ceil (wcol ); 
if~isnumeric (thre )||~isscalar (thre )||thre <0 
error (message ('stats:classreg:learning:regr:RegressionEnsemble:shrink:BadThre' )); 
end


ifisempty (this .Regularization )
ifisempty (lambda )
cmp =compact (this ); 
return ; 
end
if~isscalar (lambda )
error (message ('stats:classreg:learning:regr:RegressionEnsemble:shrink:BadLambda' )); 
end
this =regularize (this ,'lambda' ,lambda ,extraArgs {:}); 
else
if~isempty (lambda )
error (message ('stats:classreg:learning:regr:RegressionEnsemble:shrink:LambdaForFilledRegularization' )); 
end
if~isempty (extraArgs )
error (message ('stats:classreg:learning:regr:RegressionEnsemble:shrink:ExtraArgsWithoutLambda' )); 
end
end


ifwcol >size (this .Regularization .TrainedWeights ,2 )
error (message ('stats:classreg:learning:regr:RegressionEnsemble:shrink:WeightColumnTooLarge' )); 
end
alpha =this .Regularization .TrainedWeights (:,wcol ); 


aboveThre =alpha >thre ; 
alpha =alpha (aboveThre ); 
trained =this .Trained (aboveThre ); 
usePredForIter =this .ModelParams .Generator .UsePredForIter (:,aboveThre ); 


combiner =this .Regularization .CombineWeights (alpha ); 


impl =classreg .learning .impl .CompactEnsembleImpl (trained ,combiner ); 
impl =sortLearnersByWeight (impl ); 
cmp =classreg .learning .regr .CompactRegressionEnsemble (...
    this .DataSummary ,this .PrivResponseTransform ,usePredForIter ); 
cmp .Impl =impl ; 
end

function [crit ,nlearn ]=cvshrink (this ,varargin )




































[~,partitionArgs ,extraArgs ]=...
    classreg .learning .generator .Partitioner .processArgs (varargin {:},'CrossVal' ,'on' ); 


ifisempty (this .Regularization )
defLambda =[]; 
else
defLambda =this .Regularization .Lambda ; 
end


args ={'lambda' ,'threshold' }; 
defs ={defLambda ,0 }; 
[lambda ,thre ,~,extraArgs ]=...
    internal .stats .parseArgs (args ,defs ,extraArgs {:}); 
ifisempty (lambda )
warning (message ('stats:classreg:learning:regr:RegressionEnsemble:regularize:EmptyLambda' )); 
crit =[]; 
nlearn =[]; 
return ; 
end
if~isnumeric (lambda )||~isvector (lambda )||any (lambda <0 )
error (message ('stats:classreg:learning:regr:RegressionEnsemble:cvshrink:LassoBadLambda' )); 
end
if~isnumeric (thre )||~isvector (thre )||any (thre <0 )
error (message ('stats:classreg:learning:regr:RegressionEnsemble:cvshrink:BadThre' )); 
end


cvens =crossval (this ,partitionArgs {:}); 
cvens =regularize (cvens ,'lambda' ,lambda ,extraArgs {:}); 
L =numel (lambda ); 
T =numel (thre ); 
crit =zeros (L ,T ); 
nlearn =zeros (L ,T ); 
forl =1 :L 
fort =1 :T 
cvshrunk =shrink (cvens ,'weightcolumn' ,l ,'threshold' ,thre (t )); 
crit (l ,t )=kfoldLoss (cvshrunk ); 
mlearn =0 ; 
forn =1 :cvshrunk .KFold 
mlearn =mlearn +cvshrunk .Trained {n }.NTrained ; 
end
nlearn (l ,t )=mlearn /cvshrunk .KFold ; 
end
end
end
end

end
