classdef BayesoptInfoRGP < classreg.learning.paramoptim.BayesoptInfo
    
%   Copyright 2016 The MathWorks, Inc.
    
    properties
        FitFcn = @fitrgp;
        PrepareDataFcn = @RegressionGP.prepareData;
        AllVariableDescriptions;
    end
    
    methods
        function this = BayesoptInfoRGP(Predictors, Response, FitFunctionArgs)
            this@classreg.learning.paramoptim.BayesoptInfo(Predictors, Response, FitFunctionArgs, false, true);
            MaxPredictorRange = this.MaxPredictorRange;
            if MaxPredictorRange == 0
                MaxPredictorRange = 1;
            end
            this.AllVariableDescriptions = [...
                optimizableVariable('Sigma', [1e-4, max(1e-3,10*this.ResponseStd)], 'Transform', 'log');
                optimizableVariable('BasisFunction', {'constant', 'none', 'linear', 'pureQuadratic'},...
                                    'Optimize', false);
                optimizableVariable('KernelFunction', {'ardexponential','ardmatern32',...
                'ardmatern52','ardrationalquadratic','ardsquaredexponential',...
                'exponential','matern32','matern52','rationalquadratic','squaredexponential'},...
                                    'Optimize', false);
                optimizableVariable('KernelScale', [1e-3*MaxPredictorRange, MaxPredictorRange],...
                                    'Transform', 'log', ...
                                    'Optimize', false); 
                optimizableVariable('Standardize', {'true', 'false'}, ...
                                    'Optimize', false)];
            this.ConditionalVariableFcn = @fitrgpCVF;
        end
    end
    
    methods
        function Args = updateArgsFromTable(this, FitFunctionArgs, XTable)
            import classreg.learning.paramoptim.*
            NewArgs = {};
         	% If KernelScale is being optimized, pass initial values and
            % ConstantKernelParameters, and remove KernelScale from table
            if BayesoptInfo.hasVariables(XTable, {'KernelScale'}) && ~isnan(XTable.KernelScale)
                [KernelParameters, ConstantKernelParameters] = kernelParamArgsForKernel(...
                    FitFunctionArgs, XTable);
                NewArgs = [NewArgs, {'KernelParameters', KernelParameters, ...
                                     'ConstantKernelParameters', ConstantKernelParameters}];
                XTable.KernelScale = [];
            end
            % If Sigma is being optimized, append new Sigma and
            % ConstantSigma arguments, and remove Sigma from table
            if BayesoptInfo.hasVariables(XTable, {'Sigma'}) && ~isnan(XTable.Sigma)
                NewArgs = [NewArgs, {'Sigma', prepareArgValue(XTable.Sigma), ...
                                     'ConstantSigma', true}];
                XTable.Sigma = [];
            end
            % Process remaining args in the table normally
            NormalArgs = updateArgsFromTable@classreg.learning.paramoptim.BayesoptInfo(this, FitFunctionArgs, XTable);
            % Remove KernelParameters from NormalArgs if we're optimizing
            % Kernelscale and it's NaN
            if BayesoptInfo.hasVariables(XTable, {'KernelScale'}) && isnan(XTable.KernelScale)
                NormalArgs = deleteKernelParametersArg(NormalArgs);
            end
            % Put NewArgs last to override.
            Args = [NormalArgs, NewArgs]; 
        end
    end
end

function XTable = fitrgpCVF(XTable)
% Set KernelScale to NaN when KernelFunction is any ARD kernel.
if classreg.learning.paramoptim.BayesoptInfo.hasVariables(XTable, {'KernelFunction', 'KernelScale'})
    ARDRows = ismember(XTable.KernelFunction, {'ardexponential','ardmatern32',...
        'ardmatern52','ardrationalquadratic','ardsquaredexponential'});
    XTable.KernelScale(ARDRows) = NaN;
end
end

function Args = deleteKernelParametersArg(Args)
% Delete 'KernelParameters' and its value from Args
NameLocs = find(cellfun(@(P)classreg.learning.paramoptim.prefixMatch(P,'KernelParameters'), ...
                        Args(1:2:end)));
NVPLocs = [2*NameLocs-1, 2*NameLocs];
Args(NVPLocs) = [];
end

function [KernelParameters, ConstantKernelParameters] = kernelParamArgsForKernel(...
    FitFunctionArgs, XTable)
% Assumes XTable.KernelScale exists. Create a kernelParameters vector and a
% ConstantKernelParameters vector suitable for use with the selected kernel
% function. The kernel function may be specified in XTable,
% FitFunctionArgs, or neither. if neither, assume the default
% KernelParameters layout of [kernelscale, sigma].
import classreg.learning.paramoptim.*

% Find KernelFunction argument
KernelFunction = '';
if classreg.learning.paramoptim.BayesoptInfo.hasVariables(XTable, {'KernelFunction'}) && ...
        ~isundefined(XTable.KernelFunction)
    KernelFunction = XTable.KernelFunction;
else
    % Find it in FitFunctionArgs
    string = 'kernelf';
    KFLoc = find(cellfun(@(t)strncmpi(string, t, numel(string)), lower(FitFunctionArgs(1:2:end))));
    if ~isempty(KFLoc)
        KernelFunction = FitFunctionArgs{KFLoc*2};
    end
end
% Set kernel parameters
switch KernelFunction
    case 'rationalquadratic'
        KernelParameters = [prepareArgValue(XTable.KernelScale); 1; 1];
        ConstantKernelParameters = [true; false; false];
    otherwise
        KernelParameters = [prepareArgValue(XTable.KernelScale); 1];
        ConstantKernelParameters = [true; false];
end
end
            