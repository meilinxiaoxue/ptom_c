classdef (Sealed =true )GeneralizedLinearMixedModel <classreg .regr .LinearLikeMixedModel 






























































properties (Dependent ,GetAccess ='public' ,SetAccess ='protected' ,Hidden =true )











Fitted 














Residuals 
end


properties (GetAccess =public ,SetAccess ='protected' )










FitMethod 







Distribution 














Link 

























Dispersion 
















DispersionEstimated 
end


properties (GetAccess ='public' ,SetAccess ='protected' ,Hidden =true )

Response 
end


properties (Constant =true ,Hidden =true )

AllowedFitMethods ={'mpl' ,'rempl' ,'approximatelaplace' ,'laplace' }; 

AllowedOptimizers ={'fminunc' ,'quasinewton' ,'fminsearch' }; 

AllowedStartMethods ={'random' ,'default' }; 

AllowedDFMethods ={'none' ,'residual' }; 

AllowedResidualTypes ={'raw' ,'pearson' }; 

AllowedDistributions ={'normal' ,'gaussian' ,'binomial' ,'poisson' ,'gamma' ,'inversegaussian' ,'inverse gaussian' }; 

AllowedEBMethods ={'auto' ,'default' ,'linesearchnewton' ,'linesearchmodifiednewton' ,'trustregion2d' ,'fsolve' }; 

AllowedCovarianceMethods ={'conditional' ,'jointhessian' }; 

end


properties (Access ={?classreg .regr .LinearLikeMixedModel })






BinomialSize 


Offset 


DispersionFlag 





CovariancePattern 



DummyVarCoding 


Optimizer 



OptimizerOptions 



StartMethod 



CheckHessian 




PLIterations 



PLTolerance 













MuStart 



InitPLIterations 










EBMethod 
















EBOptions 











CovarianceMethod 






UseSequentialFitting 




CovarianceTable 



ShowPLOptimizerDisplay =false ; 
end


methods (Access ='public' ,Hidden =true )

function t =title (model )
strLHS =model .ResponseName ; 
strFunArgs =internal .stats .strCollapse (model .Formula .PredictorNames ,',' ); 
t =sprintf ('%s = glme(%s)' ,strLHS ,strFunArgs ); 
end

function val =feval (model ,varargin )%#ok<INUSD> 
warning (message ('stats:GeneralizedLinearMixedModel:NoFevalMethod' )); 
val =[]; 
end

end


methods (Access ='public' )

function disp (model )






ifisempty (model .ObservationInfo )
displayFormula (model ); 
error (message ('stats:GeneralizedLinearMixedModel:NoConstructor' )); 
end


displayHeadLine (model ); 


displayModelInfo (model ); 


displayFormula (model ); 


displayModelFitStats (model ); 


displayFixedStats (model )


displayCovarianceStats (model ); 

end

end


methods (Access ='public' )

function [mupred ,muci ,df ]=predict (model ,varargin )






























































































[varargin {:}]=convertStringsToChars (varargin {:}); 
ifnargin <2 ||internal .stats .isString (varargin {1 })





haveDataset =true ; 
ds =model .Variables ; 
otherArgs =varargin ; 
else


[haveDataset ,ds ,~,~,~,otherArgs ]...
    =model .handleDatasetOrMatrixInput (varargin {:}); 
end
assertThat (haveDataset ,'stats:LinearMixedModel:MustBeDataset' ,'T' )
M =size (ds ,1 ); 



dfltConditional =true ; 
dfltSimultaneous =false ; 
dfltDFMethod ='Residual' ; 
dfltAlpha =0.05 ; 
dfltOffset =zeros (M ,1 ); 

paramNames ={'Conditional' ,'Simultaneous' ,'DFMethod' ,'Alpha' ,'Offset' }; 
paramDflts ={dfltConditional ,dfltSimultaneous ,dfltDFMethod ,dfltAlpha ,dfltOffset }; 

[conditional ,simultaneous ,dfmethod ,alpha ,offset ]...
    =internal .stats .parseArgs (paramNames ,paramDflts ,otherArgs {:}); 

conditional =model .validateConditional (conditional ); 
simultaneous =model .validateSimultaneous (simultaneous ); 
dfmethod =model .validateDFMethod (dfmethod ); 
alpha =model .validateAlpha (alpha ); 
offset =model .validateOffset (offset ,M ); 


q =model .RandomInfo .q ; 
R =model .GroupingInfo .R ; 
lev =model .GroupingInfo .lev ; 


predNames =model .PredictorNames ; 
varNames =model .Variables .Properties .VariableNames ; 
[~,predLocs ]=ismember (predNames ,varNames ); 
dsref =model .Variables (:,predLocs ); 
ds =model .validateDataset (ds ,'DS' ,dsref ); 



finfo =extractFixedInfo (model ,ds ); 
X =finfo .X ; 

rinfo =extractRandomInfo (model ,ds ); 
Z =rinfo .Z ; 



ginfo =extractGroupingInfo (model ,ds ); 
Gid =ginfo .Gid ; 
GidLevelNames =ginfo .GidLevelNames ; 







newGid =cell (R ,1 ); 
fork =1 :R 
newGid {k }=model .reorderGroupIDs (Gid {k },...
    GidLevelNames {k },model .GroupingInfo .GidLevelNames {k }); 
end




Zs =model .makeSparseZ (Z ,q ,lev ,newGid ,M ); 



wantConditional =conditional ; 
ifsimultaneous ==true 
wantPointwise =false ; 
else
wantPointwise =true ; 
end

hasIntercept =model .Formula .FELinearFormula .HasIntercept ; 
args ={X ,Zs ,alpha ,dfmethod ,...
    wantConditional ,wantPointwise ,offset ,hasIntercept }; 
switchnargout 
case {0 ,1 }
mupred =predict (model .slme ,args {:}); 
case 2 
[mupred ,muci ]=predict (model .slme ,args {:}); 
case 3 
[mupred ,muci ,df ]=predict (model .slme ,args {:}); 
end



end

function ynew =random (model ,varargin )














































[varargin {:}]=convertStringsToChars (varargin {:}); 



ifnargin <2 

wp =model .slme .PriorWeights ; 
delta =model .slme .Offset ; 
ntrials =model .slme .BinomialSize ; 
ysim =random (model .slme ,[],model .slme .X ,model .slme .Z ,delta ,wp ,ntrials ); 

subset =model .ObservationInfo .Subset ; 
ynew =NaN (length (subset ),1 ); 
ynew (subset )=ysim ; 
return ; 
end


ifinternal .stats .isString (varargin {1 })

haveDataset =true ; 
ds =model .Variables ; 
otherArgs =varargin ; 
else

[haveDataset ,ds ,~,~,~,otherArgs ]=model .handleDatasetOrMatrixInput (varargin {:}); 
end
assertThat (haveDataset ,'stats:LinearMixedModel:MustBeDataset' ,'TNEW' ); 
M =size (ds ,1 ); 



dfltWeights =ones (M ,1 ); 
dfltBinomialSize =ones (M ,1 ); 
dfltOffset =zeros (M ,1 ); 

paramNames ={'Weights' ,'BinomialSize' ,'Offset' }; 
paramDflts ={dfltWeights ,dfltBinomialSize ,dfltOffset }; 

[weights ,binomsize ,offset ]=internal .stats .parseArgs (paramNames ,paramDflts ,otherArgs {:}); 

weights =model .validateWeights (weights ,M ,model .Distribution ); 
binomsize =model .validateBinomialSize (binomsize ,M ); 
offset =model .validateOffset (offset ,M ); 


predNames =model .PredictorNames ; 
varNames =model .Variables .Properties .VariableNames ; 
[~,predLocs ]=ismember (predNames ,varNames ); 
dsref =model .Variables (:,predLocs ); 
ds =model .validateDataset (ds ,'DS' ,dsref ); 


q =model .RandomInfo .q ; 



finfo =extractFixedInfo (model ,ds ); 
X =finfo .X ; 

rinfo =extractRandomInfo (model ,ds ); 
Z =rinfo .Z ; 








ginfo =extractGroupingInfo (model ,ds ); 
Gid =ginfo .Gid ; 
lev =ginfo .lev ; 




Zs =model .makeSparseZ (Z ,q ,lev ,Gid ,M ); 




ynew =random (model .slme ,[],X ,Zs ,offset ,weights ,binomsize ,lev ); 

end

end


methods (Access ='public' ,Hidden =true )

function v =varianceParam (model )
v =model .Dispersion ; 
end

end


methods (Access ='public' )

function [feci ,reci ]=coefCI (model ,varargin )























































switchnargout 
case {0 ,1 }
feci =coefCI @classreg .regr .LinearLikeMixedModel (model ,varargin {:}); 
case 2 
[feci ,reci ]=coefCI @classreg .regr .LinearLikeMixedModel (model ,varargin {:}); 
end

end

function [P ,F ,DF1 ,DF2 ]=coefTest (model ,H ,c ,varargin )

































































ifnargin <2 

args ={}; 
elseifnargin <3 

args ={H }; 
elseifnargin <4 

args ={H ,c }; 
else

args =[{H ,c },varargin ]; 
end
[P ,F ,DF1 ,DF2 ]=coefTest @classreg .regr .LinearLikeMixedModel (model ,args {:}); 

end

end


methods (Access ='protected' )

function model =fitter (model )


model .RandomInfo .ZsColNames =makeSparseZNames (model ); 


model .slme =fitStandardLMEModel (model ); 




model .Coefs =model .slme .betaHat ; 
N =model .NumObservations ; 
P =length (model .Coefs ); 
model .DFE =N -P ; 
model .CoefficientCovariance =model .slme .covbetaHat ; 

end






function ypred =predictPredictorMatrix (model ,Xpred )%#ok<INUSD> 
ypred =[]; 
end

function D =get_diagnostics (model ,type )%#ok<INUSD> 
D =[]; 
end

function L =getlogLikelihood (model )



L =model .ModelCriterion .LogLikelihood ; 

end

function L0 =logLikelihoodNull (model )%#ok<MANU> 

L0 =NaN ; 

end

end


methods (Access ='protected' )

function model =postFit (model )


model .Dispersion =(model .slme .sigmaHat )^2 ; 
if(model .slme .isSigmaFixed ==true )
model .DispersionEstimated =false ; 
else
model .DispersionEstimated =true ; 
end
model .Response =response (model ); 


model .LogLikelihood =getlogLikelihood (model ); 
model .LogLikelihoodNull =logLikelihoodNull (model ); 


[model .SSE ,model .SSR ,model .SST ]=getSumOfSquares (model ); 


model .CoefficientNames =getCoefficientNames (model ); 




[~,~,model .CovarianceTable ]=covarianceParameters (model ,'WantCIs' ,false ); 



subset =model .ObservationInfo .Subset ; 
N =length (subset ); 
model .ObservationInfo .BinomSize =ones (N ,1 ); 
model .ObservationInfo .BinomSize (subset )=model .BinomialSize ; 

end

function model =selectVariables (model )
f =model .Formula ; 
[~,model .PredLocs ]=ismember (f .PredictorNames ,f .VariableNames ); 
[~,model .RespLoc ]=ismember (f .ResponseName ,f .VariableNames ); 
model =selectVariables @classreg .regr .ParametricRegression (model ); 
end

end




methods (Access ='protected' )








function table =tstats (model )
[~,~,table ]=fixedEffects (model ); 
end










function crit =get_modelcriterion (model ,type )

crit =modelCriterionLME (model ); 
ifnargin >=2 

crit =crit .(type ); 
end

end


function r =get_residuals (model ,residualtype )

ifnargin <2 

Raw =residuals (model ,'ResidualType' ,'raw' ); 
Pearson =residuals (model ,'ResidualType' ,'pearson' ); 


r =table (Raw ,Pearson ,'RowNames' ,model .ObservationNames ); 
else

residualtype =model .validateResidualType (residualtype ); 


switchlower (residualtype )
case 'raw' 
r =residuals (model ,'ResidualType' ,'raw' ); 
case 'pearson' 
r =residuals (model ,'ResidualType' ,'pearson' ); 
end
end

end


function yfit =get_fitted (model )


yfit =fitted (model ); 

end

end


methods (Access ='public' ,Hidden =true )

function glme =GeneralizedLinearMixedModel (varargin )





st =dbstack ; 
isokcaller =false ; 
if(length (st )>=2 )
isokcaller =any (strcmpi (st (2 ).name ,{'GeneralizedLinearMixedModel.fit' })); 
end
if(nargin ==0 &&isokcaller ==true )
glme .Formula =classreg .regr .LinearMixedFormula ('y ~ -1' ); 
return ; 
end
error (message ('stats:GeneralizedLinearMixedModel:NoConstructor' )); 
end

end


methods (Access ='private' )

function displayHeadLine (model )


isLoose =strcmp (get (0 ,'FormatSpacing' ),'loose' ); 
if(isLoose ),fprintf ('\n' ); end
switchlower (model .FitMethod )
case {'mpl' ,'rempl' }
headline =getString (message ('stats:GeneralizedLinearMixedModel:Display_headline' ,'PL' )); 
otherwise
headline =getString (message ('stats:GeneralizedLinearMixedModel:Display_headline' ,'ML' )); 
end
headline =GeneralizedLinearMixedModel .formatBold (headline ); 
fprintf ('%s\n' ,headline ); 
fprintf ('\n' ); 

end

function displayFormula (model )


formulaheadline =getString (message ('stats:GeneralizedLinearMixedModel:Display_formula' )); 
formulaheadline =GeneralizedLinearMixedModel .formatBold (formulaheadline ); 
fprintf ('%s\n' ,formulaheadline ); 
indent ='    ' ; 
maxWidth =matlab .desktop .commandwindow .size ; 
maxWidth =maxWidth (1 )-1 ; 
f =model .Formula ; 
fstr =char (f ,maxWidth -length (indent )); 
disp ([indent ,fstr ]); 
fprintf ('\n' ); 

end

function displayModelFitStats (model )


modelfitstatsheadline =getString (message ('stats:GeneralizedLinearMixedModel:Display_modelfitstats' )); 
modelfitstatsheadline =GeneralizedLinearMixedModel .formatBold (modelfitstatsheadline ); 
fprintf ('%s\n' ,modelfitstatsheadline ); 
crittable =modelCriterionLME (model ); 
crittable =GeneralizedLinearMixedModel .removeTitle (crittable ); 
disp (crittable ); 

end

function displayFixedStats (model )


fixedstatsheadline =getString (message ('stats:GeneralizedLinearMixedModel:Display_fixedstats' )); 
fixedstatsheadline =GeneralizedLinearMixedModel .formatBold (fixedstatsheadline ); 
fprintf ('%s\n' ,fixedstatsheadline ); 
ds =model .Coefficients ; 
ds =GeneralizedLinearMixedModel .removeTitle (ds ); 
disp (ds ); 

end

function displayCovarianceStats (model )


covariancestatsheadline =getString (message ('stats:GeneralizedLinearMixedModel:Display_covariancestats' )); 
covariancestatsheadline =GeneralizedLinearMixedModel .formatBold (covariancestatsheadline ); 
fprintf ('%s\n' ,covariancestatsheadline ); 


R =model .GroupingInfo .R ; 



lev =model .GroupingInfo .lev ; 
fork =1 :(R +1 )

ifk >R 
gname =getString (message ('stats:GeneralizedLinearMixedModel:String_error' )); 
fprintf ('%s\n' ,[getString (message ('stats:GeneralizedLinearMixedModel:String_group' )),': ' ,gname ]); 
else
gname =model .GroupingInfo .GNames {k }; 
fprintf ('%s\n' ,[getString (message ('stats:GeneralizedLinearMixedModel:String_group' )),': ' ,gname ,' (' ,num2str (lev (k )),' ' ,getString (message ('stats:LinearMixedModel:String_levels' )),')' ]); 
end

ifisa (model .CovarianceTable {k },'table' )
varnames =...
    model .CovarianceTable {k }.Properties .VariableNames ; 
elseifisa (model .CovarianceTable {k },'dataset' )
varnames =...
    model .CovarianceTable {k }.Properties .VarNames ; 
end
ifany (strcmpi ('Group' ,varnames ))
model .CovarianceTable {k }.Group =[]; 
end

ds =model .CovarianceTable {k }; 
ds =GeneralizedLinearMixedModel .removeTitle (ds ); 
disp (ds ); 
end

end

function displayModelInfo (model )


modelinfoheadline =getString (message ('stats:GeneralizedLinearMixedModel:Display_modelinfo' )); 
modelinfoheadline =GeneralizedLinearMixedModel .formatBold (modelinfoheadline ); 
fprintf ('%s\n' ,modelinfoheadline ); 


N =model .slme .N ; 


p =model .slme .p ; 


q =model .slme .q ; 


ifmodel .slme .isSigmaFixed 
ncov =model .slme .Psi .NumParametersExcludingSigma ; 
else
ncov =model .slme .Psi .NumParametersExcludingSigma +1 ; 
end


distribution =model .convertFirstCharToUpper (model .Distribution ); 


linkname =model .convertFirstCharToUpper (model .Link .Name ); 


switchlower (model .FitMethod )
case 'mpl' 
fitmethod ='MPL' ; 
case 'rempl' 
fitmethod ='REMPL' ; 
case 'approximatelaplace' 
fitmethod ='ApproximateLaplace' ; 
case 'laplace' 
fitmethod ='Laplace' ; 
end


indent ='    ' ; 
fprintf ('%-35s %6d\n' ,[indent ,getString (message ('stats:GeneralizedLinearMixedModel:ModelInfo_numobs' ))],N ); 
fprintf ('%-35s %6d\n' ,[indent ,getString (message ('stats:GeneralizedLinearMixedModel:ModelInfo_fecoef' ))],p ); 
fprintf ('%-35s %6d\n' ,[indent ,getString (message ('stats:GeneralizedLinearMixedModel:ModelInfo_recoef' ))],q ); 
fprintf ('%-35s %6d\n' ,[indent ,getString (message ('stats:GeneralizedLinearMixedModel:ModelInfo_covpar' ))],ncov ); 
fprintf ('%-35s %-6s\n' ,[indent ,getString (message ('stats:GeneralizedLinearMixedModel:ModelInfo_distribution' ))],distribution ); 
fprintf ('%-35s %-6s\n' ,[indent ,getString (message ('stats:GeneralizedLinearMixedModel:ModelInfo_link' ))],linkname ); 
fprintf ('%-35s %-6s\n' ,[indent ,getString (message ('stats:GeneralizedLinearMixedModel:ModelInfo_fitmethod' ))],fitmethod ); 
fprintf ('\n' ); 

end

end


methods (Access ={?classreg .regr .LinearLikeMixedModel })

function crittable =modelCriterionLME (model )






crit =modelCriterion (model .slme ); 


crittable =table (crit .AIC ,crit .BIC ,crit .logLik ,crit .Deviance ,...
    'VariableNames' ,{'AIC' ,'BIC' ,'LogLikelihood' ,'Deviance' }); 


ttl =getString (message ('stats:LinearMixedModel:Title_modelfitstats' )); 
crittable =classreg .regr .lmeutils .titleddataset (crittable ,ttl ); 

end

function w =getCombinedWeights (model ,reduce )









w =model .ObservationInfo .Weights ; 



ifnargin <2 ||reduce 
subset =model .ObservationInfo .Subset ; 
w =w (subset ); 
end

end

function slme =fitStandardLMEModel (model )






Z =model .RandomInfo .Z ; 
q =model .RandomInfo .q ; 
lev =model .GroupingInfo .lev ; 
Gid =model .GroupingInfo .Gid ; 
N =model .NumObservations ; 
Zs =GeneralizedLinearMixedModel .makeSparseZ (Z ,q ,lev ,Gid ,N ); 
Psi =makeCovarianceMatrix (model ); 




reduce =true ; 
w =getCombinedWeights (model ,reduce ); 
X =model .FixedInfo .X ; 


dofit =true ; 
dostats =true ; 
args ={'Distribution' ,model .Distribution ,...
    'BinomialSize' ,model .BinomialSize ,...
    'Link' ,model .Link ,...
    'Offset' ,model .Offset ,...
    'DispersionFlag' ,model .DispersionFlag ,...
    'Weights' ,w ,...
    'Optimizer' ,model .Optimizer ,...
    'OptimizerOptions' ,model .OptimizerOptions ,...
    'InitializationMethod' ,model .StartMethod ,...
    'CheckHessian' ,model .CheckHessian ,...
    'PLIterations' ,model .PLIterations ,...
    'PLTolerance' ,model .PLTolerance ,...
    'MuStart' ,model .MuStart ,...
    'InitPLIterations' ,model .InitPLIterations ,...
    'EBMethod' ,model .EBMethod ,...
    'EBOptions' ,model .EBOptions ,...
    'CovarianceMethod' ,model .CovarianceMethod ,...
    'UseSequentialFitting' ,model .UseSequentialFitting ,...
    'ShowPLOptimizerDisplay' ,model .ShowPLOptimizerDisplay }; 
slme =classreg .regr .lmeutils .StandardGeneralizedLinearMixedModel (X ,model .y ,Zs ,Psi ,model .FitMethod ,dofit ,dostats ,args {:}); 

end

function [SSE ,SSR ,SST ]=getSumOfSquares (model )



















subset =model .ObservationInfo .Subset ; 


F =fitted (model ); 
F =F (subset ); 


Y =response (model ); 
Y =Y (subset ); 


w =model .ObservationInfo .Weights ; 
w =w (subset ); 
ifstrcmpi (model .Distribution ,'binomial' )
w =w .*model .BinomialSize ; 
end


vfun =model .slme .VarianceFunction .VarianceFunction ; 
v =vfun (F ); 
weff =w ./v ; 


F_mean_w =sum (weff .*F )/sum (weff ); 


SSE =sum (weff .*((Y -F ).^2 )); 


SSR =sum (weff .*((F -F_mean_w ).^2 )); 


SST =SSE +SSR ; 

end

function coefnames =getCoefficientNames (model )






coefnames =model .FixedInfo .XColNames ; 

end

function np =getTotalNumberOfParameters (model )






numfixpar =model .slme .p ; 


numcovpar =model .slme .Psi .NumParametersExcludingSigma ; 


ifmodel .slme .isSigmaFixed 
np =numfixpar +numcovpar ; 
else
np =numfixpar +numcovpar +1 ; 
end

end

function w =getEffectiveObservationWeights (model ,reduce )










w =model .ObservationInfo .Weights ; 


binomsize =model .ObservationInfo .BinomSize ; 


ifstrcmpi (model .Distribution ,'binomial' )
w =w .*binomsize ; 
end


ifnargin <2 ||reduce 
subset =model .ObservationInfo .Subset ; 
w =w (subset ); 
end

end

end


methods (Static ,Access ='private' )

function strout =convertFirstCharToUpper (strin )





ifisempty (strin )
strout =strin ; 
return ; 
end


strout =strin ; 
strout (1 )=upper (strout (1 )); 

end

end

methods (Static ,Access ='protected' )

function checkNestingRequirement (smallModel ,bigModel ,smallModelName ,bigModelName )








































assert (isa (smallModel ,'GeneralizedLinearMixedModel' )); 
assert (isa (bigModel ,'GeneralizedLinearMixedModel' )); 


assert (internal .stats .isString (smallModelName )); 
assert (internal .stats .isString (bigModelName )); 





fitmethodsmall =smallModel .FitMethod ; 
fitmethodbig =bigModel .FitMethod ; 
isok =strcmpi (fitmethodsmall ,fitmethodbig )&(strcmpi (fitmethodsmall ,'rempl' )==false ); 
assertThat (isok ,'stats:GeneralizedLinearMixedModel:NestingCheck_fitmethod' ,smallModelName ,bigModelName ); 



distrsmall =smallModel .Distribution ; 
distrbig =bigModel .Distribution ; 
assertThat (strcmpi (distrsmall ,distrbig ),'stats:GeneralizedLinearMixedModel:NestingCheck_distribution' ,smallModelName ,bigModelName ); 


linksmall =smallModel .Link .Name ; 
linkbig =bigModel .Link .Name ; 
assertThat (isequal (linksmall ,linkbig ),'stats:GeneralizedLinearMixedModel:NestingCheck_link' ,smallModelName ,bigModelName ); 





ifstrcmpi (fitmethodsmall ,'mpl' )
oktocompare =any (strcmpi (distrsmall ,{'normal' ,'gaussian' }))&&strcmpi (linksmall ,'identity' ); 
if~oktocompare 
warning (message ('stats:GeneralizedLinearMixedModel:LRTUsingPseudoData' )); 
end
end



reduce =true ; 
wsmall =getEffectiveObservationWeights (smallModel ,reduce ); 
wbig =getEffectiveObservationWeights (bigModel ,reduce ); 
assertThat (max (abs (wsmall -wbig ))<=sqrt (eps ),'stats:GeneralizedLinearMixedModel:NestingCheck_weights' ,smallModelName ,bigModelName ); 



ysmall =smallModel .y ; 
ybig =bigModel .y ; 
assertThat (isequaln (ysmall ,ybig ),'stats:GeneralizedLinearMixedModel:NestingCheck_response' ,smallModelName ,bigModelName ); 


logliksmall =smallModel .LogLikelihood ; 
loglikbig =bigModel .LogLikelihood ; 
assertThat (loglikbig >=logliksmall ,'stats:GeneralizedLinearMixedModel:NestingCheck_loglik' ,bigModelName ,smallModelName ); 


Xsmall =smallModel .FixedInfo .X ; 
Xbig =bigModel .FixedInfo .X ; 
assertThat (GeneralizedLinearMixedModel .isMatrixNested (Xsmall ,Xbig ),'stats:GeneralizedLinearMixedModel:NestingCheck_nestedspanX' ,smallModelName ,bigModelName ); 


Zsmall =smallModel .slme .Z ; 
Zbig =bigModel .slme .Z ; 
assertThat (GeneralizedLinearMixedModel .isMatrixNested (Zsmall ,Zbig ),'stats:GeneralizedLinearMixedModel:NestingCheck_nestedspanZ' ,smallModelName ,bigModelName ); 

end

end



methods (Static ,Access ='protected' )

function fitmethod =validateFitMethod (fitmethod )











fitmethod =internal .stats .getParamVal (fitmethod ,...
    GeneralizedLinearMixedModel .AllowedFitMethods ,'FitMethod' ); 

end

function w =validateWeights (w ,N ,distribution )



















assert (N >=0 &internal .stats .isScalarInt (N )); 



strN =num2str (N ); 
assertThat (isnumeric (w )&isreal (w )&isvector (w )&length (w )==N ,'stats:GeneralizedLinearMixedModel:BadWeights' ,strN ,strN ); 
assertThat (all (~isnan (w )&w >=0 &w <Inf ),'stats:GeneralizedLinearMixedModel:BadWeights' ,strN ,strN ); 



ifany (strcmpi (distribution ,{'binomial' ,'poisson' }))
assertThat (internal .stats .isIntegerVals (w ,1 ),'stats:GeneralizedLinearMixedModel:BadWeights' ,strN ,strN ); 
end


ifsize (w ,1 )==1 
w =w ' ; 
end

end

function [optimizer ,optimizeroptions ]=...
    validateOptimizerAndOptions (optimizer ,optimizeroptions )


























optimizer =internal .stats .getParamVal (optimizer ,...
    GeneralizedLinearMixedModel .AllowedOptimizers ,'Optimizer' ); 


switchlower (optimizer )
case {'quasinewton' ,'fminsearch' }

case {'fminunc' }

if(license ('test' ,'optimization_toolbox' )==false )
error (message ('stats:GeneralizedLinearMixedModel:LicenseCheck_fminunc' )); 
end
end









switchlower (optimizer )
case 'quasinewton' 


assertThat (isempty (optimizeroptions )||isstruct (optimizeroptions ),'stats:GeneralizedLinearMixedModel:OptimizerOptions_qn' ); 


dflts =statset ('linearmixedmodel' ); 
ifisempty (optimizeroptions )
optimizeroptions =dflts ; 
else
optimizeroptions =statset (dflts ,optimizeroptions ); 
end

case {'fminunc' }


assertThat (isempty (optimizeroptions )||isa (optimizeroptions ,'optim.options.SolverOptions' ),'stats:GeneralizedLinearMixedModel:OptimizerOptions_fminunc' ); 


ifisempty (optimizeroptions )
optimizeroptions =optimoptions ('fminunc' ); 
optimizeroptions .Algorithm ='quasi-newton' ; 
else
optimizeroptions =optimoptions ('fminunc' ,optimizeroptions ); 
end

case 'fminsearch' 


assertThat (isempty (optimizeroptions )||isstruct (optimizeroptions ),'stats:GeneralizedLinearMixedModel:OptimizerOptions_fminsearch' ); 


dflts =optimset ('fminsearch' ); 
ifisempty (optimizeroptions )
optimizeroptions =dflts ; 
else
optimizeroptions =optimset (dflts ,optimizeroptions ); 
end
end

end

function startmethod =validateStartMethod (startmethod )











startmethod =...
    internal .stats .getParamVal (startmethod ,GeneralizedLinearMixedModel .AllowedStartMethods ,'StartMethod' ); 

end

function dfmethod =validateDFMethod (dfmethod )










dfmethod =internal .stats .getParamVal (dfmethod ,...
    GeneralizedLinearMixedModel .AllowedDFMethods ,'DFMethod' ); 

end

function residualtype =validateResidualType (residualtype )











residualtype =internal .stats .getParamVal (residualtype ,...
    GeneralizedLinearMixedModel .AllowedResidualTypes ,'ResidualType' ); 

end

function verbose =validateVerbose (verbose )
















isvalidscalarlogical =isscalar (verbose )&&islogical (verbose ); 


isvalidscalarint =internal .stats .isScalarInt (verbose ,0 ,2 ); 


isok =isvalidscalarlogical ||isvalidscalarint ; 
if~isok 
error (message ('stats:GeneralizedLinearMixedModel:BadVerbose' )); 
end


ifisvalidscalarlogical 
verbose =double (verbose ); 
end



end

function checkhessian =validateCheckHessian (checkhessian )











checkhessian =...
    GeneralizedLinearMixedModel .validateLogicalScalar (checkhessian ,'stats:GeneralizedLinearMixedModel:BadCheckHessian' ); 

end

end


methods (Static ,Access ='protected' )

function distribution =validateDistribution (distribution )












distribution =internal .stats .getParamVal (distribution ,...
    GeneralizedLinearMixedModel .AllowedDistributions ,'Distribution' ); 

end

function binomialsize =validateBinomialSize (binomialsize ,N )












assert (internal .stats .isScalarInt (N )); 



isintvals =internal .stats .isIntegerVals (binomialsize ,1 ); 
isokscalar =isintvals &isscalar (binomialsize ); 
isokvector =isintvals &isvector (binomialsize )&length (binomialsize )==N ; 
assertThat (isokscalar |isokvector ,'stats:GeneralizedLinearMixedModel:BadBinomialSize' ,num2str (N )); 


ifisokscalar 
binomialsize =binomialsize *ones (N ,1 ); 
end



ifsize (binomialsize ,1 )==1 
binomialsize =binomialsize ' ; 
end

end

function linkSpec =defaultLink (distribution )




switchlower (distribution )
case {'normal' ,'gaussian' }
linkSpec ='identity' ; 
case 'binomial' 
linkSpec ='logit' ; 
case 'poisson' 
linkSpec ='log' ; 
case 'gamma' 
linkSpec =-1 ; 
case {'inverse gaussian' ,'inversegaussian' }
linkSpec =-2 ; 
end

end

function offset =validateOffset (offset ,N )





assert (internal .stats .isScalarInt (N )); 


isok =isnumeric (offset )&isreal (offset )&...
    isvector (offset )&length (offset )==N ; 
assertThat (isok ,'stats:GeneralizedLinearMixedModel:BadOffset' ,num2str (N )); 


ifsize (offset ,1 )==1 
offset =offset ' ; 
end

end

function dispersionflag =validateDispersionFlag (dispersionflag )











dispersionflag =...
    GeneralizedLinearMixedModel .validateLogicalScalar (dispersionflag ,'stats:GeneralizedLinearMixedModel:BadDispersionFlag' ); 

end

function pliterations =validatePLIterations (pliterations )







isok =isscalar (pliterations )&...
    internal .stats .isIntegerVals (pliterations ,1 ); 
assertThat (isok ,'stats:GeneralizedLinearMixedModel:BadPLIterations' ); 

end

function pltolerance =validatePLTolerance (pltolerance )







isok =isscalar (pltolerance )&...
    isnumeric (pltolerance )&isreal (pltolerance ); 
assertThat (isok ,'stats:GeneralizedLinearMixedModel:BadPLTolerance' ); 

end

function mustart =validateMuStart (mustart ,distribution ,N )














if~isempty (mustart )

sizeok =isnumeric (mustart )&isreal (mustart )&isvector (mustart )&(length (mustart )==N ); 


switchlower (distribution )
case {'binomial' }
isok =sizeok &all (mustart >0 &mustart <1 ); 
case {'poisson' }
isok =sizeok &all (mustart >0 &mustart <Inf ); 
case {'gamma' }
isok =sizeok &all (mustart >0 &mustart <Inf ); 
case {'inverse gaussian' ,'inversegaussian' }
isok =sizeok &all (mustart >0 &mustart <Inf ); 
case {'normal' ,'gaussian' }
isok =sizeok &all (mustart >-Inf &mustart <Inf ); 
end
assertThat (isok ,'stats:GeneralizedLinearMixedModel:BadMuStart' ,num2str (N )); 



ifsize (mustart ,1 )==1 
mustart =mustart ' ; 
end
end

end

function initpliterations =validateInitPLIterations (initpliterations )







isok =isscalar (initpliterations )&...
    internal .stats .isIntegerVals (initpliterations ,1 ); 
assertThat (isok ,'stats:GeneralizedLinearMixedModel:BadInitPLIterations' ); 

end

function [ebmethod ,eboptions ]=validateEBParameters (ebmethod ,eboptions )
























dfltEBOptions =statset ('TolFun' ,1e-6 ,'TolX' ,1e-8 ,'MaxIter' ,100 ,'Display' ,'off' ); 


ebmethod =internal .stats .getParamVal (ebmethod ,GeneralizedLinearMixedModel .AllowedEBMethods ,'EBMethod' ); 
ifstrcmpi (ebmethod ,'auto' )
ebmethod ='default' ; 
end


switchlower (ebmethod )
case 'fsolve' 

if(license ('test' ,'optimization_toolbox' )==false )
error (message ('stats:GeneralizedLinearMixedModel:LicenseCheck_fsolve' )); 
end

ifisempty (eboptions )


eboptions =optimoptions ('fsolve' ); 
eboptions .TolFun =dfltEBOptions .TolFun ; 
eboptions .TolX =dfltEBOptions .TolX ; 
eboptions .MaxIter =dfltEBOptions .MaxIter ; 
eboptions .Display =dfltEBOptions .Display ; 
else

assertThat (isa (eboptions ,'optim.options.Fsolve' ),'stats:GeneralizedLinearMixedModel:BadEBOptions' ); 
end
otherwise

ifisempty (eboptions )

eboptions =dfltEBOptions ; 
else

assertThat (isstruct (eboptions ),'stats:GeneralizedLinearMixedModel:BadEBOptions' ); 

eboptions =statset (dfltEBOptions ,eboptions ); 
end
end

end

function covariancemethod =validateCovarianceMethod (covariancemethod )








covariancemethod =internal .stats .getParamVal (covariancemethod ,...
    GeneralizedLinearMixedModel .AllowedCovarianceMethods ,'CovarianceMethod' ); 

end

function usesequentialfitting =validateUseSequentialFitting (usesequentialfitting )







usesequentialfitting =...
    GeneralizedLinearMixedModel .validateLogicalScalar (usesequentialfitting ,'stats:GeneralizedLinearMixedModel:BadUseSequentialFitting' ); 

end

function ynew =validateYNew (ynew ,N ,subset )












isok =isnumeric (ynew )&isreal (ynew )&isvector (ynew )&(length (ynew )==N ); 
assertThat (isok ,'stats:GeneralizedLinearMixedModel:Bad_YNew' ,num2str (N )); 

hasnans =any (isnan (ynew (subset ))); 
assertThat (~hasnans ,'stats:GeneralizedLinearMixedModel:Bad_YNew' ,num2str (N )); 


ifsize (ynew ,1 )==1 
ynew =ynew ' ; 
end

end

end


methods (Static ,Access ='public' ,Hidden =true )

function model =fit (ds ,formula ,varargin )




formula =convertStringsToChars (formula ); 
[varargin {:}]=convertStringsToChars (varargin {:}); 


ifisa (ds ,'dataset' )
ds =dataset2table (ds ); 
end


assertThat (isa (ds ,'table' ),'stats:GeneralizedLinearMixedModel:Fit_firstinput' ); 
assertThat (internal .stats .isString (formula ),'stats:GeneralizedLinearMixedModel:Fit_secondinput' ); 


model =GeneralizedLinearMixedModel (); 



model .Formula =classreg .regr .LinearMixedFormula (formula ,ds .Properties .VariableNames ); 
yresp =ds .(model .Formula .ResponseName ); 
ifislogical (yresp )
ds .(model .Formula .ResponseName )=double (yresp ); 
end


R =length (model .Formula .RELinearFormula ); 
N =size (ds ,1 ); 




dfltCovariancePattern =cell (R ,1 ); 

dfltCovariancePattern (1 :R )=...
    {classreg .regr .lmeutils .covmats .CovarianceMatrix .TYPE_FULLCHOLESKY }; 



dfltFitMethod ='mpl' ; 



dfltWeights =ones (N ,1 ); 

dfltExclude =false (N ,1 ); 


dfltDummyVarCoding ='reference' ; 


dfltOptimizer ='quasinewton' ; 




dfltOptimizerOptions =[]; 


dfltStartMethod ='default' ; 


dfltVerbose =false ; 


dfltCheckHessian =false ; 


dfltDistribution ='normal' ; 


dfltBinomialSize =ones (N ,1 ); 



dfltLink =[]; 


dfltOffset =zeros (N ,1 ); 


dfltDispersionFlag =false ; 


dfltPLIterations =100 ; 


dfltPLTolerance =1e-8 ; 



dfltMuStart =[]; 


dfltInitPLIterations =10 ; 


dfltEBMethod ='default' ; 



dfltEBOptions =[]; 


dfltCovarianceMethod ='Conditional' ; 


dfltUseSequentialFitting =false ; 


paramNames ={'CovariancePattern' ,'FitMethod' ,'Weights' ,'Exclude' ,'DummyVarCoding' ,'Optimizer' ,'OptimizerOptions' ,'StartMethod' ,'Verbose' ,'CheckHessian' ,'Distribution' ,'BinomialSize' ,'Link' ,'Offset' ,'DispersionFlag' ,'PLIterations' ,'PLTolerance' ,'MuStart' ,'InitPLIterations' ,'EBMethod' ,'EBOptions' ,'CovarianceMethod' ,'UseSequentialFitting' }; 
paramDflts ={dfltCovariancePattern ,dfltFitMethod ,dfltWeights ,dfltExclude ,dfltDummyVarCoding ,dfltOptimizer ,dfltOptimizerOptions ,dfltStartMethod ,dfltVerbose ,dfltCheckHessian ,dfltDistribution ,dfltBinomialSize ,dfltLink ,dfltOffset ,dfltDispersionFlag ,dfltPLIterations ,dfltPLTolerance ,dfltMuStart ,dfltInitPLIterations ,dfltEBMethod ,dfltEBOptions ,dfltCovarianceMethod ,dfltUseSequentialFitting }; 
[covariancepattern ,fitmethod ,weights ,exclude ,dummyvarcoding ,optimizer ,optimizeroptions ,startmethod ,verbose ,checkhessian ,distribution ,binomialsize ,linkSpec ,offset ,dispersionflag ,pliterations ,pltolerance ,mustart ,initpliterations ,ebmethod ,eboptions ,covariancemethod ,usesequentialfitting ,setflag ]=internal .stats .parseArgs (paramNames ,paramDflts ,varargin {:}); 


fitmethod =model .validateFitMethod (fitmethod ); 
distribution =model .validateDistribution (distribution ); 
weights =model .validateWeights (weights ,N ,distribution ); 
exclude =model .validateExclude (exclude ,N ); 
dummyvarcoding =model .validateDummyVarCoding (dummyvarcoding ); 
[optimizer ,optimizeroptions ]...
    =model .validateOptimizerAndOptions (optimizer ,optimizeroptions ); 
startmethod =model .validateStartMethod (startmethod ); 
verbose =model .validateVerbose (verbose ); 
checkhessian =model .validateCheckHessian (checkhessian ); 
binomialsize =model .validateBinomialSize (binomialsize ,N ); 
ifisempty (linkSpec )

linkSpec =model .defaultLink (distribution ); 
end
linkStruct =classreg .regr .lmeutils .StandardGeneralizedLinearMixedModel .validateLink (linkSpec ,fitmethod ); 
offset =model .validateOffset (offset ,N ); 
dispersionflag =model .validateDispersionFlag (dispersionflag ); 
pliterations =model .validatePLIterations (pliterations ); 
pltolerance =model .validatePLTolerance (pltolerance ); 
mustart =model .validateMuStart (mustart ,distribution ,N ); 
initpliterations =model .validateInitPLIterations (initpliterations ); 
[ebmethod ,eboptions ]=model .validateEBParameters (ebmethod ,eboptions ); 
covariancemethod =model .validateCovarianceMethod (covariancemethod ); 
usesequentialfitting =model .validateUseSequentialFitting (usesequentialfitting ); 



showploptimizerdisplay =false ; 
if(setflag .Verbose ==true )


switchverbose 
case 0 
optimizeroptions .Display ='off' ; 
showploptimizerdisplay =false ; 
case 1 
optimizeroptions .Display ='iter' ; 
showploptimizerdisplay =false ; 
case 2 
optimizeroptions .Display ='iter' ; 
showploptimizerdisplay =true ; 
end
end









model .FitMethod =fitmethod ; 
model .DummyVarCoding =dummyvarcoding ; 
model .Optimizer =optimizer ; 
model .OptimizerOptions =optimizeroptions ; 
model .StartMethod =startmethod ; 
model .CheckHessian =checkhessian ; 
model .Distribution =distribution ; 
model .BinomialSize =binomialsize ; 
model .Link =linkStruct ; 
model .Offset =offset ; 
model .DispersionFlag =dispersionflag ; 
model .PLIterations =pliterations ; 
model .PLTolerance =pltolerance ; 
model .MuStart =mustart ; 
model .InitPLIterations =initpliterations ; 
model .EBMethod =ebmethod ; 
model .EBOptions =eboptions ; 
model .CovarianceMethod =covariancemethod ; 
model .UseSequentialFitting =usesequentialfitting ; 
model .ShowPLOptimizerDisplay =showploptimizerdisplay ; 




model .PredictorTypes ='mixed' ; 
model =assignData (model ,ds ,[],weights ,[],...
    model .Formula .VariableNames ,exclude ); 




model =selectVariables (model ); 
model =selectObservations (model ,exclude ); 





subset =model .ObservationInfo .Subset ; 
ifall (subset ==false )
error (message ('stats:LinearMixedModel:NoUsableObservations' )); 
end
dssubset =ds (subset ,:); 
model .y =extractResponse (model ,dssubset ); 
model .FixedInfo =extractFixedInfo (model ,dssubset ); 
model .RandomInfo =extractRandomInfo (model ,dssubset ); 
model .GroupingInfo =extractGroupingInfo (model ,dssubset ); 
clear ('dssubset' ); 

model .BinomialSize =model .BinomialSize (subset ); 
model .Offset =model .Offset (subset ); 
if~isempty (model .MuStart )
model .MuStart =model .MuStart (subset ); 
end



ifstrcmpi (distribution ,'binomial' )
model .y =model .y ./model .BinomialSize ; 
end



covariancepattern =GeneralizedLinearMixedModel .validateCovariancePattern ...
    (covariancepattern ,R ,model .RandomInfo .q ); 


if(setflag .CovariancePattern ==false )
fork =1 :R 
ifmodel .RandomInfo .q (k )==1 
covariancepattern {k }=classreg .regr .lmeutils .covmats .CovarianceMatrix .TYPE_ISOTROPIC ; 
end
end
end
model .CovariancePattern =covariancepattern ; 







model =doFit (model ); 


model =updateVarRange (model ); 

end

end


methods (Access ='public' )

function [D ,gnames ]=designMatrix (model ,designtype ,gnumbers )






























































ifnargin <2 
[D ,gnames ]=designMatrix @classreg .regr .LinearLikeMixedModel (model ); 
elseifnargin <3 
[D ,gnames ]=designMatrix @classreg .regr .LinearLikeMixedModel (model ,designtype ); 
else
[D ,gnames ]=designMatrix @classreg .regr .LinearLikeMixedModel (model ,designtype ,gnumbers ); 
end

end

function [beta ,betanames ,fetable ]=fixedEffects (model ,varargin )
























































switchnargout 
case {0 ,1 }
beta =fixedEffects @classreg .regr .LinearLikeMixedModel (model ,varargin {:}); 
case 2 
[beta ,betanames ]=fixedEffects @classreg .regr .LinearLikeMixedModel (model ,varargin {:}); 
case 3 
[beta ,betanames ,fetable ]=fixedEffects @classreg .regr .LinearLikeMixedModel (model ,varargin {:}); 
end

end

function [b ,bnames ,retable ]=randomEffects (model ,varargin )






















































































switchnargout 
case {0 ,1 }
b =randomEffects @classreg .regr .LinearLikeMixedModel (model ,varargin {:}); 
case 2 
[b ,bnames ]=randomEffects @classreg .regr .LinearLikeMixedModel (model ,varargin {:}); 
case 3 
[b ,bnames ,retable ]=randomEffects @classreg .regr .LinearLikeMixedModel (model ,varargin {:}); 
end

end

function [PSI ,mse ,covtable ]=covarianceParameters (model ,varargin )




















































switchnargout 
case {0 ,1 }
PSI =covarianceParameters @classreg .regr .LinearLikeMixedModel (model ,varargin {:}); 
case 2 
[PSI ,mse ]=covarianceParameters @classreg .regr .LinearLikeMixedModel (model ,varargin {:}); 
case 3 
[PSI ,mse ,covtable ]=covarianceParameters @classreg .regr .LinearLikeMixedModel (model ,varargin {:}); 
end

end

function yfit =fitted (model ,varargin )





























[varargin {:}]=convertStringsToChars (varargin {:}); 

dfltConditional =true ; 


paramNames ={'Conditional' }; 
paramDflts ={dfltConditional }; 


wantconditional =internal .stats .parseArgs (paramNames ,paramDflts ,varargin {:}); 


wantconditional =model .validateConditional (wantconditional ); 


yr =fitted (model .slme ,wantconditional ); 



subset =model .ObservationInfo .Subset ; 
yfit =NaN (length (subset ),1 ); 
yfit (subset )=yr ; 

end

function res =residuals (model ,varargin )

















































[varargin {:}]=convertStringsToChars (varargin {:}); 

dfltConditional =true ; 
dfltResidualType ='Raw' ; 


paramNames ={'Conditional' ,'ResidualType' }; 
paramDflts ={dfltConditional ,dfltResidualType }; 


[wantconditional ,residualtype ]...
    =internal .stats .parseArgs (paramNames ,paramDflts ,varargin {:}); 


wantconditional =model .validateConditional (wantconditional ); 
residualtype =model .validateResidualType (residualtype ); 


r =residuals (model .slme ,wantconditional ,residualtype ); 


subset =model .ObservationInfo .Subset ; 
res =NaN (length (subset ),1 ); 
res (subset )=r ; 

end

function table =compare (model ,altmodel ,varargin )








































































[varargin {:}]=convertStringsToChars (varargin {:}); 

model =model .validateObjectClass (model ,'GLME' ,'GeneralizedLinearMixedModel' ); 
altmodel =model .validateObjectClass (altmodel ,'ALTGLME' ,'GeneralizedLinearMixedModel' ); 


dfltCheckNesting =false ; 


paramNames ={'CheckNesting' }; 
paramDflts ={dfltCheckNesting }; 


checknesting =internal .stats .parseArgs (paramNames ,paramDflts ,varargin {:}); 


checknesting =model .validateCheckNesting (checknesting ); 


modelName =inputname (1 ); 
altmodelName =inputname (2 ); 
ifisempty (modelName )||isempty (altmodelName )
modelName ='GLME' ; 
altmodelName ='ALTGLME' ; 
end


















DF_model =getTotalNumberOfParameters (model ); 
DF_altmodel =getTotalNumberOfParameters (altmodel ); 
if(DF_altmodel <DF_model &&altmodel .LogLikelihood <=model .LogLikelihood )

warning (message ('stats:GeneralizedLinearMixedModel:NestingCheck_modelswap' ,modelName ,altmodelName )); 


temp_model =model ; 
model =altmodel ; 
altmodel =temp_model ; 
clear temp_model ; 


temp_modelName =modelName ; 
modelName =altmodelName ; 
altmodelName =temp_modelName ; 
clear temp_modelName ; 
end



logliksmall =model .LogLikelihood ; 
loglikbig =altmodel .LogLikelihood ; 
assertThat (loglikbig >=logliksmall ,'stats:GeneralizedLinearMixedModel:NestingCheck_loglik' ,altmodelName ,modelName ); 




if(checknesting ==true )
model .checkNestingRequirement (model ,altmodel ,modelName ,altmodelName ); 
end

table =model .standardLRT (model ,altmodel ,modelName ,altmodelName ); 

end

function hout =plotResiduals (model ,plottype ,varargin )














































ifnargin <2 

args ={}; 
elseifnargin <3 

args ={plottype }; 
else

args =[{plottype },varargin ]; 
end


switchnargout 
case 0 
plotResiduals @classreg .regr .LinearLikeMixedModel (model ,args {:}); 
case 1 
hout =plotResiduals @classreg .regr .LinearLikeMixedModel (model ,args {:}); 
end

end

function stats =anova (model ,varargin )



















































stats =anova @classreg .regr .LinearLikeMixedModel (model ,varargin {:}); 

end

function [Y ,binomsize ]=response (model )













subset =model .ObservationInfo .Subset ; 



N =length (subset ); 
Y =NaN (N ,1 ); 
Y (subset )=model .y ; 


ifnargout >1 
ifstrcmpi (model .Distribution ,'binomial' )
binomsize =NaN (N ,1 ); 
binomsize (subset )=model .BinomialSize ; 
else
binomsize =[]; 
end
end

end

function model =refit (model ,ynew )



















subset =model .ObservationInfo .Subset ; 
N =length (subset ); 


distribution =model .Distribution ; 


ynew =model .validateYNew (ynew ,N ,subset ); 




ifstrcmpi (distribution ,'binomial' )
ynew =ynew .*model .ObservationInfo .BinomSize ; 
end
ds =model .Variables ; 
ds .(model .ResponseName )=ynew ; 




weights =model .ObservationInfo .Weights ; 
exclude =model .ObservationInfo .Excluded ; 
model .PredictorTypes ='mixed' ; 
model =assignData (model ,ds ,[],weights ,[],...
    model .Formula .VariableNames ,exclude ); 




model =selectVariables (model ); 
model =selectObservations (model ,exclude ); 


ifall (subset ==false )
error (message ('stats:GeneralizedLinearMixedModel:NoUsableObservations' )); 
end
dssubset =ds (subset ,:); 
model .y =extractResponse (model ,dssubset ); 
clear ('dssubset' ); 



ifstrcmpi (distribution ,'binomial' )
model .y =model .y ./model .BinomialSize ; 
end







model =doFit (model ); 


model =updateVarRange (model ); 

end

end

end


function assertThat (condition ,msgID ,varargin )





if~condition 

try
msg =message (msgID ,varargin {:}); 
catch 

error (message ('stats:LinearMixedModel:BadMsgID' ,msgID )); 
end

ME =MException (msg .Identifier ,getString (msg )); 
throwAsCaller (ME ); 
end

end

