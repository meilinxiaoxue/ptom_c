classdef FitTemplate <classreg .learning .internal .DisallowVectorOps 




properties (GetAccess =public ,SetAccess =protected ,Hidden =true )
Filled =false ; 
Method ='' ; 
Type ='' ; 
BaseFitObjectArgs ={}; 
MakeModelParams =[]; 
MakeFitObject =[]; 
PrepareData =[]; 
NamesDataPrepIn ={}; 
NDataPrepOut =[]; 
MakeModelInputArgs ={}; 
CVPartitionSize =[]; 
end

properties (GetAccess =public ,SetAccess =public ,Hidden =true )
ModelParams =[]; 
end

properties (Constant =true ,GetAccess =public ,Hidden =true )
AllowedBaseFitObjectArgs ={'weights' ,'predictornames' ,'categoricalpredictors' ...
    ,'responsename' ,'responsetransform' ,'classnames' ,'cost' ,'prior' ,'scoretransform' ...
    ,'observationsin' }; 
end

methods (Static ,Hidden )
function temp =make (method ,varargin )

if~ischar (method )
error (message ('stats:classreg:learning:FitTemplate:make:BadArgs' )); 
end


args ={'type' }; 
defs ={'' }; 
[usertype ,~,modelArgs ]=...
    internal .stats .parseArgs (args ,defs ,varargin {:}); 


if~isempty (usertype )
usertype =gettype (usertype ); 
end


namesclass =classreg .learning .classificationModels (); 
namesreg =classreg .learning .regressionModels (); 
[tfclass ,locclass ]=ismember (lower (method ),lower (namesclass )); 
[tfreg ,locreg ]=ismember (lower (method ),lower (namesreg )); 
if~tfclass &&~tfreg 
error (message ('stats:classreg:learning:FitTemplate:make:UnknownMethod' ,method )); 
end
iftfclass &&tfreg 
method =namesclass {locclass }; 
type =usertype ; 







ifisempty (type )&&ismember (method ,classreg .learning .ensembleModels ())
[learners ,~,~]=internal .stats .parseArgs ({'learners' },{},modelArgs {:}); 
ifischar (learners )||isa (learners ,'classreg.learning.FitTemplate' )
learners ={learners }; 
elseif~iscell (learners )
error (message ('stats:classreg:learning:FitTemplate:make:BadLearnerTemplates' )); 
end
L =numel (learners ); 
















types =zeros (L ,1 ); 
forl =1 :L 
meth =learners {l }; 
ifisa (meth ,'classreg.learning.FitTemplate' )
meth =meth .Method ; 
end
isc =ismember (lower (meth ),lower (namesclass )); 
isr =ismember (lower (meth ),lower (namesreg )); 
if~isc &&~isr 
error (message ('stats:classreg:learning:FitTemplate:make:UnknownMethod' ,meth )); 
end
types (l )=isc -isr ; 
end
ifall (types ==1 )
type ='classification' ; 
elseifall (types ==-1 )
type ='regression' ; 
end
end
elseiftfclass 
method =namesclass {locclass }; 
type ='classification' ; 
else
method =namesreg {locreg }; 
type ='regression' ; 
end


if~isempty (usertype )&&~strcmp (usertype ,type )
error (message ('stats:classreg:learning:FitTemplate:make:UserTypeMismatch' ,method ,usertype )); 
end


temp =classreg .learning .FitTemplate (method ,modelArgs ); 
temp =fillIfNeeded (temp ,type ); 
end

function temp =makeFromModelParams (modelParams ,varargin )
if~isa (modelParams ,'classreg.learning.modelparams.ModelParams' )
error (message ('stats:classreg:learning:FitTemplate:makeFromModelParams:BadModelParams' )); 
end
method =modelParams .Method ; 
type =modelParams .Type ; 
args =varargin ; 
ifisa (modelParams ,'classreg.learning.modelparams.EnsembleParams' )
ifisa (modelParams .Generator ,'classreg.learning.generator.Resampler' )
args =[args (:)' ,{'resample' ,'on' ...
    ,'replace' ,modelParams .Generator .Replace ,'fresample' ,modelParams .Generator .FResample }]; 
elseifisa (modelParams .Generator ,'classreg.learning.generator.SubspaceSampler' )
args =[args (:)' ,{'npredtosample' ,modelParams .Generator .NPredToSample }]; 
end
modelParams .Generator =[]; 
modelParams .Modifier =[]; 
modelParams .Filled =false ; 
end
temp =classreg .learning .FitTemplate (method ,args ); 
temp .ModelParams =modelParams ; 
temp =fillIfNeeded (temp ,type ); 
end

function catchType (varargin )
args ={'type' }; 
defs ={[]}; 
[type ,~,~]=internal .stats .parseArgs (args ,defs ,varargin {:}); 
if~isempty (type )
error (message ('stats:classreg:learning:FitTemplate:catchType:NonEmptyType' )); 
end
end

function obj =loadobj (obj )
if~ismember ('observationsin' ,obj .NamesDataPrepIn )
obj .NamesDataPrepIn =[obj .NamesDataPrepIn ,{'observationsin' }]; 
end
end
end

methods (Access =protected )
function this =FitTemplate (method ,modelArgs )
this =this @classreg .learning .internal .DisallowVectorOps (); 
this .Method =method ; 
this .MakeModelInputArgs =modelArgs ; 
end

function tf =isfilled (this )

ifthis .Filled 
tf =true ; 
return ; 
end



props ={'Type' ,'Method' ,'BaseFitObjectArgs' ,'ModelParams' ...
    ,'MakeModelParams' ,'MakeFitObject' ,'PrepareData' ...
    ,'NamesDataPrepIn' ,'NDataPrepOut' }; 
tf =false ; 
fori =1 :length (props )
ifisempty (this .(props {i }))
return ; 
end
end
tf =true ; 
end
end

methods (Hidden )




function [varargout ]=fit (this ,X ,Y ,varargin )

ifisempty (this .Type )
error (message ('stats:classreg:learning:FitTemplate:fit:BadType' ,this .Method )); 
end


dataPrepOut =cell (1 ,this .NDataPrepOut ); 



ifisempty (varargin )
[X ,Y ,dataPrepOut {1 :this .NDataPrepOut }]=...
    this .PrepareData (X ,Y ,this .BaseFitObjectArgs {:}); 



else

nDataPrepIn =length (this .NamesDataPrepIn ); 
dataPrepIn =cell (1 ,nDataPrepIn ); 
args =this .NamesDataPrepIn ; 
defs =repmat ({[]},1 ,nDataPrepIn ); 
[dataPrepIn {1 :nDataPrepIn }]=...
    internal .stats .parseArgs (args ,defs ,this .BaseFitObjectArgs {:}); 


defs =dataPrepIn ; 
[dataPrepIn {1 :nDataPrepIn }]=...
    internal .stats .parseArgs (args ,defs ,varargin {:}); 



iset =find (~cellfun (@isempty ,dataPrepIn )); 
nset =length (iset ); 
prepArgs =cell (2 *nset ,1 ); 
fori =1 :nset 
j =iset (i ); 
prepArgs (2 *i -1 :2 *i )=[this .NamesDataPrepIn (j ),dataPrepIn (j )]; 
end


[X ,Y ,dataPrepOut {1 :this .NDataPrepOut }]=...
    this .PrepareData (X ,Y ,prepArgs {:}); 
end



if~isempty (this .CVPartitionSize )&&numel (Y )~=this .CVPartitionSize 
error (message ('stats:classreg:learning:FitTemplate:fit:CVPartitionSizeMismatch' ,...
    this .CVPartitionSize ,numel (Y ))); 
end


W =dataPrepOut {1 }; 
fitArgs =dataPrepOut (2 :end); 


[varargout {1 :nargout }]=this .MakeFitObject (X ,Y ,W ,this .ModelParams ,fitArgs {:}); 
end

function disp (this )
isLoose =strcmp (get (0 ,'FormatSpacing' ),'loose' ); 
ifstrcmp (this .Method ,'ByBinaryRegr' )
temp =this .ModelParams .RegressionTemplate ; 
ifisempty (temp )
fprintf ('%s\n' ,getString (message ('stats:classreg:learning:FitTemplate:FitTemplateForByBinaryRegr' ))); 
ifisLoose 
fprintf ('\n' ); 
end
else
disp (temp ); 
end
return ; 
end
ifisempty (this .Type )
type ='' ; 
else
type =[this .Type ,' ' ]; 
end
fprintf ('%s %s%s.\n' ,getString (message ('stats:classreg:learning:FitTemplate:FitTemplateFor' )),...
    type ,this .Method ); 
if~isempty (this .ModelParams )
disp (this .ModelParams ); 
elseif~isempty (this .MakeModelInputArgs )
N =numel (this .MakeModelInputArgs )/2 ; 
n =1 :N ; 
c =this .MakeModelInputArgs (2 *n ); 
f =this .MakeModelInputArgs (2 *n -1 ); 
s =cell2struct (c (:),f (:),1 ); 
disp (s ); 
else
ifisLoose 
fprintf ('\n' ); 
end
end
end

function this =fillIfNeeded (this ,type )

ifisempty (type )
return ; 
end


if~isempty (this .Type )
if~strcmp (type ,this .Type )
error (message ('stats:classreg:learning:FitTemplate:fillIfNeeded:IncompatibleType' ,this .Type )); 
end
end
this .Type =type ; 


ifisfilled (this )
return ; 
end


ifstrcmp (this .Method ,'ByBinaryRegr' )
this .PrepareData =...
    @classreg .learning .classif .ClassifByBinaryRegr .prepareData ; 
this .NDataPrepOut =4 ; 
this .NamesDataPrepIn =...
    {'weights' ,'predictornames' ,'categoricalpredictors' ...
    ,'responsename' ,'classnames' ,'cost' ,'prior' ,'scoretransform' ...
    ,'observationsin' }; 
elseifstrcmp (this .Type ,'classification' )
this .NDataPrepOut =4 ; 
ifstrcmp (this .Method ,'Tree' )
this .PrepareData =@ClassificationTree .prepareData ; 
elseifstrcmp (this .Method ,'SVM' )
this .PrepareData =@ClassificationSVM .prepareData ; 
elseifstrcmp (this .Method ,'KNN' )
this .PrepareData =@ClassificationKNN .prepareData ; 
elseifstrcmp (this .Method ,'NaiveBayes' )
this .PrepareData =@ClassificationNaiveBayes .prepareData ; 
elseifstrcmp (this .Method ,'Kernel' )
this .PrepareData =@ClassificationKernel .prepareData ; 
elseifstrcmp (this .Method ,'Linear' )
this .PrepareData =@ClassificationLinear .prepareData ; 
else
this .PrepareData =@classreg .learning .classif .FullClassificationModel .prepareData ; 
end
this .NamesDataPrepIn =...
    {'weights' ,'predictornames' ,'categoricalpredictors' ...
    ,'responsename' ,'classnames' ,'cost' ,'prior' ,'scoretransform' ...
    ,'observationsin' }; 
else
ifstrcmp (this .Method ,'SVM' )
this .PrepareData =@RegressionSVM .prepareData ; 
elseifstrcmp (this .Method ,'GP' )
this .PrepareData =@RegressionGP .prepareData ; 
elseifstrcmp (this .Method ,'Tree' )
this .PrepareData =@RegressionTree .prepareData ; 
elseifstrcmp (this .Method ,'Kernel' )
this .PrepareData =@RegressionKernel .prepareData ; 
elseifstrcmp (this .Method ,'Linear' )
this .PrepareData =@RegressionLinear .prepareData ; 
else
this .PrepareData =@classreg .learning .regr .FullRegressionModel .prepareData ; 
end
this .NDataPrepOut =3 ; 
this .NamesDataPrepIn =...
    {'weights' ,'predictornames' ,'categoricalpredictors' ...
    ,'responsename' ,'responsetransform' ,'observationsin' }; 
end


[Nfold ,partitionArgs ,otherArgs ,cvpartsize ]=...
    classreg .learning .generator .Partitioner .processArgs (this .MakeModelInputArgs {:}); 
docv =~isempty (Nfold ); 
this .CVPartitionSize =cvpartsize ; 
[dobag ,sampleArgs ,otherArgs ]=...
    classreg .learning .generator .Resampler .processArgs (otherArgs {:}); 
[dosubspace ,subspaceArgs ,otherArgs ]=...
    classreg .learning .generator .SubspaceSampler .processArgs (otherArgs {:}); 
[dorus ,undersamplerArgs ,otherArgs ]=...
    classreg .learning .generator .MajorityUndersampler .processArgs (otherArgs {:}); 


args ={'modelparams' }; 
defs ={[]}; 
[modelParams ,~,otherArgs ]=...
    internal .stats .parseArgs (args ,defs ,otherArgs {:}); 
if~docv &&~isempty (modelParams )
error (message ('stats:classreg:learning:FitTemplate:fillIfNeeded:ModelParamsWithoutCV' )); 
end


ifstrcmp (this .Method ,'Bag' )
dobag =true ; 
end


ifstrcmp (this .Method ,'Subspace' )
dosubspace =true ; 
end


ifstrcmp (this .Method ,'RUSBoost' )
dorus =true ; 
end



ifdobag &&dosubspace 
error (message ('stats:classreg:learning:FitTemplate:fillIfNeeded:BothBaggingAndSubspaceNotAllowed' )); 
end



ifdobag &&dorus 
error (message ('stats:classreg:learning:FitTemplate:fillIfNeeded:BothBaggingAndRUSBoostNotAllowed' )); 
end



ifdosubspace &&dorus 
error (message ('stats:classreg:learning:FitTemplate:fillIfNeeded:BothSubspaceAndRUSBoostNotAllowed' )); 
end


f =@(x )any (strncmpi (x ,this .NamesDataPrepIn ,length (x ))); 
loc =find (cellfun (f ,otherArgs (1 :2 :end))); 
loc =loc (:)' ; 
baseArgs =otherArgs (sort ([2 *loc -1 ,2 *loc ])); 
otherArgs ([2 *loc -1 ,2 *loc ])=[]; 


baseArgsForLearner =baseArgs ; 
f =@(x )strncmpi (x ,'scoretransform' ,length (x )); 
loc =find (cellfun (f ,baseArgs (1 :2 :end))); 
loc =loc (:)' ; 
baseArgsForLearner ([2 *loc -1 ,2 *loc ])=[]; 


switchthis .Method 
case classreg .learning .simpleModels ()
ifdobag 
error (message ('stats:classreg:learning:FitTemplate:fillIfNeeded:CannotBagSimpleModel' ,this .Method )); 
elseifdosubspace 
error (message ('stats:classreg:learning:FitTemplate:fillIfNeeded:CannotSubspaceSimpleModel' ,this .Method )); 
elseifdorus 
error (message ('stats:classreg:learning:FitTemplate:fillIfNeeded:CannotRUSBoostSimpleModel' ,this .Method )); 
elseifdocv 
this .MakeModelParams =@classreg .learning .modelparams .EnsembleParams .make ; 
ifisempty (modelParams )
learnerTemplate =...
    classreg .learning .FitTemplate .make (this .Method ,'type' ,this .Type ,...
    baseArgsForLearner {:},otherArgs {:}); 
else
learnerTemplate =...
    classreg .learning .FitTemplate .makeFromModelParams (modelParams ,...
    baseArgsForLearner {:},otherArgs {:}); 
end
ifstrcmp (this .Method ,'ECOC' )
learners =learnerTemplate .ModelParams .BinaryLearners ; 
isLinear =false ; 
if~isempty (learners )
ifisscalar (learners )
isLinear =strcmp (learners .Method ,'Linear' ); 
else
isLinear =all (cellfun (...
    @(x )strcmp (x .Method ,'Linear' ),learners )); 
end
end
ifisLinear 
meth ='PartitionedLinearECOC' ; 
this .MakeFitObject =...
    @classreg .learning .partition .ClassificationPartitionedLinearECOC ; 
else
meth ='PartitionedECOC' ; 
this .MakeFitObject =...
    @classreg .learning .partition .ClassificationPartitionedECOC ; 
end
elseifstrcmp (this .Method ,'SVM' )&&strcmp (this .Type ,'regression' )
meth ='PartitionedModel' ; 
this .MakeFitObject =...
    @classreg .learning .partition .RegressionPartitionedSVM ; 
elseifstrcmp (this .Method ,'Linear' )
meth ='PartitionedLinear' ; 
ifstrcmp (this .Type ,'classification' )
this .MakeFitObject =...
    @classreg .learning .partition .ClassificationPartitionedLinear ; 
else
this .MakeFitObject =...
    @classreg .learning .partition .RegressionPartitionedLinear ; 
end
else
meth ='PartitionedModel' ; 
ifstrcmp (this .Type ,'classification' )
this .MakeFitObject =...
    @classreg .learning .partition .ClassificationPartitionedModel ; 
else
this .MakeFitObject =...
    @classreg .learning .partition .RegressionPartitionedModel ; 
end
end
this .MakeModelInputArgs =[baseArgs ,partitionArgs ...
    ,{'method' ,meth ,'learners' ,learnerTemplate ,'nlearn' ,Nfold }]; 
else
this .MakeModelInputArgs =[baseArgs ,otherArgs ]; 
this .MakeModelParams =str2func (['classreg.learning.modelparams.' ,this .Method ,'Params.make' ]); 
ifstrcmp (this .Type ,'classification' )
ifstrcmp (this .Method ,'ByBinaryRegr' )
this .MakeFitObject =@classreg .learning .classif .ClassifByBinaryRegr ; 
elseifstrcmp (this .Method ,'Linear' )
this .MakeFitObject =@ClassificationLinear .fitClassificationLinear ; 
elseifstrcmp (this .Method ,'Kernel' )
this .MakeFitObject =@ClassificationKernel .fitClassificationKernel ; 
else
this .MakeFitObject =str2func (['Classification' ,this .Method ]); 
end
else
ifstrcmp (this .Method ,'Linear' )
this .MakeFitObject =@RegressionLinear .fitRegressionLinear ; 
elseifstrcmp (this .Method ,'Kernel' )
this .MakeFitObject =@RegressionKernel .fitRegressionKernel ; 
else
this .MakeFitObject =str2func (['Regression' ,this .Method ]); 
end
end
end
case classreg .learning .ensembleModels ()
this .MakeModelParams =@classreg .learning .modelparams .EnsembleParams .make ; 
ifdocv 
f =@(x )strcmpi (x ,'nprint' ); 
loc =find (cellfun (f ,otherArgs (1 :2 :end))); 
loc =loc (:)' ; 
otherArgs ([2 *loc -1 ,2 *loc ])=[]; 
ifisempty (modelParams )
ensembleTemplate =...
    classreg .learning .FitTemplate .make (this .Method ,'type' ,this .Type ,...
    subspaceArgs {:},sampleArgs {:},undersamplerArgs {:},...
    baseArgsForLearner {:},otherArgs {:},'nprint' ,'off' ); 
else
if~isempty (sampleArgs )
error (message ('stats:classreg:learning:FitTemplate:fillIfNeeded:CannotRedefineBagArgs' )); 
end
if~isempty (subspaceArgs )
error (message ('stats:classreg:learning:FitTemplate:fillIfNeeded:CannotRedefineSubspaceArgs' )); 
end
if~isempty (undersamplerArgs )
error (message ('stats:classreg:learning:FitTemplate:fillIfNeeded:CannotRedefineRUSBoostArgs' )); 
end
ensembleTemplate =...
    classreg .learning .FitTemplate .makeFromModelParams (modelParams ,...
    baseArgsForLearner {:},otherArgs {:},'nprint' ,'off' ); 
end
loc =find (cellfun (f ,this .MakeModelInputArgs (1 :2 :end)),1 ,'last' ); 
if~isempty (loc )
printArgs =[{'nprint' },this .MakeModelInputArgs (2 *loc )]; 
else
printArgs ={}; 
end
this .MakeModelInputArgs =[baseArgs ,otherArgs ,partitionArgs ,printArgs ...
    ,{'method' ,'PartitionedEnsemble' ,'learners' ,ensembleTemplate ...
    ,'printmsg' ,'Completed folds: ' ,'savetrainable' ,true ,'nlearn' ,Nfold }]; 
ifstrcmp (this .Type ,'classification' )
this .MakeFitObject =...
    @classreg .learning .partition .ClassificationPartitionedEnsemble ; 
else
this .MakeFitObject =...
    @classreg .learning .partition .RegressionPartitionedEnsemble ; 
end
elseifdobag 
this .MakeModelInputArgs =[baseArgs ,otherArgs ...
    ,{'method' ,this .Method },{'resample' ,'on' },sampleArgs ]; 
ifstrcmp (this .Type ,'classification' )
this .MakeFitObject =...
    @classreg .learning .classif .ClassificationBaggedEnsemble ; 
else
this .MakeFitObject =...
    @classreg .learning .regr .RegressionBaggedEnsemble ; 
end
elseifdosubspace 
this .MakeModelInputArgs =[baseArgs ,otherArgs ...
    ,{'method' ,this .Method },{'subspace' ,true },subspaceArgs ]; 
ifstrcmp (this .Type ,'classification' )
this .MakeFitObject =@classreg .learning .classif .ClassificationEnsemble ; 
else
this .MakeFitObject =@classreg .learning .regr .RegressionEnsemble ; 
end
elseifdorus 
this .MakeModelInputArgs =[baseArgs ,otherArgs ...
    ,{'method' ,this .Method },undersamplerArgs ]; 
ifstrcmp (this .Type ,'classification' )
this .MakeFitObject =@classreg .learning .classif .ClassificationEnsemble ; 
else
this .MakeFitObject =@classreg .learning .regr .RegressionEnsemble ; 
end
else
this .MakeModelInputArgs =[baseArgs ,otherArgs ,{'method' ,this .Method }]; 
ifstrcmp (this .Type ,'classification' )
this .MakeFitObject =@classreg .learning .classif .ClassificationEnsemble ; 
else
this .MakeFitObject =@classreg .learning .regr .RegressionEnsemble ; 
end
end
otherwise
error (message ('stats:classreg:learning:FitTemplate:fillIfNeeded:UnknownAlgorithm' ,this .Method )); 
end


ifisempty (this .ModelParams )
[this .ModelParams ,baseArgs ]=...
    this .MakeModelParams (this .Type ,this .MakeModelInputArgs {:}); 
forn =1 :2 :numel (baseArgs )
if~ischar (baseArgs {n })
error (message ('stats:classreg:learning:FitTemplate:fillIfNeeded:BadBaseFitObjectParameterType' )); 
end
if~any (strncmpi (baseArgs {n },this .AllowedBaseFitObjectArgs ,length (baseArgs {n })))
error (message ('stats:classreg:learning:FitTemplate:fillIfNeeded:UnknownBaseFitObjectParameter' ,baseArgs {n })); 
end
end
this .BaseFitObjectArgs =baseArgs ; 
else











ifisa (this .ModelParams ,'classreg.learning.modelparams.EnsembleParams' )
[~,~,otherArgs ]=...
    classreg .learning .generator .Resampler .processArgs (this .MakeModelInputArgs {:}); 
[~,~,otherArgs ]=...
    classreg .learning .generator .Partitioner .processArgs (otherArgs {:}); 
[~,~,otherArgs ]=...
    classreg .learning .generator .SubspaceSampler .processArgs (otherArgs {:}); 
end
forn =1 :(numel (otherArgs )/2 )
name =otherArgs {2 *n -1 }; 
value =otherArgs {2 *n }; 
if~strcmpi (name ,'method' )
ifismember (lower (name ),this .AllowedBaseFitObjectArgs )
this =setBaseArg (this ,name ,value ); 
else
this =setInputArg (this ,name ,value ); 
end
end
end
end


this .Filled =true ; 
end





function this =setInputArg (this ,name ,value )
if~ischar (name )
error (message ('stats:classreg:learning:FitTemplate:setInputArg:ArgNameNotChar' )); 
end
props =properties (this .ModelParams ); 
[tf ,loc ]=ismember (lower (name ),lower (props )); 
if~tf 
error (message ('stats:classreg:learning:FitTemplate:setInputArg:ArgNameNotFound' ,name )); 
end
foundprop =props {loc }; 
this .ModelParams .(foundprop )=value ; 
end

function out =getInputArg (this ,name )
if~ischar (name )
error (message ('stats:classreg:learning:FitTemplate:getInputArg:ArgNameNotChar' )); 
end
props =properties (this .ModelParams ); 
[tf ,loc ]=ismember (lower (name ),lower (props )); 
if~tf 
error (message ('stats:classreg:learning:FitTemplate:getInputArg:ArgNameNotFound' ,name )); 
end
foundprop =props {loc }; 
out =this .ModelParams .(foundprop ); 
end

function tf =isemptyInputArg (this ,name )
if~ischar (name )
error (message ('stats:classreg:learning:FitTemplate:isemptyInputArg:ArgNameNotChar' )); 
end
props =properties (this .ModelParams ); 
[tf ,loc ]=ismember (lower (name ),lower (props )); 
if~tf 
error (message ('stats:classreg:learning:FitTemplate:isemptyInputArg:ArgNameNotFound' ,name )); 
end
foundprop =props {loc }; 
tf =isempty (this .ModelParams .(foundprop )); 
end

function this =setBaseArg (this ,name ,value )
if~ischar (name )
error (message ('stats:classreg:learning:FitTemplate:setBaseArg:ArgNameNotChar' )); 
end
f =@(x )strcmpi (name ,x ); 
loc =find (cellfun (f ,this .BaseFitObjectArgs (1 :2 :end))); 
ifisempty (loc )
this .BaseFitObjectArgs (end+1 :end+2 )={lower (name ),value }; 
else
loc =2 *loc -1 ; 
ifloc (1 )+1 >length (this .BaseFitObjectArgs )
error (message ('stats:classreg:learning:FitTemplate:setBaseArg:MissingValueInPropertyList' ,name )); 
end
this .BaseFitObjectArgs {loc (1 )+1 }=value ; 
if~isscalar (loc )
loc =loc (:)' ; 
this .BaseFitObjectArgs ([loc (2 :end),loc (2 :end)+1 ])=[]; 
end
end
end

function this =setType (this ,type )

this .Type =gettype (type ); 
this .Filled =false ; 
this .ModelParams =[]; 
end
end
end

function type =gettype (type )

if~ischar (type )
error (message ('stats:classreg:learning:FitTemplate:gettype:BadType' )); 
end
loc =find (strncmpi (type ,{'classification' ,'regression' },length (type ))); 
ifisempty (loc )
error (message ('stats:classreg:learning:FitTemplate:gettype:UnknownType' )); 
end
ifloc ==1 
type ='classification' ; 
else
type ='regression' ; 
end
end




%#function classreg.learning.modelparams.ByBinaryRegrParams.make 
%#function classreg.learning.modelparams.DiscriminantParams.make 
%#function classreg.learning.modelparams.ECOCParams.make 
%#function classreg.learning.modelparams.EnsembleParams.make 
%#function classreg.learning.modelparams.KNNParams.make 
%#function classreg.learning.modelparams.NaiveBayesParams.make 
%#function classreg.learning.modelparams.SVMParams.make 
%#function classreg.learning.modelparams.TreeParams.make 
%#function classreg.learning.modelparams.LinearParams.make 
%#function classreg.learning.modelparams.KernelParams.make 
