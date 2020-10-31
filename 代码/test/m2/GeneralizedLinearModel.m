classdef (Sealed =true )GeneralizedLinearModel <classreg .regr .CompactGeneralizedLinearModel &classreg .regr .TermsRegression 




























































properties (Constant ,Hidden )
SupportedResidualTypes ={'Raw' ,'LinearPredictor' ,'Pearson' ,'Anscombe' ,'Deviance' }; 
end

properties (GetAccess ='protected' ,SetAccess ='protected' )
IRLSWeights =[]; 
Options =[]; 
B0 =[]; 
end
properties (GetAccess ='public' ,SetAccess ='protected' )












Offset =0 ; 
end
properties (Dependent ,GetAccess ='public' ,SetAccess ='protected' )























Residuals 
























Fitted 

































Diagnostics 
end
properties (Dependent ,GetAccess ='protected' ,SetAccess ='protected' )


binomSize_r =[]; 
offset_r =[]; 
end

methods 
function binomSize_r =get .binomSize_r (model )
ifisempty (model .WorkingValues )
subset =model .ObservationInfo .Subset ; 
model .WorkingValues .binomSize_r =model .ObservationInfo .BinomSize (subset ); 
else
binomSize_r =model .WorkingValues .binomSize_r ; 
end
end
function offset_r =get .offset_r (model )
ifisempty (model .WorkingValues )
subset =model .ObservationInfo .Subset ; 
offset =model .ObservationInfo .Offset ; 
if~isempty (offset )&&~isscalar (offset )
offset =offset (subset ); 
end
model .WorkingValues .offset_r =offset ; 
else
offset_r =model .WorkingValues .offset_r ; 
end
end
function R =get .Residuals (model )
R =get_residuals (model ); 
end









end

methods (Hidden =true ,Access ='public' )
function model =GeneralizedLinearModel (varargin )
ifnargin ==0 
model .Formula =classreg .regr .LinearFormula ; 
return 
end
error (message ('stats:GeneralizedLinearModel:NoConstructor' )); 
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
sizeArray =[size (this .ObservationInfo .Subset ,1 ); 3 ]; 
end
end

methods (Access ='public' )
function model =step (model ,varargin )























































[varargin {:}]=convertStringsToChars (varargin {:}); 


[crit ,~,args ]=internal .stats .parseArgs ({'criterion' },{'Deviance' },varargin {:}); 
ifstrncmpi (crit ,'deviance' ,length (crit ))
ifmodel .DispersionEstimated 
crit ='deviance_f' ; 
else
crit ='deviance_chi2' ; 
end
end
model =step @classreg .regr .TermsRegression (model ,'Criterion' ,crit ,args {:}); 
checkDesignRank (model ); 
end


function disp (model )




isLoose =strcmp (get (0 ,'FormatSpacing' ),'loose' ); 
if(isLoose ),fprintf ('\n' ); end
fprintf (getString (message ('stats:GeneralizedLinearModel:display_GLM' ))); 

dispBody (model )
end

function [varargout ]=predict (model ,varargin )












































ifnargin ==1 ||internal .stats .isString (varargin {1 })
X =model .Variables ; 
offset =model .Offset ; 
[varargout {1 :max (1 ,nargout )}]=...
    predict @classreg .regr .CompactGeneralizedLinearModel (model ,X ,'Offset' ,offset ,varargin {:}); 
else
Xpred =varargin {1 }; 
varargin =varargin (2 :end); 
ifisa (Xpred ,'tall' )
[varargout {1 :max (1 ,nargout )}]=hSlicefun (@model .predict ,Xpred ,varargin {:}); 
return 
end

[varargout {1 :max (1 ,nargout )}]=...
    predict @classreg .regr .CompactGeneralizedLinearModel (model ,Xpred ,varargin {:}); 
end
end

function hout =plotDiagnostics (model ,plottype ,varargin )





















ifnargin >1 
plottype =convertStringsToChars (plottype ); 
[varargin {:}]=convertStringsToChars (varargin {:}); 
end
ifnargin <2 
plottype ='leverage' ; 
else
alltypes ={'contour' ,'cookd' ,'leverage' }; 
plottype =internal .stats .getParamVal (plottype ,alltypes ,'PLOTTYPE' ); 
end
f =classreg .regr .modelutils .plotDiagnostics (model ,plottype ,varargin {:}); 
ifnargout >0 
hout =f ; 
end
end

function hout =plotResiduals (model ,plottype ,varargin )






































[varargin {:}]=convertStringsToChars (varargin {:}); 
ifnargin <2 
plottype ='histogram' ; 
end
plottype =convertStringsToChars (plottype ); 
[residtype ,~,args ]=internal .stats .parseArgs ({'residualtype' },{'Raw' },varargin {:}); 
varargin =args ; 
residtype =internal .stats .getParamVal (residtype ,...
    GeneralizedLinearModel .SupportedResidualTypes ,'''ResidualType''' ); 

f =classreg .regr .modelutils .plotResiduals (model ,plottype ,'ResidualType' ,residtype ,varargin {:}); 
ifnargout >0 
hout =f ; 
end
end

function glm =compact (this )









this .PrivateLogLikelihood =this .LogLikelihood ; 
glm =classreg .regr .CompactGeneralizedLinearModel .make (this ); 
end
end


methods (Access ='protected' )
function model =assignData (model ,X ,y ,w ,offset ,binomN ,asCat ,dummyCoding ,varNames ,excl )
model =assignData @classreg .regr .TermsRegression (model ,X ,y ,w ,asCat ,dummyCoding ,varNames ,excl ); 
y =getResponse (model ); 
n =length (y ); 


ifstrcmpi (model .DistributionName ,'binomial' )



ifisvector (y )
ifisempty (binomN )
binomN =ones (n ,1 ); 
elseif~isnumeric (binomN )||~all (binomN ==round (binomN ))...
    ||any (binomN <0 )...
    ||~(isscalar (binomN )...
    ||(isvector (binomN )&&numel (binomN )==n ))
error (message ('stats:GeneralizedLinearModel:BadNValues' )); 
elseifisscalar (binomN )
binomN =repmat (binomN ,n ,1 ); 
end
model .ObservationInfo .BinomSize =binomN (:); 
elseifsize (y ,2 )==2 &&isnumeric (y )...
    &&all (all (binomN ==round (binomN )))...
    &&all (all (binomN >=0 ))
model .ObservationInfo .BinomSize =y (:,2 ); 
model .ResponseType ='BinomialCounts' ; 
else
error (message ('stats:GeneralizedLinearModel:BadBinomialResponse' )); 
end
end
ifisempty (offset )
offset =zeros (n ,1 ); 
elseif~isnumeric (offset )||~(isscalar (offset )||...
    (isvector (offset )&&numel (offset )==n ))
error (message ('stats:GeneralizedLinearModel:BadOffset' ,n ))
elseifisscalar (offset )
offset =repmat (offset ,n ,1 ); 
end
model .Offset =offset (:); 
end


function model =selectObservations (model ,exclude ,missing )
ifnargin <3 ,missing =[]; end
model =selectObservations @classreg .regr .TermsRegression (model ,exclude ,missing ); 
subset =model .ObservationInfo .Subset ; 
ifstrcmpi (model .DistributionName ,'binomial' )

model .WorkingValues .binomSize_r =model .ObservationInfo .BinomSize (subset ); 
end
offset =model .Offset ; 
if~isempty (offset )&&~isscalar (offset )
offset =offset (subset ); 
end
model .WorkingValues .offset_r =offset ; 
end


function model =fitter (model )
X =getData (model ); 
[model .Design ,model .CoefTerm ,model .CoefficientNames ]=designMatrix (model ,X ); 


model .WorkingValues .design_r =create_design_r (model ); 

ifstrcmpi (model .DistributionName ,'binomial' )
response_r =[model .y_r ,model .binomSize_r ]; 
else
response_r =model .y_r ; 
end
estDisp =model .DispersionEstimated ||...
    ~any (strcmpi (model .DistributionName ,{'binomial' ,'poisson' })); 
[model .Coefs ,model .Deviance ,stats ]=...
    glmfit (model .design_r ,response_r ,model .DistributionName ,'EstDisp' ,estDisp ,...
    'Constant' ,'off' ,'Link' ,model .Formula .Link ,'Weights' ,model .w_r ,...
    'Offset' ,model .offset_r ,'RankWarn' ,false ,'Options' ,model .Options ,'B0' ,model .B0 ); 
model .CoefficientCovariance =stats .covb ; 
model .DFE =stats .dfe ; 
model .Dispersion =stats .s ^2 ; 

subset =model .ObservationInfo .Subset ; 
wts =NaN (size (subset )); 
wts (subset )=stats .wts ; 
model .IRLSWeights =wts ; 
end


function model =postFit (model )

model =postFit @classreg .regr .TermsRegression (model ); 
ifstrcmpi (model .DistributionName ,'binomial' )
y =[model .y_r ,model .binomSize_r ]; 
else
y =model .y_r ; 
end
estDisp =model .DispersionEstimated &&...
    ~any (strcmpi (model .DistributionName ,{'binomial' ,'poisson' })); 
[~,model .DevianceNull ]=...
    glmfit (ones (size (y ,1 ),1 ),y ,model .DistributionName ,'EstDisp' ,estDisp ,...
    'Constant' ,'off' ,'Link' ,model .Formula .Link ,'Weights' ,model .w_r ,...
    'Offset' ,model .offset_r ); 

end


function L =getlogLikelihood (model )
L =model .PrivateLogLikelihood ; 
ifisempty (L )
subset =model .ObservationInfo .Subset ; 
switchlower (model .DistributionName )
case 'binomial' 
pHat_r =predict (model ); pHat_r =pHat_r (subset ); 
L =sum (model .w_r .*binologpdf (model .y_r ,model .binomSize_r ,pHat_r )); 
case 'gamma' 
aHat =1 ./model .Dispersion ; 
bHat_r =predict (model ).*model .Dispersion ; bHat_r =bHat_r (subset ); 
L =sum (model .w_r .*gamlogpdf (model .y_r ,aHat ,bHat_r )); 
case 'inverse gaussian' 
muHat_r =predict (model ); muHat_r =muHat_r (subset ); 
lambdaHat =1 ./model .Dispersion ; 
L =sum (model .w_r .*invglogpdf (model .y_r ,muHat_r ,lambdaHat )); 
case 'normal' 
muHat_r =predict (model ); muHat_r =muHat_r (subset ); 
sigmaHat =sqrt (model .DFE /model .NumObservations *model .Dispersion ); 
L =sum (model .w_r .*normlogpdf (model .y_r ,muHat_r ,sigmaHat )); 
case 'poisson' 
lambdaHat_r =predict (model ); lambdaHat_r =lambdaHat_r (subset ); 
L =sum (model .w_r .*poisslogpdf (model .y_r ,lambdaHat_r )); 
end
end
end


function L0 =logLikelihoodNull (model )


w_r_normalized =model .w_r /sum (model .w_r ); 
switchlower (model .DistributionName )
case 'binomial' 
p0 =sum (model .w_r .*model .y_r )./sum (model .w_r .*model .binomSize_r ); 
L0 =sum (model .w_r .*binologpdf (model .y_r ,model .binomSize_r ,p0 )); 
case 'gamma' 
mu0 =sum (w_r_normalized .*model .y_r ); 
b0 =var (model .y_r ,model .w_r )./mu0 ; 
a0 =mu0 ./b0 ; 
L0 =sum (model .w_r .*gamlogpdf (model .y_r ,a0 ,b0 )); 
case 'inverse gaussian' 
mu0 =sum (w_r_normalized .*model .y_r ); 
lambda0 =(mu0 ^3 )./var (model .y_r ,model .w_r ); 
L0 =sum (model .w_r .*invglogpdf (model .y_r ,mu0 ,lambda0 )); 
case 'normal' 
mu0 =sum (w_r_normalized .*model .y_r ); 
sigma0 =std (model .y_r ,model .w_r ); 
L0 =sum (model .w_r .*normlogpdf (model .y_r ,mu0 ,sigma0 )); 
case 'poisson' 
lambda0 =sum (w_r_normalized .*model .y_r ); 
L0 =sum (model .w_r .*poisslogpdf (model .y_r ,lambda0 )); 
end
end


function yfit =get_fitted (model ,type )
ifnargin <2 
Response =get_fitted (model ,'response' ); 
LinearPredictor =get_fitted (model ,'linearpredictor' ); 
yfit =table (Response ,LinearPredictor ,'RowNames' ,model .ObservationNames ); 
ifstrcmpi (model .DistributionName ,'binomial' )
yfit .Probability =get_fitted (model ,'probability' ); 
end
else
yfit =predict (model ); 
switchlower (type )
case 'response' 
ifstrcmpi (model .DistributionName ,'binomial' )
yfit =yfit .*model .ObservationInfo .BinomSize ; 
end
case 'probability' 
if~strcmpi (model .DistributionName ,'binomial' )
error (message ('stats:GeneralizedLinearModel:NoProbabilityFit' )); 
end
case 'linearpredictor' 
link =dfswitchyard ('stattestlink' ,model .Formula .Link ,class (yfit )); 
yfit =link (yfit ); 
otherwise
error (message ('stats:GeneralizedLinearModel:UnrecognizedFit' ,type )); 
end
end
end


function d =get_CooksDistance (model )
ifhasData (model )
w =get_CombinedWeights_r (model ,false ); 
r =get_residuals (model ,'linearpredictor' ); 
h =model .Leverage ; 
d =w .*abs (r ).^2 .*(h ./(1 -h ).^2 )./(model .NumEstimatedCoefficients *varianceParam (model )); 
else
d =[]; 
end
end
function r =get_residuals (model ,type )
ifnargin <2 
Raw =get_residuals (model ,'raw' ); 
LinearPredictor =get_residuals (model ,'linearpredictor' ); 
Pearson =get_residuals (model ,'pearson' ); 
Anscombe =get_residuals (model ,'anscombe' ); 
Deviance =get_residuals (model ,'deviance' ); 
r =table (Raw ,LinearPredictor ,Pearson ,Anscombe ,Deviance ,...
    'RowNames' ,model .ObservationNames ); 
else
y =getResponse (model ); 
ifstrcmpi (model .DistributionName ,'binomial' )
N =model .ObservationInfo .BinomSize ; 
y =y (:,1 )./N ; 
else
N =1 ; 
end
mu =predict (model ); 

switchlower (type )
case 'raw' 
ifstrcmpi (model .DistributionName ,'binomial' )
r =(y -mu ).*N ; 
else
r =y -mu ; 
end
case 'linearpredictor' 
dlink =model .Link .Derivative ; 
deta =dlink (mu ); 





r =(y -mu ).*deta ; 
case 'pearson' 
ifstrcmpi (model .DistributionName ,'binomial' )
r =(y -mu )./(sqrt (model .Distribution .VarianceFunction (mu ,N ))+(y ==mu )); 
else
r =(y -mu )./(sqrt (model .Distribution .VarianceFunction (mu ))+(y ==mu )); 
end
case 'anscombe' 
switch(lower (model .DistributionName ))
case 'normal' 
r =y -mu ; 
case 'binomial' 
t =2 /3 ; 
r =beta (t ,t )*(betainc (y ,t ,t )-betainc (mu ,t ,t ))...
    ./((mu .*(1 -mu )).^(1 /6 )./sqrt (N )); 
case 'poisson' 
r =1.5 *((y .^(2 /3 )-mu .^(2 /3 ))./mu .^(1 /6 )); 
case 'gamma' 
r =3 *(y .^(1 /3 )-mu .^(1 /3 ))./mu .^(1 /3 ); 
case 'inverse gaussian' 
r =(log (y )-log (mu ))./mu ; 
end
case 'deviance' 
devFun =model .Distribution .DevianceFunction ; 
ifstrcmpi (model .DistributionName ,'binomial' )
r =sign (y -mu ).*sqrt (max (0 ,devFun (mu ,y ,N ))); 
else
r =sign (y -mu ).*sqrt (max (0 ,devFun (mu ,y ))); 
end
otherwise
error (message ('stats:GeneralizedLinearModel:UnrecognizedResidual' ,type )); 
end
end
end
function w =get_CombinedWeights_r (model ,reduce )
w =model .ObservationInfo .Weights .*model .IRLSWeights ; 
ifnargin <2 ||reduce 
subset =model .ObservationInfo .Subset ; 
w =w (subset ); 
end
end
end

methods (Static ,Access ='public' ,Hidden )
function model =fit (X ,varargin )



[varargin {:}]=convertStringsToChars (varargin {:}); 
[X ,y ,haveDataset ,otherArgs ]=GeneralizedLinearModel .handleDataArgs (X ,varargin {:}); 











paramNames ={'Distribution' ,'Link' ,'Intercept' ,'PredictorVars' ...
    ,'ResponseVar' ,'Weights' ,'Exclude' ,'CategoricalVars' ...
    ,'VarNames' ,'DummyVarCoding' ,'BinomialSize' ,'Offset' ...
    ,'DispersionFlag' ,'rankwarn' ,'Options' ,'B0' }; 
paramDflts ={'normal' ,'' ,true ,[]...
    ,[],[],[],[]...
    ,[],'reference' ,[],0 ...
    ,[],true ,[],[]}; 


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

[distr ,link ,intercept ,predictorVars ,responseVar ,...
    weights ,exclude ,asCatVar ,varNames ,dummyCoding ,binomN ,offset ,...
    disperFlag ,rankwarn ,options ,b0 ,supplied ]=...
    internal .stats .parseArgs (paramNames ,paramDflts ,otherArgs {:}); 

alldist ={'Normal' ,'Poisson' ,'Binomial' ,'Gamma' ,'Inverse Gaussian' }; 
distr =internal .stats .getParamVal (distr ,alldist ,'''Distribution''' ); 
ifisempty (disperFlag )
disperFlag =~any (strcmpi (distr ,{'Binomial' ,'Poisson' })); 
end

if~isempty (binomN )&&~strcmp (distr ,'Binomial' )
error (message ('stats:GeneralizedLinearModel:NotBinomial' )); 
end

model =GeneralizedLinearModel (); 
model .DistributionName =distr ; 
clink =canonicalLink (distr ); 

ifisscalar (disperFlag )&&(islogical (disperFlag )||...
    (isnumeric (disperFlag )&&(disperFlag ==0 ||disperFlag ==1 )))
model .DispersionEstimated =disperFlag ==1 ; 
else
error (message ('stats:GeneralizedLinearModel:BadDispersion' )); 
end


modelType ={'linear' ; 'interactions' ; 'purequadratic' ; 'quadratic' ; 'polyIJK...' }; 
ifhaveDataset ==1 &&isempty (responseVar )...
    &&isa (X .(X .Properties .VariableNames {end}),'categorical' )...
    &&any (strcmpi (modelDef ,modelType ))

dsVarNames =X .Properties .VariableNames {end}; 
y0 =X .(dsVarNames ); 
[X .(X .Properties .VariableNames {end}),classname ]=categ2num (y0 ); 
else
y0 =[]; 
end

model .Formula =GeneralizedLinearModel .createFormula (supplied ,modelDef ,X ,...
    predictorVars ,responseVar ,intercept ,link ,varNames ,haveDataset ,clink ); 

ifisempty (y0 )
ifhaveDataset ==0 &&isa (y ,'categorical' )

y0 =y ; 
[y ,classname ]=categ2num (y ); 
elseifhaveDataset ==1 &&isa (X .(model .Formula .ResponseName ),'categorical' )

y0 =X .(model .Formula .ResponseName ); 
[X .(model .Formula .ResponseName ),classname ]=categ2num (y0 ); 
else
y0 =0 ; 
end
end

model =assignData (model ,X ,y ,weights ,offset ,binomN ,asCatVar ,dummyCoding ,model .Formula .VariableNames ,exclude ); 
silent =classreg .regr .LinearFormula .isModelAlias (modelDef ); 
model =removeCategoricalPowers (model ,silent ); 
model .Options =options ; 
model .B0 =b0 ; 
model =doFit (model ); 
model .Options =[]; 
model .B0 =[]; 

ifisa (y0 ,'categorical' )
a =class (y0 ); 
model .VariableInfo .Class {model .RespLoc }=a ; 
ifstrcmpi (model .VariableInfo .Class {model .RespLoc },{'nominal' })
model .VariableInfo .Range {model .RespLoc }=nominal (classname ' ); 
elseifstrcmpi (model .VariableInfo .Class {model .RespLoc },{'ordinal' })
model .VariableInfo .Range {model .RespLoc }=ordinal (classname ' ); 
elseifstrcmpi (model .VariableInfo .Class {model .RespLoc },{'categorical' })
model .VariableInfo .Range {model .RespLoc }=categorical (classname ' ); 
end
end

model =updateVarRange (model ); 

ifrankwarn 
checkDesignRank (model ); 
end
end

function model =stepwise (X ,varargin )




[varargin {:}]=convertStringsToChars (varargin {:}); 
[X ,y ,haveDataset ,otherArgs ]=GeneralizedLinearModel .handleDataArgs (X ,varargin {:}); 

ifisempty (otherArgs )
start ='constant' ; 
else
start =otherArgs {1 }; 
otherArgs (1 )=[]; 
end

paramNames ={'Distribution' ,'Link' ,'Intercept' ,'PredictorVars' ,'ResponseVar' ,'Weights' ...
    ,'Exclude' ,'CategoricalVars' ,'VarNames' ,'Lower' ,'Upper' ,'Criterion' ...
    ,'PEnter' ,'PRemove' ,'NSteps' ,'Verbose' ,'BinomialSize' ,'Offset' ,'DispersionFlag' }; 
paramDflts ={'normal' ,[],true ,[],[],[],[],[],[],'constant' ,'interactions' ,'Deviance' ,[],[],Inf ,1 }; 
[distr ,link ,intercept ,predictorVars ,responseVar ,weights ,exclude ,...
    asCatVar ,varNames ,lower ,upper ,crit ,penter ,premove ,nsteps ,verbose ,binomN ,offset ,...
    disperFlag ,supplied ]=...
    internal .stats .parseArgs (paramNames ,paramDflts ,otherArgs {:}); 

if~isscalar (verbose )||~ismember (verbose ,0 :2 )
error (message ('stats:LinearModel:BadVerbose' )); 
end

alldist ={'Normal' ,'Poisson' ,'Binomial' ,'Gamma' ,'Inverse Gaussian' }; 
distr =internal .stats .getParamVal (distr ,alldist ,'''Distribution''' ); 
ifisempty (disperFlag )
disperFlag =~any (strcmpi (distr ,{'Binomial' ,'Poisson' })); 
end
if~(isscalar (disperFlag )&&(islogical (disperFlag )||...
    (isnumeric (disperFlag )&&(disperFlag ==0 ||disperFlag ==1 ))))
error (message ('stats:GeneralizedLinearModel:BadDispersion' )); 
end

clink =canonicalLink (distr ); 



if~supplied .ResponseVar &&(classreg .regr .LinearFormula .isTermsMatrix (start )||classreg .regr .LinearFormula .isModelAlias (start ))
ifisa (lower ,'classreg.regr.LinearFormula' )
responseVar =lower .ResponseName ; 
supplied .ResponseVar =true ; 
else
ifinternal .stats .isString (lower )&&~classreg .regr .LinearFormula .isModelAlias (lower )
lower =GeneralizedLinearModel .createFormula (supplied ,lower ,X ,...
    predictorVars ,responseVar ,intercept ,link ,varNames ,haveDataset ,clink ); 
responseVar =lower .ResponseName ; 
supplied .ResponseVar =true ; 
elseifisa (upper ,'classreg.regr.LinearFormula' )
responseVar =upper .ResponseName ; 
supplied .ResponseVar =true ; 
else
ifinternal .stats .isString (upper )&&~classreg .regr .LinearFormula .isModelAlias (upper )
upper =GeneralizedLinearModel .createFormula (supplied ,upper ,X ,...
    predictorVars ,responseVar ,intercept ,link ,varNames ,haveDataset ,clink ); 
responseVar =upper .ResponseName ; 
supplied .ResponseVar =true ; 
end
end
end
end

if~isa (start ,'classreg.regr.LinearFormula' )
start =GeneralizedLinearModel .createFormula (supplied ,start ,X ,...
    predictorVars ,responseVar ,intercept ,link ,varNames ,haveDataset ,clink ); 
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

ifhaveDataset 
model =GeneralizedLinearModel .fit (X ,start .Terms ,'Distribution' ,distr ,...
    'Link' ,start .Link ,'ResponseVar' ,start .ResponseName ,'Weights' ,weights ,...
    'Exclude' ,exclude ,'CategoricalVars' ,asCatVar ,...
    'Disper' ,disperFlag ,'BinomialSize' ,binomN ,'Offset' ,offset ,'RankWarn' ,false ); 
else
model =GeneralizedLinearModel .fit (X ,y ,start .Terms ,'Distribution' ,distr ,...
    'Link' ,start .Link ,'ResponseVar' ,start .ResponseName ,'Weights' ,weights ,...
    'Exclude' ,exclude ,'CategoricalVars' ,asCatVar ,'VarNames' ,start .VariableNames ,...
    'Disper' ,disperFlag ,'BinomialSize' ,binomN ,'Offset' ,offset ,'RankWarn' ,false ); 
end

model .Steps .Start =start ; 
model .Steps .Lower =lower ; 
model .Steps .Upper =upper ; 
ifstrcmpi (crit ,'deviance' )
ifmodel .DispersionEstimated 
model .Steps .Criterion ='deviance_f' ; 
else
model .Steps .Criterion ='deviance_chi2' ; 
end
else
model .Steps .Criterion =crit ; 
end
model .Steps .PEnter =penter ; 
model .Steps .PRemove =premove ; 
model .Steps .History =[]; 

model =stepwiseFitter (model ,nsteps ,verbose ); 
checkDesignRank (model ); 
end
end

methods (Static ,Access ='protected' )
function [addTest ,addThreshold ,removeTest ,removeThreshold ,reportedNames ,testName ]=getStepwiseTests (crit ,Steps )
localCrits ={'deviance_f' ,'deviance_chi2' }; 
ifinternal .stats .isString (crit )&&ismember (crit ,localCrits )
addThreshold =Steps .PEnter ; 
removeThreshold =Steps .PRemove ; 
ifisempty (addThreshold ),addThreshold =0.05 ; end
ifisempty (removeThreshold ),removeThreshold =0.10 ; end

ifaddThreshold >=removeThreshold 
error (message ('stats:LinearModel:BadSmallerThreshold' ,sprintf ('%g' ,addThreshold ),sprintf ('%g' ,removeThreshold ),crit )); 
end

switchlower (crit )
case 'deviance_f' 
addTest =@(proposed ,current )f_test (proposed ,current ,'up' ); 
removeTest =@(proposed ,current )f_test (current ,proposed ,'down' ); 
reportedNames ={'Deviance' ,'FStat' ,'PValue' }; 
testName ='pValue' ; 
case 'deviance_chi2' 
addTest =@(proposed ,current )chi2_test (proposed ,current ,'up' ); 
removeTest =@(proposed ,current )chi2_test (current ,proposed ,'down' ); 
reportedNames ={'Deviance' ,'Chi2Stat' ,'PValue' }; 
testName ='pValue' ; 
end
else
[addTest ,addThreshold ,removeTest ,removeThreshold ,reportedNames ,testName ]...
    =classreg .regr .TermsRegression .getStepwiseTests (crit ,Steps ); 
end
end
end
end

function [p ,pReported ,reportedVals ]=f_test (fit1 ,fit0 ,direction )
dev1 =fit1 .Deviance ; 
dfDenom =fit1 .DFE ; 
ifisempty (fit0 )
dev0 =dev1 ; 
dfNumer =0 ; 
else
dev0 =fit0 .Deviance ; 
dfNumer =fit0 .DFE -fit1 .DFE ; 
end
F =(max (0 ,(dev0 -dev1 ))/dfNumer )/fit1 .Dispersion ; 
p =fcdf (1 ./F ,dfDenom ,dfNumer ); 
pReported =p ; 
ifstrcmp (direction ,'up' )
reportedVals ={dev1 ,F ,p }; 
else
reportedVals ={dev0 ,F ,p }; 
end
end

function [p ,pReported ,reportedVals ]=chi2_test (fit1 ,fit0 ,direction )
dev1 =fit1 .Deviance ; 
ifisempty (fit0 )
dev0 =dev1 ; 
df =0 ; 
else
dev0 =fit0 .Deviance ; 
df =fit0 .DFE -fit1 .DFE ; 
end






x2 =max (0 ,(dev0 -dev1 )); 
if(df ==0 )
x2 =NaN ; 
end
p =gammainc (x2 /2 ,df /2 ,'upper' ); 
pReported =p ; 
ifstrcmp (direction ,'up' )
reportedVals ={dev1 ,x2 ,p }; 
else
reportedVals ={dev0 ,x2 ,p }; 
end
end


function logy =binologpdf (x ,n ,p )
logy =gammaln (n +1 )-gammaln (x +1 )-gammaln (n -x +1 )+x .*log (p )+(n -x ).*log1p (-p ); 
end
function logy =gamlogpdf (x ,a ,b )
z =x ./b ; 
logy =(a -1 ).*log (z )-z -gammaln (a )-log (b ); 
end
function logy =invglogpdf (x ,mu ,lambda )
logy =.5 *log (lambda ./(2 .*pi .*x .^3 ))+(-0.5 .*lambda .*(x ./mu -2 +mu ./x )./mu ); 
end
function logy =normlogpdf (x ,mu ,sigma )
logy =(-0.5 *((x -mu )./sigma ).^2 )-log (sqrt (2 *pi ).*sigma ); 
end
function logy =poisslogpdf (x ,lambda )
logy =(-lambda +x .*log (lambda )-gammaln (x +1 )); 
end


function link =canonicalLink (distr )
switchlower (distr )
case 'normal' 
link ='identity' ; 
case 'binomial' 
link ='logit' ; 
case 'poisson' 
link ='log' ; 
case 'gamma' 
link ='reciprocal' ; 
case 'inverse gaussian' 
link =-2 ; 
end
end


function [y ,classname ]=categ2num (x )
[y ,classname ]=grp2idx (x ); 
nc =length (classname ); 
ifnc >2 
error (message ('stats:glmfit:TwoLevelCategory' )); 
end
y (y ==1 )=0 ; 
y (y ==2 )=1 ; 
end
