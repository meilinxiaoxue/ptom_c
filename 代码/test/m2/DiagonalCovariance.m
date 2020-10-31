classdef DiagonalCovariance <classreg .regr .lmeutils .covmats .CovarianceMatrix 








































































properties (Access =protected )


DiagonalElements 

end

methods (Access =public )

function this =DiagonalCovariance (dimension ,varargin )











this =this @classreg .regr .lmeutils .covmats .CovarianceMatrix (dimension ,varargin {:}); 

this .DiagonalElements =logical (eye (this .Size )); 

end

function verifyTransformations (this )




theta =randn (this .Size ,1 ); 
D =theta2D (this ,theta ); 
theta_recon =D2theta (this ,D ); 
err (1 )=max (abs (theta (:)-theta_recon (:))); 


D =rand (this .Size ); 
D =diag (D ' *D ); 
theta =D2theta (this ,D ); 
D_recon =theta2D (this ,theta ); 
err (2 )=max (abs (D (:)-D_recon (:))); 



theta =randn (this .Size ,1 ); 
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



function theta =initializeTheta (this )



q =this .Size ; 
theta =zeros (q ,1 ); 

end

function L =theta2L (this ,theta )%#ok<INUSL> 

L =diag (sqrt (exp (theta ))); 

end

function D =theta2D (this ,theta )%#ok<INUSL> 

D =diag (exp (theta )); 

end

function theta =D2theta (this ,D )%#ok<INUSL> 


theta =log (diag (D )); 

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



















group =cell (this .NumParametersExcludingSigma ,1 ); 
group (:)={this .Name }; 

name1 =cell (this .NumParametersExcludingSigma ,1 ); 
name2 =cell (this .NumParametersExcludingSigma ,1 ); 
type =cell (this .NumParametersExcludingSigma ,1 ); 

q =this .Size ; 
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

end


function type =defineType (this )%#ok<MANU> 

type =classreg .regr .lmeutils .covmats .CovarianceMatrix .TYPE_DIAGONAL ; 
end


function covariancepattern =defineCovariancePattern (this )


covariancepattern =logical (eye (this .Size )); 
end

end


end

