classdef RobustBoost <classreg .learning .modifier .Modifier 




properties (Constant =true ,GetAccess =public )
FitInfoDescription =[{getString (message ('stats:classreg:learning:modifier:RobustBoost:FitInfoDescription_Line_1' ))}; 
 {getString (message ('stats:classreg:learning:modifier:RobustBoost:FitInfoDescription_Line_2' ))}]; 
end

properties (GetAccess =public ,SetAccess =protected )
TargetAccuracy =[]; 
MaxMargin =[]; 
MarginSigma =[]; 
end

methods 
function this =RobustBoost (accu ,maxMargin ,marginSigma )
this =this @classreg .learning .modifier .Modifier (2 ,1 ); 
ifisempty (ver ('Optim' ))
error (message ('stats:classreg:learning:modifier:RobustBoost:RobustBoost:NoOptim' )); 
end
this .MaxMargin =maxMargin ; 
this .MarginSigma =marginSigma ; 
e =exp (1 ); 
g =@(x )1 -rberf ((2 *(e -1 )*x -e *maxMargin )...
    /sqrt (e ^2 *(marginSigma ^2 +1 )-1 )); 
f =@(x )g (x )-accu ; 
opts =optimset ('Display' ,'off' ); 
this .TargetAccuracy =fsolve (f ,0 ,opts ); 
ifthis .TargetAccuracy <=0 
error (message ('stats:classreg:learning:modifier:RobustBoost:RobustBoost:BadTargetAccuracy' ,sprintf ('%g' ,g (Inf )),sprintf ('%g' ,g (0 )))); 
end
end
end

methods 
function [this ,mustTerminate ,X ,Y ,W ,fitData ]=modify (this ,X ,Y ,W ,H ,fitData )

ifwasTerminated (this )
mustTerminate =true ; 
return ; 
end



mar =margin (H ,X ,Y )/2 ; 


useObs =~isnan (mar ); 
ifall (~useObs )
warning (message ('stats:classreg:learning:modifier:RobustBoost:modify:AllMarginsNans' )); 
this .ReasonForTermination =getString (message ('stats:classreg:learning:modifier:RobustBoost:ReasonForTermination_1' )); 
mustTerminate =true ; 
this .Terminated =mustTerminate ; 
return ; 
end


ifthis .T ==0 
t =0 ; 
else
t =this .FullFitInfo (this .T ,2 ); 
end




opts =optimset ('Jacobian' ,'on' ,'Display' ,'off' ); 



f =@(x )objective (x ,fitData (useObs ),mar (useObs ),t ,...
    this .TargetAccuracy ,this .MaxMargin ,this .MarginSigma ); 
xsolved =lsqnonlin (f ,[0 ; min ((1 -t )/2 ,0.01 )],zeros (2 ,1 ),[exp (-t ); 1 -t ],opts ); 
dm =xsolved (1 ); 
dt =xsolved (2 ); 


this .FullFitInfo (this .T +1 ,:)=[dm ,t +dt ]; 
fitData (useObs )=fitData (useObs )*exp (-dt )+mar (useObs )*dm ; 


w =rbw (fitData (useObs ),t +dt ,this .TargetAccuracy ,this .MaxMargin ,this .MarginSigma ); 
W (useObs )=w /sum (w )*sum (W (useObs )); 
W =W /sum (W ); 


mustTerminate =false ; 
tstart =this .T -4 ; 
tend =this .T +1 ; 
ifdt <0 ||dm <0 ||t +dt >=1 -eps ...
    ||(tstart >0 ...
    &&all (this .FullFitInfo (tstart :tend ,1 )<1 /numel (W ))...
    &&all (diff (this .FullFitInfo (tstart :tend ,2 ))/(t +dt )<1e-6 ))
ifdt <0 ||dm <0 
this .ReasonForTermination =getString (message ('stats:classreg:learning:modifier:RobustBoost:ReasonForTermination_2' )); 
else
this .ReasonForTermination =getString (message ('stats:classreg:learning:modifier:RobustBoost:ReasonForTermination_3' )); 
end
mustTerminate =true ; 
end
this .Terminated =mustTerminate ; 
end

function c =makeCombiner (this )
ifthis .T ==0 
c =classreg .learning .combiner .WeightedSum ([]); 
else
dT =exp (-(this .FitInfo (end,2 )-this .FitInfo (:,2 ))); 
beta =this .FitInfo (:,1 ).*dT ; 
c =classreg .learning .combiner .WeightedSum (beta ); 
end
end
end

end

function e =rberf (x )
e =(1 +erf (x ))/2 ; 
end

function [mu ,sgm ]=rbmusgm (z ,rho ,theta ,sigma )
sgm =sqrt ((sigma ^2 +1 )*exp (2 *z )-1 ); 
mu =(theta -2 *rho )*exp (z )+2 *rho ; 
end



function phi =rbphi (s ,t ,rho ,theta ,sigma )
z =1 -t ; 
ifz <=0 
phi =zeros (size (s )); 
gr0 =s >0 ; 
lt0 =s <0 ; 

phi (lt0 )=1 ; 
phi (~gr0 &~lt0 )=0.5 ; 
else
[mu ,sgm ]=rbmusgm (z ,rho ,theta ,sigma ); 
phi =1 -rberf ((s -mu )/sgm ); 
end
end

function w =rbw (s ,t ,rho ,theta ,sigma )
z =1 -t ; 
ifz <=0 
w =zeros (size (s )); 
else
[mu ,sgm ]=rbmusgm (z ,rho ,theta ,sigma ); 
w =exp (-((s -mu )/sgm ).^2 )/sqrt (pi )/sgm ; 
end
end



function [f ,J ]=objective (X ,M ,mar ,t ,rho ,theta ,sigma )




f =zeros (2 ,1 ); 
dm =X (1 ); 
dt =X (2 ); 
Mnew =M *exp (-dt )+mar *dm ; 
tnew =t +dt ; 
rbwi =rbw (Mnew ,tnew ,rho ,theta ,sigma ); 
ift +dt >=1 -eps 
f (1 )=0 ; 
else
f (1 )=sum (mar .*rbwi ); 
end
f (2 )=sum (rbphi (M ,t ,rho ,theta ,sigma )-rbphi (Mnew ,tnew ,rho ,theta ,sigma )); 


J =zeros (2 ); 
M =Mnew ; 
z =1 -tnew ; 
ifz <=0 
return ; 
end
[mu ,sgm ]=rbmusgm (z ,rho ,theta ,sigma ); 
J (1 ,1 )=-2 /sgm ^2 *sum (mar .^2 .*(M -mu ).*rbwi ); 
J (1 ,2 )=sum (mar .*(1 +sgm ^2 -2 *(M -mu ).*(M -2 *rho )-2 *((M -mu )/sgm ).^2 ).*rbwi )/sgm ^2 ; 
J (2 ,1 )=sum (mar .*rbwi ); 
J (2 ,2 )=sum ((M -2 *rho +(M -mu )/sgm ^2 ).*rbwi ); 
end
