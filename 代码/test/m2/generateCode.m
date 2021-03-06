function script =generateCode (m )








this =m .Impl ; 


basisName =this .BasisFunction ; 
kernelName =this .KernelFunction ; 


headerText =generateHeader (kernelName ); 


basisText =generateBasisText (basisName ); 


[kernelText ,kernelEvaluation ]=generateKernelText (kernelName ); 


evaluationText =generateEvaluationText (kernelEvaluation ); 


script =sprintf ('%s\n%s\n%s\n\n%s' ,headerText ,evaluationText ,basisText ,kernelText ); 


function headerText =generateHeader (kernelName )


headerTextCell ={
 'function pred = fcn(X, XFit, alpha, beta, sigmaL, sigmaF, hyperparameters)' 
 '%#codegen' 
 '' 
 sprintf ('%% GPM evaluation for %s kernel' ,kernelName )
 '% X = New X value [inputs x 1]' 
 '% XFit = Fit data [inputs x #ActiveSetPoints]' 
 '% alpha = Model alpha' 
 '% beta = Model beta' 
 '% sigmaL = Length kernel parameters' 
 '% sigmaF = Signal variance' 
 '% hyperparameters = Only used by the rational quadratic kernel for its alpha hyperparameter' 
 '' 
 sprintf ('%% Autogenerated on %s.' ,datestr (now )); 
 }; 
headerText =sprintf ('%s\n' ,headerTextCell {:}); 


function basisText =generateBasisText (basisFunction )


import classreg.learning.modelparams.GPParams 
ifstrcmpi (basisFunction ,GPParams .BasisNone )


basisTextCell ={
 '% Evaluate model' 
 'pred = kernelAlpha;' 
 }; 
else
switchbasisFunction 
case GPParams .BasisConstant 
basisLine ={'basisBeta = beta;' }; 
case GPParams .BasisLinear 
basisLine ={
 'basisBeta = beta(1);' 
 'for i=1:length(X)' 
 '    basisBeta = basisBeta + X(i)*beta(i+1);' 
 'end' 
 }; 
case GPParams .BasisPureQuadratic 
basisLine ={
 'basisBeta = beta(1);' 
 'dims=length(X);' 
 'for i=1:dims' 
 '    basisBeta = basisBeta + X(i)*(beta(i+1) + X(i)*beta(dims+i+1));' 
 'end' 
 }; 
otherwise
error (message ('stats:classreg:learning:gputils:generateCode:UnknownBasis' ,basisFunction )); 
end
basisTextCell ={
 sprintf ('%% Create "%s" basis' ,basisFunction ); 
 sprintf ('%s\n' ,basisLine {:})
 '% Evaluate model' 
 'pred = kernelAlpha + basisBeta;' 
 }; 
end
basisText =sprintf ('%s\n' ,basisTextCell {:}); 


function evaluationText =generateEvaluationText (kernelEvaluation )

evaluationTextCell ={
 kernelEvaluation 
 }; 
evaluationText =sprintf ('%s\n' ,evaluationTextCell {:}); 


function [kernelText ,kernelEvaluation ]=generateKernelText (kernelName )

kernelEvaluationCell ={
 sprintf ('%% Evaluate the "%s" kernel at X' ,kernelName ); 
 'kernelAlpha = 0;' 
 'for i=1:size(XFit,1)' 
 sprintf ('    ithKernel = evaluate%s(X, XFit(i,:), sigmaL, sigmaF, hyperparameters);' ,kernelName ); 
 '    kernelAlpha = kernelAlpha+ithKernel*alpha(i);' 
 'end' 
 }; 
kernelEvaluation =sprintf ('%s\n' ,kernelEvaluationCell {:}); 

kernelFunctionLineCell ={
 sprintf ('function kernelEval = evaluate%s(X, XFit, sigmaL, sigmaF, hyperparameters)' ,kernelName ); 
 sprintf ('%% Evaluating the %s kernel for X' ,kernelName ); 
 }; 
kernelFunctionLine =sprintf ('%s\n' ,kernelFunctionLineCell {:}); 

import classreg.learning.modelparams.GPParams 
switchkernelName 
case GPParams .Matern32 
distText =generateDist (false ); 
kernelText =generateMatern32Text (); 
case GPParams .Matern52 
distText =generateDist (false ); 
kernelText =generateMatern52Text (); 
case GPParams .Exponential 
distText =generateDist (false ); 
kernelText =generateExponentialText (); 
case GPParams .SquaredExponential 
distText =generateDist (false ); 
kernelText =generateSquaredExponentialText (); 
case GPParams .RationalQuadratic 
distText =generateDist (false ); 
kernelText =generateRationalQuadraticText (); 
case GPParams .Matern32ARD 
distText =generateDist (true ); 
kernelText =generateMatern32Text (); 
case GPParams .Matern52ARD 
distText =generateDist (true ); 
kernelText =generateMatern52Text (); 
case GPParams .ExponentialARD 
distText =generateDist (true ); 
kernelText =generateExponentialText (); 
case GPParams .SquaredExponentialARD 
distText =generateDist (true ); 
kernelText =generateSquaredExponentialText (); 
case GPParams .RationalQuadraticARD 
distText =generateDist (true ); 
kernelText =generateRationalQuadraticText (); 
otherwise
error (message ('stats:classreg:learning:gputils:generateCode:UnknownKernel' ,kernelName ))
end
kernelText =sprintf ('%s\n%s\n%s' ,kernelFunctionLine ,distText ,kernelText ); 


function distText =generateDist (ard )


ifard 
distTextCell ={
 '% Compute normalized Euclidean distances.' 
 'd = length(X);' 
 'distanceSquared = 0;' 
 'for r = 1:d' 
 '    distanceSquared = distanceSquared + (X(r)/sigmaL(r)-XFit(:,r)/sigmaL(r)).^2;' 
 'end' 
 }; 
else
distTextCell ={
 'distanceSquared = 0;' 
 'd = length(X);' 
 'for j=1:d' 
 '    distanceSquared = distanceSquared + (XFit(j)-X(j))^2;' 
 'end' 
 'distanceSquared = distanceSquared/sigmaL^2;' 
 }; 
end
distText =sprintf ('%s\n' ,distTextCell {:}); 


function kernelText =generateMatern32Text ()

kernelTextCell ={
 '% Apply exp.' 
 'kernelEval = sqrt(3)*sqrt(distanceSquared);' 
 'kernelEval = (sigmaF^2)*((1 + kernelEval).*exp(-kernelEval));' 
 }; 
kernelText =sprintf ('%s\n' ,kernelTextCell {:}); 


function kernelText =generateMatern52Text ()

kernelTextCell ={
 '% Apply exp.' 
 'distancesqrt5 = sqrt(5)*sqrt(distanceSquared);' 
 'kernelEval = (sigmaF^2)*((1 + distancesqrt5.*(1 + distancesqrt5/3)).*exp(-distancesqrt5));' 
 }; 
kernelText =sprintf ('%s\n' ,kernelTextCell {:}); 


function kernelText =generateExponentialText ()

kernelTextCell ={
 'kernelEval = (sigmaF^2)*exp(-1*sqrt(distanceSquared));' 
 }; 
kernelText =sprintf ('%s\n' ,kernelTextCell {:}); 


function kernelText =generateSquaredExponentialText ()

kernelTextCell ={
 'kernelEval = (sigmaF^2)*exp(-0.5*distanceSquared);' 
 }; 
kernelText =sprintf ('%s\n' ,kernelTextCell {:}); 


function kernelText =generateRationalQuadraticText ()

kernelTextCell ={
 'basem1 = distanceSquared/(2*hyperparameters);' 
 'kernelEval = (2.*log(sigmaF))+(-hyperparameters.*log1p(basem1));' 
 'kernelEval = exp(kernelEval);' 
 }; 
kernelText =sprintf ('%s\n' ,kernelTextCell {:}); 

