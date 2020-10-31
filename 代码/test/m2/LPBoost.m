classdef LPBoost <classreg .learning .modifier .Modifier 




properties (GetAccess =public ,SetAccess =protected )
WBounds =[]; 
Nu =[]; 
end

properties (Constant =true ,GetAccess =public )
FitInfoDescription =[{getString (message ('stats:classreg:learning:modifier:LPandTotalBoost:FitInfoDescription_Line_1' ))}; 
 {getString (message ('stats:classreg:learning:modifier:LPandTotalBoost:FitInfoDescription_Line_2' ))}; 
 {getString (message ('stats:classreg:learning:modifier:LPandTotalBoost:FitInfoDescription_Line_3' ))}; 
 {getString (message ('stats:classreg:learning:modifier:LPandTotalBoost:FitInfoDescription_Line_4' ))}]; 
end

methods 
function this =LPBoost (nu ,N )
this =this @classreg .learning .modifier .Modifier (N +1 ,1 ); 
...
    ...
    ...
    ...
    ...
    ...
    ...
    this .WBounds =[0 ,100 /N ]; 
this .Nu =nu ; 
ifisempty (ver ('Optim' ))
error (message ('stats:classreg:learning:modifier:LPBoost:LPBoost:NoOptim' )); 
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
warning (message ('stats:classreg:learning:modifier:LPBoost:modify:NaNMargins' )); 
this .ReasonForTermination =...
    getString (message ('stats:classreg:learning:modifier:LPandTotalBoost:NaNMargins' )); 
mustTerminate =true ; 
this .Terminated =mustTerminate ; 
return ; 
end


this .FullFitInfo (this .T +1 ,:)=[mar ' ,edg ]; 


gamma0 =min (this .FullFitInfo (1 :this .T +1 ,end))-this .Nu ; 


[W ,gamma ,exitflag ]=classreg .learning .internal .maxminMargin (...
    -this .FullFitInfo (1 :this .T +1 ,1 :end-1 ),this .WBounds ,W ); 
gamma =-gamma ; 


ifexitflag ~=1 ||gamma >=gamma0 
this .ReasonForTermination =...
    getString (message ('stats:classreg:learning:modifier:LPandTotalBoost:NoImprovement' )); 
mustTerminate =true ; 
this .Terminated =true ; 
return ; 
end


mustTerminate =false ; 
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
