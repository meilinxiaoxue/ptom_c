classdef CompactRegressionGP < classreg.learning.regr.RegressionModel
%CompactRegressionGP Gaussian Process Regression (GPR) model.
%   CompactRegressionGP is a Gaussian process model for regression. This
%   model can predict response given new data.
%
%   CompactRegressionGP properties:
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
%
%   CompactRegressionGP methods:
%       loss                  - Regression loss.
%       predict               - Predicted response of this GPR model.
%
%   See also RegressionGP.

%   Copyright 2014-2017 The MathWorks, Inc.

    properties(SetAccess=protected,GetAccess=public,Dependent=true)
        %KERNELFUNCTION - Kernel function used in this model.
        %   KERNELFUNCTION is a string or a function handle specifying form
        %   of the covariance function of the Gaussian process as described
        %   below:
        %
        %       'SquaredExponential'    - Squared exponential kernel.
        %       'Exponential'           - Exponential kernel.
        %       'Matern32'              - Matern kernel with parameter 3/2.
        %       'Matern52'              - Matern kernel with parameter 5/2.
        %       'RationalQuadratic'     - Rational quadratic kernel.
        %       'ARDSquaredExponential' - Squared exponential kernel with a
        %                                 separate length scale per
        %                                 predictor.
        %       'ARDExponential         - Exponential kernel with a
        %                                 separate length scale per
        %                                 predictor.
        %       'ARDMatern32'           - Matern kernel with parameter 3/2 
        %                                 and a separate length scale per
        %                                 predictor.
        %       'ARDMatern52'           - Matern kernel with parameter 5/2 
        %                                 and a separate length scale per
        %                                 predictor.
        %       'ARDRationalQuadratic'  - Rational quadratic kernel with a
        %                                 separate length scale per
        %                                 predictor.
        %      	KFCN                    - A function handle that can be
        %                                 called like this:
        %  
        %                                   KMN = KFCN(XM,XN,THETA)
        %  
        %                                 XM is a M-by-D matrix, XN is a
        %                                 N-by-D matrix and KMN is a M-by-N
        %                                 matrix of kernel products such
        %                                 that KMN(i,j) is the kernel
        %                                 product between XM(i,:) and
        %                                 XN(j,:). THETA is the R-by-1
        %                                 unconstrained parameter vector
        %                                 for KFCN.
        %
        %   For built-in kernel functions, KERNELFUNCTION is a string,
        %   otherwise it is a function handle.
        %
        %   See also KERNELINFORMATION.
        KernelFunction;
        
        %KERNELINFORMATION - Information about parameters of this kernel function.
        %   KERNELINFORMATION is a structure with the following fields:
        %   
        %       FIELD NAME             MEANING
        %       Name                 - Name of the kernel function.
        %       KernelParameters     - Vector of estimated kernel parameters.
        %       KernelParameterNames - Names associated with elements of 
        %                              KernelParameters.
        %
        %   See also KERNELFUNCTION.
        KernelInformation;
        
        %BASISFUNCTION - Explicit basis function used in this model.
        %   BASISFUNCTION is a string or a function handle specifying form
        %   of the explicit basis in the Gaussian process model. If N is
        %   the number of observations, an explicit basis function adds the
        %   term H*BETA to the model where H is a N-by-P basis matrix and
        %   BETA is a P-by-1 vector of basis coefficients. BASISFUNCTION
        %   can be one of the following:
        % 
        %       'None'          - H = zeros(N,0).
        %       'Constant'      - H = ones(N,1).
        %       'Linear'        - H = [ones(N,1),X].
        %       'PureQuadratic' - H = [ones(N,1),X,X.^2].
        %       HFCN            - A function handle that can be called like 
        %                         this:
        % 
        %                           H = HFCN(X)  where
        % 
        %                         X is a N-by-D matrix of predictors and H 
        %                         is a N-by-P matrix of basis functions.
        %
        %   If there are categorical predictors, then X in the above expressions
        %   includes dummy variables for those predictors and D is the number of
        %   predictor columns including the dummy variables.
        %
        %   For built-in basis functions, BASISFUNCTION is a string,
        %   otherwise it is a function handle.
        %
        %   See also BETA.
        BasisFunction;
        
        %BETA - Coefficient vector for the explicit basis.
        %   BETA is a vector of estimated coefficients for the explicit
        %   basis functions defined by BASISFUNCTION.
        %
        %   See also BASISFUNCTION.
        Beta;
        
        %SIGMA - Noise standard deviation.
        %   SIGMA is the scalar estimated value for the noise standard
        %   deviation of this Gaussian process model.
        Sigma;
        
        %PREDICTORLOCATION - Predictor means.
        %   The PREDICTORLOCATION property is either empty or a vector with
        %   D elements, one for each predictor. If training data were
        %   standardized, the PREDICTORLOCATION property is filled with
        %   means of predictors used for training. Otherwise the
        %   PREDICTORLOCATION property is empty. If the PREDICTORLOCATION
        %   property is not empty, the PREDICT method centers predictor
        %   matrix X by subtracting the respective element of
        %   PREDICTORLOCATION from every column.
        %
        %   When there are categorical predictors, PREDICTORLOCATION includes
        %   elements for the dummy variables for those predictors. The
        %   corresponding entries in PREDICTORLOCATION are 0, because dummy
        %   variables are not centered or scaled.
        %
        %   See also PREDICTORSCALE.
        PredictorLocation;
        
        %PREDICTORSCALE - Predictor standard deviations.
        %   The PREDICTORSCALE property is either empty or a vector with D
        %   elements, one for each predictor. If training data were
        %   standardized, the PREDICTORSCALE property is filled with
        %   standard deviations of predictors used for training. Otherwise
        %   the PREDICTORSCALE property is empty. If the PREDICTORSCALE
        %   property is not empty, the PREDICT method scales predictor
        %   matrix X by dividing every column by the respective element of
        %   PREDICTORSCALE (after centering using PREDICTORLOCATION).
        %
        %   When there are categorical predictors, PREDICTORSCALE includes
        %   elements for the dummy variables for those predictors. The
        %   corresponding entries in PREDICTORSCALE are 1, because dummy
        %   variables are not centered or scaled.
        %
        %   See also PREDICTORLOCATION.
        PredictorScale;
        
        %ALPHA - Vector of weights from the fitted model.
        %   ALPHA is a vector of weights used to make predictions from this
        %   model. Predictions for a new predictor matrix XNEW are computed
        %   by forming the product:
        %
        %       K(XNEW,ACTIVESETVECTORS)*ALPHA
        %
        %   where K(XNEW,ACTIVESETVECTORS) is the matrix of kernel products
        %   between XNEW and ACTIVESETVECTORS and ALPHA is a vector of
        %   weights.
        %
        %   See also ACTIVESETVECTORS.
        Alpha;                
        
        %ACTIVESETVECTORS - Active set vectors.
        %   ACTIVESETVECTORS is a subset of the training data used to make
        %   predictions from this model. Predictions for a new predictor
        %   matrix XNEW are computed by forming the product:
        %
        %       K(XNEW,ACTIVESETVECTORS)*ALPHA
        %
        %   where K(XNEW,ACTIVESETVECTORS) is the matrix of kernel products
        %   between XNEW and ACTIVESETVECTORS and ALPHA is a vector of
        %   weights. ACTIVESETVECTORS is equal to the training data X for
        %   exact Gaussian process regression and it is equal to a subset
        %   of the training data X for sparse Gaussian process regression.
        %
        %   When there are categorical predictors, ACTIVESETVECTORS includes
        %   dummy variables for those predictors.
        %
        %   See also ALPHA.
        ActiveSetVectors;
        
        %FITMETHOD - Method used to estimate parameters.
        %   FITMETHOD is a string containing the name of the method used to
        %   estimate basis function coefficients, noise standard deviation
        %   and kernel parameters of this Gaussian process model. FITMETHOD
        %   can be one of the following:
        %
        %       'None'  - No estimation (uses initial parameter values).
        %       'Exact' - Exact Gaussian Process Regression.
        %       'SD'    - Subset of Datapoints approximation.
        %       'SR'    - Subset of Regressors approximation.
        %       'FIC'   - Fully Independent Conditional approximation.
        %
        %   See also PREDICTMETHOD.
        FitMethod;
        
        %PREDICTMETHOD - Method used to make predictions.
        %   PREDICTMETHOD is a string containing the name of the method 
        %   used to make predictions from a Gaussian process model given 
        %   the basis function coefficients, noise standard deviation and 
        %   kernel parameters. PREDICTMETHOD can be one of the following:
        %
        %       'Exact' - Exact Gaussian Process Regression.
        %       'BCD'   - Block Coordinate Descent.
        %       'SD'    - Subset of Datapoints approximation.
        %       'SR'    - Subset of Regressors approximation.
        %       'FIC'   - Fully Independent Conditional approximation.
        %
        %   See also FITMETHOD.
        PredictMethod;
        
        %ACTIVESETMETHOD - Method used to select the active set.
        %   ACTIVESETMETHOD is a string containing the method used to
        %   select the active set for sparse methods ('SD','SR' and 'FIC').
        %   The selected active set is used during parameter estimation or
        %   prediction or both depending on the value of 'FitMethod' and
        %   'PredictMethod' in the call to fitrgp. ACTIVESETMETHOD can be 
        %   one of the following:
        %
        %       'SGMA'       - Sparse Greedy Matrix Approximation.
        %       'Entropy'    - Differential entropy based selection.
        %       'Likelihood' - Subset of regressors log likelihood based selection.
        %       'Random'     - Random selection.
        %
        %   See also ACTIVESETVECTORS, FITMETHOD, PREDICTMETHOD.
        ActiveSetMethod;
        
        %ACTIVESETSIZE - Size of the active set.
        %   ACTIVESETSIZE is an integer specifying the size of the active
        %   set for sparse methods ('SD','SR' and 'FIC').
        %
        %   See also ACTIVESETMETHOD.
        ActiveSetSize;
    end
       
    methods
        function a = get.KernelFunction(this)
            a = this.Impl.KernelFunction;
        end
        
        function a = get.KernelInformation(this)
            a = summary(this.Impl.Kernel);
        end        
        
        function a = get.BasisFunction(this)
            a = this.Impl.BasisFunction;
        end
        
        function a = get.Beta(this)
            a = this.Impl.BetaHat;
        end
        
        function a = get.Sigma(this)
            a = this.Impl.SigmaHat;
        end
        
        function a = get.PredictorLocation(this)
            a = this.Impl.StdMu;
        end
        
        function a = get.PredictorScale(this)
            a = this.Impl.StdSigma;
        end
        
        function a = get.Alpha(this)
            a = this.Impl.AlphaHat;
        end
        
        function a = get.ActiveSetVectors(this)
            a = this.Impl.ActiveSetX;
        end
        
        function a = get.FitMethod(this)
            a = this.Impl.FitMethod;
        end
        
        function a = get.PredictMethod(this)
            a = this.Impl.PredictMethod;
        end
        
        function a = get.ActiveSetMethod(this)
            a = this.Impl.ActiveSetMethod;
        end
        
        function a = get.ActiveSetSize(this)
            a = this.Impl.ActiveSetSize;
        end
    end
    
    methods(Access=public,Hidden=true)
        function this = CompactRegressionGP(dataSummary,responseTransform,compactGPConfig)
            this      = this@classreg.learning.regr.RegressionModel(dataSummary,responseTransform);
            this.Impl = compactGPConfig;
            this.CategoricalVariableCoding = 'dummy';
        end
    end
    
    methods(Access=protected)                
        function r = response(~,~,varargin)
            r = [];
        end
        function n = getExpandedPredictorNames(this)
            n = classreg.learning.internal.expandPredictorNames(this.PredictorNames,this.VariableRange);
        end
        
        function s = propsForDisp(this,s)
        %propsForDisp Return a structure containing properties for display.
        %   s = propsForDisp(this,s) takes an object this of class
        %   CompactRegressionGP and a (possibly empty) structure s and
        %   returns a filled structure s containing the properties of
        %   CompactRegressionGP that should be displayed by a call to disp.
        %   The disp method is inherited from Predictor and this method
        %   looks for things to display in the structure s.
        
            % 1. Call superclass method first.
            s = propsForDisp@classreg.learning.regr.RegressionModel(this,s);
            
            % 2. Add properties of this class to display in s.
            s.KernelFunction    = this.KernelFunction;
            s.KernelInformation = this.KernelInformation;
            s.BasisFunction     = this.BasisFunction;
            s.Beta              = this.Beta;
            s.Sigma             = this.Sigma;
            s.PredictorLocation = this.PredictorLocation;
            s.PredictorScale    = this.PredictorScale;
            s.Alpha             = this.Alpha;
            s.ActiveSetVectors  = this.ActiveSetVectors;            
            s.PredictMethod     = this.PredictMethod;            
            s.ActiveSetSize     = this.ActiveSetSize;
            
        end % end of propsForDisp.
    end
    
    methods(Access=public)        
        function varargout = predict(this,X,varargin)
        %PREDICT Predict response of the Gaussian process regression model.
        %   YPRED=PREDICT(GPR,X) returns predicted response YPRED for Gaussian
        %   process regression model GPR and predictors X. X must be a table if
        %   GPR was originally trained on a table, or a numeric matrix if GPR was
        %   originally trained on a matrix. YPRED is a vector of type double with N
        %   elements, where N is the number of rows in X.
        %
        %   [YPRED,YSD]=PREDICT(GPR,X) also returns a N-by-1 vector YSD
        %   such that YSD(i) is the estimated standard deviation of the new
        %   response at X(i,:) from a trained model.
        %
        %   [YPRED,YSD,YINT]=PREDICT(GPR,X) also returns a N-by-2 matrix
        %   YINT containing 95% prediction intervals for the true responses
        %   corresponding to each row of X. The lower limits of the bounds
        %   are in YINT(:,1), and the upper limits are in YINT(:,2).
        %
        %   [YPRED,YSD,YINT]=PREDICT(GPR,X,'PARAM1',val1,...) specifies
        %   optional parameter name/value pairs:
        %
        %       'Alpha'          A value between 0 and 1 to specify the 
        %                        confidence level as 100(1-ALPHA)%. Default
        %                        is 0.05 for 95% confidence.
        %
        %   NOTES:        
        %   o Computation of YSD and YINT is not supported for PredictMethod
        %   equal to 'BCD'. You can specify PredictMethod in the call to
        %   fitrgp.
        %
        %   o If GPR is a CompactRegressionGP you cannot compute standard
        %   deviations or prediction intervals for PredictMethod equal to
        %   'SR' or 'FIC'. To get YSD and YINT for PredictMethod equal to
        %   'SR' or 'FIC' use the full object RegressionGP.
        %
        %   Example: Fit a sparse GPR model and plot predictions along with
        %   prediction intervals.
        %       % 1. Some example data.
        %       rng(0,'twister');
        %       N = 50000;
        %       X = linspace(0,1,N)';
        %       X = [X,X.^2];
        %       sigmaNoise = 0.2;
        %       ytrue = 1 + X*[1;2] + sin(10*X*[1;-2]);
        %       y = ytrue + sigmaNoise*randn(N,1);
        %
        %       % 2. Fit using 'SR' and predict using 'FIC' with 'Matern32'
        %       % kernel. Use 'SGMA' for active set selection with an active
        %       % set size of 50.
        %       gpr = fitrgp(X,y,'KernelFunction','Matern32','FitMethod','SR','PredictMethod','FIC',...
        %           'ActiveSetMethod','SGMA','ActiveSetSize',50,'Basis','None',...
        %           'Optimizer','QuasiNewton','KernelParameters',[1;1],'Sigma',1,'Verbose',1);
        %       
        %       % 3. Plot true response along with predictions from GPR.
        %       % Also plot 99% prediction intervals.
        %       confalpha = 0.01;
        %       [pred,se,ci] = predict(gpr,X,'Alpha',confalpha);
        %       figure;
        %       plot(y,'r');
        %       hold on;
        %       plot(ytrue,'b');
        %       plot(pred,'k');
        %       plot(ci(:,1),'c');
        %       plot(ci(:,2),'m');
        %       legend('Noisy response','True response','GPR prediction','Lower 99% Limit','Upper 99% Limit','Location','Best');
        %
        %   See also fitrgp, classreg.learning.regr.CompactRegressionGP.
        
            % Handle input data such as "tall" requiring a special adapter
            adapter = classreg.learning.internal.makeClassificationModelAdapter(this,X);
            if ~isempty(adapter) 
                [varargout{1:nargout}] = predict(adapter,X);
                return;
            end
        
            if this.TableInput || istable(X)
                vrange = getvrange(this);
                X = classreg.learning.internal.table2PredictMatrix(X,[],[],...
                    vrange,...
                    this.CategoricalPredictors,this.PredictorNames);
            end
            if any(this.CategoricalPredictors)
                if ~this.TableInput
                    X = classreg.learning.internal.encodeCategorical(X,this.VariableRange);
                end
                X = classreg.learning.internal.expandCategorical(X,...
                    this.CategoricalPredictors,this.VariableRange);
            end
            [varargin{:}] = convertStringsToChars(varargin{:});
            % 1. Default parameter values.
            dfltAlpha = 0.05;

            % 2. Optional parameter names and their default values.
            paramNames =   {'Alpha'};
            paramDflts = {dfltAlpha};

            % 3. Parse optional parameter name/value pairs.
            [confalpha] = internal.stats.parseArgs(paramNames,paramDflts,varargin{:});

            % 4. Validate optional parameter values.
            [isok,confalpha] = this.validateAlpha(confalpha);
            if ~isok
                error(message('stats:CompactRegressionGP:predict:BadAlpha'));
            end
        
            % 5. Cannot compute standard deviations or prediction intervals
            % if BCD is used.
            import classreg.learning.modelparams.GPParams;
            if ( nargout > 1 && strcmpi(this.Impl.PredictMethod,GPParams.PredictMethodBCD) )
                error(message('stats:CompactRegressionGP:predict:NoCIForBCD'));
            end
            
            % 6. Validate X. It must be a numeric, real matrix of size
            % M-by-D where D is the number of predictors in this model. In
            % addition, deal with NaN's and Inf's in X.
            D = size(this.ActiveSetVectors,2);
            isok = isnumeric(X) && isreal(X) && ismatrix(X) && (size(X,2) == D);
            if ~isok
                error(message('stats:CompactRegressionGP:predict:BadX',D));
            end
            
            % 7. Call predict on the Impl object.
            [varargout{1:nargout}] = predict(this.Impl,X,confalpha);
            
        end % end of predict.
    end
    
    methods(Static,Access=protected)        
        function [isok,alpha] = validateAlpha(alpha)
        %validateAlpha - Validate the confidence level alpha.
        %   [isok,alpha] = validateAlpha(alpha) accepts a potential alpha
        %   value and validates it. If alpha is valid, isok is true. If
        %   alpha is not valid, isok is false.
        %
        %   What is checked?
        %
        %   (1) alpha must be a numeric, real, scalar.
        %   (2) alpha must be >= 0 and <= 1.
        % 
        %   If (1) or (2) is not valid, isok is false.

            isok = isnumeric(alpha) && isreal(alpha) && isscalar(alpha);   
            isok = isok && (alpha >= 0 && alpha <= 1);
            
        end % end of validateAlpha.        
    end
    
    methods(Static,Hidden)
        function obj = fromStruct(s)
            % Make an GP object from a codegen struct.
            
            s.ResponseTransform = s.ResponseTransformFull;
            
            s = classreg.learning.coderutils.structToRegr(s);
                                   
            % implementation
            impl = classreg.learning.impl.CompactGPImpl.fromStruct(s.Impl);
            
            % Make an object
            obj = classreg.learning.regr.CompactRegressionGP(...
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
            s.FromStructFcn = 'classreg.learning.regr.CompactRegressionGP.fromStruct';
            
            % impl
            s.Impl = toStruct(this.Impl);
            
            % Add extra field to the Impl struct to retain Kernel
            % Parameters. These parameters are only available in the top-level object,
            % and are not present inside the Impl object. But they are
            % needed for reconstructing the Kernel object inside the
            % reconstructed Impl object.
            s.Impl.KernelParams = this.KernelInformation.KernelParameters;
        end
    end
    methods(Hidden, Static)
        function name = matlabCodegenRedirect(~)
            name = 'classreg.learning.coder.regr.CompactRegressionGP';
        end
    end
end