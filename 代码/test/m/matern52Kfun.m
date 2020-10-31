function KNM = matern52Kfun(usepdist,theta,XN,XM,calcDiag) %#codegen
% Matern32Kfun - calculate distance for Matern52 Kernel

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
    % Compute sqrt(5)*D/sigmaL where D is the Euclidean distance matrix.
    KNM = classreg.learning.coder.gputils.calcDistance(XN/sigmaL,XM/sigmaL,usepdist);
    KNM = sqrt(5)*sqrt(KNM);
    
    % Apply exp.
    KNM = (sigmaF^2)*((1 + KNM.*(1 + KNM/3)).*exp(-KNM));
end

end