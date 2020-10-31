classdef BayesoptInfo 








properties (Abstract )

FitFcn 


PrepareDataFcn 



AllVariableDescriptions 
end

properties 


XConstraintFcn =[]; 



ConditionalVariableFcn =[]; 




CanStoreResultsInModel =true ; 



OutputArgumentPosition =2 ; 






ModelParamNameMap =[]; 



IsRegression ; 
end

methods 




function Args =updateArgsFromTable (this ,FitFunctionArgs ,XTable )
ReducedFitFunctionArgs =deleteEliminatedParams (FitFunctionArgs ,XTable ); 
ArgsFromTable =classreg .learning .paramoptim .BayesoptInfo .argsFromTable (XTable ); 
Args =[ReducedFitFunctionArgs ,ArgsFromTable ]; 
end







function VariableDescriptions =getVariableDescriptions (this ,OptimizeHyperparametersArg )


OptimizeHyperparametersArg =checkAndCompleteOptimizeHyperparametersArg (OptimizeHyperparametersArg ,...
    this .AllVariableDescriptions ); 
ifisequal (OptimizeHyperparametersArg ,'auto' )
VariableDescriptions =this .AllVariableDescriptions ; 
elseifisequal (OptimizeHyperparametersArg ,'all' )
VariableDescriptions =this .AllVariableDescriptions ; 
forv =1 :numel (VariableDescriptions )
VariableDescriptions (v ).Optimize =true ; 
end
elseifiscellstr (OptimizeHyperparametersArg )
VariableDescriptions =enableOptimization (OptimizeHyperparametersArg ,this .AllVariableDescriptions ); 
elseifisa (OptimizeHyperparametersArg ,'optimizableVariable' )
VariableDescriptions =OptimizeHyperparametersArg ; 
end
end
end


methods (Static )


function Obj =makeBayesoptInfo (FitFunctionName ,Predictors ,Response ,FitFunctionArgs )
switchFitFunctionName 
case 'fitcdiscr' 
ConstructorFcn =@classreg .learning .paramoptim .BayesoptInfoCDiscr ; 
case 'fitcecoc' 
ConstructorFcn =@classreg .learning .paramoptim .BayesoptInfoCECOC ; 
case 'fitcensemble' 
ConstructorFcn =@classreg .learning .paramoptim .BayesoptInfoCEnsemble ; 
case 'fitcknn' 
ConstructorFcn =@classreg .learning .paramoptim .BayesoptInfoCKNN ; 
case 'fitclinear' 
ConstructorFcn =@classreg .learning .paramoptim .BayesoptInfoCLinear ; 
case 'fitcnb' 
ConstructorFcn =@classreg .learning .paramoptim .BayesoptInfoCNB ; 
case 'fitcsvm' 
ConstructorFcn =@classreg .learning .paramoptim .BayesoptInfoCSVM ; 
case 'fitctree' 
ConstructorFcn =@classreg .learning .paramoptim .BayesoptInfoCTree ; 
case 'fitrensemble' 
ConstructorFcn =@classreg .learning .paramoptim .BayesoptInfoREnsemble ; 
case 'fitrgp' 
ConstructorFcn =@classreg .learning .paramoptim .BayesoptInfoRGP ; 
case 'fitrlinear' 
ConstructorFcn =@classreg .learning .paramoptim .BayesoptInfoRLinear ; 
case 'fitrsvm' 
ConstructorFcn =@classreg .learning .paramoptim .BayesoptInfoRSVM ; 
case 'fitrtree' 
ConstructorFcn =@classreg .learning .paramoptim .BayesoptInfoRTree ; 
otherwise
classreg .learning .paramoptim .err ('UnknownFitFcn' ,FitFunctionName ); 
end
Obj =ConstructorFcn (Predictors ,Response ,FitFunctionArgs ); 
end


function tf =hasVariables (Tbl ,VarNames )

tf =all (ismember (VarNames ,Tbl .Properties .VariableNames )); 
end

function ModelParams =setModelParamsProperty (ModelParams ,...
    ParamName ,PropName ,Tbl )



ifismember (ParamName ,Tbl .Properties .VariableNames )
ifisnan (double (Tbl .(ParamName )))
ModelParams .(PropName )=cast ([],class (ModelParams .(PropName ))); 
else
ModelParams .(PropName )=classreg .learning .paramoptim .prepareArgValue (Tbl .(ParamName )); 
end
end
end

function Args =argsFromTable (XTable )


Args ={}; 
forv =1 :width (XTable )
if~isnan (double (XTable {1 ,v }))
Args =[Args ,{XTable .Properties .VariableNames {v },...
    classreg .learning .paramoptim .prepareArgValue (XTable {1 ,v })}]; 
end
end
end
end


properties (Access =protected )

NumObservations ; 
NumPredictors ; 
MaxPredictorRange ; 
MinPredictorDiff ; 
ResponseIqr ; 
ResponseStd ; 
NumClasses ; 
CategoricalPredictorIndices ; 
end

methods (Access =protected )
function this =BayesoptInfo (Predictors ,Response ,FitFunctionArgs ,ObservationsInCols ,IsRegression )
this .IsRegression =IsRegression ; 


ifObservationsInCols 
AccumDim =2 ; 
else
AccumDim =1 ; 
end
ifistable (Predictors )
[Predictors ,Response ,vrange ,wastable ,FitFunctionArgs ]=classreg .learning .internal .table2FitMatrix (...
    Predictors ,Response ,FitFunctionArgs {:}); 
end

ifIsRegression &&~isnumeric (Response )
classreg .learning .paramoptim .err ('NonNumericYInRegression' ); 
end
this .NumObservations =size (Predictors ,AccumDim ); 
this .NumPredictors =size (Predictors ,3 -AccumDim ); 

ifisnumeric (Predictors )
this .MaxPredictorRange =max (nanmax (Predictors ,[],AccumDim )-nanmin (Predictors ,[],AccumDim )); 
ifthis .MaxPredictorRange ==0 
this .MinPredictorDiff =0 ; 
else
diffs =diff (sort (Predictors ,AccumDim ),1 ,AccumDim ); 
this .MinPredictorDiff =nanmin (diffs (diffs ~=0 )); 
end
else
this .MaxPredictorRange =NaN ; 
this .MinPredictorDiff =NaN ; 
end

ifisnumeric (Response )
this .ResponseIqr =iqr (Response ); 
this .ResponseStd =nanstd (Response ); 
else
this .ResponseIqr =NaN ; 
this .ResponseStd =NaN ; 
end

[ClassNamesPassed ,~,~]=internal .stats .parseArgs ({'ClassNames' },{[]},FitFunctionArgs {:}); 
this .NumClasses =numClasses (Response ,ClassNamesPassed ); 

[CPs ,~,~]=internal .stats .parseArgs ({'CategoricalPredictors' },{[]},FitFunctionArgs {:}); 
this .CategoricalPredictorIndices =CPs ; 
end

function ModelParams =substModelParams (this ,ModelParams ,XTable )




import classreg.learning.paramoptim.* 
ParameterNames =fieldnames (this .ModelParamNameMap ); 
fori =1 :numel (ParameterNames )
ModelParams =BayesoptInfo .setModelParamsProperty (ModelParams ,ParameterNames {i },...
    this .ModelParamNameMap .(ParameterNames {i }),XTable ); 
end
end
end
end

function N =numClasses (Y ,ClassNamesPassed )
ifisempty (ClassNamesPassed )
N =numel (levels (classreg .learning .internal .ClassLabel (Y ))); 
else
N =numel (levels (classreg .learning .internal .ClassLabel (ClassNamesPassed ))); 
end
end

function ParameterNames =checkAndCompleteParameterNames (ParameterNames ,LegalParameterNames )


ArgList =repmat ({true },1 ,2 *numel (ParameterNames )); 
ArgList (1 :2 :end)=ParameterNames ; 
Defaults =repmat ({false },1 ,numel (LegalParameterNames )); 
[values {1 :numel (LegalParameterNames )},~,extra ]=internal .stats .parseArgs (...
    LegalParameterNames ,Defaults ,ArgList {:}); 
if~isempty (extra )
classreg .learning .paramoptim .err ('ParamNotOptimizable' ,extra {1 },cellstr2str (LegalParameterNames )); 
end
ParameterNames =LegalParameterNames ([values {:}]); 
end

function VariableDescriptions =enableOptimization (OptimizeHyperparameters ,...
    AllVariableDescriptions )
VariableDescriptions =AllVariableDescriptions ; 
fori =1 :numel (VariableDescriptions )
VariableDescriptions (i ).Optimize =ismember (...
    VariableDescriptions (i ).Name ,OptimizeHyperparameters ); 
end
end

function OptimizeHyperparameters =checkAndCompleteOptimizeHyperparametersArg (OptimizeHyperparameters ,LegalVariableDescriptions )

LegalVariableNames ={LegalVariableDescriptions .Name }; 
ifisequal (OptimizeHyperparameters ,'auto' )||isequal (OptimizeHyperparameters ,'all' )
return ; 
elseifiscellstr (OptimizeHyperparameters )
OptimizeHyperparameters =checkAndCompleteParameterNames (OptimizeHyperparameters ,LegalVariableNames ); 
elseifisa (OptimizeHyperparameters ,'optimizableVariable' )
checkAndCompleteParameterNames ({OptimizeHyperparameters .Name },LegalVariableNames ); 
else
classreg .learning .paramoptim .err ('OptimizeHyperparameters' ); 
end
end

function Args =deleteEliminatedParams (Args ,XTable )

forv =1 :width (XTable )
ifisnan (double (XTable {1 ,v }))
FullVarName =XTable .Properties .VariableNames {v }; 
NameLocs =find (cellfun (@(P )classreg .learning .paramoptim .prefixMatch (P ,FullVarName ),...
    Args (1 :2 :end))); 
NVPLocs =[2 *NameLocs -1 ,2 *NameLocs ]; 
Args (NVPLocs )=[]; 
end
end
end

function s =cellstr2str (C )

ifisempty (C )
s ='' ; 
else
s =C {1 }; 
end
fori =2 :numel (C )
s =[s ,', ' ,C {i }]; 
end
end
