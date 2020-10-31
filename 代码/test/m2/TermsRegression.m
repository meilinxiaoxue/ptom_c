classdef (AllowedSubclasses ={?GeneralizedLinearModel ,?LinearModel })TermsRegression <classreg .regr .ParametricRegression &classreg .regr .CompactTermsRegression 












properties (GetAccess ='protected' ,SetAccess ='protected' )
Leverage =[]; 
end

properties (GetAccess ='public' ,SetAccess ='protected' )


























Steps =[]; 
end
properties (GetAccess ='public' ,SetAccess ='protected' ,Hidden =true )
Design =[]; 
end
properties (Dependent ,GetAccess ='protected' ,SetAccess ='protected' )


design_r =[]; 
end

methods (Access ='protected' )
function H =get_HatMatrix (model )
ifhasData (model )





w_r =get_CombinedWeights_r (model ); 
sw =sqrt (w_r ); 
X_r =model .design_r ; 
Xw_r =bsxfun (@times ,X_r ,sw ); 
[Qw ,~,~]=qr (Xw_r ,0 ); 
rank =model .NumEstimatedCoefficients ; 
Qw =Qw (:,1 :rank ); 
T =Qw *Qw ' ; 
H =zeros (model .NumObservations ); 
subset =model .ObservationInfo .Subset ; 
H1 =bsxfun (@times ,bsxfun (@times ,1 ./sw ,T ),sw ' ); 
H1 (sw <=0 ,:)=0 ; 
H (subset ,subset )=H1 ; 
else
H =[]; 
end
end
function d =get_CooksDistance (model )
ifhasData (model )
w =get_CombinedWeights_r (model ,false ); 
r =model .Residuals .Raw ; 
h =model .Leverage ; 
d =w .*abs (r ).^2 .*(h ./(1 -h ).^2 )./(model .NumEstimatedCoefficients *varianceParam (model )); 
else
d =[]; 
end
end
function w =get_CombinedWeights_r (model ,reduce )

w =model .ObservationInfo .Weights ; 
ifnargin <2 ||reduce 
subset =model .ObservationInfo .Subset ; 
w =w (subset ); 
end
end
end

methods 
function design_r =get .design_r (model )
ifisempty (model .WorkingValues )
design_r =create_design_r (model ); 
else
design_r =model .WorkingValues .design_r ; 
end
end
end

methods (Access ='public' )
function model =addTerms (model ,terms )
















terms =convertStringsToChars (terms ); 
compactNotAllowed (model ,'addTerms' ,false ); 
model .Formula =addTerms (model .Formula ,terms ); 
model =removeCategoricalPowers (model ); 
model =doFit (model ); 
checkDesignRank (model )
end
function model =removeTerms (model ,terms )
















terms =convertStringsToChars (terms ); 
compactNotAllowed (model ,'removeTerms' ,false ); 
model .Formula =removeTerms (model .Formula ,terms ); 
model =doFit (model ); 
checkDesignRank (model )
end

function model =step (model ,varargin )
paramNames ={'Lower' ,'Upper' ,'Criterion' ,'PEnter' ,'PRemove' ,'NSteps' ,'Verbose' }; 
paramDflts ={'constant' ,'interactions' ,'SSE' ,[],[],1 ,1 }; 

wasempty =isempty (model .Steps ); 
if~wasempty 
paramDflts {1 }=model .Steps .Lower .Terms ; 
paramDflts {2 }=model .Steps .Upper .Terms ; 
paramDflts {3 }=model .Steps .Criterion ; 
paramDflts {4 }=model .Steps .PEnter ; 
paramDflts {5 }=model .Steps .PRemove ; 
end

[lower ,upper ,crit ,penter ,premove ,nsteps ,verbose ]=...
    internal .stats .parseArgs (paramNames ,paramDflts ,varargin {:}); 

if~isscalar (verbose )||~ismember (verbose ,0 :2 )
error (message ('stats:LinearModel:BadVerbose' )); 
end

start =model .Formula ; 

if~isa (lower ,'LinearFormula' )
lower =classreg .regr .LinearFormula (lower ,start .VariableNames ,start .ResponseName ,start .HasIntercept ,start .Link ); 
end
if~isa (upper ,'LinearFormula' )



upper =classreg .regr .LinearFormula (upper ,start .VariableNames ,start .ResponseName ,start .HasIntercept ,start .Link ); 
end



model .Steps .Start =start ; 
model .Steps .Lower =lower ; 
model .Steps .Upper =upper ; 
model .Steps .Criterion =crit ; 
model .Steps .PEnter =penter ; 
model .Steps .PRemove =premove ; 
ifwasempty 
model .Steps .History =[]; 
end
model =stepwiseFitter (model ,nsteps ,verbose ); 
end
end

methods (Access ='protected' )
function model =TermsRegression ()
model @classreg .regr .CompactTermsRegression (); 
end

function D =get_diagnostics (model ,type )
ifnargin <2 
CooksDistance =get_diagnostics (model ,'cooksdistance' ); 
HatMatrix =get_diagnostics (model ,'hatmatrix' ); 
Leverage =model .Leverage ; 
D =table (Leverage ,CooksDistance ,HatMatrix ,...
    'RowNames' ,model .ObservationNames ); 
else
subset =model .ObservationInfo .Subset ; 
switch(lower (type ))
case 'leverage' 
D =model .Leverage ; 
D (~subset ,:)=0 ; 
case 'hatmatrix' 
try
D =get_HatMatrix (model ); 
catch ME 
warning (message ('stats:LinearModel:HatMatrixError' ,...
    ME .message )); 
D =zeros (length (subset ),0 ); 
end
D (~subset ,:)=0 ; 
case 'cooksdistance' 
D =get_CooksDistance (model ); 
D (~subset ,:)=NaN ; 
otherwise
error (message ('stats:LinearModel:UnrecognizedDiagnostic' ,type )); 
end
end
end


function model =assignData (model ,X ,y ,w ,asCat ,dummyCoding ,varNames ,excl )
model =assignData @classreg .regr .ParametricRegression (model ,X ,y ,w ,asCat ,varNames ,excl ); 

tf =internal .stats .isString (dummyCoding ); 
if~tf ||~ismember (dummyCoding ,classreg .regr .TermsRegression .DummyVarCodings )
error (message ('stats:classreg:regr:TermsRegression:BadCodingValue' ,internal .stats .listStrings (classreg .regr .TermsRegression .DummyVarCodings ))); 
end
model .DummyVarCoding =dummyCoding ; 
end


function model =selectVariables (model )
f =model .Formula ; 
[~,model .PredLocs ]=ismember (f .PredictorNames ,f .VariableNames ); 
[~,model .RespLoc ]=ismember (f .ResponseName ,f .VariableNames ); 
model =selectVariables @classreg .regr .ParametricRegression (model ); 
end


function model =postFit (model )
model =postFit @classreg .regr .ParametricRegression (model ); 
ifisempty (model .Leverage )
wts =get_CombinedWeights_r (model ); 
Xw_r =bsxfun (@times ,model .design_r ,sqrt (wts )); 
[Qw_r ,~,~]=qr (Xw_r ,0 ); 
h =zeros (size (model .ObservationInfo ,1 ),1 ); 
h (model .ObservationInfo .Subset )=sum (abs (Qw_r ).^2 ,2 ); 
model .Leverage =h ; 
end
end


function design_r =create_design_r (model )
design_r =model .Design (model .ObservationInfo .Subset ,:); 
end

function model =removeCategoricalPowers (model ,silent )
ifnargin <2 
silent =false ; 
end
f =model .Formula ; 
isCat =model .VariableInfo .IsCategorical ; 
model .Formula =removeCategoricalPowers (f ,isCat ,silent ); 
end


function fit =stepwiseFitter (start ,nsteps ,verbose )
lowerBound =start .Steps .Lower .Terms ; 
upperBound =start .Steps .Upper .Terms ; 
crit =start .Steps .Criterion ; 
[addTest ,addThreshold ,removeTest ,removeThreshold ,reportedNames ,testName ]=...
    start .getStepwiseTests (crit ,start .Steps ); 

terms =start .Formula .Terms ; 
varNames =start .Formula .VariableNames ; 
[~,~,startReportedVals ]=addTest (start ,[]); 
ifisempty (start .Steps .History )
history =table (nominal ('Start' ,[],{'Start' ,'Add' ,'Remove' }),...
    {start .Formula .LinearPredictor },...
    {terms },start .NumEstimatedCoefficients ,NaN ,startReportedVals {:},...
    'VariableNames' ,[{'Action' ,'TermName' ,'Terms' ,'DF' ,'delDF' },reportedNames ]); 
else
history =start .Steps .History ; 
end
fit =start ; 
justAdded =[]; 
justRemoved =[]; 

whilensteps >0 
nsteps =nsteps -1 ; 
changed =false ; 


candidates =find (candidatesToAdd (terms ,upperBound ,justRemoved )); 
bestTestVal =Inf ; 
X =getData (fit ); 
[Qdesign ,~]=qr (fit .design_r ,0 ); 
inclRows =fit .ObservationInfo .Subset ; 
forj =1 :length (candidates )
newtermj =upperBound (candidates (j ),:); 
[termsj ,ord ]=sortTerms ([terms ; newtermj ]); 
[~,locj ]=max (ord ); 
newxterms =designMatrix (fit ,X ,[],newtermj ); 

ifredundantTerm (Qdesign ,newxterms ,inclRows )
testValj =Inf ; 
else
fitj =reFit (fit ,termsj ); 

[testValj ,testValjReported ,reportedValsj ]=addTest (fitj ,fit ); 
ifverbose >1 
tn =classreg .regr .modelutils .terms2names (termsj (locj ,:),varNames ); tn =tn {:}; 
fprintf ('   %s' ,getString (message ('stats:classreg:regr:TermsRegression:display_ForAddingIs' ,testName ,tn ,num2str (testValjReported )))); 
end
end
iftestValj <bestTestVal 
bestj =j ; 
bestTerms =termsj ; 
bestLoc =locj ; 
bestFit =fitj ; 
bestTestVal =testValj ; 
bestReportedVals =reportedValsj ; 
end
end
ifverbose >1 &&isempty (candidates )
fprintf ('   %s' ,getString (message ('stats:classreg:regr:TermsRegression:display_NoCandidateTermsToAdd' ))); 
end

ifbestTestVal <addThreshold 
addedTermName =classreg .regr .modelutils .terms2names (bestTerms (bestLoc ,:),varNames ); 
delDF =fit .DFE -bestFit .DFE ; 
history (end+1 ,:)=table (nominal ('Add' ),addedTermName ,{bestTerms },bestFit .NumEstimatedCoefficients ,delDF ,bestReportedVals {:}); 
ifverbose 
allVals =strcat (reportedNames (:),{' = ' },strjust (num2str (cat (1 ,bestReportedVals {:})),'left' )); 
displayString =sprintf (', %s' ,allVals {:}); 
fprintf ('%s' ,getString (message ('stats:classreg:regr:TermsRegression:display_Adding' ,size (history ,1 )-1 ,history .TermName {end},displayString ))); 
end
terms =bestTerms ; 
fit =bestFit ; 
changed =true ; 
justAdded =bestLoc ; 
justRemoved =[]; 

else
ifverbose >2 
fprintf ('   %s' ,getString (message ('stats:classreg:regr:TermsRegression:display_NoTermsToAddSmallestPValue' ,num2str (bestTestVal )))); 
end

candidates =find (candidatesToRemove (terms ,lowerBound ,justAdded )); 
bestTestVal =-Inf ; 
terminfo =getTermInfo (fit ); 
designterms =terminfo .designTerms ; 
forj =1 :length (candidates )
termsj =terms ; 
termsj (candidates (j ),:)=[]; 
dtj =(designterms ==candidates (j )); 
newxterms =fit .design_r (:,dtj ); 
[qrd ,~]=qr (fit .design_r (:,~dtj ),0 ); 
fitj =reFit (fit ,termsj ); 

[testValj ,testValjReported ,reportedValsj ]=removeTest (fitj ,fit ); 
ifverbose >1 
tn =classreg .regr .modelutils .terms2names (terms (candidates (j ),:),varNames ); tn =tn {:}; 
fprintf ('   %s' ,getString (message ('stats:classreg:regr:TermsRegression:display_ForRemovingIs' ,testName ,tn ,num2str (testValjReported )))); 
end






ifisnan (testValj )||testValj >bestTestVal 


bestj =j ; 
bestTerms =termsj ; 
bestFit =fitj ; 
bestTestVal =testValj ; 
bestReportedVals =reportedValsj ; 
ifisnan (testValj )
break
end
end
end
ifverbose >1 &&isempty (candidates )
fprintf ('   %s' ,getString (message ('stats:classreg:regr:TermsRegression:display_NoCandidateTermsToRemove' ))); 
end


ifisnan (bestTestVal )||bestTestVal >removeThreshold 
removedTerm =terms (candidates (bestj ),:); 
removedTermName =classreg .regr .modelutils .terms2names (removedTerm ,varNames ); 
delDF =fit .DFE -bestFit .DFE ; 
history (end+1 ,:)=table (nominal ('Remove' ),removedTermName ,{bestTerms },bestFit .NumEstimatedCoefficients ,delDF ,bestReportedVals {:}); 
ifverbose 
allVals =strcat (reportedNames (:),{' = ' },strjust (num2str (cat (1 ,bestReportedVals {:}),'%.5g' ),'left' )); 
displayString =sprintf (', %s' ,allVals {:}); 
fprintf ('%s' ,getString (message ('stats:classreg:regr:TermsRegression:display_Removing' ,size (history ,1 )-1 ,history .TermName {end},displayString ))); 
end
terms =bestTerms ; 
fit =bestFit ; 
changed =true ; 
justAdded =[]; 
[~,justRemoved ]=ismember (removedTerm ,upperBound ,'rows' ); 
ifjustRemoved ==0 
justRemoved =[]; 
end
else
ifverbose >2 
fprintf ('%s' ,getString (message ('stats:classreg:regr:TermsRegression:display_DidntRemoveAnything' ,num2str (bestTestVal )))); 
end
end
end
if~changed ,break,end
end
ifverbose &&size (history ,1 )==1 
fprintf (getString (message ('stats:classreg:regr:TermsRegression:display_NoTermsToAddToOrRemoveFromInitialModel' ))); 
end
fit .Steps =start .Steps ; 





fit .Steps .History =history ; 
end

function model =getTermMeans (model )



isCat =model .VariableInfo .IsCategorical ; 


terms =model .Formula .Terms ; 


[isHier ,subset ]=classreg .regr .modelutils .ishierarchical (terms ,isCat ); 


ifisempty (subset )
m =zeros (1 ,0 ); 
coefTerm =m ; 
else
X =getData (model ); 
X =X (model .ObservationInfo .Subset ,:); 
[design ,coefTerm ]=designMatrix (model ,X ,[],subset ); 
m =mean (design ,1 ); 
end


s =struct ('Terms' ,subset ,'CoefTerm' ,coefTerm ,'Means' ,m ); 
model .TermMeans =s ; 
model .IsHierarchical =isHier ; 
end
end

methods (Static ,Access ='protected' )

function [penter ,premove ]=getDefaultThresholds (crit ,penter ,premove )
smaller =true ; 

critString =internal .stats .isString (crit ); 
if~critString &&~isa (crit ,'function_handle' )
error (message ('stats:classreg:regr:TermsRegression:BadStepwiseCriterion' )); 
end
if(isempty (penter )||isempty (premove ))&&~critString 
error (message ('stats:classreg:regr:TermsRegression:MissingThreshold' )); 
end

ifcritString 
allcrit ={'AIC' ,'BIC' ,'Rsquared' ,'AdjRsquared' ,'SSE' }; 
crit =internal .stats .getParamVal (crit ,allcrit ,'''Criterion''' ); 

switchlower (crit )
case {'aic' ,'bic' }
ifisempty (penter ),penter =0 ; end
ifisempty (premove ),premove =0.01 ; end
case 'rsquared' 
smaller =false ; 
ifisempty (penter ),penter =0.1 ; end
ifisempty (premove ),premove =0.05 ; end
case 'adjrsquared' 
smaller =false ; 
ifisempty (penter ),penter =0 ; end
ifisempty (premove ),premove =-0.05 ; end
case 'sse' 
ifisempty (penter ),penter =0.05 ; end
ifisempty (premove ),premove =0.10 ; end
end
end

ifsmaller &&penter >=premove 
error (message ('stats:LinearModel:BadSmallerThreshold' ,sprintf ('%g' ,penter ),sprintf ('%g' ,premove ),crit )); 
elseif~smaller &&penter <=premove 
error (message ('stats:LinearModel:BadLargerThreshold' ,sprintf ('%g' ,penter ),sprintf ('%g' ,premove ),crit )); 
end
end

function [X ,y ,haveDataset ,otherArgs ]=handleDataArgs (X ,y ,varargin )
ifisa (X ,'dataset' )
X =dataset2table (X ); 
end

haveDataset =isa (X ,'table' ); 
ifhaveDataset 

ifnargin >1 

otherArgs =[{y },varargin ]; 
else
otherArgs ={}; 
end
y =[]; 
elseifnargin <2 
error (message ('stats:classreg:regr:TermsRegression:MissingY' ))
else
ifisrow (X )
nx =length (X ); 
if(isvector (y )&&numel (y )==nx )||(size (y ,1 )==nx )
X =X ' ; 
end
end
isNumVarX =isnumeric (X )||islogical (X ); 
isCatVecX =isa (X ,'categorical' )&&isvector (X ); 
if~(isNumVarX ||isCatVecX )
error (message ('stats:classreg:regr:FitObject:PredictorMatricesRequired' )); 
end
otherArgs =varargin ; 
end
end

function [addTest ,addThreshold ,removeTest ,removeThreshold ,reportedNames ,testName ]=getStepwiseTests (crit ,Steps )

addThreshold =Steps .PEnter ; 
removeThreshold =Steps .PRemove ; 
[addThreshold ,removeThreshold ]=classreg .regr .TermsRegression .getDefaultThresholds (crit ,addThreshold ,removeThreshold ); 
ifinternal .stats .isString (crit )
allcrit ={'AIC' ,'BIC' ,'Rsquared' ,'AdjRsquared' ,'SSE' }; 
crit =internal .stats .getParamVal (crit ,allcrit ,'''Criterion''' ); 
switchlower (crit )
case {'aic' ,'bic' }
addTest =@(proposed ,current )...
    generic_test (proposed ,current ,@(fit )get_modelcriterion (fit ,crit ),'decreasing' ); 
removeTest =@(proposed ,current )...
    generic_test (proposed ,current ,@(fit )get_modelcriterion (fit ,crit ),'increasing' ); 
reportedNames ={upper (crit )}; 
testName =sprintf ('%s' ,getString (message ('stats:classreg:regr:TermsRegression:display_ChangeIn' ,upper (crit )))); 
case {'rsquared' ,'adjrsquared' }
ifstrcmpi (crit ,'rsquared' )
rsqType ='Ordinary' ; 
else
rsqType ='Adjusted' ; 
end
addThreshold =-addThreshold ; 
removeThreshold =-removeThreshold ; 
addTest =@(proposed ,current )...
    generic_test (proposed ,current ,@(fit )get_rsquared (fit ,rsqType ),'increasing' ); 
removeTest =@(proposed ,current )...
    generic_test (proposed ,current ,@(fit )get_rsquared (fit ,rsqType ),'decreasing' ); 
reportedNames ={crit }; 
testName =sprintf ('%s' ,getString (message ('stats:classreg:regr:TermsRegression:display_ChangeIn' ,crit ))); 
case 'sse' 
addTest =@(proposed ,current )f_test (proposed ,current ,'up' ); 
removeTest =@(proposed ,current )f_test (current ,proposed ,'down' ); 
reportedNames ={'FStat' ,'pValue' }; 
testName ='pValue' ; 
end
elseifisa (crit ,'function_handle' )
fun =crit ; 
addTest =@(proposed ,current )generic_test (proposed ,current ,fun ,'decreasing' ); 
removeTest =@(proposed ,current )generic_test (proposed ,current ,fun ,'increasing' ); 
reportedNames ={'ModelCriterion' }; 
testName =getString (message ('stats:classreg:regr:TermsRegression:assignment_ChangeInModelCriterion' )); 
elseifiscell (crit )&&(numel (crit )==3 )&&all (cellfun (@(c )isa (c ,'function_handle' ),crit ))
addTest =crit {1 }; 
removeTest =crit {2 }; 
reportedNames ={'ModelCriterion' }; 
testName =getString (message ('stats:classreg:regr:TermsRegression:assignment_ChangeInModelCriterion' )); 
else
error (message ('stats:classreg:regr:TermsRegression:BadStepwiseCriterion' )); 
end
end
end

methods (Hidden ,Static ,Access ='public' )

function formula =createFormula (supplied ,modelDef ,X ,...
    predictorVars ,responseVar ,intercept ,link ,varNames ,haveDataset ,clink )
ifnargin <10 
clink ='identity' ; 
end

givenTerms =classreg .regr .LinearFormula .isTermsMatrix (modelDef ); 
givenAlias =classreg .regr .LinearFormula .isModelAlias (modelDef ); 
givenString =~givenAlias &&internal .stats .isString (modelDef ); 

if~haveDataset 
isTall =istall (X ); 
isTallTable =isTall &&strcmp (tall .getClass (X ),'table' ); 
ifisTall &&~isTallTable 
nx =gather (size (X ,2 )); 
elseifisTallTable 
nvars =length (X .Properties .VariableNames ); 
nx =[]; 
elseifischar (X )
nx =1 ; 
else
nx =size (X ,2 ); 
end
if~isTallTable 
[varNames ,predictorVars ,responseVar ]=...
    classreg .regr .FitObject .getVarNames (varNames ,predictorVars ,responseVar ,nx ); 
end
end

ifisa (modelDef ,'classreg.regr.LinearFormula' )

formula =modelDef ; 

elseifgivenString ||givenTerms ||givenAlias 
ifhaveDataset ||isTallTable 


ifsupplied .VarNames 
error (message ('stats:classreg:regr:TermsRegression:NoVarNames' )); 
end
varNames =X .Properties .VariableNames ; 
nvars =length (varNames ); 
else


ifsupplied .ResponseVar &&~internal .stats .isString (responseVar )
error (message ('stats:classreg:regr:TermsRegression:BadResponseVar' )); 
end
if~isempty (nx )
nvars =nx +1 ; 
end
ifisempty (varNames )
ifgivenString 




formula =classreg .regr .LinearFormula (modelDef ,[],[],[],link ); 
varNames =formula .VariableNames ; 
varnum =0 ; 
while(length (varNames )<nvars )
varnum =varnum +1 ; 
newname =sprintf ('x%d' ,varnum ); 
if~ismember (newname ,varNames )
varNames {end+1 }=newname ; 
end
end
responseName =formula .ResponseName ; 
respLoc =find (strcmp (responseName ,varNames )); 
varNames =varNames ([1 :(respLoc -1 ),(respLoc +1 ):end,respLoc ]); 
elseifgivenTerms 
varNames =[]; 
else


varNames =nvars ; 
end
else
iflength (varNames )~=nvars 
error (message ('stats:classreg:regr:TermsRegression:BadVarNames' )); 
end
end
end

ifgivenString 
if~supplied .Intercept 
intercept =[]; 
end
formula =classreg .regr .LinearFormula (modelDef ,varNames ,'' ,intercept ,link ); 


if(supplied .PredictorVars &&~all (ismember (formula .PredictorNames ,predictorVars )))||...
    (supplied .ResponseVar &&~strcmp (formula .ResponseName ,responseVar ))
error (message ('stats:classreg:regr:TermsRegression:NoFormulaVars' )); 
end

elseifgivenTerms 
ifsupplied .PredictorVars 
error (message ('stats:classreg:regr:TermsRegression:NoTermsVars' )); 
end
ifhaveDataset ||isTallTable 
ifsize (modelDef ,2 )~=nvars 
ifsize (modelDef ,2 )==1 &&size (modelDef ,1 )==size (X ,1 )
error (message ('stats:classreg:regr:TermsRegression:SeparateResponse' )); 
else
error (message ('stats:classreg:regr:TermsRegression:BadTermsDataset' )); 
end
end
if~supplied .ResponseVar 
responseVar =[]; 
end
else

ncols =size (modelDef ,2 ); 
ifncols ~=nvars 
ifncols ==nvars -1 
modelDef (:,nvars )=0 ; 
else
error (message ('stats:classreg:regr:TermsRegression:BadTermsMatrix' )); 
end
end
responseVar =nvars ; 
end
formula =classreg .regr .LinearFormula (modelDef ,varNames ,responseVar ,intercept ,link ); 

else
ifhaveDataset ||isTallTable 
if~supplied .ResponseVar 
responseVar =[]; 
end
elseif~internal .stats .isString (responseVar )

responseVar =nvars ; 
end
ifsupplied .PredictorVars 
modelDef ={modelDef ,predictorVars }; 
elseif(haveDataset ||isTallTable )&&isempty (predictorVars )
predictorVars =getValidPredictors (X ,varNames ,responseVar ); 
if~isempty (predictorVars )
modelDef ={modelDef ,predictorVars }; 
end
end

formula =classreg .regr .LinearFormula (modelDef ,varNames ,responseVar ,intercept ,link ); 
end

else
error (message ('stats:classreg:regr:TermsRegression:BadModelDef' )); 
end

if~haveDataset &&~isTallTable 
ifsupplied .VarNames &&length (formula .VariableNames )~=nvars 
error (message ('stats:classreg:regr:TermsRegression:BadVarNamesXY' )); 
end
end



ifisempty (link )&&~isequal (clink ,'identity' )&&isequal (formula .Link ,'identity' )
formula .Link =clink ; 
end
end
function model =loadobj (obj )
obj =loadobj @classreg .regr .ParametricRegression (obj ); 
ifisfield (obj .Steps ,'History' )&&isa (obj .Steps .History ,'dataset' )
obj .Steps .History =dataset2table (obj .Steps .History ); 
end
model =obj ; 
end
end
end


function [terms ,iterms ]=sortTerms (terms )








[nterms ,nvars ]=size (terms ); 
iterms =(1 :nterms )' ; 
[terms ,ord ]=unique (terms ,'rows' ); 
iterms =iterms (ord ); 
[terms ,ord ]=sortrows (terms ,-1 :-1 :-nvars ); 
iterms =iterms (ord ); 
[~,ord ]=sortrows ([sum (terms ,2 ),max (terms ,[],2 )]); 
terms =terms (ord ,:); 
iterms =iterms (ord ); 
end


function candidates =candidatesToAdd (current ,upperBound ,justRemoved )

[potentialCandidates ,icandidates ]=setdiff (upperBound ,current ,'rows' ); 
candidates =false (size (upperBound ,1 ),1 ); 
candidates (icandidates )=true ; 


if~isempty (justRemoved )
candidates (justRemoved )=false ; 
end







order =sum (potentialCandidates ,2 ); 
ifmax (order )>1 
[~,ord ]=sort (order ,1 ,'ascend' ); 
not =false (size (potentialCandidates ,1 ),1 ); 
fori =ord (:)' 
subterm =potentialCandidates (i ,:); 
termDiffs =bsxfun (@minus ,potentialCandidates ,subterm ); 
j =all (bsxfun (@times ,termDiffs ,subterm >0 )>=0 ,2 ); 
j (i )=false ; 
not =not |j ; 

ifall (not ),break; end
end
candidates (icandidates (not ))=false ; 
end
end


function candidates =candidatesToRemove (current ,lowerBound ,justAdded )

[potentialCandidates ,icandidates ]=setdiff (current ,lowerBound ,'rows' ); 
candidates =false (size (current ,1 ),1 ); 
candidates (icandidates )=true ; 


if~isempty (justAdded )
candidates (justAdded )=false ; 
end



order =sum (potentialCandidates ,2 ); 
[~,ord ]=sort (order ,1 ,'descend' ); 
not =false (size (potentialCandidates ,1 ),1 ); 
fori =ord (:)' 
superterm =potentialCandidates (i ,:); 
termDiffs =bsxfun (@minus ,superterm ,potentialCandidates ); 
j =all (termDiffs .*(potentialCandidates >0 )>=0 ,2 ); 
j (i )=false ; 
not =not |j ; 

ifall (not ),break; end
end
candidates (icandidates (not ))=false ; 
end


function model =reFit (model ,terms )
model .Formula .Terms =terms ; 
model =doFit (model ); 
end

function [delCrit ,critReported ,reportedVals ]=generic_test (proposed ,current ,critfun ,direction )


newCrit =critfun (proposed ); 
ifisempty (current )
oldCrit =newCrit ; 
else
oldCrit =critfun (current ); 
end


critReported =newCrit -oldCrit ; 
ifstrcmp (direction ,'decreasing' )
delCrit =critReported ; 
else
delCrit =-critReported ; 
end
reportedVals ={newCrit }; 
end

function [p ,pReported ,reportedVals ]=f_test (fit1 ,fit0 ,~)
sse1 =fit1 .SSE ; 
dfDenom =fit1 .DFE ; 
ifisempty (fit0 )
sse0 =sse1 ; 
dfNumer =0 ; 
else
sse0 =fit0 .SSE ; 
dfNumer =fit0 .DFE -fit1 .DFE ; 
end
F =((sse0 -sse1 )/dfNumer )/(fit1 .SSE /dfDenom ); 
p =fcdf (1 ./F ,dfDenom ,dfNumer ); 
pReported =p ; 
reportedVals ={F ,p }; 
end



function tf =redundantTerm (Q ,y ,inclRows )
ifnargin >=3 
y =y (inclRows ,:); 
end
yfit =Q *(Q ' *y ); 
res =y -yfit ; 
ratio =sum (abs (res (:)).^2 )/sum (abs (y (:).^2 )); 
tf =ratio <(eps ^(3 /4 ))*size (Q ,2 )*sqrt (size (Q ,1 )); 
end


function predVars =getValidPredictors (X ,varNames ,responseVar )



ifisa (X ,'dataset' )
X =dataset2tabel (X ); 
end
dsVarNames =X .Properties .VariableNames ; 
ifisempty (varNames )
predictors =1 :size (X ,2 ); 
else
predictors =find (ismember (dsVarNames ,varNames )); 
end


if~isempty (responseVar )&&(~isnumeric (responseVar )||isscalar (responseVar ))
ifislogical (responseVar )
response =find (responseVar ); 
elseif~isnumeric (responseVar )
response =find (strcmp (responseVar ,dsVarNames )); 
else
response =responseVar ; 
end
ifisscalar (response )
predictors =predictors (predictors ~=response ); 
end
end


okResponse =false (length (predictors ),1 ); 
forj =1 :length (predictors )
v =X .(dsVarNames {predictors (j )}); 
ifistall (v )

okResponse (j )=true ; 
elseifischar (v )&&ismatrix (v )

elseif~isvector (v )
predictors (j )=0 ; 
elseifiscell (v )
if~iscellstr (v )
predictors (j )=0 ; 
end
elseif~isnumeric (v )&&~islogical (v )&&~isa (v ,'categorical' )
predictors (j )=0 ; 
elseifisnumeric (v )||islogical (v )
okResponse (j )=true ; 
end
end



ifisempty (responseVar )&&any (okResponse )
predictors (find (okResponse ,1 ,'last' ))=0 ; 
end


predVars =dsVarNames (predictors (predictors ~=0 )); 
end
