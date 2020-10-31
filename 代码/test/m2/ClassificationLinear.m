classdef ClassificationLinear <...
    classreg .learning .classif .ClassificationModel &classreg .learning .Linear 




























methods (Hidden =true )
function this =ClassificationLinear (...
    dataSummary ,classSummary ,scoreTransform )

if~isstruct (dataSummary )
error (message ('stats:ClassificationLinear:ClassificationLinear:DoNotUseConstructor' )); 
end

this =this @classreg .learning .classif .ClassificationModel (...
    dataSummary ,classSummary ,scoreTransform ,[]); 
this =this @classreg .learning .Linear ; 
end

function cmp =compact (this )
cmp =this ; 
end

function compareHoldout (~,varargin )
error (message ('stats:ClassificationLinear:compareHoldout:DoNotUseCompareHoldout' )); 
end
end


methods (Access =protected )
function cl =getContinuousLoss (this )
cl =[]; 
lossfun =this .Impl .LossFunction ; 
switchlossfun 
case 'logit' 
ifisequal (this .PrivScoreTransform ,@classreg .learning .transform .identity )
cl =@classreg .learning .loss .logit ; 
elseifisequal (this .PrivScoreTransform ,@classreg .learning .transform .logit )
cl =@classreg .learning .loss .quadratic ; 
end

case 'hinge' 
ifisequal (this .PrivScoreTransform ,@classreg .learning .transform .identity )
cl =@classreg .learning .loss .hinge ; 
end
end
end

function s =propsForDisp (this ,s )
s =propsForDisp @classreg .learning .classif .ClassificationModel (this ,s ); 
s =propsForDisp @classreg .learning .Linear (this ,s ); 
s =rmfield (s ,'CategoricalPredictors' ); 
end

function S =score (this ,X ,obsInRows )
S =score (this .Impl ,X ,true ,obsInRows ); 
end
end


methods 
function [labels ,scores ]=predict (this ,X ,varargin )



















[varargin {:}]=convertStringsToChars (varargin {:}); 

adapter =classreg .learning .internal .makeClassificationModelAdapter (this ,X ,varargin {:}); 
if~isempty (adapter )
[labels ,scores ]=predict (adapter ,X ,varargin {:}); 
return 
end

if~istall (X )
internal .stats .checkSupportedNumeric ('X' ,X ,false ,true ); 
end


obsIn =internal .stats .parseArgs ({'observationsin' },{'rows' },varargin {:}); 
obsIn =validatestring (obsIn ,{'rows' ,'columns' },...
    'classreg.learning.internal.orientX' ,'ObservationsIn' ); 
obsInRows =strcmp (obsIn ,'rows' ); 


ifisempty (X )
D =numel (this .PredictorNames ); 
ifobsInRows 
Dpassed =size (X ,2 ); 
str =getString (message ('stats:classreg:learning:classif:ClassificationModel:predictEmptyX:columns' )); 
else
Dpassed =size (X ,1 ); 
str =getString (message ('stats:classreg:learning:classif:ClassificationModel:predictEmptyX:rows' )); 
end
ifDpassed ~=D 
error (message ('stats:classreg:learning:classif:ClassificationModel:predictEmptyX:XSizeMismatch' ,D ,str )); 
end
labels =repmat (this .ClassNames (1 ,:),0 ,1 ); 
K =numel (this .ClassSummary .ClassNames ); 
scores =NaN (0 ,K ); 
return ; 
end


S =score (this ,X ,obsInRows ); 

[N ,L ]=size (S ); 


K =numel (this .ClassSummary .ClassNames ); 
[~,pos ]=ismember (this .ClassSummary .NonzeroProbClasses ,...
    this .ClassSummary .ClassNames ); 


scores =NaN (N ,K ,L ,'like' ,S ); 
fork =1 :K 
scores (:,k ,:)=-S ; 
end
ifnumel (pos )==1 
scores (:,pos ,:)=S ; 
else
scores (:,pos (2 ),:)=S ; 
end

prior =this .Prior ; 
cost =this .Cost ; 
scoreTransform =this .PrivScoreTransform ; 
classnames =this .ClassNames ; 
ifischar (classnames )&&L >1 
classnames =cellstr (classnames ); 
end
labels =repmat (classnames (1 ,:),N ,L ); 

ifL ==1 
[labels ,scores ]=...
    this .LabelPredictor (classnames ,prior ,cost ,scores ,scoreTransform ); 
else
forl =1 :L 
[labels (:,l ),scores (:,:,l )]=...
    this .LabelPredictor (classnames ,prior ,cost ,scores (:,:,l ),scoreTransform ); 
end
end
end

function l =loss (this ,X ,varargin )








































[varargin {:}]=convertStringsToChars (varargin {:}); 

adapter =classreg .learning .internal .makeClassificationModelAdapter (this ,X ,varargin {:}); 
if~isempty (adapter )
l =loss (adapter ,X ,varargin {:}); 
return 
end

internal .stats .checkSupportedNumeric ('X' ,X ,false ,true ); 
l =loss @classreg .learning .classif .ClassificationModel (this ,X ,varargin {:}); 
end

function m =margin (this ,X ,varargin )



















[varargin {:}]=convertStringsToChars (varargin {:}); 

adapter =classreg .learning .internal .makeClassificationModelAdapter (this ,X ,varargin {:}); 
if~isempty (adapter )
m =slice (adapter ,@this .margin ,X ,varargin {:}); 
return 
end

internal .stats .checkSupportedNumeric ('X' ,X ,false ,true ); 
m =margin @classreg .learning .classif .ClassificationModel (this ,X ,varargin {:}); 
end

function e =edge (this ,X ,varargin )






















[varargin {:}]=convertStringsToChars (varargin {:}); 

adapter =classreg .learning .internal .makeClassificationModelAdapter (this ,X ,varargin {:}); 
if~isempty (adapter )
e =edge (adapter ,X ,varargin {:}); 
return 
end

internal .stats .checkSupportedNumeric ('X' ,X ,false ,true ); 
e =edge @classreg .learning .classif .ClassificationModel (this ,X ,varargin {:}); 
end
end


methods (Hidden )
function s =toStruct (this )


warnState =warning ('query' ,'all' ); 
warning ('off' ,'MATLAB:structOnObject' ); 
cleanupObj =onCleanup (@()warning (warnState )); 


fh =functions (this .PrivScoreTransform ); 
ifstrcmpi (fh .type ,'anonymous' )
error (message ('stats:classreg:learning:coderutils:classifToStruct:AnonymousFunctionsNotSupported' ,'Score Transform' )); 
end


try
classreg .learning .internal .convertScoreTransform (this .PrivScoreTransform ,'handle' ,numel (this .ClassSummary .ClassNames )); 
catch me 
rethrow (me ); 
end


s =classreg .learning .coderutils .classifToStruct (this ); 
s .ScoreTransformFull =s .ScoreTransform ; 
scoretransformfull =strsplit (s .ScoreTransform ,'.' ); 
scoretransform =scoretransformfull {end}; 
s .ScoreTransform =scoretransform ; 



transFcn =['classreg.learning.transform.' ,s .ScoreTransform ]; 
transFcnCG =['classreg.learning.coder.transform.' ,s .ScoreTransform ]; 
ifisempty (which (transFcn ))||isempty (which (transFcnCG ))
s .CustomScoreTransform =true ; 
else
s .CustomScoreTransform =false ; 
end


if~isscalar (this .Lambda )
error (message ('stats:ClassificationLinear:toStruct:NonScalarLambda' )); 
end


s .FromStructFcn ='ClassificationLinear.fromStruct' ; 


s .Learner =this .Learner ; 


s .ModelParams =classreg .learning .coderutils .linearParamsToCoderStruct (...
    this .ModelParams ); 


s .Impl =toStruct (this .Impl ); 
end
end


methods (Static ,Hidden )
function temp =template (varargin )
classreg .learning .FitTemplate .catchType (varargin {:}); 
temp =classreg .learning .FitTemplate .make ('Linear' ,...
    'type' ,'classification' ,varargin {:}); 
end

function [varargout ]=fit (X ,Y ,varargin )
temp =ClassificationLinear .template (varargin {:}); 
[varargout {1 :nargout }]=fit (temp ,X ,Y ); 
end

function obj =fromStruct (s )



ifisfield (s ,'ScoreTransformFull' )
s .ScoreTransform =s .ScoreTransformFull ; 
end

s =classreg .learning .coderutils .structToClassif (s ); 


obj =ClassificationLinear (s .DataSummary ,s .ClassSummary ,s .ScoreTransform ); 


ifisempty (s .ScoreType )
obj .ScoreType ='none' ; 
else
obj .ScoreType =s .ScoreType ; 
end

obj .DefaultLoss =s .DefaultLoss ; 
obj .LabelPredictor =s .LabelPredictor ; 
obj .DefaultScoreType =s .DefaultScoreType ; 


obj .Learner =s .Learner ; 


obj .ModelParams =classreg .learning .coderutils .coderStructToLinearParams (s .ModelParams ); 


obj .Impl =classreg .learning .impl .LinearImpl .fromStruct (s .Impl ); 
end


function obj =makebeta (beta ,bias ,modelParams ,dataSummary ,classSummary ,fitinfo ,scoreTransform )




ifisempty (scoreTransform )
switchlower (modelParams .LossFunction )
case 'hinge' 
scoreTransform =@classreg .learning .transform .identity ; 
case 'logit' 
scoreTransform =@classreg .learning .transform .logit ; 
end
end

obj =ClassificationLinear (dataSummary ,classSummary ,scoreTransform ); 

obj .DefaultLoss =@classreg .learning .loss .classiferror ; 
obj .LabelPredictor =@classreg .learning .classif .ClassificationModel .maxScore ; 
obj .DefaultScoreType ='inf' ; 

switchlower (modelParams .LossFunction )
case 'hinge' 
obj .Learner ='svm' ; 
case 'logit' 
obj .Learner ='logistic' ; 
ifisequal (obj .PrivScoreTransform ,@classreg .learning .transform .identity )
obj .ScoreTransform ='logit' ; 
obj .ScoreType ='probability' ; 
end
end

obj .ModelParams =modelParams ; 

obj .Impl =classreg .learning .impl .LinearImpl .makeNoFit (modelParams ,beta (:),bias ,fitinfo ); 

end

function [obj ,fitInfo ]=fitClassificationLinear (...
    X ,Y ,W ,modelParams ,dataSummary ,classSummary ,scoreTransform )
obj =ClassificationLinear (dataSummary ,classSummary ,scoreTransform ); 

modelParams =fillIfNeeded (modelParams ,X ,Y ,W ,dataSummary ,classSummary ); 

lossfun =modelParams .LossFunction ; 

obj .DefaultLoss =@classreg .learning .loss .classiferror ; 
obj .LabelPredictor =@classreg .learning .classif .ClassificationModel .maxScore ; 
obj .DefaultScoreType ='inf' ; 

switchlower (lossfun )
case 'hinge' 
obj .Learner ='svm' ; 

case 'logit' 
obj .Learner ='logistic' ; 
ifisequal (obj .PrivScoreTransform ,@classreg .learning .transform .identity )
obj .ScoreTransform ='logit' ; 
obj .ScoreType ='probability' ; 
end

end


gidx =grp2idx (Y ,obj .ClassSummary .NonzeroProbClasses ); 
ifany (gidx ==2 )
doclass =2 ; 
gidx (gidx ==1 )=-1 ; 
gidx (gidx ==2 )=+1 ; 
else
doclass =1 ; 
end

valgidx =[]; 
if~isempty (modelParams .ValidationY )
valgidx =grp2idx (...
    classreg .learning .internal .ClassLabel (modelParams .ValidationY ),...
    obj .ClassSummary .NonzeroProbClasses ); 
ifany (valgidx ==2 )
valgidx (valgidx ==1 )=-1 ; 
valgidx (valgidx ==2 )=1 ; 
end
end

lambda =modelParams .Lambda ; 
ifstrcmp (lambda ,'auto' )
lambda =1 /numel (gidx ); 
end

obj .Impl =classreg .learning .impl .LinearImpl .make (doclass ,...
    modelParams .InitialBeta ,modelParams .InitialBias ,...
    X ,gidx ,W ,lossfun ,...
    strcmp (modelParams .Regularization ,'ridge' ),...
    lambda ,...
    modelParams .PassLimit ,...
    modelParams .BatchLimit ,...
    modelParams .NumCheckConvergence ,...
    modelParams .BatchIndex ,...
    modelParams .BatchSize ,...
    modelParams .Solver ,...
    modelParams .BetaTolerance ,...
    modelParams .GradientTolerance ,...
    modelParams .DeltaGradientTolerance ,...
    modelParams .LearnRate ,...
    modelParams .OptimizeLearnRate ,...
    modelParams .ValidationX ,valgidx ,modelParams .ValidationW ,...
    modelParams .IterationLimit ,...
    modelParams .TruncationPeriod ,...
    modelParams .FitBias ,...
    modelParams .PostFitBias ,...
    [],...
    modelParams .HessianHistorySize ,...
    modelParams .LineSearch ,...
    0 ,...
    modelParams .Stream ,...
    modelParams .VerbosityLevel ); 

modelParams =toStruct (modelParams ); 

modelParams =rmfield (modelParams ,'ValidationX' ); 
modelParams =rmfield (modelParams ,'ValidationY' ); 
modelParams =rmfield (modelParams ,'ValidationW' ); 

obj .ModelParams =modelParams ; 

fitInfo =obj .Impl .FitInfo ; 
fitInfo .Solver =obj .Impl .Solver ; 
end


function [X ,Y ,W ,dataSummary ,classSummary ,scoreTransform ]=...
    prepareData (X ,Y ,varargin )


args ={'classnames' ,'cost' ,'prior' ,'scoretransform' }; 
defs ={[],[],[],[]}; 
[userClassNames ,cost ,prior ,transformer ,~,crArgs ]=...
    internal .stats .parseArgs (args ,defs ,varargin {:}); 


allClassNames =levels (classreg .learning .internal .ClassLabel (Y )); 
ifisempty (allClassNames )
error (message ('stats:classreg:learning:classif:FullClassificationModel:prepareData:EmptyClassNames' )); 
end


[X ,Y ,W ,dataSummary ]=classreg .learning .Linear .prepareDataCR (...
    X ,classreg .learning .internal .ClassLabel (Y ),crArgs {:}); 


[X ,Y ,W ,userClassNames ,nonzeroClassNames ,dataSummary .RowsUsed ]=...
    classreg .learning .classif .FullClassificationModel .processClassNames (...
    X ,Y ,W ,userClassNames ,allClassNames ,...
    dataSummary .RowsUsed ,dataSummary .ObservationsInRows ); 
internal .stats .checkSupportedNumeric ('Weights' ,W ,true ); 



[~,loc ]=ismember (userClassNames ,nonzeroClassNames ); 
loc (loc ==0 )=[]; 
nonzeroClassNames =nonzeroClassNames (loc ); 


ifany (ismissing (Y ))
warning (message ('stats:ClassificationLinear:prepareData:YwithMissingValues' )); 
end
[X ,Y ,W ,dataSummary .RowsUsed ]=...
    classreg .learning .classif .FullClassificationModel .removeMissingVals (...
    X ,Y ,W ,dataSummary .RowsUsed ,dataSummary .ObservationsInRows ); 


C =classreg .learning .internal .classCount (nonzeroClassNames ,Y ); 
WC =bsxfun (@times ,C ,W ); 
Wj =sum (WC ,1 ); 


prior =classreg .learning .classif .FullClassificationModel .processPrior (...
    prior ,Wj ,userClassNames ,nonzeroClassNames ); 


cost =classreg .learning .classif .FullClassificationModel .processCost (...
    cost ,prior ,userClassNames ,nonzeroClassNames ); 


[X ,Y ,~,WC ,Wj ,prior ,cost ,nonzeroClassNames ,dataSummary .RowsUsed ]=...
    ClassificationTree .removeZeroPriorAndCost (...
    X ,Y ,C ,WC ,Wj ,prior ,cost ,nonzeroClassNames ,...
    dataSummary .RowsUsed ,dataSummary .ObservationsInRows ); 



ifnumel (nonzeroClassNames )>1 
prior =prior .*sum (cost ,2 )' ; 
cost =ones (2 )-eye (2 ); 
end




prior =prior /sum (prior ); 
W =sum (bsxfun (@times ,WC ,prior ./Wj ),2 ); 


classSummary =...
    classreg .learning .classif .FullClassificationModel .makeClassSummary (...
    userClassNames ,nonzeroClassNames ,prior ,cost ); 


K =numel (classSummary .NonzeroProbClasses ); 
ifK >2 
error (message ('stats:ClassificationLinear:prepareData:DoNotPassMoreThanTwoClasses' )); 
end


scoreTransform =...
    classreg .learning .classif .FullClassificationModel .processScoreTransform (transformer ); 
end

function name =matlabCodegenRedirect (~)
name ='classreg.learning.coder.classif.ClassificationLinear' ; 
end
end

end
