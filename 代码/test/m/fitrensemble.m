function obj = fitrensemble(X,Y,varargin)
%  fitrensemble Fit ensemble of regression learners
%     ENS=fitrensemble(TBL,Y) fits a regression ensemble model ENS,
%     which can be used for making predictions on new data. ENS uses a
%     collection of individual regression learners such as
%     regression trees. These individual learners are trained from one
%     or more templates specified in LEARNERS.
%
%     TBL is a table containing predictors and Y is the response. Y can be
%     any of the following:
%       1. A vector of floating-point numbers.
%       2. The name of a variable in TBL. This variable is used as the
%          response Y, and the remaining variables in TBL are used as
%          predictors.
%       3. A formula string such as 'y ~ x1 + x2 + x3' specifying that the
%          variable y is to be used as the response, and the other variables
%          in the formula are predictors. Any table variables not listed in
%          the formula are not used.
%
%     ENS=fitrensemble(X,Y) is an alternative syntax that accepts X as an
%     N-by-P matrix of predictors with one row per observation and one
%     column per predictor. Y is the response.
%
%     Use of a matrix X rather than a table TBL saves both memory and
%     execution time.
%
%     ENS is an object of class RegressionEnsemble. If you use one of the
%     following five options and do not pass OptimizeHyperparameters, ENS
%     is of class RegressionPartitionedEnsemble: 'CrossVal', 'KFold',
%     'Holdout', 'Leaveout' or 'CVPartition'.
%
%     ENS=fitrensemble(...,'PARAM1',val1,'PARAM2',val2,...) specifies
%     optional parameter name/value pairs:
%       'Method'    - Learner aggregation method. Method must be one of
%                     the following, case-insensitive character vectors:
%                      'LSBoost'
%                      'Bag'
%                     Default: 'LSBoost'
%       'NumLearningCycles'    - Positive integer specifying the number of
%                     ensemble learning cycles. At every training cycle,
%                     fitrensemble loops over all learner templates in
%                     Learners and trains one weak learner for every
%                     template object. The number of trained learners in
%                     ENS is equal to NumLearningCycles*numel(Learners).
%                     Usually, an ensemble with a good predictive power
%                     needs between a few hundred and a few thousand weak
%                     learners. You do not have to train an ensemble for
%                     that many cycles at once. You can start by growing a
%                     few dozen learners, inspect the ensemble performance
%                     and, if necessary, train more weak learners using
%                     RESUME method of the ensemble. 
%                     Default: 100
%       'Learners'  - String scalar or character vector specifying the name 
%                     of the weaklearner, or a single or cell array of weak 
%                     learner template objects. When specifying template objects,
%                     you must construct every one using the appropriate
%                     learner template function. For example, call
%                     TEMPLATETREE if you want to grow an ensemble of
%                     trees. Usually, you need to supply only one weak
%                     learner template. To supply one weak learner using
%                     default parameters, pass Learners in as a character
%                     vector specifying the name of the weak learner, for
%                     example, 'tree'.
%                     Use the following learner names and templates:
%                       'Tree'                  
%                       templateTree
%                     Note: Ensemble performance depends on the parameters
%                     of the weak learners. You can get poor performance
%                     for weak learners with default parameters. 
%                     Default: 
%                       templateTree('MaxNumSplits',10) when Method is
%                           'LSBoost'
%                       'Tree' when Method is 'Bag', 
%       'NPrint'    - Print-out frequency, a positive integer scalar.
%                     By default, this parameter is set to 'off' (no
%                     print-outs). You can use this parameter to keep track
%                     of how many weak learners have been trained, so far.
%                     This is useful when you train ensembles with many
%                     learners on large datasets.
%       'OptimizeHyperparameters' 
%                      - Hyperparameters to optimize. Either 'none',
%                        'auto', 'all', a string/cell array of eligible
%                        hyperparameter names, or a vector of
%                        optimizableVariable objects, such as that returned
%                        by the 'hyperparameters' function. To control
%                        other aspects of the optimization, use the
%                        HyperparameterOptimizationOptions name-value pair.
%                        'auto' is equivalent to {'LearnRate', 'Method',
%                        'NumLearningCycles'}, plus the 'auto'
%                        hyperparameters of the specified weak learner.
%                        'all' is equivalent to {'LearnRate', 'Method',
%                        'NumLearningCycles'}, plus all eligible
%                        hyperparameters of the specified weak learner.
%                        Default: 'none'.
%   Refer to the MATLAB documentation for info on parameters for
%       <a href="matlab:helpview(fullfile(docroot,'stats','stats.map'), 'fitrensembleGeneralEnsembleOptions')">regression ensembles</a>
%       <a href="matlab:helpview(fullfile(docroot,'stats','stats.map'), 'fitrensembleRegressionOptions')">regression (such as 'Weights')</a>
%       <a href="matlab:helpview(fullfile(docroot,'stats','stats.map'), 'fitrensembleCVOptions')">cross-validation</a>
%       <a href="matlab:helpview(fullfile(docroot,'stats','stats.map'), 'fitrensembleSampleOptions')">sampling options</a>
%       <a href="matlab:helpview(fullfile(docroot,'stats','stats.map'), 'fitrensembleLSBoostOptions')">LSBoost</a>
%       <a href="matlab:helpview(fullfile(docroot,'stats','stats.map'), 'fitrensembleHyperparameterOptimizationOptions')">Hyperparameter Optimization</a>
%
%   See also templateTree,
%   classreg.learning.regr.RegressionEnsemble,
%   classreg.learning.regr.RegressionEnsemble/resume,
%   classreg.learning.partition.RegressionPartitionedEnsemble

%   Copyright 2017 The MathWorks, Inc.

internal.stats.checkNotTall(upper(mfilename),0,X,Y,varargin{:});

if nargin > 1
    Y = convertStringsToChars(Y);
end

if nargin > 2
    [varargin{:}] = convertStringsToChars(varargin{:});
end

[IsOptimizing, RemainingArgs] = classreg.learning.paramoptim.parseOptimizationArgs(varargin);
if IsOptimizing
    obj = classreg.learning.paramoptim.fitoptimizing('fitrensemble',X,Y,varargin{:});
else
    Names = {'Method', 'NumLearningCycles', 'Learners'};
    Defaults = {'LSBoost', 100, 'Tree'};
    [Method, NumLearningCycles, Learners, ~, RemainingArgs] = ...
        internal.stats.parseArgs(Names, Defaults, RemainingArgs{:});
    checkLearners(Learners);
    checkMethod(Method);
    if isBoostingMethod(Method)
        Learners = setTreeDefaultsIfAny(Learners);
    end
    obj = fitensemble(X, Y, Method, NumLearningCycles, Learners, RemainingArgs{:}, ...
        'Type', 'regression');
end
end

function checkMethod(Method)
if ~ischar(Method)
    error(message('stats:fitensemble:MethodNameNotChar'));
end
if ~any(strncmpi(Method,classreg.learning.ensembleModels(),length(Method)))
    error(message('stats:fitensemble:BadMethod', Method));
end
end

function checkLearners(Learners)
if ~(ischar(Learners) || isa(Learners, 'classreg.learning.FitTemplate') || ...
        iscell(Learners) && all(cellfun(@(Tmp)isa(Tmp, 'classreg.learning.FitTemplate'), Learners)))
    error(message('stats:fitensemble:BadLearners'));
end
end

function tf = isBoostingMethod(Method)
tf = ischar(Method) && ~isempty(strfind(lower(Method), 'boost'));
end

function Learners = setTreeDefaultsIfAny(Learners)
% For any learners that are trees, make MaxNumSplits default to 10. 
if ischar(Learners) && isequal(lower(Learners), 'tree')
    Learners = templateTree('MaxNumSplits', 10);
elseif isa(Learners, 'classreg.learning.FitTemplate') 
    Learners = defaultMaxNumSplitsIfTemplateTree(Learners, 10);
elseif iscell(Learners) && all(cellfun(@(Tmp)isa(Tmp, 'classreg.learning.FitTemplate'), Learners))
    Learners = cellfun(@(Tmp)defaultMaxNumSplitsIfTemplateTree(Tmp, 10), ...
                       Learners, 'UniformOutput', false);
end
end

function Tmp = defaultMaxNumSplitsIfTemplateTree(Tmp, value)
if isequal(lower(Tmp.Method), 'tree')
    Tmp = fillIfNeeded(Tmp, 'regression');
    if isempty(getInputArg(Tmp, 'MaxSplits'))
        Tmp = setInputArg(Tmp, 'MaxSplits', value);
    end
end
end
