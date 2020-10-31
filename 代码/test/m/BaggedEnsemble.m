classdef BaggedEnsemble
%BaggedEnsemble Ensemble grown by resampling.
%   BaggedEnsemble is the super class for ensemble models grown by
%   resampling the training data.
    
%   Copyright 2010-2016 The MathWorks, Inc.


    properties(GetAccess=public,SetAccess=protected,Abstract=true)
        ModelParams;
        PrivX;
        PrivY;
        W;
    end
    
    properties(GetAccess=public,SetAccess=protected,Dependent=true)
        %FRESAMPLE Fraction of training data for resampling.
        %   The FResample property is a numeric scalar between 0 and 1. It is set
        %   to the fraction of the training data resampled at random for every weak
        %   learner in this ensemble.
        %
        %   See also classreg.learning.ensemble.BaggedEnsemble.
        FResample;
        
        %REPLACE Flag indicating if training data were sampled with replacement.
        %   The Replace property is a logical flag. It is set to true if the
        %   training data for weak learners in this ensemble were sampled with
        %   replacement and set to false otherwise.
        %
        %   See also classreg.learning.ensemble.BaggedEnsemble.
        Replace;
        
        %USEOBSFORLEARNER Use observations for learners.
        %   The UseObsForLearner property is a logical matrix of size
        %   N-by-NumTrained, where N is the number of observations in the training
        %   data and NumTrained is the number of trained weak learners. An element
        %   (I,J) of this matrix is set to true if observation I was used for
        %   training learner J and set to false otherwise.
        %
        %   See also classreg.learning.ensemble.BaggedEnsemble.
        UseObsForLearner;
    end
    
    methods(Abstract)
        l = loss(this,X,Y,varargin)
    end
    
    methods(Access=protected)
        function this = BaggedEnsemble()
        end
        
        function s = propsForDisp(this,s)
            if nargin<2 || isempty(s)
                s = struct;
            else
                if ~isstruct(s)
                    error(message('stats:classreg:learning:ensemble:BaggedEnsemble:propsForDisp:BadS'));
                end
            end
            s.FResample = this.FResample;
            s.Replace = this.Replace;
            s.UseObsForLearner = this.UseObsForLearner;
        end
    end
    
    methods
        function fresample = get.FResample(this)
            fresample = this.ModelParams.Generator.FResample;
        end
        
        function replace = get.Replace(this)
            replace = this.ModelParams.Generator.Replace;
        end
        
        function usenfort = get.UseObsForLearner(this)
            usenfort = this.ModelParams.Generator.UseObsForIter;
        end
        
        function imp = oobPermutedPredictorImportance(this,varargin)
        %oobPermutedPredictorImportance Estimates of predictor importance by permutation of out-of-bag predictions
        %   IMP=oobPermutedPredictorImportance(ENS) returns a 1-by-P array of
        %   importance estimates IMP for P predictors. For each predictor, this
        %   estimate is the increase in prediction error if the values of that
        %   predictor are permuted across the out-of-bag observations. The increase
        %   in the prediction error for each predictor is computed for every weak
        %   learner, then averaged over the entire ensemble for that predictor and
        %   divided by the standard deviation over the entire ensemble for that
        %   predictor.
        %
        %   IMP=oobPermutedPredictorImportance(ENS,'PARAM1',val1,'PARAM2',val2,...)
        %   specifies optional parameter name/value pairs:
        %       'Learners'         - Indices of weak learners in the ensemble
        %                            ranging from 1 to NumTrained. Only these
        %                            learners are used for making predictions. By
        %                            default, all learners are used.
        %       'Options'          - A struct that contains options specifying
        %                            whether to use parallel computation. This
        %                            argument can be created by a call to STATSET.
        %                            Set 'Options' to statset('UseParallel',true)
        %                            to use parallel computation.
        %
        %   See also classreg.learning.ensemble.BaggedEnsemble, oobLoss, loss,
        %   predictorImportance, statset, parallelstats.

            % Catch unwanted inputs
            classreg.learning.ensemble.Ensemble.catchUOFL(varargin{:});
            classreg.learning.FullClassificationRegressionModel.catchWeights(varargin{:});
            usenfort = ~this.ModelParams.Generator.UseObsForIter;
            
            % Get number of predictors
            D = this.DataSummary.PredictorNames;
            if ~isnumeric(D)
                D = numel(D);
            end

            % Get weak learners
            trained = this.Trained;
            T = numel(trained);

            % Decode input args
            args = {'learners'           'options'};
            defs = {       1:T statset('parallel')};
            [learners,paropts] = internal.stats.parseArgs(args,defs,varargin{:});

            % Check learner indices
            if islogical(learners)
                if ~isvector(learners) || length(learners)~=T
                    error(message('stats:classreg:learning:ensemble:CompactEnsemble:checkAggregateArgs:BadLogicalIndices', T));
                end
                learners = find(learners);
            end
            if ~isempty(learners) && ...
                    (~isnumeric(learners) || ~isvector(learners) || min(learners)<=0 || max(learners)>T)
                error(message('stats:classreg:learning:ensemble:CompactEnsemble:checkAggregateArgs:BadNumericIndices', T));
            end
            learners = ceil(learners);

            % Get parallel options
            [useParallel,RNGscheme] = ...
                internal.stats.parallel.processParallelAndStreamOptions(paropts);
            
            % Initialize importance measures
            T = numel(learners);            
            Imp = NaN(T,D);

            % Loop over learners
            for j=1:T
                t = learners(j);
                
                Xoob = this.PrivX(usenfort(:,t),:);
                Yoob = this.PrivY(usenfort(:,t));
                Woob = this.W(usenfort(:,t));
                
                one_learner = trained{t};
                err = loss(one_learner,Xoob,Yoob,'Weights',Woob);
                
                Imp(t,:) = localPermutedImp(...
                    err,one_learner,Xoob,Yoob,Woob,D,useParallel,RNGscheme);
            end
            
            mu = mean(Imp,1);
            sigma = std(Imp,1,1);

            imp = zeros(1,D);
            above0 = sigma>0 | mu>0;
            imp(above0)  = mu(above0)./sigma(above0);
        end
    end
    
end


function imp = localPermutedImp(err0,learner,Xoob,Yoob,Woob,D,useParallel,RNGscheme)

imp = zeros(D,1);

if isempty(Xoob)
    return;
end

% For decision trees, restrict search to predictors that have been split
% on.
if isa(learner,'classreg.learning.classif.CompactClassificationTree') ...
        || isa(learner,'classreg.learning.regr.CompactRegressionTree')
    used = find( predictorImportance(learner) > 0 );
else
    used = 1:D;
end

err = internal.stats.parallel.smartForSliceout(...
    numel(used), @loopBody, useParallel, RNGscheme);

imp(used) = err - err0;

    % Nested function for parfor
    function err = loopBody(j,s)
        if isempty(s)
            s = RandStream.getGlobalStream;
        end
        
        d = used(j);
        
        Noob = size(Xoob,1);
        
        permuted = randperm(s,Noob);

        Xperm = Xoob;
        Xperm(:,d) = Xoob(permuted,d);
        
        err = loss(learner,Xperm,Yoob,'Weights',Woob(permuted));
    end
end
