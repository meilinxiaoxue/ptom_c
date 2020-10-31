function KNM =matern32ARDKfun (usepdist ,theta ,XN ,XM ,calcDiag )%#codegen 




coder .inline ('always' ); 


d =length (theta )-1 ; 
sigmaL =exp (theta (1 :d )); 
sigmaF =exp (theta (d +1 )); 
tiny =1e-6 ; 
sigmaL =max (sigmaL ,tiny ); 
sigmaF =max (sigmaF ,tiny ); 
makepos =true ; 

ifcalcDiag 
N =size (XN ,1 ); 
KNM =(sigmaF ^2 )*ones (N ,1 ); 
else

KNM =classreg .learning .coder .gputils .calcDistance (XN (:,1 )/sigmaL (1 ),XM (:,1 )/sigmaL (1 ),usepdist ,makepos ); 
forr =2 :coder .internal .indexInt (d )
KNM =KNM +classreg .learning .coder .gputils .calcDistance (XN (:,r )/sigmaL (r ),XM (:,r )/sigmaL (r ),usepdist ,makepos ); 
end


D =sqrt (3 )*sqrt (KNM ); 
KNM =(sigmaF ^2 )*((1 +D ).*exp (-D )); 
end

end
