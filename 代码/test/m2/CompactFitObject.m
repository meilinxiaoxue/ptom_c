classdef (AllowedSubclasses ={?classreg .regr .FitObject ,?classreg .regr .CompactPredictor })CompactFitObject <classreg .learning .internal .DisallowVectorOps &internal .matlab .variableeditor .VariableEditorPropertyProvider 











properties (GetAccess ='public' ,SetAccess ='protected' )




















VariableInfo =table ({'double' },{[NaN ; NaN ]},false ,false ,...
    'VariableNames' ,{'Class' ,'Range' ,'InModel' ,'IsCategorical' },...
    'RowNames' ,{'y' }); 
end
properties (GetAccess ='protected' ,SetAccess ='protected' )
PredLocs =zeros (1 ,0 ); 
RespLoc =1 ; 
IsFitFromData =false ; 
PredictorTypes ='numeric' ; 
ResponseType ='numeric' ; 
NumObservations_ =0 ; 
IsFitFromTable =true ; 
end
properties (Dependent ,GetAccess ='public' ,SetAccess ='protected' )









NumVariables 














VariableNames 






NumPredictors 






PredictorNames 






ResponseName 








NumObservations 
end

methods 
function n =get .NumVariables (model )
n =size (model .VariableInfo ,1 ); 
end
function vnames =get .VariableNames (model )
vnames =model .VariableInfo .Properties .RowNames ; 
end
function n =get .NumPredictors (model )
n =length (model .PredictorNames ); 
end
function vnames =get .PredictorNames (model )
vnames =model .VariableInfo .Properties .RowNames (model .PredLocs ); 
end
function vname =get .ResponseName (model )
vname =model .VariableInfo .Properties .RowNames {model .RespLoc }; 
end
function n =get .NumObservations (model )
n =model .NumObservations_ ; 
end
end

methods (Abstract ,Hidden ,Access ='public' )
t =title (model ); 
end
methods (Abstract ,Hidden ,Access ='public' )
disp (model )
val =feval (model ,varargin ); 
end

methods (Access ='protected' )
function model =noFit (model ,varNames )
p =length (varNames )-1 ; 
model .PredLocs =1 :p ; 
model .RespLoc =p +1 ; 
viName =varNames ; 
viClass =repmat ({'double' },p +1 ,1 ); 
viRange =repmat ({[NaN ; NaN ]},p +1 ,1 ); 
viInModel =[true (p ,1 ); false ]; 
viIsCategorical =false (p +1 ,1 ); 
model .VariableInfo =table (viClass ,viRange ,viInModel ,viIsCategorical ,...
    'VariableNames' ,{'Class' ,'Range' ,'InModel' ,'IsCategorical' },...
    'RowNames' ,viName ); 
model .Data =table ([{zeros (0 ,p +1 )},varNames ]); 
model .IsFitFromData =false ; 
end


function tf =hasData (model )
tf =false ; 
end
function tf =fitFromDataset (model )
tf =false ; 
end


function [varName ,varNum ]=identifyVar (model ,var )
[tf ,varName ]=internal .stats .isString (var ,true ); 
iftf 
varNum =find (strcmp (varName ,model .VariableNames )); 
ifisempty (varNum )
error (message ('stats:classreg:regr:FitObject:UnrecognizedName' ,varName )); 
end
elseifinternal .stats .isScalarInt (var ,1 )
varNum =var ; 
ifvarNum >model .NumVariables 
error (message ('stats:classreg:regr:FitObject:BadVariableNumber' ,model .NumVariables )); 
end
varName =model .VariableNames {varNum }; 
else
error (message ('stats:classreg:regr:FitObject:BadVariableSpecification' )); 
end
end


function gm =gridVectors2gridMatrices (model ,gv )
p =model .NumPredictors ; 

if~(iscell (gv )&&isvector (gv )&&length (gv )==p )
error (message ('stats:classreg:regr:FitObject:BadGridSize' ,p )); 
elseif~reconcilePredictorTypes (model ,gv )
error (message ('stats:classreg:regr:FitObject:BadGridTypes' ,p )); 
end

if~all (cellfun (@(x )isnumeric (x )&&isvector (x ),gv ))
error (message ('stats:classreg:regr:FitObject:NonNumericGrid' ,p )); 
end

ifp >1 
[gm {1 :p }]=ndgrid (gv {:}); 
else
gm =gv ; 
end
end

function tf =reconcilePredictorTypes (model ,vars )%#ok<INUSD> 
ifhasData (model )
tf =true ; 
else
tf =true ; 
end
endend

methods (Hidden ,Access ='public' )

function val =fevalgrid (model ,varargin )
gridMatrices =gridVectors2gridMatrices (model ,varargin ); 
val =feval (model ,gridMatrices {:}); 
end


function [varargout ]=subsref (a ,s )
switchs (1 ).type 
case '()' 
error (message ('stats:classreg:regr:FitObject:ParenthesesNotAllowed' )); 
case '{}' 
error (message ('stats:classreg:regr:FitObject:NoCellIndexing' )); 
case '.' 
[varargout {1 :nargout }]=builtin ('subsref' ,a ,s ); 
end
end
function a =subsasgn (a ,s ,~)
switchs (1 ).type 
case '()' 
error (message ('stats:classreg:regr:FitObject:NoParetnthesesAssignment' )); 
case '{}' 
error (message ('stats:classreg:regr:FitObject:NoCellAssignment' )); 
case '.' 
ifany (strcmp (s (1 ).subs ,properties (a )))
error (message ('stats:classreg:regr:FitObject:ReadOnly' ,s (1 ).subs ,class (a ))); 
else
error (message ('stats:classreg:regr:FitObject:NoMethodProperty' ,s (1 ).subs ,class (a ))); 
end
end
end

end

methods (Hidden ,Static ,Access ='public' )
function a =empty (varargin )%#ok<STOUT> 
error (message ('stats:classreg:regr:FitObject:NoEmptyAllowed' )); 
end
end

methods (Static ,Access ='protected' )
function opts =checkRobust (robustOpts )

ifisequal (robustOpts ,'off' )||isempty (robustOpts )||isequal (robustOpts ,false )
opts =[]; 
return ; 
end
ifinternal .stats .isString (robustOpts )||isa (robustOpts ,'function_handle' )||isequal (robustOpts ,true )
ifisequal (robustOpts ,'on' )||isequal (robustOpts ,true )
wfun ='bisquare' ; 
else
wfun =robustOpts ; 
end
robustOpts =struct ('RobustWgtFun' ,wfun ,'Tune' ,[]); 
end
ifisstruct (robustOpts )




fn =fieldnames (robustOpts ); 
if~ismember ('RobustWgtFun' ,fn )||isempty (robustOpts .RobustWgtFun )
opts =[]; 
return 
end
if~ismember ('Tune' ,fn )
robustOpts .Tune =[]; 
end
ifinternal .stats .isString (robustOpts .RobustWgtFun )
[opts .RobustWgtFun ,opts .Tune ]=dfswitchyard ('statrobustwfun' ,robustOpts .RobustWgtFun ,robustOpts .Tune ); 
ifisempty (opts .Tune )
error (message ('stats:classreg:regr:FitObject:BadRobustName' )); 
end
else
opts =struct ('RobustWgtFun' ,robustOpts .RobustWgtFun ,'Tune' ,robustOpts .Tune ); 
end
else
error (message ('stats:classreg:regr:FitObject:BadRobustValue' )); 
end
end
end
methods (Hidden ,Static )

function [varNames ,predictorVars ,responseVar ]=...
    getVarNames (varNames ,predictorVars ,responseVar ,nx )
ifisempty (varNames )


if~isempty (predictorVars )&&(iscell (predictorVars )||ischar (predictorVars ))
ifiscell (predictorVars )
predictorVars =predictorVars (:); 
else
predictorVars =cellstr (predictorVars ); 
end
iflength (predictorVars )~=nx ||...
    ~internal .stats .isStrings (predictorVars ,true )
error (message ('stats:classreg:regr:FitObject:BadPredNames' )); 
end
pnames =predictorVars ; 
else
pnames =internal .stats .numberedNames ('x' ,1 :nx )' ; 
if~isempty (responseVar )&&internal .stats .isString (responseVar )
pnames =genvarname (pnames ,responseVar ); 
end
ifisempty (predictorVars )
predictorVars =pnames ; 
else
predictorVars =pnames (predictorVars ); 
end
end
ifisempty (responseVar )
responseVar =genvarname ('y' ,predictorVars ); 
end
varNames =[pnames ; {responseVar }]; 
else
if~internal .stats .isStrings (varNames ,true )
error (message ('stats:classreg:regr:FitObject:BadVarNames' )); 
end



ifisempty (responseVar )&&isempty (predictorVars )

responseVar =varNames {end}; 
predictorVars =varNames (1 :end-1 ); 
return 
end


if~isempty (responseVar )
[tf ,rname ]=internal .stats .isString (responseVar ,true ); 
iftf 
responseVar =rname ; 
if~ismember (responseVar ,varNames )
error (message ('stats:classreg:regr:FitObject:MissingResponse' )); 
end
else
error (message ('stats:classreg:regr:FitObject:BadResponseVar' ))
end
end


if~isempty (predictorVars )
[tf ,pcell ]=internal .stats .isStrings (predictorVars ); 
iftf 
predictorVars =pcell ; 
if~all (ismember (predictorVars ,varNames ))
error (message ('stats:classreg:regr:FitObject:InconsistentNames' )); 
end
elseifisValidIndexVector (varNames ,predictorVars )
predictorVars =varNames (predictorVars ); 
else
error (message ('stats:classreg:regr:FitObject:InconsistentNames' ))
end
end


ifisempty (predictorVars )
predictorVars =setdiff (varNames ,{responseVar }); 
elseifisempty (responseVar )

responseVar =setdiff (varNames ,predictorVars ); 
ifisscalar (responseVar )
responseVar =responseVar {1 }; 
else
error (message ('stats:classreg:regr:FitObject:AmbiguousResponse' )); 
end
else
if~ismember ({responseVar },varNames )||...
    ~all (ismember (predictorVars ,varNames ))||...
    ismember ({responseVar },predictorVars )
error (message ('stats:classreg:regr:FitObject:InconsistentNames' ))
end
end
end
end
function asCat =checkAsCat (isCat ,asCat ,nvars ,haveDataset ,VarNames )
[isVarIndices ,isInt ]=internal .stats .isIntegerVals (asCat ,1 ,nvars ); 
ifisVarIndices &&isvector (asCat )
where =asCat ; 
asCat =false (nvars ,1 ); 
asCat (where )=true ; 
elseifisInt &&isvector (asCat )
error (message ('stats:classreg:regr:FitObject:BadAsCategoricalIndices' )); 
elseifinternal .stats .isStrings (asCat )
[tf ,where ]=ismember (asCat ,VarNames ); 
if~all (tf )
error (message ('stats:classreg:regr:FitObject:BadAsCategoricalNames' )); 
end
asCat =false (nvars ,1 ); 
asCat (where )=true ; 
elseifislogical (asCat )&&isvector (asCat )
if(haveDataset &&length (asCat )~=nvars )||...
    (~haveDataset &&length (asCat )~=nvars -1 )
error (message ('stats:classreg:regr:FitObject:BadAsCategoricalLength' )); 
end
if~haveDataset 
asCat =[asCat (:)' ,false ]; 
end
else
error (message ('stats:classreg:regr:FitObject:BadAsCategoricalType' )); 
end
asCat =asCat (:)' ; 
asCat =(isCat |asCat ); 
end
end
end


function range =getVarRange (v ,asCat ,excl )
v (excl ,:)=[]; 
ifasCat 
ifisa (v ,'categorical' )


range =unique (v (:)); 
range =range (~isundefined (range )); 

else



[~,~,range ]=grp2idx (v ); 
end
if~ischar (range )
range =range (:)' ; 
end
elseifisnumeric (v )||islogical (v )
range =[min (v ,[],1 ),max (v ,[],1 )]; 
else
range =NaN (1 ,2 ); 
end
end



function tf =isValidIndexVector (A ,idx )
ifisempty (idx )
tf =true ; 
elseif~isvector (idx )
tf =false ; 
elseifislogical (idx )
tf =(length (idx )==length (A )); 
elseifisnumeric (idx )
tf =all (ismember (idx ,1 :length (A ))); 
else
tf =false ; 
end
end
