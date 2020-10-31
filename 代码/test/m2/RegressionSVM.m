classdef RegressionSVM <...
    classreg .learning .regr .FullRegressionModel &classreg .learning .regr .CompactRegressionSVM 


























































properties (SetAccess =protected ,GetAccess =public ,Dependent =true )






BoxConstraints ; 









CacheInfo ; 








































ConvergenceInfo ; 






Epsilon ; 













Gradient ; 







IsSupportVector ; 







NumIterations ; 






OutlierFraction ; 







ShrinkagePeriod ; 






Solver ; 
end

methods 
function a =get .BoxConstraints (this )
a =this .Impl .C ; 
end


function a =get .CacheInfo (this )
a =this .Impl .CacheInfo ; 
end

function a =get .ConvergenceInfo (this )
a =this .Impl .ConvergenceInfo ; 
ifisfield (a ,'OutlierHistory' )
a =rmfield (a ,'OutlierHistory' ); 
end
ifisfield (a ,'ChangeSetHistory' )
a =rmfield (a ,'ChangeSetHistory' ); 
end
end

function a =get .OutlierFraction (this )
a =this .Impl .FractionToExclude ; 
end

function a =get .Epsilon (this )
a =this .ModelParams .Epsilon ; 
end
function a =get .Gradient (this )
a =this .Impl .Gradient ; 
end

function a =get .Solver (this )
a =this .ModelParams .Solver ; 
end


function a =get .NumIterations (this )
a =this .Impl .NumIterations ; 
end

function a =get .IsSupportVector (this )
a =this .Impl .IsSupportVector ; 
end

function a =get .ShrinkagePeriod (this )
a =this .Impl .Shrinkage .Period ; 
end
end

methods (Hidden )
function this =RegressionSVM (X ,Y ,W ,modelParams ,dataSummary ,responseTransform )
ifnargin ~=6 ||ischar (W )
error (message ('stats:RegressionSVM:RegressionSVM:DoNotUseConstructor' )); 
end




internal .stats .checkSupportedNumeric ('X' ,X ,true ); 
this =this @classreg .learning .regr .FullRegressionModel (...
    X ,Y ,W ,modelParams ,dataSummary ,responseTransform ); 
this =this @classreg .learning .regr .CompactRegressionSVM (...
    dataSummary ,responseTransform ,[]); 




nanX =any (isnan (this .PrivX ),2 ); 
ifany (nanX )
this .PrivX (nanX ,:)=[]; 
this .PrivY (nanX )=[]; 
this .W (nanX )=[]; 
rowsused =this .DataSummary .RowsUsed ; 
ifisempty (rowsused )
rowsused =~nanX ; 
else
rowsused (rowsused )=~nanX ; 
end
this .DataSummary .RowsUsed =rowsused ; 
end
ifisempty (this .PrivX )
error (message ('stats:ClassificationSVM:ClassificationSVM:NoDataAfterNaNsRemoved' )); 
end



if~isempty (this .ModelParams .Alpha )
this .ModelParams .Alpha (nanX )=[]; 
end
ifany (nanX )

this .W =this .W /sum (this .W ); 
end

s =[]; 




ifisempty (this .ModelParams .Epsilon )
s =iqr (this .PrivY )/1.349 ; 
ifs ==0 
s =1 ; 
end
this .ModelParams .Epsilon =s /10 ; 
end






ifisempty (this .ModelParams .BoxConstraint )&&...
    strcmpi (this .ModelParams .KernelFunction ,'gaussian' )
ifisempty (s )
s =iqr (this .PrivY )/1.349 ; 
ifs ==0 
s =1 ; 
end
end
this .ModelParams .BoxConstraint =s ; 

if~isempty (this .ModelParams .Alpha )
ifany (abs (this .ModelParams .Alpha )>this .ModelParams .BoxConstraint )
maxAlpha =max (abs (this .ModelParams .Alpha )); 
this .ModelParams .Alpha =...
    this .ModelParams .Alpha *this .ModelParams .BoxConstraint /maxAlpha ; 
end
end
end

doclass =0 ; 

this .Impl =classreg .learning .impl .SVMImpl .make (...
    this .PrivX ,this .PrivY ,this .W ,...
    this .ModelParams .Alpha ,this .ModelParams .ClipAlphas ,...
    this .ModelParams .KernelFunction ,...
    this .ModelParams .KernelPolynomialOrder ,[],...
    this .ModelParams .KernelScale ,this .ModelParams .KernelOffset ,...
    this .ModelParams .StandardizeData ,...
    doclass ,...
    this .ModelParams .Solver ,...
    this .ModelParams .BoxConstraint ,...
    this .ModelParams .Nu ,...
    this .ModelParams .IterationLimit ,...
    this .ModelParams .KKTTolerance ,...
    this .ModelParams .GapTolerance ,...
    this .ModelParams .DeltaGradientTolerance ,...
    this .ModelParams .CacheSize ,...
    this .ModelParams .CachingMethod ,...
    this .ModelParams .ShrinkagePeriod ,...
    this .ModelParams .OutlierFraction ,...
    this .ModelParams .VerbosityLevel ,...
    this .ModelParams .NumPrint ,...
    this .ModelParams .Epsilon ,...
    this .CategoricalPredictors ,...
    this .VariableRange ,...
    this .ModelParams .RemoveDuplicates ); 
end
end

methods (Static ,Hidden )
function this =fit (X ,Y ,varargin )
temp =RegressionSVM .template (varargin {:}); 
this =fit (temp ,X ,Y ); 
end

function temp =template (varargin )
classreg .learning .FitTemplate .catchType (varargin {:}); 
temp =classreg .learning .FitTemplate .make ('SVM' ,'type' ,'regression' ,varargin {:}); 
end
end

methods (Access =protected )

function s =propsForDisp (this ,s )
s =propsForDisp @classreg .learning .regr .CompactRegressionSVM (this ,s ); 
s =propsForDisp @classreg .learning .regr .FullRegressionModel (this ,s ); 
ifisfield (s ,'SupportVectors' )
s =rmfield (s ,'SupportVectors' ); 
end
s .BoxConstraints =this .BoxConstraints ; 
s .ConvergenceInfo =this .ConvergenceInfo ; 
s .IsSupportVector =this .IsSupportVector ; 
s .Solver =this .Solver ; 
end
end

methods 
function cmp =compact (this ,varargin )









dataSummary =this .DataSummary ; 
dataSummary .RowsUsed =[]; 
cmp =classreg .learning .regr .CompactRegressionSVM (...
    dataSummary ,this .PrivResponseTransform ,...
    compact (this .Impl ,this .ModelParams .SaveSupportVectors )); 
end


function [varargout ]=resubPredict (this ,varargin )







[varargout {1 :nargout }]=...
    resubPredict @classreg .learning .regr .FullRegressionModel (this ,varargin {:}); 
end

function [varargout ]=resubLoss (this ,varargin )




























[varargout {1 :nargout }]=...
    resubLoss @classreg .learning .regr .FullRegressionModel (this ,varargin {:}); 
end

function this =resume (this ,numIter ,varargin )




















[varargin {:}]=convertStringsToChars (varargin {:}); 

args ={'verbose' ,'numprint' }; 
defs ={this .ModelParams .VerbosityLevel ,this .ModelParams .NumPrint }; 
[verbose ,nprint ,~]=...
    internal .stats .parseArgs (args ,defs ,varargin {:}); 

if~isnumeric (numIter )||~isscalar (numIter )...
    ||isnan (numIter )||isinf (numIter )||numIter <=0 
error (message ('stats:ClassificationSVM:resume:BadNumIter' )); 
else
numIter =ceil (numIter ); 
end
this .ModelParams .IterationLimit =...
    this .ModelParams .IterationLimit +numIter ; 

ifverbose <=0 
nprint =0 ; 
end

doclass =0 ; 

this .Impl =resume (this .Impl ,this .PrivX ,this .PrivY ,numIter ,doclass ,verbose ,nprint ); 
end

function partModel =crossval (this ,varargin )

























[varargin {:}]=convertStringsToChars (varargin {:}); 
idxBaseArg =find (ismember (varargin (1 :2 :end),...
    classreg .learning .FitTemplate .AllowedBaseFitObjectArgs )); 
if~isempty (idxBaseArg )
error (message ('stats:classreg:learning:regr:FullRegressionModel:crossval:NoBaseArgs' ,varargin {2 *idxBaseArg -1 })); 
end


modelParams =this .ModelParams ; 
modelParams .VerbosityLevel =0 ; 
temp =classreg .learning .FitTemplate .make (this .ModelParams .Method ,...
    'type' ,'regression' ,'responsetransform' ,this .PrivResponseTransform ,...
    'modelparams' ,modelParams ,'CrossVal' ,'on' ,varargin {:}); 
partModel =fit (temp ,this .X ,this .Y ,'Weights' ,this .W ,...
    'predictornames' ,this .PredictorNames ,'categoricalpredictors' ,this .CategoricalPredictors ,...
    'responsename' ,this .ResponseName ); 
end


end

methods (Static ,Hidden )
function [X ,Y ,W ,dataSummary ,responseTransform ]=prepareData (X ,Y ,varargin )
[X ,Y ,vrange ,wastable ,varargin ]=classreg .learning .internal .table2FitMatrix (X ,Y ,varargin {:}); 


args ={'responsetransform' }; 
defs ={[]}; 
[transformer ,~,crArgs ]=...
    internal .stats .parseArgs (args ,defs ,varargin {:},'VariableRange' ,vrange ,'TableInput' ,wastable ); 


if~isfloat (X )
error (message ('stats:classreg:learning:regr:FullRegressionModel:prepareData:BadXType' )); 
end
internal .stats .checkSupportedNumeric ('X' ,X ,true ); 

[X ,Y ,W ,dataSummary ]=...
    classreg .learning .FullClassificationRegressionModel .prepareDataCR (X ,Y ,crArgs {:}); 
if~dataSummary .TableInput 
X =classreg .learning .internal .encodeCategorical (X ,dataSummary .VariableRange ); 
end


if~isfloat (Y )||~isvector (Y )
error (message ('stats:classreg:learning:regr:FullRegressionModel:prepareData:BadYType' )); 
end
internal .stats .checkSupportedNumeric ('Y' ,Y ,true ); 
Y =Y (:); 

[X ,Y ,W ,dataSummary .RowsUsed ]=classreg .learning .regr .FullRegressionModel .removeNaNs (X ,Y ,W ,dataSummary .RowsUsed ); 

W =W /sum (W ); 


responseTransform =...
    classreg .learning .regr .FullRegressionModel .processResponseTransform (transformer ); 

end
end
end
