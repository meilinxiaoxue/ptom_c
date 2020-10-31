classdef ClassificationPartitionedECOC <...
    classreg .learning .partition .PartitionedECOC ...
    &classreg .learning .partition .ClassificationPartitionedModel 



















































properties (GetAccess =public ,SetAccess =protected ,Dependent =true )















BinaryY ; 
end

methods (Hidden )
function this =ClassificationPartitionedECOC (X ,Y ,W ,modelParams ,...
    dataSummary ,classSummary ,scoreTransform )
this =this @classreg .learning .partition .PartitionedECOC ; 
this =this @classreg .learning .partition .ClassificationPartitionedModel (...
    X ,Y ,W ,modelParams ,dataSummary ,classSummary ,scoreTransform ); 
this .DefaultLoss =@classreg .learning .loss .classiferror ; 
this .LabelPredictor =@classreg .learning .classif .ClassificationModel .maxScore ; 
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
isneg =ismember (this .Ensemble .PrivY ,...
    this .Ensemble .ClassSummary .ClassNames (neg )); 
ispos =ismember (this .Ensemble .PrivY ,...
    this .Ensemble .ClassSummary .ClassNames (pos )); 
bY (isneg ,l )=-1 ; 
bY (ispos ,l )=1 ; 
end
end

function [labels ,negloss ,pscore ,posterior ]=kfoldPredict (this ,varargin )






















































































classreg .learning .ensemble .Ensemble .catchUOFL (varargin {:}); 




classreg .learning .FullClassificationRegressionModel .catchWeights (varargin {:}); 
[~,folds ,args ]=checkFoldArgs (this ,varargin {:}); 

PrivX =this .Ensemble .PrivX ; 
N =size (PrivX ,1 ); 
K =numel (this .Ensemble .ClassSummary .ClassNames ); 
negloss =NaN (N ,K ); 

pscore =[]; 
ifnargout >2 
M =this .CodingMatrix ; 
ifisempty (M )
warning (message ('stats:classreg:learning:partition:ClassificationPartitionedECOC:kfoldPredict:CodingMatrixSizeVaries' )); 
else
L =size (M ,2 ); 
pscore =NaN (N ,L ); 
end
end

posterior =[]; 
ifnargout >3 
posterior =NaN (N ,K ); 
end

learners =this .Ensemble .Trained ; 
uofl =~this .Ensemble .ModelParams .Generator .UseObsForIter ; 

fork =1 :numel (folds )
t =folds (k ); 
if~isempty (learners {t })
iuse =uofl (:,t ); 
ifnargout <3 ||(nargout <4 &&isempty (pscore ))
[~,negloss (iuse ,:)]=...
    predict (learners {t },PrivX (iuse ,:),args {:}); 
elseifnargout <4 
[~,negloss (iuse ,:),pscore (iuse ,:)]=...
    predict (learners {t },PrivX (iuse ,:),args {:}); %#ok<AGROW> 
else
ifisempty (pscore )
[~,negloss (iuse ,:),~,posterior (iuse ,:)]=...
    predict (learners {t },PrivX (iuse ,:),args {:}); %#ok<AGROW> 
else
[~,negloss (iuse ,:),pscore (iuse ,:),posterior (iuse ,:)]=...
    predict (learners {t },PrivX (iuse ,:),args {:}); %#ok<AGROW> 
end
end
end
end

labels =this .LabelPredictor (this .ClassNames ,...
    this .Prior ,this .Cost ,negloss ,@(x )x ); 
end

function l =kfoldLoss (this ,varargin )













































































classreg .learning .ensemble .Ensemble .catchUOFL (varargin {:}); 
classreg .learning .FullClassificationRegressionModel .catchWeights (varargin {:}); 
[mode ,folds ,extraArgs ]=checkFoldArgs (this ,varargin {:}); 


args ={'lossfun' }; 
defs ={this .DefaultLoss }; 
[funloss ,~,extraArgs ]=...
    internal .stats .parseArgs (args ,defs ,extraArgs {:}); 


funloss =classreg .learning .internal .lossCheck (funloss ,'classification' ); 


[~,negloss ]=kfoldPredict (this ,'folds' ,folds ,extraArgs {:}); 


C =classreg .learning .internal .classCount (...
    this .Ensemble .ClassSummary .ClassNames ,this .Ensemble .PrivY ); 


W =this .W ; 
ifstrncmpi (mode ,'ensemble' ,length (mode ))
l =funloss (C ,negloss ,W ,this .Cost ); 
elseifstrncmpi (mode ,'individual' ,length (mode ))
uofl =~this .Ensemble .ModelParams .Generator .UseObsForIter ; 
T =numel (folds ); 
l =NaN (T ,1 ); 
fork =1 :T 
t =folds (k ); 
iuse =uofl (:,t ); 
l (k )=funloss (C (iuse ,:),negloss (iuse ,:),W (iuse ),this .Cost ); 
end
else
error (message ('stats:classreg:learning:partition:PartitionedModel:checkFoldArgs:BadMode' )); 
end
end

function m =kfoldMargin (this ,varargin )












































classreg .learning .ensemble .Ensemble .catchUOFL (varargin {:}); 
classreg .learning .partition .PartitionedModel .catchFolds (varargin {:}); 
classreg .learning .FullClassificationRegressionModel .catchWeights (varargin {:}); 

[~,negloss ]=kfoldPredict (this ,varargin {:}); 

C =classreg .learning .internal .classCount (...
    this .Ensemble .ClassSummary .ClassNames ,this .Ensemble .PrivY ); 
m =classreg .learning .loss .classifmargin (C ,negloss ); 
end

function e =kfoldEdge (this ,varargin )



















































e =kfoldEdge @classreg .learning .partition .ClassificationPartitionedModel (this ,varargin {:}); 
end
end

end
