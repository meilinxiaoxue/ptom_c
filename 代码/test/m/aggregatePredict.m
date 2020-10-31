function score = aggregatePredict(X,score,combiner,trained,classifByBinRegr,learnerWeights,isCached,classNames,nonzeroProbClasses,...
    usePredForLearner,learners,useObsForLearner,classif) %#codegen

    % aggregatePredict - Predict scores for individual weak learners and then
    % aggreate the scores
    
    %   Copyright 2016-2017 The MathWorks, Inc.

coder.internal.prefer_const(classif);
coder.internal.prefer_const(classifByBinRegr);
coder.internal.prefer_const(classNames);
coder.internal.prefer_const(nonzeroProbClasses);
cachedScore = score;
cachedWeights = zeros(coder.internal.indexInt(size(cachedScore,1)),1);
T = length(learners);
if coder.internal.indexInt(T)==coder.internal.indexInt(0)
    return;
end
fnames = fieldnames(trained);
firstCache = true;
for idx=1:coder.internal.indexInt(T)
    if learners(idx)
        if firstCache 
            initCache = true;
            firstCache = false;
        else
            initCache = false;
        end
        weak_learner = classreg.coderutils.structToModel(trained.(fnames{idx}));
        [score,cachedScore,cachedWeights,isCached(idx)] = classreg.learning.coder.ensembleutils.predictOneWithCache(X,coder.ignoreConst(cachedScore),coder.ignoreConst(cachedWeights),...
            coder.ignoreConst(combiner),coder.ignoreConst(weak_learner),classifByBinRegr,learnerWeights(idx),isCached(idx),...
            classNames,nonzeroProbClasses,usePredForLearner(:,idx),useObsForLearner(:,idx),coder.ignoreConst(initCache),classif);
    end
end
end