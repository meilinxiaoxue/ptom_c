function [theta ,funtheta ,gradfuntheta ,cause ]=fminlbfgs (fun ,theta0 ,varargin )




























































































































































































































narginchk (2 ,Inf ); 




dfltTolFun =1e-6 ; 
dfltTolX =1e-6 ; 
dfltDisplay ='off' ; 
dfltMaxIter =10000 ; 
dfltGradObj ='off' ; 
dfltoptions =statset ('TolFun' ,dfltTolFun ,...
    'TolX' ,dfltTolX ,...
    'Display' ,dfltDisplay ,...
    'MaxIter' ,dfltMaxIter ,...
    'GradObj' ,dfltGradObj ); 


dfltGamma =1 ; 
dfltMemory =10 ; 
dfltStep =[]; 

weakWolfe =classreg .learning .fsutils .Solver .LineSearchMethodWeakWolfe ; 
strongWolfe =classreg .learning .fsutils .Solver .LineSearchMethodStrongWolfe ; 
backtracking =classreg .learning .fsutils .Solver .LineSearchMethodBacktracking ; 
dfltLineSearch =weakWolfe ; 

dfltMaxLineSearchIter =20 ; 

dfltOutputFcn =[]; 


names ={'Options' ,'Gamma' ,'Memory' ,'Step' ,'LineSearch' ,'MaxLineSearchIter' ,'OutputFcn' }; 
dflts ={dfltoptions ,dfltGamma ,dfltMemory ,dfltStep ,dfltLineSearch ,dfltMaxLineSearchIter ,dfltOutputFcn }; 
[options ,gamma ,memsize ,step ,linesearchtype ,maxlinesearchiter ,outfun ]=internal .stats .parseArgs (names ,dflts ,varargin {:}); 



if(~isstruct (options ))
error (message ('stats:classreg:learning:fsutils:fminlbfgs:BadOptions' )); 
end


isok =isnumeric (gamma )&isreal (gamma )&isscalar (gamma )&(gamma >0 ); 
if(~isok )
error (message ('stats:classreg:learning:fsutils:fminlbfgs:BadGamma' )); 
end


isok =internal .stats .isIntegerVals (memsize ,1 ); 
if(~isok )
error (message ('stats:classreg:learning:fsutils:fminlbfgs:BadMemory' )); 
end


if(~isempty (step ))
isok =isnumeric (step )&isreal (step )&isscalar (step )&(step >0 ); 
if(~isok )
error (message ('stats:classreg:learning:fsutils:fminlbfgs:BadStep' )); 
end
end


linesearchtype =internal .stats .getParamVal (linesearchtype ,{weakWolfe ,strongWolfe ,backtracking },'LineSearch' ); 


weakWolfeCode =1 ; 
strongWolfeCode =2 ; 
backtrackingCode =3 ; 

switchlower (linesearchtype )
case lower (weakWolfe )
linesearchCode =weakWolfeCode ; 

case lower (strongWolfe )
linesearchCode =strongWolfeCode ; 

case lower (backtracking )
linesearchCode =backtrackingCode ; 
end


isok =internal .stats .isIntegerVals (maxlinesearchiter ,1 ); 
if(~isok )
error (message ('stats:classreg:learning:fsutils:fminlbfgs:BadMaxLineSearchIter' )); 
end


if(~isempty (outfun ))
isok =isa (outfun ,'function_handle' ); 
if(~isok )
error (message ('stats:classreg:learning:fsutils:fminlbfgs:BadOutputFcn' )); 
end
end




options =statset (dfltoptions ,options ); 


gradTol =options .TolFun ; 
stepTol =options .TolX ; 
maxit =options .MaxIter ; 



if(strcmpi (options .Display ,'off' ))
verbose =false ; 
else
verbose =true ; 
end


if(strcmpi (options .GradObj ,'on' ))
haveGrad =true ; 
else
haveGrad =false ; 
end



fun =validateFun (fun ); 




theta0 =validateTheta0 (theta0 ); 


[theta ,funtheta ,gradfuntheta ,cause ]=doLBFGS (fun ,theta0 ,gamma ,memsize ,step ,linesearchCode ,maxlinesearchiter ,outfun ,gradTol ,stepTol ,maxit ,verbose ,haveGrad ,weakWolfeCode ,strongWolfeCode ,backtrackingCode ); 
end


function [theta ,funtheta ,gradfuntheta ,cause ]=doLBFGS (fun ,theta0 ,gamma ,memsize ,step ,linesearchCode ,maxlinesearchiter ,outfun ,gradTol ,stepTol ,maxit ,verbose ,haveGrad ,weakWolfeCode ,strongWolfeCode ,backtrackingCode )




n =numel (theta0 ); 


if(n ==0 )
theta =theta0 ; 
funtheta =[]; 
gradfuntheta =[]; 
cause =0 ; 
return ; 
end





if(~haveGrad )
gradfun =makeGradient (fun ); 
else
gradfun =[]; 
end




x =theta0 ; 
[f ,g ]=funAndGrad (x ,fun ,gradfun ,haveGrad ); 

errorIfNotScalar (f ); 
infnormg =max (abs (g )); 


if(f ==-Inf )
theta =x ; 
funtheta =f ; 
gradfuntheta =g ; 
cause =0 ; 
return ; 
end



infnormg0 =infnormg ; 



if(~isempty (step ))
gamma =step /max (sqrt (eps ),infnormg0 ); 
end



gamma0 =gamma ; 




c1 =1e-4 ; 
c2 =0.9 ; 







memused =0 ; 
S =zeros (n ,memused ); 
Y =zeros (n ,memused ); 
Rho =zeros (1 ,memused ); 
order =zeros (1 ,memused ); 






found =false ; 





iter =0 ; 
numfailed =0 ; 
maxnumfailed =2 ; 














if(isempty (outfun ))
haveOutputFcn =false ; 
else
haveOutputFcn =true ; 
end


if(haveOutputFcn )

optimValues =struct (); 
optimValues .iteration =iter ; 
optimValues .fval =f ; 
optimValues .gradient =g ; 
optimValues .stepsize =0 ; 
state ='init' ; 


stop =callOutputFcn (x ,optimValues ,state ,outfun ); 


if(stop )
found =true ; 
cause =4 ; 
end
end


if(verbose ==true )
twonorms =0 ; 
curvokstr =' ' ; 

alpha =0 ; 
success =true ; 
displayConvergenceInfo (iter ,f ,infnormg ,twonorms ,curvokstr ,gamma ,alpha ,success ); 
end


while(found ==false )



p =matrixVectorProductLBFGS (S ,Y ,Rho ,order ,gamma ,-g ); 






gtp =g ' *p ; 
if(gtp >=0 )
isLBFGSdirOK =false ; 


memused =0 ; 
S =zeros (n ,memused ); 
Y =zeros (n ,memused ); 
Rho =zeros (1 ,memused ); 
order =zeros (1 ,memused ); 
gamma =gamma0 ; 


p =-gamma *g ; 
else
isLBFGSdirOK =true ; 
end





[alpha ,xs ,fs ,gs ,success ]=doLineSearch (x ,f ,g ,p ,haveGrad ,fun ,gradfun ,c1 ,c2 ,maxlinesearchiter ,linesearchCode ,weakWolfeCode ,strongWolfeCode ,backtrackingCode ); 




if(isLBFGSdirOK &&~success )

memused =0 ; 
S =zeros (n ,memused ); 
Y =zeros (n ,memused ); 
Rho =zeros (1 ,memused ); 
order =zeros (1 ,memused ); 
gamma =gamma0 ; 


p =-gamma *g ; 


[alpha ,xs ,fs ,gs ,success ]=doLineSearch (x ,f ,g ,p ,haveGrad ,fun ,gradfun ,c1 ,c2 ,maxlinesearchiter ,linesearchCode ,weakWolfeCode ,strongWolfeCode ,backtrackingCode ); 
end


s =xs -x ; 
y =gs -g ; 


yts =y ' *s ; 
curvok =yts >=(c2 -1 )*(g ' *s ); 

if(curvok &&success &&(alpha >0 ))
if(memused ==memsize )

rho =1 /yts ; 
oldidx =order (end); 
S (:,oldidx )=s ; 
Y (:,oldidx )=y ; 
Rho (1 ,oldidx )=rho ; 
order =[oldidx ,order ]; 
order (end)=[]; 
else

rho =1 /yts ; 
memused =memused +1 ; 
S =[S ,s ]; 
Y =[Y ,y ]; 
Rho =[Rho ,rho ]; %#ok<*AGROW> 
order =[memused ,order ]; 
end

gamma =yts /(y ' *y ); 
end


if(success )
x =xs ; 
f =fs ; 
g =gs ; 
infnormg =norm (g ,Inf ); 

numfailed =0 ; 
else
numfailed =numfailed +1 ; 
end


twonorms =norm (s ); 


tau =max (1 ,min (abs (f ),infnormg0 )); 
if(infnormg <=tau *gradTol )
found =true ; 

cause =0 ; 
elseif(twonorms <=stepTol )
found =true ; 

cause =1 ; 
elseif(isinf (f )&&f <0 )

found =true ; 

cause =0 ; 
elseif(numfailed >=maxnumfailed )
found =true ; 

cause =3 ; 
end


iter =iter +1 ; 


if(iter >=maxit )
found =true ; 

cause =2 ; 
end


if(verbose ==true )
if(curvok )
curvokstr ='OK' ; 
else
curvokstr ='NO' ; 
end
displayConvergenceInfo (iter ,f ,infnormg ,twonorms ,curvokstr ,gamma ,alpha ,success ); 
end


if(haveOutputFcn )
if(found ==true )

optimValues .iteration =iter ; 
optimValues .fval =f ; 
optimValues .gradient =g ; 
optimValues .stepsize =twonorms ; 
state ='done' ; 


callOutputFcn (x ,optimValues ,state ,outfun ); 
elseif(success )

optimValues .iteration =iter ; 
optimValues .fval =f ; 
optimValues .gradient =g ; 
optimValues .stepsize =twonorms ; 
state ='iter' ; 


stop =callOutputFcn (x ,optimValues ,state ,outfun ); 


if(stop )
found =true ; 
cause =4 ; 
end
end
end


if(found ==true &&verbose ==true )
displayFinalConvergenceMessage (infnormg ,tau ,gradTol ,twonorms ,stepTol ,cause ); 
end

end


theta =x ; 
funtheta =f ; 
gradfuntheta =g ; 

end

function [f ,g ]=funAndGrad (x ,fun ,gradfun ,haveGrad )








if(haveGrad )
[f ,g ]=fun (x ); 
else
f =fun (x ); 
g =gradfun (x ); 
end
end


function [alpha ,xs ,fs ,gs ,success ]=doLineSearch (x ,f ,g ,p ,haveGrad ,fun ,gradfun ,c1 ,c2 ,maxit ,linesearchCode ,weakWolfeCode ,strongWolfeCode ,backtrackingCode )





































switch(linesearchCode )
case weakWolfeCode 
[alpha ,xs ,fs ,gs ,success ]=weakWolfeLineSearch (x ,f ,g ,p ,haveGrad ,fun ,gradfun ,c1 ,c2 ,maxit ); 

case strongWolfeCode 
[alpha ,xs ,fs ,gs ,success ]=strongWolfeLineSearch (x ,f ,g ,p ,haveGrad ,fun ,gradfun ,c1 ,c2 ,maxit ); 

case backtrackingCode 
[alpha ,xs ,fs ,gs ,success ]=backTrackingLineSearch (x ,f ,g ,p ,haveGrad ,fun ,gradfun ,c1 ,c2 ,maxit ); 

otherwise
error (message ('stats:classreg:learning:fsutils:fminlbfgs:BadLineSearchMethod' )); 
end
end


function [alpha ,xs ,fs ,gs ,success ]=backTrackingLineSearch (x ,f ,g ,p ,haveGrad ,fun ,gradfun ,c1 ,c2 ,maxit )%#ok<INUSL> 
































alpha =1 ; 


gtp =g ' *p ; 




iter =0 ; 
found =false ; 
success =false ; 

while(not (found ))

xs =x +alpha *p ; 
[fs ,gs ]=funAndGrad (xs ,fun ,gradfun ,haveGrad ); 


if(fs >(f +c1 *alpha *gtp ))
alpha =0.5 *alpha ; 
else
success =true ; 
return ; 
end


iter =iter +1 ; 

if(iter >=maxit )
found =true ; 
success =false ; 
end
end
end


function [alpha ,xs ,fs ,gs ,success ]=weakWolfeLineSearch (x ,f ,g ,p ,haveGrad ,fun ,gradfun ,c1 ,c2 ,maxit )


































a =0 ; 
b =Inf ; 
alpha =1 ; 


gtp =g ' *p ; 




iter =0 ; 
found =false ; 
success =false ; 

while(found ==false )

xs =x +alpha *p ; 
[fs ,gs ]=funAndGrad (xs ,fun ,gradfun ,haveGrad ); 


if(fs >(f +c1 *alpha *gtp ))

b =alpha ; 
alpha =0.5 *(a +b ); 

elseif((gs ' *p )<c2 *gtp )

a =alpha ; 
ifisinf (b )
alpha =2 *a ; 
else
alpha =0.5 *(a +b ); 
end

else

success =true ; 
return ; 
end


iter =iter +1 ; 

if(iter >=maxit )
found =true ; 
success =false ; 
end
end
end


function [alpha ,xs ,fs ,gs ,success ]=strongWolfeLineSearch (x ,f ,g ,p ,haveGrad ,fun ,gradfun ,c1 ,c2 ,maxit )

































alphamax =1e20 ; 
theta =2 ; 


phi0 =f ; 
dphi0 =p ' *g ; 


alphaA =0 ; 
xA =x ; 
fA =f ; 
gA =g ; 
phiA =phi0 ; 
dphiA =dphi0 ; 



alphaB =1 ; 


iter =0 ; 
found =false ; 

while(not (found ))


xB =x +alphaB *p ; 
[fB ,gB ]=funAndGrad (xB ,fun ,gradfun ,haveGrad ); 
phiB =fB ; 
dphiB =p ' *gB ; 


if((phiB >phi0 +c1 *alphaB *dphi0 )||(phiB >=phiA &&iter >0 ))
[alpha ,xs ,fs ,gs ,success ]=strongWolfeZoom (alphaA ,phiA ,dphiA ,alphaB ,phiB ,dphiB ,fun ,gradfun ,x ,p ,haveGrad ,phi0 ,dphi0 ,c1 ,c2 ); 
if(not (success ))


alpha =alphaA ; 
xs =xA ; 
fs =fA ; 
gs =gA ; 
end
return ; 
end


if(abs (dphiB )<=-c2 *dphi0 )
alpha =alphaB ; 
xs =xB ; 
fs =fB ; 
gs =gB ; 
success =true ; 
return ; 
end




if(dphiB >0 )
[alpha ,xs ,fs ,gs ,success ]=strongWolfeZoom (alphaB ,phiB ,dphiB ,alphaA ,phiA ,dphiA ,fun ,gradfun ,x ,p ,haveGrad ,phi0 ,dphi0 ,c1 ,c2 ); 
if(not (success ))


alpha =alphaB ; 
xs =xB ; 
fs =fB ; 
gs =gB ; 
end
return ; 
end


iter =iter +1 ; 


if(iter >=maxit )


alpha =alphaB ; 
xs =xB ; 
fs =fB ; 
gs =gB ; 
success =false ; 
return ; 
end



alphaA =alphaB ; 
xA =xB ; 
fA =fB ; 
gA =gB ; 
phiA =phiB ; 
dphiA =dphiB ; 

alphaB =min (theta *alphaB ,alphamax ); 
end
end

function [alpha ,xs ,fs ,gs ,success ]=strongWolfeZoom (alphaLo ,phiLo ,dphiLo ,alphaHi ,phiHi ,dphiHi ,fun ,gradfun ,x ,p ,haveGrad ,phi0 ,dphi0 ,c1 ,c2 )



























found =false ; 
maxit =50 ; 
iter =0 ; 

while(not (found ))




alphaj =minimizeCubicInterpolant (alphaLo ,phiLo ,dphiLo ,alphaHi ,phiHi ,dphiHi ); 


xs =x +alphaj *p ; 
[fs ,gs ]=funAndGrad (xs ,fun ,gradfun ,haveGrad ); 
phij =fs ; 
dphij =p ' *gs ; 

if((phij >phi0 +c1 *alphaj *dphi0 )||(phij >=phiLo ))



alphaHi =alphaj ; 
phiHi =phij ; 
dphiHi =dphij ; 
else



if(abs (dphij )<=-c2 *dphi0 )
alpha =alphaj ; 
success =true ; 
return ; 
end








if(dphij *(alphaHi -alphaLo )>=0 )
alphaHi =alphaLo ; 
phiHi =phiLo ; 
dphiHi =dphiLo ; 
end

alphaLo =alphaj ; 
phiLo =phij ; 
dphiLo =dphij ; 
end


iter =iter +1 ; 

if(iter >=maxit )
found =true ; 


alpha =alphaj ; 
success =false ; 
end
end
end

function [alpha ,isMinimizer ]=minimizeCubicInterpolant (a ,phia ,dphia ,b ,phib ,dphib )









delta =b -a ; 

if(delta ==0 )
alpha =a ; 
isMinimizer =false ; 
return ; 
end


d1 =(dphib +dphia )-3 *((phib -phia )/delta ); 


discr =d1 ^2 -dphia *dphib ; 

if(discr <=0 )
alpha =0.5 *(a +b ); 
isMinimizer =false ; 
return ; 
end


c1 =(dphib +dphia +2 *d1 )/(3 *delta ^2 ); 
tol =sqrt (eps (class (c1 ))); 

if(abs (c1 )<tol )
if(dphia *delta >=0 )
alpha =0.5 *(a +b ); 
isMinimizer =false ; 
return ; 
end
end


d2 =sign (delta )*sqrt (discr ); 


h =((dphib +d2 -d1 )/(dphib -dphia +2 *d2 )); 
alpha =b -delta *h ; 
isMinimizer =true ; 


if((alpha -a )*(alpha -b )>=0 )
alpha =0.5 *(a +b ); 
isMinimizer =false ; 
return ; 
end




frac =1e-3 ; 
thresh =frac *abs (delta ); 
if((abs (alpha -a )<thresh )||(abs (alpha -b )<thresh ))

alpha =0.5 *(a +b ); 
isMinimizer =false ; 
end
end


function r =matrixVectorProductLBFGS (S ,Y ,Rho ,order ,gamma ,q )





























[~,m ]=size (S ); 
a =zeros (1 ,m ); 


fori =order 
a (i )=Rho (i )*(S (:,i )' *q ); 
q =q -Y (:,i )*a (i ); 
end


r =gamma *q ; 


fori =fliplr (order )
beta =Rho (i )*(Y (:,i )' *r ); 
r =r +S (:,i )*(a (i )-beta ); 
end
end


function displayFinalConvergenceMessage (infnormg ,tau ,gradTol ,twonorms ,stepTol ,cause )















fprintf ('\n' ); 
infnormgStr =getString (message ('stats:classreg:learning:fsutils:fminlbfgs:FinalConvergenceMessage_InfNormGrad' )); 
fprintf (['         ' ,infnormgStr ,' ' ,'%6.3e\n' ],infnormg ); 
twonormsStr =getString (message ('stats:classreg:learning:fsutils:fminlbfgs:FinalConvergenceMessage_TwoNormStep' )); 
fprintf (['              ' ,twonormsStr ,' ' ,'%6.3e, ' ,'TolX   =' ,' ' ,'%6.3e\n' ],twonorms ,stepTol ); 
relinfnormgStr =getString (message ('stats:classreg:learning:fsutils:fminlbfgs:FinalConvergenceMessage_RelInfNormGrad' )); 
fprintf ([relinfnormgStr ,' ' ,'%6.3e, ' ,'TolFun =' ,' ' ,'%6.3e\n' ],infnormg /tau ,gradTol ); 


if(cause ==0 )

fprintf ([getString (message ('stats:classreg:learning:fsutils:fminlbfgs:Message_LocalMinFound' )),'\n' ]); 
elseif(cause ==1 )

fprintf ([getString (message ('stats:classreg:learning:fsutils:fminlbfgs:Message_LocalMinPossible' )),'\n' ]); 
elseif(cause ==2 )

fprintf ([getString (message ('stats:classreg:learning:fsutils:fminlbfgs:Message_UnableToConverge' )),'\n' ]); 
elseif(cause ==3 )

fprintf ([getString (message ('stats:classreg:learning:fsutils:fminlbfgs:Message_LineSearchFailed' )),'\n' ]); 
elseif(cause ==4 )

fprintf ([getString (message ('stats:classreg:learning:fsutils:fminlbfgs:Message_StoppedByOutputFcn' )),'\n' ]); 
end
end

function displayConvergenceInfo (iter ,f ,infnormg ,twonorms ,curvokstr ,gamma ,alpha ,success )































if(rem (iter ,20 )==0 )
fprintf ('\n' ); 
fprintf ('|====================================================================================================|\n' ); 
fprintf ('|   ITER   |   FUN VALUE   |  NORM GRAD  |  NORM STEP  |  CURV  |    GAMMA    |    ALPHA    | ACCEPT |\n' ); 
fprintf ('|====================================================================================================|\n' ); 
end


if(success )
stepTakenString ='YES' ; 
else
stepTakenString =' NO' ; 
end
fprintf ('|%9d |%14.6e |%12.3e |%12.3e |%6s  |%12.3e |%12.3e |%6s  |\n' ,iter ,f ,infnormg ,twonorms ,curvokstr ,gamma ,alpha ,stepTakenString ); 
end


function stop =callOutputFcn (x ,optimValues ,state ,outfun )



















stop =outfun (x ,optimValues ,state ); 
end



function gfun =makeGradient (fun )






gfun =@(theta )classreg .learning .fsutils .Solver .getGradient (fun ,theta ); 
end


function fun =validateFun (fun )




assertThat (isa (fun ,'function_handle' ),'stats:classreg:learning:fsutils:fminlbfgs:BadFun' ); 
end


function theta0 =validateTheta0 (theta0 )










assertThat (isnumeric (theta0 )&isreal (theta0 )&isvector (theta0 ),'stats:classreg:learning:fsutils:fminlbfgs:BadTheta0_NumericRealVector' ); 

assertThat (~any (isnan (theta0 ))&~any (isinf (theta0 )),'stats:classreg:learning:fsutils:fminlbfgs:BadTheta0_NoNaNInf' ); 

if(size (theta0 ,1 )==1 )
theta0 =theta0 ' ; 
end
end


function errorIfNotScalar (funtheta0 )





assertThat (isscalar (funtheta0 ),'stats:classreg:learning:fsutils:fminlbfgs:BadFunTheta0' ); 
end


function assertThat (condition ,msgID ,varargin )






if(~condition )

try
msg =message (msgID ,varargin {:}); 
catch 
error (message ('stats:LinearMixedModel:BadMsgID' ,msgID )); 
end

ME =MException (msg .Identifier ,getString (msg )); 
throwAsCaller (ME ); 
end
end
