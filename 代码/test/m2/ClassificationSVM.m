classdef ClassificationSVM <...
    classreg .learning .classif .FullClassificationModel &...
    classreg .learning .classif .CompactClassificationSVM 






































































properties (SetAccess =protected ,GetAccess =public ,Dependent =true )






BoxConstraints ; 









CacheInfo ; 


































ConvergenceInfo ; 







Gradient ; 







IsSupportVector ; 






Nu ; 






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

function a =get .Gradient (this )
a =this .Impl .Gradient ; 
end

function a =get .Solver (this )
a =this .ModelParams .Solver ; 
end

function a =get .Nu (this )
ifnumel (this .ClassSummary .NonzeroProbClasses )==1 
a =this .ModelParams .Nu ; 
else
a =[]; 
end
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

methods (Static ,Hidden )
function temp =template (varargin )
classreg .learning .FitTemplate .catchType (varargin {:}); 
temp =classreg .learning .FitTemplate .make ('SVM' ,'type' ,'classification' ,varargin {:}); 
end

function this =fit (X ,Y ,varargin )
temp =ClassificationSVM .template (varargin {:}); 
this =fit (temp ,X ,Y ); 
end
end

methods (Hidden )
function this =ClassificationSVM (X ,Y ,W ,modelParams ,...
    dataSummary ,classSummary ,scoreTransform )

ifnargin ~=7 ||ischar (W )
error (message ('stats:ClassificationSVM:ClassificationSVM:DoNotUseConstructor' )); 
end


this =this @classreg .learning .classif .FullClassificationModel (...
    X ,Y ,W ,modelParams ,dataSummary ,classSummary ,scoreTransform ); 
this =this @classreg .learning .classif .CompactClassificationSVM (...
    dataSummary ,classSummary ,scoreTransform ,[],[]); 


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



nonzeroClassNames =this .ClassSummary .NonzeroProbClasses ; 
prior =this .ClassSummary .Prior ; 
K =numel (nonzeroClassNames ); 
cost =ones (K )-eye (K ); 


C =classreg .learning .internal .classCount (nonzeroClassNames ,this .PrivY ); 
WC =bsxfun (@times ,C ,this .W ); 
Wj =sum (WC ,1 ); 



[this .PrivX ,this .PrivY ,~,WC ,Wj ,prior ,cost ,nonzeroClassNames ,this .DataSummary .RowsUsed ]=...
    ClassificationTree .removeZeroPriorAndCost (...
    this .PrivX ,this .PrivY ,C ,WC ,Wj ,prior ,cost ,nonzeroClassNames ,this .DataSummary .RowsUsed ); 




prior =prior /sum (prior ); 
this .W =sum (bsxfun (@times ,WC ,prior ./Wj ),2 ); 


this .ClassSummary =...
    classreg .learning .classif .FullClassificationModel .makeClassSummary (...
    this .ClassSummary .ClassNames ,nonzeroClassNames ,prior ,cost ); 
end


gidx =grp2idx (this .PrivY ,this .ClassSummary .NonzeroProbClasses ); 
ifany (gidx ==2 )
doclass =2 ; 
gidx (gidx ==1 )=-1 ; 
gidx (gidx ==2 )=+1 ; 
else
doclass =1 ; 
end

this .Impl =classreg .learning .impl .SVMImpl .make (...
    this .PrivX ,gidx ,this .W ,...
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
    [],...
    this .CategoricalPredictors ,...
    this .VariableRange ,...
    this .ModelParams .RemoveDuplicates ); 
end
end

methods (Access =protected )
function s =propsForDisp (this ,s )
s =propsForDisp @classreg .learning .classif .FullClassificationModel (this ,s ); 
s =propsForDisp @classreg .learning .classif .CompactClassificationSVM (this ,s ); 
ifisfield (s ,'SupportVectors' )
s =rmfield (s ,'SupportVectors' ); 
end
ifisfield (s ,'SupportVectorLabels' )
s =rmfield (s ,'SupportVectorLabels' ); 
end
s .BoxConstraints =this .BoxConstraints ; 
s .ConvergenceInfo =this .ConvergenceInfo ; 
s .IsSupportVector =this .IsSupportVector ; 
s .Solver =this .Solver ; 
end
end

methods 
function cmp =compact (this )








dataSummary =this .DataSummary ; 
dataSummary .RowsUsed =[]; 
cmp =classreg .learning .classif .CompactClassificationSVM (...
    dataSummary ,this .ClassSummary ,...
    this .PrivScoreTransform ,this .PrivScoreType ,...
    compact (this .Impl ,this .ModelParams .SaveSupportVectors )); 
end

function [varargout ]=resubPredict (this ,varargin )









[varargout {1 :nargout }]=...
    resubPredict @classreg .learning .classif .FullClassificationModel (this ,varargin {:}); 
end

function [varargout ]=resubLoss (this ,varargin )
























[varargin {:}]=convertStringsToChars (varargin {:}); 
[varargout {1 :nargout }]=...
    resubLoss @classreg .learning .classif .FullClassificationModel (this ,varargin {:}); 
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

gidx =grp2idx (this .PrivY ,this .ClassSummary .NonzeroProbClasses ); 
ifany (gidx ==2 )
doclass =2 ; 
gidx (gidx ==1 )=-1 ; 
gidx (gidx ==2 )=+1 ; 
else
doclass =1 ; 
end

this .Impl =resume (this .Impl ,this .PrivX ,gidx ,numIter ,doclass ,verbose ,nprint ); 
end

function partModel =crossval (this ,varargin )























[varargin {:}]=convertStringsToChars (varargin {:}); 
idxBaseArg =find (ismember (lower (varargin (1 :2 :end)),...
    classreg .learning .FitTemplate .AllowedBaseFitObjectArgs )); 
if~isempty (idxBaseArg )
error (message ('stats:classreg:learning:classif:FullClassificationModel:crossval:NoBaseArgs' ,varargin {2 *idxBaseArg -1 })); 
end
modelParams =this .ModelParams ; 
modelParams .VerbosityLevel =0 ; 
temp =classreg .learning .FitTemplate .make (this .ModelParams .Method ,...
    'type' ,'classification' ,'scoretransform' ,this .PrivScoreTransform ,...
    'modelparams' ,modelParams ,'CrossVal' ,'on' ,varargin {:}); 
partModel =fit (temp ,this .X ,this .Y ,'Weights' ,this .W ,...
    'predictornames' ,this .DataSummary .PredictorNames ,...
    'responsename' ,this .ResponseName ,...
    'classnames' ,this .ClassNames ,'cost' ,this .Cost ,'prior' ,this .Prior ); 
partModel .ScoreType =this .ScoreType ; 
end

function [obj ,trans ]=fitPosterior (obj ,varargin )



































































[varargin {:}]=convertStringsToChars (varargin {:}); 
[obj ,trans ]=fitSVMPosterior (obj ,varargin {:}); 
end
end

methods (Static ,Hidden )
function [X ,Y ,W ,dataSummary ,classSummary ,scoreTransform ]=...
    prepareData (X ,Y ,varargin )
[X ,Y ,vrange ,wastable ,varargin ]=classreg .learning .internal .table2FitMatrix (X ,Y ,varargin {:}); 


args ={'classnames' ,'cost' ,'prior' ,'scoretransform' }; 
defs ={[],[],[],[]}; 
[userClassNames ,cost ,prior ,transformer ,~,crArgs ]=...
    internal .stats .parseArgs (args ,defs ,varargin {:},'VariableRange' ,vrange ,'TableInput' ,wastable ); 


allClassNames =levels (classreg .learning .internal .ClassLabel (Y )); 
ifisempty (allClassNames )
error (message ('stats:classreg:learning:classif:FullClassificationModel:prepareData:EmptyClassNames' )); 
end


if~isfloat (X )
error (message ('stats:ClassificationSVM:prepareData:BadXType' )); 
end

internal .stats .checkSupportedNumeric ('X' ,X ,true ,false ,false ,true ); 


[X ,Y ,W ,dataSummary ]=...
    classreg .learning .FullClassificationRegressionModel .prepareDataCR (...
    X ,classreg .learning .internal .ClassLabel (Y ),crArgs {:}); 
if~dataSummary .TableInput 
X =classreg .learning .internal .encodeCategorical (X ,dataSummary .VariableRange ); 
end


[X ,Y ,W ,userClassNames ,nonzeroClassNames ,dataSummary .RowsUsed ]=...
    classreg .learning .classif .FullClassificationModel .processClassNames (...
    X ,Y ,W ,userClassNames ,allClassNames ,dataSummary .RowsUsed ); 

internal .stats .checkSupportedNumeric ('Weights' ,W ,true ,false ,false ,true ); 




[~,loc ]=ismember (userClassNames ,nonzeroClassNames ); 
loc (loc ==0 )=[]; 
nonzeroClassNames =nonzeroClassNames (loc ); 


[X ,Y ,W ,dataSummary .RowsUsed ]=classreg .learning .classif .FullClassificationModel .removeMissingVals (X ,Y ,W ,dataSummary .RowsUsed ); 


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



ifnumel (nonzeroClassNames )>1 
prior =prior .*sum (cost ,2 )' ; 
cost =ones (2 )-eye (2 ); 
end




prior =prior /sum (prior ); 
W =sum (bsxfun (@times ,WC ,prior ./Wj ),2 ); 


classSummary =...
    classreg .learning .classif .FullClassificationModel .makeClassSummary (...
    userClassNames ,nonzeroClassNames ,prior ,cost ); 


K =numel (classSummary .NonzeroProbClasses ); 
ifK >2 
error (message ('stats:ClassificationSVM:prepareData:DoNotPassMoreThanTwoClasses' )); 
end


scoreTransform =...
    classreg .learning .classif .FullClassificationModel .processScoreTransform (transformer ); 
end
end
end
