function [cs ,W ]=adjustPrior (cs ,Y ,W )





ifisempty (cs .Cost )
return ; 
end


C =classreg .learning .internal .classCount (cs .NonzeroProbClasses ,Y ); 
K =size (C ,2 ); 
WC =bsxfun (@times ,C ,W ); 
Wj =sum (WC ,1 ); 


Pcost =classreg .learning .classProbFromCost (cs .Cost ); 
prior =cs .Prior .*Pcost ' ; 




prior =prior /sum (prior ); 
W =sum (bsxfun (@times ,WC ,prior ./Wj ),2 ); 


cs .Prior =prior ; 
cs .Cost =ones (K )-eye (K ); 
end
