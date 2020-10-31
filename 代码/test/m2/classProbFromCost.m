function P =classProbFromCost (C )










ifisempty (C )||(~isnumeric (C )&&~islogical (C ))||~ismatrix (C )
error (message ('stats:classreg:learning:classProbFromCost:BadCType' )); 
end

[K ,M ]=size (C ); 
ifK ~=M 
error (message ('stats:classreg:learning:classProbFromCost:BadCSize' )); 
end

ifany (diag (C )~=0 )
error (message ('stats:classreg:learning:classProbFromCost:CNotDiagZero' )); 
end

ifany (any (C <0 ))
error (message ('stats:classreg:learning:classProbFromCost:NegativeC' )); 
end

ifisscalar (C )
P =1 ; 
return ; 
end

ifany (all (C ==0 ,2 ))
error (message ('stats:classreg:learning:classProbFromCost:CWithZeroRow' )); 
end

P =zeros (K ,1 ); 


ifK ==1 
P =1 ; 
end


ifK ==2 
P (1 )=C (1 ,2 ); 
P (2 )=C (2 ,1 ); 
P =P /sum (P ); 
return ; 
end


N =(K -1 )*K /2 ; 
A =zeros (N ,K ); 
Nblock =K -1 ; 
Nfilled =0 ; 
fork =1 :K -1 
A (Nfilled +1 :Nfilled +Nblock ,k )=C (k +1 :end,k ); 
A (Nfilled +1 :Nfilled +Nblock ,k +1 :end)=-diag (C (k ,k +1 :end)); 
Nfilled =Nfilled +Nblock ; 
Nblock =Nblock -1 ; 
end


ifrank (A )<K 

P =null (A ); 
else

P =sum (C ,2 ); 
end


P =P /sum (P ); 

end
