function out =constant (in ,cls )%#codegen 



out =zeros (size (in ),'like' ,in ); 
N =size (in ,1 ); 
forii =1 :coder .internal .indexInt (N )
out (ii ,cls )=1 ; 
end
end