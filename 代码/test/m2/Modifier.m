classdef Modifier <classreg .learning .internal .DisallowVectorOps 




properties (Constant =true ,GetAccess =public ,Abstract =true )
FitInfoDescription ; 
end

properties (GetAccess =public ,SetAccess =protected )

ReasonForTermination =...
    getString (message ('stats:classreg:learning:modifier:Modifier:ReasonForTermination' )); 


T =0 ; 


LearnRate =1 ; 
end

properties (GetAccess =public ,SetAccess =protected ,Dependent =true )

FitInfo ; 
end

properties (GetAccess =protected ,SetAccess =protected )

FitInfoSize =[]; 


MaxT =0 ; 




FullFitInfo =[]; 


Terminated =false ; 
end

methods 
function fi =get .FitInfo (this )
ifany (this .FitInfoSize (:))
fi =reshape (this .FullFitInfo (1 :this .T ,:),this .T ,this .FitInfoSize ); 
else
fi =[]; 
end
end
end

methods (Abstract )


[this ,mustTerminate ,X ,Y ,W ,fitData ]=modify (this ,X ,Y ,W ,H ,fitData )



combiner =makeCombiner (this )
end

methods (Hidden )
function [this ,mustTerminate ,X ,Y ,W ,fitData ]=modifyWithT (this ,X ,Y ,W ,H ,fitData )
[this ,mustTerminate ,X ,Y ,W ,fitData ]=modify (this ,X ,Y ,W ,H ,fitData ); 
if~mustTerminate 
this =updateT (this ); 
end
end

function this =reserveFitInfo (this ,T )
T =ceil (T ); 
ifT <=0 
error (message ('stats:classreg:learning:modifier:Modifier:reserveFitInfo:BadT' )); 
end
this .MaxT =this .T +T ; 
ifany (this .FitInfoSize (:))
this .FullFitInfo (this .T +1 :this .MaxT ,:)=zeros (T ,this .FitInfoSize ); 
this .FullFitInfo (this .MaxT +1 :end,:)=[]; 
end
end
end

methods (Access =protected )
function this =Modifier (fitInfoSize ,learnRate )
this =this @classreg .learning .internal .DisallowVectorOps (); 
ifisempty (fitInfoSize )||~isnumeric (fitInfoSize )...
    ||~isvector (fitInfoSize )||any (fitInfoSize <0 )
error (message ('stats:classreg:learning:modifier:Modifier:Modifier:BadFitInfoSize' )); 
end
fitInfoSize =ceil (fitInfoSize ); 

ifisempty (learnRate )||~isnumeric (learnRate )||~isscalar (learnRate )...
    ||learnRate <=0 ||learnRate >1 
error (message ('stats:classreg:learning:modifier:Modifier:Modifier:BadLearnRate' )); 
end

this .FitInfoSize =fitInfoSize ; 
this .LearnRate =learnRate ; 
end

function this =updateT (this )
this .T =this .T +1 ; 
ifthis .T >this .MaxT 
error (message ('stats:classreg:learning:modifier:Modifier:updateT:MaxTExceeded' )); 
end
end

function tf =wasTerminated (this )

tf =this .Terminated ; 
iftf 
warning (message ('stats:classreg:learning:modifier:Modifier:modify:StoppedEarly' ,class (this ),this .T )); 
end
end
end

end
