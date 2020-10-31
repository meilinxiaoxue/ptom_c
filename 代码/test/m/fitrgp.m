function obj = fitrgp(X,Y,varargin)
%FITRGP Fit a Gaussian Process Regression (GPR) model.
%   MODEL=FITRGP(TBL,Y) returns a GPR model MODEL for data in the table
%   TBL and response Y. TBL contains the predictor variables. Y can be any
%   of the following:
%      1. A column vector of floating point numbers.
%      2. The name of a variable in TBL. This variable is used as the
%         response Y, and the remaining variables in TBL are used as
%         predictors.
%      3. A formula string such as 'y ~ x1 + x2 + x3' specifying that the
%         variable y is to be used as the response, and the other variables
%         in the formula are predictors. Any table variables not listed in
%         the formula are not used.
%
%   MODEL=FITRGP(X,Y) is an alternative syntax that accepts X as an N-by-P
%   matrix of predictors with one row per observation and one column per
%   predictor. Y is the response vector.
%
%   MODEL is a GPR model. If you use one of the following five options and
%   do not pass OptimizeHyperparameters, MODEL is of class
%   RegressionPartitionedModel: 'CrossVal', 'KFold', 'Holdout', 'Leaveout'
%   or 'CVPartition'. Otherwise, MODEL is of class RegressionGP.
%
%   Use of a matrix X rather than a table TBL saves both memory and
%   execution time.
%
%   MODEL=FITRGP(X,Y,'PARAM1',val1,'PARAM2',val2,...) specifies optional
%   parameter name/value pairs:
%
%       'KernelFunction'   - A string or a function handle specifying form 
%                            of the covariance function of the Gaussian
%                            process. Valid values for 'KernelFunction'
%                            are:
%
%           'squaredexponential'    - Squared exponential kernel (Default).
%           'exponential'           - Exponential kernel.
%           'matern32'              - Matern kernel with parameter 3/2.
%           'matern52'              - Matern kernel with parameter 5/2.
%           'rationalquadratic'     - Rational quadratic kernel.
%           'ardexponential'        - Exponential kernel with a separate
%                                     length scale per predictor.
%           'ardsquaredexponential' - Squared exponential kernel with a
%                                     separate length scale per predictor.
%           'ardmatern32'           - Matern kernel with parameter 3/2 
%                                     and a separate length scale per
%                                     predictor.
%           'ardmatern52'           - Matern kernel with parameter 5/2 
%                                     and a separate length scale per
%                                     predictor.
%           'ardrationalquadratic'  - Rational quadratic kernel with a
%                                     separate length scale per predictor.
%           KFCN                    - A function handle that can be called
%                                     like this:
%
%                                     KMN = KFCN(XM,XN,THETA)
%
%                                     XM is a M-by-D matrix, XN is a N-by-D
%                                     matrix and KMN is a M-by-N matrix of
%                                     kernel products such that KMN(i,j) is
%                                     the kernel product between XM(i,:)
%                                     and XN(j,:). THETA is the R-by-1
%                                     unconstrained parameter vector for
%                                     KFCN.
%
%       'KernelParameters' - A vector of initial values for the kernel 
%                            parameters. Valid value of 'KernelParameters'
%                            depends on the value of 'KernelFunction' as
%                            follows:
%
%           If 'KernelFunction' is:   'KernelParameters' should be:
%           -----------------------   -----------------------------
%           'squaredexponential'    - A 2-by-1 vector PHI such that:
%           'exponential'             PHI(1) = length scale and
%           'matern32'                PHI(2) = signal standard deviation.
%           'matern52'              - The default value of
%                                     'KernelParameters' is:
%                                     PHI = [mean(std(X));std(Y)/sqrt(2)]
%
%           'rationalquadratic'     - A 3-by-1 vector PHI such that:
%                                     PHI(1) = length scale and
%                                     PHI(2) = rational quadratic exponent
%                                     PHI(3) = signal standard deviation
%                                   - The default value of
%                                     'KernelParameters' is:
%                                     PHI = [mean(std(X));1;std(Y)/sqrt(2)]
%
%           'ardexponential'        - A (D+1)-by-1 vector PHI such that:
%           'ardsquaredexponential'   PHI(i) = predictor i length scale and
%           'ardmatern32'             PHI(D+1) = signal standard deviation.  
%           'ardmatern52'           - The default value of 
%                                     'KernelParameters' is:
%                                     PHI = [std(X)';std(Y)/sqrt(2)]
%
%           'ardrationalquadratic'  - A (D+2)-by-1 vector PHI such that:
%                                     PHI(i) = predictor i length scale and
%                                     PHI(D+1) = rational quadratic exponent
%                                     PHI(D+2) = signal standard deviation
%                                   - The default value of
%                                     'KernelParameters' is:
%                                     PHI = [std(X)';1;std(Y)/sqrt(2)]
%
%           Function handle KFCN    - A R-by-1 vector as the initial value 
%                                     of the unconstrained parameter vector
%                                     THETA parameterizing KFCN.
%                                   - When 'KernelFunction' is a function
%                                     handle, you must supply
%                                     'KernelParameters'.
%                            
%       'BasisFunction'    - A string or a function handle specifying form 
%                            of the explicit basis in the Gaussian process
%                            model. An explicit basis function adds the
%                            term H*BETA to the Gaussian process model
%                            where H is a N-by-P basis matrix and BETA is a
%                            P-by-1 vector of basis coefficients. Valid
%                            values for 'BasisFunction' are:
%
%                   'none'          - H = zeros(N,0).
%                   'constant'      - H = ones(N,1) (Default).
%                   'linear'        - H = [ones(N,1),X].
%                   'purequadratic' - H = [ones(N,1),X,X.^2].
%                   HFCN            - A function handle that can be called 
%                                     like this:
%
%                                       H = HFCN(X)
%
%                                     X is a N-by-D matrix of predictors
%                                     and H is a N-by-P matrix of basis
%                                     functions.
%                            If there are categorical predictors, then X in
%                            the above expressions includes dummy variables
%                            for those predictors and D is the number of
%                            predictor columns including the dummy
%                            variables.
%
%       'Beta'             - Initial value for the coefficient vector BETA
%                            for the explicit basis. If the basis matrix H
%                            is N-by-P then BETA must be a P-by-1 vector.
%                            Default is zeros(P,1). The initial value of
%                            'Beta' is used only when 'FitMethod' is 'none'
%                            (see below).
%
%       'Sigma'            - A scalar specifying the initial value for the 
%                            noise standard deviation in the Gaussian
%                            process model. If 'ConstantSigma' is true,
%                            this value is held constant throughout the
%                            fitting process. Default is std(Y)/sqrt(2).
%
%       'ConstantSigma'    - A scalar logical specifying whether the
%                            'Sigma' parameter should be held constant
%                            during fitting. Default: false.
%
%       'FitMethod'        - Method used to estimate parameters of the 
%                            Gaussian process model. Choices are:
%
%               'none'  - No estimation (uses initial parameter values).
%               'exact' - Exact Gaussian Process Regression.
%               'sd'    - Subset of Datapoints approximation.
%               'sr'    - Subset of Regressors approximation.
%               'fic'   - Fully Independent Conditional approximation.
%
%                            Default is 'exact' for N <= 2000 and 'sd'
%                            otherwise.
%
%       'PredictMethod'    - Method used to make predictions from a 
%                            Gaussian process model given the parameters.
%                            Choices are:
%
%               'exact' - Exact Gaussian Process Regression.
%               'bcd'   - Block Coordinate Descent.
%               'sd'    - Subset of Datapoints approximation.
%               'sr'    - Subset of Regressors approximation.
%               'fic'   - Fully Independent Conditional approximation.
%
%                            Default is 'exact' for N <= 10000 and 'bcd'
%                            otherwise.
%
%       'ActiveSet'        - A vector of integers of length M where 
%                            1 <= M <= N indicating the observations that
%                            are in the active set. 'ActiveSet' should not
%                            have duplicate elements and its elements must
%                            be integers from 1 to N. Alternatively,
%                            'ActiveSet' can also be a logical vector of
%                            length N with at least 1 true element. If you
%                            supply 'ActiveSet' then 'ActiveSetSize' and
%                            'ActiveSetMethod' have no effect. In addition,
%                            you cannot cross validate this model. Default
%                            is [].
%
%       'ActiveSetSize'    - An integer M with 1 <= M <= N specifying the 
%                            size of the active set for sparse fit methods
%                            like 'sd', 'sr' and 'fic'. Typical values of
%                            'ActiveSetSize' are a few hundred to a few
%                            thousand. Default is min(1000,N) when
%                            'FitMethod' is equal to 'sr' or 'fic' and
%                            min(2000,N) otherwise.
%
%       'ActiveSetMethod'  - A string specifying the active set selection
%                            method. Choices are:
%
%               'sgma'       - Sparse Greedy Matrix Approximation.
%               'entropy'    - Differential entropy based selection.
%               'likelihood' - SR log likelihood based selection.
%               'random'     - Random selection.
%                           
%                            All active set selection methods (except
%                            'random') require the storage of a N-by-M
%                            matrix where M is the size of the active set
%                            and N is the number of observations. Default
%                            is 'random'.
%
%       'Standardize'      - Logical scalar. If true, standardize X by
%                            centering and dividing columns by their
%                            standard deviations. Default is false.
%
%       'Verbose'          - Verbosity level, one of: 0 or 1. 
%                            o If 'Verbose' is > 0, iterative diagnostic
%                            messages related to parameter estimation,
%                            active set selection and block coordinate
%                            descent are displayed on screen.
%                            o If 'Verbose' is 0, diagnostic messages
%                            related to active set selection and block
%                            coordinate descent are suppressed but messages
%                            related to parameter estimation are displayed
%                            depending on the value of 'Display' in
%                            'OptimizerOptions'. Default is 0.
%
%       'CacheSize'        - Positive scalar specifying the cache size in
%                            MB. 'CacheSize' is the extra memory that is 
%                            available on top of that required for fitting 
%                            and active set selection. 'CacheSize' is used 
%                            to:
%                            o Decide whether interpoint distances should 
%                              be cached when estimating parameters. 
%                            o Decide how matrix vector products should be 
%                              computed for BCD and for making predictions.    
%                            Default is 1000 MB.
%
%       'Regularization'   - A positive scalar specifying the standard 
%                            deviation for regularizing sparse methods
%                            ('sr' and 'fic'). Default is 1e-2*std(Y) where
%                            Y is the response vector.
%
%       'SigmaLowerBound'  - A positive scalar specifying a lower bound on 
%                            the noise standard deviation. Default is
%                            1e-2*std(Y) where Y is the response vector.
%
%       'RandomSearchSetSize' 
%                          - An integer specifying the random search set
%                            size per greedy inclusion for active set
%                            selection. Default is 59.
%
%       'ToleranceActiveSet'  
%                          - A positive scalar specifying the relative
%                            tolerance for terminating active set
%                            selection. Default is 1e-6.
%
%       'NumActiveSetRepeats' 
%                          - An integer specifying the number of
%                            repetitions of interleaved active set
%                            selection and parameter estimation when
%                            'ActiveSetMethod' is not 'random'. Default is 3.
%
%       'BlockSizeBCD'     - An integer >=1 and <= N specifying the block 
%                            size for BCD. Default is min(1000,N).
%
%       'NumGreedyBCD'     - An integer >=1 and <= BlockSizeBCD specifying 
%                            the number of greedy selections for BCD.
%                            Default is min(100,BlockSizeBCD).
%
%       'ToleranceBCD'     - A positive scalar specifying the relative 
%                            tolerance on gradient norm for terminating BCD
%                            iterations. Default is 1e-3.
%
%       'StepToleranceBCD' - A positive scalar specifying the absolute 
%                            tolerance on step size for terminating BCD
%                            iterations. Default is 1e-3.
%
%       'IterationLimitBCD' 
%                          - An integer specifying the maximum number of 
%                            BCD iterations. Default is 1000000.
%
%       'DistanceMethod'   - A string indicating the method for computing 
%                            interpoint distances to evaluate built in
%                            kernel functions. Choices are 'fast' and
%                            'accurate'. Default is 'fast'.
%
%       'ComputationMethod' 
%                          - A string indicating the method for computing
%                            log likelihood and gradient for 'sr' and 'fic'
%                            fitting. Choices are 'qr' and 'v'. If
%                            'ComputationMethod' is 'qr' then a QR
%                            factorization based approach is used for
%                            better accuracy. If 'ComputationMethod' is 'v'
%                            then the so called V-method based computations
%                            are used along with faster computation of log
%                            likelihood gradients. Default is 'qr'.
%
%       'Optimizer'        - A string specifying the optimizer to use for
%                            parameter estimation. Choices include
%                            'fminsearch', 'quasinewton', 'lbfgs',
%                            'fminunc' and 'fmincon'. Use of 'fminunc' and
%                            'fmincon' requires an Optimization Toolbox
%                            license. Default is 'quasinewton'.
%
%       'OptimizerOptions' - A structure or object containing options for 
%                            the chosen optimizer. If 'Optimizer' is
%                            'fminsearch', 'OptimizerOptions' must be
%                            created using OPTIMSET. If 'Optimizer' is
%                            'quasinewton' or 'lbfgs', 'OptimizerOptions'
%                            must be created using STATSET('fitrgp'). If
%                            'Optimizer' is 'fminunc' or 'fmincon',
%                            'OptimizerOptions' must be created using
%                            OPTIMOPTIONS. Default depends on the chosen
%                            value of 'Optimizer'.
%
%       'InitialStepSize'  - A real positive scalar specifying the
%                            approximate maximum absolute value of the
%                            first step when 'Optimizer' is equal to
%                            'quasinewton' or 'lbfgs'. Suppose g0 is the
%                            maximum absolute value of the gradient at the
%                            initial point. When 'InitialStepSize' s0 is
%                            specified, the initial Hessian approximation
%                            is chosen as B0 = (g0/s0)*I where I is the
%                            identity matrix. 'InitialStepSize' can also be
%                            set to 'auto' in which case s0 will be
%                            selected automatically. Default is [] meaning
%                            that the initial Hessian approximation is
%                            determined using a different heuristic that
%                            does not use 'InitialStepSize'.
%                            TIP: For a GPR model with many kernel
%                            parameters (e.g., when using an ARD kernel
%                            with many predictors), the default method of
%                            choosing the initial Hessian approximation can
%                            be slow. In this case, consider specifying a
%                            real positive scalar value or 'auto' for the
%                            'InitialStepSize' name/value pair.
%
%       'CategoricalPredictors' - List of categorical predictors. Pass
%                        'CategoricalPredictors' as one of:
%                          * A numeric vector with indices between 1 and P,
%                            where P is the number of columns of X or
%                            variables in TBL.
%                          * A logical vector of length P, where a true
%                            entry means that the corresponding column of X
%                            or T is a categorical variable. 
%                          * 'all', meaning all predictors are categorical.
%                          * A string array or cell array of strings, where 
%                            each element in the array is the name of a predictor
%                            variable. The names must match entries in
%                            'PredictorNames' values.
%                        Default: for a matrix input X, no categorical
%                        predictors; for a table TBL, predictors are
%                        treated as categorical if they are cell arrays of
%                        strings, logical, or categorical.
%
%       'CrossVal'         - If 'on', grows a cross-validated GPR model 
%                            with 10 folds. You can use 'KFold', 'Holdout',
%                            'Leaveout' and 'CVPartition' parameters to
%                            override this cross-validation setting. You
%                            can only use one of these four options
%                            ('KFold', 'Holdout', 'Leaveout' and
%                            'CVPartition') at a time when creating a
%                            cross-validated model. As an alternative, you
%                            can cross-validate later using CROSSVAL method
%                            for GPR model. Default: 'off'.
%
%       'CVPartition'      - A partition created with CVPARTITION to use in 
%                            cross-validated GPR. 
%
%       'Holdout'          - Holdout validation uses the specified fraction 
%                            of the data for test, and uses the rest of the
%                            data for training. Specify a numeric scalar 
%                            between 0 and 1.
%
%       'KFold'            - Number of folds to use in cross-validated GPR, 
%                            a positive integer. Default: 10.
%
%       'Leaveout'         - Use leave-one-out cross-validation by setting 
%                            to 'on'.
%
%       'PredictorNames'   - A string array or cell array of names for the 
%                            predictor variables, in the order in which they appear
%                            in X. Default: {'x1','x2',...}. For a table
%                            TBL, these names must be a subset of the
%                            variable names in TBL, and only the selected
%                            variables are used. Not allowed when Y is a
%                            formula. Default: all variables other than Y.
%
%       'ResponseName'     - Name of the response variable Y, a string. Not
%                            allowed when Y is a name or formula.
%                            Default: 'Y'
%
%       'OptimizeHyperparameters' 
%                      - Hyperparameters to optimize. Either 'none',
%                        'auto', 'all', a string/cell array of eligible
%                        hyperparameter names, or a vector of
%                        optimizableVariable objects, such as that returned
%                        by the 'hyperparameters' function. To control
%                        other aspects of the optimization, use the
%                        HyperparameterOptimizationOptions name-value pair.
%                        'auto' is equivalent to {'Sigma'}. 'all' is
%                        equivalent to {'BasisFunction', 'KernelFunction',
%                        'KernelScale', 'Sigma', 'Standardize'}. Note: When
%                        'KernelScale' is optimized, the 'KernelParameters'
%                        argument to fitrgp is used to specify the value of
%                        the kernel scale parameter, which is held constant
%                        during fitting. In this case, all input dimensions
%                        are constrained to have the same KernelScale
%                        value. KernelScale cannot be optimized for any of
%                        the ARD kernels. Default: 'none'.
%
%   Refer to the MATLAB documentation for info on parameters for
%       <a href="matlab:helpview(fullfile(docroot,'stats','stats.map'), 'fitrgpHyperparameterOptimizationOptions')">Hyperparameter Optimization</a>
%
%   Example: Train a GPR model on example data.
%       % 1. Generate example data.
%       rng(0,'twister');
%       N = 1000;
%       x = linspace(-10,10,N)';
%       y = 1 + x*5e-2 + sin(x)./x + 0.2*randn(N,1);
%
%       % 2. Fit the model using 'exact' and predict using 'exact'.
%       gpr = fitrgp(x,y,'Basis','linear','Optimizer','QuasiNewton',...
%                    'verbose',1,'FitMethod','exact','PredictMethod','exact');
%
%       % 3. Plot results.
%       plot(x,y,'r');
%       hold on;
%       plot(x,resubPredict(gpr),'b');
%       xlabel('x');
%       ylabel('y');
%       legend('Data','GPR fit');
%
%   See also RegressionGP, classreg.learning.regr.CompactRegressionGP.

%
%       'ConstantKernelParameters' 
%                          - A logical vector indicating which kernel
%                            parameters should be held constant during
%                            fitting. See the 'KernelParameters' parameter
%                            for the required dimensions of this argument.
%                            Default: false for all kernel parameters.
%

%   Copyright 2014-2017 The MathWorks, Inc.

if nargin > 1
    Y = convertStringsToChars(Y);
end

if nargin > 2
    [varargin{:}] = convertStringsToChars(varargin{:});
end
internal.stats.checkNotTall(upper(mfilename),0,X,Y,varargin{:});

[IsOptimizing, RemainingArgs] = classreg.learning.paramoptim.parseOptimizationArgs(varargin);
if IsOptimizing
    obj = classreg.learning.paramoptim.fitoptimizing('fitrgp',X,Y,varargin{:});
else
    obj = RegressionGP.fit(X,Y,RemainingArgs{:});
end
end