classdef FullCovariance <classreg .regr .lmeutils .covmats .CovarianceMatrix 



















































































properties (Access =protected )



DiagonalElements 

end

methods (Access =public )

function this =FullCovariance (dimension ,varargin )











this =this @classreg .regr .lmeutils .covmats .CovarianceMatrix (dimension ,varargin {:}); 

this .DiagonalElements =logical (eye (this .Size )); 

end

function verifyTransformations (this )




theta =generateRandomTheta (this ); 
D =theta2D (this ,theta ); 
theta_recon =D2theta (this ,D ); 
err (1 )=max (abs (theta (:)-theta_recon (:))); 


D =rand (this .Size ); 
D =D ' *D ; 
theta =D2theta (this ,D ); 
D_recon =theta2D (this ,theta ); 
err (2 )=max (abs (D (:)-D_recon (:))); 



theta =generateRandomTheta (this ); 
D =theta2D (this ,theta ); 
L =classreg .regr .lmeutils .covmats .CovarianceMatrix .singularLowerChol (D ); 
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
theta =zeros (q *(q +1 )/2 ,1 ); 

end

function L =theta2L (this ,theta )

L =zeros (this .Size ); 


L (tril (this .CovariancePattern ))=theta ; 

diagelem =this .DiagonalElements ; 
L (diagelem )=exp (L (diagelem )); 

end

function D =theta2D (this ,theta )

L =theta2L (this ,theta ); 
D =L *L ' ; 

end

function theta =D2theta (this ,D )


try

L =chol (D ,'lower' ); 
catch ME %#ok<NASGU> 

L =classreg .regr .lmeutils .covmats .CovarianceMatrix .singularLowerChol (D ); 
end

diagelem =this .DiagonalElements ; 
idx =(L (diagelem )<0 ); 
ifany (idx (:))
L (:,idx )=L (:,idx )*(-1 ); 
end

L (diagelem )=log (L (diagelem )); 

theta =L (tril (this .CovariancePattern )); 

end



function natural =convertUnconstrainedToNatural (this ,unconstrained )


sigma =getSigma (this ); 
D =theta2D (this ,unconstrained ); 
PSI =(sigma ^2 )*D ; 


StdCorr =PSI2StdCorr (this ,PSI ); 
Omega =StdCorr2Omega (this ,StdCorr ); 


natural =Omega (tril (this .CovariancePattern )); 

end

function unconstrained =convertNaturalToUnconstrained (this ,natural )


Omega =zeros (this .Size ); 
Omega (tril (this .CovariancePattern ))=natural ; 

Omega =Omega +tril (Omega ,-1 )' ; 


StdCorr =Omega2StdCorr (this ,Omega ); 

PSI =StdCorr2PSI (this ,StdCorr ); 


sigma =getSigma (this ); 
D =PSI /(sigma ^2 ); 


unconstrained =D2theta (this ,D ); 

end



function canonical =convertNaturalToCanonical (this ,natural )


Omega =zeros (this .Size ); 
Omega (tril (this .CovariancePattern ))=natural ; 

Omega =Omega +tril (Omega ,-1 )' ; 


StdCorr =Omega2StdCorr (this ,Omega ); 


canonical =StdCorr (tril (this .CovariancePattern )); 

end

function natural =convertCanonicalToNatural (this ,canonical )


StdCorr =zeros (this .Size ); 
StdCorr (tril (this .CovariancePattern ))=canonical ; 

StdCorr =StdCorr +tril (StdCorr ,-1 )' ; 


Omega =StdCorr2Omega (this ,StdCorr ); 


natural =Omega (tril (this .CovariancePattern )); 

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

end


function type =defineType (this )%#ok<MANU> 


type ='FullLogCholesky' ; 
end


function covariancepattern =defineCovariancePattern (this )


covariancepattern =true (this .Size ); 
end

end

methods (Access =private )

function theta =generateRandomTheta (this ,condnum )




ifnargin <2 
condnum =1e5 ; 
end

A =randn (this .Size ,this .Size ); 
Q =orth (A ); 
lambda =linspace (1 ,condnum ,this .Size ); 
D =Q *diag (lambda )*Q ' ; 
theta =D2theta (this ,D ); 

end

function StdCorr =PSI2StdCorr (this ,PSI )



[StdCorr ,SIGMA ]=corrcov (PSI ); 
StdCorr (this .DiagonalElements )=SIGMA ; 

end

function Omega =StdCorr2Omega (this ,StdCorr )



Omega =log ((1 +StdCorr )./(1 -StdCorr )); 
diagelem =this .DiagonalElements ; 
Omega (diagelem )=log (StdCorr (diagelem )); 

end

function StdCorr =Omega2StdCorr (this ,Omega )




temp =exp (Omega ); 
StdCorr =(temp -1 )./(temp +1 ); 


diagelem =this .DiagonalElements ; 
StdCorr (diagelem )=exp (Omega (diagelem )); 

end

function PSI =StdCorr2PSI (this ,StdCorr )



SIGMA =diag (StdCorr ); 
StdCorr (this .DiagonalElements )=1 ; 


StdCorr =bsxfun (@times ,StdCorr ,SIGMA ' ); 


PSI =bsxfun (@times ,StdCorr ,SIGMA ); 

end

end

end

