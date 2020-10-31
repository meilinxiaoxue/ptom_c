classdef EnsembleParams <classreg .learning .modelparams .ModelParams 





















properties 
LearnerTemplates =[]; 
NLearn =[]; 
LearnRate =[]; 
MarginPrecision =[]; 
RobustErrorGoal =[]; 
RobustMaxMargin =[]; 
RobustMarginSigma =[]; 
SortLearnersByWeight =[]; 
NPrint =[]; 
PrintMsg ='' ; 
Generator =[]; 
Modifier =[]; 
SaveTrainable =[]; 
DefaultScore =[]; 
end

properties (GetAccess =protected ,SetAccess =protected )
GeneratorArgs ={}; 
end

methods (Access =protected )
function this =EnsembleParams (type ,method ,learnerTemplates ,...
    nlearn ,learnRate ,marprec ,rbeps ,rbtheta ,rbsigma ,...
    sortlearners ,nprint ,printmsg ,saveTrainable ,defaultScore ,...
    generatorArgs )
this =this @classreg .learning .modelparams .ModelParams (method ,type ); 
this .LearnerTemplates =learnerTemplates ; 
this .NLearn =nlearn ; 
this .LearnRate =learnRate ; 
this .MarginPrecision =marprec ; 
this .RobustErrorGoal =rbeps ; 
this .RobustMaxMargin =rbtheta ; 
this .RobustMarginSigma =rbsigma ; 
this .SortLearnersByWeight =sortlearners ; 
this .NPrint =ceil (nprint ); 
this .PrintMsg =printmsg ; 
this .SaveTrainable =saveTrainable ; 
this .GeneratorArgs =generatorArgs ; 
this .DefaultScore =defaultScore ; 
end
end

methods (Static ,Hidden )
function [holder ,extraArgs ]=make (type ,varargin )

args ={'method' ,'learners' ,'nlearn' ,'learnrate' ,'marginprecision' ...
    ,'robusterrorgoal' ,'robustmaxmargin' ,'robustmarginsigma' ...
    ,'sortlearners' ...
    ,'nprint' ,'printmsg' ,'savetrainable' ,'defaultscore' }; 
defs ={'' ,{},[],[],[]...
    ,[]...
    ,[],[],[]...
    ,[],'' ,[],NaN }; 
[method ,learnerTemplates ,nlearn ,learnRate ,marprec ,...
    robustErrorGoal ,robustMaxMargin ,robustMarginSigma ,...
    sortlearners ,nprint ,msg ,saveTrainable ,defaultScore ,~,...
    extraArgs ]=...
    internal .stats .parseArgs (args ,defs ,varargin {:}); 

if~ismember (method ,[classreg .learning .ensembleModels ()...
    ,{'PartitionedModel' ,'PartitionedEnsemble' ,'PartitionedECOC' ...
    ,'PartitionedLinear' ,'PartitionedLinearECOC' }])
error (message ('stats:classreg:learning:modelparams:EnsembleParams:make:BadMethod' ,method )); 
end

if~isempty (learnRate )&&...
    (~isnumeric (learnRate )||~isscalar (learnRate )...
    ||learnRate <=0 ||learnRate >1 )
error (message ('stats:classreg:learning:modelparams:EnsembleParams:make:BadLearnRate' )); 
end
if~isempty (learnRate )&&...
    ~ismember (method ,{'AdaBoostM1' ,'AdaBoostM2' ,'AdaBoostMH' ...
    ,'LogitBoost' ,'GentleBoost' ,'LSBoost' ,'RUSBoost' ...
    ,'PartitionedEnsemble' })
error (message ('stats:classreg:learning:modelparams:EnsembleParams:make:NoLearnRateForAlg' )); 
end

if~isempty (marprec )&&(~isnumeric (marprec )||~isscalar (marprec )...
    ||marprec <0 ||marprec >1 )
error (message ('stats:classreg:learning:modelparams:EnsembleParams:make:BadMarginPrecision' )); 
end
if~isempty (marprec )&&~ismember (method ,{'LPBoost' ,'TotalBoost' ,'PartitionedEnsemble' })
error (message ('stats:classreg:learning:modelparams:EnsembleParams:make:DisallowMarginPrecision' ,method )); 
end

if~isempty (robustErrorGoal )&&...
    (~isnumeric (robustErrorGoal )||~isscalar (robustErrorGoal )...
    ||robustErrorGoal <0 ||robustErrorGoal >1 )
error (message ('stats:classreg:learning:modelparams:EnsembleParams:make:BadRobustErrorGoal' )); 
end

if~isempty (robustMaxMargin )&&...
    (~isnumeric (robustMaxMargin )||~isscalar (robustMaxMargin )||robustMaxMargin <0 )
error (message ('stats:classreg:learning:modelparams:EnsembleParams:make:BadRobustMaxMargin' )); 
end

if~isempty (robustMarginSigma )&&...
    (~isnumeric (robustMarginSigma )||~isscalar (robustMarginSigma )...
    ||robustMarginSigma <0 )
error (message ('stats:classreg:learning:modelparams:EnsembleParams:make:BadRobustMarginSigma' )); 
end

if(~isempty (robustErrorGoal )||~isempty (robustMaxMargin )||~isempty (robustMarginSigma ))...
    &&~ismember (method ,{'RobustBoost' ,'PartitionedEnsemble' })
error (message ('stats:classreg:learning:modelparams:EnsembleParams:make:BadRobustParams' ,method )); 
end

if~isempty (sortlearners )
if~strcmpi (sortlearners ,'off' )&&~strcmpi (sortlearners ,'on' )
error (message ('stats:classreg:learning:modelparams:EnsembleParams:make:BadSortLearners' )); 
end
sortlearners =strcmpi (sortlearners ,'on' ); 
end

if~isempty (nprint )&&~strcmpi (nprint ,'off' )&&...
    (~isnumeric (nprint )||~isscalar (nprint )||nprint <0 )
error (message ('stats:classreg:learning:modelparams:EnsembleParams:make:BadNPrint' )); 
end
ifisnumeric (nprint )
nprint =ceil (nprint ); 
end

if~isempty (msg )&&~ischar (msg )
error (message ('stats:classreg:learning:modelparams:EnsembleParams:make:BadMsg' )); 
end

if~isempty (saveTrainable )&&...
    ~strcmpi (saveTrainable ,'on' )&&~strcmpi (saveTrainable ,'off' )...
    &&(~islogical (saveTrainable )||~isscalar (saveTrainable ))
error (message ('stats:classreg:learning:modelparams:EnsembleParams:make:BadSaveTrainable' )); 
end

if~isempty (defaultScore )&&~isnumeric (defaultScore )
error (message ('stats:classreg:learning:modelparams:EnsembleParams:make:BadDefaultScore' )); 
end





[dobag ,sampleArgs ,extraArgs ]=...
    classreg .learning .generator .Resampler .processArgs (extraArgs {:}); 
[fresample ,replace ]=...
    classreg .learning .generator .Resampler .getArgsFromCellstr (sampleArgs {:}); 
ifdobag 
resample ='on' ; 
else
resample ='off' ; 
end

[~,partitionArgs ,extraArgs ]=...
    classreg .learning .generator .Partitioner .processArgs (extraArgs {:}); 
[cvpart ,kfold ,holdout ,leaveout ]=...
    classreg .learning .generator .Partitioner .getArgsFromCellstr (partitionArgs {:}); 

[dosubspace ,subspaceArgs ,extraArgs ]=...
    classreg .learning .generator .SubspaceSampler .processArgs (extraArgs {:}); 
[npredtosample ,exhaustive ]=...
    classreg .learning .generator .SubspaceSampler .getArgsFromCellstr (subspaceArgs {:}); 

if~ismember (method ,{'Subspace' ,'PartitionedEnsemble' })&&dosubspace 
error (message ('stats:classreg:learning:modelparams:EnsembleParams:make:SubspaceArgsWithoutSubspace' )); 
end

[dorus ,undersamplerArgs ,extraArgs ]=...
    classreg .learning .generator .MajorityUndersampler .processArgs (extraArgs {:}); 
ratioToSmallest =...
    classreg .learning .generator .MajorityUndersampler .getArgsFromCellstr (undersamplerArgs {:}); 

if~ismember (method ,{'RUSBoost' ,'PartitionedEnsemble' })&&dorus 
error (message ('stats:classreg:learning:modelparams:EnsembleParams:make:RatioToSmallestWithoutRUSBoost' )); 
end
ifstrcmp (method ,'RUSBoost' )&&isempty (ratioToSmallest )
ratioToSmallest ='default' ; 
end

generatorArgs ={resample ,fresample ,replace ...
    ,cvpart ,kfold ,holdout ,leaveout ...
    ,npredtosample ,exhaustive ,ratioToSmallest }; 


if~iscell (learnerTemplates )...
    &&~isa (learnerTemplates ,'classreg.learning.FitTemplate' )...
    &&~ischar (learnerTemplates )
error (message ('stats:classreg:learning:modelparams:EnsembleParams:make:BadLearnerTemplates' )); 
end
ifischar (learnerTemplates )
learnerTemplates =classreg .learning .FitTemplate .make (learnerTemplates ); 
end
ifisa (learnerTemplates ,'classreg.learning.FitTemplate' )
learnerTemplates ={learnerTemplates }; 
end


ifischar (nlearn )
Ttodo =nlearn ; 
else
Ttodo =nlearn *numel (learnerTemplates ); 
end


holder =classreg .learning .modelparams .EnsembleParams (...
    type ,method ,learnerTemplates ,...
    Ttodo ,learnRate ,marprec ,...
    robustErrorGoal ,robustMaxMargin ,robustMarginSigma ,...
    sortlearners ,nprint ,msg ,saveTrainable ,defaultScore ,...
    generatorArgs ); 
end
end


methods (Access =protected )
function group =getPropertyGroups (this )
plist =struct ; 

plist .Type =this .Type ; 
plist .Method =this .Method ; 

str ='' ; 
fori =1 :numel (this .LearnerTemplates )
temp =this .LearnerTemplates {i }; 
ifstrcmp (temp .Method ,'ByBinaryRegr' )
temp =temp .ModelParams .RegressionTemplate ; 
end
str =[str ,sprintf ('%s' ,temp .Method )]; %#ok<AGROW> 
end
plist .LearnerTemplates =str ; 

plist .NLearn =this .NLearn ; 

ifismember (this .Method ,...
    {'AdaBoostM1' ,'AdaBoostM2' ,'AdaBoostMH' ...
    ,'LogitBoost' ,'GentleBoost' ,'LSBoost' ,'RUSBoost' })
plist .LearnRate =this .LearnRate ; 
end

ifismember (this .Method ,{'LPBoost' ,'TotalBoost' })
plist .MarginPrecision =this .MarginPrecision ; 
end

ifstrcmp (this .Method ,'RobustBoost' )
plist .RobustErrorGoal =this .RobustErrorGoal ; 
plist .RobustMaxMargin =this .RobustMaxMargin ; 
plist .RobustMarginSigma =this .RobustMarginSigma ; 
end

group =matlab .mixin .util .PropertyGroup (plist ,'' ); 
end
end


methods (Hidden )
function gen =makeGenerator (this ,X ,Y ,W ,fitData ,dataSummary ,classSummary )

type =this .Type ; 


args =this .GeneratorArgs ; 
resample =lower (args {1 }); 
fresample =args {2 }; 
replace =lower (args {3 }); 
cvpart =args {4 }; 
kfold =args {5 }; 
holdout =args {6 }; 
leaveout =lower (args {7 }); 



ifnumel (args )<8 
npredtosample =[]; 
else
npredtosample =args {8 }; 
end
ifnumel (args )<9 
exhaustive =false ; 
else
exhaustive =args {9 }; 
end
ifnumel (args )<10 
ratioToSmallest =[]; 
else
ratioToSmallest =args {10 }; 
end





if~strcmp (resample ,'on' )&&~strcmp (resample ,'off' )
error (message ('stats:classreg:learning:modelparams:EnsembleParams:makeGenerator:BadResample' )); 
end
resample =strcmp (resample ,'on' ); 



crossval =~isempty (cvpart )||~isempty (kfold )||...
    ~isempty (holdout )||strcmp (leaveout ,'on' ); 


rusboost =~isempty (ratioToSmallest ); 


subspace =~isempty (npredtosample ); 







ifresample +crossval +subspace +rusboost >1 
error (message ('stats:classreg:learning:modelparams:EnsembleParams:makeGenerator:TooManyGeneratorsRequested' )); 
end





ifresample 
gen =classreg .learning .generator .Resampler (X ,Y ,W ,fitData ,...
    fresample ,replace ); 
return ; 
end

ifcrossval 
gen =classreg .learning .generator .Partitioner (X ,Y ,W ,fitData ,...
    cvpart ,type ,kfold ,holdout ,leaveout ,dataSummary .ObservationsInRows ); 
return ; 
end

ifsubspace 
gen =classreg .learning .generator .SubspaceSampler (X ,Y ,W ,fitData ,...
    dataSummary .PredictorNames ,npredtosample ,exhaustive ,dataSummary .CategoricalPredictors ); 
return ; 
end

ifrusboost 
gen =classreg .learning .generator .MajorityUndersampler (X ,Y ,W ,...
    fitData ,classSummary .ClassNames ,ratioToSmallest ); 
return ; 
end


gen =classreg .learning .generator .BlankGenerator (X ,Y ,W ,fitData ); 
end

function mod =makeModifier (this ,X ,Y ,W ,classSummary )
ifstrcmp (this .Type ,'classification' )...
    &&any (ismember (this .Method ,{'LSBoost' }))
error (message ('stats:classreg:learning:modelparams:EnsembleParams:makeModifier:IncompatibleTypeAndMethod' ,this .Method ,this .Type )); 
end
ifstrcmp (this .Type ,'regression' )...
    &&any (ismember (this .Method ,...
    {'AdaBoostM1' ,'AdaBoostM2' ,'AdaBoostMH' ,'RobustBoost' ...
    ,'LogitBoost' ,'GentleBoost' ,'RUSBoost' ,'LPBoost' ,'TotalBoost' }))
error (message ('stats:classreg:learning:modelparams:EnsembleParams:makeModifier:IncompatibleTypeAndMethod' ,this .Method ,this .Type )); 
end
switchthis .Method 
case 'PartitionedModel' 
mod =classreg .learning .modifier .BlankModifier (); 
case 'PartitionedEnsemble' 
mod =classreg .learning .modifier .BlankModifier (); 
case 'PartitionedECOC' 
mod =classreg .learning .modifier .BlankModifier (); 
case 'PartitionedLinear' 
mod =classreg .learning .modifier .BlankModifier (); 
case 'PartitionedLinearECOC' 
mod =classreg .learning .modifier .BlankModifier (); 
case 'AdaBoostM1' 
mod =classreg .learning .modifier .AdaBoostM1 (this .LearnRate ); 
case 'AdaBoostM2' 
mod =classreg .learning .modifier .AdaBoostM2 (...
    classSummary .NonzeroProbClasses ,this .LearnRate ); 
case 'AdaBoostMH' 
mod =classreg .learning .modifier .AdaBoostMH (...
    classSummary .NonzeroProbClasses ,this .LearnRate ); 
case 'RobustBoost' 
mod =classreg .learning .modifier .RobustBoost (...
    this .RobustErrorGoal ,this .RobustMaxMargin ,this .RobustMarginSigma ); 
case 'LogitBoost' 
mod =classreg .learning .modifier .LogitBoost (this .LearnRate ); 
case 'GentleBoost' 
mod =classreg .learning .modifier .GentleBoost (this .LearnRate ); 
case 'LSBoost' 
mod =classreg .learning .modifier .LSBoost (this .LearnRate ); 
case 'RUSBoost' 
mod =classreg .learning .modifier .RUSBoost (X ,Y ,W ,this .LearnRate ); 
case 'LPBoost' 
mod =classreg .learning .modifier .LPBoost (this .MarginPrecision ,numel (W )); 
case 'TotalBoost' 
mod =classreg .learning .modifier .TotalBoost (this .MarginPrecision ,numel (W )); 
case 'Bag' 
mod =classreg .learning .modifier .BlankModifier (); 
case 'Subspace' 
mod =classreg .learning .modifier .BlankModifier (); 
otherwise
error (message ('stats:classreg:learning:modelparams:EnsembleParams:makeModifier:UnknownModifier' ,this .Method )); 
end
end

function this =fillDefaultParams (this ,X ,Y ,W ,dataSummary ,classSummary )

ifisempty (this .NLearn )
this .NLearn =numel (this .LearnerTemplates ); 
elseifstrcmp (this .NLearn ,'leaveout' )


ifdataSummary .ObservationsInRows 
this .NLearn =size (X ,1 ); 
else
this .NLearn =size (X ,2 ); 
end
elseifischar (this .NLearn )&&...
    strncmpi (this .NLearn ,'AllPredictorCombinations' ,length (this .NLearn ))...
    &&strcmp (this .Method ,'Subspace' )


this .NLearn ='AllPredictorCombinations' ; 
this .GeneratorArgs {9 }=true ; 
else
if~isnumeric (this .NLearn )||~isscalar (this .NLearn )||this .NLearn <=0 
error (message ('stats:classreg:learning:modelparams:EnsembleParams:fillDefaultParams:BadNLearn' )); 
end
this .NLearn =ceil (this .NLearn ); 
end


ifisempty (this .LearnRate )
this .LearnRate =1 ; 
else
if~isnumeric (this .LearnRate )||~isscalar (this .LearnRate )...
    ||this .LearnRate <=0 ||this .LearnRate >1 
error (message ('stats:classreg:learning:modelparams:EnsembleParams:fillDefaultParams:BadLearnRate' )); 
end
end


ifismember (this .Method ,{'LPBoost' ,'TotalBoost' })
ifisempty (this .MarginPrecision )
this .MarginPrecision =0.01 ; 
else
this .MarginPrecision =max (this .MarginPrecision ,1 /numel (W )); 
end
end


ifstrcmp (this .Method ,'RobustBoost' )
ifisempty (this .RobustErrorGoal )
this .RobustErrorGoal =0.1 ; 
end
ifisempty (this .RobustMaxMargin )
this .RobustMaxMargin =0 ; 
end
ifisempty (this .RobustMarginSigma )
this .RobustMarginSigma =0.1 ; 
end
end


ifisempty (this .SortLearnersByWeight )
ifismember (this .Method ,{'LPBoost' ,'TotalBoost' })
this .SortLearnersByWeight =true ; 
else
this .SortLearnersByWeight =false ; 
end
end


ifisempty (this .PrintMsg )
this .PrintMsg ='Grown weak learners: ' ; 
else
if~ischar (this .PrintMsg )
error (message ('stats:classreg:learning:modelparams:EnsembleParams:fillDefaultParams:BadPrintMsg' )); 
end
end


ifisempty (this .SaveTrainable )
this .SaveTrainable =false ; 
else
if~islogical (this .SaveTrainable )
if~strcmpi (this .SaveTrainable ,'on' )&&~strcmpi (this .SaveTrainable ,'off' )
error (message ('stats:classreg:learning:modelparams:EnsembleParams:fillDefaultParams:BadSaveTrainable' )); 
end
end
end


templates =this .LearnerTemplates ; 
ifisempty (templates )
error (message ('stats:classreg:learning:modelparams:EnsembleParams:fillDefaultParams:NoTemplatesFound' )); 
end
forl =1 :length (templates )
if~isa (templates {l },'classreg.learning.FitTemplate' )
error (message ('stats:classreg:learning:modelparams:EnsembleParams:fillDefaultParams:NotFitTemplate' )); 
end
end
ifstrcmp (this .NLearn ,'AllPredictorCombinations' )&&length (templates )>1 
error (message ('stats:classreg:learning:modelparams:EnsembleParams:fillDefaultParams:TooManyLearnersForAllPredictorCombinations' )); 
end


ifany (ismember (this .Method ,...
    {'AdaBoostM1' ,'RobustBoost' ,'LogitBoost' ,'GentleBoost' }))...
    &&length (classSummary .ClassNames )>2 
error (message ('stats:classreg:learning:modelparams:EnsembleParams:fillDefaultParams:TooManyClasses' ,this .Method )); 
end
ifany (ismember (this .Method ,{'AdaBoostM2' }))...
    &&length (classSummary .ClassNames )<=2 
error (message ('stats:classreg:learning:modelparams:EnsembleParams:fillDefaultParams:TooFewClasses' ,this .Method )); 
end


fitData =[]; 
switchthis .Method 
case {'AdaBoostM2' ,'RUSBoost' }

C =classreg .learning .internal .classCount (...
    classSummary .NonzeroProbClasses ,Y ); 
fitData =repmat (W (:),1 ,length (classSummary .NonzeroProbClasses )); 
fitData =fitData .*(~C ); 
ifany (fitData (:))
fitData =fitData /sum (fitData (:)); 
else
fitData (:)=0 ; 
end
case 'AdaBoostMH' 

fitData =repmat (W (:),1 ,length (classSummary .NonzeroProbClasses )); 
ifany (fitData (:))
fitData =fitData /sum (fitData (:)); 
else
fitData (:)=0 ; 
end
case 'RobustBoost' 

fitData =zeros (numel (Y ),1 ); 
case 'LogitBoost' 




fitData =zeros (numel (Y ),2 ); 
fitData (:,1 )=classSummary .NonzeroProbClasses (1 )==Y ; 
Y =4 *fitData (:,1 )-2 ; 
case 'GentleBoost' 


fitData =zeros (numel (Y ),1 ); 
Y =double (classSummary .NonzeroProbClasses (1 )==Y ); 
Y (Y ==0 )=-1 ; 
case 'TotalBoost' 

fitData =W (:); 
end


ifismember (this .Method ,...
    {'AdaBoostM1' ,'AdaBoostM2' ,'AdaBoostMH' ,'RobustBoost' ,'LSBoost' ...
    ,'GentleBoost' ,'LogitBoost' ,'RUSBoost' ,'LPBoost' ,'TotalBoost' })
this .DefaultScore =-Inf ; 
end


ifisempty (this .Generator )
this .Generator =makeGenerator (this ,X ,Y ,W ,fitData ,dataSummary ,classSummary ); 
end




ifstrcmp (this .NLearn ,'AllPredictorCombinations' )
this .NLearn =this .Generator .NumAllCombinations ; 
end


ifisempty (this .Modifier )
this .Modifier =makeModifier (this ,X ,Y ,W ,classSummary ); 
end



forl =1 :length (templates )
learner =templates {l }; 



ifany (ismember (this .Method ,{'LogitBoost' ,'GentleBoost' }))
if~ismember (learner .Method ,[{'ByBinaryRegr' },classreg .learning .regressionModels ()])
error (message ('stats:classreg:learning:modelparams:EnsembleParams:fillDefaultParams:NoRegressionLearner' ,learner .Method )); 
end
ifstrcmp (learner .Method ,'ByBinaryRegr' )




learner .ModelParams .RegressionTemplate =...
    setBaseArg (learner .ModelParams .RegressionTemplate ,...
    'predictornames' ,dataSummary .PredictorNames ); 
learner .ModelParams .RegressionTemplate =...
    setBaseArg (learner .ModelParams .RegressionTemplate ,...
    'categoricalpredictors' ,dataSummary .CategoricalPredictors ); 
else


learner =setType (learner ,'regression' ); 
learner =fillIfNeeded (learner ,'regression' ); 
learner =setBaseArg (learner ,'predictornames' ,dataSummary .PredictorNames ); 
learner =setBaseArg (learner ,'responsename' ,dataSummary .ResponseName ); 
learner =setBaseArg (learner ,'categoricalpredictors' ,dataSummary .CategoricalPredictors ); 
learner =classreg .learning .FitTemplate .make ('ByBinaryRegr' ,'learner' ,learner ); 
learner =setBaseArg (learner ,'classnames' ,classSummary .NonzeroProbClasses ); 
learner =setBaseArg (learner ,'prior' ,'empirical' ); 
K =length (classSummary .NonzeroProbClasses ); 
learner =setBaseArg (learner ,'cost' ,ones (K )-eye (K )); 
end
end



learner =fillIfNeeded (learner ,this .Type ); 



ifismember (this .Method ,{'PartitionedECOC' ,'PartitionedLinearECOC' })...
    &&(~isempty (learner .ModelParams .VerbosityLevel )...
    &&learner .ModelParams .VerbosityLevel >0 )&&isempty (this .NPrint )
this .NPrint =1 ; 
end



ifstrcmp (this .Type ,'classification' )&&~strcmp (learner .Method ,'ByBinaryRegr' )
ifismember (this .Method ,{'PartitionedECOC' ,'PartitionedLinearECOC' })...
    ||strcmp (learner .Method ,'NaiveBayes' )









K =length (classSummary .ClassNames ); 
learner =setBaseArg (learner ,'classnames' ,classSummary .ClassNames ); 
[~,pos ]=ismember (classSummary .NonzeroProbClasses ,classSummary .ClassNames ); 
prior =zeros (1 ,K ); 
prior (pos )=classSummary .Prior ; 
learner =setBaseArg (learner ,'prior' ,prior ); 
if~isempty (classSummary .Cost )
cost =zeros (K ); 
cost (pos ,pos )=classSummary .Cost ; 
learner =setBaseArg (learner ,'cost' ,cost ); 
end
elseifismember (this .Method ,{'PartitionedModel' ,'PartitionedEnsemble' ,'PartitionedLinear' })





learner =setBaseArg (learner ,'classnames' ,classSummary .NonzeroProbClasses ); 
learner =setBaseArg (learner ,'prior' ,classSummary .Prior ); 
learner =setBaseArg (learner ,'cost' ,classSummary .Cost ); 
else












learner =setBaseArg (learner ,'classnames' ,classSummary .NonzeroProbClasses ); 
learner =setBaseArg (learner ,'prior' ,'empirical' ); 
K =length (classSummary .NonzeroProbClasses ); 
learner =setBaseArg (learner ,'cost' ,ones (K )-eye (K )); 
end
end







learner =setBaseArg (learner ,'predictornames' ,dataSummary .PredictorNames ); 
learner =setBaseArg (learner ,'categoricalpredictors' ,dataSummary .CategoricalPredictors ); 
learner =setBaseArg (learner ,'responsename' ,dataSummary .ResponseName ); 
ifdataSummary .ObservationsInRows 
learner =setBaseArg (learner ,'ObservationsIn' ,'rows' ); 
else
learner =setBaseArg (learner ,'ObservationsIn' ,'columns' ); 
end


switchlearner .Method 
case 'Tree' 
ifstrcmp (this .Method ,'PartitionedModel' )
this .DefaultScore =0 ; 
else
ifisempty (learner .ModelParams .MergeLeaves )
learner .ModelParams .MergeLeaves ='off' ; 
end
ifisempty (learner .ModelParams .Prune )
learner .ModelParams .Prune ='off' ; 
end
end
ifismember (this .Method ,{'AdaBoostM1' ,'AdaBoostM2' ...
    ,'AdaBoostMH' ,'RobustBoost' ...
    ,'RUSBoost' ,'LPBoost' ,'TotalBoost' })
ifisempty (learner .ModelParams .MinParent )...
    &&isempty (learner .ModelParams .MinLeaf )
learner .ModelParams .MinLeaf =1 ; 
learner .ModelParams .MinParent =2 ; 
ifisempty (learner .ModelParams .MaxSplits )
learner .ModelParams .MaxSplits =1 ; 
end
end
end
ifstrcmp (this .Method ,'LSBoost' )
ifisempty (learner .ModelParams .MinParent )...
    &&isempty (learner .ModelParams .MinLeaf )
learner .ModelParams .MinLeaf =5 ; 
learner .ModelParams .MinParent =10 ; 
ifisempty (learner .ModelParams .MaxSplits )
learner .ModelParams .MaxSplits =1 ; 
end
end
end
ifstrcmp (this .Method ,'Bag' )
this .DefaultScore =0 ; 
ifisempty (learner .ModelParams .NVarToSample )
p =size (X ,2 ); 
ifstrcmp (this .Type ,'classification' )
learner .ModelParams .NVarToSample =ceil (sqrt (p )); 
else
learner .ModelParams .NVarToSample =ceil (p /3 ); 
end
end
ifisempty (learner .ModelParams .MinParent )...
    &&isempty (learner .ModelParams .MinLeaf )
ifstrcmp (this .Type ,'classification' )
learner .ModelParams .MinLeaf =1 ; 
learner .ModelParams .MinParent =2 ; 
else
learner .ModelParams .MinLeaf =5 ; 
learner .ModelParams .MinParent =10 ; 
end
end
end
ifisa (this .Generator ,'classreg.learning.generator.SubspaceSampler' )
error (message ('stats:classreg:learning:modelparams:EnsembleParams:fillDefaultParams:TreesNotAllowedForSubspace' )); 
end
switchthis .Method 
case {'AdaBoostM1' ,'AdaBoostMH' ,'RobustBoost' }
learner =setBaseArg (learner ,...
    'ScoreTransform' ,@classreg .learning .transform .symmetricismax ); 
case {'LPBoost' ,'TotalBoost' }
learner =setBaseArg (learner ,...
    'ScoreTransform' ,@classreg .learning .transform .symmetric ); 
end
...
    ...
    ...
    ...
    ...
    ...
    ...
    ...
    ...
    ...
    ...
    ...
    case 'ByBinaryRegr' 
ifstrcmp (learner .ModelParams .RegressionTemplate .Method ,'Tree' )
ifisempty (learner .ModelParams .RegressionTemplate .ModelParams .MergeLeaves )
learner .ModelParams .RegressionTemplate .ModelParams .MergeLeaves ='off' ; 
end
ifisempty (learner .ModelParams .RegressionTemplate .ModelParams .Prune )
learner .ModelParams .RegressionTemplate .ModelParams .Prune ='off' ; 
end
ifany (ismember (this .Method ,{'LogitBoost' ,'GentleBoost' }))
ifisempty (learner .ModelParams .RegressionTemplate .ModelParams .MinParent )...
    &&isempty (learner .ModelParams .RegressionTemplate .ModelParams .MinLeaf )...
    &&isempty (learner .ModelParams .RegressionTemplate .ModelParams .MaxSplits )
learner .ModelParams .RegressionTemplate .ModelParams .MaxSplits =1 ; 
end
end
end
...
    ...
    ...
    ...
    ...
    ...
    ...
    ...
    ...
    ...
    ...
    ...
    ...
    ...
    ...
    case 'Discriminant' 
ifisempty (learner .ModelParams .FillCoeffs )
learner .ModelParams .FillCoeffs =false ; 
end
ifany (ismember (this .Method ,{'PartitionedModel' ,'Bag' }))
this .DefaultScore =0 ; 
end
switchthis .Method 
case {'AdaBoostM1' ,'AdaBoostMH' ,'RobustBoost' }
learner =setBaseArg (learner ,...
    'ScoreTransform' ,@classreg .learning .transform .symmetricismax ); 
case {'LPBoost' ,'TotalBoost' }
learner =setBaseArg (learner ,...
    'ScoreTransform' ,@classreg .learning .transform .symmetric ); 
end
ifany (ismember (this .Method ,classreg .learning .ensembleModels ()))
ifisempty (learner .ModelParams .DiscrimType )
learner .ModelParams .DiscrimType ='pseudoLinear' ; 
end
end
case 'KNN' 
ifstrcmp (this .Method ,'PartitionedModel' )
this .DefaultScore =0 ; 
elseif~strcmp (this .Method ,'Subspace' )
error (message ('stats:classreg:learning:modelparams:EnsembleParams:fillDefaultParams:UseKNNforSubspaceOnly' )); 
end
case 'NaiveBayes' 
ifstrcmp (this .Method ,'PartitionedModel' )
this .DefaultScore =0 ; 
else
error (message ('stats:classreg:learning:modelparams:EnsembleParams:fillDefaultParams:MethodNotAllowedForEnsembleLearning' ,...
    learner .Method )); 
end
case 'SVM' 
ifstrcmp (this .Method ,'PartitionedModel' )
if~isempty (learner .ModelParams .Alpha )
error (message ('stats:classreg:learning:modelparams:EnsembleParams:fillDefaultParams:NoSVMAlphaForCrossValidation' )); 
end
this .DefaultScore =0 ; 
else
error (message ('stats:classreg:learning:modelparams:EnsembleParams:fillDefaultParams:MethodNotAllowedForEnsembleLearning' ,...
    learner .Method )); 
end
case 'Linear' 
ifstrcmp (this .Method ,'PartitionedLinear' )
this .DefaultScore =0 ; 
else
error (message ('stats:classreg:learning:modelparams:EnsembleParams:fillDefaultParams:MethodNotAllowedForEnsembleLearning' ,...
    learner .Method )); 
end








case classreg .learning .ensembleModels ()
if~strcmp (this .Method ,'PartitionedEnsemble' )
error (message ('stats:classreg:learning:modelparams:EnsembleParams:fillDefaultParams:NoEnsembleOfEnsembles' )); 
end
ifismember (learner .Method ,{'Bag' })
this .DefaultScore =0 ; 
else
this .DefaultScore =-Inf ; 
end
case classreg .learning .weakLearners ()



otherwise
error (message ('stats:classreg:learning:modelparams:EnsembleParams:fillDefaultParams:UnknownLearnerMethod' ,learner .Method )); 
end


templates {l }=learner ; 
end


this .LearnerTemplates =templates ; 
end
end

end

