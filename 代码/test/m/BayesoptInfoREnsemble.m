classdef BayesoptInfoREnsemble < classreg.learning.paramoptim.BayesoptInfo
    
    %   Copyright 2016 The MathWorks, Inc.
    
    
    properties(Constant)
        REnsembleVariableDescriptions = [...
            optimizableVariable('Method', {'Bag' 'LSBoost'});
            optimizableVariable('NumLearningCycles', [10, 500], 'Type', 'integer', 'Transform', 'log');
            optimizableVariable('LearnRate', [1e-3, 1], 'Transform', 'log')];
    end
    
    properties
        FitFcn = @fitrensemble;
        PrepareDataFcn = @classreg.learning.regr.FullRegressionModel.prepareData;
        AllVariableDescriptions;
    end
    
    properties(Access=protected)
        LearnerOptInfo;
        % A template for the weak learner that has ModelParams
        WeakLearnerTemplate;
    end
    
    methods
        function this = BayesoptInfoREnsemble(Predictors, Response, FitFunctionArgs)
            import classreg.learning.paramoptim.*
            this@classreg.learning.paramoptim.BayesoptInfo(Predictors, Response, FitFunctionArgs, false, true);
            % Get weak learner info
            this.WeakLearnerTemplate = getWeakLearnerTemplate(this, FitFunctionArgs);
            if ~isequal(this.WeakLearnerTemplate.Method, 'Tree')
                classreg.learning.paramoptim.err('BadTemplate', this.WeakLearnerTemplate.Method);
            end
            this.LearnerOptInfo = BayesoptInfoRTree(Predictors, Response, FitFunctionArgs);
            % Concatenate the ensemble vars and the weak learner vars
            this.AllVariableDescriptions = [...
                BayesoptInfoREnsemble.REnsembleVariableDescriptions;
                this.LearnerOptInfo.AllVariableDescriptions];
            % Set conditional and xconstraint functions
            this.ConditionalVariableFcn = createCVF(this);
            this.XConstraintFcn = createXCF(this);
        end
        
        function Template = getWeakLearnerTemplate(this, FitFunctionArgs)
            LearnersArg = classreg.learning.paramoptim.parseArg('Learners', FitFunctionArgs);
            Template = templateFromLearnersArg(LearnersArg);
        end
        
        function Args = updateArgsFromTable(this, FitFunctionArgs, XTable)
            % Need to separate the Ensemble args from the weak learner
            % args. Weak learner params get put into a new 'Learner' arg.
            EnsembleXTable = getEnsembleXTable(XTable);
            Args = updateArgsFromTable@classreg.learning.paramoptim.BayesoptInfo(this, FitFunctionArgs, EnsembleXTable);
            NewLearnersArgs = updateREnsembleLearnerArgFromTable(this, FitFunctionArgs, 'Learners', XTable);
            Args = [Args, NewLearnersArgs];
        end
    end
    
    methods(Access=protected)
        function NVP = updateREnsembleLearnerArgFromTable(this, FitFunctionArgs, ArgName, XTable)
            % Find the argument to the parameter 'ArgName' in FitFunctionArgs.
            % Make it a fit template if it's not already one, then
            % substitute values from the XTable into its ModelParams
            % property. Output a new NVP that passes the template.
            import classreg.learning.paramoptim.*
            Value = parseArg(ArgName, FitFunctionArgs);
            if isempty(Value)
                % No 'Learners' arg was passed. Default to 'Tree'
                Value = 'Tree';
            end
            % Make sure we have a template with ModelParams
            Template = templateFromLearnersArg(Value);
            % Subst model params from table to template
            Template.ModelParams = this.LearnerOptInfo.substModelParams(Template.ModelParams, XTable);
            NVP = {ArgName, Template};
        end
        
        function fcn = createCVF(this)
            fcn = @fitrensembleCVF;
            function XTable = fitrensembleCVF(XTable)
                import classreg.learning.paramoptim.*
                % Apply the weak learner's CVF.
                if ~isempty(this.LearnerOptInfo.ConditionalVariableFcn)
                    % Save NumVariablesToSample if being optimized.
                    if BayesoptInfo.hasVariables(XTable, {'NumVariablesToSample'})
                        NumVariablesToSample = XTable.NumVariablesToSample;
                    end
                    % Apply weak learner CVF. This wipes out NumVariablesToSample.
                    XTable = this.LearnerOptInfo.ConditionalVariableFcn(XTable);
                    % Restore NumVariablesToSample.
                    if BayesoptInfo.hasVariables(XTable, {'NumVariablesToSample'})
                        XTable.NumVariablesToSample = NumVariablesToSample;
                    end
                end
                % Do not pass LearnRate if Method is Bag
                if BayesoptInfo.hasVariables(XTable, {'Method', 'LearnRate'})
                    XTable.LearnRate(XTable.Method=='Bag') = NaN;
                end
            end
        end
        
        function fcn = createXCF(this)
            fcn = @fitrensembleXCF;
            function TF = fitrensembleXCF(XTable)
                import classreg.learning.paramoptim.*
                TF = true(height(XTable),1);
                % Apply the weak learner's XCF
                if ~isempty(this.LearnerOptInfo.XConstraintFcn)
                    TF = TF & this.LearnerOptInfo.XConstraintFcn(XTable);
                end
            end
        end
    end
end

function Template = templateFromLearnersArg(Value)
import classreg.learning.paramoptim.*
if isempty(Value)
    Value = 'Tree';
end
if isa(Value, 'classreg.learning.FitTemplate')
    Template = fillIfNeeded(Value, 'regression');
elseif ischar(Value)
    if prefixMatch(Value, 'Tree')
        Template = templateTree('type','regression');
    end
else
    classreg.learning.paramoptim.err('BadLearnerType');
end
end

function EnsembleXTable = getEnsembleXTable(XTable)
import classreg.learning.paramoptim.*
% Form an XTable of just the Ensemble vars
REnsembleNames = {BayesoptInfoREnsemble.REnsembleVariableDescriptions.Name};
[~, REnsembleLocs] = ismember(REnsembleNames, XTable.Properties.VariableNames);
REnsembleLocs(REnsembleLocs==0) = [];
EnsembleXTable = XTable(:, REnsembleLocs);
end

