classdef RegressionModel <classreg .learning .Predictor 




properties (GetAccess =public ,SetAccess =protected ,Hidden =true )
PrivResponseTransform =[]; 
DefaultLoss =@classreg .learning .loss .mse ; 
end

properties (GetAccess =public ,SetAccess =public ,Dependent =true )






ResponseTransform ; 
end

methods 
function ts =get .ResponseTransform (this )
ts =func2str (this .PrivResponseTransform ); 
ifstrcmp (ts ,'classreg.learning.transform.identity' )
ts ='none' ; 
end
idx =strfind (ts ,'classreg.learning.transform.' ); 
if~isempty (idx )
ts =ts (1 +length ('classreg.learning.transform.' ):end); 
end
end

function this =set .ResponseTransform (this ,rt )
rt =convertStringsToChars (rt ); 
this .PrivResponseTransform =...
    classreg .learning .internal .convertScoreTransform (rt ,'handle' ,1 ); 
end
end

methods (Hidden )
function this =RegressionModel (dataSummary ,responseTransform )
this =this @classreg .learning .Predictor (dataSummary ); 
this .PrivResponseTransform =responseTransform ; 
end

function [X ,Y ,W ]=prepareDataForLoss (this ,X ,Y ,W ,vrange ,convertX ,obsInRows )

ifnargin <7 ||isempty (obsInRows )
obsInRows =true ; 
end

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


if(~isnumeric (X )||~ismatrix (X ))&&~istable (X )&&~isa (X ,'dataset' )
error (message ('stats:classreg:learning:regr:RegressionModel:prepareDataForLoss:BadXType' )); 
end


if~isempty (Y )&&(~isfloat (Y )||~isvector (Y ))
error (message ('stats:classreg:learning:regr:RegressionModel:prepareDataForLoss:BadYType' )); 
end
internal .stats .checkSupportedNumeric ('Y' ,Y ); 
Y =Y (:); 
N =numel (Y ); 


ifobsInRows 
Npassed =size (X ,1 ); 
else
Npassed =size (X ,2 ); 
end
ifNpassed ~=N 
error (message ('stats:classreg:learning:regr:RegressionModel:prepareDataForLoss:SizeXYMismatch' )); 
end


if~isfloat (W )||~isvector (W )||length (W )~=N ||any (W <0 )
error (message ('stats:classreg:learning:regr:RegressionModel:prepareDataForLoss:BadWeights' ,N )); 
end
internal .stats .checkSupportedNumeric ('Weights' ,W ,true ); 
W =W (:); 


t =isnan (Y ); 
ifany (t )&&N >0 
ifobsInRows 
X (t ,:)=[]; 
else
X (:,t )=[]; 
end
Y (t ,:)=[]; 
W (t ,:)=[]; 
end


ifsum (W )>0 
W =W /sum (W ); 
end

end
end

methods (Access =protected )
function s =propsForDisp (this ,s )
s =propsForDisp @classreg .learning .Predictor (this ,s ); 
s .ResponseTransform =this .ResponseTransform ; 
end

function yfit =predictEmptyX (this ,X )
D =numel (this .PredictorNames ); 
ifthis .ObservationsInRows 
str =getString (message ('stats:classreg:learning:regr:RegressionModel:predictEmptyX:columns' )); 
Dpassed =size (X ,2 ); 
else
Dpassed =size (X ,1 ); 
str =getString (message ('stats:classreg:learning:regr:RegressionModel:predictEmptyX:rows' )); 
end
ifDpassed ~=D 
error (message ('stats:classreg:learning:regr:RegressionModel:predictEmptyX:XSizeMismatch' ,D ,str )); 
end
yfit =NaN (0 ,1 ); 
end

end

methods (Access =protected ,Abstract =true )
r =response (this ,X ,varargin )
end

methods 
function Yfit =predict (this ,X ,varargin )












adapter =classreg .learning .internal .makeClassificationModelAdapter (this ,X ); 
if~isempty (adapter )
Yfit =predict (adapter ,X ,varargin {:}); 
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
Yfit =predictEmptyX (this ,X ); 
return ; 
end

ifany (this .CategoricalPredictors )&&strcmp (this .CategoricalVariableCoding ,'dummy' )
if~this .TableInput 
X =classreg .learning .internal .encodeCategorical (X ,this .VariableRange ); 
end
X =classreg .learning .internal .expandCategorical (X ,...
    this .CategoricalPredictors ,this .VariableRange ); 
end
Yfit =this .PrivResponseTransform (response (this ,X ,varargin {:})); 
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
defs ={@classreg .learning .loss .mse ,ones (N ,1 )}; 
[funloss ,W ,~,extraArgs ]=...
    internal .stats .parseArgs (args ,defs ,varargin {:}); 


[X ,Y ,W ]=prepareDataForLoss (this ,X ,Y ,W ,this .VariableRange ,false ,obsInRows ); 


funloss =classreg .learning .internal .lossCheck (funloss ,'regression' ); 


Yfit =predict (this ,X ,extraArgs {:}); 


classreg .learning .internal .regrCheck (Y ,Yfit (:,1 ),W ); 


R =size (Yfit ,2 ); 
l =NaN (1 ,R ); 
forr =1 :R 
l (r )=funloss (Y ,Yfit (:,r ),W ); 
end
end

function [AX ]=plotPartialDependence (this ,features ,X ,varargin )






























































































narginchk (3 ,13 ); 


ax =classreg .regr .modelutils .plotPartialDependence (this ,...
    features ,X ,varargin {:}); 
if(nargout >0 )
AX =ax ; 
end
end
end
end
