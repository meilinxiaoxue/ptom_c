



classdef DiscriminantImpl <classreg .learning .internal .DisallowVectorOps 

properties (GetAccess =public ,SetAccess =protected )


Type ='' ; 


Mu =[]; 


ClassWeights =[]; 


BetweenMu =[]; 


CenteredMu =[]; 


Gamma =[]; 
Delta =[]; 
end

properties (GetAccess =public ,SetAccess =public ,Abstract =true ,Hidden =true )
SaveMemory ; 
end

properties (GetAccess =public ,SetAccess =protected ,Abstract =true ,Hidden =true )
Sigma ; 
InvSigma ; 
LogDetSigma ; 
MinGamma ; 
end

properties (Abstract ,Constant )



AllowedTypes ; 
end

methods (Abstract )
m =linear (this ,X )
v =quadratic (this ,X1 ,X2 )
m =mahal (this ,K ,X )
v =linearCoeffs (this ,i ,j )
c =constantTerm (this ,i ,j )

delran =deltaRange (this ,gamma )
delpred =deltaPredictor (this ,gamma )

nCoeffs =nLinearCoeffs (this ,delta )

this =setType (this ,type )
this =setGamma (this ,gamma )
this =setDelta (this ,delta )
end

methods 
function this =DiscriminantImpl (gamma ,delta ,mu ,classWeights )
this =this @classreg .learning .internal .DisallowVectorOps (); 
this .Mu =mu ; 
this .Gamma =gamma ; 
this .Delta =delta ; 
[betweenMu ,centeredMu ,classWeights ]=...
    classreg .learning .impl .DiscriminantImpl .centerMu (mu ,classWeights ); 
this .ClassWeights =classWeights ; 
this .BetweenMu =betweenMu ; 
this .CenteredMu =centeredMu ; 
end
end

methods (Static )
function [betweenMu ,centeredMu ,Wj ]=centerMu (mu ,classWeights )







Wj =classWeights ; 
tfnan =isnan (mu ); 
tfall =all (tfnan ,2 ); 
tfany =any (tfnan ,2 ); 
ifany (tfall ~=tfany )
error (message ('stats:classreg:learning:impl:DiscriminantImpl:centerMu:BadMu' )); 
end
Wj (tfall )=NaN ; 
Wj (~tfall )=Wj (~tfall )/sum (Wj (~tfall )); 
betweenMu =sum (bsxfun (@times ,mu (~tfall ,:),Wj (~tfall )),1 ); 
centeredMu =bsxfun (@minus ,mu ,betweenMu ); 
end
end

end
