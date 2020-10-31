function [varargout] = fitrkernel(X,Y,varargin)
%FITRKERNEL Fit a kernel regression model by explicit feature expansion. 
%     OBJ=FITRKERNEL(X,Y) returns a kernel regression model by explicitly 
%     mapping X to a high dimensional space. FITRKERNEL sets a random
%     transformation T() such that dot(T(X(i,:)),T(X(j,:))) approximates
%     the Gausian kernel. Once X is transformed, FITRKERNEL implements a
%     LBFGS (low-memory BFGS) solver with rigde (L2) regularization. X is a
%     N-by-P full matrix for N observations and P predictors. Y is a
%     floating-point vector with N elements.
%  
%     [OBJ,FITINFO]=FITRKERNEL(X,Y) also returns a struct containing fit
%     information FITINFO.
%  
%     [...]=FITRKERNEL(X,Y,'PARAM1',val1,'PARAM2',val2,...) specifies optional
%     name-value parameter pairs:
%       'BetaTolerance'      - Relative tolerance on linear coefficients and
%                              bias term. A non-negative scalar. Default is 1e-5.
%       'BlockSize'          - A positive scalar specifying the maximum amount of 
%                              memory that can be allocated in megabytes(MB). If 
%                              FITRKERNEL requires more memory than this parameter
%                              to hold the transformed data, the internal
%                              algorithms will automatically switch to a 
%                              block-wise strategy. Default is 4e3, i.e. 4GB.
%       'BoxConstraint'      - Positive scalar specifying the box constraint. 
%                              Valid only for SVM learner and when Lambda is not 
%                              given. Default is 1.
%       'Epsilon'            - Either 'auto' or a non-negative scalar specifying half 
%                              the width of the epsilon-insensitive band.
%                              If 'auto', epsilon is set to iqr(Y)/13.49 or 0.1 if 
%                              iqr(Y) equals 0. Default is 'auto'.
%       'NumExpansionDimensions' - Number of dimensions in the expanded space.
%                              Either 'auto' or a positive integer. If you pass 
%                              'auto', FITRKERNEL selects an appropriate number 
%                              using a heuristic procedure.  Default is 'auto'.
%       'GradientTolerance'  - Absolute gradient tolerance. A non-negative scalar. 
%                              Default is 1e-6;
%       'HessianHistorySize' - Size of history buffer for Hessian approximation. 
%                              A positive integer. Default is 15.
%       'IterationLimit'     - Maximal number of optimization iterations. A
%                              positive integer. Default is 1000 if the transformed
%                              data fits in memory (see BlockSize) or 100
%                              if FITRKERNEL switches to a block-wise strategy.
%       'KernelScale'        - Either string 'auto' or positive scalar specifying
%                              the value for the scale parameter. If you pass 'auto', 
%                              FITRKERNEL selects an appropriate scale using a heuristic
%                              procedure. Default is 1. 
%       'Lambda'             - Either 'auto' or a non-negative scalar values
%                              specifying the strength of the regularization term.
%                              If 'auto', the regularization parameter is set to 
%                              1/N, where N is the number of observations in X. 
%                              Default is 'auto'.
%       'Learner'            - String, either 'svm' for support vector machine or
%                              'leastsquares' for least-squares regression.
%                              Default is 'svm'.
%       'RandomStream'       - A random number stream to control reproducibility 
%                              of the random basis functions used for
%                              transforming X to a high dimensional space.
%       'Verbose'            - Verbosity level, a non-negative integer:
%                               * 0  - FITRKERNEL does not display any
%                                      diagnostic messages. (default)
%                               * 1  - FITRKERNEL periodically displays the
%                                      value of the objective function,
%                                      gradient magnitude, and other
%                                      diagnostic info.
%       'Weights'            - Vector of observation weights, one weight per
%                              observation. FITRKERNEL normalizes the weights to
%                              add up to one. Default is equal weights.
%                          
%   See also fitrlinear.
        
%   Copyright 2017-2018 The MathWorks, Inc.

%   Undocumented warm start using ADMM:
%
%   FITRKERNEL can also refine the initial estimates of the parameters by
%   using a number of iterations of the ADMM algorithm (warm start). To control
%   the ADMM iterations the extra parameter name/value pairs are supported:
%
%       'ADMMIterationLimit' - Non-negative integer, defaults to 1.
%       'ADMMUpdateIterationLimit' - Positive integer, number of iterations for LBFGS 
%                           running inside the ADMM chunks. This value is applied to 
%                           all ADDM iterations unless WarmStartIterationLimit was also 
%                           specified, in such case ADMMUpdateIterationLimit is used for 
%                           all iterations after the first one. Default is 100.
%       'Consensus'      -  Strength of the ADMM penalty ensuring consensus across the 
%                           estimated parameters for different parts of the tall array. 
%                           A non-negative scalar, defaults to 0.1. Relevant only when
%                           ADMMIterationLimit>1
%       'WarmStartIterationLimit' - Positive integer. When FITRKERNEL switches to a 
%                           block-wise startegy (see BlockSize), FITRKERNEL first 
%                           refines the initial estimates of the parameters by 
%                           fitting the model locally to parts of the data and 
%                           combining the coefficients by averaging. 
%                           WarmStartIterationLimit sets the maximum number of 
%                           iterations for the local LBFGS. Default is 100.
%                           Tip: Increasing WarmStartIterationLimit may reduce the 
%                           fitting time of the main LBFGS algorithm executed after 
%                           the warm start.
%
%   TIPS:
%    - With larger values of the consensus penalty ADMM converges quicker,
%      with smaller vales of the consensus ADMM converges to lower values of
%      the objective function.
%    - Either 'IterationLimit' or 'ADMMIterationLimit' can be set to 0 to run only
%      ADMM iterations or distributed LBFGS iterations respectively.
%
%   Other undocummented parameter name/value pairs:
%
%         'ObservationsIn'  - only supports 'rows'
%         'Regularization'  - only supports 'ridge'
%         'Solver'          - only supports 'lbfgs'
%         'Beta'            - not supported, specifically forbiden
%         'Bias'            - not supported, specifically forbiden
%         'FitBias'         - only supports true
%         'Tranformation'   - either 'FastFood' or 'KitchenSinks'
%         'UseParallel'     - not supported
%         'InitialStepSize' - A real positive scalar specifying the approximate maximum 
%                             absolute value of the first step of the 'lbfgs' algorithm. 
%                             Suppose g0 is the maximum absolute value of the gradient at 
%                             the initial point. The initial Hessian approximation is 
%                             chosen as B0 =(g0/s0)*I where I is the identity matrix. 
%                             Default is 1.
%         'TallPassLimit'   - Maximum number of passes allowed. Defaults to intmax.
%                             TallPassLimit is most relevant when using tall data.
%


if nargin > 2
    [varargin{:}] = convertStringsToChars(varargin{:});
end

[varargout{1:nargout}] = RegressionKernel.fit(X,Y,varargin{:});

end