function KNM = rationalQuadraticKfun(usepdist,theta,XN,XM,calcDiag) %#codegen
% Matern32Kfun - calculate distance for RationalQuadratic Kernel

%   Copyright 2017 The MathWorks, Inc.

coder.inline('always');

% Get sigmaL and sigmaF from theta.
sigmaL   = exp(theta(1));
alpha    = exp(theta(2));
sigmaF   = exp(theta(3));
tiny     = 1e-6;
sigmaL   = max(sigmaL,tiny);
alpha    = max(alpha,tiny);
sigmaF   = max(sigmaF,tiny);
makepos  = false;

if calcDiag
    N       = size(XN,1);
    KNM     = (sigmaF^2)*ones(N,1);
else
    % Compute normalized Euclidean distances.
    KNM = classreg.learning.coder.gputils.calcDistance(XN/sigmaL,XM/sigmaL,usepdist,makepos);
    
    % Find the complete kernel.
    % In order to keep calculation accuracy even when alpha is
    % large, take the logarithm of the entire equation in order
    % take advantage of the accurary of log1p. Then, transform
    % the answer back by using the exp function.
    KNM = KNM./(2*alpha);
    KNM = (2.*log(sigmaF))+(-alpha.*log1p(KNM));
    KNM = exp(KNM);
end

end