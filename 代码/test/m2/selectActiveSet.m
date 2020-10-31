function [A ,C ,CProfile ,exitFlag ]=selectActiveSet (X ,kfun ,diagkfun ,varargin )





































































































































































































































X =validateX (X ); 



kfun =validatekfun (kfun ); 
if~isempty (diagkfun )
diagkfun =validatediagkfun (diagkfun ); 
end


ActiveSetMethodSGMA ='SGMA' ; 
ActiveSetMethodEntropy ='Entropy' ; 
ActiveSetMethodLikelihood ='Likelihood' ; 


SearchTypeSparse ='Sparse' ; 
SearchTypeExhaustive ='Exhaustive' ; 




N =size (X ,1 ); 
dfltActiveSetMethod =ActiveSetMethodSGMA ; 
dfltActiveSetSize =min (1000 ,N ); 
dfltInitialActiveSet =zeros (0 ,1 ); 
dfltRandomSearchSetSize =59 ; 
dfltSearchType =SearchTypeSparse ; 
dfltTolerance =1e-2 ; 
dfltVerbose =false ; 
dfltSigma =1 ; 
dfltResponseVector =ones (N ,1 ); 
dfltRegularization =0 ; 


paramNames ={'ActiveSetMethod' ,'ActiveSetSize' ,'InitialActiveSet' ,'RandomSearchSetSize' ,'SearchType' ,'Tolerance' ,'Verbose' ,'Sigma' ,'ResponseVector' ,'Regularization' }; 
paramDflts ={dfltActiveSetMethod ,dfltActiveSetSize ,dfltInitialActiveSet ,dfltRandomSearchSetSize ,dfltSearchType ,dfltTolerance ,dfltVerbose ,dfltSigma ,dfltResponseVector ,dfltRegularization }; 


[activemethod ,M ,A0 ,J ,searchtype ,tol ,verbose ,sigma ,y ,tau ]=internal .stats .parseArgs (paramNames ,paramDflts ,varargin {:}); 


activemethod =internal .stats .getParamVal (activemethod ,{ActiveSetMethodSGMA ,ActiveSetMethodEntropy ,ActiveSetMethodLikelihood },'ActiveSetMethod' ); 
M =validateActiveSetSize (M ,N ); 
A0 =validateInitialActiveSet (A0 ,M ,N ); 
J =validateRandomSearchSetSize (J ,searchtype ); 
searchtype =internal .stats .getParamVal (searchtype ,{SearchTypeSparse ,SearchTypeExhaustive },'SearchType' ); 
tol =validateTolerance (tol ); 
verbose =validateVerbose (verbose ); 
sigma =validateSigma (sigma ); 
y =validateResponseVector (y ,N ); 
tau =validateRegularization (tau ); 


ifstrcmpi (searchtype ,SearchTypeSparse )
issparsesearch =true ; 
else
issparsesearch =false ; 
end


switchlower (activemethod )
case lower (ActiveSetMethodSGMA )
[A ,C ,CProfile ,exitFlag ]=selectActiveSetSGMA (X ,kfun ,diagkfun ,M ,A0 ,J ,issparsesearch ,tol ,verbose ,tau ); 
case lower (ActiveSetMethodEntropy )
[A ,C ,CProfile ,exitFlag ]=selectActiveSetEntropy (X ,kfun ,diagkfun ,M ,A0 ,J ,issparsesearch ,tol ,verbose ,sigma ); 
case lower (ActiveSetMethodLikelihood )
[A ,C ,CProfile ,exitFlag ]=selectActiveSetLikelihood (X ,y ,kfun ,diagkfun ,M ,A0 ,J ,issparsesearch ,tol ,verbose ,sigma ,tau ); 
end
end


function diagK =computeKernelDiag (X ,kfun )


N =size (X ,1 ); 
diagK =zeros (N ,1 ); 
fori =1 :N 
diagK (i )=kfun (X (i ,:),X (i ,:)); 
end
end


function [A ,EA ,EAProfile ,exitFlag ]=selectActiveSetSGMA (X ,kfun ,diagkfun ,M ,A0 ,J ,issparsesearch ,tol ,verbose ,tau )





























N =size (X ,1 ); 


A =A0 ; 
R =setdiff ((1 :N )' ,A0 ); 


nA =length (A ); 
nR =length (R ); 


ifisempty (diagkfun )
diagK =computeKernelDiag (X ,kfun ); 
else
diagK =diagkfun (X ); 
end




TA =zeros (N ,M ); 




ifisempty (A )
TA (:,1 :nA )=zeros (N ,0 ); 
EA =sum (diagK ); 
else
KXA =kfun (X ,X (A ,:)); 
KAA =KXA (A ,:); 
KAA (1 :nA +1 :nA ^2 )=KAA (1 :nA +1 :nA ^2 )+tau ^2 ; 
[LA ,status ]=chol (KAA ,'lower' ); 
if(status ~=0 )

error (message ('stats:classreg:learning:gputils:selectActiveSet:CannotInitializeActiveSetSelection' )); 
end

TA (:,1 :nA )=KXA /LA ' ; 
sumdiagKHat =sum (sum (TA (:,1 :nA ).^2 ,1 )); 
EA =sum (diagK )-sumdiagKHat ; 
end
EA0 =EA ; 



EAProfile =zeros (M -nA +1 ,1 ); 
EAProfile (1 )=EA0 ; 
if(nA ==M )

exitFlag =1 ; 
return ; 
end





found =false ; 
index =2 ; 
isposdef =true ; 
iter =0 ; 

while(found ==false )

ifissparsesearch &&(nR >J )
Jset =R (randsample (nR ,J ),1 ); 
else
Jset =R ; 
end
lenJset =length (Jset ); 








ifissparsesearch 













KXJset =kfun (X ,X (Jset ,:)); 
wmat =TA (Jset ,1 :nA )' ; 
umat =TA (:,1 :nA )*wmat -KXJset ; 

vvec =-umat (sub2ind ([N ,lenJset ],Jset ,(1 :lenJset )' ))+tau ^2 ; 
Deltavec =sum (umat .^2 ,1 )' ./vvec ; 






badidx =(vvec <=0 )|isnan (Deltavec ); 
ifany (badidx )
Deltavec (badidx )=0 ; 
end


[Deltabest ,idx ]=max (Deltavec ); 
ibest =Jset (idx ); 
ubest =umat (:,idx ); 
vbest =vvec (idx ); 
else


Deltabest =-Inf ; 
fori =Jset ' 

ki =kfun (X ,X (i ,:)); 
w =TA (i ,1 :nA )' ; 
u =TA (:,1 :nA )*w -ki ; 

v =-u (i )+tau ^2 ; 
Delta =(u ' *u )/v ; 





if(v <=0 ||isnan (Delta ))
Delta =0 ; 
end


if(Delta >=Deltabest )
Deltabest =Delta ; 
ibest =i ; 
ubest =u ; 
vbest =v ; 
end
end
end




if(vbest <=0 ||isnan (Deltabest ))
isposdef =false ; 
end
vbest =max (0 ,vbest ); 
Deltabest =max (0 ,Deltabest ); 


ifisposdef 

A =[A ; ibest ]; %#ok<AGROW> 
R =setdiff (R ,ibest ); 


TA (:,nA +1 )=-ubest /sqrt (vbest ); 
EA =max (0 ,EA -Deltabest ); 


nA =length (A ); 
nR =length (R ); 


EAProfile (index )=EA ; 
index =index +1 ; 
end


relEA =EA /max (1 ,EA0 ); 


ifverbose 
displayConvergenceInfo (iter ,ibest ,nA ,EA ,relEA ,lenJset ); 
end


if(relEA <=tol ||nA ==M ||~isposdef )
found =true ; 


EAProfile (nA -length (A0 )+2 :end)=[]; 

if(relEA <=tol )
exitFlag =0 ; 
elseif(nA ==M )
exitFlag =1 ; 
elseif~isposdef 
exitFlag =2 ; 
end

ifverbose 
displayFinalConvergenceInfo (nA ,relEA ,M ,tol ,exitFlag ); 
end
end


iter =iter +1 ; 

end

end


function [A ,sumDeltabest ,sumDeltabestProfile ,exitFlag ]=selectActiveSetEntropy (X ,kfun ,diagkfun ,M ,A0 ,J ,issparsesearch ,tol ,verbose ,sigma )





























N =size (X ,1 ); 


A =A0 ; 
R =setdiff ((1 :N )' ,A0 ); 


nA =length (A ); 
nR =length (R ); 


ifisempty (diagkfun )
diagK =computeKernelDiag (X ,kfun ); 
else
diagK =diagkfun (X ); 
end




TA =zeros (M ,N ); 



ifisempty (A )
TA (1 :nA ,:)=zeros (0 ,N ); 
else
KAX =kfun (X (A ,:),X ); 
KAA =KAX (:,A ); 
KAA (1 :nA +1 :nA ^2 )=KAA (1 :nA +1 :nA ^2 )+sigma ^2 ; 
[LA ,status ]=chol (KAA ,'lower' ); 
if(status ~=0 )

error (message ('stats:classreg:learning:gputils:selectActiveSet:CannotInitializeActiveSetSelection' )); 
end
TA (1 :nA ,:)=LA \KAX ; 
end




sumDeltabest =0 ; 



sumDeltabestProfile =zeros (M -nA +1 ,1 ); 
sumDeltabestProfile (1 )=sumDeltabest ; 
if(nA ==M )

exitFlag =1 ; 
return ; 
end





found =false ; 
index =2 ; 
isposdef =true ; 
iter =0 ; 

while(found ==false )

ifissparsesearch &&(nR >J )
Jset =R (randsample (nR ,J ),1 ); 
else
Jset =R ; 
end
lenJset =length (Jset ); 






Delta =diagK (Jset )-sum (TA (1 :nA ,Jset ).^2 ,1 )' ; 





badidx =Delta <0 |isnan (Delta ); 
ifany (badidx )
Delta (badidx )=0 ; 
end



[Deltabest ,idx ]=max (Delta ); 
ibest =Jset (idx ); 
ubest =TA (1 :nA ,ibest ); 




if(Deltabest <0 )
isposdef =false ; 
end
Deltabest =max (0 ,Deltabest ); 


ifisposdef 

A =[A ; ibest ]; %#ok<AGROW> 
R =setdiff (R ,ibest ); 


il22 =1 /sqrt (sigma ^2 +Deltabest ); 
kbestt =kfun (X (ibest ,:),X ); 
TA (nA +1 ,:)=-il22 *(ubest ' *TA (1 :nA ,:))+il22 *kbestt ; 
sumDeltabest =sumDeltabest +Deltabest ; 


nA =length (A ); 
nR =length (R ); 


sumDeltabestProfile (index )=sumDeltabest ; 
index =index +1 ; 
end


relInc =Deltabest /sumDeltabest ; 


ifverbose 
displayConvergenceInfo (iter ,ibest ,nA ,sumDeltabest ,relInc ,lenJset ); 
end


if(relInc <=tol ||nA ==M ||~isposdef )
found =true ; 


sumDeltabestProfile (nA -length (A0 )+2 :end)=[]; 

if(relInc <=tol )
exitFlag =0 ; 
elseif(nA ==M )
exitFlag =1 ; 
elseif~isposdef 
exitFlag =2 ; 
end

ifverbose 
displayFinalConvergenceInfo (nA ,relInc ,M ,tol ,exitFlag ); 
end
end


iter =iter +1 ; 

end

end


function [A ,loglikSRA ,loglikSRAProfile ,exitFlag ]=selectActiveSetLikelihood (X ,y ,kfun ,diagkfun ,M ,A0 ,J ,issparsesearch ,tol ,verbose ,sigma ,tau )































N =size (X ,1 ); 


A =A0 ; 
R =setdiff ((1 :N )' ,A0 ); 


nA =length (A ); 
nR =length (R ); 


ifisempty (diagkfun )
diagK =computeKernelDiag (X ,kfun ); 
else
diagK =diagkfun (X ); 
end




TA =zeros (M ,N ); 
TAtilde =zeros (M ,N ); 
vA =zeros (M ,1 ); 



ubest =zeros (nA ,1 ); 
fbest =0 ; 
wbest =zeros (nA ,1 ); 
hbest =0 ; 
kbest =zeros (N ,1 ); 
tbest =0 ; 
ibest =0 ; 
tiny =1e-3 ; 


ifisempty (A )
TA (1 :nA ,:)=zeros (0 ,N ); 
TAtilde (1 :nA ,:)=zeros (0 ,N ); 
vA (1 :nA ,1 )=zeros (0 ,1 ); 
else
KXA =kfun (X ,X (A ,:)); 
KAA =KXA (A ,:); 
KAA (1 :nA +1 :nA ^2 )=KAA (1 :nA +1 :nA ^2 )+tau ^2 ; 
[LA ,status1 ]=chol (KAA +KXA ' *KXA /(sigma ^2 ),'lower' ); 
if(status1 ~=0 )

error (message ('stats:classreg:learning:gputils:selectActiveSet:CannotInitializeActiveSetSelection' )); 
end
TA (1 :nA ,:)=LA \KXA ' ; 

[LAtilde ,status2 ]=chol (KAA ,'lower' ); 
if(status2 ~=0 )

error (message ('stats:classreg:learning:gputils:selectActiveSet:CannotInitializeActiveSetSelection' )); 
end
TAtilde (1 :nA ,:)=LAtilde \KXA ' ; 

vA (1 :nA ,1 )=TA (1 :nA ,:)*y /(sigma ^2 ); 
end



cloglikSRA =(N /2 )*log (2 *pi *(sigma ^2 )); 
ifisempty (A )
loglikSRA =-0.5 *(y ' *y /(sigma ^2 ))-cloglikSRA ; 
else
loglikSRA =-0.5 *(y ' *y /(sigma ^2 )-vA (1 :nA )' *vA (1 :nA ))...
    -cloglikSRA -sum (log (abs (diag (LA ))))...
    +sum (log (abs (diag (LAtilde )))); 
end



loglikSRAProfile =zeros (M -nA +1 ,1 ); 
loglikSRAProfile (1 )=loglikSRA ; 
if(nA ==M )

exitFlag =1 ; 
return ; 
end





found =false ; 
index =2 ; 
isposdef =true ; 
iter =0 ; 

while(found ==false )

ifissparsesearch &&(nR >J )
Jset =R (randsample (nR ,J ),1 ); 
else
Jset =R ; 
end
lenJset =length (Jset ); 






ifissparsesearch 


















KXJset =kfun (X ,X (Jset ,:)); 
umat =TA (1 :nA ,Jset )+TA (1 :nA ,:)*KXJset /(sigma ^2 ); 
dvec =diagK (Jset )+sum (KXJset .^2 ,1 )' /(sigma ^2 ); 
fvec =(dvec +tau ^2 )-sum (umat .^2 ,1 )' ; 
wmat =TAtilde (1 :nA ,Jset ); 
hvec =(diagK (Jset )+tau ^2 )-sum (wmat .^2 ,1 )' ; 
gvec =(y ' *KXJset /(sigma ^2 ))' ; 
tvec =-(umat ' *vA (1 :nA ,1 )-gvec )./sqrt (abs (fvec )); 


Deltavec =(0.5 *(tvec .^2 )+0.5 *log (hvec ))-0.5 *log (fvec ); 





badidx =(fvec <=tiny |hvec <=tiny |isnan (Deltavec )); 
ifany (badidx )
Deltavec (badidx )=0 ; 
end



[Deltabest ,idx ]=max (Deltavec ); 
ubest =umat (:,idx ); 
fbest =fvec (idx ,1 ); 
wbest =wmat (:,idx ); 
hbest =hvec (idx ,1 ); 
kbest =KXJset (:,idx ); 
tbest =tvec (idx ,1 ); 
ibest =Jset (idx ); 
else

Deltabest =-Inf ; 
forr =Jset ' 


kXr =kfun (X ,X (r ,:)); 
kXr_div_sigma2 =kXr /(sigma ^2 ); 
u =TA (1 :nA ,r )+TA (1 :nA ,:)*(kXr_div_sigma2 ); 
f =diagK (r )+kXr ' *(kXr_div_sigma2 )-u ' *u +tau ^2 ; 
w =TAtilde (1 :nA ,r ); 
h =diagK (r )-w ' *w +tau ^2 ; 
g =y ' *(kXr_div_sigma2 ); 
t =-(vA (1 :nA ,1 )' *u -g )/sqrt (f ); 
Delta =0.5 *t ^2 +0.5 *(log (h )-log (f )); 




if(f <=0 ||h <=0 ||isnan (Delta ))
Delta =0 ; 
end


if(Delta >=Deltabest )
ubest =u ; 
fbest =f ; 
wbest =w ; 
hbest =h ; 
kbest =kXr ; 
tbest =t ; 
ibest =r ; 
Deltabest =Delta ; 
end
end
end






if(fbest <=0 ||hbest <=0 ||isnan (Deltabest ))
isposdef =false ; 
Deltabest =0 ; 
end
fbest =max (0 ,fbest ); 
hbest =max (0 ,hbest ); 


ifisposdef 

A =[A ; ibest ]; %#ok<AGROW> 
R =setdiff (R ,ibest ); 


TA (nA +1 ,:)=-ubest ' *TA (1 :nA ,:)/sqrt (fbest )+kbest ' /sqrt (fbest ); 
TAtilde (nA +1 ,:)=-wbest ' *TAtilde (1 :nA ,:)/sqrt (hbest )+kbest ' /sqrt (hbest ); 
vA (nA +1 ,1 )=tbest ; 
loglikSRA =loglikSRA +Deltabest ; 


nA =length (A ); 
nR =length (R ); 


loglikSRAProfile (index )=loglikSRA ; 
index =index +1 ; 
end


relInc =abs (Deltabest )/abs (loglikSRA ); 


ifverbose 
displayConvergenceInfo (iter ,ibest ,nA ,loglikSRA ,relInc ,lenJset ); 
end


if(relInc <=tol ||nA ==M ||~isposdef )
found =true ; 


loglikSRAProfile (nA -length (A0 )+2 :end)=[]; 

if(relInc <=tol )
exitFlag =0 ; 
elseif(nA ==M )
exitFlag =1 ; 
elseif~isposdef 
exitFlag =2 ; 
end

ifverbose 
displayFinalConvergenceInfo (nA ,relInc ,M ,tol ,exitFlag ); 
end
end


iter =iter +1 ; 

end

end


function displayConvergenceInfo (iter ,ibest ,nA ,convCrit ,relConvCrit ,lenJset )


























if(rem (iter ,20 )==0 )
fprintf ('\n' ); 
fprintf ('  |=================================================================================|\n' ); 
fprintf ('  | Iteration |   Best   |  Active Set |   Absolute    |   Relative    | Search Set |\n' ); 
fprintf ('  |           |  Index   |     Size    |   Criterion   |   Criterion   |    Size    |\n' ); 
fprintf ('  |---------------------------------------------------------------------------------|\n' ); 
end

fprintf ('  |%10d |%9d |%12d |%14.6e |%14.6e |%11d |\n' ,iter ,ibest ,nA ,convCrit ,relConvCrit ,lenJset ); 
end

function displayFinalConvergenceInfo (nA ,relConvCrit ,M ,tol ,exitFlag )







fprintf ('\n' ); 
finalCriterionValueString =getString (message ('stats:classreg:learning:gputils:selectActiveSet:MessageFinalCriterionValue' )); 
givenToleranceString =getString (message ('stats:classreg:learning:gputils:selectActiveSet:MessageGivenToleranceValue' )); 
finalActiveSetSizeString =getString (message ('stats:classreg:learning:gputils:selectActiveSet:MessageFinalActiveSetSize' )); 
givenActiveSetSizeString =getString (message ('stats:classreg:learning:gputils:selectActiveSet:MessageGivenActiveSetSize' )); 
fprintf ('%s = %9.3e, %s = %9.3e\n' ,finalCriterionValueString ,relConvCrit ,[givenToleranceString ,'    ' ],tol ); 
fprintf ('%s = %9d, %s = %9d\n' ,[finalActiveSetSizeString ,'               ' ],nA ,givenActiveSetSizeString ,M ); 
if(exitFlag ==0 )

msg =getString (message ('stats:classreg:learning:gputils:selectActiveSet:MessageConvergenceCriterionSatisfied' )); 
fprintf ('%s\n' ,msg ); 
elseif(exitFlag ==1 )

msg =getString (message ('stats:classreg:learning:gputils:selectActiveSet:MessageActiveSetSizeReached' )); 
fprintf ('%s\n' ,msg ); 
else

msg =getString (message ('stats:classreg:learning:gputils:selectActiveSet:MessageKernelNotPositiveDefinite' )); 
fprintf ('%s\n' ,msg ); 
end
end


function X =validateX (X )

isok =isnumeric (X )&&isreal (X )&&ismatrix (X )&&all (isfinite (X (:))); 
if~isok 
error (message ('stats:classreg:learning:gputils:selectActiveSet:BadX' )); 
end
end

function kfun =validatekfun (kfun )

isok =isa (kfun ,'function_handle' ); 
if~isok 
error (message ('stats:classreg:learning:gputils:selectActiveSet:BadKernelFunction' )); 
end
end

function diagkfun =validatediagkfun (diagkfun )

isok =isa (diagkfun ,'function_handle' ); 
if~isok 
error (message ('stats:classreg:learning:gputils:selectActiveSet:BadDiagKernelFunction' )); 
end
end

function M =validateActiveSetSize (M ,N )




isok =isscalar (M )&&internal .stats .isIntegerVals (M ,1 ,N ); 
if~isok 
error (message ('stats:classreg:learning:gputils:selectActiveSet:BadActiveSetSize' ,1 ,N )); 
end
end

function A0 =validateInitialActiveSet (A0 ,M ,N )







ifisempty (A0 )
return ; 
end

isvec =isvector (A0 ); 
isint =internal .stats .isIntegerVals (A0 ,1 ,N ); 
lenA0 =length (A0 ); 
isleM =(lenA0 <=M ); 
isok =isvec &&isint &&isleM ; 

if(size (A0 ,1 )==1 )
A0 =A0 ' ; 
end

A0 =unique (A0 ); 
isok =isok &&(length (A0 )==lenA0 ); 

if~isok 
error (message ('stats:classreg:learning:gputils:selectActiveSet:BadInitialActiveSet' ,M ,N )); 
end
end

function J =validateRandomSearchSetSize (J ,searchtype )




ifstrcmpi (searchtype ,'sparse' )
isscl =isscalar (J ); 
isint =internal .stats .isIntegerVals (J ,1 ); 
isok =isscl &&isint ; 
if~isok 
error (message ('stats:classreg:learning:gputils:selectActiveSet:BadRandomSearchSetSize' )); 
end
end
end

function tol =validateTolerance (tol )


isok =isscalar (tol )&&isnumeric (tol )&&isreal (tol )&&(tol >0 ); 
if~isok 
error (message ('stats:classreg:learning:gputils:selectActiveSet:BadTolerance' )); 
end
end

function tf =validateVerbose (tf )



ifisscalar (tf )
ifisnumeric (tf )
if(tf ==1 )
tf =true ; 
elseif(tf ==0 )
tf =false ; 
end
end
ifislogical (tf )
isok =true ; 
else
isok =false ; 
end
else
isok =false ; 
end

if~isok 
error (message ('stats:classreg:learning:gputils:selectActiveSet:BadVerbose' )); 
end
end

function sigma =validateSigma (sigma )



isok =isscalar (sigma )&&isnumeric (sigma )&&isreal (sigma )&&(sigma >0 ); 
if~isok 
error (message ('stats:classreg:learning:gputils:selectActiveSet:BadSigma' )); 
end
end

function y =validateResponseVector (y ,N )


isok =isnumeric (y )&&isreal (y )&&isvector (y )&&all (isfinite (y (:)))&&(length (y )==N ); 
if~isok 
error (message ('stats:classreg:learning:gputils:selectActiveSet:BadResponseVector' ,N )); 
end
y =y (:); 
end

function tau =validateRegularization (tau )



isok =isscalar (tau )&&isnumeric (tau )&&isreal (tau )&&(tau >=0 ); 
if~isok 
error (message ('stats:classreg:learning:gputils:selectActiveSet:BadRegularization' )); 
end
end