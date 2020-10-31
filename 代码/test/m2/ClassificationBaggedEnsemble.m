classdef ClassificationBaggedEnsemble <...
    classreg .learning .classif .ClassificationEnsemble &classreg .learning .ensemble .BaggedEnsemble 

































































methods (Hidden )
function this =ClassificationBaggedEnsemble (X ,Y ,W ,modelParams ,...
    dataSummary ,classSummary ,scoreTransform )
this =this @classreg .learning .classif .ClassificationEnsemble (X ,Y ,W ,modelParams ,...
    dataSummary ,classSummary ,scoreTransform ); 
this =this @classreg .learning .ensemble .BaggedEnsemble (); 
end
end

methods (Access =protected )
function s =propsForDisp (this ,s )
s =propsForDisp @classreg .learning .classif .ClassificationEnsemble (this ,s ); 
s =propsForDisp @classreg .learning .ensemble .BaggedEnsemble (this ,s ); 
end
end

methods (Static ,Hidden )
function this =fit (~,~,varargin )%#ok<STOUT> 
error (message ('stats:classreg:learning:classif:ClassificationBaggedEnsemble:fit:Noop' )); 
end
end

methods 
function [labels ,scores ]=oobPredict (this ,varargin )



















classreg .learning .ensemble .Ensemble .catchUOFL (varargin {:}); 
classreg .learning .FullClassificationRegressionModel .catchWeights (varargin {:}); 
usenfort =~this .ModelParams .Generator .UseObsForIter ; 
[labels ,scores ]=...
    predict (this ,this .X ,'useobsforlearner' ,usenfort ,varargin {:}); 
end

function l =oobLoss (this ,varargin )







































classreg .learning .ensemble .Ensemble .catchUOFL (varargin {:}); 
classreg .learning .FullClassificationRegressionModel .catchWeights (varargin {:}); 
usenfort =~this .ModelParams .Generator .UseObsForIter ; 
l =loss (this ,this .X ,this .PrivY ,'weights' ,this .W ,...
    'useobsforlearner' ,usenfort ,varargin {:}); 
end

function m =oobMargin (this ,varargin )



















classreg .learning .ensemble .Ensemble .catchUOFL (varargin {:}); 
classreg .learning .FullClassificationRegressionModel .catchWeights (varargin {:}); 
usenfort =~this .ModelParams .Generator .UseObsForIter ; 
m =margin (this ,this .X ,this .PrivY ,...
    'useobsforlearner' ,usenfort ,varargin {:}); 
end

function e =oobEdge (this ,varargin )

























classreg .learning .ensemble .Ensemble .catchUOFL (varargin {:}); 
classreg .learning .FullClassificationRegressionModel .catchWeights (varargin {:}); 
usenfort =~this .ModelParams .Generator .UseObsForIter ; 
e =edge (this ,this .X ,this .PrivY ,'weights' ,this .W ,...
    'useobsforlearner' ,usenfort ,varargin {:}); 
end
end

end

