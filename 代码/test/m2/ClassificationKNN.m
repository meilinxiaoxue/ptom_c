classdef ClassificationKNN <...
    classreg .learning .classif .FullClassificationModel 




























































properties (GetAccess =protected ,SetAccess =protected )

NS =[]; 


PrivW =[]; 
end

properties (GetAccess =public ,SetAccess =public ,Dependent =true )





NumNeighbors ; 






Distance ; 

















DistParameter ; 






IncludeTies ; 






DistanceWeight ; 







BreakTies ; 
end

properties (GetAccess =public ,SetAccess =protected ,Dependent =true )





NSMethod ; 
end

properties (GetAccess =public ,SetAccess =protected )










Mu ; 











Sigma ; 
end

properties (GetAccess =protected ,SetAccess =protected )





Cov =[]; 
Scale =[]; 
end

methods 

function nsmethod =get .NSMethod (this )
nsmethod =this .ModelParams .NSMethod ; 
end

function dist =get .Distance (this )
dist =this .ModelParams .Distance ; 
end

function this =set .Distance (this ,distMetric )
distMetric =convertStringsToChars (distMetric ); 
if~strncmpi (distMetric ,this .Distance ,3 )

this .NS .Distance =distMetric ; 


this .ModelParams .Distance =distMetric ; 
this .ModelParams .Exponent =[]; 
this .ModelParams .Cov =[]; 
this .ModelParams .Scale =[]; 

ifstrncmpi (distMetric ,'minkowski' ,3 )
this .ModelParams .Exponent =this .NS .DistParameter ; 
else
this =recomputeDataDependentDefaults (this ,this .NS .X ); 
end
end
end




function dp =get .DistParameter (this )
if~isempty (this .ModelParams .Exponent )
dp =this .ModelParams .Exponent ; 
elseif~isempty (this .Cov )
dp =this .Cov ; 
elseif~isempty (this .Scale )
dp =this .Scale ; 
else
dp =[]; 
end
end

function this =set .DistParameter (this ,para )

i =find (strncmpi (this .ModelParams .Distance ,{'minkowski' ,'mahalanobis' ,'seuclidean' },3 )); 
ifisempty (i )
error (message ('stats:ClassificationKNN:set:DistParameter:InvalidDistanceParam' )); 
elseif~isempty (this .Mu )&&(i ==2 ||i ==3 )

error (message ('stats:classreg:learning:modelparams:KNNParams:checkStandardizeDataArg:DistStdPrecedence' )); 
end


this .NS .DistParameter =para ; 


ifi ==1 
this .ModelParams .Exponent =para ; 
this .ModelParams .Cov =[]; 
this .ModelParams .Scale =[]; 
elseifi ==2 
this .ModelParams .Exponent =[]; 
this .ModelParams .Cov =para ; 
this .ModelParams .Scale =[]; 
else
this .ModelParams .Exponent =[]; 
this .ModelParams .Cov =[]; 
this .ModelParams .Scale =para ; 
end


this .Cov =this .ModelParams .Cov ; 
this .Scale =this .ModelParams .Scale ; 
end

function K =get .NumNeighbors (this )
K =this .ModelParams .NumNeighbors ; 
end

function this =set .NumNeighbors (this ,K )
if~isscalar (K )||~isnumeric (K )||...
    K <1 ||K ~=round (K )
error (message ('stats:ClassificationKNN:set:NumNeighbors:BadK' )); 
end
nx =size (this .X ,1 ); 
this .ModelParams .NumNeighbors =min (K ,nx ); 
end

function inTies =get .IncludeTies (this )
inTies =this .ModelParams .IncludeTies ; 
end

function this =set .IncludeTies (this ,tf )
if~islogical (tf )||~isscalar (tf )
error (message ('stats:ClassificationKNN:set:IncludeTies:BadIncludeTies' )); 
end
this .ModelParams .IncludeTies =tf ; 
end

function inTies =get .BreakTies (this )
inTies =this .ModelParams .BreakTies ; 
end

function this =set .BreakTies (this ,breakties )
breakties =convertStringsToChars (breakties ); 
if~ischar (breakties )
error (message ('stats:ClassificationKNN:set:BreakTies:BadBreakTies' )); 

else
breaktieList ={'smallest' ,'nearest' ,'random' }; 
i =find (strncmpi (breakties ,breaktieList ,length (breakties ))); 
ifisempty (i )
error (message ('stats:ClassificationKNN:set:BreakTies:BadBreakTies' )); 
else
this .ModelParams .BreakTies =breaktieList {i }; 
end
end
end

function distWgt =get .DistanceWeight (this )
distWgt =this .ModelParams .DistanceWeight ; 
end

function this =set .DistanceWeight (this ,wgt )
wgt =convertStringsToChars (wgt ); 
ifischar (wgt )
wgtList ={'equal' ,'inverse' ,'squaredinverse' }; 
i =find (strncmpi (wgt ,wgtList ,length (wgt ))); 
ifisempty (i )
error (message ('stats:ClassificationKNN:set:DistanceWeight:BadDistanceWeight' )); 
else
this .ModelParams .DistanceWeight =wgtList {i }; 
end

elseifisa (wgt ,'function_handle' )
this .ModelParams .DistanceWeight =wgt ; 
else
error (message ('stats:ClassificationKNN:set:DistanceWeight:BadDistanceWeight' )); 
end
end

end

methods (Access =protected )

function X =getX (this )

ifisempty (this .Mu )
X =this .NS .X ; 
else
X =this .unstandardize (this .NS .X ); 
end
end

function X =standardize (this ,X )


X =bsxfun (@minus ,X ,this .Mu ); 
sigma =this .Sigma ; 
sigma (sigma ==0 )=1 ; 
X =bsxfun (@rdivide ,X ,sigma ); 
end

function X =unstandardize (this ,X )


X =bsxfun (@times ,X ,this .Sigma ); 
X =bsxfun (@plus ,X ,this .Mu ); 
end

function this =recomputeDataDependentDefaults (this ,X )


this .Cov =this .ModelParams .Cov ; 
this .Scale =this .ModelParams .Scale ; 
ifstrncmpi (this .Distance ,'mahalanobis' ,3 )&&isempty (this .Cov )
this .Cov =classreg .learning .internal .wnancov (X ,this .W ,false ); 
elseifstrncmpi (this .Distance ,'seuclidean' ,3 )&&isempty (this .Scale )
this .Scale =sqrt (classreg .learning .internal .wnanvar (X ,this .W ,1 )); 
end
end

function this =createNSObj (this ,X )


nsmethod =this .ModelParams .NSMethod ; 
distance =this .ModelParams .Distance ; 
p =this .ModelParams .Exponent ; 

ifstrncmpi (nsmethod ,'kdtree' ,length (nsmethod ))
this .NS =KDTreeSearcher (X ,...
    'distance' ,distance ,'p' ,p ,'BucketSize' ,this .ModelParams .BucketSize ); 
this .ModelParams .NSMethod ='kdtree' ; 
this .Scale =[]; 
this .Cov =[]; 
this .ModelParams .Exponent =this .NS .DistParameter ; 
else


this .NS =ExhaustiveSearcher (X ,...
    'distance' ,distance ,'p' ,p ,'cov' ,this .Cov ,...
    'scale' ,this .Scale ,'checkNegativeDistance' ,true ); 
this .ModelParams .NSMethod ='exhaustive' ; 
this .ModelParams .BucketSize =[]; 
end
end

function this =normalizeWeights (this )



C =classreg .learning .internal .classCount (...
    this .ClassSummary .NonzeroProbClasses ,this .PrivY ); 

WC =bsxfun (@times ,C ,this .PrivW ); 
Wj =sum (WC ,1 ); 
this .W =sum (bsxfun (@times ,WC ,this .ClassSummary .Prior ./Wj ),2 ); 
end

function this =setPrior (this ,prior )


this =setPrivatePrior (this ,prior ); 


this =normalizeWeights (this ); 
end

function this =setCost (this ,cost )


this =setPrivateCost (this ,cost ); 
end


function s =propsForDisp (this ,s )
s =propsForDisp @classreg .learning .classif .FullClassificationModel (this ,s ); 
s .Distance =this .Distance ; 
s .NumNeighbors =this .NumNeighbors ; 
end



function [s ,gindex ,CIDX ]=score (this ,X ,varargin )
W =this .W ; 
NG =length (this .ClassSummary .ClassNames ); 

includeTies =this .ModelParams .IncludeTies ; 
gindex =grp2idx (this .PrivY ,this .ClassSummary .ClassNames ); 
distWgtList ={'equal' ,'inverse' ,'squaredinverse' }; 
distanceWeightFun =this .ModelParams .DistanceWeight ; 
distWgtIdx =find (strncmpi (distanceWeightFun ,distWgtList ,3 )); 

[CIDX ,dist ]=knnsearch (this .NS ,X ,'k' ,this .ModelParams .NumNeighbors ,...
    'includeTies' ,includeTies ); 

NX =size (X ,1 ); 







count =zeros (NX ,NG ); 
if(includeTies )
count =zeros (NG ,NX ); 
ifisa (distanceWeightFun ,'function_handle' )

try
distWgt =feval (this .ModelParams .DistanceWeight ,...
    dist {1 }); 

catch ME 
ifstrcmp ('MATLAB:UndefinedFunction' ,ME .identifier )...
    &&~isempty (strfind (ME .message ,func2str (distanceWeightFun )))
error (message ('stats:ClassificationKNN:Score:DistanceFunctionNotFound' ,func2str (distanceWeightFun ))); 
end

end
if~isnumeric (distWgt )
error (message ('stats:ClassificationKNN:Score:OutputBadType' )); 
end

forouter =1 :NX 

numNeighbors =sum (~isnan (dist {outer })); 
tempCIDX =CIDX {outer }(1 :numNeighbors ); 
tempIDX =gindex (tempCIDX ); 
tempDist =dist {outer }(1 :numNeighbors ); 
obsWgt =W (tempCIDX ); 
distWgt =feval (this .ModelParams .DistanceWeight ,tempDist ); 
if(any (distWgt <0 ))
error (message ('stats:ClassificationKNN:Score:NegativeDistanceWgt' )); 
end
wgt =obsWgt .*distWgt ' ; 
wgt (isnan (wgt ))=0 ; 

count (:,outer )=...
    accumarray (tempIDX ,wgt ,[NG ,1 ]); 
end

elseifdistWgtIdx ==1 

forouter =1 :NX 

numNeighbors =sum (~isnan (dist {outer })); 
tempCIDX =CIDX {outer }(1 :numNeighbors ); 
tempIDX =gindex (tempCIDX ); 
wgt =W (tempCIDX ); 
count (:,outer )=...
    accumarray (tempIDX ,wgt ,[NG ,1 ]); 
end

else

ifdistWgtIdx ==2 
e =1 ; 
else
e =2 ; 
end
forouter =1 :NX 

numNeighbors =sum (~isnan (dist {outer })); 
tempCIDX =CIDX {outer }(1 :numNeighbors ); 
tempIDX =gindex (tempCIDX ); 

obsWgt =W (tempCIDX ); 
tempDist =dist {outer }(1 :numNeighbors ); 
distWgt =wgtFunc (tempDist ,e ); 
wgt =obsWgt .*distWgt ' ; 
count (:,outer )=...
    accumarray (tempIDX ,wgt ,[NG ,1 ]); 

end

end
count =count ' ; 
else








numNeighbors =sum ((~all (isnan (dist ),1 ))); 
ifnumNeighbors >0 
dist (:,numNeighbors +1 :end)=[]; 
CIDX (:,numNeighbors +1 :end)=[]; 

ifisa (distanceWeightFun ,'function_handle' )
try
distWgt =feval (this .ModelParams .DistanceWeight ,dist (1 ,:)); 
catch ME 
ifstrcmp ('MATLAB:UndefinedFunction' ,ME .identifier )...
    &&~isempty (strfind (ME .message ,func2str (distanceWeightFun )))
error (message ('stats:ClassificationKNN:Score:DistanceFunctionNotFound' ,...
    func2str (distanceWeightFun ))); 
end
end
if~isnumeric (distWgt )
error (message ('stats:ClassificationKNN:Score:OutputBadType' )); 
end
distWgt =feval (this .ModelParams .DistanceWeight ,dist ); 
ifany (distWgt (:)<0 )
error (message ('stats:ClassificationKNN:Score:NegativeDistanceWgt' )); 
end
elseifdistWgtIdx ==1 
distWgt =ones (NX ,numNeighbors ); 



distWgt (isnan (dist ))=0 ; 
elseifdistWgtIdx ==2 
distWgt =wgtFunc (dist ,1 ); 
else
distWgt =wgtFunc (dist ,2 ); 
end



CNeighbor =gindex (CIDX ); 
obsWgt =W (CIDX ); 

if(NX ==1 )&&numNeighbors >1 
CNeighbor =CNeighbor ' ; 
obsWgt =obsWgt ' ; 
end


wgt =distWgt .*obsWgt ; 




wgt (isnan (wgt ))=0 ; 
ifnumNeighbors >5 


count =zeros (NG ,NX ); 
wgt =wgt ' ; 
CNeighbor =CNeighbor ' ; 
fori =1 :NX 
count (:,i )=...
    accumarray (CNeighbor (:,i ),wgt (:,i ),[NG ,1 ]); 
end
count =count ' ; 
else
count =zeros (NX ,NG ); 
forouter =1 :NX 
forinner =1 :numNeighbors 
count (outer ,CNeighbor (outer ,inner ))=...
    count (outer ,CNeighbor (outer ,inner ))+wgt (outer ,inner ); 
end
end
end
end
end

ifisa (distanceWeightFun ,'function_handle' )


infCountRow =any (isinf (count ),2 ); 
s =count ; 
s (infCountRow ,:)=0 ; 
s (isinf (count ))=1 ; 



s =bsxfun (@rdivide ,s ,sum (s ,2 )); 
else
s =bsxfun (@rdivide ,count ,sum (count ,2 )); 
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
temp =classreg .learning .FitTemplate .make (this .ModelParams .Method ,...
    'type' ,'classification' ,'scoretransform' ,this .PrivScoreTransform ,...
    'modelparams' ,this .ModelParams ,'CrossVal' ,'on' ,varargin {:}); 



partModel =fit (temp ,this .X ,this .Y ,'Weights' ,this .W ,...
    'predictornames' ,this .DataSummary .PredictorNames ,...
    'categoricalpredictors' ,this .CategoricalPredictors ,...
    'responsename' ,this .ResponseName ,...
    'classnames' ,this .ClassNames ,'prior' ,this .Prior ); 
partModel .Cost =this .Cost ; 
partModel .ScoreType =this .ScoreType ; 
end

function [label ,posteriors ,cost ]=predict (this ,X )

















adapter =classreg .learning .internal .makeClassificationModelAdapter (this ,X ); 
if~isempty (adapter )
[label ,posteriors ,cost ]=predict (adapter ,X ); 
return ; 
end


vrange =getvrange (this ); 
X =classreg .learning .internal .table2PredictMatrix (X ,[],[],...
    vrange ,this .CategoricalPredictors ,...
    getOptionalPredictorNames (this )); 




ifisempty (X )
[label ,posteriors ]=predictEmptyX (this ,X ); 
cost =NaN (0 ,numel (this .ClassSummary .ClassNames )); 
return ; 
end


if~isempty (this .Mu )
X =this .standardize (X ); 
end


breakTieFlag =find (strncmpi (this .BreakTies ,{'random' ,'nearest' },3 )); 


ifisempty (breakTieFlag )||breakTieFlag ==1 ||...
    this .NumNeighbors ==1 
posteriors =score (this ,X ); 
else
[posteriors ,gindex ,CIDX ]=score (this ,X ); 
end




cost =posteriors *this .Cost ; 
N =size (posteriors ,1 ); 
notNaN =~all (isnan (cost ),2 ); 
[~,cls ]=max (this .Prior ); 
label =repmat (this .ClassNames (cls ,:),N ,1 ); 
minCost =nan (N ,1 ); 
[minCost (notNaN ),classNum ]=min (cost (notNaN ,:),[],2 ); 
label (notNaN ,:)=this .ClassNames (classNum ,:); 
posteriors =this .PrivScoreTransform (posteriors ); 


if~isempty (breakTieFlag )&&this .NumNeighbors >1 

notNanRows =find (notNaN ); 
ifbreakTieFlag ==1 
fori =1 :numel (notNanRows )
ties =abs (cost (notNanRows (i ),:)-minCost (notNanRows (i )))<10 *eps (minCost (notNanRows (i ))); 
numTies =sum (ties ); 
ifnumTies >1 
choice =find (ties ); 
tb =randsample (numTies ,1 ); 
label (notNanRows (i ),:)=this .ClassNames (choice (tb ),:); 
end
end
else

if~this .IncludeTies 
CNeighbor =gindex (CIDX ); 
fori =1 :numel (notNanRows )
ties =abs (cost (notNanRows (i ),:)-minCost (notNanRows (i )))<10 *eps (minCost (notNanRows (i ))); 
numTies =sum (ties ); 
ifnumTies >1 
choice =find (ties ); 
forinner =1 :this .NumNeighbors 
ifismember (CNeighbor (notNanRows (i ),inner ),choice )
label (notNanRows (i ),:)=this .ClassNames (CNeighbor (notNanRows (i ),inner ),:); 
break

end
end
end
end
else

fori =1 :numel (notNanRows )
ties =cost (notNanRows (i ),:)==minCost (notNanRows (i )); 
numTies =sum (ties ); 
ifnumTies >1 
choice =find (ties ); 
forinner =1 :this .NumNeighbors 
tempCNeighbor =gindex (CIDX {notNanRows (i )}); 
ifismember (tempCNeighbor (inner ),choice )
label (notNanRows (i ),:)=this .ClassNames (tempCNeighbor (inner ),:); 
break

end
end
end
end
end
end
end
end

end

methods (Hidden )

function this =ClassificationKNN (X ,Y ,W ,modelParams ,...
    dataSummary ,classSummary ,scoreTransform )

ifnargin ~=7 ||ischar (W )
error (message ('stats:ClassificationKNN:ClassificationKNN:DoNotUseConstructor' )); 
end

[nx ,nDims ]=size (X ); 
if(modelParams .NumNeighbors >nx )
modelParams .NumNeighbors =nx ; 
end
if~(isempty (dataSummary .CategoricalPredictors )||...
    (length (dataSummary .CategoricalPredictors )==nDims ...
    &&all (dataSummary .CategoricalPredictors ==(1 :nDims ))))
ifdataSummary .TableInput 
error (message ('stats:ClassificationKNN:ClassificationKNN:BadCategoricalTable' )); 
else
error (message ('stats:ClassificationKNN:ClassificationKNN:BadCategoricalPre' )); 
end
end








origW =W ; 
this =this @classreg .learning .classif .FullClassificationModel (...
    X ,Y ,W ,modelParams ,dataSummary ,classSummary ,scoreTransform ); 



ifthis .ModelParameters .StandardizeData 

[this .PrivX ,this .Mu ,this .Sigma ]=classreg .learning .internal .wnanzscore (this .PrivX ,this .W ); 
end



this =recomputeDataDependentDefaults (this ,this .PrivX ); 


this =createNSObj (this ,this .PrivX ); 



this .PrivX =[]; 

this .ModelParams .Distance =this .NS .Distance ; 






this .PrivW =origW ; 

end

end

methods (Static ,Hidden )
function this =fit (X ,Y ,varargin )


args ={'cost' }; 
defs ={[]}; 
[cost ,~,fitArgs ]=internal .stats .parseArgs (args ,defs ,varargin {:}); 


temp =classreg .learning .FitTemplate .make (...
    'KNN' ,'type' ,'classification' ,fitArgs {:}); 
this =fit (temp ,X ,Y ); 


if~isempty (cost )
this .Cost =cost ; 
end
end

function temp =template (varargin )
classreg .learning .FitTemplate .catchType (varargin {:}); 
temp =classreg .learning .FitTemplate .make ('KNN' ,'type' ,'classification' ,varargin {:}); 
end
function [X ,Y ,W ,dataSummary ,classSummary ,scoreTransform ]=...
    prepareData (X ,Y ,varargin )
[X ,Y ,W ,dataSummary ,classSummary ,scoreTransform ]=...
    prepareData @classreg .learning .classif .FullClassificationModel (X ,Y ,varargin {:},'OrdinalIsCategorical' ,true ); 
end

function obj =fromStruct (s )

s .ScoreTransform =s .ScoreTransformFull ; 

X =s .X ; 
ifs .ClassSummary .ClassNamesType ==int8 (2 )
YtempLength =s .YLength ; 
Ytemp =cellstr (s .Y ); 
Y =arrayfun (@(x ,y )x {1 }(1 :y ),Ytemp ,YtempLength ,...
    'UniformOutput' ,false ); 
else
Y =s .Y ; 
end
Y =classreg .learning .internal .ClassLabel (Y ); 
W =s .W ; 

mp =s .ModelParams ; 
modelParams =classreg .learning .modelparams .KNNParams .fromStruct (mp ); 
s =classreg .learning .coderutils .structToClassif (s ); 
dataSummary =s .DataSummary ; 
classSummary =s .ClassSummary ; 
scoreTransform =s .ScoreTransform ; 

obj =ClassificationKNN (X ,Y ,W ,modelParams ,dataSummary ,classSummary ,scoreTransform ); 
end

function name =matlabCodegenRedirect (~)
name ='classreg.learning.coder.classif.ClassificationKNN' ; 
end
end


methods (Hidden )

function cmp =compact (this )




cmp =this ; 
end

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


ifistable (this .X )
X =table2array (this .X ); 
s .XisTable =true ; 
else
X =this .X ; 
s .XisTable =false ; 
end
s .X =X ; 


s .NSX =this .NS .X ; 
ifs .ClassSummary .ClassNamesType ==int8 (2 )
s .Y =char (this .Y ); 
s .YLength =cellfun (@length ,this .Y ); 
s .YLength =uint32 (s .YLength ); 
else
s .Y =this .Y ; 
s .YLength =uint32 (size (this .Y ,2 )*ones (size (this .Y ,1 ),1 )); 
end
s .YIdx =uint32 (grp2idx (this .PrivY ,this .ClassSummary .ClassNames )); 
s .W =this .W ; 


s .ModelParams =toStruct (this .ModelParameters ); 
s .Mu =this .Mu ; 
s .Sigma =this .Sigma ; 

s .NS =toStruct (this .NS ); 

s .FromStructFcn ='ClassificationKNN.fromStruct' ; 

end
end
end

function distWgt =wgtFunc (dist ,e )






minDist =min (dist ,[],2 ); 
distNormalized =bsxfun (@rdivide ,dist ,minDist ); 
distNormalized (dist ==0 )=1 ; 
distWgt =1 ./(distNormalized .^e ); 

end



