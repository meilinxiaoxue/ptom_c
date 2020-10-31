function [theta,funtheta,gradfuntheta,cause] = fminlbfgs(fun,theta0,varargin)
%FMINLBFGS Utility to solve unconstrained minimization problems.
%   [theta,funtheta,gradfuntheta,cause] = FMINLBFGS(fun,theta0) solves the
%   minimization problem:
%
%             min w.r.t theta: fun(theta)
%
%   starting from the initial point theta0. A limited memory BFGS (LBFGS)
%   method with line searches is used. LBFGS is a quasi-Newton method well
%   suited to solving problems where theta is high dimensional.
%
%   POSITIONAL PARAMETERS:
%     
%       fun                 A function handle to the function to be 
%                           minimized that can be called like fun(theta0).
%                           fun accepts a real vector like theta0 and
%                           returns a real scalar.
%
%       theta0              Initial point to begin iterations as a real 
%                           column vector.
%
%   Gradient of fun can be optionally computed using finite differences.
%   See the 'GradObj' field in the 'Options' name/value pair below. The
%   function fun is assumed to be smooth almost everywhere.
%
%   [...] = FMINLBFGS(fun,theta0,'Name1','Value1',...) specifies one or
%   more of the following name/value pairs:
%
%       'Gamma'             A real positive scalar specifying the initial 
%                           LBFGS inverse Hessian approximation as the
%                           value of 'Gamma' times the identity matrix.
%                           Default is 1.
%
%       'Memory'            A positive integer specifying the memory size 
%                           for LBFGS. Typical values of 'Memory' are
%                           between 3 and 20. Default is 10.
%
%       'Step'              A real positive scalar specifying the norm of 
%                           first step for LBFGS. If 'Step' is supplied
%                           then 'Gamma' is calculated based on 'Step' and
%                           the value supplied for 'Gamma' is ignored.
%                           Default is [] indicating that the value in
%                           'Gamma' is used.
%
%       'LineSearch'        A string indicating the line search method for 
%                           LBFGS - either 'WeakWolfe', 'StrongWolfe' or
%                           'Backtracking'. 'WeakWolfe' and 'StrongWolfe'
%                           maintain a positive definite approximation to
%                           the inverse Hessian in LBFGS - 'Backtracking' 
%                           does not. For non-smooth problems, 'WeakWolfe'
%                           may be better compared to 'StrongWolfe'. For
%                           smooth problems, 'StrongWolfe' can converge
%                           faster than 'WeakWolfe'. Default is 'WeakWolfe'.
%
%       'MaxLineSearchIter' 
%                           A positive integer specifying the maximum
%                           number of line search iterations. If the
%                           problem is badly scaled, a larger value of
%                           'MaxLineSearchIter' may be required. 
%                           Default is 20.
%
%       'Options'           A structure containing optimization options 
%                           with the following fields:
% 
%               'TolFun' -      Relative tolerance on the gradient of the 
%                               objective function. Default is 1e-6.
%                               Suppose f and gradf are the values of fun
%                               and gradient of fun evaluated at the
%                               current iterate. Also let gradf0 be the
%                               gradient of fun evaluated at the initial
%                               point theta0. Iterations stop if:
%
%                                   max(abs(gradf)) <= fac*TolFun 
%                                   fac = max(1,min(abs(f),max(abs(gradf0))))
%                               
%               'TolX'   -      Absolute tolerance on the step size. Default
%                               is 1e-6. If s is the current step then
%                               iterations stop if:
%
%                                   norm(s) <= TolX
%  
%               'MaxIter' -     Maximum number of iterations allowed. 
%                               Default is 10000.
%  
%               'Display' -     Level of display:  'off', 'iter', or 'final'.
%                               Default is 'off'. Both 'iter' and 'final'
%                               have the same effect.
%
%               'GradObj' -     Either 'on' or 'off'. Default is 'off'. 
%                               If 'on', it is assumed that fun can return
%                               gradient information like this:
%
%                                   [f,gradf] = fun(theta)
%
%       'OutputFcn'         A function handle to an output function that is 
%                           called at each iteration. If 'OutputFcn' is
%                           equal to @outfun then outfun looks like this:
%
%           function stop = outfun(x,optimValues,state)
%               <statements>
%           end
%                           The inputs to outfun are x, the current
%                           estimate of solution, a structure optimValues
%                           and a string state. optimValues contains the
%                           following fields:
%
%                           iteration - current iteration index.
%                           fval      - current function value.
%                           gradient  - current gradient.
%                           stepsize  - current stepsize.
%
%                           The state string is either 'init', 'iter' or
%                           'done'. When outfun is called for the first
%                           time, state is 'init', thereafter state is
%                           equal to 'iter' until convergence. Once
%                           converged, outfun is called one more time with
%                           state = 'done'. The output stop is either true
%                           or false. If stop is true, iterations are
%                           terminated before convergence. Default is []
%                           meaning no output function.
%
%   OUTPUTS:
%
%       theta               A column vector containing the estimated 
%                           solution to the problem.
%
%       funtheta            Function value at the optimal theta.
%
%       gradfuntheta        Gradient of the function at optimal theta.
%
%       cause               An integer code indicating the reason for 
%                           termination of iterations. Possible values are
%                           as follows:
%                 
%                           * cause = 0 means that the maximum absolute
%                           gradient of the function was less than TolFun
%                           in a relative error sense (see above for more
%                           details). The interpretation is: "Local minimum
%                           found".
%
%                           * cause = 1 means that the step size most
%                           recently taken was less than TolX in an
%                           absolute error sense. The interpretation is
%                           "Local minimum possible".
%
%                           * cause = 2 means 'Iteration limit reached'.
%
%                           * cause = 3 means 'Line search failed'. This
%                           indicates that either the problem is badly
%                           scaled or that the value of 'Gamma' is not
%                           suitable. Try changing 'Gamma' or specify
%                           'Gamma' indirectly using 'Step'. A heuristic
%                           that often works well is to set 'Step' to be
%                           equal to r1*norm(theta0)+r2 where 0 < r1 < 1
%                           and 0 < r2 < 1.
%
%                           * cause = 4 means iterations were terminated 
%                           before convergence because of OutputFcn. Exit 
%                           message is 'Terminated because of OutputFcn.'.
%
%   NOTES:
%
%       (1) What if we want to maximize instead of minimize? 
%       We normally minimize fun(theta). To maximize fun(theta), create a
%       new function h(theta) = -fun(theta) and then minimize h(theta).
%
%       (2) How to account for bound constraints on theta?
%       Suppose theta is a vector that satisfies a <= theta <= b where a
%       and b are the lower and upper bound vectors for elements of theta.
%       We can eliminate the bounds via the transformation:
%
%           theta = a + (b - a)./(1 + exp(-phi))
%
%       Our objective function is now parameterized by phi and can be
%       written as:
%
%           h(phi) = fun(theta) = fun( a + (b - a)./(1 + exp(-phi)) )
%
%       For any phi, we have a <= theta <= b. So minimizing h(phi) w.r.t
%       phi is the same as minimizing fun(theta) while respecting the bound
%       constraints.
%
%       (3) It is the responsibility of the caller to ensure that fun does
%       not return NaN/Inf values.
%
%   Examples:
%       % Badly scaled objective function.
%       opts = struct('Display','iter','TolX',1e-12);
%       myfun = @(x) 1e-6*(x(1) - 1)*(x(1) - 1) + 1e9*((x(2) - 1)*(x(2) - 1));
%
%       % Weak Wolfe line search with a maximum of 20 line search iterations.
%       [x,f] = fminlbfgs(myfun,[5;5],'options',opts,'line','weak','gamma',1,'maxline',20)
%    
%       % The exit message says that line search failed. What went wrong? LBFGS
%       % gathers second order information in the first few iterations and it can
%       % be sensitive to the starting search direction. If the value of 'gamma'
%       % is set incorrectly, it can require many line search iterations before
%       % moving to the next point. There are several ways to proceed:
%       % 1. Increase the maximum number of line search iterations using 'MaxLineSearchIter'.
%       % 2. Decrease the value of 'Gamma'.
%       % 3. Specify 'Gamma' indirectly using 'Step'.
%       % 4. Use a strong Wolfe line search using 'LineSearch'.
%       % Each of the above methods is illustrated below.
%
%       % 1. Weak Wolfe line search with a maximum of 50 line search iterations.
%       [x,f] = fminlbfgs(myfun,[5;5],'options',opts,'line','weak','gamma',1,'maxline',50)
%    
%       % 2. Weak Wolfe line search with a smaller value of 'gamma'.
%       [x,f] = fminlbfgs(myfun,[5;5],'options',opts,'line','weak','gamma',1e-6,'maxline',20)
%    
%       % 3. Weak Wolfe line search with a 'step' value of 0.1 instead of 'gamma'.
%       [x,f] = fminlbfgs(myfun,[5;5],'options',opts,'line','weak','step',0.1,'maxline',20)
%    
%       % 4. Strong Wolfe line search with a maximum of 20 line search iterations.
%       [x,f] = fminlbfgs(myfun,[5;5],'options',opts,'line','strong','gamma',1,'maxline',20)

%       Copyright 2015-2016 The MathWorks, Inc.

    %% Handle input args.        
    
        % 1. Check number of input arguments.
        narginchk(2,Inf);
    
        % 2. Extract optimization options.       
            % 2.1 An 'Options' structure with default values for TolFun,
            % TolX, Display, MaxIter and GradObj.
            dfltTolFun  = 1e-6;
            dfltTolX    = 1e-6;
            dfltDisplay = 'off';
            dfltMaxIter = 10000;
            dfltGradObj = 'off';
            dfltoptions = statset('TolFun' ,dfltTolFun ,...
                                  'TolX'   ,dfltTolX   ,...
                                  'Display',dfltDisplay,...
                                  'MaxIter',dfltMaxIter,...
                                  'GradObj',dfltGradObj);            
                        
            % 2.2 Default values of other optional inputs.
            dfltGamma             = 1;
            dfltMemory            = 10;
            dfltStep              = [];
                        
            weakWolfe             = classreg.learning.fsutils.Solver.LineSearchMethodWeakWolfe;    % 'WeakWolfe';
            strongWolfe           = classreg.learning.fsutils.Solver.LineSearchMethodStrongWolfe;  % 'StrongWolfe';
            backtracking          = classreg.learning.fsutils.Solver.LineSearchMethodBacktracking; % 'Backtracking';
            dfltLineSearch        = weakWolfe;
            
            dfltMaxLineSearchIter = 20;
            
            dfltOutputFcn         = [];
            
            % 2.3 Process optional name/value pairs.
            names = {  'Options',   'Gamma',   'Memory',   'Step',   'LineSearch',  'MaxLineSearchIter',    'OutputFcn'};
            dflts = {dfltoptions, dfltGamma, dfltMemory, dfltStep, dfltLineSearch, dfltMaxLineSearchIter, dfltOutputFcn};
            [options,gamma,memsize,step,linesearchtype,maxlinesearchiter,outfun] = internal.stats.parseArgs(names,dflts,varargin{:});
                
            % 2.4 Validate optional inputs.            
                % 2.4.1 'Options' struct.
                if ( ~isstruct(options) )                  
                    error(message('stats:classreg:learning:fsutils:fminlbfgs:BadOptions'));
                end
                
                % 2.4.2 'Gamma' value.
                isok = isnumeric(gamma) & isreal(gamma) & isscalar(gamma) & (gamma > 0);
                if ( ~isok )                    
                    error(message('stats:classreg:learning:fsutils:fminlbfgs:BadGamma'));
                end
                
                % 2.4.3 'Memory' value.
                isok = internal.stats.isIntegerVals(memsize,1);
                if ( ~isok )                    
                    error(message('stats:classreg:learning:fsutils:fminlbfgs:BadMemory'));
                end
                
                % 2.4.4 'Step' value.
                if ( ~isempty(step) )
                    isok = isnumeric(step) & isreal(step) & isscalar(step) & (step > 0);
                    if ( ~isok )                        
                        error(message('stats:classreg:learning:fsutils:fminlbfgs:BadStep'));
                    end
                end
                
                % 2.4.5 'LineSearch' value.
                linesearchtype   = internal.stats.getParamVal(linesearchtype,{weakWolfe,strongWolfe,backtracking},'LineSearch');
                
                % 2.4.6 Set up line search code.
                weakWolfeCode    = 1;
                strongWolfeCode  = 2;
                backtrackingCode = 3;
                
                switch lower(linesearchtype)
                    case lower(weakWolfe)
                        linesearchCode = weakWolfeCode;
                        
                    case lower(strongWolfe)
                        linesearchCode = strongWolfeCode;
                        
                    case lower(backtracking)
                        linesearchCode = backtrackingCode;                        
                end                
                
                % 2.4.7 'MaxLineSearchIter' value.
                isok = internal.stats.isIntegerVals(maxlinesearchiter,1);
                if ( ~isok )                    
                    error(message('stats:classreg:learning:fsutils:fminlbfgs:BadMaxLineSearchIter'));
                end
                
                % 2.4.8 'OutputFcn' value.
                if ( ~isempty(outfun) )
                    isok = isa(outfun,'function_handle');
                    if ( ~isok )                        
                        error(message('stats:classreg:learning:fsutils:fminlbfgs:BadOutputFcn'));
                    end
                end
                
            % 2.5 Combine dfltoptions and user specified options to create
            % a structure options with values for TolFun, TolX, Display,
            % MaxIter and GradObj.
            options = statset(dfltoptions,options);
            
            % 2.6 Extract gradTol, stepTol and maxit from options.
            gradTol = options.TolFun;
            stepTol = options.TolX;
            maxit   = options.MaxIter;
                  
            % 2.7 If options.Display is 'off' then set verbose to false,
            % otherwise set it to true.
            if ( strcmpi(options.Display,'off') )
                verbose = false;
            else
                verbose = true;
            end
                
            % 2.8 Do we have gradient information?
            if ( strcmpi(options.GradObj,'on') )
                haveGrad = true;
            else
                haveGrad = false;
            end

        % 3. Validate fun and theta0.
            % 3.1 fun must be a function handle.
            fun = validateFun(fun);
            
            % 3.2 theta0 must be a numeric real vector. If theta0 is a row
            % vector, we will convert it into a column vector. theta0 is
            % not allowed to contain NaN/Inf values.
            theta0 = validateTheta0(theta0);
            
        % 4. Call LBFGS routine.
        [theta,funtheta,gradfuntheta,cause]  = doLBFGS(fun,theta0,gamma,memsize,step,linesearchCode,maxlinesearchiter,outfun,gradTol,stepTol,maxit,verbose,haveGrad,weakWolfeCode,strongWolfeCode,backtrackingCode);
end

%% LBFGS routine.
function [theta,funtheta,gradfuntheta,cause] = doLBFGS(fun,theta0,gamma,memsize,step,linesearchCode,maxlinesearchiter,outfun,gradTol,stepTol,maxit,verbose,haveGrad,weakWolfeCode,strongWolfeCode,backtrackingCode)
            
    %% _Edge case when theta0 is empty._
    
        % 1. What is the length of theta0?
        n = numel(theta0);
        
        % 2. If theta0 is empty, set all outputs to [] and cause to 0.        
        if ( n == 0 )            
            theta        = theta0;
            funtheta     = [];
            gradfuntheta = [];
            cause        = 0;
            return;
        end
        
    %% _Initialize control variables for LBFGS iterations._  
        
        % 1. Make function to compute gradient. Instead of doing 
        % getGradient(fun,x), we can now do gradfun(x).
        if ( ~haveGrad )
            gradfun = makeGradient(fun);
        else
            gradfun = [];
        end
        
        % 2. Initial value of solution, initial function and gradient. 
        % We will also save the infinity norm of g at every iteration. We 
        % will always keep x, f, g and infnormg syncronized.
        x     = theta0;
        [f,g] = funAndGrad(x,fun,gradfun,haveGrad);
        
        errorIfNotScalar(f);
        infnormg = max(abs(g));
                    
        % 3. Edge case when f is -Inf. Can't do any better than this.
        if ( f == -Inf )
            theta        = x;
            funtheta     = f;
            gradfuntheta = g;
            cause        = 0;
            return;
        end
        
        % 4. Save initial infinity norm of gradient for relative gradient
        % convergence test.
        infnormg0 = infnormg; 
        
        % 5. Convert step value into gamma (if needed). Overwrite the value
        % supplied by 'Gamma' name/value pair.
        if ( ~isempty(step) )
            gamma  = step/max(sqrt(eps),infnormg0);
        end
        
        % 6. Save initial value of gamma to be used later to reinitialize 
        % LBFGS representation of inverse Hessian.
        gamma0 = gamma;
        
        % 7. Wolfe line search parameters 0 < c1 < c2 < 1. The values set
        % here are appropriate for a quasi-Newton method. It is unlikely
        % that these values will need modification.
        c1 = 1e-4;
        c2 = 0.9;
        
        % 8. Representation of inverse Hessian for LBFGS. memused is the
        % number of corrections stored so far. S contains the step vectors
        % and Y contains the gradient change vectors. order is a vector
        % such that order(1) is the index of the most recent correction and
        % order(end) is the index of the oldest correction. See the utility
        % function matrixVectorProductLBFGS for more information on Rho.
        memused = 0;
        S       = zeros(n,memused);
        Y       = zeros(n,memused);
        Rho     = zeros(1,memused);
        order   = zeros(1,memused);        
        
        % 9. Convergence flag. The while loop that follows will stop if
        % found = true. Iterations can stop either when optimal solution is
        % found or when step size becomes smaller than the specified
        % tolerance or when line search fails or when maximum number of
        % iterations is reached or when output function requests a stop.
        found = false;
        
        % 10. Iteration counter starting from 0. Do not change this.
        % numfailed is the number of consecutive failed line searches.
        % maxnumfailed is the maximum number of failed line searches
        % allowed.
        iter         = 0;
        numfailed    = 0;
        maxnumfailed = 2;
        
        % 11. Do we have an output function? If so, set up the structure
        % optimValues. Here's how the output function will be called:
        %
        % stop = outfun(x,optimValues,state)
        % optimValues contains the following fields:
        %
        % iteration - current iteration index.
        % fval      - current function value.
        % gradient  - current gradient.
        % stepsize  - current stepsize.
        %
        % state is 'init' for the first call and 'done' after convergence.
        % Intermediate calls have state equal to 'iter'.
        if ( isempty(outfun) )
            haveOutputFcn = false;
        else
            haveOutputFcn = true;
        end
        
        % 12. Initial call to output function.
        if ( haveOutputFcn )            
            % 12.1 Set up optimValues and state.
            optimValues           = struct();
            optimValues.iteration = iter;
            optimValues.fval      = f;
            optimValues.gradient  = g;
            optimValues.stepsize  = 0;
            state                 = 'init';
            
            % 12.2 Call the output function.
            stop = callOutputFcn(x,optimValues,state,outfun);
            
            % 12.3 Stop iterations if required.
            if ( stop )
                found = true;
                cause = 4;
            end
        end
        
        % 13. Display initial function value.
        if ( verbose == true )
            twonorms  = 0;
            curvokstr = ' ';
            % gamma is set above.
            alpha     = 0;
            success   = true;
            displayConvergenceInfo(iter,f,infnormg,twonorms,curvokstr,gamma,alpha,success);
        end
        
    %% _LBFGS main loop._    
        while ( found == false )        

            % 1. Compute LBFGS search direction p = H*(-g) where H is
            % represented implicitly by S, Y, Rho, order and gamma.
            p = matrixVectorProductLBFGS(S,Y,Rho,order,gamma,-g);
            
            % 2. p must be a descent direction in theory since we ensure
            % that LBFGS representation of H remains positive definite. But
            % numerical roundoff may prevent this from happening. If p is
            % not a descent direction, reset LBFGS storage, gamma and set p
            % proportional to the negative gradient.
            gtp = g'*p;
            if ( gtp >= 0 )
                isLBFGSdirOK = false;
                
                % 2.1 Reset LBFGS storage and gamma such that H = gamma*I.
                memused = 0;
                S       = zeros(n,memused);
                Y       = zeros(n,memused);
                Rho     = zeros(1,memused);
                order   = zeros(1,memused);
                gamma   = gamma0;
                
                % 2.2 Recompute p based on updated LBFGS storage.
                p = -gamma*g;
            else
                isLBFGSdirOK = true;
            end
            
            % 3. Line search to impose either weak Wolfe or strong Wolfe or
            % sufficient decrease conditions. This gives the step length
            % alpha, new iterate xs, new function value fs and gradient gs
            % at xs. If success is true then line search succeeded.
            [alpha,xs,fs,gs,success] = doLineSearch(x,f,g,p,haveGrad,fun,gradfun,c1,c2,maxlinesearchiter,linesearchCode,weakWolfeCode,strongWolfeCode,backtrackingCode);
            
            % 4. If LBFGS search direction is a descent direction and line
            % search failed then reset LBFGS storage and attempt a line
            % search along the negative gradient direction.
            if ( isLBFGSdirOK && ~success )
                % 4.1 Reset LBFGS storage and gamma such that H = gamma*I.
                memused = 0;
                S       = zeros(n,memused);
                Y       = zeros(n,memused);
                Rho     = zeros(1,memused);
                order   = zeros(1,memused);
                gamma   = gamma0;
                
                % 4.2 Reset search direction.
                p = -gamma*g;
                
                % 4.3 Do another line search along the new direction.
                [alpha,xs,fs,gs,success] = doLineSearch(x,f,g,p,haveGrad,fun,gradfun,c1,c2,maxlinesearchiter,linesearchCode,weakWolfeCode,strongWolfeCode,backtrackingCode);
            end
            
            % 5. Compute s and y.
            s = xs - x;
            y = gs - g;
            
            % 6. Check curvature condition and update LBFGS representation.
            yts    = y'*s;
            curvok = yts >= (c2 - 1)*(g'*s);
            
            if ( curvok && success && (alpha > 0) )
                if ( memused == memsize )
                    % 6.1 Discard oldest pair and add (s,y) to storage.
                    rho           = 1/yts;                    
                    oldidx        = order(end);
                    S(:,oldidx)   = s;
                    Y(:,oldidx)   = y;
                    Rho(1,oldidx) = rho;
                    order         = [oldidx,order];
                    order(end)    = [];
                else
                    % 6.2 Add (s,y) to storage. Increment memused.
                    rho     = 1/yts;                    
                    memused = memused + 1;
                    S       = [S,s];
                    Y       = [Y,y];                    
                    Rho     = [Rho,rho]; %#ok<*AGROW>
                    order   = [memused,order];
                end
                % 6.3 Compute gamma for the next iteration.
                gamma = yts/(y'*y);
            end

            % 7. Update x, f and g and infnormg if linesearch succeeded.
            if ( success )
                x         = xs;
                f         = fs;
                g         = gs;
                infnormg  = norm(g,Inf);
                
                numfailed = 0;                
            else
                numfailed = numfailed + 1;
            end
            
            % 8. Get 2 norm of s.
            twonorms = norm(s);
                            
            % 9. Check convergence.
            tau = max(1, min( abs(f), infnormg0 ));
            if ( infnormg <= tau*gradTol )
                found = true;
                % Local minimum found.
                cause = 0;
            elseif ( twonorms <= stepTol )
                found = true;
                % Local minimum possible.
                cause = 1;
            elseif ( isinf(f) && f < 0 )
                % Can't do any better.
                found = true;
                % Local minimum found.
                cause = 0;
            elseif ( numfailed >= maxnumfailed )
                found = true;
                % Line search failed.
                cause = 3;
            end
            
            % 10. Update iteration counter.
            iter = iter + 1;            
            
            % 11. Check iteration counter.
            if ( iter >= maxit )
                found = true;
                % Iteration limit reached.
                cause = 2;
            end
            
            % 12. Display convergence info if requested.
            if ( verbose == true )
                if ( curvok )
                    curvokstr = 'OK';
                else
                    curvokstr = 'NO';
                end
                displayConvergenceInfo(iter,f,infnormg,twonorms,curvokstr,gamma,alpha,success);
            end
            
            % 13. Call output function.
            if ( haveOutputFcn )
                if ( found == true )
                    % 13.1 Set up optimValues and state.
                    optimValues.iteration = iter;
                    optimValues.fval      = f;
                    optimValues.gradient  = g;
                    optimValues.stepsize  = twonorms;
                    state                 = 'done';
                    
                    % 13.2 Call the output function.
                    callOutputFcn(x,optimValues,state,outfun);
                elseif ( success )
                    % 13.3 Set up optimValues and state.
                    optimValues.iteration = iter;
                    optimValues.fval      = f;
                    optimValues.gradient  = g;
                    optimValues.stepsize  = twonorms;
                    state                 = 'iter';
                    
                    % 13.4 Call the output function.
                    stop = callOutputFcn(x,optimValues,state,outfun);
                    
                    % 13.5 Stop iterations if required.
                    if ( stop )
                        found = true;
                        cause = 4;
                    end
                end
            end
            
            % 14. Display final convergence message.
            if ( found == true && verbose == true )
                displayFinalConvergenceMessage(infnormg, tau, gradTol, twonorms, stepTol, cause);
            end
            
        end % end of while.

        %% _Set outputs._
        theta        = x;
        funtheta     = f;
        gradfuntheta = g;
    
end

function [f,g] = funAndGrad(x,fun,gradfun,haveGrad)
%funAndGrad - Compute function and gradient.
%   [f,g] = funAndGrad(x,fun,gradfun,haveGrad) takes a column vector x, a
%   function handle fun to compute the function value, a function handle
%   gradfun to compute the gradient vector and returns f = fun(x) and g =
%   gradfun(x). If haveGrad is true then it is assumed that fun can also
%   return the gradient information like [f,g] = fun(x) - in this case,
%   gradfun can be [].

    if ( haveGrad )
        [f,g] = fun(x);
    else
        f     = fun(x);
        g     = gradfun(x);
    end
end

%% Utility to do line search.
function [alpha,xs,fs,gs,success] = doLineSearch(x,f,g,p,haveGrad,fun,gradfun,c1,c2,maxit,linesearchCode,weakWolfeCode,strongWolfeCode,backtrackingCode)
%doLineSearch - Line search using backtracking, weak Wolfe or strong Wolfe.
% INPUTS:
%
% x        = n-by-1 vector - the current iterate.
% f        = scalar        - function value corresponding to x.
% g        = n-by-1 vector - gradient corresponding to x.
% p        = n-by-1 vector - current search direction.
% haveGrad = true if function handle fun can compute gradient and false otherwise.
% fun      = function handle to compute function and possibly gradient.
% gradfun  = function handle to compute gradient.
% c1,c2    = line search parameters such that 0 < c1 < c2 < 1.
% maxit    = maximum number of line search iterations.
%
% If haveGrad is true then fun can be called like this:
%
% [f,g] = fun(x)
%
% If haveGrad is false then fun and gradfun will be called like this:
%
% f = fun(x)
%
% g = gradfun(x)
%
% linesearchCode has the following interpretation.
%
%   linesearchCode = weakWolfeCode    -> weak Wolfe line search.
%   linesearchCode = strongWolfeCode  -> strong Wolfe line search.
%   linesearchCode = backtrackingCode -> backtracking line search.
%
% OUTPUTS:
%
% alpha   = step size satisfying sufficient decrease, weak Wolfe or strong Wolfe conditions.
% xs      = x + alpha*p.
% fs      = function value for xs.
% gs      = gradient value for xs.
% success = true if line search succeeded and false otherwise.

    switch ( linesearchCode )
        case weakWolfeCode
            [alpha,xs,fs,gs,success] =    weakWolfeLineSearch(x,f,g,p,haveGrad,fun,gradfun,c1,c2,maxit);
            
        case strongWolfeCode
            [alpha,xs,fs,gs,success] =  strongWolfeLineSearch(x,f,g,p,haveGrad,fun,gradfun,c1,c2,maxit);
            
        case backtrackingCode
            [alpha,xs,fs,gs,success] = backTrackingLineSearch(x,f,g,p,haveGrad,fun,gradfun,c1,c2,maxit);
            
        otherwise            
            error(message('stats:classreg:learning:fsutils:fminlbfgs:BadLineSearchMethod'));
    end
end

%% Utility for backtracking line search.
function [alpha,xs,fs,gs,success] = backTrackingLineSearch(x,f,g,p,haveGrad,fun,gradfun,c1,c2,maxit) %#ok<INUSL>
%backTrackingLineSearch - Line search that satisfies the sufficient decrease condition.
% INPUTS:
%
% x        = n-by-1 vector - the current iterate.
% f        = scalar        - function value corresponding to x.
% g        = n-by-1 vector - gradient corresponding to x.
% p        = n-by-1 vector - current search direction.
% haveGrad = true if function handle fun can compute gradient and false otherwise.
% fun      = function handle to compute function and possibly gradient.
% gradfun  = function handle to compute gradient.
% c1,c2    = line search parameters such that 0 < c1 < c2 < 1.
% maxit    = maximum number of line search iterations.
%
% If haveGrad is true then fun can be called like this:
%
% [f,g] = fun(x)
%
% If haveGrad is false then fun and gradfun will be called like this:
%
% f = fun(x)
%
% g = gradfun(x)
%
% OUTPUTS:
%
% alpha   = step size satisfying sufficient decrease conditions.
% xs      = x + alpha*p.
% fs      = function value for xs.
% gs      = gradient value for xs.
% success = true if line search succeeded and false otherwise.
    
    % 1. Set the trial value of alpha to 1 for quasi-Newton methods.
    alpha = 1;
    
    % 2. Derivative of fun(x+alpha*p) at alpha = 0 is p'*gradf(x) = p'*g.
    gtp = g'*p;
    
    % 3. found is a flag that controls the termination of while loop and
    % success marks whether we found a step satisfying the sufficient
    % decrease conditions or not.
    iter    = 0;
    found   = false;
    success = false;
    
    while ( not(found) )
        % 3.1 Tentative step along with new function and gradient values.
        xs      = x + alpha*p;
        [fs,gs] = funAndGrad(xs,fun,gradfun,haveGrad);
        
        % 3.2 Check sufficient conditions and adjust alpha if needed.
        if ( fs > (f + c1*alpha*gtp) )
            alpha = 0.5*alpha;
        else
            success = true;
            return;
        end
        
        % 3.3 Don't allow more than maxit iterations.
        iter = iter + 1;
        
        if ( iter >= maxit )
            found   = true;
            success = false;
        end
    end
end

%% Utility for weak Wolfe line search.
function [alpha,xs,fs,gs,success] = weakWolfeLineSearch(x,f,g,p,haveGrad,fun,gradfun,c1,c2,maxit)
%weakWolfeLineSearch - Line search that satisfies weak wolfe conditions.
% INPUTS:
%
% x        = n-by-1 vector - the current iterate.
% f        = scalar        - function value corresponding to x.
% g        = n-by-1 vector - gradient corresponding to x.
% p        = n-by-1 vector - current search direction.
% haveGrad = true if function handle fun can compute gradient and false otherwise.
% fun      = function handle to compute function and possibly gradient.
% gradfun  = function handle to compute gradient.
% c1,c2    = line search parameters such that 0 < c1 < c2 < 1.
% maxit    = maximum number of line search iterations.
%
% If haveGrad is true then fun can be called like this:
%
% [f,g] = fun(x)
%
% If haveGrad is false then fun and gradfun will be called like this:
%
% f = fun(x)
%
% g = gradfun(x)
%
% OUTPUTS:
%
% alpha   = step size satisfying weak Wolfe conditions.
% xs      = x + alpha*p.
% fs      = function value for xs.
% gs      = gradient value for xs.
% success = true if line search succeeded and false otherwise.

    % 1. Parameters for the search algorithm. The desired alpha is
    % contained in [a,b] and we set the trial value of alpha to 1 for
    % quasi-Newton methods.
    a     = 0;
    b     = Inf;
    alpha = 1;
    
    % 2. Derivative of fun(x+alpha*p) at alpha = 0 is p'*gradf(x) = p'*g.
    gtp = g'*p;
    
    % 3. Bisection search. found is a flag that controls the termination of
    % while loop and success marks whether we found a step satisfying the
    % weak Wolfe conditions or not.
    iter    = 0;
    found   = false;
    success = false;
    
    while ( found == false )
        % 3.1 Tentative step along with new function and gradient values.
        xs      = x + alpha*p;
        [fs,gs] = funAndGrad(xs,fun,gradfun,haveGrad);
        
        % 3.2 Check weak Wolfe conditions and adjust alpha if needed.
        if ( fs > (f + c1*alpha*gtp) )
            
            b     = alpha;
            alpha = 0.5*(a + b);
            
        elseif ( (gs'*p) < c2*gtp )
            
            a = alpha;
            if isinf(b)
                alpha = 2*a;
            else
                alpha = 0.5*(a + b);
            end
            
        else
            
            success = true;
            return;
        end
        
        % 3.3 Don't allow more than maxit iterations.
        iter = iter + 1;
        
        if ( iter >= maxit )
            found   = true;
            success = false;
        end
    end
end

%% Utilities for strong Wolfe line search.
function [alpha,xs,fs,gs,success] = strongWolfeLineSearch(x,f,g,p,haveGrad,fun,gradfun,c1,c2,maxit)
%strongWolfeLineSearch - Line search that satisfies strong wolfe conditions.
% INPUTS:
%
% x        = n-by-1 vector - the current iterate.
% f        = scalar        - function value corresponding to x.
% g        = n-by-1 vector - gradient corresponding to x.
% p        = n-by-1 vector - current search direction.
% haveGrad = true if function handle fun can compute gradient and false otherwise.
% fun      = function handle to compute function and possibly gradient.
% gradfun  = function handle to compute gradient.
% c1,c2    = line search parameters such that 0 < c1 < c2 < 1.
% maxit    = maximum number of line search iterations.
%
% If haveGrad is true then fun can be called like this:
%
% [f,g] = fun(x)
%
% If haveGrad is false then fun and gradfun will be called like this:
%
% f = fun(x)
%
% g = gradfun(x)
%
% OUTPUTS:
%
% alpha   = step size satisfying strong Wolfe conditions.
% xs      = x + alpha*p.
% fs      = function value for xs.
% gs      = gradient value for xs.
% success = true if line search succeeded and false otherwise.

    % 1. Maximum allowable value of alpha and increase factor for
    % bracketing.
    alphamax = 1e20;
    theta    = 2;
    
    % 2. Set phi(0), phi'(0) using f, g, p with phi(alpha)=fun(x+alpha*p).
    phi0   = f;
    dphi0  = p'*g;
    
    % 3. Solution lies in [alphaA,alphamax].
    alphaA = 0;
    xA     = x;
    fA     = f;
    gA     = g;
    phiA   = phi0;
    dphiA  = dphi0;
    
    % 4. First trial value for alpha in [alphaA,alphamax]. For quasi-Newton
    % methods the first trial value should be 1.
    alphaB = 1;
    
    % 5. Start the search.
    iter  = 0;
    found = false;
    
    while ( not(found) )
        
        % 5.1 Compute (x,f,g,phi,dphi) values for alphaB.
        xB      = x + alphaB*p;
        [fB,gB] = funAndGrad(xB,fun,gradfun,haveGrad);
        phiB    = fB;
        dphiB   = p'*gB;
        
        % 5.2 Narrow the interval down to [alphaA,alphaB].
        if ( (phiB > phi0 + c1*alphaB*dphi0) || (phiB >= phiA && iter > 0) )
            [alpha,xs,fs,gs,success] = strongWolfeZoom(alphaA,phiA,dphiA,alphaB,phiB,dphiB,fun,gradfun,x,p,haveGrad,phi0,dphi0,c1,c2);
            if ( not(success) )            
                % Return the point A since at least it satisfies the
                % sufficient decrease conditions.
                alpha   = alphaA;
                xs      = xA;
                fs      = fA;
                gs      = gA;                
            end
            return;
        end
        
        % 5.3 Check if the curvature condition holds. If so, we are done.
        if ( abs(dphiB) <= -c2*dphi0 )
            alpha   = alphaB;
            xs      = xB;
            fs      = fB;
            gs      = gB;
            success = true;
            return;
        end
        
        % 5.4 Narrow the interval down to [alphaA,alphaB]. Note the order
        % of inputs to the zoom function is different since alphaB attains
        % a lower function value compared to alphaA.
        if ( dphiB > 0 )
            [alpha,xs,fs,gs,success] = strongWolfeZoom(alphaB,phiB,dphiB,alphaA,phiA,dphiA,fun,gradfun,x,p,haveGrad,phi0,dphi0,c1,c2);
            if ( not(success) )
                % Return the point B since it satisfies the sufficient
                % decrease conditions.
                alpha   = alphaB;
                xs      = xB;
                fs      = fB;
                gs      = gB;                
            end
            return;
        end

        % 5.5 Update iteration counter.
        iter = iter + 1;
        
        % 5.6 Check convergence.
        if ( iter >= maxit )
            % Return the point B since it satisfies the sufficient decrease
            % conditions.
            alpha   = alphaB;
            xs      = xB;
            fs      = fB;
            gs      = gB;
            success = false;
            return;
        end
        
        % 5.7 Move point B to point A and increase alphaB for the next
        % iteration.
        alphaA = alphaB;        
        xA     = xB;
        fA     = fB;
        gA     = gB;        
        phiA   = phiB;
        dphiA  = dphiB;
        
        alphaB = min(theta*alphaB,alphamax);
    end
end

function [alpha,xs,fs,gs,success] = strongWolfeZoom(alphaLo,phiLo,dphiLo,alphaHi,phiHi,dphiHi,fun,gradfun,x,p,haveGrad,phi0,dphi0,c1,c2)
%strongWolfeZoom - Finds a point in [alphaLo,alphaHi] or [alphaHi,alphaLo] that satisfies the strong Wolfe conditions.
% INPUTS:
%
% alphaLo  = point that satisfies sufficient decrease condition. If alphaHi also satisfies sufficient decrease condition then phi(alphaLo) <= phi(alphaHi). 
% phiLo    = f(x + alpha*p) for alpha = alphaLo.
% dphiLo   = p'*gradf(x + alpha*p) for alpha = alphaLo.
% alphaHi  = point chosen so that dphiLo*(alphaHi - alphaLo) < 0.
% phiHi    = f(x + alpha*p) for alpha = alphaHi.
% dphiHi   = p'*gradf(x + alpha*p) for alpha = alphaHi.
% fun      = function handle to compute f(x) and possibly the gradient.
% gradfun  = function handle to compute gradient of f at x.
% x        = current estimate of solution.
% p        = current search direction.
% haveGrad = true if fun can compute the gradient and false otherwise.
% phi0     = f(x + alpha*p) for alpha = 0.
% dphi0    = p'*gradf(x + alpha*p) for alpha = 0.
% c1, c2   = constants such that 0 < c1 < c2 < 1.
%
% OUTPUTS:
%
% alpha   = step size satisfying strong Wolfe conditions.
% xs      = x + alpha*p.
% fs      = function value for xs.
% gs      = gradient value for xs.
% success = true if line search succeeded and false otherwise.

    % 1. Start the zoom iterations. We will do a maximum of 50 iterations.
    found = false;
    maxit = 50;
    iter  = 0;
    
    while ( not(found) )
        
        % 2. Do cubic interpolation in the interval bounded by alphaLo and
        % alphaHi. alphaj is either the minimizer of this cubic interpolant
        % or a midpoint of the interval.
        alphaj = minimizeCubicInterpolant(alphaLo,phiLo,dphiLo,alphaHi,phiHi,dphiHi);    
        
        % 3. Compute (x,f,g,phi,dphi) using alphaj.
        xs      = x + alphaj*p;
        [fs,gs] = funAndGrad(xs,fun,gradfun,haveGrad);       
        phij    = fs;
        dphij   = p'*gs;
        
        if ( (phij > phi0 + c1*alphaj*dphi0) || (phij >= phiLo) )
            % 4.1 If sufficient decrease is not satisfied or if phij is
            % greater than phiLo then we know that the desired alpha is in
            % the interval bounded by alphaLo and alphaj.
            alphaHi = alphaj;
            phiHi   = phij;
            dphiHi  = dphij;
        else
            % 4.2 If sufficient decrease holds and if curvature condition
            % holds then we have found alpha = alphaj. (xs,fs,gs) have been
            % calculated using alphaj.
            if ( abs(dphij) <= -c2*dphi0 )
                alpha   = alphaj;
                success = true;
                return;
            end
            
            % 4.3 Suppose alphaLo < alphaHi. Then the desired alpha is in
            % the interval [alphaLo,alphaHi]. Now dphiLo*(alphaHi - alphaLo) < 0
            % implies that dphiLo < 0. If dphij*(alphaHi - alphaLo) >= 0
            % then the slope must increase from a negative to a positive
            % value and must cross 0 somewhere. So the desired alpha lies
            % in [alphaLo,alphaj]. But now phij < phiLo so we rename
            % alphaLo to alphaHi and alphaj to alphaLo.
            if ( dphij*(alphaHi - alphaLo) >= 0 )
                alphaHi = alphaLo;
                phiHi   = phiLo;
                dphiHi  = dphiLo;
            end
            
            alphaLo = alphaj;
            phiLo   = phij;
            dphiLo  = dphij;
        end
        
        % 5. Check convergence.
        iter = iter + 1;
        
        if ( iter >= maxit )
            found = true;
            % Return alphaj and mark failure. (xs,fs,gs) have been
            % calculated using alphaj.
            alpha   = alphaj;
            success = false;
        end
    end
end

function [alpha,isMinimizer] = minimizeCubicInterpolant(a,phia,dphia,b,phib,dphib)
%minimizeCubicInterpolant - Minimize a cubic interpolant in 1D.
%   [alpha,isMinimizer] = minimizeCubicInterpolant(a,phia,dphia,b,phib,dphib) 
%   fits a cubic interpolant using the supplied scalars a, phia, dphia, b,
%   phib, dphib and attempts to compute its minimizer alpha between a and
%   b. If successful, isMinimizer is true. If the minimizer cannot be found
%   between a and b, isMinimizer is false. In this case, alpha is the
%   midpoint 0.5*(a + b). a can be >= or < b.

    % 1. If a and b are equal, return right away.
    delta = b - a;
    
    if ( delta == 0 )
        alpha       = a;
        isMinimizer = false;
        return;
    end

    % 2. Compute d1.
    d1 = (dphib + dphia) - 3*((phib - phia)/delta);

    % 3. Check condition on d1.
    discr = d1^2 - dphia*dphib;
    
    if ( discr <= 0 )
        alpha       = 0.5*(a + b);
        isMinimizer = false;
        return;
    end

    % 4. Compute c1 and check condition on dphia if c1 is almost 0.
    c1  = (dphib + dphia + 2*d1)/(3*delta^2);
    tol = sqrt(eps(class(c1)));
    
    if ( abs(c1) < tol )
        if ( dphia*delta >= 0 )
            alpha       = 0.5*(a + b);
            isMinimizer = false;
            return;
        end
    end

    % 5. Compute d2.
    d2 = sign(delta)*sqrt(discr);

    % 6. Compute alpha.
    h           = ((dphib + d2 - d1)/(dphib - dphia + 2*d2));
    alpha       = b - delta*h;
    isMinimizer = true;
    
    % 7. Ensure alpha is between a and b. Note that a can be > b.    
    if ( (alpha - a)*(alpha - b) >= 0 )
        alpha       = 0.5*(a + b);
        isMinimizer = false;
        return;
    end
    
    % 8. Ensure that alpha is not too close to the end points. We want:    
    %   abs(alpha - a) >= frac*abs(b - a)
    %   abs(alpha - b) >= frac*abs(b - a)
    frac   = 1e-3;
    thresh = frac*abs(delta);
    if ( (abs(alpha - a) < thresh) || (abs(alpha - b) < thresh) )
        % alpha is too close to the end points - return the midpoint.
        alpha       = 0.5*(a + b);
        isMinimizer = false;
    end
end

%% Utility for LBFGS two loop recursion.
function r = matrixVectorProductLBFGS(S,Y,Rho,order,gamma,q)
%matrixVectorProductLBFGS - Implements LBFGS two loop recursion for computing matrix vector products.
%   r = matrixVectorProductLBFGS(S,Y,Rho,order,gamma,q) takes a n-by-m 
%   matrix S, n-by-m matrix Y, 1-by-m vector Rho, 1-by-m vector order, a 
%   scalar gamma and a n-by-1 vector q and computes:
%
%       r = H*q
%
%   where H is the LBFGS matrix implicitly represented by S, Y, Rho and
%   gamma. Elements of order are permuted values of 1:m such that order(1)
%   is the most recent correction pair and order(end) is the oldest
%   correction pair. Here's some additional info: 
%
%   S = [s_1,s_2,...,s_m] where s_i are the step vectors in LBFGS. 
%   s_order(1) is the most recent and s_order(m) is the oldest step vector.
%
%   Y = [y_1,y_2,...,y_m] where y_i are the gradient change vectors in LBFGS.
%   y_order(1) is the most recent and y_order(m) is the oldest gradient change vector.
%
%   Rho   = [rho_1,rho_2,...,rho_m] where
%   rho_i = 1/(y_i'*s_i) > 0
%
%   gamma is a scalar such that the initial LBFGS approximation to H is
%   taken to be equal to gamma*eye(n). The choice:
%
%   gamma = (S(:,order(1))'*Y(:,order(1)))/(Y(:,order(1))'*Y(:,order(1)));
%
%   usually works well. Inputs are assumed to have compatible dimensions.

    % 1. Initialize a.
    [~,m] = size(S);    
    a     = zeros(1,m);
    
    % 2. Recursion for q - original q is overwritten.
    for i = order % instead of 1:m
        a(i) = Rho(i)*(S(:,i)'*q);
        q    = q - Y(:,i)*a(i);
    end

    % 3. Form initial r.
    r = gamma*q;

    % 4. Recursion for r in reverse order.
    for i = fliplr(order) % instead of m:-1:1
        beta = Rho(i)*(Y(:,i)'*r);
        r    = r + S(:,i)*(a(i) - beta);
    end
end

%% Utilities to display convergence info.
function displayFinalConvergenceMessage(infnormg,tau,gradTol,twonorms,stepTol,cause)
%displayFinalConvergenceMessage - Helper function to display final convergence message.
%   displayFinalConvergenceMessage(infnormg,tau,gradTol,twonorms,stepTol,cause)
%   takes several inputs (described below) and prints out a summary of why
%   the algorithm stopped.
%
%   INPUTS:
%
%   infnormg = infinity norm of the gradient at current iterate.
%   tau      = relative convergence factor for relative convergence test.
%   gradTol  = relative tolerance for convergence test. 
%   twonorms = two norm of the proposed step size s.
%   stepTol  = absolute tolerance on step length.
%   cause    = reason for termination of the algorithm.

    % 1. Explain why iterations stopped.
    fprintf('\n');
    infnormgStr = getString(message('stats:classreg:learning:fsutils:fminlbfgs:FinalConvergenceMessage_InfNormGrad'));
    fprintf(['         ',infnormgStr,' ','%6.3e\n'], infnormg);
    twonormsStr = getString(message('stats:classreg:learning:fsutils:fminlbfgs:FinalConvergenceMessage_TwoNormStep'));
   	fprintf(['              ',twonormsStr,' ','%6.3e, ','TolX   =',' ','%6.3e\n'], twonorms, stepTol);
    relinfnormgStr = getString(message('stats:classreg:learning:fsutils:fminlbfgs:FinalConvergenceMessage_RelInfNormGrad'));
    fprintf([relinfnormgStr,' ','%6.3e, ','TolFun =',' ','%6.3e\n'], infnormg/tau, gradTol);

    % 2. Explain what the final solution means.
    if ( cause == 0 )
        % Local minimum found.      
        fprintf([getString(message('stats:classreg:learning:fsutils:fminlbfgs:Message_LocalMinFound')),'\n']);
    elseif ( cause == 1 )
        % Local minimum possible.
        fprintf([getString(message('stats:classreg:learning:fsutils:fminlbfgs:Message_LocalMinPossible')),'\n']);
    elseif ( cause == 2 )
        % Iteration limit reached.
        fprintf([getString(message('stats:classreg:learning:fsutils:fminlbfgs:Message_UnableToConverge')),'\n']);
    elseif ( cause == 3 )
        % Line search failed.        
        fprintf([getString(message('stats:classreg:learning:fsutils:fminlbfgs:Message_LineSearchFailed')),'\n']);
    elseif ( cause == 4 )
        % Terminated because of output function.        
        fprintf([getString(message('stats:classreg:learning:fsutils:fminlbfgs:Message_StoppedByOutputFcn')),'\n']);
    end
end

function displayConvergenceInfo(iter,f,infnormg,twonorms,curvokstr,gamma,alpha,success)
%displayConvergenceInfo - Helper function to display iteration wise convergence info.
%   displayConvergenceInfo(iter,f,infnormg,twonorms,curvokstr,gamma,alpha,success)
%   accepts several inputs (described below) and prints out a diagnostic
%   summary of progress made by the optimizer.
%
%   INPUTS:
%
%   iter      = iteration number.
%   f         = function value at current iterate.
%   infnormg  = infinity norm of the gradient at current iterate.
%   twonorms  = two norm of the proposed step size s.
%   curvokstr = true if curvature condition was satisfied.
%   gamma     = current value of gamma in LBFGS.
%   alpha     = current step size parameter.
%   success   = true if the most recent line search was successful.
%
%   We will display convergence info like this:
%
% |====================================================================================================|
% |   ITER   |   FUN VALUE   |  NORM GRAD  |  NORM STEP  |  CURV  |    GAMMA    |    ALPHA    | ACCEPT |
% |====================================================================================================|
% |        0 |   1.39133e+00 |   9.949e-01 |   5.030e+00 |    OK  |   1.015e-01 |   1.000e+00 |   YES  |
% |        1 |   1.27099e+00 |   8.589e-01 |   1.268e-01 |    OK  |   1.201e-01 |   1.000e+00 |   YES  |
% |        2 |   1.09152e+00 |   6.458e-01 |   3.010e-01 |    OK  |   2.832e-01 |   1.000e+00 |   YES  |
% |        3 |   9.66848e-01 |   3.994e-01 |   3.550e-01 |    OK  |   6.910e-01 |   1.000e+00 |   YES  |
% |        4 |   9.50188e-01 |   1.243e-02 |   1.327e-01 |    OK  |   1.868e-01 |   1.000e+00 |   YES  |
% |        5 |   9.50165e-01 |   4.138e-04 |   5.519e-03 |    OK  |   2.331e-01 |   1.000e+00 |   YES  |
% |        6 |   9.50165e-01 |   8.860e-05 |   1.314e-04 |    OK  |   2.189e-01 |   1.000e+00 |   YES  |
% |        7 |   9.50165e-01 |   2.395e-07 |   2.278e-05 |    OK  |   1.473e-01 |   1.000e+00 |   YES  |

    % 1. Display header every 20 iterations.
    if ( rem(iter,20) == 0 )
        fprintf('\n');
        fprintf('|====================================================================================================|\n');
        fprintf('|   ITER   |   FUN VALUE   |  NORM GRAD  |  NORM STEP  |  CURV  |    GAMMA    |    ALPHA    | ACCEPT |\n');
        fprintf('|====================================================================================================|\n');
    end
    
    % 2. Display iteration wise convergence info.
    if ( success )
        stepTakenString = 'YES';
    else
        stepTakenString = ' NO';
    end
    fprintf('|%9d |%14.6e |%12.3e |%12.3e |%6s  |%12.3e |%12.3e |%6s  |\n', iter, f, infnormg, twonorms, curvokstr, gamma, alpha, stepTakenString);    
end

%% Utility to call outputFcn.
function stop = callOutputFcn(x,optimValues,state,outfun)
%callOutputFcn - calls the user supplied output function.
%
% INPUTS:
% x           = current x value.
% optimValues = current optimValues struct.
% state       = a string - 'init','iter' or 'done'
% outfun      = function handle to the output function.
%
% optimValues contains the following fields:
%
% iteration - current iteration index.
% fval      - current function value.
% gradient  - current gradient.
% stepsize  - current stepsize.
%
% OUTPUTS:
% stop = true if optimization iterations should be terminated and false
%        otherwise.

    stop = outfun(x,optimValues,state);    
end

%% Other utility functions.
%=== makeGradient
function gfun = makeGradient(fun)
%makeGradient - Make function handle to compute numerical gradient.
%   gfun = makeGradient(fun) takes a function handle fun and returns a
%   function handle gfun to compute the numerical gradient of fun. It is
%   assumed that fun can be called like fun(theta) where theta is a p-by-1
%   vector. Output function handle can be called like gfun(theta).

    gfun = @(theta) classreg.learning.fsutils.Solver.getGradient(fun,theta);
end

%=== validateFun
function fun = validateFun(fun)
%validateFun - Validate the fun input.
%   fun = validateFun(fun) takes fun which is expected to be a function
%   handle and validates it. If not valid, an error message is thrown.

    assertThat(isa(fun,'function_handle'),'stats:classreg:learning:fsutils:fminlbfgs:BadFun');
end

%=== validateTheta0
function theta0 = validateTheta0(theta0)
%validateTheta0 - Validate the theta0 input.
%   theta0 = validateTheta0(theta0) takes a potential vector theta0 and
%   validates it. If not valid, an error message is thrown. The output
%   vector theta0 will be a column vector.
%
%   What is checked?
%
%   1. theta0 must be a numeric, real vector.
%   2. theta0 must not contain any NaN or Inf values.

    assertThat(isnumeric(theta0) & isreal(theta0) & isvector(theta0),'stats:classreg:learning:fsutils:fminlbfgs:BadTheta0_NumericRealVector');
    
    assertThat(~any(isnan(theta0)) & ~any(isinf(theta0)),'stats:classreg:learning:fsutils:fminlbfgs:BadTheta0_NoNaNInf');
        
    if ( size(theta0,1) == 1 )
        theta0 = theta0';
    end
end

%=== errorIfNotScalar
function errorIfNotScalar(funtheta0)
%errorIfNotScalar - Errors if supplied function handle does not return a scalar.
%   errorIfNotScalar(funtheta0) errors out if funtheta0 is not scalar. Here
%   funtheta0 is the function handle fun evaluated at the initial point
%   theta0.
    
    assertThat(isscalar(funtheta0),'stats:classreg:learning:fsutils:fminlbfgs:BadFunTheta0');
end

%=== assertThat
function assertThat(condition,msgID,varargin)
%assertThat - Helper method for verifying assertions.
%   assertThat(condition,msgID,varargin) takes a variable condition that is
%   either true or false, a message catalog ID msgID and optional arguments
%   required to create a message object from msgID. If condition is false,
%   an error message represented by msgID is thrown.

    if ( ~condition )
        % 1. Create a message object from msgID and varargin.
        try
            msg = message(msgID,varargin{:});
        catch      
            error(message('stats:LinearMixedModel:BadMsgID',msgID));
        end
        % 2. Create and throw an MException.
        ME = MException(msg.Identifier, getString(msg));
        throwAsCaller(ME);        
    end
end
