classdef CompactClassificationECOC < classreg.learning.classif.ClassificationModel
%CompactClassificationECOC Error-correcting output code (ECOC) model.
%   CompactClassificationECOC is an ECOC model for multiclass learning.
%   This model can predict response for new data.
%
%   CompactClassificationECOC properties:
%       PredictorNames        - Names of predictors used for this model.
%       ExpandedPredictorNames - Names of expanded predictors.
%       CategoricalPredictors - Indices of categorical predictors.
%       ResponseName          - Name of the response variable.
%       ClassNames            - Names of classes in Y.
%       Cost                  - Misclassification costs.
%       Prior                 - Prior class probabilities.
%       ScoreTransform        - Transformation applied to predicted classification scores.
%       BinaryLearners        - Binary learners.
%       BinaryLoss            - Default binary loss function for prediction.
%       CodingMatrix          - Coding matrix.
%       LearnerWeights        - Weights for binary learners.
%
%   CompactClassificationECOC methods:
%       compareHoldout        - Compare two models using test data.
%       discardSupportVectors - Discard support vectors for linear SVM.
%       edge                  - Classification edge.
%       loss                  - Classification loss.
%       margin                - Classification margins.
%       predict               - Predicted response of this model.
%       selectModels          - Select a subset of regularized linear models.
%
%   See also ClassificationECOC.

%   Copyright 2014-2017 The MathWorks, Inc.
    
    properties(GetAccess=public,SetAccess=protected)
        %BINARYLEARNERS Binary learners.
        %   The BinaryLearners property is a cell array of trained binary learners.
        %   Element I of this array is the learner trained to solve the binary
        %   problem specified by column I of the coding matrix.
        %
        %   See also classreg.learning.classif.CompactClassificationECOC,
        %   CodingMatrix.
        BinaryLearners = {};
        
        %BINARYLOSS Default binary loss function for prediction.
        %   The BinaryLoss property is a string specifying the default function for
        %   computing loss incurred by each binary learner.
        %
        %   See also classreg.learning.classif.CompactClassificationECOC, predict.
        BinaryLoss = [];
        
        %CODINGMATRIX Coding matrix.
        %   The CodingMatrix property is a K-by-L matrix for K classes and L binary
        %   learners. Its elements take values -1, 0 or +1. If element (I,J) of
        %   this matrix is -1, class I is included in the negative class for binary
        %   learner J; if this element is +1, class I is included in the positive
        %   class for binary learner J; and if this element is 0, class I is not
        %   used for training binary learner J.
        %
        %   See also classreg.learning.classif.CompactClassificationECOC,
        %   BinaryLearners.
        CodingMatrix = [];
        
        %LEARNERWEIGHTS Weights for binary learners.
        %   The LearnerWeights property is a row-vector with L elements for L
        %   binary learners. Element I of this vector is the total weight of
        %   observations used to train binary learner I.
        %
        %   See also classreg.learning.classif.CompactClassificationECOC,
        %   BinaryLearners.
        LearnerWeights = [];
    end
    
    properties(GetAccess=protected,SetAccess=protected,Dependent=true)
        % True if any binary learner is of type ClassificationLinear
        IsLinear;
    end
    
    methods(Access=private, Static)
        function name = matlabCodegenRedirect(~)
            name = 'classreg.learning.coder.classif.CompactClassificationECOC';
        end
    end
    
    methods
        function islin = get.IsLinear(this)
            f = @(z) isa(z,'ClassificationLinear');
            islin = any(cellfun(f,this.BinaryLearners));
        end
    end
    
    methods(Access=protected)
        function this = setScoreType(~,~) %#ok<STOUT>
            error(message('stats:classreg:learning:classif:CompactClassificationECOC:setScoreType:DoNotUseScoreType'));
        end
        
        function cl = getContinuousLoss(this) %#ok<STOUT,MANU>
            % ContinuousLoss is replaced by BinaryLoss
            error(message('stats:classreg:learning:classif:CompactClassificationECOC:getContinuousLoss:DoNotUseContinuousLoss'));
        end
        
        function this = CompactClassificationECOC(...
                dataSummary,classSummary,scoreTransform,learners,weights,M)
            this = this@classreg.learning.classif.ClassificationModel(...
                dataSummary,classSummary,scoreTransform,[]);
            this.LabelPredictor = @classreg.learning.classif.ClassificationModel.maxScore;
            this.DefaultLoss = @classreg.learning.loss.classiferror;
            this.BinaryLearners = learners;
            this.LearnerWeights = weights;
            this.CodingMatrix = M;
            [this.BinaryLoss,this.DefaultScoreType] = ...
                classreg.learning.classif.CompactClassificationECOC.analyzeLearners(learners);
        end
        
        function s = propsForDisp(this,s)
            s = propsForDisp@classreg.learning.classif.ClassificationModel(this,s);
            s.BinaryLearners = this.BinaryLearners;
            s.CodingMatrix = this.CodingMatrix;
            
            if this.IsLinear
                s = rmfield(s,'CategoricalPredictors');
            end
        end
        
        function [labels,negloss,pscore,posterior] = predictEmptyX(this,X)
            Dexp = numel(this.PredictorNames);
            if this.ObservationsInRows
                D = size(X,2);
                str = getString(message('stats:classreg:learning:classif:ClassificationModel:predictEmptyX:columns'));
            else
                D = size(X,1);
                str = getString(message('stats:classreg:learning:classif:ClassificationModel:predictEmptyX:rows'));
            end
            if D~=Dexp
                error(message('stats:classreg:learning:classif:ClassificationModel:predictEmptyX:XSizeMismatch', Dexp, str));
            end
            labels = repmat(this.ClassNames(1,:),0,1);
            K = numel(this.ClassSummary.ClassNames);
            L = numel(this.BinaryLearners);
            negloss = NaN(0,K);
            pscore = NaN(0,L);
            posterior = NaN(0,K);
        end
        
        function [labels,negloss,pscore,posterior] = predictForEmptyLearners(this,X)
            Dexp = numel(this.PredictorNames);
            if this.ObservationsInRows
                [N,D] = size(X);
                str = getString(message('stats:classreg:learning:classif:ClassificationModel:predictEmptyX:columns'));
            else
                [D,N] = size(X);
                str = getString(message('stats:classreg:learning:classif:ClassificationModel:predictEmptyX:rows'));
            end
            if Dexp~=D
                error(message('stats:classreg:learning:classif:ClassificationModel:predictEmptyX:XSizeMismatch', D, str));
            end
            K = numel(this.ClassSummary.ClassNames);
            L = numel(this.BinaryLearners);
            
            [~,cls] = max(this.Prior);
            labels = repmat(this.ClassNames(cls,:),N,1);
            negloss = NaN(N,K);
            pscore = NaN(N,L);
            posterior = zeros(N,K);
            posterior(:,cls) = 1;
        end
        
        function [negloss,pscore] = score(...
                this,X,dist,isBuiltinDist,ignorezeros,useParallel,verbose)
            % Init
            trained = this.BinaryLearners;
            M = this.CodingMatrix;
            
            % Ignore zeros in the coding matrix?
            if ignorezeros
                M(M==0) = NaN;
            end
            
            if this.TableInput
                X = classreg.learning.internal.table2PredictMatrix(X,[],[],...
                    this.VariableRange,...
                    this.CategoricalPredictors,this.PredictorNames);
            end
            
            % Compute scores for positive class only
            pscore = localScore(X,trained,useParallel,verbose,this.ObservationsInRows);
            
            if verbose>0
                fprintf('%s\n',getString(message('stats:classreg:learning:classif:CompactClassificationECOC:score:PredictionsComputed')));
            end
                        
            % Loss per observation
            [N,~,S] = size(pscore);
            K = size(M,1);
            negloss = NaN(N,K,S,class(pscore));
            for s=1:S
                negloss(:,:,s) = -classreg.learning.ecocutils.loss(...
                    dist,M,pscore(:,:,s),useParallel,isBuiltinDist);
            end
            if verbose>0
                fprintf('%s\n',getString(message('stats:classreg:learning:classif:CompactClassificationECOC:score:LossComputed')));
            end            
        end    
    end
    
        
    methods
        function varargout = predict(this,X,varargin)
        %PREDICT Predict response of the ECOC model.
        %   [LABEL,NEGLOSS]=PREDICT(MODEL,X) returns predicted class labels LABEL
        %   and negated values of the average binary loss per class NEGLOSS for
        %   ECOC model MODEL and predictors X. X must be a table if MODEL was
        %   originally trained on a table, or a numeric matrix if MODEL was
        %   originally trained on a matrix. If X is a table, it must contain all
        %   the predictors used for training this model. If X is a matrix, X must
        %   have P columns, where P is the number of predictors used for training.
        %   Classification labels LABEL have the same type as Y used for training.
        %   Negative loss values NEGLOSS are an N-by-K matrix for N observations
        %   and K classes, where N is the number of observations (rows) in X. The
        %   predicted label is assigned to the class with the largest negated
        %   average binary loss, or equivalently smallest average binary loss.
        %
        %   If MODEL was trained using 'Linear' binary learners, PREDICT returns
        %   classification labels LABEL as an N-by-R array of the same type as Y
        %   used for training for N observations (rows) in X and R values of the
        %   regularization parameter saved in the Lambda properties of the
        %   BinaryLearners objects. Negative loss values NEGLOSS are an N-by-K-by-R
        %   matrix for N observations, K classes and R values of the regularization
        %   parameter.
        %
        %   [~,~,PBSCORE]=PREDICT(MODEL,X) also returns positive-class scores
        %   predicted by the binary learners, an N-by-L matrix for N observations
        %   and L binary learners. If MODEL was trained using 'linear' binary
        %   learners, PBSCORE is an N-by-L-by-R matrix for N observations, L binary
        %   learners and R values of the regularization parameter.
        %
        %   [~,~,~,POSTERIOR]=PREDICT(MODEL,X) also returns posterior probability
        %   estimates, an N-by-K matrix for N observations and K classes. If MODEL
        %   was trained using 'Linear' binary learners, POSTERIOR is an N-by-K-by-R
        %   matrix for N observations, K classes and R values of the
        %   regularization parameter. PREDICT cannot compute these estimates unless
        %   you passed 'FitPosterior' as true to FITCECOC. If you set
        %   'FitPosterior' to false for FITCECOC and request 4th output, PREDICT
        %   throws an error.
        %
        %   [...]=PREDICT(MODEL,X,'PARAM1',val1,'PARAM2',val2,...) specifies
        %   optional parameter name/value pairs:
        %       'ObservationsIn'       - If MODEL was trained using 'linear' binary
        %                                learners, you can pass string specifying
        %                                the data orientation, either 'rows' or
        %                                'columns'. Default: 'rows'
        %                              NOTE: Passing observations in columns for
        %                                    the 'linear' learner can significantly
        %                                    speed up prediction.
        %       'BinaryLoss'           - Function handle, or string representing a
        %                                built-in function for computing loss
        %                                induced by each binary learner. Available
        %                                loss functions for binary learners with
        %                                scores in the (-inf,+inf) range are:
        %                                'hamming', 'linear', 'exponential',
        %                                'binodeviance', 'hinge', 'logit', and
        %                                'quadratic'. Available loss functions for
        %                                binary learners with scores in the [0,1]
        %                                range are: 'hamming' and 'quadratic'. If
        %                                you pass a function handle FUN, PREDICT
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
        %                                the Kullback-Leibler divergence. PREDICT
        %                                ignores this parameter unless you request
        %                                4th output and set 'PosteriorMethod' to
        %                                'kl'. Default: 0
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
        %                                learners. PREDICT ignores this parameter
        %                                unless you request 4th output. Default:
        %                                'kl'
        %       'Verbose'              - Non-negative integer specifying the
        %                                verbosity level, either 0 or 1. PREDICT
        %                                does not display any diagnostic messages
        %                                at verbosity level 0 and displays
        %                                diagnostic messages at verbosity level 1.
        %                                Default: 0
        %
        %   See also classreg.learning.classif.CompactClassificationECOC, fitcecoc,
        %   BinaryLoss, BinaryLearners, CodingMatrix, statset.            
            [varargin{:}] = convertStringsToChars(varargin{:});
            % Handle input data such as "tall" requiring a special adapter
            adapter = classreg.learning.internal.makeClassificationModelAdapter(this,X,varargin{:});
            if ~isempty(adapter)            
                [varargout{1:max(1,nargout)}] = predict(adapter,X,varargin{:});
                return
            end
            
            if this.IsLinear
                internal.stats.checkSupportedNumeric('X',X,false,true);
            end
        
            % Get the right orientation
            [X,varargin] = classreg.learning.internal.orientX(...
                X,this.ObservationsInRows,varargin{:});
            
            % Empty data
            if isempty(X)
                if this.TableInput || istable(X)
                    vrange = getvrange(this);
                    X = classreg.learning.internal.table2PredictMatrix(X,[],[],...
                        vrange,...
                        this.CategoricalPredictors,this.PredictorNames);
                end
                [varargout{1:max(1,nargout)}] = predictEmptyX(this,X);
                return;
            end
                        
            % If all binary learners are empty, predict into the majority
            % class.
            if all(cellfun(@isempty,this.BinaryLearners))
                [varargout{1:max(1,nargout)}] = predictForEmptyLearners(this,X);
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
            
            % Get parallel options
            [useParallel,RNGscheme] = ...
                internal.stats.parallel.processParallelAndStreamOptions(paropts);
            
            % Get loss and score for the positive class
            [negloss,pscore] = score(...
                this,X,dist,isBuiltinDist,ignorezeros,useParallel,verbose);
            [N,~,S] = size(pscore);
            
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
                if S==1
                    posterior = classreg.learning.ecocutils.posteriorFromRatio(...
                        this.CodingMatrix,pscore,this.LearnerWeights,...
                        verbose,doquadprog,numfits,useParallel,RNGscheme);
                else
                    K = size(this.CodingMatrix,1);
                    posterior = NaN(N,K,S);
                    for s=1:S
                        posterior(:,:,s) = classreg.learning.ecocutils.posteriorFromRatio(...
                            this.CodingMatrix,pscore(:,:,s),this.LearnerWeights,...
                            verbose,doquadprog,numfits,useParallel,RNGscheme);
                    end
                end
            end
            
            if doposterior
                varargout = {labels,negloss,pscore,posterior};
            else
                varargout = {labels,negloss,pscore};
            end
        end
        
        function m = margin(this,X,varargin)
        %MARGIN Classification margins.
        %   M=MARGIN(MODEL,X,Y) returns classification margins obtained by MODEL
        %   for predictors X and class labels Y. X must be a table if MODEL was
        %   originally trained on a table, or a numeric matrix if MODEL was
        %   originally trained on a matrix.  If X is a table, it must contain all
        %   the predictors used for training this model. If X is a matrix, it must
        %   have size N-by-P, where P is the number of predictors used for
        %   training. Y must be of the same type as MODEL.ClassNames and have N
        %   elements, where N is the number of rows in X. Y can be omitted if X is
        %   a table that includes the response variable. Classification margin is
        %   the difference between classification score for the true class and
        %   maximal classification score for the false classes. The returned M is a
        %   numeric column-vector of length N.
        %
        %   If MODEL was trained using 'Linear' binary learners, X must be a
        %   matrix. The returned M is an N-by-R array for N observations (rows) in
        %   X and R values of the regularization parameter saved in the Lambda
        %   properties of the BinaryLearners objects.
        %
        %   M=MARGIN(MODEL,X,Y,'PARAM1',val1,'PARAM2',val2,...) specifies optional
        %   parameter name/value pairs:
        %       'ObservationsIn'       - If MODEL was trained using 'linear' binary
        %                                learners, you can pass string specifying
        %                                the data orientation, either 'rows' or
        %                                'columns'. Default: 'rows'
        %                              NOTE: Passing observations in columns for
        %                                    the 'linear' learner can significantly
        %                                    speed up prediction.
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
        %                                FUN, PREDICT calls it as shown below:
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
        %                                verbosity level, either 0 or 1. MARGIN
        %                                does not display any diagnostic messages
        %                                at verbosity level 0 and displays
        %                                diagnostic messages at verbosity level 1.
        %                                Default: 0
        %
        %   See also classreg.learning.classif.CompactClassificationECOC,
        %   predict.
            [varargin{:}] = convertStringsToChars(varargin{:});
            % Handle input data such as "tall" requiring a special adapter
            adapter = classreg.learning.internal.makeClassificationModelAdapter(this,X,varargin{:});
            if ~isempty(adapter)            
                m = slice(adapter,@this.margin,X,varargin{:});
                return
            end
        
            if this.IsLinear
                internal.stats.checkSupportedNumeric('X',X,false,true);
            end
            m = margin@classreg.learning.classif.ClassificationModel(this,X,varargin{:});
        end
        
        function e = edge(this,X,varargin)
        %EDGE Classification edge.
        %   E=EDGE(MODEL,X,Y) returns classification edge obtained by MODEL for
        %   predictors X and class labels Y. X must be a table if MODEL was
        %   originally trained on a table, or a numeric matrix if MODEL was
        %   originally trained on a matrix.  If X is a table, it must contain all
        %   the predictors used for training this model. If X is a matrix, it must
        %   have size N-by-P, where P is the number of predictors used for
        %   training. Y must be of the same type as MODEL.ClassNames and have N
        %   elements, where N is the number of rows in X. Y can be omitted if X is
        %   a table that includes the response variable. Classification edge is
        %   classification margin averaged over the entire data.
        %
        %   If MODEL was trained using 'Linear' binary learners, X must be a
        %   matrix. The returned edge E is a 1-by-R vector for R values of the
        %   regularization parameter saved in the Lambda properties of the
        %   BinaryLearners objects.
        %
        %   E=EDGE(OBJ,X,Y,'PARAM1',val1,'PARAM2',val2,...) specifies optional
        %   parameter name/value pairs:
        %       'ObservationsIn' - If MODEL was trained using 'linear' binary
        %                          learners, you can pass string specifying the
        %                          data orientation, either 'rows' or 'columns'.
        %                          Default: 'rows'
        %                         NOTE: Passing observations in columns for
        %                               the 'linear' learner can significantly
        %                               speed up prediction.
        %       'Weights'   - Vector of observation weights. By default the weight
        %                     of every observation is set to 1. The length of this
        %                     vector must be equal to the number of rows in X.
        %                     If X is a table, this may be the name of a variable
        %                     in the table. If you supply weights, EDGE computes
        %                     weighted classification edge.
        %       'BinaryLoss' - Function handle, or string representing a built-in
        %                      function for computing loss induced by each binary
        %                      learner. Available loss functions for binary
        %                      learners with scores in the (-inf,+inf) range are:
        %                      'hamming', 'linear', 'exponential', 'binodeviance'
        %                      and 'hinge'. Available loss functions for binary
        %                      learners with scores in the [0,1] range are:
        %                      'hamming' and 'quadratic'. If you pass a function
        %                      handle FUN, PREDICT calls it as shown below:
        %                                      FUN(M,F)
        %                      where M is a K-by-L coding matrix saved in the
        %                      CodingMatrix property and F is a 1-by-L row-vector
        %                      of scores computed by the binary learners. Default:
        %                      Value of the BinaryLoss property
        %       'Decoding'   - String specifying the decoding scheme, either
        %                      'lossbased' or 'lossweighted'.
        %                      Default: 'lossweighted'
        %       'Options'    - A struct that contains options specifying whether
        %                      to use parallel computation. This argument can be
        %                      created by a call to STATSET. Set 'Options' to
        %                      statset('UseParallel',true) to use parallel
        %                      computation.
        %       'Verbose'    - Non-negative integer specifying the verbosity level,
        %                      either 0 or 1. EDGE does not display any diagnostic
        %                      messages at verbosity level 0 and displays
        %                      diagnostic messages at verbosity level 1. Default: 0
        %
        %   See also classreg.learning.classif.CompactClassificationECOC,
        %   classreg.learning.classif.CompactClassificationECOC/margin.
            [varargin{:}] = convertStringsToChars(varargin{:});
            % Handle input data such as "tall" requiring a special adapter
            adapter = classreg.learning.internal.makeClassificationModelAdapter(this,X,varargin{:});
            if ~isempty(adapter)            
                e = edge(adapter,X,varargin{:});
                return
            end
        
            if this.IsLinear
                internal.stats.checkSupportedNumeric('X',X,false,true);
            end
            e = edge@classreg.learning.classif.ClassificationModel(this,X,varargin{:});
        end
        
        function l = loss(this,X,varargin)
        %LOSS Classification error.
        %   L=LOSS(MODEL,X,Y) returns classification error for model MODEL computed
        %   using predictors X and true class labels Y. X must be a table if MODEL
        %   was originally trained on a table, or a numeric matrix if MODEL was
        %   originally trained on a matrix.  If X is a table, it must contain all
        %   the predictors used for training this model. If X is a matrix, it must
        %   have size N-by-P, where P is the number of predictors used for
        %   training. Y must be of the same type as MODEL.ClassNames and have N
        %   elements, where N is the number of rows in X. Y can be omitted if X is
        %   a table that includes the response variable.
        %
        %   If MODEL was trained using 'Linear' binary learners, X must be a
        %   matrix. The returned loss L is a 1-by-R vector for R values of the
        %   regularization parameter saved in the Lambda properties of the
        %   BinaryLearners objects.
        %
        %   L=LOSS(MODEL,X,Y,'PARAM1',val1,'PARAM2',val2,...) specifies optional
        %   parameter name/value pairs:
        %       'ObservationsIn' - If MODEL was trained using 'linear' binary
        %                          learners, you can pass string specifying the
        %                          data orientation, either 'rows' or 'columns'.
        %                          Default: 'rows'
        %                         NOTE: Passing observations in columns for
        %                               the 'linear' learner can significantly
        %                               speed up prediction.
        %       'LossFun'   - Function handle for loss, or string
        %                     'classiferror' representing a built-in loss function.
        %                     If you pass a function handle FUN, LOSS calls it as
        %                     shown below:
        %                           FUN(C,S,W,COST)
        %                     where C is an N-by-K logical matrix for N elements in
        %                     Y and K classes in the ClassNames property, S is an
        %                     N-by-K numeric matrix, W is a numeric vector with N
        %                     elements, and COST is a K-by-K numeric matrix. C has
        %                     one true per row for the true class. S is a matrix of
        %                     negated loss values for classes with one row per
        %                     observation, similar to NEGLOSS output from PREDICT.
        %                     W is a vector of observation weights. COST is a
        %                     matrix of misclassification costs. Default:
        %                     'classiferror'
        %       'Weights'   - Vector of observation weights. By default the weight
        %                     of every observation is set to 1. The length of this
        %                     vector must be equal to the number of rows in X.
        %                     If X is a table, this may be the name of a variable
        %                     in the table.
        %       'BinaryLoss' - Function handle, or string representing a built-in
        %                      function for computing loss induced by each binary
        %                      learner. Available loss functions for binary
        %                      learners with scores in the (-inf,+inf) range are:
        %                      'hamming', 'linear', 'exponential', 'binodeviance',
        %                      'hinge', and 'logit'. Available loss functions for
        %                      binary learners with scores in the [0,1] range are:
        %                      'hamming' and 'quadratic'. If you pass a function
        %                      handle FUN, PREDICT calls it as shown below:
        %                            FUN(M,F)
        %                      where M is a K-by-L coding matrix saved in the
        %                      CodingMatrix property and F is a 1-by-L row-vector
        %                      of scores computed by the binary learners. Default:
        %                      Value of the BinaryLoss property
        %       'Decoding'   - String specifying the decoding scheme, either
        %                      'lossbased' or 'lossweighted'.
        %                      Default: 'lossweighted'
        %       'Options'    - A struct that contains options specifying whether to
        %                      use parallel computation. This argument can be
        %                      created by a call to STATSET. Set 'Options' to
        %                      statset('UseParallel',true) to use parallel
        %                      computation.
        %       'Verbose'    - Non-negative integer specifying the verbosity level,
        %                      either 0 or 1. LOSS does not display any diagnostic
        %                      messages at verbosity level 0 and displays
        %                      diagnostic messages at verbosity level 1. Default: 0
        %
        %   See also classreg.learning.classif.CompactClassificationECOC, 
        %   BinaryLearners, predict.
            [varargin{:}] = convertStringsToChars(varargin{:});
            % Handle input data such as "tall" requiring a special adapter
            adapter = classreg.learning.internal.makeClassificationModelAdapter(this,X,varargin{:});
            if ~isempty(adapter)            
                l = loss(adapter,X,varargin{:});
                return
            end
        
            if this.IsLinear
                internal.stats.checkSupportedNumeric('X',X,false,true);
            end
            l = loss@classreg.learning.classif.ClassificationModel(this,X,varargin{:});
        end
        
        function this = discardSupportVectors(this)
        %DISCARDSUPPORTVECTORS Discard support vectors for linear SVM binary learners.
        %   OBJ=DISCARDSUPPORTVECTORS(OBJ) empties the Alpha, SupportVectors, and
        %   SupportVectorLabels properties of binary learners that are linear SVM
        %   models. After these properties are emptied, the PREDICT method can compute
        %   predictions from those binary learners using their Beta properties.
        %
        %   See also classreg.learning.classif.CompactClassificationSVM, BinaryLearners,
        %   predict.
        
            % Find linear SVM learners
            f = @(z) isa(z,'classreg.learning.classif.CompactClassificationSVM') ...
                && strcmp(z.KernelParameters.Function,'linear');
            isLinearSVM = cellfun(f,this.BinaryLearners);
            
            % If no such learners, warn
            if ~any(isLinearSVM)
                warning(message('stats:classreg:learning:classif:CompactClassificationECOC:discardSupportVectors:NoLinearSVMLearners'));
                return;
            end
        
            % Discard SV's for linear SVM's
            idxLinearSVM = find(isLinearSVM);
            for i=1:numel(idxLinearSVM)
                n = idxLinearSVM(i);
                this.BinaryLearners{n} = discardSupportVectors(this.BinaryLearners{n});
            end
        end
        
        function this = selectModels(this,idx)
        %SELECTMODELS Select fitted regularized models for linear binary learner.
        %   OBJ2=selectModels(OBJ1,IDX) copies models with indices IDX from OBJ1 to
        %   OBJ2. Pass OBJ1 as an object of type CompactClassificationECOC obtained
        %   by fitting linear binary models. selectModels returns OBJ2 of the same
        %   type as OBJ1. Pass IDX as a vector of indices between 1 and the number
        %   of regularization parameter values stored in the Lambda properties of
        %   BinaryLearners.
        %
        %   See also ClassificationLinear, BinaryLearners.
            
            % Check idx
            if ~isnumeric(idx) || ~isvector(idx) || ~isreal(idx) || any(idx(:)<0) ...
                    || any(round(idx)~=idx)
                error(message('stats:classreg:learning:classif:CompactClassificationECOC:selectModels:BadIdx'));
            end
            
            % Find linear learners
            f = @(z) isa(z,'ClassificationLinear');
            isLinear = cellfun(f,this.BinaryLearners);
            
            % If not all learners are linear, error
            if ~all(isLinear)
                error(message('stats:classreg:learning:classif:CompactClassificationECOC:selectModels:NonLinearLearners'));
            end
            
            % Select models
            T = numel(this.BinaryLearners);
            for t=1:T
                this.BinaryLearners{t} = selectModels(this.BinaryLearners{t},idx);
            end
        end
    end
    
    methods(Hidden=true)
        % Have compact method in case someone wants to execute compact on
        % an ECOC model with fast linear solver.
        function cmp = compact(this)
            cmp = this;
        end
        
        function s = toStruct(this)
            % Convert to a struct for codegen.
            
            warnState  = warning('query','all');
            warning('off','MATLAB:structOnObject');
            cleanupObj = onCleanup(@() warning(warnState));
            
            % convert common properties to struct
            s = classreg.learning.coderutils.classifToStruct(this);
            
            % save the path to the fromStruct method
            s.FromStructFcn = 'classreg.learning.classif.CompactClassificationECOC.fromStruct';
            
            % binary learners
            learners = this.BinaryLearners;
            L = numel(learners);
            learners_struct = struct;
            
            for j=1:L
                fname = ['Learner_' num2str(j)];
                if isempty(learners{j})
                    learners_struct.(fname) = learners{j};
                else
                    if ~isa(learners{j},'classreg.learning.classif.CompactClassificationSVM') ...
                            && ~isa(learners{j},'ClassificationLinear')
                        error(message('stats:classreg:learning:classif:CompactClassificationECOC:toStruct:NonSVMorLinearLearnersNotSupported'));
                    end
                    learners_struct.(fname) = learners{j}.toStruct;
                end
            end
            
            s.NumBinaryLearners = L;
            s.BinaryLearners = learners_struct;
            
            % Other ECOC properties
            s.CodingMatrix        = this.CodingMatrix;
            s.LearnerWeights      = this.LearnerWeights;
            s.BinaryLoss          = this.BinaryLoss;
        end
    end
    
    methods(Static=true,Hidden=true)
        function obj = fromStruct(s)
            % Make an ECOC object from a codegen struct.
            
            s = classreg.learning.coderutils.structToClassif(s);

            % Prepare a cell array of learners
            L = s.NumBinaryLearners;
            learners = cell(L,1);
            
            for j=1:L
                fname = ['Learner_' num2str(j)];
                learner_struct = s.BinaryLearners.(fname);
                if ~isempty(learner_struct)
                    fcn = str2func(learner_struct.FromStructFcn);
                    learners{j} = fcn(learner_struct);
                else
                    learners{j} = learner_struct;
                end
            end
            
            % Make an object
            obj = classreg.learning.classif.CompactClassificationECOC(...
                s.DataSummary,s.ClassSummary,s.ScoreTransform,...
                learners,s.LearnerWeights,s.CodingMatrix);
            
            % Check binary loss
            if ~strcmp(obj.BinaryLoss,s.BinaryLoss)
                error(message('stats:classreg:learning:classif:CompactClassificationECOC:fromStruct:BinaryLossMismatch'));
            end
        end
        
        function [lossType,scoreType] = analyzeLearners(learners)
            if isempty(learners)
                lossType = 'hamming';
                scoreType = 'unknown';
                return;
            end

            % Fill score and object type per learner
            L = numel(learners);
            scoreTypes = repmat({''},L,1);
            lossTypes  = repmat({''},L,1);
            for l=1:L
                lrn = learners{l};
                if ~isempty(lrn)
                    scoreTypes(l) = {lrn.ScoreType};
                    lossTypes(l)  = {lossToString(lrn.ContinuousLoss)};
                end
            end
               
            % Figure out the score type
            if     ismember('unknown',scoreTypes)
                scoreType = 'unknown';
                warning(message('stats:classreg:learning:classif:CompactClassificationECOC:analyzeLearners:UnknownScoreType'));
            elseif (ismember('01',scoreTypes) || ismember('probability',scoreTypes)) ...
                    && ismember('inf',scoreTypes)
                scoreType = 'unknown';
                warning(message('stats:classreg:learning:classif:CompactClassificationECOC:analyzeLearners:ScoreRangeMismatch'));
            elseif ismember('01',scoreTypes)
                scoreType = '01';
            elseif ismember('probability',scoreTypes)
                scoreType = 'probability';
            elseif ismember('inf',scoreTypes)
                scoreType = 'inf';
            else
                % We get here if all learners are empty, that is, none was
                % trained successfully.
                scoreType = 'unknown';
            end

            %
            % Figure out the default loss.
            %            
            lossTypes(strcmp(lossTypes,'')) = [];
            lossTypes = unique(lossTypes);
            if     isempty(lossTypes) % if all learners are empty, no loss is set
                lossType = '';
                warning(message('stats:classreg:learning:classif:CompactClassificationECOC:analyzeLearners:AllLearnersEmpty'));
            elseif strcmp(scoreType,'unknown') % if scoreType is unknown, warning has been thrown already
                lossType = '';
            elseif numel(lossTypes)==1 % set the unique loss
                lossType = lossTypes{1};
            else % if there is no unique loss and scoreType is known, set to hamming
                lossType = 'hamming';
                warning(message('stats:classreg:learning:classif:CompactClassificationECOC:analyzeLearners:HammingLoss'));
            end
        end
    end
       
end


function str = lossToString(fhandle)
if     isequal(fhandle,@classreg.learning.loss.quadratic)
    str = 'quadratic';
elseif isequal(fhandle,@classreg.learning.loss.hinge)
    str = 'hinge';
elseif isequal(fhandle,@classreg.learning.loss.exponential)
    str = 'exponential';
elseif isequal(fhandle,@classreg.learning.loss.binodeviance)
    str = 'binodeviance';
else
    str = 'unknown';
end
end


function pscore = localScore(X,trained,useParallel,verbose,obsInRows)

if obsInRows
    N = size(X,1);
    predictArgs = {};
else
    N = size(X,2);
    predictArgs = {'ObservationsIn' 'columns'};
end
T = numel(trained);

pscore_cell = ...
    internal.stats.parallel.smartForSliceout(T,@loopBody,useParallel);

allS = cellfun(@(z) size(z,3),pscore_cell);
S = unique(allS(allS>1));

if numel(S)>1
    error(message('stats:classreg:learning:classif:CompactClassificationECOC:localScore:BinaryScoreSizeMismatch'));
end

if isempty(S)
    S = 1;
end

isSingle = any(cellfun(@(z) isa(z,'single'),pscore_cell));
if isSingle
    pscore = NaN(N,T,S,'single');
else
    pscore = NaN(N,T,S);
end

for t=1:T
    if S>1 && isvector(pscore_cell{t})
        pscore(:,t,:) = repmat(pscore_cell{t},1,1,S);
    else
        pscore(:,t,:) = pscore_cell{t};
    end
end

    function lscore = loopBody(l,~)
        if verbose>1
            fprintf('%s\n',getString(message('stats:classreg:learning:classif:CompactClassificationECOC:localScore:ProcessingLearner',l)));
        end
        
        if isempty(trained{l})
            lscore = {NaN(N,1)};
        else
            [~,s] = predict(trained{l},X,predictArgs{:});
            lscore = {s(:,2,:)};
        end
    end
end
