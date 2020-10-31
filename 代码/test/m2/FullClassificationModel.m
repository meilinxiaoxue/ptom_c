classdef FullClassificationModel <...
    classreg .learning .FullClassificationRegressionModel &classreg .learning .classif .ClassificationModel 









properties (GetAccess =public ,SetAccess =protected ,Dependent =true )






Y ; 
end

methods 
function y =get .Y (this )
y =labels (this .PrivY ); 
end
end

methods (Access =protected )
function this =FullClassificationModel (X ,Y ,W ,modelParams ,...
    dataSummary ,classSummary ,scoreTransform )
this =this @classreg .learning .FullClassificationRegressionModel (...
    dataSummary ,X ,Y ,W ,modelParams ); 
this =this @classreg .learning .classif .ClassificationModel (...
    dataSummary ,classSummary ,scoreTransform ,[]); 
this .ModelParams =fillIfNeeded (modelParams ,X ,Y ,W ,dataSummary ,classSummary ); 
end

function s =propsForDisp (this ,s )
s =propsForDisp @classreg .learning .classif .ClassificationModel (this ,s ); 
s =propsForDisp @classreg .learning .FullClassificationRegressionModel (this ,s ); 
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
temp =classreg .learning .FitTemplate .make (this .ModelParams .Method ,...
    'type' ,'classification' ,'scoretransform' ,this .PrivScoreTransform ,...
    'modelparams' ,this .ModelParams ,'CrossVal' ,'on' ,varargin {:}); 
partModel =fit (temp ,this .X ,this .Y ,'Weights' ,this .W ,...
    'predictornames' ,this .DataSummary .PredictorNames ,...
    'categoricalpredictors' ,this .CategoricalPredictors ,...
    'responsename' ,this .ResponseName ,...
    'classnames' ,this .ClassNames ,'cost' ,this .Cost ,'prior' ,this .Prior ); 
partModel .ScoreType =this .ScoreType ; 
end

function [varargout ]=resubPredict (this ,varargin )












classreg .learning .FullClassificationRegressionModel .catchWeights (varargin {:}); 
[varargout {1 :nargout }]=predict (this ,this .X ,varargin {:}); 
end

function [varargout ]=resubLoss (this ,varargin )

























[varargin {:}]=convertStringsToChars (varargin {:}); 
classreg .learning .FullClassificationRegressionModel .catchWeights (varargin {:}); 
[varargout {1 :nargout }]=...
    loss (this ,this .X ,this .Y ,'Weights' ,this .W ,varargin {:}); 
end

function m =resubMargin (this ,varargin )









classreg .learning .FullClassificationRegressionModel .catchWeights (varargin {:}); 
m =margin (this ,this .X ,this .Y ,varargin {:}); 
end

function e =resubEdge (this ,varargin )








classreg .learning .FullClassificationRegressionModel .catchWeights (varargin {:}); 
e =edge (this ,this .X ,this .Y ,'Weights' ,this .W ,varargin {:}); 
end
end

methods (Static ,Hidden )
function [X ,Y ,W ,userClassNames ,nonzeroClassNames ,rowsused ]=...
    processClassNames (X ,Y ,W ,userClassNames ,allClassNames ,rowsused ,obsInRows )
nonzeroClassNames =levels (Y ); 
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

function [X ,Y ,W ,rowsused ]=removeMissingVals (X ,Y ,W ,rowsused ,obsInRows )
t =ismissing (Y ); 
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

function prior =processPrior (prior ,Wj ,userClassNames ,nonzeroClassNames )






K =length (nonzeroClassNames ); 
Kuser =length (userClassNames ); 
prior =prior (:)' ; 
if~isempty (prior )&&~isstruct (prior )&&~isnumeric (prior )...
    &&~any (strncmpi (prior ,{'empirical' ,'uniform' },length (prior )))
error (message ('stats:classreg:learning:classif:FullClassificationModel:processPrior:BadPrior' )); 
end
ifisempty (prior )||strncmpi (prior ,'empirical' ,length (prior ))
prior =Wj ; 
elseifstrncmpi (prior ,'uniform' ,length (prior ))
prior =ones (1 ,K ); 
elseifisstruct (prior )
if~isfield (prior ,'ClassNames' )||~isfield (prior ,'ClassProbs' )
error (message ('stats:classreg:learning:classif:FullClassificationModel:processPrior:PriorWithMissingField' )); 
end
classprobs =prior .ClassProbs ; 
if~isfloat (classprobs )||any (classprobs <0 )||all (classprobs ==0 )
error (message ('stats:classreg:learning:classif:FullClassificationModel:processPrior:BadNumericPriorFromStruct' )); 
end
ifany (isnan (classprobs ))||any (isinf (classprobs ))
error (message ('stats:classreg:learning:classif:FullClassificationModel:processPrior:NaNInfPriorFromStruct' )); 
end
[tf ,pos ]=ismember (nonzeroClassNames ,...
    classreg .learning .internal .ClassLabel (prior .ClassNames )); 
ifany (~tf )
error (message ('stats:classreg:learning:classif:FullClassificationModel:processPrior:PriorForClassNotFound' ,find (~tf ,1 ))); 
end
prior =prior .ClassProbs (pos ); 
else
if~isfloat (prior )||any (prior <0 )||all (prior ==0 )
error (message ('stats:classreg:learning:classif:FullClassificationModel:processPrior:BadNumericPrior' )); 
end
ifany (isnan (prior ))||any (isinf (prior ))
error (message ('stats:classreg:learning:classif:FullClassificationModel:processPrior:NaNInfPrior' )); 
end
iflength (prior )~=Kuser 
error (message ('stats:classreg:learning:classif:FullClassificationModel:processPrior:BadPriorLength' ,Kuser )); 
end
[~,loc ]=ismember (nonzeroClassNames ,userClassNames ); 
prior =prior (loc ); 
end
internal .stats .checkSupportedNumeric ('Prior' ,prior )
prior =prior (:)' /sum (prior (:)); 
end

function cost =processCost (cost ,prior ,userClassNames ,nonzeroClassNames )








K =length (nonzeroClassNames ); 
Kuser =length (userClassNames ); 
if~isempty (cost )&&~isnumeric (cost )&&~isstruct (cost )
error (message ('stats:classreg:learning:classif:FullClassificationModel:processCost:BadCost' )); 
end
ifisempty (cost )
cost =ones (K )-eye (K ); 
elseifisstruct (cost )
if~isfield (cost ,'ClassNames' )||~isfield (cost ,'ClassificationCosts' )
error (message ('stats:classreg:learning:classif:FullClassificationModel:processCost:CostWithMissingField' )); 
end
classcost =cost .ClassificationCosts ; 
ifany (diag (classcost )~=0 )
error (message ('stats:classreg:learning:classif:FullClassificationModel:processCost:NonZeroDiagCostFromStruct' )); 
elseifany (classcost (:)<0 )
error (message ('stats:classreg:learning:classif:FullClassificationModel:processCost:NegativeCostFromStruct' )); 
end
userClassNames =classreg .learning .internal .ClassLabel (cost .ClassNames ); 
tf =ismember (nonzeroClassNames ,userClassNames ); 
ifany (~tf )
error (message ('stats:classreg:learning:classif:FullClassificationModel:processCost:CostForClassNotFound' ,find (~tf ,1 ))); 
end


tf =ismember (userClassNames ,nonzeroClassNames ); 
classcost (:,~tf )=[]; 
userClassNames (~tf )=[]; 
classreg .learning .classif .FullClassificationModel .checkNanCostForGoodPrior (...
    prior ,classcost ,userClassNames ); 
classcost (~tf ,:)=[]; 
[~,pos ]=ismember (nonzeroClassNames ,userClassNames ); 
cost =classcost (pos ,pos ); 
else
if~isequal (size (cost ),Kuser *ones (1 ,2 ))
error (message ('stats:classreg:learning:classif:FullClassificationModel:processCost:BadCostSize' ,Kuser ,Kuser )); 
elseifany (diag (cost )~=0 )
error (message ('stats:classreg:learning:classif:FullClassificationModel:processCost:NonZeroDiagCost' )); 
elseifany (cost (:)<0 )
error (message ('stats:classreg:learning:classif:FullClassificationModel:processCost:NegativeCost' )); 
end







tf =ismember (userClassNames ,nonzeroClassNames ); 
cost (:,~tf )=[]; 
userClassNames (~tf )=[]; 
classreg .learning .classif .FullClassificationModel .checkNanCostForGoodPrior (...
    prior ,cost ,userClassNames ); 
cost (~tf ,:)=[]; 



[~,pos ]=ismember (nonzeroClassNames ,userClassNames ); 
cost =cost (pos ,pos ); 
end
internal .stats .checkSupportedNumeric ('ClassificationCosts' ,cost )
end


















...
    ...
    ...
    ...
    ...
    ...
    ...
    ...
    ...
    ...
    ...
    ...
    ...
    
function checkNanCostForGoodPrior (prior ,cost ,classnames )
hasprior =prior >0 ; 
badcost =any (isinf (cost (:,hasprior )))|any (isnan (cost (:,hasprior ))); 
ifany (badcost )
k =find (badcost ,1 ); 
classname =cellstr (classnames (k )); 
error (message ('stats:classreg:learning:classif:FullClassificationModel:checkNanCostForGoodPrior:BadCostInColumnForGoodClass' ,...
    classname {1 })); 
end
end

function [X ,Y ,C ,WC ,Wj ,prior ,cost ,nonzeroClassNames ,rowsused ]=...
    removeZeroPriorAndCost (X ,Y ,C ,WC ,Wj ,prior ,cost ,nonzeroClassNames ,...
    rowsused ,obsInRows )
K =numel (prior ); 
prior (Wj ==0 )=0 ; 
zeroprior =prior ==0 ; 
ifall (zeroprior )
error (message ('stats:classreg:learning:classif:FullClassificationModel:removeZeroPriorAndCost:ZeroPrior' )); 
end
zerocost =false (1 ,numel (prior )); 
ifisempty (cost )
cost =ones (K )-eye (K ); 
end
ifnumel (cost )>1 
zerocost =all (cost ==0 ,2 )' &all (cost ==0 ,1 ); 
end

toremove =zeroprior |zerocost ; 
ifall (toremove )
error (message ('stats:classreg:learning:classif:FullClassificationModel:removeZeroPriorAndCost:ZeroPriorOrZeroCost' )); 
end

ifany (toremove )
removedClasses =cellstr (nonzeroClassNames (toremove )); 
warning (message ('stats:classreg:learning:classif:FullClassificationModel:removeZeroPriorAndCost:RemovingClasses' ,...
    sprintf (' ''%s''' ,removedClasses {:}))); 

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

function classSummary =...
    makeClassSummary (userClassNames ,nonzeroClassNames ,prior ,cost )
classSummary .ClassNames =userClassNames ; 
classSummary .NonzeroProbClasses =nonzeroClassNames ; 
classSummary .Prior =prior ; 

K =numel (prior ); 
stcost =ones (K )-eye (K ); 
ifisequal (cost ,stcost )&&...
    all (ismember (userClassNames ,nonzeroClassNames ))
classSummary .Cost =[]; 
else
classSummary .Cost =cost ; 
end
end

function scoreTransform =processScoreTransform (transformer )
ifisempty (transformer )
scoreTransform =@classreg .learning .transform .identity ; 
elseifischar (transformer )
ifstrcmpi (transformer ,'none' )
scoreTransform =@classreg .learning .transform .identity ; 
else
scoreTransform =str2func (['classreg.learning.transform.' ,transformer (:)' ]); 
end
else
if~isa (transformer ,'function_handle' )
error (message ('stats:classreg:learning:classif:FullClassificationModel:processScoreTransform:BadScoreTransformation' )); 
end
scoreTransform =transformer ; 
end
end

function [X ,Y ,W ,dataSummary ,classSummary ,scoreTransform ]=...
    prepareData (X ,Y ,varargin )
[X ,Y ,vrange ,wastable ,varargin ]=classreg .learning .internal .table2FitMatrix (X ,Y ,varargin {:}); 


args ={'classnames' ,'cost' ,'prior' ,'scoretransform' }; 
defs ={[],[],[],[]}; 
[userClassNames ,cost ,prior ,transformer ,~,crArgs ]=...
    internal .stats .parseArgs (args ,defs ,varargin {:}); 


allClassNames =levels (classreg .learning .internal .ClassLabel (Y )); 
ifisempty (allClassNames )
error (message ('stats:classreg:learning:classif:FullClassificationModel:prepareData:EmptyClassNames' )); 
end


[X ,Y ,W ,dataSummary ]=...
    classreg .learning .FullClassificationRegressionModel .prepareDataCR (...
    X ,classreg .learning .internal .ClassLabel (Y ),crArgs {:},'VariableRange' ,vrange ,'TableInput' ,wastable ); 


[X ,Y ,W ,userClassNames ,nonzeroClassNames ,dataSummary .RowsUsed ]=...
    classreg .learning .classif .FullClassificationModel .processClassNames (...
    X ,Y ,W ,userClassNames ,allClassNames ,...
    dataSummary .RowsUsed ,dataSummary .ObservationsInRows ); 


[X ,Y ,W ,dataSummary .RowsUsed ]=classreg .learning .classif .FullClassificationModel .removeMissingVals (X ,Y ,W ,dataSummary .RowsUsed ); 


C =classreg .learning .internal .classCount (nonzeroClassNames ,Y ); 
WC =bsxfun (@times ,C ,W ); 
Wj =sum (WC ,1 ); 


prior =classreg .learning .classif .FullClassificationModel .processPrior (...
    prior ,Wj ,userClassNames ,nonzeroClassNames ); 


cost =classreg .learning .classif .FullClassificationModel .processCost (...
    cost ,prior ,userClassNames ,nonzeroClassNames ); 


[X ,Y ,~,WC ,Wj ,prior ,cost ,nonzeroClassNames ,dataSummary .RowsUsed ]=...
    classreg .learning .classif .FullClassificationModel .removeZeroPriorAndCost (...
    X ,Y ,C ,WC ,Wj ,prior ,cost ,nonzeroClassNames ,...
    dataSummary .RowsUsed ,dataSummary .ObservationsInRows ); 




prior =prior /sum (prior ); 
W =sum (bsxfun (@times ,WC ,prior ./Wj ),2 ); 


classSummary =...
    classreg .learning .classif .FullClassificationModel .makeClassSummary (...
    userClassNames ,nonzeroClassNames ,prior ,cost ); 


scoreTransform =...
    classreg .learning .classif .FullClassificationModel .processScoreTransform (transformer ); 
end
end

end
