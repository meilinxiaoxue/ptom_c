classdef CompactClassificationEnsemble < ...
        classreg.learning.classif.ClassificationModel & classreg.learning.ensemble.CompactEnsemble
%CompactClassificationEnsemble Compact classification ensemble.
%   CompactClassificationEnsemble is a set of trained weak learner models.
%   It can predict ensemble response for new data by aggregating
%   predictions from its weak learners.
%
%   CompactClassificationEnsemble properties:
%       PredictorNames        - Names of predictors used for this ensemble.
%       ExpandedPredictorNames - Names of expanded predictors.
%       CategoricalPredictors - Indices of categorical predictors.
%       ResponseName          - Name of the response variable.
%       ClassNames            - Names of classes in Y.
%       Cost                  - Misclassification costs.
%       Prior                 - Prior class probabilities.
%       ScoreTransform        - Transformation applied to predicted classification scores.
%       NumTrained            - Number of trained learners in the ensemble.
%       Trained               - Trained learners.
%       TrainedWeights        - Learner weights.
%       CombineWeights        - Prescription for combining weighted learner predictions.
%       UsePredForLearner     - Use predictors for learners.
%
%   CompactClassificationEnsemble methods:
%       compareHoldout        - Compare two models using test data.
%       edge                  - Classification edge.
%       loss                  - Classification loss.
%       margin                - Classification margins.
%       predict               - Predicted response of this model.
%       predictorImportance   - Importance of predictors for this model.
%       removeLearners        - Remove learners from this ensemble.
%
%   See also ClassificationEnsemble.

%   Copyright 2010-2017 The MathWorks, Inc.


    properties(GetAccess=public,SetAccess=protected,Hidden=true)
        %DefaultScore Default score value for missing classes.
        %   If you sample observations from data for training weak learners, you
        %   can end up in a situation when one of the classes is missing from the
        %   selected subset. The learner trained on this subset cannot compute
        %   predicted scores for the missing class. In that case, this default
        %   value is returned. For all classifiers returning posterior
        %   probabilities, this default should be 0.
        DefaultScore = NaN;

        %PrivContinuousLoss Continuous loss for measuring ensemble accuracy.
        %   This property is set to a function handle under classreg.learning.loss
        %   that computes values of the loss function most appropriate for this
        %   ensemble provided ScoreTransform is 'none'.
        PrivContinuousLoss = [];
        
        %TransformToProbability Transformation from score to posterior probability.
        %   This property is a function handle under classreg.learning.transform
        %   used when the scores predicted by this ensemble need to be converted to
        %   posterior probabilities. If such a transformation is not possible,
        %   TransformToProbability is empty. This transformation applies to raw
        %   scores, that is, scores computed when ScoreTransform is 'none'.
        TransformToProbability = [];
    end
    
    methods(Access=protected)        
        function this = CompactClassificationEnsemble(...
                dataSummary,classSummary,scoreTransform,scoreType,...
                usepredforlearner,defaultScore,continuousLoss,...
                transformToProbability)
            this = this@classreg.learning.classif.ClassificationModel(...
                dataSummary,classSummary,scoreTransform,scoreType);
            this = this@classreg.learning.ensemble.CompactEnsemble(usepredforlearner);
            this.DefaultScore = defaultScore;
            this.DefaultLoss = @classreg.learning.loss.classiferror;
            this.LabelPredictor = @classreg.learning.classif.ClassificationModel.maxScore;
            this.PrivContinuousLoss = continuousLoss;
            this.TransformToProbability = transformToProbability;
        end
        
        function s = score(this,X,varargin)
            vrange = getvrange(this);
            X = classreg.learning.internal.table2PredictMatrix(X,[],[],...
                vrange,this.CategoricalPredictors,getOptionalPredictorNames(this));
            s = classreg.learning.ensemble.CompactEnsemble.aggregatePredict(...
                X,this.Impl.Combiner,this.Impl.Trained,...
                this.ClassSummary.ClassNames,this.ClassSummary.NonzeroProbClasses,...
                this.DefaultScore,'usepredforlearner',this.UsePredForLearner,varargin{:});
        end
        
        function s = propsForDisp(this,s)
            s = propsForDisp@classreg.learning.classif.ClassificationModel(this,s);
            s = propsForDisp@classreg.learning.ensemble.CompactEnsemble(this,s);
        end
        
        function scoreType = getScoreType(this)
            scoreType = getScoreType@classreg.learning.classif.ClassificationModel(this);
            if isequal(this.PrivScoreTransform,this.TransformToProbability)
                scoreType = 'probability';
            end
        end
        
        function cl = getContinuousLoss(this)
            cl = [];
            if     isequal(this.PrivScoreTransform,@classreg.learning.transform.identity)
                cl = this.PrivContinuousLoss;
            elseif isequal(this.PrivScoreTransform,this.TransformToProbability)
                cl = @classreg.learning.loss.quadratic;
            end
        end
    end
    
    methods
        function [labels,scores] = predict(this,X,varargin)
        %PREDICT Predict response of the ensemble.
        %   [LABEL,SCORE]=PREDICT(ENS,X) returns predicted class labels and scores
        %   for classification ensemble and predictors X. X must be a table if ENS
        %   was originally trained on a table, or a numeric matrix if ENS was
        %   originally trained on a matrix. If X is a table, it must contain all
        %   the predictors used for training this model. If X is a matrix, it must
        %   have P columns, where P is the number of predictors used for training.
        %   Classification labels LABEL have the same type as Y used for training.
        %   Scores SCORE are an N-by-K numeric matrix for N observations and K
        %   classes. High score value indicates that an observation likely comes
        %   from this class.
        %
        %   [LABEL,SCORE]=PREDICT(ENS,X,'PARAM1',val1,'PARAM2',val2,...) specifies
        %   optional parameter name/value pairs:
        %       'useobsforlearner' - Logical matrix of size N-by-NumTrained, where
        %                            N is the number of observations in X and
        %                            NumTrained is the number of weak learners.
        %                            This matrix specifies what learners in the
        %                            ensemble are used for what observations. By
        %                            default, all elements of this matrix are set
        %                            to true.
        %       'learners'         - Indices of weak learners in the ensemble
        %                            ranging from 1 to NumTrained. Only these
        %                            learners are used for making predictions. By
        %                            default, all learners are used.
        %
        %   See also CompactClassificationEnsemble.
            
            % Handle input data such as "tall" requiring a special adapter
            adapter = classreg.learning.internal.makeClassificationModelAdapter(this,X,varargin{:});
            if ~isempty(adapter)            
                [labels,scores] = predict(adapter,X,varargin{:});
                return
            end
            
            % Get scores from the compact class
            if isempty(X)
                if this.TableInput || istable(X)
                    vrange = getvrange(this);
                    X = classreg.learning.internal.table2PredictMatrix(X,[],[],...
                        vrange,...
                        this.CategoricalPredictors,this.PredictorNames);
                end
                [labels,scores] = predictEmptyX(this,X);
                return;
            end
            
            scores = score(this,X,varargin{:});
            N = size(scores,1);
            
            % Transform scores and find the most probable class
            scores = this.PrivScoreTransform(scores);
            notNaN = ~all(isnan(scores) | scores==this.DefaultScore,2);
            [~,cls] = max(this.Prior);
            labels = repmat(this.ClassNames(cls,:),N,1);
            [~,classNum] = max(scores(notNaN,:),[],2);
            labels(notNaN,:) = this.ClassNames(classNum,:);
        end
    
        function m = margin(this,X,varargin)
        %MARGIN Classification margins.
        %   M=MARGIN(ENS,X,Y) returns classification margins for predictors X and
        %   class labels Y. X must be a table if ENS was originally trained on a
        %   table, or a numeric matrix if ENS was originally trained on a matrix.
        %   If X is a table, it must contain all the predictors used for training
        %   this model. If X is a matrix, it must have P columns, where P is the
        %   number of predictors used for training. Y must be of the same type as
        %   ENS.ClassNames and have N elements. Y can be omitted if X is a table
        %   that includes the response variable. Classification margin is the
        %   difference between classification score for the true class and maximal
        %   classification score for the false classes. The returned M is a numeric
        %   column-vector of length size(X,1).
        %
        %   M=MARGIN(ENS,X,Y,'PARAM1',val1,'PARAM2',val2,...) specifies optional
        %   parameter name/value pairs:
        %       'useobsforlearner' - Logical matrix of size N-by-NumTrained, where
        %                            N is the number of observations in X and
        %                            NumTrained is the number of weak learners.
        %                            This matrix specifies what learners in the
        %                            ensemble are used for what observations. By
        %                            default, all elements of this matrix are set
        %                            to true.
        %       'learners'         - Indices of weak learners in the ensemble
        %                            ranging from 1 to NumTrained. Only these
        %                            learners are used for making predictions. By
        %                            default, all learners are used.
        %
        %   See also CompactClassificationEnsemble, predict.
        
            m = margin@classreg.learning.classif.ClassificationModel(this,X,varargin{:});
        end
        
        function e = edge(this,X,varargin)
        %EDGE Classification edge.
        %   E=EDGE(ENS,X,Y) returns classification edge obtained by ensemble ENS
        %   for predictors X and class labels Y. X must be a table if ENS was
        %   originally trained on a table, or a numeric matrix if ENS was
        %   originally trained on a matrix. If X is a table, it must contain all
        %   the predictors used for training this model. If X is a matrix, it must
        %   have P columns, where P is the number of predictors used for training.
        %   Classification edge is classification margin averaged over the entire
        %   data. Y must be of the same type as ENS.ClassNames and have N elements.
        %   Y can be omitted if X is a table that includes the response variable.
        %
        %   E=EDGE(ENS,X,Y,'PARAM1',val1,'PARAM2',val2,...) specifies optional
        %   parameter name/value pairs:
        %       'useobsforlearner' - Logical matrix of size N-by-NumTrained, where
        %                            N is the number of observations in X and
        %                            NumTrained is the number of weak learners.
        %                            This matrix specifies what learners in the
        %                            ensemble are used for what observations. By
        %                            default, all elements of this matrix are set
        %                            to true.
        %       'learners'         - Indices of weak learners in the ensemble
        %                            ranging from 1 to NumTrained. Only these
        %                            learners are used for making predictions. By
        %                            default, all learners are used.
        %       'mode'             - 'ensemble' (default), 'individual' or
        %                            'cumulative'. If 'ensemble', this method
        %                            returns a scalar value for the full ensemble.
        %                            If 'individual', this method returns a vector
        %                            with one element per trained learner. If
        %                            'cumulative', this method returns a vector in
        %                            which element J is obtained by using learners
        %                            1:J from the input list of learners.
        %       'weights'          - Observation weights, a numeric vector of
        %                            length size(X,1). By default, all observation
        %                            weights are set to 1. If you supply weights,
        %                            EDGE computes weighted classification edge.
        %
        %   See also CompactClassificationEnsemble, margin.
        
            % Handle input data such as "tall" requiring a special adapter
            adapter = classreg.learning.internal.makeClassificationModelAdapter(this,X,varargin{:});
            if ~isempty(adapter)            
                e = edge(adapter,X,varargin{:});
                return
            end  

            [Y,varargin] = classreg.learning.internal.inferResponse(this.ResponseName,X,varargin{:});
            N = size(X,1);
            args = {'weights'};
            defs = {ones(N,1)};
            [W,~,extraArgs] = internal.stats.parseArgs(args,defs,varargin{:});
            
            [X,C,W] = prepareDataForLoss(this,X,Y,W,[],true,true);
            e = classreg.learning.ensemble.CompactEnsemble.aggregateLoss(...
                this.NTrained,X,C,W,this.Cost,@classreg.learning.loss.classifedge,...
                this.Impl.Combiner,@classreg.learning.ensemble.CompactEnsemble.predictOneWithCache,...
                this.Impl.Trained,this.ClassSummary.ClassNames,this.ClassSummary.NonzeroProbClasses,...
                this.PrivScoreTransform,this.DefaultScore,'usepredforlearner',this.UsePredForLearner,...
                extraArgs{:});
        end
        
        function l = loss(this,X,varargin)
        %LOSS Classification error.
        %   L=LOSS(ENS,X,Y) returns classification error for ensemble ENS computed
        %   using predictors X and true class labels Y. X must be a table if ENS
        %   was originally trained on a table, or a numeric matrix if ENS was
        %   originally trained on a matrix. If X is a table, it must contain all
        %   the predictors used for training this model. If X is a matrix, it must
        %   have P columns, where P is the number of predictors used for training.
        %   Y must be of the same type as ENS.ClassNames and have N elements. Y can
        %   be omitted if X is a table that includes the response variable.
        %
        %   L=LOSS(ENS,X,Y,'PARAM1',val1,'PARAM2',val2,...) specifies optional
        %   parameter name/value pairs:
        %       'lossfun'          - Function handle for loss, or string
        %                            representing a built-in loss function.
        %                            Available loss functions for classification:
        %                            'binodeviance', 'classiferror', and
        %                            'exponential'. If you pass a function handle
        %                            FUN, LOSS calls it as shown below:
        %                                  FUN(C,S,W,COST)
        %                            where C is an N-by-K logical matrix for N rows
        %                            in X and K classes in the ClassNames property,
        %                            S is an N-by-K numeric matrix, W is a numeric
        %                            vector with N elements, and COST is a K-by-K
        %                            numeric matrix. C has one true per row for the
        %                            true class. S is a matrix of predicted scores
        %                            for classes with one row per observation,
        %                            similar to SCORE output from PREDICT. W is a
        %                            vector of observation weights. COST is a
        %                            matrix of misclassification costs. Default:
        %                            'classiferror'
        %       'weights'          - Vector of observation weights. By default the
        %                            weight of every observation is set to 1. The
        %                            length of this vector must be equal to the
        %                            number of rows in X.
        %       'useobsforlearner' - Logical matrix of size N-by-NumTrained, where
        %                            N is the number of observations in X and
        %                            NumTrained is the number of weak learners.
        %                            This matrix specifies what learners in the
        %                            ensemble are used for what observations. By
        %                            default, all elements of this matrix are set
        %                            to true.
        %       'learners'         - Indices of weak learners in the ensemble
        %                            ranging from 1 to NumTrained. Only these
        %                            learners are used for making predictions. By
        %                            default, all learners are used.
        %       'mode'             - 'ensemble' (default), 'individual' or
        %                            'cumulative'. If 'ensemble', this method
        %                            returns a scalar value for the full ensemble.
        %                            If 'individual', this method returns a vector
        %                            with one element per trained learner. If
        %                            'cumulative', this method returns a vector in
        %                            which element J is obtained by using learners
        %                            1:J from the input list of learners.
        %
        %   See also CompactClassificationEnsemble, predict.
            
            % Handle input data such as "tall" requiring a special adapter
            adapter = classreg.learning.internal.makeClassificationModelAdapter(this,X,varargin{:});
            if ~isempty(adapter)            
                l = loss(adapter,X,varargin{:});
                return
            end

            [Y,varargin] = classreg.learning.internal.inferResponse(this.ResponseName,X,varargin{:});
            N = size(X,1);
            args = {       'lossfun' 'weights'};
            defs = {this.DefaultLoss ones(N,1)};
            [funloss,W,~,extraArgs] = ...
                internal.stats.parseArgs(args,defs,varargin{:});
            
            [X,C,W] = prepareDataForLoss(this,X,Y,W,[],true,true);
            l = classreg.learning.ensemble.CompactEnsemble.aggregateLoss(...
                this.NTrained,X,C,W,this.Cost,funloss,...
                this.Impl.Combiner,@classreg.learning.ensemble.CompactEnsemble.predictOneWithCache,...
                this.Impl.Trained,this.ClassSummary.ClassNames,this.ClassSummary.NonzeroProbClasses,...
                this.PrivScoreTransform,this.DefaultScore,'usepredforlearner',this.UsePredForLearner,...
                extraArgs{:});
        end
        
        function [varargout] = predictorImportance(this,varargin)
        %PREDICTORIMPORTANCE Estimates of predictor importance.
        %   IMP=PREDICTORIMPORTANCE(ENS) computes estimates of predictor importance
        %   for ensemble ENS by summing these estimates over all weak learners in
        %   the ensemble. The returned vector IMP has one element for each input
        %   predictor in the data used to train this ensemble. A high value
        %   indicates that this predictor is important for this ensemble.
        %
        %   [IMP,MA]=PREDICTORIMPORTANCE(ENS) for ensembles of decision trees also
        %   returns a P-by-P matrix with predictive measures of association for P
        %   predictors. Element MA(I,J) is the predictive measure of association
        %   averaged over surrogate splits on predictor J for which predictor I is
        %   the optimal split predictor. PREDICTORIMPORTANCE averages this
        %   predictive measure of association over all trees in the ensemble.
        %
        %   See also ClassificationEnsemble, CompactClassificationEnsemble,
        %   classreg.learning.classif.CompactClassificationTree/predictorImportance,
        %   classreg.learning.classif.CompactClassificationTree/meanSurrVarAssoc.
        
            [varargout{1:nargout}] = predictorImportance(this.Impl,varargin{:});
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

            fh = functions(this.DefaultLoss);
            if strcmpi(fh.type,'anonymous')
                error(message('stats:classreg:learning:coderutils:classifToStruct:AnonymousFunctionsNotSupported','Loss'));
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

            s.DefaultLossFull = s.DefaultLoss;
            defaultlossfull = strsplit(s.DefaultLoss,'.');
            defaultloss = defaultlossfull{end};
            s.DefaultLoss = defaultloss;    
            
            try
                classreg.learning.internal.lossCheck(s.DefaultLoss,'classification');    
            catch me
                rethrow(me);
            end 
                        
            % save the path to the fromStruct method
            s.FromStructFcn = 'classreg.learning.classif.CompactClassificationEnsemble.fromStruct';
            
            % weak learners
            trained = this.Trained;
            L = numel(trained);
            
            if L == 0
               error(message('stats:classreg:learning:classif:CompactClassificationEnsemble:toStruct:EmptyModelNotSupported')); 
            end            
            
            trained_struct = struct;

            if isa(trained{1},'classreg.learning.classif.CompactClassifByBinaryRegr')
                s.ClassifByBinRegr = true;
            else
                s.ClassifByBinRegr = false;
            end
            
            
            for j=1:L
                fname = ['Learner_' num2str(j)];
                if isempty(trained{j})
                    trained_struct.(fname) = trained{j};
                else
                    if s.ClassifByBinRegr
                        classifByBinRegrStruct = classreg.learning.coderutils.classifToStruct(trained{j});
                        trained_struct.(fname) = trained{j}.CompactRegressionLearner.toStruct;
                        trained_struct.(fname).classifByBinRegrStruct = classifByBinRegrStruct;
                        trained_struct.(fname).classifByBinRegrStruct.FromStructFcn = 'classreg.learning.classif.CompactClassifByBinaryRegr.fromStruct';
                    else
                        trained_struct.(fname) = trained{j}.toStruct;
                    end
                end
            end
            
            s.NumTrained = L;
            s.Impl.Trained = trained_struct;
            s.UsePredForLearner = this.UsePredForLearner;
            s.Impl.Combiner = struct('LearnerWeights',this.Impl.Combiner.LearnerWeights,'IsCached',this.Impl.Combiner.IsCached);
            combinerClassFull = class(this.Impl.Combiner);
            combinerClassList = strsplit(combinerClassFull,'.');
            combinerClass = combinerClassList{end};
            s.Impl.CombinerClass = combinerClass;
            s.DefaultScore = this.DefaultScore;
            s.DefaultScoreType = this.DefaultScoreType;
            s.TransformToProbability = [];
            s.PrivContinuousLoss = [];
            if ~isempty(this.TransformToProbability)
                s.TransformToProbability = func2str(this.TransformToProbability);
            end
            if ~isempty(this.PrivContinuousLoss)
                s.PrivContinuousLoss = func2str(this.PrivContinuousLoss);
            end            
            
        end
        
        
        function this = setLearnersPrior(this,prior)
            trained = this.Impl.Trained;
            
            % Disallow assignment into Prior property for
            % ClassificationKNN. Assignment to Prior property of
            % ClassificationKNN renormalizes observation weights saved in
            % the W property by forcing them to sum to the prior in the
            % respective class. This works fine for a single
            % ClassificationKNN object. There is no easy way of carrying
            % out the same renormalization scheme for the W property of the
            % ClassificationPartitionedModel. To avoid inconsistency
            % between W property of ClassificationPartitionedModel and W
            % properties of ClassificationKNN objects in folds, we forbid
            % assignment into Prior property of
            % ClassificationPartitionedModel for k-NN classification.
            isknn = @(obj) isa(obj,'ClassificationKNN');
            if any(cellfun(isknn,trained))
                error(message('stats:classreg:learning:classif:CompactClassificationEnsemble:setLearnersPrior:Noop'));
            end
            
            % The if statement prevents from throwing a non-informative
            % error from prior(loc)
            if     ischar(prior) && strncmpi(prior,'uniform',numel(prior))
                T = length(trained);
                for t=1:T
                    K = numel(trained{t}.ClassSummary.ClassNames);
                    trained{t}.Prior = ones(1,K)/K;
                end
                this.Impl.Trained = trained;
                
            elseif numel(prior(:))==numel(this.Prior)
                T = length(trained);
                for t=1:T
                    [~,loc] = ismember(trained{t}.ClassSummary.ClassNames,...
                        this.ClassSummary.ClassNames);
                    trained{t}.Prior = prior(loc);
                end
                this.Impl.Trained = trained;
            end
            
            this = setPrivatePrior(this,prior);
        end
        
        function this = setLearnersCost(this,cost)
            % The if statement prevents from throwing a non-informative
            % error from cost(loc,loc)
            if isequal(size(cost),size(this.Cost))
                trained = this.Impl.Trained;
                T = length(trained);
                for t=1:T
                    [~,loc] = ismember(trained{t}.ClassSummary.ClassNames,...
                        this.ClassSummary.ClassNames);
                    trained{t}.Cost = cost(loc,loc);
                end
                this.Impl.Trained = trained;
            end
            this = setPrivateCost(this,cost);
        end
    end
    methods(Static=true,Hidden=true)
        function obj = fromStruct(s)
            % Make an Ensemble object from a codegen struct.
            
            s.ScoreTransform = s.ScoreTransformFull;
            s.DefaultLoss = s.DefaultLossFull;
            s = classreg.learning.coderutils.structToClassif(s);
            
            % Prepare a cell array of learners
            L = s.NumTrained;
            trained = cell(L,1);
            
            for j=1:L
                fname = ['Learner_' num2str(j)];
                trained_struct = s.Impl.Trained.(fname);
                if ~isempty(trained_struct)
                    fcn = str2func(trained_struct.FromStructFcn);
                     if s.ClassifByBinRegr
                          classifByBinRegrStruct = trained_struct.classifByBinRegrStruct;
                          classifByBinRegrStruct = classreg.learning.coderutils.structToClassif(classifByBinRegrStruct);
                          trained_struct = rmfield(trained_struct,'classifByBinRegrStruct');
                          crl = fcn(trained_struct);
                          trained{j} = crl;
                          crlStruct = struct('DataSummary',classifByBinRegrStruct.DataSummary,'ClassSummary',classifByBinRegrStruct.ClassSummary,...
                                             'ScoreTransform',classifByBinRegrStruct.ScoreTransform,'crl',trained{j});              
                          trained{j} = classreg.learning.classif.CompactClassifByBinaryRegr.fromStruct(crlStruct);
                     else
                        trained{j} = fcn(trained_struct);
                    end
                else
                    trained{j} = trained_struct;
                end
            end
            transformToProbability = [];
            continuousLoss = [];
            if ~isempty(s.TransformToProbability)
                transformToProbability = str2func(s.TransformToProbability);
            end
            if ~isempty(s.PrivContinuousLoss)
                continuousLoss = str2func(s.PrivContinuousLoss);
            end
            
            
            
            % Make an object
            obj = classreg.learning.classif.CompactClassificationEnsemble(...
                s.DataSummary,s.ClassSummary,s.ScoreTransform,s.ScoreType,...
                s.UsePredForLearner,s.DefaultScore,continuousLoss,transformToProbability);

            learnerweights = s.Impl.Combiner.LearnerWeights;
            combinerClassFull = ['classreg.learning.combiner.' s.Impl.CombinerClass];
            combinerClass = str2func(combinerClassFull);
            combiner = combinerClass(learnerweights);
            impl = classreg.learning.impl.CompactEnsembleImpl(trained,combiner);
            obj.DefaultScoreType = s.DefaultScoreType;   
            obj.Impl = impl;

        end
    end
    
    methods(Hidden, Static)
        function name = matlabCodegenRedirect(~)
            name = 'classreg.learning.coder.classif.CompactClassificationEnsemble';
        end
    end    
end
