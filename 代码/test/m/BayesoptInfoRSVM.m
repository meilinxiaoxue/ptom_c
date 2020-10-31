classdef BayesoptInfoRSVM < classreg.learning.paramoptim.BayesoptInfo
    
%   Copyright 2016 The MathWorks, Inc.

    
    properties
        FitFcn = @fitrsvm;
        PrepareDataFcn = @RegressionSVM.prepareData;
        AllVariableDescriptions;
    end
    
    methods
        function this = BayesoptInfoRSVM(Predictors, Response, FitFunctionArgs)
            this@classreg.learning.paramoptim.BayesoptInfo(Predictors, Response, FitFunctionArgs, false, true);
            ResponseIqr = this.ResponseIqr;
            if ResponseIqr == 0
                ResponseIqr = 1;
            end
            this.AllVariableDescriptions = [...
                optimizableVariable('BoxConstraint', [1e-3, 1e3], 'Transform', 'log');
                optimizableVariable('KernelScale', [1e-3, 1e3], 'Transform', 'log');
                optimizableVariable('Epsilon', [1e-3*ResponseIqr/1.349, 1e2*ResponseIqr/1.349], ...
                'Transform', 'log');
                optimizableVariable('KernelFunction', {'gaussian', 'linear', 'polynomial'}, 'Optimize', false);
                optimizableVariable('PolynomialOrder', [2, 4], 'Type', 'integer', 'Optimize', false);
                optimizableVariable('Standardize', {'true', 'false'}, 'Optimize', false)];
            this.ConditionalVariableFcn = @fitrsvmCVF;
        end
    end
end

function XTable = fitrsvmCVF(XTable)
% KernelScale is irrelevant if KernelFunction~='rbf' or 'gaussian'
if classreg.learning.paramoptim.BayesoptInfo.hasVariables(XTable, {'KernelScale', 'KernelFunction'})
    XTable.KernelScale(~ismember(XTable.KernelFunction, {'rbf','gaussian'})) = NaN;
end
% PolynomialOrder is irrelevant if KernelFunction~='polynomial'
if classreg.learning.paramoptim.BayesoptInfo.hasVariables(XTable, {'PolynomialOrder', 'KernelFunction'})
    XTable.PolynomialOrder(XTable.KernelFunction ~= 'polynomial') = NaN;
end
end
