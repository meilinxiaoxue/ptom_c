classdef ClassificationTree <...
    classreg .learning .classif .FullClassificationModel &classreg .learning .classif .CompactClassificationTree 






















































































methods (Hidden )
function this =ClassificationTree (X ,Y ,W ,modelParams ,...
    dataSummary ,classSummary ,scoreTransform )
ifnargin ~=7 ||ischar (W )
error (message ('stats:ClassificationTree:ClassificationTree:DoNotUseConstructor' )); 
end
this =this @classreg .learning .classif .FullClassificationModel (...
    X ,Y ,W ,modelParams ,dataSummary ,classSummary ,scoreTransform ); 
this =this @classreg .learning .classif .CompactClassificationTree (...
    dataSummary ,classSummary ,scoreTransform ,[]); 
this =fitTree (this ); 
end
end

methods (Static ,Hidden )
function this =fit (X ,Y ,varargin )
temp =ClassificationTree .template (varargin {:}); 
this =fit (temp ,X ,Y ); 
end

function temp =template (varargin )
classreg .learning .FitTemplate .catchType (varargin {:}); 
temp =classreg .learning .FitTemplate .make ('Tree' ,'type' ,'classification' ,varargin {:}); 
end
end

methods (Access =protected )
function this =fitTree (this )
N =size (this .PrivX ,1 ); 
this .Impl =classreg .learning .impl .TreeImpl .makeFromData (...
    this .PrivX ,...
    grp2idx (this .PrivY ,this .ClassSummary .NonzeroProbClasses ),...
    this .W ,...
    1 :N ,...
    true ,...
    this .DataSummary .CategoricalPredictors ,...
    this .ModelParams .SplitCriterion ,...
    this .ModelParams .MinLeaf ,...
    this .ModelParams .MinParent ,...
    this .ModelParams .MaxSplits ,...
    this .ModelParams .NVarToSample ,...
    this .ModelParams .NSurrogate ,...
    this .ModelParams .MaxCat ,...
    this .ModelParams .AlgCat ,...
    this .ClassSummary .Cost ,...
    0 ,...
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
s =propsForDisp @classreg .learning .classif .CompactClassificationTree (this ,s ); 
s =propsForDisp @classreg .learning .classif .FullClassificationModel (this ,s ); 
end
end

methods 
function cmp =compact (this )








dataSummary =this .DataSummary ; 
dataSummary .RowsUsed =[]; 
cmp =classreg .learning .classif .CompactClassificationTree (...
    dataSummary ,this .ClassSummary ,...
    this .PrivScoreTransform ,this .PrivScoreType ); 
cmp .Impl =this .Impl ; 
end

function this =prune (this ,varargin )














































[varargin {:}]=convertStringsToChars (varargin {:}); 
args ={'criterion' }; 
defs ={this .ModelParams .PruneCriterion }; 
[crit ,~,extraArgs ]=...
    internal .stats .parseArgs (args ,defs ,varargin {:}); 

if~ischar (crit )
error (message ('stats:ClassificationTree:prune:CritNotChar' )); 
end

allowedVals ={'error' ,'impurity' }; 
tf =strncmpi (crit ,allowedVals ,length (crit )); 
ifsum (tf )~=1 
error (message ('stats:ClassificationTree:prune:BadCrit' )); 
end

forceprune =false ; 
if~strcmpi (crit ,this .ModelParams .PruneCriterion )
forceprune =true ; 
end

iftf (2 )
ifstrcmpi (this .ModelParams .SplitCriterion ,'twoing' )
error (message ('stats:ClassificationTree:prune:ImpurityDisallowedForTwoing' )); 
end
crit =this .ModelParams .SplitCriterion ; 
end

this .Impl =prune (this .Impl ,'forceprune' ,forceprune ,...
    'cost' ,this .ClassSummary .Cost ,'criterion' ,crit ,extraArgs {:}); 
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

function [varargout ]=cvloss (this ,varargin )


























[varargin {:}]=convertStringsToChars (varargin {:}); 
[varargout {1 :nargout }]=cvLoss (this ,varargin {:}); 
end
end

methods (Hidden )


function [err ,seerr ,nleaf ,bestlevel ]=cvLoss (this ,varargin )

classreg .learning .FullClassificationRegressionModel .catchWeights (varargin {:}); 
args ={'subtrees' ,'KFold' ,'treesize' ,'lossfun' }; 
defs ={0 ,10 ,'se' ,this .DefaultLoss }; 
[subtrees ,kfold ,treesize ,funloss ]=...
    internal .stats .parseArgs (args ,defs ,varargin {:}); 


subtrees =processSubtrees (this .Impl ,subtrees ); 


if~ischar (treesize )||~(treesize (1 )=='s' ||treesize (1 )=='m' )
error (message ('stats:ClassificationTree:cvLoss1:BadTreeSize' )); 
end


funloss =classreg .learning .internal .lossCheck (funloss ,'classification' ); 


cv =crossval (this ,'KFold' ,kfold ); 


alpha =this .Impl .PruneAlpha ; 
avgalpha =[sqrt (alpha (1 :end-1 ).*alpha (2 :end)); Inf ]; 
T =numel (avgalpha ); 


nonzeroClassNames =this .ClassSummary .NonzeroProbClasses ; 
K =numel (nonzeroClassNames ); 


N =size (this .X ,1 ); 
Sfit =NaN (N ,K ,T ); 
useNforK =~cv .ModelParams .Generator .UseObsForIter ; 
fork =1 :numel (cv .Trained )
useobs =useNforK (:,k ); 
tree =cv .Trained {k }; 
prunelev =findsubtree (tree .Impl ,avgalpha ); 
[~,sfit ]=predict (tree ,this .PrivX (useobs ,:),'subtrees' ,prunelev ); 
[~,pos ]=ismember (nonzeroClassNames ,tree .ClassSummary .ClassNames ); 
Sfit (useobs ,:,:)=sfit (:,pos ,:); 
end


C =membership (this .PrivY ,nonzeroClassNames ); 


[~,pos ]=ismember (nonzeroClassNames ,this .ClassSummary .ClassNames ); 
cost =this .Cost (pos ,pos ); 


[err ,seerr ]=...
    classreg .learning .classif .CompactClassificationTree .stratifiedLossWithSE (...
    C ,Sfit ,this .W ,cost ,funloss ); 


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
function [X ,Y ,W ,userClassNames ,nonzeroClassNames ,rowsused ]=...
    processClassNames (X ,Y ,W ,userClassNames ,allClassNames ,rowsused ,obsInRows )
nonzeroClassNames =levels (Y ); 


bad =strcmp (labels (nonzeroClassNames ),'NaN' )|strcmp (labels (nonzeroClassNames ),'<undefined>' ); 
ifany (bad )
nonzeroClassNames (bad )=[]; 
end
ifisempty (userClassNames )
userClassNames =allClassNames ; 
else
userClassNames =classreg .learning .internal .ClassLabel (userClassNames ); 


missingC =~ismember (userClassNames ,nonzeroClassNames ); 
ifall (missingC )
error (message ('stats:classreg:learning:classif:FullClassificationModel:prepareData:ClassNamesNotFound' )); 
end


missingC =~ismember (nonzeroClassNames ,userClassNames ); 
ifany (missingC )
unmatchedY =ismember (Y ,nonzeroClassNames (missingC )); 
Y (unmatchedY )=[]; 
ifnargin <7 ||obsInRows 
X (unmatchedY ,:)=[]; 
else
X (:,unmatchedY )=[]; 
end
W (unmatchedY )=[]; 
nonzeroClassNames (missingC )=[]; 
ifisempty (rowsused )
rowsused =~unmatchedY ; 
else
rowsused (rowsused )=~unmatchedY ; 
end
end
end
end

function [X ,Y ,C ,WC ,Wj ,prior ,cost ,nonzeroClassNames ,rowsused ]=...
    removeZeroPriorAndCost (X ,Y ,C ,WC ,Wj ,...
    prior ,cost ,nonzeroClassNames ,rowsused ,obsInRows )
prior (Wj ==0 )=0 ; 
zeroprior =prior ==0 ; 
ifall (zeroprior )
error (message ('stats:ClassificationTree:removeZeroPriorAndCost:ZeroPrior' )); 
end
zerocost =false (1 ,numel (prior )); 
ifnumel (cost )>1 
zerocost =all (cost ==0 ,2 )' ; 
end

toremove =zeroprior |zerocost ; 
ifall (toremove )
error (message ('stats:ClassificationTree:removeZeroPriorAndCost:ZeroPriorOrZeroCost' )); 
end

ifany (toremove )
removedClasses =cellstr (nonzeroClassNames (toremove )); 
ignore =ismember (removedClasses ,{'NaN' ,'<undefined>' }); 
removedClasses (ignore )=[]; 
if~isempty (removedClasses )
warning (message ('stats:classreg:learning:classif:FullClassificationModel:removeZeroPriorAndCost:RemovingClasses' ,...
    sprintf (' ''%s''' ,removedClasses {:}))); 
end

t =any (C (:,toremove ),2 ); 
Y (t )=[]; 
ifnargin <10 ||obsInRows 
X (t ,:)=[]; 
else
X (:,t )=[]; 
end
C (t ,:)=[]; 
WC (t ,:)=[]; 
WC (:,toremove )=[]; 
Wj (toremove )=[]; 
nonzeroClassNames (toremove )=[]; 
prior (toremove )=[]; 
cost (toremove ,:)=[]; 
cost (:,toremove )=[]; 
ifisempty (rowsused )
rowsused =~t ; 
else
rowsused (rowsused )=~t ; 
end
end
end

function [X ,Y ,W ,rowsused ]=removeMissingVals (X ,Y ,W ,rowsused ,obsInRows )
t =ismissing (Y )|strcmp (labels (Y ),'NaN' )|strcmp (labels (Y ),'<undefined>' ); 


ifany (t )
Y (t )=[]; 
ifnargin <5 ||obsInRows 
X (t ,:)=[]; 
else
X (:,t )=[]; 
end
W (t )=[]; 
ifisempty (rowsused )
rowsused =~t ; 
else
rowsused (rowsused )=~t ; 
end
end
ifisempty (X )
error (message ('stats:classreg:learning:classif:FullClassificationModel:removeMissingVals:NoGoodYData' )); 
end
end

function [X ,Y ,W ,dataSummary ,classSummary ,scoreTransform ]=...
    prepareData (X ,Y ,varargin )
[X ,Y ,vrange ,wastable ,varargin ]=classreg .learning .internal .table2FitMatrix (X ,Y ,varargin {:},'OrdinalIsCategorical' ,false ); 


args ={'classnames' ,'cost' ,'prior' ,'scoretransform' ,'responsestring' }; 
defs ={[],[],[],[],false }; 
[userClassNames ,cost ,prior ,transformer ,responsestring ,~,crArgs ]=...
    internal .stats .parseArgs (args ,defs ,varargin {:}); 

ifresponsestring 

ifisnumeric (Y )||islogical (Y )
Y =cellstr (num2str (Y (:))); 
elseifiscategorical (Y )||ischar (Y )
Y =cellstr (Y ); 
end
end




allClassNames =levels (classreg .learning .internal .ClassLabel (Y )); 
bad =strcmp (labels (allClassNames ),'NaN' )|strcmp (labels (allClassNames ),'<undefined>' ); 
ifany (bad )
allClassNames (bad )=[]; 
end
ifisempty (allClassNames )
error (message ('stats:ClassificationTree:prepareData:EmptyClassNames' )); 
end


Y =classreg .learning .internal .ClassLabel (Y ); 
[X ,Y ,W ,dataSummary ]=...
    classreg .learning .FullClassificationRegressionModel .prepareDataCR (...
    X ,Y ,crArgs {:},'VariableRange' ,vrange ,'TableInput' ,wastable ); 
if~isfloat (X )
error (message ('stats:ClassificationTree:prepareData:BadXType' )); 
end
internal .stats .checkSupportedNumeric ('X' ,X ,true ); 

internal .stats .checkSupportedNumeric ('Weights' ,W ,true ); 


if~dataSummary .ObservationsInRows 
error (message ('stats:classreg:learning:FullClassificationRegressionModel:prepareDataCR:ObsInColsNotAllowed' ,'Tree' )); 
end


[X ,Y ,W ,userClassNames ,nonzeroClassNames ,dataSummary .RowsUsed ]=...
    ClassificationTree .processClassNames (...
    X ,Y ,W ,userClassNames ,allClassNames ,dataSummary .RowsUsed ); 


[X ,Y ,W ,dataSummary .RowsUsed ]=ClassificationTree .removeMissingVals (...
    X ,Y ,W ,dataSummary .RowsUsed ); 


C =classreg .learning .internal .classCount (nonzeroClassNames ,Y ); 
WC =bsxfun (@times ,C ,W ); 
Wj =sum (WC ,1 ); 


prior =classreg .learning .classif .FullClassificationModel .processPrior (...
    prior ,Wj ,userClassNames ,nonzeroClassNames ); 


cost =classreg .learning .classif .FullClassificationModel .processCost (...
    cost ,prior ,userClassNames ,nonzeroClassNames ); 


[X ,Y ,~,WC ,Wj ,prior ,cost ,nonzeroClassNames ,dataSummary .RowsUsed ]=...
    ClassificationTree .removeZeroPriorAndCost (...
    X ,Y ,C ,WC ,Wj ,prior ,cost ,nonzeroClassNames ,dataSummary .RowsUsed ); 




prior =prior /sum (prior ); 
W =sum (bsxfun (@times ,WC ,prior ./Wj ),2 ); 


classSummary =classreg .learning .classif .FullClassificationModel .makeClassSummary (...
    userClassNames ,nonzeroClassNames ,prior ,cost ); 


scoreTransform =...
    classreg .learning .classif .FullClassificationModel .processScoreTransform (transformer ); 
end

function this =loadobj (obj )
ifisa (obj .Impl ,'classreg.learning.impl.CompactTreeImpl' )

modelParams =fillDefaultParams (obj .ModelParams ,...
    obj .X ,obj .PrivY ,obj .W ,obj .DataSummary ,obj .ClassSummary ); 
this =ClassificationTree (obj .X ,obj .PrivY ,obj .W ,...
    modelParams ,obj .DataSummary ,obj .ClassSummary ,...
    obj .PrivScoreTransform ); 
else

this =obj ; 
end
end
end
end
