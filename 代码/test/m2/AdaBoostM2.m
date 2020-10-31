classdef AdaBoostM2 <classreg .learning .modifier .Modifier 




properties (Constant =true ,GetAccess =public )
FitInfoDescription =[{getString (message ('stats:classreg:learning:modifier:AdaBoostM2:FitInfoDescription_Line_1' ))}; 
 {getString (message ('stats:classreg:learning:modifier:AdaBoostM2:FitInfoDescription_Line_2' ))}]; 
end

properties (GetAccess =public ,SetAccess =protected )

ClassNames =[]; 
end

methods 
function this =AdaBoostM2 (classNames ,learnRate )
this =this @classreg .learning .modifier .Modifier (1 ,learnRate ); 
this .ClassNames =classNames ; 
end
end

methods 
function [this ,mustTerminate ,X ,Y ,W ,fitData ]=modify (this ,X ,Y ,W ,H ,fitData )

ifwasTerminated (this )
mustTerminate =true ; 
return ; 
end



[~,score ]=predict (H ,X ); 
[~,pos ]=ismember (H .ClassSummary .ClassNames ,this .ClassNames ); 
N =size (X ,1 ); 
K =length (this .ClassNames ); 
s =zeros (N ,K ); 
s (:,pos )=score ; 




c =classreg .learning .internal .classCount (this .ClassNames ,Y ); 
mar =bsxfun (@minus ,sum (c .*s ,2 ),(~c ).*s ); 




falseWperObs =sum (fitData ,2 ); 
useObs =W >0 &falseWperObs >0 ; 
if~any (useObs )
warning (message ('stats:classreg:learning:modifier:AdaBoostM2:modify:AllFalseWeightsZero' )); 
mustTerminate =true ; 
this .ReasonForTermination =...
    getString (message ('stats:classreg:learning:modifier:AdaBoostM2:ReasonForTermination_1' )); 
this .Terminated =mustTerminate ; 
return ; 
end
fitData (useObs ,:)=bsxfun (@times ,fitData (useObs ,:),...
    W (useObs )/sum (W (useObs ))./falseWperObs (useObs )); 
Wtot =sum (W ); 
fitData (~useObs ,:)=0 ; 


loss =0.5 *sum (sum (fitData .*(1 -mar ))); 
this .FullFitInfo (this .T +1 )=loss ; 


beta =(loss /(1 -loss ))^this .LearnRate ; 
fitData =fitData .*beta .^((1 +mar )/2 ); 



Wnew =sum (fitData ,2 ); 
W =Wnew *Wtot /sum (Wnew ); 


mustTerminate =false ; 
ifloss <=0 
warning (message ('stats:classreg:learning:modifier:AdaBoostM2:modify:NonPositiveLoss' )); 
mustTerminate =true ; 
this .ReasonForTermination =...
    getString (message ('stats:classreg:learning:modifier:AdaBoostM2:ReasonForTermination_2' )); 
end
this .Terminated =mustTerminate ; 
end

function c =makeCombiner (this )
loss =this .FitInfo ; 
loss (loss >0.5 )=0.5 ; 
beta =0.5 *this .LearnRate *log ((1 -loss )./loss ); 
c =classreg .learning .combiner .WeightedSum (beta ); 
end
end

end
