classdef CompactGPImpl 



properties 

FitMethod =[]; 
PredictMethod =[]; 
ActiveSet =[]; 
ActiveSetSize =[]; 
ActiveSetMethod =[]; 
Standardize =[]; 
Verbose =[]; 
CacheSize =[]; 
Options =[]; 
Optimizer =[]; 
OptimizerOptions =[]; 
ConstantKernelParameters =[]; 
ConstantSigma =[]; 
InitialStepSize =[]; 


KernelFunction =[]; 
KernelParameters =[]; 
BasisFunction =[]; 


Kernel =[]; 
IsBuiltInKernel =[]; 
HFcn =[]; 


StdMu =[]; 
StdSigma =[]; 


Beta0 =[]; 
Theta0 =[]; 
Sigma0 =[]; 


BetaHat =[]; 
ThetaHat =[]; 
SigmaHat =[]; 






































IsActiveSetSupplied =[]; 
ActiveSetX =[]; 
AlphaHat =[]; 
LFactor =[]; 
LFactor2 =[]; 


SigmaLB =[]; 


IsTrained =false ; 


LogLikelihoodHat =[]; 
end

methods (Access =protected )
function this =CompactGPImpl ()
end
end
methods (Hidden )
function s =toStruct (obj )


warnState =warning ('query' ,'all' ); 
warning ('off' ,'MATLAB:structOnObject' ); 
cleanupObj =onCleanup (@()warning (warnState )); 

ifisa (obj ,'classreg.learning.impl.GPImpl' )
obj =compact (obj ); 
end

s =struct (obj ); 


s =rmfield (s ,'Kernel' ); 


ifisempty (s .HFcn )
s .HFcn =[]; 
else
s .HFcn =func2str (s .HFcn ); 
end




ifischar (obj .BasisFunction )
s .BasisFcn ='' ; 
s .BasisFunction =obj .BasisFunction ; 
switchlower (obj .BasisFunction )
case 'none' 
s .HFcnType =1 ; 
case 'constant' 
s .HFcnType =2 ; 
case 'linear' 
s .HFcnType =3 ; 
case 'purequadratic' 
s .HFcnType =4 ; 
end
else



strFcn =func2str (obj .BasisFunction ); 
isfuncstr =contains (strFcn ,'@(XM)feval(name,XM)' ); 
if~isfuncstr 
error (message ('stats:classreg:learning:coderutils:classifToStruct:AnonymousFunctionsNotSupported' ,'Basis' )); 
else
fcns =functions (obj .BasisFunction ); 
s .BasisFcn =fcns .workspace {1 }.name ; 
end
s .BasisFunction =strFcn ; 
s .HFcnType =5 ; 
end


ifischar (obj .KernelFunction )
s .KernelFcn ='' ; 
s .KernelFunction =obj .KernelFunction ; 
else



strFcn =func2str (obj .KernelFunction ); 
isfuncstr =contains (strFcn ,'@(XM,XN,THETA)feval(name,XM,XN,THETA)' ); 
if~isfuncstr 
error (message ('stats:classreg:learning:coderutils:classifToStruct:AnonymousFunctionsNotSupported' ,'Kernel' )); 
else
fcns =functions (obj .KernelFunction ); 
s .KernelFcn =fcns .workspace {1 }.name ; 
end
s .KernelFunction =strFcn ; 
end

switchlower (s .Optimizer )
case 'quasinewton' 


s .OptimizerOptions =classreg .learning .gputils .statsetToStruct (s .OptimizerOptions ); 

case 'fminsearch' 


s .OptimizerOptions =classreg .learning .gputils .optimsetToStruct (s .OptimizerOptions ); 

case 'fminunc' 

s .OptimizerOptions =classreg .learning .gputils .optimoptionsToStruct (s .OptimizerOptions ,1 ); 

case 'fmincon' 

s .OptimizerOptions =classreg .learning .gputils .optimoptionsToStruct (s .OptimizerOptions ,2 ); 
end

end
end

methods (Static )
function obj =fromStruct (s )




obj =classreg .learning .impl .CompactGPImpl ; 

fieldNamesToAssign ={'FitMethod' ,'PredictMethod' ,'ActiveSet' ,...
    'ActiveSetSize' ,'ActiveSetMethod' ,'Standardize' ,'Verbose' ,...
    'CacheSize' ,'Options' ,'Optimizer' ,'ConstantKernelParameters' ,...
    'ConstantSigma' ,'KernelParameters' ,...
    'IsBuiltInKernel' ,'StdMu' ,'StdSigma' ,'Beta0' ,...
    'Theta0' ,'Sigma0' ,'BetaHat' ,'ThetaHat' ,'SigmaHat' ,...
    'IsActiveSetSupplied' ,'ActiveSetX' ,'AlphaHat' ,'LFactor' ,...
    'LFactor2' ,'SigmaLB' ,'IsTrained' ,'LogLikelihoodHat' }; 

forc =1 :numel (fieldNamesToAssign )
obj .(fieldNamesToAssign {c })=s .(fieldNamesToAssign {c }); 
end

switchlower (s .Optimizer )
case 'fminunc' 
obj .OptimizerOptions =classreg .learning .gputils .optimoptionsFromStruct (s .OptimizerOptions ,1 ); 
case 'fmincon' 
obj .OptimizerOptions =classreg .learning .gputils .optimoptionsFromStruct (s .OptimizerOptions ,2 ); 
case 'fminsearch' 
obj .OptimizerOptions =classreg .learning .gputils .optimsetFromStruct (s .OptimizerOptions ); 
case 'quasinewton' 
obj .OptimizerOptions =classreg .learning .gputils .statsetFromStruct (s .OptimizerOptions ); 
end

[~,kernel ,~]=classreg .learning .gputils .makeKernelObject (s .KernelFunction ,s .KernelParams ); 
obj .Kernel =kernel ; 


ifisempty (s .BasisFcn )
obj .BasisFunction =s .BasisFunction ; 
else
name =s .BasisFcn ; 
basisFunction =@(XM )feval (name ,XM ); 
obj .BasisFunction =basisFunction ; 
end


ifisempty (s .KernelFcn )
obj .KernelFunction =s .KernelFunction ; 
else
name =s .KernelFcn ; 
kernelFunction =@(XM ,XN ,THETA )feval (name ,XM ,XN ,THETA ); 
obj .KernelFunction =kernelFunction ; 
end


ifisempty (s .HFcn )
obj .HFcn =[]; 
else
obj .HFcn =str2func (s .HFcn ); 
end


















end
end

methods 
function L =computeLFactorExact (this ,X ,theta ,sigma )











kfun =makeKernelAsFunctionOfXNXM (this .Kernel ,theta ); 





N =size (X ,1 ); 
KPlusSigma2 =kfun (X ,X ); 
diagOffset =this .Options .DiagonalOffset ; 
KPlusSigma2 (1 :N +1 :N ^2 )=KPlusSigma2 (1 :N +1 :N ^2 )+(sigma ^2 +diagOffset ); 



[L ,status ]=chol (KPlusSigma2 ,'lower' ); 
if(status ~=0 )
error (message ('stats:classreg:learning:impl:GPImpl:GPImpl:UnableToComputeLFactorExact' )); 
end

end

function [pred ,se ,ci ]=predictExact (this ,Xnew ,alpha )

























assert (alpha >=0 &&alpha <=1 ); 
assert (this .IsTrained ); 


X =this .ActiveSetX ; 
N =size (X ,1 ); 



if(this .Standardize ==true )
Xnew =bsxfun (@rdivide ,bsxfun (@minus ,Xnew ,this .StdMu ' ),this .StdSigma ' ); 
end


alphaHat =this .AlphaHat ; 
betaHat =this .BetaHat ; 
thetaHat =this .ThetaHat ; 
sigmaHat =this .SigmaHat ; 


HFcn =this .HFcn ; %#ok<PROPLC,*PROP> 



kfun =makeKernelAsFunctionOfXNXM (this .Kernel ,thetaHat ); 


M =size (Xnew ,1 ); 


ifnargout >1 
wantse =true ; 
else
wantse =false ; 
end


ifnargout >2 
wantci =true ; 
else
wantci =false ; 
end



pred =zeros (M ,1 ); 
ifwantse 
se =zeros (M ,1 ); 
end
ifwantci 
ci =zeros (M ,2 ); 
zcrit =norminv (1 -alpha /2 ); 
end



if(wantse ||wantci )
ifisempty (this .LFactor )

L =computeLFactorExact (this ,X ,thetaHat ,sigmaHat ); 
else

L =this .LFactor ; 
assert (size (L ,1 )==N ); 
end
end


if(wantse ||wantci )


kfundiag =makeDiagKernelAsFunctionOfXN (this .Kernel ,thetaHat ); 
diagKnew =kfundiag (Xnew ); 
end








B =max (1 ,floor ((1e6 *this .CacheSize )/8 /N )); 
nchunks =floor (M /B ); 


forc =1 :nchunks +1 

ifc <nchunks +1 
idxc =(c -1 )*B +1 :c *B ; 
else

idxc =nchunks *B +1 :M ; 
end

Xnewc =Xnew (idxc ,:); 

KXnewcX =kfun (Xnewc ,X ); 

pred (idxc )=KXnewcX *alphaHat ; 
if~isempty (betaHat )
pred (idxc )=pred (idxc )+HFcn (Xnewc )*betaHat ; %#ok<PROPLC> 
end

ifwantse 
LinvKXXnewc =L \KXnewcX ' ; 
se (idxc )=sqrt (max (0 ,sigmaHat ^2 +diagKnew (idxc )-sum (LinvKXXnewc .^2 ,1 )' )); 
end

ifwantci 
delta =zcrit *se (idxc ); 
ci (idxc ,:)=[pred (idxc )-delta ,pred (idxc )+delta ]; 
end
end

end

function [pred ,se ,ci ]=predictSparse (this ,Xnew ,alpha ,useFIC )


























assert (alpha >=0 &&alpha <=1 ); 
assert (this .IsTrained ); 


XA =this .ActiveSetX ; 
NA =size (XA ,1 ); 



if(this .Standardize ==true )
Xnew =bsxfun (@rdivide ,bsxfun (@minus ,Xnew ,this .StdMu ' ),this .StdSigma ' ); 
end


alphaHat =this .AlphaHat ; 
betaHat =this .BetaHat ; 
thetaHat =this .ThetaHat ; 
sigmaHat =this .SigmaHat ; 


HFcn =this .HFcn ; %#ok<PROPLC,*PROP> 



kfun =makeKernelAsFunctionOfXNXM (this .Kernel ,thetaHat ); 


M =size (Xnew ,1 ); 


ifnargout >1 
wantse =true ; 
else
wantse =false ; 
end


ifnargout >2 
wantci =true ; 
else
wantci =false ; 
end



pred =zeros (M ,1 ); 
ifwantse 
se =zeros (M ,1 ); 
end
ifwantci 
ci =zeros (M ,2 ); 
zcrit =norminv (1 -alpha /2 ); 
end




if(wantse ||wantci )
ifisempty (this .LFactor )||isempty (this .LFactor2 )



error (message ('stats:classreg:learning:impl:GPImpl:GPImpl:NoCIsForFIC' )); 
else

L =this .LFactor ; 
LAA =this .LFactor2 ; 
assert (size (L ,1 )==NA ); 
assert (size (LAA ,1 )==NA ); 
end
end


if(wantse ||wantci )


ifuseFIC 
kfundiag =makeDiagKernelAsFunctionOfXN (this .Kernel ,thetaHat ); 
diagKnew =kfundiag (Xnew ); 
end
end








B =max (1 ,floor ((1e6 *this .CacheSize )/8 /NA )); 
nchunks =floor (M /B ); 


forc =1 :nchunks +1 

ifc <nchunks +1 
idxc =(c -1 )*B +1 :c *B ; 
else

idxc =nchunks *B +1 :M ; 
end

Xnewc =Xnew (idxc ,:); 

KXnewcXA =kfun (Xnewc ,XA ); 

pred (idxc )=KXnewcXA *alphaHat ; 
if~isempty (betaHat )
pred (idxc )=pred (idxc )+HFcn (Xnewc )*betaHat ; %#ok<PROPLC> 
end

ifwantse 
LinvKXAXnewc =L \KXnewcXA ' ; 
ifuseFIC 
LAAinvKXAXnewc =LAA \KXnewcXA ' ; 
se (idxc )=sqrt (max (0 ,sigmaHat ^2 +diagKnew (idxc )-sum (LAAinvKXAXnewc .^2 ,1 )' +sum (LinvKXAXnewc .^2 ,1 )' )); 
else
se (idxc )=sqrt (max (0 ,sigmaHat ^2 +sum (LinvKXAXnewc .^2 ,1 )' )); 
end
end

ifwantci 
delta =zcrit *se (idxc ); 
ci (idxc ,:)=[pred (idxc )-delta ,pred (idxc )+delta ]; 
end
end

end

function varargout =predict (this ,Xnew ,alpha )



















import classreg.learning.modelparams.GPParams ; 
switchlower (this .PredictMethod )
case lower (GPParams .PredictMethodExact )
[varargout {1 :nargout }]=predictExact (this ,Xnew ,alpha ); 

case lower (GPParams .PredictMethodBCD )
[varargout {1 :nargout }]=predictExact (this ,Xnew ,alpha ); 

case lower (GPParams .PredictMethodSD )
[varargout {1 :nargout }]=predictExact (this ,Xnew ,alpha ); 

case lower (GPParams .PredictMethodFIC )
useFIC =true ; 
[varargout {1 :nargout }]=predictSparse (this ,Xnew ,alpha ,useFIC ); 

case lower (GPParams .PredictMethodSR )
useFIC =false ; 
[varargout {1 :nargout }]=predictSparse (this ,Xnew ,alpha ,useFIC ); 
end

end

function [pred ,covmat ,ci ]=predictExactWithCov (this ,Xnew ,alpha )
































assert (alpha >=0 &&alpha <=1 ); 
assert (this .IsTrained ); 


X =this .ActiveSetX ; 
N =size (X ,1 ); 



if(this .Standardize ==true )
Xnew =bsxfun (@rdivide ,bsxfun (@minus ,Xnew ,this .StdMu ' ),this .StdSigma ' ); 
end


alphaHat =this .AlphaHat ; 
betaHat =this .BetaHat ; 
thetaHat =this .ThetaHat ; 
sigmaHat =this .SigmaHat ; 


HFcn =this .HFcn ; %#ok<PROPLC,*PROP> 



kfun =makeKernelAsFunctionOfXNXM (this .Kernel ,thetaHat ); 


M =size (Xnew ,1 ); 


ifnargout >1 
wantcovmat =true ; 
else
wantcovmat =false ; 
end


ifnargout >2 
wantci =true ; 
else
wantci =false ; 
end




if(wantcovmat ||wantci )
ifisempty (this .LFactor )

L =computeLFactorExact (this ,X ,thetaHat ,sigmaHat ); 
else

L =this .LFactor ; 
assert (size (L ,1 )==N ); 
end
end


KXnewX =kfun (Xnew ,X ); 
KXnewXnew =kfun (Xnew ,Xnew ); 


ifisempty (betaHat )
pred =KXnewX *alphaHat ; 
else
pred =HFcn (Xnew )*betaHat +KXnewX *alphaHat ; %#ok<PROPLC> 
end





ifwantcovmat 
LInvKXXnew =L \(KXnewX ' ); 
covmat =KXnewXnew -(LInvKXXnew ' *LInvKXXnew ); 
covmat (1 :M +1 :M ^2 )=max (0 ,covmat (1 :M +1 :M ^2 )+sigmaHat ^2 ); 
end
covmat =(covmat +covmat ' )/2 ; 



ifwantci 
zcrit =-norminv (alpha /2 ); 
sd =sqrt (diag (covmat )); 
delta =zcrit *sd ; 
ci =[pred -delta ,pred +delta ]; 
end

end
end

end

