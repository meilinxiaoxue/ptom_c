classdef BayesoptInfoCDiscr < classreg.learning.paramoptim.BayesoptInfo
    
%   Copyright 2016 The MathWorks, Inc.

    properties
        FitFcn = @fitcdiscr;
        PrepareDataFcn = @ClassificationDiscriminant.prepareData;
        AllVariableDescriptions = [...
            optimizableVariable('Delta', [1e-6 1e3], 'Transform', 'log');
            optimizableVariable('Gamma', [0 1]);
            optimizableVariable('DiscrimType', {'linear', 'quadratic', ...
                'diagLinear', 'diagQuadratic', 'pseudoLinear', ...
                'pseudoQuadratic'}, 'Optimize', false)];
    end
    
    methods
        function this = BayesoptInfoCDiscr(Predictors, Response, FitFunctionArgs)
            this@classreg.learning.paramoptim.BayesoptInfo(Predictors, Response, FitFunctionArgs, false, false);
            this.ModelParamNameMap = struct('Delta', 'Delta', ...
                                            'Gamma', 'Gamma', ...
                                            'DiscrimType', 'DiscrimType');
            this.ConditionalVariableFcn = @fitcdiscrCVF;
        end
    end
end

function XTable = fitcdiscrCVF(XTable)
import classreg.learning.paramoptim.*
% Do not pass Delta if discrim type is a quadratic
if BayesoptInfo.hasVariables(XTable, {'Delta', 'DiscrimType'})
    XTable.Delta(ismember(XTable.DiscrimType, {'quadratic', ...
        'diagQuadratic', 'pseudoQuadratic'})) = NaN;
end
% Gamma must be 0 if discrim type is a quadratic
if BayesoptInfo.hasVariables(XTable, {'Gamma', 'DiscrimType'})
    XTable.Gamma(ismember(XTable.DiscrimType, {'quadratic', ...
        'diagQuadratic', 'pseudoQuadratic'})) = 0;
end
end
