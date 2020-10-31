function hfcn = makeBasisFunction(str)
%makeBasisFunction - Create basis function handle.
%   HFCN = makeBasisFunction(STR) takes a string or a function handle STR
%   and returns a function handle HFCN that can be called like this:
%
%       H = HFCN(X)
%
%   where X is a N-by-D matrix of predictors and H is a N-by-P matrix of
%   basis functions. 
%
%   If STR is a string, the matrix H returned by HFCN depends on STR like
%   this:
%
%   import classreg.learning.modelparams.GPParams;
%
%       Value of STR                   H from HFCN
%       ===========================    ======================
%       GPParams.BasisNone          -  H = zeros(N,0)
%       GPParams.BasisConstant      -  H = ones(N,1)
%       GPParams.BasisLinear        -  H = [ones(N,1),X]
%       GPParams.BasisPureQuadratic -  H = [ones(N,1),X,X.^2]
%   
%   If STR is a function handle, HFCN is set equal to STR. In this case, it
%   is assumed that STR is callable as described above.
%
%   If STR specification is invalid, HFCN is [].
    
%   Copyright 2014-2015 The MathWorks, Inc.

    if internal.stats.isString(str)
        import classreg.learning.modelparams.GPParams;
        switch lower(str)
            case lower(GPParams.BasisNone)
                hfcn = @(X) zeros(size(X,1),0);
            case lower(GPParams.BasisConstant)
                hfcn = @(X) ones(size(X,1),1);
            case lower(GPParams.BasisLinear)
                hfcn = @(X) [ones(size(X,1),1),X];
            case lower(GPParams.BasisPureQuadratic)
                hfcn = @(X) [ones(size(X,1),1),X,X.^2];
            otherwise
                hfcn = [];
        end
    elseif isa(str,'function_handle')
        hfcn = str;
    else
        hfcn = [];
    end
end