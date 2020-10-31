function [varargout ]=fitoptimizing (FitFunctionName ,Predictors ,Response ,varargin )

































































































































verifyNoValidationArgs (varargin ); 
[OptimizeHyperparametersArg ,HyperparameterOptimizationOptions ,FitFunctionArgs ]=...
    classreg .learning .paramoptim .parseFitoptimizingArgs (varargin ); 


BOInfo =classreg .learning .paramoptim .BayesoptInfo .makeBayesoptInfo (FitFunctionName ,Predictors ,Response ,FitFunctionArgs ); 
VariableDescriptions =getVariableDescriptions (BOInfo ,OptimizeHyperparametersArg ); 


[ValidationMethod ,ValidationVal ]=getPassedValidationArgs (HyperparameterOptimizationOptions ); 
objFcn =classreg .learning .paramoptim .createObjFcn (BOInfo ,FitFunctionArgs ,Predictors ,Response ,...
    ValidationMethod ,ValidationVal ,HyperparameterOptimizationOptions .Repartition ,HyperparameterOptimizationOptions .Verbose ); 


switchHyperparameterOptimizationOptions .Optimizer 
case 'bayesopt' 
[OptimizationResults ,XBest ]=doBayesianOptimization (objFcn ,BOInfo ,VariableDescriptions ,HyperparameterOptimizationOptions ); 
case 'gridsearch' 
[OptimizationResults ,XBest ]=doNonBayesianOptimization ('grid' ,objFcn ,BOInfo ,VariableDescriptions ,HyperparameterOptimizationOptions ); 
case 'randomsearch' 
[OptimizationResults ,XBest ]=doNonBayesianOptimization ('random' ,objFcn ,BOInfo ,VariableDescriptions ,HyperparameterOptimizationOptions ); 
end


ifisempty (XBest )
classreg .learning .paramoptim .warn ('NoFinalModel' ); 
[varargout {1 :nargout }]=[]; 
else
ifBOInfo .CanStoreResultsInModel 
[varargout {1 :nargout }]=classreg .learning .paramoptim .fitToFullDataset (XBest ,BOInfo ,...
    FitFunctionArgs ,Predictors ,Response ); 
varargout {1 }=setParameterOptimizationResults (varargout {1 },OptimizationResults ); 
elseifnargout ==BOInfo .OutputArgumentPosition 

[varargout {1 :nargout -1 }]=classreg .learning .paramoptim .fitToFullDataset (XBest ,BOInfo ,...
    FitFunctionArgs ,Predictors ,Response ); 
varargout {BOInfo .OutputArgumentPosition }=OptimizationResults ; 
else

[varargout {1 :nargout }]=classreg .learning .paramoptim .fitToFullDataset (XBest ,BOInfo ,...
    FitFunctionArgs ,Predictors ,Response ); 
end
end
end

function [OptimizationResults ,XBest ]=doBayesianOptimization (objFcn ,BOInfo ,...
    VariableDescriptions ,HyperparameterOptimizationOptions )

ifHyperparameterOptimizationOptions .ShowPlots 
PlotFcn ={@plotMinObjective }; 
ifsum ([VariableDescriptions .Optimize ])<=2 
PlotFcn {end+1 }=@plotObjectiveModel ; 
end
else
PlotFcn ={}; 
end
ifHyperparameterOptimizationOptions .SaveIntermediateResults 
OutputFcn =@assignInBase ; 
else
OutputFcn ={}; 
end

OptimizationResults =bayesopt (objFcn ,VariableDescriptions ,...
    'AcquisitionFunctionName' ,HyperparameterOptimizationOptions .AcquisitionFunctionName ,...
    'MaxObjectiveEvaluations' ,HyperparameterOptimizationOptions .MaxObjectiveEvaluations ,...
    'MaxTime' ,HyperparameterOptimizationOptions .MaxTime ,...
    'XConstraintFcn' ,BOInfo .XConstraintFcn ,...
    'ConditionalVariableFcn' ,BOInfo .ConditionalVariableFcn ,...
    'Verbose' ,HyperparameterOptimizationOptions .Verbose ,...
    'UseParallel' ,HyperparameterOptimizationOptions .UseParallel ,...
    'PlotFcn' ,PlotFcn ,...
    'OutputFcn' ,OutputFcn ,...
    'AlwaysReportObjectiveErrors' ,true ); 

XBest =chooseBestPointBayesopt (OptimizationResults ); 
end

function [OptimizationResults ,XBest ]=doNonBayesianOptimization (AFName ,objFcn ,BOInfo ,...
    VariableDescriptions ,HyperparameterOptimizationOptions )

ifHyperparameterOptimizationOptions .ShowPlots 
PlotFcn ={@plotMinObjective }; 
else
PlotFcn ={}; 
end

BOResults =bayesopt (objFcn ,VariableDescriptions ,...
    'AcquisitionFunctionName' ,AFName ,...
    'NumGridDivisions' ,HyperparameterOptimizationOptions .NumGridDivisions ,...
    'FitModels' ,false ,...
    'MaxObjectiveEvaluations' ,HyperparameterOptimizationOptions .MaxObjectiveEvaluations ,...
    'MaxTime' ,HyperparameterOptimizationOptions .MaxTime ,...
    'ConditionalVariableFcn' ,BOInfo .ConditionalVariableFcn ,...
    'XConstraintFcn' ,BOInfo .XConstraintFcn ,...
    'Verbose' ,HyperparameterOptimizationOptions .Verbose ,...
    'UseParallel' ,HyperparameterOptimizationOptions .UseParallel ,...
    'PlotFcn' ,PlotFcn ,...
    'OutputFcn' ,[],...
    'AlwaysReportObjectiveErrors' ,true ); 

XBest =chooseBestPointNonBayesopt (BOResults ); 

OptimizationResults =BOResults .XTrace ; 
OptimizationResults .Objective =BOResults .ObjectiveTrace ; 
OptimizationResults .Rank =rankVector (BOResults .ObjectiveTrace ); 
end

function R =rankVector (V )
R =zeros (size (V )); 
[~,I ]=sort (V ); 
R (I )=1 :numel (V ); 
end

function BestXTable =chooseBestPointBayesopt (BO )

BestXTable =bestPoint (BO ); 
ifisempty (BestXTable )
BestXTable =bestPoint (BO ,'Criterion' ,'minobserved' ); 
end
end

function XBest =chooseBestPointNonBayesopt (BO )
ifisfinite (BO .MinObjective )
XBest =BO .XAtMinObjective ; 
else
XBest =[]; 
end
end

function verifyNoValidationArgs (Args )
ifclassreg .learning .paramoptim .anyArgPassed ({'CrossVal' ,'CVPartition' ,'Holdout' ,'KFold' ,'Leaveout' },Args )
classreg .learning .paramoptim .err ('ValidationArgLocation' ); 
end
end

function [ValidationMethod ,ValidationVal ]=getPassedValidationArgs (ParamOptimOptions )

if~isempty (ParamOptimOptions .KFold )
ValidationMethod ='KFold' ; 
ValidationVal =ParamOptimOptions .KFold ; 
elseif~isempty (ParamOptimOptions .Holdout )
ValidationMethod ='Holdout' ; 
ValidationVal =ParamOptimOptions .Holdout ; 
elseif~isempty (ParamOptimOptions .CVPartition )
ValidationMethod ='CVPartition' ; 
ValidationVal =ParamOptimOptions .CVPartition ; 
end
end
