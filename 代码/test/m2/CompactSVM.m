classdef CompactSVM %#codegen 






properties (SetAccess =protected ,GetAccess =public )


Alpha ; 


Beta ; 


Bias ; 


KernelParameters ; 


Mu ; 


Sigma ; 



SupportVectorsT ; 

end
methods (Access =protected )
function obj =CompactSVM (cgStruct )




coder .internal .prefer_const (cgStruct ); 


validateFields (cgStruct ); 

obj .Bias =cgStruct .Impl .Bias ; 
obj .Beta =cgStruct .Impl .Beta ; 
obj .SupportVectorsT =coder .const (@transpose ,cgStruct .Impl .SupportVectors ); 
obj .Mu =cgStruct .Impl .Mu ; 
obj .Sigma =cgStruct .Impl .Sigma ; 
obj .KernelParameters =cgStruct .Impl .KernelParameters ; 

end
end
methods (Static ,Hidden ,Abstract )

predictEmptySVMModel (obj )
end
methods (Access =protected )
function X =normalize (obj ,X )



mu =obj .Mu ; 
if~isempty (mu )&&~all (mu ==0 )
X =bsxfun (@minus ,X ,mu ); 
end

sigma =obj .Sigma ; 
if~isempty (sigma )&&~all (sigma ==1 )
nonzero =sigma >0 ; 
ifany (nonzero )
X (:,nonzero )=bsxfun (@rdivide ,X (:,nonzero ),sigma (nonzero )); 
end
end
end

function S =score (obj ,Xin )


coder .internal .prefer_const (obj ); 

bias =obj .Bias ; 
ifisa (Xin ,'double' )&&isa (bias ,'single' )
X =single (Xin ); 
else
X =Xin ; 
end

ifisempty (obj .Beta )&&isempty (obj .Alpha )
f =obj .predictEmptySVMModel (X ,bias ); 
else
coder .internal .errorIf (~coder .internal .isConst (size (X ,2 ))||coder .internal .indexInt (size (X ,2 ))~=obj .NumPredictors ,...
    'stats:classreg:learning:impl:CompactSVMImpl:score:BadXSize' ,obj .NumPredictors ); 


X =obj .normalize (X ); 


f =obj .kernelScore (X ); 
end
S =f ; 
end

function f =kernelScore (obj ,X )





coder .internal .prefer_const (obj ); 
validateattributes (obj .KernelParameters .Scale ,{'numeric' },{'scalar' ,'real' ,'positive' ,'nonnan' },mfilename ,'Scale' ); 
scale =cast (obj .KernelParameters .Scale ,'like' ,X ); 
kernelFcn =obj .KernelParameters .Function ; 
betas =obj .Beta ; 
svT =obj .SupportVectorsT ./scale ; 
alphas =obj .Alpha ; 
bias =obj .Bias ; 



switchkernelFcn 

case 'linear' 
ifisempty (alphas )
f =(X /scale )*betas +bias ; 
else
innerProduct =classreg .learning .coder .kernel .Linear (svT ,X ./scale ); 
f =innerProduct *alphas +bias ; 
end
case 'polynomial' 

validateattributes (obj .KernelParameters .PolyOrder ,{'numeric' },{'nonnan' ,'finite' ,'integer' ,'scalar' ,'real' ,'positive' },mfilename ,'PolyOrder' ); 
order =obj .KernelParameters .PolyOrder ; 
innerProduct =classreg .learning .coder .kernel .Poly (svT ,order ,X ./scale ); 
f =innerProduct *alphas +bias ; 
case {'rbf' ,'gaussian' }
svInnerProduct =dot (svT ,svT ); 
n =size (X ,1 ); 
f =coder .nullcopy (zeros (coder .internal .indexInt (n ),1 ,'like' ,X )); 
fori =1 :coder .internal .indexInt (n )
innerProduct =classreg .learning .coder .kernel .Gaussian (svT ,svInnerProduct ,X (i ,:)./scale ); 
f (i )=innerProduct *alphas +bias ; 
end
otherwise
kernelFunction =str2func (coder .const (kernelFcn )); 
n =size (X ,1 ); 
f =coder .nullcopy (zeros (coder .internal .indexInt (n ),1 ,'like' ,X )); 
fori =1 :coder .internal .indexInt (n )
innerProduct =kernelFunction (coder .const (obj .SupportVectorsT ' ),X (i ,:)); 
f (i )=innerProduct ' *alphas +bias ; 
end
end
end
end

methods (Static ,Access =protected )
function [posterior ]=svmPredictEmptyX (Xin ,K ,numPredictors ,bias )



Dpassed =coder .internal .indexInt (size (Xin ,2 )); 
str ='columns' ; 

coder .internal .errorIf (~coder .internal .isConst (Dpassed )||Dpassed ~=numPredictors ,...
    'stats:classreg:learning:classif:ClassificationModel:predictEmptyX:XSizeMismatch' ,numPredictors ,str ); 

ifisa (Xin ,'double' )&&isa (bias ,'single' )
X =single (Xin ); 
else
X =Xin ; 
end
posterior =repmat (coder .internal .nan ('like' ,X ),0 ,K ); 

end
end
methods (Static ,Hidden )
function props =matlabCodegenNontunableProperties (~)
props ={'KernelParameters' ,'SupportVectorsT' }; 
end
end
end

function validateFields (InStr )


coder .inline ('always' ); 


validateattributes (InStr .Impl .Bias ,{'numeric' },{'nonnan' ,'finite' ,'nonempty' ,'scalar' ,'real' },mfilename ,'Bias' ); 

if~isempty (InStr .Impl .Alpha )
validateattributes (InStr .Impl .Alpha ,{'numeric' },{'nonnan' ,'column' ,'real' },mfilename ,'Alpha' ); 
end

if~isempty (InStr .Impl .Beta )
validateattributes (InStr .Impl .Beta ,{'numeric' },{'column' ,'numel' ,InStr .DataSummary .NumPredictors ,'real' },mfilename ,'Beta' ); 
end

validateattributes (InStr .Impl .SupportVectors ,{'numeric' },{'2d' ,'nrows' ,size (InStr .Impl .Alpha ,1 ),'real' },mfilename ,'SupportVectors' ); 

if~isempty (InStr .Impl .Mu )
if~isempty (InStr .Impl .SupportVectors )
validateattributes (InStr .Impl .Mu ,{'numeric' },{'size' ,[1 ,size (InStr .Impl .SupportVectors ,2 )],'real' },mfilename ,'Mu' ); 
else
validateattributes (InStr .Impl .Mu ,{'numeric' },{'size' ,[1 ,size (InStr .Impl .Beta ,1 )],'real' },mfilename ,'Mu' ); 
end
end

if~isempty (InStr .Impl .Sigma )
if~isempty (InStr .Impl .SupportVectors )
validateattributes (InStr .Impl .Sigma ,{'numeric' },{'size' ,[1 ,size (InStr .Impl .SupportVectors ,2 )],'real' },mfilename ,'Sigma' ); 
else
validateattributes (InStr .Impl .Sigma ,{'numeric' },{'size' ,[1 ,size (InStr .Impl .Beta ,1 )],'real' },mfilename ,'Sigma' ); 
end
end
end


