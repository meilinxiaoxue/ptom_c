function s =coderStructToLinearParams (s )




s .Solver =cellstr (s .SolverNames )' ; 
s .Solver =arrayfun (@(x ,y )x {1 }(1 :y ),s .Solver ,s .SolverNamesLength ,...
    'UniformOutput' ,false ); 
s =rmfield (s ,'SolverNames' ); 
s =rmfield (s ,'SolverNamesLength' ); 

if~isempty (s .Stream )
stream =s .Stream ; 
s .Stream =RandStream (stream .Type ); 
set (s .Stream ,stream ); 
end

end
