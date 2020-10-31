classdef SquaredExponential <classreg .learning .gputils .Kernel 


















properties (Constant )


Name =classreg .learning .modelparams .GPParams .SquaredExponential ; 
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
function this =SquaredExponential ()
end
end
methods (Static )
function this =makeFromTheta (theta )









this =classreg .learning .gputils .SquaredExponential (); 
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
makepos =false ; 
ifusecache 
D2 =classreg .learning .gputils .calcDistance (XN ,XM ,usepdist ,makepos ); 
end



tiny =this .Tiny ; 


kfcn =@f ; 
function [KNM ,DKNM ]=f (theta )






sigmaL =exp (theta (1 )); 
sigmaF =exp (theta (2 )); 

sigmaL =max (sigmaL ,tiny ); 
sigmaF =max (sigmaF ,tiny ); 


if~usecache 
D2 =classreg .learning .gputils .calcDistance (XN ,XM ,usepdist ,makepos ); 
end


KNM =D2 /(sigmaL ^2 ); 
KNM =(sigmaF ^2 )*exp (-0.5 *KNM ); 


ifnargout <2 
return ; 
end

DKNM =@derf ; 
function DKNMr =derf (r )
if(r ==1 )
DKNMr =KNM .*(D2 /(sigmaL ^2 )); 
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
makepos =false ; 


kfcn =@f ; 
function KNM =f (XN ,XM )

KNM =classreg .learning .gputils .calcDistance (XN /sigmaL ,XM /sigmaL ,usepdist ,makepos ); 


KNM =(sigmaF ^2 )*exp (-0.5 *KNM ); 
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