classdef RegressionTree <...
    classreg .learning .regr .FullRegressionModel &classreg .learning .regr .CompactRegressionTree 










































































methods (Hidden )
function this =RegressionTree (X ,Y ,W ,modelParams ,dataSummary ,responseTransform )
ifnargin ~=6 ||ischar (W )
error (message ('stats:RegressionTree:RegressionTree:DoNotUseConstructor' )); 
end
internal .stats .checkSupportedNumeric ('X' ,X ,true ); 
internal .stats .checkSupportedNumeric ('Weights' ,W ,true ); 
if~dataSummary .ObservationsInRows 
error (message ('stats:classreg:learning:FullClassificationRegressionModel:prepareDataCR:ObsInColsNotAllowed' ,'Tree' )); 
end
this =this @classreg .learning .regr .FullRegressionModel (...
    X ,Y ,W ,modelParams ,dataSummary ,responseTransform ); 
this =this @classreg .learning .regr .CompactRegressionTree (...
    dataSummary ,responseTransform ); 
this =fitTree (this ); 
end
end

methods (Static ,Hidden )
function this =fit (X ,Y ,varargin )
temp =RegressionTree .template (varargin {:}); 
this =fit (temp ,X ,Y ); 
end

function temp =template (varargin )
classreg .learning .FitTemplate .catchType (varargin {:}); 
temp =classreg .learning .FitTemplate .make ('Tree' ,'type' ,'regression' ,varargin {:}); 
end

function [varargout ]=prepareData (varargin )
[varargout {1 :nargout }]=prepareData @classreg .learning .regr .FullRegressionModel (varargin {:},'OrdinalIsCategorical' ,false ); 
end
end

methods (Access =protected )
function this =fitTree (this )
N =size (this .X ,1 ); 
this .Impl =classreg .learning .impl .TreeImpl .makeFromData (...
    this .PrivX ,...
    this .Y ,...
    this .W ,...
    1 :N ,...
    false ,...
    this .DataSummary .CategoricalPredictors ,...
    this .ModelParams .SplitCriterion ,...
    this .ModelParams .MinLeaf ,...
    this .ModelParams .MinParent ,...
    this .ModelParams .MaxSplits ,...
    this .ModelParams .NVarToSample ,...
    this .ModelParams .NSurrogate ,...
    0 ,...
    '' ,...
    [],...
    this .ModelParams .QEToler ,...
    this .ModelParams .PredictorSelection ,...
    this .ModelParams .UseChisqTest ,...
    this .ModelParams .Stream ); 
ifstrcmp (this .ModelParams .MergeLeaves ,'on' )
this =prune (this ,'level' ,0 ); 
elseifstrcmp (this .ModelParams .Prune ,'on' )
this =prune (this ); 
end
end

function s =propsForDisp (this ,s )
s =propsForDisp @classreg .learning .regr .CompactRegressionTree (this ,s ); 
s =propsForDisp @classreg .learning .regr .FullRegressionModel (this ,s ); 
end
end

methods 
function cmp =compact (this ,varargin )








dataSummary =this .DataSummary ; 
dataSummary .RowsUsed =[]; 
cmp =classreg .learning .regr .CompactRegressionTree (...
    dataSummary ,this .PrivResponseTransform ); 
cmp .Impl =this .Impl ; 
end

function this =prune (this ,varargin )






































[varargin {:}]=convertStringsToChars (varargin {:}); 
this .Impl =prune (this .Impl ,varargin {:}); 
end

function [varargout ]=resubPredict (this ,varargin )




















[varargout {1 :nargout }]=...
    resubPredict @classreg .learning .regr .FullRegressionModel (this ,varargin {:}); 
end

function [varargout ]=resubLoss (this ,varargin )

































[varargout {1 :nargout }]=...
    resubLoss @classreg .learning .regr .FullRegressionModel (this ,varargin {:}); 
end

function [varargout ]=cvloss (this ,varargin )


























[varargout {1 :nargout }]=cvLoss (this ,varargin {:}); 
end
end

methods (Hidden )


function [err ,seerr ,nleaf ,bestlevel ]=cvLoss (this ,varargin )
[varargin {:}]=convertStringsToChars (varargin {:}); 

classreg .learning .FullClassificationRegressionModel .catchWeights (varargin {:}); 
args ={'subtrees' ,'KFold' ,'treesize' ,'lossfun' }; 
defs ={0 ,10 ,'se' ,@classreg .learning .loss .mse }; 
[subtrees ,kfold ,treesize ,funloss ]=...
    internal .stats .parseArgs (args ,defs ,varargin {:}); 


subtrees =processSubtrees (this .Impl ,subtrees ); 


if~ischar (treesize )||~(treesize (1 )=='s' ||treesize (1 )=='m' )
error (message ('stats:RegressionTree:cvLoss1:BadTreeSize' )); 
end


funloss =classreg .learning .internal .lossCheck (funloss ,'regression' ); 


cv =crossval (this ,'KFold' ,kfold ); 


alpha =this .Impl .PruneAlpha ; 
avgalpha =[sqrt (alpha (1 :end-1 ).*alpha (2 :end)); Inf ]; 
T =numel (avgalpha ); 


N =size (this .X ,1 ); 
Yfit =NaN (N ,T ); 
useNforK =~cv .ModelParams .Generator .UseObsForIter ; 
fork =1 :numel (cv .Trained )
useobs =useNforK (:,k ); 
tree =cv .Trained {k }; 
prunelev =findsubtree (tree .Impl ,avgalpha ); 
Yfit (useobs ,:)=predict (tree ,this .PrivX (useobs ,:),'subtrees' ,prunelev ); 
end


[err ,seerr ]=...
    classreg .learning .regr .CompactRegressionTree .lossWithSE (...
    this .Y ,Yfit ,this .W ,funloss ); 


nleaf =countLeaves (this .Impl ,'all' ); 


if~ischar (subtrees )
err =err (1 +subtrees ); 
seerr =seerr (1 +subtrees ); 
nleaf =nleaf (1 +subtrees ); 
end


ifnargout >3 
[minerr ,minloc ]=min (err ); 
ifisequal (treesize (1 ),'m' )
cutoff =minerr *(1 +100 *eps ); 
else
cutoff =minerr +seerr (minloc ); 
end
bestlevel =subtrees (find (err <=cutoff ,1 ,'last' )); 
end
end
end

methods (Static ,Hidden )
function this =loadobj (obj )
ifisa (obj .Impl ,'classreg.learning.impl.CompactTreeImpl' )

modelParams =fillDefaultParams (obj .ModelParams ,...
    obj .X ,obj .PrivY ,obj .W ,obj .DataSummary ,[]); 
this =RegressionTree (obj .X ,obj .PrivY ,obj .W ,...
    modelParams ,obj .DataSummary ,obj .PrivResponseTransform ); 
else

this =obj ; 
end
end
end
end
