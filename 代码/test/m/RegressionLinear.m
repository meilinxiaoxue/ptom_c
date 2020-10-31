classdef RegressionLinear < ...
        classreg.learning.regr.RegressionModel & classreg.learning.Linear    
%RegressionLinear Linear model for regression.
%   RegressionLinear is a linear model for regression. This model can
%   predict responses for new data.
%
%   RegressionLinear properties:
%       PredictorNames         - Names of predictors used for this model.
%       ExpandedPredictorNames - Names of expanded predictors.
%       ResponseName           - Name of the response variable.
%       ResponseTransform      - Transformation applied to predicted response values.
%       Learner                - Learned model, 'svm' or 'leastsquares'.
%       Beta                   - Linear coefficients.
%       Bias                   - Bias term.
%       FittedLoss             - Fitted loss function, 'epsiloninsensitive' or 'mse'.
%       Lambda                 - Regularization strength.
%       Regularization         - Type of regularization, L1 or L2.
%       Epsilon                - Half of the width of the epsilon-insensitive band for SVM.
%
%   RegressionLinear methods:
%       loss                  - Regression loss.
%       predict               - Predicted response of this model.
%       selectModels          - Select a subset of fitted regularized models.

%   Copyright 2015-2017 The MathWorks, Inc.
    
    properties(GetAccess=public,SetAccess=protected,Dependent=true)
        %Epsilon Half of the width of the epsilon-insensitive band for SVM.
        %   The Epsilon property is a scalar specifying half the width of
        %   the epsilon-insensitive band for SVM. If the Learner property
        %   is not 'svm', this property is empty.
        %
        %   See also RegressionLinear, Learner.
        Epsilon;
    end

    methods
        function e = get.Epsilon(this)
            e = this.Impl.Epsilon;
        end
    end

    
    methods(Hidden=true)
        function this = RegressionLinear(dataSummary,responseTransform)
            % Protect against being called by the user
            if ~isstruct(dataSummary)
                error(message('stats:RegressionLinear:RegressionLinear:DoNotUseConstructor'));
            end
            
            this = this@classreg.learning.regr.RegressionModel(...
                dataSummary,responseTransform);
            this = this@classreg.learning.Linear;
        end
        
        function cmp = compact(this)
            cmp = this;
        end
    end
    
    
    methods(Access=protected)
        function s = propsForDisp(this,s)
            s = propsForDisp@classreg.learning.regr.RegressionModel(this,s);
            s = propsForDisp@classreg.learning.Linear(this,s);
            s = rmfield(s,'CategoricalPredictors');
        end
        
        function S = response(this,X,obsInRows)
            S = score(this.Impl,X,false,obsInRows);
        end
    end
    
    
    methods
        function Yfit = predict(this,X,varargin)
        %PREDICT Predict response of the model.
        %   YFIT=PREDICT(MODEL,X) returns predicted response YFIT for linear model
        %   MODEL and predictors X. Pass X as a matrix with P columns, where P is the
        %   number of predictors used for training. YFIT is an N-by-L matrix of the
        %   same type as Y, where N is the number of observations (rows) in X
        %   and L is the number of values in Lambda.
        %
        %   YFIT=(MODEL,X,'PARAM1',val1,'PARAM2',val2,...) specifies optional
        %   parameter name/value pairs:
        %       'ObservationsIn'    - String specifying the data orientation,
        %                             either 'rows' or 'columns'. Default: 'rows'
        %                           NOTE: Passing observations in columns can
        %                                 significantly speed up prediction.
        %
        %   See also RegressionLinear, Lambda.
            [varargin{:}] = convertStringsToChars(varargin{:});
            % Handle input data such as "tall" requiring a special adapter
            adapter = classreg.learning.internal.makeClassificationModelAdapter(this,X,varargin{:});
            if ~isempty(adapter)            
                Yfit = predict(adapter,X,varargin{:});
                return
            end
        
            internal.stats.checkSupportedNumeric('X',X,false,true);
            
            % Detect the orientation
            obsIn = internal.stats.parseArgs({'observationsin'},{'rows'},varargin{:});
            obsIn = validatestring(obsIn,{'rows' 'columns'},...
                'classreg.learning.internal.orientX','ObservationsIn');
            obsInRows = strcmp(obsIn,'rows');
            
            % Predictions for empty X
            if isempty(X)
                D = numel(this.PredictorNames);
                if obsInRows
                    str = getString(message('stats:classreg:learning:regr:RegressionModel:predictEmptyX:columns'));
                    Dpassed = size(X,2);
                else
                    Dpassed = size(X,1);
                    str = getString(message('stats:classreg:learning:regr:RegressionModel:predictEmptyX:rows'));
                end
                if Dpassed~=D
                    error(message('stats:classreg:learning:regr:RegressionModel:predictEmptyX:XSizeMismatch', D, str));
                end
                Yfit = NaN(0,1);
                return;
            end

            % Predict
            Yfit = this.PrivResponseTransform(response(this,X,obsInRows));
        end
        
        function l = loss(this,X,Y,varargin)
        %LOSS Regression error.
        %   ERR=LOSS(MODEL,X,Y) returns mean squared error for MODEL computed using
        %   predictors X and observed response Y. Pass X as a matrix with P columns,
        %   where P is the number of predictors used for training. Y must be a
        %   vector of floating-point numbers with N elements, where N is the number
        %   of observations (columns) in X. ERR is a row-vector with L values,
        %   where L is the number of elements in Lambda.
        %
        %   ERR=LOSS(MODEL,X,Y,'PARAM1',val1,'PARAM2',val2,...) specifies optional
        %   parameter name/value pairs:
        %       'ObservationsIn'   - String specifying the orientation of
        %                            X, either 'rows' or 'columns'.
        %                            Default: 'rows'
        %                          NOTE: Passing observations in columns can
        %                                significantly speed up prediction.
        %       'LossFun'          - Function handle for loss, or string
        %                            representing a built-in loss function.
        %                            Available loss functions for regression: 'mse'
        %                            and 'epsiloninsensitive'. If you pass a
        %                            function handle FUN, LOSS calls it as shown
        %                            below:
        %                               FUN(Y,Yfit,W)
        %                            where Y, Yfit and W are numeric vectors of
        %                            length N. Y is observed response, Yfit is
        %                            predicted response, and W is observation
        %                            weights. Default: 'mse'
        %       'Weights'          - Vector of observation weights. By default the
        %                            weight of every observation is set to 1. The
        %                            length of this vector must be equal to the
        %                            number of columns in X.
        %
        %   See also RegressionLinear, predict, Lambda.
            [varargin{:}] = convertStringsToChars(varargin{:});
            % Handle input data such as "tall" requiring a special adapter
            adapter = classreg.learning.internal.makeClassificationModelAdapter(this,X,Y,varargin{:});
            if ~isempty(adapter)            
                l = loss(adapter,X,Y,varargin{:});
                return
            end
            
            % Table is not supported.
            internal.stats.checkSupportedNumeric('X',X,false,true);
            
            % Get observation weights
            obsInRows = classreg.learning.internal.orientation(varargin{:});            
            if obsInRows
                N = size(X,1);
            else
                N = size(X,2);
            end
            args = {                  'lossfun'  'weights'};
            defs = {@classreg.learning.loss.mse  ones(N,1)};
            [funloss,W,~,extraArgs] = ...
                internal.stats.parseArgs(args,defs,varargin{:});
            
            % Prepare data
            [X,Y,W] = prepareDataForLoss(this,X,Y,W,this.VariableRange,false,obsInRows);
            
            % Loss function
            if strncmpi(funloss,'epsiloninsensitive',length(funloss))
                if isempty(this.Epsilon) % this is empty for models other than SVM
                    error(message('stats:RegressionLinear:loss:UseEpsilonInsensitiveForSVM'));
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
            R = size(Yfit,2);
            l = NaN(1,R);
            for r=1:R
                l(r) = funloss(Y,Yfit(:,r),W);
            end
        end
    end
    methods(Hidden)
        function s = toStruct(this)
            % Convert to a struct for codegen.
            
            warnState  = warning('query','all');
            warning('off','MATLAB:structOnObject');
            cleanupObj = onCleanup(@() warning(warnState));
            
            fh = functions(this.PrivResponseTransform);
            if strcmpi(fh.type,'anonymous')
                error(message('stats:classreg:learning:coderutils:classifToStruct:AnonymousFunctionsNotSupported','Response Transform'));
            end
            % convert common properties to struct
            s = classreg.learning.coderutils.regrToStruct(this);
            
            % test provided responseTransform
            try
                classreg.learning.internal.convertScoreTransform(this.PrivResponseTransform,'handle',1);    
            catch me
                rethrow(me);
            end   
 
            s.ResponseTransformFull = s.ResponseTransform;
            responsetransformfull = strsplit(s.ResponseTransform,'.');
            responsetransform = responsetransformfull{end};
            s.ResponseTransform = responsetransform; 
            
            % decide whether scoreTransform is a user-defined function or
            % not
            transFcn = ['classreg.learning.transform.' s.ResponseTransform];
            transFcnCG = ['classreg.learning.coder.transform.' s.ResponseTransform];
            if isempty(which(transFcn)) || isempty(which(transFcnCG))
                s.CustomResponseTransform = true;
            else
                s.CustomResponseTransform = false;
            end 
              
            % Support only scalar lambda
            if ~isscalar(this.Lambda)
                error(message('stats:ClassificationLinear:toStruct:NonScalarLambda'));
            end
            
            % save the path to the fromStruct method
            s.FromStructFcn = 'RegressionLinear.fromStruct';
            
            % learner char vector
            s.Learner = this.Learner;
            
            % model params
            s.ModelParams = classreg.learning.coderutils.linearParamsToCoderStruct(...
                this.ModelParams);
            
            % impl
            s.Impl = toStruct(this.Impl);
        end
    end    
    
    methods(Static,Hidden)
        function temp = template(varargin)
            classreg.learning.FitTemplate.catchType(varargin{:});
            temp = classreg.learning.FitTemplate.make('Linear',...
                'type','regression',varargin{:});
        end
        
        function [varargout] = fit(X,Y,varargin)
            temp = RegressionLinear.template(varargin{:});
            [varargout{1:nargout}] = fit(temp,X,Y);
        end
        
        function [obj,fitInfo] = fitRegressionLinear(...
                X,Y,W,modelParams,dataSummary,responseTransform)            
            obj = RegressionLinear(dataSummary,responseTransform);
            
            modelParams = fillIfNeeded(modelParams,X,Y,W,dataSummary,[]);
                        
            lossfun = modelParams.LossFunction;
            
            switch lower(lossfun)
                case 'epsiloninsensitive'
                    obj.Learner = 'svm';
                case 'mse'
                    obj.Learner = 'leastsquares';
            end

            lambda = modelParams.Lambda;
            if strcmp(lambda,'auto')
                lambda = 1/numel(Y);
            end

            obj.Impl = classreg.learning.impl.LinearImpl.make(0,...
                modelParams.InitialBeta,modelParams.InitialBias,...
                X,Y,W,lossfun,...
                strcmp(modelParams.Regularization,'ridge'),...
                lambda,...
                modelParams.PassLimit,...
                modelParams.BatchLimit,...
                modelParams.NumCheckConvergence,...
                modelParams.BatchIndex,...
                modelParams.BatchSize,...
                modelParams.Solver,...
                modelParams.BetaTolerance,...
                modelParams.GradientTolerance,...
                modelParams.DeltaGradientTolerance,...
                modelParams.LearnRate,...
                modelParams.OptimizeLearnRate,...
                modelParams.ValidationX,modelParams.ValidationY,modelParams.ValidationW,...
                modelParams.IterationLimit,...
                modelParams.TruncationPeriod,...
                modelParams.FitBias,...
                modelParams.PostFitBias,...
                modelParams.Epsilon,... 
                modelParams.HessianHistorySize,...
                modelParams.LineSearch,...
                0,... % consensus strength
                modelParams.Stream,...
                modelParams.VerbosityLevel);
            
            modelParams = toStruct(modelParams);
            
            modelParams = rmfield(modelParams,'ValidationX');
            modelParams = rmfield(modelParams,'ValidationY');
            modelParams = rmfield(modelParams,'ValidationW');
            
            obj.ModelParams = modelParams;
            
            fitInfo                 = obj.Impl.FitInfo;
            fitInfo.Solver          = obj.Impl.Solver;
        end
        
        function obj = makebeta(beta,bias,modelParams,dataSummary,fitinfo,responseTransform)
            % Makes a RegressionLinear object without fitting by
            % feeding model parameters (beta and bias) and input model
            % parameters (modelParams)
            
            if isempty(responseTransform)
                responseTransform = @classreg.learning.transform.identity;
            end
            
            obj = RegressionLinear(dataSummary,responseTransform);
            
            switch lower(modelParams.LossFunction)
                case 'epsiloninsensitive'
                    obj.Learner = 'svm';
                case 'mse'
                    obj.Learner = 'leastsquares';
            end
            
            obj.ModelParams = modelParams;
            
            obj.Impl = classreg.learning.impl.LinearImpl.makeNoFit(modelParams,beta(:),bias,fitinfo);

        end

        function [X,Y,W,dataSummary,responseTransform] = prepareData(X,Y,varargin)
            
            % Process input args
            args = {'responsetransform'};
            defs = {                 []};
            [transformer,~,crArgs] = ...
                internal.stats.parseArgs(args,defs,varargin{:});
            
            % Pre-process
            [X,Y,W,dataSummary] = classreg.learning.Linear.prepareDataCR(X,Y,crArgs{:});

            % Check Y type
            if ~isfloat(Y) || ~isvector(Y)
                error(message('stats:classreg:learning:regr:FullRegressionModel:prepareData:BadYType'));
            end
            internal.stats.checkSupportedNumeric('Y',Y,true);
            Y = Y(:);
            
            % Remove NaN's in Y
            if any(isnan(Y))
                warning(message('stats:RegressionLinear:prepareData:YwithMissingValues'));
            end
            [X,Y,W,dataSummary.RowsUsed] = ...
                classreg.learning.regr.FullRegressionModel.removeNaNs(...
                X,Y,W,dataSummary.RowsUsed,dataSummary.ObservationsInRows);
            
            % Renormalize weights
            W = W/sum(W);
            
            % Make output response transformation
            responseTransform = ...
                classreg.learning.regr.FullRegressionModel.processResponseTransform(transformer);
        end
        
        function obj = fromStruct(s)
            % Make a Linear object from a codegen struct.
            

            s.ResponseTransform = s.ResponseTransformFull;
            
            s = classreg.learning.coderutils.structToRegr(s);
                        
            % Make an object
            obj = RegressionLinear(s.DataSummary,s.ResponseTransform);
        
            % Learner
            obj.Learner = s.Learner;
            
            % Model params
            obj.ModelParams = classreg.learning.coderutils.coderStructToLinearParams(s.ModelParams);
            
            % implementation
            obj.Impl = classreg.learning.impl.LinearImpl.fromStruct(s.Impl);            
        end
        
        function name = matlabCodegenRedirect(~)
            name = 'classreg.learning.coder.regr.RegressionLinear';
        end  
    end
    
end
