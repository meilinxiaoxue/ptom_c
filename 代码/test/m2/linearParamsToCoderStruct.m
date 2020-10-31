function s =linearParamsToCoderStruct (s )





if~isempty (s .Stream )
s .Stream =get (s .Stream ); 
end


solver =s .Solver ; 
if~isrow (solver )
solver =solver (:)' ; 
end
s .SolverNamesLength =cellfun (@length ,solver ); 
s .SolverNames =char (solver ' ); 
s =rmfield (s ,'Solver' ); 
end
