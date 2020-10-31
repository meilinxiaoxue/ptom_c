classdef ClassificationECOC <...
    classreg .learning .classif .FullClassificationModel &...
    classreg .learning .classif .CompactClassificationECOC 
























































properties (GetAccess =public ,SetAccess =protected ,Dependent =true )










BinaryY ; 







CodingName ; 
end

methods 
function bY =get .BinaryY (this )
M =this .CodingMatrix ; 
L =size (M ,2 ); 
N =this .NObservations ; 
bY =zeros (N ,L ); 

forl =1 :L 
neg =M (:,l )==-1 ; 
pos =M (:,l )==1 ; 
isneg =ismember (this .PrivY ,this .ClassSummary .ClassNames (neg )); 
ispos =ismember (this .PrivY ,this .ClassSummary .ClassNames (pos )); 
bY (isneg ,l )=-1 ; 
bY (ispos ,l )=1 ; 
end
end

function dn =get .CodingName (this )
ifischar (this .ModelParams .Coding )
dn =this .ModelParams .Coding ; 
else
dn ='custom' ; 
end
end
end

methods (Static ,Hidden )
function temp =template (varargin )
classreg .learning .FitTemplate .catchType (varargin {:}); 
temp =classreg .learning .FitTemplate .make ('ECOC' ,'type' ,'classification' ,varargin {:}); 
end

function this =fit (X ,Y ,varargin )
temp =ClassificationECOC .template (varargin {:}); 
this =fit (temp ,X ,Y ); 
end
end

methods (Hidden )
function this =ClassificationECOC (X ,Y ,W ,modelParams ,...
    dataSummary ,classSummary ,scoreTransform )

ifnargin ~=7 ||ischar (W )
error (message ('stats:ClassificationECOC:ClassificationECOC:DoNotUseConstructor' )); 
end


this =this @classreg .learning .classif .FullClassificationModel (...
    X ,Y ,W ,modelParams ,dataSummary ,classSummary ,scoreTransform ); 
this =this @classreg .learning .classif .CompactClassificationECOC (...
    dataSummary ,classSummary ,scoreTransform ,[],[],[]); 


K =numel (this .ClassSummary .ClassNames ); 
ifischar (this .ModelParams .Coding )
M =designecoc (K ,this .ModelParams .Coding ); 
else
M =this .ModelParams .Coding ; 
end







L =size (M ,2 ); 
learners =this .ModelParams .BinaryLearners ; 
ifiscell (learners )
ifnumel (learners )~=L 
error (message ('stats:ClassificationECOC:ClassificationECOC:BadNumberOfLearners' ,...
    numel (learners ),L )); 
end
else
learners =repmat ({learners },L ,1 ); 
end

C =classreg .learning .internal .classCount (...
    this .ClassSummary .ClassNames ,this .PrivY ); 

[this .BinaryLearners ,this .LearnerWeights ]=...
    localFitECOC (learners ,M ,this .PrivX ,C ,this .W ,...
    this .Prior ,this .Cost ,...
    this .ModelParams .FitPosterior ,...
    this .ObservationsInRows ,...
    this .ModelParams .Options ,...
    this .ModelParams .VerbosityLevel ); 

this .CodingMatrix =M ; 

[this .BinaryLoss ,this .DefaultScoreType ]=...
    classreg .learning .classif .CompactClassificationECOC .analyzeLearners (...
    this .BinaryLearners ); 
end

end

methods (Access =protected )
function s =propsForDisp (this ,s )
s =propsForDisp @classreg .learning .classif .CompactClassificationECOC (this ,s ); 
ifisfield (s ,'CodingMatrix' )
s =rmfield (s ,'CodingMatrix' ); 
end
s .CodingName =this .CodingName ; 
if~isempty (this .HyperparameterOptimizationResults )
s .HyperparameterOptimizationResults =this .HyperparameterOptimizationResults ; 
end
end
end

methods 
function partModel =crossval (this ,varargin )




























[varargin {:}]=convertStringsToChars (varargin {:}); 

idxBaseArg =find (ismember (lower (varargin (1 :2 :end)),...
    classreg .learning .FitTemplate .AllowedBaseFitObjectArgs )); 
if~isempty (idxBaseArg )
error (message ('stats:classreg:learning:classif:FullClassificationModel:crossval:NoBaseArgs' ,varargin {2 *idxBaseArg -1 })); 
end


args ={'options' }; 
defs ={[]}; 
[paropts ,~,extraArgs ]=internal .stats .parseArgs (args ,defs ,varargin {:}); 
if~isempty (paropts )&&~isstruct (paropts )
error (message ('stats:ClassificationECOC:crossval:BadOptionsType' )); 
end



modelParams =this .ModelParams ; 
modelParams .VerbosityLevel =0 ; 
temp =classreg .learning .FitTemplate .make (this .ModelParams .Method ,...
    'type' ,'classification' ,'modelparams' ,modelParams ,...
    'crossval' ,'on' ,'options' ,paropts ,extraArgs {:}); 


partModel =fit (temp ,this .X ,this .Y ,'Weights' ,this .W ,...
    'predictornames' ,this .DataSummary .PredictorNames ,...
    'categoricalpredictors' ,this .CategoricalPredictors ,...
    'responsename' ,this .ResponseName ,...
    'classnames' ,this .ClassNames ,'cost' ,this .Cost ,'prior' ,this .Prior ); 
end

function cmp =compact (this )








dataSummary =this .DataSummary ; 
dataSummary .RowsUsed =[]; 
cmp =classreg .learning .classif .CompactClassificationECOC (...
    dataSummary ,this .ClassSummary ,this .PrivScoreTransform ,...
    this .BinaryLearners ,this .LearnerWeights ,this .CodingMatrix ); 
end

function [varargout ]=resubPredict (this ,varargin )














































































[varargin {:}]=convertStringsToChars (varargin {:}); 
[varargout {1 :nargout }]=...
    resubPredict @classreg .learning .classif .FullClassificationModel (this ,varargin {:}); 
end

function [varargout ]=resubLoss (this ,varargin )

























































[varargin {:}]=convertStringsToChars (varargin {:}); 
[varargout {1 :nargout }]=...
    resubLoss @classreg .learning .classif .FullClassificationModel (this ,varargin {:}); 
end

function m =resubMargin (this ,varargin )











































[varargin {:}]=convertStringsToChars (varargin {:}); 
m =resubMargin @classreg .learning .classif .FullClassificationModel (this ,varargin {:}); 
end

function e =resubEdge (this ,varargin )









































[varargin {:}]=convertStringsToChars (varargin {:}); 
e =resubEdge @classreg .learning .classif .FullClassificationModel (this ,varargin {:}); 
end
end

end


function [learners ,weights ]=localFitECOC (...
    tmp ,M ,X ,C ,W ,prior ,cost ,doposterior ,obsInRows ,paropts ,verbose )



















[K ,L ]=size (M ); 

[N ,K2 ]=size (C ); 
ifK2 ~=K 
error (message ('stats:ClassificationECOC:localFitECOC:MismatchBetweenCodingMatrixAndClassMembership' ,K ,K2 )); 
end


warnState =warning ('query' ,'all' ); 
warning ('off' ); 
cleanupObj =onCleanup (@()warning (warnState )); 

[useParallel ,RNGscheme ]=...
    internal .stats .parallel .processParallelAndStreamOptions (paropts ); 

[learners ,weights ]=...
    internal .stats .parallel .smartForSliceout (L ,@loopBody ,useParallel ,RNGscheme ); 

weights =weights (:)' ; 

function [learner ,weight ]=loopBody (l ,s )
ifisempty (s )
s =RandStream .getGlobalStream ; 
end

pos =find (M (:,l )==+1 ); 
neg =find (M (:,l )==-1 ); 

if~isempty (prior )
lPrior =[sum (prior (neg )),sum (prior (pos ))]; 
else
lPrior ='empirical' ; 
end








if~isempty (cost )&&all (lPrior >0 )
cost (isnan (cost ))=0 ; 
lPrior =...
    [sum (prior (neg ))*prior (neg )*cost (neg ,pos )*prior (pos )' ...
    ,sum (prior (pos ))*prior (pos )*cost (pos ,neg )*prior (neg )' ]; 
end

idxpos =sum (C (:,pos ),2 )>0 ; 
idxneg =sum (C (:,neg ),2 )>0 ; 

y =zeros (N ,1 ); 
y (idxpos )=+1 ; 
y (idxneg )=-1 ; 

x =X ; 
w =W ; 
ifany (y ==0 )
ifobsInRows 
x (y ==0 ,:)=[]; 
else
x (:,y ==0 )=[]; 
end
w (y ==0 )=[]; 
y (y ==0 )=[]; 
end

ifverbose >0 
fprintf ('%s\n' ,getString (message ('stats:ClassificationECOC:localFitECOC:TrainingLearner' ,...
    l ,tmp {l }.Method ,L ,sum (idxneg ),sum (idxpos )))); 
ifverbose >1 
fprintf ('%s' ,getString (message ('stats:ClassificationECOC:localFitECOC:NegativeIndices' ))); 
forn =1 :numel (neg )
fprintf (' %i' ,neg (n )); 
end
fprintf ('\n' ); 

fprintf ('%s' ,getString (message ('stats:ClassificationECOC:localFitECOC:PositiveIndices' ))); 
forn =1 :numel (pos )
fprintf (' %i' ,pos (n )); 
end
fprintf ('\n\n' ); 
end
end

weight =sum (w ); 

try
full =fit (tmp {l },x ,y ,'ClassNames' ,[-1 ,1 ],'Prior' ,lPrior ,'weights' ,w ); 
catch me 
warning ('on' ,'all' ); 
warning (message ('stats:ClassificationECOC:localFitECOC:CannotFitLearner' ,...
    l ,tmp {l }.Method ,me .message )); 
warning ('off' ,'all' ); 
learner ={[]}; 
return ; 
end

ifdoposterior &&~strcmp (full .ScoreType ,'probability' )
ifisa (full ,'ClassificationSVM' )
ifverbose >0 
fprintf ('%s\n' ,getString (message ('stats:ClassificationECOC:localFitECOC:FittingLearner' ,...
    l ,tmp {l }.Method ))); 
end

try
tb =tabulate (full .Y ); 
kfold =min (tb (:,2 )); 
kfold =min (kfold ,10 ); 
ifkfold <2 
error (message ('stats:ClassificationECOC:localFitECOC:NotEnoughDataToFitPosterior' )); 
end
cvpart =cvpartition (full .Y ,'kfold' ,kfold ,s ); 
full =fitPosterior (full ,'cvpartition' ,cvpart ); 
catch me 
warning ('on' ,'all' ); 
warning (message ('stats:ClassificationECOC:localFitECOC:CannotFitPosterior' ,...
    l ,tmp {l }.Method ,me .message )); 
warning ('off' ,'all' ); 
learner ={[]}; 
return ; 
end

elseifisa (full ,'ClassificationDiscriminant' )...
    ||isa (full ,'ClassificationKNN' )...
    ||isa (full ,'ClassificationTree' )


full .ScoreTransform =@classreg .learning .transform .identity ; 

elseifisa (full ,'classreg.learning.classif.ClassificationEnsemble' )...
    &&~isempty (full .TransformToProbability )
full .ScoreTransform =full .TransformToProbability ; 










elseifisa (full ,'ClassificationLinear' )
error (message ('stats:ClassificationECOC:localFitECOC:UseLinearWithLogistic' )); 

else
error (message ('stats:ClassificationECOC:localFitECOC:CannotUseLearnerToEstimatePosterior' ,...
    l ,tmp {l }.Method )); 

end
end

learner ={compact (full )}; 
end

end
