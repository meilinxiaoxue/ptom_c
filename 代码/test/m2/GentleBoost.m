classdef GentleBoost <classreg .learning .modifier .Modifier 




properties (Constant =true ,GetAccess =public )
FitInfoDescription =[{getString (message ('stats:classreg:learning:modifier:GentleBoost:FitInfoDescription_Line_1' ))}; 
 {getString (message ('stats:classreg:learning:modifier:GentleBoost:FitInfoDescription_Line_2' ))}]; 

end

methods 
function this =GentleBoost (learnRate )
this =this @classreg .learning .modifier .Modifier (1 ,learnRate ); 
end
end

methods 
function [this ,mustTerminate ,X ,Y ,W ,fitData ]=modify (this ,X ,Y ,W ,H ,fitData )


[~,F ]=predict (H ,X ); 
fitData =fitData +this .LearnRate *F (:,1 ); 


this .FullFitInfo (this .T +1 )=classreg .learning .loss .mse (Y ,F (:,1 ),W ); 


Wtot =sum (W ); 
W =W .*exp (-Y .*F (:,1 )); 
W =W *Wtot /sum (W ); 


mustTerminate =false ; 
end

function c =makeCombiner (this )
c =classreg .learning .combiner .WeightedSum (this .LearnRate *ones (this .T ,1 )); 
end
end

end
