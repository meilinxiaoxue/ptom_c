classdef RegressionPartitionedEnsemble <...
    classreg .learning .partition .PartitionedEnsemble &...
    classreg .learning .partition .RegressionPartitionedModel 

















































methods (Hidden )
function this =RegressionPartitionedEnsemble (X ,Y ,W ,modelParams ,...
    dataSummary ,responseTransform )
this =this @classreg .learning .partition .PartitionedEnsemble (); 
this =this @classreg .learning .partition .RegressionPartitionedModel (...
    X ,Y ,W ,modelParams ,dataSummary ,responseTransform ); 
end
end

methods (Access =protected )
function s =propsForDisp (this ,s )
s =propsForDisp @classreg .learning .partition .PartitionedEnsemble (this ,s ); 
s =propsForDisp @classreg .learning .partition .RegressionPartitionedModel (this ,s ); 
end
end

methods (Hidden )
function this =regularize (this ,varargin )
fort =1 :numel (this .Ensemble .Trainable )
this .Ensemble .Trainable {t }=regularize (this .Ensemble .Trainable {t },varargin {:}); 
end
end

function this =shrink (this ,varargin )
ifisempty (this .Ensemble )||isempty (this .Ensemble .Impl )
error (message ('stats:classreg:learning:partition:RegressionPartitionedEnsemble:prune:NoImpl' )); 
end
ifnumel (this .Ensemble .Trainable )~=numel (this .Ensemble .Trained )
error (message ('stats:classreg:learning:partition:RegressionPartitionedEnsemble:prune:MismatchTrainedTrainableSize' )); 
end
fort =1 :numel (this .Ensemble .Trainable )
this .Ensemble .Impl .Trained {t }=...
    shrink (this .Ensemble .Trainable {t },varargin {:}); 
end
end
end

methods 
function l =kfoldLoss (this ,varargin )

































classreg .learning .ensemble .Ensemble .catchUOFL (varargin {:}); 
classreg .learning .FullClassificationRegressionModel .catchWeights (varargin {:}); 
args ={'lossfun' }; 
defs ={@classreg .learning .loss .mse }; 
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
l =loss (this .Ensemble ,this .Ensemble .X ,this .Ensemble .Y ,'lossfun' ,funloss ,...
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

end
