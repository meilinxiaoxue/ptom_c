function s = optimoptionsToStruct(obj,objType)
% optimoptionsToStruct - converts an optimoptions object to a struct that is
% compatible for code generation with MATLAB Coder.

% s = optimoptionsToStruct(obj,objtype) takes an optimoptions object,
% and its type, and convets the object into a struct compatible with code
% generation.
% objType can be either 1 for fminunc, or 2 for fmincon.

%   Copyright 2017 The MathWorks, Inc.

s = struct;
commonFieldNames = {'Algorithm','CheckGradients','Display','FiniteDifferenceStepSize',...
    'FiniteDifferenceType','MaxFunctionEvaluations','MaxIterations','ObjectiveLimit',...
    'OptimalityTolerance','SpecifyObjectiveGradient','TypicalX'};

switch objType
    case 1
        % OptimizerOptions is an optimoptions object with fminunc
        % properties.
        
        fminuncFieldNames = [commonFieldNames,'StepTolerance'];        
        for c = 1:numel(fminuncFieldNames)
            s.(fminuncFieldNames{c}) = obj.(fminuncFieldNames{c});
        end        
        
    case 2
        % OptimizerOptions is an optimoptions object with fmincon
        % properties
        
        fminconFieldNames = [commonFieldNames,'ConstraintTolerance','HessianApproximation',...
            'HessianFcn','HonorBounds','ScaleProblem','SpecifyConstraintGradient',...
            'SubproblemAlgorithm','UseParallel'];
        
        for c = 1:numel(fminconFieldNames)
            s.(fminconFieldNames{c}) = obj.(fminconFieldNames{c});
        end
        
        if isempty(obj.HessianMultiplyFcn)
            s.HessianMultiplyFcn = [];
        else
            s.HessianMultiplyFcn  = func2str(obj.HessianMultiplyFcn);
        end  
end

if isempty(obj.OutputFcn)
    s.OutputFcn = [];
else
    s.OutputFcn  = func2str(obj.OutputFcn);
end

if isempty(obj.PlotFcn)
    s.PlotFcn = [];
else
    s.PlotFcn  = func2str(obj.PlotFcn);
end

end