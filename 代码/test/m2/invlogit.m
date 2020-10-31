function out =invlogit (in )%#codegen 



out =coder .nullcopy (zeros (size (in ),'like' ,in )); 
fori =1 :coder .internal .indexInt (numel (in ))
ifin (i )==0 
out (i )=-coder .internal .inf ; 
elseifin (i )==1 
out (i )=coder .internal .inf ; 
elseifisnan (in (i ))
out (i )=coder .internal .nan ; 
else
out (i )=log (in (i )/(1 -in (i ))); 
end
end

end
