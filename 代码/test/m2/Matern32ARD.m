classdef Matern32ARD <classreg .learning .gputils .Kernel 


















properties (Constant )


Name =classreg .learning .modelparams .GPParams .Matern32ARD ; 
end

properties (GetAccess =public ,SetAccess =protected )













Theta ; 


NumParameters ; 



CustomFcn =[]; 
end

properties 


UsePdist =false ; 



Tiny =1e-6 ; 
end

methods 
function this =setTheta (this ,theta )



this .Theta =theta ; 
end
end



methods (Access =protected )
function this =Matern32ARD ()
end
end
methods (Static )
function this =makeFromTheta (theta )










this =classreg .learning .gputils .Matern32ARD (); 
this .Theta =theta ; 
this .NumParameters =length (theta ); 
end
end


methods 
function params =summary (this )














params =struct (); 
params .Name =this .Name ; 

theta =this .Theta ; 
d =length (theta )-1 ; 
params .KernelParameters =exp (theta ); 
KernelParameterNames =cell (d +1 ,1 ); 
fori =1 :d 
KernelParameterNames {i }=['LengthScale' ,num2str (i )]; 
end
KernelParameterNames {d +1 }='SigmaF' ; 

params .KernelParameterNames =KernelParameterNames ; 
end
end

methods 
function kfcn =makeKernelAsFunctionOfTheta (this ,XN ,XM ,usecache )





















usepdist =this .UsePdist ; 
makepos =true ; 
ifusecache 
D2 =classreg .learning .gputils .calcDistanceARD (XN ,XM ,usepdist ,makepos ); 
end



tiny =this .Tiny ; 


kfcn =@f ; 
function [KNM ,DKNM ]=f (theta )








d =length (theta )-1 ; 
sigmaL =exp (theta (1 :d )); 
sigmaF =exp (theta (d +1 )); 

sigmaL =max (sigmaL ,tiny ); 
sigmaF =max (sigmaF ,tiny ); 


ifusecache 
sigmaL3D =reshape (sigmaL ,1 ,1 ,d ); 
KNM =sum (bsxfun (@rdivide ,D2 ,sigmaL3D .^2 ),3 ); 
else
KNM =classreg .learning .gputils .calcDistance (XN (:,1 )/sigmaL (1 ),XM (:,1 )/sigmaL (1 ),usepdist ,makepos ); 
forr =2 :d 
KNM =KNM +classreg .learning .gputils .calcDistance (XN (:,r )/sigmaL (r ),XM (:,r )/sigmaL (r ),usepdist ,makepos ); 
end
end
D =sqrt (3 )*sqrt (KNM ); 
KNM =(sigmaF ^2 )*((1 +D ).*exp (-D )); 



ifnargout <2 
return ; 
end
D =KNM ./(1 +D ); 

DKNM =@derf ; 
function DKNMr =derf (r )
if(r ==d +1 )
DKNMr =2 *KNM ; 
else
ifusecache 
D2r =D2 (:,:,r )/(sigmaL (r )^2 ); 
else
D2r =(classreg .learning .gputils .calcDistance (XN (:,r )/sigmaL (r ),XM (:,r )/sigmaL (r ),usepdist ,makepos )); 
end
DKNMr =3 *(D2r .*D ); 
end
end

end

end

function kfcn =makeDiagKernelAsFunctionOfTheta (this ,XN ,usecache )%#ok<INUSD> 



















N =size (XN ,1 ); 
eN =ones (N ,1 ); 
zN =zeros (N ,1 ); 



tiny =this .Tiny ; 


kfcn =@f ; 
function [diagKNN ,DdiagKNN ]=f (theta )







d =length (theta )-1 ; 
sigmaF =exp (theta (d +1 )); 
sigmaF =max (sigmaF ,tiny ); 
diagKNN =(sigmaF ^2 )*eN ; 


ifnargout <2 
return ; 
end

DdiagKNN =@derf ; 
function DdiagKNNr =derf (r )
if(r ==d +1 )
DdiagKNNr =2 *diagKNN ; 
else
DdiagKNNr =zN ; 
end
end
end

end

function kfcn =makeKernelAsFunctionOfXNXM (this ,theta )


















d =length (theta )-1 ; 
sigmaL =exp (theta (1 :d )); 
sigmaF =exp (theta (d +1 )); 
tiny =this .Tiny ; 
sigmaL =max (sigmaL ,tiny ); 
sigmaF =max (sigmaF ,tiny ); 
usepdist =this .UsePdist ; 
makepos =true ; 


kfcn =@f ; 
function KNM =f (XN ,XM )

KNM =classreg .learning .gputils .calcDistance (XN (:,1 )/sigmaL (1 ),XM (:,1 )/sigmaL (1 ),usepdist ,makepos ); 
forr =2 :d 
KNM =KNM +classreg .learning .gputils .calcDistance (XN (:,r )/sigmaL (r ),XM (:,r )/sigmaL (r ),usepdist ,makepos ); 
end


D =sqrt (3 )*sqrt (KNM ); 
KNM =(sigmaF ^2 )*((1 +D ).*exp (-D )); 
end

end

function kfcn =makeDiagKernelAsFunctionOfXN (this ,theta )
















d =length (theta )-1 ; 
sigmaF =exp (theta (d +1 )); 
tiny =this .Tiny ; 
sigmaF =max (sigmaF ,tiny ); 


kfcn =@f ; 
function diagKNN =f (XN )
N =size (XN ,1 ); 
diagKNN =(sigmaF ^2 )*ones (N ,1 ); 
end

end

end

end