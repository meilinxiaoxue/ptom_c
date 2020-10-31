classdef CompactEnsembleImpl 





properties (GetAccess =public ,SetAccess =public ,Hidden =true )
Trained ={}; 
Combiner =[]; 
end

methods (Hidden )
function this =CompactEnsembleImpl (trained ,combiner )
this .Trained =trained ; 
this .Combiner =combiner ; 
end
end

methods 
function [varargout ]=predictorImportance (this ,varargin )

trained =this .Trained ; 
ifisempty (trained )
varargout {1 }=[]; 
ifnargout >1 
varargout {2 }=[]; 
end
return ; 
end
T =length (trained ); 
W =[]; 
ifismember ('LearnerWeights' ,properties (this .Combiner ))
W =this .Combiner .LearnerWeights ; 
end
ifisempty (W )
W =ones (T ,1 ); 
end


cmp =trained {1 }; 
ifisa (cmp ,'classreg.learning.classif.CompactClassifByBinaryRegr' )
cmp =cmp .CompactRegressionLearner ; 
end


cls =class (cmp ); 
ifnumel (trained )>1 
cfun =@(x )istype (x ,cls ); 
tf =cellfun (cfun ,trained (2 :end)); 
ifany (~tf )
error (message ('stats:classreg:learning:impl:CompactEnsembleImpl:predictorImportance:NonUniformEnsemble' )); 
end
end


istree =false ; 
ifisa (cmp ,'classreg.learning.classif.CompactClassificationTree' )...
    ||isa (cmp ,'classreg.learning.regr.CompactRegressionTree' )
istree =true ; 
end


if~istree 
error (message ('stats:classreg:learning:impl:CompactEnsembleImpl:predictorImportance:NonTreeLearner' )); 
end


dosurr =false ; 
assoc =[]; 
ifnargout >1 
ifistree &&~isempty (cmp .SurrCutFlip )
dosurr =true ; 
else
ifistree 
warning (message ('stats:classreg:learning:impl:CompactEnsembleImpl:predictorImportance:NoSurrInfo' )); 
else
warning (message ('stats:classreg:learning:impl:CompactEnsembleImpl:predictorImportance:No2ndOutputArg' )); 
end
end
end



imp =W (1 )*predictorImportance (cmp ); 
ifdosurr 
assoc =W (1 )*meanSurrVarAssoc (cmp ); 
end


fort =2 :T 
cmp =trained {t }; 
ifisa (cmp ,'classreg.learning.classif.CompactClassifByBinaryRegr' )
cmp =cmp .CompactRegressionLearner ; 
end
imp =imp +W (t )*predictorImportance (cmp ); 
ifdosurr 
assoc =assoc +W (t )*meanSurrVarAssoc (cmp ); 
end
end


varargout {1 }=imp /sum (W ); 
ifnargout >1 
varargout {2 }=assoc /sum (W ); 
end
end

function this =sortLearnersByWeight (this )
[alpha ,sorted ]=sort (this .Combiner .LearnerWeights ,'descend' ); 
this .Combiner =clone (this .Combiner ,alpha ); 
this .Trained =this .Trained (sorted ); 
end

function this =removeLearners (this ,idx )
if~isnumeric (idx )||~isvector (idx )...
    ||any (idx <=0 )||any (isnan (idx ))||any (isinf (idx ))...
    ||max (idx )>numel (this .Trained )
error (message ('stats:classreg:learning:impl:CompactEnsembleImpl:removeLearners:BadIdx' ,...
    numel (this .Trained ))); 
end
alpha =this .Combiner .LearnerWeights ; 
alpha (idx )=[]; 
this .Combiner =clone (this .Combiner ,alpha ); 
this .Trained (idx )=[]; 
end
end
end

function tf =istype (cmpobj ,expectedType )
tf =false ; 
ifisa (cmpobj ,'classreg.learning.classif.CompactClassifByBinaryRegr' )
cmpobj =cmpobj .CompactRegressionLearner ; 
end
cls =class (cmpobj ); 
ifstrcmp (cls ,expectedType )
tf =true ; 
end
end

