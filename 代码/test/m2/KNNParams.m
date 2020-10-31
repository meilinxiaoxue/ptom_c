
classdef KNNParams <classreg .learning .modelparams .ModelParams 























properties (Constant =true ,GetAccess =private ,Hidden =true )


BuiltInDistList ={'euclidean' ; 'cityblock' ; 'chebychev' ; 'minkowski' ; ...
    'mahalanobis' ; 'seuclidean' ; 'cosine' ; 'correlation' ; ...
    'spearman' ; 'hamming' ; 'jaccard' }; 
end

properties 

NumNeighbors =[]; 
NSMethod ='' ; 
Distance ='' ; 
BucketSize =[]; 
IncludeTies =[]; 
DistanceWeight =[]; 
BreakTies =[]; 
Exponent =[]; 
Cov =[]; 
Scale =[]; 
StandardizeData =[]; 
end

methods (Access =protected )
function this =KNNParams (k ,NSMethod ,Distance ,BucketSize ,IncludeTies ,...
    DistanceWeight ,BreakTies ,P ,Cov ,Scale ,StandardizeData )
this =this @classreg .learning .modelparams .ModelParams ('KNN' ,'classification' ); 
this .NumNeighbors =k ; 
this .NSMethod =NSMethod ; 
this .Distance =Distance ; 
this .BucketSize =BucketSize ; 
this .IncludeTies =IncludeTies ; 
this .DistanceWeight =DistanceWeight ; 
this .BreakTies =BreakTies ; 
this .Exponent =P ; 
this .Cov =Cov ; 
this .Scale =Scale ; 
this .StandardizeData =StandardizeData ; 
end
end

methods (Static ,Hidden )
function [holder ,extraArgs ]=make (type ,varargin )

args ={'numneighbors' ,'nsmethod' ,'distance' ,'exponent' ,'cov' ...
    ,'scale' ,'bucketsize' ,'includeties' ,'distanceweight' ...
    ,'BreakTies' ,'StandardizeData' }; 
defs ={[],'' ,'' ,[],[]...
    ,[],'' ,[],[],[]}; 
[k ,nsmethod ,distance ,minExp ,cov ,scale ,bucketSize ,includeTies ,...
    distWeight ,breakTies ,standardizeData ,~,extraArgs ]=...
    internal .stats .parseArgs (args ,defs ,varargin {:}); 









sum =~isempty (minExp )+~isempty (cov )+~isempty (scale ); 
ifsum >1 
error (message ('stats:classreg:learning:modelparams:KNNParams:make:ConflictDistParams' )); 
end

if~isempty (k )
if~isnumeric (k )||~isscalar (k )||k <=0 ||round (k )~=k 
error (message ('stats:classreg:learning:modelparams:KNNParams:make:BadNumNeighbors' )); 
end
end

if~isempty (includeTies )
if~islogical (includeTies )||~isscalar (includeTies )
error (message ('stats:classreg:learning:modelparams:KNNParams:make:BadIncludeTies' )); 
end
end


if~isempty (distWeight )
ifischar (distWeight )
wgtList ={'equal' ,'inverse' ,'squaredinverse' }; 
i =find (strncmpi (distWeight ,wgtList ,length (distWeight ))); 
ifisempty (i )
error (message ('stats:classreg:learning:modelparams:KNNParams:make:BadDistanceWeight' )); 
else
distWeight =wgtList {i }; 
end

elseif~isa (distWeight ,'function_handle' )
error (message ('stats:classreg:learning:modelparams:KNNParams:make:BadDistanceWeight' )); 
end
end


if~isempty (breakTies )
breakTies =internal .stats .getParamVal ...
    (breakTies ,{'smallest' ,'nearest' ,'random' },'BreakTies' ); 
end




holder =classreg .learning .modelparams .KNNParams (k ,nsmethod ,...
    distance ,bucketSize ,includeTies ,...
    distWeight ,breakTies ,minExp ,cov ,scale ,standardizeData ); 
end

function standardizeData =checkStandardizeDataArg (standardizeData ,...
    CategoricalPredictors ,PredictorNames ,distance ,mpCov ,mpScale )




standardizeData =internal .stats .parseOnOff (standardizeData ,'standardizeData' ); 


ifstandardizeData &&allPredictorsCategorical (CategoricalPredictors ,PredictorNames )
error (message ('stats:classreg:learning:modelparams:KNNParams:checkStandardizeDataArg:StdizeCategoricalPre' )); 
end


ifstandardizeData &&...
    (strncmpi (distance ,'mahalanobis' ,3 )&&~isempty (mpCov )||...
    strncmpi (distance ,'seuclidean' ,3 )&&~isempty (mpScale ))
error (message ('stats:classreg:learning:modelparams:KNNParams:checkStandardizeDataArg:DistStdPrecedence' )); 
end
end

function this =fromStruct (mpstruct )


mp =mpstruct ; 
ifmp .CustomDistanceWeight 
mp .DistanceWeight =str2func (mp .DistanceWeight ); 
end

this =classreg .learning .modelparams .KNNParams .make ([],'numneighbors' ,mp .NumNeighbors ,...
    'nsmethod' ,mp .NSMethod ,'distance' ,mp .Distance ,'bucketsize' ,mp .BucketSize ,'includeties' ,mp .IncludeTies ,...
    'exponent' ,mp .Exponent ,'cov' ,mp .Cov ,'scale' ,mp .Scale ,'distanceweight' ,mp .DistanceWeight ,...
    'breakties' ,mp .BreakTies ,'standardizedata' ,mp .StandardizeData ); 

end
end

methods (Hidden )
function this =fillDefaultParams (this ,X ,Y ,W ,dataSummary ,classSummary )

ifisempty (this .NumNeighbors )
this .NumNeighbors =1 ; 
end

[~,nDims ]=size (X ); 
ifisempty (this .Distance )
ifisempty (dataSummary .CategoricalPredictors )
this .Distance ='euclidean' ; 
else
this .Distance ='hamming' ; 

end
end

ifisempty (this .BucketSize )
this .BucketSize =50 ; 
end

ifisempty (this .IncludeTies )
this .IncludeTies =false ; 
end

ifisempty (this .DistanceWeight )
this .DistanceWeight ='equal' ; 
end
ifisempty (this .BreakTies )
this .BreakTies ='smallest' ; 
end

ifisempty (this .NSMethod )

if~isa (this .Distance ,'function_handle' )
distList =classreg .learning .modelparams .KNNParams .BuiltInDistList ; 
[~,i ]=internal .stats .getParamVal (this .Distance ,distList ,'Distance' ); 
end





ifischar (this .Distance )&&i <=4 &&nDims <=10 &&~issparse (X )
this .NSMethod ='kdtree' ; 
else
this .NSMethod ='exhaustive' ; 
end
end

ifisempty (this .StandardizeData )
this .StandardizeData =false ; 
else



this .StandardizeData =classreg .learning .modelparams .KNNParams .checkStandardizeDataArg (...
    this .StandardizeData ,dataSummary .CategoricalPredictors ,...
    dataSummary .PredictorNames ,this .Distance ,this .Cov ,this .Scale ); 
end


ifstrncmpi (this .Distance ,'minkowski' ,3 )&&isempty (this .Exponent )
this .Exponent =2 ; 
end
end

function s =toStruct (this )
warnState =warning ('query' ,'all' ); 
warning ('off' ,'MATLAB:structOnObject' ); 
cleanupObj =onCleanup (@()warning (warnState )); 
s =struct (this ); 
s .CustomDistanceWeight =false ; 



if~isa (this .Distance ,'char' )
fh =functions (this .Distance ); 

ifstrcmpi (fh .type ,'anonymous' )
error (message ('stats:classreg:learning:coderutils:classifToStruct:AnonymousFunctionsNotSupported' ,'Distance' )); 
end
s .Distance =func2str (s .Distance ); 
end
if~isa (this .DistanceWeight ,'char' )
fh =functions (this .DistanceWeight ); 

ifstrcmpi (fh .type ,'anonymous' )
error (message ('stats:classreg:learning:coderutils:classifToStruct:AnonymousFunctionsNotSupported' ,'DistanceWeight' )); 
end
s .DistanceWeight =func2str (s .DistanceWeight ); 
s .CustomDistanceWeight =true ; 
end



s =rmfield (s ,{'BuiltInDistList' ,'Version' }); 

end

end
end

function bool =allPredictorsCategorical (CategoricalPredictors ,PredictorNames )



ifiscell (PredictorNames )
bool =isequal (unique (CategoricalPredictors ),1 :numel (PredictorNames )); 
else
bool =isequal (unique (CategoricalPredictors ),1 :PredictorNames ); 
end
end
