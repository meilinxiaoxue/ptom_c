function [A,C,CProfile,exitFlag] = selectActiveSet(X,kfun,diagkfun,varargin)
%selectActiveSet Utility for selecting an active set of observations.
%   A = selectActiveSet(X,KFUN,DIAGKFUN) takes a N-by-D matrix of design
%   points X where N is the number of observations and D is the number of
%   predictors, a function handle KFUN to evaluate the kernel, a function
%   handle DIAGKFUN to evaluate the kernel diagonal and returns an active
%   set A using randomized greedy forward selection and a specified active
%   set selection method (see 'ActiveSetMethod' name/value pair below).
%   Output A is an integer vector with elements from 1 to N indicating the
%   sequence of points selected into the active set.
%
%   o KFUN is a function handle to a function that can be called like this:
%
%       KMN = KFUN(XM,XN)
%
%   where XM is a M-by-D matrix, XN is a N-by-D matrix and KMN is the
%   M-by-N matrix of kernel products with KMN(i,j) the kernel product
%   between XM(i,:) and XN(j,:).
%
%   o DIAGKFUN is a function handle to a function that can be called like this:
%
%       diagKN = DIAGKFUN(XN)
%
%   where XN is a N-by-D matrix and diagKN is a N-by-1 vector of kernel
%   products with diagKN(i) the kernel product between XN(i,:) and XN(i,:).
%   If DIAGKFUN is empty, the kernel diagonal is evaluated (less efficiently) 
%   using KFUN.
%
%   [A,C] = selectActiveSet(X,KFUN,DIAGKFUN) also returns a scalar
%   criterion C that measures the goodness of the selected active set A.
%   The meaning of C depends on the 'ActiveSetMethod' name/value pair below:
%
%       'ActiveSetMethod'   Meaning of criterion C
%       
%       'SGMA'            - Approximation error in the RKHS norm between the 
%                           true kernel function and its approximation
%                           using the active set A - smaller is better.
%
%       'Entropy'         - Total reduction in differential entropy for the 
%                           active set A - larger is better.
%
%       'Likelihood'      - Subset of regressors based approximation to the 
%                           log likelihood of a Gaussian Process Regression
%                           (GPR) model using the active set A - larger is
%                           better.
%
%   [A,C,CPROFILE] = selectActiveSet(X,KFUN,DIAGKFUN) also returns the
%   values of the criterion C as the active set grows from its initial size
%   to its final size. CPROFILE(1) is the value of C for the initial active
%   set and CPROFILE(end) is the value of C for the final active set.
%
%   [A,C,CPROFILE,EXITFLAG] = selectActiveSet(X,KFUN,DIAGKFUN) also returns
%   a scalar EXITFLAG that indicates the reason for termination of the
%   active set selection procedure. The meaning of EXITFLAG is described
%   below:
%
%       Value of EXITFLAG   Reason for termination
%
%           0             - Criterion C or change in criterion C is below
%                           the specified 'Tolerance' (see the 'Tolerance'
%                           name/value pair below).
%
%           1             - Desired active set size reached (see the
%                           'ActiveSetSize' name/value pair below).
%
%           2             - Cannot continue active set selection - kernel 
%                           function is not positive definite.
%
%   [A,C,CPROFILE,EXITFLAG] = selectActiveSet(X,KFUN,DIAGKFUN,'PARAM','VALUE',...) 
%   accepts additional name/value pairs as follows:
%
%      Parameter                Value
%
%      'ActiveSetMethod'        A string specifying the active set selection 
%                               method. Choices are 'SGMA', 'Entropy' or
%                               'Likelihood'. Default is 'SGMA'. A short
%                               description of each active set selection
%                               method is given below:
%
%           Name           Description
%           'SGMA'       - The method 'SGMA' stands for sparse greedy matrix 
%                          approximation. 'SGMA' creates an approximation to
%                          the true kernel function using an active set and
%                          minimizes the approximation error between the true
%                          kernel function and its approximation in the RKHS
%                          norm. This selection method is generally applicable 
%                          to kernel based methods.
%
%           'Entropy'    - The method 'Entropy' is also known by the name
%                          informative vector machine (IVM). This method is
%                          applicable to Gaussian Process Regression (GPR).
%                          The reduction in differential entropy of the
%                          Gaussian process latent variable having observed
%                          the corresponding response variable is used as a
%                          criterion for selection of observations into the
%                          active set.
%
%           'Likelihood' - This method is applicable to Gaussian Process
%                          Regression (GPR). A subset of regressors based
%                          approximation to the marginal likelihood of a
%                          GPR model is used as a measure of goodness of an
%                          active set. The criterion for selection of a new
%                          point into the active set is the change in the
%                          log likelihood upon adding a new point to the
%                          active set.
%
%      'ActiveSetSize'          An integer M specifying the desired size of
%                               active set A. If N = size(X,1) then M must
%                               be between 1 and N. Default is min(1000,N).
%
%                               The actual size of the returned active set
%                               may be smaller than the requested size M if
%                               active set selection converges early. For
%                               'ActiveSetMethod' equal to 'Likelihood',
%                               the function could return an active set
%                               that maximizes the log likelihood - but we
%                               don't do that yet.
%
%      'InitialActiveSet'       A vector of integers A0 with elements from 
%                               1,2,...,N indicating the initial value of
%                               A. Number of elements in A0 must be between
%                               1 and M. Default value is [].
%
%      'RandomSearchSetSize'    An integer J specifying the size of random
%                               search set for forward greedy selection.
%                               Default value is 59.
%
%                               The memory required for all active set
%                               selection methods is O(N*M). The amount of
%                               computation required is O(N*M^2*J) for
%                               'ActiveSetMethod' equal to 'SGMA' and
%                               'Likelihood'. The amount of computation
%                               required is O(N*M^2) for 'ActiveSetMethod'
%                               equal to 'Entropy'.
%
%      'SearchType'             A string - either 'Sparse' or 'Exhaustive'. 
%                               If 'Exhaustive', a new candidate for
%                               inclusion into the active set is chosen
%                               from all available points. Default is
%                               'Sparse'.
%
%      'Tolerance'              A real scalar TOL that specifies a relative
%                               tolerance for detecting convergence. 
%                               Default is 1e-2.
%
%                               For 'ActiveSetMethod' equal to 'SGMA',
%                               active set selection stops when the value
%                               of positive criterion C drops below
%                               max(1,C0)*TOL where C0 is the positive
%                               criterion value for the initial active set
%                               A0.
%
%                               For 'ActiveSetMethod' equal to 'Entropy' or
%                               'Likelihood', if the criterion changes from
%                               C to C + DELTAC then active set selection
%                               stops when abs(DELTAC) drops below
%                               abs(C + DELTAC)*TOL.
%
%      'Verbose'                Either true (or 1) or false (or 0). If 
%                               true, iterative progress of active set
%                               selection is displayed. Default is false.
%
%      'Sigma'                  A positive scalar specifying the noise 
%                               standard deviation of the Gaussian Process
%                               Regression (GPR) model. 'Sigma' is not used
%                               for 'ActiveSetMethod' equal to 'SGMA'.
%                               Default is 1.
%
%      'ResponseVector'         A vector Y of length N where N = size(X,1). 
%                               This is used as the response vector for a
%                               Gaussian Process Regression (GPR) model if
%                               'ActiveSetMethod' is 'Likelihood'. If the
%                               GPR model has an explicity basis term then
%                               supply 'ResponseVector' as (Y - H*BETA)
%                               where H is the basis matrix, BETA is a
%                               vector of coefficients for the explicit
%                               basis and Y is the response vector. Y is
%                               not used for other active set selection
%                               methods. Default is ones(N,1).
%
%      'Regularization'         A positive scalar TAU such that low rank 
%                               matrix factorization in 'SGMA' and
%                               'Likelihood' uses KAA + TAU^2*I instead of
%                               KAA where KAA is the square kernel matrix
%                               evaluated over the active set.
%                               Default is 0.
%
%     Example:
%   
%       % 1. Generate data from 2 Gaussians.
%       N  = 10000;
%       X1 = mvnrnd([0,0],0.5*eye(2),N);
%       X2 = mvnrnd([2,2],0.5*eye(2),N);
%       plot(X1(:,1),X1(:,2),'r.');
%       hold on;
%       plot(X2(:,1),X2(:,2),'b.');
%
%       % 2. Use the squared exponential kernel function.
%       kfun     = @(XM,XN) exp( -0.5*bsxfun(@plus,bsxfun(@plus,sum(XM.^2,2),-2*XM*XN'),sum(XN.^2,2)') );
%       diagkfun = @(XN) ones(size(XN,1),1);
%
%       % 3. Do active set selection.
%       X = [X1;X2];
%       [A,E,EProfile] = selectActiveSet(X,kfun,diagkfun,'ActiveSetSize',100,'Verbose',1,'Tolerance',1e-3,'ActiveSetMethod','SGMA');
%
%       % 4. Plot selected points and the size of active set vs. the approximation error.
%       subplot(2,1,1);
%       plot(X1(:,1),X1(:,2),'r.');
%       hold on;
%       plot(X2(:,1),X2(:,2),'b.');
%       plot(X(A,1),X(A,2),'go');
%       legend('Group 1','Group 2','Selected points');
%       subplot(2,1,2);
%       plot(0:length(A),EProfile,'ro-');
%       xlabel('Active set size');
%       ylabel('Approximation error');

%   References:
%      [1] Alex J. Smola and Bernhard Sch\"{o}kopf. Sparse Greedy Matrix
%      Approximation for Machine Learning. Proceedings of the Seventeenth
%      International Conference on Machine Learning, 911-918, 2000.
%      [2] Neil Lawrence, Matthias Seeger and Ralf Herbrich. Fast Sparse
%      Gaussian Process Methods: The Informative Vector Machine. Advances
%      in Neural Information Processing Systems 15, 625-632, 2003.
%      [3] Carl Edward Rasmussen and Christopher K. I. Williams. Gaussian
%      Processes for Machine Learning. The MIT Press, 2005.

%   Copyright 2014-2015 The MathWorks, Inc.

        % 1. Validate X.
        X = validateX(X);
        
        % 2. Validate kfun and diagkfun. If diagkfun is [], we will compute
        % the diagonal of the kernel matrix (less efficiently) using kfun.
        kfun = validatekfun(kfun);
        if ~isempty(diagkfun)
            diagkfun = validatediagkfun(diagkfun);            
        end
        
        % 3. Supported active set methods.
        ActiveSetMethodSGMA       = 'SGMA';
        ActiveSetMethodEntropy    = 'Entropy';
        ActiveSetMethodLikelihood = 'Likelihood';
        
        % 4. Supported search types.
        SearchTypeSparse     = 'Sparse';
        SearchTypeExhaustive = 'Exhaustive';
        
        % 5. Parse optional name/value pairs.
        
            % 5.1 Default parameter values.
            N                       = size(X,1);
            dfltActiveSetMethod     = ActiveSetMethodSGMA;
            dfltActiveSetSize       = min(1000,N);
            dfltInitialActiveSet    = zeros(0,1);
            dfltRandomSearchSetSize = 59;
            dfltSearchType          = SearchTypeSparse;
            dfltTolerance           = 1e-2;
            dfltVerbose             = false;
            dfltSigma               = 1;
            dfltResponseVector      = ones(N,1);
            dfltRegularization      = 0;
            
            % 5.2 Optional parameter names and their default values.
            paramNames = {  'ActiveSetMethod',   'ActiveSetSize',   'InitialActiveSet',   'RandomSearchSetSize',   'SearchType',   'Tolerance',   'Verbose',   'Sigma',   'ResponseVector',   'Regularization'};
            paramDflts = {dfltActiveSetMethod, dfltActiveSetSize, dfltInitialActiveSet, dfltRandomSearchSetSize, dfltSearchType, dfltTolerance, dfltVerbose, dfltSigma, dfltResponseVector, dfltRegularization};
            
            % 5.3 Parse optional parameter name/value pairs.
            [activemethod,M,A0,J,searchtype,tol,verbose,sigma,y,tau] = internal.stats.parseArgs(paramNames,paramDflts,varargin{:});
        
        % 6. Validate optional parameter values.
        activemethod = internal.stats.getParamVal(activemethod,{ActiveSetMethodSGMA,ActiveSetMethodEntropy,ActiveSetMethodLikelihood},'ActiveSetMethod');
        M            = validateActiveSetSize(M,N);
        A0           = validateInitialActiveSet(A0,M,N);
        J            = validateRandomSearchSetSize(J,searchtype);
        searchtype   = internal.stats.getParamVal(searchtype,{SearchTypeSparse,SearchTypeExhaustive},'SearchType');
        tol          = validateTolerance(tol);
        verbose      = validateVerbose(verbose);
        sigma        = validateSigma(sigma);
        y            = validateResponseVector(y,N);
        tau          = validateRegularization(tau);
        
        % 7. Is this "sparse" greedy selection?
        if strcmpi(searchtype,SearchTypeSparse)
            issparsesearch = true;
        else
            issparsesearch = false;
        end
        
        % 8. Call appropriate active set selection method.
        switch lower(activemethod)
            case lower(ActiveSetMethodSGMA)
                [A,C,CProfile,exitFlag] =       selectActiveSetSGMA(X,kfun,diagkfun,M,A0,J,issparsesearch,tol,verbose,tau);
            case lower(ActiveSetMethodEntropy)
                [A,C,CProfile,exitFlag] =    selectActiveSetEntropy(X,kfun,diagkfun,M,A0,J,issparsesearch,tol,verbose,sigma);
            case lower(ActiveSetMethodLikelihood)
                [A,C,CProfile,exitFlag] = selectActiveSetLikelihood(X,y,kfun,diagkfun,M,A0,J,issparsesearch,tol,verbose,sigma,tau);
        end
end % end of selectActiveSet.

% Utility function to compute kernel diagonal without diagkfun.
function diagK = computeKernelDiag(X,kfun)
% X = N-by-D matrix of predictors.
% kfun = function handle that can be called like this: KMN = kfun(XM,XN).
    N     = size(X,1);
    diagK = zeros(N,1);
    for i = 1:N
        diagK(i) = kfun(X(i,:),X(i,:));
    end
end

% Utility function to do SGMA based active set selection.
function [A,EA,EAProfile,exitFlag] = selectActiveSetSGMA(X,kfun,diagkfun,M,A0,J,issparsesearch,tol,verbose,tau)
% Assume inputs have been validated. Implementation details are given in
% section 6.2.1.2 of the GPR theory spec. The symbols used here are
% described there in detail.
%
% INPUTS:
%   X              = N-by-D matrix where N is the number of observations.
%   kfun           = function handle to evaluate the kernel function - can be called like KMN = kfun(XM,XN). 
%   diagkfun       = function handle to evaluate diagonal of kernel function - can be called like diagKN = diagkfun(XN).
%   M              = desired active set size.
%   A0             = initial active set.
%   J              = random search set size.
%   issparsesearch = true if we want to do a sparse search and false otherwise.
%   tol            = tolerance for detecting convergence.
%   verbose        = either true or false.
%   tau            = regularization strength for low rank matrix factorization. KAA gets replaced by KAA + tau^2*I.
%
% OUTPUTS:
%   A         = selected active set.
%   EA        = approximation error in the RKHS norm between the true kernel function and its approximation using A.
%   EAProfile = evolution of EA as active set grows from A0 to A.
%   exitFlag  = integer code indicating reason for termination:
%
%       Value of exitFlag        Reason for termination
%       -----------------        ----------------------
%           0                    EA <= max(1,EA0)*tol where EA0 is the value of EA using A0.
%           1                    Active set size M reached.
%           2                    Numerical instability detected.

    % 1. How many observations do we have?
    N = size(X,1);

    % 2. Initialize the active and rejected sets.
    A  = A0;
    R  = setdiff((1:N)',A0);
    
    % 3. Number of elements in the active and rejected sets.
    nA = length(A);
    nR = length(R);
    
    % 4. Initialize diagonal of kernel matrix.
    if isempty(diagkfun)
        diagK = computeKernelDiag(X,kfun);        
    else
        diagK = diagkfun(X);
    end
    
    % 5. Quantity that gets updated when active set changes. We preallocate
    % M columns here but for active set A of size nA only columns 1:nA of
    % TA are useful.
    TA = zeros(N,M);
    
    % 6. Initial computation of TA and EA. Quantities A, R, nA, nR, TA, EA
    % are always kept in sync. Save initial approximation error in E0 for
    % convergence check.
    if isempty(A)
        TA(:,1:nA)       = zeros(N,0);
        EA               = sum(diagK);
    else
        KXA              = kfun(X,X(A,:));        
        KAA              = KXA(A,:);
        KAA(1:nA+1:nA^2) = KAA(1:nA+1:nA^2) + tau^2;
        [LA,status]      = chol(KAA,'lower');
        if ( status ~= 0 )
            % Cholesky factorization didn't work.
            error(message('stats:classreg:learning:gputils:selectActiveSet:CannotInitializeActiveSetSelection'));
        end
        
        TA(:,1:nA)  = KXA / LA';
        sumdiagKHat = sum(sum(TA(:,1:nA).^2,1));
        EA          = sum(diagK) - sumdiagKHat;
    end
    EA0             = EA;
    
    % 7. Approximation error as the active set grows to its final size. 
    % Return right away if nA is equal to M.
    EAProfile    = zeros(M - nA + 1, 1);
    EAProfile(1) = EA0;
    if ( nA == M )
        % Active set size reached.
        exitFlag = 1;
        return;
    end
    
    % 8. Do randomized greedy forward selection iterations. index is 2
    % below because we will store EAProfile(2) next. isposdef is a flag
    % that marks if iterations can be continued in a numerically stable
    % manner. If not, we set isposdef to false.
    found    = false;
    index    = 2;
    isposdef = true;
    iter     = 0;
    
    while (found == false)
        % 8.1 Select a random subset of R of length J.
        if issparsesearch && (nR > J)
            Jset = R(randsample(nR,J),1);            
        else
            Jset = R;
        end
        lenJset = length(Jset);
        
        % 8.2 Compute change in EA on adding points from Jset to A. Save
        % info about best point found so far. See eq. 79 in GPR theory
        % spec. Quantities needed for updating A, TA and EA are ibest,
        % ubest, vbest and Deltabest. See eq. 82 eq. 65 in GPR theory spec.
        % If we are doing a sparse search, J is typically small and so we
        % can do these computations in matrix form without increasing the
        % memory consumption by a lot.
        if issparsesearch
            % J is probably small.
             
            % 8.2.1 Compute improvement vector Deltavec.
            % Here's a list of the sizes of the various matrices below:
            %
            %   Matrix                       Size
            %   TA(:,1:nA)                   N-by-nA
            %   KXJset                       N-by-J
            %   wmat                         nA-by-J
            %   umat                         N-by-J
            %   vvec                         J-by-1
            %   Deltavec                     J-by-1
            %            
            KXJset   = kfun(X,X(Jset,:));
            wmat     = TA(Jset,1:nA)';
            umat     = TA(:,1:nA)*wmat - KXJset;
            %  A clever way of doing: vvec = diagK(Jset) - sum(wmat.^2,1)' + tau^2;
            vvec     = -umat(sub2ind([N,lenJset],Jset,(1:lenJset)')) + tau^2;
            Deltavec = sum(umat.^2,1)'./vvec;
            
            % 8.2.2 Theoretically, all elements of vvec should be > 0 since
            % the kernel function is positive definite. Get indices where
            % vvec <= 0 or when Deltavec is NaN. For such points, reset the
            % value of Deltavec to 0 to prevent such points from being
            % selected into the active set.
            badidx = (vvec <= 0) | isnan(Deltavec);
            if any(badidx)
                Deltavec(badidx) = 0;
            end
            
            % 8.2.3 Compute point that gives the best reduction in EA.
            [Deltabest,idx] = max(Deltavec);            
            ibest           = Jset(idx);
            ubest           = umat(:,idx);
            vbest           = vvec(idx);
        else
            % J may be big.
                        
            Deltabest = -Inf;
            for i = Jset'                
                % 8.2.1 Compute improvement Delta for current point i.
                ki    = kfun(X,X(i,:));
                w     = TA(i,1:nA)';
                u     = TA(:,1:nA)*w - ki;
                % It turns out that we can replace v  = diagK(i) - w'*w + tau^2 by:
                v     = -u(i) + tau^2;
                Delta = (u'*u)/v;
                
                % 8.2.2 Theoretically, v should be > 0 since the kernel
                % function is positive definite. If v <= 0 or Delta is NaN,
                % reset Delta to 0 to prevent such points from being
                % included into the active set.
                if ( v <= 0 || isnan(Delta) )
                    Delta = 0;
                end
                
                % 8.2.3 Update "best" so far quantities.
                if ( Delta >= Deltabest )
                    Deltabest = Delta;
                    ibest     = i;
                    ubest     = u;
                    vbest     = v;
                end
            end
        end % end of if.
        
        % 8.3 If vbest is <= 0 or if Deltabest is NaN, mark isposdef as
        % false. When isposdef is false, we terminate active set selection.
        % Also ensure that vbest and Deltabest are >= 0.
        if ( vbest <= 0 || isnan(Deltabest) )
            isposdef = false;
        end
        vbest        = max(0,vbest);
        Deltabest    = max(0,Deltabest);
        
        % 8.4 Update A, R, TA, EA, nA and nR only if isposdef is true.
        if isposdef            
            % 8.4.1 Update A, R.
            A  = [A;ibest]; %#ok<AGROW>
            R  = setdiff(R,ibest);
            
            % 8.4.2 Update TA and EA. By definition, EA is >= 0.
            TA(:,nA+1) = -ubest/sqrt(vbest);
            EA         = max(0,EA - Deltabest);
            
            % 8.4.3 Update nA and nR.
            nA = length(A);
            nR = length(R);       
            
            % 8.4.4 Update EA profile.
            EAProfile(index) = EA;
            index            = index + 1;
        end                
        
        % 8.5 Compute relative approximation error.
        relEA = EA/max(1,EA0);
        
        % 8.6 Display convergence info if needed.
        if verbose            
            displayConvergenceInfo(iter,ibest,nA,EA,relEA,lenJset);
        end
        
        % 8.7 Have we converged?
        if ( relEA <= tol || nA == M || ~isposdef )
            found = true;            
            % 8.7.1 If we haven't grown to size M, delete extra elements
            % from end of EAProfile.
            EAProfile(nA-length(A0)+2:end) = [];            
            % 8.7.2 Why did the algorithm stop?            
            if ( relEA <= tol )
                exitFlag = 0;
            elseif ( nA == M )
                exitFlag = 1;
            elseif ~isposdef
                exitFlag = 2;
            end            
            % 8.7.3 Display reason for termination.
            if verbose
                displayFinalConvergenceInfo(nA,relEA,M,tol,exitFlag);
            end
        end
        
        % 8.8 Update iteration counter.
        iter = iter + 1;
        
    end % end of while.
    
end % end of selectActiveSetSGMA.

% Utility function to do Entropy based active set selection.
function [A,sumDeltabest,sumDeltabestProfile,exitFlag] = selectActiveSetEntropy(X,kfun,diagkfun,M,A0,J,issparsesearch,tol,verbose,sigma) 
% Assume inputs have been validated. Implementation details are given in
% section 6.3.1.2 of the GPR theory spec. The symbols used here are
% described there in detail.
%
% INPUTS:
%   X              = N-by-D matrix where N is the number of observations.
%   kfun           = function handle to evaluate the kernel function - can be called like KMN = kfun(XM,XN). 
%   diagkfun       = function handle to evaluate diagonal of kernel function - can be called like diagKN = diagkfun(XN).
%   M              = desired active set size.
%   A0             = initial active set.
%   J              = random search set size.
%   issparsesearch = true if we want to do a sparse search and false otherwise.
%   tol            = tolerance for detecting convergence.
%   verbose        = either true or false.
%   sigma          = noise standard deviation of the Gaussian Process Regression (GPR) model.
%
% OUTPUTS:
%   A                   = selected active set.
%   sumDeltabest        = total reduction in differential entropy using active set A.
%   sumDeltabestProfile = evolution of sumDeltabest as active set grows from A0 to A.
%   exitFlag            = integer code indicating reason for termination:
%
%       Value of exitFlag        Reason for termination
%       -----------------        ----------------------
%           0                    Deltabest <= tol*sumDeltabest where Deltabest is the increment to current sumDeltabest.
%           1                    Active set size M reached.
%           2                    Numerical instability detected.

    % 1. How many observations do we have?
    N = size(X,1);    

    % 2. Initialize the active and rejected sets.
    A = A0;
    R = setdiff((1:N)',A0);
    
    % 3. Number of elements in the active and rejected sets.
    nA = length(A);
    nR = length(R);
    
    % 4. Initialize diagonal of kernel matrix.
    if isempty(diagkfun)
        diagK = computeKernelDiag(X,kfun);        
    else
        diagK = diagkfun(X);
    end
    
    % 5. Quantity that gets updated when active set changes. We preallocate
    % M rows here but for active set A of size nA only rows 1:nA of TA are
    % useful.
    TA = zeros(M,N);
    
    % 6. Initial computation of TA and sumDeltabest. Quantities A, R, nA,
    % nR, TA and sumDeltabest are always kept in sync. 
    if isempty(A)
        TA(1:nA,:)       = zeros(0,N);
    else
        KAX              = kfun(X(A,:),X);
        KAA              = KAX(:,A);
        KAA(1:nA+1:nA^2) = KAA(1:nA+1:nA^2) + sigma^2;
        [LA,status]      = chol(KAA,'lower');
        if ( status ~= 0 )
            % Cholesky factorization didn't work.
            error(message('stats:classreg:learning:gputils:selectActiveSet:CannotInitializeActiveSetSelection'));
        end
        TA(1:nA,:)       = LA \ KAX;       
    end
    % sumDeltabest is a running sum of the criterion function as more
    % points are added to the active set. We stop iterating when the change
    % in criterion function becomes small relative to current sumDeltabest
    % or when the desired active set size is reached.
    sumDeltabest         = 0;
    
    % 7. Initialize sumDeltabestProfile. Return right away if nA is equal
    % to M.    
    sumDeltabestProfile    = zeros(M - nA + 1, 1);
    sumDeltabestProfile(1) = sumDeltabest;
    if ( nA == M )
        % Active set size reached.
        exitFlag = 1;
        return;
    end        
    
    % 8. Do randomized greedy forward selection iterations. index is 2
    % below because we will store sumDeltabestProfile(2) next. isposdef is
    % a flag that marks if iterations can be continued in a numerically
    % stable manner. If not, we set isposdef to false.
    found    = false;    
    index    = 2;
    isposdef = true;
    iter     = 0;
    
    while (found == false)        
        % 8.1 Select a random subset of R of length J.
        if issparsesearch && (nR > J)
            Jset = R(randsample(nR,J),1);            
        else
            Jset = R;
        end
        lenJset  = length(Jset);
        
        % 8.2 Compute best point to add from Jset to A. Save info about the
        % best point in ubest, ibest and Deltabest. 
        
            % 8.2.1 Compute vector Delta that is of the same length as Jset.
            % See eq. 102 in GPR theory spec.
            Delta = diagK(Jset) - sum(TA(1:nA,Jset).^2,1)';
        
            % 8.2.2 Theoretically, Delta must be > 0 since the kernel
            % function is positive definite. Get indices where Delta < 0 or
            % where it is NaN. For such points, reset Delta to 0 to prevent
            % such points from being selected into the active set.
            badidx = Delta < 0 | isnan(Delta);
            if any(badidx)
                Delta(badidx) = 0;
            end
            
            % 8.2.3 Compute largest Delta. Note that points with Delta = 0
            % are discouraged from inclusion automatically.            
            [Deltabest,idx] = max(Delta);
            ibest           = Jset(idx);
            ubest           = TA(1:nA,ibest);
        
        % 8.3 If the best value of Delta is negative, this indicates
        % numerical instability. In this case, set isposdef to false. Also
        % ensure that Deltabest is >= 0.
        if ( Deltabest < 0 )
            isposdef = false;
        end
        Deltabest    = max(0,Deltabest);
        
        % 8.4 Update A, R, TA, sumDeltabest, nA and nR only if isposdef is true.
        if isposdef            
            % 8.4.1 Update A and R.        
            A = [A;ibest]; %#ok<AGROW>
            R = setdiff(R,ibest);

            % 8.4.2 Update TA and sumDeltabest. il22 is the inverse of l22.
            il22         = 1/sqrt(sigma^2 + Deltabest);
            kbestt       = kfun(X(ibest,:),X);
            TA(nA+1,:)   = -il22*(ubest'*TA(1:nA,:)) + il22*kbestt;       
            sumDeltabest = sumDeltabest + Deltabest;
            
            % 8.4.3 Update nA and nR.
            nA = length(A);
            nR = length(R);
            
            % 8.4.4 Update sumDeltabestProfile.
            sumDeltabestProfile(index) = sumDeltabest;
            index                      = index + 1;
        end                
        
        % 8.5 How big is Deltabest compared to sumDeltabest?
        relInc = Deltabest/sumDeltabest;
                                      
        % 8.6 Display convergence info if needed.
        if verbose                        
            displayConvergenceInfo(iter,ibest,nA,sumDeltabest,relInc,lenJset);
        end
        
        % 8.7 Have we converged?
        if ( relInc <= tol || nA == M || ~isposdef )
            found = true;            
            % 8.7.1 If we haven't grown to size M, delete extra elements
            % from end of EA_profile.
            sumDeltabestProfile(nA-length(A0)+2:end) = [];            
            % 8.7.2 Why did the algorithm stop?            
            if ( relInc <= tol )
                exitFlag = 0;
            elseif ( nA == M )
                exitFlag = 1;
            elseif ~isposdef
                exitFlag = 2;
            end
            % 8.7.3 Display reason for termination.
            if verbose
                displayFinalConvergenceInfo(nA,relInc,M,tol,exitFlag);
            end
        end
        
        % 8.8 Update iteration counter.
        iter = iter + 1;
        
    end % end of while.
    
end % end of selectActiveSetEntropy. 

% Utility function to do Likelihood based active set selection.
function [A,loglikSRA,loglikSRAProfile,exitFlag] = selectActiveSetLikelihood(X,y,kfun,diagkfun,M,A0,J,issparsesearch,tol,verbose,sigma,tau)
% Assume inputs have been validated. Implementation details are given in
% section 6.4.3 of the GPR theory spec. The symbols used here are described
% there in detail.
%
% INPUTS:
%   X              = N-by-D matrix where N is the number of observations.
%   y              = N-by-1 response vector for the Gaussian Process Regression (GPR) model.
%   kfun           = function handle to evaluate the kernel function - can be called like KMN = kfun(XM,XN). 
%   diagkfun       = function handle to evaluate diagonal of kernel function - can be called like diagKN = diagkfun(XN).
%   M              = desired active set size.
%   A0             = initial active set.
%   J              = random search set size.
%   issparsesearch = true if we want to do a sparse search and false otherwise.
%   tol            = tolerance for detecting convergence.
%   verbose        = either true or false.
%   sigma          = noise standard deviation of the Gaussian Process Regression (GPR) model.
%   tau            = regularization strength for low rank matrix factorization. KAA gets replaced by KAA + tau^2*I.
%
% OUTPUTS:
%   A                = selected active set.
%   loglikSRA        = log likelihood using the subset of regressors approximation and the active set A.
%   loglikSRAProfile = evolution of loglikSRA as active set grows from A0 to A.
%   exitFlag         = integer code indicating reason for termination:
%
%       Value of exitFlag        Reason for termination
%       -----------------        ----------------------
%           0                    abs(Deltabest) <= tol*abs(loglikSRA) where Deltabest is the increment to current loglikSRA.
%           1                    Active set size M reached.
%           2                    Numerical instability detected.

    % 1. How many observations do we have?
    N = size(X,1);

    % 2. Initialize the active and rejected sets.
    A  = A0;
    R  = setdiff((1:N)',A0);
    
    % 3. Number of elements in the active and rejected sets.
    nA = length(A);
    nR = length(R);
    
    % 4. Initialize diagonal of kernel matrix.
    if isempty(diagkfun)
        diagK = computeKernelDiag(X,kfun);
    else
        diagK = diagkfun(X);
    end
    
    % 5. Quantities that get updated when active set changes. We
    % preallocate M rows here but for active set A of size nA only rows
    % 1:nA of TA, TAtilde and vA are useful.
    TA      = zeros(M,N);
    TAtilde = zeros(M,N);
    vA      = zeros(M,1);
    
    % 6. These are quantities that get updated when going from A to Anew by
    % adding point ibest to A.        
    ubest = zeros(nA,1);
    fbest = 0;
    wbest = zeros(nA,1);
    hbest = 0;
    kbest = zeros(N,1);
    tbest = 0;
    ibest = 0;
    tiny  = 1e-3;
    
    % 7. Initial computation of TA, TAtilde and vA.
    if isempty(A)
        TA(1:nA,:)      = zeros(0,N);
        TAtilde(1:nA,:) = zeros(0,N);
        vA(1:nA,1)      = zeros(0,1);
    else        
        KXA              = kfun(X,X(A,:));
        KAA              = KXA(A,:);
        KAA(1:nA+1:nA^2) = KAA(1:nA+1:nA^2) + tau^2;        
        [LA,status1]     = chol(KAA + KXA'*KXA/(sigma^2),'lower');
        if ( status1 ~= 0 )
            % Cholesky factorization didn't work.
            error(message('stats:classreg:learning:gputils:selectActiveSet:CannotInitializeActiveSetSelection'));
        end                
        TA(1:nA,:)  = LA \ KXA';        
                
        [LAtilde,status2] = chol(KAA,'lower');
        if ( status2 ~= 0 )
            % Cholesky factorization didn't work.
            error(message('stats:classreg:learning:gputils:selectActiveSet:CannotInitializeActiveSetSelection'));
        end        
        TAtilde(1:nA,:) = LAtilde \ KXA';
        
        vA(1:nA,1)      = TA(1:nA,:)*y/(sigma^2);
    end
    
    % 8. Initial subset of regressors log likelihood using A. Store a
    % constant appearing in the log likelihood expression into cloglikSRA.
    cloglikSRA    = (N/2)*log(2*pi*(sigma^2));
    if isempty(A)
        loglikSRA = -0.5*(y'*y/(sigma^2)) - cloglikSRA;        
    else
        loglikSRA = -0.5*(y'*y/(sigma^2) - vA(1:nA)'*vA(1:nA)) ...
            - cloglikSRA - sum(log(abs(diag(LA)))) ...
            + sum(log(abs(diag(LAtilde))));
    end
    
    % 9. Store the subset of regressors log likelihood as the active set
    % grows to its final size. Return right away if nA is equal to M.
    loglikSRAProfile = zeros(M - nA + 1, 1);
    loglikSRAProfile(1) = loglikSRA;    
    if ( nA == M )
        % Active set size reached.
        exitFlag = 1;
        return;
    end
    
    % 10. Do randomized greedy forward selection iterations. index is 2
    % below because we will store loglikSRAProfile(2) next. isposdef is a
    % flag that marks if iterations can be continued in a numerically
    % stable manner. If not, we set isposdef to false.
    found    = false;
    index    = 2;
    isposdef = true;
    iter     = 0;
    
    while (found == false)        
        % 10.1 Select a random subset of R of length J.
        if issparsesearch && (nR > J)
            Jset = R(randsample(nR,J),1);            
        else
            Jset = R;
        end
        lenJset = length(Jset);
        
        % 10.2 Compute improvement on adding points from Jset to A. Save
        % info about best point found so far. If we are doing a sparse
        % search, J is typically small and so we can do these computations
        % in matrix form without increasing the memory consumption by a
        % lot. See eq. 128 in GPR theory spec.
        if issparsesearch
            % J is probably small.
            
            % 10.2.1 Compute improvement vector Deltavec.
            % Here's a list of the sizes of the various matrices below:
            %
            %   Matrix                       Size
            %   TA(1:nA,:)                   nA-by-N
            %   TAtilde(1:nA,:)              nA-by-N
            %   KXJset                       N-by-J
            %   umat                         nA-by-J
            %   dvec                         J-by-1
            %   fvec                         J-by-1
            %   wmat                         nA-by-J
            %   hvec                         J-by-1
            %   gvec                         J-by-1
            %   tvec                         J-by-1
            %   Deltavec                     J-by-1
            %            
            KXJset   = kfun(X,X(Jset,:));
            umat     = TA(1:nA,Jset) + TA(1:nA,:)*KXJset/(sigma^2);            
            dvec     = diagK(Jset) + sum(KXJset.^2,1)'/(sigma^2);            
            fvec     = (dvec + tau^2) - sum(umat.^2,1)';
            wmat     = TAtilde(1:nA,Jset);  
            hvec     = (diagK(Jset) + tau^2) - sum(wmat.^2,1)';
            gvec     = (y'*KXJset/(sigma^2))';            
            tvec     = -(umat'*vA(1:nA,1) - gvec)./sqrt(abs(fvec));            
            %Deltavec = 0.5*(tvec.^2) + 0.5*(log(hvec) - log(fvec));
            %Deltavec = 0.5*(tvec.^2) + 0.5*(log(hvec./fvec));
            Deltavec = ( 0.5*(tvec.^2) + 0.5*log(hvec) ) - 0.5*log(fvec);
            
            % 10.2.2 Theoretically, elements of hvec and fvec must be
            % positive. Find points for which this is not true and exclude
            % them from being selected into the active set by setting the
            % corresponding value of Deltavec to 0.
            badidx = (fvec <= tiny | hvec <= tiny | isnan(Deltavec));
            if any(badidx)
                Deltavec(badidx) = 0;                
            end
            
            % 10.2.3 Compute point that gives the best improvement to SR
            % log likelihood.
            [Deltabest,idx] = max(Deltavec);            
            ubest           = umat(:,idx);
            fbest           = fvec(idx,1);
            wbest           = wmat(:,idx);
            hbest           = hvec(idx,1);
            kbest           = KXJset(:,idx);
            tbest           = tvec(idx,1);
            ibest           = Jset(idx);
        else
            % J may be big.
            Deltabest = -Inf;
            for r = Jset'
                
                % 10.2.1 Compute improvement Delta for current point r.
                kXr   = kfun(X,X(r,:));
                kXr_div_sigma2 = kXr/(sigma^2);
                u     = TA(1:nA,r) + TA(1:nA,:)*(kXr_div_sigma2);
                f     = diagK(r) + kXr'*(kXr_div_sigma2) - u'*u + tau^2;
                w     = TAtilde(1:nA,r);
                h     = diagK(r) - w'*w + tau^2;
                g     = y'*(kXr_div_sigma2);
                t     = -(vA(1:nA,1)'*u - g)/sqrt(f);
                Delta = 0.5*t^2 + 0.5*(log(h) - log(f));                
                
                % 10.2.2 If f <= 0 or h <= 0 or Delta is NaN, set Delta to
                % 0 to discourage inclusion of this point into the active
                % set.
                if (f <= 0 || h <= 0 || isnan(Delta))
                    Delta = 0;                    
                end
                                
                % 10.2.3 Update "best" so far quantities.
                if ( Delta >= Deltabest )
                    ubest     = u;
                    fbest     = f;
                    wbest     = w;
                    hbest     = h;
                    kbest     = kXr;
                    tbest     = t;
                    ibest     = r;
                    Deltabest = Delta;
                end
            end
        end % end of if.
        
        % 10.3 If fbest <= 0 or hbest <= 0 or if Deltabest is NaN, mark
        % isposdef as false. When isposdef is false, we terminate active
        % set selection. Also ensure that fbest >= 0 and hbest >= 0.
        % Deltabest can be +ve or -ve but reset it to 0 when isposdef is
        % set to false.
        if ( fbest <= 0 || hbest <= 0 || isnan(Deltabest) )
            isposdef  = false;
            Deltabest = 0;
        end
        fbest = max(0,fbest);
        hbest = max(0,hbest);        
        
        % 10.4 Update A, R, TA, TAtilde, vA, loglikSRA, nA and nR only if isposdef is true.
        if isposdef
            % 10.4.1 Update A and R.
            A = [A;ibest]; %#ok<AGROW>
            R = setdiff(R,ibest);
            
            % 10.4.2 Update TA, TAtilde, vA.
            TA(nA+1,:)      = -ubest'*TA(1:nA,:)/sqrt(fbest)      + kbest'/sqrt(fbest);
            TAtilde(nA+1,:) = -wbest'*TAtilde(1:nA,:)/sqrt(hbest) + kbest'/sqrt(hbest);
            vA(nA+1,1)      = tbest;
            loglikSRA       = loglikSRA + Deltabest;
            
            % 10.4.3 Update nA and nR.
            nA = length(A);
            nR = length(R);      
            
            % 10.4.4 Update SR log likelihood profile.
            loglikSRAProfile(index) = loglikSRA;
            index                   = index + 1;
        end                
        
        % 10.5 Compute relative improvement in log likelihood.
         relInc = abs(Deltabest)/abs(loglikSRA);  
        
        % 10.6 Display convergence info if needed.
        if verbose                        
            displayConvergenceInfo(iter,ibest,nA,loglikSRA,relInc,lenJset);
        end
        
        % 10.7 Have we converged?
        if ( relInc <= tol || nA == M || ~isposdef )
            found = true;            
            % 10.7.1 If we haven't grown to size M, delete extra elements
            % from end of loglikSRAProfile.
            loglikSRAProfile(nA-length(A0)+2:end) = [];
            % 10.7.2 Why did the algorithm stop?     
            if ( relInc <= tol )
                exitFlag = 0;
            elseif ( nA == M )
                exitFlag = 1;
            elseif ~isposdef
                exitFlag = 2;
            end
            % 10.7.3 Display reason for termination.
            if verbose
                displayFinalConvergenceInfo(nA,relInc,M,tol,exitFlag);
            end
        end
        
        % 10.8 Update iteration counter.
        iter = iter + 1;
        
    end % end of while.
    
end % end of selectActiveSetLikelihood.

% Utilities for displaying convergence info.
function displayConvergenceInfo(iter,ibest,nA,convCrit,relConvCrit,lenJset)
% Helper function to display iteration wise convergence info.
% iter        = iteration index.
% ibest       = index of point most recently added to active set.
% nA          = current active set size after adding ibest.
% convCrit    = current convergence criterion.
% relConvCrit = current relative convergence criterion.
% lenJset     = current search set size.
%
%  We will display convergence info like this:
%   |=================================================================|
%   | Iteration |   Best   |  Active Set |  Convergence  | Search Set |
%   |           |  Index   |     Size    |   Criterion   |    Size    |
%   |-----------------------------------------------------------------|
%   |         0 |    15356 |           1 |  8.180296e-01 |         59 |
%   |         1 |     4950 |           2 |  6.412892e-01 |         59 |
%   |         2 |    17607 |           3 |  5.600619e-01 |         59 |
%   |         3 |     5229 |           4 |  4.914040e-01 |         59 |
%   |         4 |    16767 |           5 |  4.263763e-01 |         59 |
%   |         5 |     8304 |           6 |  3.701498e-01 |         59 |
%   |         6 |    17209 |           7 |  3.236823e-01 |         59 |
%   |         7 |     1370 |           8 |  2.776070e-01 |         59 |
%   |         8 |      679 |           9 |  2.383970e-01 |         59 |
%   |         9 |    12648 |          10 |  2.100944e-01 |         59 |
%   |        10 |     9610 |          11 |  1.835741e-01 |         59 |

    % Display header.
    if ( rem(iter,20) == 0 )
        fprintf('\n');
        fprintf('  |=================================================================================|\n');
        fprintf('  | Iteration |   Best   |  Active Set |   Absolute    |   Relative    | Search Set |\n');
        fprintf('  |           |  Index   |     Size    |   Criterion   |   Criterion   |    Size    |\n');
        fprintf('  |---------------------------------------------------------------------------------|\n');
    end
    % Display iteration wise convergence info.
    fprintf('  |%10d |%9d |%12d |%14.6e |%14.6e |%11d |\n', iter, ibest, nA, convCrit, relConvCrit, lenJset); 
end

function displayFinalConvergenceInfo(nA,relConvCrit,M,tol,exitFlag)
% nA          = current active set size after adding ibest.
% relConvCrit = current relative convergence criterion.
% M           = requested active set size.
% tol         = specified tolerance.
% exitFlag    = integer code indicating reason for termination.

    % Explain why iterations stopped.
    fprintf('\n');
    finalCriterionValueString = getString(message('stats:classreg:learning:gputils:selectActiveSet:MessageFinalCriterionValue'));
    givenToleranceString      = getString(message('stats:classreg:learning:gputils:selectActiveSet:MessageGivenToleranceValue'));
    finalActiveSetSizeString  = getString(message('stats:classreg:learning:gputils:selectActiveSet:MessageFinalActiveSetSize'));
    givenActiveSetSizeString  = getString(message('stats:classreg:learning:gputils:selectActiveSet:MessageGivenActiveSetSize'));
    fprintf('%s = %9.3e, %s = %9.3e\n',finalCriterionValueString                   , relConvCrit, [givenToleranceString,'    '], tol);
    fprintf('%s = %9d, %s = %9d\n'    ,[finalActiveSetSizeString,'               '], nA         , givenActiveSetSizeString     , M  );    
    if ( exitFlag == 0 )
        % Convergence criterion less than tol.
        msg = getString(message('stats:classreg:learning:gputils:selectActiveSet:MessageConvergenceCriterionSatisfied'));
        fprintf('%s\n',msg);
    elseif ( exitFlag == 1 )
        % Desired active set size reached.
        msg = getString(message('stats:classreg:learning:gputils:selectActiveSet:MessageActiveSetSizeReached'));
        fprintf('%s\n',msg);
    else
        % Kernel function is not positive definite - numerically speaking.
        msg = getString(message('stats:classreg:learning:gputils:selectActiveSet:MessageKernelNotPositiveDefinite'));
        fprintf('%s\n',msg);
    end
end

% Validation methods.
function X = validateX(X)
% X must be a numeric, real matrix - no NaN or Inf values.
    isok = isnumeric(X) && isreal(X) && ismatrix(X) && all(isfinite(X(:)));
    if ~isok
        error(message('stats:classreg:learning:gputils:selectActiveSet:BadX')); 
    end
end

function kfun = validatekfun(kfun)
% kfun must be a function handle.
    isok = isa(kfun,'function_handle');
    if ~isok
        error(message('stats:classreg:learning:gputils:selectActiveSet:BadKernelFunction'));
    end
end

function diagkfun = validatediagkfun(diagkfun)
% diagkfun must be a function handle.
    isok = isa(diagkfun,'function_handle');
    if ~isok
        error(message('stats:classreg:learning:gputils:selectActiveSet:BadDiagKernelFunction'));
    end
end

function M = validateActiveSetSize(M,N)
% M = proposed size of active set.
% N = number of observations - guaranteed to be an integer.
% (a) M must be a scalar integer >=1 and 
% (b) M must be <= N.
    isok = isscalar(M) && internal.stats.isIntegerVals(M,1,N);
    if ~isok
        error(message('stats:classreg:learning:gputils:selectActiveSet:BadActiveSetSize',1,N));
    end
end

function A0 = validateInitialActiveSet(A0,M,N)
% A0 = proposed initial active set.
% M  = final size of active set - guaranteed to be an integer.
% N  = number of observations - guaranteed to be an integer.
% (a) A0 must be a vector with elements from 1:N. 
% (b) length(A0) must be <= M.
% (c) A0 cannot have duplicate values.
% A0 is returned as a column vector.
    if isempty(A0)
        return;
    end
    
    isvec = isvector(A0);
    isint = internal.stats.isIntegerVals(A0,1,N);
    lenA0 = length(A0);
    isleM = (lenA0 <= M);
    isok  = isvec && isint && isleM;
    
    if ( size(A0,1) == 1 )
        A0 = A0';
    end
    
    A0   = unique(A0);
    isok = isok && (length(A0) == lenA0);
    
    if ~isok
        error(message('stats:classreg:learning:gputils:selectActiveSet:BadInitialActiveSet',M,N));
    end    
end

function J = validateRandomSearchSetSize(J,searchtype)
% J          = proposed size of random search set.
% searchtype = type of search - 'sparse' or 'exhaustive'.
% (a) J must be a scalar integer >= 1.
% If searchtype is not 'sparse', then J is not validated.
    if strcmpi(searchtype,'sparse')
        isscl = isscalar(J);
        isint = internal.stats.isIntegerVals(J,1);
        isok  = isscl && isint;
        if ~isok
            error(message('stats:classreg:learning:gputils:selectActiveSet:BadRandomSearchSetSize'));
        end
    end
end

function tol = validateTolerance(tol)
% tol = proposed error tolerance.
% (a) tol must be a numeric, real, positive scalar.
    isok = isscalar(tol) && isnumeric(tol) && isreal(tol) && (tol > 0);
    if ~isok
        error(message('stats:classreg:learning:gputils:selectActiveSet:BadTolerance'));
    end    
end

function tf = validateVerbose(tf)
% tf = potential value of 'Verbose' parameter.
% (a) tf can be true/false
% (b) tf can be 1/0. If 1/0, tf is converted to true/false.
    if isscalar(tf)
        if isnumeric(tf)
            if (tf == 1)
                tf = true;
            elseif (tf == 0)
                tf = false;
            end
        end
        if islogical(tf)
            isok = true;
        else
            isok = false;
        end
    else
        isok = false;
    end
    
    if ~isok
        error(message('stats:classreg:learning:gputils:selectActiveSet:BadVerbose'));
    end
end

function sigma = validateSigma(sigma)
% sigma = proposed value for noise standard deviation.
% (a) sigma must be a real scalar.
% (b) sigma must be > 0.
    isok = isscalar(sigma) && isnumeric(sigma) && isreal(sigma) && (sigma > 0);
    if ~isok
        error(message('stats:classreg:learning:gputils:selectActiveSet:BadSigma'));
    end
end

function y = validateResponseVector(y,N)
% y must be a numeric, real vector of length N - no NaN or Inf values allowed.
% y is returned as a column vector.
    isok = isnumeric(y) && isreal(y) && isvector(y) && all(isfinite(y(:))) && (length(y) == N);
    if ~isok
        error(message('stats:classreg:learning:gputils:selectActiveSet:BadResponseVector',N));
    end
    y = y(:);    
end

function tau = validateRegularization(tau)
% tau = proposed value for low rank matrix factorization regularization.
% (a) tau must be a real scalar.
% (b) tau must be >= 0.
    isok = isscalar(tau) && isnumeric(tau) && isreal(tau) && (tau >= 0);
    if ~isok
        error(message('stats:classreg:learning:gputils:selectActiveSet:BadRegularization'));
    end
end