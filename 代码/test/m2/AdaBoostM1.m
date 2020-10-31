classdef AdaBoostM1 <classreg .learning .modifier .Modifier 




properties (Constant =true ,GetAccess =public )
FitInfoDescription =[{getString (message ('stats:classreg:learning:modifier:AdaBoostM1:FitInfoDescription_Line_1' ))}; 
 {getString (message ('stats:classreg:learning:modifier:AdaBoostM1:FitInfoDescription_Line_2' ))}]; 
end

methods 
function this =AdaBoostM1 (learnRate )
this =this @classreg .learning .modifier .Modifier (1 ,learnRate ); 
end
end

methods 
function [this ,mustTerminate ,X ,Y ,W ,fitData ]=modify (this ,X ,Y ,W ,H ,fitData )

ifwasTerminated (this )
mustTerminate =true ; 
return ; 
end


Wtot =sum (W ); 


mar =margin (H ,X ,Y ); 



right =mar >0 ; 
wrong =mar <0 ; 
halfway =~(right |wrong ); 
err =(sum (W (wrong ))+0.5 *sum (W (halfway )))/sum (W ); 
this .FullFitInfo (this .T +1 )=err ; 


W (right )=0.5 *W (right )/(1 -err )^this .LearnRate ; 
W (wrong )=0.5 *W (wrong )/err ^this .LearnRate ; 


W =W *Wtot /sum (W ); 


mustTerminate =false ; 
iferr ==0 ||err >0.5 
warning (message ('stats:classreg:learning:modifier:AdaBoostM1:modify:Terminate' ,sprintf ('%g' ,err ))); 
mustTerminate =true ; 
this .ReasonForTermination =...
    getString (message ('stats:classreg:learning:modifier:AdaBoostM1:ReasonForTermination_1' ,sprintf ('%g' ,err ))); 
end
this .Terminated =mustTerminate ; 
end

function c =makeCombiner (this )
err =this .FitInfo ; 
beta =0.5 *this .LearnRate *log ((1 -err )./err ); 
c =classreg .learning .combiner .WeightedSum (beta ); 
end
end

end
