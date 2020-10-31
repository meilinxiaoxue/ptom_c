classdef (AllowedSubclasses ={?classreg .regr .Predictor })FitObject <classreg .regr .CompactFitObject &classreg .learning .internal .DisallowVectorOps &internal .matlab .variableeditor .VariableEditorPropertyProvider 











properties (GetAccess ='public' ,SetAccess ='protected' )




















ObservationInfo =table (zeros (0 ,1 ),false (0 ,1 ),false (0 ,1 ),false (0 ,1 ),...
    'VariableNames' ,{'Weights' ,'Excluded' ,'Missing' ,'Subset' }); 
end
properties (GetAccess ='protected' ,SetAccess ='protected' )
Data =[]; 
WorkingValues =struct ; 
end
properties (Dependent ,GetAccess ='public' ,SetAccess ='protected' )







Variables 









ObservationNames 
end

methods 
function vars =get .Variables (model )
compactNotAllowed (model ,'Variables' ,true ); 
vars =getVariables (model ); 
end
function onames =get .ObservationNames (model )
iffitFromDataset (model )
onames =model .Data .Properties .RowNames ; 
else
onames ={}; 
end
end
end

methods (Abstract ,Access ='protected' )
model =fitter (model ); 
end
methods (Abstract ,Static ,Access ='public' )
model =fit (varargin ); 
end

methods (Access ='protected' )

function model =doFit (model ,exclude )
ifnargin <2 
exclude =model .ObservationInfo .Excluded ; 
end


model =selectVariables (model ); 
model =selectObservations (model ,exclude ); 

model =fitter (model ); 
model =postFit (model ); 
model .IsFitFromData =true ; 



model .WorkingValues =[]; 
end


function model =assignData (model ,X ,y ,w ,asCat ,varNames ,excl )






ifisa (X ,'dataset' )
X =dataset2table (X ); 
end
haveDataset =isa (X ,'table' ); 


ifhaveDataset &&all (varfun (@ismatrix ,X ,'OutputFormat' ,'uniform' ))
[nobs ,nvars ]=size (X ); 
predLocs =1 :(nvars -1 ); 
respLoc =nvars ; 
elseifismatrix (X )&&ismatrix (y )

ifisvector (X )
X =X (:); 
end
[nobs ,p ]=size (X ); 
ifischar (X )
p =1 ; 
end
ifisvector (y )
y =y (:); 
end
ifsize (y ,1 )~=nobs 
error (message ('stats:classreg:regr:FitObject:PredictorResponseMismatch' )); 
end
nvars =p +1 ; 
predLocs =1 :(nvars -1 ); 
respLoc =nvars ; 
else
error (message ('stats:classreg:regr:FitObject:MatricesRequired' )); 
end


[excl ,predLocs ]=getDataVariable (excl ,nobs ,X ,predLocs ,respLoc ,'exclude' ); 
ifislogical (excl )
ifnumel (excl )~=nobs 
error (message ('stats:classreg:regr:FitObject:BadExcludeLength' ,nobs )); 
end
else
ifany (excl <0 )||any (excl >nobs )||any (excl ~=round (excl ))
error (message ('stats:classreg:regr:FitObject:BadExcludeValues' )); 
end
tmp =excl ; 
excl =false (nobs ,1 ); 
excl (tmp )=true ; 
end
ifall (excl )
error (message ('stats:classreg:regr:FitObject:AllExcluded' )); 
end


ifhaveDataset 
viName =X .Properties .VariableNames ; 
viClass =varfun (@class ,X ,'OutputFormat' ,'cell' ); 



viInModel =[true (1 ,nvars -1 ),false ]; 

viIsCategorical =varfun (@internal .stats .isDiscreteVar ,X ,'OutputFormat' ,'uniform' ); 

if~isempty (asCat )
viIsCategorical =classreg .regr .FitObject .checkAsCat (viIsCategorical ,asCat ,nvars ,true ,viName ); 
end
viRange =cell (nvars ,1 ); 
fori =1 :nvars 
vi =X .(viName {i }); 
vir =getVarRange (vi ,viIsCategorical (i ),excl ); 
ifiscellstr (vi )&&isvector (vi )&&...
    (numel (unique (strtrim (vir )))<numel (vir ))
X .(viName {i })=strtrim (X .(viName {i })); 
vir =getVarRange (X .(viName {i }),viIsCategorical (i ),excl ); 
end
viRange {i }=vir ; 
end

data =X ; 
obsNames =X .Properties .RowNames ; 
elseifismatrix (X )&&ismatrix (y )

viName =varNames ; 
viClass =[repmat ({class (X )},1 ,p ),{class (y )}]; 


viInModel =[true (1 ,p ),false ]; 

viIsCategorical =[repmat (internal .stats .isDiscreteVar (X ),1 ,p ),internal .stats .isDiscreteVar (y )]; 
if~isempty (asCat )
viIsCategorical =classreg .regr .FitObject .checkAsCat (viIsCategorical ,asCat ,nvars ,false ,viName ); 
end
viRange =cell (nvars ,1 ); 
if~any (viIsCategorical )

viMax =max (X (~excl ,:),[],1 ); 
viMin =min (X (~excl ,:),[],1 ); 
temp =[viMin (:),viMax (:)]; 
viRange (1 :nvars -1 )=mat2cell (temp ,ones (size (temp ,1 ),1 ),2 ); 
else
fori =1 :(nvars -1 )
viRange {i }=getVarRange (X (:,i ),viIsCategorical (i ),excl ); 
end
end
viRange {end}=getVarRange (y ,viIsCategorical (end),excl ); 

data =struct ('X' ,{X },'y' ,{y }); 
obsNames ={}; 
end

[w ,predLocs ]=getDataVariable (w ,nobs ,X ,predLocs ,respLoc ,'weights' ); 
ifisempty (w )
w =ones (nobs ,1 ); 
elseifany (w <0 )||numel (w )~=nobs 
error (message ('stats:classreg:regr:FitObject:BadWeightValues' ,nobs )); 
end



model .Data =data ; 
model .PredLocs =predLocs ; 
model .RespLoc =respLoc ; 
model .VariableInfo =table (viClass (:),viRange (:),viInModel (:),viIsCategorical (:),...
    'VariableNames' ,{'Class' ,'Range' ,'InModel' ,'IsCategorical' },...
    'RowNames' ,viName ); 
model .ObservationInfo =table (w ,excl ,false (nobs ,1 ),false (nobs ,1 ),...
    'VariableNames' ,{'Weights' ,'Excluded' ,'Missing' ,'Subset' },...
    'RowNames' ,obsNames ); 
model .NumObservations_ =sum (~excl ); 
end


function model =updateVarRange (model )




vrange =model .VariableInfo .Range ; 
vcat =model .VariableInfo .IsCategorical ; 
excl =~model .ObservationInfo .Subset ; 
vclass =ismember (model .VariableInfo .Class ,{'nominal' ,'ordinal' ,'categorical' }); 

model .IsFitFromTable =fitFromDataset (model ); 
ifmodel .IsFitFromTable 
vnames =model .Data .Properties .VariableNames ; 
fori =1 :length (vnames )
if~vcat (i )&&~vclass (i )
vrange {i }=getVarRange (model .Data .(vnames {i }),vcat (i ),excl ); 
end
end
else
nx =size (model .Data .X ,2 ); 
fori =1 :nx 
if~vcat (i )
vrange {i }=getVarRange (model .Data .X (:,i ),vcat (i ),excl ); 
end
end
if~vclass (nx +1 )
vrange {nx +1 }=getVarRange (model .Data .y ,vcat (nx +1 ),excl ); 
end
end
model .VariableInfo .Range =vrange ; 
end


function model =selectVariables (model )


model .VariableInfo .InModel (:)=false ; 
model .VariableInfo .InModel (model .PredLocs )=true ; 

haveDataset =fitFromDataset (model ); 
ifhaveDataset 
data =model .Data ; 
isNumVar =varfun (@isnumeric ,data ,'OutputFormat' ,'uniform' ); 
isNumVec =isNumVar &varfun (@isvector ,data ,'OutputFormat' ,'uniform' ); 
isCatVec =varfun (@internal .stats .isDiscreteVec ,data ,'OutputFormat' ,'uniform' ); 
switchmodel .PredictorTypes 
case 'numeric' 
if~all (isNumVar (model .PredLocs ))
error (message ('stats:classreg:regr:FitObject:PredictorMatricesNotNumeric' )); 
end
case 'mixed' 
if~all (isNumVec (model .PredLocs )|isCatVec (model .PredLocs ))
error (message ('stats:classreg:regr:FitObject:PredictorMatricesRequired' )); 
end
otherwise

end
isNumVecY =isNumVec (model .RespLoc ); 
isCatVecY =isCatVec (model .RespLoc ); 

else
X =model .Data .X ; 
isNumVarX =isnumeric (X )||islogical (X ); 
isCatVecX =isa (X ,'categorical' )&&isvector (X ); 
switchmodel .PredictorTypes 
case 'numeric' 
if~isNumVarX 
error (message ('stats:classreg:regr:FitObject:PredictorMatricesNotNumeric' )); 
end
case 'mixed' 
if~(isNumVarX ||isCatVecX )
error (message ('stats:classreg:regr:FitObject:PredictorMatricesRequired' )); 
end
otherwise

end
y =model .Data .y ; 
isNumVecY =isnumeric (y )&&isvector (y ); 
isCatVecY =internal .stats .isDiscreteVec (y ); 
end


ifisCatVecY &&strcmp (model .ResponseType ,'numeric' )...
    &&strcmp (model .VariableInfo .Class (model .RespLoc ),'logical' )
model .VariableInfo .IsCategorical (model .RespLoc )=false ; 
isCatVecY =false ; 
isNumVecY =true ; 
end

switchmodel .ResponseType 
case 'numeric' 
if~isNumVecY 
error (message ('stats:classreg:regr:FitObject:NonNumericResponse' )); 
end
case 'categorical' 
if~isCatVecY 
error (message ('stats:classreg:regr:FitObject:NonCategoricalResponse' )); 
end
otherwise

end
ifmodel .VariableInfo .IsCategorical (model .RespLoc )&&~strcmp (model .ResponseType ,'categorical' )
error (message ('stats:classreg:regr:FitObject:ResponseTypeMismatch' )); 
end
end


function model =selectObservations (model ,exclude ,missing )





nobs =size (model .ObservationInfo ,1 ); 
haveDataset =fitFromDataset (model ); 


ifnargin <3 ||isempty (missing )
ifhaveDataset 
vn =model .VariableNames ; 
y =model .Data .(vn {model .RespLoc }); 
missing =internal .stats .hasMissingVal (y (:,1 )); 
forj =model .PredLocs 
x =model .Data .(vn {j }); 
missing =missing |internal .stats .hasMissingVal (x ); 
end
elseifisnumeric (model .Data .X )
missing =any (isnan (model .Data .X ),2 )|isnan (model .Data .y (:,1 )); 
elseifisa (model .Data .X ,'categorical' )
missing =any (isundefined (model .Data .X ),2 )|isnan (model .Data .y (:,1 )); 
else
missing =isnan (model .Data .y (:,1 )); 
end
else
if~isvector (missing )||length (missing )~=nobs 
error (message ('stats:classreg:regr:FitObject:BadMissingLength' )); 
end
missing =missing (:); 
end

ifisempty (exclude )
exclude =false (nobs ,1 ); 
else
[isObsIndices ,isInt ]=internal .stats .isIntegerVals (exclude ,1 ,nobs ); 
ifisObsIndices &&isvector (exclude )
where =exclude ; 
exclude =false (nobs ,1 ); 
exclude (where )=true ; 
elseifisInt &&all (exclude >0 )&&isvector (exclude )
error (message ('stats:classreg:regr:FitObject:BadExcludeIndices' )); 
elseifhaveDataset &&internal .stats .isStrings (exclude )
[tf ,where ]=ismember (exclude ,X .Properties .ObsNames ); 
if~all (tf )
error (message ('stats:classreg:regr:FitObject:BadExcludeNames' )); 
end
exclude =false (nobs ,1 ); 
exclude (where )=true ; 
elseifislogical (exclude )&&isvector (exclude )
iflength (exclude )~=nobs 
error (message ('stats:classreg:regr:FitObject:BadExcludeLength' ,nobs )); 
end
else
error (message ('stats:classreg:regr:FitObject:BadExcludeType' )); 
end
end
exclude =exclude (:); 

subset =~(missing |exclude ); 
model .ObservationInfo .Missing =missing ; 
model .ObservationInfo .Excluded =exclude ; 
model .ObservationInfo .Subset =subset ; 
model .NumObservations_ =sum (subset ); 
end


function model =postFit (model )
end


function tf =hasData (model )
tf =~isempty (model .Data ); 
end
function tf =fitFromDataset (model )
tf =isa (model .Data ,'dataset' )||isa (model .Data ,'table' ); 
end

function compactNotAllowed (model ,name ,isprop )
if~hasData (model )


ifisprop 
error (message ('stats:classreg:regr:FitObject:CompactProperty' ,name )); 
else
error (message ('stats:classreg:regr:FitObject:CompactMethod' ,name )); 
end
end
end


function vars =getVariables (model ,iobs ,varargin )



ifnargin <2 
iobs =':' ; 
varargin {1 }=1 :model .NumVariables ; 
end
iffitFromDataset (model )
vars =model .Data (iobs ,varargin {:}); 
else

Xvars =num2cell (model .Data .X (iobs ,:),1 ); 
vars =table (Xvars {:},model .Data .y (iobs ,:),'VariableNames' ,model .VariableNames ); 
vars =vars (:,varargin {:}); 
end
end


function [varData ,varName ,varNum ]=getVar (model ,var )


[varName ,varNum ]=identifyVar (model ,var ); 
iffitFromDataset (model )
varData =model .Data .(varName ); 
else
ifvarNum <model .NumVariables 
varData =model .Data .X (:,varNum ); 
else
varData =model .Data .y ; 
end
end
t =~model .ObservationInfo .Subset ; 
ifany (t )
ifisnumeric (varData )
varData (t )=NaN ; 
elseifisa (varData ,'categorical' )
varData (t )={'' }; 
end
end
end


function var =getResponse (model )

iffitFromDataset (model )
var =model .Data .(model .VariableNames {model .RespLoc }); 
else
var =model .Data .y ; 
end
end

function X =getData (model )
iffitFromDataset (model )
X =model .Data ; 
else
X =model .Data .X ; 
end
end


function [Xeval ,respSz ]=preEval (model ,toMatrix ,varargin )





p =model .NumPredictors ; 
ifisa (varargin {1 },'dataset' )
varargin {1 }=dataset2table (varargin {1 }); 
end
ifisscalar (varargin )&&isa (varargin {1 },'table' )
Xeval =varargin {1 }; 
[tf ,predLocs ]=ismember (model .PredictorNames ,Xeval .Properties .VariableNames ); 
if~all (tf )
error (message ('stats:classreg:regr:FitObject:BadPredictorName' )); 
elseif~reconcilePredictorTypes (model ,Xeval )
error (message ('stats:classreg:regr:FitObject:BadPredictorType' )); 
end
respSz =[size (Xeval ,1 ),1 ]; 
iftoMatrix 
Xeval =varfun (@(x )x ,Xeval ,'InputVariables' ,predLocs ); 
Xeval =cat (2 ,Xeval {:}); 
end
elseif(nargin -2 )==p 

Xeval =varargin ; 
if~reconcilePredictorTypes (model ,Xeval )
error (message ('stats:classreg:regr:FitObject:BadPredictorType' )); 
end
ifp >1 
varSz =size (Xeval {1 }); 
if~all (cellfun (@(v )isequal (size (v ),varSz ),Xeval ))
error (message ('stats:classreg:regr:FitObject:PredictorSizeMismatch' )); 
end
end
respSz =varSz ; 
iftoMatrix 
Xeval =cat (length (varSz )+1 ,Xeval {:}); 
Xeval =reshape (Xeval ,prod (varSz ),p ); 
end
elseifisscalar (varargin )
Xeval =varargin {1 }; 
ifisnumeric (Xeval )&&ismatrix (Xeval )
ifsize (Xeval ,2 )~=p 
error (message ('stats:classreg:regr:FitObject:BadPredictorColumns' )); 
elseif~reconcilePredictorTypes (model ,Xeval )
error (message ('stats:classreg:regr:FitObject:BadPredictorType' )); 
end
respSz =[size (Xeval ,1 ),1 ]; 
if~toMatrix 
Xeval =num2cell (Xeval ,1 ); 
end
else
error (message ('stats:classreg:regr:FitObject:BadPredictorInput' )); 
end
else
error (message ('stats:classreg:regr:FitObject:BadPredictorCount' ))
end
end
end

methods (Hidden ,Access ='public' )

function [varargout ]=subsref (a ,s )
switchs (1 ).type 
case '()' 
error (message ('stats:classreg:regr:FitObject:ParenthesesNotAllowed' )); 
case '{}' 
error (message ('stats:classreg:regr:FitObject:NoCellIndexing' )); 
case '.' 



ifstrcmp (s (1 ).subs ,'Variables' )&&~isscalar (s )&&...
    ~(isequal (s (2 ).type ,'.' )&&isequal (s (2 ).subs ,'Properties' ))
ifisequal (s (2 ).type ,'.' )
p =getVar (a ,s (2 ).subs ); 
else
p =getVariables (a ,s (2 ).subs {:}); 
end
iflength (s )>2 
[varargout {1 :nargout }]=builtin ('subsref' ,p ,s (3 :end)); 
else
[varargout {1 :min (nargout ,1 )}]=p ; 
end
else



[varargout {1 :nargout }]=builtin ('subsref' ,a ,s ); 
end
end
end
end

methods (Hidden ,Static ,Access ='public' )
function model =loadobj (obj )
ifisa (obj .VariableInfo ,'dataset' )
obj .VariableInfo =dataset2table (obj .VariableInfo ); 
end
ifisa (obj .ObservationInfo ,'dataset' )
obj .ObservationInfo =dataset2table (obj .ObservationInfo ); 
end
ifisa (obj .Data ,'dataset' )
obj .Data .Properties .Description ='' ; 
obj .Data =dataset2table (obj .Data ); 
end
obj .NumObservations_ =sum (obj .ObservationInfo .Subset ); 
model =obj ; 
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

function [w ,predLocs ]=getDataVariable (w ,~,X ,predLocs ,respLoc ,vtype )
ifisempty (w )
return 
end
ifisa (X ,'dataset' )
X =dataset2table (X ); 
end
ifisa (X ,'table' )&&internal .stats .isString (w )
[tf ,wloc ]=ismember (w ,X .Properties .VariableNames ); 
if~tf 
error (message ('stats:classreg:regr:FitObject:BadVariableName' ,vtype ,w )); 
end
w =X .(w ); 
predLocs =setdiff (predLocs ,wloc ); 
ifwloc ==respLoc 
respLoc =max (predLocs ); 
predLocs =setdiff (predLocs ,respLoc ); 
end
end
if~(isnumeric (w )||islogical (w ))||~isvector (w )||~isreal (w )
error (message ('stats:classreg:regr:FitObject:BadVariableValues' ,vtype )); 
end
w =w (:); 
end
