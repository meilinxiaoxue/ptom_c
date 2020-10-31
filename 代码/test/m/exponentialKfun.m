function KNM = exponentialKfun(usepdist,theta,XN,XM,calcDiag) %#codegen
% ExponentialKfun - calculate distance for Exponential Kernel

%   Copyright 2017 The MathWorks, Inc.

coder.inline('always');

% Get sigmaL and sigmaF from theta.
sigmaL   = exp(theta(1));
sigmaF   = exp(theta(2));
tiny     = 1e-6;
sigmaL   = max(sigmaL,tiny);
sigmaF   = max(sigmaF,tiny);

if calcDiag
    N       = size(XN,1);
    KNM     = (sigmaF^2)*ones(N,1);
else
    % Compute D/sigmaL where D is the Euclidean distance matrix.
    KNM = classreg.learning.coder.gputils.calcDistance(XN/sigmaL,XM/sigmaL,usepdist);
    KNM = sqrt(KNM);
    
    % Apply exp.
    KNM = (sigmaF^2)*exp(-1*KNM);
end

end