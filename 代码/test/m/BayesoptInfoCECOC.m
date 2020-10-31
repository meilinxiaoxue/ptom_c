classdef BayesoptInfoCECOC < classreg.learning.paramoptim.BayesoptInfo
    
%   Copyright 2016 The MathWorks, Inc.

    
    properties(Constant)
        ECOCVariableDescriptions = optimizableVariable('Coding', {'onevsall', 'onevsone'});
    end
    
    properties
        FitFcn = @fitcecoc;
        PrepareDataFcn = @ClassificationECOC.prepareData;
        AllVariableDescriptions;
    end
    
    properties(Access=protected)
        LearnerOptInfo;
        % A template for the weak learner that has ModelParams
        WeakLearnerTemplate;
    end
    
    methods
        function this = BayesoptInfoCECOC(Predictors, Response, FitFunctionArgs)
            this@classreg.learning.paramoptim.BayesoptInfo(Predictors, Response, FitFunctionArgs, false, false);
            % Get BOInfo for the weak learner
            this.WeakLearnerTemplate = getWeakLearnerTemplate(this, FitFunctionArgs);
            switch this.WeakLearnerTemplate.Method
                case 'Discriminant'
                    BOInfoFcn = @classreg.learning.paramoptim.BayesoptInfoCDiscr;
                case 'KNN'
                    BOInfoFcn = @classreg.learning.paramoptim.BayesoptInfoCKNN;
                case 'Linear'
                    BOInfoFcn = @classreg.learning.paramoptim.BayesoptInfoCLinear;
                case 'SVM'
                    BOInfoFcn = @classreg.learning.paramoptim.BayesoptInfoCSVM;
                case 'Tree'
                    BOInfoFcn = @classreg.learning.paramoptim.BayesoptInfoCTree;
                otherwise
                    classreg.learning.paramoptim.err('BadTemplate', this.WeakLearnerTemplate.Method);
            end
            this.LearnerOptInfo = BOInfoFcn(Predictors, Response, FitFunctionArgs);
            % Concatenate ensemble vars and weak learner vars
            this.AllVariableDescriptions = [...
                classreg.learning.paramoptim.BayesoptInfoCECOC.ECOCVariableDescriptions;
                this.LearnerOptInfo.AllVariableDescriptions];
            this.ConditionalVariableFcn = this.LearnerOptInfo.ConditionalVariableFcn;
            % CompactLinearECOC cannot store optimization results:
            if isequal(this.WeakLearnerTemplate.Method, 'Linear')
                this.CanStoreResultsInModel = false;
            end
        end
        
        function Template = getWeakLearnerTemplate(this, FitFunctionArgs)
            LearnersArg = classreg.learning.paramoptim.parseArg('Learners', FitFunctionArgs);
            Template = templateFromLearnersArg(LearnersArg);
        end
                
        function Args = updateArgsFromTable(this, FitFunctionArgs, XTable)
            % Need to separate the ECOC args from the weak learner args.
            % Weak learner params get put into a new 'Learner' arg.
            ECOCXTable = getECOCXTable(XTable);
            Args = updateArgsFromTable@classreg.learning.paramoptim.BayesoptInfo(this, FitFunctionArgs, ECOCXTable);
            NewLearnerArg = updateLearnerArgFromTable(this, FitFunctionArgs, 'Learners', XTable);
            Args = [Args, NewLearnerArg];
        end
    end
    
    methods(Access=protected)
        function NVP = updateLearnerArgFromTable(this, FitFunctionArgs, ArgName, XTable)
            % Find the argument to the parameter 'ArgName' in FitFunctionArgs.
            % Make it a fit template if it's not already one, then
            % substitute values from the XTable into its ModelParams
            % property. Output a new NVP that passes the template.
            import classreg.learning.paramoptim.*
            Value = parseArg(ArgName, FitFunctionArgs);
            if isempty(Value)
                % No 'Learners' arg was passed. Default to 'SVM'
                Value = 'SVM';
            end
            % Make sure we have a template with ModelParams
            Template = templateFromLearnersArg(Value);
            % Subst model params from table to template
            Template.ModelParams = this.LearnerOptInfo.substModelParams(Template.ModelParams, XTable);
            NVP = {ArgName, Template};
        end
    end
end

function Template = templateFromLearnersArg(Value)
import classreg.learning.paramoptim.*
if isempty(Value)
    Value = 'SVM';
end
if isa(Value, 'classreg.learning.FitTemplate')
    Template = fillIfNeeded(Value, 'classification');
elseif ischar(Value)
    if prefixMatch(Value, 'Discriminant')
        Template = templateDiscriminant;
    elseif prefixMatch(Value, 'KNN')
        Template = templateKNN;
    elseif prefixMatch(Value, 'Linear')
        Template = templateLinear;
    elseif prefixMatch(Value, 'SVM')
        Template = templateSVM;
    elseif prefixMatch(Value, 'Tree')
        Template = templateTree('type','classification');
    else
        classreg.learning.paramoptim.err('BadECOCLearner', Value);
    end
else
    classreg.learning.paramoptim.err('BadLearnerType');
end
end

function ECOCTable = getECOCXTable(XTable)
import classreg.learning.paramoptim.*
% Form an XTable of just the ECOC vars
ECOCNames = {BayesoptInfoCECOC.ECOCVariableDescriptions.Name};
[~, ECOCLocs] = ismember(ECOCNames, XTable.Properties.VariableNames);
ECOCLocs(ECOCLocs==0) = [];
ECOCTable = XTable(:, ECOCLocs);
end


