classdef CompactClassificationTree <classreg .learning .classif .ClassificationModel 




















































properties (GetAccess =public ,SetAccess =protected ,Dependent =true ,Hidden =true )
CatSplit ; 
ClassProb ; 
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









ClassCount ; 









ClassProbability ; 











CutCategories ; 










CutPoint ; 












CutType ; 







CutPredictor ; 






IsBranchNode ; 








NodeClass ; 







NodeError ; 










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

function a =get .ClassCount (this )
K =length (this .ClassSummary .ClassNames ); 
N =size (this .Impl .Children ,1 ); 
a =zeros (N ,K ); 
[~,pos ]=ismember (this .ClassSummary .NonzeroProbClasses ,...
    this .ClassSummary .ClassNames ); 
a (:,pos )=this .Impl .ClassCount ; 
end

function a =get .ClassProb (this )
K =length (this .ClassSummary .ClassNames ); 
N =size (this .Impl .Children ,1 ); 
a =zeros (N ,K ); 
[~,pos ]=ismember (this .ClassSummary .NonzeroProbClasses ,...
    this .ClassSummary .ClassNames ); 
a (:,pos )=this .Impl .ClassProb ; 
end

function a =get .ClassProbability (this )
a =this .ClassProb ; 
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

function a =get .NodeClass (this )
cls =nodeClassNum (this ); 
a =cellstr (this .ClassSummary .ClassNames (cls )); 
end

function a =get .NodeErr (this )
classProb =this .Impl .ClassProb ; 
classCost =this .Cost ; 
cost =classProb *classCost ; 
a =min (cost ,[],2 ); 
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
warning (message ('stats:classreg:learning:classif:CompactClassificationTree:get:Risk' )); 
ifall (this .NodeRisk ==0 )
a =this .NodeProb .*this .NodeErr ; 
else
a =this .NodeRisk ; 
end
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
function this =CompactClassificationTree (...
    dataSummary ,classSummary ,scoreTransform ,scoreType )
this =this @classreg .learning .classif .ClassificationModel (...
    dataSummary ,classSummary ,scoreTransform ,scoreType ); 
end

function [varargout ]=meanSurrVarAssoc (this ,varargin )
[varargout {1 :nargout }]=meanSurrVarAssoc (this .Impl ,varargin {:}); 
end
end

methods (Access =protected )
function s =score (this ,X ,varargin )%#ok<INUSD> 
s =[]; 
end

function s =propsForDisp (this ,s )
s =propsForDisp @classreg .learning .classif .ClassificationModel (this ,s ); 
end

function cls =nodeClassNum (this )
[~,cls ]=min (this .ClassProb *this .Cost ,[],2 ); 
end
end

methods (Hidden )
function s =toStruct (this )


warnState =warning ('query' ,'all' ); 
warning ('off' ,'MATLAB:structOnObject' ); 
cleanupObj =onCleanup (@()warning (warnState )); 
fh =functions (this .PrivScoreTransform ); 
ifstrcmpi (fh .type ,'anonymous' )
error (message ('stats:classreg:learning:coderutils:classifToStruct:AnonymousFunctionsNotSupported' ,'Score Transform' )); 
end

fh =functions (this .DefaultLoss ); 
ifstrcmpi (fh .type ,'anonymous' )
error (message ('stats:classreg:learning:coderutils:classifToStruct:AnonymousFunctionsNotSupported' ,'Loss' )); 
end

try
classreg .learning .internal .convertScoreTransform (this .PrivScoreTransform ,'handle' ,numel (this .ClassSummary .ClassNames )); 
catch me 
rethrow (me ); 
end


s =classreg .learning .coderutils .classifToStruct (this ); 


ifischar (s .ClassSummary .ClassNames )&&s .ClassSummary .ClassNamesType ==1 
classes =cellstr (s .ClassSummary .ClassNames ); 
s .ClassSummary .CharClassNamesLength =cellfun (@length ,classes ); 
else
s .ClassSummary .CharClassNamesLength =s .ClassSummary .ClassNamesLength ; 
end

s .ScoreTransformFull =s .ScoreTransform ; 
scoretransformfull =strsplit (s .ScoreTransform ,'.' ); 
scoretransform =scoretransformfull {end}; 
s .ScoreTransform =scoretransform ; 



transFcn =['classreg.learning.transform.' ,s .ScoreTransform ]; 
transFcnCG =['classreg.learning.coder.transform.' ,s .ScoreTransform ]; 
ifisempty (which (transFcn ))||isempty (which (transFcnCG ))
s .CustomScoreTransform =true ; 
else
s .CustomScoreTransform =false ; 
end

s .DefaultLossFull =s .DefaultLoss ; 
defaultlossfull =strsplit (s .DefaultLoss ,'.' ); 
defaultloss =defaultlossfull {end}; 
s .DefaultLoss =defaultloss ; 

try
classreg .learning .internal .lossCheck (s .DefaultLoss ,'classification' ); 
catch me 
rethrow (me ); 
end


s .FromStructFcn ='classreg.learning.classif.CompactClassificationTree.fromStruct' ; 


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


classnames =impl .ClassNames ; 
ifisempty (classnames )
classnames =[]; 
classnamesType ='' ; 
classnamesLength =0 ; 
elseifisnumeric (classnames )||islogical (classnames )||ischar (classnames )
classnamesType ='plain' ; 
classnamesLength =[]; 
else
classnamesType ='cellstr' ; 
classnamesLength =cellfun (@length ,classnames ); 
classnames =char (classnames ); 
end

impl .ClassNames =classnames ; 
impl .ClassNamesType =classnamesType ; 
impl .ClassNamesLength =classnamesLength ; 

impl =rmfield (impl ,'CutCategories' ); 


impl =rmfield (impl ,{'CatSplit' ,'CutType' }); 


impl =rmfield (impl ,{'Curvature' ,'Interaction' }); 


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


s .ScoreTransform =s .ScoreTransformFull ; 
s .DefaultLoss =s .DefaultLossFull ; 

s =classreg .learning .coderutils .structToClassif (s ); 


impl =classreg .learning .impl .TreeImpl .fromStruct (s .Impl ); 
impl .CutPoint (s .NanCutPoints )=NaN ; 
impl .CutPoint (s .InfCutPoints )=Inf ; 


obj =classreg .learning .classif .CompactClassificationTree (...
    s .DataSummary ,s .ClassSummary ,s .ScoreTransform ,s .ScoreType ); 


obj .Impl =impl ; 
end
function obj =make (s )


s .ScoreTransform =s .ScoreTransformFull ; 
s .DefaultLoss =s .DefaultLossFull ; 

s =rmfield (s ,'FromStructFcn' ); 


dataSummary =s .DataSummary ; 

dataSummary =rmfield (dataSummary ,'NumPredictors' ); 

s .DataSummary =dataSummary ; 


classSummary =s .ClassSummary ; 
classSummary .ClassNames =...
    classreg .learning .internal .ClassLabel (classSummary .ClassNames ); 
classSummary .NonzeroProbClasses =...
    classreg .learning .internal .ClassLabel (classSummary .NonzeroProbClasses ); 
s .ClassSummary =classSummary ; 


s .ScoreTransform =str2func (s .ScoreTransform ); 


ifisfield (s ,'DefaultLoss' )
s .DefaultLoss =str2func (s .DefaultLoss ); 
end


ifisfield (s ,'LabelPredictor' )
s .LabelPredictor =str2func (s .LabelPredictor ); 
end



impl =classreg .learning .impl .TreeImpl .fromStruct (s .Impl ); 
impl .CutPoint (s .NanCutPoints )=NaN ; 
impl .CutPoint (s .InfCutPoints )=Inf ; 
impl .CutCategories =s .Impl .CutCategories ; 


obj =classreg .learning .classif .CompactClassificationTree (...
    s .DataSummary ,s .ClassSummary ,s .ScoreTransform ,s .ScoreType ); 


obj .Impl =impl ; 
end
end

methods 
function [labels ,scores ,node ,cnum ]=predict (this ,X ,varargin )


































[varargin {:}]=convertStringsToChars (varargin {:}); 

adapter =classreg .learning .internal .makeClassificationModelAdapter (this ,X ); 
if~isempty (adapter )
[labels ,scores ,node ,cnum ]=predict (adapter ,X ,varargin {:}); 
return ; 
end


subtrees =internal .stats .parseArgs ({'subtrees' },{0 },varargin {:}); 


subtrees =processSubtrees (this .Impl ,subtrees ); 


vrange =getvrange (this ); 
X =classreg .learning .internal .table2PredictMatrix (X ,[],[],...
    vrange ,this .CategoricalPredictors ,getOptionalPredictorNames (this )); 


ifisempty (X )
[labels ,scores ]=predictEmptyX (this ,X ); 
node =NaN (0 ,1 ); 
cnum =NaN (0 ,1 ); 
return ; 
end

node =findNode (this .Impl ,X ,this .DataSummary .CategoricalPredictors ,subtrees ); 
ifisempty (this .Impl .ClassNames )
classnames =this .ClassSummary .NonzeroProbClasses ; 
else
classnames =this .Impl .ClassNames ; 
end


T =size (node ,2 ); 


N =size (node ,1 ); 
implscore =NaN (N ,length (classnames ),T ); 
fort =1 :T 
implscore (:,:,t )=this .Impl .ClassProb (node (:,t ),:); 
end


K =length (this .ClassSummary .ClassNames ); 
[~,pos ]=ismember (classnames ,this .ClassSummary .ClassNames ); 




scores =zeros (N ,K ,T ); 
scores (:,pos ,:)=implscore ; 


prior =this .Prior ; 
cost =this .Cost ; 
scoreTransform =this .PrivScoreTransform ; 
classnames =this .ClassNames ; 
ifischar (classnames )&&T >1 
classnames =cellstr (classnames ); 
end
labels =repmat (classnames (1 ,:),N ,T ); 
cnum =zeros (N ,T ); 
ifT ==1 
[labels ,scores ,~,cnum ]=...
    this .LabelPredictor (classnames ,prior ,cost ,scores ,scoreTransform ); 
else
fort =1 :T 
[labels (:,t ),scores (:,:,t ),~,cnum (:,t )]=...
    this .LabelPredictor (classnames ,prior ,cost ,scores (:,:,t ),scoreTransform ); 
end
end
end

function [err ,seerr ,nleaf ,bestlevel ]=loss (this ,X ,varargin )























































[varargin {:}]=convertStringsToChars (varargin {:}); 
adapter =classreg .learning .internal .makeClassificationModelAdapter (this ,X ,varargin {:}); 
if~isempty (adapter )
ifnargout >1 
error (message ('stats:classreg:learning:classif:CompactClassificationTree:loss:TooManyOutputs' )); 
end
err =loss (adapter ,X ,varargin {:}); 
return 
end

[Y ,varargin ]=classreg .learning .internal .inferResponse (this .ResponseName ,X ,varargin {:}); 


N =size (X ,1 ); 
args ={'lossfun' ,'subtrees' ,'weights' ,'treesize' }; 
defs ={this .DefaultLoss ,0 ,ones (N ,1 ),'se' }; 
[funloss ,subtrees ,W ,treesize ]=...
    internal .stats .parseArgs (args ,defs ,varargin {:}); 


subtrees =processSubtrees (this .Impl ,subtrees ); 


if~ischar (treesize )||~(treesize (1 )=='s' ||treesize (1 )=='m' )
error (message ('stats:classreg:learning:classif:CompactClassificationTree:loss:BadTreeSize' )); 
end


funloss =classreg .learning .internal .lossCheck (funloss ,'classification' ); 


[X ,C ,W ]=prepareDataForLoss (this ,X ,Y ,W ,[],true ,false ); 


[~,Sfit ]=predict (this ,X ,'subtrees' ,subtrees ); 


[err ,seerr ]=...
    classreg .learning .classif .CompactClassificationTree .stratifiedLossWithSE (...
    C ,Sfit ,W ,this .Cost ,funloss ); 


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
view (this .Impl ,cellstr (this .ClassSummary .ClassNames ),...
    nodeClassNum (this ),this .PredictorNames ,vrange ,...
    '/stats/compactclassificationtree.view.html' ,varargin {:}); 
end

function [varargout ]=surrogateAssociation (this ,varargin )


















[varargout {1 :nargout }]=meanSurrVarAssoc (this .Impl ,varargin {:}); 
end

function imp =predictorImportance (this ,varargin )

















imp =predictorImportance (this .Impl ,varargin {:}); 
end
end

methods (Static ,Hidden )
function [l ,sel ]=stratifiedLossWithSE (C ,Sfit ,W ,cost ,funloss )






ifisempty (C )
l =NaN ; 
sel =NaN ; 
return ; 
end


N =size (C ,1 ); 
ifismatrix (Sfit )
T =1 ; 
else
T =size (Sfit ,3 ); 
end


l =zeros (T ,1 ); 
sel =zeros (T ,1 ); 
lossPerObs =zeros (N ,1 ); 


W =W /sum (W ); 


WC =bsxfun (@times ,C ,W ); 


WPerClass =sum (WC ,1 ); 
WsqPerClass =sum (WC .^2 ,1 ); 


fort =1 :T 

forn =1 :N 
lossPerObs (n )=funloss (C (n ,:),Sfit (n ,:,t ),W (n ),cost ); 
end


lossPerClass =sum (bsxfun (@times ,WC ,lossPerObs ),1 ); 
sqlossPerClass =sum (bsxfun (@times ,WC ,lossPerObs .^2 ),1 ); 


l (t )=sum (lossPerClass ); 


lossPerClass =lossPerClass ./WPerClass ; 
sqlossPerClass =sqlossPerClass ./WPerClass ; 
selt =sum (WsqPerClass .*(sqlossPerClass -lossPerClass .^2 )); 
ifselt >0 
sel (t )=sqrt (selt ); 
end
end
end

function this =loadobj (obj )

ifisa (obj .Impl ,'classreg.learning.impl.CompactTreeImpl' )
obj .Impl =classreg .learning .impl .TreeImpl .makeFromClassregtree (obj .Impl .Tree ,true ); 
end
this =obj ; 
end
end
methods (Hidden ,Static )
function name =matlabCodegenRedirect (~)
name ='classreg.learning.coder.classif.CompactClassificationTree' ; 
end
end
end
