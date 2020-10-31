classdef BayesoptInfoCNB < classreg.learning.paramoptim.BayesoptInfo
    
%   Copyright 2016 The MathWorks, Inc.
    
    properties
        FitFcn = @fitcnb;
        PrepareDataFcn = @ClassificationNaiveBayes.prepareData;
        AllVariableDescriptions;
    end
    
    methods
        function this = BayesoptInfoCNB(Predictors, Response, FitFunctionArgs)
            this@classreg.learning.paramoptim.BayesoptInfo(Predictors, Response, FitFunctionArgs, false, false);
            MinPredictorDiff = this.MinPredictorDiff;
            if MinPredictorDiff == 0
                MinPredictorDiff = 1;
            end
            MaxPredictorRange = this.MaxPredictorRange;
            if MaxPredictorRange == 0
                MaxPredictorRange = 1;
            end
            this.AllVariableDescriptions = [...
                optimizableVariable('DistributionNames', {'normal', 'kernel'});
                optimizableVariable('Width', [MinPredictorDiff/4, max(MaxPredictorRange, MinPredictorDiff)],...
                                    'Transform', 'log');
                optimizableVariable('Kernel', {'normal', 'box', 'epanechnikov', 'triangle'}, ...
                                    'Optimize', false)];
            this.ConditionalVariableFcn = @fitcnbCVF;
        end
        
        function Args = updateArgsFromTable(this, FitFunctionArgs, XTable)
            import classreg.learning.paramoptim.*
            % Process args normally
            Args = updateArgsFromTable@classreg.learning.paramoptim.BayesoptInfo(this, FitFunctionArgs, XTable);
            % Now overwrite the Distribution arg if necessary. Set
            % categorical predictors to 'mvnn', set others to
            % DistributionNames
            if BayesoptInfo.hasVariables(XTable, {'DistributionNames'}) && any(this.CategoricalPredictorIndices)
                % Pass a cell array of distribution names.
                DNames = repmat({char(XTable.DistributionNames)}, 1, this.NumPredictors);
                DNames(this.CategoricalPredictorIndices) = {'mvmn'};
                XTable.DistributionNames = [];
                ArgsToAppend = {'DistributionNames', DNames};
                Args = [Args, ArgsToAppend];
            end
        end
        
        function VariableDescriptions = getVariableDescriptions(this, OptimizeHyperparametersArg)
            % Issue a warning, advising the user to standardize their numeric
            % data if they're optimizing kernel width.
            % First call the base class method to get the output.
            VariableDescriptions = getVariableDescriptions@classreg.learning.paramoptim.BayesoptInfo(...
                this, OptimizeHyperparametersArg);
            % Now warn
            if optimizingKernelWidth(VariableDescriptions)
                bayesoptim.warn('StandardizeIfOptimizingNBKernelWidth');
            end
        end
    end
end

function XTable = fitcnbCVF(XTable)
% Kernel and Width are only relevant when DistributionNames is 'kernel'
import classreg.learning.paramoptim.*
if BayesoptInfo.hasVariables(XTable, {'DistributionNames', 'Kernel'})
    XTable.Kernel(XTable.DistributionNames ~= 'kernel') = '<undefined>';
end
if BayesoptInfo.hasVariables(XTable, {'DistributionNames', 'Width'})
    XTable.Width(XTable.DistributionNames ~= 'kernel') = NaN;
end
end

function tf = optimizingKernelWidth(VariableDescriptions)
tf = false;
for i = 1:numel(VariableDescriptions)
    if VariableDescriptions(i).Optimize && isequal(VariableDescriptions(i).Name, 'Width')
        tf = true;
        return;
    end
end
end
