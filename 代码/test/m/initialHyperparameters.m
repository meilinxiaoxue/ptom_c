function [BestTheta,BestNoise,CostHistory] = initialHyperparameters(kernelFunction,basisFunction,X,Y,Criteria)
%initialHyperparameters estimate initial hyperparameters using LOO-loss or logML
%    [BestTheta,BestNoise,CostHistory] = initialHyperparameters(kernelFunction,basisFunction,X,Y,Criteria)
%   
%    Estimate initial hyperparameters by sampling hyperparameters
%       At present 64 different hyperparameter values are used and noise to
%       signal ratios of [0.0001 0.001 0.01 0.05 0.1 0.2 0.5] are tried for
%       each hyperparameter value. The trial lengths are chosen between
%       0.001 and 100. These search criteria work best if the inputs are
%       standardized. The best starting value is chosen using leave-one-out
%       loss.
%    Criteria can be:
%           'LOO-loss' leave-one-out loss (Default)
%           'logML'    log of marginal likelihood

%  Copyright 2015-2017 The MathWorks, Inc.

if nargin<5
    Criteria = 'LOO-loss';
end
% range of noise to signal ratios (think of this like 1-R^2)
noise2signal = [0.0001 0.001 0.01 0.05 0.1 0.2 0.5];

nf = size(X,2);
if strncmpi(kernelFunction,'ard',3)
    % ARD kernel
    kParams = ones(nf+1,1);
else
    % isotropic kernel
    kParams = [1 1]';
end

% figure out whether the kernel is rational quadratic
isRQ  = contains(lower(kernelFunction),'rationalquadratic');

% add alpha for the rational quadratic kernel
if isRQ
    % sigmaF is still the last parameter, so duplicate it
    kParams(end+1) = kParams(end);
    
    % alpha is the second to last parameter
    % the default value should be 1
    kParams(end-1) = 1;
end

N = length(Y);

% make kernel object
[Theta0,K] = classreg.learning.gputils.makeKernelObject(kernelFunction,kParams);
% get function handle to evaluate kernel for different theta
kfcn = K.makeKernelAsFunctionOfTheta(X,X,true);

BestTheta = Theta0;
BestNoise = Inf;


% trial lengths between 0.001 and 10^2
NumTrials = 64;
if strncmpi(kernelFunction,'ard',3)
    % use a sobol net to get an evenly distributed set of starting lengths
    TrialLengths = 10.^(net(sobolset(nf),NumTrials)*5-3);
else
    % just use equispaced points
    TrialLengths = logspace(-3,2,NumTrials)';
end
minCost = Inf;

if ~strcmp(basisFunction,'none')
    % work with residuals after applying least squares on explicit basis 
    HFcn = classreg.learning.gputils.makeBasisFunction(basisFunction);
    H = HFcn(X);
    Y = Y - H*(H\Y);
end

CostHistory = zeros(1,length(noise2signal)*NumTrials);
for i=1:length(noise2signal)
    for j=1:NumTrials
        % Kernel functions use logs of parameters
        
        % scaled problem - sigma_f^2 = 1, sigma_n^2 = noise2signal
        Theta0 = log([TrialLengths(j,:),1])/2;
        
        % add alpha for the rational quadratic kernel
        if isRQ
            % sigmaF is still the last parameter, so duplicate it
            Theta0(end+1) = Theta0(end);
            
            % alpha is the second to last parameter
            % the default value should be 1, and Theta is the logarithm of
            % the parameter values (log(1) = 0)
            Theta0(end-1) = 0;
        end
        
        % calculate kernel
        Ky = kfcn(Theta0);
        % add sigma noise to diagonal
        Ky(1:N+1:end) = Ky(1:N+1:end) + noise2signal(i);
        
        % adjust for actual signal variance
        % This trick only works when the kernel has a signal variance
        % hyperparameter.
        [L,flag] = chol(Ky,'lower');
        if flag
            % Ky not positive definite
            continue
        end
        a = L\Y;
        
        alpha = L'\a;
        
        switch lower(Criteria)
            case 'loo-loss'
                % choose best value using leave-one-out loss
                
                LInv = L \ speye(N);
                
                % Compute A values for each observation needed for computing
                % leave-one-out residuals. Avec below is a N-by-1 vector
                % containing the squared norms of the columns of LInv.
                Avec = sum(LInv.*LInv,1)';
                % calculate LOO loss
                rp = alpha./Avec;
                LOOloss = sum(rp.^2)/N;
                cost = LOOloss;
            case 'logml'
                % choose best value using log of marginal likelihood
                neglogML = 0.5*(a'*a) + sum(log(diag(L))) + (N/2)*log(2*pi);
                cost = neglogML;
            otherwise
                assert(false,'Invalid initial hyperparameters criteria')
        end
        % sigmaF profiled out
        sigmaF = a'*a/N;
        % unnomalized sigmaF
        Theta0(end) = log(sigmaF)/2;
        
        % cost function includes explicit basis so use Yfit
        
        CostHistory((i-1)*NumTrials+j) = cost;
        
        if cost<minCost
            % use the best estimate
            minCost=cost;
            BestTheta = exp(Theta0(:));
            BestNoise = sqrt(noise2signal(i))*BestTheta(end);
        end
    end
end
