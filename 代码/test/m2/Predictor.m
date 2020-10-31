classdef (AllowedSubclasses ={?classreg .regr .ParametricRegression })Predictor <classreg .regr .CompactPredictor &classreg .regr .FitObject 











properties (Dependent ,GetAccess ='public' ,SetAccess ='protected' ,Abstract =true )







Fitted 
















Residuals 
end

methods (Abstract ,Access ='protected' )
D =get_diagnostics (model ,type )
end
methods (Access ='protected' )
function r =get_residuals (model )
r =getResponse (model )-predict (model ); 
end

function yfit =get_fitted (model )
compactNotAllowed (model ,'Fitted' ,true ); 
yfit =predict (model ); 
end
end

methods (Access ='public' )
function [AX ]=plotPartialDependence (model ,features ,varargin )
































































































narginchk (2 ,13 ); 
features =convertStringsToChars (features ); 
[varargin {:}]=convertStringsToChars (varargin {:}); 


if(istable (model .Data ))
defaultData =model .Data (:,model .PredictorNames ); 
else
defaultData =model .Data .X ; 
end




p =inputParser ; 
addRequired (p ,'Model' ); 
addRequired (p ,'Var' ); 
addOptional (p ,'Data' ,defaultData ); 
addParameter (p ,'Conditional' ,{'none' ,'absolute' ,'centered' }); 
addParameter (p ,'NumObservationsToSample' ,0 ); 
addParameter (p ,'ParentAxisHandle' ,[]); 
addParameter (p ,'QueryPoints' ,[]); 
addParameter (p ,'UseParallel' ,false ); 
parse (p ,model ,features ,varargin {:}); 
data =p .Results .Data ; 



if(nargin >2 &&~ischar (varargin {1 }))

varargin =varargin (2 :end); 
end


ax =plotPartialDependence @classreg .regr .CompactPredictor ...
    (model ,features ,data ,varargin {:}); 
if(nargout >0 )
AX =ax ; 
end
end
end
end
