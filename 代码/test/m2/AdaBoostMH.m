classdef AdaBoostMH <classreg .learning .modifier .Modifier 




properties (Constant =true ,GetAccess =public )
FitInfoDescription =[{getString (message ('stats:classreg:learning:modifier:AdaBoostM2:FitInfoDescription_Line_1' ))}; 
 {getString (message ('stats:classreg:learning:modifier:AdaBoostM2:FitInfoDescription_Line_2' ))}]; 
end

properties (GetAccess =public ,SetAccess =protected )

ClassNames =[]; 
end

methods 
function this =AdaBoostMH (classNames ,learnRate )
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
s =-ones (N ,K ); 
s (:,pos )=score ; 


c =classreg .learning .internal .classCount (this .ClassNames ,Y ); 
cs =(2 *c -1 ).*s ; 




Wtot =sum (fitData (:)); 
edge =sum (sum (fitData .*cs ))/Wtot ; 


loss =(1 -edge )/2 ; 
this .FullFitInfo (this .T +1 )=loss ; 



fitData (cs >0 )=0.5 *fitData (cs >0 )/(1 -loss )^this .LearnRate ; 
fitData (cs <0 )=0.5 *fitData (cs <0 )/loss ^this .LearnRate ; 
fitData =fitData *Wtot /sum (fitData (:)); 


W =sum (fitData ,2 ); 


mustTerminate =false ; 
ifloss <=0 ||loss >=0.5 
warning (message ('stats:classreg:learning:modifier:AdaBoostMH:modify:Terminate' ,...
    sprintf ('%g' ,loss ))); 
mustTerminate =true ; 
this .ReasonForTermination =...
    getString (message ('stats:classreg:learning:modifier:AdaBoostM2:ReasonForTermination_2' )); 
end
this .Terminated =mustTerminate ; 
end

function c =makeCombiner (this )
loss =this .FitInfo ; 
beta =0.5 *this .LearnRate *log ((1 -loss )./loss ); 
c =classreg .learning .combiner .WeightedSum (beta ); 
end
end

end
