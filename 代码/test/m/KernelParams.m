classdef KernelParams < classreg.learning.modelparams.ModelParams
%KernelParams Parameters for the Kernel models.
%
%   KernelParams properties:
%       ADMMIterationLimit       - Maximal number of outer ADMM iterations.
%       ADMMUpdateIterationLimit - Maximal number of iterations inside ADMM updates.
%       BetaTolerance            - Relative tolerance on the change in the primal coefficients.
%       BlockSize                - Amount of memory (MB) for each block.
%       BoxConstraint            - Box constraint.
%       Consensus                - Strength of the ADMM penalty.
%       Epsilon                  - Epsilon for epsilon-insensitive loss.
%       NumExpansionDimensions   - Number of dimensions in the expanded space.
%       FeatureMapper            - Feature Mapper.
%       FitBias                  - Logical flag indicating if the bias term should be fit.
%       GradientTolerance        - Absolute tolerance on the inf norm of the gradient.
%       HessianHistorySize       - Size of history buffer for computing Hessian approximation by LBFGS.
%       InitialBeta              - Initial estimates of the beta coefficients.
%       InitialBias              - Initial estimate of the bias term.
%       InitialStepSize          - Initial step size for LBFGS.
%       IterationLimit           - Maximal number of iterations.
%       IterationLimitBlockWise  - Maximal number of iterations when using a block-wise approach.
%       KernelScale              - Scale factor.
%       Lambda                   - Regularization strength.
%       Learner                  - Learned model such as 'svm' or 'leastsquares'.
%       LineSearch               - Line search algorithm for LBFGS.
%       LossFunction             - Loss function such as 'hinge' or 'mse'.
%       PostFitBias              - Always false (required to use classreg.learning.impl.LinearImpl.makeNoFit)
%       Regularization           - Regularization such as 'ridge' or 'lasso'.
%       Solver                   - Algorithm such as 'lbfgs' or 'sgd'.
%       Stream                   - Random stream object.
%       Transformation           - Expansion type such as 'FastFood' or 'KitchenSinks'
%       ValidationX              - Validation X data.
%       ValidationY              - Validation Y data.
%       ValidationW              - Validation weights.
%       VerbosityLevel           - Verbosity level.
%       WarmStartIterationLimit  - Maximal number of iterations inside first ADMM iteration.

   
%   Copyright 2017 The MathWorks, Inc.
    
    properties
        ADMMIterationLimit; % (undocumented)
        ADMMUpdateIterationLimit; % (undocumented)
        BetaTolerance; 
        BlockSize;
        BoxConstraint;
        Consensus; % (undocumented)
        Epsilon;
        NumExpansionDimensions; 
        FeatureMapper; % (undocumented)
        FitBias; % (undocumented) (reserved due to similarity to LinearParams)
        GradientTolerance; 
        HessianHistorySize;
        InitialBeta; % (undocumented) (reserved due to similarity to LinearParams)
        InitialBias; % (undocumented) (reserved due to similarity to LinearParams)
        InitialStepSize; % (undocumented)
        IterationLimit; 
        IterationLimitBlockWise; % (undocumented)
        KernelScale;
        Lambda;
        Learner; 
        LineSearch; % (reserved due to similarity to LinearParams)
        LossFunction; 
        PostFitBias; % (undocumented) (reserved due to similarity to LinearParams)
        Regularization; % (undocumented) (reserved due to similarity to LinearParams)
        Solver; % (undocumented) 
        Stream; 
        Transformation; % (undocumented)
        ValidationX;  % (reserved due to similarity to LinearParams)
        ValidationY;  % (reserved due to similarity to LinearParams)
        ValidationW;  % (reserved due to similarity to LinearParams)
        VerbosityLevel; 
        WarmStartIterationLimit;
    end
    
    methods(Access=protected)
        function this = KernelParams(type,learner,lossfun,...
                fitbias,regularizer,lambda,maxiter,maxiterbw,...
                solver,betaTol,gradTol,boxConstraint,...
                epsilon,historysize,linesearch,...
                rsh,verbose,numexpansiondimensions,...
                kernelscale,transformation,blocksize,...
                admmiterationlimit,admmupdateiterationlimit,...
                warmstartiterationlimit,initialstepsize,consensus)
            
            this = this@classreg.learning.modelparams.ModelParams('Kernel',type);
            
            this.Learner                  = learner;
            this.LossFunction             = lossfun;
            this.FitBias                  = fitbias;
            this.Regularization           = regularizer;
            this.Lambda                   = lambda;
            this.IterationLimit           = maxiter;
            this.IterationLimitBlockWise  = maxiterbw;
            this.Solver                   = solver;
            this.BetaTolerance            = betaTol;
            this.GradientTolerance        = gradTol;
            this.BoxConstraint            = boxConstraint;
            this.Epsilon                  = epsilon;
            this.HessianHistorySize       = historysize;
            this.LineSearch               = linesearch;
            this.Stream                   = rsh;
            this.VerbosityLevel           = verbose;
            this.NumExpansionDimensions   = numexpansiondimensions;
            this.KernelScale              = kernelscale;
            this.Transformation           = transformation;
            this.BlockSize                = blocksize;
            this.ADMMIterationLimit       = admmiterationlimit;
            this.ADMMUpdateIterationLimit = admmupdateiterationlimit;
            this.WarmStartIterationLimit  = warmstartiterationlimit;
            this.InitialStepSize          = initialstepsize;
            this.Consensus                = consensus;
        end
    end
    
    methods(Static,Hidden)
        
        function [holder,extraArgs] = make(type,varargin)
            % Decode input args and perform all checks as long as they are
            % not data dependent.
            
            args = {'beta' 'bias' 'learner' 'lossfunction' 'lambda' ...
                'iterationlimit' 'regularization' 'solver' ...
                'betatolerance' 'gradienttolerance'  ...
                'fitbias'  'epsilon' 'validationdata' ...
                'hessianhistorysize' 'linesearch' ...
                'randomstream' 'verbose' {'numexpansiondimensions','expansiondimension'} ...
                'kernelscale' 'transformation' 'blocksize' ...
                'admmiterationlimit' 'admmupdateiterationlimit'...
                'warmstartiterationlimit' 'initialstepsize'...
                'consensus' 'boxconstraint'};
            defs = repmat({[]},1,numel(args));
            [beta0,bias0,learner,lossfun,lambda,...
                maxiter,regularizer,solvers,...
                betatol,gradtol,...
                fitbias,epsilon,valdata,...
                historysize,linesearch,...
                rsh,verbose,numexpansiondimensions,...
                kernelscale,transformation,blocksize,...
                admmiterationlimit,admmupdateiterationlimit,...
                warmstartiterationlimit,initialstepsize,...
                consensus,boxconstraint,~,extraArgs] = ...
                internal.stats.parseArgs(args,defs,varargin{:});
            
            
            % =============================================================
            % Parameters recognized but deliberately forbidden:
            % =============================================================            
            
            if ~isempty(beta0) 
                error(message('stats:classreg:learning:modelparams:KernelParams:NotAllowedBeta'))
            end
            if ~isempty(bias0)
                error(message('stats:classreg:learning:modelparams:KernelParams:NotAllowedBias'))
            end
            
            if ~isempty(epsilon)
                if strcmpi(type,'classification')
                    error(message('stats:classreg:learning:modelparams:KernelParams:NotAllowedEpsilon'))
                end
            end
            
            if ~isempty(valdata) 
                error(message('stats:classreg:learning:modelparams:KernelParams:NotAllowedValidationData'))
            end
            
            % =============================================================
            % Documented parameters:
            % =============================================================
            
            if ~isempty(betatol)
                internal.stats.checkSupportedNumeric('BetaTolerance',betatol);
                if ~isscalar(betatol) || betatol<0 || isnan(betatol) || ~isreal(betatol)
                    error(message('stats:classreg:learning:modelparams:KernelParams:BadBetaTolerance'));
                end
                betatol = double(betatol);
            end
            
            if ~isempty(blocksize)
                internal.stats.checkSupportedNumeric('BlockSize',blocksize,true);
                if ~isscalar(blocksize) || blocksize<1 ...
                        || round(blocksize)~=blocksize || ~isreal(blocksize)
                    error(message('stats:classreg:learning:modelparams:KernelParams:BadBlockSize'));
                end
                blocksize = double(blocksize);
            end
            
            if ~isempty(boxconstraint)
                internal.stats.checkSupportedNumeric('BoxConstraint',boxconstraint);
                if ~isscalar(boxconstraint) || boxconstraint<=0 || isnan(boxconstraint) || ~isreal(boxconstraint)
                    error(message('stats:classreg:learning:modelparams:KernelParams:BadBoxConstraint'));
                end
                boxconstraint = double(boxconstraint);
            end
            
            if ~isempty(epsilon)
                 if ischar(epsilon)
                    if ~strncmpi(epsilon,'auto',length(epsilon))
                        error(message('stats:classreg:learning:modelparams:KernelParams:BadEpsilon'));
                    end
                    epsilon = 'auto';
                else
                    internal.stats.checkSupportedNumeric('Epsilon',epsilon);
                    if ~isscalar(epsilon) || epsilon<0 || isnan(epsilon) || ~isreal(epsilon)
                       error(message('stats:classreg:learning:modelparams:KernelParams:BadEpsilon'));
                    end
                    epsilon = double(epsilon);
                 end
            end

                
            if ~isempty(numexpansiondimensions)
                if ischar(numexpansiondimensions)
                    if ~strncmpi(numexpansiondimensions,'auto',length(numexpansiondimensions))
                        error(message('stats:classreg:learning:modelparams:KernelParams:BadNumExpansionDimensions'));
                    end
                    numexpansiondimensions = 'auto';
                else
                    internal.stats.checkSupportedNumeric('NumExpansionDimensions',numexpansiondimensions,true);
                    if ~isscalar(numexpansiondimensions) || numexpansiondimensions<1 ...
                            || round(numexpansiondimensions)~=numexpansiondimensions || ~isreal(numexpansiondimensions)
                        error(message('stats:classreg:learning:modelparams:KernelParams:BadNumExpansionDimensions'));
                    end
                    numexpansiondimensions = double(numexpansiondimensions);
                end
            end
            
            if ~isempty(gradtol)
                internal.stats.checkSupportedNumeric('GradientTolerance',gradtol);
                if ~isscalar(gradtol) || gradtol<0 || isnan(gradtol) || ~isreal(gradtol)
                    error(message('stats:classreg:learning:modelparams:KernelParams:BadGradientTolerance'));
                end
                gradtol = double(gradtol);
            end
            
            if ~isempty(historysize)
                internal.stats.checkSupportedNumeric('HessianHistorySize',historysize,true);
                if ~isscalar(historysize) || historysize<1 ...
                        || round(historysize)~=historysize || ~isreal(historysize)
                    error(message('stats:classreg:learning:modelparams:KernelParams:BadHessianHistorySize'));
                end
                historysize = double(historysize);
            end
            
            if ~isempty(maxiter)
                internal.stats.checkSupportedNumeric('IterationLimit',maxiter,true);
                if ~isscalar(maxiter) || maxiter<0 || round(maxiter)~=maxiter || ~isreal(maxiter)
                    error(message('stats:classreg:learning:modelparams:KernelParams:BadIterationLimit'));
                end
                maxiter = double(maxiter);
                maxiterbw = maxiter; % IterationLimit sets the limit for both, the fast and the block-wise LBFGS algs
            else
                maxiterbw = [];
            end
            
            
            if ~isempty(kernelscale)
                if ischar(kernelscale)
                    if ~strncmpi(kernelscale,'auto',length(kernelscale))
                        error(message('stats:classreg:learning:modelparams:KernelParams:BadKernelScale'));
                    end
                    kernelscale = 'auto';
                else
                    internal.stats.checkSupportedNumeric('KernelScale',kernelscale);
                    if ~isscalar(kernelscale) || kernelscale<=0 || isnan(kernelscale) || ~isreal(kernelscale)
                        error(message('stats:classreg:learning:modelparams:KernelParams:BadKernelScale'));
                    end
                    kernelscale = double(kernelscale);
                end
            end
            
            
            if ~isempty(lambda)
                if ischar(lambda)
                    if ~strncmpi(lambda,'auto',length(lambda))
                        error(message('stats:classreg:learning:modelparams:KernelParams:BadLambda'));
                    end
                    lambda = 'auto';
                else
                    internal.stats.checkSupportedNumeric('Lambda',lambda);
                    if ~isscalar(lambda) || lambda<0 || isnan(lambda) || ~isreal(lambda)
                        error(message('stats:classreg:learning:modelparams:KernelParams:BadLambda'));
                    end
                    lambda = double(lambda);
                end
            end
            
            
            if ~isempty(learner)
                learner = validatestring(learner,{'svm' 'logistic' 'leastsquares'},...
                    'classreg.learning.modelparams.KernelParams','Learner');
            end
            
            if ~isempty(rsh)
                if ~isa(rsh,'RandStream')
                    error(message('stats:classreg:learning:modelparams:KernelParams:BadStream'))
                end
            end
            
            if ~isempty(verbose)
                internal.stats.checkSupportedNumeric('Verbose',verbose,true);
                if verbose<0
                    error(message('stats:classreg:learning:modelparams:KernelParams:BadVerbose'));
                end
                verbose = double(verbose);
            end
            
            if ~isempty(warmstartiterationlimit)
                internal.stats.checkSupportedNumeric('WarmStartIterationLimit',warmstartiterationlimit,true);
                if ~isscalar(warmstartiterationlimit) || warmstartiterationlimit<1 ...
                        || round(warmstartiterationlimit)~=warmstartiterationlimit || ~isreal(warmstartiterationlimit)
                     error(message('stats:classreg:learning:modelparams:KernelParams:BadWarmStartIterationLimit'));
                end
                warmstartiterationlimit = double(warmstartiterationlimit);
            end
            
            % =============================================================
            % Undocumented parameters:
            % =============================================================
            
            if ~isempty(lossfun)
                lossfun = validatestring(lossfun,{'mse' 'logit' 'hinge' 'epsiloninsensitive'},...
                    'classreg.learning.modelparams.KernelParams','LossFunction');
            end
            
            if ~isempty(regularizer)
                regularizer = validatestring(regularizer,{'lasso' 'ridge'},...
                    'classreg.learning.modelparams.KernelParams','Regularization');
                assert(strcmpi(regularizer,'ridge'),message('stats:classreg:learning:modelparams:KernelParams:LassoNotAllowed')); 
            end
            
            if ~isempty(solvers)
                % Accept solvers as a cellstr similar to LinearParams, but only one solver is supported.
                if iscellstr(solvers) && numel(solvers)==1
                    solvers = solvers{1};
                end
                solvers = {validatestring(solvers,{'lbfgs'},'classreg.learning.modelparams.KernelParams','Solver')};
            end
            
            if ~isempty(fitbias)
                % FitBias is recognized but forced to be true
                fitbias = internal.stats.parseOnOff(fitbias,'FitBias');
                assert(fitbias,message('stats:classreg:learning:modelparams:KernelParams:BadFitBias'))
            end
            
            if ~isempty(linesearch)
                linesearch = validatestring(linesearch,{'backtrack' 'weakwolfe'},...
                    'classreg.learning.modelparams.KernelParams','LineSearch');
            end
            
            if ~isempty(transformation)
                transformation = validatestring(transformation,{'KitchenSinks' 'FastFood'},...
                    'classreg.learning.modelparams.KernelParams','Transformation');
            end
            
            if ~isempty(admmiterationlimit)
                internal.stats.checkSupportedNumeric('ADMMIterationLimit',admmiterationlimit,true);
                if ~isscalar(admmiterationlimit) || admmiterationlimit<0 ...
                        || round(admmiterationlimit)~=admmiterationlimit || ~isreal(admmiterationlimit)
                     error(message('stats:classreg:learning:modelparams:KernelParams:BadADMMIterationLimit'));
                end
                admmiterationlimit = double(admmiterationlimit);
            end
            
            if ~isempty(admmupdateiterationlimit)
                internal.stats.checkSupportedNumeric('ADMMUpdateIterationLimit',admmupdateiterationlimit,true);
                if ~isscalar(admmupdateiterationlimit) || admmupdateiterationlimit<1 ...
                        || round(admmupdateiterationlimit)~=admmupdateiterationlimit || ~isreal(admmupdateiterationlimit)
                     error(message('stats:classreg:learning:modelparams:KernelParams:BadADMMUpdateIterationLimit'));
                end
                admmupdateiterationlimit = double(admmupdateiterationlimit);
            end
            
            if ~isempty(initialstepsize)
                internal.stats.checkSupportedNumeric('InitialStepSize',initialstepsize,true);
                if ~isscalar(initialstepsize) || initialstepsize<=0 || isnan(initialstepsize) || ~isreal(initialstepsize)
                     error(message('stats:classreg:learning:modelparams:KernelParams:BadInitialStepSize'));
                end
                initialstepsize = double(initialstepsize);
            end
            
            if ~isempty(consensus)
                internal.stats.checkSupportedNumeric('Consensus',consensus);
                if ~isscalar(consensus) || consensus<=0 || isnan(consensus) || ~isreal(consensus)
                    error(message('stats:classreg:learning:modelparams:KernelParams:BadConsensus'));
                end
                consensus = double(consensus);
            end
            
            % =============================================================
            
            if ~isempty(boxconstraint) && ~isempty(lambda)
                error(message('stats:classreg:learning:modelparams:KernelParams:LambdaBoxConstraint'));
            end
            if ~isempty(boxconstraint) && (strcmpi(learner,'logistic') || strcmpi(lossfun,'logit'))
                error(message('stats:classreg:learning:modelparams:KernelParams:OnlySVMBoxConstraint'));
            end
            
            if ~isempty(epsilon) &&  (strcmpi(learner,'leastsquares') || strcmpi(lossfun,'mse'))
                error(message('stats:classreg:learning:modelparams:KernelParams:OnlySVMEpsilon'));
            end
            
            holder = classreg.learning.modelparams.KernelParams(...
                type,learner,lossfun,...
                fitbias,regularizer,lambda,maxiter,maxiterbw,...
                solvers,betatol,gradtol,boxconstraint,...
                epsilon,historysize,linesearch,...
                rsh,verbose,numexpansiondimensions,...
                kernelscale,transformation,blocksize,...
                admmiterationlimit,admmupdateiterationlimit,...
                warmstartiterationlimit,initialstepsize,...
                consensus);
        end
        
    end

    
    methods(Hidden)
        function this = fillDefaultParams(this,~,~,~,~,~)
            % Set all default to input parameters as long as they are not
            % data dependent.
            doclass = strcmp(this.Type,'classification');
            if isempty(this.Learner)
                if isempty(this.LossFunction)
                    if doclass
                        this.Learner = 'svm';
                        this.LossFunction = 'hinge';
                    else
                        this.Learner = 'svm';
                        this.LossFunction = 'epsiloninsensitive';
                    end
                else
                    if doclass
                        switch this.LossFunction
                            case 'hinge'
                                this.Learner = 'svm';
                            case 'logit'
                                this.Learner = 'logistic';
                            otherwise
                                error(message('stats:classreg:learning:modelparams:KernelParams:BadLossFunction'));
                        end
                    else
                        switch this.LossFunction
                            case 'epsiloninsensitive'
                                this.Learner = 'svm';
                            case 'mse'
                                this.Learner = 'leastsquares';
                            otherwise
                                error(message('stats:classreg:learning:modelparams:KernelParams:UnknownRegressionLoss'));
                        end
                    end
                end
            else
                if doclass
                    switch this.Learner
                        case 'svm'
                            if ~isempty(this.LossFunction) && ~strcmpi(this.LossFunction,'hinge')
                                error(message('stats:classreg:learning:modelparams:KernelParams:BadLossForClassificationSVM'));
                            end
                            this.LossFunction = 'hinge';
                        case 'logistic'
                            if ~isempty(this.LossFunction) && ~strcmpi(this.LossFunction,'logit')
                                error(message('stats:classreg:learning:modelparams:KernelParams:BadLossForLogisticRegression'));
                            end
                            this.LossFunction = 'logit';
                        otherwise
                            error(message('stats:classreg:learning:modelparams:KernelParams:BadLearnerForClassification'));
                    end
                else
                    switch this.Learner
                        case 'svm'
                            if ~isempty(this.LossFunction) && ~strcmp(this.LossFunction,'epsiloninsensitive')
                                error(message('stats:classreg:learning:modelparams:KernelParams:BadLossForRegressionSVM'));
                            end
                            this.LossFunction = 'epsiloninsensitive';
                        case 'leastsquares'
                            if ~isempty(this.LossFunction) && ~strcmp(this.LossFunction,'mse')
                                error(message('stats:classreg:learning:modelparams:KernelParams:BadLossForLeastSquares'));
                            end
                            this.LossFunction = 'mse';
                        otherwise
                            error(message('stats:classreg:learning:modelparams:KernelParams:BadLearnerForRegression'));
                    end
                end
            end
            if isempty(this.Regularization)
                this.Regularization = 'ridge';
            end
            if isempty(this.Solver)
                this.Solver = {'lbfgs'};
            end
            if isempty(this.VerbosityLevel)
                this.VerbosityLevel = 0;
            end            
            if isempty(this.FitBias)
                this.FitBias = true;
            end
            if isempty(this.PostFitBias)
                this.PostFitBias = false;
            end
            if isempty(this.Epsilon) 
                this.Epsilon = 'auto';
            end
            if isempty(this.Lambda) && isempty(this.BoxConstraint) 
                this.BoxConstraint = 1;
                this.Lambda = 'auto'; % once n is known lambda will be 1/n because bc=1 
            elseif isempty(this.Lambda)
                this.Lambda = 'auto'; % once n is known lambda will be 1/(bc*n)
            elseif isempty(this.BoxConstraint) 
                if isnumeric(this.Lambda)
                    this.BoxConstraint = []; % boxConstraint will be computed later once n is knwon and using the numeric Lambda the user gave
                else % lambda must be 'auto'
                    this.BoxConstraint = 1;  % once n is known lambda will be 1/n because bc=1
                end
            end
            if isempty(this.BetaTolerance)
                this.BetaTolerance = 1e-4;
            end
            if isempty(this.GradientTolerance)
                this.GradientTolerance = 1e-6;
            end
            if isempty(this.IterationLimit)
                this.IterationLimit = 1000;
            end
            if isempty(this.IterationLimitBlockWise) 
                this.IterationLimitBlockWise = 100;
            end
            if isempty(this.HessianHistorySize)
                this.HessianHistorySize = 15;
            end
            if isempty(this.LineSearch)
                this.LineSearch = 'weakwolfe';
            end
            if isempty(this.KernelScale)
                this.KernelScale = 1;
            end
            if isempty(this.Transformation)
                this.Transformation = 'FastFood';
            end
            if isempty(this.BlockSize)
                this.BlockSize = 4000;
            end
            if isempty(this.ADMMIterationLimit)
                this.ADMMIterationLimit = 1;
            end
            if isempty(this.ADMMUpdateIterationLimit)
                this.ADMMUpdateIterationLimit = 100;
            end
            if isempty(this.WarmStartIterationLimit)
                this.WarmStartIterationLimit = this.ADMMUpdateIterationLimit;
            end
            if isempty(this.InitialStepSize)
                this.InitialStepSize = 1;
            end
            if isempty(this.Consensus)
                this.Consensus = 0.1;
            end
            if isempty(this.NumExpansionDimensions) 
                this.NumExpansionDimensions = 'auto';
            end
            if isempty(this.Stream)
                this.Stream = RandStream.getGlobalStream;
            end
      
        end
    end
    
end

