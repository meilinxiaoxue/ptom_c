classdef BayesoptInfoCECOC <classreg .learning .paramoptim .BayesoptInfo 




properties (Constant )
ECOCVariableDescriptions =optimizableVariable ('Coding' ,{'onevsall' ,'onevsone' }); 
end

properties 
FitFcn =@fitcecoc ; 
PrepareDataFcn =@ClassificationECOC .prepareData ; 
AllVariableDescriptions ; 
end

properties (Access =protected )
LearnerOptInfo ; 

WeakLearnerTemplate ; 
end

methods 
function this =BayesoptInfoCECOC (Predictors ,Response ,FitFunctionArgs )
this @classreg .learning .paramoptim .BayesoptInfo (Predictors ,Response ,FitFunctionArgs ,false ,false ); 

this .WeakLearnerTemplate =getWeakLearnerTemplate (this ,FitFunctionArgs ); 
switchthis .WeakLearnerTemplate .Method 
case 'Discriminant' 
BOInfoFcn =@classreg .learning .paramoptim .BayesoptInfoCDiscr ; 
case 'KNN' 
BOInfoFcn =@classreg .learning .paramoptim .BayesoptInfoCKNN ; 
case 'Linear' 
BOInfoFcn =@classreg .learning .paramoptim .BayesoptInfoCLinear ; 
case 'SVM' 
BOInfoFcn =@classreg .learning .paramoptim .BayesoptInfoCSVM ; 
case 'Tree' 
BOInfoFcn =@classreg .learning .paramoptim .BayesoptInfoCTree ; 
otherwise
classreg .learning .paramoptim .err ('BadTemplate' ,this .WeakLearnerTemplate .Method ); 
end
this .LearnerOptInfo =BOInfoFcn (Predictors ,Response ,FitFunctionArgs ); 

this .AllVariableDescriptions =[...
    classreg .learning .paramoptim .BayesoptInfoCECOC .ECOCVariableDescriptions ; 
 this .LearnerOptInfo .AllVariableDescriptions ]; 
this .ConditionalVariableFcn =this .LearnerOptInfo .ConditionalVariableFcn ; 

ifisequal (this .WeakLearnerTemplate .Method ,'Linear' )
this .CanStoreResultsInModel =false ; 
end
end

function Template =getWeakLearnerTemplate (this ,FitFunctionArgs )
LearnersArg =classreg .learning .paramoptim .parseArg ('Learners' ,FitFunctionArgs ); 
Template =templateFromLearnersArg (LearnersArg ); 
end

function Args =updateArgsFromTable (this ,FitFunctionArgs ,XTable )


ECOCXTable =getECOCXTable (XTable ); 
Args =updateArgsFromTable @classreg .learning .paramoptim .BayesoptInfo (this ,FitFunctionArgs ,ECOCXTable ); 
NewLearnerArg =updateLearnerArgFromTable (this ,FitFunctionArgs ,'Learners' ,XTable ); 
Args =[Args ,NewLearnerArg ]; 
end
end

methods (Access =protected )
function NVP =updateLearnerArgFromTable (this ,FitFunctionArgs ,ArgName ,XTable )




import classreg.learning.paramoptim.* 
Value =parseArg (ArgName ,FitFunctionArgs ); 
ifisempty (Value )

Value ='SVM' ; 
end

Template =templateFromLearnersArg (Value ); 

Template .ModelParams =this .LearnerOptInfo .substModelParams (Template .ModelParams ,XTable ); 
NVP ={ArgName ,Template }; 
end
end
end

function Template =templateFromLearnersArg (Value )
import classreg.learning.paramoptim.* 
ifisempty (Value )
Value ='SVM' ; 
end
ifisa (Value ,'classreg.learning.FitTemplate' )
Template =fillIfNeeded (Value ,'classification' ); 
elseifischar (Value )
ifprefixMatch (Value ,'Discriminant' )
Template =templateDiscriminant ; 
elseifprefixMatch (Value ,'KNN' )
Template =templateKNN ; 
elseifprefixMatch (Value ,'Linear' )
Template =templateLinear ; 
elseifprefixMatch (Value ,'SVM' )
Template =templateSVM ; 
elseifprefixMatch (Value ,'Tree' )
Template =templateTree ('type' ,'classification' ); 
else
classreg .learning .paramoptim .err ('BadECOCLearner' ,Value ); 
end
else
classreg .learning .paramoptim .err ('BadLearnerType' ); 
end
end

function ECOCTable =getECOCXTable (XTable )
import classreg.learning.paramoptim.* 

ECOCNames ={BayesoptInfoCECOC .ECOCVariableDescriptions .Name }; 
[~,ECOCLocs ]=ismember (ECOCNames ,XTable .Properties .VariableNames ); 
ECOCLocs (ECOCLocs ==0 )=[]; 
ECOCTable =XTable (:,ECOCLocs ); 
end


