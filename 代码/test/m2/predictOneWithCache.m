function [score ,cachedScore ,cachedWeights ,cached ]=predictOneWithCache (X ,cachedScore ,cachedWeights ,combiner ,weak_learner ,classifByBinRegr ,learnerWeights ,cached ,...
    classnames ,nonzeroProbClasses ,usePredForLearner ,useObsForLearner ,initCache ,classif )%#codegen 







coder .internal .prefer_const (classif ); 
coder .internal .prefer_const (classifByBinRegr ); 
coder .internal .prefer_const (classnames ); 
coder .internal .prefer_const (nonzeroProbClasses ); 
NONFINITES =eml_option ('NonFinitesSupport' ); 
[T ,P ]=size (cachedScore ); 
N =size (X ,1 ); 
ifclassif 
ifcoder .target ('MATLAB' )
defaultScore =NaN ; 
learnerscore =NaN (coder .internal .indexInt (T ),coder .internal .indexInt (P )); 
else
defaultScore =coder .internal .nan ; 
learnerscore =coder .internal .nan (coder .internal .indexInt (T ),coder .internal .indexInt (P )); 
end

[~,pos ]=ismember (weak_learner .ClassNames ,classnames ,'rows' ); 
else
learnerscore =zeros (coder .internal .indexInt (T ),coder .internal .indexInt (P )); 
end

obsToUseIdx =useObsForLearner ; 
predToUseIdx =usePredForLearner ; 
ifany (useObsForLearner )








if~all (predToUseIdx )
ifNONFINITES 
obsToUseIdx =false (coder .internal .indexInt (N ),1 ); 
forii =1 :coder .internal .indexInt (N )
ifuseObsForLearner (ii )
if~any (isnan (X (ii ,predToUseIdx )))
obsToUseIdx (ii )=true ; 
end
end
end
end
end
ifclassif 
ifclassifByBinRegr 
s =predict (weak_learner ,X (obsToUseIdx ,predToUseIdx )); 
learnerscore (obsToUseIdx ,pos )=[s ,-s ]; 
else
[~,learnerscore (obsToUseIdx ,pos )]=predict (weak_learner ,X (obsToUseIdx ,predToUseIdx )); 
end
else
learnerscore (obsToUseIdx )=predict (weak_learner ,X (obsToUseIdx ,predToUseIdx )); 
end

end

ifinitCache 
cachedScore (obsToUseIdx ,:)=0 ; 
else
tf =isnan (cachedScore ); 
ifany (tf (:))
cachedScore (tf &repmat (obsToUseIdx ,1 ,coder .internal .indexInt (size (cachedScore ,2 ))))=0 ; 
end
end

[score ,cachedScore ,cachedWeights ,cached ]=classreg .learning .coder .ensembleutils .updateCache (learnerscore ,coder .ignoreConst (cachedScore ),coder .ignoreConst (cachedWeights ),cached ,learnerWeights ,combiner ,obsToUseIdx ); 

ifclassif 

[~,loc ]=ismember (classnames ,nonzeroProbClasses ,'rows' ); 
score (:,~loc )=defaultScore ; 
end

end