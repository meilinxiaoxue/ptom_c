classdef (Abstract) FeatureSelectionNCAModel < classreg.learning.internal.DisallowVectorOps
%FeatureSelectionNCAModel Feature selection using neighborhood component analysis (NCA).
%   FeatureSelectionNCAModel is an abstract class for representing feature
%   selection using neighborhood component analysis (NCA). This class
%   defines common properties and methods needed for feature selection
%   using NCA for classification and regression.

%   Copyright 2015-2016 The MathWorks, Inc.

%% Constants.

    %%
    % _Optimization related_
    properties(Constant,Hidden)
        SolverLBFGS          = classreg.learning.fsutils.Solver.SolverLBFGS;
        SolverSGD            = classreg.learning.fsutils.Solver.SolverSGD;
        SolverMiniBatchLBFGS = classreg.learning.fsutils.Solver.SolverMiniBatchLBFGS;
        BuiltInSolvers       = {classreg.learning.fsutils.FeatureSelectionNCAModel.SolverLBFGS,...
                                classreg.learning.fsutils.FeatureSelectionNCAModel.SolverSGD,...
                                classreg.learning.fsutils.FeatureSelectionNCAModel.SolverMiniBatchLBFGS};
        
        LineSearchMethodBacktracking = classreg.learning.fsutils.Solver.LineSearchMethodBacktracking;
        LineSearchMethodWeakWolfe    = classreg.learning.fsutils.Solver.LineSearchMethodWeakWolfe;
        LineSearchMethodStrongWolfe  = classreg.learning.fsutils.Solver.LineSearchMethodStrongWolfe;
        BuiltInLineSearchMethods     = {classreg.learning.fsutils.FeatureSelectionNCAModel.LineSearchMethodBacktracking,...
                                        classreg.learning.fsutils.FeatureSelectionNCAModel.LineSearchMethodWeakWolfe,...
                                        classreg.learning.fsutils.FeatureSelectionNCAModel.LineSearchMethodStrongWolfe};
                                    
        StringAuto = classreg.learning.fsutils.Solver.StringAuto;
    end
    
    %%
    % _Loss functions_
    properties(Constant,Hidden)
        RobustLossL1                         = 'mad';
        RobustLossL2                         = 'mse';
        RobustLossEpsilonInsensitive         = 'epsiloninsensitive';        
        BuiltInRobustLossFunctionsRegression = {classreg.learning.fsutils.FeatureSelectionNCAModel.RobustLossL1,...
                                                classreg.learning.fsutils.FeatureSelectionNCAModel.RobustLossL2,...                                                
                                                classreg.learning.fsutils.FeatureSelectionNCAModel.RobustLossEpsilonInsensitive};
                                            
        RobustLossMisclassError                  = 'classiferror';        
        BuiltInRobustLossFunctionsClassification = {classreg.learning.fsutils.FeatureSelectionNCAModel.RobustLossMisclassError};
    end
        
    %%
    % _Supported methods_
    properties(Constant,Hidden)
        MethodRegression     = 'regression';
        MethodClassification = 'classification';
        BuiltInMethods       = {classreg.learning.fsutils.FeatureSelectionNCAModel.MethodRegression,...
                                classreg.learning.fsutils.FeatureSelectionNCAModel.MethodClassification};        
    end
        
    %%
    % _IDs for built in loss functions used in MEX code_
    properties(Constant,Hidden)
        MISCLASS_LOSS            = 1;
        L1_LOSS                  = 2;
        L2_LOSS                  = 3;
        EPSILON_INSENSITIVE_LOSS = 4;
        CUSTOM_LOSS              = 5;
    end
        
    %%
    % _Fit methods_
    properties(Constant,Hidden)
        FitMethodNone             = 'none';
        FitMethodExact            = 'exact';
        FitMethodDivideAndConquer = 'average';
        BuiltInFitMethods         = {classreg.learning.fsutils.FeatureSelectionNCAModel.FitMethodNone,...
                                     classreg.learning.fsutils.FeatureSelectionNCAModel.FitMethodExact,...
                                     classreg.learning.fsutils.FeatureSelectionNCAModel.FitMethodDivideAndConquer};        
    end
    
    %%
    % _Supported character vector priors_
    properties(Constant,Hidden)
        PriorUniform   = 'uniform';
        PriorEmpirical = 'empirical';
        BuiltInPriors  = {classreg.learning.fsutils.FeatureSelectionNCAModel.PriorUniform,...
                          classreg.learning.fsutils.FeatureSelectionNCAModel.PriorEmpirical};        
    end    
    
    %%
    % _Supported computation modes_
    properties(Constant,Hidden)
        ComputationModeMex      = 'mex-outer-tbb';
        ComputationModeMatlab   = 'matlab-inner-vector';
        BuiltInComputationModes = {classreg.learning.fsutils.FeatureSelectionNCAModel.ComputationModeMex,...
                                   classreg.learning.fsutils.FeatureSelectionNCAModel.ComputationModeMatlab};        
    end
    
    %%
    % _Subclass names_
    properties(Constant,Hidden)        
        ClassificationSubClassName = 'FeatureSelectionNCAClassification';
        RegressionSubClassName     = 'FeatureSelectionNCARegression';
    end
    
%% Properties holding computed values.    
    properties(GetAccess=public,SetAccess=protected,Dependent)
        %FitInfo - Fit information.
        %   The FitInfo property is a structure with the following fields:
        %
        %       FieldName                Meaning
        %       Iteration              - Iteration index.
        %       Objective              - Regularized objective function 
        %                                for minimization.
        %       UnregularizedObjective - Unregularized objective function 
        %                                for minimization.
        %       Gradient               - Gradient of regularized objective
        %                                function for minimization.
        %
        %   o For classification, UnregularizedObjective represents the
        %   negative of leave-one-out accuracy of NCA classifier on the
        %   training data. 
        %
        %   o For regression, UnregularizedObjective represents the
        %   leave-one-out loss between the true response and the predicted
        %   response using NCA regression model.
        %
        %   o For solver 'lbfgs', Gradient is the final gradient and for
        %   solvers 'sgd' and 'minibatch-lbfgs', Gradient is the final
        %   minibatch gradient.
        %
        %   o For 'FitMethod' equal to 'average', FitInfo is a M-by-1
        %   struct array where M is the number of partitions specified via
        %   the 'NumPartitions' name/value pair in the call to fsrnca or
        %   fscnca.
        FitInfo;

        %FeatureWeights - Feature weight vector.
        %   FeatureWeights is a P-by-1 feature weight vector where P is the
        %   number of predictors in X. 
        %
        %   o The absolute value of FeatureWeights(k) is a measure of the
        %   importance of predictor k. If FeatureWeights(k) is close to 0,
        %   predictor k does not influence the response Y.
        %
        %   o For 'FitMethod' equal to 'average', FeatureWeights is a
        %   matrix of size P-by-M where M is the number of partitions
        %   specified via the 'NumPartitions' name/value pair in the call
        %   to fsrnca or fscnca.
        FeatureWeights;     
        
        %Mu - Predictor means.
        %   The Mu property is either empty or a vector with P elements,
        %   one for each predictor. If training data were standardized, the
        %   Mu property is filled with means of predictors used for
        %   training. Otherwise the Mu property is empty. If the Mu
        %   property is not empty, the PREDICT method centers predictor
        %   matrix X by subtracting the respective element of Mu from every
        %   column.
        Mu;
        
        %Sigma - Predictor standard deviations.
        %   The Sigma property is either empty or a vector with P elements,
        %   one for each predictor. If training data were standardized, the
        %   Sigma property is filled with standard deviations of predictors
        %   used for training. Otherwise the Sigma property is empty. If
        %   the Sigma property is not empty, the PREDICT method scales
        %   predictor matrix X by dividing every column by the respective
        %   element of Sigma (after centering using MU).
        Sigma;        
    end
        
    methods
        function fitInfo = get.FitInfo(this)
            fitInfo = this.Impl.FitInfo;
        end
        
        function featureWeights = get.FeatureWeights(this)
            featureWeights = this.Impl.FeatureWeights;
        end
        
        function mu = get.Mu(this)
            mu = this.Impl.Mu;
        end
        
        function sigma = get.Sigma(this)
            sigma = this.Impl.Sigma;
        end
    end
    
%% Abstract properties.
    properties(Abstract,GetAccess=public,SetAccess=protected,Dependent)
        %Y - True class labels or continuous response used to train this model.
        %   The Y property is an array of true class labels for
        %   classification and an array of continuous response values for
        %   regression. For classification, Y is of the same type as the
        %   passed-in Y data: a categorical, logical or numeric vector, a
        %   cell array of character vectors or a character matrix.
        Y;
    end

    properties(Abstract,GetAccess=public,SetAccess=protected,Hidden,Dependent)
        %PrivY - Response vector for the model.
        %   The PrivY property is a vector of group IDs for classification
        %   and a real vector of responses for regression.
        PrivY;
    end
    
    properties(Abstract,Hidden)
        %Impl - Implementation class for fitting and prediction.
        %   The Impl property is of type FeatureSelectionNCAImpl. It
        %   provides methods for fitting a NCA feature selection model and
        %   for making predictions.
        Impl;
    end
    
%% Properties holding inputs.
    properties(GetAccess=public,SetAccess=protected,Dependent)
        %X - Matrix of predictors.
        %   The X property contains the predictor values. It is a numeric
        %   matrix of size N-by-P, where N is the number of rows and P is
        %   the number of predictor variables or columns in the training
        %   data.
        X;
    end

    properties(GetAccess=public,SetAccess=protected,Hidden,Dependent)
        %PrivX - Matrix of predictors used to build the model.
        %   The PrivX property could be the original X matrix if no
        %   standardization is used or it could be the standardized
        %   predictor matrix. This is the matrix of predictors used to fit
        %   the model and make predictions.
        PrivX;
    end
    
    properties(GetAccess=public,SetAccess=protected,Dependent)
        %W - Weights of observations used to train this model.
        %   The W property is a numeric vector of size N, where N is the
        %   number of observations. The sum of weights is N.
        W;
    end
    
    properties(GetAccess=public,SetAccess=protected,Hidden,Dependent)
        %PrivW - Weights of observations used to train this model.
        %   The PrivW property is a numeric vector of size N, where N is
        %   the number of observations. The sum of weights is N.
        PrivW;
    end
    
    properties(GetAccess=public,SetAccess=protected,Dependent)
        %ModelParameters - Model parameters.
        %   The ModelParameters property is a structure that holds
        %   parameters used for training this model. You can access the
        %   properties of ModelParameters using the dot notation. For
        %   example, if MODEL is a feature selection object then you can
        %   access the LossFunction property like this:
        %
        %       MODEL.ModelParameters.LossFunction
        ModelParameters;
    end
    
    properties(GetAccess=public,SetAccess=protected,Hidden,Dependent)
        %ModelParams - Model parameters for training this model.
        %   The ModelParams property is of type FeatureSelectionNCAParams.
        %   See classreg.learning.fsutils.FeatureSelectionNCAParams for a
        %   description of the properties in ModelParams.
        ModelParams;
    end    
    
    methods
        function X = get.X(this)
            X = this.Impl.X;
        end
        
        function privX = get.PrivX(this)
            privX = this.Impl.PrivX;
        end
        
        function W = get.W(this)
            W = this.Impl.W;
        end
        
        function privW = get.PrivW(this)
            privW = this.Impl.PrivW;
        end
        
        function mp = get.ModelParameters(this)            
            mp = toStruct(this.Impl.ModelParams);
        end
        
        function mp = get.ModelParams(this)
            mp = this.Impl.ModelParams;
        end 
    end
    
    properties(GetAccess=public,SetAccess=protected,Dependent)        
        %Lambda - Regularization parameter.
        %   The Lambda property is a scalar containing the value of the
        %   regularization parameter used for training this model. For N
        %   observations, the best Lambda value that minimizes the
        %   generalization error of the NCA model is expected to be a
        %   multiple of 1/N.
        Lambda;
        
        %FitMethod - Fitting method.
        %   The FitMethod property is a character vector containing the
        %   name of the method used to fit this model as follows:
        %
        %       FitMethod              Meaning        
        %       'none'               - No fitting.
        %       'exact'              - Fitting using all data.
        %       'average'            - Divide data into subsets, fit each 
        %                              subset using the 'exact' method and
        %                              average the feature weights.
        %
        %   o FitMethod 'none' can be used to evaluate the generalization
        %   error of the NCA model using the initial feature weights
        %   supplied in the call to fscnca or fsrnca.
        FitMethod;
        
        %Solver - Solver used to fit this model.
        %   The Solver property is a character vector containing the name
        %   of the solver used to fit this model as follows:
        %
        %       Solver              Meaning        
        %       'lbfgs'           - limited memory BFGS
        %       'sgd'             - stochastic gradient descent
        %       'minibatch-lbfgs' - stochastic gradient descent with LBFGS 
        %                           applied to minibatches
        Solver;
        
        %GradientTolerance - Tolerance on gradient norm.
        %   The GradientTolerance property is a positive real scalar
        %   specifying the relative convergence tolerance on the gradient
        %   norm for 'lbfgs' and 'minibatch-lbfgs' solvers.
        GradientTolerance;
                
        %IterationLimit - Maximum number of iterations for optimization.
        %   The IterationLimit property is a positive integer specifying
        %   the maximum number of iterations for the specified Solver.
        IterationLimit;
        
        %PassLimit - Maximum number of passes.
        %   The PassLimit property is a positive integer specifying the
        %   maximum number of passes for 'sgd' and 'minibatch-lbfgs'
        %   solvers. Every pass processes all observations in the dataset.
        PassLimit;
        
        %InitialLearningRate - Initial learning rate.
        %   The InitialLearningRate property is a positive real scalar
        %   specifying the initial learning rate for solvers 'sgd' and
        %   'minibatch-lbfgs'. The learning rate decays over iterations
        %   starting with the value specified for InitialLearningRate.
        %
        %   o If InitialLearningRate is specified as 'auto' in the call to
        %   fscnca or fsrnca then then the initial learning rate is
        %   determined using experiments on small subsets of the data. In
        %   that case, InitialLearningRate is [].
        %
        %   o You can use the name/value pairs 'NumTuningIterations' and
        %   'TuningSubsetSize' to control the automatic tuning of initial
        %   learning rate in the call to fscnca or fsrnca.
        InitialLearningRate;
        
        %Verbose - Verbosity level.
        %   The Verbose property is a non-negative integer specifying the
        %   verbosity level as follows:
        %
        %       Verbose      Meaning
        %          0       - No convergence summary is displayed.
        %          1       - Convergence summary is displayed on screen.
        %          >1      - More convergence information is displayed on
        %                    screen depending on the fitting algorithm.
        %
        %   o When using solver 'minibatch-lbfgs', if Verbose is set to a
        %   value >1 then the convergence information includes iteration
        %   log from intermediate minibatch LBFGS fits.
        Verbose;
        
        %InitialFeatureWeights - Initial feature weights.
        %   The InitialFeatureWeights property is a P-by-1 vector of real
        %   positive initial feature weights where P is the number of
        %   predictors in X.
        %
        %   o The regularized objective function for optimizing feature
        %   weights is non-convex. As a result, using different initial
        %   feature weights can give different results. Setting all initial
        %   feature weights to 1 generally works well but in some cases
        %   random initialization by setting InitialFeatureWeights to
        %   rand(P,1) can give better quality solutions.
        InitialFeatureWeights;
        
        %NumObservations - Number of observations.
        %   The NumObservations property is a scalar containing the number
        %   of observations in X and Y after removing NaN/Inf values.
        NumObservations;        
    end        

    properties(GetAccess=public,SetAccess=protected,Hidden,Dependent)
        %NumFeatures - Number of features.
        %   The NumFeatures property is a scalar containing the number of
        %   predictors in PrivX.
        NumFeatures;
    end
    
    methods
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
        
%% Abstract predict and loss methods.    
    methods(Abstract)        
        predict(this,XTest)        
        loss(this,XTest,YTest)                
    end
        
%% Refitting a model.
    methods        
        function this = refit(this,varargin)
%refit - Fit the model again with modified parameters.
%   MODEL = refit(MODEL,'PARAM1',val1,...) refits this MODEL using the
%   following optional parameter name/value pairs:
%
%       NCA parameters:
%
%       'Lambda'            A non-negative real scalar specifying the 
%                           regularization parameter. Default is
%                           MODEL.Lambda.
%       'FitMethod'         Method used to fit this model. Choices are:
%                               'none'    - No fitting.
%                               'exact'   - Fitting using all data.
%                               'average' - Divide data into subsets, fit 
%                                           each subset using the 'exact'
%                                           method and average the feature 
%                                           weights.
%                           Default is MODEL.FitMethod.
%       'Solver'            A character vector or string specifying
%                           the solver to use for estimating feature
%                           weights. Choices are:
%                     'lbfgs'           - limited memory BFGS 
%                     'sgd'             - stochastic gradient descent
%                     'minibatch-lbfgs' - stochastic gradient descent 
%                                         with LBFGS applied to minibatches
%                           Default is MODEL.Solver.
%       'InitialFeatureWeights'    
%                           A P-by-1 vector of real positive initial 
%                           feature weights where P is the number of
%                           columns in X used for training. Default is
%                           MODEL.InitialFeatureWeights.
%       'Verbose'           A non-negative integer specifying the verbosity
%                           level as follows:
%                           * 0  - no convergence summary is displayed.
%                           * 1  - convergence summary is displayed on
%                                  screen.
%                           * >1 - more convergence information is
%                                  displayed on screen depending on the 
%                                  fitting algorithm.                        
%                           Default is MODEL.Verbose.
%
%       Additional options for 'Solver' equal to 'lbfgs' and
%       'minibatch-lbfgs':
%
%       'GradientTolerance' 
%                           A positive real scalar specifying the relative
%                           convergence tolerance on the gradient norm for
%                           solver 'lbfgs'. Default is
%                           MODEL.GradientTolerance.
%
%       Additional options for 'Solver' equal to 'sgd' and
%       'minibatch-lbfgs':
%
%       'PassLimit'         A positive integer specifying the maximum
%                           number of passes for solver 'sgd'. Every pass
%                           processes size(MODEL.X,1) observations. Default
%                           is MODEL.PassLimit.
%       'InitialLearningRate'      
%                           A positive real scalar specifying the initial
%                           learning rate for solver 'sgd'. When using
%                           solver 'sgd', the learning rate decays over
%                           iterations starting with the value specified
%                           for 'InitialLearningRate'. Default is
%                           MODEL.InitialLearningRate.
%
%       Additional options for 'Solver' equal to 'sgd' or 'lbfgs' or 
%       'minibatch-lbfgs':
%
%       'IterationLimit'    A positive integer specifying the maximum 
%                           number of iterations. Default is
%                           MODEL.IterationLimit.
            [varargin{:}] = convertStringsToChars(varargin{:});
            % 1. Set parameter defaults.            
            dfltLambda                = this.Lambda;
            dfltFitMethod             = this.FitMethod;
            dfltSolver                = this.Solver;
            dfltGradientTolerance     = this.GradientTolerance;
            dfltIterationLimit        = this.IterationLimit;
            dfltPassLimit             = this.PassLimit;
            dfltInitialLearningRate   = this.InitialLearningRate;
            dfltVerbose               = this.Verbose;
            dfltInitialFeatureWeights = this.InitialFeatureWeights; 
            
            % 2. Parse optional name/value pairs.
            paramNames = {  'Lambda',   'FitMethod',   'Solver',   'GradientTolerance',   'IterationLimit',   'PassLimit',   'InitialLearningRate',   'Verbose',   'InitialFeatureWeights'};
            paramDflts = {dfltLambda, dfltFitMethod, dfltSolver, dfltGradientTolerance, dfltIterationLimit, dfltPassLimit, dfltInitialLearningRate, dfltVerbose, dfltInitialFeatureWeights};
            [lambda,fitMethod,solver,gradientTolerance,iterationLimit,passLimit,initialLearningRate,verbose,initialFeatureWeights] = internal.stats.parseArgs(paramNames,paramDflts,varargin{:});            
            
            % 3. Fit the model with new parameters. Validation of inputs is
            % handled by FeatureSelectionNCAParams class below. Set DoFit
            % to true since we want to fit the model right away.
                % 3.1 Set new model parameters.
                this.Impl.ModelParams.Lambda                = lambda;                
                this.Impl.ModelParams.FitMethod             = fitMethod;
                this.Impl.ModelParams.Solver                = solver;
                this.Impl.ModelParams.GradientTolerance     = gradientTolerance;
                this.Impl.ModelParams.IterationLimit        = iterationLimit;
                this.Impl.ModelParams.PassLimit             = passLimit;
                this.Impl.ModelParams.InitialLearningRate   = initialLearningRate;
                this.Impl.ModelParams.Verbose               = verbose;
                this.Impl.ModelParams.InitialFeatureWeights = initialFeatureWeights;                
                this.Impl.ModelParams.DoFit                 = true;

                % 3.2 Build the model without standardization since we just
                % changed the model parameters, not the data.
                this.Impl = buildModel(this.Impl);
        end
    end
    
%% Object display.
    methods(Hidden)        
        function disp(this)
            % 1. Display class name.
            internal.stats.displayClassName(this);            
            % 2. Display body.
            s = propsForDisp(this,[]);
            disp(s);          
            % 3. Display links to methods and properties.
            internal.stats.displayMethodsProperties(this);
        end
        
        function s = propsForDisp(this,s)
        %propsForDisp - Create a structure with properties for display.
        %   s = propsForDisp(this,s) takes an object this of type
        %   FeatureSelectionNCAModel, and an optional struct s and adds
        %   fields to s for display purposes. s can be empty.
        
            % 1. Create empty struct if needed.
            if ( nargin < 2 || isempty(s) )
                s = struct;
            end
            
            % 2. Add common properties of feature selection objects to s.
            s.NumObservations       = this.NumObservations;
            s.ModelParameters       = this.ModelParameters;
            s.Lambda                = this.Lambda;
            s.FitMethod             = this.FitMethod;
            s.Solver                = this.Solver;            
            s.GradientTolerance     = this.GradientTolerance;
            s.IterationLimit        = this.IterationLimit;
            s.PassLimit             = this.PassLimit;
            s.InitialLearningRate   = this.InitialLearningRate;
            s.Verbose               = this.Verbose;
            s.InitialFeatureWeights = this.InitialFeatureWeights;            
            s.FeatureWeights        = this.FeatureWeights;
            s.FitInfo               = this.FitInfo;
            s.Mu                    = this.Mu;
            s.Sigma                 = this.Sigma;
            s.X                     = this.X;
        end
    end
    
%% Generic fitting methods.
    methods(Hidden)        
        function this = doFit(this,X,Y,varargin)
        % X = N-by-P matrix of predictors
        % Y = N-by-1 vector of responses
        % varargin = optional name/value pairs
                    
            % 1. Extract observation weights.
            paramNames            = {'Weights'};
            paramDflts            = {       []};        
            [Weights,~,otherArgs] = internal.stats.parseArgs(paramNames,paramDflts,varargin{:});
            
            if ( isempty(Weights) )
                Weights = ones(size(X,1),1);
            end           
            
            % 2. Get predictors, response IDs, weights and label info. For
            % regression, yLabels and yLabelsOrig are []. privW are the
            % observation weights.
            [X,privY,privW,yLabels,yLabelsOrig] = setupXYW(this,X,Y,Weights);
            
            % 3. Create model parameters object.
            modelParams = setupModelParams(this,X,privY,otherArgs{:});
            
            % 4. Build model including a standardization step.
            this.Impl = makeImpl(this,X,privY,privW,modelParams,yLabels,yLabelsOrig);
        end
        
        function this = doReFit(this,XSub,YSub,WSub,modelParams)
        % XSub is a subset of X used in doFit.
        % YSub is a subset of Y used in doFit.
        % WSub is a subset of Weights used in doFit.
        % modelParams is an object representing new model parameters.
        
            % 1. Get predictors, response IDs, weights and label info. For
            % regression, yLabels and yLabelsOrig are []. privW are the
            % observation weights.
            [XSub,privY,privW,yLabels,yLabelsOrig] = setupXYW(this,XSub,YSub,WSub);
            
            % 2. Update model parameters object.
            modelParams.NumObservations = size(XSub,1);
            
            % 3. Build model including a standardization step.
            this.Impl = makeImpl(this,XSub,privY,privW,modelParams,yLabels,yLabelsOrig);
        end        
    end
    
%% Utilities for building the model.
    methods(Hidden)
        function impl = makeImpl(this,X,privY,privW,modelParams,yLabels,yLabelsOrig)
            isClassification = isa(this,classreg.learning.fsutils.FeatureSelectionNCAModel.ClassificationSubClassName);
            if isClassification
                impl = classreg.learning.fsutils.FeatureSelectionNCAClassificationImpl(X,privY,privW,modelParams,yLabels,yLabelsOrig);
            else
                impl = classreg.learning.fsutils.FeatureSelectionNCARegressionImpl(X,privY,privW,modelParams);
            end
            impl = standardizeDataAndBuildModel(impl);
        end
    end
    
%% Cross validation related methods.    
    methods(Hidden)
        function lossVals = cvLossVector(this,cvp,varargin)
        %cvLossVector - Compute cross-validation loss vector.
        %   lossVals = cvLossVector(this,cvp) takes an object this of type 
        %   FeatureSelectionNCAModel, a cvpartition object cvp and performs
        %   cross-validation. For k-fold cross-validation, lossVals is a
        %   vector of length k-by-1. lossVals(k) is the loss of the model
        %   trained on all observations in this.X except fold k.
        %
        %   lossVals = cvLossVector(this,cvp,varargin) passes extra input
        %   arguments to the loss method. This can be used to control the
        %   type of loss for example.
            
            numTestSets = cvp.NumTestSets;
            lossVals    = zeros(numTestSets,1);
            
            for k = 1:numTestSets
                % 1. Training set for fold k.
                trainIdx = cvp.training(k);                                
                XTrain   = this.X(trainIdx,:);
                YTrain   = this.Y(trainIdx,:);
                WTrain   = this.W(trainIdx,:);
                
                % 2. Test set for fold k.
                testIdx  = cvp.test(k);
                XTest    = this.X(testIdx,:);
                YTest    = this.Y(testIdx,:);
                
                % 3. Train on training set and test on test set.                
                modelParams       = this.ModelParams;
                modelParams.DoFit = true;
                nca               = doReFit(this,XTrain,YTrain,WTrain,modelParams);
                
                lossVals(k) = loss(nca,XTest,YTest,varargin{:});                
            end
        end
        
        function lossVals = cvLoss(this,varargin)
        %cvLoss - Compute cross-validation loss for this model.
        %   LOSSVALS = cvLoss(MODEL) computes 10-fold cross-validation loss
        %   for this model. For K-fold cross validation LOSSVALS is a
        %   K-by-1 vector such that LOSSVALS(i) is the loss value for data
        %   in fold i computed using a model trained on all observations
        %   excluding fold i.
        %
        %   LOSSVALS = cvLoss(MODEL,'PARAM1',val1,'PARAM2',val2,...) 
        %   specifies optional parameter name/value pairs:
        %
        %       'KFold'       - Number of folds for cross-validation, a 
        %                       numeric positive scalar; 10 by default.
        %       'Holdout'     - Holdout validation uses the specified
        %                       fraction of the data for test, and uses the
        %                       rest of the data for training. Specify a
        %                       numeric scalar between 0 and 1.
        %       'Leaveout'    - If 'on', use leave-one-out cross-validation.
        %       'CVPartition' - An object of class CVPARTITION; empty by 
        %                       default. If a CVPARTITION object is
        %                       supplied, it is used for splitting the data
        %                       into subsets.
        %
        %   cvLoss can also accept any additional name/value pairs accepted
        %   by the loss method of the MODEL. For example, if MODEL is of
        %   class FeatureSelectionNCAClassification, cvLoss can also accept
        %   a 'LossFunction' name/value pair. See the help text for loss
        %   method of FeatureSelectionNCAClassification for a description
        %   of 'LossFunction'.
        
            % 1. Make cvpartition object.           
            [cvp,extraArgs] = makeCVPartitionObject(this.Impl,varargin{:});
        
            % 2. Compute cross-validation loss vector.           
            lossVals = cvLossVector(this,cvp,extraArgs{:});
        end        
    end
        
%% Utilities for setting up input data.
    methods(Hidden,Abstract)
        [X,PrivY,PrivW,YLabels,YLabelsOrig] = setupXYW(this,X,Y,W)        
    end
    
    methods(Hidden)     
        function modelParams = setupModelParams(this,X,PrivY,varargin)
        % This method is called after setting up data. This is because some
        % model parameters depend on the data.
            isClassification = isa(this,classreg.learning.fsutils.FeatureSelectionNCAModel.ClassificationSubClassName);
            if isClassification
                method = classreg.learning.fsutils.FeatureSelectionNCAModel.MethodClassification;
            else
                method = classreg.learning.fsutils.FeatureSelectionNCAModel.MethodRegression;
            end
            modelParams = classreg.learning.fsutils.FeatureSelectionNCAParams(method,X,PrivY,varargin{:});            
        end
    end
    
%% Utilities for input validation.
    methods(Static,Hidden,Abstract)
        [yid,labels,labelsOrig] = validateY(Y)
        isok = checkYType(Y)
    end
    
    methods(Static,Hidden)
        function X = validateX(X)
            isok = classreg.learning.fsutils.FeatureSelectionNCAModel.checkXType(X);
            if ~isok                
                error(message('stats:classreg:learning:fsutils:FeatureSelectionNCAModel:BadX'));
            end
        end
        
        function isok = checkXType(X)
            isok = isfloat(X) && isreal(X) && ismatrix(X);
        end
        
        function wobs = validateW(wobs)
            [isok,wobs] = classreg.learning.fsutils.FeatureSelectionNCAParams.isNumericRealVectorNoNaNInf(wobs,[]);
            isok        = isok && all(wobs >= 0);
            if ~isok                
                error(message('stats:classreg:learning:fsutils:FeatureSelectionNCAModel:BadWeights'));
            end
        end
        
        function [X,yid,W,badrows] = removeBadRows(X,yid,W)
        %removeBadRows - Remove unusable rows from X, yid and W.
        %   [X,yid,W,badrows] = removeBadRows(X,yid,W) takes a N-by-P
        %   matrix X, N-by-1 vector yid and N-by-1 vector W and removes
        %   some rows from X, yid and W. Row k is removed from X, yid and W
        %   if:
        %
        %   * X(k,:) has a NaN or Inf value.
        %   * yid(k) has a NaN value.
        %   * W(k)   has a NaN value.
        %
        %   badrows is a N-by-1 logical vector marking the location of bad
        %   rows.
        %
        %   W can also be entered as [] if there are no weights.
        
            % 1. Rows with NaN values in X.
            badrowsX = any(isnan(X),2);
            
            % 2. Rows with NaN values in yid.
            badrowsY = isnan(yid);
            
            % 3. Rows with NaN values in W.
            badrowsW = isnan(W);
            
            % 4. Bad rows from X, yid and W.
            if ( isempty(W) )
                badrows = badrowsX | badrowsY;
            else
                badrows  = badrowsX | badrowsY | badrowsW;
            end
            
            % 5. Remove bad rows from X, yid and W.
            X(badrows,:) = [];
            yid(badrows) = [];
            
            if ( ~isempty(W) )
                W(badrows) = [];
            end
        end
                
        function T = convertToDouble(T)
            if ( ~isa(T,'double') )
                T = double(T);
            end
        end
        
        function T = convertToSingle(T)
            if ( ~isa(T,'single') )
                T = single(T);
            end
        end
    end
end