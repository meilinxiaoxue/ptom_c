function [theta ,funtheta ,gradfuntheta ,cause ]=fminqn (fun ,theta0 ,varargin )




























































































































narginchk (2 ,Inf ); 





dfltTolFun =1e-6 ; 
dfltTolX =1e-12 ; 
dfltDisplay ='off' ; 
dfltMaxIter =10000 ; 
dfltGradObj ='off' ; 
dfltoptions =...
    statset ('TolFun' ,dfltTolFun ,...
    'TolX' ,dfltTolX ,...
    'Display' ,dfltDisplay ,...
    'MaxIter' ,dfltMaxIter ,...
    'GradObj' ,dfltGradObj ); 
dfltGamma =[]; 
dfltInitialStepSize =[]; 

names ={'Options' ,'Gamma' ,'InitialStepSize' }; 
dflts ={dfltoptions ,dfltGamma ,dfltInitialStepSize }; 
[options ,...
    gamma ,...
    initialStepSize ]=internal .stats .parseArgs (names ,dflts ,varargin {:}); 

options =validateOptions (options ); 
gamma =validateGamma (gamma ); 
initialStepSize =validateInitialStepSize (initialStepSize ); 



options =statset (dfltoptions ,options ); 


gradTol =options .TolFun ; 
stepTol =options .TolX ; 
maxit =options .MaxIter ; 


ifstrcmpi (options .Display ,'off' )
verbose =false ; 
else
verbose =true ; 
end

ifstrcmpi (options .GradObj ,'on' )
haveGrad =true ; 
else
haveGrad =false ; 
end




fun =validateFun (fun ); 




theta0 =validateTheta0 (theta0 ); 



if(numel (theta0 )==0 )
theta =theta0 ; 
funtheta =[]; 
gradfuntheta =[]; 
cause =0 ; 
return ; 
end





if~haveGrad 
gradfun =MakeGradient (fun ); 
end





x =theta0 ; 
ifhaveGrad 
[f ,g ]=fun (x ); 
else
f =fun (x ); 
g =gradfun (x ); 
end
errorIfNotScalar (f ); 
g =replaceInf (g ,realmax ); 
infnormg =max (abs (g )); 


if(f ==-Inf )

theta =x ; 
funtheta =f ; 
gradfuntheta =g ; 
cause =0 ; 
return ; 
end


ifisempty (initialStepSize )
ifisempty (gamma )
Bdiag =getDiagonalHessian (fun ,x ); 
gamma =max (100 ,max (abs (Bdiag ))); 
B =gamma *eye (length (x )); 
else
B =gamma *eye (length (x )); 
end
else
gamma =infnormg /max (sqrt (eps ),initialStepSize ); 
B =gamma *eye (length (x )); 
end


B =replaceInf (B ,realmax ); 



infnormg0 =infnormg ; 





DeltaMax =1e9 ; 



[p0 ,~,isposdefB ]=classreg .learning .gputils .solveTrustRegionProblemExact (g ,B ,DeltaMax ); 
ifisposdefB 
Delta =max (sqrt (length (x )),norm (p0 )); 
else
Delta =sqrt (length (x )); 
end



eta =5e-4 ; 
r =1e-8 ; 





found =false ; 


iter =0 ; 


numAccepted =0 ; 


while(found ==false )





epsk =min (0.5 ,sqrt (infnormg ))*infnormg ; 
[s ,reasonCGTerm ]...
    =solveTrustRegionProblem (g ,B ,Delta ,epsk ); 
ifany (strcmpi (reasonCGTerm ,{'NEG CURV' ,'NaNORInf' }))

B =replaceInf ((B +B ' )/2 ,realmax ); 
s =classreg .learning .gputils .solveTrustRegionProblemExact (g ,B ,Delta ); 
reasonCGTerm ='EXACT' ; 
end


xs =(x +s ); 



ifhaveGrad 
[fs ,gs ]=fun (xs ); 
else
fs =fun (xs ); 
gs =gradfun (xs ); 
end
y =gs -g ; 


ared =f -fs ; 
pred =-(g ' *s +0.5 *(s ' *B *s )); 


rho =ared /pred ; 



stepTaken =false ; 
if(rho >eta )
numAccepted =numAccepted +1 ; 
stepTaken =true ; 
x =xs ; 
f =fs ; 
g =gs ; 
infnormg =max (abs (g )); 
end


twonorms =norm (s ); 


if(verbose ==true )
displayConvergenceInfo (iter ,f ,infnormg ,twonorms ,reasonCGTerm ,rho ,Delta ,stepTaken ); 
end


if(rho >0.75 )

if(twonorms >0.8 *Delta )

Delta =min (2 *Delta ,DeltaMax ); 
end

elseif(rho <0.1 )


Delta =0.5 *Delta ; 

end


y_Bs =(y -B *s ); 
y_Bs_times_s =s ' *y_Bs ; 
applyUpdate =abs (y_Bs_times_s )>=r *twonorms *norm (y_Bs ); 


ifapplyUpdate 

incr =((y_Bs *y_Bs ' )/y_Bs_times_s ); 
if~any (isnan (incr (:)))&&~any (isinf (incr (:)))

B =B +incr ; 
else


end
end


tau =max (1 ,min (abs (f ),infnormg0 )); 
if(infnormg <=tau *gradTol )
found =true ; 

cause =0 ; 
elseif(twonorms <=stepTol )
found =true ; 

cause =1 ; 
elseif(f ==-Inf )

found =true ; 

cause =0 ; 
end


if(iter >maxit )
found =true ; 

cause =2 ; 
end


if(found ==true &&verbose ==true )
displayFinalConvergenceMessage (infnormg ,tau ,gradTol ,twonorms ,stepTol ,cause ); 
end


iter =iter +1 ; 

end


theta =x ; 
ifnargout >1 
ifhaveGrad 
[funtheta ,gradfuntheta ]=fun (x ); 
else
funtheta =fun (x ); 
gradfuntheta =gradfun (x ); 
end
end

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


function displayConvergenceInfo (iter ,f ,infnormg ,twonorms ,reasonCGTerm ,rho ,Delta ,stepTaken )


























if(rem (iter ,20 )==0 )

fprintf ('\n' ); 
fprintf ('|=====================================================================================================|\n' ); 
fprintf ('|   ITER   |   FUN VALUE   |  NORM GRAD  |  NORM STEP  | CG TERM |     RHO     |  TRUST RAD  | ACCEPT |\n' ); 
fprintf ('|=====================================================================================================|\n' ); 
end


ifstepTaken ==true 
stepTakenString ='YES' ; 
else
stepTakenString =' NO' ; 
end
fprintf ('|%9d |%14.5e |%12.3e |%12.3e |%7s  |%12.3e |%12.3e |%6s  |\n' ,iter ,f ,infnormg ,twonorms ,reasonCGTerm ,rho ,Delta ,stepTakenString ); 
end


function [p ,reasonCGTerm ]=solveTrustRegionProblem (g ,B ,Delta ,epsk )


































if(any (isnan (g ))||any (isnan (B (:)))...
    ||any (isinf (g ))||any (isinf (B (:))))
p =NaN (length (g ),1 ); 
reasonCGTerm ='NaNORInf' ; 
return ; 
end




z =zeros (length (g ),1 ); 
r =g ; 
d =-r ; 


reasonCGTerm ='CONV' ; 


if(norm (r )<epsk )
p =z ; 
reasonCGTerm ='CONV' ; 
return ; 
end


found =false ; 


while(found ==false )

dBd =(d ' *B *d ); 

if(dBd <=0 )


reasonCGTerm ='NEG CURV' ; 




















zd =z ' *d ; 
dd =d ' *d ; 
zz =z ' *z ; 


[tau1 ,tau2 ]=solveQuadraticEquation (dd ,2 *zd ,(zz -Delta ^2 )); 








p1 =z +tau1 *d ; 
f1 =g ' *p1 +0.5 *(p1 ' *B *p1 ); 

p2 =z +tau2 *d ; 
f2 =g ' *p2 +0.5 *(p2 ' *B *p2 ); 


if(f1 <=f2 )
p =p1 ; 
else
p =p2 ; 
end

return ; 

end

alpha =(r ' *r )/dBd ; 
znew =z +(alpha *d ); 

if(norm (znew )>=Delta )


reasonCGTerm ='BNDRY' ; 
















zd =z ' *d ; 
dd =d ' *d ; 
zz =z ' *z ; 


[tau1 ,tau2 ]=solveQuadraticEquation (dd ,2 *zd ,(zz -Delta ^2 )); 








if(tau1 >=0 )
p =z +tau1 *d ; 
else
p =z +tau2 *d ; 
end

return ; 

end

rnew =r +alpha *(B *d ); 

if(norm (rnew )<epsk )
p =znew ; 
reasonCGTerm ='CONV' ; 
return ; 
end

ifany (isnan (rnew ))
p =NaN (length (g ),1 ); 
reasonCGTerm ='NaNORInf' ; 
return ; 
end

betanew =(rnew ' *rnew )/(r ' *r ); 
dnew =-rnew +betanew *d ; 


z =znew ; 
r =rnew ; 
d =dnew ; 

end

end


function [tau1 ,tau2 ]=solveQuadraticEquation (a ,b ,c )





















D =(b ^2 -4 *a *c ); 


assert (isreal (D )&&D >=0 ); 


if(b >0 )

b_plus_sqrtD =b +sqrt (D ); 

tau1 =-1 *b_plus_sqrtD /(2 *a ); 

tau2 =(-2 *c )/b_plus_sqrtD ; 

else

minusb_plus_sqrtD =-b +sqrt (D ); 

tau1 =(2 *c )/minusb_plus_sqrtD ; 

tau2 =minusb_plus_sqrtD /(2 *a ); 

end

end


function g =MakeGradient (fun )

g =@(Theta )getGradient (fun ,Theta ); 

end









function g =getGradient (fun ,theta ,step )





if(nargin ==2 )
step =eps ^(1 /3 ); 
end


p =length (theta ); 
g =zeros (p ,1 ); 
fori =1 :p 

theta1 =theta ; 
theta1 (i )=theta1 (i )-step ; 

theta2 =theta ; 
theta2 (i )=theta2 (i )+step ; 

g (i )=(fun (theta2 )-fun (theta1 ))/2 /step ; 
end

g =replaceInf (g ,realmax ); 

end










































function H =getHessian (fun ,theta ,wantRegularized )









step =eps ^(1 /4 ); 


p =length (theta ); 
H =zeros (p ,p ); 
funtheta =fun (theta ); 
denom =4 *(step ^2 ); 


fori =1 :p 
forj =i :p 

if(j ==i )

theta2 =theta ; 
theta2 (i )=theta2 (i )+2 *step ; 

theta1 =theta ; 
theta1 (i )=theta1 (i )-2 *step ; 

H (i ,j )=(fun (theta2 )+fun (theta1 )-2 *funtheta )/denom ; 
else

theta4 =theta ; 
theta4 (i )=theta4 (i )+step ; 
theta4 (j )=theta4 (j )+step ; 

theta3 =theta ; 
theta3 (i )=theta3 (i )-step ; 
theta3 (j )=theta3 (j )+step ; 

theta2 =theta ; 
theta2 (i )=theta2 (i )+step ; 
theta2 (j )=theta2 (j )-step ; 

theta1 =theta ; 
theta1 (i )=theta1 (i )-step ; 
theta1 (j )=theta1 (j )-step ; 

H (i ,j )=(fun (theta4 )+fun (theta1 )-fun (theta3 )-fun (theta2 ))/denom ; 
end
end
end


H =triu (H ,1 )' +H ; 


if(nargin ==3 &&wantRegularized )
lambda =eig (H ); 
if~all (lambda >0 )

delta =abs (min (lambda ))+sqrt (eps ); 

H =H +delta *eye (size (H )); 
end
end

end


function Hdiag =getDiagonalHessian (fun ,theta )









step =eps ^(1 /4 ); 


p =length (theta ); 
Hdiag =zeros (p ,1 ); 


funtheta =fun (theta ); 


fori =1 :p 

theta2 =theta ; 
theta2 (i )=theta2 (i )+2 *step ; 

theta1 =theta ; 
theta1 (i )=theta1 (i )-2 *step ; 

Hdiag (i )=(fun (theta2 )+fun (theta1 )-2 *funtheta )/4 /step /step ; 
end

end


function B =replaceInf (B ,value )







assert (isnumeric (B )&ismatrix (B )); 
assert (isnumeric (value )&isscalar (value )); 


absvalue =abs (value ); 


isinfB =isinf (B ); 


B (isinfB &B >0 )=absvalue ; 


B (isinfB &B <0 )=-absvalue ; 
end


function fun =validateFun (fun )




assertThat (isa (fun ,'function_handle' ),'stats:classreg:regr:lmeutils:fminqn:BadFun' ); 

end


function theta0 =validateTheta0 (theta0 )











assertThat (isnumeric (theta0 )&isreal (theta0 )&isvector (theta0 ),'stats:classreg:regr:lmeutils:fminqn:BadTheta0_NumericRealVector' ); 

assertThat (~any (isnan (theta0 ))&~any (isinf (theta0 )),'stats:classreg:regr:lmeutils:fminqn:BadTheta0_NoNaNInf' ); 

ifsize (theta0 ,1 )==1 
theta0 =theta0 ' ; 
end

end


function options =validateOptions (options )
assertThat (isstruct (options ),'stats:classreg:regr:lmeutils:fminqn:BadOptions' ); 
end


function gamma =validateGamma (gamma )
if(~isempty (gamma ))
isok =isnumeric (gamma )&&isreal (gamma )&&isscalar (gamma )&&(gamma >0 ); 
assertThat (isok ,'stats:classreg:regr:lmeutils:fminqn:BadGamma' ); 
end
end


function initialStepSize =validateInitialStepSize (initialStepSize )
if(~isempty (initialStepSize ))
isok =isnumeric (initialStepSize )&&isreal (initialStepSize )&&isscalar (initialStepSize )&&(initialStepSize >0 ); 
assertThat (isok ,'stats:classreg:regr:lmeutils:fminqn:BadInitialStepSize' ); 
end
end


function errorIfNotScalar (funtheta0 )



assertThat (isscalar (funtheta0 ),'stats:classreg:regr:lmeutils:fminqn:BadFunTheta0' ); 

end


function assertThat (condition ,msgID ,varargin )





if~condition 

try
msg =message (msgID ,varargin {:}); 
catch 
error (message ('stats:LinearMixedModel:BadMsgID' ,msgID )); 
end

ME =MException (msg .Identifier ,getString (msg )); 
throwAsCaller (ME ); 
end

end
