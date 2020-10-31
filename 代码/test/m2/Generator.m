classdef Generator <classreg .learning .internal .DisallowVectorOps 




properties (GetAccess =public ,SetAccess =protected )
X =[]; 
Y =[]; 
W =[]; 
FitData =[]; 


T =0 ; 
end

properties (GetAccess =public ,SetAccess =protected ,Dependent =true )


UseObsForIter ; 



UsePredForIter ; 
end

properties (GetAccess =protected ,SetAccess =protected )

MaxT =0 ; 


PrivUseObsForIter =false (0 ); 


LastUseObsForIter =[]; 


PrivUsePredForIter =false (0 ); 


LastUsePredForIter =[]; 



ObservationsInRows =true ; 
end

methods (Access =protected )
function this =Generator (X ,Y ,W ,fitData ,obsInRows )
this =this @classreg .learning .internal .DisallowVectorOps (); 

ifnargin <5 
obsInRows =true ; 
end

if~isnumeric (X )||~ismatrix (X )
error (message ('stats:classreg:learning:generator:Generator:Generator:BadX' )); 
end
ifobsInRows 
[N ,D ]=size (X ); 
else
[D ,N ]=size (X ); 
end

if(~isnumeric (Y )&&~isa (Y ,'classreg.learning.internal.ClassLabel' ))...
    ||~isvector (Y )||numel (Y )~=N 
error (message ('stats:classreg:learning:generator:Generator:Generator:BadY' ,N )); 
end

if~isvector (W )||numel (W )~=N 
error (message ('stats:classreg:learning:generator:Generator:Generator:BadW' ,N )); 
end

if~isempty (fitData )&&(~isnumeric (fitData )||size (fitData ,1 )~=N )
error (message ('stats:classreg:learning:generator:Generator:Generator:BadFitData' ,N )); 
end

this .X =X ; 
this .Y =Y ; 
this .W =W ; 
this .FitData =fitData ; 
this .LastUseObsForIter =1 :N ; 
this .LastUsePredForIter =1 :D ; 
this .ObservationsInRows =obsInRows ; 
end

function this =updateT (this )
this .T =this .T +1 ; 
ifthis .T >this .MaxT 
error (message ('stats:classreg:learning:generator:Generator:updateT:MaxTExceeded' )); 
end
this .PrivUseObsForIter (this .LastUseObsForIter ,this .T )=true ; 
this .PrivUsePredForIter (this .LastUsePredForIter ,this .T )=true ; 
end

function this =reservePredForIter (this )
ifthis .ObservationsInRows 
D =size (this .X ,2 ); 
else
D =size (this .X ,1 ); 
end
this .PrivUsePredForIter (1 :D ,this .T +1 :this .MaxT )=false ; 
this .PrivUsePredForIter (:,this .MaxT +1 :end)=[]; 
end
end

methods (Abstract )





[this ,X ,Y ,W ,fitData ,optArgs ]=generate (this )


this =update (this ,X ,Y ,W ,fitData )
end

methods 
function usenfort =get .UseObsForIter (this )
usenfort =this .PrivUseObsForIter (:,1 :this .T ); 
end

function usenfort =get .UsePredForIter (this )
ifisempty (this .PrivUsePredForIter )


ifthis .ObservationsInRows 
D =size (this .X ,2 ); 
else
D =size (this .X ,1 ); 
end
usenfort =true (D ,this .T ); 
else
usenfort =this .PrivUsePredForIter (:,1 :this .T ); 
end
end
end

methods (Hidden )
function this =updateWithT (this ,X ,Y ,W ,fitData )
this =update (this ,X ,Y ,W ,fitData ); 
this =updateT (this ); 
end

function this =reserveFitInfo (this ,T )
ifthis .ObservationsInRows 
N =size (this .X ,1 ); 
else
N =size (this .X ,2 ); 
end
T =ceil (T ); 
ifT <=0 
error (message ('stats:classreg:learning:generator:Generator:reserveFitInfo:BadT' )); 
end
this .MaxT =this .T +T ; 
this .PrivUseObsForIter (1 :N ,this .T +1 :this .MaxT )=false ; 
this .PrivUseObsForIter (:,this .MaxT +1 :end)=[]; 
this =reservePredForIter (this ); 
end
end

end

