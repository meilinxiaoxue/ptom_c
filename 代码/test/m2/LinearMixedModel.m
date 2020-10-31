classdef (Sealed =true )LinearMixedModel <classreg .regr .LinearLikeMixedModel 























































properties (Dependent ,GetAccess ='public' ,SetAccess ='protected' ,Hidden =true )










Fitted 














Residuals 
end


properties (GetAccess ='public' ,SetAccess ='protected' )






FitMethod 









MSE 
end


properties (GetAccess ='public' ,SetAccess ='protected' ,Hidden =true )

Response 
end


properties (Constant =true ,Hidden =true )

AllowedFitMethods ={'ML' ,'REML' }; 

AllowedDFMethods ={'None' ,'Residual' ,'Satterthwaite' }; 

AllowedResidualTypes ={'Raw' ,'Pearson' ,'Standardized' }; 

AllowedOptimizers ={'fminunc' ,'quasinewton' }; 

AllowedStartMethods ={'random' ,'default' }; 

end


properties (Access ={?classreg .regr .LinearLikeMixedModel })
















XYZGNames 





CovariancePattern 


DummyVarCoding 


Optimizer 


OptimizerOptions 


StartMethod 


CheckHessian 




CovarianceTable 
end


methods (Access ='public' ,Hidden =true )

function t =title (model )
strLHS =model .ResponseName ; 
strFunArgs =internal .stats .strCollapse (model .Formula .PredictorNames ,',' ); 
t =sprintf ('%s = lme(%s)' ,strLHS ,strFunArgs ); 
end

function val =feval (model ,varargin )%#ok<INUSD> 
warning (message ('stats:LinearMixedModel:NoFevalMethod' )); 
val =[]; 
end

end


methods (Access ='public' )

function disp (model )






ifisempty (model .ObservationInfo )
displayFormula (model ); 
error (message ('stats:LinearMixedModel:NoConstructor' )); 
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

function [ypred ,yci ,df ]=predict (model ,varargin )




























































































[varargin {:}]=convertStringsToChars (varargin {:}); 
ifnargin <2 ||internal .stats .isString (varargin {1 })



haveDataset =true ; 
ds =model .Variables ; 
X =[]; 
Z =[]; 
G =[]; 
otherArgs =varargin ; 
else


[haveDataset ,ds ,X ,Z ,G ,otherArgs ]...
    =LinearMixedModel .handleDatasetOrMatrixInput (varargin {:}); 
end



dfltConditional =true ; 
dfltSimultaneous =false ; 
dfltPrediction ='curve' ; 
dfltDFMethod ='Residual' ; 
dfltAlpha =0.05 ; 


paramNames ={'Conditional' ,'Simultaneous' ,'Prediction' ,'DFMethod' ,'Alpha' }; 
paramDflts ={dfltConditional ,dfltSimultaneous ,dfltPrediction ,dfltDFMethod ,dfltAlpha }; 


[conditional ,simultaneous ,prediction ,dfmethod ,alpha ]...
    =internal .stats .parseArgs (paramNames ,paramDflts ,otherArgs {:}); 


conditional =LinearMixedModel .validateConditional (conditional ); 
simultaneous =LinearMixedModel .validateSimultaneous (simultaneous ); 
prediction =LinearMixedModel .validatePrediction (prediction ); 
dfmethod =LinearMixedModel .validateDFMethod (dfmethod ); 
alpha =LinearMixedModel .validateAlpha (alpha ); 


p =size (model .FixedInfo .X ,2 ); 
q =model .RandomInfo .q ; 
R =model .GroupingInfo .R ; 
lev =model .GroupingInfo .lev ; 
ifhaveDataset 
M =size (ds ,1 ); 
else
M =size (X ,1 ); 
end



ifhaveDataset ==true 

predNames =model .PredictorNames ; 
varNames =model .Variables .Properties .VariableNames ; 
[~,predLocs ]=ismember (predNames ,varNames ); 
dsref =model .Variables (:,predLocs ); 
ds =LinearMixedModel .validateDataset (ds ,'DS' ,dsref ); 
else


[X ,Z ,G ]=LinearMixedModel .validateXZG (X ,Z ,G ,'X' ,'Z' ,'G' ); 

X =LinearMixedModel .validateMatrix (X ,'X' ,[],p ); 

Z =LinearMixedModel .validateCellVector (Z ,'Z' ,R ); 
fork =1 :R 
ZNamek =['Z{' ,num2str (k ),'}' ]; 
Z {k }=LinearMixedModel .validateMatrix (Z {k },ZNamek ,M ,q (k )); 
end

G =LinearMixedModel .validateCellVector (G ,'G' ,R ); 
fork =1 :R 
GNamek =['G{' ,num2str (k ),'}' ]; 
G {k }=LinearMixedModel .validateGroupingVar (G {k },GNamek ,M ); 
end








fepredictors =model .XYZGNames .XNames ; 
respvar =model .XYZGNames .YName ; 
repredictors =model .XYZGNames .ZNames ; 
regroups =model .XYZGNames .GNames ; 


Y =NaN (M ,1 ); 


[ds ,~]=LinearMixedModel .convertXYZGToDataset (X ,Y ,Z ,G ,fepredictors ,respvar ,repredictors ,regroups ); 
ds .(respvar )=[]; 
end



finfo =extractFixedInfo (model ,ds ); 
X =finfo .X ; 

rinfo =extractRandomInfo (model ,ds ); 
Z =rinfo .Z ; 



ginfo =extractGroupingInfo (model ,ds ); 
Gid =ginfo .Gid ; 
GidLevelNames =ginfo .GidLevelNames ; 







newGid =cell (R ,1 ); 
fork =1 :R 
newGid {k }=LinearMixedModel .reorderGroupIDs (Gid {k },...
    GidLevelNames {k },model .GroupingInfo .GidLevelNames {k }); 
end




Zs =LinearMixedModel .makeSparseZ (Z ,q ,lev ,newGid ,M ); 





wantConditional =conditional ; 
ifsimultaneous ==true 
wantPointwise =false ; 
else
wantPointwise =true ; 
end
ifstrcmpi (prediction ,'curve' )
wantCurve =true ; 
else
wantCurve =false ; 
end

hasIntercept =model .Formula .FELinearFormula .HasIntercept ; 
args ={X ,Zs ,alpha ,dfmethod ,...
    wantConditional ,wantPointwise ,wantCurve ,hasIntercept }; 
switchnargout 
case {0 ,1 }
ypred =predict (model .slme ,args {:}); 
case 2 
[ypred ,yci ]=predict (model .slme ,args {:}); 
case 3 
[ypred ,yci ,df ]=predict (model .slme ,args {:}); 

ifany (df ==0 )&&strcmpi (dfmethod ,'Satterthwaite' )
warning (message ('stats:LinearMixedModel:BadSatterthwaiteDF' )); 
end
end



end

function ynew =random (model ,varargin )














































ifnargin <2 

ysim =random (model .slme ,[],model .slme .X ,model .slme .Z ); 
w =getCombinedWeights (model ,true ); 
ysim =ysim ./sqrt (w ); 


subset =model .ObservationInfo .Subset ; 
ynew =NaN (length (subset ),1 ); 
ynew (subset )=ysim ; 

return ; 
end



[haveDataset ,ds ,X ,Z ,G ,otherArgs ]...
    =LinearMixedModel .handleDatasetOrMatrixInput (varargin {:}); %#ok<NASGU> 


p =size (model .FixedInfo .X ,2 ); 
q =model .RandomInfo .q ; 
R =model .GroupingInfo .R ; 
ifhaveDataset 
M =size (ds ,1 ); 
else
M =size (X ,1 ); 
end



ifhaveDataset ==true 

predNames =model .PredictorNames ; 
varNames =model .Variables .Properties .VariableNames ; 
[~,predLocs ]=ismember (predNames ,varNames ); 
dsref =model .Variables (:,predLocs ); 
ds =LinearMixedModel .validateDataset (ds ,'DS' ,dsref ); 
else


[X ,Z ,G ]=LinearMixedModel .validateXZG (X ,Z ,G ,'X' ,'Z' ,'G' ); 

X =LinearMixedModel .validateMatrix (X ,'X' ,[],p ); 

Z =LinearMixedModel .validateCellVector (Z ,'Z' ,R ); 
fork =1 :R 
ZNamek =['Z{' ,num2str (k ),'}' ]; 
Z {k }=LinearMixedModel .validateMatrix (Z {k },ZNamek ,M ,q (k )); 
end

G =LinearMixedModel .validateCellVector (G ,'G' ,R ); 
fork =1 :R 
GNamek =['G{' ,num2str (k ),'}' ]; 
G {k }=LinearMixedModel .validateGroupingVar (G {k },GNamek ,M ); 
end








fepredictors =model .XYZGNames .XNames ; 
respvar =model .XYZGNames .YName ; 
repredictors =model .XYZGNames .ZNames ; 
regroups =model .XYZGNames .GNames ; 


Y =NaN (M ,1 ); 



[ds ,~]=LinearMixedModel .convertXYZGToDataset (X ,Y ,Z ,G ,fepredictors ,respvar ,repredictors ,regroups ); 
ds .(respvar )=[]; 
end



finfo =extractFixedInfo (model ,ds ); 
X =finfo .X ; 

rinfo =extractRandomInfo (model ,ds ); 
Z =rinfo .Z ; 








ginfo =extractGroupingInfo (model ,ds ); 
Gid =ginfo .Gid ; 
lev =ginfo .lev ; 




Zs =LinearMixedModel .makeSparseZ (Z ,q ,lev ,Gid ,M ); 


ifisempty (lev )
bsim =zeros (0 ,1 ); 
else
bsim =randomb (model .slme ,[],lev ); 
end


epsilonsim =model .slme .sigmaHat *randn (M ,1 ); 


ifisempty (bsim )
ynew =X *model .slme .betaHat +epsilonsim ; 
else
ynew =X *model .slme .betaHat +Zs *bsim +epsilonsim ; 
end

end

end


methods (Access ='public' ,Hidden =true )

function v =varianceParam (model )
v =model .MSE ; 
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




w =model .ObservationInfo .Weights ; 
subset =model .ObservationInfo .Subset ; 
w =w (subset ); 
L =model .slme .loglikHat +0.5 *sum (log (w )); 

end

function L0 =logLikelihoodNull (model )%#ok<MANU> 

L0 =NaN ; 

end

end


methods (Access ='protected' )

function model =postFit (model )


model .MSE =model .slme .sigmaHat ^2 ; 
model .Response =response (model ); 




model .LogLikelihood =getlogLikelihood (model ); 
model .LogLikelihoodNull =logLikelihoodNull (model ); 


[model .SSE ,model .SSR ,model .SST ]=getSumOfSquares (model ); 


model .CoefficientNames =getCoefficientNames (model ); 


[~,~,model .CovarianceTable ]=covarianceParameters (model ); 




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
Standardized =residuals (model ,'ResidualType' ,'standardized' ); 


r =table (Raw ,Pearson ,Standardized ,...
    'RowNames' ,model .ObservationNames ); 
else

residualtype ...
    =LinearMixedModel .validateResidualType (residualtype ); 


switchlower (residualtype )
case 'raw' 
r =residuals (model ,'ResidualType' ,'raw' ); 
case 'pearson' 
r =residuals (model ,'ResidualType' ,'pearson' ); 
case 'standardized' 
r =residuals (model ,'ResidualType' ,'standardized' ); 
end
end

end


function yfit =get_fitted (model )


yfit =fitted (model ); 


end

end


methods (Access ='public' ,Hidden =true )

function lme =LinearMixedModel (varargin )




st =dbstack ; 
isokcaller =false ; 
if(length (st )>=2 )
isokcaller =any (strcmpi (st (2 ).name ,{'LinearMixedModel.fit' ,'LinearMixedModel.fitmatrix' })); 
end
if(nargin ==0 &&isokcaller ==true )
lme .Formula =classreg .regr .LinearMixedFormula ('y ~ -1' ); 
return ; 
end
error (message ('stats:LinearMixedModel:NoConstructor' )); 
end

end


methods (Access ='private' )

function displayHeadLine (model )


isLoose =strcmp (get (0 ,'FormatSpacing' ),'loose' ); 
if(isLoose ),fprintf ('\n' ); end
headline =getString (message ('stats:LinearMixedModel:Display_headline' ,model .FitMethod )); 
headline =LinearMixedModel .formatBold (headline ); 
fprintf ('%s\n' ,headline ); 
fprintf ('\n' ); 

end

function displayFormula (model )


formulaheadline =getString (message ('stats:LinearMixedModel:Display_formula' )); 
formulaheadline =LinearMixedModel .formatBold (formulaheadline ); 
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


modelfitstatsheadline =getString (message ('stats:LinearMixedModel:Display_modelfitstats' )); 
modelfitstatsheadline =LinearMixedModel .formatBold (modelfitstatsheadline ); 
fprintf ('%s\n' ,modelfitstatsheadline ); 
crittable =modelCriterionLME (model ); 
crittable =LinearMixedModel .removeTitle (crittable ); 
disp (crittable ); 

end

function displayFixedStats (model )


fixedstatsheadline =getString (message ('stats:LinearMixedModel:Display_fixedstats' )); 
fixedstatsheadline =LinearMixedModel .formatBold (fixedstatsheadline ); 
fprintf ('%s\n' ,fixedstatsheadline ); 
ds =model .Coefficients ; 
ds =LinearMixedModel .removeTitle (ds ); 
disp (ds ); 

end

function displayCovarianceStats (model )


covariancestatsheadline =getString (message ('stats:LinearMixedModel:Display_covariancestats' )); 
covariancestatsheadline =LinearMixedModel .formatBold (covariancestatsheadline ); 
fprintf ('%s\n' ,covariancestatsheadline ); 


R =model .GroupingInfo .R ; 




lev =model .GroupingInfo .lev ; 
fork =1 :(R +1 )

ifk >R 
gname =getString (message ('stats:LinearMixedModel:String_error' )); 
fprintf ('%s\n' ,[getString (message ('stats:LinearMixedModel:String_group' )),': ' ,gname ]); 
else
gname =model .GroupingInfo .GNames {k }; 
fprintf ('%s\n' ,[getString (message ('stats:LinearMixedModel:String_group' )),': ' ,gname ,' (' ,num2str (lev (k )),' ' ,getString (message ('stats:LinearMixedModel:String_levels' )),')' ]); 
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
ds =LinearMixedModel .removeTitle (ds ); 
disp (ds ); 
end

end

function displayModelInfo (model )


modelinfoheadline =getString (message ('stats:LinearMixedModel:Display_modelinfo' )); 
modelinfoheadline =LinearMixedModel .formatBold (modelinfoheadline ); 
fprintf ('%s\n' ,modelinfoheadline ); 


N =model .slme .N ; 


p =model .slme .p ; 


q =model .slme .q ; 


ncov =model .slme .Psi .NumParametersExcludingSigma +1 ; 


indent ='    ' ; 
fprintf ('%-35s %6d\n' ,[indent ,getString (message ('stats:LinearMixedModel:ModelInfo_numobs' ))],N ); 
fprintf ('%-35s %6d\n' ,[indent ,getString (message ('stats:LinearMixedModel:ModelInfo_fecoef' ))],p ); 
fprintf ('%-35s %6d\n' ,[indent ,getString (message ('stats:LinearMixedModel:ModelInfo_recoef' ))],q ); 
fprintf ('%-35s %6d\n' ,[indent ,getString (message ('stats:LinearMixedModel:ModelInfo_covpar' ))],ncov ); 
fprintf ('\n' ); 

end

end


methods (Access ={?classreg .regr .LinearLikeMixedModel })

function crittable =modelCriterionLME (model )


















N =model .slme .N ; 
p =model .slme .p ; 


stats .NumCoefficients =...
    model .slme .Psi .NumParametersExcludingSigma +(p +1 ); 


switchlower (model .FitMethod )
case {'ml' }
stats .NumObservations =N ; 
case {'reml' }
stats .NumObservations =(N -p ); 
otherwise
error (message ('stats:LinearMixedModel:BadFitMethod' )); 
end




stats .LogLikelihood =model .LogLikelihood ; 


crit =classreg .regr .modelutils .modelcriterion (stats ,'all' ,true ); 


Deviance =-2 *stats .LogLikelihood ; 
crittable =table (crit .AIC ,crit .BIC ,stats .LogLikelihood ,Deviance ,...
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
Zs =LinearMixedModel .makeSparseZ (Z ,q ,lev ,Gid ,N ); 
Psi =makeCovarianceMatrix (model ); 




reduce =true ; 
w =getCombinedWeights (model ,reduce ); 
Xw =LinearMixedModel .scaleMatrixUsingWeights (model .FixedInfo .X ,w ); 
yw =LinearMixedModel .scaleMatrixUsingWeights (model .y ,w ); 
Zsw =LinearMixedModel .scaleMatrixUsingWeights (Zs ,w ); 


dofit =true ; 
dostats =true ; 
slme =classreg .regr .lmeutils .StandardLinearMixedModel (Xw ,yw ,Zsw ,Psi ,model .FitMethod ,...
    dofit ,dostats ,'Optimizer' ,model .Optimizer ,...
    'OptimizerOptions' ,model .OptimizerOptions ,...
    'InitializationMethod' ,model .StartMethod ,...
    'CheckHessian' ,model .CheckHessian ); 

end

function [SSE ,SSR ,SST ]=getSumOfSquares (model )

























F =fitted (model ); 


Y =response (model ); 


w =model .ObservationInfo .Weights ; 


subset =model .ObservationInfo .Subset ; 


F =F (subset ); 
Y =Y (subset ); 
w =w (subset ); 


Y_mean_w =sum (w .*Y )/sum (w ); 



SSE =sum (w .*((Y -F ).^2 )); 



SSR =sum (w .*((F -Y_mean_w ).^2 )); 


SST =SSE +SSR ; 


end

function coefnames =getCoefficientNames (model )






coefnames =model .FixedInfo .XColNames ; 

end

function np =getTotalNumberOfParameters (model )






numfixpar =model .slme .p ; 


numcovpar =model .slme .Psi .NumParametersExcludingSigma ; 


np =numfixpar +numcovpar +1 ; 

end

function ysim =randomForSLRT (model ,S )









slmeObj =model .slme ; 




ysim =random (slmeObj ,S ,slmeObj .X ,slmeObj .Z ); 
reduce =true ; 
w =getCombinedWeights (model ,reduce ); 
ysim =ysim ./sqrt (w ); 

end

function loglik =doFitFunForSLRT (model ,ysim )










reduce =true ; 
w =getCombinedWeights (model ,reduce ); 
yw =LinearMixedModel .scaleMatrixUsingWeights (ysim ,w ); 


slmeObj =model .slme ; 


slmeObj .y =yw ; 


slmeObj =refit (slmeObj ); 



loglik =slmeObj .loglikHat +0.5 *sum (log (w )); 

end

end


methods (Static ,Access ='private' )

function [X ,XColNames ,XCols2Terms ]=designFromFormula (F ,ds ,dummyvarcoding )










[X ,~,~,XCols2Terms ,XColNames ]=...
    classreg .regr .modelutils .designmatrix (ds ,'Model' ,F .Terms ,...
    'PredictorVars' ,F .PredictorNames ,'ResponseVar' ,F .ResponseName ,...
    'DummyVarCoding' ,dummyvarcoding ); 










end

function Xw =scaleMatrixUsingWeights (X ,w )






assert (isnumeric (X )&isreal (X )&ismatrix (X )); 


N =size (X ,1 ); 


w =LinearMixedModel .validateWeights (w ,N ); 


ifall (w ==1 )
Xw =X ; 
else
Xw =bsxfun (@times ,X ,sqrt (w )); 
end

end

function [ds ,formula ]=convertXYZGToDataset (X ,Y ,Z ,G ,XNames ,YName ,ZNames ,GNames )



















ds =table (); 


ds =LinearMixedModel .addColumnsToDataset (ds ,X ,XNames ); 


ds =LinearMixedModel .addColumnsToDataset (ds ,Y ,{YName }); 


R =length (Z ); 
fork =1 :R 
ds =LinearMixedModel .addColumnsToDataset (ds ,Z {k },ZNames {k }); 
end


fork =1 :length (G )
if~ismember (GNames {k },ds .Properties .VariableNames )
ds .(GNames {k })=G {k }; 
end
end


formula =YName ; 


fespec =LinearMixedModel .getFixedRandomSpec (XNames ,[],false ); 
formula =[formula ,' ~ ' ,fespec ]; 


fork =1 :R 
respec =LinearMixedModel .getFixedRandomSpec (ZNames {k },...
    GNames {k },false ); 
formula =[formula ,' + ' ,respec ]; %#ok<AGROW> 
end

end

function ds =addColumnsToDataset (ds ,X ,XNames )









p =size (X ,2 ); 
fork =1 :p 


if~ismember (XNames {k },ds .Properties .VariableNames )
ds .(XNames {k })=X (:,k ); 
end
end

end

function spec =getFixedRandomSpec (varnames ,gname ,wantintercept )



















switchnargin 
case 1 

gname =[]; 
wantintercept =false ; 
case 2 

wantintercept =false ; 
end


ifwantintercept ==true 
spec ='1' ; 
else
spec ='-1' ; 
end


p =length (varnames ); 
fork =1 :p 
spec =[spec ,' + ' ,varnames {k }]; %#ok<AGROW> 
end


if~isempty (gname )
spec =['(' ,spec ,' | ' ,gname ,')' ]; 
end

end

function [lrt ,siminfo ]=simulatedLRT (smallModel ,bigModel ,smallModelName ,bigModelName ,nsim ,alpha ,options )





















[useParallel ,RNGscheme ]...
    =internal .stats .parallel .processParallelAndStreamOptions (options ,true ); 



smallModel .slme =turnOffOptimizerDisplay (smallModel .slme ); 
bigModel .slme =turnOffOptimizerDisplay (bigModel .slme ); 


loopbody =LinearMixedModel .makeloopbodyFunSLRT (smallModel ,bigModel ); 


TH0 ...
    =internal .stats .parallel .smartForSliceout (nsim ,loopbody ,useParallel ,RNGscheme ); 


T =2 *(bigModel .LogLikelihood -smallModel .LogLikelihood ); 




[pvalueSim ,pvalueSimCI ]...
    =binofit (1 +sum (TH0 >=T ),1 +nsim ,alpha ); 


lrt =LinearMixedModel .standardLRT (smallModel ,bigModel ,...
    smallModelName ,bigModelName ); 






lrt .deltaDF =[]; 



pValue =zeros (2 ,1 ); 
pValue (1 )=0 ; 
pValue (2 )=pvalueSim ; 
pValueAbsent =[true ; false ]; 
lrt .pValue =internal .stats .DoubleTableColumn (pValue ,pValueAbsent ); 


Lower =zeros (2 ,1 ); 
Lower (1 )=0 ; 
Lower (2 )=pvalueSimCI (1 ); 
LowerAbsent =[true ; false ]; 
lrt .Lower ...
    =internal .stats .DoubleTableColumn (Lower ,LowerAbsent ); 

Upper =zeros (2 ,1 ); 
Upper (1 )=0 ; 
Upper (2 )=pvalueSimCI (2 ); 
UpperAbsent =[true ; false ]; 
lrt .Upper ...
    =internal .stats .DoubleTableColumn (Upper ,UpperAbsent ); 


ttl =getString (message ('stats:LinearMixedModel:Title_SLRT' ,num2str (nsim ),num2str (alpha ))); 
lrt =classreg .regr .lmeutils .titleddataset (lrt ,ttl ); 



siminfo .nsim =nsim ; 

siminfo .alpha =alpha ; 

siminfo .pvalueSim =pvalueSim ; 

siminfo .pvalueSimCI =pvalueSimCI ; 


DF =lrt .DF ; 
siminfo .deltaDF =DF (2 )-DF (1 ); 


siminfo .TH0 =TH0 ; 

end

function fun =makeloopbodyFunSLRT (smallModel ,bigModel )



fun =@loopbodyFun ; 

function TH0 =loopbodyFun (~,S )


ysim =randomForSLRT (smallModel ,S ); 


loglik1 =doFitFunForSLRT (smallModel ,ysim ); 
loglik2 =doFitFunForSLRT (bigModel ,ysim ); 
TH0 =2 *(loglik2 -loglik1 ); 

end

end

end

methods (Static ,Access ='protected' )

function checkNestingRequirement (smallModel ,bigModel ,smallModelName ,bigModelName ,isSimulatedTest )

















































assert (isa (smallModel ,'LinearMixedModel' )); 
assert (isa (bigModel ,'LinearMixedModel' )); 


assert (internal .stats .isString (smallModelName )); 
assert (internal .stats .isString (bigModelName )); 


assert (isscalar (isSimulatedTest )&islogical (isSimulatedTest )); 



fitmethodsmall =smallModel .FitMethod ; 
fitmethodbig =bigModel .FitMethod ; 
assertThat (isequal (fitmethodsmall ,fitmethodbig ),'stats:LinearMixedModel:NestingCheck_fitmethod' ,smallModelName ,bigModelName ); 



ysmall =smallModel .y ; 
ybig =bigModel .y ; 
assertThat (isequaln (ysmall ,ybig ),'stats:LinearMixedModel:NestingCheck_response' ,smallModelName ,bigModelName ); 


Xsmall =smallModel .FixedInfo .X ; 
Xbig =bigModel .FixedInfo .X ; 



ifstrcmpi (smallModel .FitMethod ,'reml' )
assertThat (isequaln (Xsmall ,Xbig ),'stats:LinearMixedModel:NestingCheck_spanX' ,smallModelName ,bigModelName ); 
end



logliksmall =smallModel .LogLikelihood ; 
loglikbig =bigModel .LogLikelihood ; 
assertThat (loglikbig >=logliksmall ,'stats:LinearMixedModel:NestingCheck_loglik' ,bigModelName ,smallModelName ); 

ifisSimulatedTest ==false 




wsmall =getCombinedWeights (smallModel ,true ); 
wbig =getCombinedWeights (bigModel ,true ); 
assertThat (isequaln (wsmall ,wbig ),'stats:LinearMixedModel:NestingCheck_weights' ,smallModelName ,bigModelName ); 

ifstrcmpi (smallModel .FitMethod ,'ml' )

assertThat (LinearMixedModel .isMatrixNested (Xsmall ,Xbig ),'stats:LinearMixedModel:NestingCheck_nestedspanX' ,smallModelName ,bigModelName ); 
end


Zsmall =smallModel .slme .Z ; 
Zbig =bigModel .slme .Z ; 
assertThat (LinearMixedModel .isMatrixNested (Zsmall ,Zbig ),'stats:LinearMixedModel:NestingCheck_nestedspanZ' ,smallModelName ,bigModelName ); 
end

end

end


methods (Static ,Access ='protected' )

function fitmethod =validateFitMethod (fitmethod )











fitmethod =internal .stats .getParamVal (fitmethod ,...
    LinearMixedModel .AllowedFitMethods ,'FitMethod' ); 

end

function w =validateWeights (w ,N )














assert (N >=0 &internal .stats .isScalarInt (N )); 



assertThat (isnumeric (w )&isreal (w )&isvector (w )&length (w )==N ,'stats:LinearMixedModel:BadWeights' ,num2str (N )); 
assertThat (all (~isnan (w )&w >=0 &w <Inf ),'stats:LinearMixedModel:BadWeights' ,num2str (N )); 


ifsize (w ,1 )==1 
w =w ' ; 
end

end

function options =validateOptions (options )












assertThat (isstruct (options ),'stats:LinearMixedModel:MustBeStruct' ); 

end

function [optimizer ,optimizeroptions ]=...
    validateOptimizerAndOptions (optimizer ,optimizeroptions )

























optimizer =internal .stats .getParamVal (optimizer ,...
    LinearMixedModel .AllowedOptimizers ,'Optimizer' ); 


switchlower (optimizer )
case 'quasinewton' 


case {'fminunc' }

if(license ('test' ,'optimization_toolbox' )==false )
error (message ('stats:LinearMixedModel:LicenseCheck_fminunc' )); 
end
end









switchlower (optimizer )
case 'quasinewton' 


assertThat (isempty (optimizeroptions )||isstruct (optimizeroptions ),'stats:LinearMixedModel:OptimizerOptions_qn' ); 


dflts =statset ('linearmixedmodel' ); 
ifisempty (optimizeroptions )
optimizeroptions =dflts ; 
else
optimizeroptions =statset (dflts ,optimizeroptions ); 
end

case {'fminunc' }


assertThat (isempty (optimizeroptions )||isa (optimizeroptions ,'optim.options.SolverOptions' ),'stats:LinearMixedModel:OptimizerOptions_fminunc' ); 


ifisempty (optimizeroptions )
optimizeroptions =optimoptions ('fminunc' ); 
optimizeroptions .Algorithm ='quasi-newton' ; 
else
optimizeroptions =optimoptions ('fminunc' ,optimizeroptions ); 
end
end

end

function startmethod =validateStartMethod (startmethod )












startmethod =...
    internal .stats .getParamVal (startmethod ,LinearMixedModel .AllowedStartMethods ,'StartMethod' ); 

end

function dfmethod =validateDFMethod (dfmethod )










dfmethod =internal .stats .getParamVal (dfmethod ,...
    LinearMixedModel .AllowedDFMethods ,'DFMethod' ); 

end

function residualtype =validateResidualType (residualtype )












residualtype =internal .stats .getParamVal (residualtype ,...
    LinearMixedModel .AllowedResidualTypes ,'ResidualType' ); 

end

function prediction =validatePrediction (prediction )












prediction =internal .stats .getParamVal (prediction ,...
    {'curve' ,'observation' },'Prediction' ); 

end

function [X ,Z ,G ]=validateXZG (X ,Z ,G ,XName ,ZName ,GName )
























X =LinearMixedModel .validateMatrix (X ,XName ); 
N =size (X ,1 ); 


ifisempty (Z )
Z =zeros (N ,0 ); 
end



if~iscell (Z )
Z ={Z }; 
end
ifsize (Z ,1 )==1 
Z =Z ' ; 
end
Z =LinearMixedModel .validateCellVector (Z ,'Z' ); 
R =size (Z ,1 ); 
fork =1 :R 
ZNamek =[ZName ,'{' ,num2str (k ),'}' ]; 
Z {k }=LinearMixedModel .validateMatrix (Z {k },ZNamek ,N ); 
end



ifisempty (G )
G =cell (R ,1 ); 
G (1 :R )={ones (N ,1 )}; 
end




if~iscell (G )
G ={G }; 
end
ifsize (G ,1 )==1 
G =G ' ; 
end
G =LinearMixedModel .validateCellVector (G ,'G' ); 
assertThat (length (G )==R ,'stats:LinearMixedModel:MustBeCellArraysOfSameLength' ,ZName ,GName ); 
fork =1 :R 
GNamek =[GName ,'{' ,num2str (k ),'}' ]; 
G {k }=LinearMixedModel .validateGroupingVar (G {k },GNamek ,N ); 
end

end

function [X ,Y ,Z ,G ]=validateXYZG (X ,Y ,Z ,G ,XName ,YName ,ZName ,GName )




























X =LinearMixedModel .validateMatrix (X ,XName ); 
N =size (X ,1 ); 




Y =LinearMixedModel .validateMatrix (Y ,YName ); 
ifsize (Y ,1 )==1 
Y =Y ' ; 
end
Y =LinearMixedModel .validateMatrix (Y ,YName ,N ,1 ); 


ifisempty (Z )
Z =zeros (N ,0 ); 
end



if~iscell (Z )
Z ={Z }; 
end
ifsize (Z ,1 )==1 
Z =Z ' ; 
end
Z =LinearMixedModel .validateCellVector (Z ,'Z' ); 
R =size (Z ,1 ); 
fork =1 :R 
ZNamek =[ZName ,'{' ,num2str (k ),'}' ]; 
Z {k }=LinearMixedModel .validateMatrix (Z {k },ZNamek ,N ); 
end



ifisempty (G )
G =cell (R ,1 ); 
G (1 :R )={ones (N ,1 )}; 
end




if~iscell (G )
G ={G }; 
end
ifsize (G ,1 )==1 
G =G ' ; 
end
G =LinearMixedModel .validateCellVector (G ,'G' ); 
assertThat (length (G )==R ,'stats:LinearMixedModel:MustBeCellArraysOfSameLength' ,ZName ,GName ); 
fork =1 :R 
GNamek =[GName ,'{' ,num2str (k ),'}' ]; 
G {k }=LinearMixedModel .validateGroupingVar (G {k },GNamek ,N ); 
end

end

function Nsim =validateNsim (Nsim )














ifisempty (Nsim )
Nsim =0 ; 
end


assertThat (internal .stats .isScalarInt (Nsim ,0 ,Inf ),'stats:LinearMixedModel:MustBeNonNegativeInteger' ,'Nsim' ); 

end

function verbose =validateVerbose (verbose )











verbose =...
    LinearMixedModel .validateLogicalScalar (verbose ,'stats:LinearMixedModel:BadVerbose' ); 

end

function checkhessian =validateCheckHessian (checkhessian )











checkhessian =...
    LinearMixedModel .validateLogicalScalar (checkhessian ,'stats:LinearMixedModel:BadCheckHessian' ); 

end

end


methods (Static ,Access ='public' ,Hidden =true )

function model =fit (ds ,formula ,varargin )





ifisa (ds ,'dataset' )
ds =dataset2table (ds ); 
end


assertThat (isa (ds ,'table' ),'stats:LinearMixedModel:Fit_firstinput' ); 

assertThat (internal .stats .isString (formula ),'stats:LinearMixedModel:Fit_secondinput' ); 
formula =convertStringsToChars (formula ); 
[varargin {:}]=convertStringsToChars (varargin {:}); 


model =LinearMixedModel (); 


model .Formula =classreg .regr .LinearMixedFormula (formula ,ds .Properties .VariableNames ); 


R =length (model .Formula .RELinearFormula ); 
N =size (ds ,1 ); 




dfltCovariancePattern =cell (R ,1 ); 

dfltCovariancePattern (1 :R )=...
    {classreg .regr .lmeutils .covmats .CovarianceMatrix .TYPE_FULLCHOLESKY }; 



dfltFitMethod ='ML' ; 



dfltWeights =ones (N ,1 ); 

dfltExclude =false (N ,1 ); 


dfltDummyVarCoding ='reference' ; 


dfltOptimizer ='quasinewton' ; 




dfltOptimizerOptions =[]; 


dfltStartMethod ='default' ; 


dfltVerbose =false ; 


dfltCheckHessian =false ; 


paramNames ={'CovariancePattern' ,'FitMethod' ,'Weights' ,'Exclude' ,'DummyVarCoding' ,'Optimizer' ,'OptimizerOptions' ,'StartMethod' ,'Verbose' ,'CheckHessian' }; 
paramDflts ={dfltCovariancePattern ,dfltFitMethod ,dfltWeights ,dfltExclude ,dfltDummyVarCoding ,dfltOptimizer ,dfltOptimizerOptions ,dfltStartMethod ,dfltVerbose ,dfltCheckHessian }; 
[covariancepattern ,fitmethod ,weights ,exclude ,dummyvarcoding ,optimizer ,optimizeroptions ,startmethod ,verbose ,checkhessian ,setflag ]=internal .stats .parseArgs (paramNames ,paramDflts ,varargin {:}); 


fitmethod =LinearMixedModel .validateFitMethod (fitmethod ); 
weights =LinearMixedModel .validateWeights (weights ,N ); 
exclude =LinearMixedModel .validateExclude (exclude ,N ); 
dummyvarcoding =LinearMixedModel .validateDummyVarCoding (dummyvarcoding ); 
[optimizer ,optimizeroptions ]...
    =LinearMixedModel .validateOptimizerAndOptions (optimizer ,optimizeroptions ); 
startmethod =LinearMixedModel .validateStartMethod (startmethod ); 
verbose =LinearMixedModel .validateVerbose (verbose ); 
checkhessian =LinearMixedModel .validateCheckHessian (checkhessian ); 


if(setflag .Verbose ==true )

if(verbose ==true )
optimizeroptions .Display ='iter' ; 
else
optimizeroptions .Display ='off' ; 
end
end











model .FitMethod =fitmethod ; 
model .DummyVarCoding =dummyvarcoding ; 
model .Optimizer =optimizer ; 
model .OptimizerOptions =optimizeroptions ; 
model .StartMethod =startmethod ; 
model .CheckHessian =checkhessian ; 




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



covariancepattern =LinearMixedModel .validateCovariancePattern ...
    (covariancepattern ,R ,model .RandomInfo .q ); 


model .CovariancePattern =covariancepattern ; 







model =doFit (model ); 


model =updateVarRange (model ); 

end

function model =fitmatrix (X ,Y ,Z ,G ,varargin )




[varargin {:}]=convertStringsToChars (varargin {:}); 

[X ,Y ,Z ,G ]=LinearMixedModel .validateXYZG (X ,Y ,Z ,G ,'X' ,'Y' ,'Z' ,'G' ); 


p =size (X ,2 ); 
R =length (Z ); 
q =zeros (R ,1 ); 
fork =1 :R 
q (k )=size (Z {k },2 ); 
end



dfltFixedEffectPredictors =internal .stats .numberedNames ('x' ,1 :p ); 

dfltResponseVarName ='y' ; 

dfltRandomEffectPredictors =cell (R ,1 ); 
fork =1 :R 
zk =['z' ,num2str (k )]; 
dfltRandomEffectPredictors {k }=...
    internal .stats .numberedNames (zk ,1 :q (k )); 
end

dfltRandomEffectGroups =internal .stats .numberedNames ('g' ,1 :R ); 


paramNames ={'FixedEffectPredictors' ,...
    'RandomEffectPredictors' ,...
    'ResponseVarName' ,...
    'RandomEffectGroups' }; 
paramDflts ={dfltFixedEffectPredictors ,...
    dfltRandomEffectPredictors ,...
    dfltResponseVarName ,...
    dfltRandomEffectGroups }; 
[fepredictors ,repredictors ,respvar ,regroups ,~,otherArgs ]=...
    internal .stats .parseArgs (paramNames ,paramDflts ,varargin {:}); 



fepredictors =...
    LinearMixedModel .validateCellVectorOfStrings (fepredictors ,...
    'FixedEffectPredictors' ,p ,true ); 

respvar =...
    LinearMixedModel .validateString (respvar ,'ResponseVarName' ); 



repredictors =...
    LinearMixedModel .validateCellVector (repredictors ,...
    'RandomEffectPredictors' ,R ); 
fork =1 :R 
repredictorskname =...
    getString (message ('stats:LinearMixedModel:String_repredictors_k' ,num2str (k ))); 
repredictors {k }...
    =LinearMixedModel .validateCellVectorOfStrings (...
    repredictors {k },repredictorskname ,q (k ),true ); 
end

regroups =...
    LinearMixedModel .validateCellVectorOfStrings (regroups ,...
    'RandomEffectGroups' ,R ,false ); 




[ds ,formula ]=LinearMixedModel .convertXYZGToDataset (X ,Y ,Z ,G ,...
    fepredictors ,respvar ,repredictors ,regroups ); 



model =LinearMixedModel .fit (ds ,formula ,otherArgs {:}); 


model .XYZGNames .XNames =fepredictors ; 
model .XYZGNames .YName =respvar ; 
model .XYZGNames .ZNames =repredictors ; 
model .XYZGNames .GNames =regroups ; 

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


wantconditional =...
    internal .stats .parseArgs (paramNames ,paramDflts ,varargin {:}); 


wantconditional ...
    =LinearMixedModel .validateConditional (wantconditional ); 


yr =fitted (model .slme ,wantconditional ); 




reduce =true ; 
w =getCombinedWeights (model ,reduce ); 

yr =yr ./sqrt (w ); 



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


wantconditional ...
    =LinearMixedModel .validateConditional (wantconditional ); 
residualtype =LinearMixedModel .validateResidualType (residualtype ); 


r =residuals (model .slme ,wantconditional ,residualtype ); 





ifstrcmpi (residualtype ,'Raw' )

reduce =true ; 
w =getCombinedWeights (model ,reduce ); 

r =r ./sqrt (w ); 
end


subset =model .ObservationInfo .Subset ; 
res =NaN (length (subset ),1 ); 
res (subset )=r ; 

end

function [table ,siminfo ]=compare (model ,altmodel ,varargin )







































































































































































[varargin {:}]=convertStringsToChars (varargin {:}); 

model =LinearMixedModel .validateObjectClass (model ,...
    'LME' ,'LinearMixedModel' ); 
altmodel =LinearMixedModel .validateObjectClass (altmodel ,...
    'ALTLME' ,'LinearMixedModel' ); 


dfltNsim =0 ; 
dfltAlpha =0.05 ; 
dfltOptions =statset ('UseParallel' ,false ); 
dfltCheckNesting =false ; 


paramNames ={'Nsim' ,'Alpha' ,'Options' ,'CheckNesting' }; 
paramDflts ={dfltNsim ,dfltAlpha ,dfltOptions ,dfltCheckNesting }; 


[nsim ,alpha ,options ,checknesting ]...
    =internal .stats .parseArgs (paramNames ,paramDflts ,varargin {:}); 


nsim =LinearMixedModel .validateNsim (nsim ); 
alpha =LinearMixedModel .validateAlpha (alpha ); 
options =LinearMixedModel .validateOptions (options ); 
checknesting =...
    LinearMixedModel .validateCheckNesting (checknesting ); 



options =statset (dfltOptions ,options ); 


modelName =inputname (1 ); 
altmodelName =inputname (2 ); 
ifisempty (modelName )||isempty (altmodelName )
modelName ='LME' ; 
altmodelName ='ALTLME' ; 
end


if(nsim ==0 )




if(checknesting ==true )
isSimulatedTest =false ; 
LinearMixedModel .checkNestingRequirement (model ,altmodel ,...
    modelName ,altmodelName ,isSimulatedTest ); 
end


table =LinearMixedModel .standardLRT (model ,altmodel ,...
    modelName ,altmodelName ); 


siminfo =[]; 

else



if(checknesting ==true )
isSimulatedTest =true ; 
LinearMixedModel .checkNestingRequirement (model ,altmodel ,...
    modelName ,altmodelName ,isSimulatedTest ); 
end


[table ,siminfo ]=LinearMixedModel .simulatedLRT (model ,...
    altmodel ,modelName ,altmodelName ,nsim ,alpha ,options ); 

end

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

function Y =response (model )







subset =model .ObservationInfo .Subset ; 



N =length (subset ); 
Y =NaN (N ,1 ); 
Y (subset )=model .y ; 

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

