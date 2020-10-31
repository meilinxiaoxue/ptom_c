function [theta0,kernel,isbuiltin] = makeKernelObject(kFcn,kParams)
%makeKernelObject - Create a kernel function object.
%   [theta0,kernel,isbuiltin] = makeKernelObject(kFcn,kParams)
%   takes a string or a function handle kFcn and a vector kParams
%   of parameters for the kernel function and makes an object
%   kernel representing the kernel function. theta0 is a vector of
%   unconstrained parameters for this kernel function. isbuiltin is
%   true if this is a built-in kernel function and false otherwise.
%
%   If kFcn is a function handle then kFcn should be callable like
%   this:
%
%   KMN = kFcn(XM,XN,kParams)
%
%   XM is a M-by-D matrix, XN is a N-by-D matrix and KMN is a
%   M-by-N matrix of kernel products such that KMN(i,j) is the
%   kernel product between XM(i,:) and XN(j,:). kParams is the
%   unconstrained parameter vector for kFcn. In this case, kernel
%   is an object of type classreg.learning.gputils.CustomKernel.
%
%   Built-in kernel functions are indicated by specifying kFcn as a
%   string. Possible choices are as follows:
%
%   import classreg.learning.modelparams.GPParams;
%
%   String value of kFcn             Type of kernel object
%   ====================             =====================
%   GPParams.Exponential           - classreg.learning.gputils.Exponential
%   GPParams.SquaredExponential    - classreg.learning.gputils.SquaredExponential
%   GPParams.Matern32              - classreg.learning.gputils.Matern32
%   GPParams.Matern52              - classreg.learning.gputils.Matern52
%   GPParams.RationalQuadratic     - classreg.learning.gputils.RationalQuadratic
%   GPParams.ExponentialARD        - classreg.learning.gputils.ExponentialARD
%   GPParams.SquaredExponentialARD - classreg.learning.gputils.SquaredExponentialARD
%   GPParams.Matern32ARD           - classreg.learning.gputils.Matern32ARD
%   GPParams.Matern52ARD           - classreg.learning.gputils.Matern52ARD
%   GPParams.RationalQuadraticARD  - classreg.learning.gputils.RationalQuadraticARD
%
%   When kFcn is a string, kParams is the natural parameterization
%   for the kernel function as described below:
%
%   String value of kFcn             Value for kParams
%   ====================             =====================
%   GPParams.Exponential           - A 2-by-1 vector PHI such that PHI(1) = length scale and
%                                    PHI(2) = square root of the multiplier of exp term.
%   
%   GPParams.SquaredExponential    - A 2-by-1 vector PHI such that PHI(1) = length scale and
%                                    PHI(2) = square root of the multiplier of exp term.
%
%   GPParams.Matern32              - A 2-by-1 vector PHI such that PHI(1) = length scale and
%                                    PHI(2) = square root of the multiplier of exp term.
%
%   GPParams.Matern52              - A 2-by-1 vector PHI such that PHI(1) = length scale and
%                                    PHI(2) = square root of the multiplier of exp term.
%
%   GPParams.RationalQuadratic     - A 3-by-1 vector PHI such that PHI(1) = length scale,
%                                    PHI(2) = square root of the multiplier of expression, and
%                                    PHI(3) = rational quadratic exponent
%
%   GPParams.ExponentialARD        - A (D+1)-by-1 vector PHI such that PHI(i) = length scale
%                                    for predictor i for i = 1...D and PHI(D+1) = square root
%                                    of the multiplier of the exp term.
%
%   GPParams.SquaredExponentialARD - A (D+1)-by-1 vector PHI such that PHI(i) = length scale
%                                    for predictor i for i = 1...D and PHI(D+1) = square root
%                                    of the multiplier of the exp term.
%
%   GPParams.Matern32ARD           - A (D+1)-by-1 vector PHI such that PHI(i) = length scale
%                                    for predictor i for i = 1...D and PHI(D+1) = square root
%                                    of the multiplier of the exp term.
%
%   GPParams.Matern52ARD           - A (D+1)-by-1 vector PHI such that PHI(i) = length scale
%                                    for predictor i for i = 1...D and PHI(D+1) = square root
%                                    of the multiplier of the exp term.
%
%   GPParams.RationalQuadraticARD  - A (D+2)-by-1 vector PHI such that PHI(i) = length scale
%                                    for predictor i for i = 1...D, PHI(D+1) = square root
%                                    of the multiplier of expression, and PHI(D+2) = 
%                                    rational quadratic exponent.
%
%   kernel is [] if the specification for kFcn is not valid.

%   Copyright 2014-2016 The MathWorks, Inc.

    if internal.stats.isString(kFcn)
        import classreg.learning.modelparams.GPParams;
        switch lower(kFcn)
            case lower(GPParams.Exponential)
                theta0    = log(kParams);
                kernel    = classreg.learning.gputils.Exponential.makeFromTheta(theta0);
                isbuiltin = true;
            case lower(GPParams.SquaredExponential)
                theta0    = log(kParams);
                kernel    = classreg.learning.gputils.SquaredExponential.makeFromTheta(theta0);
                isbuiltin = true;
            case lower(GPParams.Matern32)
                theta0    = log(kParams);
                kernel    = classreg.learning.gputils.Matern32.makeFromTheta(theta0);
                isbuiltin = true;
            case lower(GPParams.Matern52)
                theta0    = log(kParams);
                kernel    = classreg.learning.gputils.Matern52.makeFromTheta(theta0);
                isbuiltin = true;
            case lower(GPParams.RationalQuadratic)
                theta0    = log(kParams);
                kernel    = classreg.learning.gputils.RationalQuadratic.makeFromTheta(theta0);
                isbuiltin = true;
            case lower(GPParams.ExponentialARD)
                theta0    = log(kParams);
                kernel    = classreg.learning.gputils.ExponentialARD.makeFromTheta(theta0);
                isbuiltin = true;
            case lower(GPParams.SquaredExponentialARD)
                theta0    = log(kParams);
                kernel    = classreg.learning.gputils.SquaredExponentialARD.makeFromTheta(theta0);
                isbuiltin = true;
            case lower(GPParams.Matern32ARD)
                theta0    = log(kParams);
                kernel    = classreg.learning.gputils.Matern32ARD.makeFromTheta(theta0);
                isbuiltin = true;
            case lower(GPParams.Matern52ARD)
                theta0    = log(kParams);
                kernel    = classreg.learning.gputils.Matern52ARD.makeFromTheta(theta0);
                isbuiltin = true;
            case lower(GPParams.RationalQuadraticARD)
                theta0    = log(kParams);
                kernel    = classreg.learning.gputils.RationalQuadraticARD.makeFromTheta(theta0);
                isbuiltin = true;
            otherwise
                theta0    = [];
                kernel    = [];
                isbuiltin = false;
        end
    elseif isa(kFcn,'function_handle')
        theta0    = kParams;
        kernel    = classreg.learning.gputils.CustomKernel.makeFromTheta(theta0,kFcn);
        isbuiltin = false;
    else
        theta0    = [];
        kernel    = [];
        isbuiltin = false;
    end
end
