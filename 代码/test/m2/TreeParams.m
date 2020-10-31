classdef TreeParams <classreg .learning .modelparams .ModelParams 





















properties 
SplitCriterion =[]; 
MinParent =[]; 
MinLeaf =[]; 
MaxSplits =[]; 
NVarToSample =[]; 
MergeLeaves =[]; 
Prune =[]; 
PruneCriterion =[]; 
QEToler =[]; 
NSurrogate =[]; 
MaxCat =[]; 
AlgCat =[]; 
PredictorSelection =[]; 
UseChisqTest =[]; 
Stream =[]; 
end

methods (Access =protected )
function this =TreeParams (type ,splitcrit ,minparent ,minleaf ,...
    maxsplits ,nvartosample ,mergeleaves ,prune ,prunecrit ,qetoler ,...
    nsurrogate ,maxcat ,algcat ,predictorsel ,usechisq ,stream )
this =this @classreg .learning .modelparams .ModelParams ('Tree' ,type ,2 ); 
this .SplitCriterion =splitcrit ; 
this .MinParent =minparent ; 
this .MinLeaf =minleaf ; 
this .MaxSplits =maxsplits ; 
this .NVarToSample =nvartosample ; 
this .MergeLeaves =mergeleaves ; 
this .Prune =prune ; 
this .PruneCriterion =prunecrit ; 
this .QEToler =qetoler ; 
this .NSurrogate =nsurrogate ; 
this .MaxCat =maxcat ; 
this .AlgCat =algcat ; 
this .PredictorSelection =predictorsel ; 
this .UseChisqTest =usechisq ; 
this .Stream =stream ; 
end
end

methods (Static ,Hidden )
function [holder ,extraArgs ]=make (type ,varargin )

args ={'splitcriterion' ...
    ,{'minparentsize' ,'minparent' }...
    ,{'minleafsize' ,'minleaf' }...
    ,'maxnumsplits' ...
    ,{'numvariablestosample' ,'numpredictorstosample' ,'nvartosample' }...
    ,'mergeleaves' ...
    ,'prune' ...
    ,'prunecriterion' ...
    ,{'quadraticerrortolerance' ,'qetoler' }...
    ,'surrogate' ...
    ,{'maxnumcategories' ,'maxcat' }...
    ,'algorithmforcategorical' ...
    ,'predictorselection' ...
    ,'chisquarecurvaturetest' ...
    ,'stream' }; 
defs ={repmat ([],1 ,15 )}; 
[splitcrit ,minparent ,minleaf ,maxsplits ,...
    nvartosample ,mergeleaves ,prune ,prunecrit ,qetoler ,...
    nsurrogate ,maxcat ,algcat ,predictorsel ,usechisq ,...
    stream ,~,extraArgs ]=...
    internal .stats .parseArgs (args ,defs ,varargin {:}); 

if~isempty (splitcrit )
ifischar (splitcrit )
ifstrcmpi (type ,'regression' )&&~strcmpi (splitcrit ,'mse' )
error (message ('stats:classreg:learning:modelparams:TreeParams:make:BadRegressionSplitCrit' )); 
end
ifstrcmpi (type ,'classification' )...
    &&~any (strncmpi (splitcrit ,{'gdi' ,'deviance' ,'twoing' },length (splitcrit )))
error (message ('stats:classreg:learning:modelparams:TreeParams:make:BadClassificationSplitCrit' )); 
end
else
if~iscellstr (splitcrit )||numel (splitcrit )~=2 
error (message ('stats:classreg:learning:modelparams:TreeParams:make:BadSplitCrit' )); 
end
end
end

if~isempty (minparent )&&(~isnumeric (minparent )||~isscalar (minparent )...
    ||minparent <=0 ||isnan (minparent )||isinf (minparent ))
error (message ('stats:classreg:learning:modelparams:TreeParams:make:BadMinParent' )); 
end
if~ischar (minparent )
minparent =ceil (minparent ); 
end

if~isempty (minleaf )&&(~isnumeric (minleaf )||~isscalar (minleaf )...
    ||minleaf <=0 ||isnan (minleaf )||isinf (minleaf ))
error (message ('stats:classreg:learning:modelparams:TreeParams:make:BadMinLeaf' )); 
end
minleaf =ceil (minleaf ); 

if~isempty (maxsplits )&&(~isnumeric (maxsplits )||~isscalar (maxsplits )...
    ||maxsplits <0 ||isnan (maxsplits )||isinf (maxsplits ))
error (message ('stats:classreg:learning:modelparams:TreeParams:make:BadMaxSplits' )); 
end
maxsplits =ceil (maxsplits ); 

if~isempty (nvartosample )&&...
    ~(ischar (nvartosample )&&strcmpi (nvartosample ,'all' ))&&...
    ~(isnumeric (nvartosample )&&isscalar (nvartosample )...
    &&nvartosample >0 &&~isnan (nvartosample )&&~isinf (nvartosample ))
error (message ('stats:classreg:learning:modelparams:TreeParams:make:BadNvartosample' )); 
end
ifisnumeric (nvartosample )
nvartosample =ceil (nvartosample ); 
end

if~isempty (mergeleaves )&&(~ischar (mergeleaves )...
    ||~ismember (lower (mergeleaves ),{'on' ,'off' }))
error (message ('stats:classreg:learning:modelparams:TreeParams:make:BadMergeLeaves' )); 
end

if~isempty (prune )&&(~ischar (prune )...
    ||~ismember (lower (prune ),{'on' ,'off' }))
error (message ('stats:classreg:learning:modelparams:TreeParams:make:BadPrune' )); 
end

if~isempty (prunecrit )
ifischar (prunecrit )
ifstrcmpi (type ,'regression' )&&~strcmpi (prunecrit ,'mse' )
error (message ('stats:classreg:learning:modelparams:TreeParams:make:BadRegressionPruneCrit' )); 
end
ifstrcmpi (type ,'classification' )...
    &&~any (strncmpi (prunecrit ,{'error' ,'impurity' },length (prunecrit )))
error (message ('stats:classreg:learning:modelparams:TreeParams:make:BadClassificationPruneCrit' )); 
end
else
error (message ('stats:classreg:learning:modelparams:TreeParams:make:BadPruneCrit' )); 
end
end

if~isempty (qetoler )&&(~isfloat (qetoler )||~isscalar (qetoler )...
    ||qetoler <=0 ||isnan (qetoler )||isinf (qetoler ))
error (message ('stats:classreg:learning:modelparams:TreeParams:make:BadQEtoler' )); 
end

if~isempty (nsurrogate )...
    &&(~ischar (nsurrogate )||~ismember (lower (nsurrogate ),{'on' ,'off' ,'all' }))...
    &&(~islogical (nsurrogate )||~isscalar (nsurrogate ))...
    &&(~isnumeric (nsurrogate )||~isscalar (nsurrogate )||nsurrogate <0 )
error (message ('stats:classreg:learning:modelparams:TreeParams:make:BadSurrogate' )); 
end
ifisnumeric (nsurrogate )
nsurrogate =ceil (nsurrogate ); 
end

if~isempty (maxcat )&&(~isnumeric (maxcat )||~isscalar (maxcat )...
    ||maxcat <0 ||isnan (maxcat )||isinf (maxcat ))
error (message ('stats:classreg:learning:modelparams:TreeParams:make:BadMaxcat' )); 
end
maxcat =ceil (maxcat ); 

if~isempty (algcat )
ifstrcmpi (type ,'regression' )
error (message ('stats:classreg:learning:modelparams:TreeParams:make:AlgCatForRegression' )); 
end
if~ischar (algcat )
error (message ('stats:classreg:learning:modelparams:TreeParams:make:AlgCatNotChar' )); 
end
allowedVals ={'Exact' ,'PullLeft' ,'PCA' ,'OVAbyClass' }; 
tf =strncmpi (algcat ,allowedVals ,length (algcat )); 
ifsum (tf )~=1 
error (message ('stats:classreg:learning:modelparams:TreeParams:make:AlgCatUnknownValue' )); 
end
algcat =allowedVals {tf }; 
end

if~isempty (predictorsel )
predictorsel =validatestring (predictorsel ,...
    {'allsplits' ,'curvature' ,'interaction-curvature' },...
    'classreg.learning.modelparams.TreeParams.make' ,'PredictorSelection' ); 
end

if~isempty (usechisq )
usechisq =internal .stats .parseOnOff (usechisq ,'ChisquareCurvatureTest' ); 
end


holder =classreg .learning .modelparams .TreeParams (type ,splitcrit ,minparent ,...
    minleaf ,maxsplits ,nvartosample ,mergeleaves ,prune ,prunecrit ,qetoler ,...
    nsurrogate ,maxcat ,algcat ,predictorsel ,usechisq ,stream ); 
end


function this =loadobj (obj )
found =fieldnames (obj ); 

ifismember ('Version' ,found )&&~isempty (obj .Version )
ifobj .Version ==classreg .learning .modelparams .TreeParams .expectedVersion ()

this =obj ; 

elseifobj .Version ==1 

predictorsel ='allsplits' ; 
usechisq =true ; 

this =classreg .learning .modelparams .TreeParams (...
    obj .Type ,obj .SplitCriterion ,obj .MinParent ,...
    obj .MinLeaf ,obj .MaxSplits ,obj .NVarToSample ,obj .MergeLeaves ,...
    obj .Prune ,obj .PruneCriterion ,obj .QEToler ,...
    obj .NSurrogate ,obj .MaxCat ,obj .AlgCat ,...
    predictorsel ,usechisq ,obj .Stream ); 
end

else



predictorsel ='allsplits' ; 
usechisq =true ; 

ifismember ('AlgCat' ,found )&&~isempty (obj .AlgCat )
algcat =obj .AlgCat ; 
else
algcat ='auto' ; 
end

ifismember ('MaxCat' ,found )&&~isempty (obj .MaxCat )
maxcat =obj .MaxCat ; 
else
maxcat =10 ; 
end

ifismember ('NSurrogate' ,found )&&~isempty (obj .NSurrogate )
nsurrogate =obj .NSurrogate ; 
else
ifismember ('Surrogate' ,found )&&strcmpi (obj .Surrogate ,'on' )
nsurrogate =10 ; 
else
nsurrogate =0 ; 
end
end

stream =[]; 
ifismember ('Stream' ,found )
stream =obj .Stream ; 
end

ifismember ('MaxSplits' ,found )&&~isempty (obj .MaxSplits )
maxsplits =obj .MaxSplits ; 
else
maxsplits =double (intmax ); 
end

minparent =obj .MinParent ; 
ifischar (minparent )&&strcmp (minparent ,'OneSplit' )
minparent =10 ; 
maxsplits =1 ; 
end

this =classreg .learning .modelparams .TreeParams (...
    obj .Type ,obj .SplitCriterion ,minparent ,...
    obj .MinLeaf ,maxsplits ,obj .NVarToSample ,obj .MergeLeaves ,...
    obj .Prune ,obj .PruneCriterion ,obj .QEToler ,...
    nsurrogate ,maxcat ,algcat ,...
    predictorsel ,usechisq ,stream ); 
end
end

function v =expectedVersion ()
v =2 ; 
end
end

methods (Hidden )
function this =fillDefaultParams (this ,X ,Y ,W ,dataSummary ,classSummary )%#ok<INUSD> 
[N ,D ]=size (X ); 

ifisempty (this .SplitCriterion )
ifstrcmpi (this .Type ,'classification' )
this .SplitCriterion ='gdi' ; 
else
this .SplitCriterion ='mse' ; 
end
end

ifisempty (this .MinParent )
this .MinParent =10 ; 
end
ifisempty (this .MinLeaf )
this .MinLeaf =1 ; 
end
this .MinParent =max (this .MinParent ,2 *this .MinLeaf ); 

ifisempty (this .MaxSplits )||this .MaxSplits >N -1 
this .MaxSplits =N -1 ; 
end

ifisempty (this .NVarToSample )||...
    (~ischar (this .NVarToSample )&&this .NVarToSample >=D )
this .NVarToSample ='all' ; 
end

ifisempty (this .MergeLeaves )
this .MergeLeaves ='on' ; 
end
ifisempty (this .Prune )
this .Prune ='on' ; 
end

ifisempty (this .PruneCriterion )
ifstrcmpi (this .Type ,'classification' )
this .PruneCriterion ='error' ; 
else
this .PruneCriterion ='mse' ; 
end
end

ifstrcmpi (this .Type ,'regression' )&&isempty (this .QEToler )
this .QEToler =1e-6 ; 
end

ifisempty (this .NSurrogate )
this .NSurrogate =0 ; 
elseifstrcmpi (this .NSurrogate ,'on' )
this .NSurrogate =min (D -1 ,10 ); 
elseifislogical (this .NSurrogate )&&this .NSurrogate 
this .NSurrogate =min (D -1 ,10 ); 
elseifisnumeric (this .NSurrogate )&&this .NSurrogate >D -1 
this .NSurrogate ='all' ; 
end

ifisempty (this .MaxCat )
this .MaxCat =10 ; 
end
ifisempty (this .AlgCat )
this .AlgCat ='auto' ; 
end

ifisempty (this .PredictorSelection )
this .PredictorSelection ='allsplits' ; 
end

ifisempty (this .UseChisqTest )
this .UseChisqTest =true ; 
end
end
end

end
