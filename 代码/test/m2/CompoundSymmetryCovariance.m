classdef CompoundSymmetryCovariance <classreg .regr .lmeutils .covmats .CovarianceMatrix 




























































































properties (Access =protected )


DiagonalElements 

end

methods (Access =public )

function this =CompoundSymmetryCovariance (dimension ,varargin )











this =this @classreg .regr .lmeutils .covmats .CovarianceMatrix (dimension ,varargin {:}); 

this .DiagonalElements =logical (eye (this .Size )); 

end

function verifyTransformations (this )




ifthis .Size ==1 
theta =randn (1 ,1 ); 
else
theta =randn (2 ,1 ); 
end
D =theta2D (this ,theta ); 
theta_recon =D2theta (this ,D ); 
err (1 )=max (abs (theta (:)-theta_recon (:))); 


q =this .Size ; 
ifq >1 
rho =-1 /(q -1 )+0.05 ; 
sigma1_sqrd =3 ; 
D =sigma1_sqrd *(rho *ones (q )+(1 -rho )*eye (q )); 
else
D =3 ; 
end
theta =D2theta (this ,D ); 
D_recon =theta2D (this ,theta ); 
err (2 )=max (abs (D (:)-D_recon (:))); 



ifthis .Size ==1 
theta =randn ; 
else
theta =randn (2 ,1 ); 
end
D =theta2D (this ,theta ); 
L =chol (D ,'lower' ); 
this =setUnconstrainedParameters (this ,theta ); 
L1 =getLowerTriangularCholeskyFactor (this ); 
err (3 )=max (abs (L (:)-L1 (:))); 



natural =convertUnconstrainedToNatural (this ,theta ); 
this =setNaturalParameters (this ,natural ); 
L2 =getLowerTriangularCholeskyFactor (this ); 
err (4 )=max (abs (L (:)-L2 (:))); 



this =setUnconstrainedParameters (this ,theta ); 
canonical1 =getCanonicalParameters (this ); 
this =setNaturalParameters (this ,natural ); 
canonical2 =getCanonicalParameters (this ); 
err (5 )=max (abs (canonical1 (:)-canonical2 (:))); 

ifmax (err (:))<=sqrt (eps )
disp (getString (message ('stats:classreg:regr:lmeutils:covmats:CovarianceMatrix:String_TransformsOK' ))); 
else
error (message ('stats:classreg:regr:lmeutils:covmats:CovarianceMatrix:String_TransformsNotOK' )); 
end

end

end

methods (Access =public ,Hidden =true )



function theta =initializeTheta (this )



q =this .Size ; 
ifq ==1 
theta =zeros (1 ,1 ); 
else

theta =zeros (2 ,1 ); 
theta (1 )=0 ; 
theta (2 )=-log (q -1 ); 
end

end

function L =theta2L (this ,theta )

D =theta2D (this ,theta ); 
try
L =chol (D ,'lower' ); 
catch ME %#ok<NASGU> 
L =classreg .regr .lmeutils .covmats .CovarianceMatrix .singularLowerChol (D ); 
end

end

function D =theta2D (this ,theta )



iflength (theta )==1 
sigma1_sqrd =exp (theta (1 )); 
D =sigma1_sqrd ; 
else
sigma1_sqrd =exp (theta (1 )); 
q =this .Size ; 
f =1 /(q -1 ); 
temp =exp (theta (2 )); 
rho =-f +(temp /(1 +temp ))*(1 +f ); 

D =sigma1_sqrd *(rho *ones (q )+(1 -rho )*eye (q )); 
end

end

function theta =D2theta (this ,D )


q =this .Size ; 
ifq ==1 
sigma1_sqrd =D (1 ,1 ); 
theta (1 )=log (sigma1_sqrd ); 
else
sigma1_sqrd =D (1 ,1 ); 
rho =D (1 ,2 )/sigma1_sqrd ; 




f =1 /(q -1 ); 

theta =zeros (2 ,1 ); 
theta (1 )=log (sigma1_sqrd ); 
theta (2 )=log ((rho +f )/(1 -rho )); 
end

end



function natural =convertUnconstrainedToNatural (this ,unconstrained )







sigma =getSigma (this ); 

iflength (unconstrained )==1 
sigma1_sqrd =exp (unconstrained (1 )); 
canonical (1 )=sqrt ((sigma ^2 )*sigma1_sqrd ); 
natural (1 )=log (canonical (1 )); 
else
q =this .Size ; 
f =1 /(q -1 ); 
temp =exp (unconstrained (2 )); 
rho =-f +(temp /(1 +temp ))*(1 +f ); 
natural =zeros (2 ,1 ); 
sigma1_sqrd =exp (unconstrained (1 )); 
canonical (1 )=sqrt ((sigma ^2 )*sigma1_sqrd ); 
natural (1 )=log (canonical (1 )); 
canonical (2 )=rho ; 
natural (2 )=log ((1 +canonical (2 ))/(1 -canonical (2 ))); 
end

end

function unconstrained =convertNaturalToUnconstrained (this ,natural )







sigma =getSigma (this ); 
canonical =convertNaturalToCanonical (this ,natural ); 

iflength (canonical )==1 
sigma1_sqrd =(canonical (1 )^2 )/(sigma ^2 ); 
unconstrained (1 )=log (sigma1_sqrd ); 
else
sigma1_sqrd =(canonical (1 )^2 )/(sigma ^2 ); 
rho =canonical (2 ); 
q =this .Size ; 
unconstrained =zeros (2 ,1 ); 
unconstrained (1 )=log (sigma1_sqrd ); 
unconstrained (2 )=log ((rho +1 /(q -1 ))/(1 -rho )); 
end

end



function canonical =convertNaturalToCanonical (this ,natural )%#ok<INUSL> 



iflength (natural )==1 
canonical (1 )=exp (natural (1 )); 
else
canonical =zeros (2 ,1 ); 
canonical (1 )=exp (natural (1 )); 



ifnatural (2 )<=0 
temp =exp (natural (2 )); 
canonical (2 )=(temp -1 )/(temp +1 ); 
else
temp =exp (-natural (2 )); 
canonical (2 )=(1 -temp )/(1 +temp ); 
end
end

end

function natural =convertCanonicalToNatural (this ,canonical )%#ok<INUSL> 



iflength (canonical )==1 
natural (1 )=log (canonical (1 )); 
else
natural =zeros (2 ,1 ); 
natural (1 )=log (canonical (1 )); 
natural (2 )=log ((1 +canonical (2 ))/(1 -canonical (2 ))); 
end

end


function ds =defineCanonicalParameterNames (this )






















q =this .Size ; 
nrows =q *(q +1 )/2 ; 
group =cell (nrows ,1 ); 
group (:)={this .Name }; 

name1 =cell (nrows ,1 ); 
name2 =cell (nrows ,1 ); 
type =cell (nrows ,1 ); 

vnames =this .VariableNames ; 
count =1 ; 
forcol =1 :q 
forrow =col :q 
name1 {count }=vnames {row }; 
name2 {count }=vnames {col }; 
if(row ==col )
type {count }='std' ; 
else
type {count }='corr' ; 
end
count =count +1 ; 
end
end

ds =table (group ,name1 ,name2 ,type ,'VariableNames' ,{'Group' ,'Name1' ,'Name2' ,'Type' }); 
ds .Group =char (ds .Group ); 



ifq ==1 
ds =ds (1 ,:); 
elseifq >=2 
ds =ds (1 :2 ,:); 
end

end


function type =defineType (this )%#ok<MANU> 

type =classreg .regr .lmeutils .covmats .CovarianceMatrix .TYPE_COMPSYMM ; 
end


function covariancepattern =defineCovariancePattern (this )


covariancepattern =true (this .Size ); 
end

end

end

