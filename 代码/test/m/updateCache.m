function [score,cachedScore,cachedWeights,cached] = updateCache(learnerscore,cachedScore,cachedWeights,cached,learnerWeight,combinerName,obsIndices) %#codegen

    % updateCache - update Cached scores
    %   Copyright 2016-2017 The MathWorks, Inc.
    

coder.internal.prefer_const(combinerName);
score = cachedScore;

if cached || learnerWeight <= 0
    return;
end
cached = true;
cachedScore(obsIndices,:) = cachedScore(obsIndices,:) + learnerscore(obsIndices,:)*learnerWeight;
cachedWeights(obsIndices) = cachedWeights(obsIndices) + learnerWeight;

if strcmpi(combinerName,'weightedaverage')    
    for i = 1:coder.internal.indexInt(size(cachedScore,1)) 
        if cachedWeights(i) == 0
            if cachedScore(i,:) == 0 
                score(i,:) = coder.internal.nan;
            elseif cachedScore(i,:) < 0
                score(i,:) = -1*coder.internal.inf;
            else
                score(i,:) = coder.internal.inf;
            end
        else
            score(i,:) = bsxfun(@rdivide,cachedScore(i,:),cachedWeights(i));
        end
    end
else
    for i = 1:coder.internal.indexInt(size(cachedScore,1))
        score(i,:) = cachedScore(i,:);
    end
end


end