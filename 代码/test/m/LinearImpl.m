classdef LinearImpl
    
%   Copyright 2015-2016 The MathWorks, Inc.
    
    properties(GetAccess=public,SetAccess=protected)
        BatchIndex          = [];
        BatchLimit          = [];
        BatchSize           = [];
        Beta                = [];
        Bias                = [];
        Consensus           = [];
        FitInfo             = [];
        Epsilon             = [];
        HessianHistorySize  = [];
        IterationLimit      = [];
        Lambda              = [];
        LearnRate           = [];
        LineSearch          = 'backtrack'; % default for backward compatibility
        LossFunction        = [];
        NumPredictors       = [];
        NumCheckConvergence = [];
        OptimizeLearnRate   = [];
        OptimalLearnRate    = [];
        PassLimit           = [];
        PostFitBias         = [];
        Ridge               = [];
        Solver              = [];
        Stream              = [];
        TruncationPeriod    = [];
        VerbosityLevel      = [];        
    end
   
    methods(Access=protected)
        function this = LinearImpl()
        end
    end
    
    methods
        function F = score(this,X,doclass,obsInRows)
            %doclass: true for classification, or false for regression.
            
            if ~isfloat(X) || ~ismatrix(X)
                error(message('stats:classreg:learning:impl:LinearImpl:score:BadX'));
            end
            internal.stats.checkSupportedNumeric('X',X,false,true);
            
            beta = this.Beta;
            bias = this.Bias;
            
            if obsInRows
                [N,D] = size(X);
            else
                [D,N] = size(X);
            end
            
            if isempty(beta)
                L = numel(this.Lambda);
                if doclass
                    F = NaN(N,L,'like',bias);
                else
                    F = zeros(N,L,'like',bias) + bias;
                end
                return;
            end
            
            if D~=this.NumPredictors
                if obsInRows
                    str = getString(message('stats:classreg:learning:impl:LinearImpl:score:columns'));
                else
                    str = getString(message('stats:classreg:learning:impl:LinearImpl:score:rows'));
                end
                error(message('stats:classreg:learning:impl:LinearImpl:score:BadXSize',...
                    this.NumPredictors, str));
            end
            
            if isa(X,'double') && isa(bias,'single')
                X = single(X);
            end

            if obsInRows
                F = bsxfun(@plus,X*beta,bias);
            else
                F = bsxfun(@plus,(beta'*X)',bias);
            end
        end
                
        function this = selectModels(this,idx)            
            if ~isnumeric(idx) || ~isvector(idx) || ~isreal(idx) || any(idx(:)<0) ...
                    || any(round(idx)~=idx) || any(idx(:)>numel(this.Lambda))
                error(message('stats:classreg:learning:impl:LinearImpl:selectModels:BadIdx',...
                    numel(this.Lambda)));
            end
            
            this.Lambda = this.Lambda(idx);
            this.Beta = this.Beta(:,idx);
            this.Bias = this.Bias(idx);
        end
        
        function s = toStruct(this)
            % Convert to struct suitable for codegen
            
            warnState  = warning('query','all');
            warning('off','MATLAB:structOnObject');
            cleanupObj = onCleanup(@() warning(warnState));

            s = struct(this);
            
            % Process fit info. Do not save history.
            fitinfo = s.FitInfo;
            fitinfo.History = [];

            % Do not save TerminationStatus since it can be reconstructed
            % from TerminationCode.
            fitinfo = rmfield(fitinfo,'TerminationStatus');

            s.FitInfo = fitinfo;
            
            % Random stream. If not empty, convert to struct.
            if ~isempty(s.Stream)
                s.Stream = get(s.Stream);
            end
            
            % Solver: convert from cellstr to char
            solver = s.Solver;
            if ~isrow(solver)
                solver = solver(:)';
            end            
            s.SolverNamesLength = cellfun(@length,solver);
            s.SolverNames = char(solver');
            s = rmfield(s,'Solver');
        end
    end

    methods(Static)
        function obj = fromStruct(s)
            % Make an object from a codegen struct.
            
            obj = classreg.learning.impl.LinearImpl;
            
            obj.BatchIndex          = s.BatchIndex;
            obj.BatchLimit          = s.BatchLimit;
            obj.BatchSize           = s.BatchSize;
            obj.Beta                = s.Beta;
            obj.Bias                = s.Bias;
            
            if isfield(s,'Consensus')
                obj.Consensus       = s.Consensus;
            else
                obj.Consensus       = 0;
            end
            
            fitinfo = s.FitInfo;
            fitinfo.TerminationStatus = terminationStatus(fitinfo.TerminationCode);            
            obj.FitInfo             = fitinfo;
            
            obj.Epsilon             = s.Epsilon;
            obj.HessianHistorySize  = s.HessianHistorySize;
            obj.IterationLimit      = s.IterationLimit;
            obj.Lambda              = s.Lambda;
            obj.LearnRate           = s.LearnRate;
            obj.LineSearch          = s.LineSearch;
            obj.LossFunction        = s.LossFunction;
            obj.NumPredictors       = s.NumPredictors;
            obj.NumCheckConvergence = s.NumCheckConvergence;
            obj.OptimizeLearnRate   = s.OptimizeLearnRate;
            obj.OptimalLearnRate    = s.OptimalLearnRate;
            obj.PassLimit           = s.PassLimit;
            obj.PostFitBias         = s.PostFitBias;
            obj.Ridge               = s.Ridge;
            
            obj.Solver              = cellstr(s.SolverNames)';
            obj.Solver              = arrayfun( @(x,y) x{1}(1:y), ...
                                      obj.Solver, s.SolverNamesLength, ...
                                      'UniformOutput',false );
            
            if ~isempty(s.Stream)
                obj.Stream          = RandStream(s.Stream.Type);
                set(obj.Stream,s.Stream);
            else
                obj.Stream          = [];
            end
            
            obj.TruncationPeriod    = s.TruncationPeriod;
            obj.VerbosityLevel      = s.VerbosityLevel;
        end
        
        function this = makeNoFit(param,Beta,Bias,fitinfo)
            % Create a LinearImpl object without fitting
            % Used by tall.fticlinear
            this = classreg.learning.impl.LinearImpl;

            this.HessianHistorySize = param.HessianHistorySize;
            this.IterationLimit = param.IterationLimit;
            this.Lambda = param.Lambda;
            this.LineSearch = param.LineSearch;
            this.LossFunction = param.LossFunction;
            this.PostFitBias = param.PostFitBias;
            this.Ridge = strcmp(param.Regularization,'ridge');
            this.Solver = param.Solver;
            this.VerbosityLevel = param.VerbosityLevel;
            this.Epsilon = param.Epsilon;
            
            this.Beta = Beta;
            this.Bias = Bias;
            this.FitInfo = fitinfo;
            
        end
            
        function this = make(doclass,...
                Beta0,Bias0,X,y,w,lossfun,doridge,lambda,maxpass,maxbatch,...
                nconv,batchindex,batchsize,solvers,betatol,gradtol,deltagradtol,...
                gamma,presolve,valX,valY,valW,maxiter,truncationK,...
                fitbias,postfitbias,epsilon,historysize,linesearch,rho,rsh,verbose)
            
            % doclass:
            %   0 = regression
            %   1 = one class
            %   2 = two classes
 
            this = classreg.learning.impl.LinearImpl;
            
            [D,N] = size(X);
            clsname = class(X);
            
            L = numel(lambda);            
            S = numel(solvers);
            
            this.NumPredictors = D;
            
            solvers = solvers(:)';
            dodual = ismember('dual',solvers);
            doduallast = strcmp('dual',solvers(end));
            dosgdlast = any(strcmp({'sgd' 'asgd'},solvers(end)));
            dononsgdlast = any(strcmp({'bfgs' 'lbfgs' 'sparsa'},solvers(end)));

            % Set up values to be passed into mex
            
            passed_deltagradtol = deltagradtol;
            if isempty(deltagradtol)
                deltagradtol = NaN;
            end
            
            if isempty(batchindex)
                batchindex = NaN(1,L);
            end
            
            if isempty(batchsize)
                batchsize = NaN;
            end
            
            passed_maxpass = maxpass;
            if isempty(maxpass)
                maxpass = NaN;
            end
            
            passed_maxbatch = maxbatch;
            if isempty(maxbatch)
                maxbatch = NaN;
            end
            
            passed_maxiter = maxiter;
            if isempty(maxiter)
                maxiter = NaN;
            end
            
            if isempty(gamma)
                gamma = NaN;
            end

            passed_epsilon = epsilon;
            if isempty(epsilon)
                epsilon = NaN;
            end
            
            if isempty(truncationK)
                truncationK = NaN;
            end
            
            if isempty(nconv)
                nconv = 0;
            end
            
            if isempty(presolve)
                presolve = false;
            end
            
            if isempty(historysize)
                historysize = NaN;
            end
            
            this.LossFunction           = lossfun;
            this.Ridge                  = doridge;
            this.Lambda                 = lambda;
            this.PassLimit              = maxpass;
            this.BatchLimit             = maxbatch;
            this.NumCheckConvergence    = nconv;
            this.BatchSize              = batchsize;
            this.Solver                 = solvers;
            this.LearnRate              = gamma;
            this.OptimizeLearnRate      = presolve;
            this.IterationLimit         = maxiter;
            this.TruncationPeriod       = truncationK;
            this.PostFitBias            = postfitbias;
            this.Epsilon                = passed_epsilon;
            this.HessianHistorySize     = historysize;
            this.LineSearch             = linesearch;
            this.Consensus              = rho;
            this.Stream                 = rsh;
            this.VerbosityLevel         = verbose;
            
            if doclass==1
                % If only one class, no learning takes place. Prepare and
                % return fixed values such that prediction is always into
                % this class.
                
                if     strcmp(lossfun,'logit')
                    this.Bias = Inf(1,L,clsname);
                elseif strcmp(lossfun,'hinge')
                    this.Bias = ones(1,L,clsname);
                end
                
                this.BatchIndex       = zeros(1,L);
                this.Beta             = zeros(D,L,clsname);
                this.OptimalLearnRate = repmat(gamma,1,L);
                                                
                fitInfo.Objective = zeros(1,L,clsname);
                
                if dosgdlast || doduallast
                    fitInfo.PassLimit = passed_maxpass;
                    fitInfo.NumPasses = zeros(1,L);
                    fitInfo.BatchLimit = passed_maxbatch;
                end
                
                if dosgdlast
                    fitInfo.BatchIndex       = zeros(1,L);
                    fitInfo.OptimalLearnRate = repmat(gamma,1,L);
                end
                
                if dononsgdlast
                    fitInfo.IterationLimit = passed_maxiter;
                end
                fitInfo.NumIterations = zeros(1,L);

                fitInfo.GradientNorm      = [];
                fitInfo.GradientTolerance = repmat(gradtol,1,L);
                
                fitInfo.RelativeChangeInBeta = [];
                fitInfo.BetaTolerance        = repmat(betatol,1,L);
                
                fitInfo.DeltaGradient          = [];
                fitInfo.DeltaGradientTolerance = repmat(passed_deltagradtol,1,L);
                
                fitInfo.TerminationCode   = repmat(-13,S,L);
                fitInfo.TerminationStatus = repmat(...
                    {getString(message('stats:classreg:learning:impl:LinearImpl:make:OneClass'))},...
                    S,L);

                if doduallast
                    fitInfo.Alphas = [];
                end
                
                fitInfo.History = [];
                fitInfo.FitTime = 0;
                
                this.FitInfo = fitInfo;
                
                return;
            end
            
            isXdouble = isa(X,'double');
            epsX = 100*eps(clsname);
            
            orthant = false;  % Do not use orthant method
            sloss = numel(y); % Scaling factor for loss gradient for SGD
            slambda = 1;      % Scaling factor for regularizer gradient
            
            dohist = verbose>0; % Record history?

            % Allocate various arrays
            beta = zeros(D,L,clsname);
            bias = zeros(1,L,clsname);
            optlearnrate = NaN(1,L,clsname);
            if dodual
                alphas = zeros(N,L,clsname);
            else
                alphas = zeros(0,L,clsname);
            end
            alphas0 = [];
            objective = zeros(1,L,clsname);
            grad      = zeros(1,L,clsname);
            dbeta     = zeros(1,L,clsname);
            deltagrad = zeros(1,L,clsname);
            numpass   = zeros(1,L);
            numiter   = zeros(1,L);
            status = cell(1,L);
            if dohist
                history = repmat(struct,1,L);
            else
                history = [];
            end

            % For the dual solver, go through lambdas in descending order
            if dodual
                lambda = fliplr(lambda);
            end

            % Coefficients that are allowed to take non-zero values for
            % lasso
            mask = true(D,1);
            
            % Time
            tstart = tic;
            
            for l=1:L
                domask = l>1 && ~doridge; % Fill the mask array?

                % Initial estimates for the first lambda. If l>1, these may
                % be reset.
                beta0 = Beta0(:,1);
                bias0 = Bias0(1);
                
                if l>1
                    if ~isvector(Beta0)
                        % If initial estimates are passed for each lambda, use
                        % them.
                        beta0 = Beta0(:,l);
                        bias0 = Bias0(l);
                        
                        if domask
                            mask = beta0~=0;
                        end
                    elseif any(ismember({'sgd' 'asgd'},solvers)) && ~doridge
                        % For SGD with lasso, always use the initial
                        % estimate. Using warm start from the previous
                        % lambda values often fails.
                        beta0 = Beta0;
                        bias0 = Bias0;
                        
                        % Don't allow non-zero values for coefficients that
                        % were set to zero for a smaller lambda.
                        if domask
                            mask = beta(:,l-1)~=0;
                        end
                    else
                        % If initial estimates for each lambda are not passed,
                        % use the estimate for the previous lambda.
                        beta0 = beta(:,l-1);
                        bias0 = bias(l-1);
                        
                        if domask
                            mask = beta0~=0;
                        end
                    end

                    % Warm start for the dual solver.
                    if dodual
                        alphas0 = alphas(:,l-1);
                    end
                end
                
                if verbose>0 && L>1
                    fprintf('\n%s Lambda = %13e\n',getString(...
                        message('stats:classreg:learning:impl:LinearImpl:make:Lambda')),...
                        lambda(l) );
                end
                
                % Use weak Wolfe?
                dowolfe = strcmp(linesearch,'weakwolfe');
                
                % Call mex. This is where all the fitting is done.
                % Note: rho is penalty on distance to initial beta estimate.
                [beta(:,l),bias(l),objective(l),grad(l),dbeta(l),deltagrad(l),...
                    numpass(l),numiter(l),status{l},...
                    batchindex(l),optlearnrate(l),alphas(:,l),...
                    hSolver,hPass,hIteration,hObjective,hStep,hGradient,...
                    hDeltaBeta,hNumBeta,hValidationLoss] = ...
                    classreg.learning.linearutils.solve(beta0,bias0,X,y,w,lossfun,...
                    doridge,lambda(l),gamma,maxpass,nconv,batchsize,solvers,...
                    betatol,gradtol,epsilon,presolve,epsX,rho,...
                    valX,valY,valW,batchindex(l),maxiter,...
                    sloss,slambda,isXdouble,orthant,...
                    truncationK,mask,deltagradtol,alphas0,...
                    fitbias,historysize,dowolfe,maxbatch,...
                    rsh,verbose);

                % Record history
                if dohist
                    history(l).Solver               = hSolver;
                    history(l).NumPasses            = hPass;
                    history(l).NumIterations        = hIteration;
                    history(l).Objective            = hObjective;
                    if dodual
                        history(l).DeltaGradient    = hStep;
                    else
                        history(l).Step             = hStep;
                    end
                    history(l).Gradient             = hGradient;
                    history(l).RelativeChangeInBeta = hDeltaBeta;
                    history(l).NumNonzeroBeta       = hNumBeta;
                    if ~isempty(hValidationLoss)
                        history(l).ValidationLoss   = hValidationLoss;
                    end
                end
            end

            % For the dual solver, flip lambdas and all associated arrays
            % back into ascending order
            if dodual
                lambda     = fliplr(lambda);
                alphas     = fliplr(alphas);
                batchindex = fliplr(batchindex);
                beta       = fliplr(beta);
                bias       = fliplr(bias);
                objective  = fliplr(objective);
                grad       = fliplr(grad);
                dbeta      = fliplr(dbeta);
                deltagrad  = fliplr(deltagrad);
                numpass    = fliplr(numpass);
                numiter    = fliplr(numiter);
                optlearnrate = fliplr(optlearnrate);
                status     = fliplr(status);
                history    = fliplr(history);
            end
            
            if postfitbias
                F = (beta'*X)';
                bias = classreg.learning.linearutils.fitbias(lossfun,y,F,w,epsilon);
            end
            
            % Time
            telapsed = toc(tstart);
                                    
            this.BatchIndex       = batchindex;
            this.Beta             = beta;
            this.Bias             = bias;
            this.OptimalLearnRate = optlearnrate;
            
            % Fill out fit info
            fitInfo.Lambda    = lambda;
            fitInfo.Objective = objective;
            
            if dosgdlast || doduallast
                fitInfo.PassLimit = passed_maxpass;
                fitInfo.NumPasses = 1+numpass;
                fitInfo.BatchLimit = passed_maxbatch;
            end
            
            if dononsgdlast
                fitInfo.IterationLimit = passed_maxiter;
            end
            fitInfo.NumIterations = numiter;
                
            fitInfo.GradientNorm      = grad;
            fitInfo.GradientTolerance = gradtol;
            
            fitInfo.RelativeChangeInBeta = dbeta;
            fitInfo.BetaTolerance        = betatol;

            if isempty(passed_deltagradtol)
                fitInfo.DeltaGradient = [];
            else
                fitInfo.DeltaGradient = deltagrad;
            end
            fitInfo.DeltaGradientTolerance = passed_deltagradtol;                        
            
            fitInfo.TerminationCode   = cell2mat(status);
            fitInfo.TerminationStatus = terminationStatus(fitInfo.TerminationCode);
            
            if dosgdlast
                fitInfo.BatchIndex       = batchindex;
                fitInfo.OptimalLearnRate = optlearnrate;
            end
            
            if doduallast
                fitInfo.Alpha = alphas;
            end
            
            fitInfo.History = history;
            fitInfo.FitTime = telapsed;
            
            this.FitInfo = fitInfo;
        end
    end
    
end


function status = terminationStatus(termCode)

[S,L] = size(termCode);
status = cell(S,L);

for l=1:L
    for s=1:S
        switch termCode(s,l)
            case -11
                str = getString(message('stats:classreg:learning:impl:LinearImpl:make:ObjectiveDoesNotDecrease'));
            case -10
                str = getString(message('stats:classreg:learning:impl:LinearImpl:make:SmallLearnRate'));
            case -3
                str = getString(message('stats:classreg:learning:impl:LinearImpl:make:NaNorInfObjective'));
            case -2
                str = getString(message('stats:classreg:learning:impl:LinearImpl:make:AllPreviousCoeffsZero'));
            case -1
                str = getString(message('stats:classreg:learning:impl:LinearImpl:make:AllCoeffsRemainZero',10));
            case 0
                str = getString(message('stats:classreg:learning:impl:LinearImpl:make:MaxIterReached'));
            case 1
                str = getString(message('stats:classreg:learning:impl:LinearImpl:make:BetaToleranceMet'));
            case 2
                str = getString(message('stats:classreg:learning:impl:LinearImpl:make:GradientToleranceMet'));
            case 3
                str = getString(message('stats:classreg:learning:impl:LinearImpl:make:ValidationLossIncreases',5));
            case 4
                str = getString(message('stats:classreg:learning:impl:LinearImpl:make:DeltaGradientToleranceMet'));
            otherwise
                error(message('stats:classreg:learning:impl:LinearImpl:make:BadStatus'));
        end
        
        status{s,l} = str;
    end
end
end
