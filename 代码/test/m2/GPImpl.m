classdef GPImpl <classreg .learning .impl .CompactGPImpl 




properties 

X =[]; 
y =[]; 


BadNegativeLogLikelihood =1e20 ; 









































ActiveSetHistory =[]; 













BCDHistory =[]; 
end


methods (Access =protected )
function this =GPImpl ()
this =this @classreg .learning .impl .CompactGPImpl (); 
end
end


methods (Static )
function this =make (X ,y ,...
    kernelFunction ,...
    kernelParameters ,...
    basisFunction ,...
    beta ,...
    sigma ,...
    fitMethod ,...
    predictMethod ,...
    activeSet ,...
    activeSetSize ,...
    activeSetMethod ,...
    standardize ,...
    verbose ,...
    cacheSize ,...
    options ,...
    optimizer ,...
    optimizerOptions ,...
    constantKernelParameters ,...
    constantSigma ,...
    initialStepSize ,...
    iscat ,...
    vrange )
[X ,catcols ]=classreg .learning .internal .expandCategorical (X ,iscat ,vrange ); 



this =classreg .learning .impl .GPImpl (); 








if(standardize )
[X ,StdMu ,StdSigma ]=classreg .learning .gputils .standardizeData (X ,standardize &~catcols ); 
this .StdMu =StdMu ; 
this .StdSigma =StdSigma ; 
else

this .StdMu =[]; 
this .StdSigma =[]; 
end


this .X =X ; 
this .y =y ; 




import classreg.learning.modelparams.GPParams ; 
ifisempty (kernelParameters )
ifinternal .stats .isString (kernelFunction )

tiny =1e-3 ; 
switchlower (kernelFunction )
case lower (GPParams .Exponential )
sigmaL0 =max (tiny ,mean (nanstd (X ))); 
sigmaF0 =max (tiny ,nanstd (y )/sqrt (2 )); 
kernelParameters =[sigmaL0 ; sigmaF0 ]; 
case lower (GPParams .SquaredExponential )
sigmaL0 =max (tiny ,mean (nanstd (X ))); 
sigmaF0 =max (tiny ,nanstd (y )/sqrt (2 )); 
kernelParameters =[sigmaL0 ; sigmaF0 ]; 
case lower (GPParams .Matern32 )
sigmaL0 =max (tiny ,mean (nanstd (X ))); 
sigmaF0 =max (tiny ,nanstd (y )/sqrt (2 )); 
kernelParameters =[sigmaL0 ; sigmaF0 ]; 
case lower (GPParams .Matern52 )
sigmaL0 =max (tiny ,mean (nanstd (X ))); 
sigmaF0 =max (tiny ,nanstd (y )/sqrt (2 )); 
kernelParameters =[sigmaL0 ; sigmaF0 ]; 
case lower (GPParams .RationalQuadratic )
sigmaL0 =max (tiny ,mean (nanstd (X ))); 
alpha =1 ; 
sigmaF0 =max (tiny ,nanstd (y )/sqrt (2 )); 
kernelParameters =[sigmaL0 ; alpha ; sigmaF0 ]; 
case lower (GPParams .ExponentialARD )
sigmaL0 =max (tiny ,nanstd (X ))' ; 
sigmaF0 =max (tiny ,nanstd (y )/sqrt (2 )); 
kernelParameters =[sigmaL0 ; sigmaF0 ]; 
case lower (GPParams .SquaredExponentialARD )
sigmaL0 =max (tiny ,nanstd (X ))' ; 
sigmaF0 =max (tiny ,nanstd (y )/sqrt (2 )); 
kernelParameters =[sigmaL0 ; sigmaF0 ]; 
case lower (GPParams .Matern32ARD )
sigmaL0 =max (tiny ,nanstd (X ))' ; 
sigmaF0 =max (tiny ,nanstd (y )/sqrt (2 )); 
kernelParameters =[sigmaL0 ; sigmaF0 ]; 
case lower (GPParams .Matern52ARD )
sigmaL0 =max (tiny ,nanstd (X ))' ; 
sigmaF0 =max (tiny ,nanstd (y )/sqrt (2 )); 
kernelParameters =[sigmaL0 ; sigmaF0 ]; 
case lower (GPParams .RationalQuadraticARD )
sigmaL0 =max (tiny ,nanstd (X ))' ; 
alpha =1 ; 
sigmaF0 =max (tiny ,nanstd (y )/sqrt (2 )); 
kernelParameters =[sigmaL0 ; alpha ; sigmaF0 ]; 
end
end
end



ifisempty (constantKernelParameters )
constantKernelParameters =false (size (kernelParameters )); 
else
if~isequal (size (constantKernelParameters ),size (kernelParameters ))
error (message ('stats:classreg:learning:impl:GPImpl:GPImpl:BadConstantKernelParametersSize' ,...
    size (kernelParameters ,1 ),size (kernelParameters ,2 ))); 
end
end


ifisempty (sigma )
tiny =1e-3 ; 
sigma =max (tiny ,nanstd (y )/sqrt (2 )); 
end


ifisempty (constantSigma )
constantSigma =false ; 
end


ifisempty (options .Regularization )
tiny =1e-3 ; 
options .Regularization =max (tiny ,1e-2 *nanstd (y )); 
end

ifisempty (options .SigmaLowerBound )
tiny =1e-3 ; 
options .SigmaLowerBound =max (tiny ,1e-2 *nanstd (y )); 
end



[this .Theta0 ,this .Kernel ,this .IsBuiltInKernel ]=classreg .learning .gputils .makeKernelObject (kernelFunction ,kernelParameters ); 
this .KernelFunction =kernelFunction ; 
this .KernelParameters =kernelParameters ; 




ifstrcmpi (options .DistanceMethod ,GPParams .DistanceMethodAccurate )
this .Kernel .UsePdist =true ; 
end



this .HFcn =classreg .learning .gputils .makeBasisFunction (basisFunction ); 
this .BasisFunction =basisFunction ; 
this .checkExplicitBasisRank (this .HFcn ,this .X ); 


this .Beta0 =beta ; 
this .Sigma0 =sigma ; 


this .FitMethod =fitMethod ; 
this .PredictMethod =predictMethod ; 
this .ActiveSet =activeSet ; 
this .ActiveSetSize =activeSetSize ; 
this .ActiveSetMethod =activeSetMethod ; 
this .Standardize =standardize ; 
this .Verbose =verbose ; 
this .CacheSize =cacheSize ; 
this .Options =options ; 
this .Optimizer =optimizer ; 
this .OptimizerOptions =optimizerOptions ; 
this .ConstantKernelParameters =constantKernelParameters ; 
this .ConstantSigma =constantSigma ; 
this .InitialStepSize =initialStepSize ; 


ifisempty (activeSet )
this .IsActiveSetSupplied =false ; 
else
this .IsActiveSetSupplied =true ; 
end




this =doFit (this ); 
end
end


methods 
function cmp =compact (this )
cmp =classreg .learning .impl .CompactGPImpl (); 


cmp .FitMethod =this .FitMethod ; 
cmp .PredictMethod =this .PredictMethod ; 
cmp .ActiveSet =this .ActiveSet ; 
cmp .ActiveSetSize =this .ActiveSetSize ; 
cmp .ActiveSetMethod =this .ActiveSetMethod ; 
cmp .Standardize =this .Standardize ; 
cmp .Verbose =this .Verbose ; 
cmp .CacheSize =this .CacheSize ; 
cmp .Options =this .Options ; 
cmp .Optimizer =this .Optimizer ; 
cmp .OptimizerOptions =this .OptimizerOptions ; 
cmp .ConstantKernelParameters =this .ConstantKernelParameters ; 
cmp .ConstantSigma =this .ConstantSigma ; 
cmp .InitialStepSize =this .InitialStepSize ; 


cmp .KernelFunction =this .KernelFunction ; 
cmp .KernelParameters =this .KernelParameters ; 
cmp .BasisFunction =this .BasisFunction ; 


cmp .Kernel =this .Kernel ; 
cmp .IsBuiltInKernel =this .IsBuiltInKernel ; 
cmp .HFcn =this .HFcn ; 


cmp .StdMu =this .StdMu ; 
cmp .StdSigma =this .StdSigma ; 


cmp .Beta0 =this .Beta0 ; 
cmp .Theta0 =this .Theta0 ; 
cmp .Sigma0 =this .Sigma0 ; 


cmp .BetaHat =this .BetaHat ; 
cmp .ThetaHat =this .ThetaHat ; 
cmp .SigmaHat =this .SigmaHat ; 


cmp .IsActiveSetSupplied =this .IsActiveSetSupplied ; 
cmp .ActiveSetX =this .ActiveSetX ; 
cmp .AlphaHat =this .AlphaHat ; 
cmp .LFactor =[]; 
cmp .LFactor2 =[]; 


cmp .SigmaLB =this .SigmaLB ; 


cmp .IsTrained =this .IsTrained ; 


cmp .LogLikelihoodHat =this .LogLikelihoodHat ; 
end
end


methods 
function this =doFit (this )











import classreg.learning.modelparams.GPParams ; 
warnState =warning ('query' ,'all' ); 
warning ('off' ,'MATLAB:nearlySingularMatrix' ); 
warning ('off' ,'MATLAB:illConditionedMatrix' ); 
warning ('off' ,'MATLAB:singularMatrix' ); 
warning ('off' ,'MATLAB:rankDeficientMatrix' ); 
cleanupObj =onCleanup (@()warning (warnState )); 



switchlower (this .FitMethod )

case lower (GPParams .FitMethodNone )

this =doFitMethodNone (this ); 

case lower (GPParams .FitMethodExact )

this =doFitMethodExact (this ); 

case lower (GPParams .FitMethodSD )

this =doFitMethodSD (this ); 

case {lower (GPParams .FitMethodFIC ),lower (GPParams .FitMethodSR )}

this =doFitMethodSparse (this ); 
end




if(this .Verbose >0 )
alphaEstimationMessageStr =getString (message ('stats:classreg:learning:impl:GPImpl:GPImpl:MessageAlphaEstimation' ,this .PredictMethod )); 
fprintf ('\n' ); 
fprintf ('%s\n' ,alphaEstimationMessageStr ); 
end

switchlower (this .PredictMethod )

case lower (GPParams .PredictMethodSD )

this =doPredictMethodSD (this ); 

case lower (GPParams .PredictMethodExact )

this =doPredictMethodExact (this ); 

case lower (GPParams .PredictMethodBCD )

this =doPredictMethodBCD (this ); 

case {lower (GPParams .PredictMethodFIC ),lower (GPParams .PredictMethodSR )}

this =doPredictMethodSparse (this ); 
end


this .IsTrained =true ; 


this .Kernel =setTheta (this .Kernel ,this .ThetaHat ); 
end
end


methods 

function this =doFitMethodNone (this )

this .BetaHat =this .Beta0 ; 
this .ThetaHat =this .Theta0 ; 
this .SigmaHat =this .Sigma0 ; 
end

function this =doFitMethodExact (this )


[this .ThetaHat ,this .SigmaHat ,this .LogLikelihoodHat ]=estimateThetaHatSigmaHatExact (this ,this .X ,this .y ,this .Beta0 ,this .Theta0 ,this .Sigma0 ); 




[this .BetaHat ,this .LFactor ]=computeBetaHatExact (this ,this .X ,this .y ,this .ThetaHat ,this .SigmaHat ); 
end

function this =doFitMethodSD (this )
import classreg.learning.modelparams.GPParams ; 
ifthis .IsActiveSetSupplied 



activeSet =this .ActiveSet ; 
XA =this .X (activeSet ,:); 
yA =this .y (activeSet ,1 ); 
[this .ThetaHat ,this .SigmaHat ,this .LogLikelihoodHat ]=estimateThetaHatSigmaHatExact (this ,XA ,yA ,this .Beta0 ,this .Theta0 ,this .Sigma0 ); 



[this .BetaHat ,this .LFactor ]=computeBetaHatExact (this ,XA ,yA ,this .ThetaHat ,this .SigmaHat ); 
else





ifstrcmpi (this .ActiveSetMethod ,GPParams .ActiveSetMethodRandom )
numreps =1 ; 
else
numreps =this .Options .NumActiveSetRepeats ; 
end


beta =this .Beta0 ; 
theta =this .Theta0 ; 
sigma =this .Sigma0 ; 






activeSetHistory =struct (); 
forreps =1 :numreps 
[activeSet ,activeSetIndices ,critProfile ]=selectActiveSet (this ,this .X ,this .y ,beta ,theta ,sigma ); 
XA =this .X (activeSet ,:); 
yA =this .y (activeSet ,1 ); 
[theta ,sigma ,loglik ]=estimateThetaHatSigmaHatExact (this ,XA ,yA ,beta ,theta ,sigma ); 
[beta ,LFactor ]=computeBetaHatExact (this ,XA ,yA ,theta ,sigma ); 

activeSetHistory .ParameterVector {reps }=[beta ; theta ; sigma ]; 
activeSetHistory .ActiveSetIndices {reps }=activeSetIndices ; 
activeSetHistory .LogLikelihood (reps )=loglik ; 
activeSetHistory .CriterionProfile {reps }=critProfile ; 
end



this .BetaHat =beta ; 
this .ThetaHat =theta ; 
this .SigmaHat =sigma ; 
this .LFactor =LFactor ; 
this .ActiveSet =activeSet ; 
this .LogLikelihoodHat =loglik ; 
this .ActiveSetHistory =activeSetHistory ; 
end
end

function this =doFitMethodSparse (this )
import classreg.learning.modelparams.GPParams ; 

ifstrcmpi (this .FitMethod ,GPParams .FitMethodFIC )
useFIC =true ; 
else
useFIC =false ; 
end


useQR =this .Options .UseQR ; 

ifthis .IsActiveSetSupplied 


[this .ThetaHat ,this .SigmaHat ,this .LogLikelihoodHat ]=estimateThetaHatSigmaHatSparse (this ,this .X ,this .y ,this .ActiveSet ,this .Beta0 ,this .Theta0 ,this .Sigma0 ,useFIC ,useQR ); 




[this .AlphaHat ,this .BetaHat ,this .LFactor ,this .LFactor2 ]=computeAlphaHatBetaHatSparseV (this ,this .X ,this .y ,this .ActiveSet ,[],this .ThetaHat ,this .SigmaHat ,useFIC ); 
else





ifstrcmpi (this .ActiveSetMethod ,GPParams .ActiveSetMethodRandom )
numreps =1 ; 
else
numreps =this .Options .NumActiveSetRepeats ; 
end


beta =this .Beta0 ; 
theta =this .Theta0 ; 
sigma =this .Sigma0 ; 






activeSetHistory =struct (); 
forreps =1 :numreps 
[activeSet ,activeSetIndices ,critProfile ]=selectActiveSet (this ,this .X ,this .y ,beta ,theta ,sigma ); 
[theta ,sigma ,loglik ]=estimateThetaHatSigmaHatSparse (this ,this .X ,this .y ,activeSet ,beta ,theta ,sigma ,useFIC ,useQR ); 
[alphaHat ,beta ,LFactor ,LFactor2 ]=computeAlphaHatBetaHatSparseV (this ,this .X ,this .y ,activeSet ,[],theta ,sigma ,useFIC ); 

activeSetHistory .ParameterVector {reps }=[beta ; theta ; sigma ]; 
activeSetHistory .ActiveSetIndices {reps }=activeSetIndices ; 
activeSetHistory .LogLikelihood (reps )=loglik ; 
activeSetHistory .CriterionProfile {reps }=critProfile ; 
end



this .BetaHat =beta ; 
this .ThetaHat =theta ; 
this .SigmaHat =sigma ; 
this .LFactor =LFactor ; 
this .LFactor2 =LFactor2 ; 
this .ActiveSet =activeSet ; 
this .AlphaHat =alphaHat ; 
this .LogLikelihoodHat =loglik ; 
this .ActiveSetHistory =activeSetHistory ; 
end
end


function this =doPredictMethodSD (this )
import classreg.learning.modelparams.GPParams ; 
ifstrcmpi (this .FitMethod ,GPParams .FitMethodSD )&&~isempty (this .ActiveSet )&&~isempty (this .LFactor )


activeSet =this .ActiveSet ; 
XA =this .X (activeSet ,:); 
yA =this .y (activeSet ,1 ); 
this .AlphaHat =computeAlphaHatExact (this ,XA ,yA ,this .BetaHat ,this .LFactor ); 
this .ActiveSetX =XA ; 
else



ifisempty (this .ActiveSet )
activeSetHistory =struct (); 
[this .ActiveSet ,activeSetIndices ,critProfile ]=selectActiveSet (this ,this .X ,this .y ,this .BetaHat ,this .ThetaHat ,this .SigmaHat ); 
activeSetHistory .ActiveSetIndices {1 }=activeSetIndices ; 
activeSetHistory .CriterionProfile {1 }=critProfile ; 
activeSetHistory .ParameterVector =[]; 
activeSetHistory .LogLikelihood =[]; 
this .ActiveSetHistory =activeSetHistory ; 
end
activeSet =this .ActiveSet ; 
XA =this .X (activeSet ,:); 
yA =this .y (activeSet ,1 ); 
[this .AlphaHat ,~,this .LFactor ]=computeAlphaHatBetaHatExact (this ,XA ,yA ,this .BetaHat ,this .ThetaHat ,this .SigmaHat ); 
this .ActiveSetX =XA ; 
end
end

function this =doPredictMethodExact (this )
import classreg.learning.modelparams.GPParams ; 
ifstrcmpi (this .FitMethod ,GPParams .FitMethodExact )&&~isempty (this .LFactor )


this .AlphaHat =computeAlphaHatExact (this ,this .X ,this .y ,this .BetaHat ,this .LFactor ); 
this .ActiveSetX =this .X ; 
this .ActiveSet =true (size (this .X ,1 ),1 ); 
else

[this .AlphaHat ,~,this .LFactor ]=computeAlphaHatBetaHatExact (this ,this .X ,this .y ,this .BetaHat ,this .ThetaHat ,this .SigmaHat ); 
this .ActiveSetX =this .X ; 
this .ActiveSet =true (size (this .X ,1 ),1 ); 
end
end

function this =doPredictMethodBCD (this )

bcdHistory =struct (); 
[this .AlphaHat ,gHat ,fHat ,selectionCounts ]=computeAlphaHatBCD (this ,this .X ,this .y ,this .BetaHat ,this .ThetaHat ,this .SigmaHat ); 
this .ActiveSetX =this .X ; 
this .ActiveSet =true (size (this .X ,1 ),1 ); 
bcdHistory .Gradient =gHat ; 
bcdHistory .Objective =fHat ; 
bcdHistory .SelectionCounts =selectionCounts ; 
this .BCDHistory =bcdHistory ; 
end

function this =doPredictMethodSparse (this )
import classreg.learning.modelparams.GPParams ; 

ifstrcmpi (this .PredictMethod ,GPParams .PredictMethodFIC )
useFIC =true ; 
else
useFIC =false ; 
end



ifisempty (this .ActiveSet )
activeSetHistory =struct (); 
[this .ActiveSet ,activeSetIndices ,critProfile ]=selectActiveSet (this ,this .X ,this .y ,this .BetaHat ,this .ThetaHat ,this .SigmaHat ); 
activeSetHistory .ActiveSetIndices {1 }=activeSetIndices ; 
activeSetHistory .CriterionProfile {1 }=critProfile ; 
activeSetHistory .ParameterVector =[]; 
activeSetHistory .LogLikelihood =[]; 
this .ActiveSetHistory =activeSetHistory ; 
end




ifstrcmpi (this .FitMethod ,this .PredictMethod )


else


[this .AlphaHat ,~,this .LFactor ,this .LFactor2 ]=computeAlphaHatBetaHatSparseV (this ,this .X ,this .y ,this .ActiveSet ,this .BetaHat ,this .ThetaHat ,this .SigmaHat ,useFIC ); 
end


this .ActiveSetX =this .X (this .ActiveSet ,:); 
end
end


methods 

function [betaHat ,L ]=computeBetaHatExact (this ,X ,y ,theta ,sigma )









H =this .HFcn (X ); 


L =computeLFactorExact (this ,X ,theta ,sigma ); 


if(size (H ,2 )==0 )
betaHat =zeros (0 ,1 ); 
else
Linvy =L \y ; 
LinvH =L \H ; 
betaHat =LinvH \Linvy ; 
end

end

function alphaHat =computeAlphaHatExact (this ,X ,y ,beta ,L )














H =this .HFcn (X ); 


ifisempty (beta )

if(size (H ,2 )==0 )
betaHat =zeros (0 ,1 ); 
else
Linvy =L \y ; 
LinvH =L \H ; 
betaHat =LinvH \Linvy ; 
end
else

betaHat =beta ; 
end






alphaHat =(L ' \(L \(y -H *betaHat ))); 

end

function [alphaHat ,betaHat ,L ]=computeAlphaHatBetaHatExact (this ,X ,y ,beta ,theta ,sigma )





















H =this .HFcn (X ); 


L =computeLFactorExact (this ,X ,theta ,sigma ); 


ifisempty (beta )

if(size (H ,2 )==0 )
betaHat =zeros (0 ,1 ); 
else
Linvy =L \y ; 
LinvH =L \H ; 
betaHat =LinvH \Linvy ; 
end
else

betaHat =beta ; 
end






alphaHat =(L ' \(L \(y -H *betaHat ))); 

end

function [thetaHat ,sigmaHat ,loglikHat ]=estimateThetaHatSigmaHatExact (this ,X ,y ,beta0 ,theta0 ,sigma0 )








































[N ,D ]=size (X ); 
M =N ; 
usecache =checkCacheSizeForFitting (this ,N ,D ,M ); 
[objFun ,haveGrad ]=makeNegativeProfiledLogLikelihoodExact (this ,X ,y ,beta0 ,theta0 ,sigma0 ,usecache ); 


sigmaLB =this .Options .SigmaLowerBound ; 
ifthis .ConstantSigma 
gamma0 =log (max (1e-6 ,sigma0 -sigmaLB )); 
else
gamma0 =log (max (1e-3 ,sigma0 -sigmaLB )); 
end
phi0 =[theta0 ; gamma0 ]; 





warnState =warning ('query' ,'all' ); 
warning ('off' ,'MATLAB:nearlySingularMatrix' ); 
warning ('off' ,'MATLAB:illConditionedMatrix' ); 
warning ('off' ,'MATLAB:singularMatrix' ); 
warning ('off' ,'MATLAB:rankDeficientMatrix' ); 
cleanupObj =onCleanup (@()warning (warnState )); 

if(this .Verbose >0 )
parameterEstimationMessageStr =getString (message ('stats:classreg:learning:impl:GPImpl:GPImpl:MessageParameterEstimation' ,this .FitMethod ,this .Optimizer )); 
fprintf ('\n' ); 
fprintf ('%s\n' ,parameterEstimationMessageStr ); 
end

ifthis .ConstantSigma ||any (this .ConstantKernelParameters )
[phiHat ,nloglikHat ,cause ]=doMinimizationWithSomeConstParams (this ,objFun ,phi0 ,haveGrad ); 
else
[phiHat ,nloglikHat ,cause ]=doMinimization (this ,objFun ,phi0 ,haveGrad ); 
end


if(cause ~=0 &&cause ~=1 )
warning (message ('stats:classreg:learning:impl:GPImpl:GPImpl:OptimizerUnableToConverge' ,this .Optimizer )); 
end


s =length (phiHat ); 
thetaHat =phiHat (1 :s -1 ,1 ); 
gammaHat =phiHat (s ,1 ); 
sigmaHat =sigmaLB +exp (gammaHat ); 


loglikHat =-1 *nloglikHat ; 

end

function [objFun ,haveGrad ]=makeNegativeProfiledLogLikelihoodExact (this ,X ,y ,beta0 ,theta0 ,sigma0 ,usecache )%#ok<INUSL> 














































assert (islogical (usecache )); 
kfcn =makeKernelAsFunctionOfTheta (this .Kernel ,X ,X ,usecache ); 


H =this .HFcn (X ); 
p =size (H ,2 ); 


N =size (X ,1 ); 
diagOffset =this .Options .DiagonalOffset ; 




c =(N /2 )*log (2 *pi ); 



isbuiltin =this .IsBuiltInKernel ; 
ifisbuiltin 
haveGrad =true ; 
else
haveGrad =false ; 
end






s =length (theta0 )+1 ; 
sigmaLB =this .Options .SigmaLowerBound ; 
badnloglik =this .BadNegativeLogLikelihood ; 



objFun =@f1 ; 
function [nloglik ,gnloglik ]=f1 (phi )


theta =phi (1 :s -1 ,1 ); 
gamma =phi (s ,1 ); 
sigma =sigmaLB +exp (gamma ); 






[V ,DK ]=kfcn (theta ); 
V (1 :N +1 :N ^2 )=V (1 :N +1 :N ^2 )+(sigma ^2 +diagOffset ); 


[L ,flag ]=chol (V ,'lower' ); 
if(flag ~=0 )



nloglik =badnloglik ; 
ifnargout >1 
ifisbuiltin 
gnloglik =zeros (s ,1 ); 
else
gnloglik =[]; 
end
end
return ; 
end


if(p ==0 )

Linvy =L \y ; 
LinvH =zeros (N ,0 ); 
betaHat =zeros (0 ,1 ); 
else

Linvy =L \y ; 
LinvH =L \H ; 
betaHat =LinvH \Linvy ; 
end



LinvAdjy =(Linvy -LinvH *betaHat ); 
loglik =-0.5 *(LinvAdjy ' *LinvAdjy )-c -sum (log (abs (diag (L )))); 
nloglik =-1 *loglik ; 


ifnargout >1 
ifhaveGrad 



alphaHat =L ' \LinvAdjy ; 



Linv =L \eye (N ); 




gloglik =zeros (s ,1 ); 



forr =1 :s -1 

DKr =DK (r ); 

quadTerm =0.5 *(alphaHat ' *DKr *alphaHat ); 

DKr =L \DKr ; 
traceTerm =-0.5 *sum (sum (Linv .*DKr ,1 )); 

gloglik (r )=quadTerm +traceTerm ; 
end






sigma_sigmaLB =sigma *(sigma -sigmaLB ); 
quadTerm =sigma_sigmaLB *(alphaHat ' *alphaHat ); 

traceTerm =-sigma_sigmaLB *sum (sum (Linv .*Linv ,1 )); 

gloglik (s )=quadTerm +traceTerm ; 


gnloglik =-1 *gloglik ; 
else

gnloglik =[]; 
end
end
end
end

function loglikHat =computeLogLikelihoodExact (this )








assert (this .IsTrained ); 
warnState =warning ('query' ,'all' ); 
warning ('off' ,'MATLAB:nearlySingularMatrix' ); 
warning ('off' ,'MATLAB:illConditionedMatrix' ); 
warning ('off' ,'MATLAB:singularMatrix' ); 
warning ('off' ,'MATLAB:rankDeficientMatrix' ); 
cleanupObj =onCleanup (@()warning (warnState )); 


X =this .X ; 
y =this .y ; 
H =this .HFcn (X ); 


beta =this .BetaHat ; 
theta =this .ThetaHat ; 
sigma =this .SigmaHat ; 


kfcn =makeKernelAsFunctionOfXNXM (this .Kernel ,theta ); 
V =kfcn (X ,X ); 


diagOffset =this .Options .DiagonalOffset ; 
N =size (X ,1 ); 
V (1 :N +1 :N ^2 )=V (1 :N +1 :N ^2 )+(sigma ^2 +diagOffset ); 



[L ,flag ]=chol (V ,'lower' ); 
if(flag ~=0 )

loglikHat =-1 *this .BadNegativeLogLikelihood ; 
return ; 
end


LInvAdjy =L \(y -H *beta ); 
loglikHat =-0.5 *(LInvAdjy ' *LInvAdjy )-0.5 *N *log (2 *pi )-sum (log (abs (diag (L )))); 

end

end


methods 

function [alphaHat ,gHat ,fHat ,selectionCounts ]=computeAlphaHatBCD (this ,X ,y ,beta ,theta ,sigma )



















kfun =makeKernelAsFunctionOfXNXM (this .Kernel ,theta ); 



diagkfun =makeDiagKernelAsFunctionOfXN (this .Kernel ,theta ); 


H =this .HFcn (X ); 


adjy =y -H *beta ; 


numgreedy =this .Options .NumGreedyBCD ; 
blocksize =this .Options .BlockSizeBCD ; 
tolerance =this .Options .ToleranceBCD ; 
stepTolerance =this .Options .StepToleranceBCD ; 
maxIter =this .Options .IterationLimitBCD ; 

ifthis .Verbose >0 
verbose =1 ; 
else
verbose =0 ; 
end







N =size (X ,1 ); 
squarecachesize =floor (sqrt ((this .CacheSize *1e6 )/8 )); 
squarecachesize =min (max (1 ,squarecachesize ),N ); 



if(verbose ==1 )
BCDMessageStr =getString (message ('stats:classreg:learning:impl:GPImpl:GPImpl:MessageBCD' ,blocksize ,numgreedy )); 
fprintf ('\n' ); 
fprintf ('%s\n' ,BCDMessageStr ); 
end


[alphaHat ,gHat ,fHat ,selectionCounts ]=classreg .learning .gputils .bcdGPR (X ,adjy ,kfun ,diagkfun ,...
    'verbose' ,verbose ,'Tolerance' ,tolerance ,'BlockSize' ,blocksize ,'SquareCacheSize' ,squarecachesize ,...
    'NumGreedy' ,numgreedy ,'Sigma' ,sigma ,'StepTolerance' ,stepTolerance ,'MaxIter' ,maxIter ); 

end

end


methods 


































































































































































































function [alphaHat ,betaHat ,L ,LAA ]=computeAlphaHatBetaHatSparseQR (this ,X ,y ,A ,beta ,theta ,sigma ,useFIC )





































N =size (X ,1 ); 
XA =X (A ,:); 
M =size (XA ,1 ); 

H =this .HFcn (X ); 
p =size (H ,2 ); 


kfun =makeKernelAsFunctionOfXNXM (this .Kernel ,theta ); 


ifuseFIC 
diagkfun =makeDiagKernelAsFunctionOfXN (this .Kernel ,theta ); 
diagK =diagkfun (X ); 
end


tau =this .Options .Regularization ; 


KXA =kfun (X ,XA ); 


KAA =KXA (A ,:); 
KAA (1 :M +1 :M ^2 )=KAA (1 :M +1 :M ^2 )+tau ^2 ; 


[LAA ,status ]=chol (KAA ,'lower' ); 
if(status ~=0 )
error (message ('stats:classreg:learning:impl:GPImpl:GPImpl:UnableToComputeLFactorFIC' )); 
end



LAAInvKAX =LAA \KXA ' ; 
clear KXA ; 

ifuseFIC 
diagLambda =max (0 ,sigma ^2 +diagK -sum (LAAInvKAX .^2 ,1 )' ); 
invDiagLambda =1 ./diagLambda ; 
else
sigma2 =sigma ^2 ; 
invDiagLambda =(1 /sigma2 )*ones (N ,1 ); 
end
sqrtInvDiagLambda =sqrt (invDiagLambda ); 




Q =[bsxfun (@times ,sqrtInvDiagLambda ,LAAInvKAX ' ); 
 eye (M )]; 
[Q ,R ]=qr (Q ,0 ); 
L =LAA *R ' ; 
clear LAAInvKAX ; 


sqrtLambdaInvH =bsxfun (@times ,sqrtInvDiagLambda ,H ); 
sqrtLambdaInvy =bsxfun (@times ,sqrtInvDiagLambda ,y ); 

Htilde =[sqrtLambdaInvH ; zeros (M ,p )]; 
ytilde =[sqrtLambdaInvy ; zeros (M ,1 )]; 

QTHtilde =Q ' *Htilde ; 
QTytilde =Q ' *ytilde ; 

clear Q ; 


ifisempty (beta )

if(p ==0 )
betaHat =zeros (0 ,1 ); 
else
HTLambdaInvH =sqrtLambdaInvH ' *sqrtLambdaInvH ; 
HTLambdaInvy =sqrtLambdaInvH ' *sqrtLambdaInvy ; 

HTVInvH =HTLambdaInvH -QTHtilde ' *QTHtilde ; 
HTVInvy =HTLambdaInvy -QTHtilde ' *QTytilde ; 

betaHat =HTVInvH \HTVInvy ; 
end
else

betaHat =beta ; 
end


alphaHat =LAA ' \(R \(QTytilde -QTHtilde *betaHat )); 

end

function [alphaHat ,betaHat ,L ,LAA ]=computeAlphaHatBetaHatSparseV (this ,X ,y ,A ,beta ,theta ,sigma ,useFIC )




































H =this .HFcn (X ); 
p =size (H ,2 ); 
N =size (X ,1 ); 


kfun =makeKernelAsFunctionOfXNXM (this .Kernel ,theta ); 


ifuseFIC 
diagkfun =makeDiagKernelAsFunctionOfXN (this .Kernel ,theta ); 
diagK =diagkfun (X ); 
end
































M =length (find (A )); 
B =max (1 ,floor ((1e6 *this .CacheSize )/8 /M )); 
nchunks =floor (N /B ); 






tau =this .Options .Regularization ; 
XA =X (A ,:); 
KAA =kfun (XA ,XA ); 
KAA (1 :M +1 :M ^2 )=KAA (1 :M +1 :M ^2 )+tau ^2 ; 
[LAA ,status ]=chol (KAA ,'lower' ); 
if(status ~=0 )
error (message ('stats:classreg:learning:impl:GPImpl:GPImpl:UnableToComputeLFactorFIC' )); 
end



ifisempty (beta )

if(p ==0 )
betaHat =zeros (0 ,1 ); 
estimateBeta =false ; 
else
estimateBeta =true ; 
end
else

betaHat =beta ; 
estimateBeta =false ; 
end





















SA =eye (M ); 
KAXLambdaInvH =zeros (M ,p ); 
KAXLambdaInvy =zeros (M ,1 ); 
ifestimateBeta 
HTLambdaInvH =zeros (p ,p ); 
HTLambdaInvy =zeros (p ,1 ); 
end


forc =1 :(nchunks +1 )
ifc <(nchunks +1 )
idxc =(c -1 )*B +1 :c *B ; 
else

idxc =nchunks *B +1 :N ; 
end

Kc =kfun (X (idxc ,:),XA ); 
Hc =H (idxc ,:); 
yc =y (idxc ,1 ); 

ifuseFIC 
diagLambdac =max (0 ,sigma ^2 +diagK (idxc )-sum ((LAA \Kc ' ).^2 ,1 )' ); 
else
diagLambdac =max (0 ,sigma ^2 *ones (length (idxc ),1 )); 
end
sqrtInvDiagLambdac =sqrt (1 ./diagLambdac ); 

sqrtLambdacInvKc =bsxfun (@times ,sqrtInvDiagLambdac ,Kc ); 
sqrtLambdacInvHc =bsxfun (@times ,sqrtInvDiagLambdac ,Hc ); 
sqrtLambdacInvyc =bsxfun (@times ,sqrtInvDiagLambdac ,yc ); 

LAAInvSqrtLambdacInvKcT =LAA \sqrtLambdacInvKc ' ; 
SA =SA +LAAInvSqrtLambdacInvKcT *LAAInvSqrtLambdacInvKcT ' ; 

KAXLambdaInvH =KAXLambdaInvH +sqrtLambdacInvKc ' *sqrtLambdacInvHc ; 
KAXLambdaInvy =KAXLambdaInvy +sqrtLambdacInvKc ' *sqrtLambdacInvyc ; 

ifestimateBeta 
HTLambdaInvH =HTLambdaInvH +sqrtLambdacInvHc ' *sqrtLambdacInvHc ; 
HTLambdaInvy =HTLambdaInvy +sqrtLambdacInvHc ' *sqrtLambdacInvyc ; 
end
end










[R ,status ]=chol (SA ); 
if(status ~=0 )
error (message ('stats:classreg:learning:impl:GPImpl:GPImpl:UnableToComputeLFactorFIC' )); 
end
L =LAA *R ' ; 


LInvKAXLambdaInvH =L \KAXLambdaInvH ; 
LInvKAXLambdaInvy =L \KAXLambdaInvy ; 
ifestimateBeta 
HTVInvH =HTLambdaInvH -LInvKAXLambdaInvH ' *LInvKAXLambdaInvH ; 
HTVInvy =HTLambdaInvy -LInvKAXLambdaInvH ' *LInvKAXLambdaInvy ; 
betaHat =HTVInvH \HTVInvy ; 
end


alphaHat =L ' \(LInvKAXLambdaInvy -LInvKAXLambdaInvH *betaHat ); 

end

function [thetaHat ,sigmaHat ,loglikHat ]=estimateThetaHatSigmaHatSparse (this ,X ,y ,A ,beta0 ,theta0 ,sigma0 ,useFIC ,useQR )















































[N ,D ]=size (X ); 
M =sum (A ); 
usecache =checkCacheSizeForFitting (this ,N ,D ,M ); 
ifuseQR 

[objFun ,haveGrad ]=makeNegativeProfiledLogLikelihoodSparseQR (this ,X ,y ,A ,beta0 ,theta0 ,sigma0 ,usecache ,useFIC ); 
else

[objFun ,haveGrad ]=makeNegativeProfiledLogLikelihoodSparseVFastGrad (this ,X ,y ,A ,beta0 ,theta0 ,sigma0 ,usecache ,useFIC ); 
end


sigmaLB =this .Options .SigmaLowerBound ; 
ifthis .ConstantSigma 
gamma0 =log (max (1e-6 ,sigma0 -sigmaLB )); 
else
gamma0 =log (max (1e-3 ,sigma0 -sigmaLB )); 
end
phi0 =[theta0 ; gamma0 ]; 





warnState =warning ('query' ,'all' ); 
warning ('off' ,'MATLAB:nearlySingularMatrix' ); 
warning ('off' ,'MATLAB:illConditionedMatrix' ); 
warning ('off' ,'MATLAB:singularMatrix' ); 
warning ('off' ,'MATLAB:rankDeficientMatrix' ); 
cleanupObj =onCleanup (@()warning (warnState )); 

if(this .Verbose >0 )
ifuseQR 
computationMethod ='QR' ; 
else
computationMethod ='V' ; 
end

ifuseFIC 
fitMethod =classreg .learning .modelparams .GPParams .FitMethodFIC ; 
else
fitMethod =classreg .learning .modelparams .GPParams .FitMethodSR ; 
end

parameterEstimationMessageStr =getString (message ('stats:classreg:learning:impl:GPImpl:GPImpl:MessageSparseParameterEstimation' ,fitMethod ,this .Optimizer ,computationMethod )); 
fprintf ('\n' ); 
fprintf ('%s\n' ,parameterEstimationMessageStr ); 
end

ifthis .ConstantSigma ||any (this .ConstantKernelParameters )
[phiHat ,nloglikHat ,cause ]=doMinimizationWithSomeConstParams (this ,objFun ,phi0 ,haveGrad ); 
else
[phiHat ,nloglikHat ,cause ]=doMinimization (this ,objFun ,phi0 ,haveGrad ); 
end


if(cause ~=0 &&cause ~=1 )
warning (message ('stats:classreg:learning:impl:GPImpl:GPImpl:OptimizerUnableToConverge' ,this .Optimizer )); 
end


s =length (phiHat ); 
thetaHat =phiHat (1 :s -1 ,1 ); 
gammaHat =phiHat (s ,1 ); 
sigmaHat =sigmaLB +exp (gammaHat ); 


loglikHat =-1 *nloglikHat ; 

end

function [objFun ,haveGrad ]=makeNegativeProfiledLogLikelihoodSparseVFastGrad (this ,X ,y ,A ,beta0 ,theta0 ,sigma0 ,usecache ,useFIC )%#ok<INUSL> 



















































XA =X (A ,:); 

assert (islogical (usecache )); 
kfcn =makeKernelAsFunctionOfTheta (this .Kernel ,X ,XA ,usecache ); 















diagkfcn =makeDiagKernelAsFunctionOfTheta (this .Kernel ,X ,usecache ); 


H =this .HFcn (X ); 
p =size (H ,2 ); 



N =size (X ,1 ); 
M =size (XA ,1 ); 
if~useFIC 
eN =ones (N ,1 ); 
end





const =(N /2 )*log (2 *pi ); 



isbuiltin =this .IsBuiltInKernel ; 
ifisbuiltin 
haveGrad =true ; 
else
haveGrad =false ; 
end





s =length (theta0 )+1 ; 
sigmaLB =this .Options .SigmaLowerBound ; 
badnloglik =this .BadNegativeLogLikelihood ; 


tau =this .Options .Regularization ; 



objFun =@f2 ; 
function [nloglik ,gnloglik ]=f2 (phi )


theta =phi (1 :s -1 ,1 ); 
gamma =phi (s ,1 ); 
sigma =sigmaLB +exp (gamma ); 


[KXA ,DKXA ]=kfcn (theta ); 


[diagK ,DdiagK ]=diagkfcn (theta ); 


KAA =KXA (A ,:); 
KAA (1 :M +1 :M ^2 )=KAA (1 :M +1 :M ^2 )+tau ^2 ; 


[LAA ,flag1 ]=chol (KAA ,'lower' ); 
if(flag1 ~=0 )



nloglik =badnloglik ; 
ifnargout >1 
ifisbuiltin 
gnloglik =zeros (s ,1 ); 
else
gnloglik =[]; 
end
end
return ; 
end



LAAInvKAX =LAA \KXA ' ; 
ifuseFIC 
diagLambda =max (0 ,sigma ^2 +diagK -sum (LAAInvKAX .^2 ,1 )' ); 
invDiagLambda =1 ./diagLambda ; 
else
sigma2 =sigma ^2 ; 
diagLambda =sigma2 *eN ; 
invDiagLambda =(1 /sigma2 )*eN ; 
end
sqrtInvDiagLambda =sqrt (invDiagLambda ); 


KAXLambdaInvKXA =KXA ' *bsxfun (@times ,invDiagLambda ,KXA ); 







SA =bsxfun (@times ,sqrtInvDiagLambda ,LAAInvKAX ' ); 
SA =eye (M )+SA ' *SA ; 
[R ,flag2 ]=chol (SA ); 
if(flag2 ~=0 )



nloglik =badnloglik ; 
ifnargout >1 
ifhaveGrad 
gnloglik =zeros (s ,1 ); 
else
gnloglik =[]; 
end
end
return ; 
end
L =LAA *R ' ; 


LambdaInvH =bsxfun (@times ,invDiagLambda ,H ); 
LambdaInvy =bsxfun (@times ,invDiagLambda ,y ); 

LInvKAXLambdaInvH =L \(KXA ' *LambdaInvH ); 
LInvKAXLambdaInvy =L \(KXA ' *LambdaInvy ); 

HTLambdaInvH =H ' *LambdaInvH ; 
HTLambdaInvy =H ' *LambdaInvy ; 
yTLambdaInvy =y ' *LambdaInvy ; 

HTVInvH =HTLambdaInvH -LInvKAXLambdaInvH ' *LInvKAXLambdaInvH ; 
HTVInvy =HTLambdaInvy -LInvKAXLambdaInvH ' *LInvKAXLambdaInvy ; 
yTVInvy =yTLambdaInvy -LInvKAXLambdaInvy ' *LInvKAXLambdaInvy ; 

if(p ==0 )
betaHat =zeros (0 ,1 ); 
else
betaHat =HTVInvH \HTVInvy ; 
end




quadTerm =yTVInvy -2 *HTVInvy ' *betaHat +betaHat ' *(HTVInvH *betaHat ); 
logTerm =sum (log (abs (diagLambda )))+2 *sum (log (abs (diag (R )))); 
loglik =-0.5 *quadTerm -const -0.5 *logTerm ; 
nloglik =-1 *loglik ; 

if~isfinite (nloglik )
nloglik =badnloglik ; 
ifnargout >1 
ifhaveGrad 
gnloglik =zeros (s ,1 ); 
else
gnloglik =[]; 
end
end
return ; 
end


ifnargout >1 
ifhaveGrad 



BAInvKAXLambdaInvAdjy =L ' \(LInvKAXLambdaInvy -LInvKAXLambdaInvH *betaHat ); 
rHat =invDiagLambda .*(y -H *betaHat -KXA *BAInvKAXLambdaInvAdjy ); 
KAXrHat =KXA ' *rHat ; 
KAAInvKAXrHat =LAA ' \(LAA \KAXrHat ); 
LInv =L \eye (M ); 
diagLambda2 =diagLambda .^2 ; 
KAAInvKAXLambdaInvKXA =LAA ' \(LAA \KAXLambdaInvKXA ); 

ifuseFIC 
KAAInvKAX =LAA ' \LAAInvKAX ; 
end


gloglik =zeros (s ,1 ); 

forr =1 :s -1 

DKXAr =DKXA (r ); 


quadTerm =2 *(rHat ' *DKXAr )*KAAInvKAXrHat ...
    -KAAInvKAXrHat ' *(DKXAr (A ,:))*KAAInvKAXrHat ; 
ifuseFIC 

diagDOmegar =DdiagK (r )-2 *sum (DKXAr ' .*KAAInvKAX ,1 )' +sum (KAAInvKAX .*(DKXAr (A ,:)*KAAInvKAX ),1 )' ; 
quadTerm =quadTerm +rHat ' *(diagDOmegar .*rHat ); 
end


DKAXLambdaInvKXAr =DKXAr ' *bsxfun (@times ,invDiagLambda ,KXA ); 
traceTerm1 =sum (sum (LInv .*(L \DKAXLambdaInvKXAr ))); 


traceTerm2 =sum (sum (LInv .*(L \(DKXAr (A ,:)*KAAInvKAXLambdaInvKXA )))); 

ifuseFIC 

lambdaOmega =diagDOmegar ./diagLambda2 ; 
KAXLambdaOmegaKXA =KXA ' *bsxfun (@times ,lambdaOmega ,KXA ); 
traceTerm3 =sum (diagDOmegar .*invDiagLambda )-sum (sum (LInv .*(L \KAXLambdaOmegaKXA ))); 
else
traceTerm3 =0 ; 
end
traceTerm =2 *traceTerm1 -traceTerm2 +traceTerm3 ; 


gloglik (r )=0.5 *quadTerm -0.5 *traceTerm ; 
end



quadTerm =rHat ' *rHat ; 
KAXLambdaInv2KXA =KXA ' *bsxfun (@times ,1 ./diagLambda2 ,KXA ); 
traceTerm =sum (invDiagLambda )-sum (sum (LInv .*(L \KAXLambdaInv2KXA ))); 
sigma_sigmaLB =sigma *(sigma -sigmaLB ); 
gloglik (s )=sigma_sigmaLB *(quadTerm -traceTerm ); 


gnloglik =-1 *gloglik ; 
else

gnloglik =[]; 
end
end
end
end

function [objFun ,haveGrad ]=makeNegativeProfiledLogLikelihoodSparseQR (this ,X ,y ,A ,beta0 ,theta0 ,sigma0 ,usecache ,useFIC )%#ok<INUSL> 




















































XA =X (A ,:); 

assert (islogical (usecache )); 
kfcn =makeKernelAsFunctionOfTheta (this .Kernel ,X ,XA ,usecache ); 















diagkfcn =makeDiagKernelAsFunctionOfTheta (this .Kernel ,X ,usecache ); 


H =this .HFcn (X ); 
p =size (H ,2 ); 


N =size (X ,1 ); 
M =size (XA ,1 ); 





const =(N /2 )*log (2 *pi ); 



isbuiltin =this .IsBuiltInKernel ; 
ifisbuiltin 
haveGrad =true ; 
else
haveGrad =false ; 
end





s =length (theta0 )+1 ; 
sigmaLB =this .Options .SigmaLowerBound ; 
badnloglik =this .BadNegativeLogLikelihood ; 


tau =this .Options .Regularization ; 



objFun =@f4 ; 
function [nloglik ,gnloglik ]=f4 (phi )


theta =phi (1 :s -1 ,1 ); 
gamma =phi (s ,1 ); 
sigma =sigmaLB +exp (gamma ); 


[KXA ,DKXA ]=kfcn (theta ); 


[diagK ,DdiagK ]=diagkfcn (theta ); 


KAA =KXA (A ,:); 
KAA (1 :M +1 :M ^2 )=KAA (1 :M +1 :M ^2 )+tau ^2 ; 


[LAA ,flag ]=chol (KAA ,'lower' ); 
if(flag ~=0 )



nloglik =badnloglik ; 
ifnargout >1 
ifhaveGrad 
gnloglik =zeros (s ,1 ); 
else
gnloglik =[]; 
end
end
return ; 
end



LAAInvKAX =LAA \KXA ' ; 
ifuseFIC 
diagLambda =max (0 ,sigma ^2 +diagK -sum (LAAInvKAX .^2 ,1 )' ); 
else
diagLambda =(sigma ^2 )*ones (N ,1 ); 
end
invDiagLambda =1 ./diagLambda ; 
sqrtInvDiagLambda =sqrt (invDiagLambda ); 
invDiagLambda2 =invDiagLambda .*invDiagLambda ; 




Q =[bsxfun (@times ,sqrtInvDiagLambda ,LAAInvKAX ' ); 
 eye (M )]; 
[Q ,R ]=qr (Q ,0 ); 
L =LAA *R ' ; 


sqrtLambdaInvH =bsxfun (@times ,sqrtInvDiagLambda ,H ); 
sqrtLambdaInvy =bsxfun (@times ,sqrtInvDiagLambda ,y ); 

HTLambdaInvH =sqrtLambdaInvH ' *sqrtLambdaInvH ; 
HTLambdaInvy =sqrtLambdaInvH ' *sqrtLambdaInvy ; 
yTLambdaInvy =sqrtLambdaInvy ' *sqrtLambdaInvy ; 

Htilde =[sqrtLambdaInvH ; zeros (M ,p )]; 
ytilde =[sqrtLambdaInvy ; zeros (M ,1 )]; 

QTHtilde =Q ' *Htilde ; 
QTytilde =Q ' *ytilde ; 

clear Q ; 

HTVInvH =HTLambdaInvH -QTHtilde ' *QTHtilde ; 
HTVInvy =HTLambdaInvy -QTHtilde ' *QTytilde ; 
yTVInvy =yTLambdaInvy -QTytilde ' *QTytilde ; 

if(p ==0 )
betaHat =zeros (0 ,1 ); 
else
betaHat =HTVInvH \HTVInvy ; 
end


quadTerm =yTVInvy -2 *HTVInvy ' *betaHat +betaHat ' *(HTVInvH *betaHat ); 
logTerm =sum (log (abs (diagLambda )))+2 *sum (log (abs (diag (R )))); 
loglik =-0.5 *quadTerm -const -0.5 *logTerm ; 
nloglik =-1 *loglik ; 



if~isfinite (nloglik )
nloglik =badnloglik ; 
ifnargout >1 
ifhaveGrad 
gnloglik =zeros (s ,1 ); 
else
gnloglik =[]; 
end
end
return ; 
end


ifnargout >1 
ifhaveGrad 



QTztilde =QTytilde -QTHtilde *betaHat ; 
rHat =invDiagLambda .*((y -H *betaHat )-LAAInvKAX ' *(R \QTztilde )); 
KAXrHat =KXA ' *rHat ; 
KAAInvKAXrHat =LAA ' \(LAA \KAXrHat ); 
LInvKAX =L \KXA ' ; 
LInvKAXdiag =sum (LInvKAX .*LInvKAX ,1 )' ; 
ifuseFIC 


KAAInvKAX =LAA ' \LAAInvKAX ; 
end


gloglik =zeros (s ,1 ); 

forr =1 :s -1 

DKXAr =DKXA (r ); 


quadTerm =2 *(rHat ' *DKXAr )*KAAInvKAXrHat ...
    -KAAInvKAXrHat ' *(DKXAr (A ,:))*KAAInvKAXrHat ; 
ifuseFIC 

diagDOmegar =DdiagK (r )-2 *sum (DKXAr ' .*KAAInvKAX ,1 )' +sum (KAAInvKAX .*(DKXAr (A ,:)*KAAInvKAX ),1 )' ; 
quadTerm =quadTerm +rHat ' *(diagDOmegar .*rHat ); 
end


LInvDKAXr =L \DKXAr ' ; 
traceTerm1 =sum (sum (LInvKAX .*LInvDKAXr ,1 )' .*invDiagLambda ); 
traceTerm2 =sum (sum (LInvKAX .*(((L \DKXAr (A ,:))/LAA ' )*LAAInvKAX ),1 )' .*invDiagLambda ); 

ifuseFIC 

lambdaOmega =diagDOmegar .*invDiagLambda2 ; 
traceTerm3 =sum (diagDOmegar .*invDiagLambda )-sum (LInvKAXdiag .*lambdaOmega ); 
else
traceTerm3 =0 ; 
end
traceTerm =2 *traceTerm1 -traceTerm2 +traceTerm3 ; 


gloglik (r )=0.5 *quadTerm -0.5 *traceTerm ; 
end




quadTerm =rHat ' *rHat ; 
traceTerm =sum (invDiagLambda )-sum (LInvKAXdiag .*invDiagLambda2 ); 
sigma_sigmaLB =sigma *(sigma -sigmaLB ); 
gloglik (s )=sigma_sigmaLB *(quadTerm -traceTerm ); 


gnloglik =-1 *gloglik ; 
else

gnloglik =[]; 
end
end
end
end

function [objFun ,haveGrad ]=makeNegativeProfiledLogLikelihoodSparseV (this ,X ,y ,A ,beta0 ,theta0 ,sigma0 ,usecache ,useFIC )%#ok<INUSL> 




















































XA =X (A ,:); 

assert (islogical (usecache )); 
kfcn =makeKernelAsFunctionOfTheta (this .Kernel ,X ,XA ,usecache ); 















diagkfcn =makeDiagKernelAsFunctionOfTheta (this .Kernel ,X ,usecache ); 


H =this .HFcn (X ); 
p =size (H ,2 ); 


N =size (X ,1 ); 
M =size (XA ,1 ); 





const =(N /2 )*log (2 *pi ); 



isbuiltin =this .IsBuiltInKernel ; 
ifisbuiltin 
haveGrad =true ; 
else
haveGrad =false ; 
end





s =length (theta0 )+1 ; 
sigmaLB =this .Options .SigmaLowerBound ; 
badnloglik =this .BadNegativeLogLikelihood ; 


tau =this .Options .Regularization ; 



objFun =@f5 ; 
function [nloglik ,gnloglik ]=f5 (phi )


theta =phi (1 :s -1 ,1 ); 
gamma =phi (s ,1 ); 
sigma =sigmaLB +exp (gamma ); 


[KXA ,DKXA ]=kfcn (theta ); 


[diagK ,DdiagK ]=diagkfcn (theta ); 


KAA =KXA (A ,:); 
KAA (1 :M +1 :M ^2 )=KAA (1 :M +1 :M ^2 )+tau ^2 ; 


[LAA ,flag1 ]=chol (KAA ,'lower' ); 
if(flag1 ~=0 )



nloglik =badnloglik ; 
ifnargout >1 
ifhaveGrad 
gnloglik =zeros (s ,1 ); 
else
gnloglik =[]; 
end
end
return ; 
end



LAAInvKAX =LAA \KXA ' ; 
ifuseFIC 
diagLambda =max (0 ,sigma ^2 +diagK -sum (LAAInvKAX .^2 ,1 )' ); 
else
diagLambda =(sigma ^2 )*ones (N ,1 ); 
end
invDiagLambda =1 ./diagLambda ; 
sqrtInvDiagLambda =sqrt (invDiagLambda ); 
invDiagLambda2 =invDiagLambda .*invDiagLambda ; 







SA =bsxfun (@times ,sqrtInvDiagLambda ,LAAInvKAX ' ); 
SA =eye (M )+SA ' *SA ; 
[R ,flag2 ]=chol (SA ); 
if(flag2 ~=0 )



nloglik =badnloglik ; 
ifnargout >1 
ifhaveGrad 
gnloglik =zeros (s ,1 ); 
else
gnloglik =[]; 
end
end
return ; 
end
L =LAA *R ' ; 


LambdaInvH =bsxfun (@times ,invDiagLambda ,H ); 
LambdaInvy =bsxfun (@times ,invDiagLambda ,y ); 

LInvKAXLambdaInvH =L \(KXA ' *LambdaInvH ); 
LInvKAXLambdaInvy =L \(KXA ' *LambdaInvy ); 

HTLambdaInvH =H ' *LambdaInvH ; 
HTLambdaInvy =H ' *LambdaInvy ; 
yTLambdaInvy =y ' *LambdaInvy ; 

HTVInvH =HTLambdaInvH -LInvKAXLambdaInvH ' *LInvKAXLambdaInvH ; 
HTVInvy =HTLambdaInvy -LInvKAXLambdaInvH ' *LInvKAXLambdaInvy ; 
yTVInvy =yTLambdaInvy -LInvKAXLambdaInvy ' *LInvKAXLambdaInvy ; 

if(p ==0 )
betaHat =zeros (0 ,1 ); 
else
betaHat =HTVInvH \HTVInvy ; 
end


quadTerm =yTVInvy -2 *HTVInvy ' *betaHat +betaHat ' *(HTVInvH *betaHat ); 
logTerm =sum (log (abs (diagLambda )))+2 *sum (log (abs (diag (R )))); 
loglik =-0.5 *quadTerm -const -0.5 *logTerm ; 
nloglik =-1 *loglik ; 



if~isfinite (nloglik )
nloglik =badnloglik ; 
ifnargout >1 
ifhaveGrad 
gnloglik =zeros (s ,1 ); 
else
gnloglik =[]; 
end
end
return ; 
end


ifnargout >1 
ifhaveGrad 



BAInvKAXLambdaInvAdjy =L ' \(LInvKAXLambdaInvy -LInvKAXLambdaInvH *betaHat ); 
rHat =invDiagLambda .*(y -H *betaHat -KXA *BAInvKAXLambdaInvAdjy ); 

KAXrHat =KXA ' *rHat ; 
KAAInvKAXrHat =LAA ' \(LAA \KAXrHat ); 
LInvKAX =L \KXA ' ; 
LInvKAXdiag =sum (LInvKAX .*LInvKAX ,1 )' ; 
ifuseFIC 


KAAInvKAX =LAA ' \LAAInvKAX ; 
end


gloglik =zeros (s ,1 ); 

forr =1 :s -1 

DKXAr =DKXA (r ); 


quadTerm =2 *(rHat ' *DKXAr )*KAAInvKAXrHat ...
    -KAAInvKAXrHat ' *(DKXAr (A ,:))*KAAInvKAXrHat ; 
ifuseFIC 

diagDOmegar =DdiagK (r )-2 *sum (DKXAr ' .*KAAInvKAX ,1 )' +sum (KAAInvKAX .*(DKXAr (A ,:)*KAAInvKAX ),1 )' ; 
quadTerm =quadTerm +rHat ' *(diagDOmegar .*rHat ); 
end


LInvDKAXr =L \DKXAr ' ; 
traceTerm1 =sum (sum (LInvKAX .*LInvDKAXr ,1 )' .*invDiagLambda ); 
traceTerm2 =sum (sum (LInvKAX .*(((L \DKXAr (A ,:))/LAA ' )*LAAInvKAX ),1 )' .*invDiagLambda ); 

ifuseFIC 

lambdaOmega =diagDOmegar .*invDiagLambda2 ; 
traceTerm3 =sum (diagDOmegar .*invDiagLambda )-sum (LInvKAXdiag .*lambdaOmega ); 
else
traceTerm3 =0 ; 
end
traceTerm =2 *traceTerm1 -traceTerm2 +traceTerm3 ; 


gloglik (r )=0.5 *quadTerm -0.5 *traceTerm ; 
end




quadTerm =rHat ' *rHat ; 
traceTerm =sum (invDiagLambda )-sum (LInvKAXdiag .*invDiagLambda2 ); 
sigma_sigmaLB =sigma *(sigma -sigmaLB ); 
gloglik (s )=sigma_sigmaLB *(quadTerm -traceTerm ); 


gnloglik =-1 *gloglik ; 
else

gnloglik =[]; 
end
end
end
end

end


methods 

function [activeSet ,activeSetIndices ,critProfile ]=selectActiveSet (this ,X ,y ,beta ,theta ,sigma )


























import classreg.learning.modelparams.GPParams ; 


M =this .ActiveSetSize ; 
activemethod =this .ActiveSetMethod ; 
J =this .Options .RandomSearchSetSize ; 
tol =this .Options .ToleranceActiveSet ; 
isverbose =this .Verbose >0 ; 
N =size (X ,1 ); 
tau =this .Options .Regularization ; 


kfun =makeKernelAsFunctionOfXNXM (this .Kernel ,theta ); 
diagkfun =makeDiagKernelAsFunctionOfXN (this .Kernel ,theta ); 


ifisverbose 
activeSetMessageStr =getString (message ('stats:classreg:learning:impl:GPImpl:GPImpl:MessageActiveSetSelection' ,activemethod ,M )); 
fprintf ('\n' ); 
fprintf ('%s\n' ,activeSetMessageStr ); 
end


switchlower (activemethod )
case lower (GPParams .ActiveSetMethodSGMA )

[activeSet ,~,critProfile ,~]=classreg .learning .gputils .selectActiveSet (X ,kfun ,diagkfun ,...
    'ActiveSetMethod' ,'SGMA' ,'ActiveSetSize' ,M ,...
    'RandomSearchSetSize' ,J ,'Tolerance' ,tol ,'Verbose' ,isverbose ,'Regularization' ,tau ); 

case lower (GPParams .ActiveSetMethodEntropy )

[activeSet ,~,critProfile ,~]=classreg .learning .gputils .selectActiveSet (X ,kfun ,diagkfun ,...
    'ActiveSetMethod' ,'Entropy' ,'ActiveSetSize' ,M ,...
    'RandomSearchSetSize' ,J ,'Tolerance' ,tol ,'Verbose' ,isverbose ,'Sigma' ,sigma ,'Regularization' ,tau ); 

case lower (GPParams .ActiveSetMethodLikelihood )

H =this .HFcn (X ); 
adjy =y -H *beta ; 
[activeSet ,~,critProfile ,~]=classreg .learning .gputils .selectActiveSet (X ,kfun ,diagkfun ,...
    'ActiveSetMethod' ,'Likelihood' ,'ActiveSetSize' ,M ,...
    'RandomSearchSetSize' ,J ,'Tolerance' ,tol ,'Verbose' ,isverbose ,'Sigma' ,sigma ,'ResponseVector' ,adjy ,'Regularization' ,tau ); 

case lower (GPParams .ActiveSetMethodRandom )

activeSet =randsample (N ,M ); 
critProfile =[]; 
end


if(length (activeSet )<M )


R =setdiff ((1 :N )' ,activeSet ); 


additionalPoints =R (randsample (length (R ),M -length (activeSet ))); 


activeSet =[activeSet ; additionalPoints ]; 
end






logicalActiveSet =false (N ,1 ); 
logicalActiveSet (activeSet )=true ; 
activeSetIndices =activeSet ; 
activeSet =logicalActiveSet ; 

end

end


methods 
function [phiHat ,nloglikHat ,cause ]=doMinimizationWithSomeConstParams (this ,objFun ,phi0 ,haveGrad )





constPhi =[this .ConstantKernelParameters ; this .ConstantSigma ]; 
partialPhi0 =phi0 (~constPhi ); 


[partialPhiHat ,nloglikHat ,cause ]=doMinimization (this ,@objFunWithFewerVars ,partialPhi0 ,haveGrad ); 


phiHat =phi0 ; 
phiHat (~constPhi )=partialPhiHat ; 


function [f ,partialGrad ]=objFunWithFewerVars (partialPhi )
fullPhi =phi0 ; 
fullPhi (~constPhi )=partialPhi ; 
[f ,fullGrad ]=objFun (fullPhi ); 
ifisempty (fullGrad )
partialGrad =[]; 
else
partialGrad =fullGrad (~constPhi ); 
end
end
end

function [phiHat ,fHat ,cause ]=doMinimization (this ,objFun ,phi0 ,haveGrad )



























import classreg.learning.modelparams.GPParams ; 
switchlower (this .Optimizer )
case lower (GPParams .OptimizerFminunc )



opts =this .OptimizerOptions ; 




if(strcmpi (opts .GradObj ,'on' )&&(haveGrad ==false ))
opts .GradObj ='off' ; 
end



if(this .Verbose >0 )
opts .Display ='iter' ; 
end


[phiHat ,fHat ,exitFlag ]=fminunc (objFun ,phi0 ,opts ); 


switchexitFlag 
case 1 

cause =0 ; 
case {2 ,3 ,5 }

cause =1 ; 
otherwise

cause =2 ; 
end
case lower (GPParams .OptimizerFmincon )



opts =this .OptimizerOptions ; 




if(strcmpi (opts .GradObj ,'on' )&&(haveGrad ==false ))
opts .GradObj ='off' ; 
end



if(this .Verbose >0 )
opts .Display ='iter' ; 
end


[phiHat ,fHat ,exitFlag ]=fmincon (objFun ,phi0 ,[],[],[],[],[],[],[],opts ); 


switchexitFlag 
case 1 

cause =0 ; 
case {2 ,3 ,4 ,5 }

cause =1 ; 
otherwise

cause =2 ; 
end
case lower (GPParams .OptimizerFminsearch )



opts =this .OptimizerOptions ; 



if(this .Verbose >0 )
opts .Display ='iter' ; 
end


[phiHat ,fHat ,exitFlag ]=fminsearch (objFun ,phi0 ,opts ); 


switchexitFlag 
case 1 





cause =0 ; 
otherwise

cause =2 ; 
end

case lower (GPParams .OptimizerQuasiNewton )



opts =this .OptimizerOptions ; 




if(strcmpi (opts .GradObj ,'on' )&&(haveGrad ==false ))
opts .GradObj ='off' ; 
end



if(this .Verbose >0 )
opts .Display ='iter' ; 
end


initialStepSize =getInitialStepSize (this ,phi0 ); 
[phiHat ,fHat ,~,exitFlag ]=classreg .learning .gputils .fminqn (objFun ,phi0 ,'Options' ,opts ,'InitialStepSize' ,initialStepSize ); 


cause =exitFlag ; 

case lower (GPParams .OptimizerLBFGS )



opts =this .OptimizerOptions ; 




if(strcmpi (opts .GradObj ,'on' )&&(haveGrad ==false ))
opts .GradObj ='off' ; 
end



if(this .Verbose >0 )
opts .Display ='iter' ; 
end


initialStepSize =getInitialStepSize (this ,phi0 ); 
[phiHat ,fHat ,~,exitFlag ]=classreg .learning .impl .GPImpl .doLBFGS (objFun ,phi0 ,opts ,initialStepSize ); 


switchexitFlag 
case 0 

cause =0 ; 
case 1 

cause =1 ; 
otherwise

cause =2 ; 
end
end

end

function initialStepSize =getInitialStepSize (this ,phi0 )
initialStepSize =this .InitialStepSize ; 


isStringAuto =internal .stats .isString (initialStepSize )&&...
    strcmpi (initialStepSize ,classreg .learning .modelparams .GPParams .StringAuto ); 
ifisStringAuto 
initialStepSize =norm (phi0 ,Inf )*0.5 +0.1 ; 
end
end

function tf =checkCacheSizeForFitting (this ,N ,D ,M )






















isARDKernel =strncmpi (this .KernelFunction ,'ard' ,3 ); 


ifisARDKernel 
memoryNeededMB =(N *M *D *8 )/1e6 ; 
else
memoryNeededMB =(N *M *8 )/1e6 ; 
end


cacheSizeMB =this .CacheSize ; 


if(memoryNeededMB <=cacheSizeMB )
tf =true ; 
else
tf =false ; 
end

end
end


methods (Static )
function checkExplicitBasisRank (HFcn ,X )






H =HFcn (X ); 


p =rank (H ); 


isok =(p ==size (H ,2 )); 


if~isok 
warning (message ('stats:classreg:learning:impl:GPImpl:GPImpl:BadBasisMatrix' )); 
end
end

function [phiHat ,fHat ,gHat ,exitFlag ]=doLBFGS (objFun ,phi0 ,opts ,initialStepSize )

numcomp =1 ; 
solver =classreg .learning .fsutils .Solver (numcomp ); 


solver .SolverName ='lbfgs' ; 

ifstrcmpi (opts .GradObj ,'on' )
solver .HaveGradient =true ; 
else
solver .HaveGradient =false ; 
end

solver .GradientTolerance =opts .TolFun ; 
solver .StepTolerance =opts .TolX ; 
solver .IterationLimit =opts .MaxIter ; 

ifstrcmpi (opts .Display ,'iter' )
solver .Verbose =1 ; 
else
solver .Verbose =0 ; 
end

solver .MaxLineSearchIterations =50 ; 
solver .InitialStepSize =initialStepSize ; 



warnState =warning ('query' ,'all' ); 
warning ('off' ,'stats:classreg:learning:fsutils:Solver:LBFGSUnableToConverge' ); 
cleanupObj =onCleanup (@()warning (warnState )); 


results =solver .doMinimization (objFun ,phi0 ,numcomp ); 
phiHat =results .xHat ; 
fHat =results .fHat ; 
gHat =results .gHat ; 
exitFlag =results .cause ; 
end
end


methods 
function [loores ,neff ]=postFitStatisticsExact (this ,isBetaEstimatedUsingExact )


























ifnargin <2 
isBetaEstimatedUsingExact =false ; 
end


import classreg.learning.modelparams.GPParams ; 
tf =strcmpi (this .PredictMethod ,GPParams .PredictMethodExact ); 
if~tf 
error (message ('stats:classreg:learning:impl:GPImpl:GPImpl:PostFitStatsPredictMethodExact' ,GPParams .PredictMethodExact )); 
end


thetaHat =this .ThetaHat ; 
sigmaHat =this .SigmaHat ; 
alphaHat =this .AlphaHat ; 


X =this .X ; %#ok<PROPLC,*PROP> 
N =size (X ,1 ); %#ok<PROPLC> 



ifisempty (this .LFactor )

L =computeLFactorExact (this ,X ,thetaHat ,sigmaHat ); %#ok<PROPLC> 
else

L =this .LFactor ; 
assert (size (L ,1 )==N ); 
end



LInv =L \eye (N ); 





Avec =sum (LInv .*LInv ,1 )' ; 










































ifstrcmpi (this .FitMethod ,GPParams .FitMethodExact )||isBetaEstimatedUsingExact 



H =this .HFcn (X ); %#ok<PROPLC> 
LInvH =LInv *H ; 
[Q ,~]=qr (LInvH ,0 ); 
QTLInv =Q ' *LInv ; 
Tvec =sum (QTLInv .*QTLInv ,1 )' ; 
loores =alphaHat ./(Avec -Tvec ); 


ifnargout >1 
neff =N -sigmaHat ^2 *sum (Avec )+sigmaHat ^2 *sum (Tvec ); 
neff =max (0 ,neff ); 
end
else





loores =alphaHat ./Avec ; 


ifnargout >1 
neff =N -sigmaHat ^2 *sum (Avec ); 
neff =max (0 ,neff ); 
end
end

end
end

end

