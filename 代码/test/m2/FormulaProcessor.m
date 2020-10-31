classdef FormulaProcessor 



properties (Abstract ,Constant ,GetAccess ='protected' )
rules 
p 
irules 
end
properties (Abstract ,Access ='protected' )
isMultivariate 
end
properties (Constant ,GetAccess ='protected' )
allElseStr ='...' ; 
end

properties (GetAccess ='protected' ,SetAccess ='protected' )
tree =[]; 
str ='y ~ 0' ; 


responseName ='y' ; 
varNames ={'y' }; 
link ='identity' ; 
terms =zeros (0 ,1 ); 
end

properties (GetAccess ='public' ,SetAccess ='protected' )
FunctionCalls =cell (1 ,0 ); 
end

properties (Dependent ,GetAccess ='public' ,SetAccess ='public' )
ResponseName 
VariableNames 
Link 
Terms 
end
properties (Dependent ,GetAccess ='public' ,SetAccess ='protected' )
ModelFun 
InModel 
LinearPredictor 
PredictorNames 
TermNames 
HasIntercept 
NTerms 
NVars 
NPredictors 
end
methods 
function terms =get .Terms (f )
terms =f .terms ; 
end
function f =set .Terms (f ,update )
ifclassreg .regr .FormulaProcessor .isTermsMatrix (update )
ifsize (update ,2 )~=size (f .terms ,2 )
error (message ('stats:classreg:regr:LinearFormula:TermsBadColumns' ,size (f .terms ,2 ))); 
end
f .terms =removeDupRows (update ); 
elseifinternal .stats .isString (update )
[ustr ,utree ]=parseStr (f ,update ); 
ifutree (1 ,1 )~=f .irules .LinearPredictor 
error (message ('stats:classreg:regr:LinearFormula:TermsBadLinearPredictor' )); 
end
f .terms =sortTerms (createTerms (f ,utree ,ustr ,1 ,f .varNames )); 
else
error (message ('stats:classreg:regr:LinearFormula:TermsMatrixOrString' )); 
end
f .str =getStr (f ); 
end
function link =get .Link (f )
link =f .link ; 
end
function f =set .Link (f ,update )
dfswitchyard ('stattestlink' ,update ,'double' ); 
f .link =update ; 
f .str =getStr (f ); 
end
function name =get .ResponseName (f )
name =f .responseName ; 
end
function f =set .ResponseName (f ,update )
if~internal .stats .isString (update )
error (message ('stats:classreg:regr:LinearFormula:ResponseNameNotString' )); 
end
f .responseName =update ; 
f .str =getStr (f ); 
end
function names =get .VariableNames (f )
names =f .varNames ; 
end
function f =set .VariableNames (f ,update )
[tf ,update ]=internal .stats .isStrings (update ); 
if~tf ||length (update )~=size (f .terms ,2 )
error (message ('stats:classreg:regr:LinearFormula:BadVariableNames' ,size (f .terms ,2 ))); 
end
f .varNames =update ; 
f .str =getStr (f ); 
end

function fun =get .ModelFun (~)
fun =@(b ,X )X *b ; 
end
function tf =get .InModel (f )
tf =any (f .terms >0 ,1 ); 
end
function names =get .PredictorNames (f )
names =f .varNames (f .InModel ); 
end
function names =get .TermNames (f )
names =classreg .regr .modelutils .terms2names (f .terms ,f .varNames ); 
end
function tf =get .HasIntercept (f )




tf =any (all (f .terms ==0 ,2 ),1 ); 
end
function expr =get .LinearPredictor (f )
expr =terms2expr (f .terms ,f .varNames ); 
end
function n =get .NVars (f )
n =size (f .terms ,2 ); 
end
function n =get .NPredictors (f )
n =sum (f .InModel ); 
end
function n =get .NTerms (f )
n =size (f .terms ,1 ); 
end
end

methods (Access ='public' )
function f =FormulaProcessor (modelSpec ,varNames ,responseVar ,hasIntercept ,link )
ifnargin <1 ,return ,end

ifnargin <2 ,varNames =[]; end
ifnargin <3 ,responseVar =[]; end
ifnargin <4 ,hasIntercept =[]; end
ifnargin <5 ,link =[]; end

ifclassreg .regr .FormulaProcessor .isTermsMatrix (modelSpec )





nvars =size (modelSpec ,2 ); 
ifisMissingArg (varNames )

elseifinternal .stats .isStrings (varNames ,true )
ifnumel (varNames )~=nvars 
error (message ('stats:classreg:regr:LinearFormula:BadVarNameLength' )); 
end
varNames =mustBeUnique (asCellStr (varNames )); 
else
error (message ('stats:classreg:regr:LinearFormula:BadVarNameValue' )); 
end
ifisMissingArg (responseVar )
respLoc =find (all (modelSpec ==0 ,1 )); 
if~isscalar (respLoc )
error (message ('stats:classreg:regr:LinearFormula:UndeterminedResponse' )); 
end
ifisMissingArg (varNames )
responseName ='y' ; %#ok<*PROP> 
else
responseName =varNames {respLoc }; 
end
elseifinternal .stats .isString (responseVar )
responseName =responseVar ; 
ifisMissingArg (varNames )
respLoc =find (all (modelSpec ==0 ,1 )); 
if~isscalar (respLoc )
error (message ('stats:classreg:regr:LinearFormula:UndeterminedResponse' )); 
end
else
respLoc =find (strcmp (responseName ,varNames )); 
ifisempty (respLoc )
error (message ('stats:classreg:regr:LinearFormula:BadResponseName' )); 
elseifany (modelSpec (:,respLoc )~=0 )
error (message ('stats:classreg:regr:LinearFormula:ResponseInTerms' )); 
end
end
elseifinternal .stats .isScalarInt (responseVar ,1 ,nvars )
respLoc =responseVar ; 
ifany (modelSpec (:,respLoc )~=0 )
error (message ('stats:classreg:regr:LinearFormula:ResponseIsPredictor' )); 
end
ifisMissingArg (varNames )
responseName ='y' ; 
else
responseName =varNames {respLoc }; 
end
else
error (message ('stats:classreg:regr:LinearFormula:ResponseNameOrNumber' )); 
end
ifisMissingArg (varNames )
varNames ={}; 
varNames ([1 :(respLoc -1 ),(respLoc +1 ):nvars ])=internal .stats .numberedNames ('x' ,1 :nvars -1 ); 
varNames {respLoc }=responseName ; 
end
ifisMissingArg (link )
link ='identity' ; 
end
f .terms =removeDupRows (modelSpec ); 
f .varNames =varNames ; 
f .responseName =responseName ; 
ifsize (f .terms ,1 )<size (modelSpec ,1 )
warning (message ('stats:classreg:regr:LinearFormula:RemoveDupTerms' )); 
end
f .link =link ; 
f .FunctionCalls =cell (1 ,0 ); 
f .str =composeFormulaString (f .link ,f .responseName ,terms2expr (f .terms ,f .varNames )); 



if~isMissingArg (hasIntercept )&&~isequal (hasIntercept ,f .HasIntercept )
error (message ('stats:classreg:regr:LinearFormula:InterceptFlagConflict' )); 
end
elseifclassreg .regr .FormulaProcessor .isModelAlias (modelSpec )...
    ||(iscell (modelSpec )&&classreg .regr .FormulaProcessor .isModelAlias (modelSpec {1 }))









ifisMissingArg (varNames )
error (message ('stats:classreg:regr:LinearFormula:MissingVarNameNumber' )); 
elseifinternal .stats .isStrings (varNames )
varNames =mustBeUnique (asCellStr (varNames )); 
haveVarNames =true ; 
nvars =numel (varNames ); 
elseifinternal .stats .isScalarInt (varNames )
haveVarNames =false ; 
nvars =varNames ; 


else
error (message ('stats:classreg:regr:LinearFormula:BadVarNames' )); 
end
ifisMissingArg (responseVar )


responseName =[]; 
respLoc =[]; 
elseifinternal .stats .isString (responseVar )
responseName =responseVar ; 
respLoc =[]; 
elseifinternal .stats .isScalarInt (responseVar ,1 ,nvars )
responseName =[]; 
respLoc =responseVar ; 
elseifislogical (responseVar )&&isvector (responseVar )&&...
    length (responseVar )<=nvars &&...
    (sum (responseVar )==1 ||f .isMultivariate )
responseName =[]; 
respLoc =find (responseVar ); 
else
error (message ('stats:classreg:regr:LinearFormula:InvalidResponseName' )); 
end
ifiscell (modelSpec )
alias =modelSpec {1 }; 
predVars =modelSpec {2 }; 

[isVarIndices ,isInt ]=internal .stats .isIntegerVals (predVars ,1 ,nvars ); 
ifisVarIndices &&isvector (predVars )
where =predVars ; 
predVars =false (nvars ,1 ); predVars (where )=true ; 
elseifisInt &&isvector (predVars )
error (message ('stats:classreg:regr:LinearFormula:PredictorsOutOfRange' )); 
elseifinternal .stats .isStrings (predVars )
ifhaveVarNames 
[tf ,predLocs ]=ismember (predVars ,varNames ); 
if~all (tf )
error (message ('stats:classreg:regr:LinearFormula:PredictorNotVar' )); 
end
predVars =false (1 ,nvars ); predVars (predLocs )=true ; 
else
predVars =[true (1 ,nvars -1 ),false ]; 
end
elseifislogical (predVars )&&isvector (predVars )
iflength (predVars )~=nvars 
error (message ('stats:classreg:regr:LinearFormula:BadPredictorVarLength' )); 
end
else
error (message ('stats:classreg:regr:LinearFormula:BadPredictorVarType' )); 
end
ifhaveVarNames 
ifisempty (responseName )
ifisscalar (respLoc )
responseName =varNames {respLoc }; 
elseifsum (predVars )==nvars -1 
responseName =varNames {~predVars }; 
else
error (message ('stats:classreg:regr:LinearFormula:AmbiguousResponse' )); 
end
else
respLoc =find (strcmp (responseName ,varNames )); 
ifisempty (respLoc )
error (message ('stats:classreg:regr:LinearFormula:BadResponseName' )); 
elseifpredVars (respLoc )
error (message ('stats:classreg:regr:LinearFormula:ResponseIsPredictor' )); 
end
end
else
ifisempty (respLoc )
respLoc =find (~predVars ); 
if~isscalar (respLoc )
error (message ('stats:classreg:regr:LinearFormula:AmbiguousResponse' )); 
end
else
ifpredVars (respLoc )
error (message ('stats:classreg:regr:LinearFormula:ResponseIsPredictor' )); 
end
end
ifisempty (responseName )
responseName ='y' ; 
end
varNames ={}; 
varNames ([1 :(respLoc -1 ),(respLoc +1 ):nvars ])=internal .stats .numberedNames ('x' ,1 :nvars -1 ); 
varNames {respLoc }=responseName ; 
end
else
alias =modelSpec ; 
ifhaveVarNames 
ifisempty (responseName )
ifisempty (respLoc )
respLoc =nvars ; 
end
responseName =varNames {respLoc }; 
else
respLoc =find (strcmp (responseName ,varNames )); 
ifisempty (respLoc )
error (message ('stats:classreg:regr:LinearFormula:BadResponseName' )); 
end
end
else
ifisempty (responseName )
responseName ='y' ; 
end
ifisempty (respLoc )
respLoc =nvars ; 
end
varNames ={}; 
varNames ([1 :(respLoc -1 ),(respLoc +1 ):nvars ])=internal .stats .numberedNames ('x' ,1 :nvars -1 ); 
varNames {respLoc }=responseName ; 
end
predVars =true (1 ,nvars ); predVars (respLoc )=false ; 
end
ifisMissingArg (hasIntercept )
hasIntercept =true ; 
elseif~islogical (hasIntercept )||~isscalar (hasIntercept )
error (message ('stats:classreg:regr:LinearFormula:BadHasIntercept' )); 
end
ifisMissingArg (link )
link ='identity' ; 
end
f .terms =classreg .regr .modelutils .model2terms (alias ,predVars ,hasIntercept ); 
f .responseName =responseName ; 
f .varNames =varNames ; 
f .link =link ; 
f .FunctionCalls =cell (1 ,0 ); 
f .str =composeFormulaString (f .link ,f .responseName ,terms2expr (f .terms ,f .varNames )); 

elseifinternal .stats .isString (modelSpec )




[f .str ,f .tree ]=parseStr (f ,modelSpec ); 
iff .tree (1 ,1 )~=f .irules .Formula 
error (message ('stats:classreg:regr:LinearFormula:InvalidFormula' ,modelSpec )); 
end

ifisMissingArg (varNames )
[f .str ,f .tree ]=substituteForAllElse (f ,{}); 
varNames =getPredictorAndResponseNames (f ); 
elseifinternal .stats .isStrings (varNames ,true )
varNames =mustBeUnique (asCellStr (varNames )); 
if~isempty (setdiff (getPredictorAndResponseNames (f ),varNames ))
error (message ('stats:classreg:regr:LinearFormula:BadFormulaVariables' )); 
end
[f .str ,f .tree ]=substituteForAllElse (f ,varNames ); 
else
error (message ('stats:classreg:regr:LinearFormula:BadVarNameValue' )); 
end
f =processFormula (f ,varNames ); 




if~isMissingArg (responseVar )
if(internal .stats .isString (responseVar )&&~isequal (responseVar ,f .responseName ))||...
    (internal .stats .isScalarInt (responseVar ,1 ,length (varNames ))...
    &&~isequal (responseVar ,find (strcmp (f .responseName ,varNames ))))
error (message ('stats:classreg:regr:LinearFormula:ResponseVarConflict' )); 
end
end
if~isMissingArg (hasIntercept )&&~isequal (hasIntercept ,f .HasIntercept )

iff .HasIntercept 
f =removeTerms (f ,'1' ); 
else
f =addTerms (f ,'1' ); 
end
end
if~isMissingArg (link )&&~isequal (link ,f .link )
ifisequal (f .link ,'identity' )

f .link =link ; 
f .str =composeFormulaString (f .link ,f .responseName ,terms2expr (f .terms ,f .varNames )); 
else

error (message ('stats:classreg:regr:LinearFormula:LinkConflict' )); 
end
end
else
error (message ('stats:classreg:regr:LinearFormula:BadModelSpec' )); 
end
end

function f =addTerms (f ,update )
ntermsBefore =size (f .terms ,1 ); 
ifclassreg .regr .FormulaProcessor .isTermsMatrix (update )
f .terms =removeDupRows ([f .terms ; update ]); 
elseifinternal .stats .isString (update )
[ustr ,utree ]=parseStr (f ,update ); 
ifutree (1 ,1 )~=f .irules .LinearPredictor 
error (message ('stats:classreg:regr:LinearFormula:UpdateNotFormula' )); 
end
[addTerms ,removeTerms ]=createTerms (f ,utree ,ustr ,1 ,f .varNames ,false ); 
f .terms =sortTerms (setdiff ([f .terms ; addTerms ],removeTerms ,'rows' )); 
else
error (message ('stats:classreg:regr:LinearFormula:BadModelSpecUpdate' )); 
end
ntermsAfter =size (f .terms ,1 ); 
ifntermsAfter <=ntermsBefore 
warning (message ('stats:classreg:regr:LinearFormula:NoNewTerms' )); 
end
respLoc =find (strcmp (f .responseName ,f .varNames )); 
if~isempty (respLoc )&&any (f .terms (:,respLoc (1 )))
warning (message ('stats:classreg:regr:LinearFormula:ResponseTerm' ))
end

f .str =getStr (f ); 
end
function f =removeTerms (f ,update ,silent )
ifnargin <3 
silent =false ; 
end
ntermsBefore =size (f .terms ,1 ); 
ifclassreg .regr .FormulaProcessor .isTermsMatrix (update )
[isfound ,foundrow ]=ismember (update ,f .terms ,'rows' ); 
f .terms (foundrow (isfound ),:)=[]; 
elseifinternal .stats .isString (update )
[ustr ,utree ]=parseStr (f ,update ); 
ifutree (1 ,1 )~=f .irules .LinearPredictor 
error (message ('stats:classreg:regr:LinearFormula:UpdateNotFormula' )); 
end
[addTerms ,removeTerms ]=createTerms (f ,utree ,ustr ,1 ,f .varNames ,false ); 
oldterms =[f .terms ; removeTerms ]; 
f .terms =sortTerms (setdiff (oldterms ,addTerms ,'rows' )); 
else
error (message ('stats:classreg:regr:LinearFormula:BadModelSpecUpdate' )); 
end
ntermsAfter =size (f .terms ,1 ); 
ifntermsAfter >=ntermsBefore &&~silent 
warning (message ('stats:classreg:regr:LinearFormula:TermNotFound' )); 
end
f .str =getStr (f ); 
end

function fstr =char (f ,maxWidth )
fstr =prettyStr (f .str ); 
ifnargin ==2 &&(length (fstr )>maxWidth )
fstr =sprintf ('%s' ,getString (message ('stats:classreg:regr:LinearFormula:display_LinearFormula' ,...
    f .ResponseName ,f .NTerms ,f .NPredictors ))); 




end
end

function disp (f )
fstr =prettyStr (f .str ); 
strLHSlen =regexp (fstr ,'\ *~\ *' ,'start' )-1 ; 


lf =sprintf ('\n' ); 
pad =repmat (' ' ,1 ,strLHSlen +6 ); 
maxWidth =get (0 ,'CommandWindowSize' ); maxWidth =maxWidth (1 )-1 ; 
start =regexp (fstr ,' [+-] ' ,'start' ); 
loc =0 ; 
indent =0 ; 
whilelength (fstr )-loc >maxWidth -indent 
i =start (find (start -loc <maxWidth -indent ,1 ,'last' )); 
fstr (i )=lf ; 
loc =i +1 ; 
indent =length (pad ); 
end
fstr =regexprep (fstr ,'\n' ,[lf ,pad ]); 

disp (fstr ); 
end
function f =removeCategoricalPowers (f ,isCat ,silent )
quadCatTerms =find (max (f .Terms (:,isCat ),[],2 )>1 ); 
if~isempty (quadCatTerms )
if~silent 
warning (message ('stats:classreg:regr:TermsRegression:NoCatPowers' )); 
end
f =removeTerms (f ,f .Terms (quadCatTerms ,:)); 
end
end
function [f ,isRemoved ]=removeBadVars (f ,isValidVar )
isRemoved =false ; 
toBeRemoved =any (f .Terms (:,~isValidVar ),2 ); 
ifany (toBeRemoved )
f =removeTerms (f ,f .Terms (toBeRemoved ,:),true ); 
isRemoved =true ; 
end
end
end

methods (Access ='protected' )
function str =getStr (f )
str =composeFormulaString (f .link ,f .responseName ,terms2expr (f .terms ,f .varNames )); 
end

function [s ,t ]=substituteForAllElse (f ,varNames )
t =f .tree ; 
s =f .str ; 


phLoc =find (t (1 ,:)==f .irules .AllElse ); 
ifisscalar (phLoc )
ifisMissingArg (varNames )
error (message ('stats:classreg:regr:LinearFormula:BadAllElse' ,FormulaProcessor .allElseStr )); 
end


explicitNames =getPredictorAndResponseNames (f ); 
phStr =internal .stats .strCollapse (setdiff (varNames ,explicitNames ),' + ' ); 
ifisempty (phStr )
phStr ='0' ; 
end
modelString =[s (1 :(t (2 ,phLoc )-1 )),phStr ,s ((t (3 ,phLoc )+1 ):end)]; 
[s ,t ]=parseStr (f ,modelString ); 
ift (1 ,1 )~=f .irules .Formula 
error (message ('stats:classreg:regr:LinearFormula:InvalidFormula' ,modelString )); 
end
elseif~isempty (phLoc )
error (message ('stats:classreg:regr:LinearFormula:MultipleAllElse' ,FormulaProcessor .allElseStr )); 
end
end

function f =processFormula (f ,varNames )
t =f .tree ; 
s =f .str ; 
ift (1 ,2 )~=f .irules .Response 
error (message ('stats:classreg:regr:LinearFormula:ResponseAndPredictor' )); 
end


ifisfield (f .irules ,'LinkFunction' )
j =find (t (1 ,:)==f .irules .LinkFunction ,1 ,'first' ); 
else
j =[]; 
end
ifisempty (j )
f .link ='identity' ; 
else
j =j +1 ; 
ift (1 ,j )==f .irules .PowerLink 
k =j +find (t (1 ,(j +1 ):end)==f .irules .Expon ,1 ,'first' ); 
expon =s (t (2 ,k ):t (3 ,k )); 
f .link =str2double (expon ); 
ifisempty (f .link )
error (message ('stats:classreg:regr:LinearFormula:UnrecognizedExponent' ,expon )); 
end
else
f .link =s (t (2 ,j ):t (3 ,j )); 
end
end


j =find (t (1 ,:)==f .irules .ResponseVar ); 
f .responseName =s (min (t (2 ,j )):max (t (3 ,j ))); 










r =2 ; 
lp =r +t (5 ,r ); 
f .terms =sortTerms (createTerms (f ,t ,s ,lp ,varNames )); 
f .varNames =varNames ; 
f .str =getStr (f ); 
end

function names =getPredictorAndResponseNames (f )
t =f .tree ; 
j =find ((t (1 ,:)==f .irules .ResponseVar )|...
    (t (1 ,:)==f .irules .PredictorVar )); 



names =cell (size (j )); 
fori =1 :length (j )
names {i }=f .str (t (2 ,j (i )):t (3 ,j (i ))); 
end
names =uniqueLocal (names ); 
end

function names =getPredictorNames (f )
t =f .tree ; 
j =find ((t (1 ,:)==f .irules .PredictorVar )); 


names =cell (size (j )); 
fori =1 :length (j )
names {i }=f .str (t (2 ,j (i )):t (3 ,j (i ))); 
end
names =uniqueLocal (names ); 
end
end

methods (Static )
function tf =isTermsMatrix (x )
tf =isnumeric (x )&&ismatrix (x )&&all (x (:)>=0 )&&all (x (:)==round (x (:))); 
end

function tf =isModelAlias (model )
if~internal .stats .isString (model )
tf =false ; 
else
switchlower (model )
case {'constant' ,'linear' ,'interactions' ,'purequadratic' ,'quadratic' }
tf =true ; 
otherwise
[c ,startLoc ,endLoc ]=regexp (lower (model ),'poly(\d*)' ,'tokens' ); 
tf =(isscalar (c )&&(startLoc ==1 )&&(endLoc ==length (model ))); 
end
end
end
end
end

function [str ,tree ]=parseStr (f ,str )

str =strtrim (str ); 
treestruct =f .p .parse (str ); 
tree =treestruct .tree ; 
ifisempty (tree )||tree (3 ,1 )<length (str )
error (message ('stats:classreg:regr:LinearFormula:BadString' ,str )); 
end
end

function [addTerms ,removeTerms ]=createTerms (f ,tree ,str ,start ,vnames ,addint )
nvars =length (vnames ); 
removeTerms =zeros (0 ,nvars ); 
addTerms =identifyTerms (f ,start +1 ); 


ifnargin <6 ||addint 
addTerms =[zeros (1 ,nvars ); addTerms ]; 
end

ifnargout <2 


addTerms =setdiff (addTerms ,removeTerms ,'rows' ); 
else

end

function [terms ,node ]=identifyTerms (f ,node )
switchtree (1 ,node )
case f .irules .Sum 
last =node +tree (5 ,node )-1 ; 
[terms ,node ]=identifyTerms (f ,node +1 ); 
whilenode <=last 
terms1 =terms ; 
type =tree (1 ,node ); 
[terms2 ,node ]=identifyTerms (f ,node ); 
switchtype 
case f .irules .Addend 
terms =[terms1 ; terms2 ]; 
case f .irules .Subend 
terms =terms1 ; 
end
end
case f .irules .Addend 
[terms ,node ]=identifyTerms (f ,node +1 ); 
case f .irules .Subend 
terms =zeros (0 ,nvars ); 
[rterms ,node ]=identifyTerms (f ,node +1 ); 
removeTerms =[removeTerms ; rterms ]; 
case f .irules .Product 
last =node +tree (5 ,node )-1 ; 
[terms ,node ]=identifyTerms (f ,node +1 ); 
whilenode <=last 
terms1 =terms ; 
[terms2 ,node ]=identifyTerms (f ,node ); 
n1 =size (terms1 ,1 ); n2 =size (terms2 ,1 ); 
i1 =repmat ((1 :n1 )' ,1 ,n2 ); i2 =repmat (1 :n2 ,n1 ,1 ); 
terms =[terms1 ; terms2 ; terms1 (i1 ,:)+terms2 (i2 ,:)]; 
end
case f .irules .Inside 
[terms1 ,node ]=identifyTerms (f ,node +1 ); 
[terms2 ,node ]=identifyTerms (f ,node ); 
n1 =size (terms1 ,1 ); n2 =size (terms2 ,1 ); 
i1 =repmat ((1 :n1 )' ,1 ,n2 ); i2 =repmat (1 :n2 ,n1 ,1 ); 
terms =[terms1 ; terms1 (i1 ,:)+terms2 (i2 ,:)]; 
case f .irules .Interaction 
last =node +tree (5 ,node )-1 ; 
[terms ,node ]=identifyTerms (f ,node +1 ); 
whilenode <=last 
terms1 =terms ; 
[terms2 ,node ]=identifyTerms (f ,node ); 
n1 =size (terms1 ,1 ); n2 =size (terms2 ,1 ); 
i1 =repmat ((1 :n1 )' ,1 ,n2 ); i2 =repmat (1 :n2 ,n1 ,1 ); 
terms =terms1 (i1 ,:)+terms2 (i2 ,:); 
end
case f .irules .Power 
[terms2 ,node ]=identifyTerms (f ,node +1 ); 
expon =str2double (str (tree (2 ,node ):tree (3 ,node ))); 
node =node +1 ; 
terms =terms2 ; 
fori =2 :expon 
terms1 =terms ; 
n1 =size (terms1 ,1 ); n2 =size (terms2 ,1 ); 
i1 =repmat ((1 :n1 )' ,1 ,n2 ); i2 =repmat (1 :n2 ,n1 ,1 ); 
terms =[terms1 ; terms1 (i1 ,:)+terms2 (i2 ,:)]; 
end
case f .irules .PredictorVar 
name =str (tree (2 ,node ):tree (3 ,node )); 
ivar =find (strcmp (name ,vnames )); 
ifisempty (ivar )
error (message ('stats:classreg:regr:LinearFormula:UnrecognizedVariable' ,name )); 
end
terms =zeros (1 ,nvars ); terms (end,ivar )=1 ; 
node =node +1 ; 
case f .irules .Intercept 
terms =zeros (1 ,nvars ); 
node =node +1 ; 
case f .irules .Zero 
terms =zeros (0 ,nvars ); 
node =node +1 ; 
otherwise
error (message ('stats:classreg:regr:LinearFormula:UnrecognizedRule' ,tree (1 ,node ))); 
end
end
end

function modelStr =composeFormulaString (link ,responseName ,expr )
ifisMissingArg (link )||isequal (link ,'identity' )
modelStr =sprintf ('%s ~ %s' ,responseName ,expr ); 
elseifisnumeric (link )
modelStr =sprintf ('power(%s,%d) ~ %s' ,responseName ,expr ); 
elseifinternal .stats .isString (link )
modelStr =sprintf ('%s(%s) ~ %s' ,link ,responseName ,expr ); 
else
modelStr =sprintf ('link(%s) ~ %s' ,responseName ,expr ); 
end
end

function expr =terms2expr (terms ,varNames )
if~isempty (terms )
termNames =classreg .regr .modelutils .terms2names (terms ,varNames ); 
termNames (strcmp (termNames ,'(Intercept)' ))={'1' }; 
keep =true (size (termNames )); 
mainEffectTerms =find (sum (terms ,2 )==1 ); 
mainEffectVars =find (sum (terms (mainEffectTerms ,:),1 )); 
interactions =find ((sum (terms ,2 )==2 )&(sum (terms >0 ,2 )==2 ))' ; 
fork =interactions 
ij =find (terms (k ,:)); 
[tf ,loc ]=ismember (ij ,mainEffectVars ); 
ifall (tf )
termNames {k }=internal .stats .strCollapse (varNames (ij ),'*' ); 
keep (mainEffectTerms (loc ))=false ; 






end
end
expr =internal .stats .strCollapse (termNames (keep ),' + ' ); 
elseifsize (terms ,1 )>0 


expr ='1' ; 
else


expr ='0' ; 
end
end

function terms =sortTerms (terms )
nvars =size (terms ,2 ); 
terms =unique (terms ,'rows' ); 
terms =sortrows (terms ,nvars :-1 :1 ); 
[~,ord ]=sortrows ([sum (terms ,2 ),max (terms ,[],2 )]); terms =terms (ord ,:); 
end

function x =removeDupRows (x )

[~,i ]=unique (x ,'rows' ,'first' ); 
iflength (i )<size (x ,1 )
x =x (sort (i ),:); 
end
end


function str =prettyStr (str )
str (isspace (str ))=[]; 
tilde =find (str =='~' ,1 ); 
ifisempty (tilde )
tilde =0 ; 
end
part1 =str (1 :tilde -1 ); 
part2 =str (tilde +1 :end); 
str =[part1 ,' ~ ' ,regexprep (part2 ,{'~' ,'+' ,'-' },{' ~ ' ,' + ' ,' - ' })]; 
end

function b =uniqueLocal (a )

b =unique (a ); b =b (:)' ; 
end

function a =mustBeUnique (a )
iflength (a )~=length (unique (a ))
error (message ('stats:classreg:regr:LinearFormula:RepeatedVariables' )); 
end
a =a (:)' ; 
end

function c =asCellStr (c )
if~iscell (c ),c ={c }; end
end

function tf =isMissingArg (x )
tf =isequal (x ,[]); 
end
