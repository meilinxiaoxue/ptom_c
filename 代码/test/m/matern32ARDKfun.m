function KNM = matern32ARDKfun(usepdist,theta,XN,XM,calcDiag) %#codegen
% Matern32Kfun - calculate distance for Matern32ARD Kernel

%   Copyright 2017 The MathWorks, Inc.

coder.inline('always');

% Get sigmaL and sigmaF from theta.
d        = length(theta) - 1;
sigmaL   = exp(theta(1:d));
sigmaF   = exp(theta(d+1));
tiny     = 1e-6;
sigmaL   = max(sigmaL,tiny);
sigmaF   = max(sigmaF,tiny);
makepos  = true;

if calcDiag
    N       = size(XN,1);
    KNM     = (sigmaF^2)*ones(N,1);
else
    % Compute normalized Euclidean distances.
    KNM = classreg.learning.coder.gputils.calcDistance(XN(:,1)/sigmaL(1),XM(:,1)/sigmaL(1),usepdist,makepos);
    for r = 2:coder.internal.indexInt(d)
        KNM = KNM + classreg.learning.coder.gputils.calcDistance(XN(:,r)/sigmaL(r),XM(:,r)/sigmaL(r),usepdist,makepos);
    end
    
    % Matern32
    D = sqrt(3)*sqrt(KNM);
    KNM = (sigmaF^2)*((1 + D).*exp(-D));
end

end
