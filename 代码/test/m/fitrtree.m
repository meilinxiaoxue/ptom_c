function this = fitrtree(X,Y,varargin)
%FITRTREE Fit a regression decision tree.
%   TREE=FITRTREE(TBL,Y) returns a regression decision tree for data in
%   the table TBL and response Y. TBL contains the predictor variables. Y
%   can be any of the following:
%      1. A column vector of floating-point numbers.
%      2. The name of a variable in TBL. This variable is used as the
%         response Y, and the remaining variables in TBL are used as
%         predictors.
%      3. A formula character vector such as 'y ~ x1 + x2 + x3' specifying
%         that the variable y is to be used as the response, and the other
%         variables in the formula are predictors. Any table variables not
%         listed in the formula are not used.
%
%   TREE=FITRTREE(X,Y) is an alternative syntax that accepts X as an
%   N-by-P matrix of predictors with one row per observation and one column
%   per predictor. Y is the N-by-1 response vector. 
%   FITRTREE grows the tree using MSE (mean squared error) as the splitting
%   criterion.
%
%   TREE is a regression tree with binary splits. If you use one of the
%   following five options and do not pass OptimizeHyperparameters, TREE is
%   of class RegressionPartitionedModel:
%   'CrossVal', 'KFold', 'Holdout', 'Leaveout' or 'CVPartition'. Otherwise,
%   TREE is of class RegressionTree.
%
%   Use of a matrix X rather than a table TBL saves both memory and
%   execution time.
%
%   TREE=FITRTREE(X,Y,'PARAM1',val1,'PARAM2',val2,...) specifies optional
%   parameter name/value pairs:
%       'CategoricalPredictors' - List of categorical predictors. Pass
%                        'CategoricalPredictors' as one of:
%                          * A numeric vector with indices between 1 and P,
%                            where P is the number of columns of X or
%                            variables in TBL.
%                          * A logical vector of length P, where a true
%                            entry means that the corresponding column of X
%                            or T is a categorical variable. 
%                          * 'all', meaning all predictors are categorical.
%                          * A string array or cell array of character vectors,
%                            where each element in the array is the name of a
%                            predictor variable. The names must match
%                            entries in 'PredictorNames' values.
%                        Default: for a matrix input X, no categorical
%                        predictors; for a table TBL, predictors are
%                        treated as categorical if they are cell arrays of
%                        character vectors, logical, or unordered of type
%                        'categorical'.
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
%                        'NumVariablesToSample'}. Note:
%                        NumVariablesToSample is held constant when
%                        optimizing a single tree. It is free to vary when
%                        trees are used as weak learners in ensembles. See
%                        fitcensemble and fitrensemble. Default: 'none'.
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
%       'Prune'        - When 'on', the output TREE includes the optimal
%                        sequence of pruned subtrees. When 'off', this
%                        pruning sequence is not computed. Default: 'on'
%       'QuadraticErrorTolerance' - Defines tolerance on quadratic error
%                        per node for regression trees. Splitting nodes
%                        stops when quadratic error per node drops below
%                        TOLER*QED, where QED is the quadratic error for
%                        the entire data computed before the decision tree
%                        is grown: QED = NORM(Y-YBAR) with YBAR estimated
%                        as the average of the input array Y. Default =
%                        1e-6.
%       'ResponseName' - Name of the response variable Y, a character
%                        vector. Not allowed when Y is a name or formula.
%                        Default: 'Y'
%       'Surrogate'    - 'on', 'off', 'all', or a positive integer. When
%                        'on', FITRTREE finds 10 surrogate splits at each
%                        branch node. When set to an integer, FITRTREE
%                        finds at most the specified number of surrogate
%                        splits at each branch node. When 'all', FITRTREE
%                        finds all surrogate splits at each branch node.
%                        The 'all' setting can use much time and memory.
%                        Use surrogate splits to improve the tree accuracy
%                        for data with missing values or to compute
%                        measures of association between predictors.
%                        Default: 'off'
%       'Weights'      - Vector of observation weights, one weight per
%                        observation. FITRTREE normalizes the weights to
%                        add up to one. Default: ones(size(X,1),1). For an
%                        input table TBL, the 'Weights' value can be the
%                        name of a variable in TBL.
%
%   Refer to the MATLAB documentation for info on parameters for
%       <a href="matlab:helpview(fullfile(docroot,'stats','stats.map'), 'fitrtreeHyperparameterOptimizationOptions')">Hyperparameter Optimization</a>
%
%   Example: Grow a regression tree for car data.
%       % Using matrices
%       load carsmall
%       t = fitrtree([Weight Horsepower],MPG,'PredictorNames',{'Weight' 'Horsepower'})
%       view(t)
%
%       % Using a table
%       tbl = table(Weight,Horsepower,MPG);
%       t2 = fitrtree(tbl,'MPG')
%       view(t,'mode','graph')
%
%   See also RegressionTree,
%   classreg.learning.partition.RegressionPartitionedModel.

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
    this = classreg.learning.paramoptim.fitoptimizing('fitrtree',X,Y,varargin{:});
else
    temp = RegressionTree.template(RemainingArgs{:});
    this = fit(temp,X,Y);
end
end