classdef PartitionedModel <classreg .learning .internal .DisallowVectorOps 






properties (GetAccess =public ,SetAccess =protected ,Dependent =true )







CrossValidatedModel ; 







PredictorNames ; 








CategoricalPredictors ; 






ResponseName ; 







NumObservations ; 









X ; 










Y ; 







W ; 







ModelParameters ; 







Trained ; 







KFold ; 







Partition ; 
end

properties (GetAccess =public ,SetAccess =protected ,Hidden =true ,Dependent =true )
NObservations ; 
ModelParams ; 
end

properties (GetAccess =public ,SetAccess =protected ,Hidden =true )
Ensemble ; 
end

methods 
function cvmodel =get .CrossValidatedModel (this )
cvmodel ='' ; 
ifnumel (this .Ensemble .ModelParams .LearnerTemplates )==1 
cvmodel =this .Ensemble .ModelParams .LearnerTemplates {1 }.Method ; 
end
end

function predictornames =get .PredictorNames (this )
predictornames =this .Ensemble .PredictorNames ; 
end

function catpreds =get .CategoricalPredictors (this )
catpreds =this .Ensemble .CategoricalPredictors ; 
end

function respname =get .ResponseName (this )
respname =this .Ensemble .ResponseName ; 
end

function n =get .NumObservations (this )
n =size (this .Ensemble .X ,1 ); 
end

function n =get .NObservations (this )
n =size (this .Ensemble .X ,1 ); 
end

function x =get .X (this )
x =this .Ensemble .X ; 
end

function y =get .Y (this )
y =this .Ensemble .Y ; 
end

function w =get .W (this )
w =this .Ensemble .W ; 
end

function mp =get .ModelParameters (this )
mp =this .Ensemble .ModelParameters ; 
end

function mp =get .ModelParams (this )
mp =this .Ensemble .ModelParams ; 
end

function trained =get .Trained (this )
trained =this .Ensemble .Trained ; 
end

function ntrained =get .KFold (this )
ntrained =this .Ensemble .NTrained ; 
end

function p =get .Partition (this )
p =this .ModelParams .Generator .Partition ; 
end
end

methods (Access =protected )
function this =PartitionedModel ()
this =this @classreg .learning .internal .DisallowVectorOps (); 
end

function s =propsForDisp (this ,s )
ifnargin <2 ||isempty (s )
s =struct ; 
else
if~isstruct (s )
error (message ('stats:classreg:learning:partition:PartitionedModel:propsForDisp:BadS' )); 
end
end
s .CrossValidatedModel =this .CrossValidatedModel ; 
s .PredictorNames =this .PredictorNames ; 
if~isempty (this .CategoricalPredictors )
s .CategoricalPredictors =this .CategoricalPredictors ; 
end
s .ResponseName =this .ResponseName ; 
s .NumObservations =size (this .X ,1 ); 
s .KFold =this .KFold ; 
s .Partition =this .Partition ; 
end
end

methods 
function [varargout ]=kfoldPredict (this ,varargin )
classreg .learning .ensemble .Ensemble .catchUOFL (varargin {:}); 
classreg .learning .partition .PartitionedModel .catchFolds (varargin {:}); 
classreg .learning .FullClassificationRegressionModel .catchWeights (varargin {:}); 
[mode ,~,args ]=checkFoldArgs (this ,varargin {:}); 
[varargout {1 :nargout }]=predict (this .Ensemble ,this .Ensemble .X ,...
    'useobsforlearner' ,~this .Ensemble .ModelParams .Generator .UseObsForIter ,...
    'mode' ,mode ,args {:}); 
end

function vals =kfoldfun (this ,funeval )

































vals =[]; 
T =this .Ensemble .NTrained ; 
ifT <1 
return ; 
end
trained =this .Ensemble .Trained ; 
usenfort =this .Ensemble .ModelParams .Generator .UseObsForIter ; 
x =this .Ensemble .X ; 
y =this .Ensemble .Y ; 
w =this .Ensemble .W ; 


vals =zeros (T ,1 ); 
fort =1 :T 
use =usenfort (:,t ); 
cmp =trained {t }; 
cmp .TableInput =this .Ensemble .TableInput ; 
cmp .VariableRange =this .Ensemble .VariableRange ; 
valt =funeval (cmp ,x (use ,:),y (use ,:),w (use ),x (~use ,:),y (~use ,:),w (~use )); 
ift ==1 
vals (1 ,1 :numel (valt ))=valt ; 
else
ifnumel (valt )~=size (vals ,2 )
error (message ('stats:classreg:learning:partition:PartitionedModel:kfoldfun:BadDimsPerFold' ,numel (valt ),t ,size (vals ,2 ))); 
end
vals (t ,:)=valt ; 
end
end
end
end


methods (Hidden )
function this =compactPartitionedModel (this )
this .Ensemble =compact (this .Ensemble ); 
end

function disp (this )
internal .stats .displayClassName (this ); 


s =propsForDisp (this ,[]); 
disp (s ); 

internal .stats .displayMethodsProperties (this ); 
end

function [ensembleMode ,folds ,extraArgs ]=checkFoldArgs (this ,varargin )
kfold =length (this .Trained ); 

args ={'mode' ,'folds' ,'learners' }; 
defs ={'average' ,1 :kfold ,[]}; 
[cvmode ,folds ,learners ,~,extraArgs ]=...
    internal .stats .parseArgs (args ,defs ,varargin {:}); 

if~isempty (learners )
error (message ('stats:classreg:learning:partition:PartitionedModel:checkFoldArgs:LearnersNoop' )); 
end

cvmode =lower (cvmode ); 
ifstrncmpi (cvmode ,'average' ,length (cvmode ))
ensembleMode ='ensemble' ; 
elseifstrncmpi (cvmode ,'individual' ,length (cvmode ))
ensembleMode ='individual' ; 
else
error (message ('stats:classreg:learning:partition:PartitionedModel:checkFoldArgs:BadMode' )); 
end

ifislogical (folds )
if~isvector (folds )||length (folds )~=kfold 
error (message ('stats:classreg:learning:partition:PartitionedModel:checkFoldArgs:BadLogicalIndices' ,kfold )); 
end
folds =find (folds ); 
end
ifisempty (folds )||~isnumeric (folds )||~isvector (folds )||min (folds )<=0 ||max (folds )>kfold 
error (message ('stats:classreg:learning:partition:PartitionedModel:checkFoldArgs:BadNumericIndices' ,kfold )); 
end
folds =ceil (folds ); 
end
end

methods (Static ,Hidden )
function catchFolds (varargin )
args ={'folds' }; 
defs ={[]}; 
[folds ,~,~]=internal .stats .parseArgs (args ,defs ,varargin {:}); 
if~isempty (folds )
error (message ('stats:classreg:learning:partition:PartitionedModel:catchFolds:NonEmptyFolds' )); 
end
end
end

end
