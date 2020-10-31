function [B ,stats ]=lassoglm (x ,y ,distr ,varargin )































































































































































































ifnargin >2 
distr =convertStringsToChars (distr ); 
end

ifnargin >3 
[varargin {:}]=convertStringsToChars (varargin {:}); 
end

ifnargin <2 
error (message ('stats:lassoGlm:TooFewInputs' )); 
end

ifnargin <3 ||isempty (distr ),distr ='normal' ; end

paramNames ={'link' ,'offset' ,'weights' }; 
paramDflts ={'canonical' ,[],[]}; 
[link ,offset ,pwts ,~,varargin ]=...
    internal .stats .parseArgs (paramNames ,paramDflts ,varargin {:}); 


LRdefault =1e-4 ; 
pnames ={'alpha' ,'numlambda' ,'lambdaratio' ,'lambda' ...
    ,'dfmax' ,'standardize' ,'reltol' ,'cv' ,'mcreps' ,'maxiter' ...
    ,'predictornames' ,'options' }; 
dflts ={1 ,100 ,LRdefault ,[]...
    ,[],true ,1e-4 ,'resubstitution' ,1 ,1e4 ...
    ,{},[]}; 
[alpha ,nLambda ,lambdaRatio ,lambda ,...
    dfmax ,standardize ,reltol ,cvp ,mcreps ,maxIter ,predictorNames ,parallelOptions ]...
    =internal .stats .parseArgs (pnames ,dflts ,varargin {:}); 

if~isempty (lambda )
userSuppliedLambda =true ; 
else
userSuppliedLambda =false ; 
end


if~ismatrix (x )||length (size (x ))~=2 ||~isreal (x )
error (message ('stats:lassoGlm:XnotaReal2DMatrix' )); 
end


ifisempty (x )||size (x ,1 )<2 
error (message ('stats:lassoGlm:TooFewObservations' )); 
end


ifisa (y ,'categorical' )
[y ,classname ]=grp2idx (y ); 
nc =length (classname ); 
ifnc >2 
error (message ('stats:glmfit:TwoLevelCategory' )); 
end
y (y ==1 )=0 ; 
y (y ==2 )=1 ; 
end


P =size (x ,2 ); 


wsIllConditioned2 =warning ('off' ,'stats:glmfit:IllConditioned' ); 
cleanupIllConditioned2 =onCleanup (@()warning (wsIllConditioned2 )); 




[X ,Y ,offset ,pwts ,dataClass ,nTrials ,binomialTwoColumn ]=...
    glmProcessData (x ,y ,distr ,'off' ,offset ,pwts ); 

[~,sqrtvarFun ,devFun ,linkFun ,dlinkFun ,ilinkFun ,link ,mu ,eta ,muLims ,isCanonical ,dlinkFunCanonical ]=...
    glmProcessDistrAndLink (Y ,distr ,link ,'off' ,nTrials ,dataClass ); 

[X ,Y ,pwts ,nLambda ,lambda ,dfmax ,cvp ,mcreps ,predictorNames ,ever_active ]=...
    processLassoParameters (X ,Y ,pwts ,alpha ,nLambda ,lambdaRatio ,lambda ,dfmax ,...
    standardize ,reltol ,cvp ,mcreps ,predictorNames ); 


[lambdaMax ,nullDev ,nullIntercept ]=computeLambdaMax (X ,Y ,pwts ,alpha ,standardize ,...
    distr ,link ,dlinkFun ,offset ,isCanonical ,dlinkFunCanonical ,devFun ); 



ifisempty (lambda )
lambda =computeLambdaSequence (lambdaMax ,nLambda ,lambdaRatio ,LRdefault ); 
end



ifstrcmp (distr ,'binomial' )
muLims =[1.0e-5 ,1.0 -1.0e-5 ]; 
end




ifisempty (pwts )&&isscalar (nTrials )
totalWeight =size (X ,1 ); 
elseif~isempty (pwts )&&isscalar (nTrials )
totalWeight =sum (pwts ); 
elseifisempty (pwts )&&~isscalar (nTrials )
totalWeight =sum (nTrials ); 
else
totalWeight =sum (pwts .*nTrials ); 
end


lambda =lambda *totalWeight ; 

penalizedFitPartition =@(x ,y ,offset ,pwts ,n ,wlsfit ,b ,active ,mu ,eta ,sqrtvarFun )...
    glmIRLSwrapper (x ,y ,distr ,offset ,pwts ,dataClass ,n ,...
    sqrtvarFun ,linkFun ,dlinkFun ,ilinkFun ,devFun ,b ,active ,mu ,muLims ,wlsfit ,nullDev ,reltol ); 

penalizedFit =@(x ,y ,wlsfit ,b ,active ,mu ,eta )...
    penalizedFitPartition (x ,y ,offset ,pwts ' ,nTrials ,wlsfit ,b ,active ,mu ,eta ,sqrtvarFun ); 

[B ,Intercept ,lambda ,deviance ]=...
    lassoFit (X ,Y ,pwts ,lambda ,alpha ,dfmax ,standardize ,reltol ,maxIter ,lambdaMax *totalWeight ,ever_active ,...
    penalizedFit ,mu ,eta ,dataClass ,userSuppliedLambda ,nullDev ,nullIntercept ); 


df =sum (B ~=0 ,1 ); 




stats =struct (); 
stats .Intercept =[]; 
stats .Lambda =[]; 
stats .Alpha =alpha ; 
stats .DF =[]; 
stats .Deviance =[]; 
stats .PredictorNames =predictorNames ; 






if~isequal (cvp ,'resubstitution' )





cvfun =@(Xtrain ,Ytrain ,Xtest ,Ytest )lassoFitAndPredict (...
    Xtrain ,Ytrain ,Xtest ,Ytest ,...
    lambda ,alpha ,P ,standardize ,reltol ,maxIter ,ever_active ,...
    penalizedFitPartition ,distr ,link ,linkFun ,dlinkFun ,sqrtvarFun ,...
    isCanonical ,dlinkFunCanonical ,devFun ,dataClass ); 
weights =pwts ; 
ifisempty (weights )
weights =nan (size (X ,1 ),1 ); 
end
ifisempty (offset )||isequal (offset ,0 )
offset =nan (size (X ,1 ),1 ); 
end
ifbinomialTwoColumn 
response =[nTrials ,Y ]; 
else
response =Y ; 
end
cvDeviance =crossval (cvfun ,[weights (:),offset (:),X ],response ,...
    'Partition' ,cvp ,'Mcreps' ,mcreps ,'Options' ,parallelOptions ); 

cvDeviance =bsxfun (@times ,cvDeviance ,repmat ((size (X ,1 )./cvp .TestSize )' ,mcreps ,1 )); 
deviance =mean (cvDeviance ); 
se =std (cvDeviance )/sqrt (size (cvDeviance ,1 )); 
minDeviance =min (deviance ); 
minIx =find (deviance ==minDeviance ,1 ); 
lambdaMin =lambda (minIx ); 
minplus1 =deviance (minIx )+se (minIx ); 
seIx =find ((deviance (1 :minIx )<=minplus1 ),1 ,'first' ); 
ifisempty (seIx )
lambdaSE =[]; 
else
lambdaSE =lambda (seIx ); 
end


stats .SE =se ; 
stats .LambdaMinDeviance =lambdaMin ; 
stats .Lambda1SE =lambdaSE ; 
stats .IndexMinDeviance =minIx ; 
stats .Index1SE =seIx ; 



stats .LambdaMinDeviance =stats .LambdaMinDeviance /totalWeight ; 
stats .Lambda1SE =stats .Lambda1SE /totalWeight ; 
end





nLambda =length (lambda ); 
reverseIndices =nLambda :-1 :1 ; 
lambda =lambda (reverseIndices ); 
lambda =reshape (lambda ,1 ,nLambda ); 
B =B (:,reverseIndices ); 
Intercept =Intercept (reverseIndices ); 
df =df (reverseIndices ); 
deviance =deviance (reverseIndices ); 
if~isequal (cvp ,'resubstitution' )
stats .SE =stats .SE (reverseIndices ); 
stats .IndexMinDeviance =nLambda -stats .IndexMinDeviance +1 ; 
stats .Index1SE =nLambda -stats .Index1SE +1 ; 
end

stats .Intercept =Intercept ; 
stats .Lambda =lambda ; 
stats .DF =df ; 
stats .Deviance =deviance ; 


stats .Lambda =stats .Lambda /totalWeight ; 

end









function mu =startingVals (distr ,y ,N )

switchdistr 
case 'poisson' 
mu =y +0.25 ; 
case 'binomial' 
mu =(N .*y +0.5 )./(N +1 ); 
case {'gamma' ,'inverse gaussian' }
mu =max (y ,eps (class (y ))); 
otherwise
mu =y ; 
end
end





function diagnoseSeparation (eta ,y ,N )

[x ,idx ]=sort (eta ); 
if~isscalar (N )
N =N (idx ); 
end
p =y (idx ); 
ifall (p ==p (1 ))
return 
end
ifx (1 )==x (end)
return 
end

noFront =0 <p (1 )&&p (1 )<1 ; 
noEnd =0 <p (end)&&p (end)<1 ; 
ifp (1 )==p (end)||(noFront &&noEnd )


return 
end












dx =100 *max (eps (x (1 )),eps (x (end))); 
n =length (p ); 
ifnoFront 
A =0 ; 
else
A =find (p ~=p (1 ),1 ,'first' )-1 ; 
cutoff =x (A +1 )-dx ; 
A =sum (x (1 :A )<cutoff ); 
end

ifnoEnd 
B =n +1 ; 
else
B =find (p ~=p (end),1 ,'last' )+1 ; 
cutoff =x (B -1 )+dx ; 
B =(n +1 )-sum (x (B :end)>cutoff ); 
end

ifA +1 <B -1 

ifx (B -1 )-x (A +1 )>dx 
return 
end
end


ifA +1 ==B 
xmid =x (A )+0.5 *(x (B )-x (A )); 
else
xmid =x (A +1 ); 
ifisscalar (N )
pmid =mean (p (A +1 :B -1 )); 
else
pmid =sum (p (A +1 :B -1 ).*N (A +1 :B -1 ))/sum (N (A +1 :B -1 )); 
end
end


ifA >=1 
explanation =sprintf ('\n   XB<%g: P=%g' ,xmid ,p (1 )); 
else
explanation ='' ; 
end


ifA +1 <B 
explanation =sprintf ('%s\n   XB=%g: P=%g' ,explanation ,xmid ,pmid ); 
end


ifB <=n 
explanation =sprintf ('%s\n   XB>%g: P=%g' ,explanation ,xmid ,p (end)); 
end

warning (message ('stats:lassoGlm:PerfectSeparation' ,explanation )); 
end





function [x ,y ,offset ,pwts ,dataClass ,N ,binomialTwoColumn ]=...
    glmProcessData (x ,y ,distr ,const ,offset ,pwts )

N =[]; 
binomialTwoColumn =false ; 


ifstrcmp (distr ,'binomial' )
ifsize (y ,2 )==1 

ifany (y <0 |y >1 )
error (message ('stats:lassoGlm:BadDataBinomialFormat' )); 
end
elseifsize (y ,2 )==2 
binomialTwoColumn =true ; 
y (y (:,2 )==0 ,2 )=NaN ; 
N =y (:,2 ); 
y =y (:,1 )./N ; 
ifany (y <0 |y >1 )
error (message ('stats:lassoGlm:BadDataBinomialRange' )); 
end
else
error (message ('stats:lassoGlm:MatrixOrBernoulliRequired' )); 
end
end

[anybad ,~,y ,x ,offset ,pwts ,N ]=dfswitchyard ('statremovenan' ,y ,x ,offset ,pwts ,N ); 
ifanybad >0 
switchanybad 
case 2 
error (message ('stats:lassoGlm:InputSizeMismatchX' ))
case 3 
error (message ('stats:lassoGlm:InputSizeMismatchOffset' ))
case 4 
error (message ('stats:lassoGlm:InputSizeMismatchPWTS' ))
end
end


okrows =all (isfinite (x ),2 )&all (isfinite (y ),2 )&all (isfinite (offset )); 

if~isempty (pwts )

if~isvector (pwts )||~isreal (pwts )||size (x ,1 )~=length (pwts )||...
    ~all (isfinite (pwts ))||any (pwts <0 )
error (message ('stats:lassoGlm:InvalidObservationWeights' )); 
end
okrows =okrows &pwts (:)>0 ; 
pwts =pwts (okrows ); 
end


ifsum (okrows )<2 
error (message ('stats:lassoGlm:TooFewObservationsAfterNaNs' )); 
end



x =x (okrows ,:); 
y =y (okrows ); 
if~isempty (N )&&~isscalar (N )
N =N (okrows ); 
end
if~isempty (offset )
offset =offset (okrows ); 
end

ifisequal (const ,'on' )
x =[ones (size (x ,1 ),1 ),x ]; 
end
dataClass =superiorfloat (x ,y ); 
x =cast (x ,dataClass ); 
y =cast (y ,dataClass ); 

ifisempty (offset ),offset =0 ; end
ifisempty (N ),N =1 ; end

end





function [X ,Y ,weights ,nLambda ,lambda ,dfmax ,cvp ,mcreps ,predictorNames ,ever_active ]=...
    processLassoParameters (X ,Y ,weights ,alpha ,nLambda ,lambdaRatio ,lambda ,dfmax ,...
    standardize ,reltol ,cvp ,mcreps ,predictorNames )


if~isempty (weights )


weights =weights (:)' ; 

end

[~,P ]=size (X ); 




constantPredictors =(range (X )==0 ); 
ever_active =~constantPredictors ; 





if~isscalar (alpha )||~isreal (alpha )||~isfinite (alpha )||...
    alpha <=0 ||alpha >1 
error (message ('stats:lassoGlm:InvalidAlpha' ))
end




if~isscalar (standardize )||(~islogical (standardize )&&standardize ~=0 &&standardize ~=1 )
error (message ('stats:lassoGlm:InvalidStandardize' ))
end



if~isempty (lambda )


if~isreal (lambda )||any (lambda <0 )
error (message ('stats:lassoGlm:NegativeLambda' )); 
end

lambda =sort (lambda (:),1 ,'descend' ); 

else


if~isreal (nLambda )||~isfinite (nLambda )||nLambda <1 
error (message ('stats:lassoGlm:InvalidNumLambda' )); 
else
nLambda =floor (nLambda ); 
end


if~isreal (lambdaRatio )||lambdaRatio <0 ||lambdaRatio >=1 
error (message ('stats:lassoGlm:InvalidLambdaRatio' )); 
end
end



if~isscalar (reltol )||~isreal (reltol )||~isfinite (reltol )||reltol <=0 ||reltol >=1 
error (message ('stats:lassoGlm:InvalidRelTol' )); 
end






ifisempty (dfmax )
dfmax =P ; 
else
if~isscalar (dfmax )
error (message ('stats:lassoGlm:DFmaxBadType' )); 
end
try
dfmax =uint32 (dfmax ); 
catch ME 
mm =message ('stats:lassoGlm:DFmaxBadType' ); 
throwAsCaller (MException (mm .Identifier ,'%s' ,getString (mm ))); 
end
ifdfmax <1 
error (message ('stats:lassoGlm:DFmaxNotAnIndex' )); 
else
dfmax =min (dfmax ,P ); 
end
end



if~isscalar (mcreps )||~isreal (mcreps )||~isfinite (mcreps )||mcreps <1 
error (message ('stats:lassoGlm:MCRepsBadType' )); 
end
mcreps =fix (mcreps ); 




ifisnumeric (cvp )&&isscalar (cvp )&&(cvp ==round (cvp ))&&(0 <cvp )

if(cvp >size (X ,1 ))
error (message ('stats:lassoGlm:InvalidCVforX' )); 
end
cvp =cvpartition (size (X ,1 ),'Kfold' ,cvp ); 
elseifisa (cvp ,'cvpartition' )
ifstrcmpi (cvp .Type ,'resubstitution' )
cvp ='resubstitution' ; 
elseifstrcmpi (cvp .Type ,'leaveout' )
error (message ('stats:lassoGlm:InvalidCVtype' )); 
elseifstrcmpi (cvp .Type ,'holdout' )&&mcreps <=1 
error (message ('stats:lassoGlm:InvalidMCReps' )); 
end
elseifstrncmpi (cvp ,'resubstitution' ,length (cvp ))



cvp ='resubstitution' ; 
else
error (message ('stats:lassoGlm:InvalidCVtype' )); 
end
ifstrcmp (cvp ,'resubstitution' )&&mcreps ~=1 
error (message ('stats:lassoGlm:InvalidMCReps' )); 
end

ifisa (cvp ,'cvpartition' )
if(cvp .N ~=size (X ,1 ))||(min (cvp .TrainSize )<2 )



error (message ('stats:lassoGlm:TooFewObservationsForCrossval' )); 
end
end






if~isempty (predictorNames )
if~iscellstr (predictorNames )||length (predictorNames (:))~=size (X ,2 )
error (message ('stats:lassoGlm:InvalidPredictorNames' )); 
else
predictorNames =predictorNames (:)' ; 
end
end

end





function [estdisp ,sqrtvarFun ,devFun ,linkFun ,dlinkFun ,ilinkFun ,link ,mu ,eta ,muLims ,...
    isCanonical ,dlinkFunCanonical ]=...
    glmProcessDistrAndLink (y ,distr ,link ,estdisp ,N ,dataClass )

switchdistr 
case 'normal' 
canonicalLink ='identity' ; 
case 'binomial' 
canonicalLink ='logit' ; 
case 'poisson' 
canonicalLink ='log' ; 
case 'gamma' 
canonicalLink ='reciprocal' ; 
case 'inverse gaussian' 
canonicalLink =-2 ; 
end

ifisequal (link ,'canonical' ),link =canonicalLink ; end

switchdistr 
case 'normal' 
sqrtvarFun =@(mu )ones (size (mu )); 
devFun =@(mu ,y )(y -mu ).^2 ; 
estdisp ='on' ; 
case 'binomial' 
sqrtN =sqrt (N ); 
sqrtvarFun =@(mu )sqrt (mu ).*sqrt (1 -mu )./sqrtN ; 
devFun =@(mu ,y )2 *N .*(y .*log ((y +(y ==0 ))./mu )+(1 -y ).*log ((1 -y +(y ==1 ))./(1 -mu ))); 
case 'poisson' 
ifany (y <0 )
error (message ('stats:lassoGlm:BadDataPoisson' )); 
end
sqrtvarFun =@(mu )sqrt (mu ); 
devFun =@(mu ,y )2 *(y .*(log ((y +(y ==0 ))./mu ))-(y -mu )); 
case 'gamma' 
ifany (y <=0 )
error (message ('stats:lassoGlm:BadDataGamma' )); 
end
sqrtvarFun =@(mu )mu ; 
devFun =@(mu ,y )2 *(-log (y ./mu )+(y -mu )./mu ); 
estdisp ='on' ; 
case 'inverse gaussian' 
ifany (y <=0 )
error (message ('stats:lassoGlm:BadDataInvGamma' )); 
end
sqrtvarFun =@(mu )mu .^(3 /2 ); 
devFun =@(mu ,y )((y -mu )./mu ).^2 ./y ; 
estdisp ='on' ; 
otherwise
error (message ('stats:lassoGlm:BadDistribution' )); 
end



[linkFun ,dlinkFun ,ilinkFun ]=dfswitchyard ('stattestlink' ,link ,dataClass ); 


mu =startingVals (distr ,y ,N ); 
eta =linkFun (mu ); 



switchdistr 
case 'binomial' 


muLims =[eps (dataClass ),1 -eps (dataClass )]; 
case {'poisson' ,'gamma' ,'inverse gaussian' }


muLims =realmin (dataClass ).^.25 ; 
otherwise
muLims =[]; 
end




isCanonical =isequal (link ,canonicalLink ); 
[~,dlinkFunCanonical ]=dfswitchyard ('stattestlink' ,canonicalLink ,dataClass ); 

end





function [b ,mu ,eta ,varargout ]=glmIRLS (x ,y ,distr ,offset ,pwts ,dataClass ,N ,...
    sqrtvarFun ,linkFun ,dlinkFun ,ilinkFun ,b ,active ,mu ,muLims ,...
    wlsfit ,nullDev ,devFun ,reltol )

wsIterationLimit =warning ('off' ,'stats:lassoGlm:IterationLimit' ); 
wsPerfectSeparation =warning ('off' ,'stats:lassoGlm:PerfectSeparation' ); 
wsBadScaling =warning ('off' ,'stats:lassoGlm:BadScaling' ); 
cleanupIterationLimit =onCleanup (@()warning (wsIterationLimit )); 
cleanupPerfectSeparation =onCleanup (@()warning (wsPerfectSeparation )); 
cleanupBadScaling =onCleanup (@()warning (wsBadScaling )); 

ifisempty (pwts )
pwts =1 ; 
end


iter =0 ; 
iterLim =100 ; 
warned =false ; 
seps =sqrt (eps ); 



convcrit =max (1e-6 ,2 *reltol ); 

eta =linkFun (mu ); 

whileiter <=iterLim 
iter =iter +1 ; 


deta =dlinkFun (mu ); 
z =eta +(y -mu ).*deta ; 


sqrtw =sqrt (pwts )./(abs (deta ).*sqrtvarFun (mu )); 





wtol =max (sqrtw )*eps (dataClass )^(2 /3 ); 
t =(sqrtw <wtol ); 
ifany (t )
t =t &(sqrtw ~=0 ); 
ifany (t )
sqrtw (t )=wtol ; 
if~warned 
warning (message ('stats:lassoGlm:BadScaling' )); 
end
warned =true ; 
end
end

b_old =b ; 
[b ,active ]=wlsfit (z -offset ,x ,sqrtw .^2 ,b ,active ); 


eta =offset +x *b ; 


mu =ilinkFun (eta ); 


switchdistr 
case 'binomial' 
ifany (mu <muLims (1 )|muLims (2 )<mu )
mu =max (min (mu ,muLims (2 )),muLims (1 )); 
end
case {'poisson' ,'gamma' ,'inverse gaussian' }
ifany (mu <muLims (1 ))
mu =max (mu ,muLims (1 )); 
end
end



if(~any (abs (b -b_old )>convcrit *max (seps ,abs (b_old ))))
break; 
end

ifsum (devFun (mu ,y ))<(1.0e-3 *nullDev )
break; 
end

end

ifiter >iterLim 
warning (message ('stats:lassoGlm:IterationLimit' )); 
end

ifiter >iterLim &&isequal (distr ,'binomial' )
diagnoseSeparation (eta ,y ,N ); 
end

varargout {1 }=active ; 

end





function [B ,active ,varargout ]=glmIRLSwrapper (X ,Y ,distr ,offset ,pwts ,dataClass ,N ,...
    sqrtvarFun ,linkFun ,dlinkFun ,ilinkFun ,devFun ,b ,active ,mu ,muLims ,...
    wlsfit ,nullDev ,reltol )












X =[ones (size (X ,1 ),1 ),X ]; 



ifisempty (pwts ),pwts =1 ; end

[B ,mu ,eta ,active ]=glmIRLS (X ,Y ,distr ,offset ,pwts ,dataClass ,N ,...
    sqrtvarFun ,linkFun ,dlinkFun ,ilinkFun ,b ,active ,mu ,muLims ,...
    wlsfit ,nullDev ,devFun ,reltol ); 

deviance =sum (pwts .*devFun (mu ,Y )); 



Intercept =B (1 ); 
B =B (2 :end); 

extras .Intercept =Intercept ; 
extras .Deviance =deviance ; 
varargout {1 }=extras ; 
varargout {2 }=mu ; 
varargout {3 }=eta ; 

end





function dev =lassoFitAndPredict (Xtrain ,Ytrain ,Xtest ,Ytest ,...
    lambda ,alpha ,dfmax ,standardize ,reltol ,maxIter ,ever_active ,...
    penalizedFitPartition ,distr ,link ,linkFun ,dlinkFun ,sqrtvarFun ,...
    isCanonical ,dlinkFunCanonical ,devFun ,dataClass )





trainWeights =Xtrain (:,1 ); 



ifany (isnan (trainWeights ))
trainWeights =[]; 
end
trainOffset =Xtrain (:,2 ); 
ifany (isnan (trainOffset ))
trainOffset =0 ; 
end

Xtrain =Xtrain (:,3 :end); 
ifsize (Ytrain ,2 )==2 
trainN =Ytrain (:,1 ); 
Ytrain =Ytrain (:,2 ); 
else
trainN =1 ; 
end




mu =startingVals (distr ,Ytrain ,trainN ); 
eta =linkFun (mu ); 
ifisequal (distr ,'binomial' )
sqrtvarFun =@(mu )sqrt (mu ).*sqrt (1 -mu )./sqrt (trainN ); 
devFun =@(mu ,y )2 *trainN .*(y .*log ((y +(y ==0 ))./mu )+(1 -y ).*log ((1 -y +(y ==1 ))./(1 -mu ))); 
end

penalizedFit =@(x ,y ,wlsfit ,b ,active ,mu ,eta )penalizedFitPartition (x ,y ,...
    trainOffset ,trainWeights ,trainN ,wlsfit ,b ,active ,mu ,eta ,sqrtvarFun ); 

[lambdaMax ,nullDev ,nullIntercept ]=computeLambdaMax (Xtrain ,Ytrain ,trainWeights ,...
    alpha ,standardize ,distr ,link ,dlinkFun ,trainOffset ,isCanonical ,dlinkFunCanonical ,devFun ); 




ifisempty (trainWeights )&&isscalar (trainN )
totalWeight =size (Xtrain ,1 ); 
elseif~isempty (trainWeights )&&isscalar (trainN )
totalWeight =sum (trainWeights ); 
elseifisempty (trainWeights )&&~isscalar (trainN )
totalWeight =sum (trainN ); 
else
totalWeight =sum (trainWeights .*trainN ); 
end

lambdaMax =lambdaMax *totalWeight ; 

[B ,Intercept ]=lassoFit (Xtrain ,Ytrain ,...
    trainWeights ,lambda ,alpha ,dfmax ,standardize ,reltol ,maxIter ,...
    lambdaMax ,ever_active ,penalizedFit ,mu ,eta ,dataClass ,true ,nullDev ,nullIntercept ); 
Bplus =[Intercept ; B ]; 

testWeights =Xtest (:,1 ); 
ifany (isnan (testWeights ))
testWeights =ones (size (Xtest ,1 ),1 ); 
end
testOffset =Xtest (:,2 ); 
ifany (isnan (testOffset ))
testOffset =0 ; 
end
Xtest =Xtest (:,3 :end); 
ifsize (Ytest ,2 )==2 
testN =Ytest (:,1 ); 
Ytest =Ytest (:,2 ); 
else
testN =1 ; 
end





ifisequal (distr ,'binomial' )
devFun =@(mu ,y )2 *testN .*(y .*log ((y +(y ==0 ))./mu )+(1 -y ).*log ((1 -y +(y ==1 ))./(1 -mu ))); 
end

numFits =size (Bplus ,2 ); 
dev =zeros (1 ,numFits ); 
fori =1 :numFits 
if~isequal (testOffset ,0 )
mu =glmval (Bplus (:,i ),Xtest ,link ,'Offset' ,testOffset ); 
else
mu =glmval (Bplus (:,i ),Xtest ,link ); 
end
di =devFun (mu ,Ytest ); 
dev (i )=sum (testWeights ' *di ); 
end

end





function [B ,Intercept ,lambda ,varargout ]=...
    lassoFit (X ,Y ,weights ,lambda ,alpha ,dfmax ,standardize ,reltol ,maxIter ,...
    lambdaMax ,ever_active ,penalizedFit ,mu ,eta ,dataClass ,userSuppliedLambda ,nullDev ,nullIntercept )





regressionType ='GLM' ; 

[~,P ]=size (X ); 
nLambda =length (lambda ); 




constantPredictors =(range (X )==0 ); 
ever_active =ever_active &~constantPredictors ; 



observationWeights =~isempty (weights ); 
if~isempty (weights )
observationWeights =true ; 
weights =weights (:)' ; 

weights =weights /sum (weights ); 
end

ifstandardize 
if~observationWeights 

[X0 ,muX ,sigmaX ]=zscore (X ,1 ); 

sigmaX (constantPredictors )=1 ; 
else

muX =weights *X ; 
X0 =bsxfun (@minus ,X ,muX ); 
sigmaX =sqrt (weights *(X0 .^2 )); 

sigmaX (constantPredictors )=1 ; 
X0 =bsxfun (@rdivide ,X0 ,sigmaX ); 
end
else
switchregressionType 
case 'OLS' 
if~observationWeights 

muX =mean (X ,1 ); 
X0 =bsxfun (@minus ,X ,muX ); 
sigmaX =1 ; 
else

muX =weights *X ; 
X0 =bsxfun (@minus ,X ,muX ); 
sigmaX =1 ; 
end
case 'GLM' 
X0 =X ; 

sigmaX =1 ; 
muX =zeros (1 ,size (X ,2 )); 
end
end


switchregressionType 
case 'OLS' 
if~observationWeights 
muY =mean (Y ); 
else
muY =weights *Y ; 
end
Y0 =bsxfun (@minus ,Y ,muY ); 
case 'GLM' 
Y0 =Y ; 
end




B =zeros (P ,nLambda ); 

b =zeros (P ,1 ,dataClass ); 

ifnLambda >0 
Extras (nLambda )=struct ('Intercept' ,nullIntercept ,'Deviance' ,nullDev ); 
fori =1 :nLambda -1 ,Extras (i )=Extras (nLambda ); end
intercept =nullIntercept ; 
end

active =false (1 ,P ); 

fori =1 :nLambda 

lam =lambda (i ); 

iflam >=lambdaMax 
continue ; 
end




wlsfit =@(x ,y ,weights ,b ,active )glmPenalizedWlsWrapper (y ,x ,b ,active ,weights ,lam ,...
    alpha ,reltol ,ever_active ,maxIter ); 

[b ,active ,extras ,mu ,eta ]=penalizedFit (X0 ,Y0 ,wlsfit ,[intercept ; b ],active ,mu ,eta ); 

B (:,i )=b ; 

Extras (i )=extras ; 


ifsum (active )>dfmax 

lambda =lambda (1 :(i -1 )); 
B =B (:,1 :(i -1 )); 
Extras =Extras (:,1 :(i -1 )); 
break
end



if~(userSuppliedLambda ||isempty (nullDev ))
ifextras .Deviance <1.0e-3 *nullDev 
lambda =lambda (1 :i ); 
B =B (:,1 :i ); 
Extras =Extras (:,1 :i ); 
break
end
end

end





B =bsxfun (@rdivide ,B ,sigmaX ' ); 
B (~ever_active ,:)=0 ; 

switchregressionType 
case 'OLS' 
Intercept =muY -muX *B ; 
case 'GLM' 
Intercept =zeros (1 ,length (lambda )); 
fori =1 :length (lambda )
Intercept (i )=Extras (i ).Intercept ; 
end
ifisempty (lambda )
Intercept =[]; 
else
Intercept =Intercept -muX *B ; 
end
end





switchregressionType 
case 'OLS' 
Intercept =muY -muX *B ; 
BwithI =[Intercept ; B ]; 
fits =[ones (size (X ,1 ),1 ),X ]*BwithI ; 
residuals =bsxfun (@minus ,Y ,fits ); 
if~observationWeights 
mspe =mean (residuals .^2 ); 
else

mspe =weights *(residuals .^2 ); 
end
varargout {1 }=mspe ; 
case 'GLM' 
deviance =zeros (1 ,length (lambda )); 
fori =1 :length (lambda )
deviance (i )=Extras (i ).Deviance ; 
end
ifisempty (lambda )
deviance =[]; 
end
varargout {1 }=deviance ; 
end

end





function potentially_active =thresholdScreen (X0 ,wX0 ,Y0 ,...
    b ,active ,threshold )
r =Y0 -X0 (:,active )*b (active ,:); 


potentially_active =abs (r ' *wX0 )>threshold ; 
end





function [b ,active ,wX2 ,wX2calculated ,shrinkFactor ]=...
    cdescentCycleNewCandidates (X0 ,weights ,wX0 ,wX2 ,wX2calculated ,Y0 ,...
    b ,active ,shrinkFactor ,threshold ,candidates )

r =Y0 -X0 *b ; 
bold =b ; 

forj =find (candidates ); 

bj =sum (wX0 (:,j ).*r ); 

margin =abs (bj )-threshold ; 


ifmargin >0 
if~wX2calculated (j )
wX2 (j )=weights *X0 (:,j ).^2 ; 
wX2calculated (j )=true ; 
shrinkFactor (j )=wX2 (j )+shrinkFactor (j ); 
end

b (j )=sign (bj ).*margin ./shrinkFactor (j ); 

active (j )=true ; 
end

r =r -X0 (:,j )*(b (j )-bold (j )); 
end

end





function [b ,active ]=...
    cdescentCycleNoRecalc (X0 ,wX0 ,wX2 ,Y0 ,b ,active ,shrinkFactor ,threshold )

r =Y0 -X0 *b ; 
bwX2 =b .*wX2 ; 
bold =b ; 

forj =find (active ); 

bj =sum (wX0 (:,j ).*r )+bwX2 (j ); 

margin =abs (bj )-threshold ; 


ifmargin >0 
b (j )=sign (bj ).*margin ./shrinkFactor (j ); 
else
b (j )=0 ; 
active (j )=false ; 
end

r =r -X0 (:,j )*(b (j )-bold (j )); 
end

end





function [b ,varargout ]=...
    penalizedWls (X ,Y ,b ,active ,weights ,lambda ,alpha ,reltol ,maxIter )

weights =weights (:)' ; 

[~,P ]=size (X ); 

wX =bsxfun (@times ,X ,weights ' ); 

wX2 =zeros (P ,1 ); 
wX2 (active )=(weights *X (:,active ).^2 )' ; 
wX2calculated =active ; 

threshold =lambda *alpha ; 

shrinkFactor =wX2 +lambda *(1 -alpha ); 


fornumIter =1 :maxIter 

bold =b ; 
old_active =active ; 

[b ,active ]=cdescentCycleNoRecalc (X ,wX ,wX2 ,Y ,b ,active ,shrinkFactor ,threshold ); 

if~any (abs (b (old_active )-bold (old_active ))>reltol *max (1.0 ,abs (bold (old_active ))))




bold =b ; 
potentially_active =thresholdScreen (X ,wX ,Y ,b ,active ,threshold ); 
new_candidates =potentially_active &~active ; 
ifany (new_candidates )
[b ,new_active ,wX2 ,wX2calculated ,shrinkFactor ]=...
    cdescentCycleNewCandidates (X ,weights ,wX ,wX2 ,wX2calculated ,Y ,...
    b ,active ,shrinkFactor ,threshold ,new_candidates ); 
else
new_active =active ; 
end

ifisequal (new_active ,active )
break
else
super_active =active |new_active ; 
if~any (abs (b (super_active )-bold (super_active ))>reltol *max (1.0 ,abs (bold (super_active ))))








ifsum (new_active )>sum (active )
b =bold ; 
else
active =new_active ; 
end
break
else
active =new_active ; 
end
end
end

ifnumIter ==maxIter 
warning (message ('stats:lasso:MaxIterReached' ,num2str (lambda ))); 
end
end

varargout {1 }=active ; 

end





function [b ,varargout ]=glmPenalizedWlsWrapper (X ,Y ,b ,active ,weights ,...
    lambda ,alpha ,reltol ,ever_active ,maxIter )




X0 =X (:,2 :end); 

weights =weights (:)' ; 

normedWeights =weights /sum (weights ); 


muX =normedWeights *X0 ; 
X0 =bsxfun (@minus ,X0 ,muX ); 


muY =normedWeights *Y ; 
Y =Y -muY ; 

[bPredictors ,varargout {1 }]=penalizedWls (X0 ,Y ,b (2 :end),...
    active ,weights ,lambda ,alpha ,reltol ,maxIter ); 

bPredictors (~ever_active ,:)=0 ; 



Intercept =muY -muX *bPredictors ; 
b =[Intercept ; bPredictors ]; 

end

function [lambdaMax ,nullDev ,nullIntercept ]=computeLambdaMax (X ,Y ,weights ,alpha ,standardize ,...
    distr ,link ,dlinkFun ,offset ,isCanonical ,dlinkFunCanonical ,devFun )











wsIllConditioned2 =warning ('off' ,'stats:glmfit:IllConditioned' ); 
wsIterationLimit =warning ('off' ,'stats:glmfit:IterationLimit' ); 
wsPerfectSeparation =warning ('off' ,'stats:glmfit:PerfectSeparation' ); 
wsBadScaling =warning ('off' ,'stats:glmfit:BadScaling' ); 
cleanupIllConditioned2 =onCleanup (@()warning (wsIllConditioned2 )); 
cleanupIterationLimit =onCleanup (@()warning (wsIterationLimit )); 
cleanupPerfectSeparation =onCleanup (@()warning (wsPerfectSeparation )); 
cleanupBadScaling =onCleanup (@()warning (wsBadScaling )); 

if~isempty (weights )
observationWeights =true ; 
weights =weights (:)' ; 

normalizedweights =weights /sum (weights ); 
else
observationWeights =false ; 
end

[N ,~]=size (X ); 





ifstandardize 


constantPredictors =(range (X )==0 ); 

if~observationWeights 

[X0 ,~,~]=zscore (X ,1 ); 
else

muX =normalizedweights *X ; 
X0 =bsxfun (@minus ,X ,muX ); 
sigmaX =sqrt (normalizedweights *(X0 .^2 )); 

sigmaX (constantPredictors )=1 ; 
X0 =bsxfun (@rdivide ,X0 ,sigmaX ); 
end
else
if~observationWeights 

muX =mean (X ,1 ); 
X0 =bsxfun (@minus ,X ,muX ); 
else

muX =normalizedweights (:)' *X ; 
X0 =bsxfun (@minus ,X ,muX ); 
end
end

constantTerm =ones (length (Y ),1 ); 
ifisscalar (offset )
[coeffs ,nullDev ]=glmfit (constantTerm ,Y ,distr ,'constant' ,'off' ,...
    'link' ,link ,'weights' ,weights ); 
predictedMu =glmval (coeffs ,constantTerm ,link ,'constant' ,'off' ); 
else
[coeffs ,nullDev ]=glmfit (constantTerm ,Y ,distr ,'constant' ,'off' ,...
    'link' ,link ,'weights' ,weights ,'offset' ,offset ); 
predictedMu =glmval (coeffs ,constantTerm ,link ,'constant' ,'off' ,'offset' ,offset ); 
end

nullIntercept =coeffs ; 













ifobservationWeights 
muDev =weights *devFun (mean (Y )*ones (length (Y ),1 ),Y ); 
else
muDev =sum (devFun (mean (Y )*ones (length (Y ),1 ),Y )); 
end
if(muDev -nullDev )/max ([1.0 ,muDev ,nullDev ])<-1.0e-4 
[~,lastid ]=lastwarn ; 
ifstrcmp (lastid ,'stats:glmfit:BadScaling' )




predictedMu =mean (Y )*ones (length (Y ),1 ); 
warning (message ('stats:lassoGlm:DifficultLikelihood' )); 
end
end

if~isCanonical 
X0 =bsxfun (@times ,X0 ,dlinkFunCanonical (predictedMu )./dlinkFun (predictedMu )); 
end

if~observationWeights 
dotp =abs (X0 ' *(Y -predictedMu )); 
lambdaMax =max (dotp )/(N *alpha ); 
else
wX0 =bsxfun (@times ,X0 ,normalizedweights ' ); 
dotp =abs (sum (bsxfun (@times ,wX0 ,(Y -predictedMu )))); 
lambdaMax =max (dotp )/alpha ; 
end

end

function lambda =computeLambdaSequence (lambdaMax ,nLambda ,lambdaRatio ,LRdefault )



ifnLambda ==1 
lambda =lambdaMax ; 
else

iflambdaRatio ==0 
lambdaRatio =LRdefault ; 
addZeroLambda =true ; 
else
addZeroLambda =false ; 
end
lambdaMin =lambdaMax *lambdaRatio ; 
loghi =log (lambdaMax ); 
loglo =log (lambdaMin ); 
lambda =exp (linspace (loghi ,loglo ,nLambda )); 
ifaddZeroLambda 
lambda (end)=0 ; 
else
lambda (end)=lambdaMin ; 
end
end

end

