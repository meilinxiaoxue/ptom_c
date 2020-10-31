function out =ismax (in )%#codegen 



[N ,K ]=size (in ); 
ifcoder .internal .indexInt (K )==1 
out =ones (coder .internal .indexInt (N ),coder .internal .indexInt (K ),'like' ,in ); 
return ; 
else
out =zeros (coder .internal .indexInt (N ),coder .internal .indexInt (K ),'like' ,in ); 
end

forn =1 :coder .internal .indexInt (N )
inmax =in (n ,1 ); 
inmaxind =coder .internal .indexInt (1 ); 
fork =2 :coder .internal .indexInt (K )
ifin (n ,k )>inmax 
inmax =in (n ,k ); 
inmaxind =coder .internal .indexInt (k ); 
end
end
out (n ,inmaxind )=1 ; 
end
end
