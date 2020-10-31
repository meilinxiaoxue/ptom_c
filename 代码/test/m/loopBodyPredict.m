function lscore = loopBodyPredict(X,outDataType,trained,idx,obsInRows,verbose) %#codegen
% LOOPBODYPREDICT Call predict method of the Binary learner indexed by idx
% on new observations, X

%   Copyright 2016 The MathWorks, Inc.

coder.inline('always');
coder.internal.prefer_const(obsInRows);
coder.extrinsic('getString','message');

if verbose>1
    fprintf('%s\n',getString(message('stats:classreg:learning:classif:CompactClassificationECOC:localScore:ProcessingLearner',idx)));
end

if obsInRows
    N = coder.internal.indexInt(size(X,1));
else
    N = coder.internal.indexInt(size(X,2));
end

if isempty(trained)
    lscore = repmat(coder.internal.nan('like',outDataType),N,1);
else
    obj = classreg.coderutils.structToModel(trained); 
    [~,s] = classreg.learning.coderutils.ecoc.learnerPredict(obj,X,obsInRows);
    lscore = s(:,2);
end
end
