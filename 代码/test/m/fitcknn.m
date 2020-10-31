function this = fitcknn(X,Y,varargin)
% FITCKNN fit KNN classification model
%   KNN=FITCKNN(TBL,Y) returns a KNN classification model for predictors X
%   and response Y. TBL contains the predictor variables. Y can be any of
%   the following: 
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
%   KNN=FITCKNN(X,Y) is an alternative syntax that accepts X as an
%   N-by-P matrix of predictors with one row per observation and one column
%   per predictor. Y is the response and is an array of N class labels. 
%
%   KNN is a KNN classification model. If you use one of the following five
%   options and do not pass OptimizeHyperparameters, KNN is of class
%   ClassificationPartitionedModel: 'CrossVal', 'KFold', 'Holdout',
%   'Leaveout' or 'CVPartition'. Otherwise, KNN is of class
%   ClassificationKNN.
%
%   Use of a matrix X rather than a table TBL saves both memory and
%   execution time.
%
%   KNN=FITCKNN(X,Y,'PARAM1',val1,'PARAM2',val2,...) specifies optional
%   parameter name/value pairs:
%       'CategoricalPredictors' - List of categorical predictors. Pass
%                        'CategoricalPredictors' as [] or 'all'. Use [] to
%                        indicate no predictors are categorical. Use 'all'
%                        to indicate all predictors are categorical.
%                        Default: []
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
%                        type that exists in Y. Default: COST(I,J)=1 if
%                        I~=J, and COST(I,J)=0 if I=J.
%       'CrossVal'     - If 'on', performs 10-fold cross-validation. You
%                        use 'KFold', 'Holdout', 'Leaveout' and
%                        'CVPartition' parameters to override this
%                        cross-validation setting. You can only use one of
%                        these four options ('KFold', 'Holdout', 'Leaveout'
%                        and 'CVPartition') at a time. As an alternative,
%                        you can cross-validate later using the CROSSVAL
%                        method. Default: 'off'
%       'CVPartition'  - A partition created with CVPARTITION to use in
%                        the cross-validation.
%       'Holdout'      - Holdout validation uses the specified fraction
%                        of the data for test, and uses the rest of the
%                        data for training. Specify a numeric scalar
%                        between 0 and 1.
%       'KFold'        - Number of folds to use in cross-validation, a
%                        positive integer. Default: 10
%       'Leaveout'     - Use leave-one-out cross-validation by setting to
%                        'on'. 
%       'OptimizeHyperparameters' 
%                      - Hyperparameters to optimize. Either 'none',
%                        'auto', 'all', a string/cell array of eligible
%                        hyperparameter names, or a vector of
%                        optimizableVariable objects, such as that returned
%                        by the 'hyperparameters' function. To control
%                        other aspects of the optimization, use the
%                        HyperparameterOptimizationOptions name-value pair.
%                        'auto' is equivalent to {'Distance',
%                        'NumNeighbors'}. 'all' is equivalent to
%                        {'Distance', 'DistanceWeight', 'Exponent',
%                        'NumNeighbors', 'Standardize'}. 
%                        Default: 'none'.
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
%                        If you pass numeric values, they are normalized
%                        to add up to one. Default: 'empirical'
%       'ResponseName' - Name of the response variable Y, a string. Not
%                        allowed when Y is a name or formula. Default: 'Y' 
%       'ScoreTransform' - Function handle for transforming scores, or
%                        string representing a built-in transformation
%                        function. Available functions: 'symmetric',
%                        'invlogit', 'ismax', 'symmetricismax', 'none',
%                        'logit', 'doublelogit', 'symmetriclogit',
%                         and 'sign'. Default: 'none'
%       'Weights'      - Vector of observation weights, one weight per
%                        observation. FITCKNN normalizes the weights to
%                        add up to the value of the prior probability in
%                        the respective class. Default: ones(size(X,1),1).
%                        For an input table TBL, the 'Weights' value can be
%                        the name of a variable in TBL.
%       'NumNeighbors' - A positive integer specifying the number of
%                        nearest neighbors in X for classifying each point
%                        when predicting. Default: 1.
%       'NSMethod'     - Nearest neighbors search method. Value is either:
%                          'kdtree' uses a kd-tree to find nearest
%                               neighbors. 'kdtree' is only valid when the
%                               distance metric is one of the following:
%                                       - 'euclidean'
%                                       - 'cityblock'
%                                       - 'minkowski'
%                                       - 'chebychev'
%                          'exhaustive' uses the exhaustive search
%                               algorithm. The distance values from all the
%                               points in X to each point in Y are computed
%                               to find nearest neighbors.
%                        Default is 'kdtree' when the number of columns of
%                        X is not greater than 10, X is not sparse, and the
%                        distance metric is one of the above 4 metrics;
%                        otherwise, default is 'exhaustive'.
%       'IncludeTies'  - A logical value. Use true to include all neighbors
%                        whose distance equal the Kth smallest distance.
%                        Use false to include exactly K nearest neighbors. 
%       'DistanceWeight' - A string or a function handle specifying the
%                        distance weighting function. The choices for a
%                        string are:
%                          'equal': Each neighbor gets equal weight
%                               (default). 
%                          'inverse': Each neighbor gets weight 1/d, where
%                               d is the distance between this neighbor and
%                               the point being classified.
%                          'squaredinverse': Each neighbor gets weight
%                               1/d^2, where d is the distance between this
%                               neighbor and the point being classified.
%                         A function is specified using @. A distance
%                         weighting function must be of the form:
%
%                             function DW = DISTWGT(D)
%
%                         taking as argument a matrix D and returning a
%                         matrix of distance weight DW. D and DW can only
%                         contains non-negative numerical values. DW must
%                         have the same size as D. DW(I,J) is the weight
%                         computed based on D(I,J).
%        'BreakTies'    - Method of breaking ties if more than one class
%                         has the same smallest cost. Choices are:
%                           'smallest': Assign the point to the class with
%                                the smallest index. This is the default.
%                           'nearest': Assign the point to the class of its
%                                class of its nearest neighbor.
%                           'random': Randomly pick a class from the
%                                classes with the smallest cost.
%        'Distance'     - A string or a function handle specifying the
%                         distance metric. The choices for a string are:
%                           'euclidean': Euclidean distance. This is the
%                                default if there are no categorical
%                                predictors. 
%                           'seuclidean': Standardized Euclidean distance.
%                                Each coordinate difference between X and a
%                                query point is divided by an element of
%                                vector S. The default value is the
%                                standard deviation computed from X. To
%                                specify another value for S, use the
%                                'Scale' argument.
%                           'cityblock': City Block distance.
%                           'chebychev': Chebychev distance (maximum
%                                coordinate  difference).
%                           'minkowski': Minkowski distance. The default
%                                exponent is 2. To specify a different
%                                exponent, use the 'P' argument.
%                           'mahalanobis': Mahalanobis distance, computed
%                                using a positive definite covariance
%                                matrix C. The default value of C is the
%                                covariance matrix computed from X. To
%                                specify another value for C, use the 'Cov'
%                                argument.
%                           'cosine': One minus the cosine of the included
%                                angle between observations (treated as
%                                vectors).
%                           'correlation' : One minus the sample linear
%                                correlation between observations (treated
%                                as sequences of values). 
%                           'spearman': One minus the sample Spearman's
%                                rank correlation between observations
%                                (treated as sequences of values).
%                           'hamming': Hamming distance, percentage of
%                                coordinates that differ. This is the
%                                default if all predictors are categorical.
%                           'jaccard': One minus the Jaccard coefficient,
%                                the percentage of nonzero coordinates that
%                                differ.
%                         A function is specified using @ (for example
%                         @DISTFUN). A distance function has the form:
%
%                             function D2 = DISTFUN(ZI, ZJ),
%
%                         taking as arguments a 1-by-N vector ZI containing
%                         a single row of X or Y, an M2-by-N matrix ZJ
%                         containing multiple rows of X or Y, and returning
%                         an M2-by-1 vector of distances D2, whose Jth
%                         element is the distance between the observations
%                         ZI and ZJ(J,:).
%       'Exponent'      - A positive scalar indicating the exponent of
%                         Minkowski distance. This argument is only valid
%                         when 'Distance' is 'minkowski'. Default: 2.
%       'Cov'           - A positive definite matrix indicating the
%                         covariance matrix when computing the Mahalanobis
%                         distance. This argument is only valid when
%                         'Distance' is 'mahalanobis'. Default: The
%                         covariance matrix computed from X, after
%                         excluding rows that contain any NaNs.
%       'Scale'         - A vector S containing non-negative values,
%                         with length equal to the number of columns in X.
%                         Each coordinate difference between X and a query
%                         point is divided by the corresponding element of
%                         S. This argument is only valid when 'Distance' is
%                         'seuclidean'. Default is the standard deviation
%                         of X.
%       'BucketSize'    - The maximum number of data points in the leaf
%                         node of the kd-tree (default is 50). This
%                         argument is only meaningful when 'NSMethod' is
%                         'kdtree'.
%       'Standardize'   - Logical scalar. If true, standardize X by
%                         centering and dividing columns by their standard
%                         deviations. Default: false
%
%   Refer to the MATLAB documentation for info on parameters for
%       <a href="matlab:helpview(fullfile(docroot,'stats','stats.map'), 'fitcknnHyperparameterOptimizationOptions')">Hyperparameter Optimization</a>
%
%   Example: Create a KNN classifier for the Fisher iris data, and compare
%            the actual and predicted species in a confusion matrix.
%      t = readtable('fisheriris.csv','format','%f%f%f%f%C');
%      knn = fitcknn(t,'Species','NumNeighbors',5);
%      confusionmat(t.Species,predict(knn,t))
%
%    See also ClassificationKNN.

%   Copyright 2013-2017 The MathWorks, Inc.

internal.stats.checkNotTall(upper(mfilename),0,X,Y,varargin{:});

if nargin > 1
    Y = convertStringsToChars(Y);
end

if nargin > 2
    [varargin{:}] = convertStringsToChars(varargin{:});
end

[IsOptimizing, RemainingArgs] = classreg.learning.paramoptim.parseOptimizationArgs(varargin);
if IsOptimizing
    this = classreg.learning.paramoptim.fitoptimizing('fitcknn',X,Y,varargin{:});
else
    this = ClassificationKNN.fit(X,Y,RemainingArgs{:});
end
end
