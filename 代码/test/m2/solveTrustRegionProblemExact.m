function [p ,mp ,isposdef ,iter ,lambda ]=solveTrustRegionProblemExact (g ,B ,Delta )


























































































































































































































































































































































[Q ,Lambda ]=eig (B ); 
Lambda =diag (Lambda ); 


if~issorted (Lambda )
[Lambda ,sidx ]=sort (Lambda ,'ascend' ); 
Q =Q (:,sidx ); 
end




absLambda =abs (Lambda ); 


maxabsLambda =max (absLambda ); 


Qtg =Q ' *g ; 





relTol =eps (class (B ))^(3 /4 ); 



absTol =eps (class (B ))^(3 /4 ); 





trustTol =eps (class (B ))^(1 /2 ); 



if((Lambda (1 )>0 &&abs (Lambda (1 ))<=relTol *maxabsLambda )||Lambda (1 )==0 )



isposdef =false ; 




offset =0 ; 
LambdaFun =makeLambdaFun (offset ); 


theta0 =chooseInitialTheta (g ,B ,Delta ,Lambda (1 ),absTol ); 



[theta ,p ,iter ,cause ]=solveStepLengthEquation (Qtg ,Q ,Lambda ,Delta ,LambdaFun ,theta0 ,trustTol ); 


lambda =LambdaFun (theta ); 












if(cause ~=0 )



islambdaSmall =abs (lambda )<=sqrt (absTol ); 


recomputep =islambdaSmall ||isinf (Delta )||(norm (p )==0 ); 
if(recomputep )

p =bestBetForStep (g ,B ,Qtg ,Q ,Lambda ,0 ,Delta ); 
lambda =0 ; 
else

warning (message ('stats:classreg:regr:lmeutils:fminqn:Message_UnableToSolveTrustRegionProblem' )); 

p =NaN (length (g ),1 ); 
end
end


mp =trustRegionObjective (g ,B ,p ); 

elseif(Lambda (1 )>0 &&abs (Lambda (1 ))>relTol *maxabsLambda )



isposdef =true ; 


[phat ,kbst ]=bestBetForStep (g ,B ,Qtg ,Q ,Lambda ,0 ,Delta ); 
if(kbst ==0 )


p =phat ; 
mp =trustRegionObjective (g ,B ,p ); 
iter =0 ; 
lambda =0 ; 
return ; 
end





offset =0 ; 
LambdaFun =makeLambdaFun (offset ); 


theta0 =chooseInitialTheta (g ,B ,Delta ,Lambda (1 ),absTol ); 



[theta ,p ,iter ,cause ]=solveStepLengthEquation (Qtg ,Q ,Lambda ,Delta ,LambdaFun ,theta0 ,trustTol ); 


lambda =LambdaFun (theta ); 












if(cause ~=0 )



islambdaSmall =abs (lambda )<=sqrt (absTol ); 


recomputep =islambdaSmall ||isinf (Delta )||(norm (p )==0 ); 
if(recomputep )


p =phat ; 
lambda =0 ; 
else

warning (message ('stats:classreg:regr:lmeutils:fminqn:Message_UnableToSolveTrustRegionProblem' )); 

p =NaN (length (g ),1 ); 
end
end


mp =trustRegionObjective (g ,B ,p ); 

elseif(Lambda (1 )<0 )



isposdef =false ; 






offset =-Lambda (1 ); 
LambdaFun =makeLambdaFun (offset ); 


theta0 =chooseInitialTheta (g ,B ,Delta ,Lambda (1 ),absTol ); 



[theta ,p ,iter ,cause ]=solveStepLengthEquation (Qtg ,Q ,Lambda ,Delta ,LambdaFun ,theta0 ,trustTol ); 


lambda =LambdaFun (theta ); 










if(cause ~=0 )



islambdaPlusLambda1Small =abs (lambda +Lambda (1 ))<=sqrt (absTol )*max (1 ,abs (Lambda (1 ))); 


recomputep =islambdaPlusLambda1Small ||(norm (p )==0 ); 
if(recomputep )

p =bestBetForStep (g ,B ,Qtg ,Q ,Lambda ,-Lambda (1 ),Delta ); 
lambda =-Lambda (1 ); 
else

warning (message ('stats:classreg:regr:lmeutils:fminqn:Message_UnableToSolveTrustRegionProblem' )); 

p =NaN (length (g ),1 ); 
end
end


mp =trustRegionObjective (g ,B ,p ); 

end


ifmp >0 ||isnan (mp )
p =zeros (length (g ),1 ); 
mp =0 ; 
end

end



function [p ,kbst ,mbest ]=bestBetForStep (g ,B ,Qtg ,Q ,Lambda ,lambda ,Delta )



























n =length (Qtg ); 

x =(Qtg ./(Lambda +lambda )).^2 ; 
fork =0 :n 
kbst =k ; 
tau2 =Delta ^2 -sum (x (k +1 :end)); 
if(tau2 >=0 )

break; 
end
end






idx =(kbst +1 ):n ; 
if~isempty (idx )
c2 =-1 *Q (:,idx )*(Qtg (idx )./(Lambda (idx )+lambda )); 
else
c2 =zeros (n ,1 ); 
end


if(kbst ==0 )
p =c2 ; 
mbest =trustRegionObjective (g ,B ,p ); 
return ; 
end













if(lambda ==0 &&~isinf (Delta )&&~isinf (tau2 ))


pbest =c2 ; 
mbest =trustRegionObjective (g ,B ,pbest ); 
else
pbest =NaN (n ,1 ); 
mbest =Inf ; 
end


form =1 :kbst 



c1pos =sqrt (tau2 )*Q (:,m ); 
c1neg =-sqrt (tau2 )*Q (:,m ); 


ppos =c1pos +c2 ; 
pneg =c1neg +c2 ; 


mpos =trustRegionObjective (g ,B ,ppos ); 
mneg =trustRegionObjective (g ,B ,pneg ); 


if(mpos <=mneg )
pcurr =ppos ; 
mcurr =mpos ; 
else
pcurr =pneg ; 
mcurr =mneg ; 
end


if(mcurr <=mbest )
mbest =mcurr ; 
pbest =pcurr ; 
end
end


p =pbest ; 

end



function [theta ,p ,iter ,cause ]=solveStepLengthEquation (Qtg ,Q ,Lambda ,Delta ,LambdaFun ,theta0 ,trustTol )



























found =false ; 





theta =theta0 ; 


lambda =LambdaFun (theta ); 



ptp =sum ((Qtg ./(Lambda +lambda )).^2 ); 



zeroViolation =abs (1 /sqrt (ptp )-1 /Delta ); 


iter =0 ; 
maxit =100 ; 


if(Delta ==0 )
p =zeros (length (Qtg ),1 ); 
cause =0 ; 
return ; 
end


while(found ==false )



qtq =sum ((Qtg ./(Lambda +lambda )).^2 ./(Lambda +lambda )); 


NewtonStep =((sqrt (ptp )-Delta )/Delta )*(exp (-theta )*ptp )/qtq ; 

if(isnan (NewtonStep )||isinf (NewtonStep ))

found =true ; 
cause =3 ; 
else





stepLength =1.0 ; 
acceptStep =false ; 
while(acceptStep ==false )



thetaNew =theta +stepLength *NewtonStep ; 
lambdaNew =LambdaFun (thetaNew ); 

ptpNew =sum ((Qtg ./(Lambda +lambdaNew )).^2 ); 
zeroViolationNew =abs (1 /sqrt (ptpNew )-1 /Delta ); 


if(zeroViolationNew <=zeroViolation &&~isinf (ptpNew ))


acceptStep =true ; 
theta =thetaNew ; 
lambda =lambdaNew ; 
ptp =ptpNew ; 
zeroViolation =zeroViolationNew ; 
else

stepLength =stepLength /2 ; 


if(abs (lambdaNew -lambda )<=trustTol )
acceptStep =true ; 
found =true ; 
cause =1 ; 
end
end

end

end



if(iter >maxit )
found =true ; 
cause =2 ; 
end

if(abs (sqrt (ptp )/Delta -1 )<=trustTol )
found =true ; 
cause =0 ; 
end


iter =iter +1 ; 

end


p =-1 *Q *(Qtg ./(Lambda +lambda )); 

end



function theta0 =chooseInitialTheta (g ,B ,Delta ,Lambda1 ,absTol )














n =length (g ); 
delta =trace (B )/n ; 




lambda0 =-delta +(norm (g )/Delta ); 


gamma =1 +0.2 ; 
tol =sqrt (absTol )*100 ; 
lambda0 =max ([lambda0 ,gamma *tol ,-gamma *Lambda1 ]); 


theta0 =log (lambda0 +Lambda1 ); 

end



function LambdaFun =makeLambdaFun (offset )



LambdaFun =@f ; 

function val =f (theta )

val =offset +exp (theta ); 

end

end



function mp =trustRegionObjective (g ,B ,p )


mp =g ' *p +0.5 *(p ' *B *p ); 

end
