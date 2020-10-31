function this = fsrnca(X,Y,varargin)
%fsrnca - Feature selection for regression.
%   MODEL = fsrnca(X,Y) performs feature selection for regression using
%   predictors in X and responses in Y. Feature weights are learned by a
%   diagonal adaptation of neighborhood component analysis (NCA) with
%   regularization.
%
%   o X is an N-by-P matrix of predictors with one row per observation and
%   one column per predictor.
%
%   o Y is a numeric real vector of length N.
%
%   o MODEL is of type FeatureSelectionNCARegression.
%
%   MODEL = fsrnca(X,Y,'PARAM1',val1,...) specifies optional parameter
%   name/value pairs:
%
%       'FitMethod'         Method used to fit this model. Choices are:
%                               'none'    - No fitting.
%                               'exact'   - Fitting using all data.
%                               'average' - Divide data into subsets, fit 
%                                           each subset using the 'exact'
%                                           method and average the feature
%                                           weights. See 'NumPartitions'
%                                           name/value pair.
%                           Default is 'exact'.
%       'Lambda'            A non-negative real scalar specifying the 
%                           regularization parameter. Default is 1/N where
%                           N = size(X,1).
%       'InitialFeatureWeights'
%                           A P-by-1 vector of real positive initial
%                           feature weights where P is the number of
%                           predictors in X. Default is ones(P,1).
%       'Standardize'       Logical scalar. If true, standardize X by
%                           centering and dividing columns by their
%                           standard deviations. If the predictors in X are 
%                           on different scales, 'Standardize' should be 
%                           set to true so that all feature weights get 
%                           equally penalized by the regularization term. 
%                           Default is false. See 'LengthScale' name/value
%                           pair.
%       'Verbose'           A non-negative integer specifying the verbosity
%                           level as follows:
%                           * 0  - no convergence summary is displayed.
%                           * 1  - convergence summary is displayed on
%                                  screen.
%                           * >1 - more convergence information is
%                                  displayed on screen depending on the 
%                                  fitting algorithm.                        
%                           Default is 0.
%       'Solver'            A character vector specifying the solver to use
%                           for estimating feature weights. Choices are:
%                     'lbfgs'           - limited memory BFGS 
%                     'sgd'             - stochastic gradient descent
%                     'minibatch-lbfgs' - stochastic gradient descent 
%                                         with LBFGS applied to minibatches
%                           Default is 'lbfgs' for N <= 1000 and 'sgd' for
%                           N > 1000.
%       'LossFunction'      A character vector specifying the loss 
%                           function. Choices are 'mad', 'mse' and
%                           'epsiloninsensitive'.
%
%                           'LossFunction' can also be a function handle
%                           lossFcn that can be called like this:
%                           
%                               L = lossFcn(YN,YM)
%
%                           where YN is a N-by-1 vector and YM is a M-by-1
%                           vector. L is a N-by-M matrix of loss values
%                           such that L(i,j) is the loss value for YN(i)
%                           and YM(j). Default is 'mad'. Also see 'Weights'
%                           name/value pair.
%       'Epsilon'           A non-negative real scalar specifying the
%                           epsilon value for 'LossFunction' equal to 
%                           'epsiloninsensitive'. Default is iqr(Y)/13.49.
%       'InitialLearningRate'
%                           A positive real scalar specifying the initial
%                           learning rate for solver 'sgd'. When using
%                           solver 'sgd', the learning rate decays over
%                           iterations starting with the value specified
%                           for 'InitialLearningRate'. Default is 'auto'
%                           indicating that the initial learning rate
%                           should be determined using experiments on small
%                           subsets of the data. See the parameter
%                           name/value pairs 'NumTuningIterations' and
%                           'TuningSubsetSize'.
%                           TIPS:
%                            - MODEL.FitInfo structure saves the Iteration
%                              and Objective traces. Plot the Iteration vs.
%                              Objective trace to ensure that the selected
%                              'InitialLearningRate' is decreasing the
%                              Objective values with increasing Iteration
%                              index.
%                            - Use the refit method on the MODEL with
%                              'InitialFeatureWeights' set to
%                              MODEL.FeatureWeights to start from the
%                              current solution and run additional
%                              iterations.
%                            - For 'Solver' equal to 'minibatch-lbfgs',
%                              'InitialLearningRate' can be set to a very
%                              large value (e.g., realmax). In this case,
%                              LBFGS is effectively applied to each
%                              minibatch separately with initial feature
%                              weights taken from the previous minibatch.
%                              The option 'MiniBatchLBFGSIterations'
%                              controls the number of LBFGS iterations per
%                              minibatch.
%       'IterationLimit'    A positive integer specifying the maximum 
%                           number of iterations. Default is 10000 for
%                           solver 'sgd' and 1000 for solvers 'lbfgs' and
%                           'minibatch-lbfgs'. For solver 'sgd', each
%                           iteration processes M observations where M is
%                           the value specified for the 'MiniBatchSize'
%                           name/value pair.
%       'PassLimit'         A positive integer specifying the maximum
%                           number of passes for solver 'sgd'. Every pass
%                           processes N observations. Default is 5.
%
%   The name/value pairs listed above are a subset of all available
%   options. Refer to the MATLAB documentation for all available options:
%
%       <a href="matlab:helpview(fullfile(docroot,'stats','stats.map'), 'NCARegressionFittingOptions')">fsrnca fitting options</a>
%       <a href="matlab:helpview(fullfile(docroot,'stats','stats.map'), 'NCARegressionLBFGSOptions')">LBFGS options</a>
%       <a href="matlab:helpview(fullfile(docroot,'stats','stats.map'), 'NCARegressionSGDOptions')">SGD options</a>
%       <a href="matlab:helpview(fullfile(docroot,'stats','stats.map'), 'NCARegressionSGD-LBFGSOptions')">SGD or LBFGS options</a>
%       <a href="matlab:helpview(fullfile(docroot,'stats','stats.map'), 'NCARegressionMiniBatchLBFGSOptions')">Minibatch-LBFGS options</a>
%
%   Example 1: Detect relevant features in toy data for regression.
%       % 1. Generate data where response depends on predictors 4, 7 and 13.
%       rng(0,'twister');
%       N = 100;
%       X = rand(N,20);
%       y = cos(X(:,7)) + sin(X(:,4).*X(:,13)) + 0.1*randn(N,1);
%
%       % 2. Fit the NCA model.
%       nca = fsrnca(X,y,'Solver','lbfgs','Verbose',1,'Lambda',0.5/N);
%
%       % 3. Plot selected features.
%       figure;
%       plot(nca.FeatureWeights,'ro');
%       grid on;
%       xlabel('Feature index');
%       ylabel('Feature weight');
%
%       % 4. Plot regularized objective function for NCA.
%       figure;
%       subplot(2,1,1);
%       plot(nca.FitInfo.Iteration,nca.FitInfo.Objective,'ko-');
%       grid on;
%       xlabel('Iteration');
%       ylabel('Objective');
%
%       % 5. Plot leave-one-out loss of NCA regressor on training data.
%       subplot(2,1,2);
%       plot(nca.FitInfo.Iteration,nca.FitInfo.UnregularizedObjective,'bo-');
%       grid on;
%       xlabel('Iteration');
%       ylabel('Leave-one-out loss');
%
%   See also fscnca.

%   Copyright 2015-2016 The MathWorks, Inc.

%       Options for function and gradient computation (internal use):
%
%       'ComputationMode'   A character vector that is either 
%                           'mex-outer-tbb' or 'matlab-inner-vector'
%                           specifying the mode of computation of the NCA
%                           objective function and gradient. For full X and
%                           Y, default is 'mex-outer-tbb'. For sparse X or
%                           Y, default is 'matlab-inner-vector'. For sparse
%                           X or Y, the only currently valid
%                           'ComputationMode' is 'matlab-inner-vector'.
%       'GrainSize'         Grain size for parallel reduction. 
%                           Default is 1.

        if nargin > 2
            [varargin{:}] = convertStringsToChars(varargin{:});
        end
        
        narginchk(2,Inf);
        this = FeatureSelectionNCARegression(X,Y,varargin{:});
end