function obj = optimoptionsFromStruct(s,objType)
% optimoptionsFromStruct - reconstructs an optimoptions object using
% properties specified in the input struct.

% obj = optimoptionsFromStruct(s) takes a codegen-compatible struct, s, and
% its type, objType, and reconstructs the corresponding optimoptions object.
% objType can be either 1 for fminunc, or 2 for fmincon.

%   Copyright 2017 The MathWorks, Inc.

commonFieldNames = {'Algorithm','CheckGradients','Display',...
    'FiniteDifferenceType','MaxIterations','ObjectiveLimit',...
    'OptimalityTolerance','SpecifyObjectiveGradient'};

switch objType
    case 1
        % OptimizerOptions is an optimoptions object with fminunc
        % properties
        
        obj = optimoptions('fminunc');
        
        fminuncFieldNames = [commonFieldNames,'StepTolerance'];        
        for c = 1:numel(fminuncFieldNames)
            obj.(fminuncFieldNames{c}) = s.(fminuncFieldNames{c});
        end
        
    case 2
        % OptimizerOptions is an optimoptions object with fmincon
        % properties
        obj = optimoptions('fmincon');
        
        fminconFieldNames = [commonFieldNames,'ConstraintTolerance','HessianApproximation',...
            'HessianFcn','HonorBounds','ScaleProblem','SpecifyConstraintGradient',...
            'SubproblemAlgorithm','UseParallel'];
        
        for c = 1:numel(fminconFieldNames)
            obj.(fminconFieldNames{c}) = s.(fminconFieldNames{c});
        end
        
        if isempty(s.HessianMultiplyFcn)
            obj.HessianMultiplyFcn = [];
        else
            obj.HessianMultiplyFcn  = str2func(s.HessianMultiplyFcn);
        end       
end

% Common field names that need special treatmet
% Anonymous functions
if isempty(s.OutputFcn)
    obj.OutputFcn = [];
else
    obj.OutputFcn  = str2func(s.OutputFcn);
end

if isempty(s.PlotFcn)
    obj.PlotFcn = [];
else
    obj.PlotFcn  = str2func(s.PlotFcn);
end

% These fields are initialized with char arrays (for example, 'sqrt(eps)') 
% but can only be assigned numeric values
if isnumeric(s.FiniteDifferenceStepSize)
    obj.FiniteDifferenceStepSize = s.FiniteDifferenceStepSize;
end

if isnumeric(s.MaxFunctionEvaluations)
    obj.MaxFunctionEvaluations = s.MaxFunctionEvaluations;
end

end