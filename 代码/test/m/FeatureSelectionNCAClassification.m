classdef FeatureSelectionNCAClassification < classreg.learning.fsutils.FeatureSelectionNCAModel
%FeatureSelectionNCAClassification Feature selection for classification using neighborhood component analysis (NCA).
%   FeatureSelectionNCAClassification learns feature weights using a
%   diagonal adaptation of neighborhood component analysis (NCA). Feature
%   selection is achieved by regularizing the feature weights.
%
%   FeatureSelectionNCAClassification properties:
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
%       ClassNames            - Names of classes in Y.
%
%   FeatureSelectionNCAClassification methods:
%       predict - Predicted response using NCA classifier.
%       loss    - Compute loss on new data.
%       refit   - Refit this model.
%
%   Example:
%       % 1. Example data where first 2 predictors are relevant.
%       N = 20000;
%       X = rand(N,2);
%       y = -ones(N,1);
%       y(X(:,1) > 0.5 & X(:,2) > 0.5) = 1;
%       y(X(:,1) < 0.5 & X(:,2) < 0.5) = 1;
%       % 2. Plot the data.
%       figure;
%       plot(X(y==1,1),X(y==1,2),'rx');
%       hold on;
%       plot(X(y==-1,1),X(y==-1,2),'bx');
%       % 3. Add irrelevant predictors.
%       Xrnd = rand(N,100);
%       Xall = [X,Xrnd];
%       % 4. Use fscnca to do feature selection using one value of Lambda.
%       nca = fscnca(Xall,y,'Solver','sgd','Lambda',7/N,'Verbose',1,'Standardize',1,'InitialFeatureWeights',rand(102,1),'PassLimit',1,'IterationLimit',3000);
%       % 5. Plot feature weights.
%       figure;
%       semilogx(nca.FeatureWeights,'ro');
%       grid on;
%       xlabel('Feature index');
%       ylabel('Feature weight');
%
%   See also fscnca, fsrnca, FeatureSelectionNCARegression.

%   Copyright 2015-2016 The MathWorks, Inc.
      
%% Constants.

    %%
    % _Supported loss functions for loss method_
    properties(Constant,Hidden)
        LossFunctionMSEProb     = 'quadratic';
        LossFunctionMisclassErr = 'classiferror';        
        BuiltInLossFunctions    = {FeatureSelectionNCAClassification.LossFunctionMSEProb,...
                                   FeatureSelectionNCAClassification.LossFunctionMisclassErr};        
    end

%% Properties holding inputs.    
    properties(GetAccess=public,SetAccess=protected,Dependent)
        %Y - True class labels used to train this model.
        %   The Y property is an array of true class labels. Y is of the
        %   same type as the passed-in Y data: a categorical, logical or
        %   numeric vector, a cell array of character vectors or a
        %   character matrix.
        Y;               
        
        %ClassNames - Names of classes in Y.
        %   The ClassNames property is a cell array of character vectors
        %   with C elements where C is the number of classes in Y. The
        %   class name ClassNames{k} is associated with an integer ID k. If
        %   POST is a C-by-1 posterior probability vector (returned by
        %   PREDICT) then POST(k) is the posterior probability of
        %   membership in class with ID k - i.e., posterior probability of
        %   membership in class with name ClassNames{k}.
        ClassNames;        
    end
    
    properties(GetAccess=public,SetAccess=protected,Hidden,Dependent)       
        %PrivY - Integer coded response vector.
        %   The PrivY property is a column vector taking values from 1 up
        %   to C where C is the number of distinct levels of the response
        %   vector.
        PrivY;
        
        %YLabels - Response level names.
        %   The YLabels property is a cell array of character vectors of
        %   length C such that integer code k in PrivY is mapped to level
        %   name YLabels{k}.
        YLabels;
        
        %YLabelsOrig - Response level names (same type as the passed in Y)
        %   The YLabelsOrig property is an array representing the response
        %   levels such that integer code k in PrivY is mapped to level
        %   YLabelsOrig(k,:). YLabelsOrig is similar to YLabels except that
        %   YLabelsOrig is not a cell array of character vectors - it has
        %   the same type as the passed in Y.
        YLabelsOrig;
    end
    
    properties(Hidden)
        %Impl - Implementation class for fitting and prediction.
        %   The Impl property is a FeatureSelectionNCAClassificationImpl
        %   object.
        Impl;        
    end
        
    methods
        function y = get.Y(this)
            yid = this.PrivY;
            y   = this.YLabelsOrig(yid,:);
        end
        
        function cn = get.ClassNames(this)
            cn = this.YLabels;
        end 
        
        function privY = get.PrivY(this)
            privY = this.Impl.PrivY;
        end
        
        function yLabels = get.YLabels(this)
            yLabels = this.Impl.YLabels;
        end
        
        function yLabelsOrig = get.YLabelsOrig(this)
            yLabelsOrig = this.Impl.YLabelsOrig;
        end
    end
    
%% Constructor.
    methods(Hidden)
        function this = FeatureSelectionNCAClassification(X,Y,varargin)
            this = doFit(this,X,Y,varargin{:});            
        end
    end
        
%% predict and loss methods.    
    methods        
        function [labels,postprobs,classnames] = predict(this,XTest)
%predict - Make predictions on test data.
%   [LABELS,POSTPROBS,CLASSNAMES] = predict(MODEL,X) takes an object MODEL
%   of type FeatureSelectionNCAClassification, an M-by-P predictor matrix X
%   with M observations and P predictors, and computes an array LABELS
%   containing the predicted labels corresponding to rows of X. LABELS has
%   the same type as the passed in Y matrix during training. POSTPROBS is
%   an M-by-C matrix such that POSTPROBS(i,:) contains the posterior
%   probabilities of membership in classes 1 through C corresponding to
%   X(i,:). CLASSNAMES is a cell array of character vectors containing the
%   name of the class for each column of POSTPROBS.

            % 1. Validate XTest.
            isok = FeatureSelectionNCAClassification.checkXType(XTest);
            if ~isok                
                error(message('stats:FeatureSelectionNCA:FeatureSelectionNCAClassification:BadXType'));
            end
            
            % 2. Get the size of XTest.
            [M,P] = size(XTest);
            
            % 3. Ensure that XTest has the right number of columns.
            if ( P ~= this.NumFeatures )                
                error(message('stats:FeatureSelectionNCA:FeatureSelectionNCAClassification:BadX',this.NumFeatures));
            end
            
            % 4. Bad rows in XTest - badrows is a M-by-1 logical vector.
            badrows = any(isnan(XTest),2);
            
            % 5. Remove bad rows from XTest.
            XTest(badrows,:) = [];
            
            % 6. If XTest is empty. we are done.
            if ( isempty(XTest) )                
                error(message('stats:FeatureSelectionNCA:FeatureSelectionNCAClassification:NoObservationsInX'));
            end
            
            % 7. Dispatch to the right predict method on the Impl object.
            % This method will account for predictor standardization if
            % required. postprobs will be of size M-by-C where C is the
            % length of this.YLabels and M is the number of rows in XTest
            % before removing NaN/Infs.
            C               = length(this.YLabels);
            postprobs       = nan(M,C,class(XTest));
            computationMode = this.ModelParams.ComputationMode;
            usemex          = strcmpi(computationMode,classreg.learning.fsutils.FeatureSelectionNCAModel.ComputationModeMex) && ~issparse(XTest);
            if usemex
                postprobs(~badrows,:) = predictNCAMex(this.Impl,XTest);
            else
                postprobs(~badrows,:) = predictNCA(this.Impl,XTest);
            end
            
            % 8. Get the ID that gets the highest posterior probability.
            [~,id] = max(postprobs(~badrows,:),[],2);
            
            % 9. For observations with NaN or Inf values, predict into the
            % first ID - this is an arbitrary choice.
            allid           = ones(M,1);
            allid(~badrows) = id;
            
            % 10. Convert ID to the type of labels supplied during training.
            labels = this.YLabelsOrig(allid,:);
            
            % 11. Also output classnames.
            classnames = this.YLabels;
        end
        
        function err = loss(this,XTest,YTest,varargin)
%loss - Evaluate accuracy of learned feature weights on test data.
%   ERR = loss(MODEL,X,Y) computes the misclassification error when
%   predicting into a class with the highest posterior probability. MODEL
%   is an object of type FeatureSelectionNCAClassification, X is the
%   predictor matrix, and Y is the response variable containing the true
%   class labels.
%
%   ERR = loss(MODEL,X,Y,'PARAM1',val1,...) accepts additional name value
%   pairs and returns a different measure of accuracy of the learned
%   feature weights (smaller the better).
%
%       Parameter        Value
%       'LossFunction' - A character vector or string specifying the
%                        loss type. Choices are 'quadratic' and
%                        'classiferror'. As described below, choice
%                        'quadratic' returns L and 'classiferror' returns
%                        MISCLASSERR. Default is 'classiferror'.
%
%   X is an M-by-P matrix where M is the number of observations and P is
%   the number of predictors. Y can be a numeric, logical, or categorical
%   vector with M elements, a cell array of character vectors with M
%   elements or a character matrix with M rows. Element i of Y is the true
%   label for row i of X.
%
%   L is computed as follows:
%
%       L = mean(sum((pest - ptrue).^2,2))
%
%   where pest is an M-by-C matrix containing the estimated probabilities
%   of membership in one of the C classes for each row in X. ptrue is an
%   M-by-C indicator matrix such that ptrue(i,k) = 1 if row i in X belongs
%   to class k and 0 otherwise.
%
%   For row i of X suppose:
%
%       kest(i) = index j such that pest(i,j) is maximized.
%       k(i)    = index j such that ptrue(i,j) = 1.
%
%   Then
%
%       MISCLASSERR = mean(kest ~= k)
            [varargin{:}] = convertStringsToChars(varargin{:});
            % 1. Figure out the loss type.
                % 1.1 Set parameter defaults.
                dfltLossFunction = FeatureSelectionNCAClassification.LossFunctionMisclassErr;
                % 1.2 Parse optional name/value pairs.
                paramNames = {  'LossFunction'};
                paramDflts = {dfltLossFunction};                
                lossType   = internal.stats.parseArgs(paramNames,paramDflts,varargin{:});
                % 1.3 Validate optional parameters.
                lossType = internal.stats.getParamVal(lossType,this.BuiltInLossFunctions,'LossFunction');                                

            % 2. Validate XTest.
            isok = FeatureSelectionNCAClassification.checkXType(XTest);
            if ~isok                
                error(message('stats:FeatureSelectionNCA:FeatureSelectionNCAClassification:BadXType'));
            end
            
            % 3. Get the size of XTest.
            [M,P] = size(XTest);
            
            % 4. Ensure that XTest has the right number of columns.
            if ( P ~= this.NumFeatures )                
                error(message('stats:FeatureSelectionNCA:FeatureSelectionNCAClassification:BadX',this.NumFeatures));                
            end
            
            % 5. Validate YTest and convert it to IDs compatible with the
            % training data. Ensure that yidTest is a column vector.
            [isok,yidTest] = encodeCategorical(this,YTest);            
            if ~isok                
                error(message('stats:FeatureSelectionNCA:FeatureSelectionNCAClassification:BadYType'));
            end
            yidTest = yidTest(:);
            
            % 6. If YTest contains new categories not originally found in
            % the training data, encodeCategorical codes these new
            % categories as NaNs. So if there are NaNs in yidTest, this is
            % an error.
            if ( any(isnan(yidTest)) )                
                error(message('stats:FeatureSelectionNCA:FeatureSelectionNCAClassification:BadYLevels'));
            end
            
            % 7. Ensure that XTest and yidTest have the same number of rows.
            if ( M ~= length(yidTest) )                
                error(message('stats:FeatureSelectionNCA:FeatureSelectionNCAClassification:BadY',M));
            end
            
            % 8. Remove bad rows from XTest and yidTest.
            [XTest,yidTest] = FeatureSelectionNCAClassification.removeBadRows(XTest,yidTest,[]);
            if ( isempty(XTest) || isempty(yidTest) )                
                error(message('stats:FeatureSelectionNCA:FeatureSelectionNCAClassification:NoObservationsInXY'));
            end
            MNew = size(XTest,1);
            
            % 9. Get probs - a MNew-by-C vector of probabilities. Column k
            % is the probability of membership in class k. If data was
            % standardized during training, the same standardization is
            % applied in the predict method.
            computationMode = this.ModelParams.ComputationMode;
            usemex          = strcmpi(computationMode,classreg.learning.fsutils.FeatureSelectionNCAModel.ComputationModeMex) && ~issparse(XTest);
            if usemex
                probs = predictNCAMex(this.Impl,XTest);
            else
                probs = predictNCA(this.Impl,XTest);
            end
            
            if ( strcmpi(lossType,FeatureSelectionNCAClassification.LossFunctionMisclassErr) )            
                % 10. Compute misclassification error if needed. yidPred is
                % a MNew-by-1 vector containing the predicted IDs which
                % have the highest posterior probability. Compare yidPred
                % with yidTest.
                [~,yidPred] = max(probs,[],2);
                misclasserr = sum(yidPred ~= yidTest)/MNew;
                err         = misclasserr;
            else
                % 11. Compute the mean squared error between the estimated
                % and true probabilities. If yidTest(i) = k then we need to
                % create a vector probs(i,:) - ek where ek is a row unit
                % vector with a 1 in position k. In other words, we need to
                % subtract 1 from probs(i,yidTest(i)).
                idx        = sub2ind(size(probs),(1:MNew)',yidTest);
                probs(idx) = probs(idx) - 1;
                L          = mean(sum(probs.^2,2));
                err        = L;
            end
        end        
    end
    
%% Object display.
    methods(Hidden)
        function s = propsForDisp(this,s)
        %propsForDisp - Create a structure with properties for display.
        %   s = propsForDisp(this,s) takes an object this of type
        %   FeatureSelectionNCAClassification, and an optional struct s and
        %   adds fields to s for display purposes. s can be empty.
            
            % 1. Invoke super-class method.
            s = propsForDisp@classreg.learning.fsutils.FeatureSelectionNCAModel(this,s);
            
            % 2. Add additional properties specific to classification to s.
            s.Y          = this.Y;
            s.W          = this.W;
            s.ClassNames = this.ClassNames;
        end
    end
    
%% Utilities for setting up input data.    
    methods(Hidden)        
        function [X,yid,W,labels,labelsOrig] = setupXYW(this,X,Y,W) 
            if ( isempty(this.Impl) )
                % First time setup.
                
                % 1. Check X.
                X = FeatureSelectionNCAClassification.validateX(X);
                
                % 2. Check Y.
                [yid,labels,labelsOrig] = FeatureSelectionNCAClassification.validateY(Y);
                
                % 3. Check W.
                W = FeatureSelectionNCAClassification.validateW(W);
                
                % 4. Number of rows in X must match the length of yid, W.
                N = size(X,1);
                if ( length(yid) ~= N )                    
                    error(message('stats:FeatureSelectionNCA:FeatureSelectionNCAClassification:BadYLength'));
                end
                
                if ( length(W) ~= N )                    
                    error(message('stats:FeatureSelectionNCA:FeatureSelectionNCAClassification:BadWeights',N));
                end
                
                % 5. Remove unusable rows from X and yid.                
                [X,yid,W] = FeatureSelectionNCAClassification.removeBadRows(X,yid,W);
                
                % 6. If X, yid or W become empty after removing bad rows, stop.
                if ( isempty(X) || isempty(yid) || isempty(W) )                    
                    error(message('stats:FeatureSelectionNCA:FeatureSelectionNCAClassification:NoObservationsInXY'));
                end
                
                % 7. Return X, yid, W, labels and labelsOrig.      
            else
                % Modification of X, Y and W (e.g., for cross validation).
                
                % 1. Check X.
                X = FeatureSelectionNCAClassification.validateX(X);
                
                % 2. Check Y.
                    % 2.1 Check the type of Y.
                    isok = FeatureSelectionNCAClassification.checkYType(Y);
                    if ~isok                        
                        error(message('stats:FeatureSelectionNCA:FeatureSelectionNCAClassification:BadYType'));
                    end
                    
                    % 2.2 Encode Y using the existing YLabels.
                    [isok,yid] = encodeCategorical(this,Y);
                    if ~isok                        
                        error(message('stats:FeatureSelectionNCA:FeatureSelectionNCAClassification:BadYType'));
                    end
                    yid = yid(:);
                    if ( any(isnan(yid)) )                        
                        error(message('stats:FeatureSelectionNCA:FeatureSelectionNCAClassification:BadYLevels'));
                    end
                
                % 3. Check W.
                W = FeatureSelectionNCAClassification.validateW(W);
                    
                % 4. Number of rows in X must match the length of yid, W.
                N = size(X,1);
                if ( length(yid) ~= N )
                    error(message('stats:FeatureSelectionNCA:FeatureSelectionNCAClassification:BadYLength'));
                end
                
                if ( length(W) ~= N )                    
                    error(message('stats:FeatureSelectionNCA:FeatureSelectionNCAClassification:BadWeights',N));
                end
                
                % 5. Remove unusable rows from X and yid.                
                [X,yid,W] = FeatureSelectionNCAClassification.removeBadRows(X,yid,W);
                
                % 6. If X, yid or W become empty after removing bad rows, stop.
                if ( isempty(X) || isempty(yid) || isempty(W) )
                    error(message('stats:FeatureSelectionNCA:FeatureSelectionNCAClassification:NoObservationsInXY'));
                end
                
                % 7. Return X, yid, W, labels and labelsOrig. Note that
                % labels and labelsOrig are extracted from the object.                
                labels     = this.YLabels;
                labelsOrig = this.YLabelsOrig;
            end
        end
        
        function [isok,yidTestNew] = encodeCategorical(this,YTest)
            % 1. Ensure that YTest has a valid type.
            isok = FeatureSelectionNCAClassification.checkYType(YTest);
            if ~isok
                yidTestNew = [];
                return;
            end
            
            % 2. Ensure that if levels with name 'A' have been assigned ID
            % xx in the training data then levels with name 'A' in YTest
            % also get assigned the ID xx.
            [yidTest,labelsTest] = grp2idx(YTest);
            
            % 3. Holder for new IDs.
            yidTestNew = nan(size(yidTest));
            
            % 4. Match labelsTest to this.YLabels. loc(j) is equal to k if
            % labelsTest{j} matches this.YLabels{k} and 0 otherwise.            
            [~,loc] = ismember(labelsTest,this.YLabels);
            
            % 5. ID j in yidTest has name labelsTest{j}. If labelsTest{j}
            % matches this.YLabels{k} (i.e., if loc(j) == k) then all
            % points in yidTest with ID j should be assigned the ID k. If
            % loc(j) == 0 then labelsTest{j} does not match anything in
            % this.YLabels. Since yidTestNew is initialized to all NaN, in 
            % this case, the new ID is NaN.
            M = length(labelsTest);
            for j = 1:M
                k = loc(j);
                if ( k ~= 0 )
                    yidTestNew(yidTest == j) = k;
                end
            end
        end
    end
    
%% Utilities for input validation.    
    methods(Static,Hidden)                
        function [yid,labels,labelsOrig] = validateY(Y)
        %validateY - Validate the Y input.
        %   [yid,labels,labelsOrig] = validateY(Y) ensure that Y is a
        %   grouping variable. If not an error is thrown. If Y is a
        %   grouping variable, it is converted into yid, labels and
        %   labelsOrig.
        %
        %   * yid is a vector of level IDs. If Y is a character matrix,
        %   element k of yid corresponds to Y(k,:) otherwise element k of
        %   yid corresponds to Y(k).
        %
        %   * labels is a cell array of character vectors such that ID k in
        %   yid is mapped to the name labels{k}.
        %
        %   * labelsOrig has the same type as Y such that ID k in yid is 
        %   mapped to labelsOrig(k,:).
        
            % 1. Check the type of Y.
            isok = FeatureSelectionNCAClassification.checkYType(Y);            
            if ~isok                
                error(message('stats:FeatureSelectionNCA:FeatureSelectionNCAClassification:BadYType'));
            end
            
            % 2. Get yid, labels and labelsOrig using grp2idx. labelsOrig
            % should already have the column orientation (grp2idx help).
            [yid,labels,labelsOrig] = grp2idx(Y);
            yid                     = yid(:);
            labels                  = labels(:);
        end
        
        function isok = checkYType(Y)            
            % 1. Y can be a categorical, logical or numeric vector or a 
            % cell vector of character vectors.
            isok1 = isvector(Y) && ( isa(Y,'categorical') || islogical(Y) || (isnumeric(Y) && isreal(Y)) || iscellstr(Y) );
            
            % 2. Y can also be a character matrix with each row
            % representing a class level.
            isok2 = ischar(Y) && ismatrix(Y);
            
            % 3. Ensure that 1 or 2 holds.
            isok  = isok1 || isok2;
        end                
    end
end