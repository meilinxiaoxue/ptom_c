classdef IsotropicCovariance <classreg .regr .lmeutils .covmats .CovarianceMatrix 









































































properties (Access =protected )


DiagonalElements 

end

methods (Access =public )

function this =IsotropicCovariance (dimension ,varargin )











this =this @classreg .regr .lmeutils .covmats .CovarianceMatrix (dimension ,varargin {:}); 

this .DiagonalElements =logical (eye (this .Size )); 

end

function verifyTransformations (this )




theta =randn (1 ,1 ); 
D =theta2D (this ,theta ); 
theta_recon =D2theta (this ,D ); 
err (1 )=max (abs (theta (:)-theta_recon (:))); 


D =rand (this .Size ); 
D =mean (diag (D ' *D ))*eye (this .Size ); 
theta =D2theta (this ,D ); 
D_recon =theta2D (this ,theta ); 
err (2 )=max (abs (D (:)-D_recon (:))); 



theta =randn (1 ,1 ); 
D =theta2D (this ,theta ); 
L =diag (sqrt (diag (D ))); 
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



function theta =initializeTheta (this )%#ok<MANU> 



q =1 ; 
theta =zeros (q ,1 ); 

end

function L =theta2L (this ,theta )

L =sqrt (exp (theta ))*eye (this .Size ); 

end

function D =theta2D (this ,theta )

D =exp (theta )*eye (this .Size ); 

end

function theta =D2theta (this ,D )%#ok<INUSL> 


theta =log (D (1 ,1 )); 

end



function natural =convertUnconstrainedToNatural (this ,unconstrained )








sigma =getSigma (this ); 

natural =log (sigma )+0.5 *unconstrained ; 

end

function unconstrained =convertNaturalToUnconstrained (this ,natural )











sigma =getSigma (this ); 

unconstrained =2 *(natural -log (sigma )); 

end



function canonical =convertNaturalToCanonical (this ,natural )%#ok<INUSL> 














canonical =exp (natural ); 

end

function natural =convertCanonicalToNatural (this ,canonical )%#ok<INUSL> 














natural =log (canonical ); 

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
if(row ==col )
name1 {count }=vnames {row }; 
name2 {count }=vnames {col }; 
type {count }='std' ; 
count =count +1 ; 
end
end
end

ds =table (group ,name1 ,name2 ,type ,'VariableNames' ,{'Group' ,'Name1' ,'Name2' ,'Type' }); 
ds .Group =char (ds .Group ); 



ifq >=1 
ds =ds (1 ,:); 
end

end


function type =defineType (this )%#ok<MANU> 

type =classreg .regr .lmeutils .covmats .CovarianceMatrix .TYPE_ISOTROPIC ; 
end


function covariancepattern =defineCovariancePattern (this )


covariancepattern =logical (eye (this .Size )); 
end

end

end

