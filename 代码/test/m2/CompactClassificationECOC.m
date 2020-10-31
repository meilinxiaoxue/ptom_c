classdef CompactClassificationECOC <classreg .learning .classif .ClassificationModel 































properties (GetAccess =public ,SetAccess =protected )







BinaryLearners ={}; 






BinaryLoss =[]; 











CodingMatrix =[]; 








LearnerWeights =[]; 
end

properties (GetAccess =protected ,SetAccess =protected ,Dependent =true )

IsLinear ; 
end

methods (Access =private ,Static )
function name =matlabCodegenRedirect (~)
name ='classreg.learning.coder.classif.CompactClassificationECOC' ; 
end
end

methods 
function islin =get .IsLinear (this )
f =@(z )isa (z ,'ClassificationLinear' ); 
islin =any (cellfun (f ,this .BinaryLearners )); 
end
end

methods (Access =protected )
function this =setScoreType (~,~)%#ok<STOUT> 
error (message ('stats:classreg:learning:classif:CompactClassificationECOC:setScoreType:DoNotUseScoreType' )); 
end

function cl =getContinuousLoss (this )%#ok<STOUT,MANU> 

error (message ('stats:classreg:learning:classif:CompactClassificationECOC:getContinuousLoss:DoNotUseContinuousLoss' )); 
end

function this =CompactClassificationECOC (...
    dataSummary ,classSummary ,scoreTransform ,learners ,weights ,M )
this =this @classreg .learning .classif .ClassificationModel (...
    dataSummary ,classSummary ,scoreTransform ,[]); 
this .LabelPredictor =@classreg .learning .classif .ClassificationModel .maxScore ; 
this .DefaultLoss =@classreg .learning .loss .classiferror ; 
this .BinaryLearners =learners ; 
this .LearnerWeights =weights ; 
this .CodingMatrix =M ; 
[this .BinaryLoss ,this .DefaultScoreType ]=...
    classreg .learning .classif .CompactClassificationECOC .analyzeLearners (learners ); 
end

function s =propsForDisp (this ,s )
s =propsForDisp @classreg .learning .classif .ClassificationModel (this ,s ); 
s .BinaryLearners =this .BinaryLearners ; 
s .CodingMatrix =this .CodingMatrix ; 

ifthis .IsLinear 
s =rmfield (s ,'CategoricalPredictors' ); 
end
end

function [labels ,negloss ,pscore ,posterior ]=predictEmptyX (this ,X )
Dexp =numel (this .PredictorNames ); 
ifthis .ObservationsInRows 
D =size (X ,2 ); 
str =getString (message ('stats:classreg:learning:classif:ClassificationModel:predictEmptyX:columns' )); 
else
D =size (X ,1 ); 
str =getString (message ('stats:classreg:learning:classif:ClassificationModel:predictEmptyX:rows' )); 
end
ifD ~=Dexp 
error (message ('stats:classreg:learning:classif:ClassificationModel:predictEmptyX:XSizeMismatch' ,Dexp ,str )); 
end
labels =repmat (this .ClassNames (1 ,:),0 ,1 ); 
K =numel (this .ClassSummary .ClassNames ); 
L =numel (this .BinaryLearners ); 
negloss =NaN (0 ,K ); 
pscore =NaN (0 ,L ); 
posterior =NaN (0 ,K ); 
end

function [labels ,negloss ,pscore ,posterior ]=predictForEmptyLearners (this ,X )
Dexp =numel (this .PredictorNames ); 
ifthis .ObservationsInRows 
[N ,D ]=size (X ); 
str =getString (message ('stats:classreg:learning:classif:ClassificationModel:predictEmptyX:columns' )); 
else
[D ,N ]=size (X ); 
str =getString (message ('stats:classreg:learning:classif:ClassificationModel:predictEmptyX:rows' )); 
end
ifDexp ~=D 
error (message ('stats:classreg:learning:classif:ClassificationModel:predictEmptyX:XSizeMismatch' ,D ,str )); 
end
K =numel (this .ClassSummary .ClassNames ); 
L =numel (this .BinaryLearners ); 

[~,cls ]=max (this .Prior ); 
labels =repmat (this .ClassNames (cls ,:),N ,1 ); 
negloss =NaN (N ,K ); 
pscore =NaN (N ,L ); 
posterior =zeros (N ,K ); 
posterior (:,cls )=1 ; 
end

function [negloss ,pscore ]=score (...
    this ,X ,dist ,isBuiltinDist ,ignorezeros ,useParallel ,verbose )

trained =this .BinaryLearners ; 
M =this .CodingMatrix ; 


ifignorezeros 
M (M ==0 )=NaN ; 
end

ifthis .TableInput 
X =classreg .learning .internal .table2PredictMatrix (X ,[],[],...
    this .VariableRange ,...
    this .CategoricalPredictors ,this .PredictorNames ); 
end


pscore =localScore (X ,trained ,useParallel ,verbose ,this .ObservationsInRows ); 

ifverbose >0 
fprintf ('%s\n' ,getString (message ('stats:classreg:learning:classif:CompactClassificationECOC:score:PredictionsComputed' ))); 
end


[N ,~,S ]=size (pscore ); 
K =size (M ,1 ); 
negloss =NaN (N ,K ,S ,class (pscore )); 
fors =1 :S 
negloss (:,:,s )=-classreg .learning .ecocutils .loss (...
    dist ,M ,pscore (:,:,s ),useParallel ,isBuiltinDist ); 
end
ifverbose >0 
fprintf ('%s\n' ,getString (message ('stats:classreg:learning:classif:CompactClassificationECOC:score:LossComputed' ))); 
end
end
end


methods 
function varargout =predict (this ,X ,varargin )







































































































[varargin {:}]=convertStringsToChars (varargin {:}); 

adapter =classreg .learning .internal .makeClassificationModelAdapter (this ,X ,varargin {:}); 
if~isempty (adapter )
[varargout {1 :max (1 ,nargout )}]=predict (adapter ,X ,varargin {:}); 
return 
end

ifthis .IsLinear 
internal .stats .checkSupportedNumeric ('X' ,X ,false ,true ); 
end


[X ,varargin ]=classreg .learning .internal .orientX (...
    X ,this .ObservationsInRows ,varargin {:}); 


ifisempty (X )
ifthis .TableInput ||istable (X )
vrange =getvrange (this ); 
X =classreg .learning .internal .table2PredictMatrix (X ,[],[],...
    vrange ,...
    this .CategoricalPredictors ,this .PredictorNames ); 
end
[varargout {1 :max (1 ,nargout )}]=predictEmptyX (this ,X ); 
return ; 
end



ifall (cellfun (@isempty ,this .BinaryLearners ))
[varargout {1 :max (1 ,nargout )}]=predictForEmptyLearners (this ,X ); 
return ; 
end


args ={'binaryloss' ,'decoding' ,'verbose' ...
    ,'posteriormethod' ,'numklinitializations' ,'options' }; 
defs ={this .BinaryLoss ,'lossweighted' ,0 ...
    ,'kl' ,0 ,statset ('parallel' )}; 
[userloss ,decoding ,verbose ,postmethod ,numfits ,paropts ]=...
    internal .stats .parseArgs (args ,defs ,varargin {:}); 


doposterior =nargout >3 ; 

[dist ,isBuiltinDist ,ignorezeros ,doquadprog ]=...
    classreg .learning .ecocutils .prepareForPredictECOC (...
    this .ScoreType ,doposterior ,postmethod ,userloss ,this .BinaryLoss ,...
    decoding ,numfits ); 


[useParallel ,RNGscheme ]=...
    internal .stats .parallel .processParallelAndStreamOptions (paropts ); 


[negloss ,pscore ]=score (...
    this ,X ,dist ,isBuiltinDist ,ignorezeros ,useParallel ,verbose ); 
[N ,~,S ]=size (pscore ); 


prior =this .Prior ; 
cost =this .Cost ; 
classnames =this .ClassNames ; 
ifischar (classnames )&&S >1 
classnames =cellstr (classnames ); 
end
labels =repmat (classnames (1 ,:),N ,S ); 

ifS ==1 
labels =this .LabelPredictor (classnames ,prior ,cost ,negloss ,@(x )x ); 
else
fors =1 :S 
labels (:,s )=...
    this .LabelPredictor (classnames ,prior ,cost ,negloss (:,:,s ),@(x )x ); 
end
end


ifdoposterior 
ifS ==1 
posterior =classreg .learning .ecocutils .posteriorFromRatio (...
    this .CodingMatrix ,pscore ,this .LearnerWeights ,...
    verbose ,doquadprog ,numfits ,useParallel ,RNGscheme ); 
else
K =size (this .CodingMatrix ,1 ); 
posterior =NaN (N ,K ,S ); 
fors =1 :S 
posterior (:,:,s )=classreg .learning .ecocutils .posteriorFromRatio (...
    this .CodingMatrix ,pscore (:,:,s ),this .LearnerWeights ,...
    verbose ,doquadprog ,numfits ,useParallel ,RNGscheme ); 
end
end
end

ifdoposterior 
varargout ={labels ,negloss ,pscore ,posterior }; 
else
varargout ={labels ,negloss ,pscore }; 
end
end

function m =margin (this ,X ,varargin )































































[varargin {:}]=convertStringsToChars (varargin {:}); 

adapter =classreg .learning .internal .makeClassificationModelAdapter (this ,X ,varargin {:}); 
if~isempty (adapter )
m =slice (adapter ,@this .margin ,X ,varargin {:}); 
return 
end

ifthis .IsLinear 
internal .stats .checkSupportedNumeric ('X' ,X ,false ,true ); 
end
m =margin @classreg .learning .classif .ClassificationModel (this ,X ,varargin {:}); 
end

function e =edge (this ,X ,varargin )





























































[varargin {:}]=convertStringsToChars (varargin {:}); 

adapter =classreg .learning .internal .makeClassificationModelAdapter (this ,X ,varargin {:}); 
if~isempty (adapter )
e =edge (adapter ,X ,varargin {:}); 
return 
end

ifthis .IsLinear 
internal .stats .checkSupportedNumeric ('X' ,X ,false ,true ); 
end
e =edge @classreg .learning .classif .ClassificationModel (this ,X ,varargin {:}); 
end

function l =loss (this ,X ,varargin )










































































[varargin {:}]=convertStringsToChars (varargin {:}); 

adapter =classreg .learning .internal .makeClassificationModelAdapter (this ,X ,varargin {:}); 
if~isempty (adapter )
l =loss (adapter ,X ,varargin {:}); 
return 
end

ifthis .IsLinear 
internal .stats .checkSupportedNumeric ('X' ,X ,false ,true ); 
end
l =loss @classreg .learning .classif .ClassificationModel (this ,X ,varargin {:}); 
end

function this =discardSupportVectors (this )










f =@(z )isa (z ,'classreg.learning.classif.CompactClassificationSVM' )...
    &&strcmp (z .KernelParameters .Function ,'linear' ); 
isLinearSVM =cellfun (f ,this .BinaryLearners ); 


if~any (isLinearSVM )
warning (message ('stats:classreg:learning:classif:CompactClassificationECOC:discardSupportVectors:NoLinearSVMLearners' )); 
return ; 
end


idxLinearSVM =find (isLinearSVM ); 
fori =1 :numel (idxLinearSVM )
n =idxLinearSVM (i ); 
this .BinaryLearners {n }=discardSupportVectors (this .BinaryLearners {n }); 
end
end

function this =selectModels (this ,idx )











if~isnumeric (idx )||~isvector (idx )||~isreal (idx )||any (idx (:)<0 )...
    ||any (round (idx )~=idx )
error (message ('stats:classreg:learning:classif:CompactClassificationECOC:selectModels:BadIdx' )); 
end


f =@(z )isa (z ,'ClassificationLinear' ); 
isLinear =cellfun (f ,this .BinaryLearners ); 


if~all (isLinear )
error (message ('stats:classreg:learning:classif:CompactClassificationECOC:selectModels:NonLinearLearners' )); 
end


T =numel (this .BinaryLearners ); 
fort =1 :T 
this .BinaryLearners {t }=selectModels (this .BinaryLearners {t },idx ); 
end
end
end

methods (Hidden =true )


function cmp =compact (this )
cmp =this ; 
end

function s =toStruct (this )


warnState =warning ('query' ,'all' ); 
warning ('off' ,'MATLAB:structOnObject' ); 
cleanupObj =onCleanup (@()warning (warnState )); 


s =classreg .learning .coderutils .classifToStruct (this ); 


s .FromStructFcn ='classreg.learning.classif.CompactClassificationECOC.fromStruct' ; 


learners =this .BinaryLearners ; 
L =numel (learners ); 
learners_struct =struct ; 

forj =1 :L 
fname =['Learner_' ,num2str (j )]; 
ifisempty (learners {j })
learners_struct .(fname )=learners {j }; 
else
if~isa (learners {j },'classreg.learning.classif.CompactClassificationSVM' )...
    &&~isa (learners {j },'ClassificationLinear' )
error (message ('stats:classreg:learning:classif:CompactClassificationECOC:toStruct:NonSVMorLinearLearnersNotSupported' )); 
end
learners_struct .(fname )=learners {j }.toStruct ; 
end
end

s .NumBinaryLearners =L ; 
s .BinaryLearners =learners_struct ; 


s .CodingMatrix =this .CodingMatrix ; 
s .LearnerWeights =this .LearnerWeights ; 
s .BinaryLoss =this .BinaryLoss ; 
end
end

methods (Static =true ,Hidden =true )
function obj =fromStruct (s )


s =classreg .learning .coderutils .structToClassif (s ); 


L =s .NumBinaryLearners ; 
learners =cell (L ,1 ); 

forj =1 :L 
fname =['Learner_' ,num2str (j )]; 
learner_struct =s .BinaryLearners .(fname ); 
if~isempty (learner_struct )
fcn =str2func (learner_struct .FromStructFcn ); 
learners {j }=fcn (learner_struct ); 
else
learners {j }=learner_struct ; 
end
end


obj =classreg .learning .classif .CompactClassificationECOC (...
    s .DataSummary ,s .ClassSummary ,s .ScoreTransform ,...
    learners ,s .LearnerWeights ,s .CodingMatrix ); 


if~strcmp (obj .BinaryLoss ,s .BinaryLoss )
error (message ('stats:classreg:learning:classif:CompactClassificationECOC:fromStruct:BinaryLossMismatch' )); 
end
end

function [lossType ,scoreType ]=analyzeLearners (learners )
ifisempty (learners )
lossType ='hamming' ; 
scoreType ='unknown' ; 
return ; 
end


L =numel (learners ); 
scoreTypes =repmat ({'' },L ,1 ); 
lossTypes =repmat ({'' },L ,1 ); 
forl =1 :L 
lrn =learners {l }; 
if~isempty (lrn )
scoreTypes (l )={lrn .ScoreType }; 
lossTypes (l )={lossToString (lrn .ContinuousLoss )}; 
end
end


ifismember ('unknown' ,scoreTypes )
scoreType ='unknown' ; 
warning (message ('stats:classreg:learning:classif:CompactClassificationECOC:analyzeLearners:UnknownScoreType' )); 
elseif(ismember ('01' ,scoreTypes )||ismember ('probability' ,scoreTypes ))...
    &&ismember ('inf' ,scoreTypes )
scoreType ='unknown' ; 
warning (message ('stats:classreg:learning:classif:CompactClassificationECOC:analyzeLearners:ScoreRangeMismatch' )); 
elseifismember ('01' ,scoreTypes )
scoreType ='01' ; 
elseifismember ('probability' ,scoreTypes )
scoreType ='probability' ; 
elseifismember ('inf' ,scoreTypes )
scoreType ='inf' ; 
else


scoreType ='unknown' ; 
end




lossTypes (strcmp (lossTypes ,'' ))=[]; 
lossTypes =unique (lossTypes ); 
ifisempty (lossTypes )
lossType ='' ; 
warning (message ('stats:classreg:learning:classif:CompactClassificationECOC:analyzeLearners:AllLearnersEmpty' )); 
elseifstrcmp (scoreType ,'unknown' )
lossType ='' ; 
elseifnumel (lossTypes )==1 
lossType =lossTypes {1 }; 
else
lossType ='hamming' ; 
warning (message ('stats:classreg:learning:classif:CompactClassificationECOC:analyzeLearners:HammingLoss' )); 
end
end
end

end


function str =lossToString (fhandle )
ifisequal (fhandle ,@classreg .learning .loss .quadratic )
str ='quadratic' ; 
elseifisequal (fhandle ,@classreg .learning .loss .hinge )
str ='hinge' ; 
elseifisequal (fhandle ,@classreg .learning .loss .exponential )
str ='exponential' ; 
elseifisequal (fhandle ,@classreg .learning .loss .binodeviance )
str ='binodeviance' ; 
else
str ='unknown' ; 
end
end


function pscore =localScore (X ,trained ,useParallel ,verbose ,obsInRows )

ifobsInRows 
N =size (X ,1 ); 
predictArgs ={}; 
else
N =size (X ,2 ); 
predictArgs ={'ObservationsIn' ,'columns' }; 
end
T =numel (trained ); 

pscore_cell =...
    internal .stats .parallel .smartForSliceout (T ,@loopBody ,useParallel ); 

allS =cellfun (@(z )size (z ,3 ),pscore_cell ); 
S =unique (allS (allS >1 )); 

ifnumel (S )>1 
error (message ('stats:classreg:learning:classif:CompactClassificationECOC:localScore:BinaryScoreSizeMismatch' )); 
end

ifisempty (S )
S =1 ; 
end

isSingle =any (cellfun (@(z )isa (z ,'single' ),pscore_cell )); 
ifisSingle 
pscore =NaN (N ,T ,S ,'single' ); 
else
pscore =NaN (N ,T ,S ); 
end

fort =1 :T 
ifS >1 &&isvector (pscore_cell {t })
pscore (:,t ,:)=repmat (pscore_cell {t },1 ,1 ,S ); 
else
pscore (:,t ,:)=pscore_cell {t }; 
end
end

function lscore =loopBody (l ,~)
ifverbose >1 
fprintf ('%s\n' ,getString (message ('stats:classreg:learning:classif:CompactClassificationECOC:localScore:ProcessingLearner' ,l ))); 
end

ifisempty (trained {l })
lscore ={NaN (N ,1 )}; 
else
[~,s ]=predict (trained {l },X ,predictArgs {:}); 
lscore ={s (:,2 ,:)}; 
end
end
end
