classdef BayesoptInfo
%BayesoptInfo   Contains information needed to apply bayesopt to the
%problem of optimizing the hyperparameters of a particular classreg fit
%function.
    
%   Copyright 2016 The MathWorks, Inc.


    %% Overridable properties and methods
    properties(Abstract)  % Must be defined in subclasses
        % A handle to the fit function.
        FitFcn
        
        % A handle to the prepareData function associated with this fit function.
        PrepareDataFcn

        % An array of all eligible optimizableVariables for the given
        % FitFcn, with default variables set to be optimized.
        AllVariableDescriptions
    end
    
    properties
        % A handle to an xConstraint function passable to bayesopt(), or []
        % if there is no xConstraint.
        XConstraintFcn = [];
        
        % A handle to a conditional variable function passable to
        % bayesopt(), or [] if there are no conditional variables.
        ConditionalVariableFcn = [];
        
        % Whether the optimization results can be stored in the returned
        % model (in the HyperparameterOptimizationResults property). If false,
        % the result will be returned as an output argument.
        CanStoreResultsInModel = true;
        
        % When the Results must be returned as an output argument of the
        % fit function, the position of that argument.
        OutputArgumentPosition = 2;
        
        % For models that can be used as weak learners in ensembles or
        % binary learners in ECOC, this is a struct mapping parameter names
        % that can appear in NVPs to ModelParams field names. It must have
        % one field for each variable in AllVariableDescriptions, such that
        % ModelParamNameMap.NVPName = MPName.
        ModelParamNameMap = [];
        
        % A logical scalar indicating whether this is a regression fit
        % function or not.
        IsRegression;
    end
    
    methods
        % Override updateArgsFromTable in subclasses if you need to do
        % something other than create a NVP for every non-NaN variable in
        % XTable, postpend it to FitFcnArgs, and delete NVPs that match NaN
        % variables in the table.
        function Args = updateArgsFromTable(this, FitFunctionArgs, XTable)
            ReducedFitFunctionArgs = deleteEliminatedParams(FitFunctionArgs, XTable);
            ArgsFromTable = classreg.learning.paramoptim.BayesoptInfo.argsFromTable(XTable);
            Args = [ReducedFitFunctionArgs, ArgsFromTable];
        end
        
        % Override getVariableDescriptions in subclasses if you need to do
        % more than check legality of the OptimizeHyperparametersArg and
        % enable the indicated VariableDesciptions. For example, the
        % NaiveBayes subclass issues a warning, advising the user to
        % standardize their numeric data if they're optimizing kernel
        % width.
        function VariableDescriptions = getVariableDescriptions(this, OptimizeHyperparametersArg)
            % Return an array of optimizableVariables, some of which should
            % be marked for optimization.  
            OptimizeHyperparametersArg = checkAndCompleteOptimizeHyperparametersArg(OptimizeHyperparametersArg, ...
                this.AllVariableDescriptions);
            if isequal(OptimizeHyperparametersArg, 'auto')
                VariableDescriptions = this.AllVariableDescriptions;
            elseif isequal(OptimizeHyperparametersArg, 'all')
                VariableDescriptions = this.AllVariableDescriptions;
                for v = 1:numel(VariableDescriptions)
                    VariableDescriptions(v).Optimize = true;
                end
            elseif iscellstr(OptimizeHyperparametersArg)
                VariableDescriptions = enableOptimization(OptimizeHyperparametersArg, this.AllVariableDescriptions);
            elseif isa(OptimizeHyperparametersArg, 'optimizableVariable')
                VariableDescriptions = OptimizeHyperparametersArg;
            end
        end
    end
    
    %% Non-overridable public API
    methods(Static)
        % Factory method to make subclasses.
        % https://sourcemaking.com/design_patterns/factory_method
        function Obj = makeBayesoptInfo(FitFunctionName, Predictors, Response, FitFunctionArgs)
            switch FitFunctionName
                case 'fitcdiscr'
                    ConstructorFcn = @classreg.learning.paramoptim.BayesoptInfoCDiscr;
                case 'fitcecoc'
                    ConstructorFcn = @classreg.learning.paramoptim.BayesoptInfoCECOC;
                case 'fitcensemble'
                    ConstructorFcn = @classreg.learning.paramoptim.BayesoptInfoCEnsemble;
                case 'fitcknn'
                    ConstructorFcn = @classreg.learning.paramoptim.BayesoptInfoCKNN;
                case 'fitclinear'
                    ConstructorFcn = @classreg.learning.paramoptim.BayesoptInfoCLinear;
                case 'fitcnb'
                    ConstructorFcn = @classreg.learning.paramoptim.BayesoptInfoCNB;
                case 'fitcsvm'
                    ConstructorFcn = @classreg.learning.paramoptim.BayesoptInfoCSVM;
                case 'fitctree'
                    ConstructorFcn = @classreg.learning.paramoptim.BayesoptInfoCTree;
                case 'fitrensemble'
                    ConstructorFcn = @classreg.learning.paramoptim.BayesoptInfoREnsemble;
                case 'fitrgp'
                    ConstructorFcn = @classreg.learning.paramoptim.BayesoptInfoRGP;
                case 'fitrlinear'
                    ConstructorFcn = @classreg.learning.paramoptim.BayesoptInfoRLinear;
                case 'fitrsvm'
                    ConstructorFcn = @classreg.learning.paramoptim.BayesoptInfoRSVM;
                case 'fitrtree'
                    ConstructorFcn = @classreg.learning.paramoptim.BayesoptInfoRTree;
                otherwise
                    classreg.learning.paramoptim.err('UnknownFitFcn', FitFunctionName);
            end
            Obj = ConstructorFcn(Predictors, Response, FitFunctionArgs);
        end
        
        % Utility functions for use by subclasses
        function tf = hasVariables(Tbl, VarNames)
            % Return true if table Tbl has all variables VarNames.
            tf = all(ismember(VarNames, Tbl.Properties.VariableNames));
        end
        
        function ModelParams = setModelParamsProperty(ModelParams, ...
                ParamName, PropName, Tbl)
            % Put Tbl.ParamName into ModelParams.PropName, unless it's NaN
            % or <undefined>, in which case set it to [] of the right
            % class.
            if ismember(ParamName, Tbl.Properties.VariableNames)
                if isnan(double(Tbl.(ParamName)))
                    ModelParams.(PropName) = cast([], class(ModelParams.(PropName)));
                else
                    ModelParams.(PropName) = classreg.learning.paramoptim.prepareArgValue(Tbl.(ParamName));
                end
            end
        end
        
        function Args = argsFromTable(XTable)
            % Return a cell array of name-value pairs, with one pair for
            % every non-missing variable in the table.
            Args = {};
            for v = 1:width(XTable)
                if ~isnan(double(XTable{1,v}))
                    Args = [Args, {XTable.Properties.VariableNames{v}, ...
                        classreg.learning.paramoptim.prepareArgValue(XTable{1,v})}];
                end
            end
        end
    end
    
    %% Protected
    properties(Access=protected)
        % Dataset properties
        NumObservations;
        NumPredictors;
        MaxPredictorRange;
        MinPredictorDiff;   % Min abs nonzero diff, or 0 if MaxPredictorRange=0
        ResponseIqr;
        ResponseStd;
        NumClasses;
        CategoricalPredictorIndices;  
    end
    
    methods(Access=protected)
        function this = BayesoptInfo(Predictors, Response, FitFunctionArgs, ObservationsInCols, IsRegression)
            this.IsRegression = IsRegression;
            % Compute dataset properties. IMPORTANT: This must be efficient
            % when Predictors is a sparse matrix.
            if ObservationsInCols
                AccumDim = 2;
            else
                AccumDim = 1;
            end
            if istable(Predictors)
                [Predictors, Response, vrange, wastable, FitFunctionArgs] = classreg.learning.internal.table2FitMatrix(...
                    Predictors, Response, FitFunctionArgs{:});
            end
            % If regression, response must be numeric
            if IsRegression && ~isnumeric(Response)
                classreg.learning.paramoptim.err('NonNumericYInRegression');
            end
            this.NumObservations = size(Predictors, AccumDim);
            this.NumPredictors = size(Predictors, 3-AccumDim);
            % predictor properties
            if isnumeric(Predictors)
                this.MaxPredictorRange = max(nanmax(Predictors,[],AccumDim) - nanmin(Predictors,[],AccumDim));
                if this.MaxPredictorRange == 0
                    this.MinPredictorDiff = 0;
                else
                    diffs = diff(sort(Predictors, AccumDim), 1, AccumDim);
                    this.MinPredictorDiff = nanmin(diffs(diffs~=0));
                end
            else
                this.MaxPredictorRange = NaN;
                this.MinPredictorDiff = NaN;
            end
            % Response properties
            if isnumeric(Response)
                this.ResponseIqr = iqr(Response);
                this.ResponseStd = nanstd(Response);
            else
                this.ResponseIqr = NaN;
                this.ResponseStd = NaN;
            end
            % Find NumClasses
            [ClassNamesPassed, ~, ~] = internal.stats.parseArgs({'ClassNames'}, {[]}, FitFunctionArgs{:});
            this.NumClasses = numClasses(Response, ClassNamesPassed);
            % Find CategoricalPredictors
            [CPs, ~, ~] = internal.stats.parseArgs({'CategoricalPredictors'}, {[]}, FitFunctionArgs{:});
            this.CategoricalPredictorIndices = CPs;
        end
        
        function ModelParams  = substModelParams(this, ModelParams, XTable)
        % For models that can be used as a weak learner in ensembles or as
        % a binary learner in ECOC. Substitute values from XTable into the
        % appropriate properties of ModelParams. Called by ensemble and
        % ecoc subclasses.
        import classreg.learning.paramoptim.*
        ParameterNames = fieldnames(this.ModelParamNameMap);
            for i = 1:numel(ParameterNames)
                ModelParams = BayesoptInfo.setModelParamsProperty(ModelParams, ParameterNames{i}, ...
                                this.ModelParamNameMap.(ParameterNames{i}), XTable);
            end
        end
    end
end

function N = numClasses(Y, ClassNamesPassed)
if isempty(ClassNamesPassed)
    N = numel(levels(classreg.learning.internal.ClassLabel(Y)));
else
    N = numel(levels(classreg.learning.internal.ClassLabel(ClassNamesPassed)));
end
end

function ParameterNames = checkAndCompleteParameterNames(ParameterNames, LegalParameterNames)
% Check that all ParameterNames are prefixes of LegalParameterNames, and
% complete them.
ArgList = repmat({true},1,2*numel(ParameterNames));
ArgList(1:2:end) = ParameterNames;
Defaults = repmat({false},1,numel(LegalParameterNames));
[values{1:numel(LegalParameterNames)}, ~, extra] = internal.stats.parseArgs(...
    LegalParameterNames, Defaults, ArgList{:});
if ~isempty(extra)
    classreg.learning.paramoptim.err('ParamNotOptimizable', extra{1}, cellstr2str(LegalParameterNames));
end
ParameterNames = LegalParameterNames([values{:}]);
end

function VariableDescriptions = enableOptimization(OptimizeHyperparameters, ...
    AllVariableDescriptions)
VariableDescriptions = AllVariableDescriptions;
for i = 1:numel(VariableDescriptions)
    VariableDescriptions(i).Optimize = ismember(...
        VariableDescriptions(i).Name, OptimizeHyperparameters);
end
end

function OptimizeHyperparameters = checkAndCompleteOptimizeHyperparametersArg(OptimizeHyperparameters, LegalVariableDescriptions)
% Check user-supplied OptimizeHyperparameters
LegalVariableNames = {LegalVariableDescriptions.Name};
if isequal(OptimizeHyperparameters, 'auto') || isequal(OptimizeHyperparameters, 'all')
    return;
elseif iscellstr(OptimizeHyperparameters)
    OptimizeHyperparameters = checkAndCompleteParameterNames(OptimizeHyperparameters, LegalVariableNames);
elseif isa(OptimizeHyperparameters, 'optimizableVariable')
    checkAndCompleteParameterNames({OptimizeHyperparameters.Name}, LegalVariableNames);
else
    classreg.learning.paramoptim.err('OptimizeHyperparameters');
end
end

function Args = deleteEliminatedParams(Args, XTable)
% Delete NVPs matching NaN/undefined vars in XTable.
for v = 1:width(XTable)
    if isnan(double(XTable{1,v}))
        FullVarName = XTable.Properties.VariableNames{v};
        NameLocs = find(cellfun(@(P)classreg.learning.paramoptim.prefixMatch(P,FullVarName), ...
                                Args(1:2:end)));
        NVPLocs = [2*NameLocs-1, 2*NameLocs];
        Args(NVPLocs) = [];
    end
end
end

function s = cellstr2str(C)
% Convert cellstr into comma-separated char array.
if isempty(C)
    s = '';
else
    s = C{1};
end
for i=2:numel(C)
    s = [s, ', ', C{i}];
end
end
