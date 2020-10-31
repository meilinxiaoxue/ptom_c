classdef GPImpl < classreg.learning.impl.CompactGPImpl
    
%   Copyright 2014-2017 The MathWorks, Inc.    
    
    % Properties.
    properties        
        % Input data. X and y are standardized if Standardize is true.
        X                = [];  % Supplied predictor matrix.
        y                = [];  % Supplied response values.  
        
        % Bad value of negative log likelihood.
        BadNegativeLogLikelihood = 1e20;
        
        % Active set selection history for sparse fitting. Suppose
        %
        %   eta = [beta;theta;sigma]
        %
        % where beta is a vector of explicit basis coefficients, theta is
        % the unconstrained parameter vector for the kernel function and
        % sigma is the noise standard deviation.
        %
        % For sparse fitting, we start with a parameter vector eta0 and
        % select an active set A1. Then we maximize the Gaussian process
        % model log likelihood using eta0 and A1 to get the new parameter
        % vector eta1 and the corresponding maximized log likelihood L1.
        % After Options.NumActiveSetRepeats repetitions of this process, we
        % stop. Here's an example of this process for 3 repetitions:
        %
        %   Parameter vector      Active set     Log likelihood
        %       eta1                 A1               L1
        %       eta2                 A2               L2
        %       eta3                 A3               L3
        %
        %   Li is computed using Ai and etai.
        %
        %   A1 is computed using eta0.
        %   A2 is computed using eta1.
        %   A3 is computed using eta2.
        %
        % ActiveSetHistory is a structure whose fields are of length
        % Options.NumActiveSetRepeats:
        %
        %   ParameterVector  - Cell array containing the eta vectors.
        %   ActiveSetIndices - Cell array containing active sets A (as index vector).
        %   LogLikelihood    - Vector containing log likelihoods L.
        %   CriterionProfile - Cell array containing criterion profile for
        %                      active set selection as the active set is
        %                      grown from its initial size to its final
        %                      size.
        %
        % If FitMethod is 'None', ParameterVector and LogLikelihood are
        % empty but ActiveSetIndices and CriterionProfile can be 1-by-1
        % cell arrays if active set selection is used.
        ActiveSetHistory     = [];  % Active set selection history.
        
        % BCD history if PredictMethod is 'BCD'. BCDHistory is a structure
        % with the following fields:
        %
        %   Gradient        - N-by-1 vector containing gradient of the BCD
        %                     objective function at convergence.
        %   Objective       - Scalar containing the BCD objective function 
        %                     at convergence.
        %   SelectionCounts - N-by-1 integer vector indicating the number 
        %                     of times each point was selected into a block
        %                     during BCD.        
        %
        %   The Alpha vector computed from BCD is stored in AlphaHat field.
        BCDHistory = [];        
    end
    
    % Constructor.
    methods(Access=protected)
        function this = GPImpl()
            this = this@classreg.learning.impl.CompactGPImpl();
        end
    end
    
    % Make this object.
    methods(Static)     
        function this = make(X,y,...
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
                initialStepSize,...
                iscat,...
                vrange)
            [X,catcols] = classreg.learning.internal.expandCategorical(X,iscat,vrange);

            
            % 1. Initialize empty model.
            this = classreg.learning.impl.GPImpl();
            
            % 2. Standardize data in X if required. Overwrite X by its
            % standardized version if standardize is true. We compute
            % predictor means StdMu and predictor standard deviations
            % StdSigma in both cases. If standardizing, these are saved in
            % this.StdMu and this.StdSigma respectively otherwise
            % this.StdMu and this.StdSigma are []. StdMu and StdSigma are
            % used for checking data scaling.
            if ( standardize )
                [X,StdMu,StdSigma] = classreg.learning.gputils.standardizeData(X, standardize&~catcols);
                this.StdMu         = StdMu;
                this.StdSigma      = StdSigma;
            else
                %[~,StdMu,StdSigma] = classreg.learning.gputils.standardizeData(X);
                this.StdMu         = [];
                this.StdSigma      = [];
            end
            
            % 3. Store predictor and response values.
            this.X = X;
            this.y = y;
            
            % 4. Set default value of kernelParameters (if needed) for
            % built in kernel functions. For custom kernel functions,
            % kernelParameters cannot be empty.
            import classreg.learning.modelparams.GPParams;
            if isempty(kernelParameters)                
                if internal.stats.isString(kernelFunction)
                    % Set default kernel parameters for built in kernels.
                    tiny = 1e-3;
                    switch lower(kernelFunction)
                        case lower(GPParams.Exponential)
                            sigmaL0          = max(tiny,mean(nanstd(X)));
                            sigmaF0          = max(tiny,nanstd(y)/sqrt(2));
                            kernelParameters = [sigmaL0;sigmaF0];
                        case lower(GPParams.SquaredExponential)
                            sigmaL0          = max(tiny,mean(nanstd(X)));
                            sigmaF0          = max(tiny,nanstd(y)/sqrt(2));
                            kernelParameters = [sigmaL0;sigmaF0];
                        case lower(GPParams.Matern32)
                            sigmaL0          = max(tiny,mean(nanstd(X)));
                            sigmaF0          = max(tiny,nanstd(y)/sqrt(2));
                            kernelParameters = [sigmaL0;sigmaF0];
                        case lower(GPParams.Matern52)
                            sigmaL0          = max(tiny,mean(nanstd(X)));
                            sigmaF0          = max(tiny,nanstd(y)/sqrt(2));
                            kernelParameters = [sigmaL0;sigmaF0];
                        case lower(GPParams.RationalQuadratic)
                            sigmaL0          = max(tiny,mean(nanstd(X)));
                            alpha            = 1;
                            sigmaF0          = max(tiny,nanstd(y)/sqrt(2));
                            kernelParameters = [sigmaL0;alpha;sigmaF0];
                        case lower(GPParams.ExponentialARD)
                            sigmaL0          = max(tiny,nanstd(X))';
                            sigmaF0          = max(tiny,nanstd(y)/sqrt(2));
                            kernelParameters = [sigmaL0;sigmaF0];
                        case lower(GPParams.SquaredExponentialARD)
                            sigmaL0          = max(tiny,nanstd(X))';
                            sigmaF0          = max(tiny,nanstd(y)/sqrt(2));
                            kernelParameters = [sigmaL0;sigmaF0];
                        case lower(GPParams.Matern32ARD)
                            sigmaL0          = max(tiny,nanstd(X))';
                            sigmaF0          = max(tiny,nanstd(y)/sqrt(2));
                            kernelParameters = [sigmaL0;sigmaF0];
                        case lower(GPParams.Matern52ARD)
                            sigmaL0          = max(tiny,nanstd(X))';
                            sigmaF0          = max(tiny,nanstd(y)/sqrt(2));
                            kernelParameters = [sigmaL0;sigmaF0];
                        case lower(GPParams.RationalQuadraticARD)
                            sigmaL0          = max(tiny,nanstd(X))';
                            alpha            = 1;
                            sigmaF0          = max(tiny,nanstd(y)/sqrt(2));
                            kernelParameters = [sigmaL0;alpha;sigmaF0];
                    end
                end
            end
            
            % 5. Set default value of constantKernelParameters, if empty.
            % If not empty, verify its size.
            if isempty(constantKernelParameters)
                constantKernelParameters = false(size(kernelParameters));
            else
                if ~isequal(size(constantKernelParameters), size(kernelParameters))
                    error(message('stats:classreg:learning:impl:GPImpl:GPImpl:BadConstantKernelParametersSize', ...
                        size(kernelParameters, 1), size(kernelParameters, 2)));
                end
            end
            
            % 6. Set default value for sigma.
            if isempty(sigma)
                tiny  = 1e-3;
                sigma = max(tiny,nanstd(y)/sqrt(2));
            end
            
            % 7. Set default value for constantSigma.
            if isempty(constantSigma)
                constantSigma = false;
            end
            
            % 8. Set default values of Regularization and SigmaLowerBound.
            if isempty(options.Regularization)
                tiny = 1e-3;
                options.Regularization = max(tiny,1e-2*nanstd(y));
            end
            
            if isempty(options.SigmaLowerBound)
                tiny = 1e-3;
                options.SigmaLowerBound = max(tiny,1e-2*nanstd(y));
            end
            
            % 9. Make kernel object. Also store the originally supplied
            % form of kernel function and kernel parameters.            
            [this.Theta0,this.Kernel,this.IsBuiltInKernel] = classreg.learning.gputils.makeKernelObject(kernelFunction,kernelParameters);
            this.KernelFunction                            = kernelFunction;
            this.KernelParameters                          = kernelParameters;
            
            % 10. For built in kernel functions set the distance calculation
            % method. If options.DistanceMethod is 'Accurate' then set the
            % UsePdist property of this.Kernel to true.
            if strcmpi(options.DistanceMethod,GPParams.DistanceMethodAccurate)
                this.Kernel.UsePdist = true;
            end
            
            % 11. Make basis function. Also store the originally supplied
            % form of the basis function.
            this.HFcn          = classreg.learning.gputils.makeBasisFunction(basisFunction);
            this.BasisFunction = basisFunction;            
            this.checkExplicitBasisRank(this.HFcn,this.X);            
            
            % 12. Save initial values of Beta and Sigma.
            this.Beta0  = beta;
            this.Sigma0 = sigma;            
            
            % 13. Save fitting options.
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
            this.ConstantSigma = constantSigma;
            this.InitialStepSize  = initialStepSize;
            
            % 14. Is the active set supplied to us?
            if isempty(activeSet)
                this.IsActiveSetSupplied = false;
            else
                this.IsActiveSetSupplied = true;
            end
            
            % 15. Do the fit. This method should fill BetaHat, ThetaHat,
            % SigmaHat, AlphaHat, ActiveSet (if needed), ActiveSetX and
            % LFactor's needed for making predictions.
            this = doFit(this);
        end
    end
     
    % Create compact object.
    methods        
        function cmp = compact(this)
            cmp = classreg.learning.impl.CompactGPImpl();
            
            % Fitting options supplied to us.
            cmp.FitMethod        = this.FitMethod;
            cmp.PredictMethod    = this.PredictMethod;
            cmp.ActiveSet        = this.ActiveSet;
            cmp.ActiveSetSize    = this.ActiveSetSize;
            cmp.ActiveSetMethod  = this.ActiveSetMethod;
            cmp.Standardize      = this.Standardize;
            cmp.Verbose          = this.Verbose;
            cmp.CacheSize        = this.CacheSize;
            cmp.Options          = this.Options;
            cmp.Optimizer        = this.Optimizer;
            cmp.OptimizerOptions = this.OptimizerOptions;
            cmp.ConstantKernelParameters = this.ConstantKernelParameters;
            cmp.ConstantSigma    = this.ConstantSigma;
            cmp.InitialStepSize  = this.InitialStepSize;
        
            % Original form of kernel function, kernel parameters and basis function.
            cmp.KernelFunction   = this.KernelFunction;
            cmp.KernelParameters = this.KernelParameters;
            cmp.BasisFunction    = this.BasisFunction;
            
            % Kernel function and basis function.
            cmp.Kernel           = this.Kernel;
            cmp.IsBuiltInKernel  = this.IsBuiltInKernel;
            cmp.HFcn             = this.HFcn;
            
            % Standardization related quantities.
            cmp.StdMu            = this.StdMu;
            cmp.StdSigma         = this.StdSigma;
            
            % Initial parameter values.
            cmp.Beta0            = this.Beta0;
            cmp.Theta0           = this.Theta0;
            cmp.Sigma0           = this.Sigma0;
            
            % Estimated parameter values.
            cmp.BetaHat          = this.BetaHat;
            cmp.ThetaHat         = this.ThetaHat;
            cmp.SigmaHat         = this.SigmaHat;
            
            % Things needed to make predictions and compute standard deviations.
            cmp.IsActiveSetSupplied = this.IsActiveSetSupplied;                     
            cmp.ActiveSetX          = this.ActiveSetX;
            cmp.AlphaHat            = this.AlphaHat;
            cmp.LFactor             = [];
            cmp.LFactor2            = [];
        
            % Lower bound on noise standard deviation.
            cmp.SigmaLB             = this.SigmaLB;
            
            % Is model ready to make predictions?
            cmp.IsTrained           = this.IsTrained;
            
            % Other useful things.
            cmp.LogLikelihoodHat    = this.LogLikelihoodHat;
        end
    end
    
    % Generic fitting method.
    methods       
        function this = doFit(this)
        %doFit - Fits a GPR model.
        %   this = doFit(this) takes an unfitted GPImpl object and returns
        %   the fitted object.  

            %   Fitting of a GPR model involves two steps:
            %
            %   1. Computation of BetaHat, ThetaHat, SigmaHat.
            %   2. Computation of weights AlphaHat, ActiveSetX (and possibly LFactors) for making predictions.
            %
            %   If needed ActiveSet may be computed during step 1 or 2.
            
            import classreg.learning.modelparams.GPParams;
            warnState  = warning('query','all');
            warning('off','MATLAB:nearlySingularMatrix');
            warning('off','MATLAB:illConditionedMatrix');
            warning('off','MATLAB:singularMatrix');
            warning('off','MATLAB:rankDeficientMatrix');
            cleanupObj = onCleanup(@() warning(warnState));
            
            % 1. Computation of BetaHat, ThetaHat, SigmaHat. For FitMethod
            % SD/SR/FIC we may also compute an ActiveSet.
            switch lower(this.FitMethod)
                
                case lower(GPParams.FitMethodNone)
                    
                    this = doFitMethodNone(this);
                    
                case lower(GPParams.FitMethodExact)
                    
                    this = doFitMethodExact(this);
                    
                case lower(GPParams.FitMethodSD)
                            
                    this = doFitMethodSD(this);
                    
                case {lower(GPParams.FitMethodFIC),lower(GPParams.FitMethodSR)}
                                
                    this = doFitMethodSparse(this);
            end
            
            % 2. Computation of AlphaHat, ActiveSetX (possibly LFactor's)
            % for making predictions. For PredictMethod SD and SR/FIC, we
            % may compute an ActiveSet as well.
            if ( this.Verbose > 0 )
                alphaEstimationMessageStr = getString(message('stats:classreg:learning:impl:GPImpl:GPImpl:MessageAlphaEstimation',this.PredictMethod));
                fprintf('\n');
                fprintf('%s\n',alphaEstimationMessageStr);
            end
            
            switch lower(this.PredictMethod)
                
                case lower(GPParams.PredictMethodSD)
                    
                    this = doPredictMethodSD(this);                    
                    
                case lower(GPParams.PredictMethodExact)
                    
                    this = doPredictMethodExact(this);                    
                    
                case lower(GPParams.PredictMethodBCD)
                    
                    this = doPredictMethodBCD(this);                    
                    
                case {lower(GPParams.PredictMethodFIC),lower(GPParams.PredictMethodSR)}
                    
                    this = doPredictMethodSparse(this);                    
            end
            
            % Mark model as ready to make predictions.
            this.IsTrained = true;
            
            % Store ThetaHat inside Kernel object.
            this.Kernel = setTheta(this.Kernel,this.ThetaHat);            
        end
    end
    
    % Helper methods for doFit.
    methods        
        % Process various FitMethods.
        function this = doFitMethodNone(this)            
            % 1.1 Copy initial values into estimated values.
            this.BetaHat  = this.Beta0;
            this.ThetaHat = this.Theta0;
            this.SigmaHat = this.Sigma0;            
        end
        
        function this = doFitMethodExact(this)            
            % 1.1 Get ThetaHat, SigmaHat - Beta is profiled out
            % during optimization.
            [this.ThetaHat,this.SigmaHat,this.LogLikelihoodHat] = estimateThetaHatSigmaHatExact(this,this.X,this.y,this.Beta0,this.Theta0,this.Sigma0);
            % 1.2 Use ThetaHat and SigmaHat to get BetaHat - you
            % get LFactor for free in the process. Store it in the
            % object so that if the PredictMethod is also Exact, we
            % don't have to recompute this.
            [this.BetaHat,this.LFactor] = computeBetaHatExact(this,this.X,this.y,this.ThetaHat,this.SigmaHat);            
        end
        
        function this = doFitMethodSD(this)
            import classreg.learning.modelparams.GPParams;
            if this.IsActiveSetSupplied
                % 1.1 If ActiveSet is user supplied, just use the
                % ActiveSet to subsample the data and compute
                % ThetaHat and SigmaHat based on that.
                activeSet                     = this.ActiveSet;
                XA                            = this.X(activeSet,:);
                yA                            = this.y(activeSet,1);
                [this.ThetaHat,this.SigmaHat,this.LogLikelihoodHat] = estimateThetaHatSigmaHatExact(this,XA,yA,this.Beta0,this.Theta0,this.Sigma0);
                % 1.2 Use ThetaHat and SigmaHat to compute BetaHat.
                % Again, we get LFactor for free which we can reuse
                % if the PredictMethod is also SD.
                [this.BetaHat,this.LFactor] = computeBetaHatExact(this,XA,yA,this.ThetaHat,this.SigmaHat);
            else
                % 1.1 If ActiveSet is not supplied we interleave
                % active set selection with parameter estimation
                % for all ActiveSetMethod values except Random.
                
                    % 1.1.1 How many interleaved reps?
                    if strcmpi(this.ActiveSetMethod,GPParams.ActiveSetMethodRandom)
                        numreps = 1;
                    else
                        numreps = this.Options.NumActiveSetRepeats;
                    end

                    % 1.1.2 Current beta, theta, sigma.
                    beta    = this.Beta0;
                    theta   = this.Theta0;
                    sigma   = this.Sigma0;

                    % 1.1.3 Do interleaved active set selection
                    % along with parameter estimation. When this
                    % loop ends we have parameter estimates, active
                    % set as well as an LFactor for the active set
                    % which can be reused if PredictMethod is SD.
                    activeSetHistory = struct();
                    for reps = 1:numreps
                        [activeSet,activeSetIndices,critProfile] = selectActiveSet(this,this.X,this.y,beta,theta,sigma);
                        XA                                       = this.X(activeSet,:);
                        yA                                       = this.y(activeSet,1);
                        [theta,sigma,loglik]                     = estimateThetaHatSigmaHatExact(this,XA,yA,beta,theta,sigma);
                        [beta,LFactor]                           = computeBetaHatExact(this,XA,yA,theta,sigma);

                        activeSetHistory.ParameterVector{reps}   = [beta;theta;sigma];
                        activeSetHistory.ActiveSetIndices{reps}  = activeSetIndices;
                        activeSetHistory.LogLikelihood(reps)     = loglik;
                        activeSetHistory.CriterionProfile{reps}  = critProfile;
                    end
                
                % 1.2 Store estimated parameters, LFactor and
                % estimated ActiveSet.
                this.BetaHat          = beta;
                this.ThetaHat         = theta;
                this.SigmaHat         = sigma;
                this.LFactor          = LFactor;
                this.ActiveSet        = activeSet;
                this.LogLikelihoodHat = loglik;
                this.ActiveSetHistory = activeSetHistory;
            end
        end
        
        function this = doFitMethodSparse(this)
            import classreg.learning.modelparams.GPParams;
            % 1.1 Are we doing SR or FIC?
            if strcmpi(this.FitMethod,GPParams.FitMethodFIC)
                useFIC = true;
            else
                useFIC = false;
            end
            
            % 1.2 Are we using QR factorization based fitting?
            useQR = this.Options.UseQR;
            
            if this.IsActiveSetSupplied
                % 1.3 If ActiveSet is user supplied, use it and
                % compute ThetaHat and SigmaHat based on that.
                [this.ThetaHat,this.SigmaHat,this.LogLikelihoodHat]     = estimateThetaHatSigmaHatSparse(this,this.X,this.y,this.ActiveSet,this.Beta0,this.Theta0,this.Sigma0,useFIC,useQR);
                % 1.4 Use ThetaHat and SigmaHat to compute BetaHat.
                % Also fill in AlphaHat, LFactor and LFactor2. If
                % predict method is also SR/FIC and matches the fit
                % method, we do not need to do more computations.
                [this.AlphaHat,this.BetaHat,this.LFactor,this.LFactor2] = computeAlphaHatBetaHatSparseV(this,this.X,this.y,this.ActiveSet,[],this.ThetaHat,this.SigmaHat,useFIC);
            else
                % 1.3 If ActiveSet is not supplied we interleave
                % active set selection with parameter estimation
                % for all ActiveSetMethod values except Random.
                
                    % 1.3.1 How many interleaved reps?
                    if strcmpi(this.ActiveSetMethod,GPParams.ActiveSetMethodRandom)
                        numreps = 1;
                    else
                        numreps = this.Options.NumActiveSetRepeats;
                    end

                    % 1.3.2 Current beta, theta, sigma.
                    beta    = this.Beta0;
                    theta   = this.Theta0;
                    sigma   = this.Sigma0;

                    % 1.3.3 Do interleaved active set selection
                    % along with parameter estimation. When this
                    % loop ends we have parameter estimates, active
                    % set as well as an LFactor's for the active
                    % set.
                    activeSetHistory = struct();
                    for reps = 1:numreps
                        [activeSet,activeSetIndices,critProfile] = selectActiveSet(this,this.X,this.y,beta,theta,sigma);
                        [theta,sigma,loglik]                     = estimateThetaHatSigmaHatSparse(this,this.X,this.y,activeSet,beta,theta,sigma,useFIC,useQR);
                        [alphaHat,beta,LFactor,LFactor2]         = computeAlphaHatBetaHatSparseV(this,this.X,this.y,activeSet,[],theta,sigma,useFIC);

                        activeSetHistory.ParameterVector{reps}   = [beta;theta;sigma];
                        activeSetHistory.ActiveSetIndices{reps}  = activeSetIndices;
                        activeSetHistory.LogLikelihood(reps)     = loglik;
                        activeSetHistory.CriterionProfile{reps}  = critProfile;
                    end
                
                % 1.4 Store estimated parameters, LFactor's,
                % alphaHat and estimated ActiveSet.
                this.BetaHat          = beta;
                this.ThetaHat         = theta;
                this.SigmaHat         = sigma;
                this.LFactor          = LFactor;
                this.LFactor2         = LFactor2;
                this.ActiveSet        = activeSet;
                this.AlphaHat         = alphaHat;
                this.LogLikelihoodHat = loglik;
                this.ActiveSetHistory = activeSetHistory;
            end
        end
                
        % Process various PredictMethods.
        function this = doPredictMethodSD(this)
            import classreg.learning.modelparams.GPParams;
            if strcmpi(this.FitMethod,GPParams.FitMethodSD) && ~isempty(this.ActiveSet) && ~isempty(this.LFactor)
                % 2.1 If FitMethod is also SD and ActiveSet is not
                % empty and if LFactor is available, we reuse it.
                activeSet       = this.ActiveSet;
                XA              = this.X(activeSet,:);
                yA              = this.y(activeSet,1);
                this.AlphaHat   = computeAlphaHatExact(this,XA,yA,this.BetaHat,this.LFactor);
                this.ActiveSetX = XA;
            else
                % 2.1 If ActiveSet is not known, we estimate it
                % first, followed by the computation of AlphaHat
                % and LFactor.
                if isempty(this.ActiveSet)
                    activeSetHistory                              = struct();
                    [this.ActiveSet,activeSetIndices,critProfile] = selectActiveSet(this,this.X,this.y,this.BetaHat,this.ThetaHat,this.SigmaHat);
                    activeSetHistory.ActiveSetIndices{1}          = activeSetIndices;
                    activeSetHistory.CriterionProfile{1}          = critProfile;
                    activeSetHistory.ParameterVector              = [];
                    activeSetHistory.LogLikelihood                = [];
                    this.ActiveSetHistory                         = activeSetHistory;
                end
                activeSet                      = this.ActiveSet;
                XA                             = this.X(activeSet,:);
                yA                             = this.y(activeSet,1);
                [this.AlphaHat,~,this.LFactor] = computeAlphaHatBetaHatExact(this,XA,yA,this.BetaHat,this.ThetaHat,this.SigmaHat);
                this.ActiveSetX                = XA;
            end
        end
        
        function this = doPredictMethodExact(this)
            import classreg.learning.modelparams.GPParams;
            if strcmpi(this.FitMethod,GPParams.FitMethodExact) && ~isempty(this.LFactor)
                % 2.1 If FitMethod is Exact and LFactor is available,
                % we can reuse it to compute AlphaHat.
                this.AlphaHat   = computeAlphaHatExact(this,this.X,this.y,this.BetaHat,this.LFactor);
                this.ActiveSetX = this.X;
                this.ActiveSet  = true(size(this.X,1),1);
            else
                % 2.1 Compute AlphaHat and LFactor from scratch.
                [this.AlphaHat,~,this.LFactor] = computeAlphaHatBetaHatExact(this,this.X,this.y,this.BetaHat,this.ThetaHat,this.SigmaHat);
                this.ActiveSetX                = this.X;
                this.ActiveSet                 = true(size(this.X,1),1);
            end
        end
        
        function this = doPredictMethodBCD(this)            
            % 2.1 Compute AlphaHat using BCD.
            bcdHistory                                = struct();
            [this.AlphaHat,gHat,fHat,selectionCounts] = computeAlphaHatBCD(this,this.X,this.y,this.BetaHat,this.ThetaHat,this.SigmaHat);
            this.ActiveSetX                           = this.X;
            this.ActiveSet                            = true(size(this.X,1),1);
            bcdHistory.Gradient                       = gHat;
            bcdHistory.Objective                      = fHat;
            bcdHistory.SelectionCounts                = selectionCounts;
            this.BCDHistory                           = bcdHistory;
        end
        
        function this = doPredictMethodSparse(this)
            import classreg.learning.modelparams.GPParams;
            % 2.1 Are we using SR or FIC?
            if strcmpi(this.PredictMethod,GPParams.PredictMethodFIC)
                useFIC = true;
            else
                useFIC = false;
            end
            
            % 2.2 Select ActiveSet if needed. We will enter the if
            % block below only for FitMethod 'None' and 'Exact'.
            if isempty(this.ActiveSet)
                activeSetHistory                              = struct();
                [this.ActiveSet,activeSetIndices,critProfile] = selectActiveSet(this,this.X,this.y,this.BetaHat,this.ThetaHat,this.SigmaHat);
                activeSetHistory.ActiveSetIndices{1}          = activeSetIndices;
                activeSetHistory.CriterionProfile{1}          = critProfile;
                activeSetHistory.ParameterVector              = [];
                activeSetHistory.LogLikelihood                = [];
                this.ActiveSetHistory                         = activeSetHistory;
            end
            
            % 2.3 Compute AlphaHat, LFactor and LFactor2 using
            % SR/FIC. If PredictMethod matches the FitMethod, we
            % have already done this.
            if strcmpi(this.FitMethod,this.PredictMethod)
                % AlphaHat and LFactor's have already been
                % computed.
            else
                % FitMethod is SR and PredictMethod is FIC or vice
                % versa.
                [this.AlphaHat,~,this.LFactor,this.LFactor2] = computeAlphaHatBetaHatSparseV(this,this.X,this.y,this.ActiveSet,this.BetaHat,this.ThetaHat,this.SigmaHat,useFIC);
            end
            
            % 2.4 Set ActiveSetX.
            this.ActiveSetX = this.X(this.ActiveSet,:);
        end        
    end
    
    % Methods for exact GPR.
    methods
    
        function [betaHat,L] = computeBetaHatExact(this,X,y,theta,sigma)
        %computeBetaHatExact - Compute profiled coefficients beta.
        %   [betaHat,L] = computeBetaHatExact(this,X,y,theta,sigma) takes a
        %   GPImpl object this, N-by-D matrix X, N-by-1 vector y,
        %   unconstrained parameter vector for the kernel function theta
        %   and noise standard deviation sigma and returns a vector betaHat
        %   of profiled coefficients beta and the lower triangular Cholesky
        %   factor L of K(X,X) + sigma^2*I_N.
            
            % 1. Get basis matrix.
            H = this.HFcn(X);
            
            % 2. Get L factor.            
            L = computeLFactorExact(this,X,theta,sigma);                        
            
            % 3. Compute betaHat if needed.
            if ( size(H,2) == 0 )
                betaHat = zeros(0,1);
            else
                Linvy   = L \ y;
                LinvH   = L \ H;
                betaHat = LinvH \ Linvy;
            end            
            
        end % end of computeBetaHatExact.
        
        function alphaHat = computeAlphaHatExact(this,X,y,beta,L)
        %computeAlphaHatExact - Compute alphaHat using precomputed Cholesky factor L.
        %   alphaHat = computeAlphaHatExact(this,X,y,beta,L) takes a GPImpl
        %   object this, N-by-D matrix X, N-by-1 vector y, explicit basis
        %   coefficient vector beta and a pre-computed N-by-N lower
        %   triangular Cholesky factor of the N-by-N matrix (K + sigma^2*I_N) 
        %   and computes:
        %
        %   alphaHat = (K + sigma^2*I_N)^{-1} * (y - H*beta)
        %
        %   See section 10.1 in GPR theory spec. If beta is empty, then
        %   beta is replaced by its profiled value (section 5.1 in GPR
        %   theory spec).
            
            % 1. Get basis matrix.
            H = this.HFcn(X);
                        
            % 2. Compute betaHat if needed.
            if isempty(beta)
                % Need to compute betaHat.
                if ( size(H,2) == 0 )
                    betaHat = zeros(0,1);
                else
                    Linvy   = L \ y;
                    LinvH   = L \ H;
                    betaHat = LinvH \ Linvy;
                end
            else
                % Set betaHat equal to beta.
                betaHat = beta;
            end
            
            % 3. Get alphaHat using L.
            % NOTE: alphaHat can also be computed like this:
            % alphaHat = classreg.learning.gputils.solveUsingChol(L,y-H*betaHat,'L');
            % This is slightly faster compared to \ since it calls LAPACK 
            % DPOTRS directly.
            alphaHat = (L' \ (L \ (y - H*betaHat)));
            
        end % end of computeAlphaHatExact.
        
        function [alphaHat,betaHat,L] = computeAlphaHatBetaHatExact(this,X,y,beta,theta,sigma)
        %computeAlphaHatBetaHatExact - Compute quantities needed to make predictions for exact GPR.
        %   [alphaHat,betaHat,L] = computeAlphaHatBetaHatExact(this,X,y,beta,theta,sigma) 
        %   takes a GPImpl object this, N-by-D matrix of predictors X,
        %   N-by-1 response vector y, GPR parameters beta, theta, sigma and
        %   computes alphaHat and L needed for making predictions. If K is
        %   the N-by-N kernel matrix then:
        %
        %   alphaHat = (K + sigma^2*I_N)^{-1} * (y - H*beta)
        %
        %   and 
        %
        %   L = lower triangular Cholesky factor of (K + sigma^2*I_N).
        %
        %   See section 10.1 in GPR theory spec. If beta is not empty, then
        %   betaHat is equal to beta.
        %
        %   If beta is empty, then betaHat is computed as described in
        %   section 5.1 of GPR theory spec. In this case, the value of
        %   alphaHat is based on this computed value of beta.
                    
            % 1. Get basis matrix.
            H = this.HFcn(X);
            
            % 2. Get L factor.            
            L = computeLFactorExact(this,X,theta,sigma);                        
            
            % 3. Compute betaHat if needed.
            if isempty(beta)
                % Need to compute betaHat.
                if ( size(H,2) == 0 )
                    betaHat = zeros(0,1);
                else
                    Linvy   = L \ y;
                    LinvH   = L \ H;
                    betaHat = LinvH \ Linvy;
                end
            else
                % Set betaHat equal to beta.
                betaHat = beta;
            end
            
            % 4. Get alphaHat using L.
            % NOTE: alphaHat can also be computed like this:
            % alphaHat = classreg.learning.gputils.solveUsingChol(L,y-H*betaHat,'L');
            % This is slightly faster compared to \ since it calls LAPACK 
            % DPOTRS directly.
            alphaHat = (L' \ (L \ (y - H*betaHat)));
        
        end % end of computeAlphaHatBetaHatExact.            
       
        function [thetaHat,sigmaHat,loglikHat] = estimateThetaHatSigmaHatExact(this,X,y,beta0,theta0,sigma0)
        %estimateThetaHatSigmaHatExact - Hyperparameter estimation for exact GPR.
        %   [thetaHat,sigmaHat,loglikHat] = estimateThetaHatSigmaHatExact(this,X,y,beta0,theta0,sigma0)
        %   takes an unfitted GPImpl object this, N-by-D matrix X, N-by-1
        %   vector y and initial values beta0, theta0 and sigma0 of the GPR
        %   parameters and returns estimated values thetaHat and sigmaHat
        %   by maximizing the profiled marginal log likelihood of the GPR
        %   model. loglikHat is the maximized profiled log likelihood of
        %   the GPR model.
        %
        %   For built-in kernel functions, we use analytical derivatives of
        %   the objective function (negative profiled log likelihood)
        %   whereas for custom kernel functions, numerical derivatives are
        %   used. See section 5 of GPR theory spec.
        
            % 1. Make objective function for minimization. This is the
            % negative profiled log likelihood of the GPR model where
            % coefficients beta are profiled out analytically and so the
            % vector of variables for the purposes of optimization is:
            %
            %   phi = [theta;gamma]
            %
            % where gamma is unconstrained and parameterizes the noise
            % standard deviation:
            %
            %   sigma = sigmaLB + exp(gamma)
            %
            % and sigmaLB is a lower bound on sigma.
            %
            % objFun below can return analytical derivatives for built-in
            % kernel functions like this:
            %
            %   [Fun,gradFun] = objFun(phi)
            %
            % For custom kernel functions, derivative information is not
            % available and so objFun should be called like this:
            %
            %   Fun = objFun(phi)
            %
            % Also, get the number of observations N, number of predictors 
            % D and decide if we can cache distances during fitting.
            [N,D]             = size(X);
            M                 = N;
            usecache          = checkCacheSizeForFitting(this,N,D,M);
            [objFun,haveGrad] = makeNegativeProfiledLogLikelihoodExact(this,X,y,beta0,theta0,sigma0,usecache);                   
            
            % 2. Initial value of phi.
            sigmaLB = this.Options.SigmaLowerBound;
            if this.ConstantSigma
                gamma0  = log(max(1e-6,sigma0-sigmaLB));
            else
                gamma0  = log(max(1e-3,sigma0-sigmaLB));
            end
            phi0    = [theta0;gamma0];
            
            % 3. Minimize objFun starting at phi0. Disable warning messages
            % during optimization and restore them when this function
            % exits. Display one line summary of FitMethod and Optimizer if
            % Verbose is > 0.
            warnState  = warning('query','all');
            warning('off','MATLAB:nearlySingularMatrix');
            warning('off','MATLAB:illConditionedMatrix');
            warning('off','MATLAB:singularMatrix');
            warning('off','MATLAB:rankDeficientMatrix');
            cleanupObj = onCleanup(@() warning(warnState));
            
            if ( this.Verbose > 0 )
                parameterEstimationMessageStr = getString(message('stats:classreg:learning:impl:GPImpl:GPImpl:MessageParameterEstimation',this.FitMethod,this.Optimizer));
                fprintf('\n');
                fprintf('%s\n',parameterEstimationMessageStr);
            end
            
            if this.ConstantSigma || any(this.ConstantKernelParameters)
                [phiHat,nloglikHat,cause] = doMinimizationWithSomeConstParams(this,objFun,phi0,haveGrad);
            else
                [phiHat,nloglikHat,cause] = doMinimization(this,objFun,phi0,haveGrad);
            end            
            
            % 4. Display convergence warning if needed.
            if ( cause ~= 0 && cause ~= 1 )
                warning(message('stats:classreg:learning:impl:GPImpl:GPImpl:OptimizerUnableToConverge',this.Optimizer));                
            end
            
            % 5. Extract thetaHat and sigmaHat from phiHat.
            s        = length(phiHat);
            thetaHat = phiHat(1:s-1,1);
            gammaHat = phiHat(s,1);
            sigmaHat = sigmaLB + exp(gammaHat);
            
            % 6. Return maximized log likelihood.
            loglikHat = -1*nloglikHat;
            
        end % end of estimateThetaHatSigmaHatExact.
        
        function [objFun,haveGrad] = makeNegativeProfiledLogLikelihoodExact(this,X,y,beta0,theta0,sigma0,usecache) %#ok<INUSL>
        %makeNegativeProfiledLogLikelihoodExact - Makes objective function for minimization for exact GPR.
        %   [objFun,haveGrad] = makeNegativeProfiledLogLikelihoodExact(this,X,y,beta0,theta0,sigma0,usecache)
        %   takes a GPImpl object this, a N-by-D matrix X, N-by-1 vector y
        %   and initial values of GPR parameters beta0, theta0 and sigma0
        %   and returns an objective function objFun for minimization.
        %   Input usecache is a boolean indicating whether squared
        %   Euclidean distances should be cached for built-in kernels.
        %   Output haveGrad is true if objFun can return gradient
        %   information and is false otherwise (see below for more info).
        %
        %   o objFun accepts a parameter vector phi such that:
        %
        %       phi = [theta;gamma]
        %
        %   where gamma is unconstrained and parameterizes the noise 
        %   standard deviation:
        %
        %       sigma = sigmaLB + exp(gamma)
        %
        %   and sigmaLB is a lower bound on sigma.
        %
        %   o For built-in kernel functions, objFun can be called like this:
        %
        %   [Fun,gradFun] = objFun(phi)
        %
        %   where Fun is the function value and gradFun is the gradient of
        %   the function evaluated at phi.
        %
        %   o For custom kernel functions, objFun does not return gradient
        %   information and it must be called like this:
        %
        %   Fun = objFun(phi)
            
            % 1. Make kernel as function of theta. kfcn below can be
            % called like this:
            %             [K,DK] = kfcn(ThetaNew)
            %  
            %     where
            %  
            %     o ThetaNew is some new value of Theta.
            %     o K  = K(X,X | ThetaNew).
            %     o DK = A function handle that accepts an integer i such that 
            %            DK(i) is the derivative of K(X,X | Theta) w.r.t. 
            %            Theta(i) evaluated at ThetaNew.
            %
            % For custom kernel functions, DK is [].
            assert( islogical(usecache) );
            kfcn = makeKernelAsFunctionOfTheta(this.Kernel,X,X,usecache);            
        
            % 2. Get basis matrix and the number of columns in it.
            H = this.HFcn(X);
            p = size(H,2);
            
            % 3. Number of observations and diagonal offset for kernel.
            N          = size(X,1);
            diagOffset = this.Options.DiagonalOffset;
            
            % 4. Compute constant that appears in profiled log likelihood.
            % c below is such that profiled log likelihood has the constant
            % -c and negative profiled log likelihood has the constant c.
            c = (N/2)*log(2*pi);
            
            % 5. Do we have a built-in kernel function. If so, gradient
            % information is available.
            isbuiltin = this.IsBuiltInKernel;
            if isbuiltin
                haveGrad = true;
            else
                haveGrad = false;
            end
            
            % 6. Length of vector phi, lower bound on sigma and bad value
            % for negative log likelihood - to be returned when computation
            % of negative log likelihood generates NaN/Inf values or when
            % the required Cholesky factorization fails. One example, when
            % this may happen is when H is rank deficient.
            s          = length(theta0) + 1;
            sigmaLB    = this.Options.SigmaLowerBound;
            badnloglik = this.BadNegativeLogLikelihood;
            
            % 7. Make objFun. This returns the *negative* log likelihood
            % and its gradient for minimization.
            objFun = @f1;
            function [nloglik,gnloglik] = f1(phi)
                                
                % 7.1 Extract theta and sigma from phi.
                theta = phi(1:s-1,1);
                gamma = phi(s,1);
                sigma = sigmaLB + exp(gamma);
                
                % 7.2 Get N-by-N kernel matrix V = (K + sigma^2*I_N) and a
                % function handle DK. Note that we add a diagonal offset
                % when creating V to deal with the sigma = 0 case. This may
                % not be necessary with the lower bounding of sigma but
                % consider this a precautionary measure.
                [V,DK]       = kfcn(theta);
                V(1:N+1:N^2) = V(1:N+1:N^2) + (sigma^2 + diagOffset);
                                
                % 7.3 Get lower triangular Cholesky factor of V.
                [L,flag] = chol(V,'lower');
                if ( flag ~= 0 )
                    % V is not positive definite - numerically speaking.
                    % Return a bad value for the negative log likelihood
                    % (the thing being minimized).
                    nloglik = badnloglik;
                    if nargout > 1
                        if isbuiltin
                            gnloglik = zeros(s,1);
                        else
                            gnloglik = [];
                        end
                    end
                    return;
                end
                
                % 7.4 Compute betaHat.
                if ( p == 0 )
                    % No basis functions.
                    Linvy   = L \ y;
                    LinvH   = zeros(N,0);
                    betaHat = zeros(0,1);
                else
                    % Non empty basis functions.
                    Linvy   = L \ y;
                    LinvH   = L \ H;
                    betaHat = LinvH \ Linvy;
                end
                
                % 7.5 Compute loglik and multiply it by -1. 
                % LinvAdjy = L \ (y - H*betaHat);
                LinvAdjy = (Linvy - LinvH*betaHat);
                loglik   = -0.5*(LinvAdjy'*LinvAdjy) - c - sum(log(abs(diag(L))));
                nloglik  = -1*loglik;
                
                % 7.6 Compute gradient vector gloglik if needed.
                if nargout > 1 
                    if haveGrad
                        % Derivative information is available.
                        
                        % 7.6.1 Get alphaHat = V^{-1}*(y-H*betaHat).
                        alphaHat = L' \ LinvAdjy;
                        
                        % 7.6.2 Get inverse of L.
                        %Linv = classreg.learning.gputils.invertTriangular(L,'L');
                        Linv = L \ eye(N);
                        
                        % 7.6.3 Get gradient vector with respect to element
                        % r of phi. Note that phi = [theta;gamma] and s =
                        % length(phi).
                        gloglik = zeros(s,1);
                        
                            % 7.6.3.1 Derivatives w.r.t. elements of theta. 
                            % phi(r) = theta(r) for r = 1..s-1.
                            for r = 1:s-1
                                % Derivative of K w.r.t. theta(r).
                                DKr = DK(r);
                                % Quadratic term.                            
                                quadTerm   = 0.5*(alphaHat'*DKr*alphaHat);
                                % Trace term. trace(A'*B) = sum(sum(A.*B,1)).
                                DKr        = L \ DKr;                            
                                traceTerm  = -0.5*sum(sum(Linv.*DKr,1));
                                % Combine terms.
                                gloglik(r) = quadTerm + traceTerm;
                            end
                            
                            % 7.6.3.2 Derivatives w.r.t. gamma. 
                            % phi(s) = gamma. The term sigma_sigmaLB
                            % replaces sigma^2 when there is a lower bound
                            % on sigma.
                                % Quadratic term.
                                sigma_sigmaLB = sigma*(sigma - sigmaLB);
                                quadTerm      = sigma_sigmaLB*(alphaHat'*alphaHat);                           
                                % Trace term.
                                traceTerm     = -sigma_sigmaLB*sum(sum(Linv.*Linv,1));                                
                                % Combine terms.
                                gloglik(s)    = quadTerm + traceTerm;
                            
                        % 7.6.4 Multiply gloglik by -1.
                        gnloglik = -1*gloglik;
                    else
                        % Derivative information is not available.
                        gnloglik = [];
                    end
                end
            end
        end % end of makeNegativeProfiledLogLikelihoodExact.
        
        function loglikHat = computeLogLikelihoodExact(this)
        %computeLogLikelihoodExact - Compute exact GPR log likelihood.
        %   loglikHat = computeLogLikelihoodExact(this) takes a GPImpl
        %   object this and computes exact GPR log likelihood using
        %   predictors this.X, response this.y and parameters this.BetaHat,
        %   this.ThetaHat and this.SigmaHat.
        
            % 1. Ensure that we have a trained object and disable some
            % common warnings.
            assert(this.IsTrained);
            warnState  = warning('query','all');
            warning('off','MATLAB:nearlySingularMatrix');
            warning('off','MATLAB:illConditionedMatrix');
            warning('off','MATLAB:singularMatrix');
            warning('off','MATLAB:rankDeficientMatrix');
            cleanupObj = onCleanup(@() warning(warnState));
            
            % 2. Get X, y and H.
            X = this.X;
            y = this.y;
            H = this.HFcn(X);
            
            % 3. Get beta, theta and sigma.
            beta  = this.BetaHat;
            theta = this.ThetaHat;
            sigma = this.SigmaHat;
            
            % 4. Evaluate K(X,X | theta) - tentatively save in variable V.
            kfcn = makeKernelAsFunctionOfXNXM(this.Kernel,theta);
            V    = kfcn(X,X);
            
            % 5. Update V to hold K(X,X) + sigma^2*eye(N).
            diagOffset   = this.Options.DiagonalOffset;
            N            = size(X,1);
            V(1:N+1:N^2) = V(1:N+1:N^2) + (sigma^2 + diagOffset);
            
            % 6. Compute lower triangular Cholesky factor of V. If that
            % doesn't work, return a bad value for log likelihood.
            [L,flag] = chol(V,'lower');
            if ( flag ~= 0 )
                % V is not positive definite - numerically speaking.                
                loglikHat = -1*this.BadNegativeLogLikelihood;
                return;
            end
            
            % 7. Compute log likelihood - note we are not profiling beta.
            LInvAdjy  = L \ (y - H*beta);            
            loglikHat = -0.5*(LInvAdjy'*LInvAdjy) - 0.5*N*log(2*pi) - sum(log(abs(diag(L))));            
            
        end % end of computeLogLikelihoodExact.
        
    end
    
    % Methods for BCD.
    methods       
            
        function [alphaHat,gHat,fHat,selectionCounts] = computeAlphaHatBCD(this,X,y,beta,theta,sigma)
        %computeAlphaHatBCD - Computes alphaHat using block coordinate descent (BCD).
        %   [alphaHat,gHat,fHat,selectionCounts] = computeAlphaHatBCD(this,X,y,beta,theta,sigma) 
        %   takes a GPImpl object this, N-by-D predictor matrix X, N-by-1
        %   response vector y, GPR parameters beta, theta, sigma and
        %   computes alphaHat needed for making predictions. If K is the
        %   N-by-N kernel matrix then:
        %
        %   alphaHat = (K + sigma^2*I_N)^{-1} * (y - H*beta)
        %
        %   See section 10.1 in GPR theory spec.
        %
        %   gHat is the N-by-1 gradient vector of the BCD objective
        %   function at convergence. fHat is the minimized BCD objective
        %   function and selectionCounts is a N-by-1 integer vector
        %   indicating the number of times each point was selected into a
        %   BCD block during BCD iterations.
            
            % 1. Make kernel as function of XN and XM for fixed theta. kfun
            % below can be called like this: KNM = kfun(XN,XM).
            kfun = makeKernelAsFunctionOfXNXM(this.Kernel,theta);
            
            % 2. Make function to get the diagonal of K(X,X). diagkfun
            % below can be called like this: diagK = diagkfun(XN).
            diagkfun = makeDiagKernelAsFunctionOfXN(this.Kernel,theta);
        
            % 3. Get basis matrix.
            H = this.HFcn(X);
            
            % 4. Get (y - H*beta).
            adjy = y - H*beta;
            
            % 5. Set up options for BCD.            
            numgreedy       = this.Options.NumGreedyBCD;
            blocksize       = this.Options.BlockSizeBCD;
            tolerance       = this.Options.ToleranceBCD;
            stepTolerance   = this.Options.StepToleranceBCD;
            maxIter         = this.Options.IterationLimitBCD;
            
            if this.Verbose > 0
                verbose = 1;
            else
                verbose = 0;
            end
            
            % 6. Set square cache size for BCD. If 'SquareCacheSize' is
            % equal to c then it is assumed that we can store a c-by-c
            % matrix in double precision. This costs c*c*8 bytes. Equate
            % this to this.CacheSize (in MB) and solve for c. c must
            % satisfy c >= 1 and c <= N where N is the number of
            % observations.
            N               = size(X,1);
            squarecachesize = floor(sqrt((this.CacheSize*1e6)/8));
            squarecachesize = min(max(1,squarecachesize),N);
            
            % 7. Display a one-line summary of the BCD call for verbose
            % display.
            if ( verbose == 1 )
                BCDMessageStr = getString(message('stats:classreg:learning:impl:GPImpl:GPImpl:MessageBCD',blocksize,numgreedy));
                fprintf('\n');
                fprintf('%s\n',BCDMessageStr);
            end
            
            % 8. Call BCD.
            [alphaHat,gHat,fHat,selectionCounts] = classreg.learning.gputils.bcdGPR(X,adjy,kfun,diagkfun,...
                                                        'verbose',verbose,'Tolerance',tolerance,'BlockSize',blocksize,'SquareCacheSize',squarecachesize,...
                                                        'NumGreedy',numgreedy,'Sigma',sigma,'StepTolerance',stepTolerance,'MaxIter',maxIter);
                                
        end % end of computeAlphaHatBCD.
        
    end
    
    % Methods for SR/FIC.
    methods
        
%         function [alphaHat,betaHat,L,LAA] = computeAlphaHatBetaHatSparse(this,X,y,A,beta,theta,sigma,useFIC)
%         %computeAlphaHatBetaHatSparse - Compute quantities needed to make predictions for SR/FIC.
%         %   [alphaHat,betaHat,L,LAA] = computeAlphaHatBetaHatSparse(this,X,y,A,beta,theta,sigma,useFIC)
%         %   takes a GPImpl object this, N-by-D matrix of predictors X,
%         %   N-by-1 response vector y, an active set of points A as a N-by-1
%         %   logical vector, GPR parameters beta, theta, sigma and computes
%         %   vector alphaHat and matrices L and LAA needed for making
%         %   predictions. If useFIC is true then FIC approximation is used
%         %   and if useFIC is false then SR approximation is used.
%         %
%         %   Equations for making predictions using FIC are given in
%         %   section 7.2.1 of the GPR theory spec.
%         %
%         %   alphaHat  = BA^{-1}*K(XA,X)*Lambda^{-1}*(y - H*beta) (eq. 191)
%         %
%         %   L         = Lower triangular Cholesky factor of BA.
%         %
%         %   LAA       = Lower triangular Cholesky factor of K(XA,XA)
%         %
%         %   Lambda(i) = sigma^2 + k(xi,xi) - K(xi,XA)*K(XA,XA)^{-1}*K(XA,xi)
%         %
%         %   BA        = K(XA,XA) + K(XA,X)*Lambda^{-1}*K(X,XA)
%         %
%         %   If beta is not empty, then betaHat is equal to beta.
%         %
%         %   If beta is empty, then betaHat is computed as described in
%         %   section 7.2.2.2 of GPR theory spec - eq. 200. In this case, the
%         %   value of alphaHat is based on this computed value of beta.
%         %
%         %   Equations for making predictions using SR are given in section
%         %   7.1.1 of the GPR theory spec. For the SR approximation,
%         %
%         %   Lambda(i) = sigma^2
%             
%             % 1. Get basis matrix and number of observations.
%             H = this.HFcn(X);
%             p = size(H,2);
%             N = size(X,1);
%             
%             % 2. Make function to evaluate kernel.
%             kfun     =   makeKernelAsFunctionOfXNXM(this.Kernel,theta);
%             
%             % 3. Evaluate diagonal of kernel for FIC.
%             if useFIC
%                 diagkfun = makeDiagKernelAsFunctionOfXN(this.Kernel,theta);           
%                 diagK    = diagkfun(X);
%             end
%             
%             % 4. The matrix K(X,XA) is of size N-by-M where M is the active
%             % set size. Usually N is much larger than M. To avoid storing
%             % K(X,XA) we break it up as follows:
%             %
%             %   K(X,XA) = [K1; 
%             %              K2;
%             %             ...;
%             %              KC]
%             %
%             % Suppose all Ki except KC have B rows and M columns. KC may
%             % have fewer rows than B. This scheme requires us to store
%             % smaller B-by-M matrices. If we want these smaller matrices to
%             % occupy the same amount of memory as this.CacheSize then B
%             % must be chosen to satisfy:
%             %
%             %   B*M*8 <= 1e6 * this.CacheSize
%             %
%             % The assumption is that each double takes 8 bytes and CacheSize
%             % is in MB. B is chosen to be:
%             %
%             %   B = max(1, floor(1e6 * this.CacheSize/(8*M)));
%             %
%             % The number of chunks of size B when splitting K(X,XA) is:
%             %
%             %   nchunks = floor(N/B);
%             %
%             % The size of last partial chunk KC is:
%             %
%             %   N - nchunks*B 
%             %
%             % Note that the active set A is a N-by-1 logical vector.
%             M       = length(find(A));
%             B       = max(1,floor((1e6*this.CacheSize)/8/M));
%             nchunks = floor(N/B);
%             
%             % 5. Get lower triangular Cholesky factor of K(XA,XA). If we
%             % motivate the FIC model using subset selection by SGMA and add
%             % a 2-norm regularizer on the basis coefficients then K(XA,XA)
%             % gets replaced by K(XA,XA) + tau^2*I where tau is the strength
%             % of regularization.
%             tau            = this.Options.Regularization;           
%             XA             = X(A,:);
%             KAA            = kfun(XA,XA);
%             KAA(1:M+1:M^2) = KAA(1:M+1:M^2) + tau^2;
%             [LAA,status]   = chol(KAA,'lower');            
%             if (status ~= 0)
%                 error(message('stats:classreg:learning:impl:GPImpl:GPImpl:UnableToComputeLFactorFIC'));
%             end
%             
%             % 6. Do we need to estimate beta? When estimateBeta is false
%             % below then betaHat contains a valid value.
%             if isempty(beta)
%                 % Try to estimate beta.
%                 if (p == 0)
%                     betaHat      = zeros(0,1);
%                     estimateBeta = false;
%                 else
%                     estimateBeta = true;
%                 end
%             else
%                 % beta is filled in.
%                 betaHat      = beta;
%                 estimateBeta = false;
%             end
%             
%             % 7. Partition diagLambda = [diagLambda1;
%             %                            diagLambda2;
%             %                                    ...;
%             %                            diagLambdaC]
%             %
%             % H as [H1;     and    y as [y1;
%             %       H2;                  y2;
%             %      ...;                 ...;           
%             %       HC]                  yC]
%             %
%             % just like rows of K(X,XA). Then:
%             %
%             % BA = K(XA,XA) + sum_{i} Ki^T * Lambdai^{-1} * Ki
%             %
%             % K(XA,X)*Lambda^{-1}*H = sum_{i} Ki^T * Lambdai^{-1} * Hi
%             %
%             % etc.
%             
%                 % 7.1 Initialize quantities needed for computing BA and
%                 % betaHat (if needed).            
%                 BA            = KAA;
%                 KAXLambdaInvH = zeros(M,p);
%                 KAXLambdaInvy = zeros(M,1);
%                 if estimateBeta                
%                     HTLambdaInvH  = zeros(p,p);
%                     HTLambdaInvy  = zeros(p,1);
%                 end
%                 
%                 % 7.2 Process chunks and accumulate required quantities.
%                 for c = 1:(nchunks + 1)
%                     if c < (nchunks + 1)
%                         idxc = (c-1)*B+1:c*B;
%                     else
%                         % Last chunk.
%                         idxc = nchunks*B+1:N;
%                     end
%                     
%                     Kc           = kfun(X(idxc,:),XA);
%                     if useFIC
%                         diagLambdac  = max(0,sigma^2 + diagK(idxc) - sum((LAA \ Kc').^2,1)');
%                     else
%                         diagLambdac  = max(0,sigma^2 * ones(length(idxc),1));
%                     end
%                     LambdacInvKc = bsxfun(@rdivide,Kc,diagLambdac);
%                     
%                     BA           = BA + Kc'*LambdacInvKc;
%                     
%                     Hc            = H(idxc,:);
%                     yc            = y(idxc,1);
%                     KAXLambdaInvH = KAXLambdaInvH + LambdacInvKc'*Hc;
%                     KAXLambdaInvy = KAXLambdaInvy + LambdacInvKc'*yc;
%                     
%                     if estimateBeta
%                         LambdacInvHc  = bsxfun(@rdivide,Hc,diagLambdac);
%                         HTLambdaInvH  = HTLambdaInvH + Hc'*LambdacInvHc;
%                         HTLambdaInvy  = HTLambdaInvy + LambdacInvHc'*yc;
%                     end
%                 end
% 
%             % 8. Cholesky factor of BA. Note that BA is initialized as KAA 
%             % which already has the tau regularization effect.
%             [L,status]    = chol(BA,'lower');
%             if (status ~= 0)
%                 error(message('stats:classreg:learning:impl:GPImpl:GPImpl:UnableToComputeLFactorFIC'));
%             end
%             
%             % 9. Compute betaHat if required.
%             if estimateBeta                
%                 LInvKAXLambdaInvH = L \ KAXLambdaInvH;
%                 LInvKAXLambdaInvy = L \ KAXLambdaInvy;
%                 HTVInvH           = HTLambdaInvH - LInvKAXLambdaInvH'*LInvKAXLambdaInvH;
%                 HTVInvy           = HTLambdaInvy - LInvKAXLambdaInvH'*LInvKAXLambdaInvy;
%                 betaHat           = HTVInvH \ HTVInvy;
%             end
%             
%             % 10. Compute alphaHat - betaHat is known at this point.            
%             alphaHat = L' \ (L \ (KAXLambdaInvy - KAXLambdaInvH*betaHat));
%                         
%         end % end of computeAlphaHatBetaHatSparse.
        
        function [alphaHat,betaHat,L,LAA] = computeAlphaHatBetaHatSparseQR(this,X,y,A,beta,theta,sigma,useFIC)
        %computeAlphaHatBetaHatSparseQR - Compute quantities needed to make predictions for SR/FIC.
        %   [alphaHat,betaHat,L,LAA] = computeAlphaHatBetaHatSparseQR(this,X,y,A,beta,theta,sigma,useFIC)
        %   takes a GPImpl object this, N-by-D matrix of predictors X,
        %   N-by-1 response vector y, an active set of points A as a N-by-1
        %   logical vector, GPR parameters beta, theta, sigma and computes
        %   vector alphaHat and matrices L and LAA needed for making
        %   predictions. If useFIC is true then FIC approximation is used
        %   and if useFIC is false then SR approximation is used. QR
        %   factorization is used for numerical stability. See Foster et
        %   al. (2009) - "Stable and Efficient Gaussian Process
        %   Calculations".
        %
        %   Equations for making predictions using FIC are given in
        %   section 7.2.1 of the GPR theory spec.
        %
        %   alphaHat  = BA^{-1}*K(XA,X)*Lambda^{-1}*(y - H*beta)
        %
        %   L         = Lower triangular Cholesky factor of BA.
        %
        %   LAA       = Lower triangular Cholesky factor of K(XA,XA)
        %
        %   Lambda(i) = sigma^2 + k(xi,xi) - K(xi,XA)*K(XA,XA)^{-1}*K(XA,xi)
        %
        %   BA        = K(XA,XA) + K(XA,X)*Lambda^{-1}*K(X,XA)
        %
        %   If beta is not empty, then betaHat is equal to beta.
        %
        %   If beta is empty, then betaHat is computed as described in
        %   section 7.2.2.2 of GPR theory spec. In this case, the value of
        %   alphaHat is based on this computed value of beta.
        %
        %   Equations for making predictions using SR are given in section
        %   7.1.1 of the GPR theory spec. For the SR approximation,
        %
        %   Lambda(i) = sigma^2
            
            % 1. Get XA, H and their dimensions.
            N  = size(X,1);
            XA = X(A,:);
            M  = size(XA,1);
            
            H  = this.HFcn(X);
            p  = size(H,2);
            
            % 2. Make function to evaluate kernel.
            kfun = makeKernelAsFunctionOfXNXM(this.Kernel,theta);
            
            % 3. Evaluate diagonal of kernel for FIC.
            if useFIC
                diagkfun = makeDiagKernelAsFunctionOfXN(this.Kernel,theta);
                diagK    = diagkfun(X);
            end
            
            % 4. Regularization on low rank matrix factorization.
            tau = this.Options.Regularization;
            
            % 5. Compute N-by-M matrix KXA.
            KXA = kfun(X,XA);
            
            % 6. Compute KAA - regularize the diagonal.
            KAA            = KXA(A,:);
            KAA(1:M+1:M^2) = KAA(1:M+1:M^2) + tau^2;
            
            % 7. Get Cholesky factor of KAA.
            [LAA,status] = chol(KAA,'lower');
            if (status ~= 0)
                error(message('stats:classreg:learning:impl:GPImpl:GPImpl:UnableToComputeLFactorFIC'));
            end
            
            % 8. Compute diagonal matrix Lambda. For the SR approximation,
            % Lambda = sigma^2*eye(N).
            LAAInvKAX             = LAA \ KXA';
            clear KXA;
            
            if useFIC                
                diagLambda        = max(0, sigma^2 + diagK - sum(LAAInvKAX.^2,1)');
                invDiagLambda     = 1./diagLambda;
            else
                sigma2            = sigma^2;                
                invDiagLambda     = (1/sigma2)*ones(N,1);
            end
            sqrtInvDiagLambda     = sqrt(invDiagLambda);            
            
            % 9. Compute Cholesky factor of BA without explicitly forming
            % BA via QR factorization of a (N+M)-by-M matrix. L is the
            % Cholesky factor of BA.
            Q     = [bsxfun(@times,sqrtInvDiagLambda,LAAInvKAX');
                     eye(M)];
            [Q,R] = qr(Q,0);
            L     = LAA*R';
            clear LAAInvKAX;
            
            % 10. Things needed for computing alphaHat.            
            sqrtLambdaInvH = bsxfun(@times,sqrtInvDiagLambda,H);
            sqrtLambdaInvy = bsxfun(@times,sqrtInvDiagLambda,y);                        
            
            Htilde         = [sqrtLambdaInvH;zeros(M,p)];
            ytilde         = [sqrtLambdaInvy;zeros(M,1)];
            
            QTHtilde       = Q'*Htilde;
            QTytilde       = Q'*ytilde;
            
            clear Q;
            
            % 11. Compute profiled coefficients betaHat (if needed).
            if isempty(beta)
                % Need to estimate betaHat.
                if ( p == 0 )
                    betaHat = zeros(0,1);
                else
                    HTLambdaInvH = sqrtLambdaInvH'*sqrtLambdaInvH;
                    HTLambdaInvy = sqrtLambdaInvH'*sqrtLambdaInvy;
                    
                    HTVInvH      = HTLambdaInvH - QTHtilde'*QTHtilde;
                    HTVInvy      = HTLambdaInvy - QTHtilde'*QTytilde;
                    
                    betaHat      = HTVInvH \ HTVInvy;
                end
            else
                % Copy beta into betaHat.
                betaHat = beta;
            end
            
            % 12. Compute alphaHat for FIC.
            alphaHat = LAA' \ (R \ (QTytilde - QTHtilde*betaHat));                        
                        
        end % end of computeAlphaHatBetaHatSparseQR.
        
        function [alphaHat,betaHat,L,LAA] = computeAlphaHatBetaHatSparseV(this,X,y,A,beta,theta,sigma,useFIC)
        %computeAlphaHatBetaHatSparseV - Compute quantities needed to make predictions for SR/FIC.
        %   [alphaHat,betaHat,L,LAA] = computeAlphaHatBetaHatSparseV(this,X,y,A,beta,theta,sigma,useFIC)
        %   takes a GPImpl object this, N-by-D matrix of predictors X,
        %   N-by-1 response vector y, an active set of points A as a N-by-1
        %   logical vector, GPR parameters beta, theta, sigma and computes
        %   vector alphaHat and matrices L and LAA needed for making
        %   predictions. If useFIC is true then FIC approximation is used
        %   and if useFIC is false then SR approximation is used. This
        %   version uses the V-method of Foster et al. (2009) - "Stable and 
        %   Efficient Gaussian Process Calculations".
        %
        %   Equations for making predictions using FIC are given in
        %   section 7.2.1 of the GPR theory spec.
        %
        %   alphaHat  = BA^{-1}*K(XA,X)*Lambda^{-1}*(y - H*beta)
        %
        %   L         = Lower triangular Cholesky factor of BA.
        %
        %   LAA       = Lower triangular Cholesky factor of K(XA,XA)
        %
        %   Lambda(i) = sigma^2 + k(xi,xi) - K(xi,XA)*K(XA,XA)^{-1}*K(XA,xi)
        %
        %   BA        = K(XA,XA) + K(XA,X)*Lambda^{-1}*K(X,XA)
        %
        %   If beta is not empty, then betaHat is equal to beta.
        %
        %   If beta is empty, then betaHat is computed as described in
        %   section 7.2.2.2 of GPR theory spec. In this case, the value of
        %   alphaHat is based on this computed value of beta.
        %
        %   Equations for making predictions using SR are given in section
        %   7.1.1 of the GPR theory spec. For the SR approximation,
        %
        %   Lambda(i) = sigma^2
            
            % 1. Get basis matrix and number of observations.
            H = this.HFcn(X);
            p = size(H,2);
            N = size(X,1);
            
            % 2. Make function to evaluate kernel.
            kfun = makeKernelAsFunctionOfXNXM(this.Kernel,theta);
            
            % 3. Evaluate diagonal of kernel for FIC.
            if useFIC
                diagkfun = makeDiagKernelAsFunctionOfXN(this.Kernel,theta);           
                diagK    = diagkfun(X);
            end
            
            % 4. The matrix K(X,XA) is of size N-by-M where M is the active
            % set size. Usually N is much larger than M. To avoid storing
            % K(X,XA) we break it up as follows:
            %
            %   K(X,XA) = [K1; 
            %              K2;
            %             ...;
            %              KC]
            %
            % Suppose all Ki except KC have B rows and M columns. KC may
            % have fewer rows than B. This scheme requires us to store
            % smaller B-by-M matrices. If we want these smaller matrices to
            % occupy the same amount of memory as this.CacheSize then B
            % must be chosen to satisfy:
            %
            %   B*M*8 <= 1e6 * this.CacheSize
            %
            % The assumption is that each double takes 8 bytes and CacheSize
            % is in MB. B is chosen to be:
            %
            %   B = max(1, floor(1e6 * this.CacheSize/(8*M)));
            %
            % The number of chunks of size B when splitting K(X,XA) is:
            %
            %   nchunks = floor(N/B);
            %
            % The size of last partial chunk KC is:
            %
            %   N - nchunks*B 
            %
            % Note that the active set A is a N-by-1 logical vector.
            M       = length(find(A));
            B       = max(1,floor((1e6*this.CacheSize)/8/M));
            nchunks = floor(N/B);
            
            % 5. Get lower triangular Cholesky factor of K(XA,XA). If we
            % motivate the FIC model using subset selection by SGMA and add
            % a 2-norm regularizer on the basis coefficients then K(XA,XA)
            % gets replaced by K(XA,XA) + tau^2*I where tau is the strength
            % of regularization.
            tau            = this.Options.Regularization;           
            XA             = X(A,:);
            KAA            = kfun(XA,XA);
            KAA(1:M+1:M^2) = KAA(1:M+1:M^2) + tau^2;
            [LAA,status]   = chol(KAA,'lower');            
            if (status ~= 0)
                error(message('stats:classreg:learning:impl:GPImpl:GPImpl:UnableToComputeLFactorFIC'));
            end
            
            % 6. Do we need to estimate beta? When estimateBeta is false
            % below then betaHat contains a valid value.
            if isempty(beta)
                % Try to estimate beta.
                if (p == 0)
                    betaHat      = zeros(0,1);
                    estimateBeta = false;
                else
                    estimateBeta = true;
                end
            else
                % beta is filled in.
                betaHat      = beta;
                estimateBeta = false;
            end
            
            % 7. Partition diagLambda = [diagLambda1;
            %                            diagLambda2;
            %                                    ...;
            %                            diagLambdaC]
            %
            % H as [H1;     and    y as [y1;
            %       H2;                  y2;
            %      ...;                 ...;           
            %       HC]                  yC]
            %
            % just like rows of K(X,XA). Then:
            %
            % BA = K(XA,XA) + sum_{i} Ki^T * Lambdai^{-1} * Ki
            %
            % K(XA,X)*Lambda^{-1}*H = sum_{i} Ki^T * Lambdai^{-1} * Hi
            %
            % etc.
            
                % 7.1 Initialize quantities needed for computing BA and
                % betaHat (if needed).
                SA            = eye(M);
                KAXLambdaInvH = zeros(M,p);
                KAXLambdaInvy = zeros(M,1);
                if estimateBeta                
                    HTLambdaInvH  = zeros(p,p);
                    HTLambdaInvy  = zeros(p,1);
                end
                
                % 7.2 Process chunks and accumulate required quantities.
                for c = 1:(nchunks + 1)
                    if c < (nchunks + 1)
                        idxc = (c-1)*B+1:c*B;
                    else
                        % Last chunk.
                        idxc = nchunks*B+1:N;
                    end
                    
                    Kc = kfun(X(idxc,:),XA);
                    Hc = H(idxc,:);
                    yc = y(idxc,1);
                    
                    if useFIC
                        diagLambdac    = max(0,sigma^2 + diagK(idxc) - sum((LAA \ Kc').^2,1)');
                    else
                        diagLambdac    = max(0,sigma^2 * ones(length(idxc),1));
                    end                    
                    sqrtInvDiagLambdac = sqrt(1./diagLambdac);
                    
                    sqrtLambdacInvKc = bsxfun(@times,sqrtInvDiagLambdac,Kc);
                    sqrtLambdacInvHc = bsxfun(@times,sqrtInvDiagLambdac,Hc);
                    sqrtLambdacInvyc = bsxfun(@times,sqrtInvDiagLambdac,yc);            
                    
                    LAAInvSqrtLambdacInvKcT = LAA \ sqrtLambdacInvKc';                    
                    SA                      = SA + LAAInvSqrtLambdacInvKcT*LAAInvSqrtLambdacInvKcT';           
                    
                    KAXLambdaInvH = KAXLambdaInvH + sqrtLambdacInvKc'*sqrtLambdacInvHc;
                    KAXLambdaInvy = KAXLambdaInvy + sqrtLambdacInvKc'*sqrtLambdacInvyc;
                    
                    if estimateBeta
                        HTLambdaInvH  = HTLambdaInvH + sqrtLambdacInvHc'*sqrtLambdacInvHc;
                        HTLambdaInvy  = HTLambdaInvy + sqrtLambdacInvHc'*sqrtLambdacInvyc;
                    end
                end

            % 8. R is the upper triangular Cholesky factor of SA. If L is
            % the lower triangular Cholesky factor of BA then:
            %
            %       R'*R = SA
            %       L*L' = BA
            %
            % and
            %
            %       L = LAA*R'
            [R,status] = chol(SA);
            if (status ~= 0)
                error(message('stats:classreg:learning:impl:GPImpl:GPImpl:UnableToComputeLFactorFIC'));
            end
            L = LAA*R';
            
            % 9. Compute betaHat if required.
            LInvKAXLambdaInvH = L \ KAXLambdaInvH;
            LInvKAXLambdaInvy = L \ KAXLambdaInvy;
            if estimateBeta
                HTVInvH           = HTLambdaInvH - LInvKAXLambdaInvH'*LInvKAXLambdaInvH;
                HTVInvy           = HTLambdaInvy - LInvKAXLambdaInvH'*LInvKAXLambdaInvy;
                betaHat           = HTVInvH \ HTVInvy;
            end
            
            % 10. Compute alphaHat - betaHat is known at this point.
            alphaHat = L' \ (LInvKAXLambdaInvy - LInvKAXLambdaInvH*betaHat);
                        
        end % end of computeAlphaHatBetaHatSparseV.        
        
        function [thetaHat,sigmaHat,loglikHat] = estimateThetaHatSigmaHatSparse(this,X,y,A,beta0,theta0,sigma0,useFIC,useQR)
        %estimateThetaHatSigmaHatSparse - Hyperparameter estimation for SR/FIC approximation to GPR.
        %   [thetaHat,sigmaHat,loglikHat] = estimateThetaHatSigmaHatSparse(this,X,y,A,beta0,theta0,sigma0,useFIC,useQR)
        %   takes an unfitted GPImpl object this, N-by-D matrix X, N-by-1
        %   vector y, N-by-1 logical vector A indicating the active set and
        %   initial values beta0, theta0 and sigma0 of the GPR parameters
        %   and returns estimated values thetaHat and sigmaHat by
        %   maximizing a sparse approximation to the profiled marginal log
        %   likelihood of the GPR model. Input useFIC is a logical scalar
        %   indicating the type of approximation to use. If useFIC is true,
        %   the FIC approximation is used and if useFIC is false, the SR
        %   approximation is used. If useQR is true, a more accurate QR
        %   factorization based method is used to evaluate the profiled log
        %   likelihood and its gradients. loglikHat is the maximized log
        %   likelihood of the GPR model.
        %
        %   For built-in kernel functions, we use analytical derivatives of
        %   the objective function (negative profiled log likelihood)
        %   whereas for custom kernel functions, numerical derivatives are
        %   used. See sections 7.1.2 and 7.2.2 of GPR theory spec.
        
            % 1. Make objective function for minimization. This is the
            % negative SR/FIC profiled log likelihood of the GPR model
            % where coefficients beta are profiled out analytically and so
            % the vector of variables for the purposes of optimization is:
            %
            %   phi = [theta;gamma]
            %
            % where gamma is unconstrained and parameterizes the noise
            % standard deviation:
            %
            %   sigma = sigmaLB + exp(gamma)
            %
            % and sigmaLB is a lower bound on sigma.
            %
            % objFun below can return analytical derivatives for built-in
            % kernel functions like this:
            %
            %   [Fun,gradFun] = objFun(phi)
            %
            % For custom kernel functions, derivative information is not
            % available and so objFun should be called like this:
            %
            %   Fun = objFun(phi)
            %
            % Also, get the number of observations N, number of predictors 
            % D and active set size M and decide if we can cache distances 
            % during fitting.
            [N,D]             = size(X);
            M                 = sum(A);
            usecache          = checkCacheSizeForFitting(this,N,D,M);
            if useQR
                % Use QR factorization based computations.
                [objFun,haveGrad] = makeNegativeProfiledLogLikelihoodSparseQR(this,X,y,A,beta0,theta0,sigma0,usecache,useFIC);
            else
                % Use V method + faster gradient computations.
                [objFun,haveGrad] = makeNegativeProfiledLogLikelihoodSparseVFastGrad(this,X,y,A,beta0,theta0,sigma0,usecache,useFIC);
            end
            
            % 2. Initial value of phi.
            sigmaLB = this.Options.SigmaLowerBound;
            if this.ConstantSigma
                gamma0  = log(max(1e-6,sigma0-sigmaLB));
            else
                gamma0  = log(max(1e-3,sigma0-sigmaLB));
            end
            phi0    = [theta0;gamma0];
            
            % 3. Minimize objFun starting at phi0. Disable warning messages
            % during optimization and restore them when this function
            % exits. Display one line summary of FitMethod and Optimizer if
            % Verbose is > 0.
            warnState  = warning('query','all');
            warning('off','MATLAB:nearlySingularMatrix');
            warning('off','MATLAB:illConditionedMatrix');
            warning('off','MATLAB:singularMatrix');
            warning('off','MATLAB:rankDeficientMatrix');
            cleanupObj = onCleanup(@() warning(warnState));
            
            if ( this.Verbose > 0 )                
                if useQR
                    computationMethod = 'QR';
                else
                    computationMethod = 'V';
                end
                
                if useFIC
                    fitMethod = classreg.learning.modelparams.GPParams.FitMethodFIC;
                else
                    fitMethod = classreg.learning.modelparams.GPParams.FitMethodSR;
                end
                
                parameterEstimationMessageStr = getString(message('stats:classreg:learning:impl:GPImpl:GPImpl:MessageSparseParameterEstimation',fitMethod,this.Optimizer,computationMethod));
                fprintf('\n');
                fprintf('%s\n',parameterEstimationMessageStr);
            end
            
            if this.ConstantSigma || any(this.ConstantKernelParameters)
                [phiHat,nloglikHat,cause] = doMinimizationWithSomeConstParams(this,objFun,phi0,haveGrad);
            else
                [phiHat,nloglikHat,cause] = doMinimization(this,objFun,phi0,haveGrad);
            end            
            
            % 4. Display convergence warning if needed.
            if ( cause ~= 0 && cause ~= 1 )
                warning(message('stats:classreg:learning:impl:GPImpl:GPImpl:OptimizerUnableToConverge',this.Optimizer));                
            end
            
            % 5. Extract thetaHat and sigmaHat from phiHat.
            s        = length(phiHat);
            thetaHat = phiHat(1:s-1,1);
            gammaHat = phiHat(s,1);
            sigmaHat = sigmaLB + exp(gammaHat);
            
            % 6. Return maximized log likelihood.
            loglikHat = -1*nloglikHat;
            
        end % end of estimateThetaHatSigmaHatSparse.
        
        function [objFun,haveGrad] = makeNegativeProfiledLogLikelihoodSparseVFastGrad(this,X,y,A,beta0,theta0,sigma0,usecache,useFIC) %#ok<INUSL>
        %   [objFun,haveGrad] = makeNegativeProfiledLogLikelihoodSparseVFastGrad(this,X,y,A,beta0,theta0,sigma0,usecache,useFIC)
        %   takes a GPImpl object this, a N-by-D matrix X, N-by-1 vector y,
        %   N-by-1 logical vector A indicating the active set and initial
        %   values of GPR parameters beta0, theta0 and sigma0 and returns
        %   an objective function objFun for minimization. Input usecache
        %   is a boolean indicating whether squared Euclidean distances
        %   should be cached for built-in kernels. Input useFIC is a
        %   logical scalar indicating the type of sparse approximation to
        %   use. If useFIC is true, we use the FIC approximation otherwise
        %   we use the SR approximation. Output haveGrad is true if objFun
        %   can return gradient information and is false otherwise (see
        %   below for more info). See Foster et al. (2009) - "Stable and 
        %   Efficient Gaussian Process Calculations".
        %
        %   o objFun accepts a parameter vector phi such that:               
        %
        %       phi = [theta;gamma]
        %
        %   where gamma is unconstrained and parameterizes the noise
        %   standard deviation:
        %
        %       sigma = sigmaLB + exp(gamma)
        %
        %   and sigmaLB is a lower bound on sigma.        
        %
        %   o For built-in kernel functions, objFun can be called like this:
        %
        %   [Fun,gradFun] = objFun(phi)
        %
        %   where Fun is the function value and gradFun is the gradient of
        %   the function evaluated at phi.
        %
        %   o For custom kernel functions, objFun does not return gradient
        %   information and it must be called like this:
        %
        %   Fun = objFun(phi)
        
            % 1. Make kernel as function of theta. kfcn below can be
            % called like this:
            %             [KXA,DKXA] = kfcn(ThetaNew)
            %  
            %     where
            %  
            %     o ThetaNew is some new value of Theta.
            %     o KXA  = K(X,XA | ThetaNew).
            %     o DKXA = A function handle that accepts an integer i such that 
            %              DKXA(i) is the derivative of K(X,XA | Theta) w.r.t. 
            %              Theta(i) evaluated at ThetaNew.
            %
            % For custom kernel functions, DKXA is [].            
                % 1.1 Part of X corresponding to the active set A.
                XA = X(A,:);
                % 1.2 Create kernel function.
                assert( islogical(usecache) );            
                kfcn = makeKernelAsFunctionOfTheta(this.Kernel,X,XA,usecache);     
        
            % 2. Make function to evaluate diagonal of kernel as a function
            % of theta. diagkfcn below can be called like this:
            %
            %             [diagK,DdiagK] = diagkfcn(ThetaNew)
            %
            %     where
            %
            %     o ThetaNew is some new value of Theta.
            %     o diagK  = diag( K(X,X | ThetaNew) ).
            %     o DdiagK = A function handle that accepts an integer i
            %                such that DdiagK(i) is the derivative of diag( K(X,X | Theta) )
            %                w.r.t. Theta(i) evaluated at ThetaNew.
            %
            % For custom kernel functions, DdiagK = [].
            diagkfcn = makeDiagKernelAsFunctionOfTheta(this.Kernel,X,usecache);                
                
            % 3. Get basis matrix and the number of columns in it.
            H = this.HFcn(X);
            p = size(H,2);
            
            % 4. Number of observations in X and XA. Vector of all ones for
            % the SR approximation.
            N  = size(X,1);
            M  = size(XA,1);
            if ~useFIC
                eN = ones(N,1);
            end
            
            % 5. Compute constant that appears in profiled log likelihood.
            % const below is such that profiled log likelihood has the
            % constant -const and negative profiled log likelihood has the
            % constant const.
            const = (N/2)*log(2*pi);
            
            % 6. Do we have a built-in kernel function. If so, gradient
            % information is available.
            isbuiltin = this.IsBuiltInKernel;
            if isbuiltin
                haveGrad = true;
            else
                haveGrad = false;
            end
            
            % 7. Length of vector phi, lower bound on sigma and bad value
            % for negative log likelihood - to be returned when computation
            % of negative log likelihood generates NaN/Inf values. One
            % example, when this may happen is when H is rank deficient.
            s          = length(theta0) + 1;
            sigmaLB    = this.Options.SigmaLowerBound;
            badnloglik = this.BadNegativeLogLikelihood;
        
            % 8. Regularization on low rank matrix factorization.
            tau = this.Options.Regularization;
                        
            % 9. Make objFun. This returns the *negative* log likelihood
            % and its gradient information.
            objFun = @f2;
            function [nloglik,gnloglik] = f2(phi)
                
                % 9.1 Extract theta and sigma from phi.               
                theta = phi(1:s-1,1);
                gamma = phi(s,1);
                sigma = sigmaLB + exp(gamma);                
                
                % 9.2 Compute kernel function and its derivatives.
                [KXA,DKXA] = kfcn(theta);
                
                % 9.3 Compute diagonal of kernel function and its derivatives.
                [diagK,DdiagK] = diagkfcn(theta);
                
                % 9.4 Compute KAA - regularize the diagonal.
                KAA            = KXA(A,:);
                KAA(1:M+1:M^2) = KAA(1:M+1:M^2) + tau^2;                
                
                % 9.5 Cholesky factor of KAA.
                [LAA,flag1] = chol(KAA,'lower');
                if ( flag1 ~= 0 )
                    % KAA is not positive definite - numerically speaking.
                    % Return a bad value for the negative log likelihood
                    % (the thing being minimized).
                    nloglik = badnloglik;
                    if nargout > 1
                        if isbuiltin
                            gnloglik = zeros(s,1);
                        else
                            gnloglik = [];
                        end
                    end
                    return;
                end
                
                % 9.6 Compute diagonal matrix Lambda and its inverse. For
                % the SR approximation, Lambda = sigma^2*eye(N).
                LAAInvKAX         = LAA \ KXA';
                if useFIC  
                    diagLambda    = max(0, sigma^2 + diagK - sum(LAAInvKAX.^2,1)');
                    invDiagLambda = 1./diagLambda;
                else
                    sigma2        = sigma^2;
                    diagLambda    = sigma2    *eN;
                    invDiagLambda = (1/sigma2)*eN;
                end                                
                sqrtInvDiagLambda = sqrt(invDiagLambda);
                
                % 9.7 Compute KAXLambdaInvKXA for later use.
                KAXLambdaInvKXA = KXA'*bsxfun(@times,invDiagLambda,KXA);
                
                % 9.8 Form the matrix BA = LAA * SA * LAA'. R is the upper
                % triangular Cholesky factor of SA: SA = R'*R. Suppose L is
                % the lower triangular Cholesky factor of BA then:
                %
                %   BA = L * L'
                %   L  = LAA * R'
                SA        = bsxfun(@times,sqrtInvDiagLambda,LAAInvKAX');
                SA        = eye(M) + SA'*SA;
                [R,flag2] = chol(SA);
                if ( flag2 ~= 0 )
                    % SA is not positive definite - numerically speaking.
                    % Return a bad value for the negative log likelihood
                    % (the thing being minimized).
                    nloglik = badnloglik;
                    if nargout > 1
                        if haveGrad
                            gnloglik = zeros(s,1);
                        else
                            gnloglik = [];
                        end
                    end
                    return;
                end
                L = LAA*R';
                
                % 9.9 Compute profiled coefficients betaHat.
                LambdaInvH        = bsxfun(@times,invDiagLambda,H);
                LambdaInvy        = bsxfun(@times,invDiagLambda,y);
                                
                LInvKAXLambdaInvH = L \ (KXA'*LambdaInvH);
                LInvKAXLambdaInvy = L \ (KXA'*LambdaInvy);
                
                HTLambdaInvH      = H'*LambdaInvH;                
                HTLambdaInvy      = H'*LambdaInvy;
                yTLambdaInvy      = y'*LambdaInvy;
                                
                HTVInvH           = HTLambdaInvH - LInvKAXLambdaInvH'*LInvKAXLambdaInvH;
                HTVInvy           = HTLambdaInvy - LInvKAXLambdaInvH'*LInvKAXLambdaInvy;
                yTVInvy           = yTLambdaInvy - LInvKAXLambdaInvy'*LInvKAXLambdaInvy;
                
                if ( p == 0 )
                    betaHat = zeros(0,1);
                else
                    betaHat = HTVInvH \ HTVInvy;                
                end
                
                % 9.10 Compute the negative profiled log likelihood. Ensure
                % that the computed nloglik is finite. If not return a bad
                % value for nloglik and return right away.
                quadTerm = yTVInvy - 2*HTVInvy'*betaHat + betaHat'*(HTVInvH*betaHat);
                logTerm  = sum(log(abs(diagLambda))) + 2*sum(log(abs(diag(R))));
                loglik   = -0.5*quadTerm - const -0.5*logTerm;                
                nloglik  = -1*loglik;
                
                if ~isfinite(nloglik)
                    nloglik = badnloglik;
                    if nargout > 1
                        if haveGrad
                            gnloglik = zeros(s,1);
                        else
                            gnloglik = [];
                        end
                    end
                    return;                                        
                end
                
                % 9.11 Compute derivatives if required.
                if nargout > 1
                    if haveGrad
                        % Derivatives are available.                        
                        
                        % 9.12 Compute rHat and other useful quantities.
                        BAInvKAXLambdaInvAdjy = L' \ (LInvKAXLambdaInvy - LInvKAXLambdaInvH*betaHat);
                        rHat                  = invDiagLambda.*(y - H*betaHat - KXA*BAInvKAXLambdaInvAdjy);
                        KAXrHat               = KXA'*rHat;
                        KAAInvKAXrHat         = LAA' \ (LAA \ KAXrHat);
                        LInv                  = L \ eye(M);
                        diagLambda2           = diagLambda.^2;
                        KAAInvKAXLambdaInvKXA = LAA' \ (LAA \ KAXLambdaInvKXA);
                        
                        if useFIC
                            KAAInvKAX         = LAA' \ LAAInvKAX;
                        end
                        
                        % 9.13 Derivatives w.r.t. theta - first (s-1) elements of phi.
                        gloglik = zeros(s,1);
                        
                        for r = 1:s-1
                            % 9.14 Derivatives of K(X,XA).
                            DKXAr = DKXA(r);                            
                            
                            % 9.15 Quadratic term of the derivative.
                            quadTerm = 2*(rHat'*DKXAr)*KAAInvKAXrHat ...
                                        - KAAInvKAXrHat'*(DKXAr(A,:))*KAAInvKAXrHat;
                            if useFIC
                                % Add contribution due to Omega for FIC.
                                diagDOmegar = DdiagK(r) - 2*sum(DKXAr'.*KAAInvKAX,1)' + sum(KAAInvKAX.*(DKXAr(A,:)*KAAInvKAX),1)';
                                quadTerm    = quadTerm + rHat'*(diagDOmegar.*rHat);
                            end
                            
                            % 9.16 Trace term of the derivative.                             
                            DKAXLambdaInvKXAr     = DKXAr'*bsxfun(@times,invDiagLambda,KXA);                            
                            traceTerm1            = sum(sum(LInv .* (L \ DKAXLambdaInvKXAr)));    
                                                                
                                                        
                            traceTerm2            = sum(sum(LInv .* (L \ (DKXAr(A,:)*KAAInvKAXLambdaInvKXA))));
                            
                            if useFIC
                                % traceTerm3 is non-zero only for FIC.
                                lambdaOmega           = diagDOmegar./diagLambda2;
                                KAXLambdaOmegaKXA     = KXA'*bsxfun(@times,lambdaOmega,KXA);
                                traceTerm3            = sum(diagDOmegar.*invDiagLambda) - sum(sum(LInv .* (L \ KAXLambdaOmegaKXA)));
                            else
                                traceTerm3            = 0;
                            end
                            traceTerm = 2*traceTerm1 - traceTerm2 + traceTerm3;
                            
                            % 9.17 Total gradient.
                            gloglik(r) = 0.5*quadTerm - 0.5*traceTerm;
                        end   
                        % 9.18 Derivatives w.r.t. gamma. phi(s) = gamma. 
                        % The term sigma_sigmaLB replaces sigma^2 when
                        % there is a lower bound on sigma.
                        quadTerm         = rHat'*rHat;                        
                        KAXLambdaInv2KXA = KXA'*bsxfun(@times,1./diagLambda2,KXA);
                        traceTerm        = sum(invDiagLambda) - sum(sum(LInv .* (L \ KAXLambdaInv2KXA)));                        
                        sigma_sigmaLB    = sigma*(sigma - sigmaLB);
                        gloglik(s)       = sigma_sigmaLB*(quadTerm - traceTerm);
                        
                        % 9.19 Multiply gloglik by -1.
                        gnloglik = -1*gloglik;
                    else
                        % Derivative information is not available.
                        gnloglik = [];
                    end
                end
            end                                    
        end % end of makeNegativeProfiledLogLikelihoodSparseVFastGrad.
                
        function [objFun,haveGrad] = makeNegativeProfiledLogLikelihoodSparseQR(this,X,y,A,beta0,theta0,sigma0,usecache,useFIC) %#ok<INUSL>
        %   [objFun,haveGrad] = makeNegativeProfiledLogLikelihoodSparseQR(this,X,y,A,beta0,theta0,sigma0,usecache,useFIC)
        %   takes a GPImpl object this, a N-by-D matrix X, N-by-1 vector y,
        %   N-by-1 logical vector A indicating the active set and initial
        %   values of GPR parameters beta0, theta0 and sigma0 and returns
        %   an objective function objFun for minimization. Input usecache
        %   is a boolean indicating whether squared Euclidean distances
        %   should be cached for built-in kernels. Input useFIC is a
        %   logical scalar indicating the type of sparse approximation to
        %   use. If useFIC is true, we use the FIC approximation otherwise
        %   we use the SR approximation. Output haveGrad is true if objFun
        %   can return gradient information and is false otherwise (see
        %   below for more info). QR factorization is used for greater
        %   numerical stability. See Foster et al. (2009) - "Stable and 
        %   Efficient Gaussian Process Calculations".
        %
        %   o objFun accepts a parameter vector phi such that:               
        %
        %       phi = [theta;gamma]
        %
        %   where gamma is unconstrained and parameterizes the noise
        %   standard deviation:
        %
        %       sigma = sigmaLB + exp(gamma)
        %
        %   and sigmaLB is a lower bound on sigma.        
        %
        %   o For built-in kernel functions, objFun can be called like this:
        %
        %   [Fun,gradFun] = objFun(phi)
        %
        %   where Fun is the function value and gradFun is the gradient of
        %   the function evaluated at phi.
        %
        %   o For custom kernel functions, objFun does not return gradient
        %   information and it must be called like this:
        %
        %   Fun = objFun(phi)
        
            % 1. Make kernel as function of theta. kfcn below can be
            % called like this:
            %             [KXA,DKXA] = kfcn(ThetaNew)
            %  
            %     where
            %  
            %     o ThetaNew is some new value of Theta.
            %     o KXA  = K(X,XA | ThetaNew).
            %     o DKXA = A function handle that accepts an integer i such that 
            %              DKXA(i) is the derivative of K(X,XA | Theta) w.r.t. 
            %              Theta(i) evaluated at ThetaNew.
            %
            % For custom kernel functions, DKXA is [].            
                % 1.1 Part of X corresponding to the active set A.
                XA = X(A,:);
                % 1.2 Create kernel function.
                assert( islogical(usecache) );            
                kfcn = makeKernelAsFunctionOfTheta(this.Kernel,X,XA,usecache);     
        
            % 2. Make function to evaluate diagonal of kernel as a function
            % of theta. diagkfcn below can be called like this:
            %
            %             [diagK,DdiagK] = diagkfcn(ThetaNew)
            %
            %     where
            %
            %     o ThetaNew is some new value of Theta.
            %     o diagK  = diag( K(X,X | ThetaNew) ).
            %     o DdiagK = A function handle that accepts an integer i
            %                such that DdiagK(i) is the derivative of diag( K(X,X | Theta) )
            %                w.r.t. Theta(i) evaluated at ThetaNew.
            %
            % For custom kernel functions, DdiagK = [].
            diagkfcn = makeDiagKernelAsFunctionOfTheta(this.Kernel,X,usecache);                
                
            % 3. Get basis matrix and the number of columns in it.
            H = this.HFcn(X);
            p = size(H,2);
            
            % 4. Number of observations in X and XA.
            N  = size(X,1);
            M  = size(XA,1);            
            
            % 5. Compute constant that appears in profiled log likelihood.
            % const below is such that profiled log likelihood has the
            % constant -const and negative profiled log likelihood has the
            % constant const.
            const = (N/2)*log(2*pi);
            
            % 6. Do we have a built-in kernel function. If so, gradient
            % information is available.
            isbuiltin = this.IsBuiltInKernel;
            if isbuiltin
                haveGrad = true;
            else
                haveGrad = false;
            end
            
            % 7. Length of vector phi, lower bound on sigma and bad value
            % for negative log likelihood - to be returned when computation
            % of negative log likelihood generates NaN/Inf values. One
            % example, when this may happen is when H is rank deficient.
            s          = length(theta0) + 1;
            sigmaLB    = this.Options.SigmaLowerBound;
            badnloglik = this.BadNegativeLogLikelihood;
        
            % 8. Regularization on low rank matrix factorization.
            tau = this.Options.Regularization;
                        
            % 9. Make objFun. This returns the *negative* log likelihood
            % and its gradient information.
            objFun = @f4;
            function [nloglik,gnloglik] = f4(phi)
                
                % 9.1 Extract theta and sigma from phi.               
                theta = phi(1:s-1,1);
                gamma = phi(s,1);
                sigma = sigmaLB + exp(gamma);                
                
                % 9.2 Compute kernel function and its derivatives.
                [KXA,DKXA] = kfcn(theta);
                
                % 9.3 Compute diagonal of kernel function and its derivatives.
                [diagK,DdiagK] = diagkfcn(theta);
                
                % 9.4 Compute KAA - regularize the diagonal.
                KAA            = KXA(A,:);
                KAA(1:M+1:M^2) = KAA(1:M+1:M^2) + tau^2;                
                
                % 9.5 Cholesky factor of KAA.
                [LAA,flag] = chol(KAA,'lower');
                if ( flag ~= 0 )
                    % KAA is not positive definite - numerically speaking.
                    % Return a bad value for the negative log likelihood
                    % (the thing being minimized).
                    nloglik = badnloglik;
                    if nargout > 1
                        if haveGrad
                            gnloglik = zeros(s,1);
                        else
                            gnloglik = [];
                        end
                    end
                    return;
                end
                
                % 9.6 Compute diagonal matrix Lambda and its inverse. For
                % the SR approximation, Lambda = sigma^2*eye(N).
                LAAInvKAX             = LAA \ KXA';
                if useFIC                    
                    diagLambda        = max(0, sigma^2 + diagK - sum(LAAInvKAX.^2,1)');                    
                else                    
                    diagLambda        = (sigma^2)*ones(N,1);                    
                end
                invDiagLambda         = 1./diagLambda;
                sqrtInvDiagLambda     = sqrt(invDiagLambda);
                invDiagLambda2        = invDiagLambda.*invDiagLambda;
                
                % 9.7 Compute Cholesky factor of BA without explicitly
                % forming BA via QR factorization of a (N+M)-by-M matrix. 
                % L is the Cholesky factor of BA.
                Q     = [bsxfun(@times,sqrtInvDiagLambda,LAAInvKAX');
                        eye(M)];
                [Q,R] = qr(Q,0);
                L     = LAA*R';
                
                % 9.8 Compute profiled coefficients betaHat.
                sqrtLambdaInvH = bsxfun(@times,sqrtInvDiagLambda,H);
                sqrtLambdaInvy = bsxfun(@times,sqrtInvDiagLambda,y);
                
                HTLambdaInvH   = sqrtLambdaInvH'*sqrtLambdaInvH;
                HTLambdaInvy   = sqrtLambdaInvH'*sqrtLambdaInvy;
                yTLambdaInvy   = sqrtLambdaInvy'*sqrtLambdaInvy;
                
                Htilde         = [sqrtLambdaInvH;zeros(M,p)];
                ytilde         = [sqrtLambdaInvy;zeros(M,1)];
                
                QTHtilde       = Q'*Htilde;
                QTytilde       = Q'*ytilde;
                
                clear Q;
                
                HTVInvH        = HTLambdaInvH - QTHtilde'*QTHtilde;
                HTVInvy        = HTLambdaInvy - QTHtilde'*QTytilde;                
                yTVInvy        = yTLambdaInvy - QTytilde'*QTytilde;
                
                if ( p == 0 )
                    betaHat = zeros(0,1);
                else
                    betaHat = HTVInvH \ HTVInvy;                
                end
                
                % 9.9 Compute the negative profiled log likelihood.                
                quadTerm = yTVInvy - 2*HTVInvy'*betaHat + betaHat'*(HTVInvH*betaHat);                
                logTerm  = sum(log(abs(diagLambda))) + 2*sum(log(abs(diag(R))));                
                loglik   = -0.5*quadTerm - const -0.5*logTerm;                
                nloglik  = -1*loglik;
                
                % 9.10 Ensure that the computed nloglik is finite. If not
                % return a bad value for nloglik and return right away.
                if ~isfinite(nloglik)
                    nloglik = badnloglik;
                    if nargout > 1
                        if haveGrad
                            gnloglik = zeros(s,1);
                        else
                            gnloglik = [];
                        end
                    end
                    return;                                        
                end
                
                % 9.11 Compute derivatives if required.
                if nargout > 1
                    if haveGrad
                        % Derivatives are available.                        
                        
                        % 9.12 Compute rHat and other useful quantities.
                        QTztilde      = QTytilde - QTHtilde*betaHat;
                        rHat          = invDiagLambda.*((y - H*betaHat) - LAAInvKAX'*(R \ QTztilde));
                        KAXrHat       = KXA'*rHat;
                        KAAInvKAXrHat = LAA' \ (LAA \ KAXrHat);
                        LInvKAX       = L \ KXA';
                        LInvKAXdiag   = sum(LInvKAX.*LInvKAX,1)';
                        if useFIC
                            % This is needed for computing the derivatives
                            % of diagonal matrix Omega.
                            KAAInvKAX = LAA' \ LAAInvKAX;
                        end
                        
                        % 9.13 Derivatives w.r.t. theta - first (s-1) elements of phi.
                        gloglik = zeros(s,1);
                        
                        for r = 1:s-1
                            % 9.14 Derivatives of K(X,XA).
                            DKXAr = DKXA(r);
                            
                            % 9.15 Quadratic term of the derivative.
                            quadTerm = 2*(rHat'*DKXAr)*KAAInvKAXrHat ...
                                        - KAAInvKAXrHat'*(DKXAr(A,:))*KAAInvKAXrHat;
                            if useFIC
                                % Add contribution due to Omega for FIC.
                                diagDOmegar = DdiagK(r) - 2*sum(DKXAr'.*KAAInvKAX,1)' + sum(KAAInvKAX.*(DKXAr(A,:)*KAAInvKAX),1)';
                                quadTerm    = quadTerm + rHat'*(diagDOmegar.*rHat);
                            end
                            
                            % 9.16 Trace term of the derivative.
                            LInvDKAXr  = L \ DKXAr';
                            traceTerm1 = sum( sum(LInvKAX .* LInvDKAXr,1)' .* invDiagLambda );
                            traceTerm2 = sum( sum(LInvKAX .* (((L \ DKXAr(A,:)) / LAA')*LAAInvKAX),1)' .* invDiagLambda );

                            if useFIC
                                % traceTerm3 is non-zero only for FIC.
                                lambdaOmega = diagDOmegar.*invDiagLambda2;                               
                                traceTerm3  = sum(diagDOmegar.*invDiagLambda) - sum(LInvKAXdiag .* lambdaOmega);
                            else
                                traceTerm3  = 0;
                            end                  
                            traceTerm = 2*traceTerm1 - traceTerm2 + traceTerm3;
                            
                            % 9.17 Total gradient.
                            gloglik(r) = 0.5*quadTerm - 0.5*traceTerm;
                        end 
                        
                        % 9.18 Derivatives w.r.t. gamma. phi(s) = gamma. 
                        % The term sigma_sigmaLB replaces sigma^2 when
                        % there is a lower bound on sigma.
                        quadTerm         = rHat'*rHat;
                        traceTerm        = sum(invDiagLambda) - sum(LInvKAXdiag .* invDiagLambda2);                      
                        sigma_sigmaLB    = sigma*(sigma - sigmaLB);
                        gloglik(s)       = sigma_sigmaLB*(quadTerm - traceTerm);
                        
                        % 9.19 Multiply gloglik by -1.
                        gnloglik = -1*gloglik;
                    else
                        % Derivative information is not available.
                        gnloglik = [];
                    end
                end
            end                                    
        end % end of makeNegativeProfiledLogLikelihoodSparseQR.
         
        function [objFun,haveGrad] = makeNegativeProfiledLogLikelihoodSparseV(this,X,y,A,beta0,theta0,sigma0,usecache,useFIC) %#ok<INUSL>
        %   [objFun,haveGrad] = makeNegativeProfiledLogLikelihoodSparseV(this,X,y,A,beta0,theta0,sigma0,usecache,useFIC)
        %   takes a GPImpl object this, a N-by-D matrix X, N-by-1 vector y,
        %   N-by-1 logical vector A indicating the active set and initial
        %   values of GPR parameters beta0, theta0 and sigma0 and returns
        %   an objective function objFun for minimization. Input usecache
        %   is a boolean indicating whether squared Euclidean distances
        %   should be cached for built-in kernels. Input useFIC is a
        %   logical scalar indicating the type of sparse approximation to
        %   use. If useFIC is true, we use the FIC approximation otherwise
        %   we use the SR approximation. Output haveGrad is true if objFun
        %   can return gradient information and is false otherwise (see
        %   below for more info). This version uses the so called V-method
        %   described in Foster et al. (2009) - "Stable and Efficient
        %   Gaussian Process Calculations".
        %
        %   o objFun accepts a parameter vector phi such that:               
        %
        %       phi = [theta;gamma]
        %
        %   where gamma is unconstrained and parameterizes the noise
        %   standard deviation:
        %
        %       sigma = sigmaLB + exp(gamma)
        %
        %   and sigmaLB is a lower bound on sigma.        
        %
        %   o For built-in kernel functions, objFun can be called like this:
        %
        %   [Fun,gradFun] = objFun(phi)
        %
        %   where Fun is the function value and gradFun is the gradient of
        %   the function evaluated at phi.
        %
        %   o For custom kernel functions, objFun does not return gradient
        %   information and it must be called like this:
        %
        %   Fun = objFun(phi)
        
            % 1. Make kernel as function of theta. kfcn below can be
            % called like this:
            %             [KXA,DKXA] = kfcn(ThetaNew)
            %  
            %     where
            %  
            %     o ThetaNew is some new value of Theta.
            %     o KXA  = K(X,XA | ThetaNew).
            %     o DKXA = A function handle that accepts an integer i such that 
            %              DKXA(i) is the derivative of K(X,XA | Theta) w.r.t. 
            %              Theta(i) evaluated at ThetaNew.
            %
            % For custom kernel functions, DKXA is [].            
                % 1.1 Part of X corresponding to the active set A.
                XA = X(A,:);
                % 1.2 Create kernel function.
                assert( islogical(usecache) );            
                kfcn = makeKernelAsFunctionOfTheta(this.Kernel,X,XA,usecache);     
        
            % 2. Make function to evaluate diagonal of kernel as a function
            % of theta. diagkfcn below can be called like this:
            %
            %             [diagK,DdiagK] = diagkfcn(ThetaNew)
            %
            %     where
            %
            %     o ThetaNew is some new value of Theta.
            %     o diagK  = diag( K(X,X | ThetaNew) ).
            %     o DdiagK = A function handle that accepts an integer i
            %                such that DdiagK(i) is the derivative of diag( K(X,X | Theta) )
            %                w.r.t. Theta(i) evaluated at ThetaNew.
            %
            % For custom kernel functions, DdiagK = [].
            diagkfcn = makeDiagKernelAsFunctionOfTheta(this.Kernel,X,usecache);                
                
            % 3. Get basis matrix and the number of columns in it.
            H = this.HFcn(X);
            p = size(H,2);
            
            % 4. Number of observations in X and XA.
            N  = size(X,1);
            M  = size(XA,1);            
            
            % 5. Compute constant that appears in profiled log likelihood.
            % const below is such that profiled log likelihood has the
            % constant -const and negative profiled log likelihood has the
            % constant const.
            const = (N/2)*log(2*pi);
            
            % 6. Do we have a built-in kernel function. If so, gradient
            % information is available.
            isbuiltin = this.IsBuiltInKernel;
            if isbuiltin
                haveGrad = true;
            else
                haveGrad = false;
            end
            
            % 7. Length of vector phi, lower bound on sigma and bad value
            % for negative log likelihood - to be returned when computation
            % of negative log likelihood generates NaN/Inf values. One
            % example, when this may happen is when H is rank deficient.
            s          = length(theta0) + 1;
            sigmaLB    = this.Options.SigmaLowerBound;
            badnloglik = this.BadNegativeLogLikelihood;
        
            % 8. Regularization on low rank matrix factorization.
            tau = this.Options.Regularization;
                        
            % 9. Make objFun. This returns the *negative* log likelihood
            % and its gradient information.
            objFun = @f5;
            function [nloglik,gnloglik] = f5(phi)
                
                % 9.1 Extract theta and sigma from phi.               
                theta = phi(1:s-1,1);
                gamma = phi(s,1);
                sigma = sigmaLB + exp(gamma);                
                
                % 9.2 Compute kernel function and its derivatives.
                [KXA,DKXA] = kfcn(theta);
                
                % 9.3 Compute diagonal of kernel function and its derivatives.
                [diagK,DdiagK] = diagkfcn(theta);
                
                % 9.4 Compute KAA - regularize the diagonal.
                KAA            = KXA(A,:);
                KAA(1:M+1:M^2) = KAA(1:M+1:M^2) + tau^2;                
                
                % 9.5 Cholesky factor of KAA.
                [LAA,flag1] = chol(KAA,'lower');
                if ( flag1 ~= 0 )
                    % KAA is not positive definite - numerically speaking.
                    % Return a bad value for the negative log likelihood
                    % (the thing being minimized).
                    nloglik = badnloglik;
                    if nargout > 1
                        if haveGrad
                            gnloglik = zeros(s,1);
                        else
                            gnloglik = [];
                        end
                    end
                    return;
                end
                
                % 9.6 Compute diagonal matrix Lambda and its inverse. For
                % the SR approximation, Lambda = sigma^2*eye(N).
                LAAInvKAX             = LAA \ KXA';
                if useFIC                    
                    diagLambda        = max(0, sigma^2 + diagK - sum(LAAInvKAX.^2,1)');                    
                else                    
                    diagLambda        = (sigma^2)*ones(N,1);                    
                end
                invDiagLambda         = 1./diagLambda;
                sqrtInvDiagLambda     = sqrt(invDiagLambda);
                invDiagLambda2        = invDiagLambda.*invDiagLambda;
                
                % 9.7 Form the matrix BA = LAA * SA * LAA'. R is the upper
                % triangular Cholesky factor of SA: SA = R'*R. Suppose L is
                % the lower triangular Cholesky factor of BA then:
                %
                %   BA = L * L'
                %   L  = LAA * R'
                SA        = bsxfun(@times,sqrtInvDiagLambda,LAAInvKAX');
                SA        = eye(M) + SA'*SA;
                [R,flag2] = chol(SA);
                if ( flag2 ~= 0 )
                    % SA is not positive definite - numerically speaking.
                    % Return a bad value for the negative log likelihood
                    % (the thing being minimized).
                    nloglik = badnloglik;
                    if nargout > 1
                        if haveGrad
                            gnloglik = zeros(s,1);
                        else
                            gnloglik = [];
                        end
                    end
                    return;
                end
                L = LAA*R';
                
                % 9.8 Compute profiled coefficients betaHat.
                LambdaInvH        = bsxfun(@times,invDiagLambda,H);
                LambdaInvy        = bsxfun(@times,invDiagLambda,y);
                                
                LInvKAXLambdaInvH = L \ (KXA'*LambdaInvH);
                LInvKAXLambdaInvy = L \ (KXA'*LambdaInvy);
                
                HTLambdaInvH      = H'*LambdaInvH;                
                HTLambdaInvy      = H'*LambdaInvy;
                yTLambdaInvy      = y'*LambdaInvy;
                                
                HTVInvH           = HTLambdaInvH - LInvKAXLambdaInvH'*LInvKAXLambdaInvH;
                HTVInvy           = HTLambdaInvy - LInvKAXLambdaInvH'*LInvKAXLambdaInvy;
                yTVInvy           = yTLambdaInvy - LInvKAXLambdaInvy'*LInvKAXLambdaInvy;
                
                if ( p == 0 )
                    betaHat = zeros(0,1);
                else
                    betaHat = HTVInvH \ HTVInvy;                
                end
                
                % 9.9 Compute the negative profiled log likelihood.                
                quadTerm = yTVInvy - 2*HTVInvy'*betaHat + betaHat'*(HTVInvH*betaHat);                
                logTerm  = sum(log(abs(diagLambda))) + 2*sum(log(abs(diag(R))));                
                loglik   = -0.5*quadTerm - const -0.5*logTerm;                
                nloglik  = -1*loglik;
                
                % 9.10 Ensure that the computed nloglik is finite. If not
                % return a bad value for nloglik and return right away.
                if ~isfinite(nloglik)
                    nloglik = badnloglik;
                    if nargout > 1
                        if haveGrad
                            gnloglik = zeros(s,1);
                        else
                            gnloglik = [];
                        end
                    end
                    return;                                        
                end
                
                % 9.11 Compute derivatives if required.
                if nargout > 1
                    if haveGrad
                        % Derivatives are available.                        
                        
                        % 9.12 Compute rHat and other useful quantities.                        
                        BAInvKAXLambdaInvAdjy = L' \ (LInvKAXLambdaInvy - LInvKAXLambdaInvH*betaHat);
                        rHat                  = invDiagLambda.*(y - H*betaHat - KXA*BAInvKAXLambdaInvAdjy);
                        
                        KAXrHat       = KXA'*rHat;
                        KAAInvKAXrHat = LAA' \ (LAA \ KAXrHat);
                        LInvKAX       = L \ KXA';
                        LInvKAXdiag   = sum(LInvKAX.*LInvKAX,1)';
                        if useFIC
                            % This is needed for computing the derivatives
                            % of diagonal matrix Omega.
                            KAAInvKAX = LAA' \ LAAInvKAX;
                        end
                        
                        % 9.13 Derivatives w.r.t. theta - first (s-1) elements of phi.
                        gloglik = zeros(s,1);
                        
                        for r = 1:s-1
                            % 9.14 Derivatives of K(X,XA).
                            DKXAr = DKXA(r);
                            
                            % 9.15 Quadratic term of the derivative.
                            quadTerm = 2*(rHat'*DKXAr)*KAAInvKAXrHat ...
                                        - KAAInvKAXrHat'*(DKXAr(A,:))*KAAInvKAXrHat;
                            if useFIC
                                % Add contribution due to Omega for FIC.
                                diagDOmegar = DdiagK(r) - 2*sum(DKXAr'.*KAAInvKAX,1)' + sum(KAAInvKAX.*(DKXAr(A,:)*KAAInvKAX),1)';
                                quadTerm    = quadTerm + rHat'*(diagDOmegar.*rHat);
                            end
                            
                            % 9.16 Trace term of the derivative.
                            LInvDKAXr  = L \ DKXAr';
                            traceTerm1 = sum( sum(LInvKAX .* LInvDKAXr,1)' .* invDiagLambda );
                            traceTerm2 = sum( sum(LInvKAX .* (((L \ DKXAr(A,:)) / LAA')*LAAInvKAX),1)' .* invDiagLambda );

                            if useFIC
                                % traceTerm3 is non-zero only for FIC.
                                lambdaOmega = diagDOmegar.*invDiagLambda2;                               
                                traceTerm3  = sum(diagDOmegar.*invDiagLambda) - sum(LInvKAXdiag .* lambdaOmega);
                            else
                                traceTerm3  = 0;
                            end                  
                            traceTerm = 2*traceTerm1 - traceTerm2 + traceTerm3;
                            
                            % 9.17 Total gradient.
                            gloglik(r) = 0.5*quadTerm - 0.5*traceTerm;
                        end 
                        
                        % 9.18 Derivatives w.r.t. gamma. phi(s) = gamma. 
                        % The term sigma_sigmaLB replaces sigma^2 when
                        % there is a lower bound on sigma.
                        quadTerm         = rHat'*rHat;
                        traceTerm        = sum(invDiagLambda) - sum(LInvKAXdiag .* invDiagLambda2);                      
                        sigma_sigmaLB    = sigma*(sigma - sigmaLB);
                        gloglik(s)       = sigma_sigmaLB*(quadTerm - traceTerm);
                        
                        % 9.19 Multiply gloglik by -1.
                        gnloglik = -1*gloglik;
                    else
                        % Derivative information is not available.
                        gnloglik = [];
                    end
                end
            end                                    
        end % end of makeNegativeProfiledLogLikelihoodSparseV.
        
    end
    
    % Method for active set selection.
    methods
       
        function [activeSet,activeSetIndices,critProfile] = selectActiveSet(this,X,y,beta,theta,sigma)
        %selectActiveSet - Select an active set of observations.
        %   [activeSet,activeSetIndices,critProfile] = selectActiveSet(this,X,y,beta,theta,sigma) 
        %   takes a GPImpl object this, N-by-D predictor matrix X, N-by-1
        %   response vector y and GPR model parameters beta, theta and
        %   sigma and returns a N-by-1 logical vector activeSet where true
        %   elements indicate the selected active set. activeSetIndices is
        %   an integer vector containing the sequence of points included in
        %   the active set. critProfile contains the selection criterion
        %   values as the active set grows in size. The interpretation of
        %   critProfile depends on the active set method like this:
        %
        %       ActiveSetMethod           Meaning of critProfile
        %       'SGMA'              -     Approximation error in RKHS norm
        %       'Entropy'           -     Differential entropy score
        %       'Likelihood'        -     Log likelihood of SR approximation
        %
        %   critProfile(1) contains the criterion value when active set is
        %   empty and critProfile(end) contains the criterion value for the
        %   selected active set.
        %
        %   We try to select an active set of size this.ActiveSetSize. If
        %   the active set selection procedure terminates before the
        %   desired active set size is reached, we pad the active set with
        %   randomly chosen observations so that we get an active set of
        %   size this.ActiveSetSize.
        
            import classreg.learning.modelparams.GPParams;
        
            % 1. Get the active set selection options.
            M            = this.ActiveSetSize;
            activemethod = this.ActiveSetMethod;
            J            = this.Options.RandomSearchSetSize;
            tol          = this.Options.ToleranceActiveSet;
            isverbose    = this.Verbose > 0;
            N            = size(X,1);
            tau          = this.Options.Regularization;
            
            % 2. Get kfun, diagkfun.
            kfun     = makeKernelAsFunctionOfXNXM(this.Kernel,theta);
            diagkfun = makeDiagKernelAsFunctionOfXN(this.Kernel,theta);
            
            % 3. Display message about active set selection (if required).
            if isverbose
                activeSetMessageStr = getString(message('stats:classreg:learning:impl:GPImpl:GPImpl:MessageActiveSetSelection',activemethod,M));
                fprintf('\n');
                fprintf('%s\n',activeSetMessageStr);
            end
            
            % 4. Do the active set selection.
            switch lower(activemethod)
                case lower(GPParams.ActiveSetMethodSGMA)
                    
                    [activeSet,~,critProfile,~] = classreg.learning.gputils.selectActiveSet(X,kfun,diagkfun,...
                        'ActiveSetMethod','SGMA','ActiveSetSize',M,...
                        'RandomSearchSetSize',J,'Tolerance',tol,'Verbose',isverbose,'Regularization',tau);
                    
                case lower(GPParams.ActiveSetMethodEntropy)
                    
                    [activeSet,~,critProfile,~] = classreg.learning.gputils.selectActiveSet(X,kfun,diagkfun,...
                        'ActiveSetMethod','Entropy','ActiveSetSize',M,...
                        'RandomSearchSetSize',J,'Tolerance',tol,'Verbose',isverbose,'Sigma',sigma,'Regularization',tau);
                    
                case lower(GPParams.ActiveSetMethodLikelihood)
                    
                    H         = this.HFcn(X);
                    adjy      = y - H*beta;
                    [activeSet,~,critProfile,~] = classreg.learning.gputils.selectActiveSet(X,kfun,diagkfun,...
                        'ActiveSetMethod','Likelihood','ActiveSetSize',M,...
                        'RandomSearchSetSize',J,'Tolerance',tol,'Verbose',isverbose,'Sigma',sigma,'ResponseVector',adjy,'Regularization',tau);
                    
                case lower(GPParams.ActiveSetMethodRandom)

                    activeSet   = randsample(N,M);
                    critProfile = [];
            end
            
            % 5. If length(activeSet) < M add additonal random elements.
            if ( length(activeSet) < M )
                % 5.1 Points from which we will select randomly. Active set
                % selection methods do not return a logical vector.
                R = setdiff((1:N)',activeSet);
                
                % 5.2 Select M - length(activeSet) points at random from R.                
                additionalPoints = R( randsample(length(R),M - length(activeSet)) );
                
                % 5.3 Add additionalPoints to activeSet.
                activeSet = [activeSet;additionalPoints];
            end
        
            % 6. activeSet should be returned as a logical vector of length
            % N. activeSetIndices contains the active set as an integer
            % vector. activeSetIndices gives us the sequence of points
            % added to the active set whereas the logical version of the
            % active set does not.
            logicalActiveSet            = false(N,1);
            logicalActiveSet(activeSet) = true;
            activeSetIndices            = activeSet;
            activeSet                   = logicalActiveSet;
            
        end % end of selectActiveSet.
        
    end
    
    % General utility methods.
    methods
        function [phiHat,nloglikHat,cause] = doMinimizationWithSomeConstParams(this,objFun,phi0,haveGrad)
            % Wrap the objective function in one that eliminates the
            % constant parameters from the optimization. Recall that
            % phi=[theta;gamma]
            
            % 1. Set phi0 to use
            constPhi = [this.ConstantKernelParameters; this.ConstantSigma];
            partialPhi0 = phi0(~constPhi);
            
            % 2. Do the minimization
            [partialPhiHat,nloglikHat,cause] = doMinimization(this,@objFunWithFewerVars,partialPhi0,haveGrad);
            
            % 3. Restore full phiHat
            phiHat = phi0;
            phiHat(~constPhi) = partialPhiHat;
            
            % 4. Define the objective function to use
            function [f, partialGrad] = objFunWithFewerVars(partialPhi)
                fullPhi = phi0;
                fullPhi(~constPhi) = partialPhi;
                [f, fullGrad] = objFun(fullPhi);
                if isempty(fullGrad)
                    partialGrad = [];
                else
                    partialGrad = fullGrad(~constPhi);
                end
            end
        end
        
        function [phiHat,fHat,cause] = doMinimization(this,objFun,phi0,haveGrad)
        %doMinimization - A wrapper around the supported optimizers.
        %   [phiHat,fHat,cause] = doMinimization(this,objFun,phi0,haveGrad)
        %   takes a GPImpl object this, a function handle objFun, a vector
        %   of initial parameter values phi0, a boolean haveGrad and
        %   minimizes objFun using the selected optimizer and optimizer
        %   options (stored in this). haveGrad is true if objFun returns
        %   gradient information and is false otherwise.
        %
        %   phiHat is a vector of optimized parameter values, fHat is the
        %   minimized objective function value and cause is an integer code
        %   indicating the qualitative reason for termination of the
        %   algorithm.
        %
        %   cause = 0      means that the problem was successfully solved. In most
        %                  cases this means that magnitude of the gradient is small
        %                  enough. The interpretation is "Local minimum found"
        %                  (subject to Hessian checks).
        %
        %   cause = 1      means that problem may have been successfully solved. In
        %                  most cases this means that the step size most recently
        %                  taken was small or the changes in objective function was
        %                  small. The interpretation is "Local minimum possible".
        %
        %   cause = 2      means unable to converge to a solution. This may mean
        %                  that iteration/function evaluation limit was reached or
        %                  unable to converge to the specified tolerances.
        
            import classreg.learning.modelparams.GPParams;                                    
            switch lower(this.Optimizer)
                case lower(GPParams.OptimizerFminunc)
                    % 1. [X,FVAL,EXITFLAG] = fminunc(FUN,X0,OPTIONS)                    
                        
                        % 1.1 Get the optimizer options.
                        opts = this.OptimizerOptions;
                        
                        % 1.2 If haveGrad is true opts.GradObj can be
                        % either 'on' or 'off'. If haveGrad is false,
                        % opts.GradObj cannot be 'on'.
                        if ( strcmpi(opts.GradObj,'on') && (haveGrad == false) )
                            opts.GradObj = 'off';
                        end                        
                        
                        % 1.3 Turn iterative display on if required.
                        % Otherwise respect the Display field in opts.
                        if ( this.Verbose > 0 )
                            opts.Display = 'iter';
                        end
                        
                        % 1.4 Invoke the optimizer.
                        [phiHat,fHat,exitFlag] = fminunc(objFun,phi0,opts);
                        
                    % 2. Translate the exitFlag into cause.                    
                    switch exitFlag
                        case 1 
                            % Magnitude of gradient is small enough.
                            cause = 0;
                        case {2,3,5}
                            % Step or function tolerance reached.
                            cause = 1;
                        otherwise
                            % Unable to converge.
                            cause = 2;
                    end
                case lower(GPParams.OptimizerFmincon)
                    % 1. [X,FVAL,EXITFLAG] = fmincon(FUN,X0,A,B,Aeq,Beq,LB,UB,NONLCON,OPTIONS)                    
                        
                        % 1.1 Get the optimizer options.
                        opts = this.OptimizerOptions;
                        
                        % 1.2 If haveGrad is true opts.GradObj can be
                        % either 'on' or 'off'. If haveGrad is false,
                        % opts.GradObj cannot be 'on'.
                        if ( strcmpi(opts.GradObj,'on') && (haveGrad == false) )
                            opts.GradObj = 'off';
                        end
                        
                        % 1.3 Turn iterative display on if required.
                        % Otherwise respect the Display field in opts.
                        if ( this.Verbose > 0 )
                            opts.Display = 'iter';                        
                        end
                        
                        % 1.4 Invoke the optimizer.
                        [phiHat,fHat,exitFlag] = fmincon(objFun,phi0,[],[],[],[],[],[],[],opts);
                        
                    % 2. Translate exitFlag into cause.
                    switch exitFlag
                        case 1
                            % First order optimality satisfied.
                            cause = 0;
                        case {2,3,4,5}
                            % Step or function tolerance reached.
                            cause = 1;
                        otherwise
                            % Unable to converge.
                            cause = 2;
                    end
                case lower(GPParams.OptimizerFminsearch)
                    % 1. [X,FVAL,EXITFLAG] = fminsearch(FUN,X0,OPTIONS)
                    
                        % 1.1 Get the optimizer options.
                        opts = this.OptimizerOptions;
                        
                        % 1.2 Turn iterative display on if required.
                        % Otherwise respect the Display field in opts.
                        if ( this.Verbose > 0 )
                            opts.Display = 'iter';                        
                        end
                    
                        % 1.3 Invoke the optimizer.
                        [phiHat,fHat,exitFlag] = fminsearch(objFun,phi0,opts);
                    
                    % 2. Translate exitFlag into cause.
                    switch exitFlag
                        case 1
                            % Maximum coordinate difference between current
                            % best point and other points in simplex is
                            % less than or equal to TolX, and corresponding
                            % difference in function values is less than or
                            % equal to TolFun.
                            cause = 0;
                        otherwise
                            % Unable to converge.
                            cause = 2;
                    end
                    
                case lower(GPParams.OptimizerQuasiNewton)
                    % 1. [theta,funtheta,gradfuntheta,cause] = fminqn(fun,theta0,varargin)
                    
                        % 1.1 Get the optimizer options.
                        opts = this.OptimizerOptions;
                        
                        % 1.2 If haveGrad is true opts.GradObj can be
                        % either 'on' or 'off'. If haveGrad is false,
                        % opts.GradObj cannot be 'on'.
                        if ( strcmpi(opts.GradObj,'on') && (haveGrad == false) )
                            opts.GradObj = 'off';
                        end
                        
                        % 1.3 Turn iterative display on if required.
                        % Otherwise respect the Display field in opts.
                        if ( this.Verbose > 0 )
                            opts.Display = 'iter';                        
                        end
                        
                        % 1.4 Invoke the optimizer.                        
                        initialStepSize = getInitialStepSize(this,phi0);
                        [phiHat,fHat,~,exitFlag] = classreg.learning.gputils.fminqn(objFun,phi0,'Options',opts,'InitialStepSize',initialStepSize);
                    
                    % 2. Translate exitFlag into cause.
                    cause = exitFlag;

                case lower(GPParams.OptimizerLBFGS)
                    % 1. Use the LBFGS solver.
                    
                        % 1.1 Get the optimizer options.
                        opts = this.OptimizerOptions;

                        % 1.2 If haveGrad is true opts.GradObj can be
                        % either 'on' or 'off'. If haveGrad is false,
                        % opts.GradObj cannot be 'on'.
                        if ( strcmpi(opts.GradObj,'on') && (haveGrad == false) )
                            opts.GradObj = 'off';
                        end

                        % 1.3 Turn iterative display on if required.
                        % Otherwise respect the Display field in opts.
                        if ( this.Verbose > 0 )
                            opts.Display = 'iter';
                        end

                        % 1.4 Invoke the optimizer.                        
                        initialStepSize = getInitialStepSize(this,phi0);
                        [phiHat,fHat,~,exitFlag] = classreg.learning.impl.GPImpl.doLBFGS(objFun,phi0,opts,initialStepSize);
                    
                    % 2. Translate exitFlag into cause.
                    switch exitFlag
                        case 0
                            % Local minimum found.
                            cause = 0;
                        case 1
                            % Local minimum possible.
                            cause = 1;
                        otherwise
                            % Iteration limit reached or line search failed.
                            cause = 2;
                    end
            end
        
        end % end of doMinimization.      
        
        function initialStepSize = getInitialStepSize(this,phi0)
            initialStepSize = this.InitialStepSize;
            % If initialStepSize is a string, it must be 'auto' since we
            % have already validated inputs.
            isStringAuto    = internal.stats.isString(initialStepSize) && ...
                              strcmpi(initialStepSize,classreg.learning.modelparams.GPParams.StringAuto);
            if isStringAuto
                initialStepSize = norm(phi0,Inf)*0.5 + 0.1;
            end
        end
        
        function tf = checkCacheSizeForFitting(this,N,D,M)
        %checkCacheSizeForFitting - Decide if distance matrices should be cached during parameter estimation.
        %   tf = checkCacheSizeForFitting(this,N,D,M) takes a GPImpl object
        %   this, an integer N indicating the number of observations used
        %   for fitting, an integer D indicating the number of predictors
        %   used for fitting and an integer M indicating the size of the
        %   active set used for fitting and returns a logical scalar tf
        %   that is true if sufficient cache memory is available to cache
        %   distance matrices during fitting and false otherwise. 
        %
        %   o For 'Exact' fitting M is equal to N and for sparse fitting 
        %   ('SD', 'SR' or 'FIC'), M is usually < N.        
        %        
        %   o For ARD kernels, we need to store N*M*D doubles which needs 
        %   N*M*D*8/1e6 MB.
        %
        %   o For non-ARD kernels, we need to store N*M doubles which needs
        %   N*M*8/1e6 MB.
        %
        %   If the supplied 'CacheSize' in MB is big enough then tf is true
        %   otherwise tf is false.
        
            % 1. Do we have an ARD kernel?
            isARDKernel = strncmpi(this.KernelFunction,'ard',3);
        
            % 2. How much memory in MB do we need?
            if isARDKernel
                memoryNeededMB = (N*M*D*8)/1e6;
            else
                memoryNeededMB = (N*M*8)/1e6;
            end
            
            % 3. What is the supplied 'CacheSize' in MB?
            cacheSizeMB = this.CacheSize;
            
            % 4. Do we have enough memory available for caching distances?
            if (memoryNeededMB <= cacheSizeMB)
                tf = true;
            else
                tf = false;
            end
            
        end % end of checkCacheSizeForFitting.        
    end
       
    % Static utility methods.
    methods(Static)       
        function checkExplicitBasisRank(HFcn,X)
        %checkExplicitBasisRank - Check rank of explicit basis in the GPR model.
        %   checkExplicitBasisRank(HFcn,X) takes a function HFcn and a
        %   N-by-D predictor matrix X and ensures that HFcn(X) has full
        %   column rank. If not, a warning message is thrown.
        
            % 1. Evaluate H.
            H = HFcn(X);
            
            % 2. Get rank of H.
            p = rank(H);
            
            % 3. Is H of full column rank?
            isok = (p == size(H,2));
            
            % 4. Throw a warning if needed.
            if ~isok
                warning(message('stats:classreg:learning:impl:GPImpl:GPImpl:BadBasisMatrix')); 
            end
        end
        
        function [phiHat,fHat,gHat,exitFlag] = doLBFGS(objFun,phi0,opts,initialStepSize)
            % 1. Create a solver object.
            numcomp = 1;
            solver  = classreg.learning.fsutils.Solver(numcomp);
            
            % 2. Set solver options.
            solver.SolverName = 'lbfgs';
            
            if strcmpi(opts.GradObj,'on')
                solver.HaveGradient = true;
            else
                solver.HaveGradient = false;
            end
            
            solver.GradientTolerance = opts.TolFun;
            solver.StepTolerance     = opts.TolX;
            solver.IterationLimit    = opts.MaxIter;
            
            if strcmpi(opts.Display,'iter')
                solver.Verbose = 1;
            else
                solver.Verbose = 0;
            end
            
            solver.MaxLineSearchIterations = 50;
            solver.InitialStepSize         = initialStepSize;
            
            % 3. Disable non-convergence warning. The caller should check
            % the exitFlag and display warning as needed.
            warnState  = warning('query','all');
            warning('off','stats:classreg:learning:fsutils:Solver:LBFGSUnableToConverge');
            cleanupObj = onCleanup(@() warning(warnState));
            
            % 4. Do minimization.
            results  = solver.doMinimization(objFun,phi0,numcomp);
            phiHat   = results.xHat;
            fHat     = results.fHat;
            gHat     = results.gHat;
            exitFlag = results.cause;
        end
    end
    
    % Post fit statistics.
     methods        
        function [loores,neff] = postFitStatisticsExact(this,isBetaEstimatedUsingExact)
        %postFitStatisticsExact - Post fit statistics for exact GPR.
        %   loores = postFitStatisticsExact(this) takes a GPImpl object
        %   this and computes leave-one-out residuals for the fitted model
        %   when the PredictMethod is 'Exact'. Output loores is a vector of
        %   length N-by-1 where N is the number of rows in this.X.
        %
        %   [loores,neff] = postFitStatisticsExact(this) also computes a
        %   scalar neff that indicates the effective number of parameters
        %   in the fitted model.
        %
        %   [...] = postFitStatisticsExact(this,isBetaEstimatedUsingExact)
        %   also takes a logical flag isBetaEstimatedUsingExact to control
        %   the calculation of loores and neff. If isBetaEstimatedUsingExact
        %   is true, then beta is forced to be treated as estimated using
        %   FitMethod 'Exact'. Default value for isBetaEstimatedUsingExact
        %   is false.
        %
        %   See section 9 of the GPR theory spec for more info. The method
        %   computes loores and neff depending on whether fixed basis
        %   coefficients beta are estimated from data using FitMethod
        %   'Exact' or not. Outputs are conditional on the kernel
        %   parameters theta and noise standard deviation sigma i.e.,
        %   uncertainty in estimating theta and sigma is not taken into
        %   account.
        
            % 1. Default value for isBetaEstimatedUsingExact.
            if nargin < 2
                isBetaEstimatedUsingExact = false;
            end
        
            % 2. Ensure that PredictMethod is equal to 'Exact'.
            import classreg.learning.modelparams.GPParams; 
            tf = strcmpi(this.PredictMethod,GPParams.PredictMethodExact);
            if ~tf
                error(message('stats:classreg:learning:impl:GPImpl:GPImpl:PostFitStatsPredictMethodExact',GPParams.PredictMethodExact));
            end
            
            % 3. Get estimated theta, sigma and alpha.
            thetaHat = this.ThetaHat;
            sigmaHat = this.SigmaHat;
            alphaHat = this.AlphaHat;
            
            % 4. Get X and the number of observations N.
            X = this.X;  %#ok<PROPLC,*PROP>
            N = size(X,1); %#ok<PROPLC>
            
            % 5. Get L the lower triangular Cholesky factor of
            % [K(X,X | thetaHat) + sigmaHat^2*eye(N)]
            if isempty(this.LFactor)
                % Compute from scratch.
                L = computeLFactorExact(this,X,thetaHat,sigmaHat); %#ok<PROPLC>
            else
                % Reuse previous value.
                L = this.LFactor;
                assert(size(L,1) == N);
            end
            
            % 6. Invert the L factor. Can use triangular inversion utility
            % instead of LInv = L \ eye(N).
            LInv = L \ eye(N);
            %LInv = classreg.learning.gputils.invertTriangular(L,'L');
            
            % 7. Compute A values for each observation needed for computing
            % leave-one-out residuals. Avec below is a N-by-1 vector
            % containing the squared norms of the columns of LInv.
            Avec = sum(LInv.*LInv,1)';
            
            % 8. Compute leave-one-out residuals and effective number of
            % parameters. There are two cases to consider:
            %
            % o Case 1: beta is known - FitMethod is not 'Exact'.
            %
            %   In this case, the N-by-1 vector loores can be written as:
            %
            %   loores = alphaHat./Avec;
            %            
            %   The effective degrees of freedom is given by:
            %
            %   neff = N - sigmaHat^2 * trace(LInv' * LInv)
            %        = N - sigmaHat^2 * sum(sum(LInv.*LInv,1))
            %        = N - sigmaHat^2 * sum(Avec)
            %
            % o Case 2. beta is estimated from data using 'Exact'.
            %
            %   Suppose H is the N-by-p basis matrix. Consider the QR
            %   factorization:
            %
            %   LInv*H = Q*R
            %
            %   where Q is a N-by-p orthogonal matrix and R is a p-by-p
            %   upper triangular matrix. Define a vector Tvec such that:
            %
            %   Tvec(i) = squared norm of i th column of Q'*LInv (p-by-N)
            %
            %   Then it can be shown that:
            %
            %   loores = alphaHat./(Avec - Tvec);
            %
            %   The effective degrees of freedom is given by:
            %
            %   neff = N - sigmaHat^2 * trace(LInv' * LInv) 
            %               + sigmaHat^2 * trace(QTLInv' * QTLInv)
            %
            %        = N - sigmaHat^2 * sum(sum(LInv.*LInv,1))
            %               + sigmaHat^2 * sum(sum(QTLInv.*QTLInv,1))
            %
            %        = N - sigmaHat^2 * sum(Avec) + sigmaHat^2 * sum(Tvec)
            %
            if strcmpi(this.FitMethod,GPParams.FitMethodExact) || isBetaEstimatedUsingExact
                % beta is estimated from data.
                
                % 8.1 LOO residuals.
                H      = this.HFcn(X); %#ok<PROPLC>
                LInvH  = LInv*H;
                [Q,~]  = qr(LInvH,0);
                QTLInv = Q'*LInv;
                Tvec   = sum(QTLInv.*QTLInv,1)';
                loores = alphaHat./(Avec - Tvec);
                
                % 8.2 Effective number of parameters.
                if nargout > 1
                    neff = N - sigmaHat^2 * sum(Avec) + sigmaHat^2 * sum(Tvec);
                    neff = max(0,neff);
                end
            else
                % Treat beta as "known". This is not strictly true if it
                % was estimated using other FitMethod's such as SD, SR or
                % FIC but this is the best we can do.
                
                % 8.1 LOO residuals.
                loores = alphaHat./Avec;
                
                % 8.2 Effective number of parameters.
                if nargout > 1                    
                    neff = N - sigmaHat^2 * sum(Avec);
                    neff = max(0,neff);
                end
            end
                
        end % end of postFitStatisticsExact.
     end
     
end

