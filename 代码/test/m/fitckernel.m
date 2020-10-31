function [varargout] = fitckernel(X,Y,varargin)
%FITCKERNEL Fit a kernel classification model by explicit feature expansion. 
%     OBJ=FITCKERNEL(X,Y) returns a kernel classification model by explicitly 
%     mapping X to a high dimensional space. FITCKERNEL sets a random
%     transformation T() such that dot(T(X(i,:)),T(X(j,:))) approximates
%     the Gausian kernel. Once X is transformed, FITCKERNEL implements a
%     LBFGS (low-memory BFGS) solver with rigde (L2) regularization. X is a
%     N-by-P full matrix for N observations and P predictors. Y as a
%     categorical array, character array, logical vector, numeric vector, a
%     string array, or cell array of character vectors. If Y is a character
%     array, it must have one class label per row. Otherwise Y must be a
%     vector with N elements. FITCKERNEL supports binary classification
%     only.
%  
%     [OBJ,FITINFO]=FITCKERNEL(X,Y) also returns a struct containing fit
%     information FITINFO.
%  
%     [...]=FITCKERNEL(X,Y,'PARAM1',val1,'PARAM2',val2,...) specifies optional
%     name-value parameter pairs:
%       'BetaTolerance'      - Relative tolerance on linear coefficients and
%                              bias term. A non-negative scalar. Default is 1e-5.
%       'BlockSize'          - A positive scalar specifying the maximum amount of 
%                              memory that can be allocated in megabytes(MB). If 
%                              FITCKERNEL requires more memory than this parameter
%                              to hold the transformed data, the internal
%                              algorithms will automatically switch to a 
%                              block-wise strategy. Default is 4e3, i.e. 4GB.
%       'BoxConstraint'      - Positive scalar specifying the box constraint. 
%                              Valid only for SVM learner and when Lambda is not 
%                              given. Default is 1.
%       'ClassNames'         - Array of class names. Use the data type that exists
%                              in Y. You can use this argument to order the classes 
%                              or select a subset of classes for training. 
%                              Default: All class names in Y.
%       'Cost'               - Square matrix, where COST(I,J) is the cost of 
%                              classifying a point into class J if its true class 
%                              is I. Alternatively, COST can be a structure S with 
%                              two fields: S.ClassificationCosts containing the cost 
%                              matrix C, and S.ClassNames containing the class names 
%                              and defining the ordering of classes used for the 
%                              rows and columns of the cost matrix. For S.ClassNames 
%                              use the data type that exists in Y. 
%                              Default: COST(I,J)=1 if I~=J, and COST(I,J)=0 if I=J. 
%                              FITCKERNEL uses the input cost matrix to adjust the 
%                              prior class probabilities. FITCKERNEL then uses the 
%                              adjusted prior probabilities and the default cost 
%                              matrix to find the decision boundary.
%       'NumExpansionDimensions' - Number of dimensions in the expanded space.
%                              Either 'auto' or a positive integer. If you pass 
%                              'auto', FITCKERNEL selects an appropriate number 
%                              using a heuristic procedure.  Default: 'auto'
%       'GradientTolerance'  - Absolute gradient tolerance. A non-negative scalar. 
%                              Default is 1e-6;
%       'HessianHistorySize' - Size of history buffer for Hessian approximation. 
%                              A positive integer. Default is 15.
%       'IterationLimit'     - Maximal number of optimization iterations. A
%                              positive integer. Default is 1000 if the transfomed
%                              data fits in memory (see BlockSize) or 100
%                              if FITCKERNEL switches to a block-wise strategy.
%       'KernelScale'        - Either string 'auto' or positive scalar specifying
%                              the value for the scale parameter. If you pass 'auto', 
%                              FITCKERNEL selects an appropriate scale using a heuristic
%                              procedure. Default is 1. 
%       'Lambda'             - Either 'auto' or a non-negative scalar values
%                              specifying the strength of the regularization term.
%                              If 'auto', the regularization parameter is set to 
%                              1/N, where N is the number of observations in X. 
%                              Default: 'auto'
%       'Learner'            - String, either 'svm' for support vector machine or
%                              'logistic' for logistic regression. Default: 'svm'
%       'Prior'              - Prior probabilities for each class. Specify as one
%                              of: 
%                               * A string:
%                                 - 'empirical' determines class probabilities
%                                   from class frequencies in Y
%                                 - 'uniform' sets all class probabilities equal
%                               * A vector (one scalar value for each class)
%                               * A structure S with two fields: S.ClassProbs
%                                 containing a vector of class probabilities, and
%                                 S.ClassNames containing the class names and
%                                 defining the ordering of classes used for the
%                                 elements of this vector.
%                              If you pass numeric values, FITCKERNEL normalizes
%                              them to add up to one. Default: 'empirical'
%       'RandomStream'       - A random number stream to control reproducibility 
%                              of the random basis functions used for
%                              transforming X to a high dimensional space.
%       'Verbose'            - Verbosity level, a non-negative integer:
%                               * 0  - FITCKERNEL does not display any
%                                      diagnostic messages. (default) 
%                               * 1  - FITCKERNEL periodically displays the
%                                      value of the objective function,
%                                      gradient magnitude, and other
%                                      diagnostic info.
%       'Weights'            - Vector of observation weights, one weight per
%                              observation. FITCKERNEL normalizes the weights to
%                              add up to the value of the prior probability in
%                              the respective class. Default is equal weights within 
%                              each class.
%                          
%   See also fitclinear.
        
%   Copyright 2017-2018 The MathWorks, Inc.

%   Undocumented warm start using ADMM:
%
%   FITCKERNEL can also refine the initial estimates of the parameters by
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
%       'WarmStartIterationLimit' - Positive integer. When FITCKERNEL switches to a 
%                           block-wise startegy (see BlockSize), FITCKERNEL first 
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

if nargin > 1
    Y = convertStringsToChars(Y);
end

if nargin > 2
    [varargin{:}] = convertStringsToChars(varargin{:});
end

[varargout{1:nargout}] = ClassificationKernel.fit(X,Y,varargin{:});

end