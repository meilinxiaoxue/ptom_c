function [h,p,loss1,loss2] = testckfold(c1,c2,X1,X2,varargin)
%TESTCKFOLD Compare accuracies of two classifiers by repeated cross-validation.
%   H=TESTCKFOLD(C1,C2,X1,X2,Y) performs a cross-validation test of the
%   null hypothesis: two classifiers, C1 and C2, have equal accuracy for
%   predictors X1 and X2 and class labels Y. Classifier C1 is applied to
%   X1, and classifier C2 is applied to X2. H indicates the result of the
%   hypothesis test:
%       H = 0 => Do not reject the null hypothesis at the 5% significance level.
%       H = 1 => Reject the null hypothesis at the 5% significance level.
%
%   Pass C1 and C2 as templates returned by one of the following functions:
%   templateDiscriminant, templateECOC, templateEnsemble, templateKNN,
%   templateNaiveBayes, templateSVM, and templateTree. Alternatively, you
%   can pass C1 or C2 as classification models returned by one of the
%   following functions: fitcdiscr, fitcecoc, fitensemble, fitcknn, fitcnb,
%   fitcsvm, and fitctree.
%
%   Pass X1 and X2 as tables or matrices having N rows and containing
%   predictor values. You must either pass both X1 and X2 as tables or pass
%   both X1 and X2 as matrices. Y can be a categorical array, logical
%   vector, numeric vector, string array or cell array of character vectors. 
%   If X1 and X2 are tables, then Y can be the name of a variable that appears in
%   both X1 and X2. This variable is used as a response for both C1 and C2,
%   and is not used as a predictor.
%
%   If both C1 and C2 are full classifiers with the same ResponseName, and
%   if this response appears in table X1 and X2 with the same value, then Y
%   can be omitted and it is taken from the tables.
%
%   TESTCKFOLD performs an R-by-K test by dividing X1, X2 and Y in K partitions,
%   training classifiers on each set of K-1 partitions and evaluating their
%   accuracies on the held-out partition. The 1st classifier is trained on
%   partitions of X1, and the 2nd classifier is trained on partitions of X2.
%   TESTCKFOLD repeats this procedure R times to form a Student t or F statistic
%   with an appropriate number of degrees of freedom. See the 'Test' parameter
%   for more detail.
%
%   [H,P,E1,E2]=TESTCKFOLD(C1,C2,X1,X2,Y) also returns the p-value P of the test,
%   and two R-by-K matrices, E1 and E2, holding classification errors for the
%   first and second classifier.
%
%   [...]=TESTCKFOLD(C1,C2,X1,X2,Y,'PARAM1',val1,'PARAM2',val2,...) specifies
%   one or more of the following name/value pairs:
%       'Alpha'        - Significance level, a positive scalar. Default 0.05
%       'Alternative'  - Character vector indicating the alternative hypothesis:
%                         'unequal'
%                               H0: "C1 and C2 have equal accuracy" vs.
%                               H1: "C1 and C2 have unequal accuracy".
%                         'less'
%                               H0: "C1 is at least as accurate as C2" vs.
%                               H1: "C1 is less accurate than C2".
%                         'greater'
%                               H0: "C1 is at most as accurate as C2" vs.
%                               H1: "C1 is more accurate than C2".
%                        Default: 'unequal'
%       'X1CategoricalPredictors' - List of categorical predictors in X1.
%                        Pass 'X1CategoricalPredictors' as one of:
%                          * A numeric vector with indices between 1 and P,
%                            where P is the number of columns of X or
%                            variables in TBL.
%                          * A logical vector of length P, where a true
%                            entry means that the corresponding column of X
%                            or T is a categorical variable. 
%                          * 'all', meaning all predictors are categorical.
%                          * A string array or cell array of character vectors,
%                             where each element in the array is the name of a
%                            predictor variable. The names must match
%                            entries in 'PredictorNames' values.
%                        Default: for a matrix input X1, no categorical
%                        predictors; for a table X1, predictors are
%                        treated as categorical if they are cell arrays of
%                        character vectors, logical, or categorical.
%       'X2CategoricalPredictors' - List of categorical predictors in X2,
%                        as described for 'X1CategoricalPredictors'.
%       'ClassNames'   - Array of class names. Use the data type that
%                        exists in Y. You can use this argument to order
%                        the classes or select a subset of classes for
%                        training. Default: All class names in Y.
%       'Cost'         - Square matrix, where COST(I,J) is the
%                        cost of classifying a point into class J if its
%                        true class is I. Alternatively, COST can be a
%                        structure S with two fields: S.ClassificationCosts
%                        containing the cost matrix C, and S.ClassNames
%                        containing the class names and defining the
%                        ordering of classes used for the rows and columns
%                        of the cost matrix. For S.ClassNames use the data
%                        type that exists in Y. Default: COST(I,J)=1 if
%                        I~=J, and COST(I,J)=0 if I=J.
%       'LossFun'      - Function handle for loss, or character vector
%                        representing a built-in loss function. Available
%                        loss functions are: 'binodeviance',
%                        'classiferror', 'exponential', 'hinge', 'logit',
%                        and 'quadratic'. If you pass a function handle
%                        FUN, loss calls it as shown below:
%                              FUN(C,S,W,COST)
%                        where C is an N-by-K logical matrix for N rows in
%                        X and K classes in the ClassNames property, S is
%                        an N-by-K numeric matrix, W is a numeric vector
%                        with N elements, and COST is a K-by-K numeric
%                        matrix. C has one true per row for the true class.
%                        S is a matrix of classification scores for classes
%                        with one row per observation. W is a vector of
%                        observation weights. COST is a matrix of
%                        misclassification costs. If you pass 'LossFun',
%                        TESTCKFOLD returns values of the specified loss
%                        for E1 and E2. Default: 'classiferror'
%       'Options'      - A struct that contains options specifying whether
%                        to use parallel computation when training binary
%                        learners. This argument can be created by a call
%                        to STATSET. TESTCKFOLD uses the following fields:
%                            'UseParallel'
%                            'UseSubstreams'
%                            'Streams'
%                        For information on these fields see PARALLELSTATS.
%
%                        NOTE: If 'UseParallel' is TRUE and 'UseSubstreams'
%                        is FALSE, then the length of 'Streams' must equal
%                        the number of workers used by TESTCKFOLD. If a
%                        parallel pool is already open, this will be the
%                        size of the parallel pool. If a parallel pool is
%                        not already open, then MATLAB may try to open a
%                        pool for you (depending on your installation and
%                        preferences). To ensure more predictable results,
%                        it is best to use the PARPOOL command and
%                        explicitly create a parallel pool prior to
%                        invoking TESTCKFOLD with 'UseParallel' set to TRUE.
%       'Prior'        - Prior probabilities for each class. Specify as one
%                        of: 
%                         * A character vector:
%                           - 'empirical' determines class probabilities
%                             from class frequencies in Y
%                           - 'uniform' sets all class probabilities equal
%                         * A vector (one scalar value for each class)
%                         * A structure S with two fields: S.ClassProbs
%                           containing a vector of class probabilities, and
%                           S.ClassNames containing the class names and
%                           defining the ordering of classes used for the
%                           elements of this vector.
%                        If you pass numeric values, they are normalized
%                        to add up to one. If you pass 'Prior' as a numeric
%                        vector, the order of elements matches the order
%                        defined by 'ClassNames'. Default: 'empirical'
%       'Test'         - Character vector, one of: '5x2t', '5x2F' or
%                        '10x10t'. If '5x2t', TESTCKFOLD runs the
%                        evaluation procedure 5 times with 2 partitions and
%                        uses a Student t statistic with 5 degrees of
%                        freedom. If '5x2F', TESTCKFOLD runs the evaluation
%                        procedure 5 times with 2 partitions and uses an F
%                        statistic with 10 and 5 degrees of freedom. If
%                        '10x10t', TESTCKFOLD runs the evaluation procedure
%                        10 times with 10 partitions and uses a Student t
%                        statistic with 10 degrees of freedom. Default:
%                        '5x2F'
%       'Verbose'      - Verbosity level, a non-negative integer. Set above
%                        0 to see diagnostic messages. Default: 0
%       'Weights'      - Vector of observation weights, one weight per
%                        observation. Classifiers normalize the weights to
%                        add up to the value of the prior probability in
%                        the respective class. Default: ones(size(X1,1),1)
%
% Example 1: Compare SVM and bagged trees on ionosphere data. Observe that SVM
%            gives a smaller error on average, but this improvement is not
%            statistically significant.
%   load ionosphere;
%   c1 = templateSVM('Standardize',true,'KernelFunction','RBF','KernelScale','auto');
%   c2 = templateEnsemble('Bag',200,'Tree','Type','classification');
%   rng('default'); % set the RNG seed for reproducibility
%   [h,p,err1,err2] = testckfold(c1,c2,X,X,Y,'Verbose',1)
%   mean(err1(:)-err2(:)) % mean error difference between the two models
%
% Example 2: Test if removing the last two predictors from the Fisher iris data
%            affects the accuracy of classification by linear SVM. Use the
%            one-vs-one approach to train a multiclass SVM model. Execute in
%            parallel.
%   load fisheriris;
%   c = templateECOC;
%   [h,p] = testckfold(c,c,meas,meas(:,1:2),species,'Test','10x10t',...
%       'Options',statset('UseParallel',true))
%
%   See also testcholdout, templateDiscriminant, templateECOC, templateEnsemble,
%   templateKNN, templateNaiveBayes, templateSVM, templateTree, parallelstats,
%   statset.

%   Copyright 2014-2017 The MathWorks, Inc.

% C1 must be either FitTemplate or FullClassificationModel
if nargin > 4
    [varargin{:}] = convertStringsToChars(varargin{:});
end

full1 = [];
if     isa(c1,'classreg.learning.FitTemplate')
    c1 = fillIfNeeded(c1,'classification');
elseif isa(c1,'classreg.learning.classif.FullClassificationModel')
    full1 = c1;
    c1 = classreg.learning.FitTemplate.makeFromModelParams(c1.ModelParameters);
else
    error(message('stats:testckfold:BadClassifierObjectType','C1'));
end

% C2 must be either FitTemplate or FullClassificationModel
full2 = [];
if     isa(c2,'classreg.learning.FitTemplate')
    c2 = fillIfNeeded(c2,'classification');
elseif isa(c2,'classreg.learning.classif.FullClassificationModel')
    full2 = c2;
    c2 = classreg.learning.FitTemplate.makeFromModelParams(c2.ModelParameters);
else
    error(message('stats:testckfold:BadClassifierObjectType','C2'));
end

% X1 and X2 must be either both matrices or both tables
ntable = sum(istable(X1) + istable(X2));
if ntable==1
    error(message('stats:testckfold:IncompatibleXTypes'));
end
dotable = ntable > 0;

% If X1 and X2 are matrices, warn that the CategoricalPredictors property
% of the full object does not apply to X1 and X2. If X1 and X2 are tables,
% it is assumed that categorical predictors are defined by the tables. No
% warning is thrown in that case.
if ~dotable
    if ~isempty(full1)
        if ~isempty(full1.CategoricalPredictors)
            warning(message('stats:testckfold:CatPredsInFirstClassifier'));
        end
    end
    if ~isempty(full2)
        if ~isempty(full2.CategoricalPredictors)
            warning(message('stats:testckfold:CatPredsInSecondClassifier'));
        end
    end
end

yname = '';
argsin = varargin;

if     dotable && ~isempty(full1) && ~isempty(full2)
    % Both are tables and we have two classifiers, Y must be inferred
    if ~strcmp(full1.ResponseName,full2.ResponseName)
        error(message('stats:classreg:learning:classif:ClassificationModel:compareHoldout:DifferentResponseNames'));
    end
    
    Y           = classreg.learning.internal.inferResponse(full1.ResponseName,X1,varargin{:});
    [Y2,argsin] = classreg.learning.internal.inferResponse(full2.ResponseName,X2,varargin{:});
    
    if ~isequal(Y,Y2)
        error(message('stats:classreg:learning:classif:ClassificationModel:compareHoldout:DifferentResponseValues'));
    end
    
    yname = full1.ResponseName;
    
elseif isempty(argsin)
    error(message('MATLAB:minrhs'));
    
else
    % Y is required, not inferred from the model
    Y = argsin{1};
    argsin(1) = [];
    if internal.stats.isString(Y)
        if mod(length(argsin),2)==1
            % This is an invalid call. Probably the response has been omitted,
            % and a later attempt to use Y as the response will fail with an
            % unhelpful message. Supply a helpful one instead.
            error(message('stats:testckfold:MissingResponse'));
            
        elseif ~istable(X1) || ~istable(X2)
            error(message('stats:testckfold:XNotTableForStringY'));
            
        else
            % Try to get the response from the tables
            try
                yname = Y;
                Y  = X1.(yname);
                Y2 = X2.(yname);
            catch me
                error(message('stats:classreg:learning:internal:utils:InvalidResponse',yname));
            end
            if ~isequal(Y,Y2)
                error(message('stats:classreg:learning:classif:ClassificationModel:compareHoldout:DifferentResponseValues'));
            end
        end
    end
end

% Convert Y to ClassLabel.
Y = classreg.learning.internal.ClassLabel(Y);
nonzeroClassNames = levels(Y);

% For X and Y, check the size only. The rest will be checked by classifiers.
N1 = size(X1,1);
if numel(Y)~=N1
    error(message('stats:testckfold:PredictorMatrixSizeMismatch','X1'));
end

N2 = size(X2,1);
if N1~=N2
    error(message('stats:testckfold:PredictorMatrixSizeMismatch','X2'));
end

% Decode input args
args = {'classnames' 'alpha' 'lossfun' 'alternative' 'test' 'verbose' ...
    'x1categoricalpredictors' 'x2categoricalpredictors' 'prior' 'cost' ...
    'weights' 'options'};
defs = {          ''    0.05        ''     'unequal' '5x2F'         0 ...
                           []                        []      []     [] ...
           []        []};       
[userClassNames,alpha,lossfun,alternative,mode,verbose,cat1,cat2,prior,cost,...
    W,paropts,~,extraArgs] = internal.stats.parseArgs(args,defs,argsin{:});

% Error if categorical predictors are passed through
% 'CategoricalPredictors'
cat = internal.stats.parseArgs({'CategoricalPredictors'},{[]},extraArgs{:});
if ~isempty(cat)
    error(message('stats:testckfold:CatPredsNotSupported'));
end

% Process weights
if isempty(W)
    W = ones(N1,1);
end
if numel(W)~=N1
    error(message('stats:testckfold:WeightSizeMismatch',N1));
end
W = W(:);

% Process classes
if isempty(userClassNames)
    % If the user has not passed any class names, use those found in the array
    % of true class labels.
    userClassNames = nonzeroClassNames;
else
    userClassNames = classreg.learning.internal.ClassLabel(userClassNames);
    
    % If none of the class names passed by the user is found in the existing
    % class names, error.
    missingC = ~ismember(userClassNames,nonzeroClassNames);
    if all(missingC)
        error(message('stats:classreg:learning:classif:FullClassificationModel:prepareData:ClassNamesNotFound'));
    end
    
    % If the user passed a subset of classes found in the data, remove labels
    % for classes not included in that subset.
    missingC = ~ismember(nonzeroClassNames,userClassNames);
    if any(missingC)
        unmatchedY = ismember(Y,nonzeroClassNames(missingC));
        Y(unmatchedY)    = [];
        X1(unmatchedY,:) = [];
        X2(unmatchedY,:) = [];
        W(unmatchedY)    = [];
        nonzeroClassNames(missingC) = [];
    end
end

% Get matrix of class weights
Call = classreg.learning.internal.classCount(nonzeroClassNames,Y);
WC = bsxfun(@times,Call,W);
Wj = sum(WC,1);

% Check prior
prior = classreg.learning.classif.FullClassificationModel.processPrior(...
    prior,Wj,userClassNames,nonzeroClassNames);

% Get costs
cost = classreg.learning.classif.FullClassificationModel.processCost(...
    cost,prior,userClassNames,nonzeroClassNames);

% Normalize priors in such a way that the priors in present classes add up
% to one.  Normalize weights to add up to the prior in the respective
% class.
prior = prior/sum(prior);
W = sum(bsxfun(@times,WC,prior./Wj),2);

% If the user has not passed a custom loss function, use classification error.
% Classification error is the only choice for classifiers of different types.
if isempty(lossfun)
    lossfun = 'classiferror';
end
lossfun = classreg.learning.internal.lossCheck(lossfun,'classification');

doclasserr = false;
if isequal(lossfun,@classreg.learning.loss.classiferror)
    doclasserr = true;
end
if ~doclasserr && ~strcmp(c1.Method,c2.Method)
    error(message('stats:testckfold:BadLossFun'));
end

% If a cost matrix has been passed, switch from classification error to minimal
% cost
if doclasserr && ~isempty(cost)
    lossfun = @classreg.learning.loss.mincost;
end

% Check alpha
if ~isscalar(alpha) || ~isfloat(alpha) || ~isreal(alpha) || isnan(alpha) ...
        || alpha<=0 || alpha>=1
    error(message('stats:testckfold:BadAlpha'));
end

% Determine the alternative hypothesis.
alternative = validatestring(alternative,{'unequal' 'less' 'greater'},...
    'testckfold','Alternative');

% Determine the test type. Make sure the test type and alternative are
% compatible.
mode = validatestring(mode,{'5x2t' '5x2F' '10x10t'},'testckfold','Test');

if strcmp(mode,'5x2F') && ~strcmp(alternative,'unequal')
    error(message('stats:testckfold:BadAlternativeTestCombo'));
end

% Check verbosity level.
if ~isscalar(verbose) || ~isnumeric(verbose) || ~isreal(verbose) ...
        || verbose<0 || round(verbose)~=verbose
    error(message('stats:testckfold:BadVerbose'));
end

% Process parallel options
[useParallel,RNGscheme] = ...
    internal.stats.parallel.processParallelAndStreamOptions(paropts,true);

% Set R and K
if     ismember(mode,{'5x2t' '5x2F'})
    R = 5;
    K = 2;
else
    R = 10;
    K = 10;
end


    % Function for computing loss values
    function [l1,l2] = loopBody(r,s)
        if isempty(s)
            s = RandStream.getGlobalStream;
        end
        
        if verbose>0
            fprintf('%s\n',getString(message('stats:testckfold:ReportRunProgress',r,R)));
        end
        
        cvp = cvpartition(Y,'kfold',K,s);
        
        l1 = NaN(1,K);
        l2 = NaN(1,K);

        % Loop over cross-validation folds
        for k=1:K
            if verbose>1
                fprintf('    %s\n',getString(message('stats:testckfold:ReportFoldProgress',k,K)));
            end

            % Indices for training and test
            itrain = training(cvp,k);
            itest = test(cvp,k);
            
            % Train the two models
            if isempty(yname)
                % Matrices
                m1 = fit(c1,X1(itrain,:),Y(itrain),'categoricalpredictors',cat1,...
                    'cost',cost,'weights',W(itrain),extraArgs{:});
                m2 = fit(c2,X2(itrain,:),Y(itrain),'categoricalpredictors',cat2,...
                    'cost',cost,'weights',W(itrain),extraArgs{:});
            else
                % Tables
                m1 = fit(c1,X1(itrain,:),yname,'categoricalpredictors',cat1,...
                    'cost',cost,'weights',W(itrain),extraArgs{:});
                m2 = fit(c2,X2(itrain,:),yname,'categoricalpredictors',cat2,...
                    'cost',cost,'weights',W(itrain),extraArgs{:});
            end
            
            % Get observation weights and true labels for the test data
            w = W(itest);
            y = Y(itest);
            
            if doclasserr
                % Compute classification error or misclassification cost based
                % on predicted labels. Here, we deviate from the classifier
                % objects in the classreg framework which compute classification
                % error and misclassification cost using predicted scores, not
                % labels. Using labels works best for comparing
                % classifiers, in particular if one predicts into the class
                % with largest posterior and the other one predicts into
                % the class with smallest cost.
                
                % Get predicted labels
                Yhat1 = classreg.learning.internal.ClassLabel(predict(m1,X1(itest,:)));
                Yhat2 = classreg.learning.internal.ClassLabel(predict(m2,X2(itest,:)));
                
                % Get logical matrix C of size N-by-L for N observations and L
                % classes with class memberships
                C = classreg.learning.internal.classCount(nonzeroClassNames,y);
                
                % Get logical matrices for predicted class labels, similar to C.
                % Yhat1 and Yhat2 cannot have elements not found in
                % nonzeroClassNames because the two classifiers have been
                % trained on Y.
                C1 = classreg.learning.internal.classCount(nonzeroClassNames,Yhat1);
                C2 = classreg.learning.internal.classCount(nonzeroClassNames,Yhat2);

                % Record loss values.
                l1(k) = lossfun(C,C1,w,cost);
                l2(k) = lossfun(C,C2,w,cost);
            else
                % If we are not computing classification error, just use the
                % LOSS method of the classification objects to compute loss
                % values based on scores.
                
                l1(k) = loss(m1,X1(itest,:),y,'lossfun',lossfun,'weights',w);
                l2(k) = loss(m2,X2(itest,:),y,'lossfun',lossfun,'weights',w);
            end
        end
    end

% Compute loss values
[loss1,loss2] = ...
    internal.stats.parallel.smartForSliceout(R,@loopBody,useParallel,RNGscheme);

%
% Analyze computed errors.
%

delta = loss1 - loss2;

% If all loss values are equal, the classifiers are equivalent.
if all( abs(delta(:)) < 100*eps(loss1(:)+loss2(:)) )
    p = 1;
    h = false;
    return;
end

%
% Apply the chosen test.
%

switch mode
    case '5x2t'        
        mdelta_r = mean(delta,2);
        s2_r = sum(bsxfun(@minus,delta,mdelta_r).^2,2);
        s2 = sum(s2_r);
        t = delta(1,1)/sqrt(s2/5);
        
        switch alternative
            case 'unequal'
                p = 2*tcdf(-abs(t),5);
            case 'less'
                % delta has a large positive value under H1
                p = tcdf(t,5,'upper');
            case 'greater'
                % delta has a large negative value under H1
                p = tcdf(t,5);
        end
    
    case '5x2F'        
        mdelta_r = mean(delta,2);
        s2_r = sum(bsxfun(@minus,delta,mdelta_r).^2,2);
        s2 = sum(s2_r);
        F = sum(delta(:).^2)/(2*s2);
        
        p = fcdf(F,10,5,'upper'); % computed only for 'unequal' H1
    
    case '10x10t'        
        m = mean(delta(:));
        s2 = var(delta(:));
        t = m/sqrt(s2/(K+1));
        
        p = tcdf(t,K);

        switch alternative
            case 'unequal'
                p = 2*tcdf(-abs(t),K);
            case 'less'
                % delta has a large positive value under H1
                p = tcdf(t,K,'upper');
            case 'greater'
                % delta has a large negative value under H1
                p = tcdf(t,K);
        end
end

h = p<alpha;

end
