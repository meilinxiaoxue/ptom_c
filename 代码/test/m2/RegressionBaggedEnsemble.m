classdef RegressionBaggedEnsemble <...
    classreg .learning .regr .RegressionEnsemble &classreg .learning .ensemble .BaggedEnsemble 



























































methods (Hidden )
function this =RegressionBaggedEnsemble (X ,Y ,W ,modelParams ,...
    dataSummary ,responseTransform )
this =this @classreg .learning .regr .RegressionEnsemble (...
    X ,Y ,W ,modelParams ,dataSummary ,responseTransform ); 
this =this @classreg .learning .ensemble .BaggedEnsemble (); 
end
end

methods (Access =protected )
function s =propsForDisp (this ,s )
s =propsForDisp @classreg .learning .regr .RegressionEnsemble (this ,s ); 
s =propsForDisp @classreg .learning .ensemble .BaggedEnsemble (this ,s ); 
end
end

methods (Static ,Hidden )
function this =fit (~,~,varargin )%#ok<STOUT> 
error (message ('stats:classreg:learning:regr:RegressionBaggedEnsemble:fit:Noop' )); 
end
end

methods 
function yfit =oobPredict (this ,varargin )

















classreg .learning .ensemble .Ensemble .catchUOFL (varargin {:}); 
classreg .learning .FullClassificationRegressionModel .catchWeights (varargin {:}); 
usenfort =~this .ModelParams .Generator .UseObsForIter ; 
yfit =predict (this ,this .X ,'useobsforlearner' ,usenfort ,varargin {:}); 
end

function l =oobLoss (this ,varargin )




























classreg .learning .ensemble .Ensemble .catchUOFL (varargin {:}); 
classreg .learning .FullClassificationRegressionModel .catchWeights (varargin {:}); 
usenfort =~this .ModelParams .Generator .UseObsForIter ; 
l =loss (this ,this .X ,this .PrivY ,'weights' ,this .W ,...
    'useobsforlearner' ,usenfort ,varargin {:}); 
end
end

end
