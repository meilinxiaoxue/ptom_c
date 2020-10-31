function [xstar ,rxstar ,Jxstar ,cause ]=nlesolve (rfun ,x0 ,varargin )




























































































































































































































narginchk (2 ,Inf )


Default ='Default' ; 
TrustRegion2D ='TrustRegion2D' ; 
LineSearchModifiedNewton ='LineSearchModifiedNewton' ; 
LineSearchNewton ='LineSearchNewton' ; 


dfltTolFun =1e-6 ; 
dfltTolX =1e-12 ; 
dfltMaxIter =1000 ; 
dfltDisplay ='off' ; 


dfltoptions =struct ('TolFun' ,dfltTolFun ,'TolX' ,dfltTolX ,...
    'MaxIter' ,dfltMaxIter ,'Display' ,dfltDisplay ); 
dfltmethod =TrustRegion2D ; 


names ={'Options' ,'Method' }; 
dflts ={dfltoptions ,dfltmethod }; 
[options ,method ]=internal .stats .parseArgs (names ,dflts ,varargin {:}); 


assert (isstruct (options )); 
internal .stats .getParamVal (method ,{Default ,TrustRegion2D ,LineSearchModifiedNewton ,LineSearchNewton },'Method' ); 





gradTol =options .TolFun ; 
stepTol =options .TolX ; 
maxit =options .MaxIter ; 


ifstrcmpi (options .Display ,'off' )
verbose =false ; 
else
verbose =true ; 
end


assert (isa (rfun ,'function_handle' )); 
assert (isnumeric (x0 )&isreal (x0 )&iscolumn (x0 )); 


ifsize (x0 ,1 )==0 
xstar =x0 ; 
rxstar =zeros (0 ,1 ); 
Jxstar =zeros (0 ,0 ); 
cause =0 ; 
return ; 
end


switchlower (method )
case {lower (TrustRegion2D ),lower (Default )}
[xstar ,rxstar ,Jxstar ,cause ]=...
    nlesolveTrustRegion2D (rfun ,x0 ,gradTol ,stepTol ,maxit ,verbose ); 
case lower (LineSearchModifiedNewton )
[xstar ,rxstar ,Jxstar ,cause ]=...
    nlesolveLineSearchModifiedNewton (rfun ,x0 ,gradTol ,stepTol ,maxit ,verbose ); 
case lower (LineSearchNewton )
[xstar ,rxstar ,Jxstar ,cause ]=...
    nlesolveLineSearchNewton (rfun ,x0 ,gradTol ,stepTol ,maxit ,verbose ); 
end

end

function [xstar ,rxstar ,Jxstar ,cause ]=nlesolveTrustRegion2D (rfun ,x0 ,gradTol ,stepTol ,maxit ,verbose )


[rx0 ,Jx0 ,pnx0 ]=rfun (x0 ); 
gx0 =-Jx0 ' *rx0 ; 
ifany (isinf (gx0 ))
gx0 =replaceInf (gx0 ,realmax ); 
end



ifany (~isfinite (pnx0 ))
Delta0 =1 ; 
else
Delta0 =norm (pnx0 ); 
end
DeltaMax =max (Delta0 ,1e9 ); 



eta =5e-4 ; 
tol =eps (class (x0 ))^(1 /4 ); 


found =false ; 
iter =0 ; 


x =x0 ; 
rx =rx0 ; 
Jx =Jx0 ; 
pnx =pnx0 ; 
gx =gx0 ; 
twonormrx =norm (rx ); 
infnormgx =max (abs (gx )); 
infnormgx0 =infnormgx ; 


Delta =Delta0 ; 


while(found ==false )



if(all (isfinite (pnx ))&&norm (pnx )<=Delta )
p =pnx ; 
else



ifany (~isfinite (pnx ))
[Q ,~]=qr (gx ,0 ); 
else
[Q ,~]=qr ([gx ,pnx ],0 ); 
end


gbarx =-Q ' *gx ; 
Bbarx =Jx *Q ; 
Bbarx =Bbarx ' *Bbarx ; 


ifany (isinf (Bbarx (:)))
Bbarx =replaceInf (Bbarx ,realmax ); 
end
ifany (isinf (gbarx ))
gbarx =replaceInf (gbarx ,realmax ); 
end
u =solveTrustRegionProblemExact (gbarx ,Bbarx ,Delta ); 
p =Q *u ; 
end
twonorms =norm (p ); 


rxp =rfun (x +p ); 
rxtrx =rx ' *rx ; 
ared =rxtrx -rxp ' *rxp ; 
pred =rxtrx -norm (rx +Jx *p )^2 ; 
rho =ared /pred ; 


if(rho >eta )
stepTaken =true ; 
else
stepTaken =false ; 
end


if(verbose ==true )
displayConvergenceInfo (iter ,twonormrx ,infnormgx ,twonorms ,rho ,Delta ,stepTaken ); 
end


if(stepTaken ==true )
x =x +p ; 
[rx ,Jx ,pnx ]=rfun (x ); 
gx =-Jx ' *rx ; 
twonormrx =norm (rx ); 
infnormgx =max (abs (gx )); 
end


if(rho <0.25 ||isnan (rho ))
Delta =0.25 *Delta ; 


else
if(rho >0.75 &&abs (twonorms -Delta )<=tol )
Delta =min (2 *Delta ,DeltaMax ); 
end
end


tau =max (1 ,min (twonormrx ,infnormgx0 )); 
if(infnormgx <=tau *gradTol )
found =true ; 
cause =0 ; 
elseif(twonorms <=stepTol )
found =true ; 
cause =1 ; 
elseif(iter >maxit )
found =true ; 
cause =2 ; 
end


iter =iter +1 ; 


if(found ==true &&verbose ==true )
displayFinalConvergenceMessage (infnormgx ,tau ,gradTol ,twonorms ,stepTol ,cause ); 
end

end


xstar =x ; 
rxstar =rx ; 
Jxstar =Jx ; 

end

function [xstar ,rxstar ,Jxstar ,cause ]=nlesolveLineSearchModifiedNewton (rfun ,x0 ,gradTol ,stepTol ,maxit ,verbose )


[rx0 ,Jx0 ,pnx0 ]=rfun (x0 ); 
gx0 =-Jx0 ' *rx0 ; 
q =length (x0 ); 



c1 =1e-5 ; 
rho =0.5 ; 
delta =1e-2 ; 


found =false ; 
iter =0 ; 


x =x0 ; 
rx =rx0 ; 
Jx =Jx0 ; 
pnx =pnx0 ; 
gx =gx0 ; 
twonormrx =norm (rx ); 
infnormgx =max (abs (gx )); 
infnormgx0 =infnormgx ; 


while(found ==false )


adelta =pnx ' *gx /norm (pnx )/norm (gx ); 


if(adelta >delta )

p =pnx ; 
modifiedNewton =false ; 
else

modifiedNewton =true ; 

done =false ; 
beta =norm (Jx ,'fro' ); 
ifall (diag (Jx ))>0 
tau =0 ; 
else
tau =beta /2 ; 
end
mag =2 ; 
while(done ==false )
Jxplus =[Jx ; sqrt (tau )*eye (q )]; 
rxplus =[rx ; zeros (q ,1 )]; 
p =-(Jxplus \rxplus ); 
adelta =p ' *gx /norm (p )/norm (gx ); 
if(adelta >delta )
done =true ; 
else
tau =max (tau *mag ,beta /2 ); 
end
end
end


alpha =1.0 ; 
done =false ; 
term1 =0.5 *(rx ' *rx ); 
term2 =p ' *(-gx ); 
while(done ==false )
rxp =rfun (x +alpha *p ); 
isok =0.5 *(rxp ' *rxp )-(term1 +c1 *alpha *term2 )<=0 ; 
if(isok ==true )
done =true ; 
elseif(alpha <=stepTol )
done =true ; 
else
alpha =rho *alpha ; 
end
end
twonorms =alpha *norm (p ); 


if(verbose ==true )
displayConvergenceInfoLineSearch (iter ,twonormrx ,infnormgx ,twonorms ,adelta ,alpha ,modifiedNewton ); 
end


x =x +alpha *p ; 
[rx ,Jx ,pnx ]=rfun (x ); 
gx =-Jx ' *rx ; 
twonormrx =norm (rx ); 
infnormgx =max (abs (gx )); 


tau =max (1 ,min (twonormrx ,infnormgx0 )); 
if(infnormgx <=tau *gradTol )
found =true ; 
cause =0 ; 
elseif(twonorms <=stepTol )
found =true ; 
cause =1 ; 
elseif(iter >maxit )
found =true ; 
cause =2 ; 
end


iter =iter +1 ; 


if(found ==true &&verbose ==true )
displayFinalConvergenceMessage (infnormgx ,tau ,gradTol ,twonorms ,stepTol ,cause ); 
end

end


xstar =x ; 
rxstar =rx ; 
Jxstar =Jx ; 

end

function [xstar ,rxstar ,Jxstar ,cause ]=nlesolveLineSearchNewton (rfun ,x0 ,gradTol ,stepTol ,maxit ,verbose )


[rx0 ,Jx0 ,pnx0 ]=rfun (x0 ); 
gx0 =-Jx0 ' *rx0 ; 



c1 =1e-5 ; 
rho =0.5 ; 


found =false ; 
iter =0 ; 


x =x0 ; 
rx =rx0 ; 
Jx =Jx0 ; 
pnx =pnx0 ; 
gx =gx0 ; 
twonormrx =norm (rx ); 
infnormgx =max (abs (gx )); 
infnormgx0 =infnormgx ; 
modifiedNewton =false ; 


while(found ==false )


adelta =pnx ' *gx /norm (pnx )/norm (gx ); 


p =pnx ; 


alpha =1.0 ; 
done =false ; 
term1 =0.5 *(rx ' *rx ); 
term2 =p ' *(-gx ); 
while(done ==false )
rxp =rfun (x +alpha *p ); 
isok =0.5 *(rxp ' *rxp )-(term1 +c1 *alpha *term2 )<=0 ; 
if(isok ==true )
done =true ; 
elseif(alpha <=stepTol )
done =true ; 
else
alpha =rho *alpha ; 
end
end
twonorms =alpha *norm (p ); 


if(verbose ==true )
displayConvergenceInfoLineSearch (iter ,twonormrx ,infnormgx ,twonorms ,adelta ,alpha ,modifiedNewton ); 
end


x =x +alpha *p ; 
[rx ,Jx ,pnx ]=rfun (x ); 
gx =-Jx ' *rx ; 
twonormrx =norm (rx ); 
infnormgx =max (abs (gx )); 


tau =max (1 ,min (twonormrx ,infnormgx0 )); 
if(infnormgx <=tau *gradTol )
found =true ; 
cause =0 ; 
elseif(twonorms <=stepTol )
found =true ; 
cause =1 ; 
elseif(iter >maxit )
found =true ; 
cause =2 ; 
end


iter =iter +1 ; 


if(found ==true &&verbose ==true )
displayFinalConvergenceMessage (infnormgx ,tau ,gradTol ,twonorms ,stepTol ,cause ); 
end

end


xstar =x ; 
rxstar =rx ; 
Jxstar =Jx ; 

end


function displayConvergenceInfoLineSearch (iter ,twonormr ,infnormg ,twonorms ,adelta ,alpha ,modifiedNewton )




















if(rem (iter ,20 )==0 )

fprintf ('\n' ); 
fprintf ('  -----------------------------------------------------------------------------------------\n' ); 
fprintf ('  ITER     ||r(x)||    ||J(x)^T r(x)||    NORM STEP    cos(theta)     alpha     Mod Newton?\n' ); 
fprintf ('  -----------------------------------------------------------------------------------------\n' ); 
end


ifmodifiedNewton ==true 
modifiedNewtonString ='YES' ; 
else
modifiedNewtonString =' NO' ; 
end
fprintf ('%6d    %+6.3e      %06.3e       %06.3e    %+6.3e    %06.3e     %3s\n' ,iter ,twonormr ,infnormg ,twonorms ,adelta ,alpha ,modifiedNewtonString ); 
end


function displayConvergenceInfo (iter ,twonormr ,infnormg ,twonorms ,rho ,Delta ,stepTaken )




















if(rem (iter ,20 )==0 )

fprintf ('\n' ); 
fprintf ('  -------------------------------------------------------------------------------------\n' ); 
fprintf ('  ITER     ||r(x)||    ||J(x)^T r(x)||    NORM STEP        RHO       TRUST RAD   ACCEPT\n' ); 
fprintf ('  -------------------------------------------------------------------------------------\n' ); 
end


ifstepTaken ==true 
stepTakenString ='YES' ; 
else
stepTakenString =' NO' ; 
end
fprintf ('%6d    %+6.3e      %06.3e       %06.3e    %+6.3e    %06.3e     %3s\n' ,iter ,twonormr ,infnormg ,twonorms ,rho ,Delta ,stepTakenString ); 
end


function displayFinalConvergenceMessage (infnormg ,tau ,gradTol ,twonorms ,stepTol ,cause )










fprintf ('\n' ); 
infnormgStr =getString (message ('stats:classreg:regr:lmeutils:fminqn:FinalConvergenceMessage_InfNormGrad' )); 
fprintf (['         ' ,infnormgStr ,' ' ,'%6.3e\n' ],infnormg ); 
twonormsStr =getString (message ('stats:classreg:regr:lmeutils:fminqn:FinalConvergenceMessage_TwoNormStep' )); 
fprintf (['              ' ,twonormsStr ,' ' ,'%6.3e, ' ,'TolX   =' ,' ' ,'%6.3e\n' ],twonorms ,stepTol ); 
relinfnormgStr =getString (message ('stats:classreg:regr:lmeutils:fminqn:FinalConvergenceMessage_RelInfNormGrad' )); 
fprintf ([relinfnormgStr ,' ' ,'%6.3e, ' ,'TolFun =' ,' ' ,'%6.3e\n' ],infnormg /tau ,gradTol ); 


if(cause ==0 )

fprintf ([getString (message ('stats:classreg:regr:lmeutils:fminqn:Message_LocalMinFound' )),'\n' ]); 
elseif(cause ==1 )

fprintf ([getString (message ('stats:classreg:regr:lmeutils:fminqn:Message_LocalMinPossible' )),'\n' ]); 
elseif(cause ==2 )

fprintf ([getString (message ('stats:classreg:regr:lmeutils:fminqn:Message_UnableToConverge' )),'\n' ]); 
end
end


function B =replaceInf (B ,value )











absvalue =abs (value ); 


isinfB =isinf (B ); 


B (isinfB &B >0 )=absvalue ; 


B (isinfB &B <0 )=-absvalue ; 
end

