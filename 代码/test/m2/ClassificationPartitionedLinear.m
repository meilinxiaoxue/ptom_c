classdef ClassificationPartitionedLinear <classreg .learning .partition .CompactClassificationPartitionedModel 













































methods (Hidden )
function this =ClassificationPartitionedLinear (X ,Y ,W ,modelParams ,...
    dataSummary ,classSummary ,scoreTransform )
this =this @classreg .learning .partition .CompactClassificationPartitionedModel (...
    X ,Y ,W ,modelParams ,dataSummary ,classSummary ,scoreTransform ); 
this .CrossValidatedModel ='Linear' ; 
end
end


methods (Access =protected )
function S =score (this )
S =[]; 
pm =this .PartitionedModel ; 
trained =pm .Ensemble .Trained ; 
if~isempty (trained )
X =pm .Ensemble .X ; 




ifpm .Ensemble .ObservationsInRows 
X =X ' ; 
end

L =numel (trained {1 }.Lambda ); 
N =size (X ,2 ); 
K =numel (pm .Ensemble .ClassSummary .ClassNames ); 

S =NaN (N ,K ,L ); 

uofl =~this .PrivGenerator .UseObsForIter ; 

T =numel (trained ); 
fort =1 :T 
if~isempty (trained {t })
idx =uofl (:,t ); 
[~,S (idx ,:,:)]=predict (trained {t },X (:,idx ),...
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
function [labels ,score ]=kfoldPredict (this )














score =this .PrivScore ; 
L =size (score ,3 ); 
N =size (score ,1 ); 

prior =this .Prior ; 
cost =this .Cost ; 
scoreTransform =this .PartitionedModel .PrivScoreTransform ; 
classnames =this .ClassNames ; 
ifischar (classnames )&&L >1 
classnames =cellstr (classnames ); 
end
labels =repmat (classnames (1 ,:),N ,L ); 

ifL ==1 
[labels ,score ]=...
    this .LabelPredictor (classnames ,prior ,cost ,score ,scoreTransform ); 
else
forl =1 :L 
[labels (:,l ),score (:,:,l )]=...
    this .LabelPredictor (classnames ,prior ,cost ,score (:,:,l ),scoreTransform ); 
end
end
end


function err =kfoldLoss (this ,varargin )









































classreg .learning .ensemble .Ensemble .catchUOFL (varargin {:}); 
classreg .learning .FullClassificationRegressionModel .catchWeights (varargin {:}); 
[mode ,folds ,extraArgs ]=checkFoldArgs (this .PartitionedModel ,varargin {:}); 


args ={'lossfun' }; 
defs ={this .DefaultLoss }; 
funloss =internal .stats .parseArgs (args ,defs ,extraArgs {:}); 


funloss =classreg .learning .internal .lossCheck (funloss ,'classification' ); 


score =this .PartitionedModel .PrivScoreTransform (this .PrivScore ); 
L =size (score ,3 ); 
C =this .PrivC ; 
w =this .W ; 
cost =this .Cost ; 


uofl =~this .PrivGenerator .UseObsForIter ; 
ifstrncmpi (mode ,'ensemble' ,length (mode ))
err =NaN (1 ,L ); 
iuse =any (uofl (:,folds ),2 ); 
forl =1 :L 
err (l )=funloss (C (iuse ,:),score (iuse ,:,l ),w (iuse ),cost ); 
end
elseifstrncmpi (mode ,'individual' ,length (mode ))
T =numel (folds ); 
err =NaN (T ,L ); 
fork =1 :T 
t =folds (k ); 
iuse =uofl (:,t ); 
forl =1 :L 
err (k ,l )=funloss (C (iuse ,:),score (iuse ,:,l ),w (iuse ),cost ); 
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

score =this .PartitionedModel .PrivScoreTransform (this .PrivScore ); 
N =size (score ,1 ); 
L =size (score ,3 ); 
C =this .PrivC ; 

m =NaN (N ,L ); 
forl =1 :L 
m (:,l )=classreg .learning .loss .classifmargin (C ,score (:,:,l )); 
end
end
end

end
