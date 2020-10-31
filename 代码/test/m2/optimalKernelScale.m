function scale =optimalKernelScale (X ,Y ,type )















ifsize (X ,1 )<2 
warning (message ('stats:classreg:learning:svmutils:CannotComputeKernelScale' )); 
scale =1 ; 
return ; 
end


P =size (X ,2 ); 

iftype ==1 ||type ==0 

M =200 ; 
N =size (X ,1 ); 
idx =datasample (1 :N ,min (N ,M ),'replace' ,false ); 


D =squareform (pdist (X (idx ,:))); 
M =size (D ,1 ); 


D (D ==0 )=Inf ; 






M2 =floor (M /2 ); 
scale =median (min (D (M2 +1 :end,1 :M2 ))); 


ifisinf (scale )
warning (message ('stats:classreg:learning:svmutils:CannotComputeKernelScale' )); 
scale =1 ; 
return ; 
end


scale =scale *(M /1e4 )^(1 /P ); 


scale =scale *exp (7 /P ^(4 /5 )); 

elseiftype ==2 

iminus =find (Y ==-1 ); 
iplus =find (Y ==+1 ); 
Nminus =numel (iminus ); 
Nplus =numel (iplus ); 


M =100 ; 
iminus =datasample (iminus ,min (M ,Nminus ),'replace' ,false ); 
iplus =datasample (iplus ,min (M ,Nplus ),'replace' ,false ); 


D =pdist2 (X (iminus ,:),X (iplus ,:)); 


D (D ==0 )=Inf ; 



scale =median (min (D )); 


ifisinf (scale )
warning (message ('stats:classreg:learning:svmutils:CannotComputeKernelScale' )); 
scale =1 ; 
return ; 
end


scale =scale *sqrt (numel (iminus )/Nminus *numel (iplus )/Nplus )^(1 /P ); 
end

end
