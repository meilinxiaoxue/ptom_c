classdef BayesoptInfoCSVM <classreg .learning .paramoptim .BayesoptInfo 



properties 
FitFcn =@fitcsvm ; 
PrepareDataFcn =@ClassificationSVM .prepareData ; 
AllVariableDescriptions =[...
    optimizableVariable ('BoxConstraint' ,[1e-3 ,1e3 ],'Transform' ,'log' ); 
 optimizableVariable ('KernelScale' ,[1e-3 ,1e3 ],'Transform' ,'log' ); 
 optimizableVariable ('KernelFunction' ,{'gaussian' ,'linear' ,'polynomial' },...
    'Optimize' ,false ); 
 optimizableVariable ('PolynomialOrder' ,[2 ,4 ],'Type' ,'integer' ,...
    'Optimize' ,false ); 
 optimizableVariable ('Standardize' ,{'true' ,'false' },...
    'Optimize' ,false )]; 
end

methods 
function this =BayesoptInfoCSVM (Predictors ,Response ,FitFunctionArgs )
this @classreg .learning .paramoptim .BayesoptInfo (Predictors ,Response ,FitFunctionArgs ,false ,false ); 
this .ModelParamNameMap =struct ('BoxConstraint' ,'BoxConstraint' ,...
    'KernelFunction' ,'KernelFunction' ,...
    'KernelScale' ,'KernelScale' ,...
    'PolynomialOrder' ,'KernelPolynomialOrder' ,...
    'Standardize' ,'StandardizeData' ); 
this .ConditionalVariableFcn =createCVF (this ); 
end
end
end

function fcn =createCVF (this )
fcn =@fitcsvmCVF ; 
function XTable =fitcsvmCVF (XTable )

ifclassreg .learning .paramoptim .BayesoptInfo .hasVariables (XTable ,{'PolynomialOrder' ,'KernelFunction' })
XTable .PolynomialOrder (XTable .KernelFunction ~='polynomial' )=NaN ; 
end

ifclassreg .learning .paramoptim .BayesoptInfo .hasVariables (XTable ,{'KernelScale' ,'KernelFunction' })
XTable .KernelScale (~ismember (XTable .KernelFunction ,{'rbf' ,'gaussian' }))=NaN ; 
end

ifthis .NumClasses ==1 &&classreg .learning .paramoptim .BayesoptInfo .hasVariables (XTable ,{'BoxConstraint' })
XTable .BoxConstraint (:)=1 ; 
end
end
end