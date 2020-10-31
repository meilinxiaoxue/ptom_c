classdef TotalBoost <classreg .learning .modifier .Modifier 




properties (GetAccess =public ,SetAccess =protected )
Nu =[]; 
end

properties (Constant =true ,GetAccess =public )
FitInfoDescription =[{getString (message ('stats:classreg:learning:modifier:LPandTotalBoost:FitInfoDescription_Line_1' ))}; 
 {getString (message ('stats:classreg:learning:modifier:LPandTotalBoost:FitInfoDescription_Line_2' ))}; 
 {getString (message ('stats:classreg:learning:modifier:LPandTotalBoost:FitInfoDescription_Line_3' ))}; 
 {getString (message ('stats:classreg:learning:modifier:LPandTotalBoost:FitInfoDescription_Line_4' ))}]; 
end

methods 
function this =TotalBoost (nu ,N )
this =this @classreg .learning .modifier .Modifier (N +1 ,1 ); 
this .Nu =nu ; 
ifisempty (ver ('Optim' ))
error (message ('stats:classreg:learning:modifier:TotalBoost:TotalBoost:NoOptim' )); 
end
end
end

methods 
function [this ,mustTerminate ,X ,Y ,W ,fitData ]=modify (this ,X ,Y ,W ,H ,fitData )

ifwasTerminated (this )
mustTerminate =true ; 
return ; 
end


mar =margin (H ,X ,Y )/2 ; 
W =W /sum (W ); 
edg =sum (mar .*W ); 


ifany (isnan (mar ))||isnan (edg )
warning (message ('stats:classreg:learning:modifier:TotalBoost:modify:NaNMargins' )); 
this .ReasonForTermination =...
    getString (message ('stats:classreg:learning:modifier:LPandTotalBoost:NaNMargins' )); 
mustTerminate =true ; 
this .Terminated =mustTerminate ; 
return ; 
end


this .FullFitInfo (this .T +1 ,:)=[mar ' ,edg ]; 


gamma0 =min (this .FullFitInfo (1 :this .T +1 ,end))-this .Nu ; 


[W ,exitflag ]=classreg .learning .internal .erweight (...
    this .FullFitInfo (1 :this .T +1 ,1 :end-1 ),gamma0 ,W ,fitData ); 


mustTerminate =false ; 
ifexitflag ~=1 
this .ReasonForTermination =...
    getString (message ('stats:classreg:learning:modifier:LPandTotalBoost:NoImprovement' )); 
mustTerminate =true ; 
end


this .Terminated =mustTerminate ; 
end

function c =makeCombiner (this )
ifthis .T ==0 
c =classreg .learning .combiner .WeightedSum ([]); 
else
M =this .FitInfo (:,1 :end-1 )' ; 
beta =classreg .learning .internal .maxminMargin (M ); 
c =classreg .learning .combiner .WeightedSum (beta ); 
end
end
end

end
