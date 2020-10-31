classdef (Abstract) FeatureSelectionNCAImpl < classreg.learning.internal.DisallowVectorOps

    %   Copyright 2015-2016 The MathWorks, Inc.    
    
    %% Properties holding computed values.
    properties
        FitInfo;                % Fit information.
        FeatureWeights;         % Feature weights.
        Mu;                     % Predictor means if predictor standardization is applied.
        Sigma;                  % Predictor standard deviations if predictor standardization is applied.
    end
    
    properties
        %IsFitted - True if this is a fitted model.
        %   The IsFitted property is a scalar indicating whether this is a
        %   fitted model or not. Unfitted models can be created by setting
        %   'DoFit' to false in the call to fsrnca or fscnca. The 'DoFit'
        %   name/value pair is not documented. An unfitted model can be fit
        %   later by calling the refit method.
        IsFitted;
        
        %Partition - Data partition used for divide and conquer fitting.
        %   The Partition property is an object of type cvpartition
        %   specifying how the data are split into chunks for 'FitMethod'
        %   equal to 'average'.
        Partition;
        
        %PrivObservationWeights - Effective observation weights.
        %   The PrivObservationWeights property is a N-by-1 vector of
        %   effective observation weights which represents the net effect
        %   of the passed in 'Weights' and 'Prior' for classification. For
        %   regression, this vector is the same as the passed in
        %   observation weights.
        PrivObservationWeights;
    end    
    
    %% Properties holding inputs.
    properties(Dependent)
        X;                      % Unstandardized matrix of predictors.
        W;                      % Observation weights.
        ModelParameters;        % Model parameters.
    end
    
    properties
        PrivX;                  % This is the standardized matrix of predictors of this.Mu and this.Sigma are not empty.
        PrivW;                  % Observation weights, same as W.
        ModelParams;            % Model parameters - same as ModelParameters.
    end
    
    properties(Abstract,Dependent)
        Y;                      % Response vector in original form.
    end
    
    properties(Abstract)
        PrivY;                  % Numeric response vector of real values or IDs.
    end
    
    properties(Dependent)
        Lambda;                 % Regularization parameter.
        FitMethod;              % Fitting method.
        Solver;                 % Solver used to fit this model.
        GradientTolerance;      % Tolerance on gradient norm.
        IterationLimit;         % Maximum number of iterations for optimization.
        PassLimit;              % Maximum number of passes.
        InitialLearningRate;    % Initial learning rate.
        Verbose;                % Verbosity level.
        InitialFeatureWeights;  % Initial feature weights.
        NumObservations;        % Number of observations.
        NumFeatures;            % Number of features.
    end
    
    %% Getters for dependent properties.
    methods
        function X = get.X(this)
            if ( this.ModelParams.Standardize && ~isempty(this.Mu) && ~isempty(this.Sigma) )
                sigmaX = this.Sigma;
                muX    = this.Mu;
                X      = bsxfun(@plus,bsxfun(@times,this.PrivX,sigmaX(:)'),muX(:)');
            else
                X      = this.PrivX;
            end
        end
        
        function W = get.W(this)
            W = this.PrivW;
        end
        
        function mp = get.ModelParameters(this)
            mp = this.ModelParams;
        end
        
        function lambda = get.Lambda(this)
            lambda = this.ModelParams.Lambda;
        end
        
        function fitMethod = get.FitMethod(this)
            fitMethod = this.ModelParams.FitMethod;
        end
        
        function solver = get.Solver(this)
            solver = this.ModelParams.Solver;
        end
        
        function gradientTolerance = get.GradientTolerance(this)
            gradientTolerance = this.ModelParams.GradientTolerance;
        end
        
        function iterationLimit = get.IterationLimit(this)
            iterationLimit = this.ModelParams.IterationLimit;
        end
        
        function passLimit = get.PassLimit(this)
            passLimit = this.ModelParams.PassLimit;
        end
        
        function initialLearningRate = get.InitialLearningRate(this)
            initialLearningRate = this.ModelParams.InitialLearningRate;
        end
        
        function verbose = get.Verbose(this)
            verbose = this.ModelParams.Verbose;
        end
        
        function initialFeatureWeights = get.InitialFeatureWeights(this)
            initialFeatureWeights = this.ModelParams.InitialFeatureWeights;
        end
        
        function N = get.NumObservations(this)
            N = size(this.PrivX,1);
        end
        
        function P = get.NumFeatures(this)
            P = size(this.PrivX,2);
        end
    end
    
    %%  Constructor.
    methods
        function this = FeatureSelectionNCAImpl(X,privW,modelParams)
            % X should be the unstandardized data. It is saved in PrivX to
            % be standardized later (if needed).
            this.PrivX       = X;
            this.PrivW       = privW;
            this.ModelParams = modelParams;
            
            this.IsFitted    = false;            
            this.Mu          = [];
            this.Sigma       = [];
        end
    end
    
    %% Objective function makers.
    methods(Abstract)
        fun = makeObjectiveFunctionForMinimization(this)
        fun = makeObjectiveFunctionForMinimizationMex(this)
    end
    
    %% Helpers for objective function makers.
    methods
        function fun = makeRegularizedObjectiveFunctionForMinimizationRobustMex(this,X,y,lossID,epsilon)
            %   Make regularized NCA objective function for feature selection.
            %   INPUTS:
            %   X       = a P-by-N predictor matrix X where P is the number of
            %             predictors and N is the number of observations.
            %             Notice that every column is one observation in this
            %             function. X must be a full matrix.
            %   y       = N-by-1 numeric vector containing the observed
            %             response values.
            %   lossID  = an integer ID representing the loss function of
            %             interest. Choices are:
            %
            %             LOSS FUNCTION NAME             ID
            %             classiferror          -        1
            %             l1  (mad)             -        2
            %             l2  (mse)             -        3
            %             epsiloninsensitive    -        4
            %             custom loss function  -        5
            %
            %   epsilon = value of epsilon for epsiloninsensitive loss.
            %
            %   When using custom robust loss functions lossID will be a
            %   function handle.
            %
            %   OUTPUTS:
            %   fun = A function handle. Suppose w is P-by-1 feature weight
            %         vector. Then fun can be called either of the following
            %         ways:
            %
            %   (a) [f,g] = fun(w)
            %
            %       f = f(w) given in section 8 of theory spec.
            %       g = gradient of f at w.
            %
            %   (b) [f,g] = fun(w,T)
            %
            %       T = a row vector that is a subset of {1,2,...,N}.
            %       f = f(w,T) given in section 8 of theory spec.
            %       g = gradient of f at w.
            %
            %       When T = 1:N then fun(w,T) = fun(w).
            %
            %   See section 8 in theory spec for a description of loss
            %   functions.
            
            % 1. Get lambda, sigma, observation weights and grainsize.
            lambda    = this.ModelParams.Lambda;
            sigma     = this.ModelParams.LengthScale;
            obswts    = this.PrivObservationWeights;
            grainsize = this.ModelParams.GrainSize;
            [P,N]     = size(X);
            allpoints = 1:N;
            
            % 2. If we are dealing with a custom loss function, copy lossID
            % into lossFcn and set lossID to mark a custom loss function.
            if ( isa(lossID,'function_handle') )
                lossFcn = lossID;
                lossID  = classreg.learning.fsutils.FeatureSelectionNCAModel.CUSTOM_LOSS;
            else
                lossFcn = [];
            end
            
            % 3. Convert all inputs to single or double based on X. Note
            % that X is a full matrix already. We ensure that all other
            % inputs are also full.
            if ( isa(X,'double') )
                convertToDoubleFcn = @(xx) full(classreg.learning.fsutils.FeatureSelectionNCAModel.convertToDouble(xx));
                
                y               = convertToDoubleFcn(y);
                P               = convertToDoubleFcn(P);
                N               = convertToDoubleFcn(N);
                allpoints       = convertToDoubleFcn(allpoints);
                lambda          = convertToDoubleFcn(lambda);
                sigma           = convertToDoubleFcn(sigma);
                obswts          = convertToDoubleFcn(obswts);
                lossID          = convertToDoubleFcn(lossID);
                epsilon         = convertToDoubleFcn(epsilon);
                grainsize       = convertToDoubleFcn(grainsize);
                haveDoubleInput = true;
            elseif ( isa(X,'single') )
                convertToSingleFcn = @(xx) full(classreg.learning.fsutils.FeatureSelectionNCAModel.convertToSingle(xx));
                
                y               = convertToSingleFcn(y);
                P               = convertToSingleFcn(P);
                N               = convertToSingleFcn(N);
                allpoints       = convertToSingleFcn(allpoints);
                lambda          = convertToSingleFcn(lambda);
                sigma           = convertToSingleFcn(sigma);
                obswts          = convertToSingleFcn(obswts);
                lossID          = convertToSingleFcn(lossID);
                epsilon         = convertToSingleFcn(epsilon);
                grainsize       = convertToSingleFcn(grainsize);
                haveDoubleInput = false;
            else
                error(message('stats:classreg:learning:fsutils:FeatureSelectionNCAModel:UnSupportedXType'));
            end
            
            fun = @ncfsobj;
            function [obj,gradobj] = ncfsobj(w,T)
                % 4. If T is not supplied, assume we want the full
                % objective function.
                if ( nargin < 2 )
                    T = allpoints;
                elseif ( ~issorted(T) )
                    T = sort(T);
                end
                M = length(T);
                
                if haveDoubleInput
                    T = convertToDoubleFcn(T);
                    M = convertToDoubleFcn(M);
                    w = convertToDoubleFcn(w);
                else
                    T = convertToSingleFcn(T);
                    M = convertToSingleFcn(M);
                    w = convertToSingleFcn(w);
                end
                
                % 5. Do we want the gradient?
                if ( nargout > 1 )
                    wantgrad = true;
                else
                    wantgrad = false;
                end
                
                % 6. Call mex function.
                if ( isempty(lossFcn) )
                    % Built in loss function.
                    if haveDoubleInput
                        lossMat = NaN('double');
                    else
                        lossMat = NaN('single');
                    end
                    if wantgrad
                        [obj,gradobj] = classreg.learning.fsutils.objgrad(X,y,P,N,T(:),M,lambda,sigma,w,lossID,epsilon,grainsize,lossMat,obswts);
                    else
                        obj           = classreg.learning.fsutils.objgrad(X,y,P,N,T(:),M,lambda,sigma,w,lossID,epsilon,grainsize,lossMat,obswts);
                    end
                else
                    % Custom loss function.
                    classX = class(X);
                    obj = zeros(1,1,classX);
                    if wantgrad
                        gradobj = zeros(P,1,classX);
                    end
                    
                    % Process M observations in T in chunks of size B such
                    % that a N-by-B matrix of doubles (8 bytes) can fit in
                    % the specified cache size. Of course, B >= 1. T is
                    % split into numchunks each of size B. The last chunk
                    % captures any remaining observations. numchunks can be
                    % 0.
                    cacheSizeMB = this.ModelParams.CacheSize;
                    B           = max(1,floor(cacheSizeMB*1e6/(8*N)));
                    numchunks   = floor(M/B);
                    
                    for c = 1:(numchunks+1)
                        if ( c < numchunks+1 )
                            % not last chunk.
                            idx = (c-1)*B+1:c*B;
                        else
                            % last chunk.
                            idx = numchunks*B+1:M;
                        end
                        
                        if ( ~isempty(idx) )
                            Tc      = T(idx);
                            Mc      = length(Tc);
                            lossMat = lossFcn(y,y(Tc(:))); % N-by-Mc matrix.
                            
                            isok = all(size(lossMat) == [N,Mc]);
                            if ~isok
                                error(message('stats:classreg:learning:fsutils:FeatureSelectionNCAModel:BadCustomLossFunctionResult'));
                            end
                            
                            if haveDoubleInput
                                lossMat = convertToDoubleFcn(lossMat);
                                Tc      = convertToDoubleFcn(Tc);
                                Mc      = convertToDoubleFcn(Mc);
                            else
                                lossMat = convertToSingleFcn(lossMat);
                                Tc      = convertToSingleFcn(Tc);
                                Mc      = convertToSingleFcn(Mc);
                            end
                            
                            if wantgrad
                                [objc,gradobjc] = classreg.learning.fsutils.objgrad(X,y,P,N,Tc(:),Mc,lambda,sigma,w,lossID,epsilon,grainsize,lossMat,obswts);
                                obj             = obj + objc*Mc;
                                gradobj         = gradobj + gradobjc*Mc;
                            else
                                objc            = classreg.learning.fsutils.objgrad(X,y,P,N,Tc(:),Mc,lambda,sigma,w,lossID,epsilon,grainsize,lossMat,obswts);
                                obj             = obj + objc*Mc;
                            end
                        end
                    end
                    
                    obj = obj/M;
                    if wantgrad
                        gradobj = gradobj/M;
                    end
                end
            end
        end
        
        function fun = makeRegularizedObjectiveFunctionForMinimizationRobust(this,X,y,lossFcn)
            %   Make regularized NCA objective function for feature selection.
            %   INPUTS:
            %   X       = a P-by-N predictor matrix X where P is the number of
            %             predictors and N is the number of observations.
            %             Notice that every column is one observation in this
            %             function.
            %   y       = N-by-1 numeric vector containing the observed
            %             response values.
            %   lossFcn = a function handle that can be called like this:
            %
            %             L = lossFcn(yi,yj)
            %
            %             o yi is a N-by-1 vector.
            %             o yj is a M-by-1 vector.
            %             o L  is a N-by-M matrix.
            %
            %   OUTPUTS:
            %   fun = A function handle. Suppose w is P-by-1 feature weight
            %         vector. Then fun can be called either of the following
            %         ways:
            %
            %   (a) [f,g] = fun(w)
            %
            %       f = f(w) given in section 8 of theory spec.
            %       g = gradient of f at w.
            %
            %   (b) [f,g] = fun(w,T)
            %
            %       T = a row vector that is a subset of {1,2,...,N}.
            %       f = f(w,T) given in section 8 of theory spec.
            %       g = gradient of f at w.
            %
            %       When T = 1:N then fun(w,T) = fun(w).
            %
            %   See section 8 in theory spec for a description of loss
            %   functions.
            
            % 1. Get lambda, sigma and 1-by-N observation weights.
            lambda    = this.ModelParams.Lambda;
            sigma     = this.ModelParams.LengthScale;
            [P,N]     = size(X);
            allpoints = 1:N;
            obswts    = this.PrivObservationWeights';
            
            % 2. Convert all inputs to single or double based on X.
            if ( isa(X,'double') )
                convertToDoubleFcn = @(xx) classreg.learning.fsutils.FeatureSelectionNCAModel.convertToDouble(xx);
                
                y               = convertToDoubleFcn(y);
                P               = convertToDoubleFcn(P);
                N               = convertToDoubleFcn(N);
                allpoints       = convertToDoubleFcn(allpoints);
                lambda          = convertToDoubleFcn(lambda);
                sigma           = convertToDoubleFcn(sigma);
                obswts          = convertToDoubleFcn(obswts);
                haveDoubleInput = true;
            elseif ( isa(X,'single') )
                convertToSingleFcn = @(xx) classreg.learning.fsutils.FeatureSelectionNCAModel.convertToSingle(xx);
                
                y               = convertToSingleFcn(y);
                P               = convertToSingleFcn(P);
                N               = convertToSingleFcn(N);
                allpoints       = convertToSingleFcn(allpoints);
                lambda          = convertToSingleFcn(lambda);
                sigma           = convertToSingleFcn(sigma);
                obswts          = convertToSingleFcn(obswts);
                haveDoubleInput = false;
            else
                error(message('stats:classreg:learning:fsutils:FeatureSelectionNCAModel:UnSupportedXType'));
            end
            
            fun = @ncfsobj;
            function [obj,gradobj] = ncfsobj(w,T)
                % 3. If T is not supplied, assume we want the full
                % objective function.
                if ( nargin < 2 )
                    T = allpoints;
                elseif ( ~issorted(T) )
                    T = sort(T);
                end
                M = length(T);
                
                if haveDoubleInput
                    T = convertToDoubleFcn(T);
                    M = convertToDoubleFcn(M);
                    w = convertToDoubleFcn(w);
                else
                    T = convertToSingleFcn(T);
                    M = convertToSingleFcn(M);
                    w = convertToSingleFcn(w);
                end
                
                % 4. Do we want the gradient?
                if ( nargout > 1 )
                    wantgrad = true;
                else
                    wantgrad = false;
                end
                
                % 5. Initialize objective function and its gradient.
                classX = class(X);
                obj = zeros(1,1,classX);
                if wantgrad
                    gradobj = zeros(P,1,classX);
                end
                
                % 6. Accumulate loss li and its gradient as i varies over
                % elements of T where T is a subset of {1,2,...,N}. Divide
                % the accumulated values by length(T). Then add the
                % contribution of the regularization term to the objective
                % and gradient.
                wsquared = w.^2;
                
                for i = T
                    % 6.1 Current observation.
                    xi = X(:,i);
                    yi = y(i);
                    
                    % 6.2 P-by-N matrix dist such that:
                    %       dist(r,j) = |x_ir - x_jr|
                    % where
                    %       x_ir = r th element of x_i and
                    %       x_jr = r th element of x_j.
                    dist = abs(bsxfun(@minus,X,xi));
                    
                    % 6.3 1-by-N vector of weighted distances between xi
                    % and observations in X. Set wtdDist(i) to Inf since we
                    % are not interested in the distance of xi to itself.
                    % The subtraction of min(wtdDist) from wtdDist ensures
                    % that sum(pij) is not zero.
                    wtdDist    = sum(bsxfun(@times,dist,wsquared),1);
                    wtdDist(i) = inf(classX);
                    wtdDist    = wtdDist - min(wtdDist);
                    
                    % 6.4 Compute 1-by-N vector of probabilities pij.
                    pij = obswts.*exp(-wtdDist/sigma);
                    pij = pij/sum(pij);
                    
                    % 6.5 Compute pij*lossFcn(yi,yj) for all j.
                    lossMat = lossFcn(yi,y);
                    isok = all(size(lossMat) == [1,N]);
                    if ~isok
                        error(message('stats:classreg:learning:fsutils:FeatureSelectionNCAModel:BadCustomLossFunctionResult'));
                    end
                    pijlij = pij.*lossMat;
                    
                    % 6.6 Compute li.
                    li = sum(pijlij);
                    
                    % 6.7 Update obj.
                    obj = obj + li;
                    
                    % 6.8 Compute gradient of li w.r.t. w and update
                    % gradobj if needed.
                    if wantgrad
                        g       = sum(bsxfun(@times,li*pij-pijlij,dist),2);
                        gradobj = gradobj + g;
                    end
                end
                obj = obj/M;
                if wantgrad
                    gradobj = ((2*w/sigma).*gradobj)/M;
                end
                
                % 7. Add contribution of the regularization term.
                obj = obj + lambda*sum(wsquared);
                if wantgrad
                    gradobj = gradobj + 2*lambda*w;
                end
            end
        end
    end
    
    %% Utilities for building the model.
    methods
        function XTest = applyStandardizationToXTest(this,XTest)
            if ( this.ModelParams.Standardize && ~isempty(this.Mu) && ~isempty(this.Sigma) )
                XTest = bsxfun(@rdivide,bsxfun(@minus,XTest,this.Mu'),this.Sigma');
            end
        end
        
        function this = standardizeData(this)
            if this.ModelParams.Standardize
                [this.PrivX,muX,sigmaX] = classreg.learning.gputils.standardizeData(this.X);
                this.Mu    = muX;
                this.Sigma = sigmaX;
            else
                this.Mu    = [];
                this.Sigma = [];
            end
        end
        
        function this = standardizeDataAndBuildModel(this)
            this = standardizeData(this);
            this = buildModel(this);
        end
        
        function this = buildModel(this)
            % Build model using the right FitMethod. This method sets
            % FeatureWeights and FitInfo in the object. It also marks the
            % object as fitted or not.
            
            % 1. Compute effective observation weights by combining
            % observation weights with class prior.
            this.PrivObservationWeights = effectiveObservationWeights(this,this.PrivW,this.ModelParams.Prior);
            
            % 2. Dispatch to the appropriate FitMethod.
            if ( this.ModelParams.DoFit == false )
                this.FeatureWeights = abs(this.ModelParams.InitialFeatureWeights);
                this.FitInfo        = [];
                this.IsFitted       = false;
            else
                switch lower(this.ModelParams.FitMethod)
                    case lower(classreg.learning.fsutils.FeatureSelectionNCAModel.FitMethodNone)
                        this = buildModelNone(this);
                        
                    case lower(classreg.learning.fsutils.FeatureSelectionNCAModel.FitMethodExact)
                        this = buildModelExact(this);
                        
                    case lower(classreg.learning.fsutils.FeatureSelectionNCAModel.FitMethodDivideAndConquer)
                        this = buildModelDivideAndConquer(this);
                end
                this.IsFitted = true;
            end
        end

        function this = buildModelDivideAndConquer(this)
            % 1. Make cvpartition object.
            cvp = makeCVPartitionObject(this,'kfold',this.ModelParams.NumPartitions);
            
            % 2. Compute weights for each chunk.
            numChunks      = cvp.NumTestSets;
            P              = this.NumFeatures;
            featureWeights = zeros(P,numChunks);
            fitInfo        = cell(numChunks,1);
            
            % 3. Train on each chunk and save results.
            for k = 1:numChunks
                % 3.1 Chunk for fold k.
                testIdx = cvp.test(k);
                XTest   = this.X(testIdx,:);
                YTest   = this.PrivY(testIdx,:);
                WTest   = this.PrivW(testIdx,:);
                
                % 3.2 Train on chunk k using 'FitMethod' equal to 'exact'.
                % We want to fit the model right away, so set 'DoFit' to
                % true.
                modelParams                 = this.ModelParams;
                modelParams.DoFit           = true;
                modelParams.NumObservations = size(XTest,1);
                modelParams.FitMethod       = classreg.learning.fsutils.FeatureSelectionNCAModel.FitMethodExact;
                
                nca             = this;
                nca.PrivX       = XTest;
                nca.PrivY       = YTest;
                nca.PrivW       = WTest;
                nca.ModelParams = modelParams;
                nca.Mu          = [];
                nca.Sigma       = [];
                nca             = standardizeDataAndBuildModel(nca);
                
                % 3.3 Save feature weights.
                featureWeights(:,k) = nca.FeatureWeights;
                
                % 3.4 Save fit info.
                fitInfo{k} = nca.FitInfo;
            end
            
            % 4. Save feature weights and fit info into object.
            this.FeatureWeights = featureWeights;
            this.FitInfo        = cell2mat(fitInfo);
            
            % 5. Save partition info into the object.
            this.Partition = cvp;
        end
        
        function this = buildModelNone(this)
            % For 'FitMethod' equal to 'None', we don't do any fit.
            this.FeatureWeights = abs(this.ModelParams.InitialFeatureWeights);
            this.FitInfo        = [];
        end
        
        function this = buildModelExact(this)
            % 1. Make objective function for minimization.
            computationMode = this.ModelParams.ComputationMode;
            usemex          = strcmpi(computationMode,classreg.learning.fsutils.FeatureSelectionNCAModel.ComputationModeMex);
            if usemex
                fun = makeObjectiveFunctionForMinimizationMex(this);
            else
                fun = makeObjectiveFunctionForMinimization(this);
            end
            
            % 2. Get initial point.
            w0 = this.ModelParams.InitialFeatureWeights;
            
            % 3. Pass fun and w0 to an optimizer.
            [wHat,fitInfo] = doMinimization(this,fun,w0);
            
            % 4. Save outputs into object.
            this.FeatureWeights = abs(wHat);
            this.FitInfo        = fitInfo;
        end
        
        function [wHat,fitInfo] = doMinimization(this,fun,w0)
            %doMinimization - Minimize objective function fun.
            %   [wHat,fitInfo] = doMinimization(this,fun,w0) takes an object
            %   this of type FeatureSelectionNCAImpl, a handle to an objective
            %   function fun, an initial point w0 and returns wHat, the
            %   minimizer of fun starting from w0. fitInfo is a structure
            %   containing the iteration history with the following fields:
            %
            %       Iteration              - Iteration index.
            %       Objective              - Regularized objective function for
            %                                minimization.
            %       UnregularizedObjective - Unregularized objective function
            %                                for minimization.
            %       Gradient               - Final gradient vector.
            
            % 1. Are we using SGD (maybe via minibatch-LBFGS)?
            haveLBFGS = strcmpi(this.ModelParams.Solver,classreg.learning.fsutils.FeatureSelectionNCAModel.SolverLBFGS);
            if haveLBFGS
                haveSGD = false;
            else
                haveSGD = true;
            end
            
            % 2. Make a solver object.
            N      = this.NumObservations;
            solver = classreg.learning.fsutils.Solver(N);
            
            % 3. Copy options from ModelParams into the solver object. Mark
            % that our objective function has gradient info available.
            solver.NumComponents            = N;
            solver.SolverName               = this.ModelParams.Solver;
            solver.HessianHistorySize       = this.ModelParams.HessianHistorySize;
            solver.InitialStepSize          = this.ModelParams.InitialStepSize;
            solver.LineSearchMethod         = this.ModelParams.LineSearchMethod;
            solver.MaxLineSearchIterations  = this.ModelParams.MaxLineSearchIterations;
            solver.GradientTolerance        = this.ModelParams.GradientTolerance;
            solver.InitialLearningRate      = this.ModelParams.InitialLearningRate;
            solver.MiniBatchSize            = this.ModelParams.MiniBatchSize;
            solver.PassLimit                = this.ModelParams.PassLimit;
            solver.NumPrint                 = this.ModelParams.NumPrint;
            solver.NumTuningIterations      = this.ModelParams.NumTuningIterations;
            solver.TuningSubsetSize         = this.ModelParams.TuningSubsetSize;
            solver.IterationLimit           = this.ModelParams.IterationLimit;
            solver.StepTolerance            = this.ModelParams.StepTolerance;
            solver.MiniBatchLBFGSIterations = this.ModelParams.MiniBatchLBFGSIterations;
            solver.Verbose                  = this.ModelParams.Verbose;
            solver.HaveGradient             = true;
            
            % 4. Regularization parameter.
            lambda = this.ModelParams.Lambda;
            
            % 5. Structure to hold history information.
            % * fval is the objective function value. For SGD, it is the
            %   minibatch function value.
            % * iter is the iteration index.
            % * acc  is the negative of NCA accuracy.
            % * grad is the final gradient. For SGD, it is the minibatch
            %   gradient.
            history      = struct();
            history.fval = [];
            history.iter = [];
            history.acc  = [];
            history.grad = [];
            
            % 6. Set up output function.
            function stop = outfun(x,optimValues,state)
                history.iter = [history.iter; optimValues.iteration];
                history.fval = [history.fval; optimValues.fval];
                history.acc  = [history.acc ; optimValues.fval - lambda*(x'*x)];
                stop         = false;
                if ( haveSGD && strcmpi(state,'done') )
                    history.grad = optimValues.gradient;
                end
            end
            
            % 7. Do minimization.
            results = doMinimization(solver,fun,w0,N,'OutputFcn',@outfun);
            
            % 8. Set wHat.
            wHat = results.xHat;
            
            % 9. Set fitInfo.
            fitInfo                        = struct();
            fitInfo.Iteration              = history.iter;
            fitInfo.Objective              = history.fval;
            fitInfo.UnregularizedObjective = history.acc;
            
            if haveSGD
                fitInfo.Gradient = history.grad;
            else
                fitInfo.Gradient = results.gHat;
            end
        end
    end
    
    %% Cross validation helper.
    methods
        function [cvp,extraArgs] = makeCVPartitionObject(this,varargin)
            %makeCVPartitionObject - Make cvpartition object.
            %   cvp = makeCVPartitionObject(this,varargin) takes an object this
            %   of type FeatureSelectionNCAImpl and a set of name value pairs
            %   and makes a cvpartition object for use in cross-validation.
            %   Only one of the following name value pairs can be used at a
            %   time:
            %
            %        'KFold'       - Number of folds for cross-validation, a numeric
            %                        positive scalar; 10 by default.
            %        'Holdout'     - Holdout validation uses the specified
            %                        fraction of the data for test, and uses the rest of
            %                        the data for training. Specify a numeric scalar
            %                        between 0 and 1.
            %        'Leaveout'    - If 'on', use leave-one-out cross-validation.
            %        'CVPartition' - An object of class CVPARTITION; empty by default. If
            %                        a CVPARTITION object is supplied, it is used for
            %                        splitting the data into subsets.
            %
            %   [cvp,extraArgs] = makeCVPartitionObject(this,varargin) also
            %   returns extra arguments passed in to this function other than
            %   the ones listed above.
            
            % 1. Set parameter defaults.
            dfltKFold       = 10;
            dfltHoldout     = [];
            dfltLeaveout    = [];
            dfltCVPartition = [];
            
            % 2. Parse optional name/value pairs.
            paramNames = {  'KFold',   'Holdout',   'Leaveout',   'CVPartition'};
            paramDflts = {dfltKFold, dfltHoldout, dfltLeaveout, dfltCVPartition};
            [kfold,holdout,leaveout,cvp,setflag,extraArgs] = internal.stats.parseArgs(paramNames,paramDflts,varargin{:});
            
            % 3. Validate leaveout and cvp. kfold and holdout are validated
            % by the cvpartition call later.
            N = this.NumObservations;
            
            if ( ~isempty(leaveout) )
                leaveout = internal.stats.getParamVal(leaveout,{'on' 'off'},'Leaveout');
            end
            
            if ( ~isempty(cvp) )
                isok = isa(cvp,'cvpartition') && (cvp.NumObservations == N);
                if ~isok
                    error(message('stats:classreg:learning:fsutils:FeatureSelectionNCAModel:BadCVPartition',N));
                end
            end
            
            % 4. Ensure that only 1 of the 4 options is specified.
            numSupplied = setflag.KFold + setflag.Holdout + setflag.Leaveout + setflag.CVPartition;
            if ( numSupplied > 1 )
                error(message('stats:classreg:learning:fsutils:FeatureSelectionNCAModel:BadCVSelection'));
            end
            
            % 5. Create the cvpartition object.
            if setflag.Holdout
                % Holdout.
                if ( strcmpi(this.ModelParams.Method,classreg.learning.fsutils.FeatureSelectionNCAModel.MethodClassification) )
                    cvp = cvpartition(this.PrivY,'HoldOut',holdout);
                else
                    cvp = cvpartition(N,'HoldOut',holdout);
                end
            elseif ( setflag.Leaveout && strcmpi(leaveout,'on') )
                % Leaveout.
                cvp = cvpartition(N,'LeaveOut');
            elseif setflag.CVPartition
                % CVPartition.
            else
                % KFold.
                if ( strcmpi(this.ModelParams.Method,classreg.learning.fsutils.FeatureSelectionNCAModel.MethodClassification) )
                    cvp = cvpartition(this.PrivY,'KFold',kfold);
                else
                    cvp = cvpartition(N,'KFold',kfold);
                end
            end
        end
    end
    
    %% Utility for computing effective observation weights.
    methods (Abstract)
        effobswts = effectiveObservationWeights(this,obswts,prior)
    end
    
    %% Helpers for making predictions.
    methods(Abstract)
        output = predictNCAMex(this,XTest)
        output = predictNCA(this,XTest)
    end
    
end

