classdef CompactGPImpl

%   Copyright 2014-2017 The MathWorks, Inc.    
    
    properties
        % Fitting options supplied to us.
        FitMethod        = [];  % What is the fit method?
        PredictMethod    = [];  % What is the predict method?
        ActiveSet        = [];  % User supplied or estimated active set (logical vector).
        ActiveSetSize    = [];  % Size of the desired active set.
        ActiveSetMethod  = [];  % Active set method.        
        Standardize      = [];  % Should inputs X be standardized?
        Verbose          = [];  % Verbosity level 0,1 or 2.
        CacheSize        = [];  % Size of cache in MB (needed for making predictions).
        Options          = [];  % Additional advanced fitting options (see GPParams class).
        Optimizer        = [];  % Name of optimizer.
        OptimizerOptions = [];  % Relevant optimizer options.
        ConstantKernelParameters = [];  % Which kernel parameters are to be held constant.
        ConstantSigma    = [];  % Whether Sigma is to be held constant.
        InitialStepSize  = [];  % Initial step size for quasinewton and lbfgs optimizers.
        
        % Original form of kernel function, kernel parameters and basis function.
        KernelFunction   = [];  % Kernel function specification.
        KernelParameters = [];  % Kernel parameters specification.
        BasisFunction    = [];  % Basis function specification.
        
        % Kernel function and basis function.
        Kernel           = [];  % Kernel function object.
        IsBuiltInKernel  = [];  % Is this a built-in kernel function?
        HFcn             = [];  % Basis function in standard form.
        
        % Standardization related quantities.
        StdMu            = [];  % Mean per predictor if data was standardized (column vector) and empty otherwise.
        StdSigma         = [];  % Standard deviation per predictor if data was standardized (column vector) and empty otherwise.
        
        % Initial parameter values.
        Beta0            = [];  % Initial value of Beta.
        Theta0           = [];  % Initial value of Theta.
        Sigma0           = [];  % Initial value of Sigma.
        
        % Estimated parameter values.
        BetaHat          = [];  % Final value of Beta.
        ThetaHat         = [];  % Final value of Theta.
        SigmaHat         = [];  % Final value of Sigma.
        
        % Things needed to make predictions and compute standard errors.
        %
        % For predictions with exact GPR using X, y, we store:
        %
        %   AlphaHat   = (K + sigma^2*eye(N))^{-1} * (y - H*beta)
        %
        %   LFactor    = Lower triangular Cholesky factor of (K + sigma^2*eye(N))
        %
        %   ActiveSetX = X
        %
        % See eq. 30 and 31 in GPR theory spec.
        %
        % For predictions with SD using X, y, we store:
        %
        %   ActiveSetX = X(this.ActiveSet,:) = XA (say)
        %
        %   AlphaHat and LFactor are computed like for exact GPR but using
        %   XA and yA where yA = y(this.ActiveSet,:).
        %
        % For predictions with BCD using X, y, we store:
        %
        %   AlphaHat   = (K + sigma^2*eye(N))^{-1} * (y - H*beta)
        %
        %   ActiveSetX = X
        %
        %   LFactor is not stored since SD/CI's cannot be computed with BCD.
        %
        % For predictions with FIC (similar for SR) using X, y, we store:
        %
        %   ActiveSetX = X(this.ActiveSet,:) = XA (say)
        %
        %   AlphaHat   = see eq. 191 in GPR theory spec
        %
        %   LFactor    = Cholesky factor of BA (eq. 185 in GPR theory spec)
        %
        %   LFactor2   = Cholesky factor of K(XA,XA) (eq. 197 in GPR theory spec)
        
        IsActiveSetSupplied  = [];  % true if active set is user supplied and false otherwise.
        ActiveSetX           = [];  % Subset of X corresponding to ActiveSet. For exact GPR, ActiveSetX = X.
        AlphaHat             = [];  % Estimated value of Alpha for computing predictions.
        LFactor              = [];  % Lower triangular Cholesky factor for computing SD/CI's.
        LFactor2             = [];  % Another Lower triangular Cholesky factor needed for FIC/SR when computing SD/CI's.
        
        % Lower bound on noise standard deviation.
        SigmaLB              = [];  % Set this as a small multiple of std(y). Sigma is parameterized as Sigma = SigmaLB + exp(gamma).
        
        % Is model ready to make predictions?
        IsTrained            = false;
        
        % Other useful things.
        LogLikelihoodHat     = [];  % Maximized log likelihood of the model.        
    end
    
    methods(Access=protected)
        function this = CompactGPImpl()
        end
    end
    methods(Hidden)
        function s = toStruct(obj)
            % Convert to a struct for codegen.
            
            warnState  = warning('query','all');
            warning('off','MATLAB:structOnObject');
            cleanupObj = onCleanup(@() warning(warnState));
            
            if isa(obj,'classreg.learning.impl.GPImpl')
                obj = compact(obj);
            end
            % impl
            s = struct(obj);
            
            % Remove dependant and unnecessary fields
            s = rmfield(s,'Kernel');
            
            % Convert HFcn 
            if isempty(s.HFcn)
                s.HFcn = [];
            else
                s.HFcn = func2str(s.HFcn);
            end            
            
            % Convert BasisFunction and 
            % - Specify the type of basis function
            % - If this is a user-defined basis funciton preserve the name of custom function. 
            if ischar(obj.BasisFunction)
                s.BasisFcn = '';
                s.BasisFunction = obj.BasisFunction;
                switch lower(obj.BasisFunction)
                    case 'none'
                        s.HFcnType = 1;                        
                    case 'constant'
                        s.HFcnType = 2;                        
                    case 'linear'
                        s.HFcnType = 3;                        
                    case 'purequadratic'
                        s.HFcnType = 4;
                end
            else
                % If basis function is user-defined, the name of this 
                % function is stored in the workspace of an anonymous
                % function, '@(XM)feval(name,XM)'
                strFcn = func2str(obj.BasisFunction);
                isfuncstr = contains(strFcn,'@(XM)feval(name,XM)');
                if ~isfuncstr
                    error(message('stats:classreg:learning:coderutils:classifToStruct:AnonymousFunctionsNotSupported','Basis'));
                else
                    fcns = functions(obj.BasisFunction);
                    s.BasisFcn = fcns.workspace{1}.name;
                end
                s.BasisFunction = strFcn;
                s.HFcnType = 5;
            end
            
            % Retain the name of user-defined Kernel function
            if ischar(obj.KernelFunction)
                s.KernelFcn = '';
                s.KernelFunction = obj.KernelFunction;                
            else                
                % If kernel function is user-defined, the name of this 
                % function is stored in the workspace of an anonymous
                % function, '@(XM,XN,THETA)feval(name,XM,XN,THETA)'
                strFcn = func2str(obj.KernelFunction);
                isfuncstr = contains(strFcn,'@(XM,XN,THETA)feval(name,XM,XN,THETA)');
                if ~isfuncstr
                    error(message('stats:classreg:learning:coderutils:classifToStruct:AnonymousFunctionsNotSupported','Kernel'));
                else
                    fcns = functions(obj.KernelFunction);
                    s.KernelFcn = fcns.workspace{1}.name;
                end
                s.KernelFunction = strFcn;                
            end
            
            switch lower(s.Optimizer)
                case 'quasinewton'
                    % OptimizerOptions is an statset struct with a cell array
                    % inside                    
                    s.OptimizerOptions = classreg.learning.gputils.statsetToStruct(s.OptimizerOptions);
                    
                case 'fminsearch'
                    % OptimizerOptions is an optimset struct, which has several
                    % objects and cell arrays                    
                    s.OptimizerOptions = classreg.learning.gputils.optimsetToStruct(s.OptimizerOptions);
                    
                case'fminunc'
                    % OptimizerOptions is an optimoptions object                    
                    s.OptimizerOptions = classreg.learning.gputils.optimoptionsToStruct(s.OptimizerOptions,1);
                    
                case'fmincon'
                    % OptimizerOptions is an optimoptions object                    
                    s.OptimizerOptions = classreg.learning.gputils.optimoptionsToStruct(s.OptimizerOptions,2);
            end
          
        end
    end
    
    methods(Static)
        function obj = fromStruct(s)
            % fromStruct - reconstructs a CompactGPImpl object from a struct
            % obj = fromStruct(s) takes a codegen-compatible struct, s and
            % reconstructs a CompactGPImpl object, obj.
            
            obj = classreg.learning.impl.CompactGPImpl;
            
            fieldNamesToAssign = {'FitMethod','PredictMethod','ActiveSet',...
                'ActiveSetSize','ActiveSetMethod','Standardize','Verbose',...
                'CacheSize','Options','Optimizer','ConstantKernelParameters',...
                'ConstantSigma','KernelParameters',...
                'IsBuiltInKernel','StdMu','StdSigma','Beta0',...
                'Theta0','Sigma0','BetaHat','ThetaHat','SigmaHat',...
                'IsActiveSetSupplied','ActiveSetX','AlphaHat','LFactor',...
                'LFactor2','SigmaLB','IsTrained','LogLikelihoodHat'};
            
            for c = 1:numel(fieldNamesToAssign)
                obj.(fieldNamesToAssign{c}) = s.(fieldNamesToAssign{c});
            end
            
            switch lower(s.Optimizer)
                case 'fminunc'
                    obj.OptimizerOptions = classreg.learning.gputils.optimoptionsFromStruct(s.OptimizerOptions,1);
                case 'fmincon'
                    obj.OptimizerOptions = classreg.learning.gputils.optimoptionsFromStruct(s.OptimizerOptions,2);
                case 'fminsearch'
                    obj.OptimizerOptions = classreg.learning.gputils.optimsetFromStruct(s.OptimizerOptions);
                case 'quasinewton'
                    obj.OptimizerOptions = classreg.learning.gputils.statsetFromStruct(s.OptimizerOptions);
            end
            % Reconstruc kernel funciton 
            [~,kernel,~]                 = classreg.learning.gputils.makeKernelObject(s.KernelFunction,s.KernelParams);
            obj.Kernel                   = kernel;
            
            % Reconstruct basis function
            if isempty(s.BasisFcn)
                obj.BasisFunction = s.BasisFunction;
            else
                name                        = s.BasisFcn;
                basisFunction               = @(XM) feval(name,XM);
                obj.BasisFunction           = basisFunction;
            end
            
            % Reconstruct kernel function
            if isempty(s.KernelFcn)
                obj.KernelFunction = s.KernelFunction;
            else
                name                        = s.KernelFcn;
                kernelFunction              = @(XM,XN,THETA)feval(name,XM,XN,THETA);
                obj.KernelFunction          = kernelFunction;
            end
            
            % HFcn can be a function handle, but it's not used for prediction.
            if isempty(s.HFcn)
                obj.HFcn  = [];
            else
                obj.HFcn  = str2func(s.HFcn);
            end
            
            % If PredictMethod is 'sd', 'sr', or 'fic', then a struict called
            % activeSetHistory is created with the following fields:
            %   FIELD NAME         MEANING
            %   ParameterVector  - Cell array containing vectors [beta;theta;sigma].
            %   ActiveSetIndices - Cell array containing active set indices.
            %   LogLikelihood    - Vector containing maximized log likelihoods.
            %   CriterionProfile - Cell array containing active set selection 
            %                      criterion values as the active set grows in
            %                      size from size 0 to its final size.
%             activeSetHistory = struct();
%             for reps = 1:numel(s.ActiveSetHistory)
%                 activeSetHistory.ParameterVector{reps}   = s.ActiveSetHistory(reps).ParameterVector;
%                 activeSetHistory.ActiveSetIndices{reps}  = s.ActiveSetHistory(reps).ActiveSetIndices;
%                 activeSetHistory.LogLikelihood(reps)     = s.ActiveSetHistory(reps).LogLikelihood;
%                 activeSetHistory.CriterionProfile{reps}  = s.ActiveSetHistory(reps).CriterionProfile;
%             end
%             obj.ActiveSetHistory = activeSetHistory;
        end
    end
    
    methods
        function L = computeLFactorExact(this,X,theta,sigma)
            %computeLFactorExact - Compute lower triangular Cholesky factor needed for computing SD/CI's for exact GPR.
            %   L = computeLFactorExact(this,X,theta,sigma) takes a
            %   CompactGPImpl object this, a N-by-D matrix X, a vector of
            %   unconstrained kernel parameters theta, noise standard deviation
            %   sigma and computes L, the lower triangular Cholesky factor of
            %   (K + sigma^2*I_N) where K is the N-by-N kernel computed using
            %   X. N is the number of observations and D is the number of
            %   predictors in X.
            
            % 1. Make kernel function for fixed theta. kfun below can be
            % called like this: KNM = kfun(XN,XM)
            kfun = makeKernelAsFunctionOfXNXM(this.Kernel,theta);
            
            % 2. Get (K + sigma^2*I_N). To deal with the case of sigma = 0,
            % we add a diagonal offset this.Options.DiagonalOffset on top
            % of sigma^2. If the value of SigmaLowerBound is large enough,
            % this modification is not necessary.
            N                      = size(X,1);
            KPlusSigma2            = kfun(X,X);
            diagOffset             = this.Options.DiagonalOffset;
            KPlusSigma2(1:N+1:N^2) = KPlusSigma2(1:N+1:N^2) + (sigma^2 + diagOffset);
            
            % 3. Get lower triangular Cholesky factor of KPlusSigma2.
            % status below is 0 if KPlusSigma2 is positive definite.
            [L,status] = chol(KPlusSigma2,'lower');
            if ( status ~= 0 )
                error(message('stats:classreg:learning:impl:GPImpl:GPImpl:UnableToComputeLFactorExact'));
            end
            
        end % end of computeLFactorExact.
                        
        function [pred,se,ci] = predictExact(this,Xnew,alpha)
        %predictExact - Predict response of a trained GPR model given new data.
        %   pred = predictExact(this,Xnew,alpha) takes a CompactGPImpl
        %   object this, a M-by-D matrix Xnew and a scalar alpha between 0
        %   and 1 and computes a M-by-1 vector pred such that pred(i) is
        %   the estimated mean of the new response ynew(i) at Xnew(i,:)
        %   from a trained GPR model.
        %
        %   [pred,se] = predictExact(this,Xnew,alpha) also computes a
        %   M-by-1 vector se such that se(i) is the estimated standard
        %   deviation of ynew(i).
        %
        %   [pred,se,ci] = predictExact(this,Xnew,alpha) also computes a
        %   M-by-2 vector ci such that ci(i,:) contains a 100*(1-alpha)%
        %   confidence interval for ynew(i). The first column of ci
        %   contains lower bounds and the second column contains upper
        %   bounds.
        %
        %   NOTE:
        %   The confidence interval is constructed under the assumption
        %   that ynew(i) has a Normal distribution with mean pred(i) and
        %   variance se(i)^2. See eq. 279 in GPR theory spec. When
        %   parameters are estimated from data, beta, theta and sigma^2 in
        %   eq. 279 are replaced by their estimated values.
            
            % 1. Ensure that alpha is sensible and model is trained.            
            assert( alpha >= 0 && alpha <= 1 );
            assert( this.IsTrained );
            
            % 2. Training X and number of observations.
            X = this.ActiveSetX;
            N = size(X,1);
            
            % 3. If Standardize is true, apply D-by-1 vectors StdMu and
            % StdSigma to columns of Xnew. Assume Xnew has been validated.
            if ( this.Standardize == true )
                Xnew = bsxfun(@rdivide,bsxfun(@minus,Xnew,this.StdMu'),this.StdSigma');
            end
            
            % 4. Get estimated coefficients.            
            alphaHat = this.AlphaHat;
            betaHat  = this.BetaHat;
            thetaHat = this.ThetaHat;
            sigmaHat = this.SigmaHat;
            
            % 5. Get basis function.
            HFcn = this.HFcn; %#ok<PROPLC,*PROP>
            
            % 6. Make kernel function for thetaHat. kfun below can be
            % called like this: KNM = kfun(XN,XM)
            kfun = makeKernelAsFunctionOfXNXM(this.Kernel,thetaHat);
            
            % 7. How many rows in Xnew.
            M = size(Xnew,1);
            
            % 8. Do we want se?
            if nargout > 1
                wantse = true;
            else
                wantse = false;
            end
            
            % 9. Do we want ci?
            if nargout > 2
                wantci = true;
            else
                wantci = false;
            end
            
            % 10. Allocate outputs and compute zcrit such that: 
            % normcdf(zcrit) = 1-alpha/2.
            pred = zeros(M,1);
            if wantse
                se = zeros(M,1);
            end
            if wantci
                ci    = zeros(M,2);
                zcrit = norminv(1-alpha/2); 
            end
            
            % 11. Get Cholesky factor L if we want se or ci. This should be
            % stored in property LFactor. If not, compute it from scratch.            
            if ( wantse || wantci )
                if isempty(this.LFactor)
                    % Compute from scratch.
                    L = computeLFactorExact(this,X,thetaHat,sigmaHat);
                else
                    % Reuse previous value.
                    L = this.LFactor;
                    assert(size(L,1) == N);
                end
            end
            
            % 12. Get the diagonal of K(Xnew,Xnew) if required.
            if ( wantse || wantci )                
                % Make function to get diagonal of kernel. kfundiag below
                % can be called like this: diagKNN = kfundiag(XN)
                kfundiag = makeDiagKernelAsFunctionOfXN(this.Kernel,thetaHat); 
                diagKnew = kfundiag(Xnew); 
            end
            
            % 13. In principle, we could form pred by computing
            % K(Xnew,X)*alphaHat. The matrix K(Xnew,X) is of size M-by-N
            % and may not fit in memory. The idea is then to process a
            % batch of rows of Xnew together depending on the CacheSize. If
            % B rows of Xnew are processed at once, we need to store a
            % matrix of size B-by-N. In double precision, this would
            % require 8*B*N/1e6 MB. Also, B >= 1.            
            B       = max(1,floor((1e6 * this.CacheSize)/8/N));            
            nchunks = floor(M/B);
            
            % 14. Process chunks.
            for c = 1:nchunks+1
                % 14.1 Indices of rows in chunk c.
                if c < nchunks+1
                    idxc = (c-1)*B+1:c*B;
                else
                    % Last chunk.
                    idxc = nchunks*B+1:M;
                end
                % 14.2 Xnew for chunk c.
                Xnewc   = Xnew(idxc,:);
                % 14.3 Kernel product matrix for chunk c.
                KXnewcX = kfun(Xnewc,X);
                % 14.4 Predictions for chunk c.
                pred(idxc) =  KXnewcX*alphaHat;
                if ~isempty(betaHat)
                    pred(idxc) = pred(idxc) + HFcn(Xnewc)*betaHat; %#ok<PROPLC>
                end
                % 14.5 SE's for chunk c.
                if wantse
                    LinvKXXnewc = L \ KXnewcX';
                    se(idxc)    = sqrt(max(0, sigmaHat^2 + diagKnew(idxc) - sum(LinvKXXnewc.^2,1)'));
                end
                % 14.6 CI's for chunk c.
                if wantci
                    delta      = zcrit*se(idxc);
                    ci(idxc,:) = [pred(idxc) - delta, pred(idxc) + delta];
                end
            end
            
        end % end of predictExact.
        
        function [pred,se,ci] = predictSparse(this,Xnew,alpha,useFIC)
        %predictSparse - Predict response of a trained GPR model given new data using SR/FIC.
        %   pred = predictSparse(this,Xnew,alpha,useFIC) takes a CompactGPImpl
        %   object this, a M-by-D matrix Xnew and a scalar alpha between 0
        %   and 1 and computes a M-by-1 vector pred such that pred(i) is
        %   the estimated mean of the new response ynew(i) at Xnew(i,:)
        %   from a trained GPR model. If useFIC is true, we use the FIC
        %   approximation otherwise we use the SR approximation.
        %
        %   [pred,se] = predictSparse(this,Xnew,alpha,useFIC) also computes
        %   a M-by-1 vector se such that se(i) is the estimated standard
        %   deviation of ynew(i).
        %
        %   [pred,se,ci] = predictSparse(this,Xnew,alpha,useFIC) also
        %   computes a M-by-2 vector ci such that ci(i,:) contains a
        %   100*(1-alpha)% confidence interval for ynew(i). The first
        %   column of ci contains lower bounds and the second column
        %   contains upper bounds.
        %
        %   NOTE:
        %   The confidence interval is constructed under the assumption
        %   that ynew(i) has a Normal distribution with mean pred(i) and
        %   variance se(i)^2. See section 7.2.1 in GPR theory spec. When
        %   parameters are estimated from data, beta, theta and sigma^2 are
        %   replaced by their estimated values.
            
            % 1. Ensure that alpha is sensible and model is trained.            
            assert( alpha >= 0 && alpha <= 1 );
            assert( this.IsTrained );
            
            % 2. Active set of observations.
            XA = this.ActiveSetX;
            NA = size(XA,1);
            
            % 3. If Standardize is true, apply D-by-1 vectors StdMu and
            % StdSigma to columns of Xnew. Assume Xnew has been validated.
            if ( this.Standardize == true )
                Xnew = bsxfun(@rdivide,bsxfun(@minus,Xnew,this.StdMu'),this.StdSigma');
            end
            
            % 4. Get estimated coefficients.            
            alphaHat = this.AlphaHat;
            betaHat  = this.BetaHat;
            thetaHat = this.ThetaHat;
            sigmaHat = this.SigmaHat;
            
            % 5. Get basis function.
            HFcn = this.HFcn; %#ok<PROPLC,*PROP>
            
            % 6. Make kernel function for thetaHat. kfun below can be
            % called like this: KNM = kfun(XN,XM)
            kfun = makeKernelAsFunctionOfXNXM(this.Kernel,thetaHat);                                               
            
            % 7. How many rows in Xnew.
            M = size(Xnew,1);
            
            % 8. Do we want se?
            if nargout > 1
                wantse = true;
            else
                wantse = false;
            end
            
            % 9. Do we want ci?
            if nargout > 2
                wantci = true;
            else
                wantci = false;
            end
            
            % 10. Allocate outputs and compute zcrit such that: 
            % normcdf(zcrit) = 1-alpha/2.
            pred = zeros(M,1);
            if wantse
                se = zeros(M,1);
            end
            if wantci
                ci    = zeros(M,2);
                zcrit = norminv(1-alpha/2); 
            end
            
            % 11. Get Cholesky factors L and LAA if we want se or ci.
            % Compact objects do not store X and so we cannot compute
            % LFactor's from scratch for SR/FIC.
            if ( wantse || wantci )
                if isempty(this.LFactor) || isempty(this.LFactor2)
                    % Compact object does not store LFactor and LFactor2
                    % and does not have access to training data X and so we
                    % cannot recompute the LFactors from scratch.
                    error(message('stats:classreg:learning:impl:GPImpl:GPImpl:NoCIsForFIC'));                    
                else
                    % Reuse previous value.
                    L   = this.LFactor;
                    LAA = this.LFactor2;
                    assert(size(L,1) == NA);
                    assert(size(LAA,1) == NA);
                end
            end
            
            % 12. Get the diagonal of K(Xnew,Xnew) if required.
            if ( wantse || wantci )
                % Make function to get diagonal of kernel. kfundiag below
                % can be called like this: diagKNN = kfundiag(XN)
                if useFIC
                    kfundiag = makeDiagKernelAsFunctionOfXN(this.Kernel,thetaHat);
                    diagKnew = kfundiag(Xnew);
                end
            end
            
            % 13. In principle, we could form pred by computing
            % K(Xnew,XA)*alphaHat. The matrix K(Xnew,XA) is of size M-by-NA
            % and may not fit in memory. The idea is then to process a
            % batch of rows of Xnew together depending on the CacheSize. If
            % B rows of Xnew are processed at once, we need to store a
            % matrix of size B-by-NA. In double precision, this would
            % require 8*B*NA/1e6 MB. Also, B >= 1.            
            B       = max(1,floor((1e6 * this.CacheSize)/8/NA));            
            nchunks = floor(M/B);
            
            % 14. Process chunks.
            for c = 1:nchunks+1
                % 14.1 Indices of rows in chunk c.
                if c < nchunks+1
                    idxc = (c-1)*B+1:c*B;
                else
                    % Last chunk.
                    idxc = nchunks*B+1:M;
                end
                % 14.2 Xnew for chunk c.
                Xnewc   = Xnew(idxc,:);
                % 14.3 Kernel product matrix for chunk c.
                KXnewcXA = kfun(Xnewc,XA);
                % 14.4 Predictions for chunk c.
                pred(idxc) =  KXnewcXA*alphaHat;
                if ~isempty(betaHat)
                    pred(idxc) = pred(idxc) + HFcn(Xnewc)*betaHat; %#ok<PROPLC>
                end
                % 14.5 SE's for chunk c.
                if wantse
                        LinvKXAXnewc   = L \ KXnewcXA';
                    if useFIC
                        LAAinvKXAXnewc = LAA \ KXnewcXA';
                        se(idxc)       = sqrt(max(0,sigmaHat^2 + diagKnew(idxc) - sum(LAAinvKXAXnewc.^2,1)' + sum(LinvKXAXnewc.^2,1)'));
                    else
                        se(idxc)       = sqrt(max(0,sigmaHat^2 + sum(LinvKXAXnewc.^2,1)'));
                    end
                end
                % 14.6 CI's for chunk c.
                if wantci
                    delta      = zcrit*se(idxc);
                    ci(idxc,:) = [pred(idxc) - delta, pred(idxc) + delta];
                end
            end
            
        end % end of predictSparse.        
    
        function varargout = predict(this,Xnew,alpha)
        %predict - Predict response of a trained GPR model using PredictMethod Exact/SR/FIC.
        %   pred = predict(this,Xnew,alpha) takes a CompactGPImpl object 
        %   this, a M-by-D matrix Xnew and a scalar alpha between 0 and 1
        %   and computes a M-by-1 vector pred such that pred(i) is the
        %   estimated mean of the new response ynew(i) at Xnew(i,:) from a
        %   trained GPR model.
        %
        %   [pred,se] = predict(this,Xnew,alpha) also computes a M-by-1
        %   vector se such that se(i) is the estimated standard deviation
        %   of ynew(i).
        %
        %   [pred,se,ci] = predict(this,Xnew,alpha) also computes a M-by-2
        %   vector ci such that ci(i,:) contains a 100*(1-alpha)%
        %   confidence interval for ynew(i). The first column of ci
        %   contains lower bounds and the second column contains upper
        %   bounds.
        %
        %   This method dispatches to either predictExact or predictSparse.
        
            import classreg.learning.modelparams.GPParams;
            switch lower(this.PredictMethod)
                case lower(GPParams.PredictMethodExact)
                    [varargout{1:nargout}] = predictExact(this,Xnew,alpha);

                case lower(GPParams.PredictMethodBCD)
                    [varargout{1:nargout}] = predictExact(this,Xnew,alpha);

                case lower(GPParams.PredictMethodSD)
                    [varargout{1:nargout}] = predictExact(this,Xnew,alpha);

                case lower(GPParams.PredictMethodFIC)
                    useFIC                 = true;
                    [varargout{1:nargout}] = predictSparse(this,Xnew,alpha,useFIC);

                case lower(GPParams.PredictMethodSR)
                    useFIC                 = false;
                    [varargout{1:nargout}] = predictSparse(this,Xnew,alpha,useFIC);
            end
        
        end
        
        function [pred,covmat,ci] = predictExactWithCov(this,Xnew,alpha)
        %predictExactWithCov - Predict response of a trained GPR model given new data.
        %   pred = predictExactWithCov(this,Xnew,alpha) takes a
        %   CompactGPImpl object this, a M-by-D matrix Xnew and a scalar
        %   alpha between 0 and 1 and computes a M-by-1 vector pred such
        %   that pred(i) is the estimated mean of the new response ynew(i)
        %   at Xnew(i,:) from a trained GPR model.
        %
        %   [pred,covmat] = predictExactWithCov(this,Xnew,alpha) also
        %   computes a M-by-M matrix covmat containing the estimated
        %   covariance of the M-by-1 vector ynew. It is ensured that the
        %   diagonal elements of covmat are >= 0 and that covmat is
        %   symmetric. Theoretically, covmat should be positive
        %   semidefinite but this is not guaranteed in floating point
        %   arithmetic. M-by-1 vectors ynew can be simulated from a Normal
        %   distribution with mean pred and covariance covmat using cholcov
        %   or svd and randn.
        %
        %   [pred,covmat,ci] = predictExactWithCov(this,Xnew,alpha) also
        %   computes a M-by-2 matrix ci such that ci(i,:) contains a
        %   100*(1-alpha)% confidence interval for ynew(i). The first
        %   column of ci contains lower bounds and the second column
        %   contains upper bounds.
        %
        %   NOTE:
        %   Let sd(i) = sqrt(covmat(i,i)), then the confidence interval is
        %   constructed under the assumption that ynew(i) has a Normal
        %   distribution with mean pred(i) and variance sd(i)^2. See eq.
        %   279 in GPR theory spec. When parameters are estimated from
        %   data, beta, theta and sigma^2 in eq. 279 are replaced by their
        %   estimated values.
            
            % 1. Ensure that alpha is sensible and model is trained.
            assert( alpha >= 0 && alpha <= 1 );
            assert( this.IsTrained );
            
            % 2. Training X and number of observations.
            X = this.ActiveSetX;
            N = size(X,1);
            
            % 3. If Standardize is true, apply D-by-1 vectors StdMu and
            % StdSigma to columns of Xnew. Assume Xnew has been validated.
            if ( this.Standardize == true )
                Xnew = bsxfun(@rdivide,bsxfun(@minus,Xnew,this.StdMu'),this.StdSigma');
            end
            
            % 4. Get estimated coefficients.
            alphaHat = this.AlphaHat;
            betaHat  = this.BetaHat;
            thetaHat = this.ThetaHat;
            sigmaHat = this.SigmaHat;
            
            % 5. Get basis function.
            HFcn = this.HFcn; %#ok<PROPLC,*PROP>
            
            % 6. Make kernel function for thetaHat. kfun below can be
            % called like this: KNM = kfun(XN,XM)
            kfun = makeKernelAsFunctionOfXNXM(this.Kernel,thetaHat);
            
            % 7. How many rows in Xnew?
            M = size(Xnew,1);
            
            % 8. Do we want covmat?
            if nargout > 1
                wantcovmat = true;
            else
                wantcovmat = false;
            end
            
            % 9. Do we want ci?
            if nargout > 2
                wantci = true;
            else
                wantci = false;
            end
            
            % 10. Get Cholesky factor L if we want covmat or ci. This
            % should be stored in property LFactor. If not, compute it from
            % scratch.
            if ( wantcovmat || wantci )
                if isempty(this.LFactor)
                    % Compute from scratch.
                    L = computeLFactorExact(this,X,thetaHat,sigmaHat);
                else
                    % Reuse previous value.
                    L = this.LFactor;
                    assert(size(L,1) == N);
                end
            end
            
            % 11. Get M-by-N matrix K(Xnew,X) and M-by-M matrix K(Xnew,Xnew).
            KXnewX    = kfun(Xnew,X);
            KXnewXnew = kfun(Xnew,Xnew);
            
            % 12. Compute M-by-1 vector pred.
            if isempty(betaHat)
                pred = KXnewX*alphaHat;
            else
                pred = HFcn(Xnew)*betaHat + KXnewX*alphaHat; %#ok<PROPLC>
            end
            
            % 13. Compute M-by-M matrix covmat. Theoretically, covmat
            % should be positive semidefinite but we do not check this. We
            % do ensure that diagonal elements of covmat are >= 0 and that
            % covmat is symmetric.
            if wantcovmat
                LInvKXXnew        = L \ (KXnewX');
                covmat            = KXnewXnew - (LInvKXXnew'*LInvKXXnew);
                covmat(1:M+1:M^2) = max(0,covmat(1:M+1:M^2) + sigmaHat^2);
            end
            covmat = (covmat + covmat')/2;
            
            % 14. Compute M-by-2 matrix ci. zcrit is such that: 
            % normcdf(zcrit) = 1-alpha/2.
            if wantci
                zcrit = -norminv(alpha/2);
                sd    = sqrt(diag(covmat));
                delta = zcrit*sd;
                ci    = [pred - delta, pred + delta];
            end
            
        end % end of predictExactWithCov.        
    end
    
end

