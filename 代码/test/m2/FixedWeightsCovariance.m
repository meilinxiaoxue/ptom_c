classdef FixedWeightsCovariance <classreg .regr .lmeutils .covmats .CovarianceMatrix 







































































properties (Access =protected )


DiagonalElements 


Weights 
end

methods (Access =public )
function this =FixedWeightsCovariance (dimension ,varargin )















this =this @classreg .regr .lmeutils .covmats .CovarianceMatrix (dimension ,varargin {:}); 
this .DiagonalElements =logical (eye (this .Size )); 


dfltWeights =[]; 
parnames ={'Weights' }; 
dflts ={dfltWeights }; 
[w ,~,~]=internal .stats .parseArgs (parnames ,dflts ,varargin {:}); 

ifisempty (w )
w =ones (dimension ,1 ); 
else

if~isvector (w )||~isnumeric (w )||~isreal (w )||~all (w >=0 )||any (isinf (w ))

error (message ('stats:classreg:regr:lmeutils:covmats:CovarianceMatrix:BadWeights' )); 
end


ifsize (w ,1 )==1 
w =w ' ; 
end

iflength (w )~=dimension 

error (message ('stats:classreg:regr:lmeutils:covmats:CovarianceMatrix:BadWeightsLength' ,num2str (dimension ))); 
end
end


this .Weights =w ; 

end

function this =setWeights (this ,w )






if~isvector (w )||~isnumeric (w )||~isreal (w )||~all (w >=0 )||any (isinf (w ))

error (message ('stats:classreg:regr:lmeutils:covmats:CovarianceMatrix:BadWeights' )); 
end


ifsize (w ,1 )==1 
w =w ' ; 
end

iflength (w )~=this .Size 

error (message ('stats:classreg:regr:lmeutils:covmats:CovarianceMatrix:BadWeightsLength' ,num2str (this .Size ))); 
end


this .Weights =w ; 

end

function w =getWeights (this )




w =this .Weights ; 

end

function verifyTransformations (this )




theta =randn (0 ,1 ); 
D =theta2D (this ,theta ); 
theta_recon =D2theta (this ,D ); 
ifisempty (max (abs (theta (:)-theta_recon (:))))
err (1 )=0 ; 
else
err (1 )=1 ; 
end


weights =rand (this .Size ,1 ); 
this =setWeights (this ,weights ); 
D =diag (1 ./weights ); 
L =this .getLowerTriangularCholeskyFactor ; 
D_recon =L *L ' ; 
err (2 )=max (abs (D (:)-D_recon (:))); 



theta =randn (0 ,1 ); 
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
ifisempty (max (abs (canonical1 (:)-canonical2 (:))))
err (5 )=0 ; 
else
err (5 )=1 ; 
end

ifmax (err (:))<=sqrt (eps )
disp (getString (message ('stats:classreg:regr:lmeutils:covmats:CovarianceMatrix:String_TransformsOK' ))); 
else
error (message ('stats:classreg:regr:lmeutils:covmats:CovarianceMatrix:String_TransformsNotOK' )); 
end

end

end

methods (Access =public ,Hidden =true )




function theta =initializeTheta (this )%#ok<MANU> 


theta =zeros (0 ,1 ); 

end

function L =theta2L (this ,theta )


assert (isempty (theta )); 
q =this .Size ; 
L =spdiags (1 ./sqrt (this .Weights ),0 ,q ,q ); 

end

function D =theta2D (this ,theta )


assert (isempty (theta )); 
q =this .Size ; 
D =spdiags (1 ./this .Weights ,0 ,q ,q ); 

end

function theta =D2theta (this ,D )%#ok<INUSD> 


theta =zeros (0 ,1 ); 

end



function natural =convertUnconstrainedToNatural (this ,unconstrained )%#ok<INUSL> 


assert (isempty (unconstrained )); 
natural =zeros (0 ,1 ); 

end

function unconstrained =convertNaturalToUnconstrained (this ,natural )%#ok<INUSL> 


assert (isempty (natural )); 
unconstrained =zeros (0 ,1 ); 

end



function canonical =convertNaturalToCanonical (this ,natural )%#ok<INUSL> 


assert (isempty (natural )); 
canonical =zeros (0 ,1 ); 

end

function natural =convertCanonicalToNatural (this ,canonical )%#ok<INUSL> 


assert (isempty (canonical )); 
natural =zeros (0 ,1 ); 

end


function names =defineCanonicalParameterNames (this )%#ok<MANU> 

names =table ({},'VariableNames' ,{'Name' }); 
end


function type =defineType (this )%#ok<MANU> 

type =classreg .regr .lmeutils .covmats .CovarianceMatrix .TYPE_FIXEDWEIGHTS ; 
end


function covariancepattern =defineCovariancePattern (this )


covariancepattern =logical (eye (this .Size )); 

end

end

end