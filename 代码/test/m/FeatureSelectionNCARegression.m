classdef FeatureSelectionNCARegression < classreg.learning.fsutils.FeatureSelectionNCAModel
%FeatureSelectionNCARegression Feature selection for regression using neighborhood component analysis (NCA).
%   FeatureSelectionNCARegression learns feature weights using a diagonal
%   adaptation of neighborhood component analysis (NCA). Feature selection
%   is achieved by regularizing the feature weights.
%
%   FeatureSelectionNCARegression properties:
%       NumObservations       - Number of observations in the training data.
%       ModelParameters       - Model parameters passed in for training this model.
%       Lambda                - Regularization parameter.
%       FitMethod             - Method used to fit this model.
%       Solver                - Solver used to fit this model.
%       GradientTolerance     - Tolerance on gradient norm for solvers 'lbfgs' and 'minibatch-lbfgs'.
%       IterationLimit        - Maximum number of iterations for optimization.
%       PassLimit             - Maximum number of passes for solvers 'sgd' and 'minibatch-lbfgs'.
%       InitialLearningRate   - Initial learning rate for solvers 'sgd' and 'minibatch-lbfgs'.
%       Verbose               - Verbosity level: 0, 1 or >1.
%       InitialFeatureWeights - Initial feature weights to start optimization.
%       FeatureWeights        - Fitted feature weights for this model.
%       FitInfo               - Fitting information from training this model.
%       Mu                    - A vector of predictor means if using predictor standardization.
%       Sigma                 - A vector of predictor standard deviations if using predictor standardization.
%       X                     - Matrix of predictors used to train this model.
%       Y                     - Observed response used to train this model.
%       W                     - Weights of observations used to train this model.
%
%   FeatureSelectionNCARegression methods:
%       predict - Predicted response using NCA regression model.
%       loss    - Compute loss on new data.
%       refit   - Refit this model.
%
%   Example:
%       % 1. Example data where first 2 predictors are relevant.
%       N  = 300;
%       y  = unifrnd(0,20,N,1);
%       x1 = y.*sin(y) + randn(N,1);
%       x2 = y.*cos(y) + randn(N,1);
%       X  = [x1,x2];
%       % 2. Add irrelevant predictors and scale all predictors from 0 to 1.
%       Xrnd = randn(N,1000);
%       Xall = [X,Xrnd];
%       Xall = bsxfun(@rdivide,bsxfun(@minus,Xall,min(Xall)),range(Xall,1));
%       % 3. Use fsrnca to do feature selection using one value of Lambda.
%       nca = fsrnca(Xall,y,'Solver','lbfgs','Lambda',0.06,'Verbose',1,'LossFunction','mad','Standardize',1);
%       % 4. Plot feature weights.
%       semilogx(nca.FeatureWeights,'ro');
%       grid on;
%       xlabel('Feature index');
%       ylabel('Feature weight');
%
%   See also fsrnca, fscnca, FeatureSelectionNCAClassification.

%   Copyright 2015-2016 The MathWorks, Inc.        

%% Constants.

    %%
    % _Supported loss functions for loss method_
    properties(Constant,Hidden)
        LossFunctionMSE = 'mse';
        LossFunctionMAD = 'mad';        
        BuiltInLossFunctions = {FeatureSelectionNCARegression.LossFunctionMSE,...
                                FeatureSelectionNCARegression.LossFunctionMAD};        
    end
    
%% Properties holding inputs.    
    properties(GetAccess=public,SetAccess=protected,Dependent)
        %Y - True response vector used to train this model.
        %   The Y property is a numeric vector of continuous response
        %   values used to train this model.
        Y;        
    end    
        
    properties(GetAccess=public,SetAccess=protected,Hidden,Dependent)
        %PrivY - True response vector used to train this model.
        %   The PrivY property is a numeric vector of continuous response
        %   values used to train this model.
        PrivY;        
    end
    
    properties(Hidden)
        %Impl - Implementation class for fitting and prediction.
        %   The Impl property is a FeatureSelectionNCARegressionImpl
        %   object.
        Impl;
    end
        
    methods
        function y = get.Y(this)
            y = this.PrivY;
        end
        
        function privY = get.PrivY(this)
            privY = this.Impl.PrivY;
        end
    end
    
%% Constructor.
    methods(Hidden)
        function this = FeatureSelectionNCARegression(X,Y,varargin)
            this = doFit(this,X,Y,varargin{:});            
        end
    end

%% predict and loss methods.    
    methods        
        function ypred = predict(this,XTest)
%predict - Make predictions on test data.
%   YPRED = predict(MODEL,X) takes an object MODEL of type
%   FeatureSelectionNCARegression, a M-by-P predictor matrix X with M
%   observations and P predictors, and computes a M-by-1 vector YPRED
%   containing the predicted values using the NCA regression model
%   corresponding to the rows of X.

            % 1. Validate XTest.
            isok = FeatureSelectionNCARegression.checkXType(XTest);
            if ~isok
                error(message('stats:FeatureSelectionNCA:FeatureSelectionNCARegression:BadXType'));
            end
            
            % 2. Get the size of XTest.
            [M,P] = size(XTest);
            
            % 3. Ensure that XTest has the right number of columns.
            if ( P ~= this.NumFeatures )
                error(message('stats:FeatureSelectionNCA:FeatureSelectionNCARegression:BadX',this.NumFeatures));
            end
            
            % 4. Bad rows in XTest - badrows is a M-by-1 logical vector.
            badrows = any(isnan(XTest),2);
            
            % 5. Remove bad rows from XTest.
            XTest(badrows,:) = [];
            
            % 6. If XTest is empty. we are done.
            if ( isempty(XTest) )
                error(message('stats:FeatureSelectionNCA:FeatureSelectionNCARegression:NoObservationsInX'));
            end
            
            % 7. Dispatch to the right predict method from the Impl class.
            % This method will account for predictor standardization if
            % required.
            ypred = nan(M,1);
            computationMode = this.ModelParams.ComputationMode;
            usemex          = strcmpi(computationMode,classreg.learning.fsutils.FeatureSelectionNCAModel.ComputationModeMex) && ~issparse(XTest);
            if usemex
                ypredNotBad = predictNCAMex(this.Impl,XTest);
            else
                ypredNotBad = predictNCA(this.Impl,XTest);            
            end
            ypred(~badrows) = ypredNotBad;
        end
        
        function L = loss(this,XTest,YTest,varargin)
%loss - Evaluate accuracy of learned feature weights on test data.
%   ERR = loss(MODEL,X,Y) computes the mean squared error (MSE) when making
%   predictions using the learned feature weights. MODEL is an object of
%   type FeatureSelectionNCARegression, X is the predictor matrix, and Y is
%   the response variable containing the true response values.
%
%   ERR = loss(MODEL,X,Y,'PARAM1',val1,...) accepts additional name value
%   pairs and returns a different measure of accuracy of the learned
%   feature weights (smaller the better).
%
%       Parameter        Value
%       'LossFunction' - A character vector or string specifying the
%                        loss type. Choices are 'mse' and 'mad'. As
%                        described below, choice 'mse' returns L2 and 'mad'
%                        returns L1. Default is 'mse'.
%
%   X is an M-by-P matrix where M is the number of observations and P is
%   the number of predictors. Y is a numeric real vector with M elements.
%   Element i of Y is the true response for row i of X. L2 is computed as
%   follows:
%
%       L2 = mean((T-Y).^2)
%
%   where T is a M-by-1 vector containing the predicted response using NCA
%   regression model for rows of X. L1 is computed as follows:
%
%       L1 = mean(abs(T-Y))
            [varargin{:}] = convertStringsToChars(varargin{:});
            % 1. Figure out the loss type.
                % 1.1 Set parameter defaults.
                dfltLossFunction = FeatureSelectionNCARegression.LossFunctionMSE;
                % 1.2 Parse optional name/value pairs.
                paramNames = {  'LossFunction'};
                paramDflts = {dfltLossFunction};
                lossType   = internal.stats.parseArgs(paramNames,paramDflts,varargin{:});
                % 1.3 Validate optional parameters.
                lossType = internal.stats.getParamVal(lossType,this.BuiltInLossFunctions,'LossFunction');

            % 2. Validate XTest.
            isok = FeatureSelectionNCARegression.checkXType(XTest);
            if ~isok
                error(message('stats:FeatureSelectionNCA:FeatureSelectionNCARegression:BadXType'));
            end
            
            % 3. Get the size of XTest.
            [M,P] = size(XTest);
            
            % 4. Ensure that XTest has the right number of columns.
            if ( P ~= this.NumFeatures )
                error(message('stats:FeatureSelectionNCA:FeatureSelectionNCARegression:BadX',this.NumFeatures));
            end
            
            % 5. Validate YTest and convert it to a column vector.
            isok = FeatureSelectionNCARegression.checkYType(YTest);
            if ~isok
                error(message('stats:FeatureSelectionNCA:FeatureSelectionNCARegression:BadYType'));
            end
            YTest = YTest(:);
            
            % 6. Ensure that XTest and YTest have the same number of rows.
            if ( M ~= length(YTest) )
                error(message('stats:FeatureSelectionNCA:FeatureSelectionNCARegression:BadY',M));
            end
            
            % 7. Remove bad rows from XTest and YTest.
            [XTest,YTest] = FeatureSelectionNCARegression.removeBadRows(XTest,YTest,[]);            
            if ( isempty(XTest) || isempty(YTest) )
                error(message('stats:FeatureSelectionNCA:FeatureSelectionNCARegression:NoObservationsInXY'));
            end
            MNew = size(XTest,1);
            
            % 8. Get predicted values for rows of XTest.
            computationMode = this.ModelParams.ComputationMode;
            usemex          = strcmpi(computationMode,classreg.learning.fsutils.FeatureSelectionNCAModel.ComputationModeMex) && ~issparse(XTest);
            if usemex
                ypred = predictNCAMex(this.Impl,XTest);
            else
                ypred = predictNCA(this.Impl,XTest);
            end
                        
            % 9. Compute loss. 
            if ( strcmpi(lossType,FeatureSelectionNCARegression.LossFunctionMSE) )
                r = ypred - YTest;
                L = (r'*r)/MNew;
            else
                r = ypred - YTest;
                L = sum(abs(r))/MNew;
            end
        end        
    end
  
%% Object display.
    methods(Hidden)
        function s = propsForDisp(this,s)
        %propsForDisp - Create a structure with properties for display.
        %   s = propsForDisp(this,s) takes an object this of type
        %   FeatureSelectionNCARegression, and an optional struct s and
        %   adds fields to s for display purposes. s can be empty.
            
            % 1. Invoke super-class method.
            s = propsForDisp@classreg.learning.fsutils.FeatureSelectionNCAModel(this,s);
            
            % 2. Add additional properties specific to regression to s.
            s.Y = this.Y;
            s.W = this.W;
        end
    end
            
%% Utilities for setting up input data.    
    methods(Hidden)        
        function [X,Y,W,labels,labelsOrig] = setupXYW(~,X,Y,W)
            % 1. Check X.
            X = FeatureSelectionNCARegression.validateX(X);
            
            % 2. Check Y.
            Y = FeatureSelectionNCARegression.validateY(Y);
            
            % 3. Check W.                
            W = FeatureSelectionNCARegression.validateW(W);            
            
            % 4. Number of rows in X must match the length of Y and W.
            N = size(X,1);
            if ( length(Y) ~= N )
                error(message('stats:FeatureSelectionNCA:FeatureSelectionNCARegression:BadYLength'));
            end
            
            if ( length(W) ~= N )
                error(message('stats:FeatureSelectionNCA:FeatureSelectionNCARegression:BadWeights',N));
            end
            
            % 5. Remove unusable rows from X, Y and W.
            [X,Y,W] = FeatureSelectionNCARegression.removeBadRows(X,Y,W);
            
            % 6. If X, Y or W become empty after removing bad rows, stop.
            if ( isempty(X) || isempty(Y) || isempty(W) )
                error(message('stats:FeatureSelectionNCA:FeatureSelectionNCARegression:NoObservationsInXY'));
            end
            
            % 7. Return X, Y and W. For regression, labels and labelsOrig
            % are set to [].
            labels     = [];
            labelsOrig = [];
        end
    end
    
%% Utilities for input validation.    
    methods(Static,Hidden)                
        function Y = validateY(Y)
        %validateY - Validate the Y input.
        %   Y = validateY(Y) ensures that Y is a numeric, real vector. If
        %   not an error is thrown. Y is returned as a column vector.
        
            % 1. Check the type of Y.
            isok = FeatureSelectionNCARegression.checkYType(Y);            
            if ~isok
                error(message('stats:FeatureSelectionNCA:FeatureSelectionNCARegression:BadYType'));
            end
            
            % 2. Ensure that Y is a column vector.
            Y = Y(:);
        end
        
        function isok = checkYType(Y)
            % Y must be a numeric, real vector.
            isok = isfloat(Y) && isreal(Y) && isvector(Y);
        end        
    end
end