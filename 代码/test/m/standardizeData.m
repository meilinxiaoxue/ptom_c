function [Xs,mu,sigma] = standardizeData(X,cols)
%standardizeData - Standardize the predictors by centering and scaling.
%   Xs = standardizeData(X) takes a N-by-d matrix X where N is the number
%   of observations and d is the number of predictors and returns a
%   standardized predictor matrix Xs of size N-by-d such that:
%
%   Xs(:,r)  = (X(:,r) - mu(r))/sigma(r)
%
%   where
%
%   mu(r)    = mean(X(:,r))
%   sigma(r) =  std(X(:,r))
%
%   If sigma(r) is close to 0 then mu(r) is set to 0 and sigma(r) is set to
%   1 i.e., Xs(:,r) = X(:,r) for this case. For example, if some column of
%   X is a constant then this column remains the same in Xs.
%
%   Xs = standardizeData(X,COLS) also takes a 1-by-d logical vector
%   indicating which columns to standardize. Default is to standardize all
%   columns.
%
%   [Xs,mu,sigma] = standardizeData(X) also returns d-by-1 vectors mu and
%   sigma used to create Xs from X.

%   Copyright 2014-2015 The MathWorks, Inc.

    if nargin<2
        cols = true(1,size(X,2));
    end

    % 1. Tentative values for mu and sigma as 1-by-d vectors.
    mu    = mean(X,1);
    sigma =  std(X,0,1);
    if any(~cols)
        mu(~cols) = 0;
        sigma(~cols) = 1;
    end

    % 2. Modify mu and sigma based on the value of sigma.
    zeroSigmaIdx        = sigma < sqrt(eps(class(X)));
    mu(zeroSigmaIdx)    = 0;
    sigma(zeroSigmaIdx) = 1;
    
    % 3. Compute Xs.
    Xs                    = X;
    nonZeroSigmaIdx       = ~zeroSigmaIdx;
    Xs(:,nonZeroSigmaIdx) = bsxfun(@rdivide,bsxfun(@minus,X(:,nonZeroSigmaIdx),mu(1,nonZeroSigmaIdx)),sigma(1,nonZeroSigmaIdx));
    
    % 4. Return mu, sigma as column vectors if needed.
    if nargout > 1
        mu    = mu';
        sigma = sigma';
    end
end