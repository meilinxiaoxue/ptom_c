classdef (Sealed =true )LinearMixedFormula 






















properties (Constant ,GetAccess ='protected' )
allElseStr ='...' ; 







rules ={
 '  Formula          = (Response Spaces "~" Spaces)? LinearPredictor Spaces ("+" LinearRandomPredictor)*' 
 '+ Response         = LinkFunction / ResponseVar' 
 '+ LinkFunction     = LinkName "(" Spaces ResponseVar Spaces ")" / PowerLink' 
 '  PowerLink        = "power" "(" Spaces ResponseVar Spaces "," Spaces Expon Spaces ")"' 
 '  ResponseVar      = Name' 
 '+ LinearRandomPredictor = Spaces "(" Spaces LinearPredictor Spaces "|" Spaces GroupingVar Spaces ")" Spaces' 
 '+ LinearPredictor  = Sum / Zero' 
 '  Sum              = Augend (Spaces (Addend / Subend))*' 
 '- Augend           = Conditional / Subend' 
 '+ Addend           = "+" Spaces Conditional' 
 '+ Subend           = "-" Spaces Conditional' 
 
 '  Conditional      = Product' 
 '  Product          = Inside (Spaces "*" Spaces Inside)*' 
 '  Inside           = Interaction (Spaces "/" Spaces PredictorVar)?' 
 '  Interaction      = Power (Spaces ":" Spaces Power)*' 
 '  Power            = Predictor ("^" Integer)?' 
 
 '- Predictor        = "(" Spaces Sum Spaces ")" / AllElse / PredictorVar / Intercept' 
 
 '  LinkName         = Name' 
 
 
 '+  GroupingVar     = PredictorVar (Spaces ":" Spaces PredictorVar)*' 
 '  PredictorVar     = Name' 
 '- Name             = [A-Za-z_] [A-Za-z0-9_]*' 
 
 '  Expon            = [0-9]+ ( "." [0-9]+ )' 
 '  Integer          = [0-9]+' 
 '  Intercept        = "1"' 
 '  Zero             = "0"' 
 ['  AllElse          = "' ,classreg .regr .LinearMixedFormula .allElseStr ,'"' ]
 '- Spaces           = (" ")*' 
 }; 

p =internal .stats .PEG (classreg .regr .LinearMixedFormula .rules ); 

irules =rulemap (classreg .regr .LinearMixedFormula .p ); 
end

properties (GetAccess ='public' ,SetAccess ='protected' )



FELinearFormula 







GroupingVariableNames 







RELinearFormula 


ResponseName 



PredictorNames 




VariableNames 



Link 

end

properties (GetAccess ='protected' ,SetAccess ='protected' )


str ='y ~ 0' ; 

tree =[]; 
end

methods (Access ='public' )

function f =LinearMixedFormula (modelSpec ,varNames )


































ifnargin <1 ,return ,end
ifnargin <2 ,varNames =[]; end

ifinternal .stats .isString (modelSpec )




[f .str ,f .tree ]=parseStr (modelSpec ); 
iff .tree (1 ,1 )~=classreg .regr .LinearMixedFormula .irules .Formula 
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
else
error (message ('stats:classreg:regr:LinearFormula:BadModelSpec' )); 
end
end

function fstr =char (f ,maxWidth )








fstr =getDisplayString (f ); 

ifnargin ==2 &&(length (fstr )>maxWidth )
fstr =sprintf ('%s' ,['Linear Mixed Formula with ' ,num2str (length (f .PredictorNames )),' predictors.' ]); 
end

end

function disp (f )



fstr =getDisplayString (f ); 
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

end

methods (Access ='protected' )

function [s ,t ]=substituteForAllElse (f ,varNames )
t =f .tree ; 
s =f .str ; 


phLoc =find (t (1 ,:)==classreg .regr .LinearMixedFormula .irules .AllElse ); 
ifisscalar (phLoc )
ifisMissingArg (varNames )
error (message ('stats:classreg:regr:LinearFormula:BadAllElse' ,classreg .regr .LinearMixedFormula .allElseStr )); 
end


explicitNames =getPredictorAndResponseNames (f ); 
phStr =internal .stats .strCollapse (setdiff (varNames ,explicitNames ),' + ' ); 
ifisempty (phStr )
phStr ='0' ; 
end
modelString =[s (1 :(t (2 ,phLoc )-1 )),phStr ,s ((t (3 ,phLoc )+1 ):end)]; 
[s ,t ]=parseStr (modelString ); 
ift (1 ,1 )~=classreg .regr .LinearMixedFormula .irules .Formula 
error (message ('stats:classreg:regr:LinearFormula:InvalidFormula' ,modelString )); 
end
elseif~isempty (phLoc )
error (message ('stats:classreg:regr:LinearFormula:MultipleAllElse' ,classreg .regr .LinearMixedFormula .allElseStr )); 
end
end

function f =processFormula (f ,varNames )
t =f .tree ; 
s =f .str ; 
ift (1 ,2 )~=classreg .regr .LinearMixedFormula .irules .Response 
error (message ('stats:classreg:regr:LinearFormula:ResponseAndPredictor' )); 
end


























idx =find (t (1 ,:)==classreg .regr .LinearMixedFormula .irules .Response ,1 ,'first' ); 

ResponseStr =s (t (2 ,idx ):t (3 ,idx )); 

FELinearFormulaStr =[ResponseStr ,' ~ ' ]; 

idx =find (t (1 ,:)==classreg .regr .LinearMixedFormula .irules .LinearPredictor ,1 ,'first' ); 

FELinearFormulaStr =[FELinearFormulaStr ,s (t (2 ,idx ):t (3 ,idx ))]; 

f .FELinearFormula =classreg .regr .LinearFormula (FELinearFormulaStr ,varNames ); 






lrp =find (t (1 ,:)==classreg .regr .LinearMixedFormula .irules .LinearRandomPredictor ); 

lp =find (t (1 ,:)==classreg .regr .LinearMixedFormula .irules .LinearPredictor ); 

gv =find (t (1 ,:)==classreg .regr .LinearMixedFormula .irules .GroupingVar ); 

pv =find (t (1 ,:)==classreg .regr .LinearMixedFormula .irules .PredictorVar ); 

RELinearFormulaStr =cell (length (lrp ),1 ); 
f .GroupingVariableNames =cell (length (lrp ),1 ); 
fori =1 :length (lrp )

childidx =lrp (i ):lrp (i )+t (5 ,lrp (i ))-1 ; 

lpidx =intersect (childidx ,lp ); 

RELinearFormulaStr {i }=[ResponseStr ,' ~ ' ,s (t (2 ,lpidx ):t (3 ,lpidx ))]; 

f .RELinearFormula {i }=classreg .regr .LinearFormula (RELinearFormulaStr {i },varNames ); 

gvidx =intersect (childidx ,gv ); 

gvchildidx =gvidx :gvidx +t (5 ,gvidx )-1 ; 

pidx =intersect (gvchildidx ,pv ); 
f .GroupingVariableNames {i }=cell (1 ,length (pidx )); 
forj =1 :length (pidx )
f .GroupingVariableNames {i }{j }=s (t (2 ,pidx (j )):t (3 ,pidx (j ))); 
end
end


j =find (t (1 ,:)==classreg .regr .LinearMixedFormula .irules .LinkFunction ,1 ,'first' ); 
ifisempty (j )
f .Link ='identity' ; 
else
j =j +1 ; 
ift (1 ,j )==classreg .regr .LinearMixedFormula .irules .PowerLink 
k =j +find (t (1 ,(j +1 ):end)==classreg .regr .LinearMixedFormula .irules .Expon ,1 ,'first' ); 
expon =s (t (2 ,k ):t (3 ,k )); 
f .Link =str2double (expon ); 
ifisempty (f .link )
error (message ('stats:classreg:regr:LinearFormula:UnrecognizedExponent' ,expon )); 
end
else
f .Link =s (t (2 ,j ):t (3 ,j )); 
end
end


j =find (t (1 ,:)==classreg .regr .LinearMixedFormula .irules .ResponseVar ); 
f .ResponseName =s (t (2 ,j ):t (3 ,j )); 


f .PredictorNames =getPredictorNames (f ); 


f .VariableNames =varNames ; 

end

function names =getPredictorAndResponseNames (f )
t =f .tree ; 
j =find ((t (1 ,:)==classreg .regr .LinearMixedFormula .irules .ResponseVar )|...
    (t (1 ,:)==classreg .regr .LinearMixedFormula .irules .PredictorVar )); 



names =cell (size (j )); 
fori =1 :length (j )
names {i }=f .str (t (2 ,j (i )):t (3 ,j (i ))); 
end
names =uniqueLocal (names ); 
end

function names =getPredictorNames (f )
t =f .tree ; 
j =find ((t (1 ,:)==classreg .regr .LinearMixedFormula .irules .PredictorVar )); 


names =cell (size (j )); 
fori =1 :length (j )
names {i }=f .str (t (2 ,j (i )):t (3 ,j (i ))); 
end
names =uniqueLocal (names ); 
end

function str =getDisplayString (f )
str =char (f .FELinearFormula ); 
gnames =prettyGroupingVariableNames (f .GroupingVariableNames ); 
fori =1 :length (f .RELinearFormula )
appendStr =['(' ,f .RELinearFormula {i }.LinearPredictor ,' | ' ,gnames {i },')' ]; 
str =[str ,' + ' ,appendStr ]; %#ok<AGROW> 
end
end

end

end

function prettynames =prettyGroupingVariableNames (names )




G =length (names ); 
prettynames =cell (G ,1 ); 
fori =1 :G 
prettynames {i }=names {i }{1 }; 
forj =2 :length (names {i })
prettynames {i }=[prettynames {i },':' ,names {i }{j }]; 
end
end
end

function [str ,tree ]=parseStr (str )

str =strtrim (str ); 
treestruct =classreg .regr .LinearMixedFormula .p .parse (str ); 
tree =treestruct .tree ; 
ifisempty (tree )||tree (3 ,1 )<length (str )
error (message ('stats:classreg:regr:LinearFormula:BadString' ,str )); 
end
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
