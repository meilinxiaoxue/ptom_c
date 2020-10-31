classdef BayesoptInfoCLinear < classreg.learning.paramoptim.BayesoptInfo
    
%   Copyright 2016 The MathWorks, Inc.

    
    properties
        FitFcn = @fitclinear;
        PrepareDataFcn = @ClassificationLinear.prepareData;
        AllVariableDescriptions;
    end
    
    methods
        function this = BayesoptInfoCLinear(Predictors, Response, FitFunctionArgs)
            this@classreg.learning.paramoptim.BayesoptInfo(Predictors, Response, FitFunctionArgs, ...
                classreg.learning.paramoptim.observationsInColumns(FitFunctionArgs), false);
            this.AllVariableDescriptions = [...
                optimizableVariable('Lambda', [(1e-5)/this.NumObservations, (1e5)/this.NumObservations],...
                                    'Transform', 'log');
                optimizableVariable('Learner', {'svm', 'logistic'});
                optimizableVariable('Regularization', {'ridge', 'lasso'}, 'Optimize', false)];
            this.ModelParamNameMap = struct('Lambda', 'Lambda', ...
                                            'Learner', 'Learner', ...
                                            'Regularization', 'Regularization');
            this.CanStoreResultsInModel = false;
            this.OutputArgumentPosition = 3;
        end
    end
end

