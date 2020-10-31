classdef FeatureSelectionNCAClassificationImpl < classreg.learning.fsutils.FeatureSelectionNCAImpl
       
    %   Copyright 2015-2016 The MathWorks, Inc.
    
    %% Properties holding inputs.
    properties(Dependent)
        Y;
        ClassNames;
    end
    
    properties
        PrivY;
        YLabels;
        YLabelsOrig;
    end
    
    %% Getters for dependent properties.
    methods
        function y = get.Y(this)
            yid = this.PrivY;
            y   = this.YLabelsOrig(yid,:);
        end
        
        function cn = get.ClassNames(this)
            cn = this.YLabels;
        end
    end
    
    %%  Constructor.
    methods
        function this = FeatureSelectionNCAClassificationImpl(X,privY,privW,modelParams,yLabels,yLabelsOrig)
            % X should be the unstandardized data. It is saved in PrivX to
            % be standardized later (if needed).
            this             = this@classreg.learning.fsutils.FeatureSelectionNCAImpl(X,privW,modelParams);
            this.PrivY       = privY;
            this.YLabels     = yLabels;
            this.YLabelsOrig = yLabelsOrig;
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
                    case lower(classreg.learning.fsutils.FeatureSelectionNCAModel.RobustLossMisclassError)
                        lossID = classreg.learning.fsutils.FeatureSelectionNCAModel.MISCLASS_LOSS;
                        
                    otherwise
                        error(message('stats:FeatureSelectionNCA:FeatureSelectionNCAClassification:BadLossFunctionClassification'));
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
            
            % Single implementation for regression and classification.
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
                    case lower(classreg.learning.fsutils.FeatureSelectionNCAModel.RobustLossMisclassError)
                        lossFcn = @(yi,yj) -double(bsxfun(@eq,yi,yj'));
                        
                    otherwise
                        error(message('stats:FeatureSelectionNCA:FeatureSelectionNCAClassification:BadLossFunctionClassification'));
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
            
            % Single implementation for regression and classification.
            fun = makeRegularizedObjectiveFunctionForMinimizationRobust(this,Xt,y,lossFcn);
        end
    end
    
    %% Utility for computing effective observation weights.
    methods
        function effobswts = effectiveObservationWeights(this,obswts,prior)
            % obswts = N-by-1 vector of observation weights
            % prior  = a valid string or a structure
            %
            % If prior is a structure, it has these fields:
            % prior.ClassProbs = K-by-1 vector
            % prior.ClassNames = K-by-1 cell array of strings
            %
            % prior.ClassNames should contain all class names found in
            % this.YLabels.
            
            % 1. How many observations and how many classes?
            N = this.NumObservations;
            R = length(this.YLabels);
            
            % 2. Get a vector of prior class probabilities.
            if ( internal.stats.isString(prior) )
                % Priors for string specification - normalized later.
                switch lower(prior)
                    case lower(classreg.learning.fsutils.FeatureSelectionNCAModel.PriorUniform)
                        classProbs = ones(R,1);
                        
                    case lower(classreg.learning.fsutils.FeatureSelectionNCAModel.PriorEmpirical)
                        % Special case of all equal observation weights.
                        w1 = obswts(1);
                        if ( all(obswts == w1) )
                            effobswts = obswts/w1;
                            return;
                        end
                        
                        classProbs = accumarray(this.PrivY,ones(N,1),[R,1]);
                        
                    otherwise
                        error(message('stats:FeatureSelectionNCA:FeatureSelectionNCAClassification:BadPriorString'));
                end
            else
                % Make sure we find all classes from this.YLabels in
                % classNames.
                classProbs = prior.ClassProbs;
                classNames = prior.ClassNames;
                
                [tf,loc] = ismember(this.YLabels,classNames);
                isok     = all(tf);
                if ~isok
                    error(message('stats:FeatureSelectionNCA:FeatureSelectionNCAClassification:BadPriorStruct'));
                end
                
                % After the next two lines, integer codes in this.PrivY
                % should be such that ID k corresponds to class k and
                % classProbs(k) is the prior probability for that class.
                % Also classNames should be identical to this.YLabels. The
                % first line below is commented out because classNames is
                % not used later.
                % classNames = classNames(loc);
                classProbs = classProbs(loc);
            end
            
            % 3. Normalize the prior probabilities to sum to 1.
            sumClassProbs = sum(classProbs);
            if ( sumClassProbs == 0 )
                error(message('stats:FeatureSelectionNCA:FeatureSelectionNCAClassification:AllZeroPriorProbs'));
            end
            classProbs = classProbs/sumClassProbs;
            
            % 4. Compute effective observation weights.
            effobswts = obswts;
            for k = 1:R
                idxk            = (this.PrivY == k);
                wk              = obswts(idxk);
                effobswts(idxk) = classProbs(k)*(wk/sum(wk));
            end
            
            % 5. Effective observation weights should sum to N.
            effobswts = effobswts*N/sum(effobswts);
        end
    end
    
    %% Helpers for making predictions.
    methods(Hidden)
        function postprobs = predictNCAMex(this,XTest)
        %predictNCAMex - Make predictions using the NCA classifier.
        %   postprobs = predictNCAMex(this,XTest) takes an object this of
        %   type FeatureSelectionNCAClassificationImpl, a M-by-P predictor
        %   matrix XTest where P = size(this.X,2) and returns a matrix
        %   postprobs of size M-by-C where C is the number of classes in
        %   this.YLabels. XTest is assumed to have been validated. XTest
        %   must be a full matrix.
        %
        %   postprobs(i,k) = posterior probability of membership in class
        %                    with ID k for observation XTest(i,:).
        %
        %   ID k has the name this.YLabels{k}.
            
            % 1. If Standardize is true, apply standardization to XTest.
            XTest = applyStandardizationToXTest(this,XTest);
            
            % 2. Number of rows in XTest and the number of classes.
            M = size(XTest,1);
            C = length(this.YLabels);
            
            % 3. Estimated feature weight vector, sigma and observation
            % weights.
            w      = mean(this.FeatureWeights,2);
            sigma  = this.ModelParams.LengthScale;
            obswts = this.PrivObservationWeights;
            
            % 4. Transpose training and test data for efficiency.
            %    XTest is P-by-M and XTrain is P-by-N.
            XTest  =  XTest';
            XTrain = (this.PrivX)';
            
            % 5. Get training IDs. yidTrain is N-by-1.
            yidTrain = this.PrivY;
            
            % 6. More info needed for calling Mex utility.
            [P,N]   = size(XTrain);
            doclass = true;
            
            % 7. If XTest is double, ensure all inputs to predict are
            % double and if XTest is single, ensure all inputs to predict
            % are single. XTest is a full matrix already. Ensure that all
            % other inputs are also full.
            if ( isa(XTest,'double') )
                convertToDoubleFcn = @(x) full(classreg.learning.fsutils.FeatureSelectionNCAModel.convertToDouble(x));
                
                XTrain   = convertToDoubleFcn(XTrain);
                yidTrain = convertToDoubleFcn(yidTrain);
                P        = convertToDoubleFcn(P);
                N        = convertToDoubleFcn(N);
                M        = convertToDoubleFcn(M);
                C        = convertToDoubleFcn(C);
                sigma    = convertToDoubleFcn(sigma);
                w        = convertToDoubleFcn(w);
                obswts   = convertToDoubleFcn(obswts);
            else
                convertToSingleFcn = @(x) full(classreg.learning.fsutils.FeatureSelectionNCAModel.convertToSingle(x));
                
                XTrain   = convertToSingleFcn(XTrain);
                yidTrain = convertToSingleFcn(yidTrain);
                P        = convertToSingleFcn(P);
                N        = convertToSingleFcn(N);
                M        = convertToSingleFcn(M);
                C        = convertToSingleFcn(C);
                sigma    = convertToSingleFcn(sigma);
                w        = convertToSingleFcn(w);
                obswts   = convertToSingleFcn(obswts);
            end
            
            % 8. Call Mex utility.
            postprobs = classreg.learning.fsutils.predict(XTrain,yidTrain,P,N,XTest,M,C,sigma,w,doclass,obswts);
            
            % 9. Transpose postprobs to make it M-by-C.
            postprobs = postprobs';
        end
        
        function postprobs = predictNCA(this,XTest)
        %predictNCA - Make predictions using the NCA classifier.
        %   postprobs = predictNCA(this,XTest) takes an object this of type
        %   FeatureSelectionNCAClassificationImpl, a M-by-P predictor
        %   matrix XTest where P = size(this.X,2) and returns a matrix
        %   postprobs of size M-by-C where C is the number of classes in
        %   this.YLabels. XTest is assumed to have been validated.
        %
        %   postprobs(i,k) = posterior probability of membership in class
        %                    with ID k for observation XTest(i,:).
        %
        %   ID k has the name this.YLabels{k}.
            
            % 1. If Standardize is true, apply standardization to XTest.
            XTest = applyStandardizationToXTest(this,XTest);
            
            % 2. Number of rows in XTest and the number of classes.
            M = size(XTest,1);
            C = length(this.YLabels);
            
            % 3. Estimated feature weight vector, sigma value and 1-by-N
            % observation weights.
            w      = mean(this.FeatureWeights,2);
            sigma  = this.ModelParams.LengthScale;
            obswts = this.PrivObservationWeights';
            
            % 4. Transpose training and test data for efficiency.
            %    XTest is P-by-M and XTrain is P-by-N.
            XTest  =  XTest';
            XTrain = (this.PrivX)';
            
            % 5. Get training IDs. yidTrain is N-by-1.
            yidTrain = this.PrivY;
            
            % 6. Initialize posterior probabilities.
            postprobs = zeros(C,M);
            
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
                
                % 6.5 Compute posterior probability for each class. Using
                % accumarray is an efficient way of doing this:
                %   post = zeros(C,1);
                %   for k = 1:C
                %       post(k) = sum(pij(yidTrain == k));
                %   end
                %   postprobs(:,i) = post;
                %
                % yidTrain has IDs from 1 to C where C is the number of
                % classes.
                % postprobs(:,i) = accumarray(yidTrain,pij);
                postprobs(1:max(yidTrain),i) = accumarray(yidTrain,pij);
            end
            
            % 7. Transpose postprobs to make it M-by-C.
            postprobs = postprobs';
        end
    end
    
end

