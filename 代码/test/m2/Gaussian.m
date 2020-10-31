function kernelProduct =Gaussian (svT ,svInnerProduct ,x )%#codegen 





coder .inline ('never' ); 

kernelProduct =bsxfun (@plus ,bsxfun (@plus ,cast (-2 ,'like' ,x )*x *svT ,x *x ' ),svInnerProduct ); 
kernelProduct =exp (-kernelProduct ); 



end