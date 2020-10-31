function KNM = squaredExponentialKfun(usepdist,theta,XN,XM,calcDiag) %#codegen
% SquaredExponentialKfun - calculate distance for SquaredExponential Kernel

%   Copyright 2017 The MathWorks, Inc.

coder.inline('always');
% coder.internal.prefer_const(varargin);

% Get sigmaL and sigmaF from theta.
sigmaL   = exp(theta(1));
sigmaF   = exp(theta(2));
tiny     = 1e-6;
sigmaL   = max(sigmaL,tiny);
sigmaF   = max(sigmaF,tiny);
makepos  = false;

if calcDiag
    N       = size(XN,1);
    KNM     = (sigmaF^2)*ones(N,1);
else
    % Compute normalized Euclidean distances.
    KNM     = classreg.learning.coder.gputils.calcDistance(XN/sigmaL,XM/sigmaL,usepdist,makepos);
    
    % Apply exp.
    KNM     = (sigmaF^2)*exp(-0.5*KNM);
end
end