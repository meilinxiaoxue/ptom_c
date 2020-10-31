function KNM =squaredExponentialKfun (usepdist ,theta ,XN ,XM ,calcDiag )%#codegen 




coder .inline ('always' ); 



sigmaL =exp (theta (1 )); 
sigmaF =exp (theta (2 )); 
tiny =1e-6 ; 
sigmaL =max (sigmaL ,tiny ); 
sigmaF =max (sigmaF ,tiny ); 
makepos =false ; 

ifcalcDiag 
N =size (XN ,1 ); 
KNM =(sigmaF ^2 )*ones (N ,1 ); 
else

KNM =classreg .learning .coder .gputils .calcDistance (XN /sigmaL ,XM /sigmaL ,usepdist ,makepos ); 


KNM =(sigmaF ^2 )*exp (-0.5 *KNM ); 
end
end