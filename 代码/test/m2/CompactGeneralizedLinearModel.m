classdef (AllowedSubclasses ={?GeneralizedLinearModel ,})...
    CompactGeneralizedLinearModel <classreg .regr .CompactTermsRegression 











































properties (GetAccess ='public' ,SetAccess ='protected' )















Dispersion =0 ; 








DispersionEstimated =false ; 














Deviance =NaN ; 

end
properties (GetAccess ='protected' ,SetAccess ='protected' )
DistributionName ='normal' ; 
DevianceNull =NaN ; 
PrivateLogLikelihood =[]; 
end
properties (Dependent ,GetAccess ='public' ,SetAccess ='protected' )


















Distribution 














Link 
end

methods 
function D =get .Distribution (model )
name =model .DistributionName ; 
[devFun ,varFun ]=getDistributionFunctions (name ); 
D .Name =name ; 
D .DevianceFunction =devFun ; 
D .VarianceFunction =varFun ; 
end
function link =get .Link (model )
[linkFun ,dlinkFun ,ilinkFun ]=dfswitchyard ('stattestlink' ,model .Formula .Link ,class (model .Coefs )); 
ifinternal .stats .isString (model .Formula .Link )
link .Name =model .Formula .Link ; 
elseifisnumeric (model .Formula .Link )
link .Name =sprintf ('%g' ,model .Formula .Link ); 
else
link .Name ='' ; 
end
link .Link =linkFun ; 
link .Derivative =dlinkFun ; 
link .Inverse =ilinkFun ; 
end









end

methods (Hidden =true ,Access ='public' )
function model =CompactGeneralizedLinearModel (varargin )
ifnargin ==0 
model .Formula =classreg .regr .LinearFormula ; 
return 
end
error (message ('stats:GeneralizedLinearModel:NoConstructor' )); 
end



function isVirtual =isVariableEditorVirtualProp (~,~)




isVirtual =false ; 
end
end
methods (Static ,Access ='public' ,Hidden )
function model =make (s )
model =classreg .regr .CompactGeneralizedLinearModel (); 
ifisa (s ,'struct' )


fn =fieldnames (s ); 
elseifisa (s ,'classreg.regr.CompactGeneralizedLinearModel' )

meta =?classreg .regr .CompactGeneralizedLinearModel ; 
props =meta .PropertyList ; 
props ([props .Dependent ]|[props .Constant ])=[]; 
fn ={props .Name }; 
end
forj =1 :length (fn )
name =fn {j }; 
model .(name )=s .(name ); 
end
model .LogLikelihood =s .PrivateLogLikelihood ; 
end
end
methods (Access ='public' )


function disp (model )




isLoose =strcmp (get (0 ,'FormatSpacing' ),'loose' ); 
if(isLoose ),fprintf ('\n' ); end
fprintf (getString (message ('stats:GeneralizedLinearModel:display_CompactGLM' ))); 

dispBody (model )
end


function [varargout ]=predict (model ,Xpred ,varargin )












































[varargin {:}]=convertStringsToChars (varargin {:}); 
ifisa (Xpred ,'tall' )
[varargout {1 :max (1 ,nargout )}]=hSlicefun (@model .predict ,Xpred ,varargin {:}); 
return 
end

design =designMatrix (model ,Xpred ); 
offset =0 ; 

paramNames ={'BinomialSize' ,'Confidence' ,'Simultaneous' ,'Alpha' ,'Offset' }; 
paramDflts ={[],.95 ,false ,0.05 ,offset }; 
[Npred ,conf ,simOpt ,alpha ,offset ,supplied ]=...
    internal .stats .parseArgs (paramNames ,paramDflts ,varargin {:}); 
ifsupplied .Confidence &&supplied .Alpha 
error (message ('stats:GeneralizedLinearModel:PredictArgCombination' ,'Confidence' ,'Alpha' ))
end
ifsupplied .Alpha 
conf =1 -alpha ; 
end

ifsupplied .BinomialSize &&~isempty (Npred )&&~strcmpi (model .DistributionName ,'Binomial' )
error (message ('stats:GeneralizedLinearModel:NotBinomial' )); 
end
ifstrcmpi (model .DistributionName ,'binomial' )
ifsupplied .BinomialSize 
binomSizePV ={'Size' ,Npred }; 
else
binomSizePV ={'Size' ,ones (size (design ,1 ),1 )}; 
end
else
binomSizePV ={}; 
end

ifnargout <2 
ypred =glmval (model .Coefs ,design ,model .Formula .Link ,'Constant' ,'off' ,'Offset' ,offset ,binomSizePV {:}); 
varargout ={ypred }; 
else
[R ,sigma ]=corrcov (model .CoefficientCovariance ); 
stats =struct ('se' ,sigma ,'coeffcorr' ,R ,...
    'dfe' ,model .DFE ,'s' ,model .Dispersion ,'estdisp' ,model .DispersionEstimated ); 
[ypred ,dylo ,dyhi ]=...
    glmval (model .Coefs ,design ,model .Formula .Link ,stats ,'Constant' ,'off' ,...
    'Confidence' ,conf ,binomSizePV {:},'simul' ,simOpt ,'Offset' ,offset ); 
yCI =[ypred -dylo ,ypred +dyhi ]; 
varargout ={ypred ,yCI }; 
end
end


function ysim =random (model ,ds ,varargin )













































[varargin {:}]=convertStringsToChars (varargin {:}); 

paramNames ={'BinomialSize' ,'Offset' }; 
paramDflts ={1 ,0 }; 
[N ,offset ,supplied ]=...
    internal .stats .parseArgs (paramNames ,paramDflts ,varargin {:}); 
varargin ={'Offset' ,offset }; 
ifsupplied .BinomialSize &&~isequal (N ,1 )
varargin (end+1 :end+2 )={'BinomialSize' ,1 }; 
end
ifstrcmpi (model .DistributionName ,'binomial' )

ifisempty (N )
N =1 ; 
elseif~isscalar (N )&&numel (N )~=size (ds ,1 )
error (message ('stats:GeneralizedLinearModel:RandomNSize' ,size (ds ,1 )))
end
end
ypred =predict (model ,ds ,varargin {:}); 
switchlower (model .DistributionName )
case 'binomial' 
ifany (strcmpi (model .VariableInfo .Class {model .RespLoc },{'nominal' ,'ordinal' ,'categorical' }))

ifN ~=1 
error (message ('stats:GeneralizedLinearModel:BadBinomialSize' ))
else
a =model .VariableInfo .Range (model .RespLoc ); 
b =a {:}; 
y =binornd (N ,ypred ); 
y1 (y ==0 )=b (1 ,1 ); 
y1 (y ==1 )=b (1 ,2 ); 
y1 =y1 ' ; 
ysim =y1 ; 
end
else
ysim =binornd (N ,ypred ); 
end

case 'gamma' 
ysim =gamrnd (1 ./model .Dispersion ,ypred .*model .Dispersion ); 
case 'inverse gaussian' 
ysim =random ('inversegaussian' ,ypred ,1 ./model .Dispersion ); 
case 'normal' 
ysim =normrnd (ypred ,sqrt (model .Dispersion )); 
case 'poisson' 
ysim =poissrnd (ypred ); 
end
end


function tbl =devianceTest (model )
















dev =[model .DevianceNull ; model .Deviance ]; 
dfe =[model .NumObservations -1 ; model .DFE ]; 
dfr =model .NumEstimatedCoefficients -1 ; 

ifmodel .DispersionEstimated 
statName ='FStat' ; 
stat =max (0 ,-diff (dev ))./(dfr *model .Dispersion ); 
p =fcdf (1 ./stat ,dfe (2 ),dfr ); 
else
statName ='chi2Stat' ; 
stat =max (0 ,-diff (dev )); 
p =gammainc (stat /2 ,dfr /2 ,'upper' ); 
end

if~hasConstantModelNested (model )
warning (message ('stats:GeneralizedLinearModel:NoIntercept' )); 
end

f0 =model .Formula ; f0 .Terms =zeros (1 ,model .NumVariables ); 
tbl =table (dev ,...
    dfe ,...
    internal .stats .DoubleTableColumn ([NaN ; stat ],[true ; false ]),...
    internal .stats .DoubleTableColumn ([NaN ; p ],[true ; false ]),...
    'VariableNames' ,{'Deviance' ,'DFE' ,statName ,'pValue' },...
    'RowNames' ,{char (f0 ,40 ),char (model .Formula ,40 )}); 
tbl .Properties .DimensionNames ={'Fits' ,'Variables' }; 
end

function fout =plotSlice (model )











f =classreg .regr .modelutils .plotSlice (model ); 



h1 =findobj (f ,'Tag' ,'boundsCurve' ); 
h2 =findobj (f ,'Tag' ,'boundsObservation' ); 
set ([h1 ,h2 ],'Enable' ,'off' ); 

ifnargout >0 
fout =f ; 
end
end
end

methods (Hidden =true )

function t =title (model )
strLHS =linkstr (model .Formula .Link ,model .ResponseName ); 
strFunArgs =internal .stats .strCollapse (model .Formula .PredictorNames ,',' ); 
t =sprintf ('%s = glm(%s)' ,strLHS ,strFunArgs ); 
end

function v =varianceParam (model )
v =model .Dispersion ; 
end

function s =toStruct (this )


warnState =warning ('query' ,'all' ); 
warning ('off' ,'MATLAB:structOnObject' ); 
cleanupObj =onCleanup (@()warning (warnState )); 


s =struct ; 
meta =?classreg .regr .CompactGeneralizedLinearModel ; 
props =meta .PropertyList ; 
props ([props .Dependent ]|[props .Constant ])=[]; 


propsToExclude ={'VariableInfo' ,'Formula' ,'CoefficientNames' }; 
fn ={props .Name }; 
forj =1 :length (fn )
name =fn {j }; 
if~ismember (name ,propsToExclude )
s .(name )=this .(name ); 
end
end
s .LogLikelihood =this .PrivateLogLikelihood ; 

s =classreg .regr .coderutils .regrToStruct (s ,this ); 
s .FromStructFcn ='classreg.regr.CompactGeneralizedLinearModel.fromStruct' ; 
end
end
methods (Static ,Hidden )
function obj =fromStruct (s )


s =classreg .regr .coderutils .structToRegr (s ); 
obj =classreg .regr .CompactGeneralizedLinearModel .make (s ); 

end
end
methods (Access ='protected' )
function dispBody (model )

indent ='    ' ; 
maxWidth =matlab .desktop .commandwindow .size ; maxWidth =maxWidth (1 )-1 ; 
f =model .Formula ; 
ifstrcmpi (model .DistributionName ,'Binomial' )&&...
    any (strcmpi (model .VariableInfo .Class {model .RespLoc },{'nominal' ,'ordinal' ,'categorical' }))
a =model .VariableInfo .Range (model .RespLoc ); 
b =a {:}; 
y =char (b (1 ,2 )); 
responseName =['P(' ,model .ResponseName ,'=''' ,y ,''')' ]; 
respstr =linkstr (model .Formula .Link ,responseName ); 
fstr =[respstr ,' ~ ' ,model .Formula .LinearPredictor ]; 
else
fstr =char (f ,maxWidth -length (indent )); 
end
disp ([indent ,fstr ]); 
fprintf ('%s' ,getString (message ('stats:GeneralizedLinearModel:display_Distribution' ,indent ,model .DistributionName ))); 

ifmodel .IsFitFromData 
fprintf ('%s' ,getString (message ('stats:GeneralizedLinearModel:display_EstimatedCoefficients' ))); 
disp (model .Coefficients ); 
fprintf ('%s' ,getString (message ('stats:GeneralizedLinearModel:display_NumObsDFE' ,model .NumObservations ,model .DFE ))); 
ifmodel .DispersionEstimated 
fprintf ('%s' ,getString (message ('stats:GeneralizedLinearModel:display_EstimatedDispersion' ,num2str (model .Dispersion ,'%.3g' )))); 
else
fprintf ('%s' ,getString (message ('stats:GeneralizedLinearModel:display_Dispersion' ,num2str (model .Dispersion ,'%.3g' )))); 
end
ifhasConstantModelNested (model )&&model .NumPredictors >0 
d =devianceTest (model ); 
ifmodel .DispersionEstimated 
fprintf ('%s' ,getString (message ('stats:GeneralizedLinearModel:display_FTest' ,num2str (d .FStat (2 ),'%.3g' ),num2str (d .pValue (2 ),'%.3g' )))); 
else
fprintf ('%s' ,getString (message ('stats:GeneralizedLinearModel:display_ChiTest' ,num2str (d .chi2Stat (2 ),'%.3g' ),num2str (d .pValue (2 ),'%.3g' )))); 
end
end
else
fprintf ('%s' ,getString (message ('stats:GeneralizedLinearModel:display_Coefficients' ))); 
ifany (model .Coefficients .SE >0 )
disp (model .Coefficients (:,{'Value' ,'SE' })); 
else
disp (model .Coefficients (:,{'Value' })); 
end
ifmodel .Dispersion >0 
fprintf ('\n%s' ,getString (message ('stats:GeneralizedLinearModel:display_Dispersion' ,num2str (model .Dispersion ,'%.3g' )))); 
end
end
end

function L =getlogLikelihood (model )
L =model .PrivateLogLikelihood ; 
end

function tbl =tstats (model )
ifmodel .DispersionEstimated 
nobs =model .NumObservations ; 
else
nobs =Inf ; 
end
tbl =classreg .regr .modelutils .tstats (model .Coefs ,sqrt (diag (model .CoefficientCovariance )),...
    nobs ,model .CoefficientNames ); 
end








function ypred =predictPredictorMatrix (model ,Xpred )

design =designMatrix (model ,Xpred ,true ); 
ypred =glmval (model .Coefs ,design ,model .Formula .Link ,'Constant' ,'off' ); 
end



function crit =get_rsquared (model ,type )
stats =struct ('SSE' ,model .SSE ,...
    'SST' ,model .SST ,...
    'DFE' ,model .DFE ,...
    'NumObservations' ,model .NumObservations ,...
    'LogLikelihood' ,model .LogLikelihood ,...
    'LogLikelihoodNull' ,model .LogLikelihoodNull ,...
    'Deviance' ,model .Deviance ,...
    'DevianceNull' ,model .DevianceNull ); 
ifnargin <2 
crit =classreg .regr .modelutils .rsquared (stats ,'all' ,true ); 
else
crit =classreg .regr .modelutils .rsquared (stats ,type ); 
end
end
end


methods (Access =private ,Static )
function name =matlabCodegenRedirect (~)
name ='classreg.regr.coder.CompactGeneralizedLinearModel' ; 
end
end


end



function str =linkstr (link ,responseName )
switchlower (link )
case 'identity' ,str =sprintf ('%s' ,responseName ); 
case {'inverse' ,'reciprocal' },str =sprintf ('1/%s' ,responseName ); 
case 'log' ,str =sprintf ('log(%s)' ,responseName ); 
case 'logit' ,str =sprintf ('logit(%s)' ,responseName ); 
case 'probit' ,str =sprintf ('probit(%s)' ,responseName ); 
case 'loglog' ,str =sprintf ('log(-log(%s))' ,responseName ); 
case 'comploglog' ,str =sprintf ('log(-log(1-%s))' ,responseName ); 
otherwise
ifisnumeric (link )
str =sprintf ('(%s)^%d' ,responseName ,link ); 
else
str =sprintf ('CustomLink(%s)' ,responseName ); 
end
end
end




function [devFun ,varFun ]=getDistributionFunctions (name )
switchlower (name )
case 'normal' 
devFun =@(mu ,y )(y -mu ).^2 ; 
varFun =@(mu )ones (size (mu ),class (mu )); 
case 'binomial' 
devFun =@(mu ,y ,N )2 *N .*(y .*log ((y +(y ==0 ))./mu )+(1 -y ).*log ((1 -y +(y ==1 ))./(1 -mu ))); 
varFun =@(mu ,N )mu .*(1 -mu )./N ; 
case 'poisson' 
devFun =@(mu ,y )2 *(y .*(log ((y +(y ==0 ))./mu ))-(y -mu )); 
varFun =@(mu )mu ; 
case 'gamma' 
devFun =@(mu ,y )2 *(-log (y ./mu )+(y -mu )./mu ); 
varFun =@(mu )mu .^2 ; 
case 'inverse gaussian' 
devFun =@(mu ,y )((y -mu )./mu ).^2 ./y ; 
varFun =@(mu )mu .^3 ; 
end
end
