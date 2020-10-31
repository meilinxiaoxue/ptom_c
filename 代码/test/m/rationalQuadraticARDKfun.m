function KNM = rationalQuadraticARDKfun(usepdist,theta,XN,XM,calcDiag) %#codegen
% Matern32Kfun - calculate distance for RationalQuadraticARD Kernel

%   Copyright 2017 The MathWorks, Inc.

coder.inline('always');

% Get sigmaL and sigmaF from theta.
d        = length(theta) - 2;
sigmaL   = exp(theta(1:d));
alpha    = exp(theta(d+1));
sigmaF   = exp(theta(d+2));
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
    KNM = classreg.learning.coder.gputils.calcDistance(XN(:,1)/sigmaL(1),XM(:,1)/sigmaL(1),usepdist,makepos);
    for r = 2:coder.internal.indexInt(d)
        KNM = KNM + classreg.learning.coder.gputils.calcDistance(XN(:,r)/sigmaL(r),XM(:,r)/sigmaL(r),usepdist,makepos);
    end
    
    % Find the complete kernel.
    % In order to keep calculation accuracy even when alpha is
    % large, take the logarithm of the entire equation in order
    % take advantage of the accurary of log1p.  Then, transform
    % the answer back by using the exp function.
    KNM = KNM./(2*alpha);
    KNM = (2.*log(sigmaF))+(-alpha.*log1p(KNM));
    KNM = exp(KNM);
end

end