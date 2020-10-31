classdef ClassificationLinear < ...
        classreg.learning.classif.ClassificationModel & classreg.learning.Linear
%ClassificationLinear Linear model for classification.
%   ClassificationLinear is a linear model for classification with one or
%   two classes. This model can predict responses for new data.
%
%   ClassificationLinear properties:
%       PredictorNames         - Names of predictors used for this model.
%       ExpandedPredictorNames - Names of expanded predictors.
%       ResponseName           - Name of the response variable.
%       ClassNames             - Names of classes in Y.
%       Cost                   - Misclassification costs.
%       Prior                  - Prior class probabilities.
%       ScoreTransform         - Transformation applied to predicted classification scores.
%       Learner                - Learned model, 'svm' or 'logistic'.
%       Beta                   - Linear coefficients.
%       Bias                   - Bias term.
%       FittedLoss             - Fitted loss function, 'hinge' or 'logit'.
%       Lambda                 - Regularization strength.
%       Regularization         - Type of regularization, L1 or L2.
%
%   ClassificationLinear methods:
%       edge                  - Classification edge.
%       loss                  - Classification loss.
%       margin                - Classification margins.
%       predict               - Predict responses of this model.
%       selectModels          - Select a subset of fitted regularized models.

%   Copyright 2015-2017 The MathWorks, Inc.
    
    methods(Hidden=true)
        function this = ClassificationLinear(...
                dataSummary,classSummary,scoreTransform)
            % Protect against being called by the user
            if ~isstruct(dataSummary)
                error(message('stats:ClassificationLinear:ClassificationLinear:DoNotUseConstructor'));
            end
            
            this = this@classreg.learning.classif.ClassificationModel(...
                dataSummary,classSummary,scoreTransform,[]);
            this = this@classreg.learning.Linear;
        end
        
        function cmp = compact(this)
            cmp = this;
        end
        
        function compareHoldout(~,varargin)
            error(message('stats:ClassificationLinear:compareHoldout:DoNotUseCompareHoldout'));
        end
    end
    
    
    methods(Access=protected)
        function cl = getContinuousLoss(this)
            cl = [];            
            lossfun = this.Impl.LossFunction;
            switch lossfun
                case 'logit'
                    if     isequal(this.PrivScoreTransform,@classreg.learning.transform.identity)
                        cl = @classreg.learning.loss.logit;
                    elseif isequal(this.PrivScoreTransform,@classreg.learning.transform.logit)
                        cl = @classreg.learning.loss.quadratic;
                    end
                    
                case 'hinge'
                    if isequal(this.PrivScoreTransform,@classreg.learning.transform.identity)
                        cl = @classreg.learning.loss.hinge;
                    end
            end
        end
        
        function s = propsForDisp(this,s)
            s = propsForDisp@classreg.learning.classif.ClassificationModel(this,s);
            s = propsForDisp@classreg.learning.Linear(this,s);
            s = rmfield(s,'CategoricalPredictors');
        end
        
        function S = score(this,X,obsInRows)
            S = score(this.Impl,X,true,obsInRows);
        end
    end
    
    
    methods
        function [labels,scores] = predict(this,X,varargin)            
        %PREDICT Predict responses of the model.
        %   [LABEL,SCORE]=PREDICT(MODEL,X) returns predicted class labels and
        %   scores for linear model MODEL and predictors X. Pass X as a matrix with
        %   P columns, where P is the number of predictors used for training this
        %   model. Classification labels LABEL are an N-by-L array of the same type
        %   as Y used for training, where N is the number of observations (rows in
        %   X) and L is the number of values of the regularization parameter saved
        %   in the Lambda property. Scores SCORE are an N-by-K-by-L numeric matrix
        %   for N observations, K classes and L values of Lambda. The predicted
        %   label is assigned to the class with the largest score.
        %
        %   [LABEL,SCORE]=(MODEL,X,'PARAM1',val1,'PARAM2',val2,...) specifies
        %   optional parameter name/value pairs:
        %       'ObservationsIn'    - String specifying the data orientation,
        %                             either 'rows' or 'columns'. Default: 'rows'
        %                           NOTE: Passing observations in columns can
        %                                 significantly speed up prediction.
        %
        %   See also ClassificationLinear, Lambda.
            [varargin{:}] = convertStringsToChars(varargin{:});
            % Handle input data such as "tall" requiring a special adapter
            adapter = classreg.learning.internal.makeClassificationModelAdapter(this,X,varargin{:});
            if ~isempty(adapter)            
                [labels,scores] = predict(adapter,X,varargin{:});
                return
            end
            
            if ~istall(X)
               internal.stats.checkSupportedNumeric('X',X,false,true);
            end
            
            % Detect the orientation
            obsIn = internal.stats.parseArgs({'observationsin'},{'rows'},varargin{:});
            obsIn = validatestring(obsIn,{'rows' 'columns'},...
                'classreg.learning.internal.orientX','ObservationsIn');
            obsInRows = strcmp(obsIn,'rows');

            % Predictions for empty X
            if isempty(X)
                D = numel(this.PredictorNames);
                if obsInRows
                    Dpassed = size(X,2);
                    str = getString(message('stats:classreg:learning:classif:ClassificationModel:predictEmptyX:columns'));
                else
                    Dpassed = size(X,1);
                    str = getString(message('stats:classreg:learning:classif:ClassificationModel:predictEmptyX:rows'));
                end
                if Dpassed~=D
                    error(message('stats:classreg:learning:classif:ClassificationModel:predictEmptyX:XSizeMismatch', D, str));
                end
                labels = repmat(this.ClassNames(1,:),0,1);
                K = numel(this.ClassSummary.ClassNames);
                scores = NaN(0,K);
                return;
            end

            % Predict
            S = score(this,X,obsInRows);
            
            [N,L] = size(S);
            
            % Match the class name order
            K = numel(this.ClassSummary.ClassNames);
            [~,pos] = ismember(this.ClassSummary.NonzeroProbClasses,...
                this.ClassSummary.ClassNames);
            
            % Match scores to class names.
            scores = NaN(N,K,L,'like',S);
            for k=1:K
                scores(:,k,:) = -S;
            end
            if numel(pos)==1 % one-class learning
                scores(:,pos,:) = S;
            else             % binary learning
                scores(:,pos(2),:) = S;
            end

            prior = this.Prior;
            cost = this.Cost;
            scoreTransform = this.PrivScoreTransform;
            classnames = this.ClassNames;
            if ischar(classnames) && L>1
                classnames = cellstr(classnames);
            end
            labels = repmat(classnames(1,:),N,L);

            if L==1
                [labels,scores] = ...
                    this.LabelPredictor(classnames,prior,cost,scores,scoreTransform);
            else
                for l=1:L
                    [labels(:,l),scores(:,:,l)] = ...
                        this.LabelPredictor(classnames,prior,cost,scores(:,:,l),scoreTransform);
                end
            end
        end
                        
        function l = loss(this,X,varargin)
        %LOSS Classification error.
        %   ERR=LOSS(MODEL,X,Y) returns classification error for model MODEL computed
        %   using predictors X and true class labels Y. Pass X as a matrix of size
        %   N-by-P, where P is the number of predictors used for training this
        %   model. Y must be of the same type as MODEL.ClassNames and have N
        %   elements. ERR is a row-vector with L values, where L is the number of
        %   elements in Lambda.
        %
        %   ERR=LOSS(MODEL,X,Y,'PARAM1',val1,'PARAM2',val2,...) specifies optional
        %   parameter name/value pairs:
        %       'ObservationsIn'   - String specifying the orientation of
        %                            X, either 'rows' or 'columns'.
        %                            Default: 'rows'
        %                          NOTE: Passing observations in columns can
        %                                significantly speed up prediction.
        %       'LossFun'          - Function handle for loss, or string
        %                            representing a built-in loss function.
        %                            Available loss functions for classification:
        %                            'binodeviance', 'classiferror', 'exponential',
        %                            'hinge', 'logit', 'mincost', and 'quadratic'.
        %                            If you pass a function handle FUN, LOSS calls
        %                            it as shown below:
        %                                  FUN(C,S,W,COST)
        %                            where C is an N-by-K logical matrix for N
        %                            elements in Y and K classes in the ClassNames
        %                            property, S is an N-by-K numeric matrix, W is
        %                            a numeric vector with N elements, and COST is
        %                            a K-by-K numeric matrix. C has one true per
        %                            row for the true class. S is a matrix of
        %                            predicted scores for classes with one row per
        %                            observation, similar to SCORE output from
        %                            PREDICT. W is a vector of observation weights.
        %                            COST is a matrix of misclassification costs.
        %                            Default: 'classiferror'
        %       'Weights'          - Vector of observation weights. By default the
        %                            weight of every observation is set to 1. The
        %                            length of this vector must be equal to the
        %                            number of columns in X.
        %
        %   See also ClassificationLinear, predict, Lambda.  
            [varargin{:}] = convertStringsToChars(varargin{:});
            % Handle input data such as "tall" requiring a special adapter
            adapter = classreg.learning.internal.makeClassificationModelAdapter(this,X,varargin{:});
            if ~isempty(adapter)            
                l = loss(adapter,X,varargin{:});
                return
            end
            
            internal.stats.checkSupportedNumeric('X',X,false,true);
            l = loss@classreg.learning.classif.ClassificationModel(this,X,varargin{:});
        end
        
        function m = margin(this,X,varargin)
        %MARGIN Classification margins.
        %   M=MARGIN(MODEL,X,Y) returns classification margins obtained by MODEL
        %   for predictors X and class labels Y. Pass X as a matrix of size N-by-P,
        %   where P is the number of predictors used for training this model. Y
        %   must be of the same type as MODEL.ClassNames and have N elements.
        %   Classification margin is the difference between classification score
        %   for the true class and maximal classification score for the false
        %   classes. The returned M is a an N-by-L matrix for N observations and L
        %   values of the regularization parameter Lambda.
        %
        %   M=MARGIN(MODEL,X,Y,'PARAM1',val1,'PARAM2',val2,...) specifies optional
        %   parameter name/value pairs:
        %       'ObservationsIn'   - String specifying the orientation of
        %                            X, either 'rows' or 'columns'.
        %                            Default: 'rows'
        %                          NOTE: Passing observations in columns can
        %                                significantly speed up prediction.
        %
        %   See also ClassificationLinear, predict, Lambda.
            [varargin{:}] = convertStringsToChars(varargin{:});
            % Handle input data such as "tall" requiring a special adapter
            adapter = classreg.learning.internal.makeClassificationModelAdapter(this,X,varargin{:});
            if ~isempty(adapter)            
                m = slice(adapter,@this.margin,X,varargin{:});
                return
            end
            
            internal.stats.checkSupportedNumeric('X',X,false,true);
            m = margin@classreg.learning.classif.ClassificationModel(this,X,varargin{:});
        end
        
        function e = edge(this,X,varargin)
        %EDGE Classification edge.
        %   E=EDGE(MODEL,X,Y) returns classification edge obtained by MODEL for
        %   predictors X and class labels Y. Pass X as a matrix of size N-by-P,
        %   where P is the number of predictors used for training this model. Y
        %   must be of the same type as MODEL.ClassNames and have N elements. E is
        %   a row-vector with L values, where L is the number of elements in
        %   Lambda. Classification edge is classification margin averaged over the
        %   entire data.
        %
        %   E=EDGE(MODEL,X,Y,'PARAM1',val1,'PARAM2',val2,...) specifies optional
        %   parameter name/value pairs:
        %       'ObservationsIn'   - String specifying the orientation of
        %                            X, either 'rows' or 'columns'.
        %                            Default: 'rows'
        %                          NOTE: Passing observations in columns can
        %                                significantly speed up prediction.
        %       'Weights'          - Observation weights, a numeric vector of length
        %                            size(X,1). By default, all observation weights
        %                            are set to 1. If you supply weights, EDGE
        %                            computes weighted classification edge. 
        %
        %   See also ClassificationLinear, margin, Lambda.
            [varargin{:}] = convertStringsToChars(varargin{:});
            % Handle input data such as "tall" requiring a special adapter
            adapter = classreg.learning.internal.makeClassificationModelAdapter(this,X,varargin{:});
            if ~isempty(adapter)            
                e = edge(adapter,X,varargin{:});
                return
            end

            internal.stats.checkSupportedNumeric('X',X,false,true);
            e = edge@classreg.learning.classif.ClassificationModel(this,X,varargin{:});
        end
    end
    
    
    methods(Hidden)
        function s = toStruct(this)
            % Convert to a struct for codegen.
            
            warnState  = warning('query','all');
            warning('off','MATLAB:structOnObject');
            cleanupObj = onCleanup(@() warning(warnState));
            

            fh = functions(this.PrivScoreTransform);
            if strcmpi(fh.type,'anonymous')
            error(message('stats:classreg:learning:coderutils:classifToStruct:AnonymousFunctionsNotSupported','Score Transform'));
            end
             
            % test provided scoreTransform
            try
                classreg.learning.internal.convertScoreTransform(this.PrivScoreTransform,'handle',numel(this.ClassSummary.ClassNames));    
            catch me
                rethrow(me);
            end
            
            % convert common properties to struct
            s = classreg.learning.coderutils.classifToStruct(this);
            s.ScoreTransformFull = s.ScoreTransform;
            scoretransformfull = strsplit(s.ScoreTransform,'.');
            scoretransform = scoretransformfull{end};
            s.ScoreTransform = scoretransform;
            
            % decide whether scoreTransform is a user-defined function or
            % not
            transFcn = ['classreg.learning.transform.' s.ScoreTransform];
            transFcnCG = ['classreg.learning.coder.transform.' s.ScoreTransform];
            if isempty(which(transFcn)) || isempty(which(transFcnCG))
                s.CustomScoreTransform = true;
            else
                s.CustomScoreTransform = false;
            end
         
            % Support only scalar lambda
            if ~isscalar(this.Lambda)
                error(message('stats:ClassificationLinear:toStruct:NonScalarLambda'));
            end
            
            % save the path to the fromStruct method
            s.FromStructFcn = 'ClassificationLinear.fromStruct';
            
            % learner char vector
            s.Learner = this.Learner;
            
            % model params
            s.ModelParams = classreg.learning.coderutils.linearParamsToCoderStruct(...
                this.ModelParams);
            
            % impl
            s.Impl = toStruct(this.Impl);
        end
    end
    
    
    methods(Static,Hidden)
        function temp = template(varargin)
            classreg.learning.FitTemplate.catchType(varargin{:});
            temp = classreg.learning.FitTemplate.make('Linear',...
                'type','classification',varargin{:});
        end
        
        function [varargout] = fit(X,Y,varargin)
            temp = ClassificationLinear.template(varargin{:});
            [varargout{1:nargout}] = fit(temp,X,Y);
        end
        
        function obj = fromStruct(s)
            % Make a Linear object from a codegen struct.
            
            % check for 2016b compatibility
            if isfield(s,'ScoreTransformFull')
                s.ScoreTransform = s.ScoreTransformFull;
            end
            
            s = classreg.learning.coderutils.structToClassif(s);
                        
            % Make an object
            obj = ClassificationLinear(s.DataSummary,s.ClassSummary,s.ScoreTransform);
        
            % Score handling
            if isempty(s.ScoreType)
                obj.ScoreType         = 'none';
            else
                obj.ScoreType         = s.ScoreType;
            end

            obj.DefaultLoss       = s.DefaultLoss;
            obj.LabelPredictor    = s.LabelPredictor;
            obj.DefaultScoreType  = s.DefaultScoreType;
            
            % Learner
            obj.Learner = s.Learner;
            
            % Model params
            obj.ModelParams = classreg.learning.coderutils.coderStructToLinearParams(s.ModelParams);
            
            % implementation
            obj.Impl = classreg.learning.impl.LinearImpl.fromStruct(s.Impl);            
        end

        
        function obj = makebeta(beta,bias,modelParams,dataSummary,classSummary,fitinfo,scoreTransform)
            % Makes a ClassificationLinear object without fitting by
            % feeding model parameters (beta and bias) and input model
            % parameters (modelParams)
           
            if isempty(scoreTransform)
                switch lower(modelParams.LossFunction)
                    case 'hinge'
                        scoreTransform = @classreg.learning.transform.identity;
                    case 'logit'
                        scoreTransform = @classreg.learning.transform.logit;
                end
            end
            
            obj = ClassificationLinear(dataSummary,classSummary,scoreTransform);
            
            obj.DefaultLoss = @classreg.learning.loss.classiferror;
            obj.LabelPredictor = @classreg.learning.classif.ClassificationModel.maxScore;
            obj.DefaultScoreType = 'inf';
            
            switch lower(modelParams.LossFunction)
                case 'hinge'
                    obj.Learner = 'svm';
                case 'logit'
                    obj.Learner = 'logistic';
                    if isequal(obj.PrivScoreTransform,@classreg.learning.transform.identity)
                        obj.ScoreTransform = 'logit';
                        obj.ScoreType = 'probability';
                    end
            end
            
            obj.ModelParams = modelParams;
            
            obj.Impl = classreg.learning.impl.LinearImpl.makeNoFit(modelParams,beta(:),bias,fitinfo);

        end
        
        function [obj,fitInfo] = fitClassificationLinear(...
                X,Y,W,modelParams,dataSummary,classSummary,scoreTransform)
            obj = ClassificationLinear(dataSummary,classSummary,scoreTransform);
            
            modelParams = fillIfNeeded(modelParams,X,Y,W,dataSummary,classSummary);
                        
            lossfun = modelParams.LossFunction;
            
            obj.DefaultLoss = @classreg.learning.loss.classiferror;
            obj.LabelPredictor = @classreg.learning.classif.ClassificationModel.maxScore;
            obj.DefaultScoreType = 'inf';
           
            switch lower(lossfun)
                case 'hinge'
                    obj.Learner = 'svm';
                    
                case 'logit'
                    obj.Learner = 'logistic';
                    if isequal(obj.PrivScoreTransform,@classreg.learning.transform.identity)
                        obj.ScoreTransform = 'logit';
                        obj.ScoreType = 'probability';
                    end
                    
            end
            
            % Map classes to -1 and +1
            gidx = grp2idx(Y,obj.ClassSummary.NonzeroProbClasses);
            if any(gidx==2)
                doclass = 2;
                gidx(gidx==1) = -1;
                gidx(gidx==2) = +1;
            else
                doclass = 1;
            end
            
            valgidx = [];
            if ~isempty(modelParams.ValidationY)
                valgidx = grp2idx(...
                    classreg.learning.internal.ClassLabel(modelParams.ValidationY),...
                    obj.ClassSummary.NonzeroProbClasses);
                if any(valgidx==2)
                    valgidx(valgidx==1) = -1;
                    valgidx(valgidx==2) =  1;
                end
            end
            
            lambda = modelParams.Lambda;
            if strcmp(lambda,'auto')
                lambda = 1/numel(gidx);
            end

            obj.Impl = classreg.learning.impl.LinearImpl.make(doclass,...
                modelParams.InitialBeta,modelParams.InitialBias,...
                X,gidx,W,lossfun,...
                strcmp(modelParams.Regularization,'ridge'),...
                lambda,...
                modelParams.PassLimit,...
                modelParams.BatchLimit,...
                modelParams.NumCheckConvergence,...
                modelParams.BatchIndex,...
                modelParams.BatchSize,...
                modelParams.Solver,...
                modelParams.BetaTolerance,...
                modelParams.GradientTolerance,...
                modelParams.DeltaGradientTolerance,...
                modelParams.LearnRate,...
                modelParams.OptimizeLearnRate,...
                modelParams.ValidationX,valgidx,modelParams.ValidationW,...
                modelParams.IterationLimit,...
                modelParams.TruncationPeriod,...
                modelParams.FitBias,...
                modelParams.PostFitBias,...
                [],... % epsilon
                modelParams.HessianHistorySize,...
                modelParams.LineSearch,...
                0, ... % consensus strength
                modelParams.Stream,...
                modelParams.VerbosityLevel);
            
            modelParams = toStruct(modelParams);
            
            modelParams = rmfield(modelParams,'ValidationX');
            modelParams = rmfield(modelParams,'ValidationY');
            modelParams = rmfield(modelParams,'ValidationW');
            
            obj.ModelParams = modelParams;
            
            fitInfo                 = obj.Impl.FitInfo;
            fitInfo.Solver          = obj.Impl.Solver;
        end
        
        
        function [X,Y,W,dataSummary,classSummary,scoreTransform] = ...
                prepareData(X,Y,varargin)
            
            % Process input args
            args = {'classnames' 'cost' 'prior' 'scoretransform'};
            defs = {          []     []      []               []};
            [userClassNames,cost,prior,transformer,~,crArgs] = ...
                internal.stats.parseArgs(args,defs,varargin{:});
            
            % Get class names before any rows might be removed
            allClassNames = levels(classreg.learning.internal.ClassLabel(Y));
            if isempty(allClassNames)
                error(message('stats:classreg:learning:classif:FullClassificationModel:prepareData:EmptyClassNames'));
            end
            
            % Pre-process
            [X,Y,W,dataSummary] = classreg.learning.Linear.prepareDataCR(...
                X,classreg.learning.internal.ClassLabel(Y),crArgs{:});
            
            % Process class names
            [X,Y,W,userClassNames,nonzeroClassNames,dataSummary.RowsUsed] = ...
                classreg.learning.classif.FullClassificationModel.processClassNames(...
                X,Y,W,userClassNames,allClassNames,...
                dataSummary.RowsUsed,dataSummary.ObservationsInRows);
            internal.stats.checkSupportedNumeric('Weights',W,true);
            
            % Sort nonzeroClassNames to make sure -1 corresponds to 1st
            % class and +1 corresponds to 2nd class passed by the user.
            [~,loc] = ismember(userClassNames,nonzeroClassNames);
            loc(loc==0) = [];
            nonzeroClassNames = nonzeroClassNames(loc);
            
            % Remove missing values
            if any(ismissing(Y))
                warning(message('stats:ClassificationLinear:prepareData:YwithMissingValues'));
            end
            [X,Y,W,dataSummary.RowsUsed] = ...
                classreg.learning.classif.FullClassificationModel.removeMissingVals(...
                X,Y,W,dataSummary.RowsUsed,dataSummary.ObservationsInRows);
            
            % Get matrix of class weights
            C = classreg.learning.internal.classCount(nonzeroClassNames,Y);
            WC = bsxfun(@times,C,W);
            Wj = sum(WC,1);
            
            % Check prior
            prior = classreg.learning.classif.FullClassificationModel.processPrior(...
                prior,Wj,userClassNames,nonzeroClassNames);
            
            % Get costs
            cost = classreg.learning.classif.FullClassificationModel.processCost(...
                cost,prior,userClassNames,nonzeroClassNames);
            
            % Remove observations for classes with zero prior probabilities
            [X,Y,~,WC,Wj,prior,cost,nonzeroClassNames,dataSummary.RowsUsed] = ...
                ClassificationTree.removeZeroPriorAndCost(...
                X,Y,C,WC,Wj,prior,cost,nonzeroClassNames,...
                dataSummary.RowsUsed,dataSummary.ObservationsInRows);
            
            % Apply the average cost correction for 2 classes and set the
            % cost to the default value.
            if numel(nonzeroClassNames)>1
                prior = prior.*sum(cost,2)';
                cost = ones(2) - eye(2);
            end
            
            % Normalize priors in such a way that the priors in present
            % classes add up to one.  Normalize weights to add up to the
            % prior in the respective class.
            prior = prior/sum(prior);
            W = sum(bsxfun(@times,WC,prior./Wj),2);
            
            % Put processed values into summary structure
            classSummary = ...
                classreg.learning.classif.FullClassificationModel.makeClassSummary(...
                userClassNames,nonzeroClassNames,prior,cost);
            
            % Only binary and one-class learning is supported
            K = numel(classSummary.NonzeroProbClasses);
            if K>2
                error(message('stats:ClassificationLinear:prepareData:DoNotPassMoreThanTwoClasses'));
            end
            
            % Make output score transformation
            scoreTransform = ...
                classreg.learning.classif.FullClassificationModel.processScoreTransform(transformer);
        end

        function name = matlabCodegenRedirect(~)
            name = 'classreg.learning.coder.classif.ClassificationLinear';
        end
    end
    
end
