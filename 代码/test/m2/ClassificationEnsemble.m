classdef ClassificationEnsemble <...
    classreg .learning .classif .FullClassificationModel &classreg .learning .ensemble .Ensemble ...
    &classreg .learning .classif .CompactClassificationEnsemble 























































methods (Hidden )
function this =ClassificationEnsemble (X ,Y ,W ,modelParams ,...
    dataSummary ,classSummary ,scoreTransform ,adjustprior )
ifnargin <8 
adjustprior =true ; 
end
ifadjustprior 
[classSummary ,W ]=...
    classreg .learning .internal .adjustPrior (classSummary ,Y ,W ); 
end
this =this @classreg .learning .classif .FullClassificationModel (X ,Y ,W ,modelParams ,...
    dataSummary ,classSummary ,scoreTransform ); 
this =this @classreg .learning .ensemble .Ensemble (); 
this =this @classreg .learning .classif .CompactClassificationEnsemble (...
    dataSummary ,classSummary ,scoreTransform ,[],[],[],[],[]); 
this .DefaultScore =this .ModelParams .DefaultScore ; 
nlearn =this .ModelParams .NLearn /numel (this .ModelParams .LearnerTemplates ); 
this =fitEnsemble (this ,nlearn ); 
ifisa (this .ModelParams .Generator ,'classreg.learning.generator.SubspaceSampler' )
this .UsePredForLearner =this .ModelParams .Generator .UsePredForIter ; 
end

this .DefaultScoreType ='unknown' ; 
switchthis .Method 
case {'AdaBoostM1' ,'AdaBoostM2' ,'AdaBoostMH' ,'RobustBoost' ...
    ,'LogitBoost' ,'GentleBoost' ,'RUSBoost' }

this .DefaultScoreType ='inf' ; 
ifismember (this .Method ,{'AdaBoostM1' ,'LogitBoost' ,'GentleBoost' })
this .TransformToProbability =...
    @classreg .learning .transform .doublelogit ; 
ifstrcmp (this .Method ,'LogitBoost' )
this .PrivContinuousLoss =@classreg .learning .loss .binodeviance ; 
else
this .PrivContinuousLoss =@classreg .learning .loss .exponential ; 
end
end
case {'Bag' ,'Subspace' }
isprob =true ; 
ifthis .NTrained >0 
fort =1 :this .NTrained 
lrn =this .Trained {t }; 
if~strcmp (lrn .ScoreType ,'probability' )
isprob =false ; 
break; 
end
end
end
ifisprob 
this .DefaultScoreType ='probability' ; 
this .TransformToProbability =...
    @classreg .learning .transform .identity ; 
this .PrivContinuousLoss =@classreg .learning .loss .quadratic ; 
end
otherwise
this .DefaultScoreType ='01' ; 
this .PrivContinuousLoss =@classreg .learning .loss .quadratic ; 
end
end

function l =aggregateLoss (this ,T ,funloss ,combiner ,fpredict ,trained ,...
    varargin )


[X ,C ,W ]=prepareDataForLoss (this ,this .X ,this .PrivY ,this .W ,[],true ,true ); 
l =classreg .learning .ensemble .CompactEnsemble .aggregateLoss (...
    T ,X ,C ,W ,this .Cost ,funloss ,combiner ,fpredict ,trained ,...
    this .ClassSummary .ClassNames ,this .ClassSummary .NonzeroProbClasses ,...
    this .PrivScoreTransform ,this .DefaultScore ,...
    varargin {:}); 
end
end

methods (Static ,Hidden )
function this =fit (X ,Y ,varargin )
warning (message ('stats:classreg:learning:classif:ClassificationEnsemble:fit:Noop' )); 
args ={'method' }; 
defs ={'' }; 
[method ,~,extraArgs ]=...
    internal .stats .parseArgs (args ,defs ,varargin {:}); 
temp =classreg .learning .FitTemplate .make (method ,'type' ,'classification' ,extraArgs {:}); 
this =fit (temp ,X ,Y ); 
end
end

methods 
function cmp =compact (this )








cmp =classreg .learning .classif .CompactClassificationEnsemble (...
    this .DataSummary ,this .ClassSummary ,...
    this .PrivScoreTransform ,this .PrivScoreType ,...
    this .UsePredForLearner ,...
    this .DefaultScore ,this .PrivContinuousLoss ,this .TransformToProbability ); 
ifthis .ModelParams .SortLearnersByWeight 
cmp .Impl =sortLearnersByWeight (this .Impl ); 
else
cmp .Impl =this .Impl ; 
end
cmp .DefaultScoreType =this .DefaultScoreType ; 
end

function partModel =crossval (this ,varargin )





























partModel =crossval @classreg .learning .classif .FullClassificationModel (this ,varargin {:}); 
end

function this =resume (this ,nlearn ,varargin )















ifisempty (nlearn )||~isnumeric (nlearn )||~isscalar (nlearn )||nlearn <=0 
error (message ('stats:classreg:learning:classif:ClassificationEnsemble:resume:BadNLearn' )); 
end
nlearn =ceil (nlearn ); 
this .ModelParams .NPrint =...
    classreg .learning .ensemble .Ensemble .checkNPrint (varargin {:}); 
this .ModelParams .NLearn =this .ModelParams .NLearn +...
    nlearn *numel (this .ModelParams .LearnerTemplates ); 
this =fitEnsemble (this ,nlearn ); 
ifisa (this .ModelParams .Generator ,'classreg.learning.generator.SubspaceSampler' )
this .UsePredForLearner =this .ModelParams .Generator .UsePredForIter ; 
end
end

function [labels ,scores ]=resubPredict (this ,varargin )
















classreg .learning .ensemble .Ensemble .catchUOFL (varargin {:}); 
[labels ,scores ]=...
    resubPredict @classreg .learning .classif .FullClassificationModel (this ,varargin {:}); 
end

function m =resubMargin (this ,varargin )
















classreg .learning .ensemble .Ensemble .catchUOFL (varargin {:}); 
m =resubMargin @classreg .learning .classif .FullClassificationModel (this ,varargin {:}); 
end

function e =resubEdge (this ,varargin )






















classreg .learning .ensemble .Ensemble .catchUOFL (varargin {:}); 
e =resubEdge @classreg .learning .classif .FullClassificationModel (this ,varargin {:}); 
end

function l =resubLoss (this ,varargin )







































classreg .learning .ensemble .Ensemble .catchUOFL (varargin {:}); 
l =resubLoss @classreg .learning .classif .FullClassificationModel (this ,varargin {:}); 
end
end

methods (Access =protected )
function s =propsForDisp (this ,s )
s =propsForDisp @classreg .learning .classif .FullClassificationModel (this ,s ); 
s =propsForDisp @classreg .learning .ensemble .Ensemble (this ,s ); 
end

function this =fitEnsemble (this ,nlearn )

[this ,trained ,generator ,modifier ,combiner ]=...
    fitWeakLearners (this ,nlearn ,this .ModelParams .NPrint ); 


this .ModelParams .Generator =generator ; 
this .ModelParams .Modifier =modifier ; 


this .Impl =classreg .learning .impl .CompactEnsembleImpl (trained ,combiner ); 
end
end

end
