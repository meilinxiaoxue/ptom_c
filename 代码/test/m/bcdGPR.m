function [alpha,g,f,selectioncounts,cause] = bcdGPR(X,y,kfun,diagkfun,varargin)
%BCDGPR Block Coordinate Descent (BCD) based Gaussian Process Regression.
%   alpha = bcdGPR(X,y,kfun,diagkfun) takes a N-by-D matrix of design
%   points X where N is the number of observations and D is the number of
%   predictors, a N-by-1 vector of responses y, a kernel function kfun and
%   computes the solution alpha to the problem:
%
%   (K + sigma^2*eye(N))*alpha = y
%
%   * K is the N-by-N kernel matrix such that K = kfun(X,X) and kfun is
%   a function handle to a function that can be called like this:
%
%       KMN = kfun(XM,XN) 
% 
%   where XM is a M-by-D matrix, XN is a N-by-D matrix and KMN is the
%   M-by-N matrix of kernel products with KMN(i,j) the kernel product
%   between XM(i,:) and XN(j,:).
%
%   * sigma^2 is the residual noise variance of the Gaussian Process with
%   default value 1. You can set a different value using the 'Sigma'
%   name/value parameter described below.
%
%   * diagkfun is a function handle that computes the diagonal of K like
%   this: diagK = diag(K) = diagkfun(X) where diagK is a N-by-1 vector and
%   X is a N-by-D matrix.
%
%   bcdGPR uses a hybrid block coordinate descent (HBCD) algorithm with
%   proximal point modification to compute alpha as the solution to the
%   minimization problem:
%
%   minimize w.r.t alpha: 
%
%   f(alpha) = 0.5*alpha'*(K + sigma^2*eye(N))*alpha - alpha'*y
%
%   Each block during HBCD iterations is selected partly randomly and
%   partly in a greedy fashion (see the 'NumGreedy' name/value pair below).
%
%   [alpha,g] = bcdGPR(X,y,kfun,diagkfun) also returns the gradient of
%   objective function f at the solution alpha.
%
%   [alpha,g,f] = bcdGPR(X,y,kfun,diagkfun) also returns the objective
%   function f at the solution alpha.
%
%   [alpha,g,f,selectioncounts] = bcdGPR(X,y,kfun,diagkfun) also returns a
%   N-by-1 vector selectioncounts such that selectioncounts(j) is the
%   number of times observation j was selected into a block during HBCD
%   iterations.
%
%   [alpha,g,f,selectioncounts,cause] = bcdGPR(X,y,kfun,diagkfun) also
%   returns an integer cause indicating the reason for termination of the
%   algorithm. The meaning of cause is as follows:
%
%       Value of cause          Meaning
%       --------------          -------
%       cause = 0               Gradient norm satisfies tolerance.
%       cause = 1               Step size satisfies step tolerance.
%       cause = 2               Iteration limit reached.
%
%   See the 'Tolerance', 'StepTolerance' and 'MaxIter' name/value pairs.
%
%   [alpha,g,f] = bcdGPR(X,y,kfun,diagkfun,'PARAM','VALUE',...) accepts
%   additional name/value pairs to control the computation of alpha as
%   follows:
%
%      Parameter                Value 
%      'Sigma'                  A positive scalar specifying the noise 
%                               standard deviation of the Gaussian Process. 
%                               Default is 1.
%
%      'BlockSize'              A positive integer q such that 1 <= q <= N. 
%                               Each subproblem in HBCD is of size q. It is
%                               assumed that a q-by-q square matrix can be
%                               stored in memory. Default is min(1000,N).
%
%      'NumGreedy'              A positive integer t such that 1 <= t <= q 
%                               indicating how many indices in the block 
%                               are to be selected in a greedy manner.
%                               Default is 1.
%
%      'SquareCacheSize'        A positive integer p such that 1 <= p <= N 
%                               indicating that it is possible to allocate 
%                               memory for a p-by-p matrix during BCD 
%                               iterations. The total memory consumption 
%                               for intermediate operations is around 
%                               (p^2 + q^2) elements. Default is 1000.
%
%      'Alpha0'                 A N-by-1 vector specifying the initial 
%                               value for alpha. Default is zeros(N,1).
%
%      'Tolerance'              A positive scalar specifying the relative
%                               tolerance on the maximum gradient. Default 
%                               is 1e-3.
%
%      'StepTolerance'          A positive scalar specifying the absolute
%                               tolerance on the step size. Default is 1e-3.
%
%      'MaxIter'                An integer specifying the maximum number of 
%                               BCD iterations. Default is 1000000.
%
%      'Tau'                    A positive scalar for the proximal point
%                               modification term to guarantee global 
%                               convergence. Default is 0.1.
%
%      'Verbose'                A positive integer specifying the verbosity 
%                               level. Valid values are 0 and 1: 
%                               0 - no iterative output is displayed on screen. 
%                               1 - iterative output is displayed on screen.
%                               Default is 0.

%   References:
%      [1] L. Grippo and M. Sciandrone. On the convergence of the block 
%      nonlinear Gauss-Seidel method under convex constraints. Operations 
%      Research Letters, 26, 127-136, 2000.
%      [2] Liefeng Bo and Cristian Sminchisescu. Greedy Block Coordinate 
%      Descent for Large Scale Gaussian Process Regression. arXiv:1206.3238 [cs.LG], 2012.
%      [3] Yu. Nesterov. Efficiency of Coordinate Descent Methods on 
%      Huge-Scale Optimization Problems. SIAM J. Optim., 22(2), 341-362, 2012.

%   Copyright 2014-2015 The MathWorks, Inc.

        % Assume all inputs have been validated.
        
        % 1. How many observations? 
        N = size(X,1);

        % 2. Parse optional name/value pairs.        
            % 2.1 Default parameter values.
            dfltSigma           = 1;
            dfltBlockSize       = min(1000,N);
            dfltNumGreedy       = 1;
            dfltSquareCacheSize = 1000;
            dfltAlpha0          = zeros(N,1);
            dfltTolerance       = 1e-3;
            dfltStepTolerance   = 1e-3;
            dfltMaxIter         = 1000000;
            dfltTau             = 0.1;
            dfltVerbose         = 0;
    
            % 2.2 Optional parameter names and their default values.
            paramNames = {  'Sigma',   'BlockSize',   'NumGreedy',   'SquareCacheSize',   'Alpha0',   'Tolerance',   'StepTolerance',   'MaxIter',   'Tau',   'Verbose'};
            paramDflts = {dfltSigma, dfltBlockSize, dfltNumGreedy, dfltSquareCacheSize, dfltAlpha0, dfltTolerance, dfltStepTolerance, dfltMaxIter, dfltTau, dfltVerbose};
            
            % 2.3 Parse optional parameter name/value pairs.
            [sigma,q,t,p,alpha0,eta,stepTol,maxIter,tau,verbose] = internal.stats.parseArgs(paramNames,paramDflts,varargin{:});
           
        % 3. Call BCD.
        [alpha,g,f,selectioncounts,cause] = dobcd(X,y,kfun,diagkfun,sigma,q,t,p,alpha0,eta,tau,verbose,stepTol,maxIter);        
        
end % end of bcdGPR.

function [alpha,g,f,selectioncounts,cause] = dobcd(X,y,kfun,diagkfun,sigma,q,t,p,alpha0,eta,tau,verbose,stepTol,maxIter)
% INPUTS:
% X        = N-by-D matrix of predictors.
% y        = N-by-1 response vector.
% kfun     = function handle to compute kernel products: KMN = kfun(XM,XN)
% diagkfun = function handle to compute diagonal of K(X,X): diagK = diagkfun(X)
% sigma    = noise standard deviation for GP.
% q        = block size.
% t        = number of greedy selections out of q.
% p        = square cache size.
% alpha0   = initial value for alpha.
% eta      = relative convergence tolerance on the gradient.
% tau      = scalar multiplier for proximal point modification.
% verbose  = 0 or 1.
% stepTol  = tolerance on step size during BCD iterations.
% maxIter  = maximum number of BCD iterations.
%
% OUTPUTS:
% alpha           = final alpha value.
% g               = gradient of objective function at alpha.
% f               = objective function value at alpha.
% selectioncounts = N-by-1 vector indicating how many times each point was selected into a block.
% cause           = integer code indicating the reason for termination of BCD iterations.
%
%   VALUE of cause        MEANING
%   cause = 0             Relative gradient norm is < eta.
%   cause = 1             Norm of the step size is < stepTol.
%   cause = 2             Iteration limit reached.
%
% Assume inputs have been validated.

    % 1. Initial gradient.
    if all(alpha0 == 0)
        % 1.1 Exploit the case when all initial alpha's are 0.
        g = -y;
    else
        % 1.2 Compute K*alpha0.
        g = computeKernelMatrixProduct(kfun,X,X,alpha0,p);

        % 1.3 Compute initial g.
        g = g + sigma^2*alpha0 - y;
    end
    
    % 2. Create useful variables.
    %    N               = Number of rows in X.
    %    L               = N-by-1 vector that is a list of indices 1 to N.
    %    B0              = N-by-1 logical vector - the initial state of 
    %                      selected block B when block selection begins.
    %    R0              = N-by-1 logical vector - the initial state of 
    %                      inactive block R when block selection begins.
    %    crit            = N-by-2 matrix such that first column of crit 
    %                      will hold the block selection function (eq. 304) 
    %                      and the second column will hold L. Second column
    %                      of crit does not change.
    %    selectioncounts = N-by-1 vector indicating how many times a
    %                      particular point was selected into B over all 
    %                      iterations.
    %    maxabsg0        = Initial gradient norm.
    %
    % Initially, all points are in R. When we select a block of size q then
    % q points are moved from R into B.
    N               = size(X,1);
    L               = (1:N)';    
    B0              = false(N,1);
    R0              =  true(N,1);
    crit            = zeros(N,2);
    crit(:,2)       = L;
    selectioncounts = zeros(N,1);
    maxabsg0        = max(abs(g));
    initGradSize    = max(1,maxabsg0);
    
    % 3. Compute diagonal of (K + sigma^2*I + tau*I) - needed for computing
    % ibest, see eq. 305.
    diagKPlusSigma2Tau = diagkfun(X) + sigma^2 + tau;
    
    % 4. Begin iterations.
    found = false;
    alpha = alpha0;    
    iter  = 0;    
    while ( found == false )
        % 5. Active set selection.
        
        % 5.1 Select first t elements greedily and the rest q-t in a
            % random fashion.
                
                % 5.1.1 Given the current alpha and g, which coordinate of 
                % alpha when optimized will give the largest decrease? 
                % Select this coordinate in the active set, update alpha 
                % and g to the new optimized values and repeat. See eq. 304.
                gbar     = g;
                % alphabar = alpha;                
                R        = R0;
                B        = B0;                
                for i = 1:t
                    crit(:,1) = (gbar.^2)./diagKPlusSigma2Tau;
                    critR     = crit(R,:);
                    [~,idx]   = max(critR(:,1));
                    bestidx   = critR(idx,2);
                    
                    B(bestidx) = true;
                    R(bestidx) = false;
                    
                    deltaAlphaBar     = -gbar(bestidx)/diagKPlusSigma2Tau(bestidx);
                    
                    % alphabar(bestidx) = alphabar(bestidx) + deltaAlphaBar;
                    
                    gbar              = gbar + kfun(X,X(bestidx,:))*deltaAlphaBar;
                    gbar(bestidx)     = -tau*deltaAlphaBar;
                end
        
        % 5.2 Select (q-t) indices at random from R which has (N-t) true elements.
        if ( q > t )
            Lminust    = L(R);
            randidx    = Lminust(randsample(N-t,q-t));
            R(randidx) = false;
            B(randidx) = true;
        end
        
        % 6. Update alpha for indices in B.
        selectioncounts(B) = selectioncounts(B) + 1;
        KBB                = kfun(X(B,:),X(B,:));
        KBB(1:q+1:q*q)     = KBB(1:q+1:q*q) + sigma^2 + tau;
        [LBB,status]   = chol(KBB,'lower');
        if ( status == 0 )
            % Cholesky factorization worked.
            deltaAlpha = -(LBB' \ (LBB \ g(B)));
        else
            % Cholesky factorization did not work.
            deltaAlpha = -(KBB \ g(B));
        end
        alpha(B)       = alpha(B) + deltaAlpha;
        
        % 7. Update gradient vector. Note that R and B are disjoint and so
        % nabla^2_{RB} f = KRB. See eq. 301.
        g(B) = -tau*deltaAlpha;
        g(R) = g(R) + computeKernelMatrixProduct(kfun,X(R,:),X(B,:),deltaAlpha,p);                
        
        % 8. Iterative progress.
        maxabsg  = max(abs(g));        
        stepsize = norm(deltaAlpha);
        if ( verbose == 1 )            
            objfun   = 0.5*alpha'*(g - y);
            displayConvergenceInfo(iter,maxabsg,stepsize,objfun);
        end
        
        % 9. Convergence test.
        if ( maxabsg < eta*initGradSize )
            found = true;
            % Local minimum found.
            cause = 0;           
        elseif ( stepsize < stepTol )
            found = true;
            % Step tolerance reached.
            cause = 1;
        elseif ( iter > maxIter )
            found = true;
            % Iteration limit reached.
            cause = 2;
        end
           
        % 10. Display final convergence message.
        if ( found == true )
            f = 0.5*alpha'*(g - y);
            if ( verbose == 1 )
                displayFinalConvergenceInfo(maxabsg,initGradSize,eta,stepsize,stepTol,cause);
            end
        end
        
        % 11. Update iteration counter.
        iter = iter + 1;
    end
    
end % end of dobcd.

function displayConvergenceInfo(iter,maxabsg,stepsize,objfun)
% Helper function to display iterative progress.
%
% iter     = iteration index.
% maxabsg  = current maximum absolute gradient.
% stepsize = most recent step size - 2 norm.
% objfun   = Value of 0.5*alpha'*(K+sigma^2*I)*alpha - alpha'*y.

%  We will display convergence info like this:
%
% |==============================================================|
% |  Iteration  |  Max Gradient  |   Step Size   |   Objective   |
% |==============================================================|
% |           0 |   6.162084e+01 |  2.495652e+00 | -1.278728e+03 |
% |           1 |   5.107846e+01 |  2.166302e+00 | -2.236142e+03 |
% |           2 |   4.540634e+01 |  1.877544e+00 | -2.955580e+03 |
% |           3 |   4.238814e+01 |  1.648336e+00 | -3.510137e+03 |
% |           4 |   4.092709e+01 |  1.390203e+00 | -3.904727e+03 |
% |           5 |   3.795027e+01 |  1.247687e+00 | -4.222473e+03 |
% |           6 |   3.296123e+01 |  1.031793e+00 | -4.439663e+03 |

    if ( rem(iter,20) == 0 )
        % Display header.
        fprintf('\n');
        fprintf('|==============================================================|\n');
        fprintf('|  Iteration  |  Max Gradient  |   Step Size   |   Objective   |\n');
        fprintf('|==============================================================|\n');
    end

    % Display iteration wise convergence info.    
    fprintf('|%12d |%15.6e |%14.6e |%14.6e |\n', iter, maxabsg, stepsize, objfun);
    
end % end of displayConvergenceInfo.

function displayFinalConvergenceInfo(maxabsg,initGradSize,eta,stepsize,stepTol,cause)
% Helper function to display final convergence message.
%
% maxabsg      = infinity norm of the gradient.
% initGradSize = initial size of the gradient.
% eta          = relative tolerance on gradient norm.
% stepsize     = two norm of the step size.
% stepTol      = tolerance on step size.
% cause        = reason for termination.

    % Explain why iterations stopped.
    fprintf('\n');
    relInfNormGradientStr = getString(message('stats:classreg:learning:gputils:bcdGPR:MessageRelativeInfinityNormFinalGradient'));
    givenToleranceStr     = getString(message('stats:classreg:learning:gputils:bcdGPR:MessageGivenTolerance'));    
    twoNormStepSizeStr    = getString(message('stats:classreg:learning:gputils:bcdGPR:MessageTwoNormFinalStep'));
    givenStepToleranceStr = getString(message('stats:classreg:learning:gputils:bcdGPR:MessageGivenStepTolerance'));    
    fprintf('%s = %9.3e, %s = %9.3e\n',relInfNormGradientStr                    ,maxabsg/initGradSize,[givenToleranceStr,'     '],eta    );
    fprintf('%s = %9.3e, %s = %9.3e\n',[twoNormStepSizeStr,'                  '],stepsize            , givenStepToleranceStr     ,stepTol);
    
    % Explain what the solution means.
    if ( cause == 0 )
        msg = getString(message('stats:classreg:learning:gputils:bcdGPR:MessageGradientSatisfiesTolerance'));
        fprintf('%s\n',msg);
    elseif ( cause == 1 )
        msg = getString(message('stats:classreg:learning:gputils:bcdGPR:MessageStepSizeSatisfiesTolerance'));
        fprintf('%s\n',msg);
    elseif ( cause == 2 )
        msg = getString(message('stats:classreg:learning:gputils:bcdGPR:MessageIterationLimitReached'));
        fprintf('%s\n',msg);
    end
    
end % end of displayFinalConvergenceInfo.

function z = computeKernelMatrixProduct(kfun,XM,XN,alpha,q)
% kfun  = function handle to compute kernel products.
% XM    = M-by-D matrix of design points.
% XN    = N-by-D matrix of design points.
% alpha = N-by-1 vector.
% q     = chunk size such that q*q elements can be stored in memory.
%
% Let KMN = kfun(XM,XN). Then KMN is a M-by-N matrix. This function 
% computes:
%
% z = KMN*alpha = M-by-1 vector.
%
% by processing a block of s rows of KMN at a time such that the memory
% consumed by the block of rows is approximately q*q. Each row of KMN is of
% length N and so s such rows has N*s elements. If N*s is approximately
% equal to q*q then s must be around s = q*q/N.

    % 1. Get M and N.
    M = size(XM,1);
    N = size(XN,1);

    % 2. Output z is a M-by-1 vector.
    z = zeros(M,1);

    % 3. How many rows should be processed at a time? s >= 1.
    s = max(1,floor(q*q/N));

    % 4. Excluding last few rows, how many row chunks of size s?
    nchunks = floor(M/s);
    
    % 5. Process each chunk of size s. For chunk r, row indices are:
    % (r-1)*s + 1 : r*s
    for r = 1:nchunks
        rowidx    = (r-1)*s + 1 : r*s;        
        Kslice    = kfun(XM(rowidx,:),XN);
        z(rowidx) = Kslice*alpha;        
    end
    
    % 6. Process last few rows.
    rowidx    = nchunks*s + 1 : M;
    if ~isempty(rowidx)
        Kslice    = kfun(XM(rowidx,:),XN);
        z(rowidx) = Kslice*alpha;
    end

end % end of computeKernelMatrixProduct.