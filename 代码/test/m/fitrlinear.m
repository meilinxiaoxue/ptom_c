function [varargout] = fitrlinear(X,y,varargin)
%FITRLINEAR Fit a linear regression model to high-dimensional data.
%   OBJ=FITRLINEAR(X,Y) returns a linear regression SVM model.
%
%   Pass X as an N-by-P full or sparse matrix for N observations and P
%   predictors. Pass Y as a floating-point vector with N elements.
%
%   [OBJ,FITINFO]=FITRLINEAR(X,Y) also returns a struct containing fit
%   information FITINFO for models without cross-validation. If you pass one of
%   the cross-validation options and request the FITINFO output, FITRLINEAR
%   errors.
%
%   [OBJ,FITINFO,HYPERPARAMETEROPTIMIZATIONRESULTS]=FITRLINEAR(X,Y) also
%   returns an object describing the results of hyperparameter
%   optimization, if 'OptimizeHyperparameters' was passed.
%
%   [...]=FITRLINEAR(X,Y,'PARAM1',val1,'PARAM2',val2,...) specifies optional
%   parameter name/value pairs:
%       'ObservationsIn'   - String specifying the orientation of
%                            X, either 'rows' or 'columns'. Default: 'rows'
%                          NOTE: Passing observations in columns can
%                                significantly reduce execution time.
%       'Epsilon'           - Non-negative scalar specifying half the width of
%                             the epsilon-insensitive band. Default:
%                             iqr(Y)/13.49 and 0.1 if iqr(Y) equals 0
%       'Lambda'            - Either 'auto' or vector of non-negative values
%                             specifying the strength of the regularization
%                             term. FITRLINEAR sorts this vector in ascending
%                             order and removes duplicates. If 'auto', the
%                             regularization parameter is set to 1/N, where N is
%                             the number of observations in X. Default: 'auto'
%       'Learner'           - String, either 'svm' for support vector machine or
%                             'leastsquares' for least-squares regression.
%                             Default: 'svm'
%       'OptimizeHyperparameters' 
%                      - Hyperparameters to optimize. Either 'none',
%                        'auto', 'all', a string/cell array of eligible
%                        hyperparameter names, or a vector of
%                        optimizableVariable objects, such as that returned
%                        by the 'hyperparameters' function. To control
%                        other aspects of the optimization, use the
%                        HyperparameterOptimizationOptions name-value pair.
%                        'auto' is equivalent to {'Lambda', 'Learner'}.
%                        'all' is equivalent to {'Lambda', 'Learner',
%                        Regularization}. Default: 'none'.
%       'Regularization'    - String, one of: 'ridge' or 'lasso'. Lasso is
%                             equivalent to L1, and ridge is equivalent to
%                             L2. If 'ridge', FITRLINEAR composes the
%                             objective function by adding
%                             (Lambda/2)*Beta'*Beta to the average loss
%                             function. If 'lasso', FITRLINEAR composes the
%                             objective function by adding
%                             Lambda*sum(abs(Beta)) to the average loss
%                             function. The bias term is not included in
%                             the regularization penalty. Default: 'ridge'
%       'Solver'            - Either a string, a string array, or a cell array 
%                             of strings. You can pass
%                               * 'sgd'   - Stochastic Gradient Descent.
%                               * 'asgd'  - Average Stochastic Gradient Descent
%                               * 'dual'  - Dual Stochastic Gradient Descent for
%                                           SVM with ridge penalty. If you pass
%                                           'dual' and specify lasso penalty,
%                                           FITRLINEAR errors. If you pass 'dual'
%                                           and specify MODEL other than 'svm',
%                                           FITRLINEAR errors.
%                               * 'bfgs'  - BFGS for the ridge penalty. If you
%                                           pass 'bfgs' and specify lasso
%                                           penalty, FITRLINEAR errors. BFGS is
%                                           not recommended for high-dimensional
%                                           data.
%                               * 'lbfgs' - Low-memory BFGS. If you pass 'lbfgs'
%                                           and specify lasso penalty,
%                                           FITRLINEAR errors.
%                               * 'sparsa'- Sparse Reconstruction by Separable
%                                           Approximation for the lasso penalty.
%                                           If you pass 'sparsa' and specify
%                                           ridge penalty, FITRLINEAR errors.
%                           TIPS: 
%                            - For high-dimensional data with ridge penalty,
%                              pass 'sgd', 'asgd', 'dual', 'lbfgs',
%                              {'sgd','lbfgs'}, {'asgd','lbfgs'}, or
%                              {'dual','lbfgs'}. Although you can pass other
%                              combinations, they often lead to solutions with
%                              poor accuracy.
%                            - For low-dimensional data with ridge penalty, try
%                              'bfgs'.
%                            - For lasso penalty, pass 'sgd', 'asgd', 'sparsa',
%                              {'sgd','sparsa'}, or {'asgd','sparsa'}.
%                           Defaults: 
%                                * 'bfgs' for ridge penalty and 100 or fewer
%                                   predictors
%                                * 'dual' for SVM with ridge penalty and more
%                                   than 100 predictors
%                                * 'sparsa' for lasso penalty and 100 or fewer
%                                   predictors
%                                * 'sgd' otherwise
%     'Verbose'           - Verbosity flag, a non-negative integer:
%                             * 0     - FITRLINEAR does not display any
%                                       diagnostic messages (default). 
%                             * 1     - FITRLINEAR periodically displays the
%                                       value of the objective function,
%                                       gradient magnitude, and other
%                                       diagnostic info.
%                             * >1    - FITRLINEAR displays a lot of diagnostic
%                                       info.
%
%   Refer to the MATLAB documentation for info on parameters for
%       <a href="matlab:helpview(fullfile(docroot,'stats','stats.map'), 'fitrlinearLinearRegressionOptions')">linear regression</a>
%       <a href="matlab:helpview(fullfile(docroot,'stats','stats.map'), 'fitrlinearSGDOptions')">SGD and ASGD solvers</a>
%       <a href="matlab:helpview(fullfile(docroot,'stats','stats.map'), 'fitrlinearOtherRegressionOption')">regression (such as 'Weights')</a>
%       <a href="matlab:helpview(fullfile(docroot,'stats','stats.map'), 'fitrlinearCVOptions')">cross-validation</a>
%       <a href="matlab:helpview(fullfile(docroot,'stats','stats.map'), 'fitrlinearSGDOptimizationControlOptions')">controlling SGD and ASGD convergence</a>
%       <a href="matlab:helpview(fullfile(docroot,'stats','stats.map'), 'fitrlinearDualOptimizationControlOptions')">controlling convergence of the Dual solver</a>
%       <a href="matlab:helpview(fullfile(docroot,'stats','stats.map'), 'fitrlinearLBFGSOptimizationControlOptions')">controlling convergence of BFGS, LBFGS and SpaRSA solvers</a>
%       <a href="matlab:helpview(fullfile(docroot,'stats','stats.map'), 'fitrlinearHyperparameterOptimizationOptions')">Hyperparameter Optimization</a>
%   See also fitclinear.

%   Copyright 2015-2016 The MathWorks, Inc.    

if nargin > 2
    [varargin{:}] = convertStringsToChars(varargin{:});
end

[IsOptimizing, RemainingArgs] = classreg.learning.paramoptim.parseOptimizationArgs(varargin);
if IsOptimizing
    [varargout{1:nargout}] = classreg.learning.paramoptim.fitoptimizing('fitrlinear',X,y,varargin{:});
else
    [varargout{1:nargout}] = RegressionLinear.fit(X,y,RemainingArgs{:});
end
end
