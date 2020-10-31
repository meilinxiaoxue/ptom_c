function [score,cachedScore,cachedWeights,cached] = predictOneWithCache(X,cachedScore,cachedWeights,combiner,weak_learner,classifByBinRegr,learnerWeights,cached,...
                            classnames,nonzeroProbClasses,usePredForLearner,useObsForLearner,initCache,classif) %#codegen
    % Predict. The combiner object aggregates scores from
    % individual learners. The score returned by combiner is the
    % aggregated score.
    % Make scores of correct size

    %   Copyright 2016-2017 The MathWorks, Inc.

coder.internal.prefer_const(classif);
coder.internal.prefer_const(classifByBinRegr);
coder.internal.prefer_const(classnames);
coder.internal.prefer_const(nonzeroProbClasses);
NONFINITES = eml_option('NonFinitesSupport');
[T,P] = size(cachedScore);
N = size(X,1);
if classif
    if coder.target('MATLAB')
        defaultScore = NaN;
        learnerscore = NaN(coder.internal.indexInt(T),coder.internal.indexInt(P));      
    else
        defaultScore = coder.internal.nan;
        learnerscore = coder.internal.nan(coder.internal.indexInt(T),coder.internal.indexInt(P));        
    end
    % Match classes
    [~,pos] = ismember(weak_learner.ClassNames,classnames,'rows');
else
    learnerscore = zeros( coder.internal.indexInt(T),coder.internal.indexInt(P)); 
end

obsToUseIdx = useObsForLearner;
predToUseIdx = usePredForLearner;
if any(useObsForLearner)
    
    % If not all predictors have been used to train learner t,
    % treat this as proof that the ensemble has been grown by
    % random subspace. In that case, do not compute predictions
    % for observations with missing inputs. To compute
    % prediction for an observation with missing values,
    % subspace ensemble averages over learners trained on
    % non-missing inputs.
    if ~all(predToUseIdx)
        if NONFINITES
            obsToUseIdx = false(coder.internal.indexInt(N),1);
            for ii = 1:coder.internal.indexInt(N) 
                if useObsForLearner(ii)   
                    if ~any(isnan(X(ii,predToUseIdx)))
                        obsToUseIdx(ii) = true; 
                    end
                end
            end          
        end
    end
    if classif
        if classifByBinRegr
            s = predict(weak_learner,X(obsToUseIdx,predToUseIdx));
            learnerscore(obsToUseIdx,pos) = [s -s]; 
        else
            [~,learnerscore(obsToUseIdx,pos)] = predict(weak_learner,X(obsToUseIdx,predToUseIdx));
        end
    else
         learnerscore(obsToUseIdx) = predict(weak_learner,X(obsToUseIdx,predToUseIdx));
    end
    
end

if initCache    
    cachedScore(obsToUseIdx,:) = 0;
else
    tf = isnan(cachedScore);
    if any(tf(:))
        cachedScore(tf & repmat(obsToUseIdx,1,coder.internal.indexInt(size(cachedScore,2)))) = 0;
    end
end

[score,cachedScore,cachedWeights,cached] = classreg.learning.coder.ensembleutils.updateCache(learnerscore,coder.ignoreConst(cachedScore),coder.ignoreConst(cachedWeights),cached,learnerWeights,combiner,obsToUseIdx);

if classif
    % Assign scores only for classes with non-zero probability
    [~,loc] = ismember(classnames,nonzeroProbClasses,'rows');
    score(:,~loc) = defaultScore;
end

end