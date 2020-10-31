function classifCheck (C ,Sfit ,W ,cost )




if~ismatrix (Sfit )||~ismatrix (C )
error (message ('stats:classreg:learning:internal:classifCheck:BadDims' )); 
end
ifany (size (Sfit )~=size (C ))
error (message ('stats:classreg:learning:internal:classifCheck:SizeScoreClassCountMismatch' )); 
end


if~islogical (C )&&~isnumeric (C )
error (message ('stats:classreg:learning:internal:classifCheck:BadC' )); 
end
if~isnumeric (Sfit )
error (message ('stats:classreg:learning:internal:classifCheck:BadSfit' )); 
end


if~isfloat (W )||~isvector (W )||length (W )~=size (C ,1 )||any (W <0 )
error (message ('stats:classreg:learning:internal:classifCheck:BadWeights' ,size (C ,1 ))); 
end


K =size (C ,2 ); 
if~isempty (cost )&&...
    (~ismatrix (cost )||~isnumeric (cost )||any (size (cost )~=[K ,K ])||any (cost (:)<0 ))
error (message ('stats:classreg:learning:internal:classifCheck:BadCost' ,K ,K )); 
end
end
