classdef RegressionGP <...
    classreg .learning .regr .FullRegressionModel &...
    classreg .learning .regr .CompactRegressionGP 












































































properties (SetAccess =protected ,GetAccess =public ,Dependent =true )








IsActiveSetVector ; 









LogLikelihood ; 






















































ActiveSetHistory ; 



















BCDInformation ; 
end

methods 
function a =get .IsActiveSetVector (this )
a =this .Impl .ActiveSet ; 
end

function a =get .LogLikelihood (this )
a =this .Impl .LogLikelihoodHat ; 
end

function a =get .ActiveSetHistory (this )
a =this .Impl .ActiveSetHistory ; 
end

function a =get .BCDInformation (this )
a =this .Impl .BCDHistory ; 
end
end

methods (Hidden )
function this =RegressionGP (X ,Y ,W ,modelParams ,dataSummary ,responseTransform )















if~dataSummary .TableInput 
X =classreg .learning .internal .encodeCategorical (X ,dataSummary .VariableRange ); 
end


this =this @classreg .learning .regr .FullRegressionModel (...
    X ,Y ,W ,modelParams ,dataSummary ,responseTransform ); 

this =this @classreg .learning .regr .CompactRegressionGP (...
    dataSummary ,responseTransform ,[]); 



badrows =any (isnan (this .PrivX ),2 )|any (isinf (this .PrivX ),2 )|any (isnan (this .PrivY ),2 )|any (isinf (this .PrivY ),2 ); 
ifany (badrows )
this .PrivX (badrows ,:)=[]; 
this .PrivY (badrows )=[]; 
this .W (badrows )=[]; 
rowsused =this .DataSummary .RowsUsed ; 
ifisempty (rowsused )
rowsused =~badrows ; 
else
rowsused (rowsused )=~badrows ; 
end
this .DataSummary .RowsUsed =rowsused ; 
end
ifisempty (this .PrivX )
error (message ('stats:RegressionGP:RegressionGP:NoDataAfterNaNsRemoved' )); 
end







this .W =this .W /sum (this .W ); 


newN =size (this .X ,1 ); 
this .ModelParams .ActiveSetSize =min (this .ModelParams .ActiveSetSize ,newN ); 




if~isempty (this .ModelParams .ActiveSet )
this .ModelParams .ActiveSet (badrows )=[]; 
if~any (this .ModelParams .ActiveSet )
error (message ('stats:RegressionGP:RegressionGP:BadActiveSet' )); 
end
end


blockSizeBCD =this .ModelParams .Options .BlockSizeBCD ; 
blockSizeBCD =min (blockSizeBCD ,newN ); 


numGreedyBCD =this .ModelParams .Options .NumGreedyBCD ; 
numGreedyBCD =min (numGreedyBCD ,blockSizeBCD ); 


this .ModelParams .Options .BlockSizeBCD =blockSizeBCD ; 
this .ModelParams .Options .NumGreedyBCD =numGreedyBCD ; 


this .Impl =classreg .learning .impl .GPImpl .make (...
    this .PrivX ,this .PrivY ,...
    this .ModelParams .KernelFunction ,...
    this .ModelParams .KernelParameters ,...
    this .ModelParams .BasisFunction ,...
    this .ModelParams .Beta ,...
    this .ModelParams .Sigma ,...
    this .ModelParams .FitMethod ,...
    this .ModelParams .PredictMethod ,...
    this .ModelParams .ActiveSet ,...
    this .ModelParams .ActiveSetSize ,...
    this .ModelParams .ActiveSetMethod ,...
    this .ModelParams .Standardize ,...
    this .ModelParams .Verbose ,...
    this .ModelParams .CacheSize ,...
    this .ModelParams .Options ,...
    this .ModelParams .Optimizer ,...
    this .ModelParams .OptimizerOptions ,...
    this .ModelParams .ConstantKernelParameters ,...
    this .ModelParams .ConstantSigma ,...
    this .ModelParams .InitialStepSize ,...
    this .CategoricalPredictors ,...
    this .VariableRange ); 
end
end

methods (Static )
function this =fit (X ,Y ,varargin )
[varargin {:}]=convertStringsToChars (varargin {:}); 
temp =classreg .learning .FitTemplate .make ('GP' ,'type' ,'regression' ,varargin {:}); 
this =fit (temp ,X ,Y ); 
end
end

methods 
function cmp =compact (this ,varargin )














compactImpl =compact (this .Impl ); 

dataSummary =this .DataSummary ; 
dataSummary .RowsUsed =[]; 
cmp =classreg .learning .regr .CompactRegressionGP (...
    dataSummary ,this .PrivResponseTransform ,compactImpl ); 
end
end

methods 
function varargout =postFitStatistics (this )

























































import classreg.learning.modelparams.GPParams ; 
tf =strcmpi (this .PredictMethod ,GPParams .PredictMethodExact ); 
if~tf 
error (message ('stats:RegressionGP:RegressionGP:BadPredictMethodForPostFitStats' ,GPParams .PredictMethodExact )); 
end


[varargout {1 :nargout }]=postFitStatisticsExact (this .Impl ); 

end

function varargout =resubPredict (this ,varargin )






















































[varargout {1 :nargout }]=resubPredict @classreg .learning .regr .FullRegressionModel (this ,varargin {:}); 

end

function varargout =resubLoss (this ,varargin )
















































[varargout {1 :nargout }]=resubLoss @classreg .learning .regr .FullRegressionModel (this ,varargin {:}); 

end

function partModel =crossval (this ,varargin )
























ifthis .Impl .IsActiveSetSupplied 
error (message ('stats:RegressionGP:RegressionGP:NoCrossValForKnownActiveSet' )); 
end


this .ModelParams .Verbose =0 ; 


partModel =crossval @classreg .learning .regr .FullRegressionModel (this ,varargin {:}); 

end
end

methods (Access =protected )
function s =propsForDisp (this ,s )









s =propsForDisp @classreg .learning .regr .FullRegressionModel (this ,s ); 
s =propsForDisp @classreg .learning .regr .CompactRegressionGP (this ,s ); 


s .FitMethod =this .FitMethod ; 
s .ActiveSetMethod =this .ActiveSetMethod ; 
s .IsActiveSetVector =this .IsActiveSetVector ; 
s .LogLikelihood =this .LogLikelihood ; 
s .ActiveSetHistory =this .ActiveSetHistory ; 
s .BCDInformation =this .BCDInformation ; 

end
end

methods (Static ,Hidden )
function [X ,Y ,W ,dataSummary ,responseTransform ]=prepareData (X ,Y ,varargin )




[X ,Y ,W ,dataSummary ,responseTransform ]=classreg .learning .regr .FullRegressionModel .prepareData (X ,Y ,varargin {:}); 


internal .stats .checkSupportedNumeric ('X' ,X ,true ); 

end
end

end

