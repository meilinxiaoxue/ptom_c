classdef GPParams < classreg.learning.modelparams.ModelParams
%GPParams Parameters for Gaussian Process Regression.
%
%   GPParams properties:
%
%       KernelFunction           - Kernel function specifying the Gaussian Process covariance.
%       KernelParameters         - Parameters for the kernel function.
%       BasisFunction            - Basis function to generate the explicit basis matrix.
%       Beta                     - Coefficients of the explicit basis matrix.
%       Sigma                    - Noise standard deviation.
%       FitMethod                - Chosen fit method: 'none','exact','sd','sr' or 'fic'.
%       PredictMethod            - Chosen prediction method: 'exact','bcd','sd','sr','fic'.
%       ActiveSet                - Logical vector containing a user specified active set.
%       ActiveSetSize            - Chosen size of the active set.
%       ActiveSetMethod          - Chosen active set selection method: 'sgma','entropy',
%                                  'likelihood' or 'random'.
%       Standardize              - True for standardizing training data in predictor
%                                  matrix X to zero mean and unit variance.
%       Verbose                  - Verbosity level: 0,1 or 2.
%       CacheSize                - Size of the cache in MB.
%       Options                  - Structure containing additional fitting options.
%       Optimizer                - Name of the optimizer: 'fminsearch','quasinewton',
%                                  'lbfgs', 'fminunc' or 'fmincon'.
%       OptimizerOptions         - A structure or object containing optimizer options.
%       ConstantKernelParameters - A logical vector indicating which kernel parameters
%                                  should be held constant during fitting.
%       ConstantSigma            - A scalar logical specifying whether the 'Sigma'
%                                  parameter should be held constant during
%                                  fitting.
%       InitialStepSize          - A positive scalar specifying the initial step
%                                  size for optimization with quasinewton and lbfgs
%                                  optimizers. This can also be specified as string
%                                  'auto'.
    
%   Copyright 2014-2017 The MathWorks, Inc.

    properties(Constant,Hidden)
        Exponential            = 'Exponential';
        ExponentialARD         = 'ARDExponential';
        SquaredExponential     = 'SquaredExponential';
        SquaredExponentialARD  = 'ARDSquaredExponential';
        Matern32               = 'Matern32';
        Matern32ARD            = 'ARDMatern32';
        Matern52               = 'Matern52';
        Matern52ARD            = 'ARDMatern52';
        RationalQuadratic      = 'RationalQuadratic';
        RationalQuadraticARD   = 'ARDRationalQuadratic';
        CustomKernel           = 'CustomKernel';
        BuiltInKernelFunctions = {classreg.learning.modelparams.GPParams.Exponential,...
                                  classreg.learning.modelparams.GPParams.ExponentialARD,...
                                  classreg.learning.modelparams.GPParams.SquaredExponential,...
                                  classreg.learning.modelparams.GPParams.SquaredExponentialARD,...
                                  classreg.learning.modelparams.GPParams.Matern32,...
                                  classreg.learning.modelparams.GPParams.Matern32ARD,...
                                  classreg.learning.modelparams.GPParams.Matern52,...
                                  classreg.learning.modelparams.GPParams.Matern52ARD,...
                                  classreg.learning.modelparams.GPParams.RationalQuadratic,...
                                  classreg.learning.modelparams.GPParams.RationalQuadraticARD};
    end

    properties(Constant,Hidden)
        BasisNone             = 'None';
        BasisConstant         = 'Constant';
        BasisLinear           = 'Linear';
        BasisPureQuadratic    = 'PureQuadratic';
        BuiltInBasisFunctions = {classreg.learning.modelparams.GPParams.BasisNone,...
                                 classreg.learning.modelparams.GPParams.BasisConstant,...
                                 classreg.learning.modelparams.GPParams.BasisLinear,...
                                 classreg.learning.modelparams.GPParams.BasisPureQuadratic};        
    end
    
    properties(Constant,Hidden)
        FitMethodNone     = 'None';
        FitMethodExact    = 'Exact';
        FitMethodSD       = 'SD';
        FitMethodFIC      = 'FIC';
        FitMethodSR       = 'SR';
        BuiltInFitMethods = {classreg.learning.modelparams.GPParams.FitMethodNone,...
                             classreg.learning.modelparams.GPParams.FitMethodExact,...
                             classreg.learning.modelparams.GPParams.FitMethodSD,...
                             classreg.learning.modelparams.GPParams.FitMethodFIC,...
                             classreg.learning.modelparams.GPParams.FitMethodSR};        
    end
    
    properties(Constant,Hidden)
        PredictMethodExact = 'Exact';
        PredictMethodBCD   = 'BCD';
        PredictMethodSD    = 'SD';
        PredictMethodFIC   = 'FIC';
        PredictMethodSR    = 'SR';
        BuiltInPredictMethods = {classreg.learning.modelparams.GPParams.PredictMethodExact,...
                                 classreg.learning.modelparams.GPParams.PredictMethodBCD,...
                                 classreg.learning.modelparams.GPParams.PredictMethodSD,...
                                 classreg.learning.modelparams.GPParams.PredictMethodFIC,...
                                 classreg.learning.modelparams.GPParams.PredictMethodSR};
    end
    
    properties(Constant,Hidden)       
        ActiveSetMethodSGMA            = 'SGMA';
        ActiveSetMethodEntropy         = 'Entropy';
        ActiveSetMethodLikelihood      = 'Likelihood';
        ActiveSetMethodRandom          = 'Random';
        BuiltInActiveSetMethods        = {classreg.learning.modelparams.GPParams.ActiveSetMethodSGMA,...
                                          classreg.learning.modelparams.GPParams.ActiveSetMethodEntropy,...
                                          classreg.learning.modelparams.GPParams.ActiveSetMethodLikelihood,...
                                          classreg.learning.modelparams.GPParams.ActiveSetMethodRandom};
    end
    
    properties(Constant,Hidden)
        OptimizerFminunc     = 'fminunc';
        OptimizerFmincon     = 'fmincon';
        OptimizerFminsearch  = 'fminsearch';
        OptimizerQuasiNewton = 'quasinewton';
        OptimizerLBFGS       = 'lbfgs';
        BuiltInOptimizers    = {classreg.learning.modelparams.GPParams.OptimizerFminunc,...
                               classreg.learning.modelparams.GPParams.OptimizerFmincon,...
                               classreg.learning.modelparams.GPParams.OptimizerFminsearch,...
                               classreg.learning.modelparams.GPParams.OptimizerQuasiNewton,...
                               classreg.learning.modelparams.GPParams.OptimizerLBFGS};
    end
    
    properties(Constant,Hidden)
        DistanceMethodFast     = 'Fast';
        DistanceMethodAccurate = 'Accurate';
        BuiltInDistanceMethods = {classreg.learning.modelparams.GPParams.DistanceMethodFast,...
                                 classreg.learning.modelparams.GPParams.DistanceMethodAccurate};
    end
    
    properties(Constant,Hidden)
        ComputationMethodQR = 'QR';
        ComputationMethodV  = 'V';
        BuiltInComputationMethods = {classreg.learning.modelparams.GPParams.ComputationMethodQR,...
                                    classreg.learning.modelparams.GPParams.ComputationMethodV};
    end
    
    properties(Constant,Hidden)
        StringAuto = 'auto';
    end
    
    properties        
        KernelFunction   = [];
        KernelParameters = [];
        BasisFunction    = [];
        Beta             = [];
        Sigma            = [];
        FitMethod        = [];
        PredictMethod    = [];
        ActiveSet        = [];
        ActiveSetSize    = [];
        ActiveSetMethod  = [];             
        Standardize      = [];
        Verbose          = [];
        CacheSize        = [];
        Options          = [];
        Optimizer        = [];
        OptimizerOptions = [];        
        ConstantKernelParameters = [];
        ConstantSigma    = [];
        InitialStepSize  = [];
    end
    
    methods(Access=protected)       
        function this = GPParams(...
            kernelFunction,...
            kernelParameters,...
            basisFunction,...
            beta,...
            sigma,...
            fitMethod,...
            predictMethod,...
            activeSet,...
            activeSetSize,...
            activeSetMethod,...                       
            standardize,...
            verbose,...
            cacheSize,...
            options,...
            optimizer,...
            optimizerOptions,...
            constantKernelParameters,...
            constantSigma,...
            initialStepSize)
                 
            this = this@classreg.learning.modelparams.ModelParams('GP','regression');
        
            this.KernelFunction   = kernelFunction;
            this.KernelParameters = kernelParameters;
            this.BasisFunction    = basisFunction;
            this.Beta             = beta;
            this.Sigma            = sigma;
            this.FitMethod        = fitMethod;
            this.PredictMethod    = predictMethod;
            this.ActiveSet        = activeSet;
            this.ActiveSetSize    = activeSetSize;
            this.ActiveSetMethod  = activeSetMethod;                        
            this.Standardize      = standardize;
            this.Verbose          = verbose;
            this.CacheSize        = cacheSize;
            this.Options          = options;
            this.Optimizer        = optimizer;
            this.OptimizerOptions = optimizerOptions;    
            this.ConstantKernelParameters = constantKernelParameters;
            this.ConstantSigma    = constantSigma;
            this.InitialStepSize  = initialStepSize;
        end
    end
    
    methods(Static,Hidden)    
        function [holder,extraArgs] = make(type,varargin)   %#ok<INUSL>
            % 1. Decode input args.
            paramNames = {'KernelFunction',...
                'KernelParameters',...
                'BasisFunction',...
                'Beta',...
                'Sigma',...
                'FitMethod',...
                'PredictMethod',...
                'ActiveSet',...
                'ActiveSetSize',...
                'ActiveSetMethod',...
                'Standardize',...
                'Verbose',...
                'CacheSize',...
                'Regularization',...
                'SigmaLowerBound',...
                'RandomSearchSetSize',...
                'ToleranceActiveSet',...
                'NumActiveSetRepeats',...
                'BlockSizeBCD',...
                'NumGreedyBCD',...
                'ToleranceBCD',...
                'StepToleranceBCD',...
                'IterationLimitBCD',...
                'DistanceMethod',...
                'ComputationMethod',...
                'Optimizer',...
                'OptimizerOptions',...
                'ConstantKernelParameters',...
                'ConstantSigma',...
                'InitialStepSize'};
            paramDflts = {[],...
                [],...
                [],...
                [],...
                [],...
                [],...
                [],...
                [],...
                [],...
                [],...
                [],...
                [],...
                [],...
                [],...
                [],...
                [],...
                [],...
                [],...
                [],...
                [],...
                [],...
                [],...
                [],...
                [],...
                [],...
                [],...
                [],...
                []};
            
            [kernelFunction,...
                kernelParameters,...
                basisFunction,...
                beta,...
                sigma,...
                fitMethod,...
                predictMethod,...
                activeSet,...
                activeSetSize,...
                activeSetMethod,...
                standardize,...
                verbose,...
                cacheSize,...
                regularization,...
                sigmaLowerBound,...
                randomSearchSetSize,...
                toleranceActiveSet,...
                numActiveSetRepeats,...
                blockSizeBCD,...
                numGreedyBCD,...
                toleranceBCD,...
                stepToleranceBCD,...
                iterationLimitBCD,...
                distanceMethod,...
                computationMethod,...
                optimizer,...
                optimizerOptions,...
                constantKernelParameters,...
                constantSigma,...
                initialStepSize,...
                ~,...
                extraArgs] = internal.stats.parseArgs(paramNames,paramDflts,varargin{:});
            
            % 2. Check input argument type for non-empty arguments.
            
                import classreg.learning.modelparams.GPParams;
            
                % 2.1 KernelFunction.
                % Require: A function handle or string to function on path 
                %          or a string in BuiltInKernelFunctions. In either
                %          case, kernelFunction should be a string for
                %          built-in kernel functions or a function handle
                %          after this point.
                if ~isempty(kernelFunction)
                    [isok,kernelFunction,isfuncstr] = GPParams.validateStringOrFunctionHandle(kernelFunction,GPParams.BuiltInKernelFunctions);
                    if ~isok                        
                        str = strjoin(GPParams.BuiltInKernelFunctions,', ');
                        error(message('stats:classreg:learning:modelparams:GPParams:make:BadKernelFunction',str));
                    end
                    if isfuncstr
                        name           = kernelFunction;
                        kernelFunction = @(XM,XN,THETA) feval(name,XM,XN,THETA);
                    end
                end
                
                % 2.2 KernelParameters.                
                % Require: A numeric, real vector, no NaN or Infs. 
                if ~isempty(kernelParameters)
                    [isok,kernelParameters] = GPParams.isNumericRealVectorNoNaNInf(kernelParameters,[]);                    
                    if ~isok
                        error(message('stats:classreg:learning:modelparams:GPParams:make:BadKernelParameters'));
                    end
                end
                
                % 2.3 BasisFunction.
                % Require: A function handle or string to function on path 
                %          or a string in BuiltInBasisFunctions. In either
                %          case, basisFunction should be a string for
                %          built-in basis functions or a function handle
                %          after this point.
                if ~isempty(basisFunction)
                    [isok,basisFunction,isfuncstr] = GPParams.validateStringOrFunctionHandle(basisFunction,GPParams.BuiltInBasisFunctions);                                                    
                    if ~isok                        
                        str = strjoin(GPParams.BuiltInBasisFunctions,', ');
                        error(message('stats:classreg:learning:modelparams:GPParams:make:BadBasisFunction',str));
                    end
                    if isfuncstr
                        name          = basisFunction;
                        basisFunction = @(XM) feval(name,XM);
                    end
                end
                
                % 2.4 Beta.
                % Require: A numeric, real vector, no NaN or Infs.
                if ~isempty(beta)
                    [isok,beta] = GPParams.isNumericRealVectorNoNaNInf(beta,[]);
                    if ~isok
                        error(message('stats:classreg:learning:modelparams:GPParams:make:BadBeta'));
                    end
                end
                
                % 2.5 Sigma.
                % Require: A positive, numeric, real scalar, no NaN or Inf.
                if ~isempty(sigma)
                    [isok,sigma] = GPParams.isNumericRealVectorNoNaNInf(sigma,1);
                    isok = isok && (sigma > 0);
                    if ~isok
                        error(message('stats:classreg:learning:modelparams:GPParams:make:BadSigma'));
                    end
                end
                
                % 2.6 FitMethod.
                % Require: A string that is one of BuiltInFitMethods.
                if ~isempty(fitMethod)                    
                    fitMethod = internal.stats.getParamVal(fitMethod,GPParams.BuiltInFitMethods,'FitMethod');
                end
                
                % 2.7 PredictMethod.
                % Require: A string that is one of BuiltInPredictMethods.
                if ~isempty(predictMethod)
                    predictMethod = internal.stats.getParamVal(predictMethod,GPParams.BuiltInPredictMethods,'PredictMethod');
                end
                
                % 2.8 ActiveSet.
                % Require: An array of positive integers with no duplicate elements or a logical vector with at least one true element.
                if ~isempty(activeSet)
                    if islogical(activeSet)
                        if ~any(activeSet)
                            error(message('stats:classreg:learning:modelparams:GPParams:make:BadActiveSet'));
                        end
                    else
                        [isok,activeSet] = GPParams.isNumericRealVectorNoNaNInf(activeSet,[]);
                        isok = isok && internal.stats.isIntegerVals(activeSet,1) && length(activeSet) == length(unique(activeSet));                    
                        if ~isok
                            error(message('stats:classreg:learning:modelparams:GPParams:make:BadActiveSet'));
                        end
                    end
                end
                
                % 2.9 ActiveSetSize.
                % Require: An integer >= 1.
                if ~isempty(activeSetSize)
                    [isok,activeSetSize] = GPParams.isNumericRealVectorNoNaNInf(activeSetSize,1);
                    isok                 = isok && internal.stats.isIntegerVals(activeSetSize,1);
                    if ~isok
                        error(message('stats:classreg:learning:modelparams:GPParams:make:BadActiveSetSize'));
                    end
                end
                
                % 2.10 ActiveSetMethod.
                % Require: A string that is one of BuiltInActiveSetMethods.
                if ~isempty(activeSetMethod)
                    activeSetMethod = internal.stats.getParamVal(activeSetMethod,GPParams.BuiltInActiveSetMethods,'ActiveSetMethod');                    
                end
                
                % 2.11 Standardize.
                % Require: True or false, 1 or 0.
                if ~isempty(standardize)
                    [isok,standardize] = GPParams.isTrueFalseZeroOne(standardize);
                    if ~isok
                        error(message('stats:classreg:learning:modelparams:GPParams:make:BadStandardize'));
                    end
                end
                
                % 2.12 Verbose.
                % Require: An integer between 0 and 2.
                if ~isempty(verbose)
                    isok = GPParams.isNumericRealVectorNoNaNInf(verbose,1);
                    isok = isok && internal.stats.isIntegerVals(verbose,0,2);
                    if ~isok
                        error(message('stats:classreg:learning:modelparams:GPParams:make:BadVerbose'));
                    end
                end
                
                % 2.13 CacheSize.
                % Require: An integer >= 1.
                if ~isempty(cacheSize)
                    [isok,cacheSize] = GPParams.isNumericRealVectorNoNaNInf(cacheSize,1);
                    isok             = isok && internal.stats.isIntegerVals(cacheSize,1);                    
                    if ~isok
                        error(message('stats:classreg:learning:modelparams:GPParams:make:BadCacheSize'));
                    end
                end
                
                % 2.14 Regularization.
                % Require: A positive, numeric, real scalar, no NaN or Inf.
                if ~isempty(regularization)
                    [isok,regularization] = GPParams.isNumericRealVectorNoNaNInf(regularization,1);
                    isok = isok && (regularization > 0);
                    if ~isok
                        error(message('stats:classreg:learning:modelparams:GPParams:make:BadRegularization'));
                    end                
                end
                    
                % 2.15 SigmaLowerBound.
                % Require: A positive, numeric, real scalar, no NaN or Inf.
                if ~isempty(sigmaLowerBound)                    
                    [isok,sigmaLowerBound] = GPParams.isNumericRealVectorNoNaNInf(sigmaLowerBound,1);
                    isok = isok && (sigmaLowerBound > 0);
                    if ~isok
                        error(message('stats:classreg:learning:modelparams:GPParams:make:BadSigmaLowerBound'));
                    end
                end
                    
                % 2.16 RandomSearchSetSize.
                % Require: An integer >= 1.
                if ~isempty(randomSearchSetSize)
                    [isok,randomSearchSetSize] = GPParams.isNumericRealVectorNoNaNInf(randomSearchSetSize,1);
                    isok                       = isok && internal.stats.isIntegerVals(randomSearchSetSize,1);
                    if ~isok
                        error(message('stats:classreg:learning:modelparams:GPParams:make:BadRandomSearchSetSize'));
                    end
                end
                    
                % 2.17 ToleranceActiveSet.
                % Require: A positive, numeric, real scalar, no NaN or Inf.
                if ~isempty(toleranceActiveSet)                    
                    [isok,toleranceActiveSet] = GPParams.isNumericRealVectorNoNaNInf(toleranceActiveSet,1);
                    isok = isok && (toleranceActiveSet > 0);
                    if ~isok
                        error(message('stats:classreg:learning:modelparams:GPParams:make:BadToleranceActiveSet'));
                    end
                end
                    
                % 2.18 NumActiveSetRepeats.
                % Require: An integer >= 1.
                if ~isempty(numActiveSetRepeats)
                    [isok,numActiveSetRepeats] = GPParams.isNumericRealVectorNoNaNInf(numActiveSetRepeats,1);
                    isok                       = isok && internal.stats.isIntegerVals(numActiveSetRepeats,1);
                    if ~isok
                        error(message('stats:classreg:learning:modelparams:GPParams:make:BadNumActiveSetRepeats'));
                    end
                end
                    
                % 2.19 BlockSizeBCD.
                % Require: An integer >= 1.
                if ~isempty(blockSizeBCD)
                    [isok,blockSizeBCD] = GPParams.isNumericRealVectorNoNaNInf(blockSizeBCD,1);
                    isok                = isok && internal.stats.isIntegerVals(blockSizeBCD,1);
                    if ~isok
                        error(message('stats:classreg:learning:modelparams:GPParams:make:BadBlockSizeBCD'));
                    end
                end
                    
                % 2.20 NumGreedyBCD.
                % Require: An integer >= 1.
                if ~isempty(numGreedyBCD)
                    [isok,numGreedyBCD] = GPParams.isNumericRealVectorNoNaNInf(numGreedyBCD,1);
                    isok                = isok && internal.stats.isIntegerVals(numGreedyBCD,1);
                    if ~isok
                        error(message('stats:classreg:learning:modelparams:GPParams:make:BadNumGreedyBCD'));
                    end
                end
                    
                % 2.21 ToleranceBCD.
                % Require: A positive, numeric, real scalar, no NaN or Inf.
                if ~isempty(toleranceBCD)
                    [isok,toleranceBCD] = GPParams.isNumericRealVectorNoNaNInf(toleranceBCD,1);
                    isok = isok && (toleranceBCD > 0);
                    if ~isok
                        error(message('stats:classreg:learning:modelparams:GPParams:make:BadToleranceBCD'));
                    end
                end
                    
                % 2.22 StepToleranceBCD.
                % Require: A positive, numeric, real scalar, no NaN or Inf.
                if ~isempty(stepToleranceBCD)
                    [isok,stepToleranceBCD] = GPParams.isNumericRealVectorNoNaNInf(stepToleranceBCD,1);
                    isok = isok && (stepToleranceBCD > 0);
                    if ~isok
                        error(message('stats:classreg:learning:modelparams:GPParams:make:BadStepToleranceBCD'));
                    end
                end
                    
                % 2.23 IterationLimitBCD.
                % Require: An integer >= 1.
                if ~isempty(iterationLimitBCD)
                    [isok,iterationLimitBCD] = GPParams.isNumericRealVectorNoNaNInf(iterationLimitBCD,1);
                    isok                     = isok && internal.stats.isIntegerVals(iterationLimitBCD,1);
                    if ~isok
                        error(message('stats:classreg:learning:modelparams:GPParams:make:BadIterationLimitBCD'));
                    end
                end
                    
                % 2.24 DistanceMethod.
                % Require: A string that is one of BuiltInDistanceMethods.
                if ~isempty(distanceMethod)
                    distanceMethod = internal.stats.getParamVal(distanceMethod,GPParams.BuiltInDistanceMethods,'DistanceMethod');
                end
                    
                % 2.25 ComputationMethod.
                % Require: A string that is one of BuiltInComputationMethods.                
                if ~isempty(computationMethod)
                    computationMethod = internal.stats.getParamVal(computationMethod,GPParams.BuiltInComputationMethods,'ComputationMethod');                    
                end
                
                % Translate ComputationMethod to UseQR.
                if isempty(computationMethod)
                    % ComputationMethod is not supplied. This is the same
                    % as not supplying UseQR.
                    useQR = [];
                else
                    % If ComputationMethod is supplied we know it is valid
                    % at this point.
                    if strcmpi(computationMethod,GPParams.ComputationMethodQR)
                        useQR = true;
                    else
                        useQR = false;
                    end
                end
                        
                % 2.26 Optimizer.
                % Require: A string that is one of BuiltInOptimizers.
                if ~isempty(optimizer)
                    optimizer = internal.stats.getParamVal(optimizer,GPParams.BuiltInOptimizers,'Optimizer');   
                end
                
                % 2.27 OptimizerOptions.
                % Require: Object created using optimoptions('fminunc'),
                %          optimoptions('fmincon') or optimset('fminsearch').
                if ~isempty(optimizerOptions)
                    isok = isa(optimizerOptions,'optim.options.Fminunc') ||...
                           isa(optimizerOptions,'optim.options.Fmincon') ||...
                           isa(optimizerOptions,'struct');                                           
                    if ~isok
                        error(message('stats:classreg:learning:modelparams:GPParams:make:BadOptimizerOptions'));
                    end
                end
                
                % 2.28 ConstantKernelParameters
                % Require: A logical array
                if ~isempty(constantKernelParameters)
                    if ~islogical(constantKernelParameters)
                        error(message('stats:classreg:learning:modelparams:GPParams:make:BadConstantKernelParametersType'));
                    end
                end
                
                % 2.29 ConstantSigma
                % Require: A logical scalar
                if ~isempty(constantSigma)
                    if ~(islogical(constantSigma) && isscalar(constantSigma))
                        error(message('stats:classreg:learning:modelparams:GPParams:make:BadConstantSigma'));
                    end
                end
                
                % 2.30 initialStepSize
                % Require: A positive, numeric, real scalar, no NaN or Inf.
                % Alternatively, initialStepSize can also be specified as
                % the string 'auto'.
                if ~isempty(initialStepSize)
                    if isnumeric(initialStepSize)
                        [isok,initialStepSize] = GPParams.isNumericRealVectorNoNaNInf(initialStepSize,1);
                        isok = isok && (initialStepSize > 0);
                        if ~isok
                            error(message('stats:classreg:learning:modelparams:GPParams:make:BadInitialStepSize'));
                        end
                    else
                        initialStepSize = internal.stats.getParamVal(initialStepSize,{GPParams.StringAuto},'InitialStepSize');
                    end
                end
                
            % 3. Create an Options structure containing the more advanced
            % fitting options. It is convenient to bundle these together.
            options                     = struct();
            options.DiagonalOffset      = 0;
            options.Regularization      = regularization;
            options.SigmaLowerBound     = sigmaLowerBound;
            options.RandomSearchSetSize = randomSearchSetSize;
            options.ToleranceActiveSet  = toleranceActiveSet;
            options.NumActiveSetRepeats = numActiveSetRepeats;
            options.BlockSizeBCD        = blockSizeBCD;
            options.NumGreedyBCD        = numGreedyBCD;
            options.ToleranceBCD        = toleranceBCD;
            options.StepToleranceBCD    = stepToleranceBCD;
            options.IterationLimitBCD   = iterationLimitBCD;
            options.DistanceMethod      = distanceMethod;
            options.UseQR               = useQR;
            
            % 4. Construct GPParams object.
            holder = classreg.learning.modelparams.GPParams(...
                kernelFunction,...
                kernelParameters,...
                basisFunction,...
                beta,...
                sigma,...
                fitMethod,...
                predictMethod,...
                activeSet,...
                activeSetSize,...
                activeSetMethod,...                
                standardize,...
                verbose,...
                cacheSize,...
                options,...
                optimizer,...
                optimizerOptions,...
                constantKernelParameters,...
                constantSigma,...
                initialStepSize);            
        end
    end
    
    methods(Hidden)       
        function this = fillDefaultParams(this,X,~,~,dataSummary,classSummary) %#ok<INUSD>            
            % 1. Set up default values for empty properties of ModelParams.
                D = size(X,2);
                N = size(X,1);
                NumXColumns = D;
                if ~isempty(dataSummary) && ~isempty(dataSummary.VariableRange)
                    % Get dimension of X including dummy variable columns
                    D = sum(cellfun(@(c)max(1,size(c,1)),dataSummary.VariableRange));
                end
            
                % 1.1 KernelFunction.
                if isempty(this.KernelFunction)
                    this.KernelFunction = this.SquaredExponential;
                end
                
                % 1.2 KernelParameters.
                if isempty(this.KernelParameters)
                    if isa(this.KernelFunction,'function_handle')
                        % With custom kernel functions - must provide KernelParameters.
                        error(message('stats:classreg:learning:modelparams:GPParams:fillDefaultParams:CustomKernelParameters'));
                    else
                        % Defaults for built in kernel functions. These
                        % depend on X and Y and so should be set in GPImpl.
                    end
                else
                    if isa(this.KernelFunction,'function_handle')
                        % TODO: Check that supplied KernelFunction accepts
                        % supplied KernelParameters without error.
                    else
                        % KernelParameters must be of the right size for
                        % built in kernel functions. In addition, each
                        % kernel function has its own requirements on the
                        % specified vector of kernel parameters. For
                        % example, for the squared exponential kernels, the
                        % vector of kernel parameters should be positive.                        
                        switch lower(this.KernelFunction)
                            case lower(this.Exponential)
                                isok = (length(this.KernelParameters) == 2) && (all(this.KernelParameters > 0));
                                if ~isok
                                    error(message('stats:classreg:learning:modelparams:GPParams:fillDefaultParams:BadExponentialParameters'));
                                end
                            case lower(this.SquaredExponential)
                                isok = (length(this.KernelParameters) == 2) && (all(this.KernelParameters > 0));
                                if ~isok
                                    error(message('stats:classreg:learning:modelparams:GPParams:fillDefaultParams:BadSquaredExponentialParameters'));
                                end
                            case lower(this.Matern32)
                                isok = (length(this.KernelParameters) == 2) && (all(this.KernelParameters > 0));
                                if ~isok
                                    error(message('stats:classreg:learning:modelparams:GPParams:fillDefaultParams:BadMatern32Parameters'));
                                end
                            case lower(this.Matern52)
                                isok = (length(this.KernelParameters) == 2) && (all(this.KernelParameters > 0));
                                if ~isok
                                    error(message('stats:classreg:learning:modelparams:GPParams:fillDefaultParams:BadMatern52Parameters'));
                                end
                            case lower(this.RationalQuadratic)
                                isok = (length(this.KernelParameters) == 3) && (all(this.KernelParameters > 0));
                                if ~isok
                                    error(message('stats:classreg:learning:modelparams:GPParams:fillDefaultParams:BadRationalQuadraticParameters'));
                                end
                            case lower(this.ExponentialARD)
                                isok = (length(this.KernelParameters) == (D+1)) && (all(this.KernelParameters > 0));
                                if ~isok
                                    error(message('stats:classreg:learning:modelparams:GPParams:fillDefaultParams:BadARDExponentialParameters',D,D+1));
                                end
                            case lower(this.SquaredExponentialARD)                               
                                isok = (length(this.KernelParameters) == (D+1)) && (all(this.KernelParameters > 0));
                                if ~isok
                                    error(message('stats:classreg:learning:modelparams:GPParams:fillDefaultParams:BadARDSquaredExponentialParameters',D,D+1));
                                end
                            case lower(this.Matern32ARD)
                                isok = (length(this.KernelParameters) == (D+1)) && (all(this.KernelParameters > 0));
                                if ~isok                                    
                                    error(message('stats:classreg:learning:modelparams:GPParams:fillDefaultParams:BadARDMatern32Parameters',D,D+1));
                                end                                
                            case lower(this.Matern52ARD)
                                isok = (length(this.KernelParameters) == (D+1)) && (all(this.KernelParameters > 0));
                                if ~isok                                    
                                    error(message('stats:classreg:learning:modelparams:GPParams:fillDefaultParams:BadARDMatern52Parameters',D,D+1));
                                end
                            case lower(this.RationalQuadraticARD)
                                isok = (length(this.KernelParameters) == (D+2)) && (all(this.KernelParameters > 0));
                                if ~isok
                                    error(message('stats:classreg:learning:modelparams:GPParams:fillDefaultParams:BadARDRationalQuadraticParameters',D,D+2));
                                end
                        end
                        % KernelParameters should already be a column
                        % vector at this point because of the checks in
                        % make but ensure that this is the case.
                        if isrow(this.KernelParameters)
                            this.KernelParameters = this.KernelParameters';
                        end
                    end
                end
                
                % 1.3 BasisFunction.
                if isempty(this.BasisFunction)
                    this.BasisFunction = this.BasisConstant;
                elseif strcmpi(this.BasisFunction,this.BasisPureQuadratic) ...
                        && D>NumXColumns
                    % Cannot have a quadratic basis with categoricals
                    error(message('stats:classreg:learning:modelparams:GPParams:fillDefaultParams:NoQuadraticCategorical'));
                end
                
                % 1.4 Beta.
                if isempty(this.Beta)
                    if isa(this.BasisFunction,'function_handle')
                        % With custom basis functions - must provide Beta.
                        error(message('stats:classreg:learning:modelparams:GPParams:fillDefaultParams:CustomBeta'));
                    else
                        % Defaults for built in basis functions.
                        switch lower(this.BasisFunction)
                            case lower(this.BasisNone)
                                this.Beta = zeros(0,1);
                            case lower(this.BasisConstant)
                                this.Beta = zeros(1,1);
                            case lower(this.BasisLinear)
                                this.Beta = zeros(D+1,1);
                            case lower(this.BasisPureQuadratic)
                                this.Beta = zeros(2*D+1,1);
                        end
                    end
                else
                    if isa(this.BasisFunction,'function_handle')
                        % TODO: Check that the supplied BasisFunction is 
                        % compatible with supplied Beta. 
                    else
                        % Beta must be of the right size for built in basis functions.
                        switch lower(this.BasisFunction)
                            case lower(this.BasisNone)                             
                                isok = isempty(this.Beta);
                                if ~isok
                                    error(message('stats:classreg:learning:modelparams:GPParams:fillDefaultParams:BadBasisNoneBeta'));
                                end
                            case lower(this.BasisConstant)
                                isok = (length(this.Beta) == 1);
                                if ~isok
                                    error(message('stats:classreg:learning:modelparams:GPParams:fillDefaultParams:BadBasisConstantBeta'));
                                end
                            case lower(this.BasisLinear)
                                isok = (length(this.Beta) == D+1);
                                if ~isok
                                    error(message('stats:classreg:learning:modelparams:GPParams:fillDefaultParams:BadBasisLinearBeta'));
                                end
                            case lower(this.BasisPureQuadratic)
                                isok = (length(this.Beta) == 2*D+1);
                                if ~isok
                                    error(message('stats:classreg:learning:modelparams:GPParams:fillDefaultParams:BadBasisPureQuadraticBeta'));
                                end
                        end
                        % Beta should already be a column vector at this
                        % point because of the checks in make but ensure
                        % that this is the case.
                        if isrow(this.Beta)
                            this.Beta = this.Beta';
                        end
                    end
                end
                        
                % 1.5 Sigma.
                if isempty(this.Sigma)
                    % The default depends on Y and so should be set in GPImpl.                    
                end
                
                % 1.6 FitMethod.
                if isempty(this.FitMethod)
                    if ( N <= 2000 )
                        this.FitMethod = this.FitMethodExact;
                    else
                        this.FitMethod = this.FitMethodSD;
                    end
                end
                
                % 1.7 PredictMethod.
                if isempty(this.PredictMethod)
                    if ( N <= 10000 )
                        this.PredictMethod = this.PredictMethodExact;
                    else
                        this.PredictMethod = this.PredictMethodBCD;
                    end
                end
                
                % 1.8 ActiveSet. If supplied, make ActiveSet into a N-by-1
                % logical vector. Fixed up in RegressionGP after NaN
                % removal.
                if ~isempty(this.ActiveSet)
                    if islogical(this.ActiveSet)
                        isok = length(this.ActiveSet) == N;
                        if ~isok
                            error(message('stats:classreg:learning:modelparams:GPParams:fillDefaultParams:BadActiveSet',N,N,N));
                        end
                    else
                        % ActiveSet must be of length M where 1 <= M <= N and 
                        % with elements from 1 to N. 
                        activeSet    = this.ActiveSet;
                        lenActiveSet = length(activeSet);
                        isok         = lenActiveSet >= 1 && lenActiveSet <= N;
                        isok         = isok && all(activeSet >= 1 & activeSet <= N);
                        if ~isok
                            error(message('stats:classreg:learning:modelparams:GPParams:fillDefaultParams:BadActiveSet',N,N,N));
                        end
                        activeSetLogical                 = false(N,1);
                        activeSetLogical(this.ActiveSet) = true;
                        this.ActiveSet                   = activeSetLogical;
                    end
                end
                
                % 1.9 ActiveSetSize. Fixed up in RegressionGP after NaN
                % removal.
                if isempty(this.ActiveSetSize)
                    isSRFIC = any(strcmpi(this.FitMethod,{this.FitMethodSR,this.FitMethodFIC}));
                    if isSRFIC
                        this.ActiveSetSize = min(1000,N);
                    else
                        this.ActiveSetSize = min(2000,N);
                    end
                else
                    if ( this.ActiveSetSize > N )
                        error(message('stats:classreg:learning:modelparams:GPParams:fillDefaultParams:BadActiveSetSize',N));
                    end
                end
                this.ActiveSetSize = max(1,min(this.ActiveSetSize,N));
                
                % 1.10 ActiveSetMethod.
                if isempty(this.ActiveSetMethod)                    
                    this.ActiveSetMethod = this.ActiveSetMethodRandom;
                end
                
                % 1.11 Standardize.
                if isempty(this.Standardize)
                    this.Standardize = false;
                end
                
                % 1.12 Verbose.
                if isempty(this.Verbose)
                    this.Verbose = 0;
                end
                
                % 1.13 CacheSize.
                if isempty(this.CacheSize)
                    this.CacheSize = 1000;
                end
                
                % 1.14 Options.
                
                    % 1.14.1 Create default fitting options.
                    %   
                    %   DiagonalOffset      - A small number added to the diagonal of the
                    %                         kernel matrix to make it positive definite.
                    %   Regularization      - A positive scalar specifying the regularization 
                    %                         standard deviation for sparse methods (SR and FIC).
                    %   SigmaLowerBound     - A positive scalar specifying a lower bound on the 
                    %                         noise standard deviation.                    
                    %   RandomSearchSetSize - size of random sets to use in active set selection.
                    %   ToleranceActiveSet  - relative convergence tolerance for active set selection.
                    %   NumActiveSetRepeats - An integer specifying the number of repetitions of 
                    %                         active set selection and parameter estimation when 
                    %                         'ActiveSetMethod' is not 'Random'.                    
                    %   BlockSizeBCD        - Block size for BCD.
                    %   NumGreedyBCD        - Number of greedy selections in BCD.
                    %   ToleranceBCD        - Convergence tolerance on the gradient norm in BCD.  
                    %   StepToleranceBCD    - Convergence tolerance on the norm of the step size in BCD.
                    %   IterationLimitBCD   - Maximum number of BCD iterations.
                    %   DistanceMethod      - Method for computing interpoint distances for 
                    %                         built in kernel functions.
                    %   UseQR               - True if SR/FIC estimation should use QR factorization.
                    %                         (for greater stability).                    
                    dfltopts                     = struct();
                    dfltopts.DiagonalOffset      = 0;
                    % Default is 1e-2*std(Y) - set in GPImpl.
                    dfltopts.Regularization      = [];
                    % Default is 1e-2*std(Y) - set in GPImpl.
                    dfltopts.SigmaLowerBound     = [];
                    dfltopts.RandomSearchSetSize = 59;
                    dfltopts.ToleranceActiveSet  = 1e-6;
                    dfltopts.NumActiveSetRepeats = 3;
                    % BlockSizeBCD and NumGreedyBCD need to be fixed up in
                    % RegressionGP after NaN removal.
                    dfltopts.BlockSizeBCD        = min(1000,N);
                    dfltopts.NumGreedyBCD        = min(100,dfltopts.BlockSizeBCD);
                    dfltopts.ToleranceBCD        = 1e-3;
                    dfltopts.StepToleranceBCD    = 1e-3;
                    dfltopts.IterationLimitBCD   = 1000000;
                    dfltopts.DistanceMethod      = this.DistanceMethodFast;
                    dfltopts.UseQR               = true;
                    
                    % 1.14.2 this.Options is a filled structure with the 13
                    % fields indicated above. The fields themselves may be
                    % empty.
                    % * If a field is empty, copy its value from dfltopts. 
                    %
                    % * If a field is not empty and its value depends on 
                    % other things then validate it.
                    %
                    % * If a field is not empty and its value is
                    % independent of other things then we are all set.
                    
                    % DiagonalOffset.
                    if isempty(this.Options.DiagonalOffset)
                        this.Options.DiagonalOffset = dfltopts.DiagonalOffset;
                    else
                        diagonalOffset = this.Options.DiagonalOffset;
                        [isok,diagonalOffset] = this.isNumericRealVectorNoNaNInf(diagonalOffset,1);
                        isok = isok && (diagonalOffset >= 0);
                        if ~isok
                            error(message('stats:classreg:learning:modelparams:GPParams:fillDefaultParams:BadDiagonalOffset'));
                        end
                        this.Options.DiagonalOffset = diagonalOffset;
                    end
                    
                    % Regularization.
                    if isempty(this.Options.Regularization)
                        this.Options.Regularization = dfltopts.Regularization;
                    end
                    
                    % SigmaLowerBound.
                    if isempty(this.Options.SigmaLowerBound)
                        this.Options.SigmaLowerBound = dfltopts.SigmaLowerBound;
                    end
                    
                    % RandomSearchSetSize.
                    if isempty(this.Options.RandomSearchSetSize)
                        this.Options.RandomSearchSetSize = dfltopts.RandomSearchSetSize;
                    end
                    
                    % ToleranceActiveSet.
                    if isempty(this.Options.ToleranceActiveSet)
                        this.Options.ToleranceActiveSet = dfltopts.ToleranceActiveSet;
                    end
                    
                    % NumActiveSetRepeats.
                    if isempty(this.Options.NumActiveSetRepeats)
                        this.Options.NumActiveSetRepeats = dfltopts.NumActiveSetRepeats; 
                    end
                    
                    % BlockSizeBCD.
                    if isempty(this.Options.BlockSizeBCD)
                        this.Options.BlockSizeBCD = dfltopts.BlockSizeBCD;
                    else
                        blockSizeBCD = this.Options.BlockSizeBCD;
                        isok = internal.stats.isIntegerVals(blockSizeBCD,1,N);
                        if ~isok
                            error(message('stats:classreg:learning:modelparams:GPParams:fillDefaultParams:BadBlockSizeBCD',N));
                        end
                        this.Options.BlockSizeBCD = blockSizeBCD;
                    end
                    this.Options.BlockSizeBCD = max(1,min(this.Options.BlockSizeBCD,N));
                    
                    % NumGreedyBCD.
                    if isempty(this.Options.NumGreedyBCD)
                        this.Options.NumGreedyBCD = dfltopts.NumGreedyBCD;
                    else
                        numGreedyBCD = this.Options.NumGreedyBCD;
                        isok = internal.stats.isIntegerVals(numGreedyBCD,1,this.Options.BlockSizeBCD);
                        if ~isok
                            error(message('stats:classreg:learning:modelparams:GPParams:fillDefaultParams:BadNumGreedyBCD',this.Options.BlockSizeBCD));
                        end
                        this.Options.NumGreedyBCD = numGreedyBCD;                                                
                    end
                    this.Options.NumGreedyBCD = max(1,min(this.Options.NumGreedyBCD,this.Options.BlockSizeBCD));
                    
                    % ToleranceBCD.
                    if isempty(this.Options.ToleranceBCD)
                        this.Options.ToleranceBCD = dfltopts.ToleranceBCD;
                    end
                    
                    % StepToleranceBCD.
                    if isempty(this.Options.StepToleranceBCD)
                        this.Options.StepToleranceBCD = dfltopts.StepToleranceBCD;
                    end
                    
                    % IterationLimitBCD.
                    if isempty(this.Options.IterationLimitBCD)
                        this.Options.IterationLimitBCD = dfltopts.IterationLimitBCD;
                    end
                    
                    % DistanceMethod.
                    if isempty(this.Options.DistanceMethod)
                        this.Options.DistanceMethod = dfltopts.DistanceMethod;
                    end
                    
                    % UseQR.
                    if isempty(this.Options.UseQR)
                        this.Options.UseQR = dfltopts.UseQR;
                    end
                    
                % 1.15 Optimizer.
                if isempty(this.Optimizer)
                    this.Optimizer = this.OptimizerQuasiNewton;
                end
                
                % 1.16 OptimizerOptions. Treat [] and struct() the same.
                isemptyStruct = isstruct(this.OptimizerOptions) && isempty(fieldnames(this.OptimizerOptions));
                if isempty(this.OptimizerOptions) || isemptyStruct
                    % Fill with default options.
                    switch lower(this.Optimizer)
                        case lower(this.OptimizerFminunc)
                            this.OptimizerOptions             = optimoptions('fminunc');
                            this.OptimizerOptions.Algorithm   = 'quasi-newton';
                            this.OptimizerOptions.GradObj     = 'on';
                            this.OptimizerOptions.MaxFunEvals = 10000;                            
                            this.OptimizerOptions.Display     = 'off';
                        case lower(this.OptimizerFmincon)
                            this.OptimizerOptions             = optimoptions('fmincon');
                            this.OptimizerOptions.GradObj     = 'on';
                            this.OptimizerOptions.MaxFunEvals = 10000;                            
                            this.OptimizerOptions.Display     = 'off';
                        case lower(this.OptimizerFminsearch)
                            this.OptimizerOptions             = optimset('fminsearch');                            
                            this.OptimizerOptions.Display     = 'off';
                        case {lower(this.OptimizerQuasiNewton),lower(this.OptimizerLBFGS)}
                            this.OptimizerOptions             = statset('fitrgp');
                            % The following two lines are already the
                            % defaults but add them here for clarity.
                            this.OptimizerOptions.GradObj     = 'on';
                            this.OptimizerOptions.Display     = 'off';
                    end
                else
                    % Ensure supplied options are sensible.
                    switch lower(this.Optimizer)
                        case lower(this.OptimizerFminunc)
                            isok = isa(this.OptimizerOptions,'optim.options.Fminunc');
                            if ~isok
                                error(message('stats:classreg:learning:modelparams:GPParams:fillDefaultParams:BadOptimizerOptionsFminunc')); 
                            end
                        case lower(this.OptimizerFmincon)                            
                            isok = isa(this.OptimizerOptions,'optim.options.Fmincon');
                            if ~isok
                                error(message('stats:classreg:learning:modelparams:GPParams:fillDefaultParams:BadOptimizerOptionsFmincon')); 
                            end
                        case lower(this.OptimizerFminsearch)
                            isok = isa(this.OptimizerOptions,'struct');  
                            if ~isok
                                error(message('stats:classreg:learning:modelparams:GPParams:fillDefaultParams:BadOptimizerOptionsFminsearch'));
                            end
                            this.OptimizerOptions = optimset(optimset('fminsearch'),this.OptimizerOptions);
                        case {lower(this.OptimizerQuasiNewton),lower(this.OptimizerLBFGS)}
                            isok = isa(this.OptimizerOptions,'struct');  
                            if ~isok
                                error(message('stats:classreg:learning:modelparams:GPParams:fillDefaultParams:BadOptimizerOptionsQuasiNewton'));
                            end
                            this.OptimizerOptions = statset(statset('fitrgp'),this.OptimizerOptions);
                    end
                end                   
                
                % 1.17 ConstantKernelParameters. The default is
                % false(size(this.KernelParameters)), but
                % this.KernelParameters is sometimes not set until inside
                % GPImpl. So we defer setting this default until there.

                % 1.18 ConstantSigma. 
                if isempty(this.ConstantSigma)
                    this.ConstantSigma = false;
                end
                
                % 1.19 InitialStepSize.
                % Empty InitialStepSize is a legal value.
        end
        
    end
    
    methods(Static)
        function [isok,func,isfuncstr] = validateStringOrFunctionHandle(func,allowedVals)
        % INPUTS:
        %   func        = function handle or a string containing name of MATLAB function 
        %                 on PATH or a string from the cell array of strings allowedVals.
        %   allowedVals = possible string values for func.
        %
        % OUTPUTS:
        %   isok      = true if func is a valid input.
        %   func      = validated value of func if isok is true.
        %   isfuncstr = true if func is a string containing name of MATLAB function on PATH and false otherwise. 

            isfuncstr = false;
            if isa(func,'function_handle')
                isok = true;
            elseif ischar(func)
                % 1. First, attempt to match in allowedVals.
                tf = strncmpi(func,allowedVals,length(func));
                nmatches = sum(tf);
                if nmatches > 1
                    % No clear match.
                    isok = false;
                elseif nmatches == 1
                    % Single match.
                    isok = true;
                    func = allowedVals{tf};
                else
                    % No match.
                    isok = false;
                end
                
                % 2. If no match, look for matching function on path.
                if ~isok
                    whichOutput = which(func);
                    if ~isempty(whichOutput) && ~strcmpi(whichOutput,'variable')
                        isfuncstr = true;
                        isok      = true;
                    end
                end
            else
                isok = false;
            end            
        end
    
        function [isok,x] = isNumericRealVectorNoNaNInf(x,N)
        % INPUTS:
        %   x = a potential numeric, real vector.
        %   N = length of x or [] if length of x is not known.
        % OUTPUT:
        %   isok = true if x is a numeric real vector of length N. NaN and 
        %          Inf values are not allowed. If N is empty x can be of 
        %          any length. 
        %      x = validated value of x as a column vector if isok is true.
            
            isok = isnumeric(x) && isreal(x) && isvector(x) && ~any(isnan(x)) && ~any(isinf(x));            
            if isempty(N)
                % x can be of any length.
            else
                % x must be of length N.
                isok = isok && (length(x) == N);
            end
            if isok && (size(x,1) == 1)
                % Make into column vector.
                x = x';
            end
        end
        
        function [isok,x] = isTrueFalseZeroOne(x)
        % INPUTS:
        %   x = a potential 0/1 or true/false value.
        % OUTPUTS:
        %   isok = true if x is valid.
        %      x = validated value of x as a logical if isok is true.
        
            if islogical(x)
                isok = true;
                return;
            end
        
            isint = internal.stats.isScalarInt(x);
            if isint
                if  x == 1                    
                    isok = true;
                    x    = true;
                elseif x == 0
                    isok = true;
                    x    = false;
                else
                    isok = false;
                end
            else
                isok = false;
            end
        end               
    end
    
end

