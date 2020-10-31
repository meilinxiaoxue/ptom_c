function out =sigmoid (in ,a ,b )%#codegen 



out =zeros (size (in ),'like' ,in ); 
N =size (in ,1 ); 
forii =1 :coder .internal .indexInt (N )
out (ii ,2 )=1 ./(1 +exp (a *in (ii ,2 )+b )); 
out (ii ,1 )=1 -out (ii ,2 ); 
end
end