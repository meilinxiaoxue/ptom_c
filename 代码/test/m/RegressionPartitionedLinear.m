classdef RegressionPartitionedLinear < classreg.learning.partition.CompactRegressionPartitionedModel
%RegressionPartitionedLinear Cross-validated regression model.
%   RegressionPartitionedLinear is a set of linear regression models
%   trained on cross-validated folds. You can obtain such a model by
%   calling FITRLINEAR with one of the cross-validation options.
%
%   To estimate the quality of regression by cross-validation, you can
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
%   RegressionPartitionedLinear properties:
%      CrossValidatedModel   - Name of the cross-validated model.
%      PredictorNames        - Names of predictors used for this model.
%      CategoricalPredictors - Indices of categorical predictors.
%      ResponseName          - Name of the response variable.
%      NumObservations       - Number of observations.
%      Y                     - Observed response values used to cross-validate this model.
%      W                     - Weights of observations used to cross-validate this model.
%      ModelParameters       - Cross-validation parameters.
%      Trained               - Compact regression models trained on cross-validation folds.
%      KFold                 - Number of cross-validation folds.
%      Partition             - Data partition used to cross-validate this model.
%      ResponseTransform     - Transformation applied to predicted regression response.
%
%   RegressionPartitionedLinear methods:
%      kfoldPredict          - Predict response for observations not used for training.
%      kfoldLoss             - Regression loss for observations not used for training.
%
%   See also cvpartition, RegressionLinear.

%   Copyright 2015 The MathWorks, Inc.
    
   methods(Hidden)
        function this = RegressionPartitionedLinear(...
                X,Y,W,modelParams,dataSummary,responseTransform)
            this = this@classreg.learning.partition.CompactRegressionPartitionedModel(...
                X,Y,W,modelParams,dataSummary,responseTransform);
            this.CrossValidatedModel = 'Linear';
        end
    end
    
    
    methods(Access=protected)
        function R = response(this)
            R = [];
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
                
                R = NaN(N,L);
                
                uofl = ~this.PrivGenerator.UseObsForIter;
                
                T = numel(trained);
                for t=1:T
                    idx = uofl(:,t);
                    R(idx,:) = predict(trained{t},X(:,idx),...
                        'ObservationsIn','columns');
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
            s.ResponseTransform   = this.ResponseTransform;
        end
    end
    
    
    methods
        function Yhat = kfoldPredict(this)
        %kfoldPredict Predict response for observations not used for training.
        %   YFIT=kfoldPredict(OBJ) returns an N-by-L matrix of predictions fitted
        %   by cross-validated regression model OBJ, where N is the number of
        %   observations in the data and L is the number of regularization
        %   parameter values saved in the Lambda properties of the Trained models.
        %   For every fold, this method predicts response for in-fold observations
        %   using a model trained on out-of-fold observations.
        %
        %   See also classreg.learning.partition.RegressionPartitionedLinear,
        %   Trained, RegressionLinear.

            Yhat = this.PartitionedModel.Ensemble.PrivResponseTransform(this.PrivYhat);
        end
        
        function err = kfoldLoss(this,varargin)
        %kfoldLoss Regression loss for observations not used for training.
        %   L=kfoldLoss(OBJ) returns a row-vector of loss values obtained by
        %   cross-validated regression model OBJ, one value per element of the
        %   regularization parameter saved in the Lambda properties of the Trained
        %   models. For every fold, this method computes regression loss for
        %   in-fold observations using a model trained on out-of-fold observations.
        %  
        %   L=kfoldLoss(OBJ,'PARAM1',val1,'PARAM2',val2,...) specifies optional
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
        %                            Available loss functions for
        %                            regression: 'mse' and
        %                            'epsiloninsensitive'. If you pass a
        %                            function handle FUN, LOSS calls it as
        %                            shown below:
        %                               FUN(Y,Yfit,W)
        %                            where Y, Yfit and W are numeric vectors of
        %                            length N. Y is observed response, Yfit is
        %                            predicted response, and W is observation
        %                            weights. Default: 'mse'
        %
        %   See also classreg.learning.partition.RegressionPartitionedLinear,
        %   kfoldPredict, Trained, RegressionLinear.
 
            classreg.learning.ensemble.Ensemble.catchUOFL(varargin{:});
            classreg.learning.FullClassificationRegressionModel.catchWeights(varargin{:});
            [mode,folds,extraArgs] = checkFoldArgs(this.PartitionedModel,varargin{:});
            
            % Process input args
            args = {                  'lossfun'};
            defs = {@classreg.learning.loss.mse};
            funloss = internal.stats.parseArgs(args,defs,extraArgs{:});
            
            % Check loss function
            if strncmpi(funloss,'epsiloninsensitive',length(funloss))
                if isempty(this.Trained{1}.Epsilon) % this is empty for models other than SVM
                    error(message('stats:RegressionLinear:loss:UseEpsilonInsensitiveForSVM'));
                end
                
                % The default numeric Epsilon is set in
                % LinearParams.fillDefaultParams which ensures the same
                % value across folds.
                funloss = @(Y,Yfit,W) classreg.learning.loss.epsiloninsensitive(...
                    Y,Yfit,W,this.Trained{1}.Epsilon);
            end
            funloss = classreg.learning.internal.lossCheck(funloss,'regression');

            % Get everything
            yhat = this.PartitionedModel.Ensemble.PrivResponseTransform(this.PrivYhat);
            L = size(yhat,2);
            y = this.Y;
            w = this.W;

            % Apply loss function to predictions
            uofl = ~this.PrivGenerator.UseObsForIter;
            if     strncmpi(mode,'ensemble',length(mode))
                err = NaN(1,L);
                iuse = any(uofl(:,folds),2);
                for l=1:L
                    err(l) = funloss(y(iuse),yhat(iuse,l),w(iuse));
                end
            elseif strncmpi(mode,'individual',length(mode))
                T = numel(folds);
                err = NaN(T,L);
                for k=1:T
                    t = folds(k);
                    iuse = uofl(:,t);
                    for l=1:L
                        err(k,l) = funloss(y(iuse),yhat(iuse,l),w(iuse));
                    end
                end
            else
                error(message('stats:classreg:learning:partition:PartitionedModel:checkFoldArgs:BadMode'));
            end           
        end
        
    end
    
end
