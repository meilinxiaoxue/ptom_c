classdef RegressionSVM < ...
        classreg.learning.regr.FullRegressionModel & classreg.learning.regr.CompactRegressionSVM
%RegressionSVM Support Vector Machine model for regression.
%   RegressionSVM is a SVM model for regression. This model can predict
%   response for new data. This model also stores data used for training
%   and can compute resubstitution predictions.
%
%   An object of this class cannot be created by calling the constructor.
%   Use FITRSVM to create a RegressionSVM object by fitting an SVM model
%   to training data.
%
%   This class is derived from CompactRegressionSVM.
%
%   RegressionSVM properties:
%       NumObservations       - Number of observations.
%       X                     - Matrix of predictors used to train this model.
%       Y                     - Observed response used to train this model.
%       W                     - Weights of observations used to train this model.
%       ModelParameters       - SVM parameters.
%       PredictorNames        - Names of predictors used for this model.
%       ExpandedPredictorNames - Names of expanded predictors.
%       ResponseName          - Name of the response variable.
%       ResponseTransform     - Transformation applied to predicted regression response.
%       Alpha                 - Coefficients obtained by solving the dual problem.
%       Beta                  - Coefficients for the primal linear problem.
%       Bias                  - Bias term.
%       KernelParameters      - Kernel parameters.
%       Mu                    - Predictor means.
%       Sigma                 - Predictor standard deviations.
%       SupportVectors        - Support vectors.
%       BoxConstraints        - Box constraints.
%       Epsilon               - Half of the width of the epsilon-insensitive band.
%       CacheInfo             - Cache information.
%       ConvergenceInfo       - Convergence information.
%       Gradient              - Gradient values in the training data.
%       IsSupportVector       - Indices of support vectors in the training data.
%       NumIterations         - Number of iterations taken by optimization.
%       OutlierFraction       - Expected fraction of outliers in the training data.
%       ShrinkagePeriod       - Number of iterations between reductions of the active set.
%       Solver                - Name of the used solver.
%       RowsUsed              - Logical index for rows used in fit. 
%
%   RegressionSVM methods:
%       compact               - Compact this model.
%       crossval              - Cross-validate this model.
%       discardSupportVectors - Discard support vectors for linear SVM.
%       loss                  - Regression loss.
%       predict               - Predicted response of this model.
%       resubLoss             - Resubstitution regression loss.
%       resubPredict          - Resubstitution predicted response.
%       resume                - Resume training.
%
%   Example: Train an SVM regression model
%       load hald
%       svr = fitrsvm(ingredients,heat,'epsilon',0.1,'Standardize',true);
%
%   See also fitrsvm, classreg.learning.regr.CompactRegressionSVM.
    
%   Copyright 2015-2017 The MathWorks, Inc.

     properties(SetAccess=protected,GetAccess=public,Dependent=true)
        %BOXCONSTRAINTS Box constraints.
        %   The BoxConstraints property is a vector with NumObservations
        %   elements. The absolute value of the dual coefficient alpha for
        %   observation I cannot exceed BoxConstraints(I).
        %
        %   See also fitrsvm, RegressionSVM, Alpha, NumObservations.
        BoxConstraints;
        
        %CACHEINFO Cache information.
        %   The CacheInfo property is a struct with 2 fields:
        %       Size      - Size of memory used for caching entries of the
        %                   Gram matrix in megabytes.
        %       Algorithm - Name of the algorithm used for removing entries
        %                   from the cache when its capacity is exceeded.
        %
        %   See also fitrsvm, RegressionSVM.
        CacheInfo;
        
        %CONVERGENCEINFO Convergence information.
        %   The ConvergenceInfo property is a struct with 10 fields:
        %       Converged                - true if optimization converged
        %                                  to the desired tolerance and
        %                                  false otherwise.
        %       ReasonForConvergence     - Name of the criterion used to
        %                                  detect convergence.
        %       Gap                      - Value of the attained  
        %                                  feasibility gap between the dual
        %                                  and primal objectives.
        %       GapTolerance             - Tolerance for the feasibility
        %                                  gap.
        %       DeltaGradient            - Value of the attained gradient
        %                                  difference between upper and
        %                                  lower violators.
        %       DeltaGradientTolerance   - Tolerance for gradient
        %                                  difference between upper and
        %                                  lower violators.
        %       LargestKKTViolation      - Value of the attained largest
        %                                  (by magnitude) Karush-Kuhn-Tucker
        %                                  (KKT) violation.
        %       KKTTolerance             - Tolerance for largest KKT
        %                                  violation.
        %       History                  - Struct with 6 fields:
        %           NumIterations            * Array of iteration indices
        %                                      at which convergence
        %                                      criteria were recorded.
        %           Gap                      * Gap values at these iterations.
        %           DeltaGradient            * DeltaGradient values at these
        %                                      iterations.
        %           LargestKKTViolation      * LargestKKTViolation values
        %                                      at these iterations.
        %           NumSupportVectors        * Numbers of support vectors
        %                                      at these iterations.
        %           Objective                * Objective values at these
        %                                      iterations.
        %       Objective                - Value of the dual objective.
        %
        %   See also fitrsvm, RegressionSVM.
        ConvergenceInfo;
        
        %EPSILON Half of the width of the epsilon-insensitive band.
        %   The Epsilon property is a scalar specifying half the width of
        %   the epsilon-insensitive band.
        %
        %   See also fitrsvm, RegressionSVM, NumObservations.
        Epsilon;
        
        %GRADIENT Gradient values in the training data.
        %   The Gradient property is a vector with 2*NumObservations
        %   elements. Element I of this vector is the value of the gradient
        %   for Alpha_up at observation I at the end of the optimization.
        %   Element I+NumObservations of this vector is the value of the
        %   gradient for Alpha_low at observation I at the end of the
        %   optimization, where Alpha_up is the Alpha coefficient
        %   corresponding to the upper boundary of the band, and Alpha_low
        %   is the Alpha coefficient corresponding to the lower boundary of
        %   the band.
        %
        %   See also fitrsvm, RegressionSVM, NumObservations.
        Gradient;
        
        %ISSUPPORTVECTOR Indices of support vectors in the training data.
        %   The IsSupportVector property is a logical vector with
        %   NumObservations elements. IsSupportVector(I) is true if
        %   observation I is a support vector and false otherwise.
        %
        %   See also fitrsvm, RegressionSVM, NumObservations.
        IsSupportVector;
        
       
        %NUMITERATIONS Number of iterations taken by optimization.
        %   The NumIterations property is an integer showing how many
        %   iterations were performed by optimization.
        %
        %   See also fitrsvm, RegressionSVM.
        NumIterations;
        
        %OUTLIERFRACTION Expected fraction of outliers in the training data.
        %   The OutlierFraction property is a numeric scalar between 0 and 1
        %   specifying the expected fraction of outliers in the training data.
        %
        %   See also fitrsvm, RegressionSVM.
        OutlierFraction;
        
        %SHRINKAGEPERIOD Number of iterations between reductions of the active set.
        %   The ShrinkagePeriod property is a non-negative integer
        %   specifying how often the active set was shrunk during
        %   optimization.
        %
        %   See also fitrsvm, RegressionSVM.
        ShrinkagePeriod;
        
        %SOLVER Name of the used solver.
        %   The Solver property is a string specifying the algorithm used
        %   to solve the SVM problem.
        %
        %   See also fitrsvm, RegressionSVM.
        Solver;
     end
    
       methods
        function a = get.BoxConstraints(this)
            a = this.Impl.C;
        end
        
        
        function a = get.CacheInfo(this)
            a = this.Impl.CacheInfo;
        end
        
        function a = get.ConvergenceInfo(this)
            a = this.Impl.ConvergenceInfo;
            if isfield(a,'OutlierHistory')
                a = rmfield(a,'OutlierHistory');
            end
            if isfield(a,'ChangeSetHistory')
                a = rmfield(a,'ChangeSetHistory');
            end
        end
        
        function a = get.OutlierFraction(this)
            a = this.Impl.FractionToExclude;
        end
        
        function a = get.Epsilon(this)
            a = this.ModelParams.Epsilon;
        end
        function a = get.Gradient(this)
            a = this.Impl.Gradient;
        end
        
        function a = get.Solver(this)
            a = this.ModelParams.Solver;
        end
        
                
        function a = get.NumIterations(this)
            a = this.Impl.NumIterations;
        end
                
        function a = get.IsSupportVector(this)
            a = this.Impl.IsSupportVector;
        end
        
        function a = get.ShrinkagePeriod(this)
            a = this.Impl.Shrinkage.Period;
        end
       end
    
    methods(Hidden)
        function this = RegressionSVM(X,Y,W,modelParams,dataSummary,responseTransform)
            if nargin~=6 || ischar(W)
                 error(message('stats:RegressionSVM:RegressionSVM:DoNotUseConstructor'));
            end
            
            %Check whether X is sparse or complex here instead of in
            %FullRegressionModel/prepareData, because the base class may be
            %extended to support sparse matrix in the future.
            internal.stats.checkSupportedNumeric('X',X,true);
            this = this@classreg.learning.regr.FullRegressionModel(...
                X,Y,W,modelParams,dataSummary,responseTransform);
            this = this@classreg.learning.regr.CompactRegressionSVM(...
                dataSummary,responseTransform,[]);
            
            % Remove all rows with NaNs.  Removing rows with NaNs needs to
            % be done here instead of prepareData, to avoid mismatch when
            % one calls crossval with a CVPartition object.
            nanX = any(isnan(this.PrivX),2);
            if any(nanX)
                this.PrivX(nanX,:)   = [];
                this.PrivY(nanX) = [];
                this.W(nanX)     = [];
                rowsused = this.DataSummary.RowsUsed;
                if isempty(rowsused)
                    rowsused = ~nanX;
                else
                    rowsused(rowsused) = ~nanX;
                end
                this.DataSummary.RowsUsed = rowsused;
            end
            if isempty(this.PrivX)
                error(message('stats:ClassificationSVM:ClassificationSVM:NoDataAfterNaNsRemoved'));
            end
            
            % Check for alphas. The size of alphas matches the size of X. This
            % is ensured by SVMParams.
            if ~isempty(this.ModelParams.Alpha)
                this.ModelParams.Alpha(nanX) = [];
            end
            if any(nanX)
                % Renormalize weights
                this.W = this.W/sum(this.W);
            end
            
            s=[];
            %Set Epsilon value if it's not provided 
            %Setting Epsilon needs to be done here instead of SVMPARAMS. In
            %the case of cross-validation, different training sets set
            %Epsilon based on it's own response.
            if isempty( this.ModelParams.Epsilon)
                s = iqr(this.PrivY)/1.349;
                if s == 0
                    s = 1;
                end
                this.ModelParams.Epsilon = s/10;
            end
            
            %Set box constraint value for Gaussian kernel if it's not
            %provided. Setting box constraint for Gaussian kernel
            %needs to be done here instead of SVMPARAMS. In the
            %case of cross-validation, different training sets set this
            %value based on it's own response.
            if isempty (this.ModelParams.BoxConstraint) &&...
                strcmpi(this.ModelParams.KernelFunction, 'gaussian')
                   if isempty(s)
                     s = iqr(this.PrivY)/1.349;
                     if s == 0
                        s = 1;
                     end
                   end
                   this.ModelParams.BoxConstraint = s;
                   
                   if ~isempty(this.ModelParams.Alpha) 
                       if any(abs(this.ModelParams.Alpha) > this.ModelParams.BoxConstraint)
                            maxAlpha = max(abs(this.ModelParams.Alpha));
                            this.ModelParams.Alpha =...
                                this.ModelParams.Alpha*this.ModelParams.BoxConstraint/maxAlpha;
                        end
                   end
            end
            
            doclass = 0; %regression
            
            this.Impl = classreg.learning.impl.SVMImpl.make(...
                this.PrivX,this.PrivY,this.W,...
                this.ModelParams.Alpha,this.ModelParams.ClipAlphas,...
                this.ModelParams.KernelFunction,...
                this.ModelParams.KernelPolynomialOrder,[],...
                this.ModelParams.KernelScale,this.ModelParams.KernelOffset,...
                this.ModelParams.StandardizeData,...
                doclass,...
                this.ModelParams.Solver,...
                this.ModelParams.BoxConstraint,...
                this.ModelParams.Nu,...
                this.ModelParams.IterationLimit,...
                this.ModelParams.KKTTolerance,...
                this.ModelParams.GapTolerance,...
                this.ModelParams.DeltaGradientTolerance,...
                this.ModelParams.CacheSize,...
                this.ModelParams.CachingMethod,...
                this.ModelParams.ShrinkagePeriod,...
                this.ModelParams.OutlierFraction,...
                this.ModelParams.VerbosityLevel,...
                this.ModelParams.NumPrint,...
                this.ModelParams.Epsilon,...
                this.CategoricalPredictors,...
                this.VariableRange,...
                this.ModelParams.RemoveDuplicates);
        end
    end

    methods(Static,Hidden)
        function this = fit(X,Y,varargin)
            temp = RegressionSVM.template(varargin{:});
            this = fit(temp,X,Y);
        end
        
        function temp = template(varargin)
            classreg.learning.FitTemplate.catchType(varargin{:});
            temp = classreg.learning.FitTemplate.make('SVM','type','regression',varargin{:});
        end
    end

    methods(Access=protected)
       
        function s = propsForDisp(this,s)
            s = propsForDisp@classreg.learning.regr.CompactRegressionSVM(this,s);
            s = propsForDisp@classreg.learning.regr.FullRegressionModel(this,s);
            if isfield(s,'SupportVectors')
                s = rmfield(s,'SupportVectors');
            end     
            s.BoxConstraints               = this.BoxConstraints;
            s.ConvergenceInfo              = this.ConvergenceInfo;
            s.IsSupportVector              = this.IsSupportVector;
            s.Solver                       = this.Solver;
        end
    end
       
    methods
        function cmp = compact(this,varargin)
        %COMPACT Compact SVM model.
        %   CMP=COMPACT(MODEL) returns an object of class
        %   CompactRegressionSVM that holds the trained SVM regression
        %   model. The compact object does not contain X and Y used for
        %   training.
        %
        %   See also RegressionSVM,
        %   classreg.learning.regr.CompactRegressionSVM.
        
            dataSummary = this.DataSummary;
            dataSummary.RowsUsed = [];
            cmp = classreg.learning.regr.CompactRegressionSVM(...
                dataSummary,this.PrivResponseTransform,...;
            compact(this.Impl,this.ModelParams.SaveSupportVectors));
        end
 
            
        function [varargout] = resubPredict(this,varargin)
        %RESUBPREDICT Predict resubstitution response of the FITRSVM.
        %   YFIT=RESUBPREDICT(MDL) returns predicted response YFIT for SVM
        %   regression model MDL and training data MDL.X. YFIT is a vector
        %   of type double with NumObservations elements.
        %
        %   See also fitrsvm, RegressionSVM, predict.
            
            [varargout{1:nargout}] = ...
                resubPredict@classreg.learning.regr.FullRegressionModel(this,varargin{:});
       end
        
        function [varargout] = resubLoss(this,varargin)
        %RESUBLOSS Regression error by resubstitution.
        %   L=RESUBLOSS(MDL) returns the mean squared error for SVM
        %   regression model MDL, computed using the training data MDL.X
        %   and MDL.Y.
        %
        %   L=RESUBLOSS(FITRSVM,'PARAM1',val1,'PARAM2',val2,...) specifies
        %   optional parameter name/value pairs:
        %       'LossFun'          - Function handle for loss function, or
        %                            string representing a built-in loss
        %                            function. Available loss functions for
        %                            SVM regression: 'mse', and
        %                            'epsiloninsensitive'. If you pass a
        %                            function handle FUN, LOSS calls it as
        %                            shown below:
        %                               FUN(Y,Yfit,W)
        %                            where Y, Yfit and W are numeric
        %                            vectors of length N. Y is observed
        %                            response, Yfit is predicted response,
        %                            and W is observation weights. Default:
        %                            'mse'
        %       'Weights'          - Vector of observation weights. By
        %                            default the weight of every
        %                            observation is set to 1. The length of
        %                            this vector must be equal to the
        %                            number of rows in X.
        %
        %   See also RegressionSVM, loss.
        
            [varargout{1:nargout}] = ...
                resubLoss@classreg.learning.regr.FullRegressionModel(this,varargin{:});
        end
        
        function this = resume(this,numIter,varargin)
        %RESUME Resume training this SVM model.
        %   MODEL=RESUME(MDL,NUMITER) trains the SVM regression model MDL
        %   for an additional number of iterations as specified by NUMITER,
        %   and returns an updated model. You can resume training an
        %   SVM model if optimization has not converged and if 'Solver' is
        %   set to 'SMO' or 'ISDA'.
        %
        %   MODEL=RESUME(MDL,NUMITER,'PARAM1',val1,'PARAM2',val2,...)
        %   specifies optional parameter name/value pairs:
        %       'Verbose'       - Verbosity level, one of: 0, 1, or 2.
        %                         Default: Value passed to FITRSVM.
        %       'NumPrint'      - Number of iterations between consecutive
        %                         diagnostic print-outs, specified as a
        %                         non-negative integer. RESUME uses this
        %                         parameter only if you pass 1 for the
        %                         'Verbose'
        %                         parameter. Default: Value passed to
        %                         FITRSVM.
        %
        %   See also fitrsvm, RegressionSVM, Solver.
            [varargin{:}] = convertStringsToChars(varargin{:});
            % Decode input args
            args = {                      'verbose'                'numprint'};
            defs = {this.ModelParams.VerbosityLevel this.ModelParams.NumPrint};
            [verbose,nprint,~] = ...
                internal.stats.parseArgs(args,defs,varargin{:});
            
            if ~isnumeric(numIter) || ~isscalar(numIter) ...
                    || isnan(numIter) || isinf(numIter) || numIter<=0
                error(message('stats:ClassificationSVM:resume:BadNumIter'));
            else
                numIter = ceil(numIter);
            end
            this.ModelParams.IterationLimit = ...
                this.ModelParams.IterationLimit + numIter;
            
            if verbose<=0
                nprint = 0;
            end
            
            doclass = 0;
            %calls the resume method of SVMImpl
            this.Impl = resume(this.Impl,this.PrivX,this.PrivY,numIter,doclass,verbose,nprint);
         end
         
        function partModel = crossval(this,varargin)
        %CROSSVAL Cross-validate this model.
        %   CVMODEL=CROSSVAL(MDL) builds a partitioned model CVMODEL from
        %   model MDL represented by a full object for regression. You can
        %   then assess the predictive performance of this model on
        %   cross-validated data using methods and properties of CVMODEL.
        %   By default, CVMODEL is built using 10-fold cross-validation on
        %   the training data. CVMODEL is of class
        %   RegressionPartitionedModel.
        %
        %   CVMODEL=CROSSVAL(MODEL,'PARAM1',val1,'PARAM2',val2,...)
        %   specifies optional parameter name/value pairs:
        %      'KFold'       - Number of folds for cross-validation, a
        %                      numeric positive scalar; 10 by default.
        %      'Holdout'     - Holdout validation uses the specified
        %                      fraction of the data for test, and uses the
        %                      rest of the data for training. Specify a
        %                      numeric scalar between 0 and 1.
        %      'Leaveout'    - If 'on', use leave-one-out cross-validation.
        %      'CVPartition' - An object of class CVPARTITION; empty by
        %                      default. If a CVPARTITION object is
        %                      supplied, it is used for splitting the data
        %                      into subsets.
        %
        %   See also fitrsvm, RegressionSVM, cvpartition,
        %   classreg.learning.partition.RegressionPartitionedSVM.
            [varargin{:}] = convertStringsToChars(varargin{:});
            idxBaseArg = find(ismember(varargin(1:2:end),...
                classreg.learning.FitTemplate.AllowedBaseFitObjectArgs));
            if ~isempty(idxBaseArg)
                error(message('stats:classreg:learning:regr:FullRegressionModel:crossval:NoBaseArgs', varargin{ 2*idxBaseArg - 1 }));
            end
            %override crossval so that VerbosityLevel is always zero when
            %performing crossval
            modelParams = this.ModelParams;
            modelParams.VerbosityLevel = 0;
            temp = classreg.learning.FitTemplate.make(this.ModelParams.Method,...
                'type','regression','responsetransform',this.PrivResponseTransform,...
                'modelparams',modelParams,'CrossVal','on',varargin{:});
            partModel = fit(temp,this.X,this.Y,'Weights',this.W,...
                'predictornames',this.PredictorNames,'categoricalpredictors',this.CategoricalPredictors,...
                'responsename',this.ResponseName);
         end    
    
   
    end
    
     methods(Static,Hidden)
        function [X,Y,W,dataSummary,responseTransform] = prepareData(X,Y,varargin)
            [X,Y,vrange,wastable,varargin] = classreg.learning.internal.table2FitMatrix(X,Y,varargin{:});

            % Process input args
            args = {'responsetransform'};
            defs = {                 []};
            [transformer,~,crArgs] = ...
                internal.stats.parseArgs(args,defs,varargin{:},'VariableRange',vrange,'TableInput',wastable);
            
            % Pre-process
            if ~isfloat(X)
                error(message('stats:classreg:learning:regr:FullRegressionModel:prepareData:BadXType'));
            end
            internal.stats.checkSupportedNumeric('X',X,true);
            
            [X,Y,W,dataSummary] = ...
                classreg.learning.FullClassificationRegressionModel.prepareDataCR(X,Y,crArgs{:});
            if ~dataSummary.TableInput
                X = classreg.learning.internal.encodeCategorical(X,dataSummary.VariableRange);
            end

            % Check Y type
            if ~isfloat(Y) || ~isvector(Y)
                error(message('stats:classreg:learning:regr:FullRegressionModel:prepareData:BadYType'));
            end
            internal.stats.checkSupportedNumeric('Y',Y,true);
            Y = Y(:);
            
            [X,Y,W,dataSummary.RowsUsed] = classreg.learning.regr.FullRegressionModel.removeNaNs(X,Y,W,dataSummary.RowsUsed);
            % Renormalize weights
            W = W/sum(W);

            % Make output response transformation
            responseTransform = ...
                classreg.learning.regr.FullRegressionModel.processResponseTransform(transformer);
            
         end
    end
end
