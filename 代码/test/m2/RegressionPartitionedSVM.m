classdef RegressionPartitionedSVM <classreg .learning .partition .RegressionPartitionedModel 












































methods (Hidden )
function this =RegressionPartitionedSVM (...
    X ,Y ,W ,modelParams ,dataSummary ,responseTransform )
this =this @classreg .learning .partition .RegressionPartitionedModel (...
    X ,Y ,W ,modelParams ,dataSummary ,responseTransform ); 

end
end
methods 

function l =kfoldLoss (this ,varargin )


































classreg .learning .ensemble .Ensemble .catchUOFL (varargin {:}); 
classreg .learning .FullClassificationRegressionModel .catchWeights (varargin {:}); 

[mode ,folds ,args ]=checkFoldArgs (this ,varargin {:}); 
usenfort =~this .Ensemble .ModelParams .Generator .UseObsForIter ; 

arglist ={'lossfun' }; 
defs ={@classreg .learning .loss .mse }; 
[funloss ,~,extraArgs ]=...
    internal .stats .parseArgs (arglist ,defs ,args {:}); 
ifstrncmpi (funloss ,'epsiloninsensitive' ,length (funloss ))
f2 =@classreg .learning .loss .epsiloninsensitive ; 
funloss =@(Y ,Yfit ,W )(f2 (Y ,Yfit ,W ,this .Trained {1 }.Impl .Epsilon )); 
end
l =loss (this .Ensemble ,this .Ensemble .X ,this .Ensemble .PrivY ,'weights' ,this .Ensemble .W ,...
    'useobsforlearner' ,usenfort ,'mode' ,mode ,'learners' ,folds ,'lossfun' ,funloss ,extraArgs {:}); 

end
end

end
