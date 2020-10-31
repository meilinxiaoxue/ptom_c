classdef Kernel 








properties (Abstract =true ,Hidden =true )
Impl ; 
end

properties (GetAccess =public ,SetAccess =protected ,Hidden =true )
ModelParams ; 
end

properties (GetAccess =protected ,SetAccess =protected )
FeatureMapper ; 
end

properties (GetAccess =protected ,SetAccess =protected ,Dependent =true )
Beta ; 
Bias ; 
end

properties (GetAccess =public ,SetAccess =protected ,Dependent =true ,Hidden =true )
ExpansionDimension ; 
end

properties (GetAccess =public ,SetAccess =protected ,Dependent =true )






NumExpansionDimensions ; 






FittedLoss ; 






Lambda ; 






ModelParameters ; 






Regularization ; 
end

properties (GetAccess =public ,SetAccess =protected )





KernelScale ; 






Learner ; 
end

methods (Access =protected )
function this =Kernel ()
end

function s =propsForDisp (this ,s )
ifnargin <2 ||isempty (s )
s =struct ; 
else
if~isstruct (s )
error (message ('stats:classreg:learning:Predictor:propsForDisp:BadS' )); 
end
end
s .Learner =this .Learner ; 
ifisempty (this .FeatureMapper )
s .Transformation ='' ; 
else
s .Transformation =this .FeatureMapper .t ; 
end
s .NumExpansionDimensions =this .NumExpansionDimensions ; 
s .KernelScale =this .KernelScale ; 
s .Lambda =this .Lambda ; 
end
end

methods 
function beta =get .Beta (this )
beta =this .Impl .Beta ; 
end

function bias =get .Bias (this )
bias =this .Impl .Bias ; 
end

function fl =get .FittedLoss (this )
fl =this .Impl .LossFunction ; 
end

function lambda =get .Lambda (this )
lambda =this .Impl .Lambda ; 
end

function mp =get .ModelParameters (this )
mp =this .ModelParams ; 
end

function r =get .Regularization (this )
ifthis .Impl .Ridge 
r ='ridge (L2)' ; 
else
r ='lasso (L1)' ; 
end
end

function ed =get .ExpansionDimension (this )
ifisempty (this .FeatureMapper )
ed =[]; 
else
ed =this .FeatureMapper .n ; 
end
end

function ed =get .NumExpansionDimensions (this )
ifisempty (this .FeatureMapper )
ed =[]; 
else
ed =this .FeatureMapper .n ; 
end
end

end

methods (Static ,Hidden )
function [X ,Y ,W ,dataSummary ]=prepareDataCR (X ,Y ,varargin )






[ignoreextra ,~,inputArgs ]=internal .stats .parseArgs (...
    {'ignoreextraparameters' },{false },varargin {:}); 

args ={'weights' ,'predictornames' ,'responsename' ...
    ,'categoricalpredictors' ,'observationsin' }; 
defs ={[],[],[]...
    ,[],'rows' }; 

ifignoreextra 
[W ,predictornames ,responsename ,catpreds ,obsIn ,~,~]=...
    internal .stats .parseArgs (args ,defs ,inputArgs {:}); 
else
[W ,predictornames ,responsename ,catpreds ,obsIn ]=...
    internal .stats .parseArgs (args ,defs ,inputArgs {:}); 
end


if~isfloat (X )||~ismatrix (X )
error (message ('stats:classreg:learning:FullClassificationRegressionModel:prepareDataCR:BadXType' )); 
end
internal .stats .checkSupportedNumeric ('X' ,X ,false ,true ); 


obsIn =validatestring (obsIn ,{'rows' ,'columns' },...
    'classreg.learning.Linear.prepareDataCR' ,'ObservationsIn' ); 
obsInRows =strcmp (obsIn ,'rows' ); 
ifobsInRows 
X =X ' ; 
end


ifisempty (X )||isempty (Y )
error (message ('stats:classreg:learning:FullClassificationRegressionModel:prepareDataCR:NoData' )); 
end
N =size (X ,2 ); 
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


t1 =any (isnan (X ),1 )' ; 
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
X (:,t )=[]; 
W (t )=[]; 
rowsused =~t ; 
else
rowsused =[]; 
end


D =size (X ,1 ); 
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


if~isempty (catpreds )
error (message ('stats:classreg:learning:Linear:prepareDataCR:CategoricalPredictorsNotSupported' )); 
end


dataSummary .PredictorNames =predictornames ; 
dataSummary .CategoricalPredictors =[]; 
dataSummary .ResponseName =responsename ; 
dataSummary .VariableRange =cell (1 ,D ); 
dataSummary .TableInput =false ; 
dataSummary .RowsUsed =rowsused ; 
dataSummary .ObservationsInRows =false ; 
dataSummary .ObservationsWereInRows =obsInRows ; 
end
end

end
