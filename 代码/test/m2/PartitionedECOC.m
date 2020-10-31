classdef PartitionedECOC <classreg .learning .internal .DisallowVectorOps 



properties (GetAccess =public ,SetAccess =protected ,Hidden =true ,Abstract =true )
Ensemble ; 
end

properties (GetAccess =public ,SetAccess =protected ,Abstract =true )
NumObservations ; 
BinaryY ; 
end

properties (GetAccess =public ,SetAccess =protected ,Dependent =true )





BinaryLoss ; 

















CodingMatrix ; 
end

methods 
function this =PartitionedECOC ()
end

function bl =get .BinaryLoss (this )
learners =this .Ensemble .Trained ; 
T =numel (learners ); 
ifT ==0 
bl ='' ; 
return ; 
end
fort =1 :T 
if~isempty (learners {t })
bl =learners {t }.BinaryLoss ; 
return ; 
end
end
end

function M =get .CodingMatrix (this )
M =[]; 
learners =this .Ensemble .Trained ; 
T =numel (learners ); 

ifT ==0 
return ; 
end

M1 =[]; 

fort =1 :T 
if~isempty (learners {t })
M =learners {t }.CodingMatrix ; 
[~,pos ]=ismember (this .Ensemble .ClassSummary .ClassNames ,...
    learners {t }.ClassSummary .ClassNames ); 
M =M (pos ,:); 

ifisempty (M1 )
M1 =M ; 
else
if~isequal (M1 ,M )
M =[]; 
return ; 
end
end
end
end
end
end

end