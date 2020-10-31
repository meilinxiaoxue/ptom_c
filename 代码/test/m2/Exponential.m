classdef Exponential <classreg .learning .gputils .Kernel 


















properties (Constant )


Name =classreg .learning .modelparams .GPParams .Exponential ; 
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
function this =Exponential ()
end
end
methods (Static )
function this =makeFromTheta (theta )









this =classreg .learning .gputils .Exponential (); 
this .Theta =theta ; 
this .NumParameters =2 ; 
end
end


methods 
function params =summary (this )













params =struct (); 
params .Name =this .Name ; 
theta =this .Theta ; 
sigmaL =exp (theta (1 )); 
sigmaF =exp (theta (2 )); 
params .KernelParameters =[sigmaL ; sigmaF ]; 
params .KernelParameterNames ={'SigmaL' ; 'SigmaF' }; 
end
end

methods 
function kfcn =makeKernelAsFunctionOfTheta (this ,XN ,XM ,usecache )



















usepdist =this .UsePdist ; 
ifusecache 


D =classreg .learning .gputils .calcDistance (XN ,XM ,usepdist ); 
D =sqrt (D ); 
end



tiny =this .Tiny ; 


kfcn =@f ; 
function [KNM ,DKNM ]=f (theta )






sigmaL =exp (theta (1 )); 
sigmaF =exp (theta (2 )); 

sigmaL =max (sigmaL ,tiny ); 
sigmaF =max (sigmaF ,tiny ); 


if~usecache 
D =classreg .learning .gputils .calcDistance (XN ,XM ,usepdist ); 
D =sqrt (D ); 
end


KNM =D /sigmaL ; 
KNM =(sigmaF ^2 )*exp (-1 *KNM ); 


ifnargout <2 
return ; 
end

DKNM =@derf ; 
function DKNMr =derf (r )
if(r ==1 )
DKNMr =KNM .*(D /sigmaL ); 
elseif(r ==2 )
DKNMr =2 *KNM ; 
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






sigmaF =exp (theta (2 )); 
sigmaF =max (sigmaF ,tiny ); 
diagKNN =(sigmaF ^2 )*eN ; 


ifnargout <2 
return ; 
end

DdiagKNN =@derf ; 
function DdiagKNNr =derf (r )
if(r ==1 )
DdiagKNNr =zN ; 
elseif(r ==2 )
DdiagKNNr =2 *diagKNN ; 
end
end
end

end

function kfcn =makeKernelAsFunctionOfXNXM (this ,theta )
















sigmaL =exp (theta (1 )); 
sigmaF =exp (theta (2 )); 
tiny =this .Tiny ; 
sigmaL =max (sigmaL ,tiny ); 
sigmaF =max (sigmaF ,tiny ); 
usepdist =this .UsePdist ; 


kfcn =@f ; 
function KNM =f (XN ,XM )

KNM =classreg .learning .gputils .calcDistance (XN /sigmaL ,XM /sigmaL ,usepdist ); 
KNM =sqrt (KNM ); 


KNM =(sigmaF ^2 )*exp (-1 *KNM ); 
end

end

function kfcn =makeDiagKernelAsFunctionOfXN (this ,theta )















sigmaF =exp (theta (2 )); 
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