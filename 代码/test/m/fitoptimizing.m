function [varargout] = fitoptimizing(FitFunctionName, Predictors, Response, varargin)
%fitoptimizing     Fit a machine learning model to a dataset, automatically
% optimizing hyperparameters to minimize validation loss.
%
%   (1) [Model, OtherArgs...] = fitoptimizing(FitFunctionName, Predictors, Response, FitFunctionArgs...)
%
%       attempts to find a model minimizing validation loss, by
%       optimizing hyperparameters of the FitFunctionName.
%
%     Input arguments:
%       FitFunctionName          - The name of the fitting function used to
%                           create models. One of 'fitcdiscr', 'fitcecoc',
%                           'fitcensemble', 'fitcknn', 'fitclinear',
%                           'fitcnb', fitcsvm', fitctree', 'fitrensemble',
%                           'fitrgp', 'fitrlinear', 'fitrsvm', 'fitrtree'.
%       Predictors          - A matrix, or table, of predictor data.
%       Response            - A vector of response data, or the name of a
%                           variable containing response data if
%                           'Predictors' is a table.
%       FitFunctionArgs...  - Any name/value pairs accepted by FitFunctionName
%                           except validation arguments. To change the
%                           default validation scheme used in the
%                           optimization, pass the
%                           'HyperparameterOptimizationOptions' argument.
%     Output arguments:
%       Model               - The best model found during the optimization.
%                           The 'HyperparameterOptimizationResults' property of
%                           Model will be set to an object containing more
%                           information about the optimization. If
%                           'Optimizer' is 'bayesopt', this is a
%                           BayesianOptimization instance. Otherwise it is a
%                           table with two variables: One is the set of X
%                           values evaluated, and the other is the
%                           corresponding ObjectiveFcn value.
%       OtherArgs...        - Any additional output arguments returned by
%                           the fit function.
%
%   (2) [...] = fitoptimizing(..., 'Param1', val1, 'Param2', val2, ...)
%
%       specifies additional name/value pairs:
%
%       'OptimizeHyperparameters'
%                   - Either 'auto', 'all', a cell array of eligible
%                   parameter names, or a vector of optimizableVariable
%                   objects, such as that returned by the 'hyperparameters'
%                   function. 
%                   Default: 'auto'.
%
%       'HyperparameterOptimizationOptions'
%                   - A struct specifying additional optimization options.
%                   Recognized fields (all optional) are:
%                       Optimizer     - One of {'bayesopt', 'gridsearch',
%                                       or 'randomsearch'} specifying the
%                                       optimization algorithm.
%                                       Default: 'bayesopt'
%                       MaxObjectiveEvaluations
%                                       - Specifies the maximum number of
%                                       function evaluations to perform.
%                                       Default: 30 for Optimizer equal to
%                                       'bayesopt' or 'randomsearch'; The
%                                       full grid size for 'gridsearch'.
%                       MaxTime         - Optimization stops when the
%                                       optimization has run for this many
%                                       seconds of "wall clock time". The
%                                       actual runtime may be higher
%                                       because individual function
%                                       evaluations are not interrupted.
%                                       Default: Inf
%                       AcquisitionFunctionName
%                                       - When Optimizer is 'bayesopt',
%                                       specifies the Acquisition Function
%                                       to use in choosing the next point
%                                       to evaluate. See BAYESOPT for
%                                       accepted values. Default:
%                                       'expected-improvement-per-second-plus'
%                       NumGridDivisions
%                                       - When Optimizer is 'gridsearch',
%                                       specifies the number of grid
%                                       divisions per dimension. Can be a
%                                       vector with the number of divisions
%                                       for each parameter, or a scalar
%                                       applied to all parameters. For
%                                       categorical parameters, the passed
%                                       value is ignored and all categories
%                                       are used. 
%                                       Default: 10
%                       ShowPlots    	- A logical scalar. If true,
%                                       a plot is displayed of the best
%                                       function value found as a function
%                                       of the number of function
%                                       evaluations. If there are 1 or 2
%                                       parameters to optimize, it will
%                                       also display a plot of a model of
%                                       the the Objective Function vs. the
%                                       parameters being optimized.
%                                       Default: true
%                       SaveIntermediateResults
%                                       - A logical scalar. If true and
%                                       Optimizer is bayesopt, a variable
%                                       'BayesoptResults' will be
%                                       overwritten in the workspace after
%                                       each iteration. 
%                                       Default: false
%                       Verbose         - 0, 1 or 2. Controls the level of
%                                       detail of command line display.
%                                       Default: 1
%                       Repartition     - A logical scalar. If true, a
%                                       new data partitioning is created
%                                       for each function evaluation. If
%                                       false, a single partitioning is
%                                       used for all evaluations. 
%                                       Default: false
%                       UseParallel     - A logical scalar specifying
%                                       whether to perform function
%                                       evaluations on the current parallel
%                                       pool. Requires Parallel Computing
%                                       Toolbox(tm).
%                                       Default: false
%                      Use no more than one of the following three field
%                      names, to define the objective function to be
%                      optimized:
%                       CVPartition     - A cvpartition object.
%                       Holdout         - A scalar in the range (0,1).
%                       KFold           - An integer greater than 1.
%                       Default: KFold,5
% 

%   Copyright 2016-2017 The MathWorks, Inc.

% Parse and check args
verifyNoValidationArgs(varargin);
[OptimizeHyperparametersArg, HyperparameterOptimizationOptions, FitFunctionArgs] = ...
    classreg.learning.paramoptim.parseFitoptimizingArgs(varargin);

% Create optimization info and validation args
BOInfo = classreg.learning.paramoptim.BayesoptInfo.makeBayesoptInfo(FitFunctionName, Predictors, Response, FitFunctionArgs);
VariableDescriptions = getVariableDescriptions(BOInfo, OptimizeHyperparametersArg);

% Create objective function
[ValidationMethod, ValidationVal] = getPassedValidationArgs(HyperparameterOptimizationOptions);
objFcn = classreg.learning.paramoptim.createObjFcn(BOInfo, FitFunctionArgs, Predictors, Response, ...
    ValidationMethod, ValidationVal, HyperparameterOptimizationOptions.Repartition, HyperparameterOptimizationOptions.Verbose);

% Perform optimization
switch HyperparameterOptimizationOptions.Optimizer
    case 'bayesopt'
        [OptimizationResults, XBest] = doBayesianOptimization(objFcn, BOInfo, VariableDescriptions, HyperparameterOptimizationOptions);
    case 'gridsearch'
        [OptimizationResults, XBest] = doNonBayesianOptimization('grid', objFcn, BOInfo, VariableDescriptions, HyperparameterOptimizationOptions);
    case 'randomsearch'
        [OptimizationResults, XBest] = doNonBayesianOptimization('random', objFcn, BOInfo, VariableDescriptions, HyperparameterOptimizationOptions);
end

% Fit final model using best parameters and return/store optimization results
if isempty(XBest)
    classreg.learning.paramoptim.warn('NoFinalModel');
    [varargout{1:nargout}] = [];
else
    if BOInfo.CanStoreResultsInModel
        [varargout{1:nargout}] = classreg.learning.paramoptim.fitToFullDataset(XBest, BOInfo, ...
            FitFunctionArgs, Predictors, Response);
        varargout{1} = setParameterOptimizationResults(varargout{1}, OptimizationResults);
    elseif nargout == BOInfo.OutputArgumentPosition
        % Return results as output arg
        [varargout{1:nargout-1}] = classreg.learning.paramoptim.fitToFullDataset(XBest, BOInfo, ...
            FitFunctionArgs, Predictors, Response);
        varargout{BOInfo.OutputArgumentPosition} = OptimizationResults;
    else
        % Can't store Results in model, and not requested as output arg
        [varargout{1:nargout}] = classreg.learning.paramoptim.fitToFullDataset(XBest, BOInfo, ...
            FitFunctionArgs, Predictors, Response);
    end
end
end

function [OptimizationResults, XBest] = doBayesianOptimization(objFcn, BOInfo, ...
    VariableDescriptions, HyperparameterOptimizationOptions)
% Create args to bayesopt
if HyperparameterOptimizationOptions.ShowPlots
    PlotFcn = {@plotMinObjective};
    if sum([VariableDescriptions.Optimize]) <= 2
        PlotFcn{end+1} = @plotObjectiveModel;
    end
else
    PlotFcn = {};
end
if HyperparameterOptimizationOptions.SaveIntermediateResults
    OutputFcn = @assignInBase;
else
    OutputFcn = {};
end
% Call bayesopt
OptimizationResults = bayesopt(objFcn, VariableDescriptions, ...
    'AcquisitionFunctionName', HyperparameterOptimizationOptions.AcquisitionFunctionName,...
    'MaxObjectiveEvaluations', HyperparameterOptimizationOptions.MaxObjectiveEvaluations, ...
    'MaxTime', HyperparameterOptimizationOptions.MaxTime, ...
    'XConstraintFcn', BOInfo.XConstraintFcn, ...
    'ConditionalVariableFcn', BOInfo.ConditionalVariableFcn, ...
    'Verbose', HyperparameterOptimizationOptions.Verbose, ...
    'UseParallel', HyperparameterOptimizationOptions.UseParallel, ...
    'PlotFcn', PlotFcn,...
    'OutputFcn', OutputFcn,...
    'AlwaysReportObjectiveErrors', true);
% Choose best point
XBest = chooseBestPointBayesopt(OptimizationResults);
end

function [OptimizationResults, XBest] = doNonBayesianOptimization(AFName, objFcn, BOInfo, ...
    VariableDescriptions, HyperparameterOptimizationOptions)
% Create args to bayesopt
if HyperparameterOptimizationOptions.ShowPlots
    PlotFcn = {@plotMinObjective};
else
    PlotFcn = {};
end
% Call bayesopt
BOResults = bayesopt(objFcn, VariableDescriptions, ...
    'AcquisitionFunctionName', AFName,...
    'NumGridDivisions', HyperparameterOptimizationOptions.NumGridDivisions,...
    'FitModels', false,...
    'MaxObjectiveEvaluations', HyperparameterOptimizationOptions.MaxObjectiveEvaluations, ...
    'MaxTime', HyperparameterOptimizationOptions.MaxTime, ...
    'ConditionalVariableFcn', BOInfo.ConditionalVariableFcn, ...
    'XConstraintFcn', BOInfo.XConstraintFcn, ...
    'Verbose', HyperparameterOptimizationOptions.Verbose, ...
    'UseParallel', HyperparameterOptimizationOptions.UseParallel, ...
    'PlotFcn', PlotFcn,...
    'OutputFcn', [],...
    'AlwaysReportObjectiveErrors', true);
% Choose best point
XBest = chooseBestPointNonBayesopt(BOResults);
% Build results table
OptimizationResults = BOResults.XTrace;
OptimizationResults.Objective = BOResults.ObjectiveTrace;
OptimizationResults.Rank = rankVector(BOResults.ObjectiveTrace);
end

function R = rankVector(V)
R = zeros(size(V));
[~,I] = sort(V);
R(I) = 1:numel(V);
end

function BestXTable = chooseBestPointBayesopt(BO)
% Try default method. If that fails, return best observed point.
BestXTable = bestPoint(BO);
if isempty(BestXTable)
    BestXTable = bestPoint(BO, 'Criterion','minobserved');
end
end

function XBest = chooseBestPointNonBayesopt(BO)
if isfinite(BO.MinObjective)
    XBest = BO.XAtMinObjective;
else
    XBest = [];
end
end

function verifyNoValidationArgs(Args)
if classreg.learning.paramoptim.anyArgPassed({'CrossVal', 'CVPartition', 'Holdout', 'KFold', 'Leaveout'}, Args)
    classreg.learning.paramoptim.err('ValidationArgLocation');
end
end

function [ValidationMethod, ValidationVal] = getPassedValidationArgs(ParamOptimOptions)
% Assumes that exactly one validation field is nonempty.
if ~isempty(ParamOptimOptions.KFold)
    ValidationMethod	= 'KFold';
    ValidationVal       = ParamOptimOptions.KFold;
elseif ~isempty(ParamOptimOptions.Holdout)
    ValidationMethod	= 'Holdout';
    ValidationVal       = ParamOptimOptions.Holdout;
elseif ~isempty(ParamOptimOptions.CVPartition)
    ValidationMethod	= 'CVPartition';
    ValidationVal       = ParamOptimOptions.CVPartition;
end
end
