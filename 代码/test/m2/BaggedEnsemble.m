classdef BaggedEnsemble 







properties (GetAccess =public ,SetAccess =protected ,Abstract =true )
ModelParams ; 
PrivX ; 
PrivY ; 
W ; 
end

properties (GetAccess =public ,SetAccess =protected ,Dependent =true )






FResample ; 







Replace ; 









UseObsForLearner ; 
end

methods (Abstract )
l =loss (this ,X ,Y ,varargin )
end

methods (Access =protected )
function this =BaggedEnsemble ()
end

function s =propsForDisp (this ,s )
ifnargin <2 ||isempty (s )
s =struct ; 
else
if~isstruct (s )
error (message ('stats:classreg:learning:ensemble:BaggedEnsemble:propsForDisp:BadS' )); 
end
end
s .FResample =this .FResample ; 
s .Replace =this .Replace ; 
s .UseObsForLearner =this .UseObsForLearner ; 
end
end

methods 
function fresample =get .FResample (this )
fresample =this .ModelParams .Generator .FResample ; 
end

function replace =get .Replace (this )
replace =this .ModelParams .Generator .Replace ; 
end

function usenfort =get .UseObsForLearner (this )
usenfort =this .ModelParams .Generator .UseObsForIter ; 
end

function imp =oobPermutedPredictorImportance (this ,varargin )


























classreg .learning .ensemble .Ensemble .catchUOFL (varargin {:}); 
classreg .learning .FullClassificationRegressionModel .catchWeights (varargin {:}); 
usenfort =~this .ModelParams .Generator .UseObsForIter ; 


D =this .DataSummary .PredictorNames ; 
if~isnumeric (D )
D =numel (D ); 
end


trained =this .Trained ; 
T =numel (trained ); 


args ={'learners' ,'options' }; 
defs ={1 :T ,statset ('parallel' )}; 
[learners ,paropts ]=internal .stats .parseArgs (args ,defs ,varargin {:}); 


ifislogical (learners )
if~isvector (learners )||length (learners )~=T 
error (message ('stats:classreg:learning:ensemble:CompactEnsemble:checkAggregateArgs:BadLogicalIndices' ,T )); 
end
learners =find (learners ); 
end
if~isempty (learners )&&...
    (~isnumeric (learners )||~isvector (learners )||min (learners )<=0 ||max (learners )>T )
error (message ('stats:classreg:learning:ensemble:CompactEnsemble:checkAggregateArgs:BadNumericIndices' ,T )); 
end
learners =ceil (learners ); 


[useParallel ,RNGscheme ]=...
    internal .stats .parallel .processParallelAndStreamOptions (paropts ); 


T =numel (learners ); 
Imp =NaN (T ,D ); 


forj =1 :T 
t =learners (j ); 

Xoob =this .PrivX (usenfort (:,t ),:); 
Yoob =this .PrivY (usenfort (:,t )); 
Woob =this .W (usenfort (:,t )); 

one_learner =trained {t }; 
err =loss (one_learner ,Xoob ,Yoob ,'Weights' ,Woob ); 

Imp (t ,:)=localPermutedImp (...
    err ,one_learner ,Xoob ,Yoob ,Woob ,D ,useParallel ,RNGscheme ); 
end

mu =mean (Imp ,1 ); 
sigma =std (Imp ,1 ,1 ); 

imp =zeros (1 ,D ); 
above0 =sigma >0 |mu >0 ; 
imp (above0 )=mu (above0 )./sigma (above0 ); 
end
end

end


function imp =localPermutedImp (err0 ,learner ,Xoob ,Yoob ,Woob ,D ,useParallel ,RNGscheme )

imp =zeros (D ,1 ); 

ifisempty (Xoob )
return ; 
end



ifisa (learner ,'classreg.learning.classif.CompactClassificationTree' )...
    ||isa (learner ,'classreg.learning.regr.CompactRegressionTree' )
used =find (predictorImportance (learner )>0 ); 
else
used =1 :D ; 
end

err =internal .stats .parallel .smartForSliceout (...
    numel (used ),@loopBody ,useParallel ,RNGscheme ); 

imp (used )=err -err0 ; 


function err =loopBody (j ,s )
ifisempty (s )
s =RandStream .getGlobalStream ; 
end

d =used (j ); 

Noob =size (Xoob ,1 ); 

permuted =randperm (s ,Noob ); 

Xperm =Xoob ; 
Xperm (:,d )=Xoob (permuted ,d ); 

err =loss (learner ,Xperm ,Yoob ,'Weights' ,Woob (permuted )); 
end
end
