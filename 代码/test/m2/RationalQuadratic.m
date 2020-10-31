classdef RationalQuadratic <classreg .learning .gputils .Kernel 


















properties (Constant )


Name =classreg .learning .modelparams .GPParams .RationalQuadratic ; 
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
function this =RationalQuadratic ()
end
end
methods (Static )
function this =makeFromTheta (theta )










this =classreg .learning .gputils .RationalQuadratic (); 
this .Theta =theta ; 
this .NumParameters =3 ; 
end
end


methods 
function params =summary (this )













params =struct (); 
params .Name =this .Name ; 
theta =this .Theta ; 
sigmaL =exp (theta (1 )); 
alpha =exp (theta (2 )); 
sigmaF =exp (theta (3 )); 
params .KernelParameters =[sigmaL ; alpha ; sigmaF ]; 
params .KernelParameterNames ={'SigmaL' ; 'AlphaRQ' ; 'SigmaF' }; 
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
alpha =exp (theta (2 )); 
sigmaF =exp (theta (3 )); 

sigmaL =max (sigmaL ,tiny ); 
alpha =max (alpha ,tiny ); 
sigmaF =max (sigmaF ,tiny ); 


if~usecache 
D2 =classreg .learning .gputils .calcDistance (XN ,XM ,usepdist ,makepos ); 
end






basem1 =D2 ./(2 *alpha *(sigmaL ^2 )); 
KNM =(2 .*log (sigmaF ))+(-alpha .*log1p (basem1 )); 
KNM =exp (KNM ); 


ifnargout <2 
return ; 
end








DKNM =@derf ; 
function DKNMr =derf (r )
if(r ==1 )
DKNMr =(KNM ./(1 +basem1 )).*(D2 /(sigmaL ^2 )); 
elseif(r ==2 )
DKNMr =KNM .*(D2 ./(2 *(1 +basem1 )*(sigmaL ^2 ))-alpha *log1p (basem1 )); 
elseif(r ==3 )
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







sigmaF =exp (theta (3 )); 
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
DdiagKNNr =zN ; 
elseif(r ==3 )
DdiagKNNr =2 *diagKNN ; 
end
end
end

end

function kfcn =makeKernelAsFunctionOfXNXM (this ,theta )



















sigmaL =exp (theta (1 )); 
alpha =exp (theta (2 )); 
sigmaF =exp (theta (3 )); 
tiny =this .Tiny ; 
sigmaL =max (sigmaL ,tiny ); 
alpha =max (alpha ,tiny ); 
sigmaF =max (sigmaF ,tiny ); 
usepdist =this .UsePdist ; 
makepos =false ; 


kfcn =@f ; 
function KNM =f (XN ,XM )

KNM =classreg .learning .gputils .calcDistance (XN /sigmaL ,XM /sigmaL ,usepdist ,makepos ); 






KNM =KNM ./(2 *alpha ); 
KNM =(2 .*log (sigmaF ))+(-alpha .*log1p (KNM )); 
KNM =exp (KNM ); 
end

end

function kfcn =makeDiagKernelAsFunctionOfXN (this ,theta )
















sigmaF =exp (theta (3 )); 
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