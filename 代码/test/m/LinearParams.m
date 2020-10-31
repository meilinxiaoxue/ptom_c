classdef LinearParams < classreg.learning.modelparams.ModelParams
%LinearParams Parameters for the liner solver.
%
%   LinearParams properties:
%       BatchIndex               - Starting batch index for SGD iterations.
%       BatchLimit               - Maximal number of batches for SGD algorithms.
%       BatchSize                - Number of observations per batch.
%       BetaTolerance            - Relative tolerance on the change in the primal coefficients.
%       DeltaGradientTolerance   - Absolute tolerance on the delta gradient for the dual solver.
%       Epsilon                  - epsilon for epsilon-insensitive loss.
%       FitBias                  - Logical flag indicating if the bias term should be fit.
%       GradientTolerance        - Absolute tolerance on the inf norm of the gradient.
%       HessianHistorySize       - Size of history buffer for computing Hessian approximation by LBFGS.
%       InitialBeta              - Initial estimates of the beta coefficients.
%       InitialBias              - Initial estimate of the bias term.
%       IterationLimit           - Maximal number of iterations for (L)BFGS and SpaRSA.
%       Lambda                   - Regularization strength.
%       Learner                  - Learned model such as 'svm' or 'leastsquares'.
%       LearnRate                - Learning rate for (A)SGD.
%       LineSearch               - Line search algorithm for (L)BFGS.
%       LossFunction             - Loss function such as 'hinge' or 'mse'.
%       NumCheckConvergence      - Number of iterations between convergence checks for SGD.
%       OptimizeLearnRate        - Flag indicating if the learning rate for SGD should be optimized.
%       PassLimit                - Maximal number of passes for SGD algorithms.
%       PostFitBias              - Logical flag indicating if the bias term should be fit after the main fit has finished.
%       Regularization           - Regularization such as 'ridge' or 'lasso'.
%       Solver                   - Algorithm such as 'lbfgs' or 'sgd'.
%       Stream                   - Random stream object.
%       TruncationPeriod         - Number of iterations between truncations of coefficients for SGD and ASGD.
%       ValidationX              - Validation X data.
%       ValidationY              - Validation Y data.
%       ValidationW              - Validation weights.
%       VerbosityLevel           - Verbosity level, 0, 1, 2 etc.
   
%   Copyright 2015-2016 The MathWorks, Inc.
    
    properties
        BatchIndex;
        BatchLimit;
        BatchSize;
        BetaTolerance;
        DeltaGradientTolerance;
        Epsilon;
        FitBias;
        GradientTolerance;
        HessianHistorySize;
        InitialBeta;
        InitialBias;
        IterationLimit;
        Learner;
        Lambda;
        LearnRate;
        LineSearch;
        LossFunction;
        NumCheckConvergence;
        OptimizeLearnRate;
        PassLimit;
        PostFitBias;
        Regularization;
        Solver;
        Stream;
        TruncationPeriod;
        ValidationX;
        ValidationY;
        ValidationW;
        VerbosityLevel;
    end
    
    methods(Access=protected)
        function this = LinearParams(type,beta,bias,learner,lossfun,...
                fitbias,postfitbias,regularizer,lambda,maxiter,maxpass,maxbatch,...
                nconv,batchindex,batchsize,solver,betaTol,gradTol,deltaGradTol,...
                learnRate,presolve,truncationK,epsilon,historysize,linesearch,...
                valX,rsh,verbose)
            this = this@classreg.learning.modelparams.ModelParams('Linear',type,2);
            
            this.InitialBeta              = beta;
            this.InitialBias              = bias;
            this.Learner                  = learner;
            this.LossFunction             = lossfun;
            this.FitBias                  = fitbias;
            this.PostFitBias              = postfitbias;
            this.Regularization           = regularizer;
            this.Lambda                   = lambda;
            this.IterationLimit           = maxiter;
            this.PassLimit                = maxpass;
            this.BatchLimit               = maxbatch;
            this.NumCheckConvergence      = nconv;
            this.BatchIndex               = batchindex;
            this.BatchSize                = batchsize;
            this.Solver                   = solver;
            this.BetaTolerance            = betaTol;
            this.GradientTolerance        = gradTol;
            this.DeltaGradientTolerance   = deltaGradTol;
            this.LearnRate                = learnRate;
            this.OptimizeLearnRate        = presolve;
            this.TruncationPeriod         = truncationK;
            this.Epsilon                  = epsilon;
            this.HessianHistorySize       = historysize;
            this.LineSearch               = linesearch;
            
            % Validation data are passed as a cell array with 2 or elements
            % and saved in the ValidationX property. ValidationY and
            % ValidationW are filled in the fillDefaultParams method.
            this.ValidationX              = valX;
            
            this.Stream                   = rsh;
            this.VerbosityLevel           = verbose;               
        end
    end
    
    methods(Static,Hidden)
        function v = expectedVersion()
            v = 2;
        end        
        
        function [holder,extraArgs] = make(type,varargin) 
            % Decode input args
            args = {'beta' 'bias' 'learner' 'lossfunction' 'lambda' ...
                'learnrate' 'optimizelearnrate' ...
                'passlimit' 'batchlimit' 'iterationlimit' ...
                'regularization' 'solver' ...
                'numcheckconvergence' 'batchindex' 'batchsize' ...
                'betatolerance' 'gradienttolerance' 'deltagradienttolerance' ...
                'fitbias' 'postfitbias' 'epsilon' 'validationdata' ...
                'truncationperiod' 'hessianhistorysize' 'linesearch' ...
                'stream' 'verbose'};
            defs = repmat({[]},1,numel(args));
            [beta0,bias0,learner,lossfun,lambda,...
                learnRate,presolve,...
                maxpass,maxbatch,maxiter,...
                regularizer,solvers,...
                nconv,batchindex,batchsize,...
                betatol,gradtol,deltagradtol,...
                fitbias,postfitbias,epsilon,valdata,...
                truncationK,historysize,linesearch,rsh,verbose,~,extraArgs] = ...
                internal.stats.parseArgs(args,defs,varargin{:});

            if ~isempty(beta0)
                internal.stats.checkSupportedNumeric('Beta',beta0);
            end
            
            if ~isempty(bias0)
                internal.stats.checkSupportedNumeric('Bias',bias0);
            end
            
            if ~isempty(learner)
                learner = validatestring(learner,{'svm' 'logistic' 'leastsquares'},...
                    'classreg.learning.modelparams.LinearParams.make','Learner');
            end
            
            if ~isempty(lossfun)
                lossfun = validatestring(lossfun,{'mse' 'logit' 'hinge' 'epsiloninsensitive'},...
                    'classreg.learning.modelparams.LinearParams.make','LossFunction');
            end
            
            if ~isempty(lambda)
                if ischar(lambda) 
                    if ~strncmpi(lambda,'auto',length(lambda))
                        error(message('stats:classreg:learning:modelparams:LinearParams:make:BadLambda'));
                    end
                else
                    internal.stats.checkSupportedNumeric('Lambda',lambda);
                    if ~isvector(lambda) || any(lambda<0)
                        error(message('stats:classreg:learning:modelparams:LinearParams:make:BadLambda'));
                    end
                end
            end
            
            if ~isempty(learnRate)
                internal.stats.checkSupportedNumeric('LearnRate',learnRate);
                if ~isscalar(learnRate) || learnRate<=0
                    error(message('stats:classreg:learning:modelparams:LinearParams:make:BadLearnRate'));
                end
            end
            
            if ~isempty(presolve)
                presolve = internal.stats.parseOnOff(presolve,'OptimizeLearnRate');
            end
            
            if ~isempty(maxpass)
                internal.stats.checkSupportedNumeric('PassLimit',maxpass,true);
                if ~isscalar(maxpass) || maxpass<1 || round(maxpass)~=maxpass
                    error(message('stats:classreg:learning:modelparams:LinearParams:make:BadPassLimit'));
                end
            end

            if ~isempty(maxbatch)
                internal.stats.checkSupportedNumeric('BatchLimit',maxbatch,true);
                if ~isscalar(maxbatch) || maxbatch<1 || round(maxbatch)~=maxbatch
                    error(message('stats:classreg:learning:modelparams:LinearParams:make:BadBatchLimit'));
                end
            end

            if ~isempty(maxiter)
                internal.stats.checkSupportedNumeric('IterationLimit',maxiter,true);
                if ~isscalar(maxiter) || maxiter<1 || round(maxiter)~=maxiter
                    error(message('stats:classreg:learning:modelparams:LinearParams:make:BadIterationLimit'));
                end
            end
            
            if ~isempty(regularizer)
                regularizer = validatestring(regularizer,{'lasso' 'ridge'},...
                    'classreg.learning.modelparams.LinearParams.make','Regularization');
            end
            
            if ~isempty(solvers)                
                if ischar(solvers)
                    solvers = {solvers};
                end
                
                if ~iscellstr(solvers)
                    error(message('stats:classreg:learning:modelparams:LinearParams:make:BadSolver'));
                end
                
                solvers = lower(solvers);
                
                for s=1:numel(solvers)
                    solvers{s} = validatestring(solvers{s},...
                        {'sgd' 'asgd' 'bfgs' 'lbfgs' 'sparsa' 'dual'},...
                        'classreg.learning.modelparams.LinearParams.make','Solvers');
                end
            end

            if ~isempty(nconv)
                internal.stats.checkSupportedNumeric('NumCheckConvergence',nconv,true);
                if ~isscalar(nconv) || nconv<1
                    error(message('stats:classreg:learning:modelparams:LinearParams:make:BadNumCheckConvergence'));
                end
            end
            
            if ~isempty(batchindex)
                internal.stats.checkSupportedNumeric('BatchIndex',batchindex,true);
                if ~isvector(batchindex) || any(batchindex<0) || any(round(batchindex)~=batchindex)
                    error(message('stats:classreg:learning:modelparams:LinearParams:make:BadBatchIndex'));
                end
            end            
            
            if ~isempty(batchsize)
                internal.stats.checkSupportedNumeric('BatchSize',batchsize,true);
                if ~isscalar(batchsize) || batchsize<1 || round(batchsize)~=batchsize
                    error(message('stats:classreg:learning:modelparams:LinearParams:make:BadBatchSize'));
                end
            end
            
            if ~isempty(betatol)
                internal.stats.checkSupportedNumeric('BetaTolerance',betatol);
                if ~isscalar(betatol) || betatol<0
                    error(message('stats:classreg:learning:modelparams:LinearParams:make:BadBetaTolerance'));
                end
            end
            
            if ~isempty(gradtol)
                internal.stats.checkSupportedNumeric('GradientTolerance',gradtol);
                if ~isscalar(gradtol) || gradtol<0
                    error(message('stats:classreg:learning:modelparams:LinearParams:make:BadGradientTolerance'));
                end
            end
            
            if ~isempty(deltagradtol)
                internal.stats.checkSupportedNumeric('DeltaGradientTolerance',deltagradtol);
                if ~isscalar(deltagradtol) || deltagradtol<0
                    error(message('stats:classreg:learning:modelparams:LinearParams:make:BadDeltaGradientTolerance'));
                end
            end
            
            if ~isempty(fitbias)
                fitbias = internal.stats.parseOnOff(fitbias,'FitBias');
            end
            
            if ~isempty(postfitbias)
                postfitbias = internal.stats.parseOnOff(postfitbias,'PostFitBias');
            end
            
            if ~isempty(epsilon)
                internal.stats.checkSupportedNumeric('Epsilon',epsilon);
                if ~isscalar(epsilon) || epsilon<0
                    error(message('stats:classreg:learning:modelparams:LinearParams:make:BadEpsilon'));
                end
            end
            
            if ~isempty(valdata)
                if ~iscell(valdata) || numel(valdata)<2 || numel(valdata)>3
                    error(message('stats:classreg:learning:modelparams:LinearParams:make:BadValidationData'));
                end
            end
            
            if ~isempty(truncationK)
                internal.stats.checkSupportedNumeric('TruncationPeriod',truncationK,true);
                if ~isscalar(truncationK) || truncationK<1 ...
                        || round(truncationK)~=truncationK
                    error(message('stats:classreg:learning:modelparams:LinearParams:make:BadTruncationPeriod'));
                end
            end
            
            if ~isempty(historysize)
                internal.stats.checkSupportedNumeric('HessianHistorySize',historysize,true);
                if ~isscalar(historysize) || historysize<1 ...
                        || round(historysize)~=historysize
                    error(message('stats:classreg:learning:modelparams:LinearParams:make:BadHessianHistorySize'));
                end
            end
            
            if ~isempty(linesearch)
                linesearch = validatestring(linesearch,{'backtrack' 'weakwolfe'},...
                    'classreg.learning.modelparams.LinearParams.make','LineSearch');
            end
            
            if ~isempty(verbose)
                internal.stats.checkSupportedNumeric('Verbose',verbose,true);
                if verbose<0
                    error(message('stats:classreg:learning:modelparams:LinearParams:make:BadVerbose'));
                end
            end
            
            holder = classreg.learning.modelparams.LinearParams(...
                type,beta0,bias0,learner,lossfun,...
                fitbias,postfitbias,regularizer,lambda,maxiter,maxpass,maxbatch,...
                nconv,batchindex,batchsize,solvers,betatol,gradtol,deltagradtol,...
                learnRate,presolve,truncationK,epsilon,historysize,linesearch,...
                valdata,rsh,verbose);
        end
        
        
        function this = loadobj(obj)
            found = fieldnames(obj);
            
            if ismember('Version',found) && ~isempty(obj.Version) ...
                    && obj.Version==classreg.learning.modelparams.LinearParams.expectedVersion()
                
                % If object of the same version, copy all params as is.
                this = obj;
                
            else
                
                % If a different version, assume defaults for params not
                % found in the input struct.
                if ismember('LineSearch',found) ...
                        && ~isempty(obj.LineSearch)
                    linesearch = obj.LineSearch;
                else
                    linesearch = 'weakwolfe';
                end
                
                this = classreg.learning.modelparams.LinearParams(...
                    obj.Type,obj.InitialBeta,obj.InitialBias,obj.Learner,obj.LossFunction,...
                    obj.FitBias,obj.PostFitBias,obj.Regularization,obj.Lambda,...
                    obj.IterationLimit,obj.PassLimit,obj.BatchLimit,...
                    obj.NumCheckConvergence,obj.BatchIndex,obj.BatchSize,...
                    obj.Solver,obj.BetaTolerance,obj.GradientTolerance,obj.DeltaGradientTolerance,...
                    obj.LearnRate,obj.OptimizeLearnRate,obj.TruncationPeriod,...
                    obj.Epsilon,obj.HessianHistorySize,linesearch,...
                    {obj.ValidationX obj.ValidationY obj.ValidationW},...
                    obj.Stream,obj.VerbosityLevel);
            end
        end
    end

    
    methods(Hidden)
        function this = fillDefaultParams(this,X,Y,W,dataSummary,classSummary)
            doclass = ~isempty(classSummary);
            
            [D,N] = size(X);
            
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
                                error(message('stats:classreg:learning:modelparams:LinearParams:fillDefaultParams:UnknownClassificationLoss'));
                        end
                    else
                        switch this.LossFunction
                            case 'epsiloninsensitive'
                                this.Learner = 'svm';
                            case 'mse'
                                this.Learner = 'leastsquares';
                            otherwise
                                error(message('stats:classreg:learning:modelparams:LinearParams:fillDefaultParams:UnknownRegressionLoss'));
                        end
                    end
                end
                
            else
                if doclass
                    switch this.Learner
                        case 'svm'
                            if ~isempty(this.LossFunction) && ~strcmp(this.LossFunction,'hinge')
                                error(message('stats:classreg:learning:modelparams:LinearParams:fillDefaultParams:BadLossForClassificationSVM'));
                            end
                            this.LossFunction = 'hinge';
                        case 'logistic'
                            if ~isempty(this.LossFunction) && ~strcmp(this.LossFunction,'logit')
                                error(message('stats:classreg:learning:modelparams:LinearParams:fillDefaultParams:BadLossForLogisticRegression'));
                            end
                            this.LossFunction = 'logit';
                        otherwise
                            error(message('stats:classreg:learning:modelparams:LinearParams:fillDefaultParams:BadLearnerForClassification'));
                    end
                else
                    switch this.Learner
                        case 'svm'
                            if ~isempty(this.LossFunction) && ~strcmp(this.LossFunction,'epsiloninsensitive')
                                error(message('stats:classreg:learning:modelparams:LinearParams:fillDefaultParams:BadLossForRegressionSVM'));
                            end
                            this.LossFunction = 'epsiloninsensitive';
                        case 'leastsquares'
                            if ~isempty(this.LossFunction) && ~strcmp(this.LossFunction,'mse')
                                error(message('stats:classreg:learning:modelparams:LinearParams:fillDefaultParams:BadLossForLeastSquares'));
                            end
                            this.LossFunction = 'mse';
                        otherwise
                            error(message('stats:classreg:learning:modelparams:LinearParams:fillDefaultParams:BadLearnerForRegression'));
                    end
                    
                end
            end
                        
            if isempty(this.Regularization)
                if ismember('sparsa',this.Solver)
                    this.Regularization = 'lasso';
                else
                    this.Regularization = 'ridge';
                end
            end
            
            doridge = strcmp(this.Regularization,'ridge');
            
            if isempty(this.Solver)
                if     D<=100
                    if doridge
                        this.Solver = {'bfgs'};
                    else
                        this.Solver = {'sparsa'};
                    end
                elseif doridge && ismember(this.LossFunction,{'hinge' 'epsiloninsensitive'})
                    this.Solver = {'dual'};
                else
                    this.Solver = {'sgd'};
                end
                
            else
                solver = this.Solver(:)';
                
                if numel(unique(solver))~=numel(solver)
                    error(message('stats:classreg:learning:modelparams:LinearParams:fillDefaultParams:MultipleCallsToSameSolver'));
                end
                
                [~,pos] = ismember('dual',solver);
                
                if any(pos>0) && ~doridge
                    error(message('stats:classreg:learning:modelparams:LinearParams:fillDefaultParams:UseRidgeForDual'));
                end
                
                if any(pos>1)
                    % To have the dual solver as a second solver, we would
                    % need a way to obtain estimates of the dual alpha
                    % coefficients from the previous solver. Since all
                    % other solvers are primal, it's impossible.
                    error(message('stats:classreg:learning:modelparams:LinearParams:fillDefaultParams:DualSolverMustBeFirst'));
                end
                
                [~,pos] = ismember({'sgd' 'asgd'},solver);
                if any(pos>1)
                    warning(message('stats:classreg:learning:modelparams:LinearParams:fillDefaultParams:SGDNotFirstSolver'));
                end
                
                if ismember('sparsa',solver) && doridge
                    error(message('stats:classreg:learning:modelparams:LinearParams:fillDefaultParams:UseLassoForSpaRSA'));
                end
                
                if any(ismember({'bfgs' 'lbfgs'},solver)) && ~doridge
                    error(message('stats:classreg:learning:modelparams:LinearParams:fillDefaultParams:UseRidgeForBFGS'));
                end
                
                this.Solver = solver;
            end
            
            dosgd = any(ismember({'sgd' 'asgd'},this.Solver));
            dodual = ismember('dual',this.Solver);
            dononsgd = any(ismember({'bfgs' 'lbfgs' 'sparsa'},this.Solver));
            
            if isempty(this.BatchSize)
                if dosgd
                    if issparse(X)
                        this.BatchSize = max( min(10,N), ceil(sqrt(numel(X)/nnz(X))) );
                    else
                        this.BatchSize = min(10,N);
                    end
                end
            else
                if dosgd && this.BatchSize>N
                    error(message('stats:classreg:learning:modelparams:LinearParams:fillDefaultParams:BatchSizeTooLarge',N));
                end
            end
            
            if isempty(this.PassLimit)
                if     dosgd
                    this.PassLimit = 1;
                elseif dodual
                    this.PassLimit = 10;
                end
                
                % If SGD is used as an initial approximation, limit the
                % number of observations processed by SGD to avoid long run
                % time.
                if isempty(this.BatchLimit)
                    if dosgd && ~isscalar(this.Solver)
                        [~,pos] = ismember({'sgd' 'asgd'},this.Solver);
                        if any(pos==1) && all(pos<2)
                            this.BatchLimit = ceil(1e6/this.BatchSize);
                        end
                    end
                end
            end
            
            if isempty(this.BatchLimit) && dosgd
                this.BatchLimit = 0;
            end
            
            if dodual
                if ~ismember(this.LossFunction,{'hinge' 'epsiloninsensitive'})
                    error(message('stats:classreg:learning:modelparams:LinearParams:fillDefaultParams:UseDualSolverForSVM'));
                end
                
                if isempty(this.DeltaGradientTolerance)
                    if doclass
                        this.DeltaGradientTolerance = 1;
                    else
                        this.DeltaGradientTolerance = 0.1;
                    end
                end
            end
            
            if isempty(this.VerbosityLevel)
                this.VerbosityLevel = 0;
            end            
            
            if isempty(this.NumCheckConvergence)
                if dosgd
                    this.NumCheckConvergence = 0;
                end
                
                if dosgd && (this.VerbosityLevel>0 || ~isempty(this.ValidationX))
                    % number of iterations
                    this.NumCheckConvergence = ceil(10^floor(log10(N/(5*this.BatchSize))));
                    while N/(this.BatchSize*this.NumCheckConvergence) > 10
                        this.NumCheckConvergence = 2*this.NumCheckConvergence;
                    end
                    this.NumCheckConvergence = min( 10000, this.NumCheckConvergence );
                end
                
                if dodual
                    % number of passes
                    this.NumCheckConvergence = 2; 
                end
            end
            
            if isempty(this.LearnRate) 
                if dosgd
                    x2 = sum(X.^2,1);
                    this.LearnRate = 1./sqrt(1 + max(x2));
                    
                    if ~doridge && ismember('asgd',this.Solver)
                        this.LearnRate = this.LearnRate...
                            *sqrt(N*this.PassLimit/this.BatchSize/2);
                    end
                end                
            end

            if isempty(this.FitBias)
                this.FitBias = true;
            end

            if isempty(this.PostFitBias)
                this.PostFitBias = false;
            end

            if ~this.FitBias
                if this.PostFitBias
                    error(message('stats:classreg:learning:modelparams:LinearParams:fillDefaultParams:FitBiasPostFitBiasMismatch'));
                end
                
                if this.InitialBias~=0
                    error(message('stats:classreg:learning:modelparams:LinearParams:fillDefaultParams:FitBiasBetaMismatch'));
                end
            end
            
            if     isempty(this.Lambda) || ischar(this.Lambda)
                this.Lambda = 'auto';
                L = 1;
            elseif ~ischar(this.Lambda)
                this.Lambda = unique(this.Lambda(:))'; % keep as a sorted row-vector
                L = numel(this.Lambda);
            end
            
            if isempty(this.InitialBeta)
                this.InitialBeta = zeros(D,1);
            else
                if ~isequal(size(this.InitialBeta),[D 1]) ...
                        && ~isequal(size(this.InitialBeta),[D L])
                    error(message('stats:classreg:learning:modelparams:LinearParams:fillDefaultParams:BadBeta',D,L,D));
                end
            end            
            
            if isempty(this.InitialBias)
                if this.FitBias
                    switch this.LossFunction
                        case 'mse'
                            bias = sum(W'*Y)/sum(W);
                        case 'logit'
                            gidx = grp2idx(Y,classSummary.NonzeroProbClasses);
                            if any(gidx==2)
                                gidx(gidx==1) = -1;
                                gidx(gidx==2) = +1;
                            end
                            bias = sum(W'*gidx)/sum(W);
                        case 'hinge'
                            bias = 0;
                        case 'epsiloninsensitive'
                            bias = classreg.learning.linearutils.fitbias(...
                                'epsiloninsensitive',Y,zeros(numel(Y),1,'like',Y),W,0);
                    end
                else
                    bias = 0;
                end
                
                this.InitialBias = repmat(bias,1,L);
            else
                if numel(this.InitialBias)~=1 && numel(this.InitialBias)~=L
                    error(message('stats:classreg:learning:modelparams:LinearParams:fillDefaultParams:BadBias',L));
                end
                
                this.InitialBias = this.InitialBias(:)';
            end
            
            if isempty(this.BatchIndex)
                if dosgd
                    this.BatchIndex = zeros(1,L);
                end
            else
                if numel(this.BatchIndex)~=L
                    error(message('stats:classreg:learning:modelparams:LinearParams:fillDefaultParams:BadBatchIndex',L));
                end
                
                this.BatchIndex = this.BatchIndex(:)';
                if dosgd && isempty(this.OptimizeLearnRate)
                    this.OptimizeLearnRate = false;
                end
            end

            if isempty(this.BetaTolerance)
                this.BetaTolerance = 1e-4;
            end
            
            if isempty(this.Epsilon)
                if ~doclass && strcmp(this.Learner,'svm')
                    this.Epsilon = iqr(Y)/13.49;
                    if this.Epsilon==0
                        this.Epsilon = 0.1;
                    end
                end
            end
            
            if isempty(this.GradientTolerance)
                if (dosgd || dodual) && ~dononsgd
                    this.GradientTolerance = 0;
                else
                    this.GradientTolerance = 1e-6;
                end
            else
                if this.GradientTolerance>0 && (dosgd || dodual)
                    warning(message('stats:classreg:learning:modelparams:LinearParams:fillDefaultParams:DoNotUseGradTolForSGD'));
                end
            end
            
            if isempty(this.IterationLimit)
                if ~(dosgd || dodual)
                    this.IterationLimit = 1000;
                end
            end

            if isempty(this.OptimizeLearnRate)
                if dosgd
                    this.OptimizeLearnRate = true;
                end
            end
            
            if isempty(this.TruncationPeriod)
                if dosgd && ~doridge
                    this.TruncationPeriod = 10;
                end
            else
                if dosgd && ~doridge && this.TruncationPeriod*this.BatchSize>N
                    error(message('stats:classreg:learning:modelparams:LinearParams:fillDefaultParams:TruncationPeriodTooLarge',...
                        floor(N/this.BatchSize)));
                end
            end
            
            if isempty(this.HessianHistorySize)
                if ismember('lbfgs',this.Solver)
                    this.HessianHistorySize = 15;
                end
            end
            
            if isempty(this.LineSearch)
                if any(ismember({'bfgs' 'lbfgs'},this.Solver))
                    this.LineSearch = 'weakwolfe';
                end
            end
                
            [this.ValidationX,this.ValidationY,this.ValidationW] ...
                = extractXyw(this.ValidationX,X,...
                dataSummary.ObservationsWereInRows,classSummary);
        end
    end
    
end


function [X,y,w] = extractXyw(cdata,trainX,obsInRows,classSummary)

X = [];
y = [];
w = [];

if isempty(cdata)
    return;
end

X = cdata{1};
y = cdata{2};

if ~ismatrix(X)
    error(message('stats:classreg:learning:FullClassificationRegressionModel:prepareDataCR:BadXType'));
end
internal.stats.checkSupportedNumeric('ValidationX',X,false,true);

% Training data have been converted to have observations in columns
D = size(trainX,1);

if obsInRows
    X = X';
end
[valD,valN] = size(X);

if valD~=D || ~strcmp(class(X),class(trainX))
    error(message('stats:classreg:learning:modelparams:LinearParams:extractXyw:BadValidationX',D));
end

doclass = ~isempty(classSummary);

if doclass
    yl = classreg.learning.internal.ClassLabel(y);
else
    internal.stats.checkSupportedNumeric('ValidationY',y);
    y = y(:);
end

if (doclass && valN~=numel(yl)) || (~doclass && valN~=numel(y))
    error(message('stats:classreg:learning:modelparams:LinearParams:extractXyw:BadValidationY',valN));
end

if numel(cdata)>2
    w = cdata{3};
    internal.stats.checkSupportedNumeric('ValidationW',w);
    w = w(:);
    if valN~=numel(w)
        error(message('stats:classreg:learning:modelparams:LinearParams:extractXyw:BadValidationW',valN));
    end
else
    w = ones(valN,1);
end

if doclass
    ismiss = ismissing(yl);
else
    ismiss = isnan(y);
end

t = ismiss' | any(isnan(X),1) | isnan(w)' | w'<=0;
if any(t)
    X(:,t) = [];
    y(t,:) = [];
    w(t)   = [];

    if doclass
        yl(t) = [];
    end
end
if isempty(X)
    error(message('stats:classreg:learning:modelparams:LinearParams:extractXyw:NoValidationDataAfterNaNRemoval'));
end

if doclass
    tf = ismember(yl,classSummary.ClassNames);
    if ~all(tf)
        idx = find(~tf,1,'first');
        str = char(yl(idx));
        cls = class(y);
        error(message('stats:classreg:learning:internal:classCount:UnknownClass', str, cls));
    end

    C = classreg.learning.internal.classCount(classSummary.NonzeroProbClasses,yl);
    
    t = ~any(C,2);
    
    if all(t)
        error(message('stats:classreg:learning:modelparams:LinearParams:extractXyw:NoValidationDataAfterZeroProbabilityRemoval'));
    end
    
    if any(t)
        X(:,t) = [];
        y(t,:) = [];
        w(t)   = [];        
    end
    
    WC = bsxfun(@times,C,w);
    Wj = sum(WC,1);    
    good = Wj>0;
    w = sum(bsxfun(@times,WC(:,good),classSummary.Prior(good)./Wj(good)),2);
    
else
    w = w/sum(w);
end

end
