classdef RationalQuadraticARD <classreg .learning .gputils .Kernel 


















properties (Constant )


Name =classreg .learning .modelparams .GPParams .RationalQuadraticARD ; 
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
function this =RationalQuadraticARD ()
end
end
methods (Static )
function this =makeFromTheta (theta )











this =classreg .learning .gputils .RationalQuadraticARD (); 
this .Theta =theta ; 
this .NumParameters =length (theta ); 
end
end


methods 
function params =summary (this )














params =struct (); 
params .Name =this .Name ; 

theta =this .Theta ; 
d =length (theta )-2 ; 
params .KernelParameters =exp (theta ); 
KernelParameterNames =cell (d +2 ,1 ); 
fori =1 :d 
KernelParameterNames {i }=['LengthScale' ,num2str (i )]; 
end
KernelParameterNames {d +1 }='AlphaRQ' ; 
KernelParameterNames {d +2 }='SigmaF' ; 

params .KernelParameterNames =KernelParameterNames ; 
end
end

methods 
function kfcn =makeKernelAsFunctionOfTheta (this ,XN ,XM ,usecache )





















usepdist =this .UsePdist ; 
makepos =false ; 
ifusecache 
D2 =classreg .learning .gputils .calcDistanceARD (XN ,XM ,usepdist ,makepos ); 
end



tiny =this .Tiny ; 


kfcn =@f ; 
function [KNM ,DKNM ]=f (theta )









d =length (theta )-2 ; 
sigmaL =exp (theta (1 :d )); 
alpha =exp (theta (d +1 )); 
sigmaF =exp (theta (d +2 )); 

sigmaL =max (sigmaL ,tiny ); 
alpha =max (alpha ,tiny ); 
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





D2SUM =KNM ; 
basem1 =D2SUM ./(2 *alpha ); 
KNM =(2 .*log (sigmaF ))+(-alpha .*log1p (basem1 )); 
KNM =exp (KNM ); 


ifnargout <2 
return ; 
end








DKNM =@derf ; 
function DKNMr =derf (r )
if(r ==d +1 )
DKNMr =KNM .*(D2SUM ./(2 *(1 +basem1 ))-alpha *log1p (basem1 )); 
elseif(r ==d +2 )
DKNMr =2 *KNM ; 
else
ifusecache 
DKNMr =(KNM ./(1 +basem1 )).*(D2 (:,:,r )/(sigmaL (r )^2 )); 
else
DKNMr =(KNM ./(1 +basem1 )).*(classreg .learning .gputils .calcDistance (XN (:,r )/sigmaL (r ),XM (:,r )/sigmaL (r ),usepdist ,makepos )); 
end
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








d =length (theta )-2 ; 
sigmaF =exp (theta (d +2 )); 
sigmaF =max (sigmaF ,tiny ); 
diagKNN =(sigmaF ^2 )*eN ; 


ifnargout <2 
return ; 
end

DdiagKNN =@derf ; 
function DdiagKNNr =derf (r )
if(r ==d +2 )
DdiagKNNr =2 *diagKNN ; 
else
DdiagKNNr =zN ; 
end
end
end

end

function kfcn =makeKernelAsFunctionOfXNXM (this ,theta )




















d =length (theta )-2 ; 
sigmaL =exp (theta (1 :d )); 
alpha =exp (theta (d +1 )); 
sigmaF =exp (theta (d +2 )); 
tiny =this .Tiny ; 
sigmaL =max (sigmaL ,tiny ); 
alpha =max (alpha ,tiny ); 
sigmaF =max (sigmaF ,tiny ); 
usepdist =this .UsePdist ; 
makepos =false ; 


kfcn =@f ; 
function KNM =f (XN ,XM )

KNM =classreg .learning .gputils .calcDistance (XN (:,1 )/sigmaL (1 ),XM (:,1 )/sigmaL (1 ),usepdist ,makepos ); 
forr =2 :d 
KNM =KNM +classreg .learning .gputils .calcDistance (XN (:,r )/sigmaL (r ),XM (:,r )/sigmaL (r ),usepdist ,makepos ); 
end






KNM =KNM ./(2 *alpha ); 
KNM =(2 .*log (sigmaF ))+(-alpha .*log1p (KNM )); 
KNM =exp (KNM ); 
end

end

function kfcn =makeDiagKernelAsFunctionOfXN (this ,theta )

















d =length (theta )-2 ; 
sigmaF =exp (theta (d +2 )); 
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