function out =sign (in )%#codegen 



out =coder .nullcopy (zeros (size (in ),'like' ,in )); 

fori =1 :numel (in )
ifin (i )<0 
out (i )=-1 ; 
elseifin (i )>0 
out (i )=1 ; 
else
out (i )=0 ; 
end
end
