classdef BayesoptInfoRGP <classreg .learning .paramoptim .BayesoptInfo 



properties 
FitFcn =@fitrgp ; 
PrepareDataFcn =@RegressionGP .prepareData ; 
AllVariableDescriptions ; 
end

methods 
function this =BayesoptInfoRGP (Predictors ,Response ,FitFunctionArgs )
this @classreg .learning .paramoptim .BayesoptInfo (Predictors ,Response ,FitFunctionArgs ,false ,true ); 
MaxPredictorRange =this .MaxPredictorRange ; 
ifMaxPredictorRange ==0 
MaxPredictorRange =1 ; 
end
this .AllVariableDescriptions =[...
    optimizableVariable ('Sigma' ,[1e-4 ,max (1e-3 ,10 *this .ResponseStd )],'Transform' ,'log' ); 
 optimizableVariable ('BasisFunction' ,{'constant' ,'none' ,'linear' ,'pureQuadratic' },...
    'Optimize' ,false ); 
 optimizableVariable ('KernelFunction' ,{'ardexponential' ,'ardmatern32' ,...
    'ardmatern52' ,'ardrationalquadratic' ,'ardsquaredexponential' ,...
    'exponential' ,'matern32' ,'matern52' ,'rationalquadratic' ,'squaredexponential' },...
    'Optimize' ,false ); 
 optimizableVariable ('KernelScale' ,[1e-3 *MaxPredictorRange ,MaxPredictorRange ],...
    'Transform' ,'log' ,...
    'Optimize' ,false ); 
 optimizableVariable ('Standardize' ,{'true' ,'false' },...
    'Optimize' ,false )]; 
this .ConditionalVariableFcn =@fitrgpCVF ; 
end
end

methods 
function Args =updateArgsFromTable (this ,FitFunctionArgs ,XTable )
import classreg.learning.paramoptim.* 
NewArgs ={}; 


ifBayesoptInfo .hasVariables (XTable ,{'KernelScale' })&&~isnan (XTable .KernelScale )
[KernelParameters ,ConstantKernelParameters ]=kernelParamArgsForKernel (...
    FitFunctionArgs ,XTable ); 
NewArgs =[NewArgs ,{'KernelParameters' ,KernelParameters ,...
    'ConstantKernelParameters' ,ConstantKernelParameters }]; 
XTable .KernelScale =[]; 
end


ifBayesoptInfo .hasVariables (XTable ,{'Sigma' })&&~isnan (XTable .Sigma )
NewArgs =[NewArgs ,{'Sigma' ,prepareArgValue (XTable .Sigma ),...
    'ConstantSigma' ,true }]; 
XTable .Sigma =[]; 
end

NormalArgs =updateArgsFromTable @classreg .learning .paramoptim .BayesoptInfo (this ,FitFunctionArgs ,XTable ); 


ifBayesoptInfo .hasVariables (XTable ,{'KernelScale' })&&isnan (XTable .KernelScale )
NormalArgs =deleteKernelParametersArg (NormalArgs ); 
end

Args =[NormalArgs ,NewArgs ]; 
end
end
end

function XTable =fitrgpCVF (XTable )

ifclassreg .learning .paramoptim .BayesoptInfo .hasVariables (XTable ,{'KernelFunction' ,'KernelScale' })
ARDRows =ismember (XTable .KernelFunction ,{'ardexponential' ,'ardmatern32' ,...
    'ardmatern52' ,'ardrationalquadratic' ,'ardsquaredexponential' }); 
XTable .KernelScale (ARDRows )=NaN ; 
end
end

function Args =deleteKernelParametersArg (Args )

NameLocs =find (cellfun (@(P )classreg .learning .paramoptim .prefixMatch (P ,'KernelParameters' ),...
    Args (1 :2 :end))); 
NVPLocs =[2 *NameLocs -1 ,2 *NameLocs ]; 
Args (NVPLocs )=[]; 
end

function [KernelParameters ,ConstantKernelParameters ]=kernelParamArgsForKernel (...
    FitFunctionArgs ,XTable )





import classreg.learning.paramoptim.* 


KernelFunction ='' ; 
ifclassreg .learning .paramoptim .BayesoptInfo .hasVariables (XTable ,{'KernelFunction' })&&...
    ~isundefined (XTable .KernelFunction )
KernelFunction =XTable .KernelFunction ; 
else

string ='kernelf' ; 
KFLoc =find (cellfun (@(t )strncmpi (string ,t ,numel (string )),lower (FitFunctionArgs (1 :2 :end)))); 
if~isempty (KFLoc )
KernelFunction =FitFunctionArgs {KFLoc *2 }; 
end
end

switchKernelFunction 
case 'rationalquadratic' 
KernelParameters =[prepareArgValue (XTable .KernelScale ); 1 ; 1 ]; 
ConstantKernelParameters =[true ; false ; false ]; 
otherwise
KernelParameters =[prepareArgValue (XTable .KernelScale ); 1 ]; 
ConstantKernelParameters =[true ; false ]; 
end
end
