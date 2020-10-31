classdef BayesoptInfoRLinear <classreg .learning .paramoptim .BayesoptInfo 




properties 
FitFcn =@fitrlinear ; 
PrepareDataFcn =@RegressionLinear .prepareData ; 
AllVariableDescriptions 
end

methods 
function this =BayesoptInfoRLinear (Predictors ,Response ,FitFunctionArgs )
this @classreg .learning .paramoptim .BayesoptInfo (Predictors ,Response ,FitFunctionArgs ,...
    classreg .learning .paramoptim .observationsInColumns (FitFunctionArgs ),true ); 
this .AllVariableDescriptions =[...
    optimizableVariable ('Lambda' ,[(1e-5 )/this .NumObservations ,(1e5 )/this .NumObservations ],...
    'Transform' ,'log' ); 
 optimizableVariable ('Learner' ,{'svm' ,'leastsquares' }); 
 optimizableVariable ('Regularization' ,{'ridge' ,'lasso' },...
    'Optimize' ,false )]; 
this .CanStoreResultsInModel =false ; 
this .OutputArgumentPosition =3 ; 
end
end
end