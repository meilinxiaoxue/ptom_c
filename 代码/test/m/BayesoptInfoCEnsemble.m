classdef BayesoptInfoCEnsemble < classreg.learning.paramoptim.BayesoptInfo
    
    %   Copyright 2016 The MathWorks, Inc.
    
    
    properties
        FitFcn = @fitcensemble;
        PrepareDataFcn = @classreg.learning.classif.FullClassificationModel.prepareData;
        AllVariableDescriptions;
        CEnsembleVariableDescriptions;
    end
    
    properties(Access=protected)
        LearnerOptInfo;
        % A template for the weak learner that has ModelParams
        WeakLearnerTemplate;
    end
    
    methods
        function this = BayesoptInfoCEnsemble(Predictors, Response, FitFunctionArgs)
            this@classreg.learning.paramoptim.BayesoptInfo(Predictors, Response, FitFunctionArgs, false, false);
            % Configure 'Method' variable based on NumClasses
            switch this.NumClasses
                case 2
                    MethodVar = optimizableVariable('Method', {'Bag' 'GentleBoost' 'LogitBoost' 'AdaBoostM1' 'RUSBoost'});
                otherwise
                    MethodVar = optimizableVariable('Method', {'Bag' 'AdaBoostM2' 'RUSBoost'});
            end
            % Get ensemble vars
            this.CEnsembleVariableDescriptions = [...
                MethodVar;
                optimizableVariable('NumLearningCycles', [10, 500], 'Type', 'integer', 'Transform', 'log');
                optimizableVariable('LearnRate', [1e-3, 1], 'Transform', 'log')];
            % Get BOInfo for the weak learner
            this.WeakLearnerTemplate = getWeakLearnerTemplate(this, FitFunctionArgs);
            switch this.WeakLearnerTemplate.Method
                case 'Discriminant'
                    this.LearnerOptInfo = classreg.learning.paramoptim.BayesoptInfoCDiscr(Predictors, Response, FitFunctionArgs);
                case 'KNN'
                    this.LearnerOptInfo = classreg.learning.paramoptim.BayesoptInfoCKNN(Predictors, Response, FitFunctionArgs);
                case 'Tree'
                    this.LearnerOptInfo = classreg.learning.paramoptim.BayesoptInfoCTree(Predictors, Response, FitFunctionArgs);
                otherwise
                    classreg.learning.paramoptim.err('BadTemplate', this.WeakLearnerTemplate.Method);
            end
            % Concatenate ensemble vars and weak learner vars
            this.AllVariableDescriptions = [this.CEnsembleVariableDescriptions;
                                            this.LearnerOptInfo.AllVariableDescriptions];
            % Set conditional and xconstraint functions
            this.ConditionalVariableFcn = createCVF(this);
            this.XConstraintFcn = createXCF(this);
        end
        
        function Template = getWeakLearnerTemplate(this, FitFunctionArgs)
            LearnersArg = classreg.learning.paramoptim.parseArg('Learners', FitFunctionArgs);
            MethodArg = classreg.learning.paramoptim.parseArg('Method', FitFunctionArgs);
            Template = templateFromLearnersArg(LearnersArg, MethodArg);
        end
        
        function Args = updateArgsFromTable(this, FitFunctionArgs, XTable)
            % Need to separate the Ensemble args from the weak learner
            % args. Weak learner params get put into a new 'Learner' arg.
            EnsembleXTable = getEnsembleXTable(this, XTable);
            Args = updateArgsFromTable@classreg.learning.paramoptim.BayesoptInfo(this, FitFunctionArgs, EnsembleXTable);
            NewLearnerArgs = updateLearnersArgFromTable(this, Args, XTable);
            Args = [Args, NewLearnerArgs];
        end
    end
    
    methods(Access=protected)
        function NVP = updateLearnersArgFromTable(this, FitFunctionArgs, XTable)
            % Find the argument to the parameter 'Learners' in
            % FitFunctionArgs. Make it a fit template if it's not already
            % one, then substitute values from the XTable into its
            % ModelParams property. Output a new NVP that passes the
            % template.
            import classreg.learning.paramoptim.*
            LearnersArg = classreg.learning.paramoptim.parseArg('Learners', FitFunctionArgs);
            MethodArg = classreg.learning.paramoptim.parseArg('Method', FitFunctionArgs);
            % Make sure we have a template with ModelParams
            Template = templateFromLearnersArg(LearnersArg, MethodArg);
            % Subst model params from table to template
            Template.ModelParams = this.LearnerOptInfo.substModelParams(Template.ModelParams, XTable);
            % Remake the template from just the modelparams. This is
            % necessary because when Method is LogitBoost or GentleBoost,
            % only the mse SplitCriterion can be used. Yet it cannot be
            % passed because this is a classification ensemble. Therefore
            % SplitCriterion must be absent from the Template. But it
            % resides in Template.MakeModelInputArgs, a protected property.
            % So here we set the ModelParams field, the rebuild the
            % Template from it.
            Template = classreg.learning.FitTemplate.makeFromModelParams(Template.ModelParams);
            NVP = {'Learners', Template};
        end
        
        function fcn = createCVF(this)
            fcn = @fitcensembleCVF;
            function XTable = fitcensembleCVF(XTable)
                import classreg.learning.paramoptim.*
                % Apply the weak learner's CVF
                if ~isempty(this.LearnerOptInfo.ConditionalVariableFcn)
                    % Save NumVariablesToSample if it is being optimized.
                    if BayesoptInfo.hasVariables(XTable, {'NumVariablesToSample'})
                        NumVariablesToSample = XTable.NumVariablesToSample;
                    end
                    % Apply weak learner CVF. When using trees, this will
                    % overwrite NumVariablesToSample with a constant value,
                    % NumPredictors.
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
                % Do not pass NumVariablesToSample if Method is not Bag
                if BayesoptInfo.hasVariables(XTable, {'Method', 'NumVariablesToSample'})
                    XTable.NumVariablesToSample(XTable.Method~='Bag') = NaN;
                end
                % Do not pass SplitCriterion if Method is LogitBoost or
                % GentleBoost, because they internally fit regression trees
                % and use 'mse'.
                if BayesoptInfo.hasVariables(XTable, {'Method', 'SplitCriterion'})
                    XTable.SplitCriterion(XTable.Method=='LogitBoost') = '<undefined>';
                    XTable.SplitCriterion(XTable.Method=='GentleBoost') = '<undefined>';
                end
            end
        end
        
        function fcn = createXCF(this)
            fcn = @fitcensembleXCF;
            function TF = fitcensembleXCF(XTable)
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

function Template = templateFromLearnersArg(Learners, Method)
import classreg.learning.paramoptim.*
if isempty(Learners)
    if isempty(Method)
        Learners = templateTree('MaxNumSplits', 10);
    elseif ischar(Method)
        switch lower(Method)
            case 'bag'
                Learners = 'Tree';
            case 'subspace'
                Learners = 'KNN';
            otherwise
                Learners = templateTree('MaxNumSplits', 10);
        end
    else
        classreg.learning.paramoptim.err('BadMethodType');
    end
end
if isa(Learners, 'classreg.learning.FitTemplate')
    Template = fillIfNeeded(Learners, 'classification');
elseif ischar(Learners)
    if prefixMatch(Learners, 'Discriminant')
        Template = templateDiscriminant;
    elseif prefixMatch(Learners, 'KNN')
        Template = templateKNN;
    elseif prefixMatch(Learners, 'Tree')
        Template = templateTree('type','classification');
    else
        classreg.learning.paramoptim.err('BadEnsembleLearner', Learners);
    end
else
    classreg.learning.paramoptim.err('BadLearnerType');
end
end

function EnsembleXTable = getEnsembleXTable(this, XTable)
import classreg.learning.paramoptim.*
% Form an XTable of just the Ensemble vars
CEnsembleNames = {this.CEnsembleVariableDescriptions.Name};
[~, CEnsembleLocs] = ismember(CEnsembleNames, XTable.Properties.VariableNames);
CEnsembleLocs(CEnsembleLocs==0) = [];
EnsembleXTable = XTable(:, CEnsembleLocs);
end

