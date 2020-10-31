classdef ClassificationPartitionedLinearECOC <...
    classreg .learning .partition .PartitionedECOC ...
    &classreg .learning .partition .CompactClassificationPartitionedModel 

















































properties (GetAccess =public ,SetAccess =protected ,Dependent =true )















BinaryY ; 
end

methods (Hidden )
function this =ClassificationPartitionedLinearECOC (X ,Y ,W ,modelParams ,...
    dataSummary ,classSummary ,scoreTransform )
this =this @classreg .learning .partition .PartitionedECOC ; 
this =this @classreg .learning .partition .CompactClassificationPartitionedModel (...
    X ,Y ,W ,modelParams ,dataSummary ,classSummary ,scoreTransform ); 
this .DefaultLoss =@classreg .learning .loss .classiferror ; 
this .LabelPredictor =@classreg .learning .classif .ClassificationModel .maxScore ; 
this .CrossValidatedModel ='LinearECOC' ; 
end
end


methods 
function bY =get .BinaryY (this )
M =this .CodingMatrix ; 
L =size (M ,2 ); 
N =this .NumObservations ; 
bY =zeros (N ,L ); 

forl =1 :L 
neg =M (:,l )==-1 ; 
pos =M (:,l )==1 ; 
isneg =any (this .PrivC (:,neg ),2 ); 
ispos =any (this .PrivC (:,pos ),2 ); 
bY (isneg ,l )=-1 ; 
bY (ispos ,l )=1 ; 
end
end
end


methods (Access =protected )
function cvmodel =getCrossValidatedModel (~)
cvmodel ='LinearECOC' ; 
end

function lw =learnerWeights (this )
WC =bsxfun (@times ,this .PrivC ,this .W ); 

M =this .CodingMatrix ; 
L =size (M ,2 ); 

ifany (M (:)==0 )
lw =NaN (1 ,L ); 
forl =1 :L 
lw (l )=sum (sum (WC (:,M (:,l )~=0 ))); 
end
else
lw =repmat (sum (this .W ),1 ,L ); 
end
end

function S =score (this )
S =[]; 

trained =this .Ensemble .Trained ; 
T =numel (trained ); 

ifT >0 
X =this .Ensemble .X ; 




ifthis .Ensemble .ObservationsInRows 
X =X ' ; 
end

B =size (this .CodingMatrix ,2 ); 

L =[]; 
fort =1 :T 
if~isempty (trained {t })
blearners =trained {t }.BinaryLearners ; 
B =numel (blearners ); 
forb =1 :B 
if~isempty (blearners {b })
ifisempty (L )
L =numel (blearners {b }.Lambda ); 
else
ifL ~=numel (blearners {b }.Lambda )
error (message ('stats:classreg:learning:partition:ClassificationPartitionedLinearECOC:score:LambdaMismatch' ,b ,t ,L )); 
end
end
end
end
end
end

ifisempty (L )
return ; 
end

N =size (X ,2 ); 

S =NaN (N ,B ,L ); 

uofl =~this .PrivGenerator .UseObsForIter ; 

T =numel (trained ); 
fort =1 :T 
if~isempty (trained {t })
idx =uofl (:,t ); 
[~,~,S (idx ,:,:)]=predict (trained {t },X (:,idx ),...
    'ObservationsIn' ,'columns' ); 
end
end
end
end

function s =propsForDisp (this ,s )
ifnargin <2 ||isempty (s )
s =struct ; 
else
if~isstruct (s )
error (message ('stats:classreg:learning:Predictor:propsForDisp:BadS' )); 
end
end

s .CrossValidatedModel ='Linear' ; 
s .ResponseName =this .ResponseName ; 
s .NumObservations =this .NumObservations ; 
s .KFold =this .KFold ; 
s .Partition =this .Partition ; 
cnames =this .ClassNames ; 
ifischar (cnames )
s .ClassNames =cnames ; 
else
s .ClassNames =cnames ' ; 
end
s .ScoreTransform =this .ScoreTransform ; 
end
end


methods 
function [labels ,negloss ,pscore ,posterior ]=kfoldPredict (this ,varargin )




























































































pscore =this .PrivScore ; 
[N ,~,S ]=size (pscore ); 

ifisempty (pscore )
labels =repmat (this .ClassNames (1 ,:),0 ,1 ); 
K =numel (this .ClassSummary .ClassNames ); 
L =numel (this .BinaryLearners ); 
negloss =NaN (0 ,K ); 
pscore =NaN (0 ,L ); 
posterior =NaN (0 ,K ); 
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

M =this .CodingMatrix ; 
ifignorezeros 
M (M ==0 )=NaN ; 
end




K =size (M ,1 ); 
negloss =NaN (N ,K ,S ); 
uofl =~this .PrivGenerator .UseObsForIter ; 
F =size (uofl ,2 ); 
forf =1 :F 
iuse =uofl (:,f ); 
fors =1 :S 
negloss (iuse ,:,s )=-classreg .learning .ecocutils .loss (...
    dist ,M ,pscore (iuse ,:,s ),useParallel ,isBuiltinDist ); 
end
end
ifverbose >0 
fprintf ('%s\n' ,getString (message ('stats:classreg:learning:classif:CompactClassificationECOC:score:LossComputed' ))); 
end


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
lw =learnerWeights (this ); 
ifS ==1 
posterior =classreg .learning .ecocutils .posteriorFromRatio (M ,pscore ,...
    lw ,verbose ,doquadprog ,numfits ,useParallel ,RNGscheme ); 
else
posterior =NaN (N ,K ,S ); 
fors =1 :S 
posterior (:,:,s )=classreg .learning .ecocutils .posteriorFromRatio (M ,pscore (:,:,s ),...
    lw ,verbose ,doquadprog ,numfits ,useParallel ,RNGscheme ); 
end
end
end
end


function err =kfoldLoss (this ,varargin )












































































classreg .learning .ensemble .Ensemble .catchUOFL (varargin {:}); 
classreg .learning .FullClassificationRegressionModel .catchWeights (varargin {:}); 
[mode ,folds ,extraArgs ]=checkFoldArgs (this .PartitionedModel ,varargin {:}); 


args ={'lossfun' }; 
defs ={this .DefaultLoss }; 
[funloss ,~,extraArgs ]=...
    internal .stats .parseArgs (args ,defs ,extraArgs {:}); 


funloss =classreg .learning .internal .lossCheck (funloss ,'classification' ); 


[~,negloss ]=kfoldPredict (this ,extraArgs {:}); 


L =size (negloss ,3 ); 
C =this .PrivC ; 
w =this .W ; 
cost =this .Ensemble .Cost ; 


uofl =~this .PrivGenerator .UseObsForIter ; 
ifstrncmpi (mode ,'ensemble' ,length (mode ))
err =NaN (1 ,L ); 
iuse =any (uofl (:,folds ),2 ); 
forl =1 :L 
err (l )=funloss (C (iuse ,:),negloss (iuse ,:,l ),w (iuse ),cost ); 
end
elseifstrncmpi (mode ,'individual' ,length (mode ))
T =numel (folds ); 
err =NaN (T ,L ); 
fork =1 :T 
t =folds (k ); 
iuse =uofl (:,t ); 
forl =1 :L 
err (k ,l )=funloss (C (iuse ,:),negloss (iuse ,:,l ),w (iuse ),cost ); 
end
end
else
error (message ('stats:classreg:learning:partition:PartitionedModel:checkFoldArgs:BadMode' )); 
end
end


function e =kfoldEdge (this ,varargin )


























































e =kfoldLoss (this ,'LossFun' ,@classreg .learning .loss .classifedge ,varargin {:}); 
end


function m =kfoldMargin (this ,varargin )















































classreg .learning .ensemble .Ensemble .catchUOFL (varargin {:}); 
classreg .learning .partition .PartitionedModel .catchFolds (varargin {:}); 
classreg .learning .FullClassificationRegressionModel .catchWeights (varargin {:}); 

[~,negloss ]=kfoldPredict (this ,varargin {:}); 
N =size (negloss ,1 ); 
L =size (negloss ,3 ); 
C =this .PrivC ; 

m =NaN (N ,L ); 
forl =1 :L 
m (:,l )=classreg .learning .loss .classifmargin (C ,negloss (:,:,l )); 
end
end
end

end
