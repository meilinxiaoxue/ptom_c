classdef (Sealed =true )NonLinearFormula 



properties (Constant ,GetAccess ='protected' )
rules ={
 '  Formula         = (Response "~")? Expression' 
 '  Response        = Name' 
 '+ Expression      = Test' 
 '  Test            = Sum (("=="/"<="/">="/"<"/">"/"~=") Sum)?' 
 '  Sum             = Product (("+"/"-") Product)*' 
 '  Product         = Power (("*"/".*"/"/"/"./") Power)*' 
 '  Power           = Term ("^" Term)?' 
 '  Term            = "(" Expression ")" / SignedFactor / Number' 
 '  SignedFactor    = ("+"/"-")* Factor' 
 '  Factor          = Function / PredictorOrCoef / MatlabExpr' 
 '  Function        = FunName "(" ArgList ")"' 
 '  FunName         = Name' 
 '  ArgList         = Expression ("," Expression)*' 
 '  PredictorOrCoef = Name' 
 '- Name            = [A-Za-z_] [A-Za-z0-9_]* ("." [A-Za-z_] [A-Za-z0-9_]*)*' 
 '  MatlabExpr      = "[" [^#x5B#x5D]+ "]"' 
 '  Number          = ("+"/"-")? [0-9]+ ("." [0-9]*)? / ("+"/"-")? ("." [0-9]+)?' 
 }; 
p =internal .stats .PEG (classreg .regr .NonLinearFormula .rules ); 
irules =rulemap (classreg .regr .NonLinearFormula .p ); 
end

properties (GetAccess ='protected' ,SetAccess ='protected' )
fun =[]; 
funType ='' ; 
tree =[]; 
str ='y ~ 0' ; 
rname ='y' ; 
cnames =cell (1 ,0 ); 
pnames =cell (1 ,0 ); 
vnames ={'y' }; 
end

properties (Dependent ,GetAccess ='public' ,SetAccess ='public' )
CoefficientNames 
VariableNames 
ResponseName 
end
properties (Dependent ,GetAccess ='public' ,SetAccess ='protected' )
Expression 
ModelFun 
InModel 

Names 
ExpressionNames 
PredictorNames 
ConstantNames 
FunctionCalls 
NumCoefficients 
NVars 
NumPredictors 
end

methods 
function rname =get .ResponseName (f )
rname =f .rname ; 
end
function f =set .ResponseName (f ,rname )
f =parseStr (f ,composeFormulaString (rname ,f .Expression )); 
end
function n =get .NumCoefficients (f )
n =length (f .cnames ); 
end
function cnames =get .CoefficientNames (f )
cnames =f .cnames ; 
end
function f =set .CoefficientNames (f ,cnames )
f =setAllNames (f ,cnames ); 
end
function n =get .NVars (f )
n =length (f .vnames ); 
end
function n =get .NumPredictors (f )
n =length (f .pnames ); 
end
function vnames =get .VariableNames (f )
vnames =f .vnames ; 
end
function f =set .VariableNames (f ,vnames )
f =setAllNames (f ,[],vnames ); 
end
function pnames =get .PredictorNames (f )
pnames =f .pnames ; 
end
function names =get .ConstantNames (f )
exprNames =f .ExpressionNames ; 
names =setdiff (exprNames ,[f .cnames ,f .vnames ]); 
end
function names =get .InModel (f )
names =ismember (f .vnames ,f .pnames ); 
end

function expr =get .Expression (f )
t =f .tree ; 
j =find (t (1 ,:)==f .irules .Expression ); 
expr =prettyStr (f .str (t (2 ,j ):t (3 ,j ))); 
end
function fun =get .ModelFun (f )
ifisempty (f .fun )
expr =f .Expression ; 
expr =regexprep (expr ,{'(\.)?\*' ,'(\.)?/' ,'(\.)?\^' },{'.*' ,'./' ,'.^' }); 
betaNames =strcat ({'b(' },num2str ((1 :f .NumCoefficients )' ),{')' }); 
coefNames =f .CoefficientNames ; 
expr =regexprepLocal (expr ,strcat ('\<' ,coefNames ,'\>' ),betaNames ,strcmp ('b' ,coefNames )); 
Xnames =strcat ({'X(:,' },num2str ((1 :f .NumPredictors )' ),{')' }); 
predNames =f .PredictorNames ; 
expr =regexprepLocal (expr ,strcat ('\<' ,predNames ,'\>' ),Xnames ,strcmp ('X' ,predNames )); 
fun =eval (['@(b,X) ' ,expr ]); 
else
fun =f .fun ; 
end
end

function names =get .Names (f )
ifisOpaqueFunType (f .funType )

names =cell (1 ,0 ); 
else
t =f .tree ; 
j =find (t (1 ,:)==f .irules .Response |t (1 ,:)==f .irules .PredictorOrCoef ); 
names =cell (size (j )); 
fori =1 :length (j )
names {i }=f .str (t (2 ,j (i )):t (3 ,j (i ))); 
end
names =uniqueLocal (names ); 
end
end
function names =get .ExpressionNames (f )
ifisOpaqueFunType (f .funType )

names =cell (1 ,0 ); 
else
t =f .tree ; 
j =find (t (1 ,:)==f .irules .PredictorOrCoef ); 
names =cell (size (j )); 
fori =1 :length (j )
names {i }=f .str (t (2 ,j (i )):t (3 ,j (i ))); 
end
names =uniqueLocal (names ); 
end
end
function names =get .FunctionCalls (f )
t =f .tree ; 
j =find (t (1 ,:)==f .irules .FunName ); 
names =cell (size (j )); 
fori =1 :length (j )
names {i }=f .str (t (2 ,j (i )):t (3 ,j (i ))); 
end
names =uniqueLocal (names ); 
end
end

methods (Access ='public' )
function f =NonLinearFormula (model ,coefNames ,predictorNames ,responseName ,varNames ,ncoefs )
ifnargin <1 ,return ,end

ifnargin <2 ,coefNames =[]; end
ifnargin <3 ,predictorNames =[]; end
ifnargin <4 ,responseName =[]; end
ifnargin <5 ,varNames =[]; end
ifnargin <6 ,ncoefs =0 ; end

givenFun =isa (model ,'function_handle' ); 
haveAnonymous =false ; 
ifisa (model ,'classreg.regr.NonLinearFormula' )
inferNames =false ; 
f =model ; 


if~isMissingArg (responseName )
f =parseStr (f ,composeFormulaString (responseName ,f .Expression )); 
end
else
inferNames =true ; 
fstr ='' ; 
ifgivenFun 
funs =functions (model ); 
f .fun =model ; 
f .funType =funs .type ; 







if~isMissingArg (varNames )
ifisMissingArg (responseName )
ifisMissingArg (predictorNames )
responseName =varNames {end}; 
predictorNames =varNames (1 :end-1 ); 
else
responseName =setdiff (varNames ,predictorNames ); 
if~isscalar (responseName )
error (message ('stats:classreg:regr:NonLinearFormula:AmbiguousResponse' )); 
end
responseName =responseName {1 }; 
end
elseifisMissingArg (predictorNames )
predictorNames =setdiff (varNames ,responseName ); 
end
end









ifisOpaqueFunType (f .funType )
ifisMissingArg (coefNames )||isMissingArg (predictorNames )
error (message ('stats:classreg:regr:NonLinearFormula:PredictorCoefRequired' ,f .funType )); 
end
else
haveAnonymous =true ; 
ifnargin (model )~=2 
error (message ('stats:classreg:regr:NonLinearFormula:BadModelArgs' )); 
end
end
elseifinternal .stats .isString (model )
fstr =model ; 
else
error (message ('stats:classreg:regr:NonLinearFormula:BadModelSpecification' )); 
end
try
ifisempty (fstr )



ifisMissingArg (responseName ),responseName ='y' ; end
[expr ,coefNames ,predictorNames ]=function2expression (funs ,coefNames ,predictorNames ); 
fstr =composeFormulaString (responseName ,expr ); 
end
f =parseStr (f ,fstr ); 
catch ME 




ifhaveAnonymous 
i1 =find (funs .function =='(' ,1 ); 
i2 =find (funs .function ==')' ,1 ); 
funargs =funs .function (i1 +1 :i2 -1 ); 
f =parseStr (f ,sprintf ('%s ~ F(%s)' ,responseName ,funargs )); 
f .funType ='opaque-anonymous' ; 
ifisempty (coefNames )
coefNames =internal .stats .numberedNames ('b' ,1 :ncoefs )' ; 
if~isempty (varNames )
coefNames =genvarname (coefNames ,varNames ); 
end
end
else
rethrow (ME )
end
end
end
f =setAllNames (f ,coefNames ,varNames ,predictorNames ,responseName ,inferNames ); 
end


function fstr =char (f ,maxWidth )
fstr =prettyStr (f .str ); 
ifnargin ==2 &&(length (fstr )>maxWidth )
fstr =sprintf ('%s' ,getString (message ('stats:classreg:regr:NonLinearFormula:display_NonlinearFormula' ,...
    f .ResponseName ,f .NumCoefficients ,f .NumPredictors ))); 
end
end


function disp (f )
fstr =prettyStr (f .str ); 
strLHSlen =regexp (fstr ,'\ *~\ *' ,'start' )-1 ; 


lf =sprintf ('\n' ); 
pad =repmat (' ' ,1 ,strLHSlen +6 ); 
maxWidth =matlab .desktop .commandwindow .size ; maxWidth =maxWidth (1 )-1 ; 
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


function print (f )
f .p .pretty (struct ('tree' ,f .tree ,'string' ,f .str ))
end
end

methods (Access ='protected' )
function f =parseStr (f ,fstr )

fstr (isspace (fstr ))=[]; 
f .str =fstr ; 
treestruct =f .p .parse (f .str ); 
f .tree =treestruct .tree ; 
t =f .tree ; 
ift (3 ,1 )<length (f .str )
error (message ('stats:classreg:regr:NonLinearFormula:InvalidFormula' ,fstr )); 
elseift (1 ,1 )~=f .irules .Formula 
error (message ('stats:classreg:regr:NonLinearFormula:MissingFormulaContents' )); 
end
end


function f =setAllNames (f ,coefNames ,varNames ,predictorNames ,responseName ,infer )
ifnargin <3 ,varNames =[]; end
ifnargin <4 ,predictorNames =[]; end
ifnargin <5 ,responseName =[]; end
ifnargin <6 ,infer =false ; end

givenFun =~isempty (f .fun ); 

t =f .tree ; 
j =find (t (1 ,:)==f .irules .Response ); 
f .rname =f .str (t (2 ,j ):t (3 ,j )); 
exprNames =f .ExpressionNames ; 






if~isMissingArg (responseName )
if~givenFun &&~isequal (responseName ,f .rname )
error (message ('stats:classreg:regr:NonLinearFormula:ResponseFormulaConflict' )); 
end
end



if~isMissingArg (varNames )
f .vnames =checkNames (varNames ,'Variable' ); 
ifisMissingArg (predictorNames )
[~,i ]=intersect (varNames ,exprNames ); 
predictorNames =varNames (sort (i )); 
end
end







if~givenFun 
if~isMissingArg (predictorNames )&&~all (ismember (predictorNames ,exprNames ))
error (message ('stats:classreg:regr:NonLinearFormula:MissingPredictors' )); 
elseif~isMissingArg (coefNames )&&~all (ismember (coefNames ,exprNames ))
error (message ('stats:classreg:regr:NonLinearFormula:MissingCoefficients' )); 
end
end

ifisMissingArg (coefNames )
ifisMissingArg (predictorNames )
ifinfer 



notCoefs =cellfun ('isempty' ,regexp (exprNames ,'\<b\d+\>' )); 
f .pnames =exprNames (notCoefs ); 
f .cnames =exprNames (~notCoefs ); 
else

end
else
f .pnames =checkNames (predictorNames ,'Predictor' ); 
ifinfer 
f .cnames =setdiff (exprNames ,f .pnames ); 
else



f .cnames =setdiff (f .cnames ,f .pnames ); 
end
end
else
f .cnames =checkNames (coefNames ,'Coefficient' ); 
ifisMissingArg (predictorNames )
ifinfer 
f .pnames =setdiff (exprNames ,f .cnames ); 
else



f .pnames =setdiff (f .pnames ,f .cnames ); 
end
else
f .pnames =checkNames (predictorNames ,'Predictor' ); 
ifany (ismember (f .pnames ,f .cnames ))
error (message ('stats:classreg:regr:NonLinearFormula:PredictorCoefficientConflict' )); 
end
end
end

ifisMissingArg (varNames )
f .vnames =[f .pnames ,f .rname ]; 
else
if~all (ismember (f .pnames ,f .vnames ))
error (message ('stats:classreg:regr:NonLinearFormula:PredictorNotVariable' )); 
end
if~any (strcmp (f .rname ,f .vnames ))
error (message ('stats:classreg:regr:NonLinearFormula:ResponseNotVariable' )); 
end
end
end
end

methods (Static ,Access ='public' )
function tf =isOpaqueFun (fun )
ifisa (fun ,'function_handle' )
s =functions (fun ); 
tf =isOpaqueFunType (s .type ); 
else
tf =false ; 
end
end
end
end


function tf =isOpaqueFunType (type )
tf =~isempty (type )&&~strcmp (type ,'anonymous' ); 
end

function fstr =composeFormulaString (responseName ,expressionStr )
fstr =[responseName ,' ~ ' ,expressionStr ]; 
end

function [expr ,coefNames ,predictorNames ]=function2expression (funs ,coefNames ,predictorNames )
funType =funs .type ; 
fstr =funs .function ; fstr (isspace (fstr ))=[]; 

ifstrcmp (funType ,'anonymous' )







tokens =regexp (fstr ,'@\(\s*([a-zA-Z_]\w*)\s*,\s*([a-zA-Z_]\w*)\s*\)\s*(.+)' ,'tokens' ); 
coefBase =tokens {1 }{1 }; 
predictorBase =tokens {1 }{2 }; 
expr =tokens {1 }{3 }; 



coefIndices =regexp (expr ,['\<' ,coefBase ,'\>\((\d)\)' ],'tokens' ); 
predictorIndices =regexp (expr ,['\<' ,predictorBase ,'\>\(:\,(\d)\)' ],'tokens' ); 



coefBadTokens =regexp (expr ,['\<' ,coefBase ,'\>(?!\(\d\))' ],'start' ); 
predictorBadTokens =regexp (expr ,['\<' ,predictorBase ,'\>(?!\(:\,\d\))' ],'tokens' ); 
ifisempty (predictorIndices )
predictorIndices =predictorBadTokens ; 
predictorBadTokens ={}; 
end



ifisempty (coefIndices )||isempty (predictorIndices )...
    ||~isempty (coefBadTokens )||~isempty (predictorBadTokens )
error (message ('stats:classreg:regr:NonLinearFormula:UnrecognizedCoefficientPredictor' ,fstr )); 
end




coefIndices =cellstr (num2str ((1 :max (str2num (char ([coefIndices {:}]' ))))' ,'%-d' )); 
coefNamesFound =strcat (coefBase ,coefIndices )' ; 
ifisMissingArg (coefNames )
coefNames =coefNamesFound ; 
elseiflength (coefNames )~=length (coefNamesFound )
error (message ('stats:classreg:regr:NonLinearFormula:BadCoefficientNameLength' )); 
end
predictorIndices =cellstr (num2str ((1 :max (str2num (char ([predictorIndices {:}]' ))))' ,'%-d' )); 
iflength (predictorIndices )>1 
predictorNamesFound =strcat (predictorBase ,predictorIndices )' ; 
else
predictorNamesFound ={predictorBase }; 
end
ifisMissingArg (predictorNames )

predictorNames =predictorNamesFound ; 
elseiflength (predictorNames )==length (predictorNamesFound )

else

ok =ismember (predictorNamesFound ,predictorNames ); 
ifall (ok )
predictorNames =predictorNamesFound ; 
elseiflength (predictorIndices )>length (predictorNames )
error (message ('stats:classreg:regr:NonLinearFormula:UnrecognizedPredictors' ,length (predictorNames ),length (predictorIndices ))); 
end
end



coefPats =strcat (coefBase ,'\(' ,coefIndices ,'\)' )' ; 
expr =regexprep (expr ,coefPats ,coefNames ); 
predictorPats =strcat (predictorBase ,'\(:,' ,predictorIndices ,'\)' )' ; 
expr =regexprep (expr ,predictorPats ,predictorNames (1 :length (predictorPats ))); 


expr =regexprep (expr ,{'\.\*' ,'\./' ,'\.\^' },{'*' ,'/' ,'^' }); 

else



expr =[fstr ,'(b,X)' ]; 
end
end

function str =prettyStr (str )

str (isspace (str ))=[]; 
str =regexprep (str ,{'~' ,'+' ,'-' },{' ~ ' ,' + ' ,' - ' }); 
str =regexprep (str ,{'(\.)?*' ,'(\.)?/' ,'(\.)?\^' },{'*' ,'/' ,'^' }); 
end

function a =checkNames (a ,which )
if~iscellstr (a )
error (message ('stats:classreg:regr:NonLinearFormula:InvalidNames' ,which )); 
end

iflength (a )~=length (unique (a ))
error (message ('stats:classreg:regr:NonLinearFormula:NamesNotUnique' ,which )); 
end
a =a (:)' ; 
end

function b =uniqueLocal (a )

b =unique (a ); b =b (:)' ; 
end

function string =regexprepLocal (string ,pattern ,replace ,doFirst )




i =[find (doFirst ),find (~doFirst )]; 
string =regexprep (string ,pattern (i ),replace (i )); 
end

function tf =isMissingArg (x )
tf =isequal (x ,[]); 
end
