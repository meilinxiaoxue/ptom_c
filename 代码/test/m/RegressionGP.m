classdef RegressionGP < ...
        classreg.learning.regr.FullRegressionModel & ...
        classreg.learning.regr.CompactRegressionGP   
%RegressionGP Gaussian Process Regression (GPR) model.
%   RegressionGP is a Gaussian process model for regression. This model can
%   predict response given new data. This model also stores data used for
%   training and can compute resubstitution predictions.
%
%   An object of this class cannot be created by calling the constructor.
%   Use FITRGP to create a RegressionGP object by fitting a GPR model to
%   training data.
%
%   This class is derived from CompactRegressionGP.
%
%   RegressionGP properties:
%       NumObservations       - Number of observations.
%       X                     - Matrix of predictors used to train this model.
%       Y                     - Observed response used to train this model.
%       W                     - Weights of observations used to train this model.
%       ModelParameters       - GPR parameters.
%       PredictorNames        - Names of predictors used for this model.
%       ExpandedPredictorNames - Names of expanded predictors.
%       CategoricalPredictors - Indices of categorical predictors.
%       ResponseName          - Name of the response variable.
%       ResponseTransform     - Transformation applied to predicted regression response.
%       KernelFunction        - Kernel function used in this model.
%       KernelInformation     - Information about parameters of this kernel function.
%       BasisFunction         - Basis function used in this model.
%       Beta                  - Estimated value of basis function coefficients.
%       Sigma                 - Estimated value of noise standard deviation.
%       PredictorLocation     - A vector of predictor means (if standardization is used).
%       PredictorScale        - A vector of predictor standard deviations (if standardization is used).
%       Alpha                 - Vector of weights for computing predictions.
%       ActiveSetVectors      - Subset of the training data needed to make predictions.
%       FitMethod             - Method used to estimate parameters.
%       PredictMethod         - Method used to make predictions.
%       ActiveSetMethod       - Method used to select the active set for sparse methods.
%       ActiveSetSize         - Size of the active set.
%       IsActiveSetVector     - Logical vector marking the active set for sparse methods.
%       LogLikelihood         - Maximized marginal log likelihood of the model.
%       ActiveSetHistory      - History of active set selection for sparse methods.
%       BCDInformation        - Information on BCD based computation of Alpha.
%       RowsUsed              - Logical index for rows used in fit. 
%
%   RegressionGP methods:
%       compact               - Compact this model.
%       crossval              - Cross-validate this model.
%       loss                  - Regression loss.
%       predict               - Predicted response of this model.
%       resubLoss             - Resubstitution regression loss.
%       resubPredict          - Resubstitution predicted response.
%       postFitStatistics     - Post fit statistics such as leave-one-out residuals.
%
%   Example: Train a GPR model on example data. 
%       % 1.Generate example data.
%       rng(0,'twister');
%       N = 100000;
%       X = linspace(0,1,N)';
%       X = [X,X.^2];
%       y = 1 + X*[1;2] + sin(20*X*[1;-2]) + 0.2*randn(N,1);
%       % 2. Fit the model using 'SR' and predict using 'FIC'. Use 20
%       % points in the active set selected using 'Entropy'.
%       gpr = fitrgp(X,y,'KernelFunction','SquaredExponential','FitMethod','SR','PredictMethod','FIC',...
%           'Basis','None','Optimizer','fminsearch','KernelParameters',[1;1],'ActiveSetSize',20,'ActiveSetMethod','Entropy',...
%           'Sigma',1,'Standardize',true,'verbose',1);
%       % 3. Plot fit and prediction intervals.
%       [pred,se,ci] = predict(gpr,X,'Alpha',0.01);
%       figure;
%       plot(y,'r');
%       hold on;
%       plot(pred,'b')
%       plot(ci(:,1),'g--');
%       plot(ci(:,2),'k--');
%       legend('Data','Pred','Lower 95%','Upper 95%','Location','Best');
%
%   See also fitrgp, classreg.learning.regr.CompactRegressionGP.
    
%   Copyright 2014-2017 The MathWorks, Inc.

    properties(SetAccess=protected,GetAccess=public,Dependent=true)
        %ISACTIVESETVECTOR - Selected active set for making predictions.
        %   ISACTIVESETVECTOR is a logical vector marking the subset of the
        %   training data selected as the active set for making predictions
        %   from a fitted model. If X is the original training data:
        %
        %       ACTIVESETVECTORS = X(ISACTIVESETVECTOR,:)
        %
        %   See also ACTIVESETVECTORS.
        IsActiveSetVector;
        
        %LOGLIKELIHOOD - Maximized marginal log likelihood of the model.
        %   LOGLIKELIHOOD is a scalar containing the maximized marginal log
        %   likelihood of the Gaussian process model. If FitMethod is equal
        %   to 'SD', 'SR' or 'FIC', LOGLIKELIHOOD contains the maximized
        %   approximation to the marginal log likelihood of the Gaussian
        %   process model. If FitMethod is 'None' then LOGLIKELIHOOD is [].
        %
        %   See also FITMETHOD.
        LogLikelihood;
        
        %ACTIVESETHISTORY - History of active set selection.
        %   ACTIVESETHISTORY is a structure containing the history of
        %   interleaved active set selection and parameter estimation for
        %   FitMethod equal to 'SD', 'SR' or 'FIC'. ACTIVESETHISTORY has
        %   the following fields:
        %
        %   FIELD NAME         MEANING
        %   ParameterVector  - Cell array containing vectors [beta;theta;sigma].
        %   ActiveSetIndices - Cell array containing active set indices.
        %   LogLikelihood    - Vector containing maximized log likelihoods.
        %   CriterionProfile - Cell array containing active set selection 
        %                      criterion values as the active set grows in 
        %                      size from size 0 to its final size.
        %
        %   Suppose eta = [beta;theta;sigma] where beta is a vector of
        %   explicit basis coefficients, theta is the unconstrained parameter
        %   vector for the kernel function and sigma is the noise standard
        %   deviation.
        %
        %   For FitMethod equal to 'SD', 'SR' or 'FIC', we start with a
        %   parameter vector eta0 and select an active set A1. Then we
        %   maximize the Gaussian process model marginal log likelihood or
        %   its approximation using eta0 and A1 to get the new parameter
        %   vector eta1 and the corresponding maximized log likelihood L1.
        %   After NumActiveSetRepeats repetitions of this process, we stop.
        %   NumActiveSetRepeats can be specified as a name/value pair in
        %   FITRGP. Here's an example of this process for 3 repetitions:
        %
        %   Initial parameter vector = eta0        
        %   Iteration       Parameter vector      Active set     Log likelihood
        %      1                eta1                 A1               L1
        %      2                eta2                 A2               L2
        %      3                eta3                 A3               L3
        %
        %       o Li is computed using Ai and etai.
        %       o A1 is computed using eta0.
        %       o A2 is computed using eta1.
        %       o A3 is computed using eta2.
        %
        %   For this example, ACTIVESETHISTORY will have fields such that:        
        %       o ParameterVector{i} stores etai.
        %       o ActiveSetIndices{i} stores Ai.
        %       o LogLikelihood{i} stores Li.
        %       o CriterionProfile{i} stores criterion values for selecting Ai.
        %
        %   Suppose FitMethod does not select an active set ('Exact' or
        %   'None') but PredictMethod does ('SD', 'SR' or 'FIC'). In this
        %   case, ParameterVector and LogLikelihood are empty but
        %   ActiveSetIndices and CriterionProfile are 1-by-1 cell arrays
        %   containing information on the active set selection for making
        %   predictions.
        %
        %   See also ACTIVESETMETHOD.
        ActiveSetHistory;
        
        %BCDINFORMATION - Information on BCD based computation of Alpha.
        %   BCDINFORMATION is a structure containing additional block
        %   coordinate descent (BCD) outputs if PredictMethod is 'BCD'. If
        %   N is the number of observations, BCDINFORMATION has the
        %   following fields:
        %
        %   Gradient        - N-by-1 vector containing gradient of the BCD
        %                     objective function at convergence.
        %   Objective       - Scalar containing the BCD objective function 
        %                     at convergence.
        %   SelectionCounts - N-by-1 integer vector indicating the number 
        %                     of times each point was selected into a block
        %                     during BCD.
        %
        %   The Alpha vector computed from BCD is stored in the Alpha
        %   field. If PredictMethod is not 'BCD' then BCDINFORMATION is [].
        %
        %   See also PREDICTMETHOD, ALPHA.
        BCDInformation;
    end
    
    methods
        function a = get.IsActiveSetVector(this)
            a = this.Impl.ActiveSet;
        end
        
        function a = get.LogLikelihood(this)
            a = this.Impl.LogLikelihoodHat;
        end
        
        function a = get.ActiveSetHistory(this)
            a = this.Impl.ActiveSetHistory;
        end
        
        function a = get.BCDInformation(this)
            a = this.Impl.BCDHistory;
        end
    end
    
    methods(Hidden)        
        function this = RegressionGP(X,Y,W,modelParams,dataSummary,responseTransform)
        %RegressionGP - Create a RegressionGP object.
        %   this = RegressionGP(X,Y,W,modelParams,dataSummary,responseTransform)
        %   takes a N-by-D matrix of predictors X, a N-by-1 vector of
        %   responses Y, a N-by-1 vector of observation weights W, an
        %   object containing model parameters modelParams, summary
        %   information about the data dataSummary, and information about
        %   the response transform responseTransform and makes an object of
        %   class RegressionGP.
        %
        %   NOTE: X, Y, W are either the originally supplied X, Y and W or
        %   a subset of the originally supplied X, Y, W (when using cross
        %   validation). Also X, Y and W may have NaN's which would need to
        %   be cleaned up here.
        
            % 0. Encode categorical predictors as group numbers
            if ~dataSummary.TableInput
                X = classreg.learning.internal.encodeCategorical(X,dataSummary.VariableRange);
            end
        
            % 1. Call superclass constructors.
            this = this@classreg.learning.regr.FullRegressionModel(...
                X,Y,W,modelParams,dataSummary,responseTransform);
            
            this = this@classreg.learning.regr.CompactRegressionGP(...
                dataSummary,responseTransform,[]);

            % 2. Remove observations with NaNs/Infs in X or Y. Ensure that
            % NaN/Inf removal does not cause X to become empty.
            badrows = any(isnan(this.PrivX),2) | any(isinf(this.PrivX),2) | any(isnan(this.PrivY),2) | any(isinf(this.PrivY),2);
            if any(badrows)
                this.PrivX(badrows,:) = [];
                this.PrivY(badrows)   = [];
                this.W(badrows)       = [];
                rowsused = this.DataSummary.RowsUsed;
                if isempty(rowsused)
                    rowsused = ~badrows;
                else
                    rowsused(rowsused) = ~badrows;
                end
                this.DataSummary.RowsUsed = rowsused;
            end
            if isempty(this.PrivX)
                error(message('stats:RegressionGP:RegressionGP:NoDataAfterNaNsRemoved'));
            end
            
            % 3. ActiveSet, ActiveSetSize, BlockSizeBCD and NumGreedyBCD
            % may be out of sync with X and Y either because of NaN/Inf
            % removal or because X and Y are a subset of the original X and
            % Y in the call to fitrgp - e.g., when using cross validation.
            
                % 3.1 this.W - weights should sum to 1.            
                this.W = this.W/sum(this.W);
                                        
                % 3.2 ActiveSetSize must be <= size(X,1).
                newN                           = size(this.X,1);            
                this.ModelParams.ActiveSetSize = min(this.ModelParams.ActiveSetSize,newN);
            
                % 3.3 cross validation is not permitted when using
                % ActiveSet but if NaN's were removed, we need to fix up
                % the supplied ActiveSet.            
                if ~isempty(this.ModelParams.ActiveSet)
                    this.ModelParams.ActiveSet(badrows) = [];
                    if ~any(this.ModelParams.ActiveSet)
                        error(message('stats:RegressionGP:RegressionGP:BadActiveSet'));
                    end
                end
            
                % 3.4 BlockSizeBCD must be <= size(X,1).
                blockSizeBCD = this.ModelParams.Options.BlockSizeBCD;
                blockSizeBCD = min(blockSizeBCD,newN);
                
                % 3.5 NumGreedyBCD must be <= BlockSizeBCD.
                numGreedyBCD = this.ModelParams.Options.NumGreedyBCD;
                numGreedyBCD = min(numGreedyBCD,blockSizeBCD);
                
                % 3.6 Modified Options in ModelParams.                                                               
                this.ModelParams.Options.BlockSizeBCD = blockSizeBCD;
                this.ModelParams.Options.NumGreedyBCD = numGreedyBCD;
            
            % 4. Make Impl object.
            this.Impl = classreg.learning.impl.GPImpl.make(...
                this.PrivX,this.PrivY,...
                this.ModelParams.KernelFunction,...
                this.ModelParams.KernelParameters,...
                this.ModelParams.BasisFunction,...
                this.ModelParams.Beta,...
                this.ModelParams.Sigma,...
                this.ModelParams.FitMethod,...
                this.ModelParams.PredictMethod,...
                this.ModelParams.ActiveSet,...
                this.ModelParams.ActiveSetSize,...
                this.ModelParams.ActiveSetMethod,...                                
                this.ModelParams.Standardize,...
                this.ModelParams.Verbose,...
                this.ModelParams.CacheSize,...
                this.ModelParams.Options,...
                this.ModelParams.Optimizer,...
                this.ModelParams.OptimizerOptions,...
                this.ModelParams.ConstantKernelParameters,...
                this.ModelParams.ConstantSigma,...
                this.ModelParams.InitialStepSize,...
                this.CategoricalPredictors,...
                this.VariableRange);
        end
    end
    
    methods(Static)
        function this = fit(X,Y,varargin)
            [varargin{:}] = convertStringsToChars(varargin{:});
            temp = classreg.learning.FitTemplate.make('GP','type','regression',varargin{:});
            this = fit(temp,X,Y);
        end        
    end
    
    methods
       function cmp = compact(this,varargin)
        %COMPACT Compact Gaussian process regression model.
        %   CMP=COMPACT(GPR) returns an object of class CompactRegressionGP
        %   holding the structure of the trained Gaussian process model. 
        %   The compact object does not contain X and Y used for training.
        %
        %   NOTE:
        %   o A compacted object is smaller, but cannot be used for
        %   cross-validation, computation of post-fit statistics, or
        %   computation of resubstitution predictions or loss.
        %
        %   See also fitrgp, RegressionGP,
        %   classreg.learning.regr.CompactRegressionGP.
        
            % 1. Make a compact form of Impl.
            compactImpl = compact(this.Impl);        
            % 2. Supply compactImpl to CompactRegressionGP constructor.
            dataSummary = this.DataSummary;
            dataSummary.RowsUsed = [];
            cmp = classreg.learning.regr.CompactRegressionGP(...
                dataSummary,this.PrivResponseTransform,compactImpl);            
        end        
    end
    
    methods
        function varargout = postFitStatistics(this)
        %postFitStatistics Post fit statistics for a Gaussian process regression model.        
        %   LOORES = postFitStatistics(GPR) takes a fitted Gaussian process
        %   regression model GPR and returns a N-by-1 vector LOORES
        %   containing estimates of the leave-one-out residuals of the
        %   model where N is the number of observations in the predictor
        %   matrix X used to train this model.
        %
        %   [LOORES,NEFF] = postFitStatistics(GPR) also returns a scalar
        %   NEFF containing the estimated effective number of parameters in
        %   the fitted model.
        %
        %   NOTE:
        %   o Computation of post fit statistics is supported only for
        %   PredictMethod 'Exact'. When computing post fit statistics, the
        %   explicit basis coefficients BETA are treated in a special way:
        %
        %   * If the FitMethod is 'Exact', postFitStatistics accounts for 
        %   the fact that coefficients BETA are estimated from data. 
        %
        %   * For other FitMethod values, coefficients BETA are treated as known. 
        %
        %   In all cases, the estimated kernel parameters and noise
        %   standard deviation are treated as known.
        %
        %   Example: Post fit statistics for an example fit.
        %       % 1. Generate example data.
        %       rng(0,'twister');
        %       N = 1000;
        %       x = linspace(-10,10,N)';
        %       y = 1 + x*5e-2 + sin(x)./x + 0.2*randn(N,1);
        %
        %       % 2. Fit the model using 'Exact' and predict using 'Exact'.
        %       gpr = fitrgp(x,y,'Basis','Linear','Optimizer','QuasiNewton','verbose',1,'FitMethod','Exact','PredictMethod','Exact','KernelFunction','Matern52');
        %
        %       % 3. Plot model fit and display effective number of 
        %       % parameters in the fit.
        %       [loores,neff] = postFitStatistics(gpr);
        %       figure;
        %       subplot(2,1,1);
        %       plot(x,y,'r');
        %       hold on;
        %       plot(x,resubPredict(gpr),'b');
        %       xlabel('x');
        %       ylabel('y');
        %       legend('Data','GPR fit','Location','Best');
        %       title(['Effective number of parameters = ',num2str(neff)]);
        %
        %       % 4. Plot leave-one-out residuals.
        %       subplot(2,1,2);
        %       plot(x,loores,'r.-');
        %       xlabel('x');
        %       ylabel('leave-one-out residuals');        
        %
        %   See also RegressionGP/predict, fitrgp.
                   
            % 1. Post fit statistics can only be calculated if
            % PredictMethod is exact.
            import classreg.learning.modelparams.GPParams; 
            tf = strcmpi(this.PredictMethod,GPParams.PredictMethodExact);
            if ~tf
                error(message('stats:RegressionGP:RegressionGP:BadPredictMethodForPostFitStats',GPParams.PredictMethodExact));
            end
            
            % 2. Call utility function in GPImpl class.            
            [varargout{1:nargout}] = postFitStatisticsExact(this.Impl);
        
        end % end of postFitStatistics.
    
        function varargout = resubPredict(this,varargin)
        %RESUBPREDICT Resubstitution prediction from a fitted Gaussian process regression model.
        %   YPRED=RESUBPREDICT(GPR) returns predicted response YPRED for
        %   Gaussian process regression model GPR at the observations in
        %   the training data GPR.X. YPRED is a vector of type double with
        %   N elements where N is the number of rows in GPR.X.
        %
        %   [YPRED,YSD]=RESUBPREDICT(GPR) also returns a N-by-1 vector YSD
        %   such that YSD(i) is the estimated standard deviation of the new
        %   response at GPR.X(i,:) from a trained model.
        %
        %   [YPRED,YSD,YINT]=RESUBPREDICT(GPR) also returns a N-by-2 matrix
        %   YINT containing 95% prediction intervals for the true responses
        %   corresponding to each row of GPR.X. The lower limits of the
        %   bounds are in YINT(:,1), and the upper limits are in YINT(:,2).
        %
        %   [YPRED,YSD,YINT]=RESUBPREDICT(GPR,'PARAM1',val1,...) specifies
        %   optional parameter name/value pairs:
        %
        %       'Alpha'          A value between 0 and 1 to specify the 
        %                        confidence level as 100(1-ALPHA)%. Default
        %                        is 0.05 for 95% confidence.
        %
        %   NOTES:        
        %   o Computation of YSD and YINT is not supported for PredictMethod
        %   equal to 'BCD'.
        %
        %   Example: Fit a model to example data and plot resubstitution
        %   predictions along with prediction intervals.
        %       % 1. Some example data.
        %       rng(0,'twister');
        %       N = 1000;
        %       x = linspace(-10,10,N)';
        %       y = sin(3*x).*cos(3*x) + sin(2*x).*cos(2*x) + sin(x) + cos(x) + 0.2*randn(N,1);
        %
        %       % 2. Fit using 'Exact' and predict using 'Exact' with a
        %       % Matern52 kernel.
        %       gpr = fitrgp(x,y,'KernelFunction','Matern52','Optimizer','QuasiNewton',...
        %               'verbose',1,'FitMethod','Exact','PredictMethod','Exact');
        %
        %       % 3. Compute resubstitution predictions.
        %       [ypred,yse,yci] = resubPredict(gpr,'Alpha',0.05);
        %
        %       % 4. Plot original data along with predictions.
        %       plot(x,y,'r');
        %       hold on;
        %       plot(x,ypred,'b');
        %       plot(x,yci(:,1),'k--');
        %       plot(x,yci(:,2),'g--');
        %       xlabel('x');
        %       ylabel('y');
        %       legend('Data','GPR fit','Lower 95% CI','Upper 95% CI','Location','Best');                
        %
        %   See also fitrgp, RegressionGP/predict.
        
            [varargout{1:nargout}] = resubPredict@classreg.learning.regr.FullRegressionModel(this,varargin{:});
                
        end % end of resubPredict.
        
        function varargout = resubLoss(this,varargin)
        %RESUBLOSS Resubstitution loss for a fitted Gaussian process regression model.
        %   L=resubLoss(GPR) returns mean squared error for Gaussian process 
        %   regression model GPR computed for training data GPR.X and GPR.Y.
        %
        %   L=resubLoss(GPR,'PARAM1',val1,'PARAM2',val2,...) specifies
        %   optional parameter name/value pairs:
        %       'lossfun'          - Function handle for loss, or string
        %                            representing a built-in loss function.
        %                            Available loss functions for regression:
        %                            'mse'. If you pass a function handle FUN, RESUBLOSS
        %                            calls it as shown below:
        %                               FUN(GPR.Y,Yfit,W)
        %                            where GPR.Y, Yfit and W are numeric vectors of
        %                            length N. GPR.Y is observed response, Yfit is
        %                            predicted response for GPR.X, and W is observation
        %                            weights. Default: 'mse'
        %       'weights'          - Vector of observation weights. By default the
        %                            weight of every observation is set to 1. The
        %                            length of this vector must be equal to the
        %                            number of rows in GPR.X.
        %
        %   Example: Compute resubstitution loss on an example fit.        
        %       % 1. Some example data.
        %       N = 1000;
        %       x = linspace(-10,10,N)';
        %       y = sin(3*x)./x + 0.2*randn(N,1);
        %
        %       % 2. Fit the model using exact GPR.
        %       gpr = fitrgp(x,y,'KernelFunction','SquaredExponential',...
        %               'FitMethod','Exact','PredictMethod','Exact','Verbose',1,'Optimizer','QuasiNewton');
        %
        %       % 3. Plot the data and GPR fit.
        %       plot(x,y,'r');
        %       hold on;
        %       ypred = resubPredict(gpr);
        %       plot(x,ypred,'b');
        %       xlabel('x');
        %       ylabel('y');
        %       legend('Data','GPR fit');
        %
        %       % 4. Compute resubstitution loss.
        %       L = resubLoss(gpr)
        %
        %       % 5. Same as 4 but by hand.
        %       (y - ypred)'*(y - ypred)/N
        %
        %   See also RegressionGP/loss.
        
            [varargout{1:nargout}] = resubLoss@classreg.learning.regr.FullRegressionModel(this,varargin{:});
        
        end % end of resubLoss.
        
        function partModel = crossval(this,varargin)
        %CROSSVAL Cross-validate this model.
        %   CVMODEL=CROSSVAL(MODEL) builds a partitioned model CVMODEL from model
        %   MODEL represented by a full object for regression. You can then
        %   assess the predictive performance of this model on cross-validated data
        %   using methods and properties of CVMODEL. By default, CVMODEL is built
        %   using 10-fold cross-validation on the training data.
        %
        %   CVMODEL=CROSSVAL(MODEL,'PARAM1',val1,'PARAM2',val2,...) specifies
        %   optional parameter name/value pairs:
        %      'KFold'      - Number of folds for cross-validation, a numeric
        %                     positive scalar; 10 by default.
        %      'Holdout'    - Holdout validation uses the specified
        %                     fraction of the data for test, and uses the rest of
        %                     the data for training. Specify a numeric scalar
        %                     between 0 and 1.
        %      'Leaveout'   - If 'on', use leave-one-out cross-validation.
        %      'CVPartition' - An object of class CVPARTITION; empty by default. If
        %                      a CVPARTITION object is supplied, it is used for
        %                      splitting the data into subsets.
        %
        %   See also fitrgp, RegressionGP, cvpartition,
        %   classreg.learning.partition.RegressionPartitionedModel.
        
            % 1. If ActiveSet is supplied, crossval cannot be called.
            if this.Impl.IsActiveSetSupplied                
                error(message('stats:RegressionGP:RegressionGP:NoCrossValForKnownActiveSet'));
            end
            
            % 2. Set verbosity to 0 for cross validation.
            this.ModelParams.Verbose = 0;
            
            % 3. Call superclass method.
            partModel = crossval@classreg.learning.regr.FullRegressionModel(this,varargin{:});
            
        end % end of crossval.
    end
    
    methods(Access=protected)        
        function s = propsForDisp(this,s)
        %propsForDisp Return a structure containing properties for display.
        %   s = propsForDisp(this,s) takes an object this of class
        %   RegressionGP and a (possibly empty) structure s and returns a
        %   filled structure s containing the properties of RegressionGP
        %   that should be displayed by a call to disp. The disp method is
        %   inherited from Predictor and this method looks for things to
        %   display in the structure s.
        
            % 1. Call superclass methods first.
            s = propsForDisp@classreg.learning.regr.FullRegressionModel(this,s);
            s = propsForDisp@classreg.learning.regr.CompactRegressionGP(this,s);            
            
            % 2. Add properties of this class to display in s.
            s.FitMethod         = this.FitMethod;
            s.ActiveSetMethod   = this.ActiveSetMethod;
            s.IsActiveSetVector = this.IsActiveSetVector;
            s.LogLikelihood     = this.LogLikelihood;
            s.ActiveSetHistory  = this.ActiveSetHistory;
            s.BCDInformation    = this.BCDInformation;
            
        end % end of propsForDisp.        
    end
    
    methods(Static,Hidden)
        function [X,Y,W,dataSummary,responseTransform] = prepareData(X,Y,varargin)
        % This method is a placeholder for including additional data
        % preparation steps in addition to FullRegressionModel.prepareData.
            
            % 1. Call static method in FullRegressionModel.
            [X,Y,W,dataSummary,responseTransform] = classreg.learning.regr.FullRegressionModel.prepareData(X,Y,varargin{:});
            
            % 2. Ensure that X cannot be complex, sparse or an object.
            internal.stats.checkSupportedNumeric('X',X,true);
            
        end % end of prepareData.
    end
    
end

