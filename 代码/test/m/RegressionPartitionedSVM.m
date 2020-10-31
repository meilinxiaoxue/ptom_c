classdef RegressionPartitionedSVM < classreg.learning.partition.RegressionPartitionedModel
%RegressionPartitionedSVM Cross-validated SVM regression model.
%   RegressionPartitionedSVM is a set of SVM regression models trained on
%   cross-validated folds. You can obtain a cross-validated model either by
%   calling CROSSVAL method of a regression model or by training a
%   regression model with one of the cross-validation options.
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
%   model and so on. In short, response for every observation is computed
%   by KFOLDPREDICT using the model trained without this observation.
%
%   RegressionPartitionedSVM properties:
%      CrossValidatedModel   - Name of the cross-validated model.
%      PredictorNames        - Names of predictors used for this model.
%      CategoricalPredictors - Indices of categorical predictors.
%      ResponseName          - Name of the response variable.
%      NumObservations       - Number of observations.
%      X                     - X data used to cross-validate this model.
%      Y                     - Observed response values used to cross-validate this model.
%      W                     - Weights of observations used to cross-validate this model.
%      ModelParameters       - Cross-validation parameters.
%      Trained               - Compact regression models trained on cross-validation folds.
%      KFold                 - Number of cross-validation folds.
%      Partition             - Data partition used to cross-validate this model.
%      ResponseTransform     - Transformation applied to predicted regression response.
%
%   RegressionPartitionedModel methods:
%      kfoldPredict          - Predict response for observations not used for training.
%      kfoldLoss             - Regression loss for observations not used for training.
%      kfoldfun              - Cross-validate function.
%
%   See also cvpartition, classreg.learning.regr.RegressionModel.

%   Copyright 2010-2014 The MathWorks, Inc.


    methods(Hidden)
        function this = RegressionPartitionedSVM(...
                X,Y,W,modelParams,dataSummary,responseTransform)
            this = this@classreg.learning.partition.RegressionPartitionedModel(...
                X,Y,W,modelParams,dataSummary,responseTransform);
         
         end
    end
    methods
   
        function l = kfoldLoss(this,varargin)
        %KFOLDLOSS Regression loss for observations not used for training.
        %   L=KFOLDLOSS(OBJ) returns loss obtained by cross-validated
        %   regression model OBJ. For every fold, this method computes
        %   regression loss for in-fold observations using a model trained
        %   on out-of-fold observations.
        %
        %   L=KFOLDLOSS(OBJ,'PARAM1',val1,'PARAM2',val2,...) specifies
        %   optional parameter name/value pairs:
        %       'Folds'            - Indices of folds ranging from 1 to
        %                            KFold. Use only these folds for
        %                            predictions. By default, all folds are
        %                            used.
        %       'Mode'             - 'average' (default) or 'individual'.
        %                            If 'average', this method averages
        %                            over all folds. If 'individual', this
        %                            method returns a vector with one
        %                            element per fold.
        %       'LossFun'          - Function handle for loss, or string
        %                            representing a built-in loss function.
        %                            Available loss functions for
        %                            regression: 'mse' and
        %                            'epsiloninsensitive'. If you pass a
        %                            function handle FUN, LOSS calls it as
        %                            shown below:
        %                               FUN(Y,Yfit,W)
        %                            where Y, Yfit and W are numeric
        %                            vectors of length N. Y is observed
        %                            response, Yfit is predicted response,
        %                            and W is observation weights. Default:
        %                            'mse'
        %
        %   See also RegressionPartitionedModel,
        %   classreg.learning.regr.RegressionModel/loss, kfoldPredict.
            
            classreg.learning.ensemble.Ensemble.catchUOFL(varargin{:});
            classreg.learning.FullClassificationRegressionModel.catchWeights(varargin{:});
            
            [mode,folds,args] = checkFoldArgs(this,varargin{:});
            usenfort = ~this.Ensemble.ModelParams.Generator.UseObsForIter;
            
                arglist = {                  'lossfun'};
                defs = {@classreg.learning.loss.mse };
                [funloss,~,extraArgs] = ...
                    internal.stats.parseArgs(arglist,defs,args{:});
                if strncmpi(funloss,'epsiloninsensitive',length(funloss))
                    f2 = @classreg.learning.loss.epsiloninsensitive;
                    funloss = @(Y,Yfit,W)(f2(Y,Yfit,W,this.Trained{1}.Impl.Epsilon));
                end
                l = loss(this.Ensemble,this.Ensemble.X,this.Ensemble.PrivY,'weights',this.Ensemble.W,...
                    'useobsforlearner',usenfort,'mode',mode,'learners',folds,'lossfun',funloss,extraArgs{:});

        end
    end
        
end
