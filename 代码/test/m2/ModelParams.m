classdef ModelParams <classreg .learning .internal .DisallowVectorOps ...
    &matlab .mixin .CustomDisplay 




properties (SetAccess =private ,GetAccess =public )
















Version =[]; 
end

properties (SetAccess =protected ,GetAccess =public )
Method ='' ; 
Type ='' ; 
end

properties (SetAccess =public ,GetAccess =public ,Hidden =true )
Filled =false ; 
end

methods (Abstract ,Static ,Hidden )
[holder ,extraArgs ]=make (type ,varargin )
end

methods (Abstract ,Hidden )
this =fillDefaultParams (this ,X ,Y ,W ,dataSummary ,classSummary )
end

methods (Access =protected )
function header =getHeader (~)
header ='' ; 
end

function this =ModelParams (method ,type ,version )
this =this @classreg .learning .internal .DisallowVectorOps (); 
this .Method =method ; 
this .Type =type ; 
ifnargin >2 
this .Version =version ; 
else
this .Version =classreg .learning .modelparams .ModelParams .expectedVersion (); 
end
end
end

methods (Static ,Hidden )
function v =expectedVersion ()














v =1 ; 
end
end

methods (Hidden )








function this =fillIfNeeded (this ,X ,Y ,W ,dataSummary ,classSummary )

if~this .Filled 
this =fillDefaultParams (this ,X ,Y ,W ,dataSummary ,classSummary ); 
end
this .Filled =true ; 
end

function tf =isfilled (this )

ifthis .Filled 
tf =true ; 
return ; 
end


props =properties (this ); 
tf =false ; 
fori =1 :length (props )
ifisempty (this .(props {i }))
return ; 
end
end
tf =true ; 
end

function s =toStruct (this )
warning ('off' ,'MATLAB:structOnObject' ); 
s =struct (this ); 
warning ('on' ,'MATLAB:structOnObject' ); 
s =rmfield (s ,'Version' ); 
s =rmfield (s ,'Filled' ); 
end
end

end
