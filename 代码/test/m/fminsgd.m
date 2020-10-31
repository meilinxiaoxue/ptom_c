function [x,cause] = fminsgd(fun,x0,N,varargin)
%FMINSGD Utility to solve unconstrained minimization problems by Stochastic Gradient Descent (SGD).
%   [x,cause] = FMINSGD(fun,x0,N) solves the minimization problem:
%
%             min w.r.t x: fun(x)
%
%   starting from the initial point x0. A minibatch Stochastic Gradient 
%   Descent (SGD) method is used. SGD can be used when fun has a special
%   form (described below).
%
%   POSITIONAL PARAMETERS:
%     
%       fun                 A function handle to the function to be 
%                           minimized that can be called like fun(x0). fun
%                           accepts a real vector like x0 and returns a
%                           real scalar. fun(x) is the average of N
%                           component functions fun_i(x) like this:
%
%                           fun(x) = (1/N) * sum_{i=1}^N fun_i(x)
%
%                           fun should also be callable like fun(x,S) where
%                           S is a subset of {1,2,...,N} such that:
%
%                           fun(x,S) = (1/|S|) * sum_{i \in S} fun_i(x)
%
%                           fun(x,S) is the average of |S| component
%                           functions fun_i.
%
%       x0                  Initial point to begin iterations as a real 
%                           column vector.
%
%       N                   A positive integer specifying the number of
%                           components fun_i(x) used to compute fun(x).
%
%   Gradient of fun can be optionally computed using finite differences.
%   See the 'GradObj' field in the 'Options' name/value pair below.
%
%   [...] = FMINSGD(fun,x0,N,'Name1','Value1',...) specifies one or more of
%   the following name/value pairs:
%
%       'MiniBatchSize'     A positive integer between 1 and N specifying 
%                           the minibatch size for SGD. Default is min(10,N).
%
%       'MaxPasses'         A positive integer specifying the maximum
%                           number of passes for SGD. Default is 1.
%
%       'LearnFcn'          A function handle learnfcn that can be called
%                           like this:
%
%                           eta_k = learnfcn(k)
%
%                           where k is the iteration index and eta_k > 0 is
%                           the learning rate. Elements of eta_k should sum
%                           to infinity and elements of eta_k^2 should sum
%                           to a finite value. Default is @(k) 1/(k+1).
%
%       'NumPrint'          A positive integer specifying the frequency
%                           with which to display convergence summary on 
%                           screen. 'NumPrint' minibatches are processed 
%                           for each line of convergence summary printed on
%                           screen. Default is 10.
%
%       'Options'           A structure containing optimization options 
%                           with the following fields:
%                               
%               'TolX'   -      Relative tolerance on the step size. 
%                               Default is 1e-6. If s is the current step
%                               then iterations stop if:
%
%                                   norm(s) <= TolX*max(1,norm(x0))
%  
%               'MaxIter' -     Maximum number of minibatch SGD iterations 
%                               allowed. Default is N.
%  
%               'Display' -     Level of display:  'off', 'iter', or 'final'.
%                               Default is 'off'. Both 'iter' and 'final'
%                               have the same effect.
%
%               'GradObj' -     Either 'on' or 'off'. Default is 'off'. 
%                               If 'on', it is assumed that fun can return
%                               gradient information like this:
%
%                                   [f,gradf] = fun(x)
%
%                               fun should also be callable like this:
%
%                                   [f,gradf] = fun(x,S)
%
%                               where fun(x,S) is described above. In this
%                               case, gradf should be the gradient of
%                               fun(x,S).
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
%                           fval      - current minibatch function value.
%                           gradient  - current minibatch gradient.
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
%       'UpdateFcn'         A function handle updatefcn that can be called
%                           like this:
%
%                           [x_{k+1},f_{k+1},g_{k+1}] = updatefcn(h,x_k)
%
%                           where h is a function handle that can be called
%                           like this:
%
%                           [f,g] = h(x)
%
%                           f is the value of h at x and g is the gradient
%                           of h at x. updatefcn should try to minimize h
%                           starting from the initial point x_k. After an
%                           approximate minimizer is found, updatefcn
%                           should return the estimated solution x_{k+1},
%                           the function value f_{k+1} at x_{k+1} and 
%                           gradient g_{k+1} at x_{k+1}. The function
%                           handle h is described in a section titled
%                           "General update representation" below. Default
%                           is [] to use the standard minibatch SGD update.
%                           To use minibatch LBFGS, create a function
%                           handle updatefcn with LBFGS as the optimizer as
%                           described above. 
%
%   OUTPUTS:
%
%       x                   A column vector containing the estimated 
%                           solution to the problem.
%
%       cause               An integer code indicating the reason for 
%                           termination of iterations. Possible values are
%                           as follows:
%
%                           * cause = 1 means that the step size most
%                           recently taken was less than TolX in a
%                           relative error sense. The interpretation is
%                           "Step tolerance reached.".
%
%                           * cause = 2 means 'Iteration or pass limit reached.'.
%
%                           * cause = 4 means iterations were terminated 
%                           before convergence because of OutputFcn. Exit 
%                           message is 'Terminated because of OutputFcn.'.

%       Copyright 2015-2016 The MathWorks, Inc.

%% Problem description.
% Suppose $x \in R^p$ and consider the objective function:
%
% $f(x) = \frac{1}{N} \sum_{i=1}^N f_i(x)$
%
% We would like to minimize $f(x)$ w.r.t. $x$ using minibatch stochastic
% gradient descent (SGD) starting at $x_0$. The overall objective function
% $f$ is made up of $N$ component functions $f_i$ which are assumed to be
% differentiable with Lipschitz continuous gradients. $f_i$ can be
% non-convex functions. Given the current iterate $x_k$ the next iterate
% $x_{k+1}$ is given by the following SGD update:
%
% $x_{k+1} = x_k - \eta_k \left[ \frac{1}{|\mathcal{S}|} \sum_{i \in \mathcal{S}} \nabla f_i(x_k) \right]$
%
% where $\mathcal{S}$ is a set of $B$ integers chosen independently and
% with equal probability from $\{1,2,\ldots,N\}$. $B$ is the minibatch size
% and $\eta_k$ is the learning rate. SGD convergence requires that the
% learning rates satisfy:
%
% $\sum_{k = 0}^{\infty} \eta_k = \infty$
%
% $\sum_{k=0}^{\infty} \eta_k^2 < \infty$
%
% $\eta_k \to 0$ as $k \to \infty$
%
% The second condition above guarantees the third but it is written out
% here for completeness. For example, the choice $\eta_k =
% \frac{\eta_0}{k}$ satisfies these conditions. In practice:
%
% * The indices $\{1,2,\ldots,N\}$ are randomly shuffled and partitioned into 
% $K$ disjoint parts or batches $\mathcal{S}_1$, $\mathcal{S}_2$, $\ldots$, $\mathcal{S}_K$ of approximate size $B$.
%
% * $K$ SGD updates are appliled using $\mathcal{S} = \mathcal{S}_j$ for $j =
% 1,2,\ldots,K$. Every SGD update processes around $B$ components $f_i$ and
% increases the iteration counter $k$ by $1$. This completes $1$ epoch or
% pass through the data. The iteration counter $k$ increases by $K$ after
% $1$ pass through the data.
%
% * For additional passes, the above steps are repeated.
%% General update representation
% Suppose $x_k$ is the current estimate of solution. Given a minibatch
% $\mathcal{S}$, we would like to compute the next iterate $x_{k+1}$. One
% general way of doing this is the following:
%
% $x_{k+1} = \mbox{arg min}_{x} \,\,\,\, g(x) + \frac{1}{2 \eta_k} (x - x_k)^T (x - x_k)$
%
% where
%
% $g(x) = \frac{1}{|\mathcal{S}|} \sum_{i \in S}
% f_i(x) = fun(x,\mathcal{S})$
%
% Suppose we approximate $g(x)$ by a first order Taylor approximation
% around $x_k$. Then:
%
% $g(x) \approx g(x_k) + (x - x_k)^T \nabla g(x_k)$
%
% If we substitute this approximation to $g(x)$ into the definition for
% $x_{k+1}$ we get:
%
% $x_{k+1} = \mbox{arg min}_{x} \,\,\,\, h(x) = g(x_k) + (x - x_k)^T \nabla g(x_k) + \frac{1}{2 \eta_k} (x - x_k)^T (x - x_k)$
%
% This simplified problem is easy to solve. Setting $\nabla h(x_{k+1}) = 0$
% gives:
%
% $\nabla g(x_k) + \frac{(x_{k+1} - x_k)}{\eta_k} = 0$
%
% or
%
% $x_{k+1} = x_k -\eta_k \, \nabla g(x_k) = x_k -\eta_k \, \left[\frac{1}{|\mathcal{S}|} \sum_{i \in S}
% \nabla f_i(x_k)\right]$
%
% This is exactly the minibatch SGD update. So minibatch SGD can be
% considered to be a special case of the more general update
% representation. Instead of approximating $g(x)$ by a linear function, we
% could keep the form of $g(x)$ and attempt to approximately solve the
% general problem:
%
% $x_{k+1} = \mbox{arg min}_{x} \,\,\,\,h(x) = g(x) + \frac{1}{2 \eta_k} (x - x_k)^T (x - x_k) = fun(x,\mathcal{S}) + \frac{1}{2 \eta_k} (x - x_k)^T (x - x_k)$
%
% by a batch method such as LBFGS. We then have a stochastic version of
% LBFGS which I call minibatch LBFGS.
%
% $\nabla h(x) = \nabla g(x) + \frac{(x - x_k)}{\eta_k}$

    %% Handle input args.        
    
        % 1. Check number of input arguments.
        narginchk(3,Inf);
    
        % 2. Validate fun, x0 and N.
            % 2.1 Validate fun.
            isok = isa(fun,'function_handle');
            if ( ~isok )                
                error(message('stats:classreg:learning:fsutils:fminsgd:BadFun'));
            end
            
            % 2.2 Validate x0. Make x0 into a column vector.
            isok = isnumeric(x0) && isreal(x0) && isvector(x0);
            if ( ~isok )                
                error(message('stats:classreg:learning:fsutils:fminsgd:BadX0'));
            end
            x0 = x0(:);
            
            % 2.3 Validate N.
            isok = internal.stats.isIntegerVals(N,1);
            if ( ~isok )                
                error(message('stats:classreg:learning:fsutils:fminsgd:BadN'));
            end
        
        % 3. Extract optimization options.
            % 3.1 An 'Options' structure with default values for TolX, 
            % Display, MaxIter and GradObj.
            dfltTolX    = 1e-6;
            dfltDisplay = 'off';
            dfltMaxIter = N;
            dfltGradObj = 'off';
            dfltoptions = statset('TolX'   ,dfltTolX   ,...
                                  'Display',dfltDisplay,...
                                  'MaxIter',dfltMaxIter,...
                                  'GradObj',dfltGradObj);            
                        
            % 3.2 Default values of other optional inputs.
            dfltMiniBatchSize = min(10,N);
            dfltMaxPasses     = 1;
            dfltLearnFcn      = @(k) 1/(k+1);
            dfltNumPrint      = 10;
            dfltOutputFcn     = [];
            dfltUpdateFcn     = [];
            
            % 3.3 Process optional name/value pairs.
            names = {  'Options',   'MiniBatchSize',   'MaxPasses',   'LearnFcn',   'NumPrint',   'OutputFcn',   'UpdateFcn'};
            dflts = {dfltoptions, dfltMiniBatchSize, dfltMaxPasses, dfltLearnFcn, dfltNumPrint, dfltOutputFcn, dfltUpdateFcn};
            [options,minibatchsize,maxpasses,learnfcn,numprint,outfun,updatefun] = internal.stats.parseArgs(names,dflts,varargin{:});
                
            % 3.4 Validate optional inputs.            
                % 3.4.1 'Options' struct.
                if ( ~isstruct(options) )                    
                    error(message('stats:classreg:learning:fsutils:fminsgd:BadOptions'));
                end
                
                % 3.4.2 'MiniBatchSize' value.
                isok = internal.stats.isIntegerVals(minibatchsize,1,N);
                if ( ~isok )                    
                    error(message('stats:classreg:learning:fsutils:fminsgd:BadMiniBatchSize',N));
                end
                
                % 3.4.3 'MaxPasses' value.
                isok = internal.stats.isIntegerVals(maxpasses,1);
                if ( ~isok )                    
                    error(message('stats:classreg:learning:fsutils:fminsgd:BadMaxPasses'));
                end
                
                % 3.4.4 'LearnFcn' value.
                isok = isa(learnfcn,'function_handle');
                if ( ~isok )                    
                    error(message('stats:classreg:learning:fsutils:fminsgd:BadLearnFcn'));
                end
                
                % 3.4.5 'NumPrint' value.
                isok = internal.stats.isIntegerVals(numprint,1);
                if ( ~isok )                    
                    error(message('stats:classreg:learning:fsutils:fminsgd:BadNumPrint'));
                end
                
                % 3.4.6 'OutputFcn' value.
                if ( ~isempty(outfun) )
                    isok = isa(outfun,'function_handle');
                    if ( ~isok )                        
                        error(message('stats:classreg:learning:fsutils:fminsgd:BadOutputFcn'));
                    end
                end
               
                % 3.4.7 'UpdateFcn' value.
                if ( ~isempty(updatefun) )
                    isok = isa(updatefun,'function_handle');
                    if ( ~isok )                        
                        error(message('stats:classreg:learning:fsutils:fminsgd:BadUpdateFcn'));
                    end
                end
                
            % 3.5 Combine dfltoptions and user specified options to create
            % a structure options with values for TolX, Display, MaxIter
            % and GradObj.
            options = statset(dfltoptions,options);
            
            % 3.6 Extract stepTol and maxit from options.
            stepTol = options.TolX;
            maxit   = options.MaxIter;
                  
            % 3.7 If options.Display is 'off' then set verbose to false,
            % otherwise set it to true.
            if ( strcmpi(options.Display,'off') )
                verbose = false;
            else
                verbose = true;
            end
                
            % 3.8 Do we have gradient information?
            if ( strcmpi(options.GradObj,'on') )
                haveGrad = true;
            else
                haveGrad = false;
            end
            
        % 4. Call SGD routine.
        [x,cause]  = doSGD(fun,x0,N,minibatchsize,maxpasses,learnfcn,outfun,stepTol,maxit,verbose,haveGrad,numprint,updatefun);
end

%% SGD routine.
function [x,cause] = doSGD(fun,x0,N,minibatchsize,maxpasses,learnfcn,outfun,stepTol,maxit,verbose,haveGrad,numprint,updatefun)

%% _Initialize control variables for SGD iterations_.
    
    % 1. Initialize iteration counters.
    % iter = number of minibatches processed so far.
    % pass = number of passes through the data so far.
    iter = 0;
    pass = 0;
            
    % 2. Divide [1,2,...,N] into K minibatches such that each minibatch has
    % around B = minibatchsize observations. The last minibatch may have
    % less observations:
    %
    % 1st     minibatch: 1:B
    % 2nd     minibatch: B+1:2*B
    % ...
    % (K-1)th minibatch: (K-2)*B+1:(K-1)*B
    % Kth     minibatch: (K-1)*B+1:N
    K = ceil(N/minibatchsize);
    
    % 3. Initialize solution and save its norm for convergence check.    
    x   = x0;    
    tau = max(1,norm(x0));
    
    % 4. Every numprint minibatch iterations we will print:
    %
    % * favg        = the average of minibatch objectives
    % * infnormgavg = the average of infinity norm of minibatch gradients
    %
    % over numprint iterations.
    favg          = 0;
    infnormgavg   = 0;
    printiter     = 0;
    numprintcalls = 0;
    
    % 5. Flag to mark convergence.
    found = false;
    
    % 6. Do we have an output function? If so, set up the structure
    % optimValues. Here's how the output function will be called:
    %
    % stop = outfun(x,optimValues,state)
    % optimValues contains the following fields:
    %
    % iteration - current iteration index.
    % fval      - current minibatch function value.
    % gradient  - current minibatch gradient.
    % stepsize  - current stepsize.
    %
    % state is 'init' for the first call and 'done' after convergence.
    % Intermediate calls have state equal to 'iter'.
    if ( isempty(outfun) )
        haveOutputFcn = false;        
    else
        haveOutputFcn = true;        
        optimValues   = struct();
    end
    
    % 7. Do we have an update function?
    if isempty(updatefun)
        haveUpdateFcn = false;
    else
        haveUpdateFcn = true;
    end
    
    % 8. Initial step to get to x0.    
    normstep = 0;
    
%% _SGD main loop_.
    while ( not(found) )
        
        % 1. Shuffle observations randomly.
        obsidx = randperm(N);
        
        for j = 1:K          
            % 2. Get indices for current minibatch.
            if ( j < K )
                Sj = obsidx( (j-1)*minibatchsize+1 : j*minibatchsize );
            else
                Sj = obsidx( (K-1)*minibatchsize+1 : N );
            end
            
            % 3. fmb and gmb are the function value and gradient vector
            % computed using the minibatch Sj.
            [fmb,gmb]  = funAndGrad(x,Sj,fun,haveGrad);
            infnormgmb = max(abs(gmb));                      
                       
            % 4. Call output function.
            if ( haveOutputFcn )
                % 4.1 Set up optimValues and state.
                if ( iter == 0 )
                    state = 'init';
                else
                    state = 'iter';
                end
                
                optimValues.iteration = iter;
                optimValues.fval      = fmb;
                optimValues.gradient  = gmb;
                optimValues.stepsize  = normstep;
                
                % 4.2 Call output function.
                stop = callOutputFcn(x,optimValues,state,outfun);
                
                % 4.3 Stop iterations if required.
                if ( stop )
                    found = true;
                    cause = 4;
                    break;
                end
            end
            
            % 5. Get learning rate for iteration iter.
            eta = learnfcn(iter);
           
            % 6. Compute step size. Use update function if supplied.
            if ( haveUpdateFcn )
                hfcn = makeHFcnForGeneralUpdate(Sj,fun,haveGrad,eta,x);
                xnew = updatefun(hfcn,x);
                step = xnew - x;
            else
                step = -eta*gmb;
            end
           
            % 7. Two norm of step size.
            normstep = norm(step);
 
            % 8. Update x.
            x = x + step;
            
            % 9. favg and infnormgavg represent the average of fmb and
            % infnormgmb over (printiter+1) iterations.
            favg        = favg + (fmb - favg)/(printiter+1);
            infnormgavg = infnormgavg + (infnormgmb - infnormgavg)/(printiter+1);
            printiter   = printiter + 1;
           
            % 10. Display convergence info.
            if ( rem(printiter,numprint) == 0 )
                if ( verbose )                    
                    displayConvergenceInfo(pass,iter,favg,infnormgavg,normstep,eta,numprintcalls);
                    numprintcalls = numprintcalls + 1;
                end
                printiter   = 0;
                favg        = 0;
                infnormgavg = 0;
            end            
           
            % 11. Update iteration counter.
            iter = iter + 1;
           
            % 12. Check convergence.            
            if ( normstep <= stepTol*tau )
                found = true;
                cause = 1;
                break;
            elseif ( iter >= maxit )
                found = true;
                cause = 2;                
                break;
            end
        end % end of for loop.
       
        % 13. Update pass counter (could be a partial pass).
        pass = pass + 1;
       
        % 14. Check convergence.
        if ( pass >= maxpasses )
            found = true;
            cause = 2;
        end
       
        % 15. Final call to output function.
        if ( haveOutputFcn && found == true)
            state = 'done';
            
            optimValues.iteration = iter;
            optimValues.fval      = fmb;
            optimValues.gradient  = gmb;
            %optimValues.fval      = NaN;
            %optimValues.gradient  = NaN;
            optimValues.stepsize  = normstep;
            
            callOutputFcn(x,optimValues,state,outfun);
        end
       
        % 16. Display final convergence message.
        if ( found == true && verbose == true )
            displayFinalConvergenceMessage(normstep,tau,stepTol,cause);           
        end
       
    end % end of while.    
end

%% General update objective function.
function hfcn = makeHFcnForGeneralUpdate(Sj,fun,haveGrad,etak,xk)
%makeHFcnForGeneralUpdate - Make the general update objective function.
%
% INPUTS:
%
% Sj       = a row integer vector that is a subset of {1,2,...,N}. N is the
%            number of components in fun.
% fun      = function handle that can be called like: [f,g] = fun(x,S). A
%            detailed description of fun is given in the help text for 
%            fminsgd.
% haveGrad = true if fun can compute gradients and false otherwise.
% etak     = current learning rate.
% xk       = current iterate.
%
% OUTPUTS:
% 
% hfcn     = A function handle. See description of h(x) in the "General 
%            update representation" section for more information.

    % Constant multiplier for the regularization term.
    c = 1/(2*etak);
    
    hfcn = @myf;
    function [fmb,gmb] = myf(x)
        % 1. fun(x,Sj) and its gradient.
        [fmb,gmb] = funAndGrad(x,Sj,fun,haveGrad);
        
        % 2. Compute (x - xk).
        deltax = x - xk;
        
        % 3. Add contribution of the regularization term.
        fmb = fmb + c*(deltax'*deltax);
        gmb = gmb + deltax/etak;
    end
end

%% Utilities to display convergence info.
function displayFinalConvergenceMessage(normstep,tau,stepTol,cause)
%displayFinalConvergenceMessage - Helper function to display final convergence message.
%   displayFinalConvergenceMessage(normstep,tau,stepTol,cause) takes
%   several inputs (described below) and prints out a summary of why the
%   algorithm stopped.
%
%   INPUTS:
%
%   normstep = two norm of the proposed step size.
%   tau      = relative convergence factor for relative convergence test.              
%   stepTol  = relative tolerance on step length. Iterations stop when normstep/tau <= stepTol.
%   cause    = reason for termination of the algorithm.
%
%   Here's what cause means:
%
%   cause = 1 means relative step tolerance reached.
%   cause = 2 means iteration or pass limit reached.
%   cause = 4 means terminated by output function.

    % 1. Explain why iterations stopped.
    fprintf('\n');
    twonormsStr = ['    ',getString(message('stats:classreg:learning:fsutils:fminsgd:FinalConvergenceMessage_TwoNormStep'))];
    fprintf(['     ',twonormsStr,' ','%6.3e\n'], normstep);
    reltwonormStr = getString(message('stats:classreg:learning:fsutils:fminsgd:FinalConvergenceMessage_RelTwoNormStep'));
    fprintf([reltwonormStr,' ','%6.3e, ','TolX =',' ','%6.3e\n'], normstep/tau, stepTol);

    % 2. Explain what the final solution means.
    if ( cause == 1 )
        fprintf([getString(message('stats:classreg:learning:fsutils:fminsgd:Message_StepTolReached')),'\n']);
    elseif ( cause == 2 )
        fprintf([getString(message('stats:classreg:learning:fsutils:fminsgd:Message_IterOrPassLimit')),'\n']);
    elseif ( cause == 4 )
        fprintf([getString(message('stats:classreg:learning:fsutils:fminsgd:Message_StoppedByOutputFcn')),'\n']);
    end
end

function displayConvergenceInfo(pass,iter,favg,infnormgavg,normstep,eta,numprintcalls)
%displayConvergenceInfo - Helper function to display iteration wise convergence info.
%   displayConvergenceInfo(pass,iter,favg,infnormgavg,normstep,eta,numprintcalls)
%   accepts several inputs (described below) and prints out a diagnostic
%   summary of progress made by the optimizer.
%
%   INPUTS:
%
%   pass          = pass number.
%   iter          = iteration number.
%   favg          = average minibatch function value over 'NumPrint' iterations.
%   infnormgavg   = average minibatch infinity norm of gradient over 'NumPrint' iterations.
%   normstep      = two norm of the proposed step size.
%   eta           = learning rate.
%   numprintcalls = number of calls to this function so far.
%
%   We will display convergence info like this:
%
% |=========================================================================================|
% |   PASS   |     ITER     | AVG MINIBATCH | AVG MINIBATCH |   NORM STEP   |      ETA      |
% |          |              |   FUN VALUE   |   NORM GRAD   |               |               |
% |=========================================================================================|
% |        0 |           99 |  2.284657e+00 |  4.883018e-01 |  5.556517e-02 |  1.000000e-01 |
% |        0 |          199 |  1.936235e+00 |  3.616897e-01 |  8.493874e-02 |  1.000000e-01 |
% |        0 |          299 |  1.983044e+00 |  3.905161e-01 |  5.351445e-02 |  1.000000e-01 |
% |        0 |          399 |  1.941715e+00 |  3.712521e-01 |  1.070249e-01 |  1.000000e-01 |
% |        0 |          499 |  2.089548e+00 |  4.046268e-01 |  6.899835e-02 |  1.000000e-01 |
% |        1 |          599 |  2.028357e+00 |  3.660823e-01 |  8.237062e-02 |  1.000000e-01 |
% |        1 |          699 |  1.971403e+00 |  4.171066e-01 |  4.886549e-02 |  1.000000e-01 |
% |        1 |          799 |  1.958866e+00 |  3.996782e-01 |  2.146670e-02 |  1.000000e-01 |
% |        1 |          899 |  2.045281e+00 |  3.862771e-01 |  3.392540e-02 |  1.000000e-01 |
% |        1 |          999 |  1.948637e+00 |  3.886502e-01 |  8.463276e-02 |  1.000000e-01 |
% |        2 |         1099 |  2.013316e+00 |  3.750765e-01 |  6.701066e-02 |  1.000000e-01 |
% |        2 |         1199 |  1.980733e+00 |  3.993497e-01 |  7.040867e-02 |  1.000000e-01 |
% |        2 |         1299 |  2.056670e+00 |  3.925954e-01 |  4.519211e-02 |  1.000000e-01 |
% |        2 |         1399 |  1.939405e+00 |  3.611192e-01 |  4.223361e-02 |  1.000000e-01 |

    % 1. Display header every 20 iterations.
    if ( rem(numprintcalls,20) == 0 )
        fprintf('\n');
        fprintf('|==========================================================================================|\n');
        fprintf('|   PASS   |     ITER     | AVG MINIBATCH | AVG MINIBATCH |   NORM STEP   |    LEARNING    |\n');
        fprintf('|          |              |   FUN VALUE   |   NORM GRAD   |               |      RATE      |\n');
        fprintf('|==========================================================================================|\n');
    end
    
    % 2. Display iteration wise convergence info.
    fprintf('|%9d |%13d |%14.6e |%14.6e |%14.6e |%15.6e |\n', pass, iter, favg, infnormgavg, normstep, eta);    
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
% fval      - current function value for minibatch.
% gradient  - current gradient value for minibatch.
% stepsize  - current stepsize.
%
% OUTPUTS:
% stop = true if optimization iterations should be terminated and false
%        otherwise.

    stop = outfun(x,optimValues,state);    
end

%% Other utility functions.
%=== funAndGrad
function [fmb,gmb] = funAndGrad(x,S,fun,haveGrad)
%funAndGrad - Compute function and gradient on a minibatch.
%   [fmb,gmb] = funAndGrad(x,S,fun,haveGrad) takes a column vector x,
%   minibatch indices S, function handle fun and returns fmb = fun(x,S) and
%   gmb = gradient of fun(x,S) at x. If haveGrad is true then it is assumed
%   that fun can also return the gradient information like:
%
%   [fmb,gmb] = fun(x,S)
%
%   If haveGrad is false, gmb is computed using central finite differences.

    if ( haveGrad )
        [fmb,gmb] = fun(x,S);
    else
        fmb   = fun(x,S);
        myfun = @(z) fun(z,S);
        gmb   = classreg.learning.fsutils.Solver.getGradient(myfun,x);
    end
end