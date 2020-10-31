function [Xout ,Y ,vrange ,wastable ,args ]=table2FitMatrix (X ,Y ,varargin )































args =varargin ; 

pnames ={'ResponseName' ,'Weights' ,'PredictorNames' ,'CategoricalPredictors' ,'OrdinalIsCategorical' }; 
[ResponseName ,ResponseIndex ,WeightsName ,WeightsIndex ,...
    PredictorNames ,PredictorIndex ,CategoricalPredictors ,CategoricalIndex ,...
    OrdinalIsCategorical ,OrdinalIsCategoricalIndex ]=...
    processArgs (pnames ,args ); 
args =removeArg (OrdinalIsCategoricalIndex ,args ); 
if~isempty (ResponseName )&&~internal .stats .isString (ResponseName )
error (message ('stats:classreg:learning:internal:utils:BadResponseName' )); 
end


ifisa (X ,'dataset' )
X =dataset2table (X ); 
end
wastable =istable (X ); 
if~wastable 
vrange ={}; 
Xout =X ; 
return 
end
VarNames =X .Properties .VariableNames ; 


if~isempty (WeightsName )
ifinternal .stats .isString (WeightsName )
WeightsName =resolveName ('WeightsName' ,WeightsName ,'' ,true ,VarNames ); 
W =X .(WeightsName ); 
args =updateArgs ('WeightsName' ,W ,WeightsIndex ,args ); 
else
WeightsName ='' ; 
end
end




[FormulaResponseName ,FormulaPredictorNames ]=processFormula (VarNames ,Y ); 


if~isempty (Y )
ifinternal .stats .isString (Y )

ResponseName =resolveName ('ResponseName' ,ResponseName ,FormulaResponseName ,false ,VarNames ); 
args =updateArgs ('ResponseName' ,ResponseName ,ResponseIndex ,args ); 
Y =X .(ResponseName ); 
elseifistable (Y )

ifwidth (Y )~=1 
error (message ('stats:classreg:learning:internal:utils:TableResponse' )); 
end
ResponseName =Y .Properties .VariableNames {1 }; 
args =updateArgs ('ResponseName' ,ResponseName ,ResponseIndex ,args ); 
Y =Y {:,1 }; 
elseif~isempty (ResponseName )

ifismember (ResponseName ,VarNames )
error (message ('stats:classreg:learning:internal:utils:AmbiguousResponse' ,ResponseName )); 
end
end
end

PredictorNames =resolveName ('PredictorNames' ,PredictorNames ,FormulaPredictorNames ,true ,VarNames ,true ); 
ifisempty (PredictorNames )
PredictorNames =VarNames ; 
if~isempty (ResponseName )||~isempty (WeightsName )
PredictorNames =setdiff (PredictorNames ,{ResponseName ,WeightsName },'stable' ); 
end
end
args =updateArgs ('PredictorNames' ,PredictorNames ,PredictorIndex ,args ); 

ifismember (ResponseName ,PredictorNames )
error (message ('stats:classreg:learning:internal:utils:ResponseIsPredictor' ))
end

ifisequal (CategoricalPredictors ,'all' )
CategoricalPredictors =PredictorNames ; 
end

[Xout ,vrange ,CategoricalPredictors ]=makeXMatrix (X ,PredictorNames ,CategoricalPredictors ,OrdinalIsCategorical ); 
args =updateArgs ('CategoricalPredictors' ,CategoricalPredictors ,CategoricalIndex ,args ); 
end

function idx =makeCategoricalIndex (CategoricalPredictors ,PredictorNames )

p =numel (PredictorNames ); 
idx =CategoricalPredictors ; 
ifisempty (CategoricalPredictors )
idx =false (1 ,p ); 
elseifislogical (CategoricalPredictors )
ifnumel (idx )~=p ||~isvector (idx )
error (message ('stats:classreg:learning:internal:utils:CategoricalBadLogical' ,p ))
end
elseifinternal .stats .isStrings (CategoricalPredictors )
tf =ismember (CategoricalPredictors ,PredictorNames ); 
if~all (tf )
error (message ('stats:classreg:learning:internal:utils:CategoricalNotPredictor' ))
end
idx =ismember (PredictorNames ,CategoricalPredictors ); 
elseifisvector (idx )&&isnumeric (idx )&&all (idx ==round (idx ))&&numel (idx )==numel (unique (idx ))
ifany (idx <1 )||any (idx >p )
error (message ('stats:classreg:learning:FullClassificationRegressionModel:prepareDataCR:BadCatPredIntegerIndex' ,p )); 
else
idx =ismember (1 :p ,idx ); 
end
else
error (message ('stats:classreg:learning:internal:utils:BadCategorical' ))
end
end

function [Xout ,vrange ,catidx ]=makeXMatrix (X ,PredictorNames ,CategoricalPredictors ,OrdinalIsCategorical )

catidx =makeCategoricalIndex (CategoricalPredictors ,PredictorNames ); 
waslogical =islogical (CategoricalPredictors ); 

n =size (X ,1 ); 
p =numel (PredictorNames ); 

ifisempty (OrdinalIsCategorical )
OrdinalIsCategorical =true ; 
end

vrange =cell (1 ,p ); 
Xout =zeros (n ,p ); 
forj =1 :p 


pname =PredictorNames {j }; 
x =X .(pname ); 
ifinternal .stats .isDiscreteVec (x )


ifwaslogical &&~catidx (j )
error (message ('stats:classreg:learning:internal:utils:CategoricalConflict' ,pname )); 
end
end
ifischar (x )

x =cellstr (x ); 
elseifiscellstr (x )||isstring (x )

x =strtrim (x ); 
elseifiscell (x )
error (message ('stats:classreg:learning:internal:utils:BadVariableType' ,pname ))
end
if~iscolumn (x )
error (message ('stats:classreg:learning:internal:utils:BadVariableSize' ,pname ))
end
ifislogical (x )||iscell (x )||isstring (x )||...
    (iscategorical (x )&&(OrdinalIsCategorical ||~isordinal (x )))

catidx (j )=true ; 
end
ifcatidx (j )||iscategorical (x )

[vrj ,~,x ]=unique (x ); 
ifisnumeric (vrj )&&any (isnan (vrj ))

vrj (isnan (vrj ))=[]; 
x (x >length (vrj ))=NaN ; 
elseifiscategorical (vrj )&&any (isundefined (vrj ))

vrj (isundefined (vrj ))=[]; 
x (x >length (vrj ))=NaN ; 
elseifiscellstr (vrj )


empties =cellfun ('isempty' ,vrj ); 
newvrj =sort (vrj (~empties ,:)); 
[~,newx ]=ismember (vrj ,newvrj ); 
x =newx (x ); 
vrj =newvrj ; 
x (x ==0 )=NaN ; 
end
vrange {j }=vrj ; 
end
if~isnumeric (x )&&~islogical (x )
error (message ('stats:classreg:learning:internal:utils:BadVariableType' ,pname ))
end
Xout (:,j )=x ; 
end
end


function ArgName =resolveName (ParameterName ,ArgName ,FormulaName ,emptyok ,VarNames ,wantcell )
ifnargin <6 
wantcell =false ; 
end
ifisempty (ArgName )
ifisempty (FormulaName )&&~emptyok 
error (message ('stats:classreg:learning:internal:utils:MissingArg' ,ParameterName ))
end
ArgName =FormulaName ; 
elseif~isempty (FormulaName )
if~all (strcmp (FormulaName ,ArgName ))
error (message ('stats:classreg:learning:internal:utils:ConflictingArg' ,ParameterName ))
end
end
ifischar (ArgName )&&(wantcell ||~isrow (ArgName ))
ArgName =cellstr (ArgName ); 
end
if~isempty (ArgName )&&(~internal .stats .isStrings (ArgName )...
    ||~all (ismember (ArgName ,VarNames ))...
    ||(iscell (ArgName )&&numel (ArgName )~=numel (unique (ArgName ))))
error (message ('stats:classreg:learning:internal:utils:InvalidArg' ,ParameterName ))
end
end

function args =updateArgs (ParameterName ,ArgName ,ArgIndex ,args )
if~isempty (ArgName )
ifArgIndex >0 
args {ArgIndex }=ArgName ; 
else
args (end+1 :end+2 )={ParameterName ,ArgName }; 
end
end
end
function args =removeArg (ArgIndex ,args )
ifArgIndex >0 
args (ArgIndex -1 :ArgIndex )=[]; 
end
end


function [FormulaResponseName ,FormulaPredictorNames ]=processFormula (VarNames ,Y )

ifisvarname (Y )
FormulaResponseName =Y ; 
FormulaPredictorNames ={}; 
elseifinternal .stats .isString (Y )
formula =classreg .regr .LinearFormula (Y ,VarNames ); 
termorder =sum (formula .Terms ,2 ); 
ifany (termorder >1 )
error (message ('stats:classreg:learning:internal:utils:LinearOnly' ))
end
FormulaResponseName =formula .ResponseName ; 
FormulaPredictorNames =formula .PredictorNames ; 
else
FormulaResponseName ='' ; 
FormulaPredictorNames ={}; 
end
end


function [varargout ]=processArgs (pnames ,args )

n =numel (pnames ); 
varargout =cell (1 ,2 *n ); 
forj =1 :n 
varargout {2 *j -1 }='' ; 
varargout {2 *j }=0 ; 
end

forj =1 :2 :length (args )-1 
pname =args {j }; 
ifinternal .stats .isString (pname )
argnum =find (strncmpi (pname ,pnames ,length (pname ))); 
ifisscalar (argnum )
varargout {2 *argnum -1 }=args {j +1 }; 
varargout {2 *argnum }=j +1 ; 
end
end
end
end

