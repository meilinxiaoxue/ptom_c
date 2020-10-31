function [BestTheta ,BestNoise ,CostHistory ]=initialHyperparameters (kernelFunction ,basisFunction ,X ,Y ,Criteria )
















ifnargin <5 
Criteria ='LOO-loss' ; 
end

noise2signal =[0.0001 ,0.001 ,0.01 ,0.05 ,0.1 ,0.2 ,0.5 ]; 

nf =size (X ,2 ); 
ifstrncmpi (kernelFunction ,'ard' ,3 )

kParams =ones (nf +1 ,1 ); 
else

kParams =[1 ,1 ]' ; 
end


isRQ =contains (lower (kernelFunction ),'rationalquadratic' ); 


ifisRQ 

kParams (end+1 )=kParams (end); 



kParams (end-1 )=1 ; 
end

N =length (Y ); 


[Theta0 ,K ]=classreg .learning .gputils .makeKernelObject (kernelFunction ,kParams ); 

kfcn =K .makeKernelAsFunctionOfTheta (X ,X ,true ); 

BestTheta =Theta0 ; 
BestNoise =Inf ; 



NumTrials =64 ; 
ifstrncmpi (kernelFunction ,'ard' ,3 )

TrialLengths =10 .^(net (sobolset (nf ),NumTrials )*5 -3 ); 
else

TrialLengths =logspace (-3 ,2 ,NumTrials )' ; 
end
minCost =Inf ; 

if~strcmp (basisFunction ,'none' )

HFcn =classreg .learning .gputils .makeBasisFunction (basisFunction ); 
H =HFcn (X ); 
Y =Y -H *(H \Y ); 
end

CostHistory =zeros (1 ,length (noise2signal )*NumTrials ); 
fori =1 :length (noise2signal )
forj =1 :NumTrials 



Theta0 =log ([TrialLengths (j ,:),1 ])/2 ; 


ifisRQ 

Theta0 (end+1 )=Theta0 (end); 




Theta0 (end-1 )=0 ; 
end


Ky =kfcn (Theta0 ); 

Ky (1 :N +1 :end)=Ky (1 :N +1 :end)+noise2signal (i ); 




[L ,flag ]=chol (Ky ,'lower' ); 
ifflag 

continue 
end
a =L \Y ; 

alpha =L ' \a ; 

switchlower (Criteria )
case 'loo-loss' 


LInv =L \speye (N ); 




Avec =sum (LInv .*LInv ,1 )' ; 

rp =alpha ./Avec ; 
LOOloss =sum (rp .^2 )/N ; 
cost =LOOloss ; 
case 'logml' 

neglogML =0.5 *(a ' *a )+sum (log (diag (L )))+(N /2 )*log (2 *pi ); 
cost =neglogML ; 
otherwise
assert (false ,'Invalid initial hyperparameters criteria' )
end

sigmaF =a ' *a /N ; 

Theta0 (end)=log (sigmaF )/2 ; 



CostHistory ((i -1 )*NumTrials +j )=cost ; 

ifcost <minCost 

minCost =cost ; 
BestTheta =exp (Theta0 (:)); 
BestNoise =sqrt (noise2signal (i ))*BestTheta (end); 
end
end
end
