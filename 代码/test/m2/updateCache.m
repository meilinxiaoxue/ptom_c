function [score ,cachedScore ,cachedWeights ,cached ]=updateCache (learnerscore ,cachedScore ,cachedWeights ,cached ,learnerWeight ,combinerName ,obsIndices )%#codegen 





coder .internal .prefer_const (combinerName ); 
score =cachedScore ; 

ifcached ||learnerWeight <=0 
return ; 
end
cached =true ; 
cachedScore (obsIndices ,:)=cachedScore (obsIndices ,:)+learnerscore (obsIndices ,:)*learnerWeight ; 
cachedWeights (obsIndices )=cachedWeights (obsIndices )+learnerWeight ; 

ifstrcmpi (combinerName ,'weightedaverage' )
fori =1 :coder .internal .indexInt (size (cachedScore ,1 ))
ifcachedWeights (i )==0 
ifcachedScore (i ,:)==0 
score (i ,:)=coder .internal .nan ; 
elseifcachedScore (i ,:)<0 
score (i ,:)=-1 *coder .internal .inf ; 
else
score (i ,:)=coder .internal .inf ; 
end
else
score (i ,:)=bsxfun (@rdivide ,cachedScore (i ,:),cachedWeights (i )); 
end
end
else
fori =1 :coder .internal .indexInt (size (cachedScore ,1 ))
score (i ,:)=cachedScore (i ,:); 
end
end


end