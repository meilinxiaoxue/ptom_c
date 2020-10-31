classdef BayesoptInfoCEnsemble <classreg .learning .paramoptim .BayesoptInfo 




properties 
FitFcn =@fitcensemble ; 
PrepareDataFcn =@classreg .learning .classif .FullClassificationModel .prepareData ; 
AllVariableDescriptions ; 
CEnsembleVariableDescriptions ; 
end

properties (Access =protected )
LearnerOptInfo ; 

WeakLearnerTemplate ; 
end

methods 
function this =BayesoptInfoCEnsemble (Predictors ,Response ,FitFunctionArgs )
this @classreg .learning .paramoptim .BayesoptInfo (Predictors ,Response ,FitFunctionArgs ,false ,false ); 

switchthis .NumClasses 
case 2 
MethodVar =optimizableVariable ('Method' ,{'Bag' ,'GentleBoost' ,'LogitBoost' ,'AdaBoostM1' ,'RUSBoost' }); 
otherwise
MethodVar =optimizableVariable ('Method' ,{'Bag' ,'AdaBoostM2' ,'RUSBoost' }); 
end

this .CEnsembleVariableDescriptions =[...
    MethodVar ; 
 optimizableVariable ('NumLearningCycles' ,[10 ,500 ],'Type' ,'integer' ,'Transform' ,'log' ); 
 optimizableVariable ('LearnRate' ,[1e-3 ,1 ],'Transform' ,'log' )]; 

this .WeakLearnerTemplate =getWeakLearnerTemplate (this ,FitFunctionArgs ); 
switchthis .WeakLearnerTemplate .Method 
case 'Discriminant' 
this .LearnerOptInfo =classreg .learning .paramoptim .BayesoptInfoCDiscr (Predictors ,Response ,FitFunctionArgs ); 
case 'KNN' 
this .LearnerOptInfo =classreg .learning .paramoptim .BayesoptInfoCKNN (Predictors ,Response ,FitFunctionArgs ); 
case 'Tree' 
this .LearnerOptInfo =classreg .learning .paramoptim .BayesoptInfoCTree (Predictors ,Response ,FitFunctionArgs ); 
otherwise
classreg .learning .paramoptim .err ('BadTemplate' ,this .WeakLearnerTemplate .Method ); 
end

this .AllVariableDescriptions =[this .CEnsembleVariableDescriptions ; 
 this .LearnerOptInfo .AllVariableDescriptions ]; 

this .ConditionalVariableFcn =createCVF (this ); 
this .XConstraintFcn =createXCF (this ); 
end

function Template =getWeakLearnerTemplate (this ,FitFunctionArgs )
LearnersArg =classreg .learning .paramoptim .parseArg ('Learners' ,FitFunctionArgs ); 
MethodArg =classreg .learning .paramoptim .parseArg ('Method' ,FitFunctionArgs ); 
Template =templateFromLearnersArg (LearnersArg ,MethodArg ); 
end

function Args =updateArgsFromTable (this ,FitFunctionArgs ,XTable )


EnsembleXTable =getEnsembleXTable (this ,XTable ); 
Args =updateArgsFromTable @classreg .learning .paramoptim .BayesoptInfo (this ,FitFunctionArgs ,EnsembleXTable ); 
NewLearnerArgs =updateLearnersArgFromTable (this ,Args ,XTable ); 
Args =[Args ,NewLearnerArgs ]; 
end
end

methods (Access =protected )
function NVP =updateLearnersArgFromTable (this ,FitFunctionArgs ,XTable )





import classreg.learning.paramoptim.* 
LearnersArg =classreg .learning .paramoptim .parseArg ('Learners' ,FitFunctionArgs ); 
MethodArg =classreg .learning .paramoptim .parseArg ('Method' ,FitFunctionArgs ); 

Template =templateFromLearnersArg (LearnersArg ,MethodArg ); 

Template .ModelParams =this .LearnerOptInfo .substModelParams (Template .ModelParams ,XTable ); 








Template =classreg .learning .FitTemplate .makeFromModelParams (Template .ModelParams ); 
NVP ={'Learners' ,Template }; 
end

function fcn =createCVF (this )
fcn =@fitcensembleCVF ; 
function XTable =fitcensembleCVF (XTable )
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

ifBayesoptInfo .hasVariables (XTable ,{'Method' ,'NumVariablesToSample' })
XTable .NumVariablesToSample (XTable .Method ~='Bag' )=NaN ; 
end



ifBayesoptInfo .hasVariables (XTable ,{'Method' ,'SplitCriterion' })
XTable .SplitCriterion (XTable .Method =='LogitBoost' )='<undefined>' ; 
XTable .SplitCriterion (XTable .Method =='GentleBoost' )='<undefined>' ; 
end
end
end

function fcn =createXCF (this )
fcn =@fitcensembleXCF ; 
function TF =fitcensembleXCF (XTable )
import classreg.learning.paramoptim.* 
TF =true (height (XTable ),1 ); 

if~isempty (this .LearnerOptInfo .XConstraintFcn )
TF =TF &this .LearnerOptInfo .XConstraintFcn (XTable ); 
end
end
end
end

end

function Template =templateFromLearnersArg (Learners ,Method )
import classreg.learning.paramoptim.* 
ifisempty (Learners )
ifisempty (Method )
Learners =templateTree ('MaxNumSplits' ,10 ); 
elseifischar (Method )
switchlower (Method )
case 'bag' 
Learners ='Tree' ; 
case 'subspace' 
Learners ='KNN' ; 
otherwise
Learners =templateTree ('MaxNumSplits' ,10 ); 
end
else
classreg .learning .paramoptim .err ('BadMethodType' ); 
end
end
ifisa (Learners ,'classreg.learning.FitTemplate' )
Template =fillIfNeeded (Learners ,'classification' ); 
elseifischar (Learners )
ifprefixMatch (Learners ,'Discriminant' )
Template =templateDiscriminant ; 
elseifprefixMatch (Learners ,'KNN' )
Template =templateKNN ; 
elseifprefixMatch (Learners ,'Tree' )
Template =templateTree ('type' ,'classification' ); 
else
classreg .learning .paramoptim .err ('BadEnsembleLearner' ,Learners ); 
end
else
classreg .learning .paramoptim .err ('BadLearnerType' ); 
end
end

function EnsembleXTable =getEnsembleXTable (this ,XTable )
import classreg.learning.paramoptim.* 

CEnsembleNames ={this .CEnsembleVariableDescriptions .Name }; 
[~,CEnsembleLocs ]=ismember (CEnsembleNames ,XTable .Properties .VariableNames ); 
CEnsembleLocs (CEnsembleLocs ==0 )=[]; 
EnsembleXTable =XTable (:,CEnsembleLocs ); 
end

