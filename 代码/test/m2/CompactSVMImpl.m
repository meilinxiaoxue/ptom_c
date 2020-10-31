classdef CompactSVMImpl 



properties (SetAccess =protected ,GetAccess =public )
Alpha =[]; 
Beta =[]; 
Bias =[]; 
KernelParameters =[]; 
Mu =[]; 
NumPredictors =[]; 
Sigma =[]; 
SupportVectors =[]; 
SupportVectorLabels =[]; 
Epsilon =[]; 
end

methods (Access =protected )
function this =CompactSVMImpl ()
end
end

methods (Static )
function obj =fromStruct (s )
obj =classreg .learning .impl .CompactSVMImpl ; 

obj .Alpha =s .Alpha ; 
obj .Beta =s .Beta ; 
obj .Bias =s .Bias ; 
obj .KernelParameters =s .KernelParameters ; 
obj .Mu =s .Mu ; 
obj .NumPredictors =s .NumPredictors ; 
obj .Sigma =s .Sigma ; 
obj .SupportVectors =s .SupportVectors ; 
obj .SupportVectorLabels =s .SupportVectorLabels ; 
obj .Epsilon =s .Epsilon ; 
end
end

methods 
function f =score (this ,X ,doclass )

if~isfloat (X )||~ismatrix (X )
error (message ('stats:classreg:learning:impl:CompactSVMImpl:score:BadX' )); 
end
internal .stats .checkSupportedNumeric ('X' ,X ,false ,false ,false ,true ); 

alphas =this .Alpha ; 
betas =this .Beta ; 
bias =this .Bias ; 

ifisempty (alphas )&&isempty (betas )
ifdoclass 
f =NaN (size (X ,1 ),1 ,'like' ,bias ); 
else
f =zeros (size (X ,1 ),1 ,'like' ,bias )+bias ; 
end
return ; 
end

ifsize (X ,2 )~=this .NumPredictors 
error (message ('stats:classreg:learning:impl:CompactSVMImpl:score:BadXSize' ,this .NumPredictors )); 
end

mu =this .Mu ; 
if~isempty (mu )&&~all (mu ==0 )
X =bsxfun (@minus ,X ,mu ); 
end

sigma =this .Sigma ; 
if~isempty (sigma )&&~all (sigma ==1 )
nonzero =sigma >0 ; 
ifany (nonzero )
X (:,nonzero )=X (:,nonzero )./sigma (nonzero ); 
end
end

ifinternal .stats .typeof (X )=="double" &&...
    internal .stats .typeof (bias )=="single" 
X =single (X ); 
end

ifisempty (alphas )


f =(X /this .KernelParameters .Scale )*betas +bias ; 
else
ifdoclass 
alphas =alphas .*this .SupportVectorLabels ; 
end

f =iDispatchPredict (...
    alphas ,bias ,this .SupportVectors ,...
    this .KernelParameters .Function ,this .KernelParameters .PolyOrder ,...
    this .KernelParameters .Sigmoid ,...
    this .KernelParameters .Scale ,X ); 
end

end
function this =discardSupportVectors (this )
if~strcmp (this .KernelParameters .Function ,'linear' )
error (message ('stats:classreg:learning:impl:CompactSVMImpl:discardSupportVectors:CannotDiscardSVforNonlinearKernel' )); 
end

this .Alpha =[]; 
this .SupportVectors =[]; 
this .SupportVectorLabels =[]; 
end
end

end

function varargout =iDispatchPredict (alphas ,offset ,suppVectors ,kernelFun ,polyOrder ,sigmoidParams ,kernelScale ,X )
nout =nargout ; 
ifisa (X ,'gpuArray' )
[varargout {1 :nout }]=classreg .learning .svmutils .gpu .predict (alphas ,...
    offset ,suppVectors ' ,kernelFun ,polyOrder ,sigmoidParams ,kernelScale ,X ' ); 
else
[varargout {1 :nout }]=classreg .learning .svmutils .predict (alphas ,...
    offset ,suppVectors ,kernelFun ,polyOrder ,sigmoidParams ,kernelScale ,X ); 
end
end
