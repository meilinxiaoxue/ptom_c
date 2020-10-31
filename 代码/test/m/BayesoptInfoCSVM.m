classdef BayesoptInfoCSVM < classreg.learning.paramoptim.BayesoptInfo
    
%   Copyright 2016 The MathWorks, Inc.

    properties
        FitFcn = @fitcsvm;
        PrepareDataFcn = @ClassificationSVM.prepareData;
        AllVariableDescriptions = [...
            optimizableVariable('BoxConstraint', [1e-3, 1e3], 'Transform', 'log');
            optimizableVariable('KernelScale', [1e-3, 1e3], 'Transform', 'log');
            optimizableVariable('KernelFunction', {'gaussian', 'linear', 'polynomial'}, ...
                                'Optimize', false);
            optimizableVariable('PolynomialOrder', [2, 4], 'Type', 'integer', ...
                                'Optimize', false);
            optimizableVariable('Standardize', {'true', 'false'}, ...
                                'Optimize', false)];
    end
    
    methods
        function this = BayesoptInfoCSVM(Predictors, Response, FitFunctionArgs)
            this@classreg.learning.paramoptim.BayesoptInfo(Predictors, Response, FitFunctionArgs, false, false);
            this.ModelParamNameMap = struct('BoxConstraint', 'BoxConstraint', ...
                                            'KernelFunction', 'KernelFunction', ...
                                            'KernelScale', 'KernelScale', ...
                                            'PolynomialOrder', 'KernelPolynomialOrder', ...
                                            'Standardize', 'StandardizeData');
            this.ConditionalVariableFcn = createCVF(this);
        end
    end
end

function fcn = createCVF(this)
fcn = @fitcsvmCVF;
    function XTable = fitcsvmCVF(XTable)
        % PolynomialOrder is irrelevant if KernelFunction~='polynomial'
        if classreg.learning.paramoptim.BayesoptInfo.hasVariables(XTable, {'PolynomialOrder', 'KernelFunction'})
            XTable.PolynomialOrder(XTable.KernelFunction ~= 'polynomial') = NaN;
        end
        % KernelScale is irrelevant if KernelFunction~='rbf' or 'gaussian'
        if classreg.learning.paramoptim.BayesoptInfo.hasVariables(XTable, {'KernelScale', 'KernelFunction'})
            XTable.KernelScale(~ismember(XTable.KernelFunction, {'rbf','gaussian'})) = NaN;
        end
        % BoxConstraint must be 1 if NumClasses==1 in a fold
        if this.NumClasses==1 && classreg.learning.paramoptim.BayesoptInfo.hasVariables(XTable, {'BoxConstraint'})
            XTable.BoxConstraint(:) = 1;
        end
    end
end