function VariableDescriptions = hyperparameters(FitFunctionName, varargin)
% HYPERPARAMETERS  Return an array of optimizableVariables for a fit function.
%   VariableDescriptions = HYPERPARAMETERS(FitFunctionName, Predictors, Response) 
%   returns a vector of optimizableVariable objects, one for each parameter
%   of FitFunctionName eligible for optimization. FitFunctionName is one of
%   the non-ensemble methods: 'fitcdiscr', 'fitcknn', 'fitclinear',
%   'fitcnb', fitcsvm', fitctree', 'fitrgp', 'fitrlinear', 'fitrsvm',
%   'fitrtree'. Predictors and Response are used to determine default
%   variable ranges.
%
%   VariableDescriptions = HYPERPARAMETERS(FitFunctionName, Predictors, Response, LearnerType) 
%   returns a vector of optimizableVariable objects when FitFunctionName
%   is one of the ensemble methods: 'fitcecoc', 'fitcensemble', or
%   'fitrensemble'. LearnerType is one of 'Discriminant', 'KNN', 'SVM',
%   or 'Tree'.
%
%   The 'Optimize' field of an optimizableVariable determines whether it
%   will be optimized. For each fit function, a default set of variables
%   have 'Optimize' set to true.
%
%   Example: Get hyperparameters for use with the fitctree function.
%       rng(0,'twister');
%       load fisheriris
%       % 1. Get hyperparameters
%       Variables = hyperparameters('fitctree',meas,species);
%       % 2. Display variables
%       arrayfun(@disp, Variables);
%       % 3. Fit trees, optimizing hyperparameters
%       Tree = fitctree(meas,species,'OptimizeHyperparameters',Variables)
%
%
%   Example: Get hyperparameters to fit an ensemble of regression trees
%       % 1. Generate example data.
%       rng(0,'twister');
%       N = 1000;
%       x = linspace(-10,10,N)';
%       y = 1 + x*5e-2 + sin(x)./x + 0.2*randn(N,1);
%       % 2. Get hyperparameters and display
%       Variables = hyperparameters('fitrensemble',x,y,'Tree');
%       arrayfun(@disp, Variables);
%       % 3. Adjust which hyperparameters to optimize
%       Variables(1).Optimize = false;
%       Variables(2).Optimize = false;
%       % 4. Find the best 50-tree boosted ensemble
%       Ens = fitrensemble(x,y,'Method','LSBoost','NumLearn',50,'OptimizeHyperparameters',Variables)
%       % 5. Plot results.
%       figure;
%       plot(x,y,'r');
%       hold on;
%       plot(x,kfoldPredict(crossval(Ens,'kfold',5)),'b');
%       xlabel('x');
%       ylabel('y');
%       legend('Data','Ensemble fit');
%
%   See also: BAYESOPT, OPTIMIZABLEVARIABLE

%   Copyright 2016 The MathWorks, Inc.

if nargin > 0
    FitFunctionName = convertStringsToChars(FitFunctionName);
end

if nargin > 1
    [varargin{:}] = convertStringsToChars(varargin{:});
end

narginchk(3, 4);
switch FitFunctionName
    case {'fitcecoc', 'fitcensemble', 'fitrensemble'}
        if nargin ~= 4
            classreg.learning.paramoptim.err('NarginEnsemble');
        else
            Predictors = varargin{1};
            Response = varargin{2};
            Learners = varargin{3};
            BOInfo = classreg.learning.paramoptim.BayesoptInfo.makeBayesoptInfo(FitFunctionName, ...
                Predictors, Response, {'Learners', Learners});
        end
    case {'fitcdiscr', 'fitcknn', 'fitclinear', 'fitcnb', 'fitcsvm', ...
          'fitctree', 'fitrgp', 'fitrlinear', 'fitrsvm', 'fitrtree'}
        if nargin ~= 3
            classreg.learning.paramoptim.err('NarginNonEnsemble');
        else
            Predictors = varargin{1};
            Response = varargin{2};
            BOInfo = classreg.learning.paramoptim.BayesoptInfo.makeBayesoptInfo(FitFunctionName, ...
                Predictors, Response, {});
        end
    otherwise
        classreg.learning.paramoptim.err('UnknownFitFcn', FitFunctionName);
end
VariableDescriptions = BOInfo.AllVariableDescriptions;
end
