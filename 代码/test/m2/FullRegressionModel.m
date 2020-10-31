classdef FullRegressionModel <...
    classreg .learning .FullClassificationRegressionModel &classreg .learning .regr .RegressionModel 










properties (GetAccess =public ,SetAccess =protected ,Dependent =true )




Y ; 
end

methods 
function y =get .Y (this )
y =this .PrivY ; 
end
end

methods (Access =protected )
function this =FullRegressionModel (X ,Y ,W ,modelParams ,dataSummary ,responseTransform )
this =this @classreg .learning .FullClassificationRegressionModel (...
    dataSummary ,X ,Y ,W ,modelParams ); 
this =this @classreg .learning .regr .RegressionModel (dataSummary ,responseTransform ); 
this .ModelParams =fillIfNeeded (modelParams ,X ,Y ,W ,dataSummary ,[]); 
end

function s =propsForDisp (this ,s )
s =propsForDisp @classreg .learning .regr .RegressionModel (this ,s ); 
s =propsForDisp @classreg .learning .FullClassificationRegressionModel (this ,s ); 
end
end

methods 
function partModel =crossval (this ,varargin )























[varargin {:}]=convertStringsToChars (varargin {:}); 
idxBaseArg =find (ismember (varargin (1 :2 :end),...
    classreg .learning .FitTemplate .AllowedBaseFitObjectArgs )); 
if~isempty (idxBaseArg )
error (message ('stats:classreg:learning:regr:FullRegressionModel:crossval:NoBaseArgs' ,varargin {2 *idxBaseArg -1 })); 
end
temp =classreg .learning .FitTemplate .make (this .ModelParams .Method ,...
    'type' ,'regression' ,'responsetransform' ,this .PrivResponseTransform ,...
    'modelparams' ,this .ModelParams ,'CrossVal' ,'on' ,varargin {:}); 
partModel =fit (temp ,this .X ,this .Y ,'Weights' ,this .W ,...
    'predictornames' ,this .PredictorNames ,'categoricalpredictors' ,this .CategoricalPredictors ,...
    'responsename' ,this .ResponseName ); 
end

function [varargout ]=resubPredict (this ,varargin )
[varargin {:}]=convertStringsToChars (varargin {:}); 
classreg .learning .FullClassificationRegressionModel .catchWeights (varargin {:}); 
[varargout {1 :nargout }]=predict (this ,this .X ,varargin {:}); 
end

function [varargout ]=resubLoss (this ,varargin )
[varargin {:}]=convertStringsToChars (varargin {:}); 
classreg .learning .FullClassificationRegressionModel .catchWeights (varargin {:}); 
[varargout {1 :nargout }]=...
    loss (this ,this .X ,this .Y ,'Weights' ,this .W ,varargin {:}); 
end

function [AX ]=plotPartialDependence (this ,features ,varargin )






























































































narginchk (2 ,13 ); 
features =convertStringsToChars (features ); 
[varargin {:}]=convertStringsToChars (varargin {:}); 




p =inputParser ; 
addRequired (p ,'Model' ); 
addRequired (p ,'Var' ); 
addOptional (p ,'Data' ,this .X ); 
addParameter (p ,'Conditional' ,{'none' ,'absolute' ,'centered' }); 
addParameter (p ,'NumObservationsToSample' ,0 ); 
addParameter (p ,'ParentAxisHandle' ,[]); 
addParameter (p ,'QueryPoints' ,[]); 
addParameter (p ,'UseParallel' ,false ); 
parse (p ,this ,features ,varargin {:}); 
X =p .Results .Data ; 



if(nargin >2 &&~ischar (varargin {1 }))

varargin =varargin (2 :end); 
end


ax =plotPartialDependence @classreg .learning .regr .RegressionModel ...
    (this ,features ,X ,varargin {:}); 
if(nargout >0 )
AX =ax ; 
end
end
end

methods (Static ,Hidden )
function [X ,Y ,W ,dataSummary ,responseTransform ]=prepareData (X ,Y ,varargin )
[X ,Y ,vrange ,wastable ,varargin ]=classreg .learning .internal .table2FitMatrix (X ,Y ,varargin {:}); 


args ={'responsetransform' }; 
defs ={[]}; 
[transformer ,~,crArgs ]=...
    internal .stats .parseArgs (args ,defs ,varargin {:}); 


[X ,Y ,W ,dataSummary ]=...
    classreg .learning .FullClassificationRegressionModel .prepareDataCR (...
    X ,Y ,crArgs {:},'VariableRange' ,vrange ,'TableInput' ,wastable ); 
if~isfloat (X )
error (message ('stats:classreg:learning:regr:FullRegressionModel:prepareData:BadXType' )); 
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

function [X ,Y ,W ,rowsused ]=removeNaNs (X ,Y ,W ,rowsused ,obsInRows )
t =isnan (Y ); 
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
error (message ('stats:classreg:learning:regr:FullRegressionModel:prepareData:NoGoodYData' )); 
end
end

function responseTransform =processResponseTransform (transformer )
ifisempty (transformer )
responseTransform =@classreg .learning .transform .identity ; 
elseifischar (transformer )
ifstrcmpi (transformer ,'none' )
responseTransform =@classreg .learning .transform .identity ; 
else
responseTransform =str2func (['classreg.learning.transform.' ,transformer (:)' ]); 
end
else
if~isa (transformer ,'function_handle' )
error (message ('stats:classreg:learning:regr:FullRegressionModel:prepareData:BadResponseTransformation' )); 
end
responseTransform =transformer ; 
end

end
end
end
