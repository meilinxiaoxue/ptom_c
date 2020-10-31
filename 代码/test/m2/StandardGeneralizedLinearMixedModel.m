classdef StandardGeneralizedLinearMixedModel <classreg .regr .lmeutils .StandardLinearLikeMixedModel 









































































































































properties (GetAccess =public ,SetAccess =public )

y 


X 


Z 




Psi 









FitMethod 
end


properties (GetAccess =public ,SetAccess =protected )


Distribution 







Link 


Offset 



BinomialSize 



PriorWeights 




DispersionFixed 







VarianceFunction 
end


properties (GetAccess =public ,SetAccess =protected )

N 


p 


q 


rankX 
end


properties (GetAccess =public ,SetAccess =protected )

Optimizer ='fminsearch' ; 


OptimizerOptions =struct ([]); 




CheckHessian =false ; 




PLIterations 



PLTolerance 













MuStart 


















MuBound =struct ('TINY' ,eps ,'BIG' ,Inf ); 



InitPLIterations 









EBMethod 















EBOptions 











CovarianceMethod 








UseSequentialFitting 
end


properties (GetAccess =public ,SetAccess =public )


InitializationMethod ='default' ; 
end


properties (GetAccess =public ,SetAccess =protected )


slme 
end


properties (GetAccess =public ,SetAccess =protected )

betaHat 


bHat 


DeltabHat 


sigmaHat 


thetaHat 


phiHat 


loglikHat 




loglikHatPseudoData 
end


properties (GetAccess =public ,SetAccess =protected )

covbetaHat 


covthetaHatlogsigmaHat 



covetaHatlogsigmaHat 


covbetaHatbHat 
end


properties (GetAccess =public ,SetAccess =protected )

isSigmaFixed =false ; 


sigmaFixed =NaN ; 
end


properties (GetAccess =public ,SetAccess =protected )

isFitToData =false ; 


isReadyForStats =false ; 
end


properties (GetAccess =public ,SetAccess =protected )





UseAMDPreordering 



AMDOrder 








NewtonStepMethod 
end


properties (Access =private )







NewtonStepMethodCode 
end


properties (Access =private )




HaveWarnedAboutBadlyScaledPLWeights =false ; 
end


properties (Access =private )


ShowPLOptimizerDisplay =false ; 
end


properties (Constant =true ,Hidden =true )

AllowedFitMethods ={'mpl' ,'rempl' ,'approximatelaplace' ,'laplace' ,'quadrature' }; 


AllowedDistributions ={'normal' ,'gaussian' ,'binomial' ,'poisson' ,'gamma' ,'inversegaussian' ,'inverse gaussian' }; 


AllowedLinks ={'identity' ,'log' ,'logit' ,'probit' ,'comploglog' ,'loglog' ,'reciprocal' }; 



AllowedEBMethods ={'Default' ,'LineSearchNewton' ,'LineSearchModifiedNewton' ,'TrustRegion2D' ,'fsolve' }; 



AllowedCovarianceMethods ={'Conditional' ,'JointHessian' }; 



AllowedNewtonStepMethods ={'Cholesky' ,'Backslash' }; 
end


methods 

function sglme =set .y (sglme ,newy )

if~isempty (sglme .y )

newy =validatey (sglme ,newy ); 


sglme =invalidateFit (sglme ); 
end


sglme .y =newy ; 

end

function sglme =set .X (sglme ,newX )

if~isempty (sglme .X )

newX =validateX (sglme ,newX ); 


sglme =invalidateFit (sglme ); 
end


sglme .X =newX ; 

end

function sglme =set .Z (sglme ,newZ )

if~isempty (sglme .Z )

newZ =validateZ (sglme ,newZ ); 


sglme =invalidateFit (sglme ); 
end


sglme .Z =newZ ; 

end

function sglme =set .Psi (sglme ,newPsi )

if~isempty (sglme .Psi )

newPsi =validatePsi (sglme ,newPsi ); 


sglme =invalidateFit (sglme ); 
end


sglme .Psi =newPsi ; 

end

function sglme =set .FitMethod (sglme ,newFitMethod )

if~isempty (sglme .FitMethod )

newFitMethod =validateFitMethod (sglme ,newFitMethod ); 


sglme =invalidateFit (sglme ); 
end


sglme .FitMethod =newFitMethod ; 

end

end


methods (Access =protected )

function FitMethod =validateFitMethod (sglme ,FitMethod )


FitMethod =internal .stats .getParamVal (FitMethod ,sglme .AllowedFitMethods ,'FitMethod' ); 

end

function offset =validateOffset (sglme ,offset ,N )%#ok<INUSL> 





assert (internal .stats .isScalarInt (N )); 


isok =isnumeric (offset )&isreal (offset )&...
    isvector (offset )&size (offset ,1 )==N ; 
if~isok 
error (message ('stats:classreg:regr:lmeutils:StandardGeneralizedLinearMixedModel:BadOffset' ,N )); 
end

end

function binomialsize =validateBinomialSize (sglme ,binomialsize ,N )%#ok<INUSL> 






assert (internal .stats .isScalarInt (N )); 



isok =internal .stats .isIntegerVals (binomialsize ,1 )&...
    isvector (binomialsize )&size (binomialsize ,1 )==N ; 
if~isok 
error (message ('stats:classreg:regr:lmeutils:StandardGeneralizedLinearMixedModel:BadBinomialSize' ,N )); 
end

end

function weights =validateWeights (sglme ,weights ,N ,distribution )%#ok<INUSL> 







assert (internal .stats .isScalarInt (N )); 


assert (internal .stats .isString (distribution )); 




ifany (strcmpi (distribution ,{'binomial' ,'poisson' }))
isok =internal .stats .isIntegerVals (weights ,1 )&...
    isvector (weights )&size (weights ,1 )==N ; 
else
isok =isnumeric (weights )&isreal (weights )...
    &isvector (weights )&size (weights ,1 )==N ; 
end
if~isok 
error (message ('stats:classreg:regr:lmeutils:StandardGeneralizedLinearMixedModel:BadWeights' ,N ,N )); 
end

end

function validateyRange (sglme ,y ,binomialsize ,weights ,distribution )














assert (iscolumn (y )&isnumeric (y )&isreal (y )); 
N =size (y ,1 ); 


distribution =internal .stats .getParamVal (distribution ,sglme .AllowedDistributions ,'Distribution' ); 


binomialsize =validateBinomialSize (sglme ,binomialsize ,N ); 


weights =validateWeights (sglme ,weights ,N ,distribution ); 


switchlower (distribution )
case 'binomial' 
counts =weights .*binomialsize .*y ; 
isok =all (y >=0 &y <=1 )&max (abs (counts -round (counts )))<=sqrt (eps ); 
if~isok 
error (message ('stats:classreg:regr:lmeutils:StandardGeneralizedLinearMixedModel:BadBinomialY' )); 
end
case 'poisson' 
counts =weights .*y ; 
isok =all (y >=0 )&max (abs (counts -round (counts )))<=sqrt (eps ); 
if~isok 
error (message ('stats:classreg:regr:lmeutils:StandardGeneralizedLinearMixedModel:BadPoissonY' )); 
end
case 'gamma' 
isok =all (y >0 ); 
if~isok 
error (message ('stats:classreg:regr:lmeutils:StandardGeneralizedLinearMixedModel:BadGammaY' )); 
end
case {'inverse gaussian' ,'inversegaussian' }
isok =all (y >0 ); 
if~isok 
error (message ('stats:classreg:regr:lmeutils:StandardGeneralizedLinearMixedModel:BadInverseGaussianY' )); 
end
case {'normal' ,'gaussian' }
end

end

function linkSpec =defaultLink (sglme ,distribution )





distribution =internal .stats .getParamVal (distribution ,sglme .AllowedDistributions ,'Distribution' ); 


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

function varStruct =varianceFunction (sglme ,distribution )














distribution =internal .stats .getParamVal (distribution ,sglme .AllowedDistributions ,'Distribution' ); 


switchlower (distribution )
case {'normal' ,'gaussian' }
varStruct .VarianceFunction =@(mu )ones (size (mu )); 
varStruct .Derivative =@(mu )zeros (size (mu )); 
case 'binomial' 
varStruct .VarianceFunction =@(mu )mu .*(1 -mu ); 
varStruct .Derivative =@(mu )1 -2 *mu ; 
case 'poisson' 
varStruct .VarianceFunction =@(mu )mu ; 
varStruct .Derivative =@(mu )ones (size (mu )); 
case 'gamma' 
varStruct .VarianceFunction =@(mu )mu .^2 ; 
varStruct .Derivative =@(mu )2 *mu ; 
case {'inverse gaussian' ,'inversegaussian' }
varStruct .VarianceFunction =@(mu )mu .^3 ; 
varStruct .Derivative =@(mu )3 *(mu .^2 ); 
end

end

function pliterations =validatePLIterations (sglme ,pliterations )%#ok<INUSL> 




isok =isscalar (pliterations )&...
    internal .stats .isIntegerVals (pliterations ,1 ); 
if~isok 
error (message ('stats:classreg:regr:lmeutils:StandardGeneralizedLinearMixedModel:BadPLIterations' )); 
end

end

function pltolerance =validatePLTolerance (sglme ,pltolerance )%#ok<INUSL> 





isok =isscalar (pltolerance )&...
    isnumeric (pltolerance )&isreal (pltolerance ); 
if~isok 
error (message ('stats:classreg:regr:lmeutils:StandardGeneralizedLinearMixedModel:BadPLTolerance' )); 
end

end

function mustart =validateMuStart (sglme ,mustart ,distribution ,N )















assert (internal .stats .isIntegerVals (N ,1 )&isscalar (N )); 


assert (any (strcmpi (distribution ,sglme .AllowedDistributions ))); 


if~isempty (mustart )
sizeok =isvector (mustart )&(size (mustart ,1 )==N ); 
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
if~isok 
error (message ('stats:classreg:regr:lmeutils:StandardGeneralizedLinearMixedModel:BadMuStart' ,N )); 
end
end

end

function dispersionfixed =setDispersionFixed (sglme ,dispersionflag ,distribution ,fitmethod )























assert (isscalar (dispersionflag )&islogical (dispersionflag )); 
assert (any (strcmpi (distribution ,sglme .AllowedDistributions ))); 
assert (any (strcmpi (fitmethod ,sglme .AllowedFitMethods ))); 


switchlower (distribution )
case {'binomial' ,'poisson' }
dispersionfixed =true ; 
otherwise
dispersionfixed =false ; 
end




estdisp =(dispersionflag ==true )&...
    any (strcmpi (distribution ,{'binomial' ,'poisson' }))...
    &any (strcmpi (fitmethod ,{'mpl' ,'rempl' })); 
ifestdisp ==true 
dispersionfixed =false ; 
end

end

function [ebmethod ,eboptions ]=validateEBParameters (sglme ,ebmethod ,eboptions ,dfltEBOptions )







ebmethod =internal .stats .getParamVal (ebmethod ,sglme .AllowedEBMethods ,'EBMethod' ); 


if~isstruct (eboptions )&&~isa (eboptions ,'optim.options.Fsolve' )
error (message ('stats:classreg:regr:lmeutils:StandardGeneralizedLinearMixedModel:BadEBOptions' )); 
end


ifisstruct (eboptions )&&strcmpi (ebmethod ,'fsolve' )

eboptions =sglme .convertOptionsToFSolveOptions (eboptions ,dfltEBOptions ); 
elseifisstruct (eboptions )&&~strcmpi (ebmethod ,'fsolve' )

eboptions =statset (dfltEBOptions ,eboptions ); 
elseifisa (eboptions ,'optim.options.Fsolve' )&&strcmpi (ebmethod ,'fsolve' )

elseifisa (eboptions ,'optim.options.Fsolve' )&&~strcmpi (ebmethod ,'fsolve' )


error (message ('stats:classreg:regr:lmeutils:StandardGeneralizedLinearMixedModel:BadEBOptions' )); 
else

error (message ('stats:classreg:regr:lmeutils:StandardGeneralizedLinearMixedModel:BadEBOptions' )); 
end

end

function initpliterations =validateInitPLIterations (sglme ,initpliterations )%#ok<INUSL> 




isok =isscalar (initpliterations )&...
    internal .stats .isIntegerVals (initpliterations ,1 ); 
if~isok 
error (message ('stats:classreg:regr:lmeutils:StandardGeneralizedLinearMixedModel:BadInitPLIterations' )); 
end

end

function [mulowerbound ,muupperbound ]=validateMuBounds (sglme ,mulowerbound ,muupperbound )%#ok<INUSL> 






ok =isnumeric (mulowerbound )&isreal (mulowerbound )&isscalar (mulowerbound ); 
ok =ok &(mulowerbound >=0 &mulowerbound <1 ); 
if~ok 
error (message ('stats:classreg:regr:lmeutils:StandardGeneralizedLinearMixedModel:BadMuLowerBound' )); 
end


ok =isnumeric (muupperbound )&isreal (muupperbound )&isscalar (muupperbound ); 
ok =ok &(muupperbound >0 ); 
if~ok 
error (message ('stats:classreg:regr:lmeutils:StandardGeneralizedLinearMixedModel:BadMuUpperBound' )); 
end


ok =mulowerbound <muupperbound ; 
if~ok 
error (message ('stats:classreg:regr:lmeutils:StandardGeneralizedLinearMixedModel:BadMuLowerBound' )); 
end

end

function checkDistributionLinkCombination (sglme ,distribution ,linkStruct )%#ok<INUSL> 


















linkname =linkStruct .Name ; 
ifany (strcmpi (linkname ,{'reciprocal' ,'power' }))
warning (message ('stats:classreg:regr:lmeutils:StandardGeneralizedLinearMixedModel:BadDistLinkCombination1' )); 
end



ifstrcmpi (distribution ,'binomial' )&&any (strcmpi (linkname ,{'identity' ,'log' }))
warning (message ('stats:classreg:regr:lmeutils:StandardGeneralizedLinearMixedModel:BadDistLinkCombination2' )); 
end



ifany (strcmpi (distribution ,{'poisson' ,'gamma' ,'inversegaussian' ,'inverse gaussian' }))&&strcmpi (linkname ,'identity' )
warning (message ('stats:classreg:regr:lmeutils:StandardGeneralizedLinearMixedModel:BadDistLinkCombination3' )); 
end

end

function sglme =checkForBadlyScaledPLWeights (sglme ,sqrtdiagW )














dataClass =class (sqrtdiagW ); 
wtol =max (sqrtdiagW )*eps (dataClass )^(2 /3 ); 
t =(sqrtdiagW <wtol ); 
ifany (t )
t =t &(sqrtdiagW ~=0 ); 
ifany (t )
warned =sglme .HaveWarnedAboutBadlyScaledPLWeights ; 
if~warned 
warning (message ('stats:classreg:regr:lmeutils:StandardGeneralizedLinearMixedModel:BadlyScaledPLWeights' )); 
sglme .HaveWarnedAboutBadlyScaledPLWeights =true ; 
end
end
end

end
end


methods (Static ,Access =public ,Hidden =true )

function linkStruct =validateLink (linkSpec ,fitMethod )




















isastring =internal .stats .isString (linkSpec ); 
isanumber =isnumeric (linkSpec )&isreal (linkSpec )&isscalar (linkSpec ); 
isastruct =isstruct (linkSpec ); 
if~(isanumber ||isastruct ||isastring )
error (message ('stats:classreg:regr:lmeutils:StandardGeneralizedLinearMixedModel:BadLinkSpec' )); 
end


ifisastring 
linkSpec =lower (linkSpec ); 
end


assert (internal .stats .isString (fitMethod )); 



[linkStruct .Link ,linkStruct .Derivative ,linkStruct .Inverse ]=...
    dfswitchyard ('stattestlink' ,linkSpec ,'double' ); 




ifisanumber 
iflinkSpec ==0 
linkName ='log' ; 
else
linkName ='power' ; 
linkExponent =linkSpec ; 
end
elseifisastruct 
linkName ='custom' ; 
elseifisastring 

linkName =linkSpec ; 
end


switchlower (linkName )
case 'identity' 
linkStruct .SecondDerivative =@(mu )zeros (size (mu )); 
linkStruct .Name ='identity' ; 
case 'log' 
linkStruct .SecondDerivative =@(mu )-1 ./(mu .^2 ); 
linkStruct .Name ='log' ; 
case 'logit' 
linkStruct .SecondDerivative =@(mu )(2 *mu -1 )./((mu .*(1 -mu )).^2 ); 
linkStruct .Name ='logit' ; 
case 'probit' 
linkStruct .SecondDerivative =@(mu )norminv (mu )./((normpdf (norminv (mu ))).^2 ); 
linkStruct .Name ='probit' ; 
case 'comploglog' 
linkStruct .SecondDerivative =@(mu )-(1 +log (1 -mu ))./(((1 -mu ).*log (1 -mu )).^2 ); 
linkStruct .Name ='comploglog' ; 
case {'loglog' ,'logloglink' }
linkStruct .SecondDerivative =@(mu )-(1 +log (mu ))./((mu .*log (mu )).^2 ); 
linkStruct .Name ='loglog' ; 
case 'reciprocal' 
linkStruct .SecondDerivative =@(mu )2 ./(mu .^3 ); 
linkStruct .Name ='reciprocal' ; 
case 'power' 
linkStruct .SecondDerivative =@(mu )linkExponent *(linkExponent -1 )*(mu .^(linkExponent -2 )); 
linkStruct .Name ='power' ; 
case 'custom' 


if~any (strcmpi (fitMethod ,{'mpl' ,'rempl' }))


if~isfield (linkSpec ,'SecondDerivative' )
error (message ('stats:classreg:regr:lmeutils:StandardGeneralizedLinearMixedModel:MustSupplySecondDerivativeForML' )); 
end
d2link =linkSpec .SecondDerivative ; 
ifischar (d2link )&&~isempty (which (d2link ))
name =d2link ; d2link =@(mu )feval (name ,mu ); 
elseif~isa (d2link ,'function_handle' )&&~isa (d2link ,'inline' )
error (message ('stats:classreg:regr:lmeutils:StandardGeneralizedLinearMixedModel:BadLinkSpecSecondDerivative' )); 
end
linkStruct .SecondDerivative =d2link ; 
end


ifisfield (linkSpec ,'Name' )
linkStruct .Name =linkSpec .Name ; 
else
linkStruct .Name ='custom' ; 
end

otherwise
error (message ('stats:stattestlink:UnrecognizedLink' )); 
end

end

end


methods (Access =protected )

function weights =getEffectiveObservationWeights (sglme )






ifstrcmpi (sglme .Distribution ,'binomial' )==1 
weights =sglme .PriorWeights .*sglme .BinomialSize ; 
else
weights =sglme .PriorWeights ; 
end

end

function mu =initializeMuForPL (sglme )















if(sglme .isFitToData ==true )

X =sglme .X ; 
Z =sglme .Z ; 
delta =sglme .Offset ; 
betaHat =sglme .betaHat ; 
bHat =sglme .bHat ; 
etaHat =X *betaHat +Z *bHat +delta ; 
mu =sglme .Link .Inverse (etaHat ); 
else
ifisempty (sglme .MuStart )

y =sglme .y ; 
N =sglme .BinomialSize ; 
switchlower (sglme .Distribution )
case 'poisson' 
mu =y +0.25 ; 
case 'binomial' 
mu =(N .*y +0.5 )./(N +1 ); 
case {'gamma' ,'inverse gaussian' }
mu =max (y ,eps (class (y ))); 
otherwise
mu =y ; 
end
else

mu =sglme .MuStart ; 
end
end


mu =constrainMu (sglme ,mu ,sglme .Distribution ); 





tf =isMuStartFeasibleForLink (sglme ,mu ); 
if~tf 
warning (message ('stats:classreg:regr:lmeutils:StandardGeneralizedLinearMixedModel:MuStartNotFeasible' )); 
end



mu =constrainMuForLink (sglme ,mu ,sglme .Link .Name ); 

end

function tf =isMuStartFeasibleForLink (sglme ,mu )






g =sglme .Link .Link ; 


eta =g (mu ); 


ifisreal (eta )&&all (isfinite (eta ))
tf =true ; 
else
tf =false ; 
end

end

function [tfeta ,tfmu ]=isLinearPredictorFeasible (sglme ,eta )








g =sglme .Link .Link ; 
ginv =sglme .Link .Inverse ; 



mu =ginv (eta ); 
muCon =constrainMu (sglme ,mu ,sglme .Distribution ); 


etaCon =g (muCon ); 




errEta =max (abs (etaCon -eta ))/max (max (abs (eta )),1 ); 
errMu =max (abs (muCon -mu ))/max (max (abs (mu )),1 ); 


tol =sqrt (eps ); 


if(errEta <=tol )

tfeta =true ; 
else
tfeta =false ; 
end


if(errMu <=tol )

tfmu =true ; 
else
tfmu =false ; 
end

end

function mu =constrainMuForLink (sglme ,mu ,linkname )



















TINY =sglme .MuBound .TINY ; 
BIG =sglme .MuBound .BIG ; 


switchlower (linkname )
case {'logit' ,'probit' ,'comploglog' ,'loglog' }

isok =all (mu >TINY &mu <1 -TINY ); 
if~isok 
a =max (TINY ,eps ); 
mu =sglme .constrainVector (mu ,a ,1 -a ); 
end
case {'log' ,'power' ,'reciprocal' }

isok =all (mu >TINY &mu <BIG ); 
if~isok 
a =max (TINY ,eps ); 
b =min (BIG ,realmax ); 
mu =sglme .constrainVector (mu ,a ,b ); 
end
case {'identity' }

isok =all (mu >-BIG &mu <BIG ); 
if~isok 
b =min (BIG ,realmax ); 
mu =sglme .constrainVector (mu ,-b ,b ); 
end
end

end

function mu =constrainMu (sglme ,mu ,distribution )

















mu =real (mu ); 

TINY =sglme .MuBound .TINY ; 
BIG =sglme .MuBound .BIG ; 


switchlower (distribution )
case 'binomial' 

isok =all (mu >TINY &mu <1 -TINY ); 
if~isok 
a =max (TINY ,eps ); 
mu =sglme .constrainVector (mu ,a ,1 -a ); 
end
case {'poisson' ,'gamma' ,'inverse gaussian' ,'inversegaussian' }

isok =all (mu >TINY &mu <BIG ); 
if~isok 
a =max (TINY ,eps ); 
b =min (BIG ,realmax ); 
mu =sglme .constrainVector (mu ,a ,b ); 
end
case {'normal' ,'gaussian' }

isok =all (mu >-BIG &mu <BIG ); 
if~isok 
b =min (BIG ,realmax ); 
mu =sglme .constrainVector (mu ,-b ,b ); 
end
end

end

function displayPLConvergenceInfo (sglme ,iter ,loglik ,etaTilde ,etaHat ,diagW ,kappa ,showploptimizerdisplay ,isPLconverged )




















infnormEtaTilde =max (abs (etaTilde )); 


deltaEta =max (abs (etaHat -etaTilde ))/max (max (abs (etaTilde )),1 ); 


twonormW =norm (diagW ); 



muHat =sglme .Link .Inverse (etaHat ); 
muHat =constrainMu (sglme ,muHat ,sglme .Distribution ); 
etaHatRecon =sglme .Link .Link (muHat ); 
etaHatReconError =max (abs (etaHat -etaHatRecon ))/max (max (abs (etaHat )),1 ); 



if(showploptimizerdisplay ||rem (iter ,20 )==1 )
fprintf ('\n' ); 
fprintf ('  -----------------------------------------------------------------------------------\n' ); 
fprintf ('  PL ITER      LOGLIK       ||ETA||    ||ERR: ETA||    ||W||    ||ERR: ETA->MU->ETA||\n' ); 
fprintf ('  -----------------------------------------------------------------------------------\n' ); 
end


fprintf ('%9d    %+6.3e    %06.3e    %06.3e    %06.3e       %06.3e\n' ,iter ,loglik ,infnormEtaTilde ,deltaEta ,twonormW ,etaHatReconError ); 




if(isPLconverged ==true )
plconvergedstring =getString (message ('stats:classreg:regr:lmeutils:StandardGeneralizedLinearMixedModel:Display_PLIterationDetail1' )); 
relchangestring =getString (message ('stats:classreg:regr:lmeutils:StandardGeneralizedLinearMixedModel:Display_PLIterationDetail2' )); 
pltolstring =getString (message ('stats:classreg:regr:lmeutils:StandardGeneralizedLinearMixedModel:Display_PLIterationDetail3' )); 
fprintf ('\n' ); 
fprintf ('%s: %s %6.3e, %s %6.3e\n' ,plconvergedstring ,relchangestring ,deltaEta ,pltolstring ,kappa ); 
end

end

function tf =showSummaryMessages (sglme )












optimizeroptions =sglme .OptimizerOptions ; 


ifisempty (optimizeroptions )
tf =false ; 
return ; 
end



ifany (strcmpi (optimizeroptions .Display ,{'off' ,'none' }))
tf =false ; 
else
tf =true ; 
end

end

function checkFinalPLSolution (sglme ,eta )




[tfeta ,tfmu ]=isLinearPredictorFeasible (sglme ,eta ); 















if(tfeta ==true &&tfmu ==true )

elseif(tfeta ==false &&tfmu ==false )

warning (message ('stats:classreg:regr:lmeutils:StandardGeneralizedLinearMixedModel:BadFinalPLSolution' )); 
else

warning (message ('stats:classreg:regr:lmeutils:StandardGeneralizedLinearMixedModel:BadFinalPLSolution' )); 
end

end

function [sglme ,cause ]=fitUsingPL (sglme ,numIter ,kappa )


















ifnargin <2 
numIter =sglme .PLIterations ; 
kappa =sglme .PLTolerance ; 
elseifnargin <3 
kappa =sglme .PLTolerance ; 
end
assert (isscalar (numIter )...
    &internal .stats .isIntegerVals (numIter ,1 )); 
assert (isnumeric (kappa )&isreal (kappa )&isscalar (kappa )); 




verbose =showSummaryMessages (sglme ); 



X =sglme .X ; 
y =sglme .y ; 
Z =sglme .Z ; 
delta =sglme .Offset ; 
w =getEffectiveObservationWeights (sglme ); 
fitmethod =sglme .FitMethod ; 
distribution =sglme .Distribution ; 




if~any (strcmpi (fitmethod ,{'mpl' ,'rempl' }))
fitmethod ='mpl' ; 
end



g =sglme .Link .Link ; 
ginv =sglme .Link .Inverse ; 
gp =sglme .Link .Derivative ; 
v =sglme .VarianceFunction .VarianceFunction ; 



muTilde =initializeMuForPL (sglme ); 
etaTilde =g (muTilde ); 


iter =1 ; 
found =false ; 

if(verbose ==true )
fprintf ('\n%s\n' ,getString (message ('stats:classreg:regr:lmeutils:StandardGeneralizedLinearMixedModel:Display_StartingPL' ))); 
end

while(found ==false )



muTilde =ginv (etaTilde ); 
muTilde =constrainMu (sglme ,muTilde ,distribution ); 



yp =gp (muTilde ).*(y -muTilde )+(etaTilde -delta ); 








diagW =w ./v (muTilde )./(gp (muTilde ).^2 ); 



sqrtdiagW =sqrt (diagW ); 
sglme =checkForBadlyScaledPLWeights (sglme ,sqrtdiagW ); 
ypw =sqrtdiagW .*yp ; 
Xw =bsxfun (@times ,sqrtdiagW ,X ); 
Zw =bsxfun (@times ,sqrtdiagW ,Z ); 

















ifiter ==1 
Psiw =sglme .Psi ; 
switchlower (fitmethod )
case 'mpl' 
fitmethodw ='ml' ; 
case 'rempl' 
fitmethodw ='reml' ; 
end






optimizeroptions =sglme .OptimizerOptions ; 
if(sglme .ShowPLOptimizerDisplay ==false )
if~isempty (optimizeroptions )
optimizeroptions .Display ='off' ; 
end
end

dofit =false ; 
dostats =false ; 
args ={'Optimizer' ,sglme .Optimizer ,...
    'OptimizerOptions' ,optimizeroptions ,...
    'InitializationMethod' ,sglme .InitializationMethod ,...
    'CheckHessian' ,sglme .CheckHessian }; 
if(sglme .DispersionFixed ==true )
args =[args ,{'ResidualStd' ,1.0 }]; %#ok<AGROW> 
end
slme =classreg .regr .lmeutils .StandardLinearMixedModel (Xw ,...
    ypw ,Zw ,Psiw ,fitmethodw ,dofit ,dostats ,args {:}); 
else
slme .X =Xw ; 
slme .y =ypw ; 
slme .Z =Zw ; 
slme .InitializationMethod ='default' ; 
end


slme =refit (slme ); 


betaHat =slme .betaHat ; 
bHat =slme .bHat ; 


etaHat =X *betaHat +Z *bHat +delta ; 


if(max (abs (etaHat -etaTilde ))<=max (kappa *max (abs (etaTilde )),kappa ))
found =true ; 
cause =0 ; 
elseif(iter >=numIter )
found =true ; 
cause =1 ; 
end


if(verbose ==true )
if(found ==true &&cause ==0 )
isPLconverged =true ; 
else
isPLconverged =false ; 
end
displayPLConvergenceInfo (sglme ,iter ,slme .loglikHat ,etaTilde ,etaHat ,diagW ,kappa ,sglme .ShowPLOptimizerDisplay ,isPLconverged ); 
end


etaTilde =etaHat ; 
iter =iter +1 ; 

end


sglme .betaHat =slme .betaHat ; 
sglme .bHat =slme .bHat ; 
sglme .DeltabHat =slme .DeltabHat ; 
sglme .sigmaHat =slme .sigmaHat ; 
sglme .thetaHat =slme .thetaHat ; 
sglme .phiHat =[]; 
sglme .Psi =slme .Psi ; 
sglme .slme =slme ; 




muHat =ginv (etaHat ); 
muHat =constrainMu (sglme ,muHat ,distribution ); 
gpmuHat =gp (muHat ); 
diagW =w ./v (muHat )./(gpmuHat .^2 ); 
sglme .loglikHatPseudoData =slme .loglikHat ...
    +0.5 *sum (log (abs (diagW ))); 
sglme .loglikHat =sglme .loglikHatPseudoData ...
    +sum (log (abs (gpmuHat ))); 


checkFinalPLSolution (sglme ,etaHat ); 

end

function sglme =initstatsPL (sglme )






ifisempty (sglme .slme )
error (message ('stats:classreg:regr:lmeutils:StandardGeneralizedLinearMixedModel:MustRefitFirst' )); 
end


assert (sglme .slme .isFitToData ); 
sglme .slme =initstats (sglme .slme ); 



sglme .covbetaHat =sglme .slme .covbetaHat ; 
sglme .covthetaHatlogsigmaHat =sglme .slme .covthetaHatlogsigmaHat ; 
sglme .covetaHatlogsigmaHat =sglme .slme .covetaHatlogsigmaHat ; 


sglme .rankX =sglme .slme .rankX ; 

end

function sglme =computeAMDPreordering (sglme ,theta0 )








U =getU (sglme ,theta0 ); 


q =sglme .q ; 
Iq =spdiags (ones (q ,1 ),0 ,q ,q ); 


sglme .AMDOrder =amd (U ' *U +Iq ); 

end

function tf =isModelPreInitialized (sglme )







betaHat =sglme .betaHat ; 
okbetaHat =(length (betaHat )==sglme .p ); 


thetaHat =sglme .thetaHat ; 
okthetaHat =(length (thetaHat )==sglme .Psi .NumParametersExcludingSigma ); 


sigmaHat =sglme .sigmaHat ; 
oksigmaHat =(length (sigmaHat )==1 ); 


bHat =sglme .bHat ; 
okbHat =(length (bHat )==sglme .q ); 


DeltabHat =sglme .DeltabHat ; 
okDeltabHat =(length (DeltabHat )==sglme .q ); 


tf =okbetaHat &okthetaHat &oksigmaHat &okbHat &okDeltabHat ; 

end

function [sglme ,cause ,x0 ,fun ,xHat ]=fitUsingApproximateLaplace (sglme )
















assert (isModelPreInitialized (sglme )==true ); 


sigma0 =sglme .sigmaHat ; 
theta0 =sglme .thetaHat ; 


lenthetaHat =length (theta0 ); 


warnState =warning ('query' ,'all' ); 
warning ('off' ,'MATLAB:nearlySingularMatrix' ); 
warning ('off' ,'MATLAB:illConditionedMatrix' ); 
warning ('off' ,'MATLAB:singularMatrix' ); 
cleanupObj =onCleanup (@()warning (warnState )); 


















ifsglme .isSigmaFixed 
x0 =theta0 ; 
else
x0 =[theta0 ; log (sigma0 )]; 
end

fun =makeNegativeApproximateLaplacianLogLikelihood (sglme ); 

verbose =showSummaryMessages (sglme ); 
if(verbose ==true )
fprintf ('\n%s\n' ,getString (message ('stats:classreg:regr:lmeutils:StandardGeneralizedLinearMixedModel:Display_StartingApproximateLaplace' ))); 
end
[xHat ,cause ]=doMinimization (sglme ,fun ,x0 ); 

thetaHat =xHat (1 :lenthetaHat ); 

ifisempty (thetaHat )
thetaHat =zeros (0 ,1 ); 
end

ifsglme .isSigmaFixed 
sigmaHat =1.0 ; 
else
logsigmaHat =xHat (lenthetaHat +1 ); 
sigmaHat =exp (logsigmaHat ); 
end


includeConst =true ; 
[loglikHat ,betaHat ,DeltabHat ,bHat ]=loglikelihoodApproximateLaplace (sglme ,thetaHat ,sigmaHat ,includeConst ); 



sglme .betaHat =betaHat ; 
sglme .bHat =bHat ; 
sglme .DeltabHat =DeltabHat ; 
sglme .sigmaHat =sigmaHat ; 
sglme .thetaHat =thetaHat ; 
sglme .loglikHat =loglikHat ; 
sglme .phiHat =[]; 
sglme .Psi =setUnconstrainedParameters (sglme .Psi ,sglme .thetaHat ); 
sglme .Psi =setSigma (sglme .Psi ,sglme .sigmaHat ); 

end

function [sglme ,cause ,x0 ,fun ,xHat ]=fitUsingLaplace (sglme )
















assert (isModelPreInitialized (sglme )==true ); 


beta0 =sglme .betaHat ; 
sigma0 =sglme .sigmaHat ; 
theta0 =sglme .thetaHat ; 


lenbetaHat =length (beta0 ); 
lenthetaHat =length (theta0 ); 


warnState =warning ('query' ,'all' ); 
warning ('off' ,'MATLAB:nearlySingularMatrix' ); 
warning ('off' ,'MATLAB:illConditionedMatrix' ); 
warning ('off' ,'MATLAB:singularMatrix' ); 
cleanupObj =onCleanup (@()warning (warnState )); 


















ifsglme .isSigmaFixed 
x0 =[beta0 ; theta0 ]; 
else
x0 =[beta0 ; theta0 ; log (sigma0 )]; 
end

fun =makeNegativeLaplacianLogLikelihood (sglme ); 

verbose =showSummaryMessages (sglme ); 
if(verbose ==true )
fprintf ('\n%s\n' ,getString (message ('stats:classreg:regr:lmeutils:StandardGeneralizedLinearMixedModel:Display_StartingLaplace' ))); 
end
[xHat ,cause ]=doMinimization (sglme ,fun ,x0 ); 

betaHat =xHat (1 :lenbetaHat ); 
thetaHat =xHat (lenbetaHat +1 :lenbetaHat +lenthetaHat ); 

ifisempty (betaHat )
betaHat =zeros (0 ,1 ); 
end
ifisempty (thetaHat )
thetaHat =zeros (0 ,1 ); 
end

ifsglme .isSigmaFixed 
sigmaHat =1.0 ; 
else
logsigmaHat =xHat (lenbetaHat +lenthetaHat +1 ); 
sigmaHat =exp (logsigmaHat ); 
end

includeConst =true ; 
[loglikHat ,DeltabHat ,bHat ]=loglikelihoodLaplace (sglme ,thetaHat ,sigmaHat ,betaHat ,includeConst ); 



sglme .betaHat =betaHat ; 
sglme .bHat =bHat ; 
sglme .DeltabHat =DeltabHat ; 
sglme .sigmaHat =sigmaHat ; 
sglme .thetaHat =thetaHat ; 
sglme .loglikHat =loglikHat ; 
sglme .phiHat =[]; 
sglme .Psi =setUnconstrainedParameters (sglme .Psi ,sglme .thetaHat ); 
sglme .Psi =setSigma (sglme .Psi ,sglme .sigmaHat ); 

end

function [sglme ,cause ]=fitUsingML (sglme )













if(sglme .isFitToData ==false )
numIter =sglme .InitPLIterations ; 
kappa =sglme .PLTolerance ; 
[sglme ,~]=fitUsingPL (sglme ,numIter ,kappa ); 
end


if(sglme .UseAMDPreordering ==true )
sglme =computeAMDPreordering (sglme ,sglme .thetaHat ); 
end

















switchlower (sglme .FitMethod )
case 'laplace' 



if(sglme .UseSequentialFitting ==true )
[sglme ,~]=fitUsingApproximateLaplace (sglme ); 
end
[sglme ,cause ,~,fun ,xHat ]=fitUsingLaplace (sglme ); 

case 'approximatelaplace' 
[sglme ,cause ,~,fun ,xHat ]=fitUsingApproximateLaplace (sglme ); 

case 'quadrature' 

end


doHessianCheck =(cause ==0 ||cause ==1 )&&(sglme .CheckHessian ==true ); 
if(doHessianCheck ==true )
checkObjectiveFunctionHessianForML (sglme ,fun ,xHat ); 
end

end

function checkObjectiveFunctionHessianForML (sglme ,fun ,xHat )





if~isempty (xHat )

wantRegularized =false ; 
H =sglme .getHessian (fun ,xHat ,wantRegularized ); 


switchlower (sglme .FitMethod )
case 'laplace' 
msgID ='stats:classreg:regr:lmeutils:StandardGeneralizedLinearMixedModel:Message_NotSPDHessian_Laplace' ; 
case 'approximatelaplace' 
msgID ='stats:classreg:regr:lmeutils:StandardGeneralizedLinearMixedModel:Message_NotSPDHessian_ApproximateLaplace' ; 
otherwise
error (message ('stats:classreg:regr:lmeutils:StandardGeneralizedLinearMixedModel:BadMLFitMethod' )); 
end


sglme .checkPositiveDefinite (H ,msgID ); 
end

end

function sglme =initstatsML (sglme )













switchlower (sglme .CovarianceMethod )
case 'conditional' 



sglme .covbetaHat =approximateCovBetaHatAsFunctionOfParameters (sglme ,...
    sglme .betaHat ,sglme .DeltabHat ,sglme .thetaHat ,sglme .sigmaHat ); 


sglme .covetaHatlogsigmaHat =[]; 


sglme .covthetaHatlogsigmaHat =[]; 
case 'jointhessian' 





[sglme .covbetaHat ,sglme .covetaHatlogsigmaHat ]=covBetaHatEtaHatLogSigmaHat (sglme ); 


sglme .covthetaHatlogsigmaHat =[]; 
end


sglme .rankX =rank (sglme .X ); 

end

end


methods (Access =protected )

function fun =makeNegativeApproximateLaplacianLogLikelihood (sglme )






fun =@f5 ; 
function y5 =f5 (x )


theta =x (1 :sglme .Psi .NumParametersExcludingSigma ,1 ); 


ifsglme .isSigmaFixed 
sigma =sglme .sigmaFixed ; 
else
logsigma =x (end); 
sigma =exp (logsigma ); 
end



includeConst =false ; 
L =loglikelihoodApproximateLaplace (sglme ,theta ,sigma ,includeConst ); 
y5 =-1 *L ; 


y5 =max (-realmax ,y5 ); 

end


end

function fun =makeNegativeLaplacianLogLikelihood (sglme )





fun =@f1 ; 
function y1 =f1 (x )

beta =x (1 :sglme .p ,1 ); 
theta =x (sglme .p +1 :sglme .p +sglme .Psi .NumParametersExcludingSigma ,1 ); 


ifsglme .isSigmaFixed 
sigma =sglme .sigmaFixed ; 
else
logsigma =x (end); 
sigma =exp (logsigma ); 
end



includeConst =false ; 
switchlower (sglme .EBMethod )
case 'default' 
L =loglikelihoodLaplace (sglme ,theta ,sigma ,beta ,includeConst ); 
otherwise
L =loglikelihoodLaplace2 (sglme ,theta ,sigma ,beta ,includeConst ); 
end
y1 =-1 *L ; 


y1 =max (-realmax ,y1 ); 
end

end

function fun =makeNegativeLaplacianLogLikelihoodNaturalParameters (sglme )






fun =@f3 ; 
function y3 =f3 (x )

beta =x (1 :sglme .p ,1 ); 
eta =x (sglme .p +1 :sglme .p +sglme .Psi .NumParametersExcludingSigma ,1 ); 


ifsglme .isSigmaFixed 
sigma =sglme .sigmaFixed ; 
else
logsigma =x (end); 
sigma =exp (logsigma ); 
end


Psi =sglme .Psi ; 
Psi =setSigma (Psi ,sigma ); 
Psi =setNaturalParameters (Psi ,eta ); 


theta =getUnconstrainedParameters (Psi ); 



includeConst =false ; 
switchlower (sglme .EBMethod )
case 'default' 
L =loglikelihoodLaplace (sglme ,theta ,sigma ,beta ,includeConst ); 
otherwise
L =loglikelihoodLaplace2 (sglme ,theta ,sigma ,beta ,includeConst ); 
end
y3 =-1 *L ; 


y3 =max (-realmax ,y3 ); 

end

end

end


methods (Access =public ,Hidden =true )

function diagW =getDiagW (sglme ,mu ,w )





gp =sglme .Link .Derivative ; 
v =sglme .VarianceFunction .VarianceFunction ; 


diagW =w ./v (mu )./(gp (mu ).^2 ); 

end

function diagC =getDiagC (sglme ,mu ,w )






gp =sglme .Link .Derivative ; 
g2p =sglme .Link .SecondDerivative ; 
v =sglme .VarianceFunction .VarianceFunction ; 
vp =sglme .VarianceFunction .Derivative ; 


gpmu =gp (mu ); 
vmu =v (mu ); 
xi =(g2p (mu ).*vmu )./gpmu +vp (mu ); 


diagW =w ./vmu ./(gpmu .^2 ); 


y =sglme .y ; 
diagC =(((y -mu ).*xi )./vmu +1 ).*diagW ; 

end

function cloglik =conditionalLogLikelihood (sglme ,mu ,sigma ,includeConst )












assert (iscolumn (mu )&size (mu ,1 )==sglme .N ); 
assert (isscalar (sigma )&all (sigma >0 )); 
assert (isscalar (includeConst )&islogical (includeConst )); 


distribution =sglme .Distribution ; 


w =getEffectiveObservationWeights (sglme ); 
y =sglme .y ; 


switchlower (distribution )
case {'normal' ,'gaussian' }
sigma2 =sigma ^2 ; 
cloglik =-(0.5 /sigma2 )*sum (w .*((y -mu ).^2 ))-0.5 *sum (log ((2 *pi *sigma2 )./w )); 
case 'binomial' 
cloglik =sum (w .*(y .*log (mu )+(1 -y ).*log (1 -mu ))); 
if(includeConst ==true )
const =sum (gammaln (w +1 )-gammaln (w .*y +1 )-gammaln (w .*(1 -y )+1 )); 
cloglik =cloglik +const ; 
end
case 'poisson' 
cloglik =sum (w .*(y .*log (mu )-mu ))+sum (w .*y .*log (w )); 
if(includeConst ==true )
const =-sum (gammaln (w .*y +1 )); 
cloglik =cloglik +const ; 
end
case 'gamma' 
sigma2 =sigma ^2 ; 
cloglik =sum ((log ((y .*w )./(mu *sigma2 ))-(y ./mu )).*(w /sigma2 ))...
    -sum (log (y ))-sum (gammaln (w /sigma2 )); 
case {'inverse gaussian' ,'inversegaussian' }
sigma2 =sigma ^2 ; 
cloglik =-(0.5 /sigma2 )*sum ((w .*((y -mu ).^2 ))./((mu .^2 ).*y ))...
    +0.5 *sum (log (w ./(2 *pi *sigma2 *(y .^3 )))); 
end

end

end


methods (Access =protected )

function diagF =getDiagF (sglme ,mu )




gp =sglme .Link .Derivative ; 


diagF =gp (mu ); 

end

function [U ,Lambda ]=getU (sglme ,theta )







Z =sglme .Z ; 


Psi =sglme .Psi ; 
Psi =setUnconstrainedParameters (Psi ,theta ); 
Psi =setSigma (Psi ,1 ); 



Lambda =getLowerTriangularCholeskyFactor (Psi ); 


U =Z *Lambda ; 

end

function M =getUtCUPlusIdentity (sglme ,U ,diagC )














q =sglme .q ; 
N =sglme .N ; 


diagC =spdiags (diagC ,0 ,N ,N ); 


Iq =spdiags (ones (q ,1 ),0 ,q ,q ); 


M =((U ' *(diagC *U ))+Iq ); 

end

function beta0 =initializeBeta (sglme )





ifisempty (sglme .betaHat )
beta0 =zeros (sglme .p ,1 ); 
else
beta0 =sglme .betaHat ; 
end

end

function Deltab0 =initializeDeltab (sglme )





ifisempty (sglme .DeltabHat )
Deltab0 =zeros (sglme .q ,1 ); 
else
Deltab0 =sglme .DeltabHat ; 
end

end

end


methods (Access =protected )

function [logliklap ,b ]=loglikelihoodLaplaceAsFunctionOfParameters (sglme ,theta ,sigma ,beta ,Deltab ,includeConst )











X =sglme .X ; 
q =sglme .q ; 
delta =sglme .Offset ; 


[U ,Lambda ]=getU (sglme ,theta ); 


eta =X *beta +U *Deltab +delta ; 


ginv =sglme .Link .Inverse ; 
mu =ginv (eta ); 
mu =constrainMu (sglme ,mu ,sglme .Distribution ); 


w =getEffectiveObservationWeights (sglme ); 
diagC =getDiagC (sglme ,mu ,w ); 





M =getUtCUPlusIdentity (sglme ,U ,diagC ); 
[R ,status ,~]=chol (M ); 


if(status ~=0 )
error (message ('stats:classreg:regr:lmeutils:StandardGeneralizedLinearMixedModel:BadLaplaceLogLikelihood' )); 
end


cloglik =conditionalLogLikelihood (sglme ,mu ,sigma ,includeConst ); 


logliklap =cloglik -0.5 *(Deltab ' *Deltab )/(sigma ^2 )-sglme .logAbsDetTriangular (R ); 


ifnargout >1 
b =Lambda *Deltab ; 
end

end

function [rb ,eta ,mu ]=normalizedrb (sglme ,y ,X ,beta ,U ,Deltab ,delta ,w )







ginv =sglme .Link .Inverse ; 
eta =X *beta +U *Deltab +delta ; 
mu =ginv (eta ); 


mu =constrainMu (sglme ,mu ,sglme .Distribution ); 


diagF =getDiagF (sglme ,mu ); 
diagW =getDiagW (sglme ,mu ,w ); 


rb =U ' *(diagW .*diagF .*(y -mu ))-Deltab ; 

end

function [Deltab ,cause ]=normalizedPosteriorModeOfB (sglme ,theta ,sigma ,beta ,numIter ,kappa ,stepTol )



















y =sglme .y ; 
X =sglme .X ; 
Z =sglme .Z ; 
q =sglme .q ; 
delta =sglme .Offset ; 
w =getEffectiveObservationWeights (sglme ); 


Psi =sglme .Psi ; 
Psi =setUnconstrainedParameters (Psi ,theta ); 
Psi =setSigma (Psi ,1 ); 



Lambda =getLowerTriangularCholeskyFactor (Psi ); 


U =Z *Lambda ; 


Deltab =initializeDeltab (sglme ); 


[rb ,eta ,mu ]=normalizedrb (sglme ,y ,X ,beta ,U ,Deltab ,delta ,w ); 



rho =0.5 ; 
c1 =1e-5 ; 


iter =0 ; 
found =false ; 
while(found ==false )


diagC =getDiagC (sglme ,mu ,w ); 




Jb =-1 *getUtCUPlusIdentity (sglme ,U ,diagC ); 




[R ,status ,S ]=chol (-Jb ); 
if(status ~=0 )

Deltap =-(Jb \rb ); 
else
Deltap =S *(R \(R ' \(S ' *rb ))); 
end


alpha =1.0 ; 
foundalpha =false ; 





term1 =rb ' *rb ; 
term2 =Deltap ' *Jb ' *rb ; 
while(foundalpha ==false )

Deltabnew =Deltab +alpha *Deltap ; 


[rbnew ,etanew ,munew ]=normalizedrb (sglme ,y ,X ,beta ,U ,Deltabnew ,delta ,w ); 



isok =(rbnew ' *rbnew -(term1 +2 *c1 *alpha *term2 ))<=0 ; 


if(isok ==true )
foundalpha =true ; 
elseif(alpha <=stepTol )
foundalpha =true ; 
warning (message ('stats:classreg:regr:lmeutils:StandardGeneralizedLinearMixedModel:Message_PosteriorModeLineSearch' )); 
else
alpha =rho *alpha ; 
end
end


if(max (abs (etanew -eta ))<=max (kappa *max (abs (eta )),kappa ))
found =true ; 
cause =0 ; 
elseif(norm (alpha *Deltap )<=stepTol )
found =true ; 
cause =1 ; 
elseif(iter >=numIter )
found =true ; 
cause =2 ; 
end


Deltab =Deltabnew ; 
rb =rbnew ; 
eta =etanew ; 
mu =munew ; 
iter =iter +1 ; 
end

end

function [logliklap ,Deltab ,b ]=loglikelihoodLaplace (sglme ,theta ,sigma ,beta ,includeConst )











numIter =sglme .EBOptions .MaxIter ; 
kappa =sglme .EBOptions .TolFun ; 
stepTol =sglme .EBOptions .TolX ; 
[Deltab ,cause ]=normalizedPosteriorModeOfB (sglme ,theta ,sigma ,beta ,numIter ,kappa ,stepTol ); 
if(cause ==2 )
warning (message ('stats:classreg:regr:lmeutils:StandardGeneralizedLinearMixedModel:Message_PosteriorModeLineSearchNonConvergence' )); 
end


[logliklap ,b ]=loglikelihoodLaplaceAsFunctionOfParameters (sglme ,theta ,sigma ,beta ,Deltab ,includeConst ); 

end

function [logliklap ,Deltab ,b ]=loglikelihoodLaplace2 (sglme ,theta ,sigma ,beta ,includeConst )











[Deltab ,rDeltab ,JDeltab ,cause ]=normalizedPosteriorModeOfB2 (sglme ,theta ,sigma ,beta ); 
if(cause ==2 )
warning (message ('stats:classreg:regr:lmeutils:StandardGeneralizedLinearMixedModel:Message_PosteriorModeLineSearchNonConvergence' )); 
end




if~issparse (JDeltab )
JDeltab =sparse (JDeltab ); 
end
[R ,status ,~]=chol (JDeltab ); 


if(status ~=0 )
error (message ('stats:classreg:regr:lmeutils:StandardGeneralizedLinearMixedModel:BadLaplaceLogLikelihood' )); 
end


X =sglme .X ; 
Z =sglme .Z ; 
delta =sglme .Offset ; 


Psi =sglme .Psi ; 
Psi =setUnconstrainedParameters (Psi ,theta ); 
Psi =setSigma (Psi ,1 ); 



Lambda =getLowerTriangularCholeskyFactor (Psi ); 


U =Z *Lambda ; 


eta =X *beta +U *Deltab +delta ; 


ginv =sglme .Link .Inverse ; 
mu =ginv (eta ); 
mu =constrainMu (sglme ,mu ,sglme .Distribution ); 


cloglik =conditionalLogLikelihood (sglme ,mu ,sigma ,includeConst ); 


logliklap =cloglik -0.5 *(Deltab ' *Deltab )/(sigma ^2 )-sglme .logAbsDetTriangular (R ); 


ifnargout >2 
b =Lambda *Deltab ; 
end

end

function [loglikapproxlap ,beta ,Deltab ,b ]=loglikelihoodApproximateLaplace (sglme ,theta ,sigma ,includeConst )













[beta ,Deltab ,r ,J ,cause ]=normalizedPosteriorModeOfBetaB (sglme ,theta ,sigma ); 
if(cause ==2 )
warning (message ('stats:classreg:regr:lmeutils:StandardGeneralizedLinearMixedModel:Message_JointPosteriorModeLineSearchNonConvergence' )); 
end


[loglikapproxlap ,b ]=loglikelihoodLaplaceAsFunctionOfParameters (sglme ,theta ,sigma ,beta ,Deltab ,includeConst ); 


end

end



methods (Access =public ,Hidden =true )

function rfun =makerfunForB (sglme ,theta ,sigma ,beta )





y =sglme .y ; 
X =sglme .X ; 
Z =sglme .Z ; 
delta =sglme .Offset ; 
w =getEffectiveObservationWeights (sglme ); 


Psi =sglme .Psi ; 
Psi =setUnconstrainedParameters (Psi ,theta ); 
Psi =setSigma (Psi ,1 ); 



Lambda =getLowerTriangularCholeskyFactor (Psi ); 


U =Z *Lambda ; 


useamd =sglme .UseAMDPreordering ; 
s =sglme .AMDOrder ; 
methodcode =sglme .NewtonStepMethodCode ; 



rfun =@f2 ; 
function [r ,J ,pn ]=f2 (Deltab )

switchnargout 
case 1 
r =rfunForB (sglme ,Deltab ,theta ,sigma ,beta ,y ,X ,U ,delta ,w ,useamd ,s ,methodcode ); 
case 2 
[r ,J ]=rfunForB (sglme ,Deltab ,theta ,sigma ,beta ,y ,X ,U ,delta ,w ,useamd ,s ,methodcode ); 
case 3 
[r ,J ,pn ]=rfunForB (sglme ,Deltab ,theta ,sigma ,beta ,y ,X ,U ,delta ,w ,useamd ,s ,methodcode ); 
end
end

end

function rfun =makerfunForBetaB (sglme ,theta ,sigma )






y =sglme .y ; 
X =sglme .X ; 
Z =sglme .Z ; 
delta =sglme .Offset ; 
w =getEffectiveObservationWeights (sglme ); 


Psi =sglme .Psi ; 
Psi =setUnconstrainedParameters (Psi ,theta ); 
Psi =setSigma (Psi ,1 ); 



Lambda =getLowerTriangularCholeskyFactor (Psi ); 


U =Z *Lambda ; 


p =sglme .p ; 
q =sglme .q ; 
N =sglme .N ; 


useamd =sglme .UseAMDPreordering ; 
s =sglme .AMDOrder ; 
methodcode =sglme .NewtonStepMethodCode ; 


rfun =@f4 ; 
function [r ,J ,pn ]=f4 (x )

beta =x (1 :p ,1 ); 
Deltab =x (p +1 :p +q ,1 ); 

switchnargout 
case 1 
r =rfunForBetaB (sglme ,Deltab ,theta ,sigma ,beta ,y ,X ,U ,delta ,w ,useamd ,s ,methodcode ,N ); 
case 2 
[r ,J ]=rfunForBetaB (sglme ,Deltab ,theta ,sigma ,beta ,y ,X ,U ,delta ,w ,useamd ,s ,methodcode ,N ); 
case 3 
[r ,J ,pn ]=rfunForBetaB (sglme ,Deltab ,theta ,sigma ,beta ,y ,X ,U ,delta ,w ,useamd ,s ,methodcode ,N ); 
end
end

end

end


methods (Access =protected )

function [r ,J ,pn ]=rfunForB (sglme ,Deltab ,theta ,sigma ,beta ,y ,X ,U ,delta ,w ,useamd ,s ,methodcode )

































































































































ginv =sglme .Link .Inverse ; 
eta =X *beta +U *Deltab +delta ; 
mu =ginv (eta ); 


mu =constrainMu (sglme ,mu ,sglme .Distribution ); 


diagF =getDiagF (sglme ,mu ); 
diagW =getDiagW (sglme ,mu ,w ); 


r =-(U ' *(diagW .*diagF .*(y -mu ))-Deltab ); 


ifnargout >1 

diagC =getDiagC (sglme ,mu ,w ); 


J =getUtCUPlusIdentity (sglme ,U ,diagC ); 
end


ifnargout >2 





pn =sglme .computeNewtonStepForB (J ,r ,useamd ,s ,methodcode ); 
end

end

function [r ,J ,pn ]=rfunForBetaB (sglme ,Deltab ,theta ,sigma ,beta ,y ,X ,U ,delta ,w ,useamd ,s ,methodcode ,N )










































































ginv =sglme .Link .Inverse ; 
eta =X *beta +U *Deltab +delta ; 
mu =ginv (eta ); 


mu =constrainMu (sglme ,mu ,sglme .Distribution ); 


diagF =getDiagF (sglme ,mu ); 
diagW =getDiagW (sglme ,mu ,w ); 


p =sglme .p ; 
q =sglme .q ; 
r =zeros (p +q ,1 ); 

rbeta =-(X ' *(diagW .*diagF .*(y -mu ))); 
rb =-(U ' *(diagW .*diagF .*(y -mu ))-Deltab ); 
r (1 :p )=rbeta ; 
r (p +1 :p +q )=rb ; 


ifnargout >1 

diagC =getDiagC (sglme ,mu ,w ); 


J =sparse (p +q ,p +q ); 
XtCX =X ' *bsxfun (@times ,diagC ,X ); 

CU =spdiags (diagC ,0 ,N ,N )*U ; 
XtCU =X ' *CU ; 
UtCU =U ' *CU ; 
Iq =spdiags (ones (q ,1 ),0 ,q ,q ); 
UtCUIq =UtCU +Iq ; 

i1 =1 :p ; 
i2 =(p +1 ):(p +q ); 
J (i1 ,i1 )=XtCX ; 
J (i1 ,i2 )=XtCU ; 
J (i2 ,i1 )=XtCU ' ; 
J (i2 ,i2 )=UtCUIq ; 
end


ifnargout >2 



pn =sglme .computeNewtonStepForBetaB (J ,r ,UtCUIq ,XtCU ,XtCX ,rb ,rbeta ,p ,q ,Iq ,useamd ,s ,methodcode ); 

end

end

function [beta ,Deltab ,r ,J ,cause ]=normalizedPosteriorModeOfBetaB (sglme ,theta ,sigma )













beta0 =initializeBeta (sglme ); 
Deltab0 =initializeDeltab (sglme ); 


rfun =makerfunForBetaB (sglme ,theta ,sigma ); 


x0 =[beta0 ; Deltab0 ]; 


ifstrcmpi (sglme .EBMethod ,'fsolve' )
sglme .EBOptions .Jacobian ='on' ; 

[x ,r ,exitflag ,~,J ]=fsolve (rfun ,x0 ,sglme .EBOptions ); 








switchexitflag 
case 1 
cause =0 ; 
case {2 ,3 ,4 }
cause =1 ; 
otherwise
cause =2 ; 
end
else
[x ,r ,J ,cause ]=nlesolve (rfun ,x0 ,...
    'Options' ,sglme .EBOptions ,'Method' ,sglme .EBMethod ); 
end


p =sglme .p ; 
q =sglme .q ; 
beta =x (1 :p ,1 ); 
Deltab =x (p +1 :p +q ,1 ); 

end

function [Deltab ,rDeltab ,JDeltab ,cause ]=normalizedPosteriorModeOfB2 (sglme ,theta ,sigma ,beta )














Deltab0 =initializeDeltab (sglme ); 


rfun =makerfunForB (sglme ,theta ,sigma ,beta ); 


ifstrcmpi (sglme .EBMethod ,'fsolve' )
sglme .EBOptions .Jacobian ='on' ; 

[Deltab ,rDeltab ,exitflag ,~,JDeltab ]=fsolve (rfun ,Deltab0 ,sglme .EBOptions ); 








switchexitflag 
case 1 
cause =0 ; 
case {2 ,3 ,4 }
cause =1 ; 
otherwise
cause =2 ; 
end
else
[Deltab ,rDeltab ,JDeltab ,cause ]=nlesolve (rfun ,Deltab0 ,...
    'Options' ,sglme .EBOptions ,'Method' ,sglme .EBMethod ); 
end

end

end



methods (Access =protected )

function covbetaHat =approximateCovBetaHatAsFunctionOfParameters (sglme ,beta ,Deltab ,theta ,sigma )







X =sglme .X ; 
p =sglme .p ; 
q =sglme .q ; 
delta =sglme .Offset ; 


U =getU (sglme ,theta ); 


eta =X *beta +U *Deltab +delta ; 


ginv =sglme .Link .Inverse ; 
mu =ginv (eta ); 
mu =constrainMu (sglme ,mu ,sglme .Distribution ); 


w =getEffectiveObservationWeights (sglme ); 
diagC =getDiagC (sglme ,mu ,w ); 



CU =bsxfun (@times ,diagC ,U ); 
CX =bsxfun (@times ,diagC ,X ); 


XtCX =X ' *CX ; 
XtCU =X ' *CU ; 


Iq =spdiags (ones (q ,1 ),0 ,q ,q ); 
M =U ' *CU +Iq ; 
M =0.5 *(M +M ' ); 





[R ,status ,S ]=chol (M ); 


if(status ~=0 )
error (message ('stats:classreg:regr:lmeutils:StandardGeneralizedLinearMixedModel:BadLaplaceLogLikelihood' )); 
end


Q1 =(XtCU *S )/R ; 


R1R1t =XtCX -Q1 *Q1 ' ; 


[R1 ,status1 ]=chol (R1R1t ,'lower' ); 
if(status1 ~=0 )


R1 =classreg .regr .lmeutils .covmats .CovarianceMatrix .singularLowerChol (R1R1t ); 
end


R1inv =R1 \eye (p ); 


covbetaHat =(sigma ^2 )*(R1inv ' *R1inv ); 

end

function covbetaHatbHat =covBetaHatBHatAsFunctionOfOfParameters (sglme ,beta ,Deltab ,theta ,sigma )









































X =sglme .X ; 
p =sglme .p ; 
q =sglme .q ; 
N =sglme .N ; 
delta =sglme .Offset ; 


[U ,Lambda ]=getU (sglme ,theta ); 


eta =X *beta +U *Deltab +delta ; 


ginv =sglme .Link .Inverse ; 
mu =ginv (eta ); 
mu =constrainMu (sglme ,mu ,sglme .Distribution ); 





w =getEffectiveObservationWeights (sglme ); 
switchlower (sglme .FitMethod )
case {'mpl' ,'rempl' }
diagC =getDiagW (sglme ,mu ,w ); 
otherwise
diagC =getDiagC (sglme ,mu ,w ); 
end
diagC =spdiags (diagC ,0 ,N ,N ); 


CU =diagC *U ; 
CX =diagC *X ; 


XtCX =X ' *CX ; 
XtCU =X ' *CU ; 




Iq =spdiags (ones (q ,1 ),0 ,q ,q ); 
UtCUplusIq =U ' *CU +Iq ; 
[~,status ,~]=chol (UtCUplusIq ); 
if(status ~=0 )
error (message ('stats:classreg:regr:lmeutils:StandardGeneralizedLinearMixedModel:BadLaplaceLogLikelihood' )); 
end


M =sparse (p +q ,p +q ); 
i1 =1 :p ; 
i2 =p +1 :p +q ; 
M (i1 ,i1 )=XtCX ; 
M (i1 ,i2 )=XtCU ; 
M (i2 ,i1 )=XtCU ' ; 
M (i2 ,i2 )=UtCUplusIq ; 


try
L =chol (M ,'lower' ); 
catch ME %#ok<NASGU> 
L =classreg .regr .lmeutils .covmats .CovarianceMatrix .singularLowerChol (M ); 
end


G =sparse (p +q ,p +q ); 
G (i1 ,i1 )=eye (p ); 
G (i2 ,i2 )=Lambda ' ; 


T =L \G ; 


covbetaHatbHat =(sigma ^2 )*(T ' *T ); 

end

function C =covBetaHatBHat (sglme )





ifisempty (sglme .covbetaHatbHat )
beta =sglme .betaHat ; 
Deltab =sglme .DeltabHat ; 
theta =sglme .thetaHat ; 
sigma =sglme .sigmaHat ; 
C =covBetaHatBHatAsFunctionOfOfParameters (sglme ,beta ,Deltab ,theta ,sigma ); 
else
C =sglme .covbetaHatbHat ; 
end

end

function [covbetaHat ,covetaHatlogsigmaHat ]=covBetaHatetaHatlogsigmaHatAsFunctionOfBetaThetaSigma (sglme ,beta ,theta ,sigma )








fun =makeNegativeLaplacianLogLikelihoodNaturalParameters (sglme ); 


Psi =sglme .Psi ; 
Psi =setUnconstrainedParameters (Psi ,theta ); 
Psi =setSigma (Psi ,sigma ); 
eta =getNaturalParameters (Psi ); 


ifsglme .isSigmaFixed 

x =[beta ; eta ]; 
else

x =[beta ; eta ; log (sigma )]; 
end



try
H =sglme .getHessian (fun ,x ); 
catch ME %#ok<NASGU> 
H =NaN (length (x )); 
end



ifsglme .isSigmaFixed 
n =size (H ,1 ); 
H (n +1 ,:)=0 ; 
H (:,n +1 )=0 ; 
end




warnState =warning ('query' ,'all' ); 
warning ('off' ,'MATLAB:singularMatrix' ); 
warning ('off' ,'MATLAB:illConditionedMatrix' ); 
warning ('off' ,'MATLAB:nearlySingularMatrix' ); 
cleanupObj =onCleanup (@()warning (warnState )); 
try
C =covarianceOnNaturalScale (sglme ,H ); 
catch ME %#ok<NASGU> 
C =H \eye (size (H )); 
end


lenbeta =length (beta ); 
leneta =length (eta ); 
ibeta =1 :lenbeta ; 
ietalogsigma =lenbeta +1 :lenbeta +leneta +1 ; 
covbetaHat =C (ibeta ,ibeta ); 
covetaHatlogsigmaHat =C (ietalogsigma ,ietalogsigma ); 

end

function [covbetaHat ,covetaHatlogsigmaHat ]=covBetaHatEtaHatLogSigmaHat (sglme )













betaHat =sglme .betaHat ; 
thetaHat =sglme .thetaHat ; 
sigmaHat =sglme .sigmaHat ; 


Psi =sglme .Psi ; 
Psi =setUnconstrainedParameters (Psi ,thetaHat ); 
Psi =setSigma (Psi ,sigmaHat ); 
etaHat =getNaturalParameters (Psi ); 



ifsglme .isSigmaFixed 
x =[betaHat ; etaHat ]; 
else
x =[betaHat ; etaHat ; log (sigmaHat )]; 
end




fun =makeNegativeLaplacianLogLikelihoodNaturalParameters (sglme ); 



try
H =sglme .getHessian (fun ,x ); 
catch ME %#ok<NASGU> 
H =NaN (length (x )); 
end




warnState =warning ('query' ,'all' ); 
warning ('off' ,'MATLAB:singularMatrix' ); 
warning ('off' ,'MATLAB:illConditionedMatrix' ); 
warning ('off' ,'MATLAB:nearlySingularMatrix' ); 
cleanupObj =onCleanup (@()warning (warnState )); 
try
C =sglme .covarianceOnNaturalScale (H ); 
catch ME %#ok<NASGU> 
C =H \eye (size (H )); 
end



ifsglme .isSigmaFixed 
n =size (C ,1 ); 
C (n +1 ,:)=0 ; 
C (:,n +1 )=0 ; 
end


lenbeta =length (betaHat ); 
leneta =length (etaHat ); 
ibeta =1 :lenbeta ; 
ietalogsigma =lenbeta +1 :lenbeta +leneta +1 ; 
covbetaHat =C (ibeta ,ibeta ); 
covetaHatlogsigmaHat =C (ietalogsigma ,ietalogsigma ); 

end

function [pred ,varpred ]=getEstimateAndVariance (sglme ,Xnew ,Znew ,betaBar ,DeltabBar ,theta ,sigma ,type )



























ifnargin <8 
type ='variance' ; 
end


M =size (Xnew ,1 ); 
p =size (Xnew ,2 ); 
q =size (Znew ,2 ); 
assert (size (Znew ,1 )==M ); 
assert (p ==sglme .p &&q ==sglme .q ); 
assert (size (betaBar ,1 )==p &&size (betaBar ,2 )==1 ); 
assert (size (DeltabBar ,1 )==q &&size (DeltabBar ,2 )==1 ); 


X =sglme .X ; 
N =sglme .N ; 
delta =sglme .Offset ; 


[U ,Lambda ]=getU (sglme ,theta ); 


pred =Xnew *betaBar +Znew *(Lambda *DeltabBar ); 
pred =full (pred ); 


ifnargout >1 
warnState =warning ('query' ,'all' ); 
warning ('off' ,'MATLAB:nearlySingularMatrix' ); 
warning ('off' ,'MATLAB:illConditionedMatrix' ); 
warning ('off' ,'MATLAB:singularMatrix' ); 
cleanupObj =onCleanup (@()warning (warnState )); 


eta =X *betaBar +U *DeltabBar +delta ; 


ginv =sglme .Link .Inverse ; 
mu =ginv (eta ); 
mu =constrainMu (sglme ,mu ,sglme .Distribution ); 





w =getEffectiveObservationWeights (sglme ); 
switchlower (sglme .FitMethod )
case {'mpl' ,'rempl' }
diagC =getDiagW (sglme ,mu ,w ); 
otherwise
diagC =getDiagC (sglme ,mu ,w ); 
end
diagC =spdiags (diagC ,0 ,N ,N ); 


XtCX =X ' *(diagC *X ); 
CU =diagC *U ; 
XtCU =X ' *CU ; 





Iq =spdiags (ones (q ,1 ),0 ,q ,q ); 
[R ,status ,S ]=chol (U ' *CU +Iq ); 
if(status ~=0 )
error (message ('stats:classreg:regr:lmeutils:StandardGeneralizedLinearMixedModel:BadLaplaceLogLikelihood' )); 
end





Q1 =(XtCU *S )/R ; 
[R1 ,status1 ]=chol (XtCX -Q1 *Q1 ' ,'lower' ); 
if(status1 ~=0 )
error (message ('stats:classreg:regr:lmeutils:StandardGeneralizedLinearMixedModel:BadJointPosteriorCovariance' )); 
end


if(M <=q )
Cb =R ' \(S ' *(Lambda ' *Znew ' )); 
else
Cb =(R ' \(S ' *Lambda ' ))*Znew ' ; 
end
Ca =R1 \(Xnew ' -Q1 *Cb ); 


ifstrcmpi (type ,'variance' )
varpred =sum (Cb .^2 ,1 )+sum (Ca .^2 ,1 ); 
varpred =(sigma ^2 )*varpred ' ; 
else
varpred =sigma ^2 *(Cb ' *Cb +Ca ' *Ca ); 
end
varpred =full (varpred ); 
end

end

end



methods (Access =protected )







function C =covEtaHatLogSigmaHat (sglme )


[~,C ]=covBetaHatEtaHatLogSigmaHat (sglme ); 

end

end


methods (Access =public )

function sglme =StandardGeneralizedLinearMixedModel (X ,y ,Z ,Psi ,FitMethod ,dofit ,dostats ,varargin )

















































































































































































































































































if(nargin ==0 )
return ; 
end


assert (isscalar (dofit )&islogical (dofit )); 
assert (isscalar (dostats )&islogical (dostats )); 


[X ,y ,Z ,Psi ,FitMethod ]=validateInputs (sglme ,X ,y ,Z ,Psi ,FitMethod ); 


[N ,p ]=size (X ); %#ok<*PROP> 
q =size (Z ,2 ); 
sglme .N =N ; 
sglme .p =p ; 
sglme .q =q ; 


sglme .X =X ; 
sglme .y =y ; 
sglme .Z =Z ; 
sglme .Psi =Psi ; 
sglme .FitMethod =FitMethod ; 



dfltDistribution ='normal' ; 
dfltLink =[]; 
dfltOffset =zeros (N ,1 ); 
dfltBinomialSize =ones (N ,1 ); 
dfltWeights =ones (N ,1 ); 
dfltDispersionFlag =false ; 
switchlower (FitMethod )
case {'mpl' ,'rempl' }
dfltOptimizer ='quasinewton' ; 
otherwise
dfltOptimizer ='fminsearch' ; 
end
dfltOptimizerOptions =struct ([]); 
dfltInitializationMethod ='default' ; 
dfltCheckHessian =false ; 
dfltPLIterations =100 ; 
dfltPLTolerance =1e-8 ; 
dfltMuStart =[]; 
dfltInitPLIterations =10 ; 
dfltEBMethod ='default' ; 
dfltEBOptions =statset ('TolFun' ,1e-6 ,'TolX' ,1e-8 ,'MaxIter' ,100 ,'Display' ,'off' ); 
dfltCovarianceMethod ='conditional' ; 
dfltUseAMDPreordering =false ; 
dfltNewtonStepMethod ='cholesky' ; 
dfltMuLowerBound =eps ; 
dfltMuUpperBound =Inf ; 
dfltUseSequentialFitting =false ; 
dfltShowPLOptimizerDisplay =false ; 


paramNames ={'Distribution' ,'Link' ,'Offset' ,'BinomialSize' ,'Weights' ,'DispersionFlag' ,'Optimizer' ,'OptimizerOptions' ,'InitializationMethod' ,'CheckHessian' ,'PLIterations' ,'PLTolerance' ,'MuStart' ,'InitPLIterations' ,'EBMethod' ,'EBOptions' ,'CovarianceMethod' ,'UseAMDPreordering' ,'NewtonStepMethod' ,'MuLowerBound' ,'MuUpperBound' ,'UseSequentialFitting' ,'ShowPLOptimizerDisplay' }; 
paramDflts ={dfltDistribution ,dfltLink ,dfltOffset ,dfltBinomialSize ,dfltWeights ,dfltDispersionFlag ,dfltOptimizer ,dfltOptimizerOptions ,dfltInitializationMethod ,dfltCheckHessian ,dfltPLIterations ,dfltPLTolerance ,dfltMuStart ,dfltInitPLIterations ,dfltEBMethod ,dfltEBOptions ,dfltCovarianceMethod ,dfltUseAMDPreordering ,dfltNewtonStepMethod ,dfltMuLowerBound ,dfltMuUpperBound ,dfltUseSequentialFitting ,dfltShowPLOptimizerDisplay }; 


[distribution ,linkSpec ,offset ,...
    binomialsize ,weights ,dispersionflag ,...
    optimizer ,optimizeroptions ,...
    initializationmethod ,checkhessian ,...
    pliterations ,pltolerance ,mustart ,...
    initpliterations ,...
    ebmethod ,eboptions ,...
    covariancemethod ,...
    useamdpreordering ,...
    newtonstepmethod ,...
    mulowerbound ,muupperbound ,...
    usesequentialfitting ,...
    showploptimizerdisplay ]...
    =internal .stats .parseArgs (paramNames ,paramDflts ,varargin {:}); 



distribution =internal .stats .getParamVal (distribution ,sglme .AllowedDistributions ,'Distribution' ); 



ifisempty (linkSpec )


linkSpec =defaultLink (sglme ,distribution ); 
end
linkStruct =sglme .validateLink (linkSpec ,sglme .FitMethod ); 

checkDistributionLinkCombination (sglme ,distribution ,linkStruct ); 


offset =validateOffset (sglme ,offset ,sglme .N ); 


ifstrcmpi (distribution ,'binomial' )
binomialsize =validateBinomialSize (sglme ,binomialsize ,sglme .N ); 
end


weights =validateWeights (sglme ,weights ,sglme .N ,distribution ); 


dispersionflag =internal .stats .parseOnOff (dispersionflag ,'DispersionFlag' ); 



validateyRange (sglme ,sglme .y ,binomialsize ,weights ,distribution ); 


[optimizer ,optimizeroptions ,initializationmethod ]...
    =validateOptimizationOptions (sglme ,optimizer ,optimizeroptions ,initializationmethod ); 


checkhessian =internal .stats .parseOnOff (checkhessian ,'CheckHessian' ); 


pliterations =validatePLIterations (sglme ,pliterations ); 


pltolerance =validatePLTolerance (sglme ,pltolerance ); 


mustart =validateMuStart (sglme ,mustart ,distribution ,N ); 


initpliterations =validateInitPLIterations (sglme ,initpliterations ); 


[ebmethod ,eboptions ]=validateEBParameters (sglme ,ebmethod ,eboptions ,dfltEBOptions ); 


covariancemethod =internal .stats .getParamVal (covariancemethod ,sglme .AllowedCovarianceMethods ,'CovarianceMethod' ); 


useamdpreordering =internal .stats .parseOnOff (useamdpreordering ,'UseAMDPreordering' ); 


newtonstepmethod =internal .stats .getParamVal (newtonstepmethod ,sglme .AllowedNewtonStepMethods ,'NewtonStepMethod' ); 


[mulowerbound ,muupperbound ]=validateMuBounds (sglme ,mulowerbound ,muupperbound ); 


usesequentialfitting =internal .stats .parseOnOff (usesequentialfitting ,'UseSequentialFitting' ); 


showploptimizerdisplay =internal .stats .parseOnOff (showploptimizerdisplay ,'ShowPLOptimizerDisplay' ); 


sglme .Distribution =distribution ; 
sglme .Link =linkStruct ; 
sglme .Offset =offset ; 
sglme .BinomialSize =binomialsize ; 
sglme .PriorWeights =weights ; 
sglme .DispersionFixed =...
    setDispersionFixed (sglme ,dispersionflag ,distribution ,FitMethod ); 
if(sglme .DispersionFixed ==true )
sglme .isSigmaFixed =true ; 
sglme .sigmaFixed =1.0 ; 
end

sglme .Optimizer =optimizer ; 
sglme .OptimizerOptions =optimizeroptions ; 
sglme .InitializationMethod =initializationmethod ; 
sglme .CheckHessian =checkhessian ; 
sglme .PLIterations =pliterations ; 
sglme .PLTolerance =pltolerance ; 
sglme .MuStart =mustart ; 

sglme .InitPLIterations =initpliterations ; 

sglme .EBMethod =ebmethod ; 
sglme .EBOptions =eboptions ; 

sglme .CovarianceMethod =covariancemethod ; 

sglme .UseAMDPreordering =useamdpreordering ; 




sglme .NewtonStepMethod =newtonstepmethod ; 
switchlower (newtonstepmethod )
case 'cholesky' 
sglme .NewtonStepMethodCode =1 ; 
case 'backslash' 
sglme .NewtonStepMethodCode =2 ; 
end

sglme .MuBound .TINY =mulowerbound ; 
sglme .MuBound .BIG =muupperbound ; 

sglme .UseSequentialFitting =usesequentialfitting ; 

sglme .ShowPLOptimizerDisplay =showploptimizerdisplay ; 


sglme .VarianceFunction =varianceFunction (sglme ,sglme .Distribution ); 


if(dofit ==true )
sglme =refit (sglme ); 

if(dostats ==true )
sglme =initstats (sglme ); 
end
end

end

function sglme =refit (sglme )












switchlower (sglme .FitMethod )
case {'mpl' ,'rempl' }

numIter =sglme .PLIterations ; 
kappa =sglme .PLTolerance ; 
[sglme ,cause ]=fitUsingPL (sglme ,numIter ,kappa ); 
if(cause ==1 )
warning (message ('stats:classreg:regr:lmeutils:StandardGeneralizedLinearMixedModel:Message_PLUnableToConverge' ,numIter )); 
end

case {'approximatelaplace' ,'laplace' ,'quadrature' }

[sglme ,cause ]=fitUsingML (sglme ); 
if(cause ~=0 &&cause ~=1 )
warning (message ('stats:classreg:regr:lmeutils:StandardGeneralizedLinearMixedModel:Message_OptimizerUnableToConverge' ,sglme .Optimizer )); 
end

otherwise
error (message ('stats:classreg:regr:lmeutils:StandardGeneralizedLinearMixedModel:BadFitMethod' )); 
end


sglme .isFitToData =true ; 

end

function sglme =initstats (sglme )


















if(sglme .isFitToData ==false )
error (message ('stats:classreg:regr:lmeutils:StandardGeneralizedLinearMixedModel:MustRefitFirst' )); 
end




switchlower (sglme .FitMethod )
case {'mpl' ,'rempl' }
sglme =initstatsPL (sglme ); 
case {'approximatelaplace' ,'laplace' ,'quadrature' }
sglme =initstatsML (sglme ); 
otherwise
error (message ('stats:classreg:regr:lmeutils:StandardGeneralizedLinearMixedModel:BadFitMethod' )); 
end


sglme .isReadyForStats =true ; 

end

end




methods (Access =public )

function df =dfBetaTTest (slme ,c )%#ok<STOUT,INUSD> 

error (message ('stats:classreg:regr:lmeutils:StandardGeneralizedLinearMixedModel:BadDFMethod' )); 

end

function df =dfBetaFTest (slme ,L )%#ok<STOUT,INUSD> 

error (message ('stats:classreg:regr:lmeutils:StandardGeneralizedLinearMixedModel:BadDFMethod' )); 

end

function df =dfBetaBTTest (slme ,c )%#ok<STOUT,INUSD> 

error (message ('stats:classreg:regr:lmeutils:StandardGeneralizedLinearMixedModel:BadDFMethod' )); 

end

function df =dfBetaBFTest (slme ,L )%#ok<STOUT,INUSD> 

error (message ('stats:classreg:regr:lmeutils:StandardGeneralizedLinearMixedModel:BadDFMethod' )); 

end

end


methods (Access =public )

function crittable =modelCriterion (sglme )












N =sglme .N ; 
p =sglme .p ; 



if(sglme .isSigmaFixed ==true )
stats .NumCoefficients =...
    sglme .Psi .NumParametersExcludingSigma +p ; 
else
stats .NumCoefficients =...
    sglme .Psi .NumParametersExcludingSigma +(p +1 ); 
end


switchlower (sglme .FitMethod )
case {'mpl' ,'approximatelaplace' ,'laplace' ,'quadrature' }
stats .NumObservations =N ; 
case {'rempl' }
stats .NumObservations =(N -p ); 

otherwise

error (message ('stats:classreg:regr:lmeutils:StandardGeneralizedLinearMixedModel:BadFitMethod' )); 
end


switchlower (sglme .FitMethod )
case {'approximatelaplace' ,'laplace' ,'quadrature' }
stats .LogLikelihood =sglme .loglikHat ; 
case {'mpl' ,'rempl' }
stats .LogLikelihood =sglme .loglikHatPseudoData ; 
otherwise

error (message ('stats:classreg:regr:lmeutils:StandardGeneralizedLinearMixedModel:BadFitMethod' )); 
end


crit =classreg .regr .modelutils .modelcriterion (stats ,'all' ,true ); 


Deviance =-2 *stats .LogLikelihood ; 
crittable =table (crit .AIC ,crit .BIC ,stats .LogLikelihood ,Deviance ,...
    'VariableNames' ,{'AIC' ,'BIC' ,'logLik' ,'Deviance' }); 

end

end


methods (Access =public )

function H =postCovb (sglme )










X =sglme .X ; 
delta =sglme .Offset ; 


thetaHat =sglme .thetaHat ; 
betaHat =sglme .betaHat ; 
DeltabHat =sglme .DeltabHat ; 
sigmaHat =sglme .sigmaHat ; 


[U ,Lambda ]=getU (sglme ,thetaHat ); 


eta =X *betaHat +U *DeltabHat +delta ; 


ginv =sglme .Link .Inverse ; 
mu =ginv (eta ); 
mu =constrainMu (sglme ,mu ,sglme .Distribution ); 




w =getEffectiveObservationWeights (sglme ); 
switchlower (sglme .FitMethod )
case {'mpl' ,'rempl' }
diagC =getDiagW (sglme ,mu ,w ); 
otherwise
diagC =getDiagC (sglme ,mu ,w ); 
end



M =getUtCUPlusIdentity (sglme ,U ,diagC ); 
[R ,status ,S ]=chol (M ); 


if(status ~=0 )
error (message ('stats:classreg:regr:lmeutils:StandardGeneralizedLinearMixedModel:BadLaplaceLogLikelihood' )); 
end



T =(Lambda *S )/R ; 
H =(sigmaHat ^2 )*(T *T ' ); 

end

end


methods (Access =public )

function mufit =fitted (sglme ,wantConditional )









assert (islogical (wantConditional )...
    &isscalar (wantConditional )); 


X =sglme .X ; 
betaHat =sglme .betaHat ; 
delta =sglme .Offset ; 
ginv =sglme .Link .Inverse ; 


if(wantConditional ==true )

Z =sglme .Z ; 
bHat =sglme .bHat ; 

etaHat =X *betaHat +Z *bHat +delta ; 
else

etaHat =X *betaHat +delta ; 
end


mufit =ginv (etaHat ); 
mufit =constrainMu (sglme ,mufit ,sglme .Distribution ); 

end

end


methods (Access =public )

function [ypred ,CI ,DF ]=predict (sglme ,Xnew ,Znew ,alpha ,dfmethod ,wantConditional ,wantPointwise ,delta ,hasIntercept )



























wantCurve =true ; 
args ={Xnew ,Znew ,alpha ,dfmethod ,wantConditional ,wantPointwise ,wantCurve ,hasIntercept }; 
switchnargout 
case {0 ,1 }
ypred =predict @classreg .regr .lmeutils .StandardLinearLikeMixedModel (sglme ,args {:}); 
case 2 
[ypred ,CI ]=predict @classreg .regr .lmeutils .StandardLinearLikeMixedModel (sglme ,args {:}); 
case 3 
[ypred ,CI ,DF ]=predict @classreg .regr .lmeutils .StandardLinearLikeMixedModel (sglme ,args {:}); 
end




assert (isnumeric (delta )&isreal (delta )&iscolumn (delta )&size (delta ,1 )==size (ypred ,1 )); 



ginv =sglme .Link .Inverse ; 
distribution =sglme .Distribution ; 
ypred =ginv (ypred +delta ); 
ypred =constrainMu (sglme ,ypred ,distribution ); 
ifnargout >1 
CI =ginv (bsxfun (@plus ,CI ,delta )); 
CI (:,1 )=constrainMu (sglme ,CI (:,1 ),distribution ); 
CI (:,2 )=constrainMu (sglme ,CI (:,2 ),distribution ); 
CI =[min (CI ,[],2 ),max (CI ,[],2 )]; 
end

end

end


methods (Access =public )

function ysim =random (sglme ,S ,Xsim ,Zsim ,delta ,wp ,ntrials ,numreps )





























narginchk (4 ,8 ); 


assert (isnumeric (Xsim )&isreal (Xsim )&ismatrix (Xsim )); 
assert (size (Xsim ,2 )==sglme .p ); 


assert (isnumeric (Zsim )&isreal (Zsim )&ismatrix (Zsim )); 


assert (size (Xsim ,1 )==size (Zsim ,1 )); 


N =size (Xsim ,1 ); 
ifnargin <5 
delta =zeros (N ,1 ); 
end
ifnargin <6 
wp =ones (N ,1 ); 
end
ifnargin <7 
ntrials =ones (N ,1 ); 
end
ifnargin <8 
numreps =sglme .Psi .NumReps ; 
end


assert (isnumeric (delta )&isreal (delta )&iscolumn (delta )); 






ifisempty (numreps )
bsim =zeros (0 ,1 ); 
else
bsim =randomb (sglme ,S ,numreps ); 
end
assert (size (Zsim ,2 )==length (bsim )); 


betaHat =sglme .betaHat ; 
sigmaHat =sglme .sigmaHat ; 



ifisempty (bsim )
eta =Xsim *betaHat +delta ; 
else
eta =Xsim *betaHat +Zsim *bsim +delta ; 
end
mu =sglme .Link .Inverse (eta ); 
mu =constrainMu (sglme ,mu ,sglme .Distribution ); 



ifisempty (S )
ysim =conditionalRandom (sglme ,mu ,sigmaHat ,wp ,ntrials ); 
else
prevS =RandStream .setGlobalStream (S ); 
cleanupObj =onCleanup (@()RandStream .setGlobalStream (prevS )); 
ysim =conditionalRandom (sglme ,mu ,sigmaHat ,wp ,ntrials ); 
end

end

end



methods (Access =protected )

function yrnd =conditionalRandom (sglme ,mu ,sigma ,wp ,ntrials )








distribution =sglme .Distribution ; 


M =size (mu ,1 ); 
mu =validateMuStart (sglme ,mu ,distribution ,M ); 
sigma =validateSigma (sglme ,sigma ); 
wp =validateWeights (sglme ,wp ,M ,distribution ); 


switchlower (distribution )
case 'binomial' 
ntrials =validateBinomialSize (sglme ,ntrials ,M ); 
counts =ntrials .*wp ; 
sumurnd =random ('binomial' ,counts ,mu ,M ,1 ); 
yrnd =sumurnd ./counts ; 
case 'poisson' 
sumurnd =random ('poisson' ,wp .*mu ,M ,1 ); 
yrnd =sumurnd ./wp ; 
case 'gamma' 
a =(1 /(sigma ^2 )); 
awp =a .*wp ; 
b =mu ./awp ; 
yrnd =random ('gamma' ,awp ,b ,M ,1 ); 
case {'inverse gaussian' ,'inversegaussian' }
lambda =(1 /(sigma ^2 )); 
yrnd =random ('inversegaussian' ,mu ,lambda .*wp ,M ,1 ); 
case {'normal' ,'gaussian' }
yrnd =random ('normal' ,mu ,sigma ./sqrt (wp ),M ,1 ); 
end

end

end


methods (Access =protected )

function rawr =getRawResiduals (sglme ,wantConditional )







assert (isscalar (wantConditional )&islogical (wantConditional )); 



mufit =fitted (sglme ,wantConditional ); 
rawr =sglme .y -mufit ; 

end

function pearsonr =getPearsonResiduals (sglme ,wantConditional )







assert (isscalar (wantConditional )...
    &islogical (wantConditional )); 


mufit =fitted (sglme ,wantConditional ); 


rawr =sglme .y -mufit ; 


sigmaHat =sglme .sigmaHat ; 
w =getEffectiveObservationWeights (sglme ); 
v =sglme .VarianceFunction .VarianceFunction ; 
stdvec =sigmaHat *sqrt (v (mufit )./w ); 


pearsonr =rawr ./stdvec ; 

end

function studr =getStudentizedResiduals (sglme ,wantConditional )%#ok<STOUT,INUSD> 




error (message ('stats:classreg:regr:lmeutils:StandardGeneralizedLinearMixedModel:BadResidualType' )); 

end

end


methods (Static )

function optsFsolve =convertOptionsToFSolveOptions (opts ,dfltopts )






assert (isstruct (opts )&isstruct (dfltopts )); 


opts =statset (dfltopts ,opts ); 


optsFsolve =optimoptions ('fsolve' ); 



optsFsolve .TolFun =opts .TolFun ; 
optsFsolve .TolX =opts .TolX ; 
optsFsolve .MaxIter =opts .MaxIter ; 
optsFsolve .Display =opts .Display ; 

end

function pn =computeNewtonStepForB (J ,r ,useamd ,s ,methodcode )








switchmethodcode 
case 1 

if(useamd ==true )
[L ,status ]=chol (J (s ,s ),'lower' ); 
else
[L ,status ,s ]=chol (J ,'lower' ,'vector' ); 
end
if(status ==0 )

pn =r ; 
pn (s )=-(L ' \(L \r (s ))); 
else


pn =(-J )\r ; 
end
case 2 


pn =-(J \r ); 
otherwise
end

end

function pn =computeNewtonStepForBetaB (J ,r ,UtCUIq ,XtCU ,XtCX ,rb ,rbeta ,p ,q ,Iq ,useamd ,s ,methodcode )













switchmethodcode 
case 1 


if(useamd ==true )
[L ,status ]=chol (UtCUIq (s ,s ),'lower' ); 
else
[L ,status ,s ]=chol (UtCUIq ,'lower' ,'vector' ); 
end
if(status ==0 )

S =Iq (:,s ); 
Q1 =(XtCU *S )/L ' ; 
cb =L \(S ' *rb ); 
pn =r ; 
pn (1 :p )=(XtCX -Q1 *Q1 ' )\(rbeta -Q1 *cb ); 
pn (p +1 :p +q )=S *(L ' \(cb -Q1 ' *pn (1 :p ))); 
pn =-pn ; 
else

pn =(-J )\r ; 
end
case 2 

pn =-(J \r ); 
otherwise
end

end

end

end
