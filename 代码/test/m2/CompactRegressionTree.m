classdef CompactRegressionTree <classreg .learning .regr .RegressionModel 












































properties (GetAccess =public ,SetAccess =protected ,Dependent =true ,Hidden =true )
CatSplit ; 
CutVar ; 
IsBranch ; 
NodeErr ; 
NodeProb ; 
SurrCutCategories ; 
SurrCutFlip ; 
SurrCutPoint ; 
SurrCutType ; 
SurrCutVar ; 
SurrVarAssoc ; 
end

properties (GetAccess =public ,SetAccess =protected ,Dependent =true )












CategoricalSplit ; 







Children ; 











CutCategories ; 










CutPoint ; 












CutType ; 







CutPredictor ; 






IsBranchNode ; 







NodeError ; 









NodeMean ; 










NodeProbability ; 









NodeRisk ; 








NodeSize ; 






NumNodes ; 







Parent ; 









PruneAlpha ; 








PruneList ; 




















SurrogateCutCategories ; 























SurrogateCutFlip ; 






















SurrogateCutPoint ; 



















SurrogateCutType ; 














SurrogateCutPredictor ; 

















SurrogatePredictorAssociation ; 
end

properties (GetAccess =public ,SetAccess =protected ,Dependent =true ,Hidden =true )





Risk ; 
end

methods 
function a =get .CatSplit (this )
a =this .Impl .CatSplit ; 
end

function a =get .CategoricalSplit (this )
a =this .Impl .CatSplit ; 
end

function a =get .Children (this )
a =this .Impl .Children ; 
end

function a =get .CutCategories (this )
a =this .Impl .CutCategories ; 
end

function a =get .CutPoint (this )
a =this .Impl .CutPoint ; 
end

function a =get .CutType (this )
a =this .Impl .CutType ; 
end

function a =get .CutVar (this )
varidx =this .Impl .CutVar ; 
a =repmat ({'' },numel (varidx ),1 ); 
useidx =varidx >0 ; 
a (useidx )=this .PredictorNames (varidx (useidx )); 
end

function a =get .CutPredictor (this )
a =this .CutVar ; 
end

function a =get .IsBranch (this )
a =this .Impl .IsBranch ; 
end

function a =get .IsBranchNode (this )
a =this .Impl .IsBranch ; 
end

function a =get .NodeMean (this )
a =this .Impl .NodeMean ; 
end

function a =get .NodeErr (this )
a =this .Impl .NodeRisk ./this .Impl .NodeProb ; 
end

function a =get .NodeError (this )
a =this .NodeErr ; 
end

function a =get .NodeProb (this )
a =this .Impl .NodeProb ; 
end

function a =get .NodeProbability (this )
a =this .Impl .NodeProb ; 
end

function a =get .NodeRisk (this )
a =this .Impl .NodeRisk ; 
end

function a =get .NodeSize (this )
a =this .Impl .NodeSize ; 
end

function a =get .NumNodes (this )
a =size (this .Impl .NodeSize ,1 ); 
end

function a =get .Parent (this )
a =this .Impl .Parent ; 
end

function a =get .PruneAlpha (this )
a =this .Impl .PruneAlpha ; 
end

function a =get .PruneList (this )
a =this .Impl .PruneList ; 
end

function a =get .Risk (this )
warning (message ('stats:classreg:learning:regr:CompactRegressionTree:get:Risk' )); 
a =this .NodeRisk ; 
end

function a =get .SurrCutCategories (this )
a =this .Impl .SurrCutCategories ; 
end

function a =get .SurrogateCutCategories (this )
a =this .Impl .SurrCutCategories ; 
end

function a =get .SurrCutFlip (this )
a =this .Impl .SurrCutFlip ; 
end

function a =get .SurrogateCutFlip (this )
a =this .Impl .SurrCutFlip ; 
end

function a =get .SurrCutPoint (this )
a =this .Impl .SurrCutPoint ; 
end

function a =get .SurrogateCutPoint (this )
a =this .Impl .SurrCutPoint ; 
end

function a =get .SurrCutType (this )
a =this .Impl .SurrCutType ; 
end

function a =get .SurrogateCutType (this )
a =this .Impl .SurrCutType ; 
end

function a =get .SurrCutVar (this )
varnames =this .PredictorNames ; 
surrcutvar =this .Impl .SurrCutVar ; 
N =numel (surrcutvar ); 
a =repmat ({{}},N ,1 ); 
forn =1 :N 
cutvar =surrcutvar {n }; 
if~isempty (cutvar )
a {n }=varnames (cutvar ); 
end
end
end

function a =get .SurrogateCutPredictor (this )
a =this .SurrCutVar ; 
end

function a =get .SurrVarAssoc (this )
a =this .Impl .SurrVarAssoc ; 
end

function a =get .SurrogatePredictorAssociation (this )
a =this .Impl .SurrVarAssoc ; 
end
end

methods (Access =public ,Hidden =true )
function this =CompactRegressionTree (dataSummary ,responseTransform )
this =this @classreg .learning .regr .RegressionModel (dataSummary ,responseTransform ); 
end

function [varargout ]=meanSurrVarAssoc (this ,varargin )
[varargout {1 :nargout }]=meanSurrVarAssoc (this .Impl ,varargin {:}); 
end
end

methods (Access =protected )
function r =response (~,~,varargin )
r =[]; 
end

function s =propsForDisp (this ,s )
s =propsForDisp @classreg .learning .regr .RegressionModel (this ,s ); 
end
end

methods 
function [Yfit ,node ]=predict (this ,X ,varargin )
























[varargin {:}]=convertStringsToChars (varargin {:}); 

adapter =classreg .learning .internal .makeClassificationModelAdapter (this ,X ); 
if~isempty (adapter )
[Yfit ,node ]=predict (adapter ,X ,varargin {:}); 
return ; 
end


subtrees =internal .stats .parseArgs ({'subtrees' },{0 },varargin {:}); 


vrange =getvrange (this ); 
X =classreg .learning .internal .table2PredictMatrix (X ,[],[],...
    vrange ,this .CategoricalPredictors ,getOptionalPredictorNames (this )); 


ifisempty (X )
Yfit =predictEmptyX (this ,X ); 
node =NaN (0 ,1 ); 
return ; 
end

node =findNode (this .Impl ,X ,this .DataSummary .CategoricalPredictors ,subtrees ); 


T =size (node ,2 ); 


N =size (node ,1 ); 
Yfit =NaN (N ,T ); 
fort =1 :T 
Yfit (:,t )=this .Impl .NodeMean (node (:,t )); 
end
Yfit =this .PrivResponseTransform (Yfit ); 
end

function [err ,seerr ,nleaf ,bestlevel ]=loss (this ,X ,varargin )














































[varargin {:}]=convertStringsToChars (varargin {:}); 
adapter =classreg .learning .internal .makeClassificationModelAdapter (this ,X ,varargin {:}); 
if~isempty (adapter )
ifnargout >1 
error (message ('stats:classreg:learning:regr:CompactRegressionTree:loss:TooManyOutputs' )); 
end
err =loss (adapter ,X ,varargin {:}); 
return 
end

[Y ,varargin ]=classreg .learning .internal .inferResponse (this .ResponseName ,X ,varargin {:}); 


N =size (X ,1 ); 
args ={'lossfun' ,'subtrees' ,'weights' ,'treesize' }; 
defs ={@classreg .learning .loss .mse ,0 ,ones (N ,1 ),'se' }; 
[funloss ,subtrees ,W ,treesize ]=...
    internal .stats .parseArgs (args ,defs ,varargin {:}); 


subtrees =processSubtrees (this .Impl ,subtrees ); 


if~ischar (treesize )||~(treesize (1 )=='s' ||treesize (1 )=='m' )
error (message ('stats:classreg:learning:regr:CompactRegressionTree:loss:BadTreeSize' )); 
end


funloss =classreg .learning .internal .lossCheck (funloss ,'regression' ); 


[X ,Y ,W ]=prepareDataForLoss (this ,X ,Y ,W ,this .VariableRange ,false ); 


Yfit =predict (this ,X ,'subtrees' ,subtrees ); 


[err ,seerr ]=...
    classreg .learning .regr .CompactRegressionTree .lossWithSE (...
    Y ,Yfit ,W ,funloss ); 


ifnargout >2 
nleaf =countLeaves (this .Impl ,subtrees ); 
end


ifnargout >3 
[minerr ,minloc ]=min (err ); 
ifisequal (treesize (1 ),'m' )
cutoff =minerr *(1 +100 *eps ); 
else
cutoff =minerr +seerr (minloc ); 
end
bestlevel =subtrees (find (err <=cutoff ,1 ,'last' )); 
end
end

function view (this ,varargin )











[varargin {:}]=convertStringsToChars (varargin {:}); 
vrange =getvrange (this ); 
view (this .Impl ,{},this .Impl .NodeMean ,this .PredictorNames ,vrange ,...
    '/stats/compactregressiontree.view.html' ,varargin {:}); 
end

function [varargout ]=surrogateAssociation (this ,varargin )


















[varargout {1 :nargout }]=meanSurrVarAssoc (this .Impl ,varargin {:}); 
end

function imp =predictorImportance (this ,varargin )
















imp =predictorImportance (this .Impl ,varargin {:}); 
end
end
methods (Hidden )
function s =toStruct (this )


warnState =warning ('query' ,'all' ); 
warning ('off' ,'MATLAB:structOnObject' ); 
cleanupObj =onCleanup (@()warning (warnState )); 

fh =functions (this .PrivResponseTransform ); 
ifstrcmpi (fh .type ,'anonymous' )
error (message ('stats:classreg:learning:coderutils:classifToStruct:AnonymousFunctionsNotSupported' ,'Response Transform' )); 
end


s =classreg .learning .coderutils .regrToStruct (this ); 



try
classreg .learning .internal .convertScoreTransform (this .PrivResponseTransform ,'handle' ,1 ); 
catch me 
rethrow (me ); 
end

s .ResponseTransformFull =s .ResponseTransform ; 
responsetransformfull =strsplit (s .ResponseTransform ,'.' ); 
responsetransform =responsetransformfull {end}; 
s .ResponseTransform =responsetransform ; 



transFcn =['classreg.learning.transform.' ,s .ResponseTransform ]; 
transFcnCG =['classreg.learning.coder.transform.' ,s .ResponseTransform ]; 
ifisempty (which (transFcn ))||isempty (which (transFcnCG ))
s .CustomResponseTransform =true ; 
else
s .CustomResponseTransform =false ; 
end



s .FromStructFcn ='classreg.learning.regr.CompactRegressionTree.fromStruct' ; 


impl =struct (this .Impl ); 


if~isempty (impl .SurrCutCategories )||...
    ~isempty (impl .SurrCutFlip )||...
    ~isempty (impl .SurrCutPoint )||...
    ~isempty (impl .SurrCutVar )||...
    ~isempty (impl .SurrSplitGain )||...
    ~isempty (impl .SurrVarAssoc )||...
    ~isempty (impl .SurrCutType )
error (message ('stats:classreg:learning:coderutils:treeToStruct:SurrogateSplitsNotSupported' )); 
end
impl =rmfield (impl ,{'SurrCutCategories' ,'SurrCutFlip' ,'SurrCutPoint' ,'SurrCutVar' ...
    ,'SurrSplitGain' ,'SurrVarAssoc' ,'SurrCutType' }); 

impl =rmfield (impl ,'CutCategories' ); 


impl =rmfield (impl ,{'CatSplit' ,'CutType' }); 


impl =rmfield (impl ,{'Curvature' ,'Interaction' ,'ClassNames' }); 


NanCutPoints =isnan (impl .CutPoint ); 
InfCutPoints =isinf (impl .CutPoint ); 
impl .CutPoint (NanCutPoints )=0 ; 
impl .CutPoint (InfCutPoints )=0 ; 
s .NanCutPoints =NanCutPoints ; 
s .InfCutPoints =InfCutPoints ; 
s .Impl =impl ; 
end
end
methods (Static ,Hidden )
function obj =fromStruct (s )


s .ResponseTransform =s .ResponseTransformFull ; 

s =classreg .learning .coderutils .structToRegr (s ); 
s .Impl .ClassNames ={}; 

impl =classreg .learning .impl .TreeImpl .fromStruct (s .Impl ); 
impl .CutPoint (s .NanCutPoints )=NaN ; 
impl .CutPoint (s .InfCutPoints )=Inf ; 

obj =classreg .learning .regr .CompactRegressionTree (...
    s .DataSummary ,s .ResponseTransform ); 


obj .Impl =impl ; 
end


function [l ,sel ]=lossWithSE (Y ,Yfit ,W ,funloss )


ifisempty (Y )
l =NaN ; 
sel =NaN ; 
return ; 
end


[N ,T ]=size (Yfit ); 


l =zeros (T ,1 ); 
sel =zeros (T ,1 ); 
lossPerObs =zeros (N ,1 ); 


W =W /sum (W ); 


fort =1 :T 

forn =1 :N 
lossPerObs (n )=funloss (Y (n ),Yfit (n ,t ),W (n )); 
end


l (t )=sum (W .*lossPerObs ); 


varl =sum (W .*(lossPerObs -l (t )).^2 ); 
ifvarl >0 
sel (t )=sqrt (varl )/N ; 
end
end
end

function this =loadobj (obj )

ifisa (obj .Impl ,'classreg.learning.impl.CompactTreeImpl' )
obj .Impl =classreg .learning .impl .TreeImpl .makeFromClassregtree (obj .Impl .Tree ); 
end
this =obj ; 
end
end
methods (Hidden ,Static )
function name =matlabCodegenRedirect (~)
name ='classreg.learning.coder.regr.CompactRegressionTree' ; 
end
end
end
