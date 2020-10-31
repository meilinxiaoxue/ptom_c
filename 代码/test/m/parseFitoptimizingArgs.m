function [OptimizeHyperparameters, HyperparameterOptimizationOptions, RemainingArgs] = ...
    parseFitoptimizingArgs(Args)
% Parse the two parameters 'OptimizeHyperparameters' and
% 'HyperparameterOptimizationOptions'. Fill options defaults.
    
%   Copyright 2016-2017 The MathWorks, Inc.

[OptimizeHyperparameters, Opts, ~, RemainingArgs] = internal.stats.parseArgs(...
    {'OptimizeHyperparameters', 'HyperparameterOptimizationOptions'}, ...
    {'auto', []}, ...
    Args{:});
HyperparameterOptimizationOptions = validateAndFillParameterOptimizationOptions(Opts);
end

function Opts = validateAndFillParameterOptimizationOptions(Opts)
if isempty(Opts)
    Opts = struct;
elseif ~isstruct(Opts)
    classreg.learning.paramoptim.err('OptimOptionsNotStruct');
end
Opts = validateAndCompleteStructFields(Opts, {'Optimizer', 'MaxObjectiveEvaluations', 'MaxTime',...
    'AcquisitionFunctionName', 'NumGridDivisions', 'ShowPlots', 'SaveIntermediateResults', 'Verbose', ...
    'CVPartition', 'Holdout', 'KFold', 'Repartition', 'UseParallel'});
% Validate and fill Optimizer:
if ~isempty(Opts.Optimizer)
    validateOptimizer(Opts.Optimizer);
else
    Opts.Optimizer = 'bayesopt';
end
% Validate and fill MaxObjectiveEvaluations:
if ~isempty(Opts.MaxObjectiveEvaluations)
    validateMaxFEvals(Opts.MaxObjectiveEvaluations);
else
    Opts.MaxObjectiveEvaluations = [];      % use bayesopt default.
end
% Validate and fill MaxTime:
if ~isempty(Opts.MaxTime)
    validateMaxTime(Opts.MaxTime);
else
    Opts.MaxTime = Inf;
end
% Validate and fill AcquisitionFunctionName:
if ~isempty(Opts.AcquisitionFunctionName)
    validateAcquisitionFunctionName(Opts.AcquisitionFunctionName);
else
    Opts.AcquisitionFunctionName = 'expected-improvement-per-second-plus';
end
% Validate and fill NumGridDivisions:
if ~isempty(Opts.NumGridDivisions)
    validateNumGrid(Opts.NumGridDivisions);
else
    Opts.NumGridDivisions = 10;
end
% Validate and fill ShowPlots:
if ~isempty(Opts.ShowPlots)
    validateShowPlots(Opts.ShowPlots);
else
    Opts.ShowPlots = true;
end
% Validate and fill SaveIntermediateResults:
if ~isempty(Opts.SaveIntermediateResults)
    validateSaveIntermediateResults(Opts.SaveIntermediateResults);
    if Opts.SaveIntermediateResults && ~isequal(Opts.Optimizer, 'bayesopt')
        classreg.learning.paramoptim.err('SaveIntermediateResultsCondition');
    end
else
    Opts.SaveIntermediateResults = false;
end
% Validate and fill Verbose:
if ~isempty(Opts.Verbose)
    validateVerbose(Opts.Verbose);
else
    Opts.Verbose = 1;
end
% Validate and fill UseParallel. THIS MUST PRECEDE
% validateAndFillValidationOptions:
if ~isempty(Opts.UseParallel)
    validateUseParallel(Opts.UseParallel);
else
    Opts.UseParallel = false;
end
% Validate and fill validation options. THIS MUST FOLLOW validateUseParallel
Opts = validateAndFillValidationOptions(Opts);
end

function validateOptimizer(Optimizer)
if ~bayesoptim.isCharInCellstr(Optimizer, {'bayesopt', 'gridsearch', 'randomsearch'})
    classreg.learning.paramoptim.err('Optimizer');
end
end

function validateMaxFEvals(MaxObjectiveEvaluations)
if ~bayesoptim.isNonnegativeInteger(MaxObjectiveEvaluations)
    classreg.learning.paramoptim.err('MaxObjectiveEvaluations');
end
end

function validateMaxTime(MaxTime)
if ~bayesoptim.isNonnegativeRealScalar(MaxTime)
    classreg.learning.paramoptim.err('MaxTime');
end
end

function validateAcquisitionFunctionName(AcquisitionFunctionName)
RepairedString = bayesoptim.parseArgValue(AcquisitionFunctionName, {...
    'expectedimprovement', ...
    'expectedimprovementplus', ...
    'expectedimprovementpersecond',...
    'expectedimprovementpersecondplus',...
    'lowerconfidencebound',...
    'probabilityofimprovement'});
if isempty(RepairedString)
    classreg.learning.paramoptim.err('AcquisitionFunctionName');
end
end

function validateNumGrid(NumGridDivisions)
if ~all(arrayfun(@(x)bayesoptim.isLowerBoundedIntScalar(x,2), NumGridDivisions))
    classreg.learning.paramoptim.err('NumGridDivisions');
end
end

function validateShowPlots(ShowPlots)
if ~bayesoptim.isLogicalScalar(ShowPlots)
    classreg.learning.paramoptim.err('ShowPlots');
end
end

function validateUseParallel(UseParallel)
if ~bayesoptim.isLogicalScalar(UseParallel)
    classreg.learning.paramoptim.err('UseParallel');
end
end

function validateSaveIntermediateResults(SaveIntermediateResults)
if ~bayesoptim.isLogicalScalar(SaveIntermediateResults)
    classreg.learning.paramoptim.err('SaveIntermediateResultsType');
end
end

function validateVerbose(Verbose)
if ~(bayesoptim.isAllFiniteReal(Verbose) && ismember(Verbose, [0,1,2]))
    classreg.learning.paramoptim.err('Verbose');
end
end

function validateRepartition(Repartition, Options)
% Assumes UseParallel has been filled by this point.
if ~bayesoptim.isLogicalScalar(Repartition)
    classreg.learning.paramoptim.err('RepartitionType');
end
if Repartition && ~isempty(Options.CVPartition)
    classreg.learning.paramoptim.err('RepartitionCondition');
end
end

function Options = validateAndFillValidationOptions(Options)
% Assumes UseParallel has been filled by this point.
NumPassed = ~isempty(Options.CVPartition) + ~isempty(Options.Holdout) + ~isempty(Options.KFold);
if NumPassed > 1
    classreg.learning.paramoptim.err('MultipleValidationArgs');
elseif NumPassed == 0
    Options.KFold = 5;
elseif ~isempty(Options.CVPartition)
    if ~isa(Options.CVPartition, 'cvpartition')
        classreg.learning.paramoptim.err('CVPartitionType');
    end
elseif ~isempty(Options.Holdout)
    v = Options.Holdout;
    if ~(bayesoptim.isAllFiniteReal(v) && v>0 && v<1)
        classreg.learning.paramoptim.err('Holdout');
    end
elseif ~isempty(Options.KFold)
    v = Options.KFold;
    if ~(bayesoptim.isLowerBoundedIntScalar(v,2))
        classreg.learning.paramoptim.err('KFold');
    end
end
% Repartition
if ~isempty(Options.Repartition)
    validateRepartition(Options.Repartition, Options);
else
    Options.Repartition = false;
end
end

function S = validateAndCompleteStructFields(S, FieldNames)
% Make sure all fields of S are prefixes of the character vectors in
% FieldNames, and return a complete struct.
f = fieldnames(S);
ArgList = cell(1,2*numel(f));
ArgList(1:2:end) = f;
ArgList(2:2:end) = struct2cell(S);
Defaults = cell(1,numel(f));
[values{1:numel(FieldNames)}, ~, extra] = internal.stats.parseArgs(...
    FieldNames, Defaults, ArgList{:});
if ~isempty(extra)
    classreg.learning.paramoptim.err('BadStructField', extra{1});
end
StructArgs = cell(1,2*numel(FieldNames));
StructArgs(1:2:end) = FieldNames;
StructArgs(2:2:end) = values;
S = struct(StructArgs{:});
end


