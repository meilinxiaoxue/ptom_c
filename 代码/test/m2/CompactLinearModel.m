classdef (AllowedSubclasses ={?LinearModel })CompactLinearModel <classreg .regr .CompactTermsRegression 









































properties (GetAccess ='public' ,SetAccess ='protected' )






MSE 













Robust =[]; 
end
properties (GetAccess ='protected' ,SetAccess ='protected' )
Qy 
R 
Rtol 
PrivateLogLikelihood 
end
properties (Dependent =true ,GetAccess ='public' ,SetAccess ='protected' )






RMSE 
end

methods 
function s =get .RMSE (model )
s =sqrt (model .MSE ); 
end






end

methods (Hidden =true ,Access ='public' )
function model =CompactLinearModel (varargin )
ifnargin ==0 
model .Formula =classreg .regr .LinearFormula ; 
return 
end
error (message ('stats:LinearModel:NoConstructor' )); 
end



function isVirtual =isVariableEditorVirtualProp (~,~)




isVirtual =false ; 
end
function isComplex =isVariableEditorComplexProp (~,~)

isComplex =false ; 
end
function isSparse =isVariableEditorSparseProp (~,~)

isSparse =false ; 
end
function className =getVariableEditorClassProp (~,~)

className ='table' ; 
end
function sizeArray =getVariableEditorSize (this ,~)
sizeArray =[size (this .ObservationInfo .Subset ,1 ); 7 ]; 
end
end
methods (Hidden =true )
function s =toStruct (this )


warnState =warning ('query' ,'all' ); 
warning ('off' ,'MATLAB:structOnObject' ); 
cleanupObj =onCleanup (@()warning (warnState )); 

s =struct ; 
meta =?classreg .regr .CompactLinearModel ; 
props =meta .PropertyList ; 
props ([props .Dependent ]|[props .Constant ])=[]; 


propsToExclude ={'VariableInfo' ,'Formula' ,'CoefficientNames' ,'Robust' }; 
fn ={props .Name }; 
forj =1 :length (fn )
name =fn {j }; 
if~ismember (name ,propsToExclude )
s .(name )=this .(name ); 
end
end

robustStr =this .Robust ; 
if~isempty (robustStr )
robustStr .RobustWgtFun =func2str (robustStr .RobustWgtFun ); 

robustStr .Weights =[]; 
s .Robust =robustStr ; 
else
s .Robust =robustStr ; 
end
s =classreg .regr .coderutils .regrToStruct (s ,this ); 
s .FromStructFcn ='classreg.regr.CompactLinearModel.fromStruct' ; 
end
end
methods (Access ='public' )
function disp (model )




isLoose =strcmp (get (0 ,'FormatSpacing' ),'loose' ); 
if(isLoose ),fprintf ('\n' ); end
ifisempty (model .Robust )
fprintf ('%s' ,getString (message ('stats:LinearModel:display_CompactLinearRegressionModel' ))); 
else
fprintf ('%s' ,getString (message ('stats:LinearModel:display_CompactLinearRegressionModelrobustFit' ))); 
end

dispBody (model )
end


function [varargout ]=predict (model ,Xpred ,varargin )








































[varargin {:}]=convertStringsToChars (varargin {:}); 
ifisa (Xpred ,'tall' )
[varargout {1 :max (1 ,nargout )}]=hSlicefun (@model .predict ,Xpred ,varargin {:}); 
return 
end
design =designMatrix (model ,Xpred ); 
[varargout {1 :max (1 ,nargout )}]=predictDesign (model ,design ,varargin {:}); 
end


function ysim =random (model ,x )
























ypred =predict (model ,x ); 
ysim =normrnd (ypred ,model .RMSE ); 
end

function tbl =anova (model ,anovatype ,sstype )






































ifnargin <2 
anovatype ='components' ; 
else
anovatype =convertStringsToChars (anovatype ); 
anovatype =internal .stats .getParamVal (anovatype ,...
    {'summary' ,'components' ,'oldcomponents' ,'newcomponents' },'second' ); 
end
ifnargin <3 
sstype ='h' ; 
end
sstype =convertStringsToChars (sstype ); 
switch(lower (anovatype ))
case 'components' 
tbl =componentanova (model ,sstype ); 
case 'oldcomponents' 
tbl =componentanova (model ,sstype ,true ); 
case 'newcomponents' 
tbl =componentanova (model ,sstype ,false ); 
case 'summary' 
tbl =summaryanova (model ); 
otherwise
error (message ('stats:LinearModel:BadAnovaType' )); 
end
end



function fout =plotSlice (model )




















f =classreg .regr .modelutils .plotSlice (model ); 
ifnargout >0 
fout =f ; 
end
end
function hout =plotEffects (model )



































if~hasData (model )&&~isHierarchical (model )&&...
    (isempty (model .TermMeans )||isempty (model .TermMeans .Terms ))
error (message ('stats:LinearModel:PlotHierarchy' )); 
end


[effect ,effectSE ,effectname ]=getEffects (model ); 


y =(1 :length (effect ))' ; 
ci =[effect ,effect ]+effectSE *tinv ([.025 ,.975 ],model .DFE ); 
h =plot (effect ,y ,'bo' ,ci ' ,[y ,y ]' ,'b-' ); 
set (h (1 ),'Tag' ,'estimate' ); 
set (h (2 :end),'Tag' ,'ci' ); 
xlabel (getString (message ('stats:LinearModel:xylabel_MainEffect' ))); 
set (gca ,'YTick' ,y ,'YTickLabel' ,effectname ,'YLim' ,[.5 ,max (y )+.5 ],'YDir' ,'reverse' ); 
dfswitchyard ('vline' ,gca ,0 ,'LineStyle' ,':' ,'Color' ,'k' ); 

ifnargout >0 
hout =h ; 
end
end
function hout =plotInteraction (model ,var1 ,var2 ,ptype )


















































ifnargin <4 
ptype ='effects' ; 
end
var1 =convertStringsToChars (var1 ); 
var2 =convertStringsToChars (var2 ); 
ptype =convertStringsToChars (ptype ); 




if~hasData (model )&&~isHierarchical (model )&&...
    (isempty (model .TermMeans )||isempty (model .TermMeans .Terms ))
error (message ('stats:LinearModel:PlotHierarchy' )); 
end




terminfo =getTermInfo (model ); 
[vname1 ,vnum1 ]=identifyVar (model ,var1 ); 
[vname2 ,vnum2 ]=identifyVar (model ,var2 ); 

ifisequal (vname1 ,model .ResponseName )||isequal (vname2 ,model .ResponseName )
error (message ('stats:LinearModel:ResponseNotAllowed' ,model .ResponseName ))
elseifisequal (vnum1 ,vnum2 )
error (message ('stats:LinearModel:DifferentPredictors' ))
end

switch(ptype )
case 'effects' 
h =plotInteractionEffects (model ,vnum1 ,vnum2 ,vname1 ,vname2 ,terminfo ); 
case 'predictions' 
h =plotInteractionPredictions (model ,vnum1 ,vnum2 ,vname1 ,vname2 ,terminfo ); 
otherwise
error (message ('stats:LinearModel:BadEffectsType' )); 
end

ifnargout >0 
hout =h ; 
end
end


end

methods (Access ='protected' )
function dispBody (model )

indent ='    ' ; 
maxWidth =matlab .desktop .commandwindow .size ; maxWidth =maxWidth (1 )-1 ; 
f =model .Formula ; 
fstr =char (f ,maxWidth -length (indent )); 
disp ([indent ,fstr ]); 

if~isnan (model .DFE )

fprintf ('%s' ,getString (message ('stats:LinearModel:display_EstimatedCoefficients' ))); 
else
fprintf (getString (message ('stats:LinearModel:display_Coefficients' ))); 
end
disp (model .Coefficients ); 

if~isnan (model .DFE )
fprintf ('%s' ,getString (message ('stats:LinearModel:display_NumObservationsDFE' ,model .NumObservations ,model .DFE ))); 
end
ifmodel .MSE >0 &&~isnan (model .MSE )
fprintf ('%s' ,getString (message ('stats:LinearModel:display_RMSE' ,num2str (model .RMSE ,'%.3g' )))); 
end
ifhasConstantModelNested (model )&&model .NumPredictors >0 
rsq =get_rsquared (model ,{'ordinary' ,'adjusted' }); 
fprintf ('%s' ,getString (message ('stats:LinearModel:display_RsquaredAdj' ,num2str (rsq (1 ),'%.3g' ),num2str (rsq (2 ),'%.3g' )))); 
[f ,p ]=fTest (model ); 
fprintf ('%s' ,getString (message ('stats:LinearModel:display_Ftest' ,num2str (f ,'%.3g' ),num2str (p ,'%.3g' )))); 
end
end


function L =getlogLikelihood (model )
sigmaHat =sqrt (model .DFE /model .NumObservations *model .MSE ); 
ifsigmaHat ==0 

L =Inf ; 
else
n =model .NumObservations ; 
L =-(n /2 )*log (2 *pi )-n *log (sigmaHat )-0.5 *model .SSE /(sigmaHat ^2 ); 

end
end


function ypred =predictPredictorMatrix (model ,Xpred )

ypred =designMatrix (model ,Xpred ,true )*model .Coefs ; 
end
function [ypred ,yCI ]=predictDesign (model ,design ,varargin )
paramNames ={'Alpha' ,'Simultaneous' ,'Prediction' ,'Confidence' }; 
paramDflts ={.05 ,false ,'curve' ,.95 }; 
[alpha ,simOpt ,predOpt ,conf ,supplied ]=...
    internal .stats .parseArgs (paramNames ,paramDflts ,varargin {:}); 
ifsupplied .Confidence &&supplied .Alpha 
error (message ('stats:LinearModel:ArgCombination' ))
end
ifsupplied .Confidence 
alpha =1 -conf ; 
end

predOpt =internal .stats .getParamVal (predOpt ,...
    {'curve' ,'observation' },'''Prediction''' ); 
predOpt =strcmpi (predOpt ,'observation' ); 
simOpt =internal .stats .parseOnOff (simOpt ,'''Simultaneous''' ); 
ifnargout <2 
ypred =predci (design ,model .Coefs ); 
else
[ypred ,yCI ]=predci (design ,model .Coefs ,...
    model .CoefficientCovariance ,model .MSE ,...
    model .DFE ,alpha ,simOpt ,predOpt ,model .Formula .HasIntercept ); 
end
end
function h =plotInteractionPredictions (model ,vnum1 ,vnum2 ,vname1 ,vname2 ,terminfo )

[xdata1 ,xlabels1 ]=getInteractionXData (model ,vnum1 ,terminfo ); 
[xdata2 ,xlabels2 ]=getInteractionXData (model ,vnum2 ,terminfo ); 


if~terminfo .isCatVar (vnum1 )

xdata1 =xdata1 ([1 ,51 ,101 ]); 
xlabels1 =cellstr (strjust (num2str (xdata1 ),'left' )); 
end


ngrid2 =length (xdata2 ); 
ifterminfo .isCatVar (vnum2 )

xi2 =(1 :ngrid2 )' ; 
plotspec ='-o' ; 
else

xi2 =xdata2 ; 
plotspec ='-' ; 
end

y =zeros (ngrid2 ,length (xdata1 )); 
xi =[xi2 ,xi2 ]; 
forj =1 :size (y ,2 )
xi (:,1 )=xdata1 (j ); 
y (:,j )=getAdjustedResponse (model ,[vnum1 ,vnum2 ],xi ,terminfo ); 
end

h =plot (1 ,1 ,xi2 ,y ,plotspec ,'LineWidth' ,2 ); 
set (h (1 ),'LineStyle' ,'none' ,'Marker' ,'none' ,'XData' ,[],'YData' ,[]); 
title (sprintf ('%s' ,getString (message ('stats:LinearModel:sprintf_InteractionOfAnd' ,vname1 ,vname2 )))); 
xlabel (vname2 ); 
ylabel (sprintf ('%s' ,getString (message ('stats:LinearModel:sprintf_Adjusted' ,model .ResponseName )))); 
legend (h ,[vname1 ; xlabels1 (:)]); 

ifterminfo .isCatVar (vnum2 )
set (gca ,'XTick' ,1 :ngrid2 ,'XTickLabel' ,xlabels2 ,'XLim' ,[0.5 ,ngrid2 +0.5 ]); 
end
h (1 )=[]; 
end

function [x ,xlabels ]=getInteractionXData (model ,vnum ,terminfo )
xdata =model .VariableInfo .Range {vnum }; 
ifterminfo .isCatVar (vnum )

[~,xlabels ]=grp2idx (xdata ); 
x =(1 :length (xlabels ))' ; 
else

x =linspace (min (xdata ),max (xdata ),101 )' ; 
xlabels =[]; 
end
end


function h =plotInteractionEffects (model ,vnum1 ,vnum2 ,vname1 ,vname2 ,terminfo )
[effect ,effectSE ,effectName ,x ]=getEffects (model ,[vnum1 ,vnum2 ],terminfo ); 
ci =[effect ,effect ]+effectSE *tinv ([.025 ,.975 ],model .DFE ); 

[ceffect1 ,ceffect1SE ,ceffect1Name ]=getConditionalEffect (model ,vnum1 ,vnum2 ,x (1 ,:)' ,terminfo ); 
ci1 =[ceffect1 ,ceffect1 ]+ceffect1SE *tinv ([.025 ,.975 ],model .DFE ); 

[ceffect2 ,ceffect2SE ,ceffect2Name ]=getConditionalEffect (model ,vnum2 ,vnum1 ,x (2 ,:)' ,terminfo ); 
ci2 =[ceffect2 ,ceffect2 ]+ceffect2SE *tinv ([.025 ,.975 ],model .DFE ); 


gap =2 ; 
y0 =[1 ; 2 +gap +length (ceffect1 )]; 
y1 =1 +(1 :length (ceffect1 ))' ; 
y2 =2 +gap +length (ceffect1 )+(1 :length (ceffect2 ))' ; 
y =[y0 (1 ); y1 ; y0 (2 ); y2 ]; 
allnames =[effectName (1 ); ceffect1Name ; effectName (2 ); ceffect2Name ]; 

h =plot (effect ,y0 ,'bo' ,ci ' ,[y0 ,y0 ]' ,'b-' ,'LineWidth' ,2 ,'Tag' ,'main' ); 
washold =ishold ; 
hold on 
h =[h ; 
 plot (ceffect1 ,y1 ,'Color' ,'r' ,'LineStyle' ,'none' ,'Marker' ,'o' ,'Tag' ,'conditional1' ); ...
    plot (ci1 ' ,[y1 ,y1 ]' ,'Color' ,'r' ,'Tag' ,'conditional1' ); ...
    plot (ceffect2 ,y2 ,'Color' ,'r' ,'LineStyle' ,'none' ,'Marker' ,'o' ,'Tag' ,'conditional2' ); ...
    plot (ci2 ' ,[y2 ,y2 ]' ,'Color' ,'r' ,'Tag' ,'conditional2' )]; 
if~washold 
hold off 
end
title (sprintf ('%s' ,getString (message ('stats:LinearModel:sprintf_InteractionOfAnd' ,vname1 ,vname2 )))); 
xlabel (getString (message ('stats:LinearModel:xylabel_Effect' ))); 
set (gca ,'YTick' ,y ,'YTickLabel' ,allnames ,'YLim' ,[.5 ,max (y )+.5 ],'YDir' ,'reverse' ); 
dfswitchyard ('vline' ,gca ,0 ,'LineStyle' ,':' ,'Color' ,'k' ); 
end

function tbl =componentanova (model ,sstype ,refit )


nterms =length (model .Formula .TermNames ); 

iseffects =isequal (model .DummyVarCoding ,'effects' ); 
sstype =getSSType (sstype ); 
ifnargin <3 
refit =sstype ==3 &&~isHierarchical (model )&&~iseffects ; 
end

ifsstype ==3 &&refit 
if~hasData (model )&&~isHierarchical (model )
error (message ('stats:LinearModel:AnovaHierarchy' )); 
end


oldmodel =model ; 
formula =sprintf ('%s ~ %s' ,oldmodel .Formula .ResponseName ,oldmodel .Formula .LinearPredictor ); 
model =LinearModel .fit (oldmodel .Variables ,formula ,'DummyVarCoding' ,'effects' ,...
    'Robust' ,oldmodel .Robust ,'Categorical' ,oldmodel .VariableInfo .IsCategorical ,...
    'Exclude' ,~oldmodel .ObservationInfo .Subset ,'Weight' ,oldmodel .ObservationInfo .Weights ,...
    'Intercept' ,oldmodel .Formula .HasIntercept ); 
end



allmodels =getComparisonModels (model ,sstype ); 
[uniquemodels ,~,uidx ]=unique (allmodels ,'rows' ); 


rtol =model .Rtol ; 
mse =model .MSE ; 
ifsstype ==3 &&~refit &&~iseffects 

[coefs ,coefcov ,R1 ,Qy1 ]=applyEffectsCoding (model ); 
else

R1 =model .R ; 
coefs =model .Coefs ; 
coefcov =model .CoefficientCovariance ; 
Qy1 =model .Qy ; 
end


allSS =zeros (nterms ,2 ); 
allDF =zeros (nterms ,2 ); 
dfx =model .NumObservations -model .DFE ; 
forj =1 :size (uniquemodels ,1 )
[ssModel ,dfModel ]=getTermSS1 (~uniquemodels (j ,:),dfx ,...
    R1 ,mse ,coefs ,coefcov ,Qy1 ,rtol ); 
t =(uidx ==j ); 
allSS (t )=ssModel ; 
allDF (t )=dfModel ; 
end

ss =[max (0 ,diff (allSS ,1 ,2 )); model .SSE ]; 
df =[diff (allDF ,1 ,2 ); model .DFE ]; 


constTerm =all (model .Formula .Terms ==0 ,2 ); 
ss (constTerm ,:)=[]; 
df (constTerm ,:)=[]; 


ms =ss ./df ; 
invalidrows =(1 :length (ms ))' ==length (ms ); 
f =ms ./ms (end); 
pval =fcdf (f ,df ,df (end),'upper' ); 


tbl =table (ss ,df ,ms ,...
    internal .stats .DoubleTableColumn (f ,invalidrows ),...
    internal .stats .DoubleTableColumn (pval ,invalidrows ),...
    'VariableNames' ,{'SumSq' ,'DF' ,'MeanSq' ,'F' ,'pValue' },...
    'RowNames' ,[model .Formula .TermNames (~constTerm ); 'Error' ]); 
end


function tbl =summaryanova (model )










ss =zeros (7 ,1 ); 
df =zeros (7 ,1 ); 
keep =true (7 ,1 ); 

termorder =sum (model .Formula .Terms ,2 ); 


hasconst =any (termorder ==0 ); 
ss (1 )=model .SST ; 
df (1 )=model .NumObservations -hasconst ; 

ss (2 )=model .SSR ; 
dfx =df (1 )-model .DFE ; 
df (2 )=dfx ; 

ss (5 )=model .SSE ; 
df (5 )=model .DFE ; 


ifsum (termorder >1 )>0 &&sum (termorder ==1 )>0 
terminfo =getTermInfo (model ); 
nonlincols =ismember (terminfo .designTerms ,find (termorder >1 )); 
[ss (4 ),df (4 )]=getTermSS (model ,nonlincols ,dfx +hasconst ); 
ss (3 )=ss (2 )-ss (4 ); 
df (3 )=df (2 )-df (4 ); 
else
keep (3 :4 )=false ; 
end


[isrep ,sspe ,dfpe ]=getReplicateInfo (model ); 
ifany (isrep )
ss (7 )=sspe ; 
df (7 )=dfpe ; 
ss (6 )=ss (5 )-ss (7 ); 
df (6 )=df (5 )-df (7 ); 
else
keep (6 :7 )=false ; 
end


ms =ss ./df ; 


invalidrows =[true ,false ,false ,false ,true ,false ,true ]' ; 
mse =[NaN ,ms (5 ),ms (5 ),ms (5 ),NaN ,ms (7 ),NaN ]' ; 
dfe =[NaN ,df (5 ),df (5 ),df (5 ),NaN ,df (7 ),NaN ]' ; 

f =ms ./mse ; 
pval =fcdf (1 ./f ,dfe ,df ); 

obsnames ={'Total' ,'Model' ,'. Linear' ,'. Nonlinear' ...
    ,'Residual' ,'. Lack of fit' ,'. Pure error' }; 
tbl =table (ss (keep ),df (keep ),ms (keep ),...
    internal .stats .DoubleTableColumn (f (keep ),invalidrows (keep )),...
    internal .stats .DoubleTableColumn (pval (keep ),invalidrows (keep )),...
    'VariableNames' ,{'SumSq' ,'DF' ,'MeanSq' ,'F' ,'pValue' },...
    'RowNames' ,obsnames (keep )); 
end

function [isrep ,sspe ,dfpe ]=getReplicateInfo (model )%#ok<MANU> 
isrep =false ; 
sspe =0 ; 
dfpe =0 ; 
end


function allmodels =getComparisonModels (model ,sstype )
terminfo =getTermInfo (model ,false ); 
termcols =terminfo .designTerms ; 
nterms =max (termcols ); 
terms =model .Formula .Terms ; 
allmodels =false (2 *nterms ,length (termcols )); 
continuous =~terminfo .isCatVar ; 
switch(sstype )
case 1 

forj =1 :nterms 
allmodels (j ,:)=termcols <=j ; 
allmodels (j +nterms ,:)=termcols <j ; 
end
case 3 
forj =1 :nterms 
allmodels (j ,:)=true ; 
allmodels (j +nterms ,:)=termcols ~=j ; 
end
case {2 ,'h' }

forj =1 :nterms 

varsin =terms (j ,:); 


out =all (bsxfun (@ge ,terms (:,varsin >0 ),terms (j ,varsin >0 )),2 ); 


ifsstype ==2 
out =out &all (bsxfun (@eq ,terms (:,continuous ),terms (j ,continuous )),2 ); 
end
t =ismember (termcols ,find (~out )); 
allmodels (j ,:)=t |termcols ==j ; 
allmodels (j +nterms ,:)=t ; 
end
end
end


function [ss ,df ]=getTermSS (model ,termcols ,dfbefore )


[ss ,df ]=getTermSS1 (termcols ,dfbefore ,model .R ,model .MSE ,model .Coefs ,...
    model .CoefficientCovariance ,model .Qy ,model .Rtol ); 
end


function [xrow ,psmatrix ,psflag ]=reduceterm (model ,vnum ,terminfo )






xrow =zeros (size (terminfo .designTerms )); 
psmatrix =zeros (length (vnum ),length (terminfo .designTerms )); 
psflag =terminfo .isCatVar (vnum ); 

forj =1 :size (terminfo .terms ,1 )
v =terminfo .terms (j ,:); 
tj =terminfo .designTerms ==j ; 
pwr =v (vnum ); 
[~,meanx ]=gettermmean (model ,v ,vnum ,terminfo ); 

ifall (pwr ==0 |~psflag )



xrow (tj )=meanx ; 
psmatrix (:,tj )=repmat (pwr ' ,1 ,sum (tj )); 
elseifisscalar (vnum )&&sum (terminfo .isCatVar (v >0 ))==sum (psflag )

xrow (tj )=meanx ; 
psmatrix (:,tj )=2 :terminfo .numCatLevels (vnum ); 
else



isreduced =ismember (find (v >0 ),vnum ); 
termcatdims =terminfo .numCatLevels (v >0 ); 
sz1 =ones (1 ,max (2 ,length (termcatdims ))); 
sz1 (~isreduced )=max (1 ,termcatdims (~isreduced )-1 ); 
sz2 =ones (1 ,max (2 ,length (termcatdims ))); 
sz2 (isreduced )=max (1 ,termcatdims (isreduced )-1 ); 


meanx =reshape (meanx ,sz1 ); 
meanx =repmat (meanx ,sz2 ); 
xrow (tj )=meanx (:)' ; 


controws =(pwr >0 )&~psflag ; 
psmatrix (controws ,tj )=repmat (pwr (controws ),1 ,sum (tj )); 


catrows =(pwr >0 )&psflag ; 
catsettings =1 +fullfact (terminfo .numCatLevels (vnum (catrows ))-1 )' ; 
idx =reshape (1 :size (catsettings ,2 ),sz2 ); 
idx =repmat (idx ,sz1 ); 
psmatrix (catrows ,tj )=catsettings (:,idx (:)); 
end
end
end


function [ok ,meanx ]=gettermmean (model ,v ,vnum ,terminfo )





v (vnum )=0 ; 


[ok ,row ]=ismember (v ,terminfo .terms ,'rows' ); 
ifok 

meanx =terminfo .designMeans (terminfo .designTerms ==row ); 
elseif~any (v )

meanx =1 ; 
else

ifisempty (model .TermMeans )
ok =false ; 
else
[ok ,row ]=ismember (v ,model .TermMeans .Terms ,'rows' ); 
end

ifok 
meanx =model .TermMeans .Means (model .TermMeans .CoefTerm ==row ); 
else
meanx =[]; 
end
end
end
end
methods (Hidden =true ,Access ='public' )
function t =title (model )
strLHS =model .ResponseName ; 
strFunArgs =internal .stats .strCollapse (model .Formula .PredictorNames ,',' ); 
t =sprintf ('%s = lm(%s)' ,strLHS ,strFunArgs ); 
end

function v =varianceParam (model )
v =model .MSE ; 
end
function [fxi ,fxiVar ]=getAdjustedResponse (model ,var ,xi ,terminfo )


ifnargin <4 

terminfo =getTermInfo (model ); 
end
ifisnumeric (var )
vnum =var ; 
else
[~,vnum ]=identifyVar (model ,var ); 
end




[xrow ,psmatrix ,psflag ]=reduceterm (model ,vnum ,terminfo ); 


nrows =size (xi ,1 ); 
X =repmat (xrow ,nrows ,1 ); 
fork =1 :length (psflag )
ifpsflag (k )

forj =1 :max (psmatrix (k ,:))
t =(psmatrix (k ,:)==j ); 
ifany (t )
X (:,t )=bsxfun (@times ,X (:,t ),(xi (:,k )==j )); 
end
end
else

forj =1 :max (psmatrix (k ,:))
t =(psmatrix (k ,:)==j ); 
X (:,t )=bsxfun (@times ,X (:,t ),xi (:,k ).^j ); 
end
end
end


fxi =X *model .Coefs ; 
ifnargout >=2 
fxiVar =X *model .CoefficientCovariance *X ' ; 
end
end
function [effects ,effectSEs ,effectnames ,effectXs ]=getEffects (model ,vars ,terminfo )



ifnargin <3 

terminfo =getTermInfo (model ); 
end
ifnargin <2 
vars =model .PredictorNames ; 
end

npred =length (vars ); 
effectnames =cell (npred ,1 ); 
effects =zeros (npred ,1 ); 
effectSEs =zeros (npred ,1 ); 
effectXs =zeros (npred ,2 ); 

forj =1 :length (vars )
[vname ,vnum ]=identifyVar (model ,vars (j )); 
xdata =model .VariableInfo .Range {vnum }; 

ifterminfo .isCatVar (vnum )

[~,xlabels ]=grp2idx (xdata ); 
xi =(1 :length (xlabels ))' ; 
else

xi =linspace (min (xdata ),max (xdata ),101 )' ; 
end


[fxi ,fxiVar ]=getAdjustedResponse (model ,vnum ,xi ,terminfo ); 


[maxf ,maxloc ]=max (fxi ); 
[minf ,minloc ]=min (fxi ); 
effect =maxf -minf ; 
effectSE =sqrt (max (0 ,fxiVar (minloc ,minloc )+fxiVar (maxloc ,maxloc )-2 *fxiVar (minloc ,maxloc ))); 
ifterminfo .isCatVar (vnum )
effectname =sprintf ('%s' ,getString (message ('stats:LinearModel:sprintf_EffectAtoB' ,vname ,xlabels {minloc },xlabels {maxloc }))); 
else
ifminloc >maxloc 
effect =-effect ; 
temp =minloc ; 
minloc =maxloc ; 
maxloc =temp ; 
end
effectname =sprintf ('%s' ,getString (message ('stats:LinearModel:sprintf_EffectAtoB' ,vname ,num2str (xi (minloc )),num2str (xi (maxloc ))))); 
end

effectX =[xi (minloc ),xi (maxloc )]; 

effects (j )=effect ; 
effectnames {j }=effectname ; 
effectSEs (j )=effectSE ; 
effectXs (j ,:)=effectX ; 
end
end
function [effect ,effectSE ,effectName ]=getConditionalEffect (model ,var1 ,var2 ,xi1 ,terminfo )




ifnargin <5 

terminfo =getTermInfo (model ); 
end
[~,vnum1 ]=identifyVar (model ,var1 ); 
[vname2 ,vnum2 ]=identifyVar (model ,var2 ); 
xdata2 =model .VariableInfo .Range {vnum2 }; 

ifterminfo .isCatVar (vnum2 )

[~,xlabels2 ]=grp2idx (xdata2 ); 
ngrid =length (xlabels2 ); 
xi2 =(1 :ngrid )' ; 
else

ngrid =3 ; 
xi2 =linspace (min (xdata2 ),max (xdata2 ),ngrid )' ; 
end

xi =[repmat (xi1 (1 ),ngrid ,1 ),xi2 ; ...
    repmat (xi1 (2 ),ngrid ,1 ),xi2 ]; 



[fxi ,fxiVar ]=getAdjustedResponse (model ,[vnum1 ,vnum2 ],xi ,terminfo ); 


effect =fxi (ngrid +1 :2 *ngrid )-fxi (1 :ngrid ); 
fxiVarDiag =diag (fxiVar ); 
fxiCov =diag (fxiVar (1 :ngrid ,ngrid +1 :2 *ngrid )); 
effectSE =sqrt (max (fxiVarDiag (1 :ngrid )+fxiVarDiag (ngrid +1 :2 *ngrid )-2 *fxiCov ,0 )); 
ifterminfo .isCatVar (vnum2 )
effectName =strcat (sprintf ('%s=' ,vname2 ),xlabels2 (:)); 
else
effectName ={sprintf ('%s=%g' ,vname2 ,xi2 (1 )); ...
    sprintf ('%s=%g' ,vname2 ,xi2 (2 )); ...
    sprintf ('%s=%g' ,vname2 ,xi2 (3 ))}; 
end
end
end

methods (Static ,Hidden )
function obj =fromStruct (s )



s =classreg .regr .coderutils .structToRegr (s ); 
if~isempty (s .Robust )
fh =str2func (s .Robust .RobustWgtFun ); 
fhInfo =functions (fh ); 
ifstrcmpi (fhInfo .type ,'anonymous' )
warning (message ('stats:classreg:loadCompactModel:LinearModelRobustWgtFunReset' )); 
s .Robust =[]; 
else
s .Robust .RobustWgtFun =fh ; 
end
end
obj =classreg .regr .CompactLinearModel .make (s ); 
end
end
methods (Static ,Access ='public' ,Hidden )

function model =make (s )
model =classreg .regr .CompactLinearModel (); 
ifisa (s ,'struct' )


fn =fieldnames (s ); 
elseifisa (s ,'classreg.regr.CompactLinearModel' )

meta =?classreg .regr .CompactLinearModel ; 
props =meta .PropertyList ; 
props ([props .Dependent ]|[props .Constant ])=[]; 
fn ={props .Name }; 
end
forj =1 :length (fn )
name =fn {j }; 
model .(name )=s .(name ); 
end
model .MSE =model .SSE /model .DFE ; 
if~isempty (model .Robust )
model .Robust .Weights =[]; 
end
end
end

methods (Access =private ,Static )
function name =matlabCodegenRedirect (~)
name ='classreg.regr.coder.CompactLinearModel' ; 
end
end

end


function [ypred ,yci ]=predci (X ,beta ,Sigma ,mse ,dfe ,alpha ,sim ,pred ,hasintercept )


ypred =X *beta ; 

ifnargout >1 

if(pred )
varpred =sum ((X *Sigma ).*X ,2 )+mse ; 
else
varpred =sum ((X *Sigma ).*X ,2 ); 
end

if(sim )
if(pred )

if(hasintercept )

sch =length (beta ); 
else

sch =length (beta )+1 ; 
end
else

sch =length (beta ); 
end
crit =sqrt (sch *finv (1 -alpha ,sch ,dfe )); 
else
crit =tinv (1 -alpha /2 ,dfe ); 
end
delta =sqrt (varpred )*crit ; 
yci =[ypred -delta ,ypred +delta ]; 
end
end



function sstype =getSSType (sstype )
ifisscalar (sstype )&&isnumeric (sstype )&&ismember (sstype ,1 :3 )
return 
end
ifisscalar (sstype )&&ischar (sstype )
[tf ,loc ]=ismember (lower (sstype ),'123h' ); 
iftf 
ok ={1 ,2 ,3 ,'h' }; 
sstype =ok {loc }; 
return 
end
end
throwAsCaller (MException (message ('stats:anovan:BadSumSquares' )))
end

function [T ,catvars ,levels ,terms ]=getPredictorTable (model )







[~,predLocs ]=ismember (model .PredictorNames ,model .VariableNames ); 
nvars =length (predLocs ); 


catvars =model .VariableInfo .IsCategorical (predLocs ); 
levels =model .VariableInfo .Range (predLocs ); 
terms =model .Formula .Terms (:,predLocs ); 




vardf =ones (nvars ,1 ); 
forjVar =1 :nvars 
levj =levels {jVar }; 
if~ischar (levj )
levj =levj (:); 
end
ifcatvars (jVar )


vardf (jVar )=size (levj ,1 )-1 ; 
else


maxpower =max (terms (:,jVar )); 
levels {jVar }=linspace (min (levj ),max (levj ),max (2 ,maxpower +1 ))' ; 
end
end



nterms =size (terms ,1 ); 
termdf =ones (nterms ,1 ); 
forkTerm =1 :nterms 
t =terms (kTerm ,:)>0 ; 
termdf (kTerm )=prod (vardf (t )); 
end
totdf =sum (termdf ); 


T =table (); 
forjVar =1 :nvars 
levj =levels {jVar }; 
if~ischar (levj )
levj =levj (:); 
end
column =repmat (levj (1 ,:),totdf ,1 ); 
nextrow =1 ; 
forkTerm =1 :nterms 
dfk =termdf (kTerm ); 
allrows =nextrow -1 +(1 :dfk ); 
tj =terms (kTerm ,:); 
iftj (jVar )>0 
ifcatvars (jVar )














usedvars =tj >0 ; 
termvardf =vardf ; 
termvardf (~usedvars )=1 ; 
repeat1 =prod (termvardf (1 :jVar -1 )); 
repeat2 =prod (termvardf (jVar +1 :end)); 
indices =repmat (2 :(1 +vardf (jVar )),repeat1 ,repeat2 ); 
indices =indices (:); 
column (allrows ,:)=levj (indices ,:); 
else



column (allrows ,:)=levj (tj (jVar )+1 ,:); 
end
end
nextrow =nextrow +dfk ; 
end
T .(model .PredictorNames {jVar })=column ; 
end

end

function [ss ,df ]=getTermSS1 (termcols ,dfbefore ,R ,mse ,b ,V ,Qy ,Rtol )

ifsize (R ,1 )==dfbefore &&mse >0 


b =b (termcols ); 
b =b (:); 
V =V (termcols ,termcols ); 
ss =b ' *(V \b )*mse ; 
df =length (b ); 
else







[q ,r ,~]=qr (R (:,~termcols )); 
ifisvector (r )
dfafter =any (r ); 
else
dfafter =sum (abs (diag (r ))>Rtol ); 
end
ss =norm (Qy ' *q (:,dfafter +1 :end))^2 ; 
df =dfbefore -dfafter ; 
end
end

function [coefs ,coefcov ,R ,Qy ]=applyEffectsCoding (model )


[T ,catvars ,catlevels ,terms ]=getPredictorTable (model ); 


coding =model .DummyVarCoding ; 
X1 =classreg .regr .modelutils .designmatrix (T ,'Model' ,terms ,...
    'DummyVarCoding' ,coding ,...
    'CategoricalVars' ,catvars ,...
    'CategoricalLevels' ,catlevels ); 


X2 =classreg .regr .modelutils .designmatrix (T ,'Model' ,terms ,...
    'DummyVarCoding' ,'effects' ,...
    'CategoricalVars' ,catvars ,...
    'CategoricalLevels' ,catlevels ); 


H =X2 \X1 ; 
coefs =H *model .Coefficients .Estimate ; 
coefcov =H *model .CoefficientCovariance *H ' ; 

ifnargout >2 
R =model .R /H ; 
Qy =model .Qy ; 
end
end

