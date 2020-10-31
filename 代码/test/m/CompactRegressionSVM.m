classdef CompactRegressionSVM < classreg.learning.regr.RegressionModel
%CompactRegressionSVM Support Vector Machine model for regression.
%   CompactRegressionSVM is an SVM model for regression. It can predict
%   response for new data. Unlike RegressionSVM models,
%   CompactRegressionSVM models do not store the training data.
%
%   CompactRegressionSVM properties:
%       PredictorNames        - Names of predictors used for this model.
%       ExpandedPredictorNames - Names of expanded predictors.
%       ResponseName          - Name of the response variable.
%       ResponseTransform     - Transformation applied to predicted response.
%       Alpha                 - Coefficients obtained by solving the dual problem.
%       Beta                  - Coefficients for the primal linear problem.
%       Bias                  - Bias term.
%       KernelParameters      - Kernel parameters.
%       Mu                    - Predictor means.
%       Sigma                 - Predictor standard deviations.
%       SupportVectors        - Support vectors.
%
%   CompactRegressionSVM methods:
%       discardSupportVectors - Discard support vectors for linear SVM.
%       loss                  - Regression loss.
%       predict               - Predicted response of this model.
%
%   See also RegressionSVM.

%   Copyright 2015-2017 The MathWorks, Inc.

    properties(GetAccess=public,SetAccess=protected,Dependent=true)
        %ALPHA Coefficients obtained by solving the dual problem.
        %   The Alpha property is a vector with M elements for M support
        %   vectors. The PREDICT method computes response for predictor
        %   matrix X using
        %
        %   F = G(X,SupportVectors)*Alpha + Bias
        %
        %   where G(X,SupportVectors) is an N-by-M matrix of kernel products for N
        %   rows in X and M rows in SupportVectors.
        %
        %   See also classreg.learning.regr.CompactRegressionSVM,
        %   Bias, SupportVectors, predict.
        Alpha;
        
        %BETA Coefficients for the primal linear problem.
        %   The Beta property is a vector of linear coefficients with P elements
        %   for P predictors. If this SVM model is obtained using a kernel function
        %   other than 'linear', this property is empty. Otherwise response
        %   obtained by this model for predictor matrix X can be computed using
        %
        %   Yfit = (X/S)*Beta + Bias
        %
        %   where S is the kernel scale saved in the KernelParameters.Scale property.
        %
        %   When there are categorical predictors, the matrix X in this expression
        %   includes dummy variables for those predictors, and the Beta vector is
        %   expanded accordingly.
        %
        %   See also classreg.learning.regr.CompactRegressionSVM, Alpha,
        %   Bias, SupportVectors, predict.
        Beta;
        
        %BIAS Bias term.
        %   The Bias property is a scalar specifying the bias term in the SVM
        %   model. The PREDICT method computes responses F for predictor matrix X
        %   using
        %
        %   F = G(X,SupportVectors)*Alpha + Bias
        %
        %   where G(X,SupportVectors) is an N-by-M matrix of kernel products for N
        %   rows in X and M rows in SupportVectors.
        %
        %   See also classreg.learning.regr.CompactRegressionSVM, Alpha,
        %   Bias, SupportVectors, predict.
        Bias;
        
        %KERNELPARAMETERS Parameters of the kernel function.
        %   The KernelParameters is a struct with two fields:
        %       Function     - Name of the kernel function, a string.
        %       Scale        - Scale factor used to divide predictor values.
        %   The PREDICT method computes a kernel product between vectors x and z
        %   using Function(x/Scale,z/Scale).
        %
        %   See also classreg.learning.regr.CompactRegressionSVM, predict.
        KernelParameters;
        
        %MU Predictor means.
        %   The Mu property is either empty or a vector with P elements, one for
        %   each predictor. If training data were standardized, the Mu property is
        %   filled with means of predictors used for training. Otherwise the Mu
        %   property is empty. If the Mu property is not empty, the PREDICT method
        %   centers predictor matrix X by subtracting the respective element of Mu
        %   from every column.
        %
        %   When there are categorical predictors, Mu includes elements for the
        %   dummy variables for those predictors. The corresponding entries in Mu
        %   are 0, because dummy variables are not centered or scaled.
        %
        %   See also classreg.learning.regr.CompactRegressionSVM, predict.
        Mu;
        
        %SIGMA Predictor standard deviations.
        %   The Sigma property is either empty or a vector with P elements, one for
        %   each predictor. If training data were standardized, the Sigma property
        %   is filled with standard deviations of predictors used for training.
        %   Otherwise the Sigma property is empty. If the Sigma property is not
        %   empty, the PREDICT method scales predictor matrix X by dividing every
        %   column by the respective element of Sigma (after centering).
        %
        %   When there are categorical predictors, Sigma includes elements for the
        %   dummy variables for those predictors. The corresponding entries in Sigma
        %   are 1, because dummy variables are not centered or scaled.
        %
        %   See also classreg.learning.regr.CompactRegressionSVM, predict.
        Sigma;
        
        %SUPPORTVECTORS Support vectors.
        %   The SupportVectors property is an M-by-P matrix for M support vectors
        %   and P predictors. The PREDICT method computes scores F for predictor
        %   matrix X using
        %
        %   F = G(X,SupportVectors)*Alpha + Bias
        %
        %   where G(X,SupportVectors) is an N-by-M matrix of kernel products for N
        %   rows in X and M rows in SupportVectors.
        %
        %   When there are categorical predictors, SupportVectors includes dummy
        %   variables for those predictors.
        %
        %   See also classreg.learning.regr.CompactRegressionSVM,
        %   Alpha, Bias, predict.
        SupportVectors;
    end
     
    methods
         function a = get.Alpha(this)
            a = this.Impl.Alpha;
        end
        
        function a = get.Bias(this)
            a = this.Impl.Bias;
        end
        
        function b = get.Beta(this)
            b = this.Impl.Beta;
        end
        
        function p = get.KernelParameters(this)
            p.Function = this.Impl.KernelParameters.Function;
            p.Scale    = this.Impl.KernelParameters.Scale;
            % Offset has been incorporated in the Bias already.
            % For the user, offset for prediction is zero.
            
            if strcmpi(p.Function,'polynomial')
                p.Order = this.Impl.KernelParameters.PolyOrder;
            elseif strcmpi(p.Function,'sigmoid')
                p.Sigmoid = this.Impl.KernelParameters.Sigmoid;
            end
        end
        
        function a = get.Mu(this)
            a = this.Impl.Mu;
        end
        
        function a = get.Sigma(this)
            a = this.Impl.Sigma;
        end
        
        function a = get.SupportVectors(this)
            a = this.Impl.SupportVectors;
        end
        
        function this = discardSupportVectors(this)
        %DISCARDSUPPORTVECTORS Discard support vectors for linear SVM.
        %   OBJ=DISCARDSUPPORTVECTORS(OBJ) empties the Alpha and
        %   SupportVectors properties of a linear SVM model. After these
        %   properties are emptied, the PREDICT method can compute SVM
        %   responses using the Beta coefficients.
        %   DISCARDSUPPORTVECTORS errors for a non-linear SVM model.
        %
        %   See also Alpha, Beta, SupportVectors, predict.
        
            this.Impl = discardSupportVectors(this.Impl);
        end
       
        function l = loss(this,X,varargin)
        %LOSS Regression error.
        %   L=LOSS(MODEL,X,Y) returns mean squared error (MSE) for SVM model MODEL
        %   computed using predictors X and observed response Y. X must be a table
        %   if MODEL was originally trained on a table, or a numeric matrix if
        %   MODEL was originally trained on a matrix.  If X is a table, it must
        %   contain all the predictors used for training this model. If X is a
        %   matrix, it must have size N-by-P, where P is the number of predictors
        %   used for training this model. Y must be a vector of floating-point
        %   numbers with N elements, where N is the number of rows in X. Y can be
        %   omitted if it appears in the table X.
        %
        %   L=LOSS(MODEL,X,Y,'PARAM1',val1,'PARAM2',val2,...) specifies
        %   optional parameter name/value pairs:
        %       'LossFun'          - Function handle for loss, or string
        %                            representing a built-in loss function.
        %                            Available loss functions for SVM regression:
        %                            'mse', and 'epsiloninsensitive'. If you pass a
        %                            function handle FUN, LOSS calls it as shown
        %                            below:
        %                               FUN(Y,Yfit,W)
        %                            where Y, Yfit and W are numeric vectors of
        %                            length N. Y is observed response, Yfit is
        %                            predicted response, and W is observation
        %                            weights. Default: 'mse'
        %       'Weights'         -  Vector of observation weights. By default the
        %                            weight of every observation is set to 1. The
        %                            length of this vector must be equal to the
        %                            number of rows in X. If X is a table, this
        %                            may be the name of a variable in the table.
        %
        %   See also classreg.learning.regr.RegressionModel,
        %   classreg.learning.regr.RegressionModel/predict.
            [varargin{:}] = convertStringsToChars(varargin{:});
            % Handle input data such as "tall" requiring a special adapter
            adapter = classreg.learning.internal.makeClassificationModelAdapter(this,X,varargin{:});
            if ~isempty(adapter)            
                l = loss(adapter,X,varargin{:});
                return
            end
        
            [Y,varargin] = classreg.learning.internal.inferResponse(this.ResponseName,X,varargin{:});

            % Get observation weights
            N = size(X,1);
            args = {                  'lossfun'  'weights'};
            defs = {@classreg.learning.loss.mse  ones(N,1)};
            [funloss,W,~,extraArgs] = ...
                internal.stats.parseArgs(args,defs,varargin{:});
            
            % Prepare data
            [X,Y,W] = prepareDataForLoss(this,X,Y,W,this.VariableRange,false);

            % Loss function
            if strncmpi(funloss,'epsiloninsensitive',length(funloss))
                    f2 = @classreg.learning.loss.epsiloninsensitive;
                    funloss = @(Y,Yfit,W)(f2(Y,Yfit,W,this.Impl.Epsilon));
            end
            funloss = classreg.learning.internal.lossCheck(funloss,'regression');
            
            % Get predictions
            Yfit = predict(this,X,extraArgs{:});
            
            % Check
            classreg.learning.internal.regrCheck(Y,Yfit,W);

            % Get loss
            l = funloss(Y,Yfit,W);
           
        end
    end

    methods(Static,Hidden)
        function obj = fromStruct(s)
            % Make an SVM object from a codegen struct.
            
            s.ResponseTransform = s.ResponseTransformFull;
            
            s = classreg.learning.coderutils.structToRegr(s);
            
            % implementation
            impl = classreg.learning.impl.CompactSVMImpl.fromStruct(s.Impl);
            
            % Make an object
            obj = classreg.learning.regr.CompactRegressionSVM(...
                s.DataSummary,s.ResponseTransform,impl);
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
            
            
            % save the path to the fromStruct method
            s.FromStructFcn = 'classreg.learning.regr.CompactRegressionSVM.fromStruct';
            
            % impl
            impl = this.Impl;
            if isa(impl,'classreg.learning.impl.SVMImpl')
                impl = compact(impl,true);
            end
            s.Impl = struct(impl);
        end
    end
    
    methods(Access=protected)
        function this = CompactRegressionSVM(dataSummary,responseTransform, impl)
            this = this@classreg.learning.regr.RegressionModel(dataSummary,responseTransform);
            this.Impl = impl;
            this.CategoricalVariableCoding = 'dummy';
        end
        
        function n = getExpandedPredictorNames(this)
            n = classreg.learning.internal.expandPredictorNames(this.PredictorNames,this.VariableRange);
        end
            
        function s = propsForDisp(this,s)
            s = propsForDisp@classreg.learning.regr.RegressionModel(this,s);
            hasAlpha = ~isempty(this.Alpha);
            if ~hasAlpha
                s.Beta                = this.Beta;
            else
                s.Alpha               = this.Alpha;
            end
            
            s.Bias                    = this.Bias;
            s.KernelParameters        = this.KernelParameters;
            if ~isempty(this.Mu)
                s.Mu                  = this.Mu;
            end
            if ~isempty(this.Sigma)
                s.Sigma               = this.Sigma;
            end
            if hasAlpha
                s.SupportVectors      = this.SupportVectors;
            end
          
        end
        
        function r = response(this,X,varargin)
                   %Call CompactSVMImpl.score method
                   r = score(this.Impl,X,false,varargin{:}); 
        end
    end
    
    methods(Hidden, Static)
        function name = matlabCodegenRedirect(~)
            name = 'classreg.learning.coder.regr.CompactRegressionSVM';
        end
    end
    
    
end


