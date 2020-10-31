function out =rdivideFinite (num ,den )
%#codegen 





out =zeros (size (den ),'like' ,den ); 
forii =1 :coder .internal .indexInt (numel (out ))
if(den (ii )~=0 )
out (ii )=num (ii )/den (ii ); 
end
end
end