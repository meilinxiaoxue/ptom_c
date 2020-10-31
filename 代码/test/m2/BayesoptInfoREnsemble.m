classdef BayesoptInfoREnsemble <classreg .learning .paramoptim .BayesoptInfo 




properties (Constant )
REnsembleVariableDescriptions =[...
    optimizableVariable ('Method' ,{'Bag' ,'LSBoost' }); 
 optimizableVariable ('NumLearningCycles' ,[10 ,500 ],'Type' ,'integer' ,'Transform' ,'log' ); 
 optimizableVariable ('LearnRate' ,[1e-3 ,1 ],'Transform' ,'log' )]; 
end

properties 
FitFcn =@fitrensemble ; 
PrepareDataFcn =@classreg .learning .regr .FullRegressionModel .prepareData ; 
AllVariableDescriptions ; 
end

properties (Access =protected )
LearnerOptInfo ; 

WeakLearnerTemplate ; 
end

methods 
function this =BayesoptInfoREnsemble (Predictors ,Response ,FitFunctionArgs )
import classreg.learning.paramoptim.* 
this @classreg .learning .paramoptim .BayesoptInfo (Predictors ,Response ,FitFunctionArgs ,false ,true ); 

this .WeakLearnerTemplate =getWeakLearnerTemplate (this ,FitFunctionArgs ); 
if~isequal (this .WeakLearnerTemplate .Method ,'Tree' )
classreg .learning .paramoptim .err ('BadTemplate' ,this .WeakLearnerTemplate .Method ); 
end
this .LearnerOptInfo =BayesoptInfoRTree (Predictors ,Response ,FitFunctionArgs ); 

this .AllVariableDescriptions =[...
    BayesoptInfoREnsemble .REnsembleVariableDescriptions ; 
 this .LearnerOptInfo .AllVariableDescriptions ]; 

this .ConditionalVariableFcn =createCVF (this ); 
this .XConstraintFcn =createXCF (this ); 
end

function Template =getWeakLearnerTemplate (this ,FitFunctionArgs )
LearnersArg =classreg .learning .paramoptim .parseArg ('Learners' ,FitFunctionArgs ); 
Template =templateFromLearnersArg (LearnersArg ); 
end

function Args =updateArgsFromTable (this ,FitFunctionArgs ,XTable )


EnsembleXTable =getEnsembleXTable (XTable ); 
Args =updateArgsFromTable @classreg .learning .paramoptim .BayesoptInfo (this ,FitFunctionArgs ,EnsembleXTable ); 
NewLearnersArgs =updateREnsembleLearnerArgFromTable (this ,FitFunctionArgs ,'Learners' ,XTable ); 
Args =[Args ,NewLearnersArgs ]; 
end
end

methods (Access =protected )
function NVP =updateREnsembleLearnerArgFromTable (this ,FitFunctionArgs ,ArgName ,XTable )




import classreg.learning.paramoptim.* 
Value =parseArg (ArgName ,FitFunctionArgs ); 
ifisempty (Value )

Value ='Tree' ; 
end

Template =templateFromLearnersArg (Value ); 

Template .ModelParams =this .LearnerOptInfo .substModelParams (Template .ModelParams ,XTable ); 
NVP ={ArgName ,Template }; 
end

function fcn =createCVF (this )
fcn =@fitrensembleCVF ; 
function XTable =fitrensembleCVF (XTable )
import classreg.learning.paramoptim.* 

if~isempty (this .LearnerOptInfo .ConditionalVariableFcn )

ifBayesoptInfo .hasVariables (XTable ,{'NumVariablesToSample' })
NumVariablesToSample =XTable .NumVariablesToSample ; 
end

XTable =this .LearnerOptInfo .ConditionalVariableFcn (XTable ); 

ifBayesoptInfo .hasVariables (XTable ,{'NumVariablesToSample' })
XTable .NumVariablesToSample =NumVariablesToSample ; 
end
end

ifBayesoptInfo .hasVariables (XTable ,{'Method' ,'LearnRate' })
XTable .LearnRate (XTable .Method =='Bag' )=NaN ; 
end
end
end

function fcn =createXCF (this )
fcn =@fitrensembleXCF ; 
function TF =fitrensembleXCF (XTable )
import classreg.learning.paramoptim.* 
TF =true (height (XTable ),1 ); 

if~isempty (this .LearnerOptInfo .XConstraintFcn )
TF =TF &this .LearnerOptInfo .XConstraintFcn (XTable ); 
end
end
end
end
end

function Template =templateFromLearnersArg (Value )
import classreg.learning.paramoptim.* 
ifisempty (Value )
Value ='Tree' ; 
end
ifisa (Value ,'classreg.learning.FitTemplate' )
Template =fillIfNeeded (Value ,'regression' ); 
elseifischar (Value )
ifprefixMatch (Value ,'Tree' )
Template =templateTree ('type' ,'regression' ); 
end
else
classreg .learning .paramoptim .err ('BadLearnerType' ); 
end
end

function EnsembleXTable =getEnsembleXTable (XTable )
import classreg.learning.paramoptim.* 

REnsembleNames ={BayesoptInfoREnsemble .REnsembleVariableDescriptions .Name }; 
[~,REnsembleLocs ]=ismember (REnsembleNames ,XTable .Properties .VariableNames ); 
REnsembleLocs (REnsembleLocs ==0 )=[]; 
EnsembleXTable =XTable (:,REnsembleLocs ); 
end

