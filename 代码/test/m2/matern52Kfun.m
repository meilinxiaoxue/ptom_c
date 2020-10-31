function KNM =matern52Kfun (usepdist ,theta ,XN ,XM ,calcDiag )%#codegen 




coder .inline ('always' ); 


sigmaL =exp (theta (1 )); 
sigmaF =exp (theta (2 )); 
tiny =1e-6 ; 
sigmaL =max (sigmaL ,tiny ); 
sigmaF =max (sigmaF ,tiny ); 

ifcalcDiag 
N =size (XN ,1 ); 
KNM =(sigmaF ^2 )*ones (N ,1 ); 
else

KNM =classreg .learning .coder .gputils .calcDistance (XN /sigmaL ,XM /sigmaL ,usepdist ); 
KNM =sqrt (5 )*sqrt (KNM ); 


KNM =(sigmaF ^2 )*((1 +KNM .*(1 +KNM /3 )).*exp (-KNM )); 
end

end