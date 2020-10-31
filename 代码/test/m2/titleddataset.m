classdef titleddataset <dataset 



properties (Access =private )
Title ='' ; 
end

methods (Hidden =true )
function ds =titleddataset (varargin )
ifisa (varargin {1 },'table' )
varargin {1 }=table2dataset (varargin {1 }); 
end
copying =nargin >=1 &&isa (varargin {1 },'dataset' ); 
ifcopying 
args ={}; 
else
args =varargin ; 
end
ds @dataset (args {:}); 
ifcopying 
ds =classreg .regr .lmeutils .datasetcopier (ds ,varargin {1 }); 
ifnargin >=2 
ds .Title =varargin {2 }; 
end
end
end
end

methods 
function ds =settitle (ds ,title )
ds .Title =title ; 
end
function disp (ds )
if~isempty (ds .Title )
iffeature ('hotlinks' )
fprintf ('\n    <strong>%s</strong>\n\n' ,ds .Title )
else
fprintf ('\n    %s\n\n' ,upper (ds .Title ))
end
end
disp @dataset (ds )
end
end

end

