classdef CompactPartitionedModel <classreg .learning .internal .DisallowVectorOps 



properties (GetAccess =protected ,SetAccess =protected )
PartitionedModel ; 
PrivGenerator ; 
end

properties (GetAccess =public ,SetAccess =protected ,Hidden =true )
ModelParams ; 
end

properties (GetAccess =public ,SetAccess =protected ,Hidden =true ,Dependent =true )
Ensemble ; 
end

properties (GetAccess =public ,SetAccess =protected )






CrossValidatedModel ; 






NumObservations ; 









Y ; 






W ; 
end

properties (GetAccess =public ,SetAccess =protected ,Dependent =true )





PredictorNames ; 







CategoricalPredictors ; 





ResponseName ; 






Trained ; 






KFold ; 






Partition ; 






ModelParameters ; 
end

methods (Abstract )
varargout =kfoldPredict (this ,varargin )
err =kfoldLoss (this ,varargin )
end

methods 
function pnames =get .PredictorNames (this )
pnames =this .PartitionedModel .PredictorNames ; 
end

function catpred =get .CategoricalPredictors (this )
catpred =this .PartitionedModel .CategoricalPredictors ; 
end

function resp =get .ResponseName (this )
resp =this .PartitionedModel .ResponseName ; 
end

function trained =get .Trained (this )
trained =this .PartitionedModel .Trained ; 
end

function kfold =get .KFold (this )
kfold =this .PartitionedModel .KFold ; 
end

function p =get .Partition (this )
p =this .PrivGenerator .Partition ; 
end

function ens =get .Ensemble (this )
ens =this .PartitionedModel .Ensemble ; 
end

function mp =get .ModelParameters (this )
mp =this .ModelParams ; 
end
end

methods (Access =protected )
function this =CompactPartitionedModel ()
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
s .NumObservations =this .NumObservations ; 
s .KFold =this .KFold ; 
s .Partition =this .Partition ; 
end
end

methods (Hidden )
function disp (this )
internal .stats .displayClassName (this ); 


s =propsForDisp (this ,[]); 
disp (s ); 

internal .stats .displayMethodsProperties (this ); 
end
end


end
