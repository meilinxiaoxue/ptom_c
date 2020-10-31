classdef BayesoptInfoCNB <classreg .learning .paramoptim .BayesoptInfo 



properties 
FitFcn =@fitcnb ; 
PrepareDataFcn =@ClassificationNaiveBayes .prepareData ; 
AllVariableDescriptions ; 
end

methods 
function this =BayesoptInfoCNB (Predictors ,Response ,FitFunctionArgs )
this @classreg .learning .paramoptim .BayesoptInfo (Predictors ,Response ,FitFunctionArgs ,false ,false ); 
MinPredictorDiff =this .MinPredictorDiff ; 
ifMinPredictorDiff ==0 
MinPredictorDiff =1 ; 
end
MaxPredictorRange =this .MaxPredictorRange ; 
ifMaxPredictorRange ==0 
MaxPredictorRange =1 ; 
end
this .AllVariableDescriptions =[...
    optimizableVariable ('DistributionNames' ,{'normal' ,'kernel' }); 
 optimizableVariable ('Width' ,[MinPredictorDiff /4 ,max (MaxPredictorRange ,MinPredictorDiff )],...
    'Transform' ,'log' ); 
 optimizableVariable ('Kernel' ,{'normal' ,'box' ,'epanechnikov' ,'triangle' },...
    'Optimize' ,false )]; 
this .ConditionalVariableFcn =@fitcnbCVF ; 
end

function Args =updateArgsFromTable (this ,FitFunctionArgs ,XTable )
import classreg.learning.paramoptim.* 

Args =updateArgsFromTable @classreg .learning .paramoptim .BayesoptInfo (this ,FitFunctionArgs ,XTable ); 



ifBayesoptInfo .hasVariables (XTable ,{'DistributionNames' })&&any (this .CategoricalPredictorIndices )

DNames =repmat ({char (XTable .DistributionNames )},1 ,this .NumPredictors ); 
DNames (this .CategoricalPredictorIndices )={'mvmn' }; 
XTable .DistributionNames =[]; 
ArgsToAppend ={'DistributionNames' ,DNames }; 
Args =[Args ,ArgsToAppend ]; 
end
end

function VariableDescriptions =getVariableDescriptions (this ,OptimizeHyperparametersArg )



VariableDescriptions =getVariableDescriptions @classreg .learning .paramoptim .BayesoptInfo (...
    this ,OptimizeHyperparametersArg ); 

ifoptimizingKernelWidth (VariableDescriptions )
bayesoptim .warn ('StandardizeIfOptimizingNBKernelWidth' ); 
end
end
end
end

function XTable =fitcnbCVF (XTable )

import classreg.learning.paramoptim.* 
ifBayesoptInfo .hasVariables (XTable ,{'DistributionNames' ,'Kernel' })
XTable .Kernel (XTable .DistributionNames ~='kernel' )='<undefined>' ; 
end
ifBayesoptInfo .hasVariables (XTable ,{'DistributionNames' ,'Width' })
XTable .Width (XTable .DistributionNames ~='kernel' )=NaN ; 
end
end

function tf =optimizingKernelWidth (VariableDescriptions )
tf =false ; 
fori =1 :numel (VariableDescriptions )
ifVariableDescriptions (i ).Optimize &&isequal (VariableDescriptions (i ).Name ,'Width' )
tf =true ; 
return ; 
end
end
end
