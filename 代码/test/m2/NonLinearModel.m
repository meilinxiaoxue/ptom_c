classdef (Sealed =true )NonLinearModel <classreg .regr .ParametricRegression 



















































properties (Constant ,Hidden )
SupportedResidualTypes ={'Raw' ,'Pearson' ,'Standardized' ,'Studentized' }; 
end

properties (GetAccess ='public' ,SetAccess ='protected' )





MSE =0 ; 








Iterative =[]; 












Robust =[]; 
end
properties (GetAccess ='protected' ,SetAccess ='protected' )
HaveGrad =false ; 
Leverage =[]; 
Design =[]; 
end
properties (Dependent ,GetAccess ='public' ,SetAccess ='protected' )


















Residuals 










Fitted 






RMSE 
































Diagnostics 
end

properties (Dependent ,GetAccess ='public' ,SetAccess ='protected' ,Hidden =false )




















WeightedResiduals 
end

properties (Dependent ,GetAccess ='protected' ,SetAccess ='protected' )


J_r =[]; 
end
properties (Access ='protected' ,Hidden =true )










ErrorModelInfo =struct ('ErrorModel' ,[],'ErrorParameters' ,[],'ErrorVariance' ,[],'MSE' ,[],...
    'ScheffeSimPred' ,[],'WeightFunction' ,[],'FixedWeights' ,[],'RobustWeightFunction' ,[]); 



getEstimableContrasts =[]; 



RankJW =[]; 


WeightFunctionHandle =[]; 



SST0 =NaN ; 



FTestFval =NaN ; 
FTestPval =NaN ; 
EmptyNullModel =NaN ; 
HasIntercept =NaN ; 


VersionNumber =2.0 ; 
end

properties (Constant =true ,Hidden =true )

NAME_CONSTANT ='constant' ; 
NAME_PROPORTIONAL ='proportional' ; 
NAME_COMBINED ='combined' ; 
SupportedErrorModels ={NonLinearModel .NAME_CONSTANT ,NonLinearModel .NAME_PROPORTIONAL ,NonLinearModel .NAME_COMBINED }; 
end

methods 

function yfit =get .Fitted (model )
yfit =get_fitted (model ); 
end
function r =get .Residuals (model )
r =get_residuals (model ); 
end
function r =get .WeightedResiduals (model )
r =get_weighted_residuals (model ); 
end
function s =get .RMSE (model )
s =sqrt (model .MSE ); 
end
function J_r =get .J_r (model )
ifisempty (model .WorkingValues )
J_r =create_J_r (model ); 
else
J_r =model .WorkingValues .J_r ; 
end
end









end

methods (Hidden =true ,Access ='public' )
function model =NonLinearModel (varargin )
ifnargin ==0 
model .Formula =classreg .regr .NonLinearFormula ; 
return 
end
error (message ('stats:NonLinearModel:NoConstructor' )); 
end
end

methods (Access ='public' )
function disp (model )




isLoose =strcmp (get (0 ,'FormatSpacing' ),'loose' ); 
if(isLoose ),fprintf ('\n' ); end
ifisempty (model .Robust )
fprintf (getString (message ('stats:NonLinearModel:display_Nonlin' ))); 
else
fprintf (getString (message ('stats:NonLinearModel:display_NonlinRobust' ))); 
end


indent ='    ' ; 
maxWidth =matlab .desktop .commandwindow .size ; maxWidth =maxWidth (1 )-1 ; 
f =model .Formula ; 
fstr =char (f ,maxWidth -length (indent )); 
disp ([indent ,fstr ]); 

ifmodel .IsFitFromData 
fprintf (getString (message ('stats:NonLinearModel:display_EstimatedCoefficients' ))); 
disp (model .Coefficients ); 
fprintf ('%s' ,getString (message ('stats:NonLinearModel:display_NumObsDFE' ,model .NumObservations ,model .DFE ))); 
fprintf ('%s' ,getString (message ('stats:NonLinearModel:display_RMSE' ,num2str (model .RMSE ,'%.3g' )))); 
rsq =get_rsquared (model ,{'ordinary' ,'adjusted' }); 
fprintf ('%s' ,getString (message ('stats:NonLinearModel:display_RSquared' ,num2str (rsq (1 ),'%.3g' ),num2str (rsq (2 ),'%.3g' )))); 
[f ,p ,emptyNullModel ]=fTest (model ); 
ifemptyNullModel 
fprintf ('%s' ,getString (message ('stats:NonLinearModel:display_FtestZero' ,num2str (f ,'%.3g' ),num2str (p ,'%.3g' )))); 
else
fprintf ('%s' ,getString (message ('stats:NonLinearModel:display_Ftest' ,num2str (f ,'%.3g' ),num2str (p ,'%.3g' )))); 
end
else
fprintf (getString (message ('stats:NonLinearModel:display_Coefficients' ))); 
ifany (model .Coefficients .SE >0 )
disp (model .Coefficients (:,{'Value' ,'SE' })); 
else
disp (model .Coefficients (:,{'Value' })); 
end
ifmodel .MSE >0 
fprintf ('\n%s' ,getString (message ('stats:NonLinearModel:display_RMSE' ,num2str (model .RMSE ,'%.3g' )))); 
end
end
end


function [ypred ,yCI ]=predict (model ,varargin )














































ifnargin >1 &&~internal .stats .isString (varargin {1 })
Xpred =varargin {1 }; 
varargin =varargin (2 :end); 
design =predictorMatrix (model ,Xpred ); 
else
design =model .Design ; 
end
[varargin {:}]=convertStringsToChars (varargin {:}); 
paramNames ={'Confidence' ,'Simultaneous' ,'Prediction' ,'Alpha' ,'Weights' }; 
paramDflts ={.95 ,false ,'curve' ,.05 ,[]}; 
[conf ,simOpt ,predOpt ,alpha ,weights ,supplied ]=...
    internal .stats .parseArgs (paramNames ,paramDflts ,varargin {:}); 

ifsupplied .Confidence &&supplied .Alpha 
error (message ('stats:NonLinearModel:ArgCombination' ))
end
ifsupplied .Alpha 
conf =1 -alpha ; 
end
if~islogical (predOpt )
predOpt =internal .stats .getParamVal (predOpt ,{'curve' ,'observation' },'''Prediction''' ); 
predOpt =isequal (predOpt ,'observation' ); 
end
ifnargout <2 
ypred =model .Formula .ModelFun (model .Coefs ,design ); 
else


ifmodel .HaveGrad 
[ypred ,Jpred ]=model .Formula .ModelFun (model .Coefs ,design ); 
else
ypred =model .Formula .ModelFun (model .Coefs ,design ); 
Jpred =jacobian (model ,design ); 
end


estimable =model .getEstimableContrasts (Jpred ); 


if~isempty (weights )
weights =NonLinearModel .checkWeights (weights ,ypred ); 
end


ypredVar =sum ((Jpred *model .CoefficientCovariance ).*Jpred ,2 ); 

usingErrorModel =false ; 
if(predOpt )
if~isempty (weights )
ifisa (weights ,'function_handle' )
wVec =weights (ypred ); 
else
wVec =weights ; 
end

wVec =wVec (:); 
errorVar =model .MSE ./wVec ; 
elseif~isempty (model .ErrorModelInfo )&&~isempty (model .ErrorModelInfo .ScheffeSimPred )&&~isempty (model .ErrorModelInfo .ErrorVariance )

errorVar =model .ErrorModelInfo .ErrorVariance (design ); 
errorVar =errorVar (:); 
usingErrorModel =true ; 
else


errorVar =model .MSE *ones (size (Jpred ,1 ),1 ); 
end
ypredVar =ypredVar +errorVar ; 
end


if(simOpt )

if(predOpt )

ifusingErrorModel 

sch =model .ErrorModelInfo .ScheffeSimPred ; 

if(sch ~=model .RankJW &&sch ~=(model .RankJW +1 ))

sch =(model .RankJW +1 ); 
end

sch =NonLinearModel .validateScheffeParamUsingJacobianPred (sch ,model .RankJW ,Jpred ,estimable ,errorVar ); 
else

sch =(model .RankJW +1 ); 
end
else

sch =model .RankJW ; 
end
crit =sqrt (sch *finv (conf ,sch ,model .DFE )); 
else

crit =tinv ((1 +conf )/2 ,model .DFE ); 
end
delta =sqrt (ypredVar )*crit ; 


yCI =[ypred -delta ,ypred +delta ]; 

yCI (~estimable ,:)=NaN ; 
end
end


function ysim =random (model ,varargin )









































ifnargin >1 &&~internal .stats .isString (varargin {1 })
Xpred =varargin {1 }; 
varargin =varargin (2 :end); 
design =predictorMatrix (model ,Xpred ); 
else
design =model .Design ; 
end
[varargin {:}]=convertStringsToChars (varargin {:}); 
paramNames ={'Weights' }; 
paramDflts ={[]}; 
[weights ,~]=internal .stats .parseArgs (paramNames ,paramDflts ,varargin {:}); 


ypred =model .Formula .ModelFun (model .Coefs ,design ); 


if~isempty (weights )
weights =NonLinearModel .checkWeights (weights ,ypred ); 
end

if~isempty (weights )
ifisa (weights ,'function_handle' )
wVec =weights (ypred ); 
else
wVec =weights ; 
end

wVec =wVec (:); 
errorVar =model .MSE ./wVec ; 
elseif~isempty (model .ErrorModelInfo )&&~isempty (model .ErrorModelInfo .ScheffeSimPred )&&~isempty (model .ErrorModelInfo .ErrorVariance )

errorVar =model .ErrorModelInfo .ErrorVariance (design ); 
errorVar =errorVar (:); 
else


errorVar =model .MSE *ones (length (ypred ),1 ); 
end




ysim =normrnd (ypred ,sqrt (errorVar )); 
end


function hout =plotDiagnostics (model ,plottype ,varargin )





























ifnargin <2 
plottype ='leverage' ; 
else
plottype =convertStringsToChars (plottype ); 
alltypes ={'contour' ,'cookd' ,'leverage' }; 
plottype =internal .stats .getParamVal (plottype ,alltypes ,'PLOTTYPE' ); 
end
[varargin {:}]=convertStringsToChars (varargin {:}); 
f =classreg .regr .modelutils .plotDiagnostics (model ,plottype ,varargin {:}); 
ifnargout >0 
hout =f ; 
end
end

function hout =plotResiduals (model ,plottype ,varargin )













































ifnargin <2 
plottype ='histogram' ; 
end
plottype =convertStringsToChars (plottype ); 
[varargin {:}]=convertStringsToChars (varargin {:}); 
[residtype ,wantWeighted ,~,args ]=internal .stats .parseArgs ({'residualtype' ,'weighted' },{'Raw' ,false },varargin {:}); 
varargin =args ; 
residtype =internal .stats .getParamVal (residtype ,...
    NonLinearModel .SupportedResidualTypes ,'''ResidualType''' ); 
wantWeighted =internal .stats .parseOnOff (wantWeighted ,'''Weighted''' ); 
f =classreg .regr .modelutils .plotResiduals (model ,plottype ,'ResidualType' ,residtype ,'Weighted' ,wantWeighted ,varargin {:}); 
ifnargout >0 
hout =f ; 
end
end

function fout =plotSlice (model )
















f =classreg .regr .modelutils .plotSlice (model ); 
ifnargout >0 
fout =f ; 
end
end
end

methods (Access ='public' )
function CI =coefCI (model ,alpha )
















ifnargin <2 
alpha =0.05 ; 
end
se =sqrt (diag (model .CoefficientCovariance )); 
delta =se *tinv (1 -alpha /2 ,model .DFE ); 
CI =[(model .Coefs (:)-delta ),(model .Coefs (:)+delta )]; 


nC =numel (model .Coefs ); 
H =eye (nC ); 
estimable =model .getEstimableContrasts (H ); 
CI (~estimable ,:)=NaN ; 
end


function [p ,t ,r ]=coefTest (model ,H ,c )


























nc =model .NumCoefficients ; 
ifnargin <2 

H =eye (nc ); 
end
ifnargin <3 
c =zeros (size (H ,1 ),1 ); 
end

[p ,t ,r ]=linhyptest (model .Coefs ,model .CoefficientCovariance ,c ,H ,model .DFE ); 


estimable =model .getEstimableContrasts (H ); 
if~all (estimable )
p =p *NaN ; 
t =t *NaN ; 
r =r *NaN ; 
end
end
end

methods (Hidden =true )

function t =title (model )

indent ='    ' ; 
maxWidth =matlab .desktop .commandwindow .size ; maxWidth =maxWidth (1 )-1 ; 
f =model .Formula ; 
fstr =char (f ,maxWidth -length (indent )); 
t =[indent ,fstr ]; 
end

function v =varianceParam (model )
v =model .RMSE ; 
end
end

methods (Access ='protected' )






function [f ,p ,emptyNullModel ,hasIntercept ]=fTest (model )






[~,Junw_r ]=create_J_r (model ); 
Jmin =min (Junw_r ,[],1 ); 
Jmax =max (Junw_r ,[],1 ); 
hasIntercept =any (abs (Jmax -Jmin )<=sqrt (eps (class (Junw_r )))*(abs (Jmax )+abs (Jmin ))); 
ifhasIntercept &&(model .NumEstimatedCoefficients >1 )

emptyNullModel =false ; 
nobs =model .NumObservations ; 
ssr =max (model .SST -model .SSE ,0 ); 
dfr =model .NumEstimatedCoefficients -1 ; 
dfe =nobs -1 -dfr ; 
f =(ssr ./dfr )/(model .SSE /dfe ); 
p =fcdf (1 ./f ,dfe ,dfr ); 
else

emptyNullModel =true ; 
ssr =max (model .SST0 -model .SSE ,0 ); 
dfr =model .NumEstimatedCoefficients ; 
dfe =model .NumObservations -model .NumEstimatedCoefficients ; 
f =(ssr ./dfr )/(model .SSE /dfe ); 
p =fcdf (1 ./f ,dfe ,dfr ); 
end
end



function tbl =tstats (model )


effectiveNumObservations =model .DFE +numel (model .CoefficientNames ); 
tbl =classreg .regr .modelutils .tstats (model .Coefs ,sqrt (diag (model .CoefficientCovariance )),...
    effectiveNumObservations ,model .CoefficientNames ); 





estimable =model .getEstimableContrasts (eye (numel (model .Coefs ))); 
tableVals =table2array (tbl ); 
tableVals (~estimable ,2 :4 )=NaN ; 
tableVals =array2table (tableVals ); 
tableVals .Properties .VariableNames =tbl .Properties .VariableNames ; 
tableVals .Properties .RowNames =tbl .Properties .RowNames ; 
end


function D =get_diagnostics (model ,type )
ifnargin <2 
HatMatrix =get_diagnostics (model ,'hatmatrix' ); 
CooksDistance =get_diagnostics (model ,'cooksdistance' ); 
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

case 'cooksdistance' 
D =get_CooksDistance (model ); 
D (~subset ,:)=NaN ; 
otherwise
error (message ('stats:LinearModel:UnrecognizedDiagnostic' ,type )); 
end
end
end
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
subset =model .ObservationInfo .Subset ; 
SSE =sum (wt (subset ).*abs (r (subset )).^2 ); 
s2_i =(SSE -delta_i )./newdf ; 
s2_i (~subset &~isnan (s2_i ))=0 ; 
end

function H =get_HatMatrix (model )
ifhasData (model )









[~,Xunw_r ]=create_J_r (model ); 

sw =sqrt (get_CombinedWeights_r (model )); 
Xw_r =bsxfun (@times ,sw (:),Xunw_r ); 
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
d =w .*abs (r ).^2 .*(h ./((1 -h ).^2 ))./(model .NumCoefficients *model .MSE ); 
else
d =[]; 
end
end

function w =get_CombinedWeights_r (model ,reduce )






























switchlower (model .ErrorModelInfo .ErrorModel )
case NonLinearModel .NAME_CONSTANT 
if~isempty (model .WeightFunctionHandle )

X =model .Design ; 
w =model .MSE ./model .ErrorModelInfo .ErrorVariance (X ); 

assert (isempty (model .Robust )); 
elseif~isempty (model .Robust )

w =model .ObservationInfo .Weights .*model .Robust .Weights ; 


assert (all (model .ObservationInfo .Weights ==1 )); 
else

w =model .ObservationInfo .Weights ; 

assert (isempty (model .Robust )); 
end
case {NonLinearModel .NAME_COMBINED ,NonLinearModel .NAME_PROPORTIONAL }

X =model .Design ; 
w =model .MSE ./model .ErrorModelInfo .ErrorVariance (X ); 
otherwise
error (message ('stats:NonLinearModel:InvalidErrorModel' )); 
end

ifnargin <2 ||reduce 
subset =model .ObservationInfo .Subset ; 
w =w (subset ); 
end
end


function design =predictorMatrix (model ,X ,isPredictorsOnly )
ifisa (X ,'dataset' )
X =dataset2table (X ); 
end
ifisa (X ,'table' )



tf =ismember (model .PredictorNames ,X .Properties .VariableNames ); 
if~all (tf )
error (message ('stats:NonLinearModel:PredictorMissing' )); 
end
design =classreg .regr .modelutils .predictormatrix (X ,...
    'ResponseVar' ,[],...
    'PredictorVars' ,model .Formula .PredictorNames ); 
else
ifnargin >2 &&isPredictorsOnly 


npreds =model .NumPredictors ; 
ifsize (X ,2 )~=npreds 
error (message ('stats:NonLinearModel:BadXColumnNumber' ,npreds )); 
end
varLocs =model .PredLocs ; 
else


nvars =model .NumVariables ; 
ifsize (X ,2 )~=nvars -1 
error (message ('stats:NonLinearModel:BadXColumnNumber' ,nvars -1 )); 
end
varLocs =true (1 ,nvars ); 
varLocs (model .RespLoc )=false ; 
end
design =X (:,model .VariableInfo .InModel (varLocs )); 
end
end


function J =jacobian (model ,X )
ifmodel .HaveGrad 
[~,J ]=model .Formula .ModelFun (model .Coefs ,X ); 
else

beta =model .Coefs ; 
dbeta =eps (max (abs (beta ),1 )).^(1 /3 ); 
J =zeros (size (X ,1 ),model .NumCoefficients ); 
fori =1 :model .NumCoefficients 
h =zeros (size (beta )); h (i )=dbeta (i ); 
ypredplus =model .Formula .ModelFun (beta +h ,X ); 
ypredminus =model .Formula .ModelFun (beta -h ,X ); 
J (:,i )=(ypredplus -ypredminus )/(2 *h (i )); 
end
end
end


function model =fitter (model )


X =getData (model ); 
model .Design =predictorMatrix (model ,X ); 
model .CoefficientNames =model .Formula .CoefficientNames ; 
response =getResponse (model ); 



opts =model .Iterative .IterOpts ; 
subset =model .ObservationInfo .Subset ; 
X =model .Design (subset ,:); 
y =response (subset ,:); 
F =model .Formula .ModelFun ; 
b0 =model .Iterative .InitialCoefs ; 







ifisempty (model .WeightFunctionHandle )

w =model .ObservationInfo .Weights (subset ,:); 
if~all (w ==1 )
wtargs ={'Weights' ,w }; 
else
wtargs ={}; 
end
else

w =model .WeightFunctionHandle ; 
wtargs ={'Weights' ,w }; 
end


errormodelargs ={'ErrorModel' ,model .ErrorModelInfo .ErrorModel ,...
    'ErrorParam' ,model .ErrorModelInfo .ErrorParam }; 



if~isempty (wtargs )&&~strcmpi (model .ErrorModelInfo .ErrorModel ,NonLinearModel .NAME_CONSTANT )
error (message ('stats:NonLinearModel:ErrorModelWeightConflict' )); 
end



ifisempty (model .Robust )
[model .Coefs ,~,J_r ,model .CoefficientCovariance ,model .MSE ,model .ErrorModelInfo ,~]=...
    nlinfit (X ,y ,F ,b0 ,opts ,wtargs {:},errormodelargs {:}); 
else
opts .Robust ='on' ; 
opts =statset (opts ,model .Robust ); 
[model .Coefs ,~,J_r ,model .CoefficientCovariance ,model .MSE ,model .ErrorModelInfo ,robustw ]=...
    nlinfit (X ,y ,F ,b0 ,opts ,wtargs {:},errormodelargs {:}); 


model .Robust .Weights =zeros (length (subset ),1 ); 
model .Robust .Weights (subset )=robustw ; 
end


model .WorkingValues .J_r =J_r ; 



TolSVD =eps (class (model .Coefs )); 
[~,model .RankJW ,~,model .getEstimableContrasts ,~,~]=...
    internal .stats .isEstimable (eye (numel (model .Coefs )),'DesignMatrix' ,J_r ,'TolSVD' ,TolSVD ); 


model .DFE =model .NumObservations -model .RankJW ; 
end


function model =selectVariables (model )
f =model .Formula ; 
[~,model .PredLocs ]=ismember (f .PredictorNames ,f .VariableNames ); 
[~,model .RespLoc ]=ismember (f .ResponseName ,f .VariableNames ); 
model =selectVariables @classreg .regr .ParametricRegression (model ); 
end


function model =postFit (model )

model =getSumOfSquaresAndLogLikelihood (model ); 
[~,Junw_r ]=create_J_r (model ); 
sw =sqrt (get_CombinedWeights_r (model )); 
Xw_r =bsxfun (@times ,Junw_r ,sw ); 
[Qw_r ,~,~]=qr (Xw_r ,0 ); 







rank =model .NumEstimatedCoefficients ; 
Qw_r =Qw_r (:,1 :rank ); 
h =zeros (size (model .ObservationInfo ,1 ),1 ); 
h (model .ObservationInfo .Subset )=sum (abs (Qw_r ).^2 ,2 ); 
model .Leverage =h ; 


[model .FTestFval ,model .FTestPval ,model .EmptyNullModel ,...
    model .HasIntercept ]=fTest (model ); 
end


function model =getSumOfSquaresAndLogLikelihood (model )





subset =model .ObservationInfo .Subset ; 

resid_r =getResponse (model )-predict (model ); 
resid_r =resid_r (subset ); 

y =getResponse (model ); 
y_r =y (subset ); 

yfit_r =predict (model ); 
yfit_r =yfit_r (subset ); 

w =get_CombinedWeights_r (model ,false ); 
w_r =w (subset ); 

sumw =sum (w_r ); 
wtdymean =sum (w_r .*y_r )/sumw ; 
model .SSE =sum (w_r .*resid_r .^2 ); 
model .SSR =sum (w_r .*(yfit_r -wtdymean ).^2 ); 
model .SST =sum (w_r .*(y_r -wtdymean ).^2 ); 
model .SST0 =sum (w_r .*(y_r ).^2 ); 
model .LogLikelihood =getlogLikelihood (model ); 
model .LogLikelihoodNull =logLikelihoodNull (model ); 
end


function [J_r ,Junw_r ]=create_J_r (model )
subset =model .ObservationInfo .Subset ; 
J_r =jacobian (model ,model .Design (subset ,:)); 
ifnargout >=2 
Junw_r =J_r ; 
end
w =model .ObservationInfo .Weights (subset ,:); 
if~all (w ==1 )
J_r =bsxfun (@times ,sqrt (w ),J_r ); 
end
end


function ypred =predictPredictorMatrix (model ,Xpred )

design =predictorMatrix (model ,Xpred ,true ); 
ypred =model .Formula .ModelFun (model .Coefs ,design ); 
end


function L =getlogLikelihood (model )
Var =model .DFE /model .NumObservations *model .MSE ; 
ifisempty (model .Robust )

w_r =get_CombinedWeights_r (model ,true ); 
L =-(model .DFE +model .NumObservations *log (2 *pi )+sum (log (Var ./w_r )))/2 ; 
else


subset =model .ObservationInfo .Subset ; 
yfit =predict (model ); 
yfit =yfit (subset ); 
y =getResponse (model ); 
y =y (subset ); 
L =-(sum ((y -yfit ).^2 )/Var +model .NumObservations *log (2 *pi )+model .NumObservations *log (Var ))/2 ; 
end

end


function L0 =logLikelihoodNull (model )










ifisempty (model .Robust )

w =get_CombinedWeights_r (model ,false ); 
else

w =ones (length (model .ObservationInfo .Weights ),1 ); 
end


subset =model .ObservationInfo .Subset ; 

y =getResponse (model ); 
y_r =y (subset ); 

w_r =w (subset ); 

mu0 =sum (y_r .*w_r )/sum (w_r ); 

n_r =length (w_r ); 
if(n_r >1 )
mse0 =sum (w_r .*(y_r -mu0 ).^2 )/(n_r -1 ); 
else
mse0 =sum (w_r .*(y_r -mu0 ).^2 )/(n_r ); 
end
L0 =-((n_r -1 )+n_r *log (2 *pi )+sum (log (mse0 ./w_r )))/2 ; 

end


function r =get_residuals (model ,type )
ifnargin <2 
Raw =get_residuals (model ,'raw' ); 
Pearson =get_residuals (model ,'pearson' ); 
Studentized =get_residuals (model ,'studentized' ); 
Standardized =get_residuals (model ,'standardized' ); 
r =table (Raw ,Pearson ,Studentized ,Standardized ,...
    'RowNames' ,model .ObservationNames ); 
else
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
r =raw ./(sqrt (model .MSE *(1 -model .Leverage ))); 
otherwise
error (message ('stats:NonLinearModel:BadResidualType' ,type )); 
end
r (~model .ObservationInfo .Subset )=NaN ; 
end
end

function r =get_weighted_residuals (model ,type )

if(nargin <2 )
r =get_residuals (model ); 
else
r =get_residuals (model ,type ); 
end


ifisempty (model .Robust )

w =get_CombinedWeights_r (model ,false ); 
else

w =ones (length (model .ObservationInfo .Weights ),1 ); 
end


ifisa (r ,'dataset' )
r =dataset2table (r ); 
end
ifisa (r ,'table' )
rnames =r .Properties .VariableNames ; 
r =varfun (@(xx )xx .*sqrt (w ),r ); 
r .Properties .VariableNames =rnames ; 
else
r =sqrt (w ).*r ; 
end
end


end

methods (Static ,Access ='public' ,Hidden )
function model =fit (X ,varargin )



[varargin {:}]=convertStringsToChars (varargin {:}); 
[X ,y ,haveDataset ,otherArgs ]=NonLinearModel .handleDataArgs (X ,varargin {:}); 


iflength (otherArgs )<2 
error (message ('stats:NonLinearModel:TooFewArguments' )); 
end
modelDef =otherArgs {1 }; 
initialCoefs =otherArgs {2 }; 
ncoefs =numel (initialCoefs ); 
otherArgs (1 :2 )=[]; 





paramNames ={'CoefficientNames' ,'PredictorVars' ,'ResponseVar' ,'Weights' ,'Exclude' ...
    ,'VarNames' ,'Options' ,'ErrorModel' ,'ErrorParameters' }; 
paramDflts ={[],[],[],[],[],[],[],[]}; 
[coefNames ,predictorVars ,responseVar ,weights ,...
    exclude ,varNames ,options ,errormodel ,errorparam ,supplied ]=...
    internal .stats .parseArgs (paramNames ,paramDflts ,otherArgs {:}); 

model =NonLinearModel (); 
model .Iterative .InitialCoefs =initialCoefs ; 
model .Iterative .IterOpts =options ; 
if~isempty (options )
options =statset (statset ('nlinfit' ),options ); 
end
model .Robust =classreg .regr .FitObject .checkRobust (options ); 

if~haveDataset 
nx =size (X ,2 ); 
[varNames ,predictorVars ,responseVar ]=...
    classreg .regr .FitObject .getVarNames (varNames ,predictorVars ,responseVar ,nx ); 
end

model .Formula =NonLinearModel .createFormula (supplied ,modelDef ,X ,ncoefs ,coefNames ,...
    predictorVars ,responseVar ,varNames ,haveDataset ); 





if~isempty (weights )&&isa (weights ,'function_handle' )

model =assignData (model ,X ,y ,[],[],model .Formula .VariableNames ,exclude ); 

weights =NonLinearModel .checkWeights (weights ,getResponse (model )); 

model .WeightFunctionHandle =weights ; 
else

model =assignData (model ,X ,y ,weights ,[],model .Formula .VariableNames ,exclude ); 
end

iflength (model .Formula .CoefficientNames )~=ncoefs 
error (message ('stats:NonLinearModel:BadInitial' ,ncoefs ,length (model .Formula .CoefficientNames ))); 
end


[errormodel ,errorparam ]=NonLinearModel .ValidateErrorModelAndErrorParam (errormodel ,errorparam ); 
model .ErrorModelInfo .ErrorModel =errormodel ; 
model .ErrorModelInfo .ErrorParam =errorparam ; 






model =doFit (model ); 

model =updateVarRange (model ); 
end
end

methods (Static =true ,Hidden =true )
function model =loadobj (obj )

obj =loadobj @classreg .regr .ParametricRegression (obj ); 


emptyErrorModel =false ; 
ifisempty (obj .ErrorModelInfo .ErrorModel )

emptyErrorModel =true ; 


S =struct ('ErrorModel' ,[],'ErrorParameters' ,[],'ErrorVariance' ,[],...
    'MSE' ,[],'ScheffeSimPred' ,[],'WeightFunction' ,false ,...
    'FixedWeights' ,false ,'RobustWeightFunction' ,false ); 


mse =obj .MSE ; 
errorparam =sqrt (mse ); 
S .ErrorModel ='constant' ; 
S .ErrorParameters =errorparam ; 
S .ErrorVariance =@(x )mse *ones (size (x ,1 ),1 ); 
S .MSE =mse ; 
S .ScheffeSimPred =obj .NumCoefficients +1 ; 
if~all (obj .ObservationInfo .Weights ==1 )

S .FixedWeights =true ; 
end
if~isempty (obj .Robust )

S .RobustWeightFunction =true ; 
end
obj .ErrorModelInfo =S ; 
end


ifisempty (obj .getEstimableContrasts )

obj .getEstimableContrasts =@(Cnew )true (size (Cnew ,1 ),1 ); 
end


ifisempty (obj .RankJW )

obj .RankJW =obj .NumCoefficients ; 
end





ifisempty (obj .SST0 )||isnan (obj .SST0 )
obj =getSumOfSquaresAndLogLikelihood (obj ); 
end

[f ,p ,emptyNullModel ,hasIntercept ]=fTest (obj ); 

ifisempty (obj .FTestFval )||isnan (obj .FTestFval )
obj .FTestFval =f ; 
end


ifisempty (obj .FTestPval )||isnan (obj .FTestPval )
obj .FTestPval =p ; 
end


ifisempty (obj .EmptyNullModel )||isnan (obj .EmptyNullModel )
obj .EmptyNullModel =emptyNullModel ; 
end


ifisempty (obj .HasIntercept )||isnan (obj .HasIntercept )
obj .HasIntercept =hasIntercept ; 
end


ifemptyErrorModel &&obj .HasIntercept 
obj .ErrorModelInfo .ScheffeSimPred =obj .NumCoefficients ; 
end


model =obj ; 

end
end


methods (Static ,Access ='protected' )
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
error (message ('stats:NonLinearModel:MissingY' ))
else
ifisrow (X )&&numel (X )==numel (y )
X =X (:); 
y =y (:); 
end
otherArgs =varargin ; 
end
end


function formula =createFormula (supplied ,modelDef ,X ,ncoefs ,coefNames ,predictorVars ,responseVar ,varNames ,haveDataset )

givenFun =isa (modelDef ,'function_handle' ); 
givenString =~givenFun &&internal .stats .isString (modelDef ); 

ifisa (modelDef ,'classreg.regr.NonLinearFormula' )
formula =modelDef ; 

elseifgivenString ||givenFun 
ifgivenString 
ifsupplied .PredictorVars ||supplied .ResponseVar 
error (message ('stats:NonLinearModel:NamesWithFormula' )); 
end
elseifgivenFun &&classreg .regr .NonLinearFormula .isOpaqueFun (modelDef )









if~supplied .CoefficientNames 
coefNames =strcat ({'b' },num2str ((1 :ncoefs )' )); 
end
end

ifhaveDataset 


ifsupplied .VarNames 
error (message ('stats:NonLinearModel:NamesWithDataset' )); 
end
varNames =X .Properties .VariableNames ; 

else


nvars =size (X ,2 )+1 ; 
ifsupplied .VarNames 
iflength (varNames )~=nvars 
error (message ('stats:NonLinearModel:BadVarNamesLength' )); 
end
else
ifgivenString 




formula =classreg .regr .NonLinearFormula (modelDef ,coefNames ,[],[],[],ncoefs ); 
varNames =formula .VariableNames ; 
responseName =formula .ResponseName ; 
respLoc =find (strcmp (responseName ,varNames )); 
varNames =varNames ([1 :(respLoc -1 ),(respLoc +1 ):end,respLoc ]); 
iflength (varNames )~=nvars 



isBuiltIn =cellfun (@(name )exist (name ,'builtin' ),formula .VariableNames )>0 ; 
iflength (varNames )==nvars +sum (isBuiltIn )
formula .VariableNames (isBuiltIn )=[]; 
varNames =formula .VariableNames ; 
responseName =formula .ResponseName ; 
respLoc =find (strcmp (responseName ,varNames )); 
varNames =varNames ([1 :(respLoc -1 ),(respLoc +1 ):end,respLoc ]); 
coefNames =formula .CoefficientNames ; 
else
error (message ('stats:NonLinearModel:CannotDetermineNames' )); 
end
end
else
ifclassreg .regr .NonLinearFormula .isOpaqueFun (modelDef )

varNames =[strcat ({'X' },num2str ((1 :size (X ,2 ))' ))' ,{'y' }]; 
end
end
end
end

ifgivenString 
formula =classreg .regr .NonLinearFormula (modelDef ,coefNames ,[],[],varNames ,ncoefs ); 
else
ifclassreg .regr .NonLinearFormula .isOpaqueFun (modelDef )
if~supplied .PredictorVars 
ifhaveDataset &&supplied .ResponseVar 
predictorVars =varNames (~strcmp (responseVar ,varNames )); 
else
predictorVars =varNames (1 :(end-1 )); 
end
end
end
formula =classreg .regr .NonLinearFormula (modelDef ,coefNames ,predictorVars ,responseVar ,varNames ,ncoefs ); 
end

else
error (message ('stats:NonLinearModel:BadModelDef' )); 
end
end


function [errormodel ,errorparam ]=ValidateErrorModelAndErrorParam (errormodel ,errorparam )






ifisempty (errormodel )
errormodel =NonLinearModel .NAME_CONSTANT ; 
elseif~isempty (errormodel )&&~any (strcmpi (errormodel ,NonLinearModel .SupportedErrorModels ))
error (message ('stats:NonLinearModel:InvalidErrorModel' )); 
end


ifnumel (errorparam )>2 ||~isnumeric (errorparam )
error (message ('stats:nlinfit:BadErrorParam' ))
end
switchlower (errormodel )
case NonLinearModel .NAME_COMBINED 
ifisempty (errorparam )
errorparam =[1 ,1 ]; 
elseifnumel (errorparam )~=2 

error (message ('stats:nlinfit:BadCombinedParam' ,errormodel )); 
end
case NonLinearModel .NAME_PROPORTIONAL 

ifisempty (errorparam )
errorparam =1 ; 
elseifnumel (errorparam )~=1 
error (message ('stats:nlinfit:BadErrorParam1' ,errormodel ))
end
case NonLinearModel .NAME_CONSTANT 

ifisempty (errorparam )
errorparam =1 ; 
elseifnumel (errorparam )~=1 
error (message ('stats:nlinfit:BadErrorParam1' ,errormodel ))
end
end

end


function weights =checkWeights (weights ,yfit )





ifisa (weights ,'function_handle' )||(isnumeric (weights )&&isvector (weights ))


ifisa (weights ,'function_handle' )

try
wVec =weights (yfit ); 
catch ME 
ifisa (weights ,'inline' )
m =message ('stats:nlinfit:InlineWeightFunctionError' ); 
throw (addCause (MException (m .Identifier ,'%s' ,getString (m )),ME )); 
elseifstrcmp ('MATLAB:UndefinedFunction' ,ME .identifier )...
    &&~isempty (strfind (ME .message ,func2str (weights )))
error (message ('stats:nlinfit:WeightFunctionNotFound' ,func2str (weights ))); 
else
m =message ('stats:nlinfit:WeightFunctionError' ,func2str (weights )); 
throw (addCause (MException (m .Identifier ,'%s' ,getString (m )),ME )); 
end
end
else

wVec =weights ; 
end


if~isequal (size (wVec ),size (yfit ))||~isnumeric (wVec )||~isreal (wVec )||~isvector (wVec )||any (wVec (:)<=0 )
error (message ('stats:nlinfit:InvalidWeights' )); 
end

else

error (message ('stats:nlinfit:InvalidWeights' )); 
end

end


function sch =validateScheffeParamUsingJacobianPred (sch ,rankJ ,delta ,estimable ,errorVar )


ifsch ~=(rankJ +1 )

delta_est =delta (estimable ,:); 

EVPred =errorVar (estimable ); EVFit =ones (size (EVPred )); 
[schEstDelta ,rankEstDelta ]=internal .stats .getscheffeparam ('UnWeightedJacobian' ,delta_est ,'Intopt' ,'observation' ,'ErrorVarianceFit' ,EVFit ,'ErrorVariancePred' ,EVPred ); 
if(schEstDelta ~=rankEstDelta )



sch =(rankJ +1 ); 
end
end

end


function [y ,model ]=applyLogTransformation (y ,model )



if~all (y >0 )
error (message ('stats:nlinfit:PositiveYRequired' )); 
else
y =log (max (y ,realmin )); 
end

model =@(phi ,X )log (max (model (phi ,X ),realmin )); 
end

end

end
