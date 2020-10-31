classdef Solver < classreg.learning.internal.DisallowVectorOps
    
%   Copyright 2015-2016 The MathWorks, Inc.    
    
    properties(Constant,Hidden)        
        SolverLBFGS          = 'lbfgs';
        SolverSGD            = 'sgd';
        SolverMiniBatchLBFGS = 'minibatch-lbfgs';
        BuiltInSolvers       = {classreg.learning.fsutils.Solver.SolverLBFGS,...
                                classreg.learning.fsutils.Solver.SolverSGD,...
                                classreg.learning.fsutils.Solver.SolverMiniBatchLBFGS};
        
        LineSearchMethodBacktracking = 'backtracking';
        LineSearchMethodWeakWolfe    = 'weakwolfe';
        LineSearchMethodStrongWolfe  = 'strongwolfe';
        BuiltInLineSearchMethods     = {classreg.learning.fsutils.Solver.LineSearchMethodBacktracking,...
                                        classreg.learning.fsutils.Solver.LineSearchMethodWeakWolfe,...
                                        classreg.learning.fsutils.Solver.LineSearchMethodStrongWolfe};        
    end
    
    properties(Constant,Hidden)
        StringAuto = 'auto';
    end
    
    properties        
        NumComponents;                % We can minimize fun(x) = (1/N) * sum_{i=1}^N fun_i(x) where N is NumComponents.        
        SolverName;                   % A string specifying the solver name.
        
        % Additional options for 'SolverName' equal to 'lbfgs' and 'minibatch-lbfgs'
        HessianHistorySize;           % A positive integer specifying the Hessian history size for solver 'lbfgs'.
        InitialStepSize;              % A positive real scalar specifying the initial step size for solver 'lbfgs'.
        LineSearchMethod;             % A string specifying the line search method for solver 'lbfgs'.
        MaxLineSearchIterations;      % A positive integer specifying the maximum number of line search iterations for solver 'lbfgs'.
        GradientTolerance;            % A positive real scalar specifying the relative convergence tolerance on the gradient norm for solver 'lbfgs'.
        
        % Additional options for 'SolverName' equal to 'sgd' and 'minibatch-lbfgs'
        InitialLearningRate;          % A positive real scalar specifying the initial learning rate for solver 'sgd'.
        MiniBatchSize;                % A positive integer between 1 and N specifying the minibatch size for solver 'sgd'.
        PassLimit;                    % A positive integer specifying the maximum number of passes for solver 'sgd'.
        NumPrint;                     % A positive integer specifying the frequency with which to display convergence summary on screen for solver 'sgd' when 'Verbose' is > 0.
        NumTuningIterations;          % A positive integer specifying the number of tuning iterations for solver 'sgd'.
        TuningSubsetSize;             % A positive integer between 1 and N specifying the size of a subset of observations to use to tune the initial learning rate.
        
        % Additional options for 'SolverName' equal to 'sgd' or 'lbfgs' or 'minibatch-lbfgs'
        Verbose;                      % Verbosity level: 0, 1 or > 1.
        IterationLimit;               % A positive integer specifying the maximum number of iterations.
        StepTolerance;                % A positive real scalar specifying convergence tolerance on the step size.                
        HaveGradient;                 % True if gradient information is available. See doMinimization below for more info.        
        
        % Additional options for 'SolverName' equal to 'minibatch-lbfgs'
        MiniBatchLBFGSIterations;     % A positive integer specifying the maximum number of iterations per minibatch LBFGS step.
        
        % Additional options related to tuning of learning rate.
        InitialLearningRateForTuning; % Tentative learning rate to start tuning.
        ModificationFactorForTuning;  % Learning rate modification factor for tuning.
    end
    
    methods
        function this = Solver(N)
%Solver - Create a solver object.
%   OBJ = Solver(N) takes an integer N and creates a solver object OBJ for
%   solving the following optimization problem:
%
%       min w.r.t x: fun(x)
%
%   where fun(x) = (1/N) * sum_{i=1}^N fun_i(x). Notice that fun can be
%   written as the average of N component functions fun_i. The requirement
%   that fun be expressible in this form is necessary for using SGD and
%   minibatch-LBFGS solvers.

            this = fillDefaultSolverOptions(this,N);
        end
        
        function results = doMinimization(this,fun,x0,N,varargin)
%doMinimization - Minimize objective function fun.
%   results = doMinimization(solver,fun,x0,N) takes an object solver of
%   type Solver and solves the minimization problem:
%
%             min w.r.t x: fun(x)
%
%   starting from the initial point x0. The algorithm used depends on the
%   value of solver.SolverName.
%
%   POSITIONAL PARAMETERS:
%     
%       fun                 fun is a function handle to the function to be 
%                           minimized. 
%
%                           o For solver LBFGS, fun should be callable like
%                           fun(x0). fun accepts a real vector like x0 and
%                           returns a real scalar. If solver.HaveGradient
%                           is true then it is assumed that fun can return
%                           gradient info like this:
%
%                                   [f,gradf] = fun(x)
%
%                           where gradf is the gradient of fun at x.
%
%                           o For solver SGD and minibatch-LBFGS, fun(x) is
%                           assumed to be the average of N component
%                           functions fun_i(x) like this:
%
%                           fun(x) = (1/N) * sum_{i=1}^N fun_i(x)
%
%                           fun should be callable like fun(x) (as before)
%                           and also like fun(x,S) where S is a subset of
%                           {1,2,...,N} such that:
%
%                           fun(x,S) = (1/|S|) * sum_{i \in S} fun_i(x)
%
%                           fun(x,S) is the average of |S| component
%                           functions fun_i. If solver.HaveGradient is
%                           true, fun should be callable like [f,gradf] =
%                           fun(x) (as before) and also like this:
%
%                                   [f,gradf] = fun(x,S)
%
%                           where fun(x,S) is described above. In this
%                           case, gradf should be the gradient of fun(x,S).
%
%       x0                  Initial point to begin iterations as a real 
%                           column vector.
%
%       N                   A positive integer specifying the number of 
%                           components fun_i(x) used to compute fun(x).
%                           This value should equal solver.NumComponents.
%
%   [...] = doMinimization(solver,fun,x0,N,'Name1','Value1',...) specifies
%   one or more of the following name/value pairs:
%
%       'OutputFcn'         A function handle to an output function that is 
%                           called at each iteration. If 'OutputFcn' is
%                           equal to @outfun then outfun looks like this:
%
%           function stop = outfun(x,optimValues,state)
%               <statements>
%           end
%                           o The inputs to outfun are x, the current
%                           estimate of solution, a structure optimValues
%                           and a string state. optimValues contains the
%                           following fields:
%
%                           iteration - current iteration index.
%                           fval      - current function value.
%                           gradient  - current gradient.
%                           stepsize  - current stepsize.
%
%                           o For SGD and minibatch-LBFGS solvers, fval and
%                           gradient are the minibatch values.
%
%                           o The state string is either 'init', 'iter' or
%                           'done'. When outfun is called for the first
%                           time, state is 'init', thereafter state is
%                           equal to 'iter' until convergence. Once
%                           converged, outfun is called one more time with
%                           state = 'done'. The output stop is either true
%                           or false. If stop is true, iterations are
%                           terminated before convergence. Default is []
%                           meaning no output function.
%   OUTPUTS:
%
%       results             A structure containing optimization results. 
%                           The fields in results depend on the type of the
%                           solver used.
%
%                           Solver name              Fields in results
%                             LBFGS                - xHat,fHat,gHat,cause
%                             SGD/minibatch-LBFGS  - xHat,cause
%
%                           o xHat is the estimated solution.
%                           o fHat is the final objective value.
%                           o gHat is the final gradient.
%                           o cause is the termination code.
%
%                           The termination codes are as follows:
%
%                           Cause    Solver Name    Message
%                             0      LBFGS          Local minimum found.
%                             1      All            Local minimum possible.
%                             2      All            Iteration limit or pass limit reached.
%                             3      LBFGS          Line search failed.
%                             4      All            Terminated because of output function.
%
%                           o For LBFGS, cause = 0 means the gradient norm
%                           of the function was small.
%
%                           o For all solvers, cause = 1 means the step
%                           size most recently taken was small.
%
%                           o For all solvers, cause = 2 means iteration or
%                           pass limit was reached.
%
%                           o For LBFGS, cause = 3 means that line search
%                           failed. This indicates that either: 
%                               * the value of InitialStepSize is not set 
%                                 correctly. 
%                               * the value of MaxLineSearchIterations is 
%                                 too small.
%
%                           o For all solvers, cause = 4 means iterations
%                           were terminated before convergence because of
%                           output function.

            % 1. Default values of other optional inputs.
            dfltOutputFcn = [];

            % 2. Process optional name/value pairs.
            names  = {  'OutputFcn'};
            dflts  = {dfltOutputFcn};
            outfun = internal.stats.parseArgs(names,dflts,varargin{:});
            
            % 3. Input validation.
            if ( ~isempty(outfun) )
                assert(isa(outfun,'function_handle'));
            end
            assert(N == this.NumComponents);
            
            % 4. Call the appropriate solver.
            switch lower(this.SolverName)
                case lower(this.SolverLBFGS)
                    results = doMinimizationLBFGS(this,fun,x0,outfun);
                case {lower(this.SolverSGD),lower(this.SolverMiniBatchLBFGS)}
                    results = doMinimizationSGD(this,fun,x0,outfun);
            end
        end        
    end
    
    methods(Hidden)
        function this = fillDefaultSolverOptions(this,N)
            % 1.1 Default solver.
            if ( N > 1000 )
                dfltSolverName = this.SolverSGD;
            else
                dfltSolverName = this.SolverLBFGS;
            end
            
            % 1.2 Defaults for LBFGS.
            dfltHessianHistorySize      = 15;
            dfltInitialStepSize         = this.StringAuto;
            dfltLineSearchMethod        = this.LineSearchMethodWeakWolfe;
            dfltMaxLineSearchIterations = 20;
            dfltGradientTolerance       = 1e-6;
            
            % 1.3 Defaults for SGD.
            dfltInitialLearningRate = this.StringAuto;
            dfltMiniBatchSize       = min(10,N);
            dfltPassLimit           = 5;
            dfltNumPrint            = 10;
            dfltNumTuningIterations = 20;
            dfltTuningSubsetSize    = min(100,N);
            
            % 1.4 Defaults common to LBFGS and SGD.
            dfltIterationLimit = 1000;
            dfltStepTolerance = 1e-6;
            
            % 1.5 Defaults for minibatch LBFGS.
            dfltMiniBatchLBFGSIterations = 10;
            
            % 1.6 Default verbosity level.
            dfltVerbose = 0;
            
            % 1.7 Gradient available or not?
            dfltHaveGradient = false;
            
            % 1.8 Defaults for tuning of learning rate.
            dfltInitialLearningRateForTuning = 0.1;
            dfltModificationFactorForTuning  = 2;
            
            % 1.9 Save default solver options in the object.
            this.NumComponents                = N;
            this.SolverName                   = dfltSolverName;
            this.HessianHistorySize           = dfltHessianHistorySize;
            this.InitialStepSize              = dfltInitialStepSize;
            this.LineSearchMethod             = dfltLineSearchMethod;
            this.MaxLineSearchIterations      = dfltMaxLineSearchIterations;
            this.GradientTolerance            = dfltGradientTolerance;
            this.InitialLearningRate          = dfltInitialLearningRate;
            this.MiniBatchSize                = dfltMiniBatchSize;
            this.PassLimit                    = dfltPassLimit;
            this.NumPrint                     = dfltNumPrint;
            this.NumTuningIterations          = dfltNumTuningIterations;
            this.TuningSubsetSize             = dfltTuningSubsetSize;
            this.IterationLimit               = dfltIterationLimit;
            this.StepTolerance                = dfltStepTolerance;
            this.MiniBatchLBFGSIterations     = dfltMiniBatchLBFGSIterations;
            this.Verbose                      = dfltVerbose;
            this.HaveGradient                 = dfltHaveGradient;
            this.InitialLearningRateForTuning = dfltInitialLearningRateForTuning;
            this.ModificationFactorForTuning  = dfltModificationFactorForTuning;
            
            % 1.10 Conver auto strings to [].
            if ( strcmpi(this.InitialStepSize,this.StringAuto) )
                this.InitialStepSize = [];
            end
            
            if ( strcmpi(this.InitialLearningRate,this.StringAuto) )
                this.InitialLearningRate = [];
            end
        end

        function opts = getLBFGSOptions(this)
            opts         = struct();
            opts.TolFun  = this.GradientTolerance;
            opts.TolX    = this.StepTolerance;
            opts.MaxIter = this.IterationLimit;
            
            if this.HaveGradient
                opts.GradObj = 'on';
            else
                opts.GradObj = 'off';
            end
            
            if ( this.Verbose > 0 )
                opts.Display = 'iter';
            else
                opts.Display = 'off';
            end
        end
        
        function step = initialStepForLBFGS(this,x0)
            step = this.InitialStepSize;
            if ( isempty(step) )
                step = norm(x0,Inf)*0.5 + 0.1;
            end
        end
        
        function results = doMinimizationLBFGS(this,fun,x0,outfun)            
            % 1. Get initial step size.
            step   = initialStepForLBFGS(this,x0);            
            
            % 2. Algorithm options for LBFGS.
            memory            = this.HessianHistorySize;
            linesearch        = this.LineSearchMethod;
            maxlinesearchiter = this.MaxLineSearchIterations;            
            
            % 3. Options structure for LBFGS.
            opts = getLBFGSOptions(this);            
                       
            % 4. Call LBFGS.            
            if ( this.Verbose > 0 )
                fprintf('\n o Solver = LBFGS, HessianHistorySize = %d, LineSearchMethod = %s\n',memory,linesearch);
            end
            
            [xHat,fHat,gHat,cause] = classreg.learning.fsutils.fminlbfgs(fun,x0,'Memory',memory,'Step',step,...
                                'LineSearch',linesearch,'MaxLineSearchIter',maxlinesearchiter,...
                                'Options',opts,'OutputFcn',outfun);
            
            % 5. If cause is not 0 or 1, show a non convergence warning.
            if ( cause ~= 0 && cause ~= 1 )
                warning(message('stats:classreg:learning:fsutils:Solver:LBFGSUnableToConverge'));
            end
            
            % 6. Set results.
            results       = struct();
            results.xHat  = xHat;
            results.fHat  = fHat;
            results.gHat  = gHat;
            results.cause = cause;
        end
        
        function opts = getSGDOptions(this)
            opts         = struct();
            opts.TolX    = this.StepTolerance;
            opts.MaxIter = this.IterationLimit;
            
            if this.HaveGradient
                opts.GradObj = 'on';
            else
                opts.GradObj = 'off';
            end
            
            if ( this.Verbose > 0 )
                opts.Display = 'iter';
            else
                opts.Display = 'off';
            end            
        end
        
        function results = doMinimizationSGD(this,fun,x0,outfun)            
            % 1. Algorithm options for SGD.
            miniBatchSize = this.MiniBatchSize;
            passLimit     = this.PassLimit;
            numPrint      = this.NumPrint;            
            
            % 2. Options structure for SGD.
            opts = getSGDOptions(this);
                     
            % 3. Get initial learning rate and tune it if needed.
            N                   = this.NumComponents;
            initialLearningRate = this.InitialLearningRate;
            
            if ( isempty(initialLearningRate) )                
                numTuningIterations          = this.NumTuningIterations;
                tuningSubsetSize             = this.TuningSubsetSize;
                verbose                      = this.Verbose > 0;
                passLimitForTuning           = 1;
                initialLearningRateForTuning = this.InitialLearningRateForTuning;
                modificationFactorForTuning  = this.ModificationFactorForTuning;
                initialLearningRate = classreg.learning.fsutils.Solver.tuneInitialLearningRate(fun,x0,N,miniBatchSize,passLimitForTuning,numPrint,opts,numTuningIterations,tuningSubsetSize,verbose,...
                                                                                               initialLearningRateForTuning,modificationFactorForTuning);
            end
            
            % 4. Set up a learning rate decay schedule.
                % 4.1 How many iterations to make 1 pass?                
                iterPerPass = ceil(N/miniBatchSize);
                
                % 4.2 Keep learning rate constant for each pass.
                learnFcn = @(k) initialLearningRate/(floor(k/iterPerPass)+1);                       
            
            % 5. Are we using minibatch LBFGS?
            if ( strcmpi(this.SolverName,this.SolverMiniBatchLBFGS) )
                usingMiniBatchLBFGS = true;
            else
                usingMiniBatchLBFGS = false;
            end
            
            % 6. Set the update function to be passed on to fminsgd if we
            % are doing minibatch LBFGS.
            if usingMiniBatchLBFGS
                step              = initialStepForLBFGS(this,x0);
                memory            = this.HessianHistorySize;
                linesearch        = this.LineSearchMethod;
                maxlinesearchiter = this.MaxLineSearchIterations;                
                optsLBFGS         = getLBFGSOptions(this);
                if ( this.Verbose > 1 )
                    optsLBFGS.Display = 'iter';
                else
                    optsLBFGS.Display = 'off';
                end
                optsLBFGS.MaxIter = this.MiniBatchLBFGSIterations;
                
                updatefun = @(hfcn,myx) classreg.learning.fsutils.fminlbfgs(hfcn,myx,'Memory',memory,'Step',step,...
                                'LineSearch',linesearch,'MaxLineSearchIter',maxlinesearchiter,...
                                'Options',optsLBFGS);
            else
                updatefun = [];
            end
            
            % 7. Call SGD.
            if ( this.Verbose > 0 )
                if usingMiniBatchLBFGS
                    fprintf('\n o Solver = MiniBatchLBFGS, MiniBatchSize = %d, PassLimit = %d\n',miniBatchSize,passLimit);
                else
                    fprintf('\n o Solver = SGD, MiniBatchSize = %d, PassLimit = %d\n',miniBatchSize,passLimit);
                end
            end
            
            [xHat,cause] = classreg.learning.fsutils.fminsgd(fun,x0,N,'MiniBatchSize',miniBatchSize,...
                        'MaxPasses',passLimit,'LearnFcn',learnFcn,...
                        'NumPrint',numPrint,'Options',opts,'OutputFcn',outfun,'UpdateFcn',updatefun);            
            
            % 8. Don't show convergence warning for SGD since in most cases
            % SGD stops because of iteration or pass limit.
            
            % 9. Set results.
            results       = struct();
            results.xHat  = xHat;
            results.cause = cause;
        end
    end
    
    methods(Static,Hidden)        
        function etaBest = tuneInitialLearningRate(fun,x0,N,miniBatchSize,passLimit,numPrint,opts,numTuningIterations,tuningSubsetSize,verbose,initialLearningRateForTuning,modificationFactorForTuning)
            % 1. fun uses an average of N subfunctions. Make a function
            % that uses an average of M randomly selected subfunctions
            % where M is much smaller than N.
            M             = tuningSubsetSize;
            testfunForFit = classreg.learning.fsutils.Solver.makeTestFunctionToTuneLearningRate(fun,N,M);
            testfun       = classreg.learning.fsutils.Solver.makeTestFunctionToTuneLearningRate(fun,N,M);
            
            % 2. Initialize tentative learning rates.            
            factor = modificationFactorForTuning;  % for example, 2;
            etaLo  = initialLearningRateForTuning; % for example, 0.1;
            etaHi  = factor*etaLo;
            
            % 3. Turn off SGD display for tuning runs.
            opts.Display = 'off';
            
            % 4. A function handle to run SGD with a fixed learning rate.
            sgdfun = @(myeta) classreg.learning.fsutils.fminsgd(testfunForFit,x0,M,'Options',opts,'MiniBatchSize',min(miniBatchSize,M),...
                                        'NumPrint',numPrint,'MaxPasses',passLimit,'LearnFcn',@(k) myeta);
            
            % 5. Initial SGD runs for etaLo and etaHi.            
            wLo = sgdfun(etaLo);
            fLo = testfun(wLo);
            
            wHi = sgdfun(etaHi);            
            fHi = testfun(wHi);            
            
            % 6. Best learning rate and function value so far.
            etaBest = etaLo;
            fBest   = fLo;
            
            % 7. Keep track of the best learning rate so far.
            if verbose                
                tuningMessageStr = getString(message('stats:classreg:learning:fsutils:Solver:Message_TuningLearningRate'));
                fprintf(['\n o ',tuningMessageStr,' NumTuningIterations = %d, TuningSubsetSize = %d\n'],numTuningIterations,tuningSubsetSize);
            end
            
            for i = 1:numTuningIterations
                if ( fLo < fHi )
                    etaHi = etaLo;
                    fHi   = fLo;
                    
                    if ( fLo < fBest )
                        fBest   = fLo;
                        etaBest = etaLo;
                    end
                    
                    etaLo  = etaLo/factor;
                    
                    wLo = sgdfun(etaLo);                    
                    fLo = testfun(wLo);
                else
                    etaLo = etaHi;
                    fLo   = fHi;
                    
                    if ( fHi < fBest )
                        fBest   = fHi;
                        etaBest = etaHi;
                    end
                    
                    etaHi = factor*etaHi;
                    
                    wHi = sgdfun(etaHi);                    
                    fHi = testfun(wHi);         
                end
                
                if verbose
                    if ( rem(i,20) == 1 )
                        fprintf('\n');
                        fprintf('|===============================================|\n');
                        fprintf('|    TUNING    | TUNING SUBSET |    LEARNING    |\n');
                        fprintf('|     ITER     |   FUN VALUE   |      RATE      |\n');
                        fprintf('|===============================================|\n');
                    end
                    fprintf('|%13d |%14.6e |%15.6e |\n', i, fBest, etaBest);                    
                end
            end
        end
        
        function z = makeTestFunctionToTuneLearningRate(fun,N,M)
            % 1. Get a subset of {1,2,...,N} of size M in idx. randsample
            % returns a column vector and we want idx to be a row vector -
            % so transpose the result from randsample.
            idx = randsample(N,M);
            idx = idx';
            
            % 2. Make objective function. tunefun(w) should average fun_i
            % over idx and tunefun(w,S) should average fun_i over idx(S)
            % where S is a subset of {1,2,...,M}.
            z   = @tunefun;            
            function [f,g] = tunefun(w,S)
                % S is a subset of {1,2,...,M}.
                if ( nargin < 2 )
                    [f,g] = fun(w,idx);
                else
                    [f,g] = fun(w,idx(S));
                end
            end
        end
        
        function g = getGradient(fun,theta,step)
        %getGradient - Numerical gradient using central differences.
        %   g = getGradient(fun,theta,step) gets numerical gradient of the
        %   function fun evaluated at p-by-1 vector theta. The output g
        %   will be a column vector of size p-by-1. fun is a function
        %   handle to a function that accepts a vector theta and returns a
        %   scalar. Input step is optional.
            
            % 1. Set step size.
            if ( nargin < 3 )
                step = eps^(1/3);
            end
            
            % 2. Initialize output.
            p = length(theta);
            g = zeros(p,1);
            
            for i = 1:p
                % 3. Use central differences.
                theta1    = theta;
                theta1(i) = theta1(i) - step;
                
                theta2    = theta;
                theta2(i) = theta2(i) + step;
                
                g(i)      = (fun(theta2) - fun(theta1))/2/step;
            end
            
            % 4. Prevent Inf values in g.
            g = classreg.learning.fsutils.Solver.replaceInf(g,realmax);
        end
        
        function B = replaceInf(B,value)
        %replaceInf - Replace Inf values in B.
        %   B = replaceInf(B,value) takes a matrix or vector B, a scalar
        %   value and replaces +Inf elements in B with abs(value) and -Inf
        %   elements in B with -abs(value). The resulting B is returned.
            
            % 1. Ensure that B is a numeric, matrix and value is a numeric
            % scalar.
            assert( isnumeric(B) & ismatrix(B) );
            assert( isnumeric(value) & isscalar(value) );
            
            % 2. Get abs(value).
            absvalue = abs(value);
            
            % 3. Find +Inf or -Inf in B.
            isinfB = isinf(B);
            
            % 4. Find +Inf elements in B and replace them with abs(value).
            B(isinfB & B > 0) = absvalue;
            
            % 5. Find -Inf elements in B and replace them with -abs(value).
            B(isinfB & B < 0) = -absvalue;
        end
    end    
    
end