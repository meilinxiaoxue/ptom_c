function this = fitcdiscr(X,Y,varargin)
%FITCDISCR Fit discriminant analysis.
%   TREE=FITCDISCR(TBL,Y) returns a classification decision tree for data
%   in the table TBL and response Y. TBL contains the predictor variables.
%   Y can be any of the following:
%      1. An array of class labels. Y can be a categorical array, logical
%         vector, numeric vector, string array or cell array of strings.
%      2. The name of a variable in TBL. This variable is used as the
%         response Y, and the remaining variables in TBL are used as
%         predictors.
%      3. A formula string such as 'y ~ x1 + x2 + x3' specifying that the
%         variable y is to be used as the response, and the other variables
%         in the formula are predictors. Any table variables not listed in
%         the formula are not used.
%
%   DISCR=FITCDISCR(X,Y) is an alternative syntax that accepts X as an
%   N-by-P matrix of predictors with one row per observation and one column
%   per predictor. Y is the response and is an array of N class labels.
%
%   DISCR is a discriminant analysis model. If you use one of the following
%   five options and do not pass OptimizeHyperparameters, DISCR is of class
%   ClassificationPartitionedModel: 'CrossVal', 'KFold', 'Holdout',
%   'Leaveout' or 'CVPartition'. Otherwise, DISCR is of class
%   ClassificationDiscriminant.
%
%   DISCR=FITCDISCR(X,Y,'PARAM1',val1,'PARAM2',val2,...) specifies optional
%   parameter name/value pairs:
%       'ClassNames'   - Array of class names. Use the data type that
%                        exists in Y. You can use this argument to order
%                        the classes or select a subset of classes for
%                        training. Default: All class names in Y.
%       'Cost'         - Square matrix, where COST(I,J) is the
%                        cost of classifying a point into class J if its
%                        true class is I. Alternatively, COST can be a
%                        structure S with two fields: S.ClassificationCosts
%                        containing the cost matrix C, and S.ClassNames
%                        containing the class names and defining the
%                        ordering of classes used for the rows and columns
%                        of the cost matrix. For S.ClassNames use the data
%                        type that exists in Y. As an alternative, you can
%                        assign to the Cost property of DISCR. Default:
%                        COST(I,J)=1 if I~=J, and COST(I,J)=0 if I=J.
%       'CrossVal'     - If 'on', performs 10-fold cross-validation.
%                        You can use 'KFold', 'Holdout', 'Leaveout' and
%                        'CVPartition' parameters to override this cross-
%                        validation setting. You can only use one of these
%                        four options ('KFold', 'Holdout', 'Leaveout' and
%                        'CVPartition') at a time. As an alternative, you
%                        can cross-validate later using the CROSSVAL
%                        method. Default: 'off'
%       'CVPartition'  - A partition created with CVPARTITION to use for
%                        cross-validation.
%       'Holdout'      - Holdout validation uses the specified fraction
%                        of the data for test, and uses the rest of the
%                        data for training. Specify a numeric scalar
%                        between 0 and 1.
%       'KFold'        - Number of folds K to use in K-fold cross-
%                        validation. K is a positive integer. Default: 10
%       'Leaveout'     - Use leave-one-out cross-validation by setting to
%                        'on'. 
%       'DiscrimType'  - A string with the type of the discriminant
%                        analysis. Specify as one of 'linear',
%                        'pseudolinear', 'diaglinear', 'quadratic',
%                        'pseudoquadratic' or 'diagquadratic'.
%                        Default: 'linear'
%       'Gamma'        - Parameter for regularizing the correlation matrix
%                        of predictors. 
%                          * For linear discriminants you can pass a scalar
%                            G, 0<=G<=1. If G=0 and DiscrimType is
%                            'linear', and if the correlation matrix is
%                            singular, FITCDISCR sets 'Gamma' to the
%                            minimal value required for inverting the
%                            covariance matrix. If G=1, FITCDISCR sets the
%                            discriminant type to 'diaglinear'. For
%                            0<G<1,FITCDISCR sets the discriminant type to
%                            'linear'.
%
%                          * For quadratic discriminants you can pass
%                            either 0 or 1. If G=0 and DiscrimType is
%                            'quadratic', and if one of the classes has a
%                            singular covariance matrix, FITCDISCR errors.
%                            If G=1, FITCDISCR sets the discriminant type
%                            to 'diagquadratic'.
%                        Default: 0
%       'Delta'        - Threshold on linear coefficients, a non-negative
%                        scalar. For quadratic discriminant, this parameter
%                        must be set to 0. Default: 0
%       'FillCoeffs'   - If 'on', fills the struct holding discriminant
%                        coefficients. If 'off', the Coeffs property of
%                        discriminant DISCR will be empty. Default: 'on'
%       'OptimizeHyperparameters' 
%                      - Hyperparameters to optimize. Either 'none',
%                        'auto', 'all', a string/cell array of eligible
%                        hyperparameter names, or a vector of
%                        optimizableVariable objects, such as that returned
%                        by the 'hyperparameters' function. To control
%                        other aspects of the optimization, use the
%                        HyperparameterOptimizationOptions name-value pair.
%                        'auto' is equivalent to {'Delta', 'Gamma'}. 'all'
%                        is equivalent to {'Delta', 'DiscrimType',
%                        'Gamma'}.  Default: 'none'.
%       'PredictorNames' - A string/cell array of names for the predictor
%                        variables, in the order in which they appear in X.
%                        Default: {'x1','x2',...}. For a table TBL, these
%                        names must be a subset of the variable names in
%                        TBL, and only the selected variables are used. Not
%                        allowed when Y is a formula. Default: all
%                        variables other than Y.
%       'Prior'        - Prior probabilities for each class. Specify as one
%                        of: 
%                         * A string:
%                           - 'empirical' determines class probabilities
%                             from class frequencies in Y
%                           - 'uniform' sets all class probabilities equal
%                         * A vector (one scalar value for each class)
%                         * A structure S with two fields: S.ClassProbs
%                           containing a vector of class probabilities, and
%                           S.ClassNames containing the class names and
%                           defining the ordering of classes used for the
%                           elements of this vector.
%                        If you pass numeric values, FITCDISCR normalizes
%                        them to add up to one. As an alternative, you can
%                        assign to the Prior property of DISCR.
%                        Default: 'empirical'
%       'ResponseName' - Name of the response variable Y, a string. Not
%                        allowed when Y is a name or formula. Default: 'Y' 
%       'SaveMemory'   - If 'on', defers computing the full covariance
%                        matrix until it is needed for prediction. If
%                        'off', computes and stores the full covariance
%                        matrix in the returned object. Set this parameter
%                        to 'on' if X has thousands of predictors.
%                        Default: 'off'
%       'ScoreTransform' - Function handle for transforming scores, or
%                        string representing a built-in transformation
%                        function. Available functions: 'symmetric',
%                        'invlogit', 'ismax', 'symmetricismax', 'none',
%                        'logit', 'doublelogit', 'symmetriclogit', 'sign'.
%                        Default: 'none'
%       'Weights'      - Vector of observation weights, one weight per
%                        observation. Default: ones(size(X,1),1)
%
%   Refer to the MATLAB documentation for info on parameters for
%       <a href="matlab:helpview(fullfile(docroot,'stats','stats.map'), 'fitcdiscrHyperparameterOptimizationOptions')">Hyperparameter Optimization</a>
%
%   Example: Fit a linear discriminant to the Fisher iris data, and look at
%   a confusion matrix comparing the true and predicted Species values:
%       t = readtable('fisheriris.csv','format','%f%f%f%f%C');
%       d = fitcdiscr(t,'Species')
%       confusionmat(t.Species,predict(d,t))
%
%   See also ClassificationDiscriminant,
%   classreg.learning.partition.ClassificationPartitionedModel.

%   Copyright 2013-2016 The MathWorks, Inc.

if nargin > 1
    Y = convertStringsToChars(Y);
end

if nargin > 2
    [varargin{:}] = convertStringsToChars(varargin{:});
end

[IsOptimizing, RemainingArgs] = classreg.learning.paramoptim.parseOptimizationArgs(varargin);
if IsOptimizing
    this = classreg.learning.paramoptim.fitoptimizing('fitcdiscr',X,Y,varargin{:});
else
    this = ClassificationDiscriminant.fit(X,Y,RemainingArgs{:});
end
end
