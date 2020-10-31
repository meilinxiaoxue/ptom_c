classdef (Abstract )StandardLinearLikeMixedModel 





































properties (Abstract =true ,GetAccess =public ,SetAccess =public )

y 


X 


Z 



Psi 


FitMethod 
end

properties (Abstract =true ,GetAccess =public ,SetAccess =protected )

N 


p 


q 


rankX 
end

properties (Abstract =true ,GetAccess =public ,SetAccess =protected )

Optimizer 


OptimizerOptions 



CheckHessian 
end

properties (Abstract =true ,GetAccess =public ,SetAccess =public )


InitializationMethod 
end

properties (Abstract =true ,GetAccess =public ,SetAccess =protected )

betaHat 


bHat 



sigmaHat 


thetaHat 



loglikHat 
end

properties (Abstract =true ,GetAccess =public ,SetAccess =protected )

covbetaHat 


covthetaHatlogsigmaHat 



covetaHatlogsigmaHat 



covbetaHatbHat 
end

properties (Abstract =true ,GetAccess =public ,SetAccess =protected )

isSigmaFixed 


sigmaFixed 
end

properties (Abstract =true ,GetAccess =public ,SetAccess =protected )

isFitToData 


isReadyForStats 
end

properties (Constant =true ,Hidden =true )

AllowedDFMethods ={'None' ,'Residual' ,'Satterthwaite' }; 


AllowedResidualTypes ={'Raw' ,'Pearson' ,'Standardized' }; 


AllowedOptimizers ={'fminsearch' ,'fminunc' ,'quasinewton' }; 


AllowedInitializationMethods ={'random' ,'default' }; 
end


methods (Abstract =true ,Access =public )
slme =refit (slme )




slme =initstats (slme )




end


methods (Abstract =true ,Access =public )
df =dfBetaTTest (slme ,c )



df =dfBetaBTTest (slme ,c )



df =dfBetaFTest (slme ,L )



df =dfBetaBFTest (slme ,L )


end


methods (Abstract =true ,Access =public )
crittable =modelCriterion (slme )
yfit =fitted (slme ,wantConditional )
ysim =random (slme ,S ,Xsim ,Zsim )
C =postCovb (slme )
end


methods (Abstract =true ,Access =protected )
r =getRawResiduals (slme ,wantConditional )
r =getPearsonResiduals (slme ,wantConditional )
r =getStudentizedResiduals (slme ,wantConditional )

C =covEtaHatLogSigmaHat (slme )
C =covBetaHatBHat (slme )
[pred ,varpred ]=getEstimateAndVariance (slme ,Xnew ,Znew ,betaBar ,DeltabBar ,theta ,sigma )
end


methods (Abstract =true ,Access =protected )
FitMethod =validateFitMethod (slme ,FitMethod )
end


methods (Access =protected )
function [X ,y ,Z ,Psi ,FitMethod ]=validateInputs (slme ,X ,y ,Z ,Psi ,FitMethod )






[N ,p ]=size (X ); 
slme .assertThat (isnumeric (X )&isreal (X )&ismatrix (X ),'stats:classreg:regr:lmeutils:StandardLinearLikeMixedModel:BadX' ); 


slme .assertThat (~slme .hasNaNInf (X ),'stats:classreg:regr:lmeutils:StandardLinearLikeMixedModel:NoNaNInfAllowed' ,'X' ); 


slme .assertThat (rank (X )==p ,'stats:classreg:regr:lmeutils:StandardLinearLikeMixedModel:MustBeFullRank_X' ); 


slme .assertThat (isnumeric (y )&isreal (y )&isvector (y ),'stats:classreg:regr:lmeutils:StandardLinearLikeMixedModel:BadY' ,num2str (N )); 
slme .assertThat (all (size (y )==[N ,1 ]),'stats:classreg:regr:lmeutils:StandardLinearLikeMixedModel:BadY' ,num2str (N )); 


slme .assertThat (~slme .hasNaNInf (y ),'stats:classreg:regr:lmeutils:StandardLinearLikeMixedModel:NoNaNInfAllowed' ,'y' ); 


q =size (Z ,2 ); 
slme .assertThat (isnumeric (Z )&isreal (Z )&ismatrix (Z ),'stats:classreg:regr:lmeutils:StandardLinearLikeMixedModel:BadZ' ,num2str (N )); 
slme .assertThat (all (size (Z )==[N ,q ]),'stats:classreg:regr:lmeutils:StandardLinearLikeMixedModel:BadZ' ,num2str (N )); 


slme .assertThat (~slme .hasNaNInf (Z ),'stats:classreg:regr:lmeutils:StandardLinearLikeMixedModel:NoNaNInfAllowed' ,'Z' ); 


if~issparse (Z )
Z =sparse (Z ); 
end


slme .assertThat (isa (Psi ,'classreg.regr.lmeutils.covmats.CovarianceMatrix' ),'stats:classreg:regr:lmeutils:StandardLinearLikeMixedModel:BadPsi' ); 


slme .assertThat (Psi .Size ==q ,'stats:classreg:regr:lmeutils:StandardLinearLikeMixedModel:BadPsi_Size' ,num2str (q )); 


FitMethod =validateFitMethod (slme ,FitMethod ); 


slme .assertThat (N >=2 ,'stats:classreg:regr:lmeutils:StandardLinearLikeMixedModel:BadN' ); 


slme .assertThat (N >=p ,'stats:classreg:regr:lmeutils:StandardLinearLikeMixedModel:BadN_MinN' ,num2str (p )); 

end

function slme =invalidateFit (slme )





slme .isFitToData =false ; 
slme .isReadyForStats =false ; 

end

function X =validateX (slme ,X )



slme .assertThat (isnumeric (X )&isreal (X )&ismatrix (X ),'stats:classreg:regr:lmeutils:StandardLinearLikeMixedModel:InValidX_Size' ,num2str (slme .N ),num2str (slme .p )); 
slme .assertThat (all (size (X )==[slme .N ,slme .p ]),'stats:classreg:regr:lmeutils:StandardLinearLikeMixedModel:InValidX_Size' ,num2str (slme .N ),num2str (slme .p )); 


slme .assertThat (~slme .hasNaNInf (X ),'stats:classreg:regr:lmeutils:StandardLinearLikeMixedModel:NoNaNInfAllowed' ,'X' ); 


slme .assertThat (rank (X )==slme .p ,'stats:classreg:regr:lmeutils:StandardLinearLikeMixedModel:InValidX_Rank' ,num2str (slme .p )); 

end

function y =validatey (slme ,y )


slme .assertThat (isnumeric (y )&isreal (y )&isvector (y ),'stats:classreg:regr:lmeutils:StandardLinearLikeMixedModel:InValidY_Size' ,num2str (slme .N ),num2str (1 )); 
slme .assertThat (all (size (y )==[slme .N ,1 ]),'stats:classreg:regr:lmeutils:StandardLinearLikeMixedModel:InValidY_Size' ,num2str (slme .N ),num2str (1 )); 


slme .assertThat (~slme .hasNaNInf (y ),'stats:classreg:regr:lmeutils:StandardLinearLikeMixedModel:NoNaNInfAllowed' ,'y' ); 

end

function Z =validateZ (slme ,Z )



slme .assertThat (isnumeric (Z )&isreal (Z )&ismatrix (Z ),'stats:classreg:regr:lmeutils:StandardLinearLikeMixedModel:InValidZ_Size' ,num2str (slme .N ),num2str (slme .q )); 
slme .assertThat (all (size (Z )==[slme .N ,slme .q ]),'stats:classreg:regr:lmeutils:StandardLinearLikeMixedModel:InValidZ_Size' ,num2str (slme .N ),num2str (slme .q )); 


slme .assertThat (~slme .hasNaNInf (Z ),'stats:classreg:regr:lmeutils:StandardLinearLikeMixedModel:NoNaNInfAllowed' ,'Z' ); 


if~issparse (Z )
Z =sparse (Z ); 
end

end

function Psi =validatePsi (slme ,Psi )


slme .assertThat (isa (Psi ,'classreg.regr.lmeutils.covmats.CovarianceMatrix' ),'stats:classreg:regr:lmeutils:StandardLinearLikeMixedModel:BadPsi' ); 


slme .assertThat (Psi .Size ==slme .q ,'stats:classreg:regr:lmeutils:StandardLinearLikeMixedModel:BadPsi_Size' ,num2str (slme .q )); 

end

function initializationmethod =validateInitializationMethod (slme ,initializationmethod )

initializationmethod =internal .stats .getParamVal (initializationmethod ,slme .AllowedInitializationMethods ,'InitializationMethod' ); 

end

function theta =validateTheta (slme ,theta )


assert (isnumeric (theta )&isreal (theta )&isvector (theta )); 


assert (all (size (theta )==[slme .Psi .NumParametersExcludingSigma ,1 ])); 


assert (~slme .hasNaNInf (theta )); 

end

function beta =validateBeta (slme ,beta )


assert (isnumeric (beta )&isreal (beta )&isvector (beta )); 


assert (all (size (beta )==[slme .p ,1 ])); 


assert (~slme .hasNaNInf (beta )); 

end

function sigma =validateSigma (slme ,sigma )


assert (isnumeric (sigma )&isreal (sigma )&isscalar (sigma )); 


assert (sigma >0 ); 


assert (~slme .hasNaNInf (sigma )); 

end

function [optimizer ,optimizeroptions ,initializationmethod ]...
    =validateOptimizationOptions (slme ,optimizer ,optimizeroptions ,initializationmethod )


optimizer =internal .stats .getParamVal (optimizer ,slme .AllowedOptimizers ,'Optimizer' ); 


initializationmethod =internal .stats .getParamVal (initializationmethod ,slme .AllowedInitializationMethods ,'InitializationMethod' ); 


slme .assertThat (isstruct (optimizeroptions )||isa (optimizeroptions ,'optim.options.SolverOptions' ),'stats:classreg:regr:lmeutils:StandardGeneralizedLinearMixedModel:BadOptimizerOptions' ); 
switchlower (optimizer )
case 'quasinewton' 

slme .assertThat (isempty (optimizeroptions )||isstruct (optimizeroptions ),'stats:classreg:regr:lmeutils:StandardGeneralizedLinearMixedModel:BadOptimizerOptions_quasinewton' ); 
case {'fminunc' }

slme .assertThat (isempty (optimizeroptions )||isa (optimizeroptions ,'optim.options.SolverOptions' ),'stats:classreg:regr:lmeutils:StandardGeneralizedLinearMixedModel:BadOptimizerOptions_fminunc' ); 
case {'fminsearch' }

slme .assertThat (isempty (optimizeroptions )||isstruct (optimizeroptions ),'stats:classreg:regr:lmeutils:StandardGeneralizedLinearMixedModel:BadOptimizerOptions_fminsearch' ); 
end

end
end


methods (Access =public )

function [P ,T ,DF ]=betaTTest (slme ,c ,e ,dfmethod )










ifsize (c ,1 )==1 
c =c ' ; 
end
assert (all (size (c )==[slme .p ,1 ])); 


assert (all (size (e )==[1 ,1 ])); 



dfmethod =lower (dfmethod ); 
assert (ischar (dfmethod )&isvector (dfmethod )...
    &(size (dfmethod ,1 )==1 )); 
assert (any (strcmpi (dfmethod ,slme .AllowedDFMethods ))); 


switchdfmethod 
case 'none' 
DF =Inf ; 
case 'residual' 
DF =slme .N -slme .rankX ; 
case 'satterthwaite' 
DF =dfBetaTTest (slme ,c ); 
otherwise

error (message ('stats:classreg:regr:lmeutils:StandardLinearLikeMixedModel:BadDFMethod' )); 
end


T =(c ' *slme .betaHat -e )/sqrt (c ' *slme .covbetaHat *c ); 



P =2 *(tcdf (abs (T ),DF ,'upper' )); 

end


function [P ,T ,DF ]=betaBTTest (slme ,t ,s ,e ,dfmethod )










ifsize (t ,1 )==1 
t =t ' ; 
end
assert (all (size (t )==[slme .p ,1 ])); 


ifsize (s ,1 )==1 
s =s ' ; 
end
assert (all (size (s )==[slme .q ,1 ])); 


assert (all (size (e )==[1 ,1 ])); 


c =[t ; s ]; 



dfmethod =lower (dfmethod ); 
assert (ischar (dfmethod )&isvector (dfmethod )...
    &(size (dfmethod ,1 )==1 )); 
assert (any (strcmpi (dfmethod ,slme .AllowedDFMethods ))); 


switchdfmethod 
case 'none' 
DF =Inf ; 
case 'residual' 
DF =slme .N -slme .rankX ; 
case 'satterthwaite' 
DF =dfBetaBTTest (slme ,c ); 
otherwise

error (message ('stats:classreg:regr:lmeutils:StandardLinearLikeMixedModel:BadDFMethod' )); 
end


betaHatbHat =[slme .betaHat ; slme .bHat ]; 






Xnew =t ' ; 
Znew =s ' ; 
[~,ctVc ]=getEstimateAndVariance (slme ,Xnew ,Znew ,slme .betaHat ,...
    slme .DeltabHat ,slme .thetaHat ,slme .sigmaHat ); 
T =(c ' *betaHatbHat -e )/sqrt (ctVc ); 



P =2 *(tcdf (abs (T ),DF ,'upper' )); 

end


function [P ,T ,DF1 ,DF2 ]=betaFTest (slme ,L ,e ,dfmethod )










assert (size (L ,2 )==slme .p ); 


ifsize (e ,1 )==1 
e =e ' ; 
end
assert (all (size (e )==[size (L ,1 ),1 ])); 


ifisempty (L )
P =NaN ; 
T =NaN ; 
DF1 =NaN ; 
DF2 =NaN ; 
return ; 
end










[ok ,~,L ,e ]=slme .fullrankH (L ,e ); 
if~ok 

error (message ('stats:classreg:regr:lmeutils:StandardLinearLikeMixedModel:BadHypothesisMatrix' )); 
end
r =size (L ,1 ); 



dfmethod =lower (dfmethod ); 
assert (ischar (dfmethod )&isvector (dfmethod )...
    &(size (dfmethod ,1 )==1 )); 
assert (any (strcmpi (dfmethod ,slme .AllowedDFMethods ))); 


switchdfmethod 
case 'none' 
DF2 =Inf ; 
case 'residual' 
DF2 =slme .N -slme .rankX ; 
case 'satterthwaite' 
DF2 =dfBetaFTest (slme ,L ); 
otherwise

error (message ('stats:classreg:regr:lmeutils:StandardLinearLikeMixedModel:BadDFMethod' )); 
end


delta =(L *slme .betaHat -e ); 
T =delta ' *((L *slme .covbetaHat *L ' )\delta )/r ; 


DF1 =r ; 



P =fcdf (T ,DF1 ,DF2 ,'upper' ); 

end


function [P ,T ,DF1 ,DF2 ]=betaBFTest (slme ,H ,K ,e ,dfmethod )











assert (size (H ,2 )==slme .p ); 


assert (size (K ,1 )==size (H ,1 )); 
assert (size (K ,2 )==slme .q ); 


L =[H ,K ]; 


ifsize (e ,1 )==1 
e =e ' ; 
end
assert (all (size (e )==[size (H ,1 ),1 ])); 










[ok ,~,L ,e ]=slme .fullrankH (L ,e ); 
if~ok 

error (message ('stats:classreg:regr:lmeutils:StandardLinearLikeMixedModel:BadHypothesisMatrix' )); 
end
r =size (L ,1 ); 



dfmethod =lower (dfmethod ); 
assert (ischar (dfmethod )&isvector (dfmethod )...
    &(size (dfmethod ,1 )==1 )); 
assert (any (strcmpi (dfmethod ,slme .AllowedDFMethods ))); 


switchdfmethod 
case 'none' 
DF2 =Inf ; 
case 'residual' 
DF2 =slme .N -slme .rankX ; 
case 'satterthwaite' 
DF2 =dfBetaBFTest (slme ,L ); 
otherwise

error (message ('stats:classreg:regr:lmeutils:StandardLinearLikeMixedModel:BadDFMethod' )); 
end


betaHatbHat =[slme .betaHat ; slme .bHat ]; 






delta =(L *betaHatbHat -e ); 
p =slme .p ; 
q =slme .q ; 
Xnew =L (:,1 :p ); 
Znew =L (:,p +1 :p +q ); 
[~,LVLt ]=getEstimateAndVariance (slme ,Xnew ,Znew ,slme .betaHat ,...
    slme .DeltabHat ,slme .thetaHat ,slme .sigmaHat ,'covariance' ); 
T =delta ' *(LVLt \delta )/r ; 


DF1 =r ; 



P =fcdf (T ,DF1 ,DF2 ,'upper' ); 

end
end


methods (Access =public )

function [CI ,DF ]=betaCI (slme ,c ,alpha ,dfmethod )











ifsize (c ,1 )==1 
c =c ' ; 
end
assert (all (size (c )==[slme .p ,1 ])); 


assert (isnumeric (alpha )&isreal (alpha )&isscalar (alpha )); 
assert (alpha >=0 &alpha <=1 ); 



dfmethod =lower (dfmethod ); 
assert (ischar (dfmethod )&isvector (dfmethod )...
    &(size (dfmethod ,1 )==1 )); 
assert (any (strcmpi (dfmethod ,slme .AllowedDFMethods ))); 


switchdfmethod 
case 'none' 
DF =Inf ; 
case 'residual' 
DF =slme .N -slme .rankX ; 
case 'satterthwaite' 
DF =dfBetaTTest (slme ,c ); 
otherwise

error (message ('stats:classreg:regr:lmeutils:StandardLinearLikeMixedModel:BadDFMethod' )); 
end


V =slme .covbetaHat ; 


delta =tinv (1 -alpha /2 ,DF )*sqrt (c ' *V *c ); 


ctbetaHat =c ' *slme .betaHat ; 
CI =[ctbetaHat -delta ,ctbetaHat +delta ]; 

end


function [CI ,DF ]=betaBCI (slme ,t ,s ,alpha ,dfmethod )











ifsize (t ,1 )==1 
t =t ' ; 
end
assert (all (size (t )==[slme .p ,1 ])); 


ifsize (s ,1 )==1 
s =s ' ; 
end
assert (all (size (s )==[slme .q ,1 ])); 


c =[t ; s ]; 


assert (isnumeric (alpha )&isreal (alpha )&isscalar (alpha )); 
assert (alpha >=0 &alpha <=1 ); 



dfmethod =lower (dfmethod ); 
assert (ischar (dfmethod )&isvector (dfmethod )...
    &(size (dfmethod ,1 )==1 )); 
assert (any (strcmpi (dfmethod ,slme .AllowedDFMethods ))); 


switchdfmethod 
case 'none' 
DF =Inf ; 
case 'residual' 
DF =slme .N -slme .rankX ; 
case 'satterthwaite' 
DF =dfBetaBTTest (slme ,c ); 
otherwise

error (message ('stats:classreg:regr:lmeutils:StandardLinearLikeMixedModel:BadDFMethod' )); 
end






Xnew =t ' ; 
Znew =s ' ; 
[~,ctVc ]=getEstimateAndVariance (slme ,Xnew ,Znew ,slme .betaHat ,...
    slme .DeltabHat ,slme .thetaHat ,slme .sigmaHat ); 
delta =tinv (1 -alpha /2 ,DF )*sqrt (ctVc ); 


ctbetaHatbHat =c ' *[slme .betaHat ; slme .bHat ]; 
CI =[ctbetaHatbHat -delta ,ctbetaHatbHat +delta ]; 

end
end


methods (Access =public )
function fetable =fixedEffects (slme ,alpha ,dfmethod )

















assert (isnumeric (alpha )&isreal (alpha )&isscalar (alpha )); 
assert (alpha >=0 &alpha <=1 ); 



dfmethod =lower (dfmethod ); 
assert (ischar (dfmethod )&isvector (dfmethod )...
    &(size (dfmethod ,1 )==1 )); 
assert (any (strcmpi (dfmethod ,slme .AllowedDFMethods ))); 


p =slme .p ; 


pred =slme .betaHat ; 
if(p ==0 )

se =zeros (p ,1 ); 
else
se =sqrt (diag (slme .covbetaHat )); 
end


switchdfmethod 
case 'none' 
DF =Inf *ones (p ,1 ); 
case 'residual' 
DF =(slme .N -p )*ones (p ,1 ); 
case 'satterthwaite' 
DF =zeros (p ,1 ); 
Ip =speye (p ); 
fori =1 :p 

c =full (Ip (:,i )); 
DF (i )=dfBetaTTest (slme ,c ); 
end
otherwise
error (message ('stats:classreg:regr:lmeutils:StandardLinearLikeMixedModel:BadDFMethod' )); 
end


T =pred ./se ; 



P =2 *(tcdf (abs (T ),DF ,'upper' )); 


halfwidth =tinv (1 -alpha /2 ,DF ).*se ; 


LB =pred -halfwidth ; 
UB =pred +halfwidth ; 


ifany (isnan (DF ))
error (message ('stats:classreg:regr:lmeutils:StandardLinearLikeMixedModel:ErrorDFCalculation' )); 
end


fetable =table (pred ,se ,T ,DF ,P ,LB ,UB ,'VariableNames' ,{'Estimate' ,'SE' ,...
    'tStat' ,'DF' ,'pValue' ,'Lower' ,'Upper' }); 

end

function retable =randomEffects (slme ,alpha ,dfmethod )

















assert (isnumeric (alpha )&isreal (alpha )&isscalar (alpha )); 
assert (alpha >=0 &alpha <=1 ); 



dfmethod =lower (dfmethod ); 
assert (ischar (dfmethod )&isvector (dfmethod )...
    &(size (dfmethod ,1 )==1 )); 
assert (any (strcmpi (dfmethod ,slme .AllowedDFMethods ))); 


p =slme .p ; 
q =slme .q ; 




Xnew =sparse (q ,p ); 
Znew =speye (q ); 
[pred ,varpred ]=getEstimateAndVariance (slme ,Xnew ,Znew ,slme .betaHat ,slme .DeltabHat ,slme .thetaHat ,slme .sigmaHat ); 
se =sqrt (varpred ); 


switchdfmethod 
case 'none' 
DF =Inf *ones (q ,1 ); 
case 'residual' 
DF =(slme .N -slme .p )*ones (q ,1 ); 
case 'satterthwaite' 
DF =zeros (q ,1 ); 
fori =1 :q 

c =full ([Xnew (i ,:),Znew (i ,:)])' ; 
DF (i )=dfBetaBTTest (slme ,c ); 
end
otherwise
error (message ('stats:classreg:regr:lmeutils:StandardLinearLikeMixedModel:BadDFMethod' )); 
end


T =pred ./se ; 



P =2 *(tcdf (abs (T ),DF ,'upper' )); 


halfwidth =tinv (1 -alpha /2 ,DF ).*se ; 


LB =pred -halfwidth ; 
UB =pred +halfwidth ; 


ifany (isnan (DF ))
error (message ('stats:classreg:regr:lmeutils:StandardLinearLikeMixedModel:ErrorDFCalculation' )); 
end


retable =table (pred ,se ,T ,DF ,P ,LB ,UB ,'VariableNames' ,{'Estimate' ,'SEPred' ,...
    'tStat' ,'DF' ,'pValue' ,'Lower' ,'Upper' }); 

end

function predtable =predictTable (slme ,Xnew ,Znew ,alpha ,dfmethod )



















assert (isnumeric (Xnew )&isreal (Xnew )&ismatrix (Xnew )); 
assert (size (Xnew ,2 )==slme .p ); 


assert (isnumeric (Znew )&isreal (Znew )&ismatrix (Znew )); 
assert (size (Znew ,2 )==slme .q ); 


assert (size (Xnew ,1 )==size (Znew ,1 )); 


assert (isnumeric (alpha )&isreal (alpha )&isscalar (alpha )); 
assert (alpha >=0 &alpha <=1 ); 



dfmethod =lower (dfmethod ); 
assert (ischar (dfmethod )&isvector (dfmethod )...
    &(size (dfmethod ,1 )==1 )); 
assert (any (strcmpi (dfmethod ,slme .AllowedDFMethods ))); 


M =size (Xnew ,1 ); 


V =covBetaHatBHat (slme ); 


betaHat =slme .betaHat ; 
bHat =slme .bHat ; 


ypred =Xnew *betaHat +Znew *bHat ; 


Alpha =alpha *ones (M ,1 ); 


SEPred =zeros (M ,1 ); 
DF =zeros (M ,1 ); 
LB =zeros (M ,1 ); 
UB =zeros (M ,1 ); 
fori =1 :M 



t =Xnew (i ,:)' ; 
s =Znew (i ,:)' ; 
[CI0 ,DF0 ]=betaBCI (slme ,t ,s ,alpha ,dfmethod ); 
LB (i )=CI0 (1 ); 
UB (i )=CI0 (2 ); 
DF (i )=DF0 ; 


c =[t ; s ]; 
SEPred (i )=sqrt (c ' *V *c ); 
end


ifany (isnan (DF ))

error (message ('stats:classreg:regr:lmeutils:StandardLinearLikeMixedModel:ErrorDFCalculation' )); 
end


predtable =table (ypred ,SEPred ,DF ,Alpha ,LB ,UB ,'VariableNames' ,{'Pred' ,'SEPred' ,'DF' ,'Alpha' ,'Lower' ,'Upper' }); 
end

function [ypred ,CI ,DF ]=predict (slme ,Xnew ,Znew ,alpha ,dfmethod ,wantConditional ,wantPointwise ,wantCurve ,hasIntercept )



























assert (isnumeric (Xnew )&isreal (Xnew )&ismatrix (Xnew )); 
assert (size (Xnew ,2 )==slme .p ); 


assert (isnumeric (Znew )&isreal (Znew )&ismatrix (Znew )); 
assert (size (Znew ,2 )==slme .q ); 


assert (size (Xnew ,1 )==size (Znew ,1 )); 


assert (isnumeric (alpha )&isreal (alpha )&isscalar (alpha )); 
assert (alpha >=0 &alpha <=1 ); 



dfmethod =lower (dfmethod ); 
assert (ischar (dfmethod )&isvector (dfmethod )...
    &(size (dfmethod ,1 )==1 )); 
assert (any (strcmpi (dfmethod ,slme .AllowedDFMethods ))); 


assert (isscalar (wantConditional )&islogical (wantConditional )); 


assert (isscalar (wantPointwise )&islogical (wantPointwise )); 


assert (isscalar (wantCurve )&islogical (wantCurve )); 


assert (isscalar (hasIntercept )&islogical (hasIntercept )); 


if(wantConditional ==true )
ypred =Xnew *slme .betaHat +Znew *slme .bHat ; 
else
ypred =Xnew *slme .betaHat ; 
end

ifnargout >1 















if(wantConditional ==true )
C =[Xnew ,Znew ]; 




[~,varpred ]=getEstimateAndVariance (slme ,Xnew ,Znew ,slme .betaHat ,slme .DeltabHat ,slme .thetaHat ,slme .sigmaHat ); 
else
C =Xnew ; 
V =slme .covbetaHat ; 
varpred =sum (C .*(C *V ' ),2 ); 
end



if(wantCurve ==false )
varpred =varpred +(slme .sigmaHat )^2 ; 
end



M =size (Xnew ,1 ); 
rankX =slme .rankX ; 
q =slme .q ; 



if(wantPointwise ==true )

switchdfmethod 
case 'none' 
DF =Inf *ones (M ,1 ); 
case 'residual' 
DF =(slme .N -rankX )*ones (M ,1 ); 
case 'satterthwaite' 
DF =zeros (M ,1 ); 
fori =1 :M 
if(wantConditional ==true )
DF (i )=dfBetaBTTest (slme ,C (i ,:)); 
else
DF (i )=dfBetaTTest (slme ,C (i ,:)); 
end
end
otherwise

error (message ('stats:classreg:regr:lmeutils:StandardLinearLikeMixedModel:BadDFMethod' )); 
end

crit =tinv (1 -alpha /2 ,DF ); 
else

switchdfmethod 
case 'none' 
DF =Inf ; 
case 'residual' 
DF =(slme .N -rankX ); 
case 'satterthwaite' 
if(wantConditional ==true )
DF =dfBetaBFTest (slme ,eye (rankX +q )); 
else
DF =dfBetaFTest (slme ,eye (rankX )); 
end
otherwise

error (message ('stats:classreg:regr:lmeutils:StandardLinearLikeMixedModel:BadDFMethod' )); 
end



if(wantConditional ==true )
if(wantCurve ==true )
numDF =rankX +q ; 
else
ifhasIntercept 
numDF =rankX +q ; 
else
numDF =rankX +q +1 ; 
end
end
else
if(wantCurve ==true )
numDF =rankX ; 
else
ifhasIntercept 
numDF =rankX ; 
else
numDF =rankX +1 ; 
end
end
end


crit =sqrt (numDF *finv (1 -alpha ,numDF ,DF )); 
end


delta =crit .*sqrt (varpred ); 
CI =[ypred -delta ,ypred +delta ]; 
end

end
end


methods (Access =public )
function slme =storeCovBetaHatBHat (slme )





slme .covbetaHatbHat =covBetaHatBHat (slme ); 

end

function slme =unstoreCovBetaHatBHat (slme )






slme .covbetaHatbHat =[]; 

end
end


methods (Access =public )
function r =residuals (slme ,wantConditional ,residualType )










assert (isscalar (wantConditional )&islogical (wantConditional )); 



residualType =lower (residualType ); 
assert (ischar (residualType )&isvector (residualType )...
    &(size (residualType ,1 )==1 )); 
assert (any (strcmpi (residualType ,slme .AllowedResidualTypes ))); 


switchresidualType 
case 'raw' 
r =getRawResiduals (slme ,wantConditional ); 
case 'pearson' 
r =getPearsonResiduals (slme ,wantConditional ); 
case 'standardized' 


r =getStudentizedResiduals (slme ,wantConditional ); 
otherwise
error (message ('stats:classreg:regr:lmeutils:StandardLinearLikeMixedModel:BadResidualType' )); 
end

end
end


methods (Access =public )

function covtable =covarianceParameters (slme ,alpha ,wantCIs )
















ifnargin <3 
wantCIs =true ; 
end


assert (isnumeric (alpha )&isreal (alpha )&isscalar (alpha )); 
assert (alpha >=0 &alpha <=1 ); 


hetaHat =slme .Psi .getCanonicalParameters ; 


sigmaHat =slme .sigmaHat ; 


x =[hetaHat ; sigmaHat ]; 


covtable =table (x ,'VariableNames' ,{'Estimate' }); 




ifwantCIs ==true 
try
CI =hetaSigmaCI (slme ,alpha ); 
covtable .Lower =CI (:,1 ); 
covtable .Upper =CI (:,2 ); 
catch ME 
msgID ='stats:classreg:regr:lmeutils:StandardLinearLikeMixedModel:Message_TooManyCovarianceParameters' ; 
msgStr =getString (message (msgID )); 
baseME =MException (msgID ,msgStr ); 
ME =addCause (baseME ,ME ); 
warning ('stats:classreg:regr:lmeutils:StandardLinearLikeMixedModel:Message_TooManyCovarianceParameters' ,ME .message ); 
end
end

end


function CI =etaLogSigmaCI (slme ,alpha )









assert (isnumeric (alpha )&isreal (alpha )&isscalar (alpha )); 
assert (alpha >=0 &alpha <=1 ); 


etaHat =getNaturalParameters (slme .Psi ); 
sigmaHat =slme .sigmaHat ; 
x =[etaHat ; log (sigmaHat )]; 



C =slme .covetaHatlogsigmaHat ; 
ifisempty (C )
C =covEtaHatLogSigmaHat (slme ); 
end





delta =-norminv (alpha /2 )*sqrt (diag (C )); 
CI =[x -delta ,x +delta ]; 

end


function CI =hetaSigmaCI (slme ,alpha )









assert (isnumeric (alpha )&isreal (alpha )&isscalar (alpha )); 
assert (alpha >=0 &alpha <=1 ); 


CI0 =etaLogSigmaCI (slme ,alpha ); 


Psi =slme .Psi ; 




eta_lb =CI0 (1 :end-1 ,1 ); 
logsigma_lb =CI0 (end,1 ); 
sigma_lb =exp (logsigma_lb ); 
Psi =setNaturalParameters (Psi ,eta_lb ); 
Psi =setSigma (Psi ,sigma_lb ); 
heta_lb =getCanonicalParameters (Psi ); 


eta_ub =CI0 (1 :end-1 ,2 ); 
logsigma_ub =CI0 (end,2 ); 
sigma_ub =exp (logsigma_ub ); 
Psi =setNaturalParameters (Psi ,eta_ub ); 
Psi =setSigma (Psi ,sigma_ub ); 
heta_ub =getCanonicalParameters (Psi ); 


CI (:,1 )=[heta_lb ; sigma_lb ]; 
CI (:,2 )=[heta_ub ; sigma_ub ]; 

end
end


methods (Access =public )
function bsim =randomb (slme ,S ,NumReps )



















Psi =slme .Psi ; 


SizeVec =Psi .SizeVec ; 
NumBlocks =Psi .NumBlocks ; 


assert (isnumeric (NumReps )&isreal (NumReps )...
    &isvector (NumReps )&length (NumReps )==NumBlocks ); 


ifsize (NumReps ,1 )==1 
NumReps =NumReps ' ; 
end







bsim =zeros (sum (SizeVec .*NumReps ),1 ); 




if~isempty (bsim )
offset =0 ; 
forr =1 :NumBlocks 

Lr =getLowerTriangularCholeskyFactor (Psi .Matrices {r }); 
sigmar =getSigma (Psi ); 
PSIr =(sigmar ^2 )*(Lr *Lr ' ); 


mur =zeros (1 ,SizeVec (r )); 


Nr =NumReps (r ); 


ifisempty (S )

temp =mvnrnd (mur ,PSIr ,Nr )' ; 


else


temp =slme .mymvnrnd (S ,mur ,PSIr ,Nr )' ; 
end



bsim (offset +1 :offset +SizeVec (r )*NumReps (r ))=temp (:); 


offset =offset +SizeVec (r )*NumReps (r ); 
end
end

end

function slme =turnOffOptimizerDisplay (slme )







switchlower (slme .Optimizer )
case 'quasinewton' 
slme .OptimizerOptions .Display ='off' ; 
case 'fminunc' 
slme .OptimizerOptions .Display ='off' ; 
case 'fminsearch' 
slme .OptimizerOptions .Display ='off' ; 
otherwise
error (message ('stats:classreg:regr:lmeutils:StandardGeneralizedLinearMixedModel:BadOptimizerName' )); 
end

end
end


methods (Access =protected )
function [thetaHat ,cause ]=doMinimization (slme ,fun ,theta0 )






















switchlower (slme .Optimizer )
case 'quasinewton' 


[thetaHat ,~,~,cause ]=...
    fminqn (fun ,theta0 ,'Options' ,slme .OptimizerOptions ); 




case 'fminunc' 













[thetaHat ,~,exitflag ]=...
    fminunc (fun ,theta0 ,slme .OptimizerOptions ); 


switchexitflag 
case 1 

cause =0 ; 
case {2 ,3 ,5 }

cause =1 ; 
otherwise

cause =2 ; 
end

case 'fminsearch' 


[thetaHat ,~,exitflag ]=...
    fminsearch (fun ,theta0 ,slme .OptimizerOptions ); 


switchexitflag 
case 1 





cause =0 ; 
otherwise

cause =2 ; 
end

otherwise

error (message ('stats:classreg:regr:lmeutils:StandardLinearMixedModel:BadOptimizerName' )); 
end

end
end


methods (Static )
function C =covarianceOnNaturalScale (H )









C =pinv (H ); 




sizeH =size (H ,1 ); 
F =internal .stats .isEstimable (eye (sizeH ),'NormalMatrix' ,H ,'TolSVD' ,sqrt (eps (class (H )))); 




diagC =diag (C ); 
F (diagC <0 )=false ; 


C (~F ,:)=NaN ; 
C (:,~F )=NaN ; 

end

function [ok ,p ,H ,C ]=fullrankH (H ,C )


















[~,r ,e ]=qr (H ' ,0 ); 
tol =eps (norm (H ))^(3 /4 ); 
p =sum (abs (diag (r ))>max (size (H ))*tol *abs (r (1 ,1 ))); 


E =e (1 :max (1 ,p )); 


b =H (E ,:)\C (E ); 


ok =all (abs (H *b -C )<tol ); 


H =H (E ,:); 
C =C (E ); 

end

function g =getGradient (fun ,theta ,step )








if(nargin ==2 )
step =eps ^(1 /3 ); 
end


p =length (theta ); 
g =zeros (p ,1 ); 
fori =1 :p 

theta1 =theta ; 
theta1 (i )=theta1 (i )-step ; 

theta2 =theta ; 
theta2 (i )=theta2 (i )+step ; 

g (i )=(fun (theta2 )-fun (theta1 ))/2 /step ; 
end

end

function H =getHessian2 (fun ,theta ,wantRegularized )











step =eps ^(1 /4 ); 


p =length (theta ); 
H =zeros (p ,p ); %#ok<*PROP> 
fori =1 :p 

theta1 =theta ; 
theta1 (i )=theta1 (i )-step ; 

theta2 =theta ; 
theta2 (i )=theta2 (i )+step ; 

H (:,i )=(classreg .regr .lmeutils .StandardLinearLikeMixedModel .getGradient (fun ,theta2 ,step )...
    -classreg .regr .lmeutils .StandardLinearLikeMixedModel .getGradient (fun ,theta1 ,step ))/2 /step ; 
end

if(nargin ==3 &&wantRegularized )
lambda =eig (H ); 
if~all (lambda >0 )

delta =abs (min (lambda ))+sqrt (eps ); 

H =H +delta *eye (size (H )); 
end
end

end

function H =getHessian (fun ,theta ,wantRegularized )









step =eps ^(1 /4 ); 


p =length (theta ); 
H =zeros (p ,p ); 
funtheta =fun (theta ); 
denom =4 *(step ^2 ); 


fori =1 :p 
forj =i :p 

if(j ==i )

theta2 =theta ; 
theta2 (i )=theta2 (i )+2 *step ; 

theta1 =theta ; 
theta1 (i )=theta1 (i )-2 *step ; 

H (i ,j )=(fun (theta2 )+fun (theta1 )-2 *funtheta )/denom ; 
else

theta4 =theta ; 
theta4 (i )=theta4 (i )+step ; 
theta4 (j )=theta4 (j )+step ; 

theta3 =theta ; 
theta3 (i )=theta3 (i )-step ; 
theta3 (j )=theta3 (j )+step ; 

theta2 =theta ; 
theta2 (i )=theta2 (i )+step ; 
theta2 (j )=theta2 (j )-step ; 

theta1 =theta ; 
theta1 (i )=theta1 (i )-step ; 
theta1 (j )=theta1 (j )-step ; 

H (i ,j )=(fun (theta4 )+fun (theta1 )-fun (theta3 )-fun (theta2 ))/denom ; 
end
end
end


H =triu (H ,1 )' +H ; 


if(nargin ==3 &&wantRegularized )
lambda =eig (H ); 
if~all (lambda >0 )

delta =abs (min (lambda ))+sqrt (eps ); 

H =H +delta *eye (size (H )); 
end
end

end

function R =mymvnrnd (S ,MU ,SIGMA ,N )





























































p =size (MU ,2 ); 
assert (p ==size (SIGMA ,1 )); 
assert (p ==size (SIGMA ,2 )); 


T =cholcov (SIGMA ); 


ifisempty (S )

R =bsxfun (@plus ,MU ,randn (N ,p )*T ); 
else

assert (isa (S ,'RandStream' )); 
R =bsxfun (@plus ,MU ,randn (S ,N ,p )*T ); 
end

end

function tf =hasNaNInf (X )




tf =any (any (isnan (X )))||any (any (isinf (X ))); 

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

function x =logAbsDetTriangular (R )














x =sum (log (abs (diag (R )))); 

end

function checkPositiveDefinite (H ,msgID ,varargin )








try
chol (H ); 
catch ME %#ok<NASGU>  

msg =message (msgID ,varargin {:}); 
msgStr =getString (msg ); 


hasNaN =any (isnan (H (:))); 
hasInf =any (isinf (H (:))); 



if~hasNaN &&~hasInf 
mineigH =min (eig (H )); 

eigmsgStr =getString (message ('stats:classreg:regr:lmeutils:StandardLinearLikeMixedModel:Message_MinEig' ,num2str (mineigH ))); 
msgStr =[msgStr ,' ' ,eigmsgStr ]; 
else

naninfmsgStr =getString (message ('stats:classreg:regr:lmeutils:StandardLinearLikeMixedModel:Message_NaNInfInHessian' )); 
msgStr =[msgStr ,' ' ,naninfmsgStr ]; 
end

warning (msg .Identifier ,msgStr ); 
end

end

function mu =constrainVector (mu ,a ,b )




assert (a <b ); 
mu (mu <a )=a ; 
mu (mu >b )=b ; 

end

function p =solveUsingQR (J ,r )



















































assert (isnumeric (J )&isreal (J )&ismatrix (J )); 
assert (isnumeric (r )&isreal (r )&iscolumn (r )); 
q =size (J ,1 ); 
assert (size (r ,1 )==q ); 


[Q ,R ,e ]=qr (J ,'vector' ); 


diagR =diag (R ); 
tol =max (abs (diagR ))*sqrt (eps (class (diagR ))); 
idx =find (abs (diagR )>tol ); 


ifisempty (idx )

p =zeros (q ,1 ); 
else

Q1 =Q (:,idx ); 
R11 =R (idx ,idx ); 


pE1 =-(R11 \(Q1 ' *r )); 
m =length (idx ); 
pE2 =zeros (q -m ,1 ); 
pE =[pE1 ; pE2 ]; 


p =zeros (q ,1 ); 
p (e )=pE ; 
end

end
end

end

