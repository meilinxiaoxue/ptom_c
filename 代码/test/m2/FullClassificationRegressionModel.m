classdef FullClassificationRegressionModel <classreg .learning .Predictor 








properties (GetAccess =public ,SetAccess =protected ,Dependent =true )







X ; 







RowsUsed =[]; 
end

properties (GetAccess =public ,SetAccess =protected ,Hidden =true )
ModelParams =[]; 
end

properties (GetAccess =public ,SetAccess =protected )





W =[]; 
end

properties (GetAccess =public ,SetAccess =protected ,Dependent =true ,Hidden =true )
NObservations ; 
end

properties (GetAccess =public ,SetAccess =protected ,Hidden =true )
PrivX =[]; 
PrivY =[]; 
end

properties (GetAccess =public ,SetAccess =protected ,Dependent =true )





ModelParameters =[]; 






NumObservations ; 
end

properties (SetAccess =private )





HyperparameterOptimizationResults =[]; 
end

methods 
function x =get .X (this )
x =getX (this ); 


ifthis .TableInput 
t =array2table (x ,'VariableNames' ,this .PredictorNames ); 
forj =1 :size (x ,2 )
vrj =this .VariableRange {j }; 
newx =decodeX (x (:,j ),vrj ); 
t .(this .PredictorNames {j })=newx ; 
end
x =t ; 
elseif~isempty (this .VariableRange )&&isequal (this .CategoricalVariableCoding ,'dummy' )
forj =1 :size (x ,2 )
vrj =this .VariableRange {j }; 
if~isempty (vrj )
newx =decodeX (x (:,j ),vrj ); 
x (:,j )=newx ; 
end
end
end
end

function this =set .X (this ,x )
this .PrivX =x ; 
end

function mp =get .ModelParameters (this )
mp =this .ModelParams ; 
end

function n =get .NumObservations (this )
n =size (getX (this ),1 ); 
end

function n =get .NObservations (this )
n =this .NumObservations ; 
end

function ru =get .RowsUsed (this )
try
ru =this .DataSummary .RowsUsed ; 
catch 
ru =[]; 
end
end
function this =set .RowsUsed (this ,ru )
this .DataSummary .RowsUsed =ru ; 
end
end

methods (Abstract ,Static )
obj =fit (X ,Y ,varargin )
end

methods (Abstract )
cmp =compact (this )
partModel =crossval (this ,varargin )
end

methods (Access =protected )
function x =getX (this )
x =this .PrivX ; 
end
end

methods (Access =protected )
function this =FullClassificationRegressionModel (dataSummary ,X ,Y ,W ,modelParams )
this =this @classreg .learning .Predictor (dataSummary ); 
this .PrivX =X ; 
this .PrivY =Y ; 
this .W =W ; 
this .ModelParams =modelParams ; 
end

function s =propsForDisp (this ,s )
s =propsForDisp @classreg .learning .Predictor (this ,s ); 
s .NumObservations =this .NumObservations ; 
if~isempty (this .HyperparameterOptimizationResults )
s .HyperparameterOptimizationResults =this .HyperparameterOptimizationResults ; 
end
end
end

methods (Static ,Hidden )
function [X ,Y ,W ,dataSummary ]=prepareDataCR (X ,Y ,varargin )

[ignoreextra ,~,inputArgs ]=internal .stats .parseArgs (...
    {'ignoreextraparameters' },{false },varargin {:}); 

args ={'weights' ,'predictornames' ,'responsename' ...
    ,'categoricalpredictors' ,'variablerange' ,'tableinput' ...
    ,'observationsin' }; 
defs ={[],[],[]...
    ,[],{},false ...
    ,'rows' }; 

ifignoreextra 
[W ,predictornames ,responsename ,catpreds ,vrange ,wastable ,obsIn ,~,~]=...
    internal .stats .parseArgs (args ,defs ,inputArgs {:}); 
else
[W ,predictornames ,responsename ,catpreds ,vrange ,wastable ,obsIn ]=...
    internal .stats .parseArgs (args ,defs ,inputArgs {:}); 
end










if~isnumeric (X )||~ismatrix (X )
error (message ('stats:classreg:learning:FullClassificationRegressionModel:prepareDataCR:BadXType' )); 
end


obsIn =validatestring (obsIn ,{'rows' ,'columns' },...
    'classreg.learning.FullClassificationRegressionModel:prepareDataCR' ,'ObservationsIn' ); 
obsInRows =strcmp (obsIn ,'rows' ); 


ifisempty (X )||isempty (Y )
error (message ('stats:classreg:learning:FullClassificationRegressionModel:prepareDataCR:NoData' )); 
end
ifobsInRows 
N =size (X ,1 ); 
else
N =size (X ,2 ); 
end
ifN ~=length (Y )
error (message ('stats:classreg:learning:FullClassificationRegressionModel:prepareDataCR:InputSizeMismatch' )); 
end


ifisempty (W )
W =ones (N ,1 ); 
else
if~isfloat (W )||length (W )~=N ||~isvector (W )
error (message ('stats:classreg:learning:FullClassificationRegressionModel:prepareDataCR:BadW' )); 
end
ifany (W <0 )||all (W ==0 )
error (message ('stats:classreg:learning:FullClassificationRegressionModel:prepareDataCR:NegativeWeights' )); 
end
W =W (:); 
end
internal .stats .checkSupportedNumeric ('Weights' ,W ,true ); 


ifobsInRows 
t1 =all (isnan (X ),2 ); 
else
t1 =all (isnan (X ),1 )' ; 
end
ifall (t1 )
error (message ('stats:classreg:learning:FullClassificationRegressionModel:prepareDataCR:NoGoodXData' )); 
end


t2 =(W ==0 |isnan (W )); 
t =t1 |t2 ; 
ifall (t )
error (message ('stats:classreg:learning:FullClassificationRegressionModel:prepareDataCR:NoGoodWeights' )); 
end

ifany (t )
Y (t )=[]; 
ifobsInRows 
X (t ,:)=[]; 
else
X (:,t )=[]; 
end
W (t )=[]; 
rowsused =~t ; 
else
rowsused =[]; 
end


ifobsInRows 
D =size (X ,2 ); 
else
D =size (X ,1 ); 
end
ifisempty (predictornames )
predictornames =D ; 
elseifisnumeric (predictornames )
if~(isscalar (predictornames )&&predictornames ==D )
error (message ('stats:classreg:learning:FullClassificationRegressionModel:prepareDataCR:BadNumericPredictor' ,D )); 
end
else
if~iscellstr (predictornames )
if~ischar (predictornames )
error (message ('stats:classreg:learning:FullClassificationRegressionModel:prepareDataCR:BadPredictorType' )); 
end
predictornames =cellstr (predictornames ); 
end
iflength (predictornames )~=D ||length (unique (predictornames ))~=D 
error (message ('stats:classreg:learning:FullClassificationRegressionModel:prepareDataCR:PredictorMismatch' ,D )); 
end
end
predictornames =predictornames (:)' ; 


ifisempty (responsename )
responsename ='Y' ; 
else
if~ischar (responsename )
error (message ('stats:classreg:learning:FullClassificationRegressionModel:prepareDataCR:BadResponseName' )); 
end
end


ifisnumeric (catpreds )
catpreds =ceil (catpreds ); 
ifany (catpreds <1 )||any (catpreds >D )
error (message ('stats:classreg:learning:FullClassificationRegressionModel:prepareDataCR:BadCatPredIntegerIndex' ,D )); 
end
elseifislogical (catpreds )
iflength (catpreds )~=D 
error (message ('stats:classreg:learning:FullClassificationRegressionModel:prepareDataCR:BadCatPredLogicalIndex' ,D )); 
end
idx =1 :D ; 
catpreds =idx (catpreds ); 
elseifischar (catpreds )&&strcmpi (catpreds ,'all' )
catpreds =1 :D ; 
else
if~ischar (catpreds )&&~iscellstr (catpreds )
error (message ('stats:classreg:learning:FullClassificationRegressionModel:prepareDataCR:BadCatVarType' )); 
end
if~iscellstr (catpreds )
catpreds =cellstr (catpreds ); 
end
ifisnumeric (predictornames )
error (message ('stats:classreg:learning:FullClassificationRegressionModel:prepareDataCR:CharCatVarWithoutVarNames' )); 
end
[tf ,pos ]=ismember (catpreds ,predictornames ); 
ifany (~tf )
error (message ('stats:classreg:learning:FullClassificationRegressionModel:prepareDataCR:BadCatVarName' ,...
    catpreds {find (~tf ,1 ,'first' )})); 
end
catpreds =pos ; 
end

if~wastable 
vrange =cell (1 ,D ); 
iscat =false (1 ,D ); 
iscat (catpreds )=true ; 
fork =1 :D 
ifiscat (k )
ifobsInRows 
x =X (:,k ); 
else
x =X (k ,:)' ; 
end
vrk =unique (x ); 
vrange {k }=vrk (~isnan (vrk )); 
end
end
end


ifisempty (catpreds )
catpreds =[]; 
end
dataSummary .PredictorNames =predictornames ; 
dataSummary .CategoricalPredictors =catpreds ; 
dataSummary .ResponseName =responsename ; 
dataSummary .VariableRange =vrange ; 
dataSummary .TableInput =wastable ; 
dataSummary .RowsUsed =rowsused ; 
dataSummary .ObservationsInRows =obsInRows ; 
end

function catchWeights (varargin )
args ={'weights' }; 
defs ={[]}; 
[w ,~,~]=internal .stats .parseArgs (args ,defs ,varargin {:}); 
if~isempty (w )
error (message ('stats:classreg:learning:FullClassificationRegressionModel:catchWeights:NonEmptyWeights' )); 
end
end

end

methods (Hidden )
function this =setParameterOptimizationResults (this ,Results )
this .HyperparameterOptimizationResults =Results ; 
end
end
end

function newx =decodeX (oldx ,vr )

ifisempty (vr )
newx =oldx ; 
else
ok =oldx >0 &~isnan (oldx ); 
ifall (ok )
newx =vr (oldx ); 
else
newx (ok ,:)=vr (oldx (ok )); 
ifiscategorical (newx )
missing ='<undefined>' ; 
elseifisfloat (newx )
missing =NaN ; 
elseifiscell (newx )
missing ={'' }; 
elseifischar (newx )
missing =' ' ; 
end
newx (~ok ,:)=missing ; 
end
end
end
