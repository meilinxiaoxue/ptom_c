classdef (Sealed =true )LinearModel <classreg .regr .CompactLinearModel &classreg .regr .TermsRegression 






























































properties (Constant ,Hidden )
SupportedResidualTypes ={'Raw' ,'Pearson' ,'Standardized' ,'Studentized' }; 
end

properties (GetAccess ='protected' ,SetAccess ='protected' )
Q 
end
properties (Dependent =true ,GetAccess ='public' ,SetAccess ='protected' )


















Residuals 










Fitted 


















































Diagnostics 
end

methods 
function yfit =get .Fitted (model )
yfit =get_fitted (model ); 
end
function r =get .Residuals (model )
r =get_residuals (model ); 
end






function D =get .Diagnostics (model )
D =get_diagnostics (model ); 
end
end
methods (Access ='protected' )
function s2_i =get_S2_i (model )
r =getResponse (model )-predict (model ); 
h =model .Leverage ; 
wt =get_CombinedWeights_r (model ,false ); 
delta_i =wt .*abs (r ).^2 ./(1 -h ); 
ifany (h ==1 )



newdf =repmat (model .DFE -1 ,length (h ),1 ); 
delta_i (h ==1 )=0 ; 
newdf (h ==1 )=newdf (h ==1 )+1 ; 
else
newdf =model .DFE -1 ; 
end
s2_i =max (0 ,model .SSE -delta_i )./newdf ; 
subset =model .ObservationInfo .Subset ; 
s2_i (~subset &~isnan (s2_i ))=0 ; 
end
function dfbetas =get_Dfbetas (model )
rows =model .ObservationInfo .Subset ; 
w_r =get_CombinedWeights_r (model ); 
[~,~,~,R1 ,~,~,~,Q1 ]=lsfit (model .design_r ,model .y_r ,w_r ); 
C =Q1 /R1 ' ; 
e_i =model .Residuals .Studentized (rows ,:); 
h =model .Leverage (rows ,:); 
dfbetas =zeros (length (e_i ),size (C ,2 )); 
dfb =bsxfun (@rdivide ,C ,sqrt (sum (C .^2 ))); 
dfb =bsxfun (@times ,dfb ,sqrt (w_r ).*e_i ./sqrt (1 -h )); 
dfbetas (rows ,:)=dfb ; 
end
function dffits =get_Dffits (model )
e_i =model .Residuals .Studentized ; 
wt =get_CombinedWeights_r (model ,false ); 
h =model .Leverage ; 
dffits =sqrt (h ./(1 -h )).*sqrt (wt ).*e_i ; 
end
function covr =get_CovRatio (model )
n =model .NumObservations ; 
p =model .NumEstimatedCoefficients ; 
wt =get_CombinedWeights_r (model ,false ); 
e_i =model .Residuals .Studentized ; 
h =model .Leverage ; 
covr =1 ./((((n -p -1 +wt .*abs (e_i ).^2 )./(n -p )).^p ).*(1 -h )); 
end
function w =get_CombinedWeights_r (model ,reduce )
w =model .ObservationInfo .Weights ; 
if~isempty (model .Robust )
w =w .*model .Robust .Weights ; 
end
ifnargin <2 ||reduce 
subset =model .ObservationInfo .Subset ; 
w =w (subset ); 
end
end
end

methods (Hidden =true ,Access ='public' )
[fxi ,fxiVar ]=getAdjustedResponse (model ,var ,xi ,terminfo )


end

methods (Hidden =true ,Access ='public' )
function model =LinearModel (varargin )
ifnargin ==0 
model .Formula =classreg .regr .LinearFormula ; 
return 
end
error (message ('stats:LinearModel:NoConstructor' )); 
end



function isVirtual =isVariableEditorVirtualProp (~,prop )




isVirtual =strcmp (prop ,'Diagnostics' ); 
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

methods (Access ='public' )
function disp (model )




isLoose =strcmp (get (0 ,'FormatSpacing' ),'loose' ); 
if(isLoose ),fprintf ('\n' ); end
ifisempty (model .Robust )
fprintf ('%s' ,getString (message ('stats:LinearModel:display_LinearRegressionModel' ))); 
else
fprintf ('%s' ,getString (message ('stats:LinearModel:display_LinearRegressionModelrobustFit' ))); 
end

dispBody (model )
end

function [varargout ]=predict (model ,varargin )








































[varargin {:}]=convertStringsToChars (varargin {:}); 
ifnargin >1 &&~internal .stats .isString (varargin {1 })
Xpred =varargin {1 }; 
varargin =varargin (2 :end); 
ifisa (Xpred ,'tall' )
[varargout {1 :max (1 ,nargout )}]=hSlicefun (@model .predict ,Xpred ,varargin {:}); 
return 
end
design =designMatrix (model ,Xpred ); 
else
design =model .Design ; 
end
[varargout {1 :max (1 ,nargout )}]=predictDesign (model ,design ,varargin {:}); 
end


function model =step (model ,varargin )























































compactNotAllowed (model ,'step' ,false ); 
[varargin {:}]=convertStringsToChars (varargin {:}); 
if~isempty (model .Robust )
error (message ('stats:LinearModel:NoRobustStepwise' )); 
end
model =step @classreg .regr .TermsRegression (model ,varargin {:}); 
checkDesignRank (model ); 
end

function lm =compact (this )













ifisempty (this .TermMeans )
lm =getTermMeans (this ); 
else
lm =this ; 
end

lm =classreg .regr .CompactLinearModel .make (lm ); 
end

function [p ,stat ]=dwtest (model ,option ,tail )









































compactNotAllowed (model ,'dwtest' ,false ); 
ifnargin <2 
ifmodel .NumObservations <400 
option ='exact' ; 
else
option ='approximate' ; 
end; 
end; 
ifnargin <3 
tail ='both' ; 
end; 

option =convertStringsToChars (option ); 
tail =convertStringsToChars (tail ); 

subset =model .ObservationInfo .Subset ; 
r =model .Residuals .Raw (subset ); 
stat =sum (diff (r ).^2 )/sum (r .^2 ); 




pdw =dfswitchyard ('pvaluedw' ,stat ,model .design_r ,option ); 


switchlower (tail )
case 'both' 
p =2 *min (pdw ,1 -pdw ); 
case 'left' 
p =1 -pdw ; 
case 'right' 
p =pdw ; 
end
end
end
methods (Access ='public' )
function hout =plot (lm ,varargin )
























compactNotAllowed (lm ,'plot' ,false ); 
p =length (lm .PredictorNames ); 
internal .stats .plotargchk (varargin {:}); 

ifp ==0 

h =plotResiduals (lm ,'histogram' ); 
elseifp ==1 

h =plotxy (lm ,varargin {:}); 
else
h =plotAdded (lm ,[],varargin {:}); 
end

ifnargout >0 
hout =h ; 
end

end
function hout =plotAdded (model ,cnum ,varargin )







































compactNotAllowed (model ,'plotAdded' ,false ); 
[varargin {:}]=convertStringsToChars (varargin {:}); 
internal .stats .plotargchk (varargin {:}); 

sub =model .ObservationInfo .Subset ; 
stats .source ='stepwisefit' ; 
stats .B =model .Coefs ; 
stats .SE =model .CoefSE ; 
stats .dfe =model .DFE ; 
stats .covb =model .CoefficientCovariance ; 

stats .yr =model .Residuals .Raw (sub ); 
stats .wasnan =~sub ; 
stats .wts =get_CombinedWeights_r (model ); 
stats .mse =model .MSE ; 
[~,p ]=size (model .Design ); 


terminfo =getTermInfo (model ); 
constrow =find (all (terminfo .terms ==0 ,2 ),1 ); 
ifisempty (constrow )
constrow =NaN ; 
end
ncoefs =length (model .Coefs ); 
ifnargin <2 ||isempty (cnum )

cnum =find (terminfo .designTerms ~=constrow ); 
end
cnum =convertStringsToChars (cnum ); 

ifisrow (cnum )&&ischar (cnum )
termnum =find (strcmp (model .Formula .TermNames ,cnum )); 
ifisscalar (termnum )
cnum =find (terminfo .designTerms ==termnum ); 
else
cnum =find (strcmp (model .CoefficientNames ,cnum )); 
if~isscalar (cnum )
error (message ('stats:LinearModel:BadCoefficientName' )); 
end
end
elseifisempty (cnum )||~isvector (cnum )||~all (ismember (cnum ,1 :ncoefs ))
error (message ('stats:LinearModel:BadCoefficientNumber' )); 
end
cnum =sort (cnum ); 
if~isscalar (cnum )&&any (diff (cnum )==0 )
error (message ('stats:LinearModel:RepeatedCoeffients' )); 
end


y =getResponse (model ); 
h =addedvarplot (model .Design (sub ,:),y (sub ),cnum ,true (1 ,p ),stats ,[],false ,varargin {:}); 


ax =ancestor (h (1 ),'axes' ); 
ylabel (ax ,sprintf ('%s' ,getString (message ('stats:LinearModel:sprintf_Adjusted' ,model .ResponseName ))),'Interpreter' ,'none' ); 
tcols =terminfo .designTerms (cnum ); 
ifisscalar (cnum )
thetitle =sprintf ('%s' ,getString (message ('stats:LinearModel:title_AddedVariablePlotFor' ,model .CoefficientNames {cnum }))); 
thexlabel =sprintf ('%s' ,getString (message ('stats:LinearModel:sprintf_Adjusted' ,model .CoefficientNames {cnum }))); 
elseif~any (tcols ==constrow )&&length (cnum )==ncoefs -1 
thetitle =getString (message ('stats:LinearModel:title_AddedVariablePlotModel' )); 
thexlabel =getString (message ('stats:LinearModel:xylabel_AdjustedWholeModel' )); 
elseifall (tcols ==tcols (1 ))&&length (tcols )==sum (terminfo .designTerms ==tcols (1 ))

thetitle =sprintf ('%s' ,getString (message ('stats:LinearModel:title_AddedVariablePlotFor' ,model .Formula .TermNames {tcols (1 )}))); 
thexlabel =sprintf ('%s' ,getString (message ('stats:LinearModel:sprintf_Adjusted' ,model .Formula .TermNames {tcols (1 )}))); 
else
thetitle =getString (message ('stats:LinearModel:title_AddedVariablePlotTerms' )); 
thexlabel =getString (message ('stats:LinearModel:xylabel_AdjustedSpecifiedTerms' )); 
end
title (ax ,thetitle ,'Interpreter' ,'none' ); 
xlabel (ax ,thexlabel ,'Interpreter' ,'none' ); 


ObsNames =model .ObservationNames ; 
internal .stats .addLabeledDataTip (ObsNames ,h (1 ),h (2 :end)); 

ifnargout >0 
hout =h ; 
end
end

function hout =plotDiagnostics (model ,varargin )







































compactNotAllowed (model ,'plotDiagnostics' ,false ); 
[varargin {:}]=convertStringsToChars (varargin {:}); 
f =classreg .regr .modelutils .plotDiagnostics (model ,varargin {:}); 
ifnargout >0 
hout =f ; 
end
end

function hout =plotResiduals (model ,plottype ,varargin )















































compactNotAllowed (model ,'plotResiduals' ,false ); 
ifnargin <2 
plottype ='histogram' ; 
end
plottype =convertStringsToChars (plottype ); 
[varargin {:}]=convertStringsToChars (varargin {:}); 
[residtype ,~,args ]=internal .stats .parseArgs ({'residualtype' },{'Raw' },varargin {:}); 
varargin =args ; 
residtype =internal .stats .getParamVal (residtype ,...
    LinearModel .SupportedResidualTypes ,'''ResidualType''' ); 
internal .stats .plotargchk (varargin {:}); 

f =classreg .regr .modelutils .plotResiduals (model ,plottype ,'ResidualType' ,residtype ,varargin {:}); 
ifnargout >0 
hout =f ; 
end
end
function hout =plotAdjustedResponse (model ,var ,varargin )





























narginchk (2 ,Inf ); 
compactNotAllowed (model ,'plotAdjustedResponse' ,false ); 
var =convertStringsToChars (var ); 
[varargin {:}]=convertStringsToChars (varargin {:}); 
internal .stats .plotargchk (varargin {:}); 


terminfo =getTermInfo (model ); 
[xdata ,vname ,vnum ]=getVar (model ,var ); 

if~model .Formula .InModel (vnum )
ifstrcmp (vname ,model .Formula .ResponseName )
error (message ('stats:LinearModel:ResponseNotAllowed' ,vname )); 
else
error (message ('stats:LinearModel:NotPredictor' ,vname )); 
end

elseifterminfo .isCatVar (vnum )

[xdata ,xlabels ]=grp2idx (xdata ); 
nlevels =length (xlabels ); 
xi =(1 :nlevels )' ; 
else

xi =linspace (min (xdata ),max (xdata ))' ; 
nlevels =length (xi ); 
xi =[xi ; xdata ]; 
end



fxi =getAdjustedResponse (model ,vnum ,xi ,terminfo ); 


ifterminfo .isCatVar (vnum )
d =double (xdata ); 
fx (~isnan (d ))=fxi (d (~isnan (d ))); 
fx (isnan (d ))=NaN ; 
fx =fx (:); 
else
fx =fxi (nlevels +1 :end); 
xi =xi (1 :nlevels ); 
fxi =fxi (1 :nlevels ); 
end


resid =model .Residuals .Raw ; 
h =plot (xdata ,fx +resid ,'ro' ,varargin {:}); 
ax =ancestor (h ,'axes' ); 
washold =ishold (ax ); 
if~washold 
hold (ax ,'on' ); 
end
h =[h ; plot (ax ,xi ,fxi ,'b-' )]; 
if~washold 
hold (ax ,'off' ); 
end
set (h (1 ),'Tag' ,'data' ); 
set (h (2 ),'Tag' ,'fit' ); 
legend (ax ,'Adjusted data' ,'Adjusted fit' ,'location' ,'best' ); 
xlabel (ax ,vname ); 
ylabel (ax ,sprintf ('%s' ,getString (message ('stats:LinearModel:sprintf_Adjusted' ,model .ResponseName )))); 
title (ax ,getString (message ('stats:LinearModel:title_AdjustedResponsePlot' )))

ifterminfo .isCatVar (vnum )
set (ax ,'XTick' ,xi ,'XTickLabel' ,xlabels ,'XLim' ,[.5 ,max (xi )+.5 ]); 
end


ObsNames =model .ObservationNames ; 
internal .stats .addLabeledDataTip (ObsNames ,h (1 ),[]); 

ifnargout >0 
hout =h ; 
end
end
end
methods (Access ='protected' )
function L0 =logLikelihoodNull (model )
mu0 =sum (model .w_r .*model .y_r )/sum (model .w_r ); 
sigma0 =std (model .y_r ,model .w_r ); 
L0 =sum (model .w_r .*normlogpdf (model .y_r ,mu0 ,sigma0 )); 
end
function h =plotxy (lm ,varargin )


col =lm .PredLocs ; 
xname =lm .PredictorNames {1 }; 


xdata =getVar (lm ,col ); 
y =getResponse (lm ); 
ObsNames =lm .ObservationNames ; 

iscat =lm .VariableInfo .IsCategorical (col ); 

ifiscat 

[x ,xlabels ,levels ]=grp2idx (xdata ); 
tickloc =(1 :length (xlabels ))' ; 
ticklab =xlabels ; 
xx =tickloc ; 
else
x =xdata ; 
xx =linspace (min (x ),max (x ))' ; 
levels =xx ; 
end
nlevels =size (levels ,1 ); 



t =isnan (x )|isnan (y ); 
ifany (t )
x (t )=NaN ; 
y (t )=NaN ; 
end


ifisa (lm .Variables ,'dataset' )||isa (lm .Variables ,'table' )

X =lm .Variables (ones (nlevels ,1 ),:); 
X .(xname )=levels (:); 
else

npreds =lm .NumVariables -1 ; 
X =zeros (length (xx ),npreds ); 
X (:,col )=xx ; 
end
[yfit ,yci ]=lm .predict (X ); 
h =plot (x ,y ,'bx' ,varargin {:}); 
ax =ancestor (h ,'axes' ); 
washold =ishold (ax ); 
hold (ax ,'on' )
h =[h ; plot (ax ,xx ,yfit ,'r-' ,xx ,yci ,'r:' )]; 
if~washold 
hold (ax ,'off' )
end

ifiscat 
set (ax ,'XTick' ,tickloc ' ,'XTickLabel' ,ticklab ); 
set (ax ,'XLim' ,[tickloc (1 )-0.5 ,tickloc (end)+0.5 ]); 
end

yname =lm .ResponseName ; 
title (ax ,sprintf ('%s' ,getString (message ('stats:LinearModel:sprintf_AvsB' ,yname ,xname ))),'Interpreter' ,'none' ); 
set (xlabel (ax ,xname ),'Interpreter' ,'none' ); 
set (ylabel (ax ,yname ),'Interpreter' ,'none' ); 
legend (ax ,h (1 :3 ),getString (message ('stats:LinearModel:legend_Data' )),...
    getString (message ('stats:LinearModel:legend_Fit' )),...
    getString (message ('stats:LinearModel:legend_ConfidenceBounds' )),...
    'location' ,'best' )


internal .stats .addLabeledDataTip (ObsNames ,h (1 ),h (2 :end)); 
end
function model =fitter (model )
X =getData (model ); 
[model .Design ,model .CoefTerm ,model .CoefficientNames ]=designMatrix (model ,X ); 


dr =create_design_r (model ); 
model .WorkingValues .design_r =dr ; 
model .DesignMeans =mean (dr ,1 ); 

ifisempty (model .Robust )
[model .Coefs ,model .MSE ,model .CoefficientCovariance ,model .R ,model .Qy ,model .DFE ,model .Rtol ,Q1 ]...
    =lsfit (model .design_r ,model .y_r ,model .w_r ); 
h =zeros (size (model .ObservationInfo ,1 ),1 ); 
h (model .ObservationInfo .Subset )=sum (abs (Q1 ).^2 ,2 ); 
model .Leverage =h ; 
else
[model .Coefs ,stats ]...
    =robustfit (model .design_r ,model .y_r ,model .Robust .RobustWgtFun ,model .Robust .Tune ,'off' ,model .w_r ,false ); 
model .CoefficientCovariance =stats .covb ; 
model .DFE =stats .dfe ; 
model .MSE =stats .s ^2 ; 
model .Rtol =stats .Rtol ; 

w =NaN (size (model .ObservationInfo ,1 ),1 ); 
w (model .ObservationInfo .Subset )=stats .w ; 
model .Robust .Weights =w ; 

model .R =stats .R ; 
model .Qy =stats .Qy ; 






end
end
function model =postFit (model )

model =postFit @classreg .regr .TermsRegression (model ); 


model .SSE =model .DFE *model .MSE ; 
model .SST =model .SSR +model .SSE ; 



model =getTermMeans (model ); 
end



function D =get_diagnostics (model ,type )
compactNotAllowed (model ,'Diagnostics' ,true ); 
ifnargin <2 
HatMatrix =get_diagnostics (model ,'hatmatrix' ); 
CooksDistance =get_diagnostics (model ,'cooksdistance' ); 
Dffits =get_diagnostics (model ,'dffits' ); 
S2_i =get_diagnostics (model ,'s2_i' ); 
Dfbetas =get_diagnostics (model ,'dfbetas' ); 
CovRatio =get_diagnostics (model ,'covratio' ); 
Leverage =model .Leverage ; 
D =table (Leverage ,CooksDistance ,...
    Dffits ,S2_i ,CovRatio ,Dfbetas ,HatMatrix ,...
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
case 'dffits' 
D =get_Dffits (model ); 
D (~subset ,:)=NaN ; 
case 's2_i' 
D =get_S2_i (model ); 
D (~subset ,:)=NaN ; 
case 'dfbetas' 
D =get_Dfbetas (model ); 
D (~subset ,:)=0 ; 
case 'covratio' 
D =get_CovRatio (model ); 
D (~subset ,:)=NaN ; 
otherwise
error (message ('stats:LinearModel:UnrecognizedDiagnostic' ,type )); 
end
end
end
function r =get_residuals (model ,type )
compactNotAllowed (model ,'Residuals' ,true ); 
ifnargin <2 
Raw =get_residuals (model ,'raw' ); 
Pearson =get_residuals (model ,'pearson' ); 
Studentized =get_residuals (model ,'studentized' ); 
Standardized =get_residuals (model ,'standardized' ); 
r =table (Raw ,Pearson ,Studentized ,Standardized ,...
    'RowNames' ,model .ObservationNames ); 
else
subset =model .ObservationInfo .Subset ; 
raw =getResponse (model )-predict (model ); 
switchlower (type )
case 'raw' 
r =raw ; 
case 'pearson' 
r =raw ./model .RMSE ; 
case 'studentized' 
h =model .Leverage ; 
s2_i =get_S2_i (model ); 
r =raw ./sqrt (s2_i .*(1 -h )); 
case 'standardized' 
h =model .Leverage ; 
r =raw ./(sqrt (model .MSE *(1 -h ))); 
otherwise
error (message ('stats:LinearModel:UnrecognizedResidual' ,type )); 
end
r (~subset )=NaN ; 
end
end
function [ok ,meanx ]=gettermmean (model ,v ,vnum ,terminfo )




[ok ,meanx ]=gettermmean @classreg .regr .CompactLinearModel (model ,v ,vnum ,terminfo ); 

if~ok 


v (vnum )=0 ; 


X =model .Data ; 
ifisstruct (X )
X =X .X ; 
v (end)=[]; 
end
design =classreg .regr .modelutils .designmatrix (X ,'Model' ,v ,'VarNames' ,model .Formula .VariableNames ); 
meanx =mean (design ,1 ); 
end
end

function [isrep ,sspe ,dfpe ]=getReplicateInfo (model )

sspe =0 ; 
dfpe =0 ; 
if~hasData (model )
isrep =false ; 
else
subset =model .ObservationInfo .Subset ; 
[sx ,ix ]=sortrows (model .Design (subset ,:)); 
isrep =[all (diff (sx )==0 ,2 ); false ]; 
sx =[]; %#ok<NASGU> % no longer needed, save space 
end
ifany (isrep )
first =1 ; 
n =length (isrep ); 
r =model .Residuals .Raw (subset ); 
w =model .ObservationInfo .Weights (subset ); 
while(first <n )

if~isrep (first )
first =first +1 ; 
continue ; 
end
fork =first +1 :n 
if~isrep (k )
last =k ; 
break
end
end


t =ix (first :last ); 
r1 =r (t ); 
w1 =w (t ); 
m =sum (w1 .*r1 )/sum (w1 ); 
sspe =sspe +sum (w1 .*(r1 -m ).^2 ); 
dfpe =dfpe +(last -first ); 


first =last +1 ; 
end
ifdfpe ==model .DFE 

isrep =false ; 
end
end
end
end

methods (Static ,Access ='public' ,Hidden )
function model =fit (X ,varargin )



[varargin {:}]=convertStringsToChars (varargin {:}); 
[X ,y ,haveDataset ,otherArgs ]=LinearModel .handleDataArgs (X ,varargin {:}); 













paramNames ={'Intercept' ,'PredictorVars' ,'ResponseVar' ...
    ,'Weights' ,'Exclude' ,'CategoricalVars' ,'VarNames' ...
    ,'RobustOpts' ,'DummyVarCoding' ,'rankwarn' }; 
paramDflts ={[],[],[],[],[],[],[],[],'reference' ,true }; 


ifisempty (otherArgs )
modelDef ='linear' ; 
else
arg1 =otherArgs {1 }; 
ifmod (length (otherArgs ),2 )==1 
modelDef =arg1 ; 
otherArgs (1 )=[]; 
elseifinternal .stats .isString (arg1 )&&...
    any (strncmpi (arg1 ,paramNames ,length (arg1 )))

modelDef ='linear' ; 
end
end

[intercept ,predictorVars ,responseVar ,weights ,exclude ,...
    asCatVar ,varNames ,robustOpts ,dummyCoding ,rankwarn ,supplied ]=...
    internal .stats .parseArgs (paramNames ,paramDflts ,otherArgs {:}); 

model =LinearModel (); 

model .Robust =classreg .regr .FitObject .checkRobust (robustOpts ); 
model .Formula =LinearModel .createFormula (supplied ,modelDef ,X ,...
    predictorVars ,responseVar ,intercept ,varNames ,haveDataset ); 
model =assignData (model ,X ,y ,weights ,asCatVar ,dummyCoding ,model .Formula .VariableNames ,exclude ); 

silent =classreg .regr .LinearFormula .isModelAlias (modelDef ); 
model =removeCategoricalPowers (model ,silent ); 

model =doFit (model ); 

model =updateVarRange (model ); 

ifrankwarn 
checkDesignRank (model ); 
end
end
function model =stepwise (X ,varargin )




[varargin {:}]=convertStringsToChars (varargin {:}); 
[X ,y ,haveDataset ,otherArgs ]=LinearModel .handleDataArgs (X ,varargin {:}); 


paramNames ={'Intercept' ,'PredictorVars' ,'ResponseVar' ,'Weights' ,'Exclude' ,'CategoricalVars' ...
    ,'VarNames' ,'Lower' ,'Upper' ,'Criterion' ,'PEnter' ,'PRemove' ,'NSteps' ,'Verbose' }; 
paramDflts ={true ,[],[],[],[],[],[],'constant' ,'interactions' ,'SSE' ,[],[],Inf ,1 }; 


ifisempty (otherArgs )
start ='constant' ; 
else
arg1 =otherArgs {1 }; 
ifmod (length (otherArgs ),2 )==1 
start =arg1 ; 
otherArgs (1 )=[]; 
elseifinternal .stats .isString (arg1 )&&...
    any (strncmpi (arg1 ,paramNames ,length (arg1 )))

start ='constant' ; 
end
end

[intercept ,predictorVars ,responseVar ,weights ,exclude ,asCatVar ,...
    varNames ,lower ,upper ,crit ,penter ,premove ,nsteps ,verbose ,supplied ]=...
    internal .stats .parseArgs (paramNames ,paramDflts ,otherArgs {:}); 

[penter ,premove ]=classreg .regr .TermsRegression .getDefaultThresholds (crit ,penter ,premove ); 

if~isscalar (verbose )||~ismember (verbose ,0 :2 )
error (message ('stats:LinearModel:BadVerbose' )); 
end




if~supplied .ResponseVar &&(classreg .regr .LinearFormula .isTermsMatrix (start )||classreg .regr .LinearFormula .isModelAlias (start ))
ifisa (lower ,'classreg.regr.LinearFormula' )
responseVar =lower .ResponseName ; 
supplied .ResponseVar =true ; 
else
ifinternal .stats .isString (lower )&&~classreg .regr .LinearFormula .isModelAlias (lower )
lower =LinearModel .createFormula (supplied ,lower ,X ,...
    predictorVars ,responseVar ,intercept ,varNames ,haveDataset ); 
responseVar =lower .ResponseName ; 
supplied .ResponseVar =true ; 
elseifisa (upper ,'classreg.regr.LinearFormula' )
responseVar =upper .ResponseName ; 
supplied .ResponseVar =true ; 
else
ifinternal .stats .isString (upper )&&~classreg .regr .LinearFormula .isModelAlias (upper )
upper =LinearModel .createFormula (supplied ,upper ,X ,...
    predictorVars ,responseVar ,intercept ,varNames ,haveDataset ); 
responseVar =upper .ResponseName ; 
supplied .ResponseVar =true ; 
end
end
end
end

if~isa (start ,'classreg.regr.LinearFormula' )
ismodelalias =classreg .regr .LinearFormula .isModelAlias (start ); 
start =LinearModel .createFormula (supplied ,start ,X ,...
    predictorVars ,responseVar ,intercept ,varNames ,haveDataset ); 
else
ismodelalias =false ; 
end

if~isa (lower ,'classreg.regr.LinearFormula' )
ifclassreg .regr .LinearFormula .isModelAlias (lower )
ifsupplied .PredictorVars 
lower ={lower ,predictorVars }; 
end
end
lower =classreg .regr .LinearFormula (lower ,start .VariableNames ,start .ResponseName ,start .HasIntercept ,start .Link ); 
end
if~isa (upper ,'classreg.regr.LinearFormula' )
ifclassreg .regr .LinearFormula .isModelAlias (upper )
ifsupplied .PredictorVars 
upper ={upper ,predictorVars }; 
end
end
upper =classreg .regr .LinearFormula (upper ,start .VariableNames ,start .ResponseName ,start .HasIntercept ,start .Link ); 
end

ifisa (X ,'table' )
isNumVar =varfun (@isnumeric ,X ,'OutputFormat' ,'uniform' ); 
isNumVec =isNumVar &varfun (@isvector ,X ,'OutputFormat' ,'uniform' ); 
isCatVec =varfun (@internal .stats .isDiscreteVec ,X ,'OutputFormat' ,'uniform' ); 
isValidVar =isNumVec |isCatVec ; 
ifany (~isValidVar )
[start ,isRs ]=removeBadVars (start ,isValidVar ); 
[lower ,isRl ]=removeBadVars (lower ,isValidVar ); 
[upper ,isRu ]=removeBadVars (upper ,isValidVar ); 
ifisRs ||isRl ||isRu 
warning (message ('stats:classreg:regr:modelutils:BadVariableType' )); 
end
end
end



nvars =size (X ,2 ); 
ifhaveDataset 
isCat =varfun (@internal .stats .isDiscreteVar ,X ,'OutputFormat' ,'uniform' ); 
else
isCat =[repmat (internal .stats .isDiscreteVar (X ),1 ,nvars ),internal .stats .isDiscreteVar (y )]; 
nvars =nvars +1 ; 
end
if~isempty (asCatVar )
isCat =classreg .regr .FitObject .checkAsCat (isCat ,asCatVar ,nvars ,haveDataset ,start .VariableNames ); 
end
ifany (isCat )
start =removeCategoricalPowers (start ,isCat ,ismodelalias ); 
lower =removeCategoricalPowers (lower ,isCat ,ismodelalias ); 
upper =removeCategoricalPowers (upper ,isCat ,ismodelalias ); 
end

ifhaveDataset 
model =LinearModel .fit (X ,start .Terms ,'ResponseVar' ,start .ResponseName ,...
    'Weights' ,weights ,'Exclude' ,exclude ,'CategoricalVars' ,asCatVar ,'RankWarn' ,false ); 
else
model =LinearModel .fit (X ,y ,start .Terms ,'ResponseVar' ,start .ResponseName ,...
    'Weights' ,weights ,'Exclude' ,exclude ,'CategoricalVars' ,asCatVar ,...
    'VarNames' ,start .VariableNames ,'RankWarn' ,false ); 
end

model .Steps .Start =start ; 
model .Steps .Lower =lower ; 
model .Steps .Upper =upper ; 
model .Steps .Criterion =crit ; 
model .Steps .PEnter =penter ; 
model .Steps .PRemove =premove ; 
model .Steps .History =[]; 

model =stepwiseFitter (model ,nsteps ,verbose ); 
checkDesignRank (model ); 
end

end

methods (Static ,Hidden )
function formula =createFormula (supplied ,modelDef ,X ,predictorVars ,responseVar ,intercept ,varNames ,haveDataset )
supplied .Link =false ; 
formula =classreg .regr .TermsRegression .createFormula (supplied ,modelDef ,...
    X ,predictorVars ,responseVar ,intercept ,'identity' ,varNames ,haveDataset ); 
end
end
end


function logy =normlogpdf (x ,mu ,sigma )
logy =(-0.5 *((x -mu )./sigma ).^2 )-log (sqrt (2 *pi ).*sigma ); 
end




function [b ,mse ,S ,R1 ,Qy1 ,dfe ,Rtol ,Q1 ]=lsfit (X ,y ,w )


[nobs ,nvar ]=size (X ); 


ifnargin <3 ||isempty (w )
w =[]; 


elseifisvector (w )&&numel (w )==nobs &&all (w >=0 )
D =sqrt (w (:)); 
X =bsxfun (@times ,D ,X ); 
y =bsxfun (@times ,D ,y ); 


else
error (message ('stats:LinearModel:InvalidWeights' ,nobs )); 
end

outClass =superiorfloat (X ,y ,w ); 


[Q ,R ,perm ]=qr (X ,0 ); 
Qy =Q ' *y ; 


ifisempty (R )
Rtol =1 ; 
keepCols =zeros (1 ,0 ); 
else
Rtol =abs (R (1 )).*max (nobs ,nvar ).*eps (class (R )); 
ifisrow (R )
keepCols =1 ; 
else
keepCols =find (abs (diag (R ))>Rtol ); 
end
end

rankX =length (keepCols ); 
R0 =R ; 
perm0 =perm ; 
ifrankX <nvar 
R =R (keepCols ,keepCols ); 
Qy =Qy (keepCols ,:); 
perm =perm (keepCols ); 
end



b =zeros (nvar ,1 ,outClass ); 
b (perm ,1 )=R \Qy ; 

ifnargout >1 

dfe =nobs -rankX ; 
ifdfe >0 
sst =sum (y .*conj (y ),1 ); 
ssx =sum (Qy .*conj (Qy ),1 ); 
mse =max (0 ,sst -ssx )./dfe ; 
else
mse =zeros (1 ,1 ,outClass ); 
end



Rinv =R \eye (rankX ,outClass ); 
ifnargout >2 
S =zeros (nvar ,nvar ,outClass ); 
S (perm ,perm )=Rinv *Rinv ' .*mse ; 
end


ifnargout >3 
Qy1 =zeros (nvar ,1 ); 
Qy1 (perm ,1 )=Qy ; 
R1 =zeros (nvar ,nvar ,outClass ); 
R1 (perm ,perm0 )=R0 (keepCols ,:); 
Q1 =zeros (size (X ),outClass ); 
Q1 (:,perm )=Q (:,keepCols ); 
end
end
end
