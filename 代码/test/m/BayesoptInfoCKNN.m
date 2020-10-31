classdef BayesoptInfoCKNN < classreg.learning.paramoptim.BayesoptInfo
    
%   Copyright 2016 The MathWorks, Inc.

    
    properties
        FitFcn = @fitcknn;
        PrepareDataFcn = @ClassificationKNN.prepareData;
        AllVariableDescriptions;
    end
    
    methods
        function this = BayesoptInfoCKNN(Predictors, Response, FitFunctionArgs)
            this@classreg.learning.paramoptim.BayesoptInfo(Predictors, Response, FitFunctionArgs, false, false);
            this.AllVariableDescriptions = [...
                optimizableVariable('NumNeighbors', [1, max(2,round(this.NumObservations/2))], ...
                                    'Type', 'integer', 'Transform', 'log');
                optimizableVariable('Distance', {'cityblock', 'chebychev', 'correlation', 'cosine', ...
                                    'euclidean', 'hamming', 'jaccard', 'mahalanobis', 'minkowski', ...
                                    'seuclidean', 'spearman'});
                optimizableVariable('DistanceWeight', {'equal', 'inverse', 'squaredinverse'}, ...
                                    'Optimize', false);
                optimizableVariable('Exponent', [.5, 3], 'Optimize', false);
                optimizableVariable('Standardize', {'true', 'false'}, ...
                                    'Optimize', false)];
            this.ModelParamNameMap = struct('Distance', 'Distance',...
                                            'DistanceWeight', 'DistanceWeight',...
                                            'Exponent', 'Exponent',...
                                            'NumNeighbors', 'NumNeighbors',...
                                            'Standardize', 'StandardizeData');
            this.ConditionalVariableFcn = @fitcknnCVF;
            this.XConstraintFcn = @fitcknnXCF;
        end
    end
end

function XTable = fitcknnCVF(XTable)
% Exponent is irrelevant unless Distance is minkowski
import classreg.learning.paramoptim.*
if BayesoptInfo.hasVariables(XTable, {'Exponent', 'Distance'})
    XTable.Exponent(XTable.Distance ~= 'minkowski') = NaN;
end
end

function TF = fitcknnXCF(XTable)
% When Standardize=true, prohibit seuclidean and mahalanobis, because the
% result is the same when Standardize=false.
if classreg.learning.paramoptim.BayesoptInfo.hasVariables(XTable, {'Standardize', 'Distance'})
    TF = ~(XTable.Standardize=='true' & ismember(XTable.Distance, {'seuclidean', 'mahalanobis'}));
else
    TF = true(height(XTable),1);
end
end
