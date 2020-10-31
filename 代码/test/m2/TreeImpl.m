classdef TreeImpl 



properties 
D =[]; 
Children =[]; 
ClassCount =[]; 
ClassNames ={}; 
ClassProb =[]; 
Curvature ={}; 
CutCategories =[]; 
CutPoint =[]; 
CutVar =[]; 
HasUnsplit =[]; 
Interaction ={}; 
IsBranch =[]; 
NodeMean =[]; 
NodeProb =[]; 
NodeRisk =[]; 
NodeSize =[]; 
Parent =[]; 
PruneList =[]; 
PruneAlpha =[]; 
SplitGain =[]; 
SurrCutCategories =[]; 
SurrCutFlip =[]; 
SurrCutPoint =[]; 
SurrCutVar =[]; 
SurrSplitGain =[]; 
SurrVarAssoc =[]; 
end

properties (GetAccess =public ,SetAccess =protected ,Dependent =true )
CatSplit ; 
CutType ; 
SurrCutType ; 
end

methods 
function a =get .CatSplit (this )
branches =this .IsBranch ; 
notNumericCut =isnan (this .CutPoint ); 
catCut =branches &notNumericCut ; 
ifany (catCut )
a =this .CutCategories (catCut ,:); 
else
a ={}; 
end
end

function a =get .CutType (this )
branches =this .IsBranch ; 
numericCut =~isnan (this .CutPoint ); 
N =length (branches ); 
a =repmat ({'' },N ,1 ); 
a (branches &numericCut )={'continuous' }; 
a (branches &~numericCut )={'categorical' }; 
end

function a =get .SurrCutType (this )
ifisempty (this .SurrCutPoint )
a ={}; 
else
a =repmat ({{}},size (this .IsBranch ,1 ),1 ); 
branches =find (this .IsBranch ); 
forb =1 :numel (branches )
node =branches (b ); 
cutpoint =this .SurrCutPoint {node }; 
if~isempty (cutpoint )
nodecut =repmat ({'' },1 ,numel (cutpoint )); 
numericCut =~isnan (cutpoint ); 
nodecut (numericCut )={'continuous' }; 
nodecut (~numericCut )={'categorical' }; 
a {node }=nodecut ; 
end
end
end
end
end

methods (Access =protected )
function this =TreeImpl ()
end

function this =pruneNodes (this ,branches )

N =size (this .Children ,1 ); 


parents =branches ; 
tokeep =true (N ,1 ); 
kids =[]; 
while(true )
newkids =this .Children (parents ,:); 
newkids =newkids (:); 
newkids =newkids (newkids >0 &~ismember (newkids ,kids )); 
ifisempty (newkids )
break; 
end
kids =[kids ; newkids ]; %#ok<AGROW> 
tokeep (newkids )=false ; 
parents =newkids ; 
end


this .CutVar (branches )=0 ; 
this .CutPoint (branches )=NaN ; 
this .CutCategories (branches ,:)={[]}; 
this .Children (branches ,:)=0 ; 
this .HasUnsplit (branches )=false ; 
this .IsBranch (branches )=false ; 
this .SplitGain (branches )=0 ; 

if~isempty (this .SurrCutVar )
this .SurrCutVar (branches )={[]}; 
this .SurrCutPoint (branches )={[]}; 
this .SurrCutCategories (branches )={{}}; 
this .SurrCutFlip (branches )={[]}; 
this .SurrSplitGain (branches )={[]}; 
this .SurrVarAssoc (branches )={[]}; 
end


ntokeep =sum (tokeep ); 
nodenums =zeros (N ,1 ); 
nodenums (tokeep )=(1 :ntokeep )' ; 


remove =~tokeep ; 


this .Parent (remove )=[]; 
this .Children (remove ,:)=[]; 
mask =this .Parent >0 ; 
this .Parent (mask )=nodenums (this .Parent (mask )); 
mask =this .Children >0 ; 
this .Children (mask )=nodenums (this .Children (mask )); 


this .ClassCount (remove ,:)=[]; 
this .ClassProb (remove ,:)=[]; 
this .CutCategories (remove ,:)=[]; 
this .CutPoint (remove )=[]; 
this .CutVar (remove )=[]; 
this .HasUnsplit (remove )=[]; 
this .IsBranch (remove )=[]; 
this .NodeMean (remove )=[]; 
this .NodeProb (remove )=[]; 
this .NodeRisk (remove )=[]; 
this .NodeSize (remove )=[]; 
this .SplitGain (remove )=[]; 

if~isempty (this .Curvature )
this .Curvature (remove ,:)=[]; 
end

if~isempty (this .Interaction )
this .Interaction (remove ,:)=[]; 
end

if~isempty (this .SurrCutVar )
this .SurrCutVar (remove )=[]; 
this .SurrCutPoint (remove )=[]; 
this .SurrCutCategories (remove )=[]; 
this .SurrCutFlip (remove )=[]; 
this .SurrSplitGain (remove )=[]; 
this .SurrVarAssoc (remove )=[]; 
end
end
end

methods 
function this =prune (this ,varargin )
verbose =0 ; 

args ={'forceprune' ,'criterion' ,'cost' ,'level' ,'nodes' ,'alpha' }; 
defs ={false ,'' ,[],[],[],[]}; 
[force ,crit ,cost ,level ,nodes ,alpha ]=...
    internal .stats .parseArgs (args ,defs ,varargin {:}); 

dolevel =~isempty (level ); 
donodes =~isempty (nodes ); 
doalpha =~isempty (alpha ); 

ifsum (dolevel +donodes +doalpha )>1 
error (message ('stats:classreg:learning:impl:TreeImpl:prune:TooManyPruningOptions' )); 
end

doprune =any ([dolevel ,donodes ,doalpha ]); 

if~isempty (crit )&&(~ischar (crit )||~isvector (crit ))
error (message ('stats:classreg:learning:impl:TreeImpl:prune:BadCrit' )); 
end

ifdolevel 
if~isnumeric (level )||~isscalar (level )||level <0 
error (message ('stats:classreg:learning:impl:TreeImpl:prune:BadLevel' )); 
end
level =ceil (level ); 
end

ifdoalpha 
if~isnumeric (alpha )||~isscalar (alpha )||any (alpha <0 )
error (message ('stats:classreg:learning:impl:TreeImpl:prune:BadAlpha' )); 
end
end

ifdonodes 
if~isnumeric (nodes )||~isvector (nodes )||any (nodes <1 )
error (message ('stats:classreg:learning:impl:TreeImpl:prune:BadNodes' )); 
end
nodes =ceil (nodes ); 
end

ifisempty (this .PruneList )||isempty (this .PruneAlpha )||force 
[prunelist ,prunealpha ]=...
    classreg .learning .treeutils .computePruneInfo (...
    this .ClassProb ' ,cost ,...
    this .NodeProb ,this .NodeRisk ,this .HasUnsplit ,...
    this .Children ' ,crit ,verbose ); 
this .PruneList =prunelist ; 
this .PruneAlpha =prunealpha ; 
end


if~doprune 
return ; 
end

ifdolevel &&level >max (this .PruneList )
warning (message ('stats:classreg:learning:impl:TreeImpl:prune:LevelTooLarge' ,...
    level ,max (this .PruneList ))); 
end

ifdoalpha &&alpha >max (this .PruneAlpha )
warning (message ('stats:classreg:learning:impl:TreeImpl:prune:AlphaTooLarge' ,...
    sprintf ('%g' ,alpha ),sprintf ('%g' ,max (this .PruneAlpha )))); 
end

ifdoalpha 
level =find (this .PruneAlpha <=alpha ,1 ,'last' )-1 ; 
end


if~isempty (level )
nodes =find (this .IsBranch &this .PruneList <=level ); 
end


pruned =false ; 
if~isempty (nodes )
this =pruneNodes (this ,nodes ); 
pruned =true ; 
end


ifpruned 
[prunelist ,prunealpha ]=...
    classreg .learning .treeutils .computePruneInfo (...
    this .ClassProb ' ,cost ,...
    this .NodeProb ,this .NodeRisk ,this .HasUnsplit ,...
    this .Children ' ,crit ,verbose ); 
this .PruneList =prunelist ; 
this .PruneAlpha =prunealpha ; 
end
end

function subtrees =processSubtrees (this ,subtrees )
if~strcmpi (subtrees ,'all' )&&...
    (~isnumeric (subtrees )||~isvector (subtrees )...
    ||any (subtrees <0 )||any (diff (subtrees )<0 ))
error (message ('stats:classreg:learning:impl:TreeImpl:processSubtrees:BadSubtrees' )); 
end
ifisscalar (subtrees )&&subtrees ==0 
return ; 
end
prunelevs =this .PruneList ; 
ifisempty (prunelevs )
error (message ('stats:classreg:learning:impl:TreeImpl:processSubtrees:NoPruningInfo' )); 
end
ifischar (subtrees )
subtrees =min (prunelevs ):max (prunelevs ); 
end
subtrees =ceil (subtrees ); 
ifsubtrees (end)>max (prunelevs )
error (message ('stats:classreg:learning:impl:TreeImpl:processSubtrees:SubtreesTooBig' )); 
end
end

function tree =findsubtree (this ,alpha0 )
adjfactor =1 +100 *eps ; 
alpha =this .PruneAlpha ; 
tree =zeros (size (alpha0 )); 
forj =1 :length (alpha0 )
tree (j )=sum (alpha <=alpha0 (j )*adjfactor ); 
end
tree =tree -1 ; 
end

function nleaf =countLeaves (this ,subtrees )
N =numel (this .PruneAlpha ); 
ifN ==0 
nleaf =sum (~this .IsBranch ); 
else
ifstrcmp (subtrees ,'all' )
subtrees =0 :N -1 ; 
end
N =numel (subtrees ); 
nleaf =zeros (N ,1 ); 
forn =1 :N 
t =prune (this ,'level' ,subtrees (n )); 
nleaf (n )=sum (~t .IsBranch ); 
end
end
end

function n =findNode (this ,X ,catpred ,subtrees )
verbose =0 ; 

if~isfloat (X )||~ismatrix (X )
error (message ('stats:classreg:learning:impl:TreeImpl:findNode:BadX' )); 
end
internal .stats .checkSupportedNumeric ('X' ,X ); 

p =size (X ,2 ); 
ifp ~=this .D 
error (message ('stats:classreg:learning:impl:TreeImpl:findNode:BadXSize' ,this .D )); 
end

iscat =false (size (X ,2 ),1 ); 
iscat (catpred )=true ; 


subtrees =processSubtrees (this ,subtrees ); 

n =classreg .learning .treeutils .findNode (X ,...
    subtrees ,this .PruneList ,...
    this .Children ' ,iscat ,...
    this .CutVar ,this .CutPoint ,this .CutCategories ,...
    this .SurrCutFlip ,this .SurrCutVar ,...
    this .SurrCutPoint ,this .SurrCutCategories ,...
    verbose ); 
end


function [imp ,nSplit ]=predictorImportance (this ,varargin )
imp =zeros (1 ,this .D ); 
nSplit =zeros (1 ,this .D ); 

nBranch =sum (this .IsBranch ); 
ifnBranch ==0 
return ; 
end

splitGain =this .SplitGain ; 
cutVar =this .CutVar ; 
ford =1 :this .D 
imp (d )=sum (splitGain (cutVar ==d )); 
nSplit (d )=sum (cutVar ==d ); 
end

surrCutVar =this .SurrCutVar ; 
surrSplitGain =this .SurrSplitGain ; 
if~isempty (surrCutVar )
M =numel (surrCutVar ); 
form =1 :M 
thisCutVar =surrCutVar {m }; 
thisSplitGain =surrSplitGain {m }; 
imp (thisCutVar )=imp (thisCutVar )+thisSplitGain ; 
nSplit (thisCutVar )=nSplit (thisCutVar )+1 ; 
end
end

imp =imp /nBranch ; 
nSplit =nSplit /nBranch ; 
end

function ma =meanSurrVarAssoc (this ,j )
ifnargin >1 
validateNodes (this ,j ); 
end

ifnargin <2 
j =1 :numel (this .SurrCutVar ); 
end


isbr =this .IsBranch (j ); 
j =j (isbr ); 


N =numel (j ); 
p =this .D ; 
ma =zeros (p ); 
nsplit =zeros (p ,1 ); 


a =this .SurrVarAssoc (j ); 
bestvar =this .CutVar (j ); 
surrvar =this .SurrCutVar (j ); 


fori =1 :N 
n =bestvar (i ); 
nsplit (n )=nsplit (n )+1 ; 
m =surrvar {i }; 
if~isempty (m )
ma (n ,m )=ma (n ,m )+a {i }; 
end
end



gt0 =nsplit >0 ; 
ifany (gt0 )
ma (gt0 ,:)=bsxfun (@rdivide ,ma (gt0 ,:),nsplit (gt0 )); 
end


ma (1 :p +1 :end)=1 ; 
end

function validateNodes (this ,j )
numnodes =size (this .Children ,1 ); 
ifislogical (j )
ok =(numel (j )<=numnodes ); 
else
ok =ismember (j ,1 :numnodes ); 
ok =all (ok (:)); 
end
if~ok 
error (message ('stats:classreg:learning:impl:TreeImpl:validateNodes:BadNodes' ,numnodes ,numnodes )); 
end
end

function view (this ,classnames ,nodevalue ,varnames ,vrange ,htmlhelp ,varargin )
args ={'mode' ,'prunelevel' }; 
defs ={'text' ,[]}; 
[mode ,prunelevel ]=...
    internal .stats .parseArgs (args ,defs ,varargin {:}); 

ifstrncmpi (mode ,'text' ,length (mode ))
viewText (this ,classnames ,nodevalue ,varnames ,prunelevel ,vrange ); 
elseifstrncmpi (mode ,'graph' ,length (mode ))
viewGraph (this ,classnames ,nodevalue ,varnames ,prunelevel ,vrange ,htmlhelp ); 
else
error (message ('stats:classreg:learning:impl:TreeImpl:view:BadViewMode' )); 
end
end

function viewText (this ,classnames ,nodevalue ,varnames ,prunelevel ,vrange )

ifisempty (prunelevel )
t =this ; 
else
t =prune (this ,'level' ,prunelevel ); 
end

if~isempty (classnames )
nodevalue =classnames (nodevalue ); 
end

isLoose =strcmp (get (0 ,'FormatSpacing' ),'loose' ); 
if(isLoose ),fprintf ('\n' ); end


maxnode =size (t .Children ,1 ); 
nd =1 +floor (log10 (maxnode )); 
isregression =isempty (classnames ); 
ifisregression 
fprintf (getString (message ('stats:classregtree:disp:DecisionTreeForRegression' ))); 
else
fprintf (getString (message ('stats:classregtree:disp:DecisionTreeForClassification' ))); 
end
ifisempty (vrange )
vrange =cell (length (varnames ),1 ); 
end



forj =1 :maxnode 
ifany (t .Children (j ,:))

vnum =t .CutVar (j ); 
vtype =t .CutType {j }; 
vname =varnames {vnum }; 
kids =t .Children (j ,:); 
ifisempty (classnames )
Yfit =nodevalue (j ); 
Yfit =num2str (Yfit ,'%g' ); 
else
Yfit =nodevalue {j }; 
end
ifstrcmp (vtype ,'continuous' )
cut =t .CutPoint (j ); 
[condleft ,condright ]=getCondLR (true ,vname ,cut ,vrange {vnum }); 
else
cut =t .CutCategories (j ,:); 
[condleft ,condright ]=getCondLR (false ,vname ,cut ,vrange {vnum }); 
end
fprintf ('%*d  %s\n' ,nd ,j ,getString (message ('stats:classregtree:disp:TreeBranch' ,...
    condleft ,kids (1 ),condright ,kids (2 ),Yfit ))); 
else

ifisregression 
fprintf (sprintf ('%s  %s %s\n' ,'%*d' ,getString (message ('stats:classregtree:disp:FittedResponse' )),'%g' ),nd ,j ,nodevalue (j )); 
else
fprintf (sprintf ('%s  %s %s\n' ,'%*d' ,getString (message ('stats:classregtree:disp:PredictedClass' )),'%s' ),nd ,j ,nodevalue {j }); 
end
end
end
if(isLoose ),fprintf ('\n' ); end

end

function outfig =viewGraph (this ,classnames ,nodevalue ,varnames ,curlevel ,vrange ,htmlhelp )

ifisempty (curlevel )
curlevel =0 ; 
end

doclass =~isempty (classnames ); 

function helpviewer (varargin )
helpview ([docroot ,htmlhelp ]); 
end


fig =classreg .learning .treeutils .TreeDrawer .setupfigure (doclass ); 
try
classreg .learning .treeutils .TreeDrawer .adjustmenu (fig ,@helpviewer ); 
catch me 
error (message ('stats:classreg:learning:impl:TreeImpl:view:AdjustMenuFails' ,me .message )); 
end


fulltree =this ; 


[X ,Y ]=classreg .learning .treeutils .TreeDrawer .drawtree (...
    this ,fig ,nodevalue ,varnames ,curlevel ,classnames ,vrange ,...
    @(iscont ,vname ,cut ,vals )getCondLR (iscont ,vname ,cut ,vals ,5 )); 


set (fig ,'ButtonDownFcn' ,@classreg .learning .treeutils .TreeDrawer .removelabels ,...
    'UserData' ,{X ,Y ,0 ,varnames ,nodevalue ,fulltree ,curlevel ,classnames }); 


classreg .learning .treeutils .TreeDrawer .updateenable (fig ); 
classreg .learning .treeutils .TreeDrawer .updatelevel (fig ,curlevel ,fulltree ); 

ifnargout >0 
outfig =fig ; 
end
end
end

methods (Static )
function this =makeFromData (X ,Y ,W ,useObs ,doclass ,catpred ,splitcrit ,...
    minleaf ,minparent ,maxsplits ,nvartosample ,nsurrsplit ,...
    maxcat ,algcat ,cost ,reltol ,predictorsel ,usechisq ,rsh )







verbose =0 ; 

D =size (X ,2 ); 

iscat =false (D ,1 ); 
iscat (catpred )=true ; 

ifstrcmpi (nsurrsplit ,'off' )
nsurrsplit =0 ; 
end

ifstrcmpi (nsurrsplit ,'all' )
nsurrsplit =D ; 
end

ifstrcmpi (nvartosample ,'all' )
nvartosample =D ; 
end

[~,algcat ]=ismember (algcat ,{'auto' ,'Exact' ,'PullLeft' ,'PCA' ,'OVAbyClass' }); 
algcat =algcat -1 ; 

curvtest =false ; 
intertest =false ; 
ifstrcmp (predictorsel ,'curvature' )
curvtest =true ; 
elseifstrcmp (predictorsel ,'interaction-curvature' )
curvtest =true ; 
intertest =true ; 
end

ifdoclass 
Y =Y -1 ; 
end

[children ,classcount ,classprob ,curvature ,...
    cutcategories ,cutpoint ,cutvar ,hasunsplit ,interaction ,isbranch ,...
    nodemean ,nodeprob ,nodesize ,parent ,noderisk ,splitgain ,...
    surrcutcategories ,surrcutflip ,...
    surrcutpoint ,surrcutvar ,surrsplitgain ,surrvarassoc ]=...
    classreg .learning .treeutils .growTree (...
    X ,Y ,W ,useObs -1 ,iscat ,splitcrit ,...
    minleaf ,minparent ,maxsplits ,...
    nvartosample ,nsurrsplit ,maxcat ,algcat ,cost ,reltol ,...
    curvtest ,intertest ,usechisq ,rsh ,verbose ); 

this =classreg .learning .impl .TreeImpl (); 
this .D =D ; 
this .Children =children ' ; 
this .ClassCount =classcount ' ; 
this .ClassProb =classprob ' ; 
this .Curvature =curvature ; 
this .CutCategories =cutcategories ; 
this .CutPoint =cutpoint ; 
this .CutVar =cutvar ; 
this .HasUnsplit =hasunsplit ; 
this .Interaction =interaction ; 
this .IsBranch =isbranch ; 
this .NodeMean =nodemean ; 
this .NodeProb =nodeprob ; 
this .NodeRisk =noderisk ; 
this .NodeSize =nodesize ; 
this .Parent =parent ; 
this .SplitGain =splitgain ; 
this .SurrCutCategories =surrcutcategories ; 
this .SurrCutFlip =surrcutflip ; 
this .SurrCutPoint =surrcutpoint ; 
this .SurrCutVar =surrcutvar ; 
this .SurrSplitGain =surrsplitgain ; 
this .SurrVarAssoc =surrvarassoc ; 
end


function this =makeFromClassregtree (tree ,calledFromLoadobj )
ifnargin <2 
calledFromLoadobj =false ; 
end

if~isempty (tree .impurity )
crit ='impurity' ; 
else
crit ='error' ; 
end

N =numnodes (tree ); 

this =classreg .learning .impl .TreeImpl (); 
this .D =tree .npred ; 
this .Children =children (tree ); 

ifstrcmp (type (tree ),'classification' )
this .ClassCount =classcount (tree ); 
else
this .ClassCount =nodesize (tree ); 
end

this .ClassNames =classreg .learning .internal .ClassLabel (classname (tree )); 

ifstrcmp (type (tree ),'classification' )
this .ClassProb =classprob (tree ); 
else
this .ClassProb =ones (N ,1 ); 
end

this .CutCategories =cutcategories (tree ); 
this .CutPoint =cutpoint (tree ); 
this .CutVar =abs (tree .var ); 
this .HasUnsplit =true (N ,1 ); 
this .IsBranch =isbranch (tree ); 

ifstrcmp (type (tree ),'regression' )
this .NodeMean =nodemean (tree ); 
else
this .NodeMean =NaN (N ,1 ); 
end

this .NodeProb =nodeprob (tree ); 
this .NodeRisk =risk (tree ,1 :N ,'criterion' ,crit ); 
this .NodeSize =nodesize (tree ); 
this .Parent =parent (tree ); 

this .PruneList =tree .prunelist ; 
this .PruneAlpha =tree .alpha ; 

r =risk (tree ,1 :N ,'criterion' ,crit ); 
rdiff =risk (tree ,1 :N ,'criterion' ,crit ,'mode' ,'diff' ); 
this .SplitGain =rdiff ; 
hasKids =find (all (children (tree )>0 ,2 )); 

this .SplitGain (hasKids )=rdiff (hasKids )...
    -sum (reshape (r (children (tree ,hasKids )),numel (hasKids ),2 ),2 ); 

this .SurrCutCategories =surrcutcategories (tree ); 
this .SurrCutFlip =surrcutflip (tree ); 
this .SurrCutPoint =surrcutpoint (tree ); 
this .SurrCutVar =cellfun (@abs ,tree .surrvar ,'UniformOutput' ,false ); 

M =numel (this .SurrCutVar ); 
this .SurrSplitGain =cell (M ,1 ); 
ifM >0 &&calledFromLoadobj 
warning (message ('stats:classreg:learning:impl:TreeImpl:makeFromClassregtree:Pre13aTreeWithSurrogateSplits' )); 
end
form =1 :M 
this .SurrSplitGain {m }=zeros (1 ,numel (this .SurrCutVar {m })); 
end

this .SurrVarAssoc =surrvarassoc (tree ); 
end

function this =fromStruct (s )



this =classreg .learning .impl .TreeImpl (); 


N =size (s .Children ,1 ); 

this .D =s .D ; 
this .Children =s .Children ; 
this .ClassCount =s .ClassCount ; 

ifisempty (s .ClassNames )
classnames ={}; 
elseifstrcmp (s .ClassNamesType ,'cellstr' )
classnames =cellstr (s .ClassNames ); 
classnames =...
    arrayfun (@(x ,y )x {1 }(1 :y ),...
    classnames ,...
    s .ClassNamesLength ,...
    'UniformOutput' ,false ); 
classnames =classreg .learning .internal .ClassLabel (classnames ); 
else
classnames =s .ClassNames ; 
classnames =classreg .learning .internal .ClassLabel (classnames ); 
end

this .ClassNames =classnames ; 

this .ClassProb =s .ClassProb ; 
this .Curvature ={}; 
this .CutCategories =repmat ({[],[]},N ,1 ); 
this .CutPoint =s .CutPoint ; 
this .CutVar =s .CutVar ; 
this .HasUnsplit =s .HasUnsplit ; 
this .Interaction ={}; 
this .IsBranch =s .IsBranch ; 
this .NodeMean =s .NodeMean ; 
this .NodeProb =s .NodeProb ; 
this .NodeRisk =s .NodeRisk ; 
this .NodeSize =s .NodeSize ; 
this .Parent =s .Parent ; 
this .PruneList =s .PruneList ; 
this .PruneAlpha =s .PruneAlpha ; 
this .SplitGain =s .SplitGain ; 
this .SurrCutCategories ={}; 
this .SurrCutFlip ={}; 
this .SurrCutPoint ={}; 
this .SurrCutVar ={}; 
this .SurrSplitGain ={}; 
this .SurrVarAssoc ={}; 
end
end

end


function [condleft ,condright ]=getCondLR (iscont ,vname ,cut ,vals ,maxnum )
ifnargin <5 
maxnum =Inf ; 
end
ifiscont 
ifisempty (vals )

condleft =sprintf ('%s<%g' ,vname ,cut ); 
condright =sprintf ('%s>=%g' ,vname ,cut ); 
else

ifiscategorical (vals )
vals =cellstr (vals ); 
end
cut =ceil (cut ); 
ifcut ==2 
condleft =sprintf ('%s=%s' ,vname ,vals {cut -1 }); 
else
condleft =sprintf ('%s<=%s' ,vname ,vals {cut -1 }); 
end
ifcut <numel (vals )
condright =sprintf ('%s>=%s' ,vname ,vals {cut }); 
else
condright =sprintf ('%s=%s' ,vname ,vals {cut }); 
end
end
else

condleft =makeSet (cut {1 },vname ,vals ,maxnum ); 
condright =makeSet (cut {2 },vname ,vals ,maxnum ); 
end
end

function cond =makeSet (cats ,vname ,invals ,maxnum )
ifisempty (invals )
vals =cellstr (num2str (cats (:))); 
else
[~,invals ]=grp2idx (invals ); 
vals =invals (cats ); 
end
ifisscalar (vals )
cond =sprintf ('%s=%s' ,vname ,vals {1 }); 
else
set =deblank (sprintf ('%s ' ,vals {1 :min (maxnum ,end)})); 
iflength (vals )>maxnum 
set =[set ,'...' ]; 
end
cond =sprintf ('%s %s {%s}' ,vname ,getString (message ('stats:classregtree:disp:ElementInSet' )),set ); 
end
end
