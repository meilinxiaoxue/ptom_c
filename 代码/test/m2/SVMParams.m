classdef SVMParams <classreg .learning .modelparams .ModelParams 









































properties 
Alpha =[]; 
BoxConstraint =[]; 
CacheSize =[]; 
CachingMethod ='' ; 
ClipAlphas =[]; 
DeltaGradientTolerance =[]; 
Epsilon =[]; 
GapTolerance =[]; 
KKTTolerance =[]; 
IterationLimit =[]; 
KernelFunction ='' ; 
KernelScale =[]; 
KernelOffset =[]; 
KernelPolynomialOrder =[]; 
NumPrint =[]; 
Nu =[]; 
OutlierFraction =[]; 
RemoveDuplicates =[]; 
ShrinkagePeriod =[]; 
Solver ='' ; 
StandardizeData =[]; 
SaveSupportVectors =[]; 
VerbosityLevel =[]; 
end

methods (Access =protected )
function this =SVMParams (type ,alphas ,clipAlphas ,...
    C ,nu ,...
    cacheSize ,cacheAlg ,...
    deltagradtol ,gaptol ,kkttol ,...
    outfrac ,maxiter ,...
    kernelfun ,scale ,offset ,polyorder ,...
    dostandardize ,solver ,shrinkAfter ,saveSV ,...
    verbose ,nprint ,epsilon ,removeDups )
this =this @classreg .learning .modelparams .ModelParams ('SVM' ,type ,2 ); 

this .Alpha =alphas ; 
this .BoxConstraint =C ; 
this .CacheSize =cacheSize ; 
this .CachingMethod =cacheAlg ; 
this .ClipAlphas =clipAlphas ; 
this .DeltaGradientTolerance =deltagradtol ; 
this .Epsilon =epsilon ; 
this .GapTolerance =gaptol ; 
this .KKTTolerance =kkttol ; 
this .OutlierFraction =outfrac ; 
this .IterationLimit =maxiter ; 
this .KernelFunction =kernelfun ; 
this .KernelScale =scale ; 
this .KernelOffset =offset ; 
this .KernelPolynomialOrder =polyorder ; 
this .Nu =nu ; 
this .NumPrint =nprint ; 
this .RemoveDuplicates =removeDups ; 
this .ShrinkagePeriod =shrinkAfter ; 
this .Solver =solver ; 
this .StandardizeData =dostandardize ; 
this .SaveSupportVectors =saveSV ; 
this .VerbosityLevel =verbose ; 
end
end

methods (Static ,Hidden )
function v =expectedVersion ()
v =2 ; 
end

function [holder ,extraArgs ]=make (type ,varargin )

args ={'alpha' ,'boxconstraint' ,'nu' ...
    ,'cachesize' ,'cachingmethod' ,'clipalphas' ...
    ,'kkttolerance' ,'gaptolerance' ,'deltagradienttolerance' ...
    ,'outlierfraction' ...
    ,'iterationlimit' ...
    ,'kernelfunction' ,'kernelscale' ,'kerneloffset' ,'polynomialorder' ...
    ,'solver' ...
    ,'standardize' ...
    ,'shrinkageperiod' ...
    ,'savesupportvectors' ...
    ,'verbose' ,'numprint' ...
    ,'epsilon' ,'removeduplicates' }; 
defs ={[],[],[]...
    ,[],'' ,[]...
    ,[],[],[]...
    ,[]...
    ,[]...
    ,'' ,[],[],[]...
    ,'' ...
    ,[]...
    ,[]...
    ,[]...
    ,[],[]...
    ,[],[]}; 
[alphas ,C ,nu ,cachesize ,cachingmethod ,clipAlphas ,...
    kkttol ,gaptol ,deltagradtol ,outfrac ,maxiter ,...
    kernelfun ,scale ,offset ,polyorder ,...
    solver ,dostandardize ,shrinkAfter ,saveSV ,...
    verbose ,nprint ,epsilon ,removeDups ,~,extraArgs ]=...
    internal .stats .parseArgs (args ,defs ,varargin {:}); 

doclass =strcmp (type ,'classification' ); 
if~isempty (alphas )
if(~isfloat (alphas )||~isvector (alphas )||...
    any (isnan (alphas ))||any (isinf (alphas )))
error (message ('stats:classreg:learning:modelparams:SVMParams:make:BadAlpha' )); 
end
ifdoclass &&any (alphas <0 )
error (message ('stats:classreg:learning:modelparams:SVMParams:make:BadAlpha' )); 
end
end
alphas =alphas (:); 
if~isempty (alphas )
internal .stats .checkSupportedNumeric ('Alpha' ,alphas ,true ); 
end

if~isempty (clipAlphas )
clipAlphas =internal .stats .parseOnOff (clipAlphas ,'ClipAlphas' ); 
end

if~isempty (C )&&...
    (~isscalar (C )||~isfloat (C )||C <=0 ||isnan (C ))
error (message ('stats:classreg:learning:modelparams:SVMParams:make:BadBoxConstraint' )); 
end


if~isempty (nu )
if~doclass 
error (message ('stats:classreg:learning:modelparams:SVMParams:make:InvalidNuForRegression' )); 
elseif(~isscalar (nu )||~isfloat (nu )||nu <=0 ||isnan (nu ))
error (message ('stats:classreg:learning:modelparams:SVMParams:make:BadNu' )); 
end
end

if~isempty (cachingmethod )&&~ischar (cachingmethod )
error (message ('stats:classreg:learning:modelparams:SVMParams:make:BadCachingMethod' )); 
end

if~isempty (cachesize )
if(~ischar (cachesize )||~strncmpi (cachesize ,'maximal' ,length (cachesize )))...
    &&(~isscalar (cachesize )||~isfloat (cachesize )...
    ||cachesize <=0 ||isnan (cachesize ))
error (message ('stats:classreg:learning:modelparams:SVMParams:make:BadCacheSize' )); 
end
ifischar (cachesize )
cachesize ='maximal' ; 
end
end

if~isempty (kkttol )&&...
    (~isscalar (kkttol )||~isfloat (kkttol )...
    ||kkttol <0 ||isnan (kkttol ))
error (message ('stats:classreg:learning:modelparams:SVMParams:make:BadKKTTolerance' )); 
end

if~isempty (gaptol )&&...
    (~isscalar (gaptol )||~isfloat (gaptol )...
    ||gaptol <0 ||isnan (gaptol ))
error (message ('stats:classreg:learning:modelparams:SVMParams:make:BadGapTolerance' )); 
end

if~isempty (deltagradtol )&&...
    (~isscalar (deltagradtol )||~isfloat (deltagradtol )...
    ||deltagradtol <0 ||isnan (deltagradtol ))
error (message ('stats:classreg:learning:modelparams:SVMParams:make:BadDeltaGradientTolerance' )); 
end

if~isempty (outfrac )
if(~isscalar (outfrac )||~isfloat (outfrac )...
    ||outfrac <0 ||outfrac >=1 ||isnan (outfrac ))
error (message ('stats:classreg:learning:modelparams:SVMParams:make:BadOutlierFraction' )); 
end
end

if~isempty (maxiter )&&...
    (~isscalar (maxiter )||~isfloat (maxiter )...
    ||maxiter <=0 ||isnan (maxiter ))
error (message ('stats:classreg:learning:modelparams:SVMParams:make:BadIterationLimit' )); 
end

if~isempty (kernelfun )
if~ischar (kernelfun )
error (message ('stats:classreg:learning:modelparams:SVMParams:make:KernelFunctionNotString' )); 
end
allowedVals ={'linear' ,'gaussian' ,'rbf' ,'polynomial' }; 
tf =strncmpi (kernelfun ,allowedVals ,length (kernelfun )); 
Nfound =sum (tf ); 
ifNfound >1 
error (message ('stats:classreg:learning:modelparams:SVMParams:make:KernelFunctionNotRecognized' )); 
elseifNfound ==1 
iffind (tf ,1 )==3 
kernelfun ='gaussian' ; 
else
kernelfun =allowedVals {tf }; 
end
else
ifexist (kernelfun ,'file' )==0 
error (message ('stats:classreg:learning:modelparams:SVMParams:make:KernelFunctionFileNotFound' ,...
    kernelfun )); 
end
end
end

if~isempty (scale )
if(~ischar (scale )||~strncmpi (scale ,'auto' ,length (scale )))...
    &&(~isscalar (scale )||~isfloat (scale )...
    ||scale <=0 ||isnan (scale ))
error (message ('stats:classreg:learning:modelparams:SVMParams:make:BadKernelScale' )); 
end
ifischar (scale )
scale ='auto' ; 
end
end

if~isempty (offset )&&...
    (~isscalar (offset )||~isfloat (offset )...
    ||offset <0 ||isnan (offset ))
error (message ('stats:classreg:learning:modelparams:SVMParams:make:BadKernelOffset' )); 
end

if~isempty (polyorder )&&...
    (~isscalar (polyorder )||~isfloat (polyorder )...
    ||polyorder <=0 ||isnan (polyorder ))
error (message ('stats:classreg:learning:modelparams:SVMParams:make:BadPolynomialOrder' )); 
end

if~isempty (solver )
if~ischar (solver )
error (message ('stats:classreg:learning:modelparams:SVMParams:make:SolverNotString' )); 
end
allowedVals ={'SMO' ,'ISDA' ,'L1QP' }; 
tf =strncmpi (solver ,allowedVals ,length (solver )); 
ifsum (tf )~=1 
error (message ('stats:classreg:learning:modelparams:SVMParams:make:SolverNotRecognized' )); 
end
solver =allowedVals {tf }; 
end

if~isempty (dostandardize )
dostandardize =internal .stats .parseOnOff (dostandardize ,'Standardize' ); 
end

if~isempty (shrinkAfter )&&...
    (~isscalar (shrinkAfter )||~isfloat (shrinkAfter )...
    ||shrinkAfter <0 ||isnan (shrinkAfter ))
error (message ('stats:classreg:learning:modelparams:SVMParams:make:BadShrinkagePeriod' )); 
end

if~isempty (saveSV )
saveSV =internal .stats .parseOnOff (saveSV ,'SaveSupportVectors' ); 
end

ifislogical (verbose )
verbose =double (verbose ); 
end
if~isempty (verbose )&&...
    (~isscalar (verbose )||~isfloat (verbose )...
    ||verbose <0 ||isnan (verbose ))
error (message ('stats:classreg:learning:modelparams:SVMParams:make:BadVerbose' )); 
end

if~isempty (nprint )&&...
    (~isscalar (nprint )||~isfloat (nprint )...
    ||nprint <0 ||isnan (nprint ))
error (message ('stats:classreg:learning:modelparams:SVMParams:make:BadNumPrint' )); 
end

if~isempty (epsilon )
ifdoclass 
error (message ('stats:classreg:learning:modelparams:SVMParams:make:InvalidEpsilon' )); 
end

if(~isscalar (epsilon )||~isfloat (epsilon )...
    ||epsilon <0 ||isnan (epsilon ))
error (message ('stats:classreg:learning:modelparams:SVMParams:make:BadEpsilon' )); 
end
end

if~isempty (removeDups )
removeDups =internal .stats .parseOnOff (removeDups ,'RemoveDuplicates' ); 
end

holder =classreg .learning .modelparams .SVMParams (...
    type ,alphas ,clipAlphas ,C ,nu ,...
    cachesize ,cachingmethod ,...
    deltagradtol ,gaptol ,kkttol ,...
    outfrac ,maxiter ,...
    kernelfun ,scale ,offset ,polyorder ,...
    dostandardize ,solver ,shrinkAfter ,saveSV ,...
    verbose ,nprint ,epsilon ,removeDups ); 
end

function this =loadobj (obj )
found =fieldnames (obj ); 

ifismember ('Version' ,found )&&~isempty (obj .Version )...
    &&obj .Version ==classreg .learning .modelparams .SVMParams .expectedVersion ()


this =obj ; 

else



ifismember ('RemoveDuplicates' ,found )...
    &&~isempty (obj .RemoveDuplicates )
removeDups =obj .RemoveDuplicates ; 
else
removeDups =false ; 
end

ifismember ('SaveSupportVectors' ,found )...
    &&~isempty (obj .SaveSupportVectors )
saveSV =obj .SaveSupportVectors ; 
else
saveSV =true ; 
end

ifismember ('ClipAlphas' ,found )&&~isempty (obj .ClipAlphas )
clipAlphas =obj .ClipAlphas ; 
else
clipAlphas =true ; 
end

this =classreg .learning .modelparams .SVMParams (...
    obj .Type ,...
    obj .Alpha ,clipAlphas ,obj .BoxConstraint ,obj .Nu ,...
    obj .CacheSize ,obj .CachingMethod ,...
    obj .DeltaGradientTolerance ,obj .GapTolerance ,obj .KKTTolerance ,...
    obj .OutlierFraction ,obj .IterationLimit ,...
    obj .KernelFunction ,obj .KernelScale ,...
    obj .KernelOffset ,obj .KernelPolynomialOrder ,...
    obj .StandardizeData ,obj .Solver ,obj .ShrinkagePeriod ,saveSV ,...
    obj .VerbosityLevel ,obj .NumPrint ,obj .Epsilon ,removeDups ); 
end
end
end

methods (Hidden )
function this =fillDefaultParams (this ,X ,Y ,W ,dataSummary ,classSummary )%#ok<INUSL> 
N =size (X ,1 ); 

if~isempty (this .Alpha )&&numel (this .Alpha )~=N 
error (message ('stats:classreg:learning:modelparams:SVMParams:fillDefaultParams:BadAlpha' ,N )); 
end

ifisempty (this .ClipAlphas )
this .ClipAlphas =true ; 
end

doclass =strcmpi (this .Type ,'classification' ); 

ifisempty (this .KernelFunction )
ifdoclass &&numel (classSummary .NonzeroProbClasses )==1 
this .KernelFunction ='gaussian' ; 
this .SaveSupportVectors =true ; 
else
this .KernelFunction ='linear' ; 
end
end

ifisempty (this .BoxConstraint )
if~doclass &&strcmpi (this .KernelFunction ,'gaussian' )



else
this .BoxConstraint =1 ; 
end
else
ifdoclass &&numel (classSummary .NonzeroProbClasses )==1 
ifthis .BoxConstraint ~=1 
error (message ('stats:classreg:learning:modelparams:SVMParams:fillDefaultParams:BadBoxConstraint' )); 
end
end
end



ifdoclass 
ifisempty (this .Nu )
this .Nu =0.5 ; 
else
ifthis .Nu >1 
error (message ('stats:classreg:learning:modelparams:SVMParams:fillDefaultParams:BadNu' )); 
end
end
end







if~isempty (this .Alpha )
alphas =this .Alpha ; 
ifdoclass &&numel (classSummary .NonzeroProbClasses )==1 
sumAlpha =sum (alphas ); 

ifsumAlpha ==0 
error (message ('stats:classreg:learning:modelparams:SVMParams:fillDefaultParams:BadAlphaForOneClassLearning' ,...
    sprintf ('%e' ,N *this .Nu ))); 
end

ifabs (sumAlpha -N *this .Nu )>100 *eps (sumAlpha )
alphas =alphas *N *this .Nu /sumAlpha ; 
ifany (alphas >1 )
error (message ('stats:classreg:learning:modelparams:SVMParams:fillDefaultParams:BadAlphaForOneClassLearning' ,...
    sprintf ('%e' ,N *this .Nu ))); 
end
end
else
if~isempty (this .BoxConstraint )
ifany (abs (alphas )>this .BoxConstraint )
maxAlpha =max (abs (alphas )); 
alphas =alphas *this .BoxConstraint /maxAlpha ; 
end
end
end
this .Alpha =alphas ; 

end
import internal.stats.typeof ; 


iftypeof (X )=="double" 
oneColSize =ceil (8 *N /1024 /1024 ); 
elseiftypeof (X )=="single" 
oneColSize =ceil (4 *N /1024 /1024 ); 
end

ifisempty (this .CacheSize )
iftypeof (X )=="double" 
this .CacheSize =max (1000 ,oneColSize ); 
elseiftypeof (X )=="single" 
this .CacheSize =max (1000 ,oneColSize ); 
end
elseifstrcmpi (this .CacheSize ,'maximal' )||this .CacheSize ==Inf 
iftypeof (X )=="double" 
this .CacheSize =ceil (8 *N *N /1024 /1024 ); 
elseiftypeof (X )=="single" 
this .CacheSize =ceil (4 *N *N /1024 /1024 ); 
end
else
ifthis .CacheSize <oneColSize 
error (message ('stats:classreg:learning:modelparams:SVMParams:fillDefaultParams:BadCacheSize' ,...
    oneColSize )); 
end
end

ifisempty (this .CachingMethod )
this .CachingMethod ='Queue' ; 
end

ifisempty (this .OutlierFraction )
this .OutlierFraction =0 ; 
elseifthis .OutlierFraction >0 
if~(doclass &&numel (classSummary .NonzeroProbClasses )==1 )


ifisempty (this .Solver )
this .Solver ='ISDA' ; 
elseifstrcmpi (this .Solver ,'L1QP' )
error (message ('stats:classreg:learning:modelparams:SVMParams:fillDefaultParams:QPwithRobustLearning' )); 
elseif~doclass &&strcmpi (this .Solver ,'SMO' )
error (message ('stats:classreg:learning:modelparams:SVMParams:fillDefaultParams:SVRSMOwithRobustLearning' )); 
end
end
end

ifisempty (this .Solver )
this .Solver ='SMO' ; 
end

ifdoclass &&(numel (classSummary .NonzeroProbClasses )==1 ...
    &&strcmpi (this .Solver ,'ISDA' ))
error (message ('stats:classreg:learning:modelparams:SVMParams:fillDefaultParams:ISDAwithOneClassLearning' )); 
end

ifstrcmpi (this .Solver ,'L1QP' )
ifisempty (this .KernelOffset )
this .KernelOffset =0 ; 
end
if~isempty (this .KKTTolerance )
error (message ('stats:classreg:learning:modelparams:SVMParams:fillDefaultParams:BadToleranceParameterForL1QP' ,...
    'KKTTolerance' )); 
end
if~isempty (this .GapTolerance )
error (message ('stats:classreg:learning:modelparams:SVMParams:fillDefaultParams:BadToleranceParameterForL1QP' ,...
    'GapTolerance' )); 
end
if~isempty (this .DeltaGradientTolerance )
error (message ('stats:classreg:learning:modelparams:SVMParams:fillDefaultParams:BadToleranceParameterForL1QP' ,...
    'DeltaGradientTolerance' )); 
end
else
ifstrcmpi (this .Solver ,'SMO' )
ifisempty (this .KernelOffset )
this .KernelOffset =0 ; 
end
ifdoclass 
ifisempty (this .KKTTolerance )
this .KKTTolerance =0 ; 
end
ifisempty (this .GapTolerance )
this .GapTolerance =0 ; 
end
ifisempty (this .DeltaGradientTolerance )
this .DeltaGradientTolerance =0.001 ; 
end
else
ifisempty (this .KKTTolerance )
this .KKTTolerance =0 ; 
end
ifisempty (this .GapTolerance )
this .GapTolerance =0.001 ; 
end
ifisempty (this .DeltaGradientTolerance )
this .DeltaGradientTolerance =0 ; 
end
end
elseifstrcmpi (this .Solver ,'ISDA' )
ifisempty (this .KernelOffset )
this .KernelOffset =0.1 ; 
end
ifdoclass 
ifisempty (this .KKTTolerance )
this .KKTTolerance =0.001 ; 
end
ifisempty (this .GapTolerance )
this .GapTolerance =0 ; 
end
ifisempty (this .DeltaGradientTolerance )
this .DeltaGradientTolerance =0 ; 
end
else
ifisempty (this .KKTTolerance )
this .KKTTolerance =0 ; 
end
ifisempty (this .GapTolerance )
this .GapTolerance =0.001 ; 
end
ifisempty (this .DeltaGradientTolerance )
this .DeltaGradientTolerance =0 ; 
end
end
elseifstrcmpi (this .Solver ,'All2D' )
ifisempty (this .KernelOffset )
this .KernelOffset =0.01 ; 
end
ifisempty (this .KKTTolerance )
this .KKTTolerance =0.001 ; 
end
ifisempty (this .GapTolerance )
this .GapTolerance =0.001 ; 
end
ifisempty (this .DeltaGradientTolerance )
this .DeltaGradientTolerance =0.001 ; 
end
end

end

ifisempty (this .SaveSupportVectors )
this .SaveSupportVectors =true ; 
else
if~this .SaveSupportVectors &&~strcmp (this .KernelFunction ,'linear' )
error (message ('stats:classreg:learning:modelparams:SVMParams:fillDefaultParams:MustKeepSVforNonlinearKernel' )); 
end
end

ifisempty (this .KernelScale )
this .KernelScale =1 ; 
else


knownKernels ={'linear' ,'gaussian' ,'rbf' ,'polynomial' }; 
isknown =ismember (this .KernelFunction ,knownKernels ); 
if~isknown &&(strcmp (this .KernelScale ,'auto' )||this .KernelScale ~=1 )
error (message ('stats:classreg:learning:modelparams:SVMParams:fillDefaultParams:KernelScaleForCustomKernel' ,...
    this .KernelFunction )); 
end
end

ifisempty (this .KernelPolynomialOrder )
ifstrcmpi (this .KernelFunction ,'polynomial' )
this .KernelPolynomialOrder =3 ; 
end
else
if~strcmpi (this .KernelFunction ,'polynomial' )
error (message ('stats:classreg:learning:modelparams:SVMParams:fillDefaultParams:PolyOrderWithoutPolyKernel' )); 
end
end







ifisempty (this .IterationLimit )
this .IterationLimit =1e6 ; 
end

ifisempty (this .StandardizeData )
this .StandardizeData =false ; 
end

ifisempty (this .ShrinkagePeriod )
this .ShrinkagePeriod =0 ; 
end

ifisempty (this .VerbosityLevel )
this .VerbosityLevel =0 ; 
end

ifisempty (this .NumPrint )
ifthis .VerbosityLevel >0 
this .NumPrint =1000 ; 
else
this .NumPrint =0 ; 
end
end

ifisempty (this .RemoveDuplicates )
this .RemoveDuplicates =false ; 
end






end

end
end

