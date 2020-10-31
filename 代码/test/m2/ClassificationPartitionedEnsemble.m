classdef ClassificationPartitionedEnsemble <...
    classreg .learning .partition .PartitionedEnsemble &...
    classreg .learning .partition .ClassificationPartitionedModel 






















































methods (Hidden )
function this =ClassificationPartitionedEnsemble (X ,Y ,W ,modelParams ,...
    dataSummary ,classSummary ,scoreTransform )
this =this @classreg .learning .partition .PartitionedEnsemble (); 
this =this @classreg .learning .partition .ClassificationPartitionedModel (...
    X ,Y ,W ,modelParams ,dataSummary ,classSummary ,scoreTransform ); 
end
end

methods (Access =protected )
function scoreType =getScoreType (this )
scoreType =getScoreType @classreg .learning .partition .ClassificationPartitionedModel (this ); 
ifthis .Ensemble .NTrained >0 ...
    &&isequal (this .PrivScoreTransform ,this .Ensemble .Trained {1 }.TransformToProbability )
scoreType ='probability' ; 
end
end

function cl =getContinuousLoss (this )
cl =[]; 
ifthis .Ensemble .NTrained >0 
ifisequal (this .PrivScoreTransform ,@classreg .learning .transform .identity )
cl =this .Ensemble .Trained {1 }.ContinuousLoss ; 
elseifisequal (this .PrivScoreTransform ,this .Ensemble .Trained {1 }.TransformToProbability )
cl =@classreg .learning .loss .quadratic ; 
end
end
end

function s =propsForDisp (this ,s )
s =propsForDisp @classreg .learning .partition .PartitionedEnsemble (this ,s ); 
s =propsForDisp @classreg .learning .partition .ClassificationPartitionedModel (this ,s ); 
end
end

methods 
function e =kfoldEdge (this ,varargin )






















e =kfoldLoss (this ,'lossfun' ,@classreg .learning .loss .classifedge ,varargin {:}); 
end

function l =kfoldLoss (this ,varargin )











































classreg .learning .ensemble .Ensemble .catchUOFL (varargin {:}); 
classreg .learning .FullClassificationRegressionModel .catchWeights (varargin {:}); 
args ={'lossfun' }; 
defs ={@classreg .learning .loss .classiferror }; 
[funloss ,~,extraArgs ]=...
    internal .stats .parseArgs (args ,defs ,varargin {:}); 

usenfort =~this .Ensemble .ModelParams .Generator .UseObsForIter ; 
[mode ,folds ,partArgs ]=checkEnsembleFoldArgs (this ,extraArgs {:}); 
ifstrcmp (mode ,'cumulative' )
T =min (this .NTrainedPerFold (folds )); 
D =numel (this .Ensemble .PredictorNames ); 
trained =this .Ensemble .Impl .Trained (folds ); 
useDinFold =classreg .learning .partition .PartitionedEnsemble .usePredInFold (...
    folds ,T ,D ,trained ); 
l =aggregateLoss (this .Ensemble ,T ,funloss ,this .Combiner (folds ),...
    @classreg .learning .partition .PartitionedEnsemble .predictKfoldWithCache ,...
    trained ,...
    'useobsforlearner' ,usenfort (:,folds ),'mode' ,mode ,...
    'usepredforlearner' ,useDinFold ,partArgs {:}); 
else
l =loss (this .Ensemble ,this .Ensemble .X ,this .Ensemble .PrivY ,'lossfun' ,funloss ,...
    'weights' ,this .Ensemble .W ,'useobsforlearner' ,usenfort ,'mode' ,mode ,...
    'learners' ,folds ,partArgs {:}); 
end
end

function this =resume (this ,nlearn ,varargin )

















nprint =classreg .learning .ensemble .Ensemble .checkNPrint (varargin {:}); 
trainable =resumePartitionedWithPrint (this ,nlearn ,nprint ); 
T =numel (trainable ); 
trained =cell (T ,1 ); 
fort =1 :T 
trained {t }=compact (trainable {t }); 
end
this .Ensemble .Trainable =trainable ; 
this .Ensemble .Impl .Trained =trained ; 
end
end

methods (Static ,Hidden )
function this =loadobj (obj )
ifisempty (obj .PrivScoreTransform )
this =classreg .learning .partition .ClassificationPartitionedEnsemble (...
    obj .Ensemble .X ,obj .Ensemble .PrivY ,obj .Ensemble .W ,...
    obj .Ensemble .ModelParams ,...
    obj .Ensemble .DataSummary ,obj .Ensemble .ClassSummary ,...
    obj .Ensemble .PrivScoreTransform ); 
else

this =obj ; 
end
end
end

end
