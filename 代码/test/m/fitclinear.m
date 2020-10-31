function [varargout] = fitclinear(X,y,varargin)
%FITCLINEAR Fit a linear classification model to high-dimensional data.
%   OBJ=FITCLINEAR(X,Y) returns a classification linear SVM model.
%
%   Pass X as an N-by-P full or sparse matrix for N observations and P
%   predictors. Pass Y as a categorical array, character array, logical
%   vector, numeric vector, string array or cell array of strings. If Y is
%   a character array, it must have one class label per row. Otherwise Y
%   must be a vector with N elements. FITCLINEAR supports binary
%   classification only.
%
%   [OBJ,FITINFO]=FITCLINEAR(X,Y) also returns a struct containing fit
%   information FITINFO for models without cross-validation. If you pass one of
%   the cross-validation options and request the FITINFO output, FITCLINEAR
%   errors.
%
%   [OBJ,FITINFO,HYPERPARAMETEROPTIMIZATIONRESULTS]=FITCLINEAR(X,Y) also
%   returns an object describing the results of hyperparameter
%   optimization, if 'OptimizeHyperparameters' was passed.
%
%   [...]=FITCLINEAR(X,Y,'PARAM1',val1,'PARAM2',val2,...) specifies optional
%   parameter name/value pairs:
%       'ObservationsIn'   - String specifying the orientation of
%                            X, either 'rows' or 'columns'. Default: 'rows'
%                          NOTE: Passing observations in columns can
%                                significantly reduce execution time.
%       'Lambda'            - Either 'auto' or vector of non-negative values
%                             specifying the strength of the regularization
%                             term. FITCLINEAR sorts this vector in ascending
%                             order and removes duplicates. If 'auto', the
%                             regularization parameter is set to 1/N, where N is
%                             the number of observations in X. Default: 'auto'
%       'Learner'           - String, either 'svm' for support vector machine or
%                             'logistic' for logistic regression. Default: 'svm'
%       'OptimizeHyperparameters' 
%                           - Hyperparameters to optimize. Either 'none',
%                             'auto', 'all', a string/cell array of eligible
%                             hyperparameter names, or a vector of
%                             optimizableVariable objects, such as that
%                             returned by the 'hyperparameters' function.
%                             To control other aspects of the optimization,
%                             use the HyperparameterOptimizationOptions
%                             name-value pair. 'auto' is equivalent to
%                             {'Lambda', 'Learner'}. 'all' is equivalent to
%                             {'Lambda', 'Learner', Regularization}.
%                             Default: 'none'.
%       'Regularization'    - String, one of: 'ridge' or 'lasso'. Lasso is
%                             equivalent to L1, and ridge is equivalent to
%                             L2. If 'ridge', FITCLINEAR composes the
%                             objective function by adding
%                             (Lambda/2)*Beta'*Beta to the average loss
%                             function. If 'lasso', FITCLINEAR composes the
%                             objective function by adding
%                             Lambda*sum(abs(Beta)) to the average loss
%                             function. The bias term is not included in
%                             the regularization penalty. Default: 'ridge'
%       'Solver'            - Either a string, string array or cell array of 
%                             strings. You can pass
%                               * 'sgd'   - Stochastic Gradient Descent.
%                               * 'asgd'  - Average Stochastic Gradient Descent
%                               * 'dual'  - Dual Stochastic Gradient Descent for
%                                           SVM with ridge penalty. If you pass
%                                           'dual' and specify lasso penalty,
%                                           FITCLINEAR errors. If you pass 'dual'
%                                           and specify MODEL other than 'svm',
%                                           FITCLINEAR errors.
%                               * 'bfgs'  - BFGS for the ridge penalty. If you
%                                           pass 'bfgs' and specify lasso
%                                           penalty, FITCLINEAR errors. BFGS is
%                                           not recommended for high-dimensional
%                                           data.
%                               * 'lbfgs' - Low-memory BFGS. If you pass 'lbfgs'
%                                           and specify lasso penalty,
%                                           FITCLINEAR errors.
%                               * 'sparsa'- Sparse Reconstruction by Separable
%                                           Approximation for the lasso penalty.
%                                           If you pass 'sparsa' and specify
%                                           ridge penalty, FITCLINEAR errors.
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
%                             * 0     - FITCLINEAR does not display any
%                                       diagnostic messages (default). 
%                             * 1     - FITCLINEAR periodically displays the
%                                       value of the objective function,
%                                       gradient magnitude, and other
%                                       diagnostic info.
%                             * >1    - FITCLINEAR displays a lot of diagnostic
%                                       info.
%
%   Refer to the MATLAB documentation for info on parameters for
%       <a href="matlab:helpview(fullfile(docroot,'stats','stats.map'), 'fitclinearLinearClassificationOptions')">linear classification</a>
%       <a href="matlab:helpview(fullfile(docroot,'stats','stats.map'), 'fitclinearSGDOptions')">SGD and ASGD solvers</a>
%       <a href="matlab:helpview(fullfile(docroot,'stats','stats.map'), 'fitclinearOtherClassOptions')">classification (such as 'Prior', 'Cost' and others)</a>
%       <a href="matlab:helpview(fullfile(docroot,'stats','stats.map'), 'fitclinearCVOptions')">cross-validation</a>
%       <a href="matlab:helpview(fullfile(docroot,'stats','stats.map'), 'fitclinearSGDOptimizationControlOptions')">controlling SGD and ASGD convergence</a>
%       <a href="matlab:helpview(fullfile(docroot,'stats','stats.map'), 'fitclinearDualOptimizationControlOptions')">controlling convergence of the Dual solver</a>
%       <a href="matlab:helpview(fullfile(docroot,'stats','stats.map'), 'fitclinearLBFGSOptimizationControlOptions')">controlling convergence of BFGS, LBFGS and SpaRSA solvers</a>
%       <a href="matlab:helpview(fullfile(docroot,'stats','stats.map'), 'fitclinearHyperparameterOptimizationOptions')">Hyperparameter Optimization</a>
%
%   Example 1: Estimate the accuracy of a linear SVM model using 5-fold
%              cross-validation.
%       load nlpdata;
%       X = X'; % transpose data if you plan to use it for other fits
%       Y = Y=='stats'; % separate the 'stats' product from all others
%       cvsvm = fitclinear(X,Y,'Kfold',5,'Prior','uniform','ObservationsIn','columns');
%       Yhat = kfoldPredict(cvsvm);
%       confusionmat(Y,Yhat)
%
%   Example 2: Plot hold-out deviance of a logistic regression model vs the
%              number of non-zero coefficients (not including the
%              intercept) for various values of the regularization parameter.
%       load nlpdata;
%       X = X'; % transpose data since it will be used more than once
%       Y = Y=='stats'; % separate the 'stats' product from all others
%       rng(1) % set RNG for reproducibility
%       cvp = cvpartition(Y,'Holdout',0.2);
%       glm = fitclinear(X(:,training(cvp)),Y(training(cvp)),'Learner','logistic',...
%                        'Prior','uniform','ObservationsIn','columns',...
%                        'Solver','sparsa','Regularization','lasso',...
%                        'Lambda',logspace(-6,1,20));
%       glm.ScoreTransform = 'none'; % use raw predictions instead of probabilities
%       deviance = 2*sum(test(cvp))*loss(glm,X(:,test(cvp)),Y(test(cvp)),...
%                  'ObservationsIn','columns','LossFun','logit');
%       figure
%       semilogy(sum(glm.Beta~=0),deviance)
%       xlabel('Number of coefficients')
%       ylabel('Hold-out deviance')
%       grid on
%
%   See also fitrlinear.

%   Copyright 2015-2016 The MathWorks, Inc.

if nargin > 1
    y = convertStringsToChars(y);
end

if nargin > 2
    [varargin{:}] = convertStringsToChars(varargin{:});
end

[IsOptimizing, RemainingArgs] = classreg.learning.paramoptim.parseOptimizationArgs(varargin);
if IsOptimizing
    [varargout{1:nargout}] = classreg.learning.paramoptim.fitoptimizing('fitclinear',X,y,varargin{:});
else
    [varargout{1:nargout}] = ClassificationLinear.fit(X,y,RemainingArgs{:});
end
end