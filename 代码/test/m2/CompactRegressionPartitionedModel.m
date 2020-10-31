classdef CompactRegressionPartitionedModel <classreg .learning .partition .CompactPartitionedModel 



properties (GetAccess =protected ,SetAccess =protected )
PrivYhat ; 
end

properties (GetAccess =public ,SetAccess =public ,Dependent =true )










ResponseTransform ; 
end

methods 
function rt =get .ResponseTransform (this )
rt =this .PartitionedModel .ResponseTransform ; 
end

function this =set .ResponseTransform (this ,rt )
this .PartitionedModel .ResponseTransform =rt ; 
end
end


methods (Access =protected )
function s =propsForDisp (this ,s )
s =propsForDisp @classreg .learning .partition .CompactPartitionedModel (this ,s ); 
s .ResponseTransform =this .ResponseTransform ; 
end
end


methods (Hidden )
function this =CompactRegressionPartitionedModel (...
    X ,Y ,W ,modelParams ,dataSummary ,responseTransform )
this =this @classreg .learning .partition .CompactPartitionedModel (); 

pm =classreg .learning .partition .RegressionPartitionedModel (...
    X ,Y ,W ,modelParams ,dataSummary ,responseTransform ); 



this .PartitionedModel =pm ; 

ifdataSummary .ObservationsInRows 
this .NumObservations =size (pm .Ensemble .X ,1 ); 
else
this .NumObservations =size (pm .Ensemble .X ,2 ); 
end
this .PrivGenerator =pm .Ensemble .ModelParams .Generator ; 

this .PrivYhat =response (this ); 

this .Y =pm .Ensemble .Y ; 
this .W =pm .Ensemble .W ; 

this .ModelParams =pm .Ensemble .ModelParams ; 

this .PartitionedModel =compactPartitionedModel (pm ); 
end
end


methods (Access =protected ,Abstract =true )
r =response (this )
end

end
