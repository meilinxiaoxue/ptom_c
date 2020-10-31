classdef (AllowedSubclasses ={?classreg .regr .Predictor ,?classreg .regr .CompactParametricRegression })CompactPredictor <classreg .regr .CompactFitObject 




methods (Abstract ,Access ='public' )
ypred =predict (model ,varargin )
ysim =random (model ,varargin )
end

methods (Abstract ,Access ='protected' )





ypred =predictPredictorMatrix (model ,Xpred ); 
end

methods (Hidden ,Access ='public' )
function yPred =predictGrid (model ,varargin )

gridMatrices =gridVectors2gridMatrices (model ,varargin ); 
outSize =size (gridMatrices {1 }); 
gridCols =cellfun (@(x )x (:),gridMatrices ,'UniformOutput' ,false ); 
predData =table (gridCols {:},'VariableNames' ,model .PredictorNames ); 
yPred =predict (model ,predData ); 
yPred =reshape (yPred ,outSize ); 
end
end

methods (Access ='public' )
function yPred =feval (model ,varargin )





























npreds =model .NumPredictors ; 
ifisa (varargin {1 },'dataset' )
varargin {1 }=dataset2table (varargin {1 }); 
end
ifnargin -1 ==npreds &&...
    ~(nargin ==2 &&isa (varargin {1 },'table' ))
predArgs =varargin ; 



sizeOut =[1 ,1 ]; 
fori =1 :length (predArgs )
thisarg =predArgs {i }; 
ifischar (thisarg )
ifsize (thisarg ,1 )~=1 
sizeOut =[size (thisarg ,1 ),1 ]; 
break
end
else
if~isscalar (thisarg )
sizeOut =size (thisarg ); 
break
end
end
end


asCols =predArgs ; 
fori =1 :length (predArgs )
thisarg =predArgs {i }; 
ifischar (thisarg )
thisarg =cellstr (thisarg ); 
end
ifisscalar (thisarg )
thisarg =repmat (thisarg ,sizeOut ); 
elseif~isequal (size (predArgs {i }),sizeOut )
error (message ('stats:classreg:regr:Predictor:InputSizeMismatch' )); 
end
asCols {i }=thisarg (:); 
end


Xpred =table (asCols {:},'VariableNames' ,model .PredictorNames ); 
yPred =reshape (predict (model ,Xpred ),sizeOut ); 
elseifnargin ==2 
predVars =varargin {1 }; 
ifisa (predVars ,'table' )
yPred =predict (model ,predVars ); 
else
ifsize (predVars ,2 )~=npreds 
error (message ('stats:classreg:regr:Predictor:BadNumColumns' ,npreds )); 
end
yPred =predictPredictorMatrix (model ,predVars ); 
end
else
error (message ('stats:classreg:regr:Predictor:BadNumInputs' ,npreds ,npreds )); 
end
end

function [AX ]=plotPartialDependence (model ,features ,data ,varargin )

























































































narginchk (3 ,13 ); 


ax =classreg .regr .modelutils .plotPartialDependence (model ,...
    features ,data ,varargin {:}); 
if(nargout >0 )
AX =ax ; 
end
end
end
end
