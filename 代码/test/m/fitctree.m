function this = fitctree(X,Y,varargin)
%FITCTREE Fit a classification decision tree.
%   TREE=FITCTREE(TBL,Y) returns a classification decision tree for data in
%   the table TBL and response Y. TBL contains the predictor variables. Y
%   can be any of the following:
%      1. An array of class labels. Y can be a categorical array, logical
%         vector, numeric vector, string array or cell array of character 
%         vectors.
%      2. The name of a variable in TBL. This variable is used as the
%         response Y, and the remaining variables in TBL are used as
%         predictors.
%      3. A formula character vector such as 'y ~ x1 + x2 + x3' specifying
%         that the variable y is to be used as the response, and the other
%         variables in the formula are predictors. Any table variables not
%         listed in the formula are not used.
%
%   TREE=FITCTREE(X,Y) is an alternative syntax that accepts X as an
%   N-by-P matrix of predictors with one row per observation and one column
%   per predictor. Y is the response and is an array of N class labels. 
%
%   TREE is a classification tree with binary splits. If you use one of the
%   following options and do not pass OptimizeHyperparameters, TREE is of
%   class ClassificationPartitionedModel: 'CrossVal', 'KFold', 'Holdout',
%   'Leaveout' or 'CVPartition'. Otherwise, TREE is of class
%   ClassificationTree.
%
%   Use of a matrix X rather than a table TBL saves both memory and
%   execution time.
%
%   TREE=FITCTREE(...,'PARAM1',val1,'PARAM2',val2,...) specifies optional
%   parameter name/value pairs:
%       'AlgorithmForCategorical' - Algorithm to find the best split on a
%                        categorical predictor in data with 3 or more
%                        classes. Set to one of: 'exact', 'pullleft', 'pca'
%                        or 'ovabyclass'. By default, FITCTREE selects the
%                        optimal subset of algorithms for each split using
%                        the known number of classes and levels of a
%                        categorical predictor. For two classes, FITCTREE
%                        always performs the exact search.
%       'CategoricalPredictors' - List of categorical predictors. Pass
%                        'CategoricalPredictors' as one of:
%                          * A numeric vector with indices between 1 and P,
%                            where P is the number of columns of X or
%                            variables in TBL.
%                          * A logical vector of length P, where a true
%                            entry means that the corresponding column of X
%                            or T is a categorical variable. 
%                          * 'all', meaning all predictors are categorical.
%                          * A string array or cell array of strings, where 
%                            each element in the array is the name of a 
%                            predictor variable. The names must match 
%                            entries in 'PredictorNames' values.
%                        Default: for a matrix input X, no categorical
%                        predictors; for a table TBL, predictors are
%                        treated as categorical if they are cell arrays of
%                        character vectors, logical, or unordered of type
%                        'categorical'.
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
%       'CrossVal'     - If 'on', grows a cross-validated tree with 10
%                        folds. You can use 'KFold', 'Holdout', 'Leaveout'
%                        and 'CVPartition' parameters to override this
%                        cross-validation setting. You can only use one of
%                        these four options ('KFold', 'Holdout', 'Leaveout'
%                        and 'CVPartition') at a time when creating a
%                        cross-validated tree. As an alternative, you can
%                        cross-validate later using CROSSVAL method for
%                        tree TREE. Default: 'off'
%       'CVPartition'  - A partition created with CVPARTITION to use in
%                        the cross-validated tree.
%       'Holdout'      - Holdout validation uses the specified fraction
%                        of the data for test, and uses the rest of the
%                        data for training. Specify a numeric scalar
%                        between 0 and 1.
%       'KFold'        - Number of folds to use in cross-validated tree,
%                        a positive integer. Default: 10
%       'Leaveout'     - Use leave-one-out cross-validation by setting to
%                        'on'. 
%       'MaxNumCategories'  - FITCTREE splits a categorical predictor
%                        using the exact search algorithm if the predictor
%                        has at most MaxNumCategories levels in the split
%                        node. Otherwise FITCTREE finds the best
%                        categorical split using one of inexact algorithms.
%                        Pass this parameter as a numeric non-negative
%                        scalar. Passing a small value can lead to loss of
%                        accuracy and passing a large value can lead to
%                        long computation time and memory overload.
%                        Default: 10
%       'MaxNumSplits' - Maximal number of decision splits (or branch
%                        nodes) per tree. Default: size(X,1)-1
%       'MergeLeaves'  - When 'on', leaves are merged if they originate
%                        from the same parent node, and the sum of their
%                        risk values is greater or equal to the risk
%                        associated with the parent node. When 'off',
%                        leaves are not merged. Default: 'on'
%       'MinLeafSize'  - Each leaf has at least 'MinLeafSize' observations
%                        per tree leaf. If you supply both 'MinParentSize'
%                        and 'MinLeafSize', both are enforced so the
%                        minimum parent size in the resulting tree is
%                        max(MinParentSize, 2*MinLeafSize). Default: 1
%       'MinParentSize' - Each splitting node in the tree has at least
%                        'MinParentSize' observations. If you supply both
%                        'MinParentSize' and 'MinLeafSize', both are
%                        enforced so the minimum parent size in the
%                        resulting tree is max(MinParentSize,
%                        2*MinLeafSize). Default: 10
%       'NumVariablesToSample' - Number of predictors to select at random
%                        for each split. Can be a positive integer or
%                        'all'; 'all' means use all available predictors.
%                        Default: 'all'
%       'OptimizeHyperparameters' 
%                      - Hyperparameters to optimize. Either 'none',
%                        'auto', 'all', a string/cell array of eligible
%                        hyperparameter names, or a vector of
%                        optimizableVariable objects, such as that returned
%                        by the 'hyperparameters' function. To control
%                        other aspects of the optimization, use the
%                        HyperparameterOptimizationOptions name-value pair.
%                        'auto' is equivalent to {'MinLeafSize'}. 'all' is
%                        equivalent to {'MaxNumSplits', 'MinLeafSize',
%                        'NumVariablesToSample', 'SplitCriterion'}. Note:
%                        NumVariablesToSample is held constant when
%                        optimizing a single tree. It is free to vary when
%                        trees are used as weak learners in ensembles. See
%                        fitcensemble and fitrensemble.
%                        Default: 'none'.
%       'PredictorNames' - A string/cell array of names for the predictor
%                        variables, in the order in which they appear in X.
%                        Default: {'x1','x2',...}. For a table TBL, these
%                        names must be a subset of the variable names in
%                        TBL, and only the selected variables are used. Not
%                        allowed when Y is a formula. Default: all
%                        variables other than Y.
%       'PredictorSelection' - Character vector specifying the algorithm
%                       for choosing the best split predictor, one of:
%                       'allsplits', 'curvature' and
%                       'interaction-curvature'. If 'allsplits', the split
%                       predictor is chosen by maximizing the gain in the
%                       split criterion over all possible splits on all
%                       predictors. If 'curvature', the split predictor is
%                       chosen by minimizing the p-value of a chi-square
%                       test of independence between each predictor and
%                       response. If 'interaction-curvature', the split
%                       predictor is chosen by minimizing the p-value of a
%                       chi-square test of independence between each
%                       predictor and response and minimizing the p-value
%                       of a chi-square test of independence between each
%                       pair of predictors and response. Default:
%                       'allsplits'
%       'Prior'    - Prior probabilities for each class. Specify as one of:
%                         * A character vector:
%                           - 'empirical' determines class probabilities
%                             from class frequencies in Y
%                           - 'uniform' sets all class probabilities equal
%                         * A vector (one scalar value for each class)
%                         * A structure S with two fields: S.ClassProbs
%                           containing a vector of class probabilities, and
%                           S.ClassNames containing the class names and
%                           defining the ordering of classes used for the
%                           elements of this vector.
%                        If you pass numeric values, FITCTREE normalizes
%                        them to add up to one. Default: 'empirical'
%       'Prune'        - When 'on', the output TREE includes the optimal
%                        sequence of pruned subtrees. When 'off', this
%                        pruning sequence is not computed. Default: 'on'
%       'PruneCriterion' - Character vector with the pruning criterion,
%                        either 'error' or 'impurity'. Default: 'error'
%       'ResponseName' - Name of the response variable Y, a character
%                        vector. Not allowed when Y is a name or formula.
%                        Default: 'Y'
%       'ScoreTransform' - Function handle for transforming scores, or
%                        character vector representing a built-in
%                        transformation function. Available functions:
%                        'symmetric', 'invlogit', 'ismax',
%                        'symmetricismax', 'none', 'logit', 'doublelogit',
%                        'symmetriclogit', and 'sign'. Default: 'none'
%       'SplitCriterion' - Criterion for choosing a split. One of 'gdi'
%                        (Gini's diversity index), 'twoing' for the twoing
%                        rule, or 'deviance' for maximum deviance reduction
%                        (also known as cross-entropy). Default: 'gdi'
%       'Surrogate'    - 'on', 'off', 'all', or a positive integer. When
%                        'on', FITCTREE finds 10 surrogate splits at each
%                        branch node. When set to an integer, FITCTREE
%                        finds at most the specified number of surrogate
%                        splits at each branch node. When 'all', FITCTREE
%                        finds all surrogate splits at each branch node.
%                        The 'all' setting can use much time and memory.
%                        Use surrogate splits to improve the tree accuracy
%                        for data with missing values or to compute
%                        measures of association between predictors.
%                        Default: 'off'
%       'Weights'      - Vector of observation weights, one weight per
%                        observation. FITCTREE normalizes the weights to
%                        add up to the value of the prior probability in
%                        the respective class. Default: ones(size(X,1),1).
%                        For an input table TBL, the 'Weights' value can be
%                        the name of a variable in TBL.
%
%   Refer to the MATLAB documentation for info on parameters for
%       <a href="matlab:helpview(fullfile(docroot,'stats','stats.map'), 'fitctreeHyperparameterOptimizationOptions')">Hyperparameter Optimization</a>
%
%   Example: Grow a classification tree for Fisher's iris data.
%       % Using matrices
%       load fisheriris
%       t = fitctree(meas,species,'PredictorNames',{'SL' 'SW' 'PL' 'PW'})
%       view(t)
%
%       % Using a table
%       tbl = readtable('fisheriris.csv','format','%f%f%f%f%C');
%       t2 = fitctree(tbl,'Species')
%       view(t2,'Mode','graph')
%
%   See also ClassificationTree,
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
    this = classreg.learning.paramoptim.fitoptimizing('fitctree',X,Y,varargin{:});
else
    temp = ClassificationTree.template(RemainingArgs{:});
    this = fit(temp,X,Y);
end
end