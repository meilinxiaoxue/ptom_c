classdef FeatureSelectionNCARegressionImpl < classreg.learning.fsutils.FeatureSelectionNCAImpl

    %   Copyright 2015-2016 The MathWorks, Inc.
    
    %% Properties holding inputs.
    properties(Dependent)
        Y;
    end
    
    properties
        PrivY;
    end
    
    %% Getters for dependent properties.
    methods
        function y = get.Y(this)
            y = this.PrivY;
        end
    end
    
    %%  Constructor.
    methods
        function this = FeatureSelectionNCARegressionImpl(X,privY,privW,modelParams)
            % X should be the unstandardized data. It is saved in PrivX to
            % be standardized later (if needed).
            this       = this@classreg.learning.fsutils.FeatureSelectionNCAImpl(X,privW,modelParams);
            this.PrivY = privY;
        end
    end
    
    %% Objective function makers.
    methods
        function fun = makeObjectiveFunctionForMinimizationMex(this)
            % 1. Get X and y. For efficiency reasons, transpose X to
            % compute NCA objective function.
            Xt = this.PrivX';
            y  = this.PrivY;
            
            % 2. Make Robust loss function integer code for mex. Here is a
            % list of supported loss functions for mex:
            %
            %             LOSS FUNCTION NAME             ID
            %             classiferror          -        1
            %             l1 (mad)              -        2
            %             l2 (mse)              -        3
            %             epsiloninsensitive    -        4
            %
            % See section 8 in theory spec for robust loss functions.
            
            robustLoss = this.ModelParams.LossFunction;
            if ( isa(robustLoss,'function_handle') )
                lossID = robustLoss;
            else
                switch lower(robustLoss)
                    case lower(classreg.learning.fsutils.FeatureSelectionNCAModel.RobustLossL1)
                        lossID = classreg.learning.fsutils.FeatureSelectionNCAModel.L1_LOSS;
                        
                    case lower(classreg.learning.fsutils.FeatureSelectionNCAModel.RobustLossL2)
                        lossID = classreg.learning.fsutils.FeatureSelectionNCAModel.L2_LOSS;
                        
                    case lower(classreg.learning.fsutils.FeatureSelectionNCAModel.RobustLossEpsilonInsensitive)
                        lossID = classreg.learning.fsutils.FeatureSelectionNCAModel.EPSILON_INSENSITIVE_LOSS;
                        
                    otherwise
                        error(message('stats:FeatureSelectionNCA:FeatureSelectionNCARegression:BadLossFunctionRegression'));
                end
            end
            
            % 3. Extract epsilon.
            epsilon = this.ModelParams.Epsilon;
            
            % 4. Create the NCA objective function. fun below can be called
            % like this:
            %
            %   [f,g] = fun(w)
            %
            % or
            %
            %   [f,g] = fun(w,T)
            %
            % where T is a subset of {1,2,...,N}. The first call gives the
            % full NCA objective with T = {1,2,...,N} whereas the second
            % call is appropriate for SGD. See section 8 in theory spec for
            % robust loss functions.
            fun = makeRegularizedObjectiveFunctionForMinimizationRobustMex(this,Xt,y,lossID,epsilon);
        end
        
        function fun = makeObjectiveFunctionForMinimization(this)
            % 1. Get X and y. For efficiency reasons, transpose X to
            % compute NCA objective function.
            Xt = this.PrivX';
            y  = this.PrivY;
            
            % 2. Make Robust loss function (if needed). See section 8 in
            % theory spec for robust loss functions. lossFcn below is a
            % function handle that can be called like this:
            %
            %   L = lossFcn(yi,yj)
            %
            % o yi is a N-by-1 vector.
            % o yj is a M-by-1 vector.
            % o L  is a N-by-M matrix.
            robustLoss = this.ModelParams.LossFunction;
            if ( isa(robustLoss,'function_handle') )
                lossFcn = robustLoss;
            else
                switch lower(robustLoss)
                    case lower(classreg.learning.fsutils.FeatureSelectionNCAModel.RobustLossL1)
                        lossFcn = @(yi,yj) abs(bsxfun(@minus,yi,yj'));
                        
                    case lower(classreg.learning.fsutils.FeatureSelectionNCAModel.RobustLossL2)
                        lossFcn = @(yi,yj) (bsxfun(@minus,yi,yj')).^2;
                        
                    case lower(classreg.learning.fsutils.FeatureSelectionNCAModel.RobustLossEpsilonInsensitive)
                        epsilon = this.ModelParams.Epsilon;
                        lossFcn = @(yi,yj) max(0,abs(bsxfun(@minus,yi,yj'))-epsilon);
                        
                    otherwise
                        error(message('stats:FeatureSelectionNCA:FeatureSelectionNCARegression:BadLossFunctionRegression'));
                end
            end
            
            % 3. Create the NCA objective function. fun below can be called
            % like this:
            %
            %   [f,g] = fun(w)
            %
            % or
            %
            %   [f,g] = fun(w,T)
            %
            % where T is a subset of {1,2,...,N}. The first call gives the
            % full NCA objective with T = {1,2,...,N} whereas the second
            % call is appropriate for SGD. See section 8 in theory spec for
            % robust loss functions.
            
            % single implementation for regression and classification.
            fun = makeRegularizedObjectiveFunctionForMinimizationRobust(this,Xt,y,lossFcn);
        end
    end
    
    %% Utility for computing effective observation weights.
    methods
        function effobswts = effectiveObservationWeights(this,obswts,~)
            % 1. How many observations?
            N = this.NumObservations;
            
            % 2. Observation weights should sum to N.
            sumobswts = sum(obswts);
            if ( sumobswts ~= N )
                effobswts = obswts*N/sumobswts;
            else
                effobswts = obswts;
            end
        end
    end
    
    %% Helpers for making predictions.
    methods(Hidden)
        function ypred = predictNCA(this,XTest)
        %predictNCA - Make predictions using the NCA regression model.
        %   ypred = predictNCA(this,XTest) takes an object this of type
        %   FeatureSelectionNCARegressionImpl, a M-by-P predictor matrix
        %   XTest where P = size(this.X,2) and returns a M-by-1 vector
        %   ypred containing the predicted response of the NCA regression
        %   model corresponding to the rows of XTest. It is assumed that
        %   XTest has been validated.
            
            % 1. If Standardize is true, apply standardization to XTest.
            XTest = applyStandardizationToXTest(this,XTest);
            
            % 2. Number of rows in XTest.
            M = size(XTest,1);
            
            % 3. Estimated feature weight vector, sigma value and 1-by-N
            % observation weights.
            w      = mean(this.FeatureWeights,2);
            sigma  = this.ModelParams.LengthScale;
            obswts = this.PrivObservationWeights';
            
            % 4. Transpose training and test data for efficiency.
            %    XTest is P-by-M and XTrain is P-by-N.
            XTest  =  XTest';
            XTrain = (this.PrivX)';
            
            % 5. Get N-by-1 response vector used for training.
            yTrain = this.PrivY;
            
            % 6. Initialize predicted values.
            ypred = zeros(M,1);
            
            for i = 1:M
                % 6.1 Current observation.
                xi = XTest(:,i);
                
                % 6.2 P-by-N matrix dist such that:
                %   dist(r,j) = |x_ir - x_jr|
                % where
                %   x_ir = r th element of x_i and
                %   x_jr = r th element of x_j.
                dist = abs(bsxfun(@minus,XTrain,xi));
                
                % 6.3 1-by-N vector of weighted distances between xi
                % and observations in XTrain. Subtract min(wtdDist) from
                % wtdDist so that sum(pij) is not zero.
                wtdDist = sum(bsxfun(@times,dist,w.^2),1);
                wtdDist = wtdDist - min(wtdDist);
                
                % 6.4 Compute 1-by-N vector of probabilities pij.
                pij = obswts.*exp(-wtdDist/sigma);
                pij = pij/sum(pij);
                
                % 6.5 Compute predicted response for xi.
                ypred(i) = pij*yTrain;
            end
        end
        
        function ypred = predictNCAMex(this,XTest)
        %predictNCAMex - Make predictions using the NCA regression model.
        %   ypred = predictNCAMex(this,XTest) takes an object this of type
        %   FeatureSelectionNCARegressionImpl, a M-by-P predictor matrix
        %   XTest where P = size(this.X,2) and returns a M-by-1 vector
        %   ypred containing the predicted response of the NCA regression
        %   model corresponding to the rows of XTest. It is assumed that
        %   XTest has been validated. XTest must be a full matrix.
            
            % 1. If Standardize is true, apply standardization to XTest.
            XTest = applyStandardizationToXTest(this,XTest);
            
            % 2. Number of rows in XTest.
            M = size(XTest,1);
            
            % 3. Estimated feature weight vector, sigma and observation
            % weights.
            w      = mean(this.FeatureWeights,2);
            sigma  = this.ModelParams.LengthScale;
            obswts = this.PrivObservationWeights;
            
            % 4. Transpose training and test data for efficiency.
            %    XTest is P-by-M and XTrain is P-by-N.
            XTest  =  XTest';
            XTrain = (this.PrivX)';
            
            % 5. Get N-by-1 response vector used for training.
            yTrain = this.PrivY;
            
            % 6. More info needed for calling mex utility.
            [P,N]   = size(XTrain);
            C       = NaN;
            doclass = false;
            
            % 7. If XTest is double, ensure all inputs to predict are
            % double and if XTest is single, ensure all inputs to predict
            % are single. XTest is a full matrix already. Ensure that all
            % other inputs are also full.
            if ( isa(XTest,'double') )
                convertToDoubleFcn = @(x) full(classreg.learning.fsutils.FeatureSelectionNCAModel.convertToDouble(x));
                
                XTrain = convertToDoubleFcn(XTrain);
                yTrain = convertToDoubleFcn(yTrain);
                P      = convertToDoubleFcn(P);
                N      = convertToDoubleFcn(N);
                M      = convertToDoubleFcn(M);
                C      = convertToDoubleFcn(C);
                sigma  = convertToDoubleFcn(sigma);
                w      = convertToDoubleFcn(w);
                obswts = convertToDoubleFcn(obswts);
            else
                convertToSingleFcn = @(x) full(classreg.learning.fsutils.FeatureSelectionNCAModel.convertToSingle(x));
                
                XTrain = convertToSingleFcn(XTrain);
                yTrain = convertToSingleFcn(yTrain);
                P      = convertToSingleFcn(P);
                N      = convertToSingleFcn(N);
                M      = convertToSingleFcn(M);
                C      = convertToSingleFcn(C);
                sigma  = convertToSingleFcn(sigma);
                w      = convertToSingleFcn(w);
                obswts = convertToSingleFcn(obswts);
            end
            
            % 8. Call mex utility.
            ypred   = classreg.learning.fsutils.predict(XTrain,yTrain,P,N,XTest,M,C,sigma,w,doclass,obswts);
        end
    end
    
end

