classdef PartitionedEnsemble <classreg .learning .partition .PartitionedModel 






properties (GetAccess =public ,SetAccess =protected ,Dependent =true )






Trainable ; 







NumTrainedPerFold ; 
end

properties (GetAccess =public ,SetAccess =protected ,Hidden =true ,Dependent =true )
NTrainedPerFold ; 
end

properties (GetAccess =public ,SetAccess =protected ,Dependent =true ,Hidden =true )
Combiner ; 
end

methods 
function trainable =get .Trainable (this )
trainable =this .Ensemble .Trainable ; 
end

function tfold =get .NumTrainedPerFold (this )
tfold =this .NTrainedPerFold ; 
end

function tfold =get .NTrainedPerFold (this )
kfold =length (this .Ensemble .Trained ); 
tfold =zeros (1 ,kfold ); 
fork =1 :kfold 
tfold (k )=length (this .Ensemble .Trained {k }.Trained ); 
end
end

function comb =get .Combiner (this )
kfold =length (this .Ensemble .Trained ); 
comb =cell (kfold ,1 ); 
fork =1 :kfold 
comb {k }=this .Ensemble .Trained {k }.Impl .Combiner ; 
end
end
end

methods (Access =protected )
function this =PartitionedEnsemble ()
this =this @classreg .learning .partition .PartitionedModel (); 
end

function s =propsForDisp (this ,s )
s =propsForDisp @classreg .learning .partition .PartitionedModel (this ,s ); 
s .NumTrainedPerFold =this .NumTrainedPerFold ; 
end

function trainable =resumePartitionedWithPrint (this ,nlearn ,nprint )
trainable =this .Ensemble .Trainable ; 
ifisempty (trainable )
error (message ('stats:classreg:learning:partition:PartitionedEnsemble:resumePartitionedWithPrint:NoTrainableLearners' )); 
end
fort =1 :numel (trainable )
trainable {t }=resume (trainable {t },nlearn ); 
ifmod (t ,nprint )==0 
fprintf (1 ,'%s%i\n' ,this .Ensemble .ModelParams .PrintMsg ,t ); 
end
end
end

function [ensembleMode ,folds ,extraArgs ]=checkEnsembleFoldArgs (this ,varargin )
kfold =length (this .Ensemble .Trained ); 

args ={'mode' ,'folds' ,'learners' }; 
defs ={'average' ,1 :kfold ,[]}; 
[cvmode ,folds ,learners ,~,extraArgs ]=...
    internal .stats .parseArgs (args ,defs ,varargin {:}); 

if~isempty (learners )
error (message ('stats:classreg:learning:partition:PartitionedEnsemble:checkEnsembleFoldArgs:LearnersNoop' )); 
end

cvmode =lower (cvmode ); 
ifstrncmpi (cvmode ,'average' ,length (cvmode ))
ensembleMode ='ensemble' ; 
elseifstrncmpi (cvmode ,'individual' ,length (cvmode ))
ensembleMode ='individual' ; 
elseifstrncmpi (cvmode ,'cumulative' ,length (cvmode ))
ensembleMode ='cumulative' ; 
else
error (message ('stats:classreg:learning:partition:PartitionedEnsemble:checkEnsembleFoldArgs:BadMode' )); 
end

ifislogical (folds )
if~isvector (folds )||length (folds )~=kfold 
error (message ('stats:classreg:learning:partition:PartitionedEnsemble:checkEnsembleFoldArgs:BadLogicalIndices' ,kfold )); 
end
folds =find (folds ); 
end
if~isnumeric (folds )||~isvector (folds )||min (folds )<=0 ||max (folds )>kfold 
error (message ('stats:classreg:learning:partition:PartitionedEnsemble:checkEnsembleFoldArgs:BadNumericIndices' ,kfold )); 
end
folds =ceil (folds ); 
fork =1 :length (folds )
ifthis .Ensemble .Trained {folds (k )}.NTrained ==0 
warning (message ('stats:classreg:learning:partition:PartitionedEnsemble:checkEnsembleFoldArgs:EmptyFolds' )); 
end
end
end
end

methods (Static ,Hidden )
function [combiner ,score ]=predictKfoldWithCache (combiner ,X ,...
    t ,useNfort ,useDfort ,trained ,classnames ,nonzeroProbClasses ,...
    defaultScore )

kfold =length (trained ); 


K =length (classnames ); 
doclass =true ; 
ifK ==0 
doclass =false ; 
K =1 ; 
end


N =size (X ,1 ); 
score =NaN (N ,K ); 


fork =1 :kfold 
useNfortK =useNfort (:,k ); 
useDfortTK =useDfort (:,t ,k ); 
weak =trained {k }.Impl .Trained {t }; 









if~all (useDfortTK )
goodobs =~any (isnan (X (useNfortK ,useDfortTK )),2 ); 
idxNfortK =find (useNfortK ); 
idxobs =idxNfortK (goodobs ); 
goodUseNfortK =false (N ,1 ); 
goodUseNfortK (idxobs )=true ; 
else
goodobs =true (sum (useNfortK ),1 ); 
goodUseNfortK =useNfortK ; 
end

ifdoclass 
[~,pos ]=ismember (weak .ClassSummary .ClassNames ,classnames ); 
[~,score (goodUseNfortK ,pos )]=predict (weak ,X (goodUseNfortK ,useDfortTK )); 
else
score (goodUseNfortK )=predict (weak ,X (goodUseNfortK ,useDfortTK )); 
end

combiner {k }=updateCache (combiner {k },score (useNfortK ,:),t ,goodobs ); 
score (useNfortK ,:)=cachedScore (combiner {k }); 
end


ifdoclass 
tf =ismember (classnames ,nonzeroProbClasses ); 
score (:,~tf )=defaultScore ; 
end
end

function tf =usePredInFold (folds ,T ,D ,trained )
Kfold =numel (folds ); 
tf =true (D ,T ,Kfold ); 
fork =1 :Kfold 
if~isempty (trained {k }.UsePredForLearner )
tf (:,:,k )=trained {k }.UsePredForLearner (:,1 :T ); 
end
end
end
end

end
