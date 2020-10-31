classdef BayesoptInfoCTree < classreg.learning.paramoptim.BayesoptInfo
    
%   Copyright 2016 The MathWorks, Inc.

    
    properties
        FitFcn = @fitctree;
        PrepareDataFcn = @ClassificationTree.prepareData;
        AllVariableDescriptions;
    end
    
    methods
        function this = BayesoptInfoCTree(Predictors, Response, FitFunctionArgs)
            this@classreg.learning.paramoptim.BayesoptInfo(Predictors, Response, FitFunctionArgs, false, false);
            % Configure 'SplitCriterion' variable based on NumClasses
            switch this.NumClasses
                case 2
                    SplitCriterionVar = optimizableVariable('SplitCriterion', {'gdi', 'deviance'}, 'Optimize', false);
                otherwise
                    SplitCriterionVar = optimizableVariable('SplitCriterion', {'gdi', 'twoing', 'deviance'}, 'Optimize', false);
            end
            this.AllVariableDescriptions = [...
                optimizableVariable('MinLeafSize', [1, max(2,floor(this.NumObservations/2))], 'Type', 'integer', 'Transform', 'log');
                optimizableVariable('MaxNumSplits', [1, max(2,this.NumObservations-1)], 'Type', 'integer', 'Transform', 'log', 'Optimize', false);
                SplitCriterionVar;
                optimizableVariable('NumVariablesToSample', [1, max(2,this.NumPredictors)], 'Type', 'integer', 'Optimize', false)];
            this.ModelParamNameMap = struct('MinLeafSize', 'MinLeaf', ...
                                            'MaxNumSplits', 'MaxSplits', ...
                                            'SplitCriterion', 'SplitCriterion', ...
                                            'NumVariablesToSample', 'NVarToSample');
            this.ConditionalVariableFcn = createCVF(this);
        end
    end
    
    methods(Access=protected)
        function fcn = createCVF(this)
            fcn = @fitctreeCVF;
            function XTable = fitctreeCVF(XTable)
                % Always set NumVariablesToSample = NumPredictors. This is
                % here to ensure that single trees will not optimize this
                % parameter, but the parameter will be available for
                % enclosing ensembles to optimize it.
                if classreg.learning.paramoptim.BayesoptInfo.hasVariables(XTable, {'NumVariablesToSample'})
                    XTable.NumVariablesToSample(:) = this.NumPredictors;
                end
            end
        end
    end
end
