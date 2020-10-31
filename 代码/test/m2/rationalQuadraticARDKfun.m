function KNM =rationalQuadraticARDKfun (usepdist ,theta ,XN ,XM ,calcDiag )%#codegen 




coder .inline ('always' ); 


d =length (theta )-2 ; 
sigmaL =exp (theta (1 :d )); 
alpha =exp (theta (d +1 )); 
sigmaF =exp (theta (d +2 )); 
tiny =1e-6 ; 
sigmaL =max (sigmaL ,tiny ); 
alpha =max (alpha ,tiny ); 
sigmaF =max (sigmaF ,tiny ); 
makepos =false ; 

ifcalcDiag 
N =size (XN ,1 ); 
KNM =(sigmaF ^2 )*ones (N ,1 ); 
else

KNM =classreg .learning .coder .gputils .calcDistance (XN (:,1 )/sigmaL (1 ),XM (:,1 )/sigmaL (1 ),usepdist ,makepos ); 
forr =2 :coder .internal .indexInt (d )
KNM =KNM +classreg .learning .coder .gputils .calcDistance (XN (:,r )/sigmaL (r ),XM (:,r )/sigmaL (r ),usepdist ,makepos ); 
end






KNM =KNM ./(2 *alpha ); 
KNM =(2 .*log (sigmaF ))+(-alpha .*log1p (KNM )); 
KNM =exp (KNM ); 
end

end