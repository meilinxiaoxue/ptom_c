classdef BayesoptInfoRTree <classreg .learning .paramoptim .BayesoptInfo 



properties 
FitFcn =@fitrtree ; 
PrepareDataFcn =@RegressionTree .prepareData ; 
AllVariableDescriptions ; 
end

methods 
function this =BayesoptInfoRTree (Predictors ,Response ,FitFunctionArgs )
this @classreg .learning .paramoptim .BayesoptInfo (Predictors ,Response ,FitFunctionArgs ,false ,true ); 
this .AllVariableDescriptions =[...
    optimizableVariable ('MinLeafSize' ,[1 ,max (2 ,floor (this .NumObservations /2 ))],...
    'Type' ,'integer' ,'Transform' ,'log' ); 
 optimizableVariable ('MaxNumSplits' ,[1 ,max (2 ,this .NumObservations -1 )],...
    'Type' ,'integer' ,'Transform' ,'log' ,...
    'Optimize' ,false ); 
 optimizableVariable ('NumVariablesToSample' ,[1 ,max (2 ,this .NumPredictors )],...
    'Type' ,'integer' ,'Optimize' ,false )]; 
this .ModelParamNameMap =struct ('MinLeafSize' ,'MinLeaf' ,...
    'MaxNumSplits' ,'MaxSplits' ,...
    'NumVariablesToSample' ,'NVarToSample' ); 
this .ConditionalVariableFcn =createCVF (this ); 
end
end

methods (Access =protected )
function fcn =createCVF (this )
fcn =@fitrtreeCVF ; 
function XTable =fitrtreeCVF (XTable )




ifclassreg .learning .paramoptim .BayesoptInfo .hasVariables (XTable ,{'NumVariablesToSample' })
XTable .NumVariablesToSample (:)=this .NumPredictors ; 
end
end
end
end
end
