classdef ClassificationPartitionedLinear < classreg.learning.partition.CompactClassificationPartitionedModel
%ClassificationPartitionedLinear Cross-validated classification model.
%   ClassificationPartitionedLinear is a set of linear classification
%   models trained on cross-validated folds. You can obtain such a model by
%   calling FITCLINEAR with one of the cross-validation options.
%
%   To estimate the quality of classification by cross-validation, you can
%   use KFOLD methods. Every KFOLD method uses models trained on in-fold
%   observations to predict response for out-of-fold observations. For
%   example, you cross-validate using 5 folds. In this case, every training
%   fold contains roughly 4/5 of data and every test fold contains roughly
%   1/5 of data. The first model stored in Trained{1} was trained on X and
%   Y with the first 1/5 excluded, the second model stored in Trained{2}
%   was trained on X and Y with the second 1/5 excluded and so on. When you
%   call KFOLDPREDICT, it computes predictions for the first 1/5 of the
%   data using the first model, for the second 1/5 of data using the second
%   model and so on. In short, response for every observation is computed by
%   KFOLDPREDICT using the model trained without this observation.
%
%   ClassificationPartitionedLinear properties:
%      CrossValidatedModel   - Name of the cross-validated model.
%      PredictorNames        - Names of predictors used for this model.
%      CategoricalPredictors - Indices of categorical predictors.
%      ResponseName          - Name of the response variable.
%      NumObservations       - Number of observations.
%      Y                     - True class labels used to cross-validate this model.
%      W                     - Weights of observations used to cross-validate this model.
%      ModelParameters       - Cross-validation parameters.
%      Trained               - Compact classifiers trained on cross-validation folds.
%      KFold                 - Number of cross-validation folds.
%      Partition             - Data partition used to cross-validate this model.
%      ClassNames            - Names of classes in Y.
%      Cost                  - Misclassification costs.
%      Prior                 - Prior class probabilities.
%      ScoreTransform        - Transformation applied to predicted classification scores.
%
%   ClassificationPartitionedLinear methods:
%      kfoldPredict          - Predict response for observations not used for training.
%      kfoldLoss             - Classification loss for observations not used for training.
%      kfoldMargin           - Classification margins for observations not used for training.
%      kfoldEdge             - Classification edge for observations not used for training.
%
%   See also cvpartition, ClassificationLinear.

%   Copyright 2015 The MathWorks, Inc.    
    
    methods(Hidden)
        function this = ClassificationPartitionedLinear(X,Y,W,modelParams,...
                dataSummary,classSummary,scoreTransform)
            this = this@classreg.learning.partition.CompactClassificationPartitionedModel(...
                X,Y,W,modelParams,dataSummary,classSummary,scoreTransform);
            this.CrossValidatedModel = 'Linear';
        end
    end
    
    
    methods(Access=protected)
        function S = score(this)
            S = [];
            pm = this.PartitionedModel;
            trained = pm.Ensemble.Trained;
            if ~isempty(trained)
                X = pm.Ensemble.X;
                
                % This check is not necessary since X must already have
                % observations in columns for linear models but is left
                % here as a precaution.
                if pm.Ensemble.ObservationsInRows
                    X = X';
                end
                
                L = numel(trained{1}.Lambda);
                N = size(X,2);
                K = numel(pm.Ensemble.ClassSummary.ClassNames);
                
                S = NaN(N,K,L);
                
                uofl = ~this.PrivGenerator.UseObsForIter;
                
                T = numel(trained);
                for t=1:T
                    if ~isempty(trained{t})
                        idx = uofl(:,t);
                        [~,S(idx,:,:)] = predict(trained{t},X(:,idx),...
                            'ObservationsIn','columns');
                    end
                end
            end            
        end
                
        function s = propsForDisp(this,s)
            if nargin<2 || isempty(s)
                s = struct;
            else
                if ~isstruct(s)
                    error(message('stats:classreg:learning:Predictor:propsForDisp:BadS'));
                end
            end

            s.CrossValidatedModel = 'Linear';
            s.ResponseName        = this.ResponseName;
            s.NumObservations     = this.NumObservations;
            s.KFold               = this.KFold;
            s.Partition           = this.Partition;            
            cnames = this.ClassNames;
            if ischar(cnames)
                s.ClassNames      = cnames;
            else
                s.ClassNames      = cnames';
            end
            s.ScoreTransform      = this.ScoreTransform;
        end
    end
    
    
    methods
        function [labels,score] = kfoldPredict(this)
        %kfoldPredict Predict response for observations not used for training.
        %   [LABEL,SCORE]=kfoldPredict(OBJ) returns class labels and scores
        %   predicted by cross-validated classification model OBJ. Classification
        %   labels LABEL are an N-by-L array of the same type as Y used for
        %   training, where N is the number of observations and L is the number of
        %   values of the regularization parameter saved in the Lambda properties
        %   of the Trained models. Scores SCORE are an N-by-K-by-L numeric matrix
        %   for N observations, K classes and L values of Lambda. For every fold,
        %   this method predicts class labels and scores for in-fold observations
        %   using a model trained on out-of-fold observations.
        %
        %   See also classreg.learning.partition.ClassificationPartitionedLinear,
        %   Trained, ClassificationLinear.

            score = this.PrivScore;
            L = size(score,3);
            N = size(score,1);
            
            prior = this.Prior;
            cost = this.Cost;
            scoreTransform = this.PartitionedModel.PrivScoreTransform;
            classnames = this.ClassNames;
            if ischar(classnames) && L>1
                classnames = cellstr(classnames);
            end
            labels = repmat(classnames(1,:),N,L);

            if L==1
                [labels,score] = ...
                    this.LabelPredictor(classnames,prior,cost,score,scoreTransform);
            else
                for l=1:L
                    [labels(:,l),score(:,:,l)] = ...
                        this.LabelPredictor(classnames,prior,cost,score(:,:,l),scoreTransform);
                end
            end
        end
        
        
        function err = kfoldLoss(this,varargin)
        %kfoldLoss Classification loss for observations not used for training.
        %   ERR=kfoldLoss(OBJ) returns a row-vector of classification error values
        %   obtained by cross-validated model OBJ with one value per element of the
        %   regularization parameter saved in the Lambda properties of the Trained
        %   models. For every fold, this method computes classification loss for
        %   in-fold observations using a model trained on out-of-fold observations.
        %  
        %   ERR=kfoldLoss(OBJ,'PARAM1',val1,'PARAM2',val2,...) specifies optional
        %   parameter name/value pairs:
        %       'Folds'            - Indices of folds ranging from 1 to KFold. Use
        %                            only these folds for predictions. By default,
        %                            all folds are used.
        %       'Mode'             - 'average' (default) or 'individual'. If
        %                            'average', this method averages over all
        %                             folds. If 'individual', this method returns
        %                             an F-by-L matrix where F is the number of
        %                             folds and L is the number of regularization
        %                             values saved in the Lambda properties.        
        %       'LossFun'          - Function handle for loss, or string
        %                            representing a built-in loss function.
        %                            Available loss functions for classification:
        %                            'binodeviance', 'classiferror', 'exponential',
        %                            'hinge', 'logit', 'mincost', and 'quadratic'.
        %                            If you pass a function handle FUN, loss calls
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
        %
        %   See also classreg.learning.partition.ClassificationPartitionedLinear,
        %   kfoldPredict, Trained, ClassificationLinear.

            classreg.learning.ensemble.Ensemble.catchUOFL(varargin{:});
            classreg.learning.FullClassificationRegressionModel.catchWeights(varargin{:});
            [mode,folds,extraArgs] = checkFoldArgs(this.PartitionedModel,varargin{:});
            
            % Process input args
            args = {       'lossfun'};
            defs = {this.DefaultLoss};
            funloss = internal.stats.parseArgs(args,defs,extraArgs{:});
            
            % Check loss function
            funloss = classreg.learning.internal.lossCheck(funloss,'classification');

            % Get everything
            score = this.PartitionedModel.PrivScoreTransform(this.PrivScore);
            L = size(score,3);
            C = this.PrivC;
            w = this.W;
            cost = this.Cost;

            % Apply loss function to predictions
            uofl = ~this.PrivGenerator.UseObsForIter;
            if     strncmpi(mode,'ensemble',length(mode))
                err = NaN(1,L);
                iuse = any(uofl(:,folds),2);
                for l=1:L
                    err(l) = funloss(C(iuse,:),score(iuse,:,l),w(iuse),cost);
                end
            elseif strncmpi(mode,'individual',length(mode))
                T = numel(folds);
                err = NaN(T,L);
                for k=1:T
                    t = folds(k);
                    iuse = uofl(:,t);
                    for l=1:L
                        err(k,l) = funloss(C(iuse,:),score(iuse,:,l),w(iuse),cost);
                    end
                end
            else
                error(message('stats:classreg:learning:partition:PartitionedModel:checkFoldArgs:BadMode'));
            end           
        end
        
        
        function e = kfoldEdge(this,varargin)            
        %kfoldEdge Classification edge for observations not used for training.
        %   ERR=kfoldEdge(OBJ) returns a row-vector of classification edge values
        %   obtained by cross-validated model OBJ with one value per element of the
        %   regularization parameter saved in the Lambda properties of the Trained
        %   models. For every fold, this method computes classification edge for
        %   in-fold observations using a model trained on out-of-fold observations.
        %  
        %   ERR=kfoldEdge(OBJ,'PARAM1',val1,'PARAM2',val2,...) specifies optional
        %   parameter name/value pairs:
        %       'Folds'            - Indices of folds ranging from 1 to KFold. Use
        %                            only these folds for predictions. By default,
        %                            all folds are used.
        %       'Mode'             - 'average' (default) or 'individual'. If
        %                            'average', this method averages over all
        %                             folds. If 'individual', this method returns
        %                             an F-by-L matrix where F is the number of
        %                             folds and L is the number of regularization
        %                             values saved in the Lambda properties.        
        %
        %   See also classreg.learning.partition.ClassificationPartitionedLinear,
        %   kfoldMargin, Trained, ClassificationLinear.

            e = kfoldLoss(this,'LossFun',@classreg.learning.loss.classifedge,varargin{:});
        end
        
        
        function m = kfoldMargin(this,varargin)
        %KFOLDMARGIN Classification margins for observations not used for training.
        %   M=KFOLDMARGIN(OBJ) returns classification margins obtained by
        %   cross-validated classification model OBJ. For every fold, this method
        %   computes classification margins for in-fold observations using a model
        %   trained on out-of-fold observations. The returned M is a an N-by-L
        %   matrix for N observations and L values of the regularization parameter
        %   saved in the Lambda properties of the Trained models.
        %
        %   See also classreg.learning.partition.ClassificationPartitionedLinear,
        %   kfoldPredict, Trained, ClassificationLinear.
            
            classreg.learning.ensemble.Ensemble.catchUOFL(varargin{:});
            classreg.learning.partition.PartitionedModel.catchFolds(varargin{:});
            classreg.learning.FullClassificationRegressionModel.catchWeights(varargin{:});
            
            score = this.PartitionedModel.PrivScoreTransform(this.PrivScore);
            N = size(score,1);
            L = size(score,3);
            C = this.PrivC;
            
            m = NaN(N,L);
            for l=1:L
                m(:,l) = classreg.learning.loss.classifmargin(C,score(:,:,l));
            end
        end
    end
    
end
