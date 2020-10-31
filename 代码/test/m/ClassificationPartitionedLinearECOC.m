classdef ClassificationPartitionedLinearECOC < ...
        classreg.learning.partition.PartitionedECOC ...
        & classreg.learning.partition.CompactClassificationPartitionedModel
%ClassificationPartitionedLinearECOC Cross-validated linear error-correcting output code (ECOC) model.
%   ClassificationPartitionedLinearECOC is a set of linear ECOC models
%   trained on cross-validated folds. You can obtain such a model by
%   passing one of the cross-validation options and passing 'Linear' or an
%   object of type TEMPLATELINEAR to the FITCECOC function.
%
%   To estimate the quality of classification by cross-validation, you can
%   use KFOLD methods. Every KFOLD method uses models trained on in-fold
%   observations to predict responses for out-of-fold observations. For
%   example, you cross-validate using 5 folds. In this case, every training
%   fold contains roughly 4/5 of data and every test fold contains roughly
%   1/5 of data. The first model stored in Trained{1} was trained on X and
%   Y with the first 1/5 excluded, the second model stored in Trained{2}
%   was trained on X and Y with the second 1/5 excluded and so on. When you
%   call KFOLDPREDICT, it computes predictions for the first 1/5 of the
%   data using the first model, for the second 1/5 of data using the second
%   model and so on. In short, a response for every observation is computed
%   by KFOLDPREDICT using the model trained without this observation.
%
%   ClassificationPartitionedLinearECOC properties:
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
%      BinaryY               - Class labels for binary learners.
%      BinaryLoss            - Default binary loss function for prediction.
%      CodingMatrix          - Coding matrix.
%
%   ClassificationPartitionedLinearECOC methods:
%      kfoldPredict          - Predict response for observations not used for training.
%      kfoldLoss             - Classification loss for observations not used for training.
%      kfoldMargin           - Classification margins for observations not used for training.
%      kfoldEdge             - Classification edge for observations not used for training.
%
%   See also cvpartition, fitcecoc, ClassificationECOC, templateLinear.

%   Copyright 2015 The MathWorks, Inc.

    properties(GetAccess=public,SetAccess=protected,Dependent=true)
        %BINARYY Class labels for binary learners.
        %   If the same coding matrix is used across all folds, the BinaryY
        %   property is an N-by-L matrix for N observations and L binary learners
        %   specified by the columns of the coding matrix. Its elements take values
        %   -1, 0 or +1. If element (I,J) of this matrix is -1, observation I is
        %   included in the negative class for binary learner J; if this element is
        %   +1, observation I is included in the positive class for binary learner
        %   J; and if this element is 0, observation I is not used for training
        %   binary learner J.
        %
        %   If the coding matrix varies across the folds, the BinaryY property is
        %   empty.
        %
        %   See also classreg.learning.partition.ClassificationPartitionedLinearECOC,
        %   CodingMatrix.
        BinaryY;
    end
        
    methods(Hidden)
        function this = ClassificationPartitionedLinearECOC(X,Y,W,modelParams,...
                dataSummary,classSummary,scoreTransform)
            this = this@classreg.learning.partition.PartitionedECOC;
            this = this@classreg.learning.partition.CompactClassificationPartitionedModel(...
                X,Y,W,modelParams,dataSummary,classSummary,scoreTransform);
            this.DefaultLoss = @classreg.learning.loss.classiferror;
            this.LabelPredictor = @classreg.learning.classif.ClassificationModel.maxScore;
            this.CrossValidatedModel = 'LinearECOC';
        end
    end
    
    
    methods
        function bY = get.BinaryY(this)
            M = this.CodingMatrix;            
            L = size(M,2);
            N = this.NumObservations;
            bY = zeros(N,L);
            
            for l=1:L
                neg = M(:,l)==-1;
                pos = M(:,l)==1;
                isneg = any(this.PrivC(:,neg),2);
                ispos = any(this.PrivC(:,pos),2);
                bY(isneg,l) = -1;
                bY(ispos,l) =  1;
            end
        end
    end

    
    methods(Access=protected)
        function cvmodel = getCrossValidatedModel(~)
            cvmodel = 'LinearECOC';
        end
        
        function lw = learnerWeights(this)
            WC = bsxfun(@times,this.PrivC,this.W);
            
            M = this.CodingMatrix;            
            L = size(M,2);
            
            if any(M(:)==0)
                lw = NaN(1,L);
                for l=1:L
                    lw(l) = sum(sum(WC(:,M(:,l)~=0)));
                end
            else
                lw = repmat(sum(this.W),1,L);
            end
        end
        
        function S = score(this)
            S = [];
            
            trained = this.Ensemble.Trained;
            T = numel(trained);
            
            if T>0
                X = this.Ensemble.X;
                
                % This check is not necessary since X must already have
                % observations in columns for linear models but is left
                % here as a precaution.
                if this.Ensemble.ObservationsInRows
                    X = X';
                end
                
                B = size(this.CodingMatrix,2);
                
                L = [];
                for t=1:T
                    if ~isempty(trained{t})
                        blearners = trained{t}.BinaryLearners;
                        B = numel(blearners);
                        for b=1:B
                            if ~isempty(blearners{b})
                                if isempty(L)
                                    L = numel(blearners{b}.Lambda);
                                else
                                    if L~=numel(blearners{b}.Lambda)
                                        error(message('stats:classreg:learning:partition:ClassificationPartitionedLinearECOC:score:LambdaMismatch',b,t,L));
                                    end
                                end
                            end
                        end
                    end
                end
                
                if isempty(L)
                    return;
                end                
                
                N = size(X,2);
                
                S = NaN(N,B,L);
                
                uofl = ~this.PrivGenerator.UseObsForIter;
                
                T = numel(trained);
                for t=1:T
                    if ~isempty(trained{t})
                        idx = uofl(:,t);
                        [~,~,S(idx,:,:)] = predict(trained{t},X(:,idx),...
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
        function [labels,negloss,pscore,posterior] = kfoldPredict(this,varargin)            
        %KFOLDPREDICT Predict response for observations not used for training.
        %   [LABEL,NEGLOSS]=KFOLDPREDICT(OBJ) returns class labels LABEL and
        %   negated values of the average binary loss per class NEGLOSS predicted
        %   by cross-validated ECOC model OBJ. Classification labels LABEL are an
        %   N-by-R array of the same type as Y used for training, where N is the
        %   number of observations and R is the number of values of the
        %   regularization parameter saved in the Lambda properties of the
        %   BinaryLearners models in the Trained cross-validation folds. Negative
        %   loss values NEGLOSS are an N-by-K-by-R matrix for N observations, K
        %   classes in OBJ.ClassNames and R values of the regularization parameter.
        %   For every fold, this method predicts class labels and negative loss
        %   values for in-fold observations using a model trained on out-of-fold
        %   observations. The predicted label is assigned to the class with the
        %   largest negated average binary loss, or equivalently smallest average
        %   binary loss.
        %
        %   [~,~,PBSCORE]=KFOLDPREDICT(OBJ) also returns an N-by-L-by-R matrix of
        %   positive-class scores predicted by the binary learners for N
        %   observations, L binary learners in the BinaryLearners properties of the
        %   Trained cross-validation folds, and R values of the regularization
        %   parameter. If the coding matrix varies across the folds, KFOLDPREDICT
        %   returns PBSCORE as an empty array.
        %
        %   [~,~,~,POSTERIOR]=KFOLDPREDICT(OBJ) also returns posterior probability
        %   estimates, an N-by-K-by-R matrix for N observations, K classes in
        %   ClassNames, and R values of the regularization parameter. KFOLDPREDICT
        %   cannot compute these estimates unless you passed 'FitPosterior' as true
        %   to FITCECOC. If you set 'FitPosterior' to false for FITCECOC and
        %   request 4th output, KFOLDPREDICT throws an error.
        %
        %   [...]=KFOLDPREDICT(OBJ,X,'PARAM1',val1,'PARAM2',val2,...) specifies
        %   optional parameter name/value pairs:
        %       'BinaryLoss'           - Function handle, or string representing a
        %                                built-in function for computing loss
        %                                induced by each binary learner. Available
        %                                loss functions for binary learners with
        %                                scores in the (-inf,+inf) range are:
        %                                'hamming', 'linear', 'exponential',
        %                                'binodeviance', 'hinge', and 'logit'.
        %                                Available loss functions for binary
        %                                learners with scores in the [0,1] range
        %                                are: 'hamming' and 'quadratic'. If you
        %                                pass a function handle FUN, KFOLDPREDICT
        %                                calls it as shown below:
        %                                      FUN(M,F)
        %                                where M is a K-by-L coding matrix saved in
        %                                the CodingMatrix property and F is a
        %                                1-by-L row-vector of scores computed by
        %                                the binary learners. Default: Value of the
        %                                BinaryLoss property
        %       'Decoding'             - String specifying the decoding scheme, either
        %                                'lossbased' or 'lossweighted'. Default:
        %                                'lossweighted'
        %       'NumKLInitializations' - Non-negative integer specifying the number
        %                                of random initial guesses for fitting
        %                                posterior probabilities by minimization of
        %                                the Kullback-Leibler divergence.
        %                                KFOLDPREDICT ignores this parameter unless
        %                                you request 4th output and set
        %                                'PosteriorMethod' to 'kl'. Default: 0
        %       'Options'              - A struct that contains options specifying
        %                                whether to use parallel computation. This
        %                                argument can be created by a call to
        %                                STATSET. Set 'Options' to
        %                                statset('UseParallel',true) to use
        %                                parallel computation.
        %       'PosteriorMethod'      - String specifying how posterior
        %                                probabilities are fitted, either 'qp' or
        %                                'kl'. If 'qp', multiclass probabilities
        %                                are fitted by solving a least-squares
        %                                problem by quadratic programming. The 'qp'
        %                                method requires an Optimization Toolbox
        %                                license. If 'kl', multiclass probabilities
        %                                are fitted by minimizing the
        %                                Kullback-Leibler divergence between the
        %                                predicted and expected posterior
        %                                probabilities returned by the binary
        %                                learners. KFOLDPREDICT ignores this
        %                                parameter unless you request 4th output.
        %                                Default: 'kl'
        %       'Verbose'              - Non-negative integer specifying the
        %                                verbosity level, either 0 or 1.
        %                                KFOLDPREDICT does not display any
        %                                diagnostic messages at verbosity level 0
        %                                and displays diagnostic messages at
        %                                verbosity level 1. Default: 0
        %
        %   See also
        %   classreg.learning.partition.ClassificationPartitionedLinearECOC,
        %   ClassificationECOC/predict, ClassificationLinear, fitcecoc,
        %   templateLinear, Trained, BinaryLoss, CodingMatrix, statset.
            
            pscore = this.PrivScore;
            [N,~,S] = size(pscore);

            if isempty(pscore)
                labels = repmat(this.ClassNames(1,:),0,1);
                K = numel(this.ClassSummary.ClassNames);
                L = numel(this.BinaryLearners);
                negloss = NaN(0,K);
                pscore = NaN(0,L);
                posterior = NaN(0,K);
                return;
            end
            
            % Get args
            args = {   'binaryloss'     'decoding' 'verbose' ...
                'posteriormethod' 'numklinitializations'           'options'};
            defs = {this.BinaryLoss 'lossweighted'         0 ...
                'kl'                      0 statset('parallel')};
            [userloss,decoding,verbose,postmethod,numfits,paropts] = ...
                internal.stats.parseArgs(args,defs,varargin{:});
            
            % Can compute posterior probabilities?
            doposterior = nargout>3;
            
            [dist,isBuiltinDist,ignorezeros,doquadprog] = ...
                classreg.learning.ecocutils.prepareForPredictECOC(...
                this.ScoreType,doposterior,postmethod,userloss,this.BinaryLoss,...
                decoding,numfits);

            [useParallel,RNGscheme] = ...
                internal.stats.parallel.processParallelAndStreamOptions(paropts);

            M = this.CodingMatrix;
            if ignorezeros
                M(M==0) = NaN;
            end

            % Loss per observation. Because the distance function uses
            % things like nanmean, taking a loop over columns of
            % UseObsForIter ensures that uncomputed loss values remain NaN.
            K = size(M,1);
            negloss = NaN(N,K,S);            
            uofl = ~this.PrivGenerator.UseObsForIter;            
            F = size(uofl,2);
            for f=1:F
                iuse = uofl(:,f);
                for s=1:S
                    negloss(iuse,:,s) = -classreg.learning.ecocutils.loss(...
                        dist,M,pscore(iuse,:,s),useParallel,isBuiltinDist);
                end
            end
            if verbose>0
                fprintf('%s\n',getString(message('stats:classreg:learning:classif:CompactClassificationECOC:score:LossComputed')));
            end            
            
            % Get class labels
            prior = this.Prior;
            cost = this.Cost;
            classnames = this.ClassNames;
            if ischar(classnames) && S>1
                classnames = cellstr(classnames);
            end
            labels = repmat(classnames(1,:),N,S);

            if S==1
                labels = this.LabelPredictor(classnames,prior,cost,negloss,@(x)x);
            else
                for s=1:S
                    labels(:,s) = ...
                        this.LabelPredictor(classnames,prior,cost,negloss(:,:,s),@(x)x);
                end
            end
            
            % Fit posterior probabilities
            if doposterior
                lw = learnerWeights(this);
                if S==1
                    posterior = classreg.learning.ecocutils.posteriorFromRatio(M,pscore,...
                        lw,verbose,doquadprog,numfits,useParallel,RNGscheme);
                else
                    posterior = NaN(N,K,S);
                    for s=1:S
                        posterior(:,:,s) = classreg.learning.ecocutils.posteriorFromRatio(M,pscore(:,:,s),...
                            lw,verbose,doquadprog,numfits,useParallel,RNGscheme);
                    end
                end
            end
        end
        
        
        function err = kfoldLoss(this,varargin)
        %KFOLDLOSS Classification error for observations not used for training.
        %   ERR=KFOLDLOSS(OBJ) returns a row-vector of classification error values
        %   obtained by cross-validated model OBJ with one value per element of the
        %   regularization parameter saved in the Lambda properties of the
        %   BinaryLearners model in the Trained cross-validation folds. For every
        %   fold, this method computes classification error for in-fold
        %   observations using a model trained on out-of-fold observations.
        %
        %   ERR=KFOLDLOSS(OBJ,'PARAM1',val1,'PARAM2',val2,...) specifies optional
        %   parameter name/value pairs:
        %       'Folds'                - Indices of folds ranging from 1 to KFold.
        %                                Use only these folds for predictions. By
        %                                default, all folds are used.
        %       'Mode'                 - 'average' (default) or 'individual'. If
        %                                'average', this method averages over all
        %                                folds. If 'individual', this method
        %                                returns an F-by-L matrix where F is the
        %                                number of folds and L is the number of
        %                                regularization values saved in the Lambda
        %                                properties of the BinaryLearners models in
        %                                the Trained folds.
        %       'LossFun'              - Function handle for loss, or string
        %                                'classiferror' representing a built-in
        %                                loss function. If you pass a function
        %                                handle FUN, KFOLDLOSS calls it as shown
        %                                below:
        %                                         FUN(C,S,W,COST)
        %                                where C is an N-by-K logical matrix for N
        %                                elements in Y and K classes in the ClassNames
        %                                property, S is an N-by-K numeric matrix, W
        %                                is a numeric vector with N elements, and
        %                                COST is a K-by-K numeric matrix. C has one
        %                                true per row for the true class. S is a
        %                                matrix of negated loss values for classes
        %                                with one row per observation, similar to
        %                                NEGLOSS output from KFOLDPREDICT. W is a
        %                                vector of observation weights. COST is a
        %                                matrix of misclassification costs.
        %                                Default: 'classiferror'
        %       'BinaryLoss'           - Function handle, or string representing a
        %                                built-in function for computing loss
        %                                induced by each binary learner. Available
        %                                loss functions for binary learners with
        %                                scores in the (-inf,+inf) range are:
        %                                'hamming', 'linear', 'exponential',
        %                                'binodeviance', 'hinge', and 'logit'.
        %                                Available loss functions for binary
        %                                learners with scores in the [0,1] range
        %                                are: 'hamming' and 'quadratic'. If you
        %                                pass a function handle FUN, KFOLDPREDICT
        %                                calls it as shown below:
        %                                      FUN(M,F)
        %                                where M is a K-by-L coding matrix saved in
        %                                the CodingMatrix property and F is a
        %                                1-by-L row-vector of scores computed by
        %                                the binary learners. Default: Value of the
        %                                BinaryLoss property
        %       'Decoding'             - String specifying the decoding scheme, either
        %                                'lossbased' or 'lossweighted'. Default:
        %                                'lossweighted'
        %       'Options'              - A struct that contains options specifying
        %                                whether to use parallel computation. This
        %                                argument can be created by a call to
        %                                STATSET. Set 'Options' to
        %                                statset('UseParallel',true) to use
        %                                parallel computation.
        %       'Verbose'              - Non-negative integer specifying the
        %                                verbosity level, either 0 or 1.
        %                                KFOLDLOSS does not display any
        %                                diagnostic messages at verbosity level 0
        %                                and displays diagnostic messages at
        %                                verbosity level 1. Default: 0
        %
        %   See also classreg.learning.partition.ClassificationPartitionedLinearECOC,
        %   kfoldPredict, Trained, ClassificationLinear/loss.
 
            classreg.learning.ensemble.Ensemble.catchUOFL(varargin{:});
            classreg.learning.FullClassificationRegressionModel.catchWeights(varargin{:});
            [mode,folds,extraArgs] = checkFoldArgs(this.PartitionedModel,varargin{:});

            % Process input args
            args = {       'lossfun'};
            defs = {this.DefaultLoss};
            [funloss,~,extraArgs] = ...
                internal.stats.parseArgs(args,defs,extraArgs{:});
            
            % Check loss function
            funloss = classreg.learning.internal.lossCheck(funloss,'classification');

            % Get negative loss values
            [~,negloss] = kfoldPredict(this,extraArgs{:});
            
            % Get everything
            L = size(negloss,3);
            C = this.PrivC;
            w = this.W;
            cost = this.Ensemble.Cost;

            % Apply loss function to predictions
            uofl = ~this.PrivGenerator.UseObsForIter;
            if     strncmpi(mode,'ensemble',length(mode))
                err = NaN(1,L);
                iuse = any(uofl(:,folds),2);
                for l=1:L
                    err(l) = funloss(C(iuse,:),negloss(iuse,:,l),w(iuse),cost);
                end
            elseif strncmpi(mode,'individual',length(mode))
                T = numel(folds);
                err = NaN(T,L);
                for k=1:T
                    t = folds(k);
                    iuse = uofl(:,t);
                    for l=1:L
                        err(k,l) = funloss(C(iuse,:),negloss(iuse,:,l),w(iuse),cost);
                    end
                end
            else
                error(message('stats:classreg:learning:partition:PartitionedModel:checkFoldArgs:BadMode'));
            end           
        end
        
        
        function e = kfoldEdge(this,varargin)            
        %KFOLDEDGE Classification edge for observations not used for training.
        %   E=KFOLDEDGE(OBJ) returns a row-vector of classification edge values
        %   (average classification margin) with one value per element of the
        %   regularization parameter saved in the Lambda properties of the
        %   BinaryLearners model in the Trained cross-validation folds. obtained by
        %   cross-validated classification model OBJ. For every fold, this method
        %   computes classification edge for in-fold observations using a model
        %   trained on out-of-fold observations.
        %
        %   E=KFOLDEDGE(OBJ,'PARAM1',val1,'PARAM2',val2,...) specifies optional
        %   parameter name/value pairs:
        %       'Folds'               - Indices of folds ranging from 1 to KFold.
        %                               Use only these folds for predictions. By
        %                               default, all folds are used.
        %       'Mode'                 - 'average' (default) or 'individual'. If
        %                                'average', this method averages over all
        %                                folds. If 'individual', this method
        %                                returns an F-by-L matrix where F is the
        %                                number of folds and L is the number of
        %                                regularization values saved in the Lambda
        %                                properties of the BinaryLearners models in
        %                                the Trained folds.
        %       'BinaryLoss'           - Function handle, or string representing a
        %                                built-in function for computing loss
        %                                induced by each binary learner. Available
        %                                loss functions for binary learners with
        %                                scores in the (-inf,+inf) range are:
        %                                'hamming', 'linear', 'exponential',
        %                                'binodeviance' and 'hinge'. Available loss
        %                                functions for binary learners with scores
        %                                in the [0,1] range are: 'hamming' and
        %                                'quadratic'. If you pass a function handle
        %                                FUN, KFOLDPREDICT calls it as shown below:
        %                                         FUN(M,F)
        %                                where M is a K-by-L coding matrix saved in
        %                                the CodingMatrix property and F is a
        %                                1-by-L row-vector of scores computed by
        %                                the binary learners. Default: Value of the
        %                                BinaryLoss property
        %       'Decoding'             - String specifying the decoding scheme, either
        %                                'lossbased' or 'lossweighted'. Default:
        %                                'lossweighted'
        %       'Options'              - A struct that contains options specifying
        %                                whether to use parallel computation. This
        %                                argument can be created by a call to
        %                                STATSET. Set 'Options' to
        %                                statset('UseParallel',true) to use
        %                                parallel computation.
        %       'Verbose'              - Non-negative integer specifying the
        %                                verbosity level, either 0 or 1. KFOLDEDGE
        %                                does not display any diagnostic messages
        %                                at verbosity level 0 and displays
        %                                diagnostic messages at verbosity level 1.
        %                                Default: 0
        %
        %   See also classreg.learning.partition.ClassificationPartitionedLinearECOC,
        %   kfoldPredict, kfoldMargin, Trained, ClassificationLinear/edge.

            e = kfoldLoss(this,'LossFun',@classreg.learning.loss.classifedge,varargin{:});
        end
        
        
        function m = kfoldMargin(this,varargin)
        %KFOLDMARGIN Classification margins for observations not used for training.
        %   M=KFOLDMARGIN(OBJ) returns an N-by-R matrix of classification margins
        %   obtained by cross-validated classification model OBJ for N observations
        %   in the input data and R values of the regularization parameter saved in
        %   the Lambda properties of the BinaryLearners model in the Trained
        %   cross-validation folds. For every fold, this method computes
        %   classification margins for in-fold observations using a model trained
        %   on out-of-fold observations.
        %
        %   M=KFOLDMARGIN(OBJ,X,Y,'PARAM1',val1,'PARAM2',val2,...) specifies
        %   optional parameter name/value pairs:
        %       'BinaryLoss'           - Function handle, or string representing a
        %                                built-in function for computing loss
        %                                induced by each binary learner. Available
        %                                loss functions for binary learners with
        %                                scores in the (-inf,+inf) range are:
        %                                'hamming', 'linear', 'exponential',
        %                                'binodeviance' and 'hinge'. Available loss
        %                                functions for binary learners with scores
        %                                in the [0,1] range are: 'hamming' and
        %                                'quadratic'. If you pass a function handle
        %                                FUN, KFOLDPREDICT calls it as shown below:
        %                                      FUN(M,F)
        %                                where M is a K-by-L coding matrix saved in
        %                                the CodingMatrix property and F is a
        %                                1-by-L row-vector of scores computed by
        %                                the binary learners. Default: Value of the
        %                                BinaryLoss property
        %       'Decoding'             - String specifying the decoding scheme, either
        %                                'lossbased' or 'lossweighted'. Default:
        %                                'lossweighted'
        %       'Options'              - A struct that contains options specifying
        %                                whether to use parallel computation. This
        %                                argument can be created by a call to
        %                                STATSET. Set 'Options' to
        %                                statset('UseParallel',true) to use
        %                                parallel computation.
        %       'Verbose'              - Non-negative integer specifying the
        %                                verbosity level, either 0 or 1.
        %                                KFOLDMARGIN does not display any
        %                                diagnostic messages at verbosity level 0
        %                                and displays diagnostic messages at
        %                                verbosity level 1. Default: 0
        %
        %   See also classreg.learning.partition.ClassificationPartitionedLinearECOC,
        %   kfoldPredict, Trained, ClassificationLinear/margin.
            
            classreg.learning.ensemble.Ensemble.catchUOFL(varargin{:});
            classreg.learning.partition.PartitionedModel.catchFolds(varargin{:});
            classreg.learning.FullClassificationRegressionModel.catchWeights(varargin{:});
            
            [~,negloss] = kfoldPredict(this,varargin{:});
            N = size(negloss,1);
            L = size(negloss,3);
            C = this.PrivC;
            
            m = NaN(N,L);
            for l=1:L
                m(:,l) = classreg.learning.loss.classifmargin(C,negloss(:,:,l));
            end
        end
    end
    
end
