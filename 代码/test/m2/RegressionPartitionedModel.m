classdef RegressionPartitionedModel <classreg .learning .partition .PartitionedModel 












































properties (GetAccess =public ,SetAccess =public ,Dependent =true )










ResponseTransform ; 
end

methods 
function rt =get .ResponseTransform (this )
rt =this .Ensemble .ResponseTransform ; 
end

function this =set .ResponseTransform (this ,rt )
this .Ensemble .ResponseTransform =rt ; 
end
end

methods (Hidden )
function this =RegressionPartitionedModel (...
    X ,Y ,W ,modelParams ,dataSummary ,responseTransform )
this =this @classreg .learning .partition .PartitionedModel (); 
this .Ensemble =classreg .learning .regr .RegressionEnsemble (...
    X ,Y ,W ,modelParams ,dataSummary ,responseTransform ); 
end
end

methods (Access =protected )
function s =propsForDisp (this ,s )
s =propsForDisp @classreg .learning .partition .PartitionedModel (this ,s ); 
s .ResponseTransform =this .ResponseTransform ; 
end
end

methods 
function yfit =kfoldPredict (this ,varargin )








yfit =kfoldPredict @classreg .learning .partition .PartitionedModel (this ,varargin {:}); 
end

function l =kfoldLoss (this ,varargin )




























classreg .learning .ensemble .Ensemble .catchUOFL (varargin {:}); 
classreg .learning .FullClassificationRegressionModel .catchWeights (varargin {:}); 
[mode ,folds ,args ]=checkFoldArgs (this ,varargin {:}); 
usenfort =~this .Ensemble .ModelParams .Generator .UseObsForIter ; 
l =loss (this .Ensemble ,this .Ensemble .X ,this .Ensemble .PrivY ,'weights' ,this .Ensemble .W ,...
    'useobsforlearner' ,usenfort ,'mode' ,mode ,'learners' ,folds ,args {:}); 
end
end

end
