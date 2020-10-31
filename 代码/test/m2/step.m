function out =step (in ,lo ,hi ,p )%#codegen 



out =zeros (size (in ),'like' ,in ); 
N =size (in ,1 ); 
forii =1 :coder .internal .indexInt (N )
s =in (ii ,2 ); 
ifs >hi 
out (ii ,2 )=1 ; 
elseifs <lo 
out (ii ,1 )=1 ; 
else
out (ii ,1 )=1 -p ; 
out (ii ,2 )=p ; 
end
end
end