classdef ClassificationPartitionedModel <classreg .learning .partition .PartitionedModel 


















































properties (GetAccess =public ,SetAccess =protected ,Dependent =true )





ClassNames ; 
end

properties (GetAccess =public ,SetAccess =public ,Dependent =true )






Cost ; 





Prior ; 











ScoreTransform ; 
end

properties (GetAccess =public ,SetAccess =public ,Dependent =true ,Hidden =true )

ScoreType ; 
end

properties (GetAccess =public ,SetAccess =protected ,Dependent =true ,Hidden =true )

ContinuousLoss ; 
end

properties (GetAccess =public ,SetAccess =public ,Hidden =true )
DefaultLoss =@classreg .learning .loss .classiferror ; 
LabelPredictor =@classreg .learning .classif .ClassificationModel .maxScore ; 
end

properties (GetAccess =public ,SetAccess =protected ,Hidden =true )
PrivScoreTransform =[]; 
PrivScoreType =[]; 
end

methods 
function cnames =get .ClassNames (this )
cnames =this .Ensemble .ClassNames ; 
end

function cost =get .Cost (this )
cost =this .Ensemble .Cost ; 
end

function this =set .Cost (this ,cost )
this .Ensemble =setLearnersCost (this .Ensemble ,cost ); 
end

function prior =get .Prior (this )
prior =this .Ensemble .Prior ; 
end

function this =set .Prior (this ,prior )
this .Ensemble =setLearnersPrior (this .Ensemble ,prior ); 
end

function st =get .ScoreTransform (this )
st =classreg .learning .internal .convertScoreTransform (...
    this .PrivScoreTransform ,'string' ,[]); 
end

function this =set .ScoreTransform (this ,st )
this .PrivScoreTransform =...
    classreg .learning .internal .convertScoreTransform (st ,...
    'handle' ,numel (this .Ensemble .ClassSummary .ClassNames )); 
this .PrivScoreType =[]; 
end

function st =get .ScoreType (this )
st =getScoreType (this ); 
end

function this =set .ScoreType (this ,st )
this .PrivScoreType =classreg .learning .internal .convertScoreType (st ); 
end

function cl =get .ContinuousLoss (this )
cl =getContinuousLoss (this ); 
end
end

methods (Hidden )
function this =ClassificationPartitionedModel (X ,Y ,W ,modelParams ,...
    dataSummary ,classSummary ,scoreTransform )
this =this @classreg .learning .partition .PartitionedModel (); 
this .Ensemble =classreg .learning .classif .ClassificationEnsemble (...
    X ,Y ,W ,modelParams ,dataSummary ,classSummary ,scoreTransform ,false ); 
this .PrivScoreTransform =this .Ensemble .PrivScoreTransform ; 
ifthis .Ensemble .NTrained >0 
this .DefaultLoss =this .Ensemble .Trained {1 }.DefaultLoss ; 
this .LabelPredictor =this .Ensemble .Trained {1 }.LabelPredictor ; 
end
end
end

methods (Access =protected )
function st =getScoreType (this )
ifthis .Ensemble .NTrained >0 ...
    &&isequal (this .PrivScoreTransform ,@classreg .learning .transform .identity )
st =this .Ensemble .Trained {1 }.ScoreType ; 
elseif~isempty (this .PrivScoreType )
st =this .PrivScoreType ; 
else
st ='unknown' ; 
end
end

function cl =getContinuousLoss (this )
cl =[]; 
ifthis .Ensemble .NTrained >0 
ifisequal (this .PrivScoreTransform ,@classreg .learning .transform .identity )
cl =this .Ensemble .Trained {1 }.ContinuousLoss ; 
elseifstrcmp (this .ScoreType ,'probability' )
cl =@classreg .learning .loss .quadratic ; 
end
end
end

function s =propsForDisp (this ,s )
s =propsForDisp @classreg .learning .partition .PartitionedModel (this ,s ); 
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
function [varargout ]=kfoldPredict (this ,varargin )

















[~,score ]=kfoldPredict @classreg .learning .partition .PartitionedModel (this ,varargin {:}); 
[varargout {1 :nargout }]=this .LabelPredictor (this .ClassNames ,...
    this .Prior ,this .Cost ,score ,this .PrivScoreTransform ); 
end

function m =kfoldMargin (this ,varargin )









classreg .learning .ensemble .Ensemble .catchUOFL (varargin {:}); 
classreg .learning .partition .PartitionedModel .catchFolds (varargin {:}); 
classreg .learning .FullClassificationRegressionModel .catchWeights (varargin {:}); 
[mode ,~,args ]=checkFoldArgs (this ,varargin {:}); 
usenfort =~this .Ensemble .ModelParams .Generator .UseObsForIter ; 
m =margin (this .Ensemble ,this .Ensemble .X ,this .Ensemble .PrivY ,...
    'useobsforlearner' ,usenfort ,'mode' ,mode ,args {:}); 
end

function e =kfoldEdge (this ,varargin )

















e =kfoldLoss (this ,'lossfun' ,@classreg .learning .loss .classifedge ,varargin {:}); 
end

function l =kfoldLoss (this ,varargin )







































classreg .learning .ensemble .Ensemble .catchUOFL (varargin {:}); 
classreg .learning .FullClassificationRegressionModel .catchWeights (varargin {:}); 
[mode ,folds ,extraArgs ]=checkFoldArgs (this ,varargin {:}); 

usenfort =~this .Ensemble .ModelParams .Generator .UseObsForIter ; 

X =this .Ensemble .X ; 
Y =this .Ensemble .PrivY ; 
W =this .Ensemble .W ; 

args ={'lossfun' }; 
defs ={this .DefaultLoss }; 
[funloss ,~,extraArgs ]=...
    internal .stats .parseArgs (args ,defs ,extraArgs {:}); 

[X ,C ,W ,~,usenfort ]=prepareDataForLoss (this .Ensemble ,X ,Y ,W ,usenfort ,true ,true ); 
l =classreg .learning .ensemble .CompactEnsemble .aggregateLoss (...
    this .Ensemble .NTrained ,X ,C ,W ,this .Ensemble .Cost ,funloss ,...
    this .Ensemble .Impl .Combiner ,@classreg .learning .ensemble .CompactEnsemble .predictOneWithCache ,...
    this .Ensemble .Impl .Trained ,this .Ensemble .ClassSummary .ClassNames ,this .Ensemble .ClassSummary .NonzeroProbClasses ,...
    this .PrivScoreTransform ,this .Ensemble .DefaultScore ,...
    'useobsforlearner' ,usenfort ,'mode' ,mode ,'learners' ,folds ,extraArgs {:}); 
end
end

methods (Static ,Hidden )
function this =loadobj (obj )
ifisempty (obj .PrivScoreTransform )
this =classreg .learning .partition .ClassificationPartitionedModel (...
    obj .Ensemble .X ,obj .Ensemble .PrivY ,obj .Ensemble .W ,...
    obj .Ensemble .ModelParams ,...
    obj .Ensemble .DataSummary ,obj .Ensemble .ClassSummary ,...
    obj .Ensemble .PrivScoreTransform ); 
else

this =obj ; 
end
end
end

end
