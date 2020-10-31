function KNM = CustomKernel(theta,kernelFcn,XN,XM,calcDiag) %#codegen

%   Copyright 2017 The MathWorks, Inc.

coder.inline('always');

N = size(XN,1);

% kernelFcn is empty when a built-in kernel function is used, in which 
% case there is no calls to CustomKernel. kernelFcn is a codegen-only 
% property that is used to store the name of the user-defined kernel function. 
% If the name of user-specified kernel is empty, then both MATLAB and codegen 
% resort to 'SquaredExponential' and there is no call to CustomKernel.
% Therefore, the following codition is only met when end-users alter the
% value of kernelFcn field in the compact struct used for codegen.
if isempty(kernelFcn)
    KNM = zeros(N,1);
    return
end

% Create function handle for the user-defined kernel 
customFcn = str2func(kernelFcn);

% Call user-defined kernel function.
if calcDiag    
    KNM = zeros(N,1);
    for i = 1:coder.internal.indexInt(N)
        KNM(i) = customFcn(XN(i,:),XN(i,:),theta);
    end
else
    KNM = customFcn(XN,XM,theta);
end