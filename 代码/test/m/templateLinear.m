function temp = templateLinear(varargin)
%TEMPLATELINEAR Create a linear model template for high-dimensional data.
%   T=templateLinear() returns a linear model template suitable for use in the
%   FITCECOC function.
%
%   T=templateLinear('PARAM1',val1,'PARAM2',val2,...) specifies optional
%   parameter name/value pairs:
%       'Lambda'            - Either 'auto' or vector of non-negative values
%                             specifying the strength of the regularization
%                             term. FITCLINEAR sorts this vector in ascending
%                             order and removes duplicates. If 'auto', the
%                             regularization parameter is set to 1/N, where N is
%                             the number of observations in X. Default: 'auto'
%       'Learner'           - String, either 'svm' for support vector machine or
%                             'logistic' for logistic regression. Default: 'svm'
%       'Regularization'    - String, one of: 'ridge' or 'lasso'. Lasso is
%                             equivalent to L1, and ridge is equivalent to
%                             L2. If 'ridge', the objective function is
%                             composed by adding (Lambda/2)*Beta'*Beta to
%                             the average loss function. If 'lasso', the
%                             objective function is composed by adding
%                             Lambda*sum(abs(Beta)) to the average loss
%                             function. The bias term is not included in
%                             the regularization penalty. Default: 'ridge'
%       'Solver'            - Either a string, a string array or a cell
%                             array of strings. You can pass
%                               * 'sgd'   - Stochastic Gradient Descent.
%                               * 'asgd'  - Average Stochastic Gradient Descent
%                               * 'dual'  - Dual Stochastic Gradient Descent for
%                                           SVM with ridge penalty. If you
%                                           pass 'dual' and specify lasso
%                                           penalty, optimization errors.
%                                           If you pass 'dual' and specify
%                                           MODEL other than 'svm',
%                                           optimization errors.
%                               * 'bfgs'  - BFGS for the ridge penalty. If you
%                                           pass 'bfgs' and specify lasso
%                                           penalty, optimization errors.
%                                           BFGS is not recommended for
%                                           high-dimensional data.
%                               * 'lbfgs' - Low-memory BFGS. If you pass 'lbfgs'
%                                           and specify lasso penalty,
%                                           optimization errors.
%                               * 'sparsa'- Sparse Reconstruction by Separable
%                                           Approximation for the lasso penalty.
%                                           If you pass 'sparsa' and specify
%                                           ridge penalty, optimization errors.
%                           TIPS: 
%                            - For high-dimensional data with ridge penalty,
%                              pass 'sgd', 'asgd', 'dual', 'lbfgs',
%                              {'sgd','lbfgs'}, {'asgd','lbfgs'}, or
%                              {'dual','lbfgs'}. Although you can pass other
%                              combinations, they often lead to solutions with
%                              poor accuracy.
%                            - For low-dimensional data with ridge penalty, try
%                              'bfgs'.
%                            - For lasso penalty, try 'asgd', 'sparsa' or
%                              {'asgd','sparsa'}.
%                           Defaults: 
%                                * 'bfgs' for ridge penalty and 100 or fewer
%                                   predictors
%                                * 'dual' for SVM with ridge penalty and more
%                                   than 100 predictors
%                                * 'sparsa' for lasso penalty and 100 or fewer
%                                   predictors
%                                * 'sgd' otherwise
%
%   Refer to the MATLAB documentation for info on parameters for
%       <a href="matlab:helpview(fullfile(docroot,'stats','stats.map'), 'templateLinearClassificationOptions')">linear classification</a>
%       <a href="matlab:helpview(fullfile(docroot,'stats','stats.map'), 'templateLinearSGDOptions')">SGD and ASGD solvers</a>
%       <a href="matlab:helpview(fullfile(docroot,'stats','stats.map'), 'templateLinearSGDOptimizationControlOptions')">controlling SGD and ASGD convergence</a>
%       <a href="matlab:helpview(fullfile(docroot,'stats','stats.map'), 'templateLinearDualOptimizationControlOptions')">controlling convergence of the Dual solver</a>
%       <a href="matlab:helpview(fullfile(docroot,'stats','stats.map'), 'templateLinearLBFGSOptimizationControlOptions')">controlling convergence of BFGS, LBFGS and SpaRSA solvers</a>
%
%   See also fitcecoc, fitclinear, ClassificationECOC,
%   ClassificationLinear.

%   Copyright 2015 The MathWorks, Inc.

if nargin > 0
    [varargin{:}] = convertStringsToChars(varargin{:});
end

[type,learner,~,extra] = internal.stats.parseArgs({'type' 'learner'},{'' ''},varargin{:});

doclass = [];

if ~isempty(type)
    type = validatestring(type,{'classification' 'regression'},...
        'templateLinear','Type');
    doclass = strcmp(type,'classification');
end

if ~isempty(learner)
    learner = validatestring(learner,{'leastsquares' 'logistic' 'svm'},...
        'templateLinear','Learner');
else
    if isempty(type)    
        learner = 'svm';
        doclass = true;
    end
end

if     strncmpi(learner,'leastsquares',length(learner))
    if ~isempty(doclass) && doclass
        error(message('stats:templateLinear:BadClassificationLearner'));
    end
    temp = RegressionLinear.template('Learner','leastsquares',extra{:});
elseif strncmpi(learner,'logistic',length(learner))
    if ~isempty(doclass) && ~doclass
        error(message('stats:templateLinear:BadRegressionLearner'));
    end
    temp = ClassificationLinear.template('Learner','logistic',extra{:});
elseif strncmpi(learner,'svm',length(learner))
    if isempty(doclass) || doclass
        temp = ClassificationLinear.template('Learner','svm',extra{:});
    else
        temp = RegressionLinear.template('Learner','svm',extra{:});
    end
else
    error(message('stats:templateLinear:BadLearner'));
end

end
