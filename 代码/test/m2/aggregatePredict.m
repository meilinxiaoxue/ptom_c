function score =aggregatePredict (X ,score ,combiner ,trained ,classifByBinRegr ,learnerWeights ,isCached ,classNames ,nonzeroProbClasses ,...
    usePredForLearner ,learners ,useObsForLearner ,classif )%#codegen 






coder .internal .prefer_const (classif ); 
coder .internal .prefer_const (classifByBinRegr ); 
coder .internal .prefer_const (classNames ); 
coder .internal .prefer_const (nonzeroProbClasses ); 
cachedScore =score ; 
cachedWeights =zeros (coder .internal .indexInt (size (cachedScore ,1 )),1 ); 
T =length (learners ); 
ifcoder .internal .indexInt (T )==coder .internal .indexInt (0 )
return ; 
end
fnames =fieldnames (trained ); 
firstCache =true ; 
foridx =1 :coder .internal .indexInt (T )
iflearners (idx )
iffirstCache 
initCache =true ; 
firstCache =false ; 
else
initCache =false ; 
end
weak_learner =classreg .coderutils .structToModel (trained .(fnames {idx })); 
[score ,cachedScore ,cachedWeights ,isCached (idx )]=classreg .learning .coder .ensembleutils .predictOneWithCache (X ,coder .ignoreConst (cachedScore ),coder .ignoreConst (cachedWeights ),...
    coder .ignoreConst (combiner ),coder .ignoreConst (weak_learner ),classifByBinRegr ,learnerWeights (idx ),isCached (idx ),...
    classNames ,nonzeroProbClasses ,usePredForLearner (:,idx ),useObsForLearner (:,idx ),coder .ignoreConst (initCache ),classif ); 
end
end
end