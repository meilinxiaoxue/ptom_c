classdef RUSBoost <classreg .learning .modifier .Modifier 




properties (Constant =true ,GetAccess =public )
FitInfoDescription =[{'Vector of length NTrained, where NTrained is the number of learned weak hypotheses.' }; 
 {'Element t of this vector is the weighted loss from hypothesis t.' }]; 
end

properties (GetAccess =public ,SetAccess =protected )
X =[]; 
Y =[]; 
W =[]; 
FitData =[]; 
Booster =[]; 
end

methods (Hidden )
function this =reserveFitInfo (this ,T )
this =reserveFitInfo @classreg .learning .modifier .Modifier (this ,T ); 
this .Booster =reserveFitInfo (this .Booster ,T ); 
end
end

methods 
function this =RUSBoost (X ,Y ,W ,learnRate )
this =this @classreg .learning .modifier .Modifier (1 ,learnRate ); 






this .X =X ; 
this .Y =Y ; 
this .W =W ; 


C =membership (Y ); 
K =size (C ,2 ); 
fitData =repmat (W (:),1 ,K ); 
fitData =fitData .*(~C ); 
ifany (fitData (:))
fitData =fitData /sum (fitData (:)); 
else
fitData (:)=0 ; 
end
this .FitData =fitData ; 


classnames =levels (Y ); 
this .Booster =classreg .learning .modifier .AdaBoostM2 (classnames ,learnRate ); 
end

function [this ,mustTerminate ,X ,Y ,W ,fitData ]=modify (this ,X ,Y ,W ,H ,fitData )

[this .Booster ,mustTerminate ,X ,Y ,W ,fitData ]=...
    modifyWithT (this .Booster ,this .X ,this .Y ,this .W ,H ,this .FitData ); 


ifmustTerminate 
this .ReasonForTermination =this .Booster .ReasonForTermination ; 
return ; 
end



this .W =W ; 
this .FitData =fitData ; 





this .FullFitInfo (this .T +1 )=this .Booster .FitInfo (this .T +1 ); 
end

function combiner =makeCombiner (this )
combiner =makeCombiner (this .Booster ); 
end
end

end
