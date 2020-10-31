function [alpha ,g ,f ,selectioncounts ,cause ]=bcdGPR (X ,y ,kfun ,diagkfun ,varargin )


























































































































N =size (X ,1 ); 



dfltSigma =1 ; 
dfltBlockSize =min (1000 ,N ); 
dfltNumGreedy =1 ; 
dfltSquareCacheSize =1000 ; 
dfltAlpha0 =zeros (N ,1 ); 
dfltTolerance =1e-3 ; 
dfltStepTolerance =1e-3 ; 
dfltMaxIter =1000000 ; 
dfltTau =0.1 ; 
dfltVerbose =0 ; 


paramNames ={'Sigma' ,'BlockSize' ,'NumGreedy' ,'SquareCacheSize' ,'Alpha0' ,'Tolerance' ,'StepTolerance' ,'MaxIter' ,'Tau' ,'Verbose' }; 
paramDflts ={dfltSigma ,dfltBlockSize ,dfltNumGreedy ,dfltSquareCacheSize ,dfltAlpha0 ,dfltTolerance ,dfltStepTolerance ,dfltMaxIter ,dfltTau ,dfltVerbose }; 


[sigma ,q ,t ,p ,alpha0 ,eta ,stepTol ,maxIter ,tau ,verbose ]=internal .stats .parseArgs (paramNames ,paramDflts ,varargin {:}); 


[alpha ,g ,f ,selectioncounts ,cause ]=dobcd (X ,y ,kfun ,diagkfun ,sigma ,q ,t ,p ,alpha0 ,eta ,tau ,verbose ,stepTol ,maxIter ); 

end

function [alpha ,g ,f ,selectioncounts ,cause ]=dobcd (X ,y ,kfun ,diagkfun ,sigma ,q ,t ,p ,alpha0 ,eta ,tau ,verbose ,stepTol ,maxIter )































ifall (alpha0 ==0 )

g =-y ; 
else

g =computeKernelMatrixProduct (kfun ,X ,X ,alpha0 ,p ); 


g =g +sigma ^2 *alpha0 -y ; 
end



















N =size (X ,1 ); 
L =(1 :N )' ; 
B0 =false (N ,1 ); 
R0 =true (N ,1 ); 
crit =zeros (N ,2 ); 
crit (:,2 )=L ; 
selectioncounts =zeros (N ,1 ); 
maxabsg0 =max (abs (g )); 
initGradSize =max (1 ,maxabsg0 ); 



diagKPlusSigma2Tau =diagkfun (X )+sigma ^2 +tau ; 


found =false ; 
alpha =alpha0 ; 
iter =0 ; 
while(found ==false )









gbar =g ; 

R =R0 ; 
B =B0 ; 
fori =1 :t 
crit (:,1 )=(gbar .^2 )./diagKPlusSigma2Tau ; 
critR =crit (R ,:); 
[~,idx ]=max (critR (:,1 )); 
bestidx =critR (idx ,2 ); 

B (bestidx )=true ; 
R (bestidx )=false ; 

deltaAlphaBar =-gbar (bestidx )/diagKPlusSigma2Tau (bestidx ); 



gbar =gbar +kfun (X ,X (bestidx ,:))*deltaAlphaBar ; 
gbar (bestidx )=-tau *deltaAlphaBar ; 
end


if(q >t )
Lminust =L (R ); 
randidx =Lminust (randsample (N -t ,q -t )); 
R (randidx )=false ; 
B (randidx )=true ; 
end


selectioncounts (B )=selectioncounts (B )+1 ; 
KBB =kfun (X (B ,:),X (B ,:)); 
KBB (1 :q +1 :q *q )=KBB (1 :q +1 :q *q )+sigma ^2 +tau ; 
[LBB ,status ]=chol (KBB ,'lower' ); 
if(status ==0 )

deltaAlpha =-(LBB ' \(LBB \g (B ))); 
else

deltaAlpha =-(KBB \g (B )); 
end
alpha (B )=alpha (B )+deltaAlpha ; 



g (B )=-tau *deltaAlpha ; 
g (R )=g (R )+computeKernelMatrixProduct (kfun ,X (R ,:),X (B ,:),deltaAlpha ,p ); 


maxabsg =max (abs (g )); 
stepsize =norm (deltaAlpha ); 
if(verbose ==1 )
objfun =0.5 *alpha ' *(g -y ); 
displayConvergenceInfo (iter ,maxabsg ,stepsize ,objfun ); 
end


if(maxabsg <eta *initGradSize )
found =true ; 

cause =0 ; 
elseif(stepsize <stepTol )
found =true ; 

cause =1 ; 
elseif(iter >maxIter )
found =true ; 

cause =2 ; 
end


if(found ==true )
f =0.5 *alpha ' *(g -y ); 
if(verbose ==1 )
displayFinalConvergenceInfo (maxabsg ,initGradSize ,eta ,stepsize ,stepTol ,cause ); 
end
end


iter =iter +1 ; 
end

end

function displayConvergenceInfo (iter ,maxabsg ,stepsize ,objfun )




















if(rem (iter ,20 )==0 )

fprintf ('\n' ); 
fprintf ('|==============================================================|\n' ); 
fprintf ('|  Iteration  |  Max Gradient  |   Step Size   |   Objective   |\n' ); 
fprintf ('|==============================================================|\n' ); 
end


fprintf ('|%12d |%15.6e |%14.6e |%14.6e |\n' ,iter ,maxabsg ,stepsize ,objfun ); 

end

function displayFinalConvergenceInfo (maxabsg ,initGradSize ,eta ,stepsize ,stepTol ,cause )










fprintf ('\n' ); 
relInfNormGradientStr =getString (message ('stats:classreg:learning:gputils:bcdGPR:MessageRelativeInfinityNormFinalGradient' )); 
givenToleranceStr =getString (message ('stats:classreg:learning:gputils:bcdGPR:MessageGivenTolerance' )); 
twoNormStepSizeStr =getString (message ('stats:classreg:learning:gputils:bcdGPR:MessageTwoNormFinalStep' )); 
givenStepToleranceStr =getString (message ('stats:classreg:learning:gputils:bcdGPR:MessageGivenStepTolerance' )); 
fprintf ('%s = %9.3e, %s = %9.3e\n' ,relInfNormGradientStr ,maxabsg /initGradSize ,[givenToleranceStr ,'     ' ],eta ); 
fprintf ('%s = %9.3e, %s = %9.3e\n' ,[twoNormStepSizeStr ,'                  ' ],stepsize ,givenStepToleranceStr ,stepTol ); 


if(cause ==0 )
msg =getString (message ('stats:classreg:learning:gputils:bcdGPR:MessageGradientSatisfiesTolerance' )); 
fprintf ('%s\n' ,msg ); 
elseif(cause ==1 )
msg =getString (message ('stats:classreg:learning:gputils:bcdGPR:MessageStepSizeSatisfiesTolerance' )); 
fprintf ('%s\n' ,msg ); 
elseif(cause ==2 )
msg =getString (message ('stats:classreg:learning:gputils:bcdGPR:MessageIterationLimitReached' )); 
fprintf ('%s\n' ,msg ); 
end

end

function z =computeKernelMatrixProduct (kfun ,XM ,XN ,alpha ,q )

















M =size (XM ,1 ); 
N =size (XN ,1 ); 


z =zeros (M ,1 ); 


s =max (1 ,floor (q *q /N )); 


nchunks =floor (M /s ); 



forr =1 :nchunks 
rowidx =(r -1 )*s +1 :r *s ; 
Kslice =kfun (XM (rowidx ,:),XN ); 
z (rowidx )=Kslice *alpha ; 
end


rowidx =nchunks *s +1 :M ; 
if~isempty (rowidx )
Kslice =kfun (XM (rowidx ,:),XN ); 
z (rowidx )=Kslice *alpha ; 
end

end