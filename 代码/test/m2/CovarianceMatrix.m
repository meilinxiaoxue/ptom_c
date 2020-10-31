classdef CovarianceMatrix 











































































































properties (Access =public )

Name 
end

properties (GetAccess =public ,SetAccess =protected )

Size 



VariableNames 




Type 




CovariancePattern 


WhichParameterization 


NumParametersExcludingSigma 
end

properties (Access =protected )


UnconstrainedParameters 



NaturalParameters 



CanonicalParameters 



CanonicalParameterNames 


Sigma 


SigmaName ='Res std' ; 
end

properties (Access =public ,Constant =true ,Hidden =true )

PARAMETERIZATION_NATURAL ='Natural' ; 
PARAMETERIZATION_CANONICAL ='Canonical' ; 
PARAMETERIZATION_UNCONSTRAINED ='Unconstrained' ; 


TYPE_FULL ='Full' ; 
TYPE_FULLCHOLESKY ='FullCholesky' ; 
TYPE_DIAGONAL ='Diagonal' ; 
TYPE_ISOTROPIC ='Isotropic' ; 
TYPE_COMPSYMM ='CompSymm' ; 
TYPE_BLOCKED ='Blocked' ; 
TYPE_FIXEDWEIGHTS ='FixedWeights' ; 
TYPE_PATTERNED ='Patterned' ; 




AllowedCovarianceTypes =...
    {classreg .regr .lmeutils .covmats .CovarianceMatrix .TYPE_FULL ,...
    classreg .regr .lmeutils .covmats .CovarianceMatrix .TYPE_FULLCHOLESKY ,...
    classreg .regr .lmeutils .covmats .CovarianceMatrix .TYPE_DIAGONAL ,...
    classreg .regr .lmeutils .covmats .CovarianceMatrix .TYPE_ISOTROPIC ,...
    classreg .regr .lmeutils .covmats .CovarianceMatrix .TYPE_COMPSYMM ,...
    classreg .regr .lmeutils .covmats .CovarianceMatrix .TYPE_FIXEDWEIGHTS ,...
    classreg .regr .lmeutils .covmats .CovarianceMatrix .TYPE_PATTERNED }; 
end

methods (Access =public )

function this =CovarianceMatrix (dimension ,varargin )












ifnargin ==0 
return ; 
end


dfltVariableNames =[]; 
dfltName =[]; 


parnames ={'VariableNames' ,'Name' }; 
dflts ={dfltVariableNames ,dfltName }; 


[variablenames ,name ,~,~]=internal .stats .parseArgs (parnames ,dflts ,varargin {:}); 


isPosInteger =internal .stats .isIntegerVals (dimension ,0 ); 
if~isPosInteger ||~isscalar (dimension )

error (message ('stats:classreg:regr:lmeutils:covmats:CovarianceMatrix:BadDimension' )); 
end


if~isempty (variablenames )

if~internal .stats .isStrings (variablenames ,true )||~isvector (variablenames )

error (message ('stats:classreg:regr:lmeutils:covmats:CovarianceMatrix:BadVariableNames' )); 
end


ifsize (variablenames ,1 )==1 
variablenames =variablenames ' ; 
end


iflength (variablenames )~=dimension 

error (message ('stats:classreg:regr:lmeutils:covmats:CovarianceMatrix:BadVariableNamesLength' ,num2str (dimension ))); 
end
else

variablenames =cell (dimension ,1 ); 
fori =1 :dimension 
variablenames {i }=['v' ,num2str (i )]; 
end
end


if~isempty (name )

[tf ,name ]=internal .stats .isString (name ,true ); 
if~tf 

error (message ('stats:classreg:regr:lmeutils:covmats:CovarianceMatrix:BadName' )); 
end
else

name ='g' ; 
end

this .Name =name ; 
this .Size =dimension ; 
this .VariableNames =variablenames ; 

this .Type =defineType (this ); 
assert (internal .stats .isString (this .Type ,false )==true ); 

this .CovariancePattern =defineCovariancePattern (this ); 
assert (all (size (this .CovariancePattern )==[dimension ,dimension ])); 


this .WhichParameterization =classreg .regr .lmeutils .covmats .CovarianceMatrix .PARAMETERIZATION_UNCONSTRAINED ; 
theta =initializeTheta (this ); 
this .UnconstrainedParameters =theta ; 

this .NumParametersExcludingSigma =length (theta ); 

this .CanonicalParameterNames =defineCanonicalParameterNames (this ); 



if~isa (this ,'classreg.regr.lmeutils.covmats.BlockedCovariance' )
assert (size (this .CanonicalParameterNames ,1 )==length (theta )); 
end

this .Sigma =1 ; 

end

function unconstrained =getUnconstrainedParameters (this )





ifisempty (this .UnconstrainedParameters )
this =createUnconstrainedParameterization (this ); 
end
unconstrained =this .UnconstrainedParameters ; 

end

function natural =getNaturalParameters (this )





ifisempty (this .NaturalParameters )
this =createNaturalParameterization (this ); 
end
natural =this .NaturalParameters ; 

end

function canonical =getCanonicalParameters (this )





ifisempty (this .CanonicalParameters )
this =createCanonicalParameterization (this ); 
end
canonical =this .CanonicalParameters ; 

end

function names =getCanonicalParameterNames (this )





names =this .CanonicalParameterNames ; 

end

function this =setUnconstrainedParameters (this ,theta )







narginchk (2 ,Inf ); 


isRealVector =isreal (theta )&isvector (theta ); 
ifisRealVector &&length (theta )==this .NumParametersExcludingSigma 

ifsize (theta ,1 )==1 
theta =theta ' ; 
end
else

error (message ('stats:classreg:regr:lmeutils:covmats:CovarianceMatrix:BadTheta' ,num2str (this .NumParametersExcludingSigma ))); 
end


this .NaturalParameters =[]; 
this .CanonicalParameters =[]; 


this .UnconstrainedParameters =theta ; 
this .WhichParameterization =classreg .regr .lmeutils .covmats .CovarianceMatrix .PARAMETERIZATION_UNCONSTRAINED ; 

end

function this =setNaturalParameters (this ,eta )






narginchk (2 ,Inf ); 


isRealVector =isreal (eta )&isvector (eta ); 
ifisRealVector &&length (eta )==this .NumParametersExcludingSigma 

ifsize (eta ,1 )==1 
eta =eta ' ; 
end
else

error (message ('stats:classreg:regr:lmeutils:covmats:CovarianceMatrix:BadEta' ,num2str (this .NumParametersExcludingSigma ))); 
end


this .UnconstrainedParameters =[]; 
this .CanonicalParameters =[]; 


this .NaturalParameters =eta ; 
this .WhichParameterization =classreg .regr .lmeutils .covmats .CovarianceMatrix .PARAMETERIZATION_NATURAL ; 

end

function L =getLowerTriangularCholeskyFactor (this )






narginchk (1 ,Inf ); 


theta =getUnconstrainedParameters (this ); 
L =theta2L (this ,theta ); 

end

function sigma =getSigma (this )




sigma =this .Sigma ; 

end

function this =setSigma (this ,sigma )





narginchk (2 ,Inf ); 


if~isreal (sigma )||~isscalar (sigma )

error (message ('stats:classreg:regr:lmeutils:covmats:CovarianceMatrix:BadSigma' )); 
end

this .Sigma =sigma ; 

end

function this =createUnconstrainedParameterization (this )





switchthis .WhichParameterization 

case classreg .regr .lmeutils .covmats .CovarianceMatrix .PARAMETERIZATION_NATURAL 

natural =this .NaturalParameters ; 
unconstrained =convertNaturalToUnconstrained (this ,natural ); 
this .UnconstrainedParameters =unconstrained ; 

case classreg .regr .lmeutils .covmats .CovarianceMatrix .PARAMETERIZATION_CANONICAL 

canonical =this .CanonicalParameters ; 
unconstrained =convertCanonicalToUnconstrained (this ,canonical ); 
this .UnconstrainedParameters =unconstrained ; 

case classreg .regr .lmeutils .covmats .CovarianceMatrix .PARAMETERIZATION_UNCONSTRAINED 

otherwise

error (message ('stats:classreg:regr:lmeutils:covmats:CovarianceMatrix:BadParameterization' )); 
end
end

function this =createNaturalParameterization (this )





switchthis .WhichParameterization 

case classreg .regr .lmeutils .covmats .CovarianceMatrix .PARAMETERIZATION_NATURAL 

case classreg .regr .lmeutils .covmats .CovarianceMatrix .PARAMETERIZATION_CANONICAL 

canonical =this .CanonicalParameters ; 
natural =convertCanonicalToNatural (this ,canonical ); 
this .NaturalParameters =natural ; 

case classreg .regr .lmeutils .covmats .CovarianceMatrix .PARAMETERIZATION_UNCONSTRAINED 

unconstrained =this .UnconstrainedParameters ; 
natural =convertUnconstrainedToNatural (this ,unconstrained ); 
this .NaturalParameters =natural ; 

otherwise

error (message ('stats:classreg:regr:lmeutils:covmats:CovarianceMatrix:BadParameterization' )); 
end
end

function this =createCanonicalParameterization (this )





switchthis .WhichParameterization 

case classreg .regr .lmeutils .covmats .CovarianceMatrix .PARAMETERIZATION_NATURAL 

natural =this .NaturalParameters ; 
canonical =convertNaturalToCanonical (this ,natural ); 
this .CanonicalParameters =canonical ; 

case classreg .regr .lmeutils .covmats .CovarianceMatrix .PARAMETERIZATION_CANONICAL 

case classreg .regr .lmeutils .covmats .CovarianceMatrix .PARAMETERIZATION_UNCONSTRAINED 

unconstrained =this .UnconstrainedParameters ; 
canonical =convertUnconstrainedToCanonical (this ,unconstrained ); 
this .CanonicalParameters =canonical ; 

otherwise

error (message ('stats:classreg:regr:lmeutils:covmats:CovarianceMatrix:BadParameterization' )); 
end
end

end

methods (Access =protected )

function canonical =convertUnconstrainedToCanonical (this ,unconstrained )


natural =convertUnconstrainedToNatural (this ,unconstrained ); 
canonical =convertNaturalToCanonical (this ,natural ); 

end

function unconstrained =convertCanonicalToUnconstrained (this ,canonical )


natural =convertCanonicalToNatural (this ,canonical ); 
unconstrained =convertNaturalToUnconstrained (this ,natural ); 

end

end

methods (Abstract =true ,Access =public ,Hidden =true )




theta =initializeTheta (this ); 
L =theta2L (this ,theta ); 
D =theta2D (this ,theta ); 
theta =D2theta (this ,D ); 



natural =convertUnconstrainedToNatural (this ,unconstrained ); 
unconstrained =convertNaturalToUnconstrained (this ,natural ); 



canonical =convertNaturalToCanonical (this ,natural ); 
natural =convertCanonicalToNatural (this ,canonical ); 


names =defineCanonicalParameterNames (this ); 


type =defineType (this ); 


covariancepattern =defineCovariancePattern (this ); 

end

methods (Access =public ,Static =true )


function R1 =singularLowerChol (T )



















assertThat (isreal (T )&ismatrix (T )&size (T ,1 )==size (T ,2 ),'stats:classreg:regr:lmeutils:covmats:CovarianceMatrix:BadT' ); 


T =(T +T ' )/2 ; 



hasNaNs =any (isnan (T (:))); 
hasInfs =any (isinf (T (:))); 
if(hasNaNs ||hasInfs )
R1 =tril (NaN (size (T ))); 
return ; 
end





epsilon =eps (class (T )); 
delta =epsilon ; 
I =eye (size (T )); 
found =false ; 
while(found ==false )
[R1 ,p ]=chol (T +delta *I ,'lower' ); 
if(p ==0 )

found =true ; 
else


delta =2 *delta ; 
end
end

end


function cmat =createCovariance (name ,dimension ,varargin )


















narginchk (2 ,Inf ); 


name =internal .stats .getParamVal (name ,classreg .regr .lmeutils .covmats .CovarianceMatrix .AllowedCovarianceTypes ,'NAME' ); 


switchlower (name )
case lower (classreg .regr .lmeutils .covmats .CovarianceMatrix .TYPE_FULL )
cmat =classreg .regr .lmeutils .covmats .FullCovariance (dimension ,varargin {:}); 

case lower (classreg .regr .lmeutils .covmats .CovarianceMatrix .TYPE_FULLCHOLESKY )
cmat =classreg .regr .lmeutils .covmats .FullCholeskyCovariance (dimension ,varargin {:}); 

case lower (classreg .regr .lmeutils .covmats .CovarianceMatrix .TYPE_DIAGONAL )
cmat =classreg .regr .lmeutils .covmats .DiagonalCovariance (dimension ,varargin {:}); 

case lower (classreg .regr .lmeutils .covmats .CovarianceMatrix .TYPE_ISOTROPIC )
cmat =classreg .regr .lmeutils .covmats .IsotropicCovariance (dimension ,varargin {:}); 

case lower (classreg .regr .lmeutils .covmats .CovarianceMatrix .TYPE_COMPSYMM )
cmat =classreg .regr .lmeutils .covmats .CompoundSymmetryCovariance (dimension ,varargin {:}); 

case lower (classreg .regr .lmeutils .covmats .CovarianceMatrix .TYPE_FIXEDWEIGHTS )
cmat =classreg .regr .lmeutils .covmats .FixedWeightsCovariance (dimension ,varargin {:}); 

case lower (classreg .regr .lmeutils .covmats .CovarianceMatrix .TYPE_PATTERNED )
cmat =classreg .regr .lmeutils .covmats .PatternedCovariance (dimension ,varargin {:}); 

otherwise

error (message ('stats:classreg:regr:lmeutils:covmats:CovarianceMatrix:BadCovarianceName' ,name )); 
end

end

end

end


function assertThat (condition ,msgID ,varargin )





if~condition 

try
msg =message (msgID ,varargin {:}); 
catch 

error (message ('stats:LinearMixedModel:BadMsgID' ,msgID )); 
end

ME =MException (msg .Identifier ,getString (msg )); 
throwAsCaller (ME ); 
end

end

