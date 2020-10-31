function kernelProduct =Poly (svT ,order ,x )%#codegen 





coder .inline ('never' ); 
kernelProduct =x *svT +cast (1 ,'like' ,x ); 
temp =kernelProduct ; 
fori =1 :order -1 
kernelProduct =kernelProduct .*temp ; 
end

end