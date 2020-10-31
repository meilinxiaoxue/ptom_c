classdef ClassificationModel <classreg .learning .Predictor 






properties (GetAccess =public ,SetAccess =protected ,Hidden =true )
ClassSummary =struct ('ClassNames' ,{},'NonzeroProbClasses' ,{},'Cost' ,[],'Prior' ,[]); 
end

properties (GetAccess =public ,SetAccess =protected ,Hidden =true )
PrivScoreTransform =[]; 
PrivScoreType =[]; 
end

properties (GetAccess =public ,SetAccess =protected ,Dependent =true )





ClassNames ; 
end

properties (GetAccess =public ,SetAccess =public ,Dependent =true )




Prior ; 







Cost ; 











ScoreTransform ; 
end

properties (GetAccess =public ,SetAccess =public ,Dependent =true ,Hidden =true )














ScoreType ; 
end

properties (GetAccess =public ,SetAccess =protected ,Dependent =true ,Hidden =true )



ContinuousLoss ; 
end

properties (GetAccess =public ,SetAccess =public ,Hidden =true )
DefaultLoss =@classreg .learning .loss .mincost ; 
LabelPredictor =@classreg .learning .classif .ClassificationModel .minCost ; 
DefaultScoreType ='probability' ; 
end

methods 
function cnames =get .ClassNames (this )
cnames =labels (this .ClassSummary .ClassNames ); 
end

function cost =get .Cost (this )
K =length (this .ClassSummary .ClassNames ); 
ifisempty (this .ClassSummary .Cost )
cost =ones (K )-eye (K ); 
else
cost =zeros (K ); 
[~,pos ]=ismember (this .ClassSummary .NonzeroProbClasses ,...
    this .ClassSummary .ClassNames ); 
cost (pos ,pos )=this .ClassSummary .Cost ; 
unmatched =1 :K ; 
unmatched (pos )=[]; 
cost (:,unmatched )=NaN ; 
cost (1 :K +1 :end)=0 ; 
end
end

function prior =get .Prior (this )
K =length (this .ClassSummary .ClassNames ); 
prior =zeros (1 ,K ); 
[~,pos ]=ismember (this .ClassSummary .NonzeroProbClasses ,...
    this .ClassSummary .ClassNames ); 
prior (pos )=this .ClassSummary .Prior ; 
end

function this =set .Prior (this ,prior )
this =setPrior (this ,prior ); 
end

function this =set .Cost (this ,cost )
this =setCost (this ,cost ); 
end

function st =get .ScoreTransform (this )
st =classreg .learning .internal .convertScoreTransform (...
    this .PrivScoreTransform ,'string' ,[]); 
end

function this =set .ScoreTransform (this ,st )
st =convertStringsToChars (st ); 
this .PrivScoreTransform =...
    classreg .learning .internal .convertScoreTransform (st ,...
    'handle' ,numel (this .ClassSummary .ClassNames )); 
this .PrivScoreType =[]; 
end

function scoreType =get .ScoreType (this )
scoreType =getScoreType (this ); 
end

function this =set .ScoreType (this ,st )
this =setScoreType (this ,st ); 
end

function cl =get .ContinuousLoss (this )
cl =getContinuousLoss (this ); 
end
end

methods (Access =protected ,Abstract =true )
s =score (this ,X ,varargin )
end

methods (Access =protected )
function this =setPrior (this ,~)%#ok<INUSD> 
error (message ('stats:classreg:learning:classif:ClassificationModel:setPrior:Noop' )); 
end

function this =setCost (this ,~)%#ok<INUSD> 
error (message ('stats:classreg:learning:classif:ClassificationModel:setCost:Noop' )); 
end

function scoreType =getScoreType (this )
ifisequal (this .PrivScoreTransform ,@classreg .learning .transform .identity )
scoreType =this .DefaultScoreType ; 
elseif~isempty (this .PrivScoreType )
scoreType =this .PrivScoreType ; 
else
scoreType ='unknown' ; 
end
end

function this =setScoreType (this ,st )
this .PrivScoreType =classreg .learning .internal .convertScoreType (st ); 
end

function cl =getContinuousLoss (this )
cl =[]; 
ifstrcmp (this .ScoreType ,'probability' )
cl =@classreg .learning .loss .quadratic ; 
end
end

function s =propsForDisp (this ,s )
s =propsForDisp @classreg .learning .Predictor (this ,s ); 
cnames =this .ClassNames ; 
ifischar (cnames )
s .ClassNames =cnames ; 
else
s .ClassNames =cnames ' ; 
end
s .ScoreTransform =this .ScoreTransform ; 
end

function [labels ,posterior ,cost ]=predictEmptyX (this ,X )
D =numel (this .PredictorNames ); 
ifthis .ObservationsInRows 
Dpassed =size (X ,2 ); 
str =getString (message ('stats:classreg:learning:classif:ClassificationModel:predictEmptyX:columns' )); 
else
Dpassed =size (X ,1 ); 
str =getString (message ('stats:classreg:learning:classif:ClassificationModel:predictEmptyX:rows' )); 
end
ifDpassed ~=D 
error (message ('stats:classreg:learning:classif:ClassificationModel:predictEmptyX:XSizeMismatch' ,D ,str )); 
end
labels =repmat (this .ClassNames (1 ,:),0 ,1 ); 
K =numel (this .ClassSummary .ClassNames ); 
posterior =NaN (0 ,K ); 
cost =NaN (0 ,K ); 
end
end

methods (Hidden )
function this =ClassificationModel (dataSummary ,classSummary ,...
    scoreTransform ,scoreType )
this =this @classreg .learning .Predictor (dataSummary ); 
this .ClassSummary =classSummary ; 
this .PrivScoreTransform =scoreTransform ; 
this .PrivScoreType =scoreType ; 
end

function this =setPrivatePrior (this ,prior )
ifisempty (prior )||strncmpi (prior ,'empirical' ,length (prior ))
error (message ('stats:classreg:learning:classif:ClassificationModel:setPrivatePrior:EmpiricalOrEmptyPrior' )); 
end
this .ClassSummary .Prior =...
    classreg .learning .classif .FullClassificationModel .processPrior (...
    prior ,[],this .ClassSummary .ClassNames ,...
    this .ClassSummary .NonzeroProbClasses ); 
end

function this =setPrivateCost (this ,cost )
this .ClassSummary .Cost =...
    classreg .learning .classif .FullClassificationModel .processCost (...
    cost ,this .ClassSummary .Prior ,this .ClassSummary .ClassNames ,...
    this .ClassSummary .NonzeroProbClasses ); 
end

function [X ,C ,W ,Y ,rowData ]=prepareDataForLoss (...
    this ,X ,Y ,W ,rowData ,cleanRows ,convertX ,obsInRows )


ifnargin <8 ||isempty (obsInRows )
obsInRows =true ; 
end

vrange =getvrange (this ); 
ifistable (X )
pnames =this .PredictorNames ; 
else
pnames =getOptionalPredictorNames (this ); 
end


ifconvertX 
[X ,Y ,W ]=classreg .learning .internal .table2PredictMatrix (X ,Y ,W ,...
    vrange ,this .CategoricalPredictors ,pnames ); 
else
[~,Y ,W ]=classreg .learning .internal .table2PredictMatrix (X ,Y ,W ,...
    vrange ,this .CategoricalPredictors ,pnames ); 
end


Y =classreg .learning .internal .ClassLabel (Y ); 
N =numel (Y ); 


if(~isnumeric (X )||~ismatrix (X ))&&~istable (X )&&~isa (X ,'dataset' )
error (message ('stats:classreg:learning:classif:ClassificationModel:prepareDataForLoss:BadXType' )); 
end


ifobsInRows 
Npassed =size (X ,1 ); 
else
Npassed =size (X ,2 ); 
end
ifNpassed ~=N 
error (message ('stats:classreg:learning:classif:ClassificationModel:prepareDataForLoss:SizeXYMismatch' )); 
end


if~isfloat (W )||~isvector (W )||length (W )~=N ||any (W <0 )
error (message ('stats:classreg:learning:classif:ClassificationModel:prepareDataForLoss:BadWeights' ,N )); 
end
internal .stats .checkSupportedNumeric ('Weights' ,W ,true ,false ,false ,true ); 
W =W (:); 


if~isempty (rowData )
haveRowData =true ; 
ifsize (rowData ,1 )~=N 
error (message ('stats:classreg:learning:classif:ClassificationModel:prepareDataForLoss:SizeRowDataMismatch' ,N )); 
end
else
haveRowData =false ; 
end


t =ismissing (Y ); 
ifany (t )&&cleanRows 
Y (t )=[]; 
ifobsInRows 
X (t ,:)=[]; 
else
X (:,t )=[]; 
end
W (t ,:)=[]; 
ifhaveRowData 
rowData (t ,:)=[]; 
end
end




C =classreg .learning .internal .classCount (this .ClassSummary .ClassNames ,Y ); 




zeroprior =this .Prior ==0 ; 
ifany (zeroprior )&&cleanRows &&~isscalar (this .Prior )
t =any (C (:,zeroprior ),2 ); 
Y (t )=[]; 
ifobsInRows 
X (t ,:)=[]; 
else
X (:,t )=[]; 
end
C (t ,:)=[]; 
W (t ,:)=[]; 
ifhaveRowData 
rowData (t ,:)=[]; 
end
end




zerocost =all (this .Cost ==0 ,2 )' ; 
ifany (zerocost )&&cleanRows &&~isscalar (this .Cost )
t =any (C (:,zerocost ),2 ); 
Y (t )=[]; 
ifobsInRows 
X (t ,:)=[]; 
else
X (:,t )=[]; 
end
C (t ,:)=[]; 
W (t ,:)=[]; 
ifhaveRowData 
rowData (t ,:)=[]; 
end
end


if~isempty (C )
WC =bsxfun (@times ,C ,W ); 
Wj =sum (WC ,1 ); 
adjWFactor =zeros (1 ,numel (Wj ),'like' ,Wj ); 
zeroprior =Wj ==0 ; 
adjWFactor (~zeroprior )=this .Prior (~zeroprior )./Wj (~zeroprior ); 
W =sum (WC .*adjWFactor ,2 ); 
end
end
end

methods 
function [labels ,scores ,cost ]=predict (this ,X ,varargin )
















adapter =classreg .learning .internal .makeClassificationModelAdapter (this ,X ); 
if~isempty (adapter )
[labels ,scores ,cost ]=predict (adapter ,X ); 
return ; 
end


ifthis .TableInput ||istable (X )
vrange =getvrange (this ); 
X =classreg .learning .internal .table2PredictMatrix (X ,[],[],...
    vrange ,...
    this .CategoricalPredictors ,this .PredictorNames ); 
end


[X ,varargin ]=classreg .learning .internal .orientX (...
    X ,this .ObservationsInRows ,varargin {:}); 


ifisempty (X )
[labels ,scores ,cost ]=predictEmptyX (this ,X ); 
return ; 
end


scores =score (this ,X ,varargin {:}); 


[labels ,scores ,cost ]=this .LabelPredictor (this .ClassNames ,...
    this .Prior ,this .Cost ,scores ,this .PrivScoreTransform ); 
end

function m =margin (this ,X ,varargin )














[varargin {:}]=convertStringsToChars (varargin {:}); 

adapter =classreg .learning .internal .makeClassificationModelAdapter (this ,X ,varargin {:}); 
if~isempty (adapter )
m =slice (adapter ,@this .margin ,X ,varargin {:}); 
return 
end

[Y ,varargin ]=classreg .learning .internal .inferResponse (this .ResponseName ,X ,varargin {:}); 

obsInRows =classreg .learning .internal .orientation (varargin {:}); 
ifobsInRows 
N =size (X ,1 ); 
else
N =size (X ,2 ); 
end

[X ,C ]=prepareDataForLoss (this ,X ,Y ,ones (N ,1 ),[],false ,false ,obsInRows ); 

[~,Sfit ]=predict (this ,X ,varargin {:}); 
S =size (Sfit ,3 ); 
m =NaN (N ,S ,'like' ,Sfit ); 
fors =1 :S 
m (:,s )=classreg .learning .loss .classifmargin (C ,Sfit (:,:,s )); 
end
end

function e =edge (this ,X ,varargin )




















[varargin {:}]=convertStringsToChars (varargin {:}); 

adapter =classreg .learning .internal .makeClassificationModelAdapter (this ,X ,varargin {:}); 
if~isempty (adapter )
e =edge (adapter ,X ,varargin {:}); 
return 
end

[Y ,varargin ]=classreg .learning .internal .inferResponse (...
    this .ResponseName ,X ,varargin {:}); 


obsInRows =classreg .learning .internal .orientation (varargin {:}); 
ifobsInRows 
N =size (X ,1 ); 
else
N =size (X ,2 ); 
end
args ={'weights' }; 
defs ={ones (N ,1 )}; 
[W ,~,extraArgs ]=internal .stats .parseArgs (args ,defs ,varargin {:}); 


[X ,C ,W ]=prepareDataForLoss (this ,X ,Y ,W ,[],true ,false ,obsInRows ); 


[~,Sfit ]=predict (this ,X ,extraArgs {:}); 


classreg .learning .internal .classifCheck (C ,Sfit (:,:,1 ),W ,[]); 


S =size (Sfit ,3 ); 
e =NaN (1 ,S ,'like' ,Sfit ); 
fors =1 :S 
e (s )=classreg .learning .loss .classifedge (C ,Sfit (:,:,s ),W ,[]); 
end
end

function l =loss (this ,X ,varargin )






































[varargin {:}]=convertStringsToChars (varargin {:}); 

adapter =classreg .learning .internal .makeClassificationModelAdapter (this ,X ,varargin {:}); 
if~isempty (adapter )
l =loss (adapter ,X ,varargin {:}); 
return 
end

[Y ,varargin ]=classreg .learning .internal .inferResponse (this .ResponseName ,X ,varargin {:}); 


obsInRows =classreg .learning .internal .orientation (varargin {:}); 
ifobsInRows 
N =size (X ,1 ); 
else
N =size (X ,2 ); 
end
args ={'lossfun' ,'weights' }; 
defs ={this .DefaultLoss ,ones (N ,1 )}; 
[funloss ,W ,~,extraArgs ]=...
    internal .stats .parseArgs (args ,defs ,varargin {:}); 


[X ,C ,W ]=prepareDataForLoss (this ,X ,Y ,W ,[],true ,false ,obsInRows ); 


funloss =classreg .learning .internal .lossCheck (funloss ,'classification' ); 


[~,Sfit ]=predict (this ,X ,extraArgs {:}); 


classreg .learning .internal .classifCheck (C ,Sfit (:,:,1 ),W ,this .Cost ); 


S =size (Sfit ,3 ); 
l =NaN (1 ,S ,'like' ,Sfit ); 
fors =1 :S 
l (s )=funloss (C ,Sfit (:,:,s ),W ,this .Cost ); 
end
end

function [h ,p ,err1 ,err2 ]=compareHoldout (this ,other ,X1 ,X2 ,varargin )





































































































[varargin {:}]=convertStringsToChars (varargin {:}); 
if~isa (other ,'classreg.learning.classif.ClassificationModel' )
error (message ('stats:classreg:learning:classif:ClassificationModel:compareHoldout:BadOtherType' )); 
end


adapter =classreg .learning .internal .makeClassificationModelAdapter (this ,X1 ,X2 ,varargin {:}); 
if~isempty (adapter )
error (message ('MATLAB:bigdata:array:FcnNotSupported' ,'COMPAREHOLDOUT' ))
end

args =varargin ; 
ifistable (X1 )&&istable (X2 )

Y =classreg .learning .internal .inferResponse (this .ResponseName ,X1 ,varargin {:}); 
[Y2 ,args ]=classreg .learning .internal .inferResponse (other .ResponseName ,X2 ,varargin {:}); 
if~isequal (Y ,Y2 )
error (message ('stats:classreg:learning:classif:ClassificationModel:compareHoldout:DifferentResponseValues' )); 
end
elseifisempty (args )
error (message ('MATLAB:minrhs' )); 
else

Y =args {1 }; 
args (1 )=[]; 
end

Y =classreg .learning .internal .ClassLabel (Y ); 
N =numel (Y ); 

if~ismatrix (X1 )||size (X1 ,1 )~=N 
error (message ('stats:classreg:learning:classif:ClassificationModel:compareHoldout:BadPredictorMatrix' ,'X1' ,N )); 
end
if~ismatrix (X2 )||size (X2 ,1 )~=N 
error (message ('stats:classreg:learning:classif:ClassificationModel:compareHoldout:BadPredictorMatrix' ,'X2' ,N )); 
end

Yhat1 =predict (this ,X1 ); 
Yhat2 =predict (other ,X2 ); 

[h ,p ,err1 ,err2 ]=testcholdout (Yhat1 ,Yhat2 ,Y ,args {:}); 
end
end

methods (Static =true ,Hidden =true )
function [labels ,scores ,cost ,classnum ]=...
    maxScore (classnames ,Prior ,Cost ,scores ,scoreTransform )
scores =scoreTransform (scores ); 
N =size (scores ,1 ); 
notNaN =~all (isnan (scores ),2 ); 
[~,cls ]=max (Prior ); 
labels =repmat (classnames (cls ,:),N ,1 ); 
[~,classnum ]=max (scores (notNaN ,:),[],2 ); 
labels (notNaN ,:)=classnames (classnum ,:); 
cost =Cost (:,classnum )' ; 
ifN >size (classnum ,1 )
temp =NaN (N ,1 ,'like' ,scores ); 
temp (notNaN ,:)=classnum ; 
classnum =temp ; 
temp =NaN (N ,size (cost ,2 )); 
temp (notNaN ,:)=cost ; 
cost =temp ; 
end
end

function [labels ,scores ,cost ,classnum ]=...
    minCost (classnames ,Prior ,Cost ,posterior ,scoreTransform )
cost =posterior *Cost ; 
N =size (posterior ,1 ); 
notNaN =~all (isnan (cost ),2 ); 
[~,cls ]=max (Prior ); 
labels =repmat (classnames (cls ,:),N ,1 ); 
[~,classnum ]=min (cost (notNaN ,:),[],2 ); 
labels (notNaN ,:)=classnames (classnum ,:); 
scores =scoreTransform (posterior ); 
end
end

end
