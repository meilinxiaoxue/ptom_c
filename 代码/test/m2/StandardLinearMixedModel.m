classdef StandardLinearMixedModel <classreg .regr .lmeutils .StandardLinearLikeMixedModel 










































































































properties (GetAccess =public ,SetAccess =public )

y 


X 


Z 







Psi 



FitMethod 
end


properties (GetAccess =public ,SetAccess =protected )

N 


p 


q 


rankX 
end


properties (GetAccess =public ,SetAccess =protected )


Optimizer ='quasinewton' ; 


OptimizerOptions =struct ([]); 



CheckHessian =false ; 

end


properties (GetAccess =public ,SetAccess =public )



InitializationMethod ='default' ; 

end


properties (GetAccess =public ,SetAccess =protected )

betaHat 



bHat 


DeltabHat 


sigmaHat 


thetaHat 



loglikHat 
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


properties (Constant =true ,Hidden =true )


AllowedFitMethods ={'ML' ,'REML' }; 

end


properties (Access =private )


XtX 


Xty 



XtZ 



Zty 



ZtZ 
end


methods 

function slme =set .y (slme ,newy )

if~isempty (slme .y )

newy =validatey (slme ,newy ); 


slme =invalidateFit (slme ); 
end


slme .y =newy ; 

end

function slme =set .X (slme ,newX )

if~isempty (slme .X )

newX =validateX (slme ,newX ); 


slme =invalidateFit (slme ); 
end


slme .X =newX ; 

end

function slme =set .Z (slme ,newZ )

if~isempty (slme .Z )

newZ =validateZ (slme ,newZ ); 


slme =invalidateFit (slme ); 
end


slme .Z =newZ ; 

end

function slme =set .Psi (slme ,newPsi )

if~isempty (slme .Psi )

newPsi =validatePsi (slme ,newPsi ); 


slme =invalidateFit (slme ); 
end


slme .Psi =newPsi ; 

end

function slme =set .FitMethod (slme ,newFitMethod )

if~isempty (slme .FitMethod )

newFitMethod =validateFitMethod (slme ,newFitMethod ); 


slme =invalidateFit (slme ); 
end


slme .FitMethod =newFitMethod ; 

end

function slme =set .InitializationMethod (slme ,newInitializationMethod )

if~isempty (slme .InitializationMethod )

newInitializationMethod =validateInitializationMethod (slme ,newInitializationMethod ); 


slme =invalidateFit (slme ); 
end


slme .InitializationMethod =newInitializationMethod ; 

end

end


methods (Access =protected )

function FitMethod =validateFitMethod (slme ,FitMethod )%#ok<INUSL> 


FitMethod =internal .stats .getParamVal (FitMethod ,classreg .regr .lmeutils .StandardLinearMixedModel .AllowedFitMethods ,'FitMethod' ); 

end

end


methods (Access =protected )

function fun =makeObjectiveFunctionForMinimization (slme )











switchlower (slme .FitMethod )
case 'ml' 
fun =makeNegBetaSigmaProfiledLogLikelihoodAsFunctionOfTheta (slme ); 
case 'reml' 
fun =makeNegSigmaProfiledRestrictedLogLikelihoodAsFunctionOfTheta (slme ); 
otherwise

error (message ('stats:classreg:regr:lmeutils:StandardLinearMixedModel:BadFitMethod' )); 
end

end

function theta0 =initializeTheta (slme )





switchlower (slme .InitializationMethod )
case 'default' 

theta0 =getUnconstrainedParameters (slme .Psi ); 
case 'random' 

theta0 =getUnconstrainedParameters (slme .Psi ); 
theta0 =randn (length (theta0 ),1 ); 
otherwise

error (message ('stats:classreg:regr:lmeutils:StandardLinearMixedModel:BadInitializationMethod' )); 
end

end

function warnAboutPerfectFit (slme ,theta0 )









[~,~,sigmaHat ,~,~,~]=solveMixedModelEquations (slme ,theta0 ); 


sigmaHatTol =sqrt (eps (class (sigmaHat ))); 
ifabs (sigmaHat )<=sigmaHatTol *std (slme .y )

warning (message ('stats:classreg:regr:lmeutils:StandardLinearMixedModel:Message_PerfectFit' )); 
end

end

function thetaHat =solveForThetaHat (slme )






fun =makeObjectiveFunctionForMinimization (slme ); 


theta0 =initializeTheta (slme ); 


warnAboutPerfectFit (slme ,theta0 ); 



[thetaHat ,cause ]=doMinimization (slme ,fun ,theta0 ); 



if(cause ~=0 &&cause ~=1 )

warning (message ('stats:classreg:regr:lmeutils:StandardLinearMixedModel:Message_OptimizerUnableToConverge' ,slme .Optimizer )); 
end

end

function H =objectiveFunctionHessianAtThetaHat (slme )






fun =makeObjectiveFunctionForMinimization (slme ); 


wantRegularized =false ; 
H =slme .getHessian (fun ,slme .thetaHat ,wantRegularized ); 

end

function checkObjectiveFunctionHessianAtThetaHat (slme )









H =objectiveFunctionHessianAtThetaHat (slme ); 



switchlower (slme .FitMethod )
case 'ml' 

msgID ='stats:classreg:regr:lmeutils:StandardLinearMixedModel:Message_NotSPDHessian_ML' ; 
case 'reml' 

msgID ='stats:classreg:regr:lmeutils:StandardLinearMixedModel:Message_NotSPDHessian_REML' ; 
otherwise

error (message ('stats:classreg:regr:lmeutils:StandardLinearMixedModel:BadFitMethod' )); 
end



slme .checkPositiveDefinite (H ,msgID ); 

end

function [betaHat ,bHat ,sigmaHat ,r2 ,R ,R1 ,Deltab ]=solveMixedModelEquations (slme ,theta )











X =slme .X ; 
y =slme .y ; 
Z =slme .Z ; 
N =slme .N ; 
p =slme .p ; 
q =slme .q ; 
XtX =slme .XtX ; 
Xty =slme .Xty ; 
XtZ =slme .XtZ ; 
Zty =slme .Zty ; 
ZtZ =slme .ZtZ ; 


Psi =slme .Psi ; 
Psi =setUnconstrainedParameters (Psi ,theta ); 
Psi =setSigma (Psi ,1 ); 



Lambda =getLowerTriangularCholeskyFactor (Psi ); 







Iq =spdiags (ones (q ,1 ),0 ,q ,q ); 

[R ,status ,S ]=chol (Lambda ' *ZtZ *Lambda +Iq ); 


if(status ~=0 )

error (message ('stats:classreg:regr:lmeutils:StandardLinearMixedModel:ErrorSparseCholesky' )); 
end





warnState =warning ('query' ,'all' ); 
warning ('off' ,'MATLAB:nearlySingularMatrix' ); 
warning ('off' ,'MATLAB:illConditionedMatrix' ); 
warning ('off' ,'MATLAB:singularMatrix' ); 
cleanupObj =onCleanup (@()warning (warnState )); 




Q1 =((XtZ *Lambda )*S )/R ; 

R1R1t =XtX -Q1 *Q1 ' ; 
try


R1 =chol (R1R1t ,'lower' ); 
catch ME %#ok<NASGU> 


R1 =classreg .regr .lmeutils .covmats .CovarianceMatrix .singularLowerChol (R1R1t ); 
end




cDeltab =R ' \(S ' *((Lambda ' *Zty ))); 

cbeta =R1 \(Xty -Q1 *cDeltab ); 


betaHat =R1 ' \cbeta ; 

Deltab =S *(R \(cDeltab -Q1 ' *betaHat )); 


bHat =Lambda *Deltab ; 


r2 =sum (Deltab .^2 )+sum ((y -X *betaHat -Z *bHat ).^2 ); 


ifslme .isSigmaFixed 
sigmaHat =slme .sigmaFixed ; 
else
switchlower (slme .FitMethod )
case 'ml' 
sigma2 =r2 /N ; 
sigmaHat =sqrt (sigma2 ); 
case 'reml' 
sigma2 =r2 /(N -p ); 
sigmaHat =sqrt (sigma2 ); 
otherwise

error (message ('stats:classreg:regr:lmeutils:StandardLinearMixedModel:BadFitMethod' )); 
end
end




end

function [pred ,varpred ]=getEstimateAndVariance (slme ,Xnew ,Znew ,betaBar ,DeltabBar ,theta ,sigma ,type )




























ifnargin <8 
type ='variance' ; 
end


M =size (Xnew ,1 ); 
p =size (Xnew ,2 ); 
q =size (Znew ,2 ); 
assert (size (Znew ,1 )==M ); 
assert (p ==slme .p &&q ==slme .q ); 
assert (size (betaBar ,1 )==p &&size (betaBar ,2 )==1 ); 
assert (size (DeltabBar ,1 )==q &&size (DeltabBar ,2 )==1 ); 


ifslme .isSigmaFixed 
sigma =slme .sigmaFixed ; 
end


Psi =slme .Psi ; 
Psi =Psi .setUnconstrainedParameters (theta ); 
Lambda =getLowerTriangularCholeskyFactor (Psi ); 


pred =Xnew *betaBar +Znew *(Lambda *DeltabBar ); 
pred =full (pred ); 


ifnargout >1 
warnState =warning ('query' ,'all' ); 
warning ('off' ,'MATLAB:nearlySingularMatrix' ); 
warning ('off' ,'MATLAB:illConditionedMatrix' ); 
warning ('off' ,'MATLAB:singularMatrix' ); 
cleanupObj =onCleanup (@()warning (warnState )); 



X =slme .X ; 
Z =slme .Z ; 
U =Z *Lambda ; 
Iq =spdiags (ones (q ,1 ),0 ,q ,q ); 
[R ,status ,S ]=chol (U ' *U +Iq ); 
if(status ~=0 )
error (message ('stats:classreg:regr:lmeutils:StandardLinearMixedModel:ErrorSparseCholesky' )); 
end
Q1 =(X ' *U *S )/R ; 
try
R1 =chol (X ' *X -Q1 *Q1 ' ,'lower' ); 
catch ME %#ok<NASGU> 

R1 =classreg .regr .lmeutils .covmats .CovarianceMatrix .singularLowerChol (X ' *X -Q1 *Q1 ' ); 
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

function fun =makeNegBetaSigmaProfiledLogLikelihoodAsFunctionOfTheta (slme )




fun =@f0 ; 
function y0 =f0 (theta )
L =BetaSigmaProfiledLogLikelihood (slme ,theta ); 
y0 =-1 *L ; 

y0 =max (-realmax ,y0 ); 
end

end

function fun =makeNegSigmaProfiledRestrictedLogLikelihoodAsFunctionOfTheta (slme )




fun =@f1 ; 
function y1 =f1 (theta )
L =SigmaProfiledRestrictedLogLikelihood (slme ,theta ); 
y1 =-1 *L ; 

y1 =max (-realmax ,y1 ); 
end

end

function fun =makeNegBetaProfiledLogLikelihoodAsFunctionOfThetaLogSigma (slme )




fun =@f2 ; 
function y2 =f2 (x )

theta =x (1 :end-1 ); 
logsigma =x (end); 


sigma =exp (logsigma ); 
L =BetaProfiledLogLikelihood (slme ,theta ,sigma ); 
y2 =-1 *L ; 
end

end

function fun =makeNegRestrictedLogLikelihoodAsFunctionOfThetaLogSigma (slme )




fun =@f3 ; 
function y3 =f3 (x )

theta =x (1 :end-1 ); 
logsigma =x (end); 


sigma =exp (logsigma ); 
L =RestrictedLogLikelihood (slme ,theta ,sigma ); 
y3 =-1 *L ; 
end

end

function fun =makeNegBetaProfiledLogLikelihoodAsFunctionOfEtaLogSigma (slme )





fun =@f6 ; 
function y6 =f6 (x )

eta =x (1 :end-1 ); 
logsigma =x (end); 
ifslme .isSigmaFixed 
sigma =slme .sigmaFixed ; 
else
sigma =exp (logsigma ); 
end

Psi =slme .Psi ; 
Psi =setSigma (Psi ,sigma ); 
Psi =setNaturalParameters (Psi ,eta ); 

theta =getUnconstrainedParameters (Psi ); 


L =BetaProfiledLogLikelihood (slme ,theta ,sigma ); 
y6 =-1 *L ; 
end

end

function fun =makeNegRestrictedLogLikelihoodAsFunctionOfEtaLogSigma (slme )




fun =@f7 ; 
function y7 =f7 (x )

eta =x (1 :end-1 ); 
logsigma =x (end); 
ifslme .isSigmaFixed 
sigma =slme .sigmaFixed ; 
else
sigma =exp (logsigma ); 
end

Psi =slme .Psi ; 
Psi =setSigma (Psi ,sigma ); 
Psi =setNaturalParameters (Psi ,eta ); 

theta =getUnconstrainedParameters (Psi ); 


L =RestrictedLogLikelihood (slme ,theta ,sigma ); 
y7 =-1 *L ; 
end


end

end


methods (Access =protected )

function LogLik =LogLikelihood (slme ,theta ,sigma ,beta )





ifslme .isSigmaFixed 
sigma =slme .sigmaFixed ; 
end


X =slme .X ; 
y =slme .y ; 
Z =slme .Z ; 
N =slme .N ; 
q =slme .q ; 


Psi =slme .Psi ; 
Psi =setUnconstrainedParameters (Psi ,theta ); 
Psi =setSigma (Psi ,1 ); 



Lambda =getLowerTriangularCholeskyFactor (Psi ); 


U =Z *Lambda ; 




Iq =spdiags (ones (q ,1 ),0 ,q ,q ); 
[R ,status ,S ]=chol (U ' *U +Iq ); 


if(status ~=0 )

error (message ('stats:classreg:regr:lmeutils:StandardLinearMixedModel:ErrorSparseCholesky' )); 
end


P1 =S *R ' ; 


Deltab =P1 ' \(P1 \(U ' *(y -X *beta ))); 


b =Lambda *Deltab ; 


r2 =sum (Deltab .^2 )+sum ((y -X *beta -Z *b ).^2 ); 


logAbsDetR =slme .logAbsDetTriangular (R ); 


sigma2 =sigma ^2 ; 
LogLik =(-N /2 )*log (2 *pi *sigma2 )-r2 /(2 *sigma2 )-logAbsDetR ; 

end

function PLogLik =BetaSigmaProfiledLogLikelihood (slme ,theta )





ifslme .isSigmaFixed 
PLogLik =BetaProfiledLogLikelihood (slme ,theta ,slme .sigmaFixed ); 
else


[~,~,~,r2 ,R ,~]=solveMixedModelEquations (slme ,theta ); 


logAbsDetR =slme .logAbsDetTriangular (R ); 


N =slme .N ; 
PLogLik =(-N /2 )*(1 +log (2 *pi *r2 /N ))-logAbsDetR ; 
end

end

function PLogLik =BetaProfiledLogLikelihood (slme ,theta ,sigma )





ifslme .isSigmaFixed 
sigma =slme .sigmaFixed ; 
end



[~,~,~,r2 ,R ,~]=solveMixedModelEquations (slme ,theta ); 


logAbsDetR =slme .logAbsDetTriangular (R ); 


N =slme .N ; 
sigma2 =sigma ^2 ; 
PLogLik =(-N /2 )*log (2 *pi *sigma2 )-r2 /(2 *sigma2 )-logAbsDetR ; 

end

function PRLogLik =SigmaProfiledRestrictedLogLikelihood (slme ,theta )





ifslme .isSigmaFixed 
PRLogLik =RestrictedLogLikelihood (slme ,theta ,slme .sigmaFixed ); 
else


[~,~,~,r2 ,R ,R1 ]=solveMixedModelEquations (slme ,theta ); 



logAbsDetR =slme .logAbsDetTriangular (R ); 
logAbsDetR1 =slme .logAbsDetTriangular (R1 ); 


N =slme .N ; 
p =slme .p ; 
PRLogLik =(-(N -p )/2 )*(1 +log (2 *pi *r2 /(N -p )))...
    -logAbsDetR -logAbsDetR1 ; 
end
end

function RLogLik =RestrictedLogLikelihood (slme ,theta ,sigma )





ifslme .isSigmaFixed 
sigma =slme .sigmaFixed ; 
end



[~,~,~,r2 ,R ,R1 ]=solveMixedModelEquations (slme ,theta ); 



logAbsDetR =slme .logAbsDetTriangular (R ); 
logAbsDetR1 =slme .logAbsDetTriangular (R1 ); 


N =slme .N ; 
p =slme .p ; 
sigma2 =sigma ^2 ; 
RLogLik =(-(N -p )/2 )*log (2 *pi *sigma2 )-r2 /(2 *sigma2 )...
    -logAbsDetR -logAbsDetR1 ; 

end

end


methods (Access =protected )

function covbetaHat =covBetaHatAsFunctionOfThetaSigma (slme ,theta ,sigma )




ifslme .isSigmaFixed 
sigma =slme .sigmaFixed ; 
end


[~,~,~,~,~,R1 ]=solveMixedModelEquations (slme ,theta ); 



sigma2 =sigma ^2 ; 
invR1 =R1 \eye (size (R1 )); 
covbetaHat =sigma2 *(invR1 ' *invR1 ); 

end

function f =makecovcTBetaHatAsFunctionOfThetaLogSigma (slme ,c )




f =@f4 ; 
function ret =f4 (x )
theta =x (1 :end-1 ); 
logsigma =x (end); 
sigma =exp (logsigma ); 
ret =c ' *covBetaHatAsFunctionOfThetaSigma (slme ,theta ,sigma )*c ; 
end

end

function covbetaHatbHat =covBetaHatBHatAsFunctionOfThetaSigma (slme ,theta ,sigma )




ifslme .isSigmaFixed 
sigma =slme .sigmaFixed ; 
end


X =slme .X ; 
Z =slme .Z ; 
p =slme .p ; 
q =slme .q ; 


Psi =slme .Psi ; 
Psi =Psi .setUnconstrainedParameters (theta ); 


Lambda =getLowerTriangularCholeskyFactor (Psi ); 


U =Z *Lambda ; 


M =zeros (p +q ); 
M (1 :p ,1 :p )=X ' *X ; 
M (1 :p ,p +1 :end)=X ' *U ; 
M (p +1 :end,1 :p )=M (1 :p ,p +1 :end)' ; 
M (p +1 :end,p +1 :end)=U ' *U +eye (q ); 


try
C =chol (M ,'lower' ); 
catch ME %#ok<NASGU> 
C =classreg .regr .lmeutils .covmats .CovarianceMatrix .singularLowerChol (M ); 
end


G =zeros (p +q ); 
G (1 :p ,1 :p )=eye (p ); 
G (p +1 :end,p +1 :end)=Lambda ' ; 


T =C \G ; 


covbetaHatbHat =(sigma ^2 )*(T ' *T ); 

end

function f =makecovcTBetaHatBHatAsFunctionOfThetaLogSigma (slme ,c )




f =@f5 ; 
function ret =f5 (x )
theta =x (1 :end-1 ); 
logsigma =x (end); 
sigma =exp (logsigma ); 







p =slme .p ; 
q =slme .q ; 
Xnew =c (1 :p ,1 )' ; 
Znew =c (p +1 :p +q ,1 )' ; 
betaBar =NaN (p ,1 ); 
DeltabBar =NaN (q ,1 ); 
[~,ret ]=getEstimateAndVariance (slme ,Xnew ,Znew ,betaBar ,DeltabBar ,theta ,sigma ); 
end

end


function C =covBetaHatBHat (slme )





ifisempty (slme .covbetaHatbHat )
C =covBetaHatBHatAsFunctionOfThetaSigma (slme ,...
    slme .thetaHat ,slme .sigmaHat ); 
else
C =slme .covbetaHatbHat ; 
end

end

end



methods (Access =protected )

function C =covThetaHatLogSigmaHat (slme )





x =[slme .thetaHat ; log (slme .sigmaHat )]; 


switchlower (slme .FitMethod )
case 'ml' 



fun =makeNegBetaProfiledLogLikelihoodAsFunctionOfThetaLogSigma (slme ); 
case 'reml' 



fun =makeNegRestrictedLogLikelihoodAsFunctionOfThetaLogSigma (slme ); 
end


wantRegularized =false ; 
H =slme .getHessian (fun ,x ,wantRegularized ); 




warnState =warning ('query' ,'all' ); 
warning ('off' ,'MATLAB:singularMatrix' ); 
warning ('off' ,'MATLAB:illConditionedMatrix' ); 
warning ('off' ,'MATLAB:nearlySingularMatrix' ); 
cleanupObj =onCleanup (@()warning (warnState )); 



ifslme .isSigmaFixed 
n =size (H ,1 ); 
ifn ==1 


C =0 ; 
else




C =zeros (n ); 
m =n -1 ; 
C (1 :m ,1 :m )=H (1 :m ,1 :m )\eye (m ); 
end
else
C =H \eye (size (H )); 

end

end

function C =covEtaHatLogSigmaHat (slme )






etaHat =getNaturalParameters (slme .Psi ); 
sigmaHat =slme .sigmaHat ; 


x =[etaHat ; log (sigmaHat )]; 


switchlower (slme .FitMethod )
case 'ml' 



fun =makeNegBetaProfiledLogLikelihoodAsFunctionOfEtaLogSigma (slme ); 
case 'reml' 


fun =makeNegRestrictedLogLikelihoodAsFunctionOfEtaLogSigma (slme ); 
end


wantRegularized =false ; 
try
H =slme .getHessian (fun ,x ,wantRegularized ); 
catch ME %#ok<NASGU> 
H =NaN (length (x )); 
end




warnState =warning ('query' ,'all' ); 
warning ('off' ,'MATLAB:singularMatrix' ); 
warning ('off' ,'MATLAB:illConditionedMatrix' ); 
warning ('off' ,'MATLAB:nearlySingularMatrix' ); 
cleanupObj =onCleanup (@()warning (warnState )); 

try
C =slme .covarianceOnNaturalScale (H ); 


catch ME %#ok<NASGU> 
C =H \eye (size (H )); 
end




ifslme .isSigmaFixed 
C (end,:)=0 ; 
C (:,end)=0 ; 
end

end
































end


methods (Access =public )

function slme =StandardLinearMixedModel (X ,y ,Z ,Psi ,FitMethod ,dofit ,dostats ,varargin )


























































if(nargin ==0 )
return ; 
end


assert (isscalar (dofit )&islogical (dofit )); 
assert (isscalar (dostats )&islogical (dostats )); 


[X ,y ,Z ,Psi ,FitMethod ]=validateInputs (slme ,X ,y ,Z ,Psi ,FitMethod ); 


[N ,p ]=size (X ); %#ok<*PROP> 
q =size (Z ,2 ); 
slme .N =N ; 
slme .p =p ; 
slme .q =q ; 


slme .X =X ; 
slme .y =y ; 
slme .Z =Z ; 
slme .Psi =Psi ; 
slme .FitMethod =FitMethod ; 



dfltOptimizer ='quasinewton' ; 
dfltOptimizerOptions =struct ([]); 
dfltInitializationMethod ='default' ; 
dfltCheckHessian =false ; 
dfltResidualStd =NaN ; 


paramNames ={'Optimizer' ,'OptimizerOptions' ,'InitializationMethod' ,'CheckHessian' ,'ResidualStd' }; 
paramDflts ={dfltOptimizer ,dfltOptimizerOptions ,dfltInitializationMethod ,dfltCheckHessian ,dfltResidualStd }; 


[optimizer ,optimizeroptions ,initializationmethod ,checkhessian ,sigmafixed ]...
    =internal .stats .parseArgs (paramNames ,paramDflts ,varargin {:}); 


[optimizer ,optimizeroptions ,initializationmethod ]...
    =validateOptimizationOptions (slme ,optimizer ,optimizeroptions ,initializationmethod ); 


checkhessian =internal .stats .parseOnOff (checkhessian ,'CheckHessian' ); 
if~isnan (sigmafixed )
sigmafixed =validateSigma (slme ,sigmafixed ); 
end



slme .Optimizer =optimizer ; 
slme .OptimizerOptions =optimizeroptions ; 
slme .InitializationMethod =initializationmethod ; 
slme .CheckHessian =checkhessian ; 
if~isnan (sigmafixed )
slme .isSigmaFixed =true ; 
slme .sigmaFixed =sigmafixed ; 
end


if(dofit ==true )
slme =refit (slme ); 

if(dostats ==true )
slme =initstats (slme ); 
end
end

end

function slme =refit (slme )











X =slme .X ; 
y =slme .y ; 
Z =slme .Z ; 
slme .XtX =X ' *X ; 
slme .Xty =X ' *y ; 
slme .XtZ =X ' *Z ; 
slme .Zty =Z ' *y ; 
slme .ZtZ =Z ' *Z ; 


slme .thetaHat =solveForThetaHat (slme ); 




[slme .betaHat ,slme .bHat ,slme .sigmaHat ,~,~,~,slme .DeltabHat ]=...
    solveMixedModelEquations (slme ,slme .thetaHat ); 


switchlower (slme .FitMethod )
case 'ml' 
slme .loglikHat =...
    BetaSigmaProfiledLogLikelihood (slme ,slme .thetaHat ); 
case 'reml' 
slme .loglikHat =...
    SigmaProfiledRestrictedLogLikelihood (slme ,slme .thetaHat ); 
otherwise

error (message ('stats:classreg:regr:lmeutils:StandardLinearMixedModel:BadFitMethod' )); 
end


slme .Psi =setUnconstrainedParameters (slme .Psi ,slme .thetaHat ); 
slme .Psi =setSigma (slme .Psi ,slme .sigmaHat ); 


slme .isFitToData =true ; 

end

function slme =initstats (slme )







if(slme .isFitToData ==false )

error (message ('stats:classreg:regr:lmeutils:StandardLinearMixedModel:MustRefitFirst' )); 
end


ifslme .CheckHessian ==true 
checkObjectiveFunctionHessianAtThetaHat (slme ); 
end




slme .rankX =slme .p ; 


slme .covbetaHat =...
    covBetaHatAsFunctionOfThetaSigma (slme ,slme .thetaHat ,slme .sigmaHat ); 



slme .covthetaHatlogsigmaHat =covThetaHatLogSigmaHat (slme ); 



ifslme .CheckHessian ==true 

msg1ID ='stats:classreg:regr:lmeutils:StandardLinearMixedModel:Message_NotSPDCovarianceUnconstrainedScale' ; 
slme .checkPositiveDefinite (slme .covthetaHatlogsigmaHat ,msg1ID ); 
end



slme .covetaHatlogsigmaHat =covEtaHatLogSigmaHat (slme ); 



ifslme .CheckHessian ==true 

msg2ID ='stats:classreg:regr:lmeutils:StandardLinearMixedModel:Message_NotSPDCovarianceNaturalScale' ; 
slme .checkPositiveDefinite (slme .covetaHatlogsigmaHat ,msg2ID ); 
end









slme .isReadyForStats =true ; 

end

end


methods (Access =public )

function df =dfBetaTTest (slme ,c )







ifsize (c ,1 )==1 
c =c ' ; 
end
assert (all (size (c )==[slme .p ,1 ])); 




ctVcfun =makecovcTBetaHatAsFunctionOfThetaLogSigma (slme ,c ); 


x =[slme .thetaHat ; log (slme .sigmaHat )]; 


gHat =slme .getGradient (ctVcfun ,x ); 



CHat =slme .covthetaHatlogsigmaHat ; 


df =2 *(ctVcfun (x ))^2 /(gHat ' *CHat *gHat ); 


df =max (0 ,df ); 

end

function df =dfBetaFTest (slme ,L )







r =size (L ,1 ); 
assert (size (L ,2 )==slme .p &r <=slme .p ); 
assert (rank (L )==r ); 


V =slme .covbetaHat ; 


[Veig ,Lambdaeig ]=eig (L *V *L ' ); 
Lambdaeig =diag (Lambdaeig ); 


U =Veig ' ; 


B =U *L ; 


x =[slme .thetaHat ; log (slme .sigmaHat )]; 


C =slme .covthetaHatlogsigmaHat ; 


nu =zeros (r ,1 ); 
fori =1 :r 


bi =B (i ,:)' ; 
fi =makecovcTBetaHatAsFunctionOfThetaLogSigma (slme ,bi ); 


gi =slme .getGradient (fi ,x ); 


nu (i )=2 *(Lambdaeig (i )^2 )/(gi ' *C *gi ); 
end


nu =nu ((nu >2 )); 
ifisempty (nu )
G =0 ; 
else
G =sum ((nu ./(nu -2 ))); 
end



if(G >r )
df =2 *G /(G -r ); 
else
df =0 ; 
end

end

function df =dfBetaBTTest (slme ,c )







ifsize (c ,1 )==1 
c =c ' ; 
end
assert (all (size (c )==[slme .p +slme .q ,1 ])); 




ctVcfun =makecovcTBetaHatBHatAsFunctionOfThetaLogSigma (slme ,c ); 


x =[slme .thetaHat ; log (slme .sigmaHat )]; 


gHat =slme .getGradient (ctVcfun ,x ); 



CHat =slme .covthetaHatlogsigmaHat ; 


df =2 *(ctVcfun (x ))^2 /(gHat ' *CHat *gHat ); 


df =max (0 ,df ); 

end

function df =dfBetaBFTest (slme ,L )







r =size (L ,1 ); 
assert (size (L ,2 )==(slme .p +slme .q )&r <=(slme .p +slme .q )); 
assert (rank (L )==r ); 






p =slme .p ; 
q =slme .q ; 
Xnew =L (:,1 :p ); 
Znew =L (:,p +1 :p +q ); 
[~,LVLt ]=getEstimateAndVariance (slme ,Xnew ,Znew ,slme .betaHat ,...
    slme .DeltabHat ,slme .thetaHat ,slme .sigmaHat ,'covariance' ); 



[Veig ,Lambdaeig ]=eig (LVLt ); 
Lambdaeig =diag (Lambdaeig ); 


U =Veig ' ; 


B =U *L ; 


x =[slme .thetaHat ; log (slme .sigmaHat )]; 


C =slme .covthetaHatlogsigmaHat ; 


nu =zeros (r ,1 ); 
fori =1 :r 


bi =B (i ,:)' ; 
fi =makecovcTBetaHatBHatAsFunctionOfThetaLogSigma (slme ,bi ); 

gi =slme .getGradient (fi ,x ); 


nu (i )=2 *(Lambdaeig (i )^2 )/(gi ' *C *gi ); 
end


G =sum ((nu ./(nu -2 )).*(nu >2 )); 


if(G >r )
df =2 *G /(G -r ); 
else
df =0 ; 
end

end

end


methods (Access =public )

function crittable =modelCriterion (slme )












N =slme .N ; 
p =slme .p ; 


ifslme .isSigmaFixed 

stats .NumCoefficients =...
    slme .Psi .NumParametersExcludingSigma +p ; 
else

stats .NumCoefficients =...
    slme .Psi .NumParametersExcludingSigma +(p +1 ); 
end


switchlower (slme .FitMethod )
case {'ml' }
stats .NumObservations =N ; 
case {'reml' }
stats .NumObservations =(N -p ); 
otherwise
error (message ('stats:classreg:regr:lmeutils:StandardLinearMixedModel:BadFitMethod' )); 
end


loglikHat =slme .loglikHat ; 
stats .LogLikelihood =loglikHat ; 


crit =classreg .regr .modelutils .modelcriterion (stats ,'all' ,true ); 


Deviance =-2 *loglikHat ; 
crittable =table (crit .AIC ,crit .BIC ,loglikHat ,Deviance ,...
    'VariableNames' ,{'AIC' ,'BIC' ,'logLik' ,'Deviance' }); 

end

end


methods (Access =public )

function C =postCovb (slme )










Lambda =getLowerTriangularCholeskyFactor (slme .Psi ); 


Z =slme .Z ; 
q =slme .q ; 


U =Z *Lambda ; 



Iq =spdiags (ones (q ,1 ),0 ,q ,q ); 
[R ,status ,S ]=chol (U ' *U +Iq ); 


if(status ~=0 )

error (message ('stats:classreg:regr:lmeutils:StandardLinearMixedModel:ErrorPostCovb' )); 
end


sigmaHat =slme .sigmaHat ; 




T =(Lambda *S )/R ; 
C =(sigmaHat ^2 )*(T *T ' ); 

end

end


methods (Access =public )

function yfit =fitted (slme ,wantConditional )










assert (islogical (wantConditional )&isscalar (wantConditional )); 


if(wantConditional ==true )
yfit =slme .X *slme .betaHat +slme .Z *slme .bHat ; 
else
yfit =slme .X *slme .betaHat ; 
end

end

end


methods (Access =public )

function [ypred ,CI ,DF ]=predict (slme ,Xnew ,Znew ,alpha ,dfmethod ,wantConditional ,wantPointwise ,wantCurve ,hasIntercept )


























args ={Xnew ,Znew ,alpha ,dfmethod ,wantConditional ,wantPointwise ,wantCurve ,hasIntercept }; 
switchnargout 
case {0 ,1 }
ypred =predict @classreg .regr .lmeutils .StandardLinearLikeMixedModel (slme ,args {:}); 
case 2 
[ypred ,CI ]=predict @classreg .regr .lmeutils .StandardLinearLikeMixedModel (slme ,args {:}); 
case 3 
[ypred ,CI ,DF ]=predict @classreg .regr .lmeutils .StandardLinearLikeMixedModel (slme ,args {:}); 
end



end

end


methods (Access =public )

function ysim =random (slme ,S ,Xsim ,Zsim )









assert (isnumeric (Xsim )&isreal (Xsim )&ismatrix (Xsim )); 
assert (size (Xsim ,2 )==slme .p ); 


assert (isnumeric (Zsim )&isreal (Zsim )&ismatrix (Zsim )); 
assert (size (Zsim ,2 )==slme .q ); 


assert (size (Xsim ,1 )==size (Zsim ,1 )); 


Psi =slme .Psi ; 
betaHat =slme .betaHat ; 
sigmaHat =slme .sigmaHat ; 


NumReps =Psi .NumReps ; 








bsim =randomb (slme ,S ,NumReps ); 


N =size (Xsim ,1 ); 
ifisempty (S )

epsilonsim =sigmaHat *randn (N ,1 ); 
else

epsilonsim =sigmaHat *randn (S ,N ,1 ); 
end


ifisempty (bsim )

ysim =Xsim *betaHat +epsilonsim ; 
else
ysim =Xsim *betaHat +Zsim *bsim +epsilonsim ; 
end

end

end


methods (Access =protected )


function rawr =getRawResiduals (slme ,wantConditional )







assert (isscalar (wantConditional )&islogical (wantConditional )); 


if(wantConditional ==true )

rawr =slme .y -slme .X *slme .betaHat -slme .Z *slme .bHat ; 
else

rawr =slme .y -slme .X *slme .betaHat ; 
end

end


function pearsonr =getPearsonResiduals (slme ,wantConditional )







assert (isscalar (wantConditional )&islogical (wantConditional )); 


if(wantConditional ==true )



rawr =getRawResiduals (slme ,true ); 



stdvec =slme .sigmaHat ; 


pearsonr =rawr ./stdvec ; 

else



rawr =getRawResiduals (slme ,false ); 

















sigmaHat =slme .sigmaHat ; 
Lambda =getLowerTriangularCholeskyFactor (slme .Psi ); 


U =slme .Z *Lambda ; 


diaginvH =(sum (U .^2 ,2 )+1 ); 
stdvec =sigmaHat *sqrt (diaginvH ); 


pearsonr =rawr ./stdvec ; 
end

end



function studr =getStudentizedResiduals (slme ,wantConditional )







assert (isscalar (wantConditional )&islogical (wantConditional )); 


sigmaHat =slme .sigmaHat ; 
X =slme .X ; 
Z =slme .Z ; 
q =slme .q ; 
Lambda =getLowerTriangularCholeskyFactor (slme .Psi ); 
U =Z *Lambda ; 



Iq =spdiags (ones (q ,1 ),0 ,q ,q ); 
[R ,status ,S ]=chol (U ' *U +Iq ); 


if(status ~=0 )

error (message ('stats:classreg:regr:lmeutils:StandardLinearMixedModel:ErrorStandardizedResiduals' )); 
end



T =Lambda *S /R ; 





try
Q =X ' *Z *T ; 
R1 =chol (X ' *X -Q *Q ' ,'lower' ); 
catch ME %#ok<NASGU> 
R1 =classreg .regr .lmeutils .covmats .CovarianceMatrix .singularLowerChol (X ' *X -Q *Q ' ); 
end


if(wantConditional ==true )



rawr =getRawResiduals (slme ,true ); 


















HX =X -(Z *T )*(T ' *Z ' *X ); 


diagHFH =1 -sum ((Z *T ).^2 ,2 )-sum ((HX /R1 ' ).^2 ,2 ); 


stdvec =sigmaHat *sqrt (diagHFH ); 


studr =rawr ./stdvec ; 

else



rawr =getRawResiduals (slme ,false ); 

















diagF =1 +sum ((U .^2 ),2 )-sum ((X /R1 ' ).^2 ,2 ); 


stdvec =sigmaHat *sqrt (diagF ); 


studr =rawr ./stdvec ; 
end

end

end

end