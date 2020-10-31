function KNM =rationalQuadraticKfun (usepdist ,theta ,XN ,XM ,calcDiag )%#codegen 




coder .inline ('always' ); 


sigmaL =exp (theta (1 )); 
alpha =exp (theta (2 )); 
sigmaF =exp (theta (3 )); 
tiny =1e-6 ; 
sigmaL =max (sigmaL ,tiny ); 
alpha =max (alpha ,tiny ); 
sigmaF =max (sigmaF ,tiny ); 
makepos =false ; 

ifcalcDiag 
N =size (XN ,1 ); 
KNM =(sigmaF ^2 )*ones (N ,1 ); 
else

KNM =classreg .learning .coder .gputils .calcDistance (XN /sigmaL ,XM /sigmaL ,usepdist ,makepos ); 






KNM =KNM ./(2 *alpha ); 
KNM =(2 .*log (sigmaF ))+(-alpha .*log1p (KNM )); 
KNM =exp (KNM ); 
end

end