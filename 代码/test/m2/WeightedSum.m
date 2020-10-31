classdef WeightedSum <classreg .learning .internal .DisallowVectorOps 




properties (GetAccess =public ,SetAccess =protected )

LearnerWeights =[]; 



IsCached =[]; 
end

properties (GetAccess =protected ,SetAccess =protected )

CachedScore =[]; 
end

methods 
function this =WeightedSum (learnerWeights )
this =this @classreg .learning .internal .DisallowVectorOps (); 
this .LearnerWeights =learnerWeights (:); 
this .IsCached =false (numel (this .LearnerWeights ),1 ); 
end

function obj =clone (this ,learnerWeights )
ifnargin <2 
learnerWeights =this .LearnerWeights ; 
end
obj =classreg .learning .combiner .WeightedSum (learnerWeights ); 
end



function this =addWeights (this ,score ,t ,usenfort )
end



function this =initWeights (this ,score ,t ,usenfort )
end

function this =resetCache (this )
this .CachedScore =[]; 
this .IsCached =false (numel (this .LearnerWeights ),1 ); 
end

function score =cachedScore (this )
score =this .CachedScore ; 
end

function this =updateCache (this ,score ,t ,usenfort )

T =length (this .LearnerWeights ); 
[N ,K ]=size (score ); 


t =ceil (t ); 
ift <1 ||t >T 
error (message ('stats:classreg:learning:combiner:WeightedSum:updateCache:BadLearnerIndex' ,T )); 
end
if~isempty (this .CachedScore )&&~all (size (this .CachedScore )==[N ,K ])
error (message ('stats:classreg:learning:combiner:WeightedSum:updateCache:BadCacheSize' )); 
end



ifisempty (this .CachedScore )
this .CachedScore =NaN (size (score ),'like' ,score ); 
this .CachedScore (usenfort ,:)=0 ; 
this =initWeights (this ,score ,t ,usenfort ); 
else
tf =isnan (this .CachedScore ); 
ifany (tf (:))
this .CachedScore (tf &repmat (usenfort ,1 ,size (this .CachedScore ,2 )))=0 ; 
end
end



ifthis .IsCached (t )||this .LearnerWeights (t )<=0 
return ; 
end


this .CachedScore (usenfort ,:)=this .CachedScore (usenfort ,:)+...
    score (usenfort ,:)*this .LearnerWeights (t ); 
this =addWeights (this ,score ,t ,usenfort ); 
this .IsCached (t )=true ; 
end
end

end
