classdef RegressionKernel < ...
        classreg.learning.regr.RegressionModel & classreg.learning.Kernel
%RegressionKernel Kernel model for regression.
%   RegressionKernel is a kernel model for regression for which the
%   predictors are explicitly mapped to a high dimensional space.  
%
%   RegressionKernel properties:
%       BoxConstraint          - Box constraint for SVM
%       Epsilon                - Half of the width of the epsilon-insensitive band for SVM
%       ExpandedPredictorNames - Names of expanded predictors
%       NumExpansionDimensions - Number of dimensions of expanded space
%       FittedLoss             - Fitted loss function, 'epsiloninsensitive' or 'mse'
%       KernelScale            - Kernel scale
%       Lambda                 - Regularization strength
%       Learner                - Learned model, 'svm' or 'leastsquares'
%       PredictorNames         - Names of predictors used for this model
%       ResponseName           - Name of the response variable
%       ResponseTransform      - Transformation applied to predicted response values
%
%   RegressionKernel methods:
%       loss                  - Regression loss
%       predict               - Predicted response of this model
%       resume                - Continue fitting this model

    %   Copyright 2017 The MathWorks, Inc.
    
    properties(GetAccess=protected,SetAccess=protected,Hidden=true)
        FitInfo = [];
    end
    
    properties(GetAccess=public,SetAccess=protected)
        %Epsilon Epsilon-insensitive band
        %   The Epsilon property is a non negative scalar specifying half
        %   the width of the epsilon-insensitive band. Epsilon applies to
        %   SVM learners only. 
        %
        %   See also RegressionKernel.
        Epsilon = [];
        
        %BoxConstraint Regularization strength.
        %   The BoxConstraint property is a non negative scalar used to
        %   control the strength of regularization. BoxConstraint applies
        %   to SVM learners only. BoxConstraint and Lambda are related by:
        %
        %               BoxConstraint * Lambda = 1 / N
        %
        %   where N is the number of observation in the training set.
        %  
        %   See also ClassificationKernel, RegressionKernel.        
        BoxConstraint = [];
    end
    
    methods(Hidden)
        function this = RegressionKernel(dataSummary,responseTransform)
            % Protect against being called by the user
            if ~isstruct(dataSummary)
                error(message('stats:RegressionKernel:DoNotUseConstructor'));
            end
            
            this = this@classreg.learning.regr.RegressionModel(...
                dataSummary,responseTransform);
            this = this@classreg.learning.Kernel;
        end
        
        function cmp = compact(this)
            cmp = this;
        end
        
    end
    
    methods(Access=protected)
        function s = propsForDisp(this,s)
            s = propsForDisp@classreg.learning.regr.RegressionModel(this,s);
            s = propsForDisp@classreg.learning.Kernel(this,s);
            if strcmp(this.Learner,'svm') 
                s.BoxConstraint  = this.BoxConstraint;
                s.Epsilon        = this.Epsilon;
            end
            s = rmfield(s,'CategoricalPredictors');
            if strcmp(s.ResponseTransform,'none')
                s = rmfield(s,'ResponseTransform');
            end
        end
        
        function S = response(this,X)
            
            %Implements abstract RegressionModel/response
          
            X = X'; %Because ObsInRows is false
            [n,p] = size(X);
            if p~=this.FeatureMapper.d
                error(message('stats:RegressionKernel:XSizeMismatch',this.FeatureMapper.d))
            end
            
            maxChunkSize = RegressionKernel.estimateMaxChunkSize(this.FeatureMapper.n,this.ModelParams.BlockSize,false);
            numberChunks = ceil(n / maxChunkSize);
            
            if numberChunks<=1
                Xm = map(this.FeatureMapper,X,this.KernelScale);
                S = score(this.Impl,Xm,false,true); % doClass = false , obsInRows = true
            else
                % Block-wise
                S = cell(numberChunks,1);
                j = 1;
                for i = 1:numberChunks
                    k = min(n,j+maxChunkSize-1);
                    Xm = map(this.FeatureMapper,X(j:k,:),this.KernelScale);
                    S{i} = score(this.Impl,Xm,false,true); % doClass = false , obsInRows = true
                    j = j + maxChunkSize;
                end
                S = cell2mat(S);
            end
        end
    end
    
    methods    
        function  [model,fitinfo] = resume(this,X,Y,varargin)
        %RESUME Resume training of the model.
        %   MODEL_OUT = RESUME(MODEL,X,Y) continues training same model starting at
        %   the current estimated parameters. X is a N-by-P full matrix for N observations 
        %   and P predictors. Y is a floating-point vector with N elements. To effectively 
        %   continue the training, X and Y should be the same arrays used to initially fit 
        %   the model MODEL. 
        %
        %   [MODEL_OUT,FITINFO] = RESUME(...) also returns FITINFO, a struct containing fit
        %   information.
        %
        %   [...] = RESUME(MODEL,X,Y,'PARAM1',val1,'PARAM2',val2,...) specifies 
        %   optional name-value parameter pairs:        
        %   
        %            'Weights'  - Vector of observation weights, one weight per
        %                         observation. RESUME normalizes the weights to
        %                         add up to one. Default is equal weights.        
        %      'BetaTolerance'  - Relative tolerance on linear coefficients and
        %                         bias term. A non-negative scalar. Default
        %                         is same BetaTolerance value used to train
        %                         MODEL.
        %   'GradientTolerance' - Absolute gradient tolerance. A non-negative
        %                         scalar. Default is the same GradientTolerance value 
        %                         used to train MODEL. 
        %     'IterationLimit'  - Maximal number of extra optimization iterations. A
        %                         positive integer. Default is 1000 if the transformed
        %                         data fits in memory, 100 if the fitting algorithm 
        %                         switches to a block-wise strategy, or 20 if inputs
        %                         are tall.
        %
        %   See also fitrkernel, RegressionKernel.    
        
            args = {'weights'  'betatolerance'                    'gradienttolerance'                    'iterationlimit'};
            defs = {[]         this.ModelParameters.BetaTolerance this.ModelParameters.GradientTolerance []};
            [W,betaTolerance,gradientTolerance,iterationLimit] = internal.stats.parseArgs(args,defs,varargin{:});
            temp = RegressionKernel.template('Weights',W,...
                                  'BetaTolerance',betaTolerance,...
                                  'GradientTolerance',gradientTolerance,...
                                  'Epsilon',this.Epsilon,...  % Taken from object as ModelParams may have 'auto'
                                  'FitBias',this.ModelParameters.FitBias,...
                                  'HessianHistorySize',this.ModelParameters.HessianHistorySize,...
                                  'Learner',this.ModelParameters.Learner,...
                                  'Lambda',this.Lambda,... % Taken from object as ModelParams may have 'auto'
                                  'LineSearch',this.ModelParameters.LineSearch,...
                                  'LossFunction',this.ModelParameters.LossFunction,...
                                  'Regularization',this.ModelParameters.Regularization,...
                                  'Solver',this.ModelParameters.Solver,...
                                  'RandomStream',this.ModelParameters.Stream,...
                                  'Verbose',this.ModelParameters.VerbosityLevel,...
                                  'NumExpansionDimensions',this.NumExpansionDimensions,... % Taken from object as ModelParams may have 'auto'
                                  'KernelScale',this.KernelScale,... % Taken from object as ModelParams may have 'auto'
                                  'Transformation',this.ModelParameters.Transformation,...
                                  'BlockSize',this.ModelParameters.BlockSize,...
                                  'ADMMIterationLimit',0,... % No initialization needed when resuming
                                  'Consensus',this.ModelParameters.Consensus,...
                                  'InitialStepSize',this.ModelParameters.InitialStepSize);
                              
            % IterationLimit is handled differently as two parameters
            % depend on it (IterationLimit and IterationLimitBlockWise), 
            % if these parameters were defaulted in the original fit, they have
            % *different* values and we need to set them individually in the new
            % template. We cannot set them with the template constructor (as all 
            % other parameters) because they would be set to the same value.
            if ~isempty(iterationLimit)
                tempDummy = RegressionKernel.template('iterationLimit',iterationLimit);
                temp.ModelParams.IterationLimit = tempDummy.ModelParams.IterationLimit;
                temp.ModelParams.IterationLimitBlockWise = tempDummy.ModelParams.IterationLimitBlockWise;
            end
            
            %Starting point
            temp.ModelParams.InitialBeta = this.Beta;
            temp.ModelParams.InitialBias = this.Bias;
            temp.ModelParams.FeatureMapper = this.FeatureMapper;
            
            if this.FeatureMapper.d ~= gather(size(X,2)) 
                error(message('stats:RegressionKernel:XSizeMismatch',this.FeatureMapper.d))
            end
            if istall(X) || istall(Y) || istall(W)
                [model,fitinfo] = fitrkernel(X,Y,temp);
            else
                [model,fitinfo] = fit(temp,X,Y);
            end
            
            % Check if it is needed to concatenate the History of a
            % previous fit:
            if ~isempty(this.FitInfo.History)
               if isempty(fitinfo.History)
                   % Current fit did not return History, so only the
                   % previous History is copied:
                   fitinfo.History = this.FitInfo.History;
               else
                   % Concatenate both History structures
                   fns = fieldnames(fitinfo.History);
                   for i = 1:numel(fns)
                       fitinfo.History.(fns{i}) = [this.FitInfo.History.(fns{i});fitinfo.History.(fns{i})];
                   end
               end
               model.FitInfo.History = fitinfo.History;
            end
        
        end
        
        function [varargout] = predict(this,X,varargin)
        %PREDICT Predict responses of the model.
        %   YFIT=PREDICT(MODEL,X) returns predicted response for the
        %   regression model MODEL and  predictors X. X is a N-by-P matrix,
        %   where P is the number of predictors used for training MODEL.
        %   YFIT is a N-by-1 array of the same type as the response data
        %   (Y) used for training.
        %
        %   See also RegressionKernel.
            
            % Overrides RegressionModel/predict because tables are not supported 
            
            % Check for non supported tables (when it is tall, check will be done by the tall adapter)
            if ~istall(X)
                internal.stats.checkSupportedNumeric('X',X) 
            end
            % Call predict from base class
            [varargout{1:nargout}] = predict@classreg.learning.regr.RegressionModel(this,X,varargin{:});
        end
        
        function l = loss(this,X,Y,varargin)
        %LOSS Regression error.
        %   ERR=LOSS(MODEL,X,Y) returns mean squared error for the
        %   regression model MODEL using predictors X and observed response
        %   Y. X is a N-by-P matrix, where P is is the number of predictors
        %   used for training this model. Y must be a vector of floating-point
        %   numbers with N elements, where N is the number of observations
        %   (rows) in X.
        %
        %   ERR=LOSS(MODEL,X,Y,'PARAM1',val1,'PARAM2',val2,...) specifies optional
        %   name-value parameter pairs:
        %       'LossFun'          - Function handle for loss, or string
        %                            representing a built-in loss function.
        %                            Available loss functions for regression: 'mse'
        %                            and 'epsiloninsensitive'. If you pass a
        %                            function handle FUN, LOSS calls it as shown
        %                            below:
        %                               FUN(Y,Yfit,W)
        %                            where Y, Yfit and W are numeric vectors of
        %                            length N. Y is the observed response, Yfit is
        %                            the predicted response, and W is the observation
        %                            weights. Default: 'mse'
        %       'Weights'          - Vector of observation weights. The length of this 
        %                            vector must be equal to the number of rows in X. 
        %                            Default is equal weights.
        %
        %   See also RegressionKernel.

           % Overrides RegressionModel/loss because tables are not
           % supported and because it adds 'epsiloninsensitive' loss
           
           % Handle input data such as "tall" requiring a special adapter
            adapter = classreg.learning.internal.makeClassificationModelAdapter(this,X,Y,varargin{:});
            if ~isempty(adapter)            
                l = loss(adapter,X,Y,varargin{:});
                return
            end
            
            % Table is not supported.
            internal.stats.checkSupportedNumeric('X',X,false,true);
            
            obsInRows = true;
            N = size(X,1);
            
            args = {                  'lossfun'  'weights'};
            defs = {@classreg.learning.loss.mse  ones(N,1)};
            [funloss,W,~,extraArgs] = internal.stats.parseArgs(args,defs,varargin{:});
            
            % Prepare data
            [X,Y,W] = prepareDataForLoss(this,X,Y,W,this.VariableRange,false,obsInRows);
            
            % Adjust loss function in case of 'epsiloninsensitive'
            if strncmpi(funloss,'epsiloninsensitive',length(funloss))
                if isempty(this.Epsilon) % this is empty for models other than SVM
                    error(message('stats:RegressionKernel:UseEpsilonInsensitiveForSVM'));
                end
                funloss = @(Y,Yfit,W) classreg.learning.loss.epsiloninsensitive(...
                    Y,Yfit,W,this.Epsilon);
            end
            funloss = classreg.learning.internal.lossCheck(funloss,'regression');
            
            % Get predictions
            Yfit = predict(this,X,extraArgs{:});
            
            % Check
            classreg.learning.internal.regrCheck(Y,Yfit(:,1),W);

            % Get loss
            l = funloss(Y,Yfit,W);
        
        end        
        
    end
    
    methods(Static,Hidden)
        
        function [lambda,bc] = resolveAutoLambdaOrEmptyBoxConstraint(lambda,bc,n)
            if strcmp(lambda,'auto')
                lambda = 1/bc/n;
            elseif isempty(bc)
                bc = 1/lambda/n;
            end
        end
        
        function numExpansionDimensions = resolveAutoNumExpansionDimensions(numExpansionDimensions,d)
            if strcmp(numExpansionDimensions,'auto')
                numExpansionDimensions = 2.^ceil(min(log2(d)+5,15));
            end
        end
        
        function epsilon = resolveAutoEpsilon(epsilon,lossFunction,Y)
            if strcmp(epsilon,'auto')
                switch lossFunction
                    case 'epsiloninsensitive'
                        epsilon = iqr(Y)./13.49;
                        if epsilon == 0
                            epsilon = 1;
                        end
                     case 'mse'
                        epsilon = [];   
                end
            end
        end
        
        function kernelScale = resolveAutoKernelScale(kernelScale,X,Y,type)
            if strcmp(kernelScale,'auto')
                kernelScale = classreg.learning.svmutils.optimalKernelScale(X,Y,type);
            end
        end
        
        function featureMapper = resolveEmptyFeatureMapper(featureMapper,d,expDim,transformation,stream)
            if isempty(featureMapper)
                featureMapper = classreg.learning.rkeutils.featureMapper(stream,d,expDim,transformation);
            end
        end
        
        function initialBeta = resolveEmptyInitialBeta(initialBeta,expDim)
            if isempty(initialBeta)
                initialBeta = zeros(expDim,1);
            end
        end
        
        function initialBias = resolveEmptyInitialBias(initialBias,lossFunction,Y,W,epsilon)
            if isempty(initialBias)
                switch lossFunction
                    case 'epsiloninsensitive'
                        % Epsilon is not used for initial Bias to avoid cases that could
                        % lead to zero objective gradient...
                        epsilon = 0;
                        initialBias =  classreg.learning.linearutils.fitbias(...
                                'epsiloninsensitive',Y,zeros(numel(Y),1,'like',Y),W,0);
                    case 'mse'
                        initialBias = sum(W'*Y)/sum(W);
                end
            end
        end
        
        function maxChunkSize = estimateMaxChunkSize(numExpansionDimensions,blockSize,isFitting)
            memoryPerExpandedRow = numExpansionDimensions * 8;
            memoryBlock = blockSize * 1e6;
            maxChunkSize = floor(memoryBlock ./ memoryPerExpandedRow); %RowsPerBlock (Maximum)
            if isFitting && maxChunkSize<1000 %Only check for few rows per chunk when we are fitting
                 error(message('stats:RegressionKernel:FewObservationsPerBlock'))
             end
        end
        
        function temp = template(varargin)
            classreg.learning.FitTemplate.catchType(varargin{:}); %You are not allowed to pass 'type' argument.
            temp = classreg.learning.FitTemplate.make('Kernel',...
                'type','regression',varargin{:});
        end
        
        function [varargout] = fit(X,Y,varargin)
            temp = RegressionKernel.template(varargin{:});
            [varargout{1:nargout}] = fit(temp,X,Y);
        end
        
        function [X,Y,W,dataSummary,responseTransform] = ...
                prepareData(X,Y,varargin)
            % Reuse RegressionLinear.prepareData
            [X,Y,W,dataSummary,responseTransform] = ...
                RegressionLinear.prepareData(X,Y,varargin{:});
            % ... but we also restrict sparse data
            internal.stats.checkSupportedNumeric('X',X,false,false,false)
        end
        
        function obj = makeNoFit(beta,bias,lambda,featureMapper,kernelScale,boxConstraint,epsilon,modelParams,dataSummary,fitinfo,responseTransform)
            % Makes a RegressionKernel object without fitting by
            % feeding model parameters (beta and bias). input model
            % parameters (modelParams) and featureMapper
            
            if isempty(responseTransform)
                responseTransform = @classreg.learning.transform.identity;
            end
            
            obj = RegressionKernel(dataSummary,responseTransform);
            obj.DefaultLoss = @classreg.learning.loss.mse;
            
            switch lower(modelParams.LossFunction)
                case 'epsiloninsensitive'
                    obj.Learner = 'svm';
                case 'mse'
                    obj.Learner = 'leastsquares';
            end
            
            modelParamsStruct = toStruct(modelParams);
            
            obj.Epsilon = epsilon;
            obj.KernelScale = kernelScale;
            obj.FeatureMapper = featureMapper;
            obj.BoxConstraint = boxConstraint;
            
            modelParams.Lambda = lambda; % Impl keeps the real lambda in case modelParams is still 'auto'
            obj.Impl = classreg.learning.impl.LinearImpl.makeNoFit(modelParams,beta,bias,fitinfo);
            
            modelParamsStruct = rmfield(modelParamsStruct,'ValidationX');
            modelParamsStruct = rmfield(modelParamsStruct,'ValidationY');
            modelParamsStruct = rmfield(modelParamsStruct,'ValidationW');
            modelParamsStruct = rmfield(modelParamsStruct,'FeatureMapper');
            obj.ModelParams = modelParamsStruct;
            
            % save fitInfo into a private property, used only by resume method to
            % concatenate history informartion. User should only obtain
            % fitInfo from the second output argument.
            obj.FitInfo = fitinfo;    
        end
        
        function [obj,fitInfo] = fitRegressionKernel(...
                X,Y,W,modelParams,dataSummary,responseTransform)
            
            modelParams = fillIfNeeded(modelParams,X,Y,W,dataSummary,[]);
            obj = RegressionKernel(dataSummary,responseTransform);
            
            obj.DefaultLoss = @classreg.learning.loss.mse;
            
            switch lower(modelParams.LossFunction)
                case 'epsiloninsensitive'
                    obj.Learner = 'svm';
                    
                case 'mse'
                    obj.Learner = 'leastsquares';
            end
            
            [d,n] = size(X); % Number of predictors and observations
            
            % Resolve parameters that may still be set to 'auto' or empty
            % (Order matters!). All these modifications are not placed back
            % into modelParams; the actual lambda is saved in obj.impl after
            % fitting, and the actual numExpansionDimensions is saved in
            % obj.FeatureMapper after fitting.
            [lambda,obj.BoxConstraint] = RegressionKernel.resolveAutoLambdaOrEmptyBoxConstraint(modelParams.Lambda,modelParams.BoxConstraint,n);
            numExpansionDimensions =  RegressionKernel.resolveAutoNumExpansionDimensions(modelParams.NumExpansionDimensions,d);
            obj.FeatureMapper = RegressionKernel.resolveEmptyFeatureMapper(modelParams.FeatureMapper,d,numExpansionDimensions,modelParams.Transformation,modelParams.Stream);
            obj.KernelScale = RegressionKernel.resolveAutoKernelScale(modelParams.KernelScale,X',Y,0);
            obj.Epsilon = RegressionKernel.resolveAutoEpsilon(modelParams.Epsilon,modelParams.LossFunction,Y);
            
            
            initialBeta = RegressionKernel.resolveEmptyInitialBeta(modelParams.InitialBeta,numExpansionDimensions);
            initialBias = RegressionKernel.resolveEmptyInitialBias(modelParams.InitialBias,modelParams.LossFunction,Y,W,obj.Epsilon);
            
            % Figure out maxChunkSize from BlockSize
            maxChunkSize = RegressionKernel.estimateMaxChunkSize(numExpansionDimensions,modelParams.BlockSize,true);
            numberChunks = ceil(n / maxChunkSize);
            
            if numberChunks == 1
                %%%%%%%% FIT THE DATA IN ONE MEMORY BLOCK %%%%%%%%%%%%%%
                if modelParams.IterationLimit == 0
                    error(message('stats:RegressionKernel:InvalidIterationLimit'))
                end
                
                Xm = map(obj.FeatureMapper,X',obj.KernelScale)';
                
                obj.Impl = classreg.learning.impl.LinearImpl.make(0,...
                    initialBeta,initialBias,...
                    Xm,Y,W,...
                    modelParams.LossFunction,...
                    strcmp(modelParams.Regularization,'ridge'),...
                    lambda,...
                    [],...  % PassLimit
                    [],...  % BatchLimit
                    [],...  % NumCheckConvergence
                    [],...  % BatchIndex
                    [],...  % BatchSize
                    modelParams.Solver,...
                    modelParams.BetaTolerance,...
                    modelParams.GradientTolerance,...
                    1e-6,... % DeltaGradientTolerance
                    [],...   % LearnRate
                    [],...   % OptimizeLearnRate
                    modelParams.ValidationX,modelParams.ValidationY,modelParams.ValidationW,...
                    modelParams.IterationLimit,...
                    [],...   % TruncationPeriod,...
                    modelParams.FitBias,...
                    modelParams.PostFitBias,...
                    obj.Epsilon,... % Epsilon
                    modelParams.HessianHistorySize,...
                    modelParams.LineSearch,...
                    0, ... % Consensus
                    [],... % Stream
                    modelParams.VerbosityLevel);
                
                modelParamsStruct = toStruct(modelParams);
                
                fiHis = obj.Impl.FitInfo.History;
                if isempty(fiHis)
                    fiHisNew = [];
                else
                    % Adapt the history of the Fast Linear Solver to 
                    % RegressionKernel's history
                    fiHisNew = struct('ObjectiveValue',fiHis.Objective,...
                        'GradientMagnitude',fiHis.Gradient,...
                        'Solver',categorical(repmat({'LBFGS-fast'},numel(fiHis.Solver),1)),...
                        'IterationNumber',fiHis.NumIterations,...
                        'DataPass',cumsum(fiHis.NumPasses),...
                        'RelativeChangeInBeta',fiHis.RelativeChangeInBeta,...
                        'ElapsedTime',[nan(numel(fiHis.Solver)-1,1);obj.Impl.FitInfo.FitTime]);
                end
                
                fitInfo = struct('Solver','LBFGS-fast',...
                    'LossFunction',modelParams.LossFunction,...
                    'Lambda',lambda,...
                    'BetaTolerance', modelParams.BetaTolerance,...
                    'GradientTolerance',modelParams.GradientTolerance,...
                    'ObjectiveValue',obj.Impl.FitInfo.Objective,...
                    'GradientMagnitude',obj.Impl.FitInfo.GradientNorm,...
                    'RelativeChangeInBeta',obj.Impl.FitInfo.RelativeChangeInBeta,...
                    'FitTime',obj.Impl.FitInfo.FitTime,...
                    'History',fiHisNew);
                
            else
                if (modelParams.IterationLimit + modelParams.ADMMIterationLimit) == 0
                    error(message('stats:RegressionKernel:InvalidIterationLimitADMM'))
                end
                %%%%%%%% FIT THE DATA WITH A BLOCK-WISE SOLVER %%%%%%%%%%%%%%
                X = X'; 
                if modelParams.VerbosityLevel>0
                    fprintf(getString(message('stats:RegressionKernel:FoundNBlocks',numberChunks)))
                end
                
                Beta = [initialBias;initialBeta]; %including Bias
                
                doridge = strcmp(modelParams.Regularization,'ridge');
                rho = modelParams.Consensus;
                
                chunkIDs = arrayfun(@(x) sprintf('P0C%d',x),(1:numberChunks)','uniform',false);
                chunkMap = containers.Map(chunkIDs,1:numberChunks);
                
                Wk = zeros(numberChunks,1);
                h = 0;
                for i = 1:maxChunkSize:n
                    h = h + 1;
                    j = min(i+maxChunkSize-1,n);
                    Wk(h) = sum(W(i:j,:),1);
                end
                hfixedchunkfun = @fixedchunkfun;
                
                betaTol = modelParams.BetaTolerance;       
                gradTol = modelParams.GradientTolerance;   
                admmIterationLimit = modelParams.ADMMIterationLimit;
                tallPassLimit = intmax;
                verbose = modelParams.VerbosityLevel;
                
                doBias = modelParams.FitBias;
                lossfun = modelParams.LossFunction;
                
                % Parameters for the LBFGS inside ADMM iterations:
                iterationlimit_ADMMLBFGS = [modelParams.WarmStartIterationLimit modelParams.ADMMUpdateIterationLimit];
                hessianHistorySize_ADMMLBFGS = 15;  % fixed, cannot be controlled by user
                dowolfe_ADMMLBFGS = true;           % fixed, cannot be controlled by user
                doBias_ADMMLBFGS  = doBias;         % already restricted to always true above
                gradTol_ADMMLBFGS = gradTol;        % same as outer loop
                betaTol_ADMMLBFGS = betaTol;        % same as outer loop
                doridge_ADMMLBFGS = doridge;        % already restricted to always true above
                lossfun_ADMMLBFGS = lossfun;        % already set to 'mse' or 'epsiloninsensitive' above
                
                % Make the objective function
                expType = modelParams.Transformation;
                objgraF = makeobjgradF(X,Y,W,lossfun,lambda./numberChunks,maxChunkSize,obj.FeatureMapper,obj.KernelScale,obj.Epsilon);
                % Wrap objective function with verbosity and progress tracking behavior
                hclientfun = @(x)(x); % Doesn't matter because X is not tall
                keepHist = true;
                progressF = classreg.learning.linearutils.linearSolverProgressFunction(objgraF,false,admmIterationLimit>1,verbose>0,keepHist,hclientfun);
                
                %%%%%%%%%%%%%%%%%%%%%%%%%%% ADMM FIT %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                
                Beta = classreg.learning.linearutils.ADMMimpl(X,Y,W,Beta,rho,lambda,doridge,...
                    chunkMap,Wk,maxChunkSize,hfixedchunkfun,...
                    betaTol,gradTol,admmIterationLimit,tallPassLimit,progressF,verbose,...
                    {lossfun_ADMMLBFGS,obj.Epsilon},betaTol_ADMMLBFGS,gradTol_ADMMLBFGS,...
                    iterationlimit_ADMMLBFGS, doridge_ADMMLBFGS,...
                    hessianHistorySize_ADMMLBFGS,dowolfe_ADMMLBFGS,doBias_ADMMLBFGS,...
                    obj.FeatureMapper,expType,obj.KernelScale);
                
                %%%%%%%%%%%%%%%%%%%%%%%%%%% CENTRALIZED LBFGS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                hessianHistorySize = modelParams.HessianHistorySize;
                lineSearch = modelParams.LineSearch;
                iterationlimit = modelParams.IterationLimitBlockWise;
                initialStepSize = modelParams.InitialStepSize;
                
                Beta = classreg.learning.linearutils.LBFGSimpl(Beta,progressF,verbose,...
                    betaTol,gradTol,iterationlimit,tallPassLimit,...
                    hessianHistorySize,lineSearch,initialStepSize);
                
                beta = Beta(2:end);
                bias = Beta(1);
                
                if verbose>0
                    printLastLine(progressF);
                end
                
                modelParamsStruct = toStruct(modelParams);
                modelParams.Lambda = lambda; % Impl keeps the real lambda in case modelParams is still 'auto'
                
                obj.Impl = classreg.learning.impl.LinearImpl.makeNoFit(modelParams,beta,bias,progressF.History);
                
                fiHis = obj.Impl.FitInfo;
                if verbose>0
                    % Adapt the history of linearSolverProgressFunction to 
                    % RegressionKernel's history
                    fiHisNew = struct('ObjectiveValue',fiHis.ObjectiveValue(:),...
                        'GradientMagnitude',fiHis.GradientMagnitude(:),...
                        'Solver',categorical(repmat({'LBFGS-blockwise'},numel(fiHis.Solver),1)),...
                        'IterationNumber',fiHis.IterationNumber(:),...
                        'DataPass',fiHis.DataPass(:),...
                        'RelativeChangeInBeta',fiHis.RelativeChangeBeta(:),...
                        'ElapsedTime',fiHis.ElapsedTime(:));
                else
                    fiHisNew = [];
                end
                
                fitInfo = struct('Solver','LBFGS-blockwise',...
                    'LossFunction',modelParams.LossFunction,...
                    'Lambda',modelParams.Lambda,...
                    'BetaTolerance', modelParams.BetaTolerance,...
                    'GradientTolerance',modelParams.GradientTolerance,...
                    'ObjectiveValue',obj.Impl.FitInfo.ObjectiveValue(end),...
                    'GradientMagnitude',obj.Impl.FitInfo.GradientMagnitude(end),...
                    'RelativeChangeInBeta',obj.Impl.FitInfo.RelativeChangeBeta(end),...
                    'FitTime',obj.Impl.FitInfo.ElapsedTime(end),...
                    'History',fiHisNew);
                
                
            end
            
            modelParamsStruct = rmfield(modelParamsStruct,'ValidationX');
            modelParamsStruct = rmfield(modelParamsStruct,'ValidationY');
            modelParamsStruct = rmfield(modelParamsStruct,'ValidationW');
            modelParamsStruct = rmfield(modelParamsStruct,'FeatureMapper');
            obj.ModelParams = modelParamsStruct;
            
            % save fitInfo into a private property, used only by resume method to
            % concatenate history informartion. User should only obtain
            % fitInfo from the second output argument.
            obj.FitInfo = fitInfo;
            
        end
        
    end
    
end

function objgraF = makeobjgradF(X,Y,W,lossfun,lambdaK,maxChunkSize,FM,kernelScale,epsilon)
objgraF = @fcn;
    function [obj,gra] = fcn(Beta)
        [~,obj,gra] = fixedchunkfun( @(info,x,y,w) ...
            chunkObjGraFun(info,Beta,x,y,w,lossfun,lambdaK,FM,kernelScale,epsilon), ...
            maxChunkSize, {[],[],[]}, X,Y,W);
        obj = sum(obj,1);
        gra = sum(gra,1);
    end
end

function  varargout = fixedchunkfun(fcn,FixedNumSlices,~,varargin)
% Replicates tall.fixedchunkfun on non-tall inputs so we can use the same
% implementation of the solvers. Assumes all variables in varargin will be
% partitioned (i.e. no broadcasted inputs). This functions is called in two
% places: 1) from the objgra functor (above), and 2) from the Beta update
% in the ADMM algorithm.

info = struct('PartitionId',0,'FixedSizeChunkID',0,'IsLastChunk',true);
bi = cellfun(@(x) isa(x,'matlab.bigdata.internal.BroadcastArray'),varargin);
n = size(varargin{find(~bi,1)},1); % height
nia = numel(varargin);
varargout = cell(1,nargout);
h = 0;
for i = 1:FixedNumSlices:n
    h = h +1;
    info.FixedSizeChunkID = h;
    j = min(i+FixedNumSlices-1,n);
    invar = cell(1,nia);
    outvar = cell(1,nargout);
    for k = 1:nia
        if bi(k)
            invar{k} = varargin{k};
        else
            invar{k} = varargin{k}(i:j,:);
        end
    end
    [~,outvar{:}] = fcn(info,invar{:});
    for k = 1:nargout
        varargout{k}(h,:) = outvar{k};
    end
end

end

function [hasFinished,id,obj,gra] = chunkObjGraFun(info,Beta,x,y,w,lossfun,lambda,FM,kernelScale,epsilon)
hasFinished = info.IsLastChunk;
id = {sprintf('P%dC%d',info.PartitionId,info.FixedSizeChunkID)};
useBias = true;
doridge = true;
if isempty(x)
    obj = (Beta(2:end)'*Beta(2:end))*lambda/2;
    gra = [0;Beta(2:end)*lambda]';
else
    xm = map(FM,x,kernelScale);
    [obj,gra] = classreg.learning.linearutils.objgrad( Beta(2:end),Beta(1),xm',y,w,...
        lossfun,doridge,lambda,epsilon,useBias,...
        zeros(numel(Beta)-1,1,'like',Beta),0,0);
    gra = [gra(end);gra(1:end-1)]';
    % obj = sum(max(0,1-(x*Beta(2:end)+Beta(1)).*y).*w)+(Beta(2:end)'*Beta(2:end))*lambda/2;
    % gra = (sum((y.*(x*Beta(2:end)+Beta(1))<1) .* (-y.*[ones(numel(w),1) x].*w))' + [0;Beta(2:end)*lambda])';
end
end