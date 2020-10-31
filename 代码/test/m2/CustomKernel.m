function KNM =CustomKernel (theta ,kernelFcn ,XN ,XM ,calcDiag )%#codegen 



coder .inline ('always' ); 

N =size (XN ,1 ); 








ifisempty (kernelFcn )
KNM =zeros (N ,1 ); 
return 
end


customFcn =str2func (kernelFcn ); 


ifcalcDiag 
KNM =zeros (N ,1 ); 
fori =1 :coder .internal .indexInt (N )
KNM (i )=customFcn (XN (i ,:),XN (i ,:),theta ); 
end
else
KNM =customFcn (XN ,XM ,theta ); 
end