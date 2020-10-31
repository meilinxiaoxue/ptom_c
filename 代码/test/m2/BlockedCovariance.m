classdef BlockedCovariance <classreg .regr .lmeutils .covmats .CovarianceMatrix 








































































































properties (GetAccess =public ,SetAccess =protected )


NumBlocks 





Matrices 



NumReps 



SizeVec 




NumParametersExcludingSigmaVec 
end

properties (Access =private )

D_nzind 


L_nzind 


Lpat 
end

methods (Access =public )

function this =BlockedCovariance (mats ,reps ,varargin )













this =this @classreg .regr .lmeutils .covmats .CovarianceMatrix (); 


narginchk (2 ,Inf ); 
dfltName =[]; 
parnames ={'Name' }; 
dflts ={dfltName }; 
name =internal .stats .parseArgs (parnames ,dflts ,varargin {:}); 


if~isempty (name )

[tf ,name ]=internal .stats .isString (name ,true ); 
if~tf 

error (message ('stats:classreg:regr:lmeutils:covmats:CovarianceMatrix:BadName' )); 
end
else

name ='Blocked Covariance Matrix' ; 
end


if~iscell (mats )

error (message ('stats:classreg:regr:lmeutils:covmats:CovarianceMatrix:BadMatrices' )); 
end


ifsize (mats ,1 )==1 
mats =mats ' ; 
end


if~internal .stats .isIntegerVals (reps ,1 )

error (message ('stats:classreg:regr:lmeutils:covmats:CovarianceMatrix:BadReps' )); 
end


ifsize (reps ,1 )==1 
reps =reps ' ; 
end


iflength (mats )~=length (reps )

error (message ('stats:classreg:regr:lmeutils:covmats:CovarianceMatrix:InvalidMatricesReps' )); 
end


numblocks =length (mats ); 
fori =1 :numblocks 
if~isa (mats {i },'classreg.regr.lmeutils.covmats.CovarianceMatrix' )

error (message ('stats:classreg:regr:lmeutils:covmats:CovarianceMatrix:BadMatrices' )); 
end
end


this .NumBlocks =numblocks ; 


this .Matrices =mats ; 


this .NumReps =reps ; 


this .Name =name ; 


sizevec =zeros (numblocks ,1 ); 
fori =1 :numblocks 
sizevec (i )=mats {i }.Size ; 
end
this .Size =sum (sizevec .*reps ); 
this .SizeVec =sizevec ; 


numparameters =0 ; 
numparametersvec =zeros (numblocks ,1 ); 
fori =1 :numblocks 
numparametersvec (i )=mats {i }.NumParametersExcludingSigma ; 
numparameters =numparameters +numparametersvec (i ); 
end
this .NumParametersExcludingSigma =numparameters ; 
this .NumParametersExcludingSigmaVec =numparametersvec ; 



this .VariableNames =[]; 






this .Type =defineType (this ); 
assert (internal .stats .isString (this .Type ,false )==true ); 

this .CovariancePattern =defineCovariancePattern (this ); 
dimension =this .Size ; 
assert (all (size (this .CovariancePattern )==[dimension ,dimension ])); 

this .WhichParameterization =classreg .regr .lmeutils .covmats .CovarianceMatrix .PARAMETERIZATION_UNCONSTRAINED ; 
theta =initializeTheta (this ); 
this .UnconstrainedParameters =theta ; 

this .CanonicalParameterNames =defineCanonicalParameterNames (this ); 

this .Sigma =1 ; 



this .D_nzind =find (this .CovariancePattern ); 
this .Lpat =tril (this .CovariancePattern ); 
this .L_nzind =find (this .Lpat ); 

end

function verifyTransformations (this )




theta =randn (this .NumParametersExcludingSigma ,1 ); 
D =theta2D (this ,theta ); 
theta_recon =D2theta (this ,D ); 
err (1 )=max (abs (theta (:)-theta_recon (:))); 



theta =randn (this .NumParametersExcludingSigma ,1 ); 
D =theta2D (this ,theta ); 
L =classreg .regr .lmeutils .covmats .CovarianceMatrix .singularLowerChol (D ); 
this =setUnconstrainedParameters (this ,theta ); 
L1 =getLowerTriangularCholeskyFactor (this ); 
err (2 )=max (abs (L (:)-L1 (:))); 



natural =convertUnconstrainedToNatural (this ,theta ); 
this =setNaturalParameters (this ,natural ); 
L2 =getLowerTriangularCholeskyFactor (this ); 
err (3 )=max (abs (L (:)-L2 (:))); 



this =setUnconstrainedParameters (this ,theta ); 
canonical1 =getCanonicalParameters (this ); 
this =setNaturalParameters (this ,natural ); 
canonical2 =getCanonicalParameters (this ); 
err (4 )=max (abs (canonical1 (:)-canonical2 (:))); 

ifmax (err (:))<=sqrt (eps )
disp (getString (message ('stats:classreg:regr:lmeutils:covmats:CovarianceMatrix:String_TransformsOK' ))); 
else
error (message ('stats:classreg:regr:lmeutils:covmats:CovarianceMatrix:String_TransformsNotOK' )); 
end

end

function this =setUnconstrainedParameters (this ,theta )







this =setUnconstrainedParameters @classreg .regr .lmeutils .covmats .CovarianceMatrix (this ,theta ); 

numblocks =this .NumBlocks ; 
offset =0 ; 
fori =1 :numblocks 
startidx =offset +1 ; 
endidx =offset +this .NumParametersExcludingSigmaVec (i ); 
thetai =theta (startidx :endidx ); 
offset =endidx ; 
this .Matrices {i }=this .Matrices {i }.setUnconstrainedParameters (thetai ); 
this .Matrices {i }.WhichParameterization =...
    classreg .regr .lmeutils .covmats .CovarianceMatrix .PARAMETERIZATION_UNCONSTRAINED ; 
end

end

function this =setNaturalParameters (this ,eta )






this =setNaturalParameters @classreg .regr .lmeutils .covmats .CovarianceMatrix (this ,eta ); 

numblocks =this .NumBlocks ; 
offset =0 ; 
fori =1 :numblocks 
startidx =offset +1 ; 
endidx =offset +this .NumParametersExcludingSigmaVec (i ); 
etai =eta (startidx :endidx ); 
offset =endidx ; 
this .Matrices {i }=this .Matrices {i }.setNaturalParameters (etai ); 
this .Matrices {i }.WhichParameterization =...
    classreg .regr .lmeutils .covmats .CovarianceMatrix .PARAMETERIZATION_NATURAL ; 
end

end

function this =setSigma (this ,sigma )





this =setSigma @classreg .regr .lmeutils .covmats .CovarianceMatrix (this ,sigma ); 

numblocks =this .NumBlocks ; 
fori =1 :numblocks 
this .Matrices {i }=this .Matrices {i }.setSigma (sigma ); 
end

end

end

methods (Access =public ,Hidden =true )




function theta =initializeTheta (this )

theta =zeros (this .NumParametersExcludingSigma ,1 ); 
offset =0 ; 
fori =1 :this .NumBlocks 
startidx =offset +1 ; 
endidx =offset +this .NumParametersExcludingSigmaVec (i ); 
theta (startidx :endidx )=this .Matrices {i }.initializeTheta (); 
offset =endidx ; 
end

end

function L =theta2L (this ,theta )


numblocks =this .NumBlocks ; 



lvec =cell (numblocks ,1 ); 
offset =0 ; 
fori =1 :numblocks 
startidx =offset +1 ; 
endidx =offset +this .NumParametersExcludingSigmaVec (i ); 
thetai =theta (startidx :endidx ); 
offset =endidx ; 
Li =this .Matrices {i }.theta2L (thetai ); 


li =Li (tril (this .Matrices {i }.CovariancePattern )); 

lvec {i }=repmat (li ,this .NumReps (i ),1 ); 
end




L =double (this .Lpat ); 
L (this .L_nzind )=cell2mat (lvec (:)); 

end

function D =theta2D (this ,theta )


numblocks =this .NumBlocks ; 



dvec =cell (numblocks ,1 ); 
offset =0 ; 
fori =1 :numblocks 
startidx =offset +1 ; 
endidx =offset +this .NumParametersExcludingSigmaVec (i ); 
thetai =theta (startidx :endidx ); 
offset =endidx ; 
Di =this .Matrices {i }.theta2D (thetai ); 

di =Di (this .Matrices {i }.CovariancePattern ); 
dvec {i }=kron (ones (this .NumReps (i ),1 ),di ); 
end




D =double (this .CovariancePattern ); 
D (this .D_nzind )=cell2mat (dvec (:)); 

end

function theta =D2theta (this ,D )

theta =zeros (this .NumParametersExcludingSigma ,1 ); 
offset =0 ; 
fori =1 :this .NumBlocks 
startidx =offset +1 ; 
endidx =offset +this .NumParametersExcludingSigmaVec (i ); 

Dsub =getSubMatrix (this ,D ,i ,1 ); 
theta (startidx :endidx )=this .Matrices {i }.D2theta (Dsub ); 
offset =endidx ; 
end

end



function natural =convertUnconstrainedToNatural (this ,unconstrained )

assert (length (unconstrained )==this .NumParametersExcludingSigma ); 

natural =zeros (this .NumParametersExcludingSigma ,1 ); 
offset =0 ; 
fori =1 :this .NumBlocks 
startidx =offset +1 ; 
endidx =offset +this .NumParametersExcludingSigmaVec (i ); 
natural (startidx :endidx )=...
    this .Matrices {i }.convertUnconstrainedToNatural (unconstrained (startidx :endidx )); 
offset =endidx ; 
end


end

function unconstrained =convertNaturalToUnconstrained (this ,natural )

assert (length (natural )==this .NumParametersExcludingSigma ); 

unconstrained =zeros (this .NumParametersExcludingSigma ,1 ); 
offset =0 ; 
fori =1 :this .NumBlocks 
startidx =offset +1 ; 
endidx =offset +this .NumParametersExcludingSigmaVec (i ); 
unconstrained (startidx :endidx )=...
    this .Matrices {i }.convertNaturalToUnconstrained (natural (startidx :endidx )); 
offset =endidx ; 
end

end



function canonical =convertNaturalToCanonical (this ,natural )

assert (length (natural )==this .NumParametersExcludingSigma ); 

canonical =zeros (this .NumParametersExcludingSigma ,1 ); 
offset =0 ; 
fori =1 :this .NumBlocks 
startidx =offset +1 ; 
endidx =offset +this .NumParametersExcludingSigmaVec (i ); 
canonical (startidx :endidx )=...
    this .Matrices {i }.convertNaturalToCanonical (natural (startidx :endidx )); 
offset =endidx ; 
end

end

function natural =convertCanonicalToNatural (this ,canonical )

assert (length (canonical )==this .NumParametersExcludingSigma ); 

natural =zeros (this .NumParametersExcludingSigma ,1 ); 
offset =0 ; 
fori =1 :this .NumBlocks 
startidx =offset +1 ; 
endidx =offset +this .NumParametersExcludingSigmaVec (i ); 
natural (startidx :endidx )=...
    this .Matrices {i }.convertCanonicalToNatural (canonical (startidx :endidx )); 
offset =endidx ; 
end

end


function names =defineCanonicalParameterNames (this )




numblocks =this .NumBlocks ; 
names =cell (numblocks ,1 ); 
fori =1 :numblocks 
names {i }=this .Matrices {i }.defineCanonicalParameterNames ; 
end

end


function type =defineType (this )%#ok<MANU> 

type =classreg .regr .lmeutils .covmats .CovarianceMatrix .TYPE_BLOCKED ; 
end


function covariancepattern =defineCovariancePattern (this )





numblocks =this .NumBlocks ; 
reps =this .NumReps ; 
localq =this .SizeVec ; 

qreps =localq .*reps ; 
covariancepattern =logical (sparse (sum (qreps ),sum (qreps ))); 
forr =1 :numblocks 
fork =1 :reps (r )
offset =sum (qreps (1 :(r -1 )))+(k -1 )*localq (r ); 
idx =offset +1 :offset +localq (r ); 
covariancepattern (idx ,idx )=this .Matrices {r }.CovariancePattern ; 
end
end

end


end

methods (Access =private )

function Dsub =getSubMatrix (this ,D ,block ,rep )






qreps =this .SizeVec .*this .NumReps ; 


offset =sum (qreps (1 :block -1 ))+(rep -1 )*this .SizeVec (block ); 


idx =offset +1 :offset +this .SizeVec (block ); 


Dsub =D (idx ,idx ); 
end

end

end


