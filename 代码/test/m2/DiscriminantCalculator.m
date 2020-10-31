



classdef DiscriminantCalculator <classreg .learning .internal .DisallowVectorOps 

properties (GetAccess =public ,SetAccess =public )

Mu =[]; 


InvD =[]; 
end

methods (Access =protected )
function this =DiscriminantCalculator (mu ,invD )
this =this @classreg .learning .internal .DisallowVectorOps (); 
this .Mu =mu ; 
this .InvD =invD (:)' ; 
end
end

methods (Abstract )



m =linear (this ,X )


v =quadratic (this ,X1 ,X2 )



m =mahal (this ,K ,X )


v =linearCoeffs (this ,i ,j )


sig =sigma (this ,d ,s ,v )


invsig =invSigma (this )


logsig =logDetSigma (this ,d ,s ,v )
end

methods 

function c =constantTerm (this ,i ,j )
mah =mahal (this ,[i ,j ],zeros (1 ,size (this .Mu ,2 ))); 
c =0.5 *(mah (1 )-mah (2 )); 
end
end
end
