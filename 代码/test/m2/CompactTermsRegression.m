


classdef CompactTermsRegression %#codegen 

properties (SetAccess =protected ,GetAccess =public )

RespLoc ; 

PredLocs ; 

FormulaTerms ; 

hasIntercept ; 

Coefs ; 

CoefficientCovariance ; 

DFE ; 

NumPredictors ; 

NumVariables ; 

end

methods (Access =protected )
function obj =CompactTermsRegression (cgStruct )




coder .internal .prefer_const (cgStruct ); 


validateFields (cgStruct ); 
obj .hasIntercept =cgStruct .hasIntercept ; 
obj .Coefs =cgStruct .Coefs ; 
obj .CoefficientCovariance =cgStruct .CoefficientCovariance ; 
obj .DFE =cgStruct .DFE ; 
obj .NumPredictors =cgStruct .NumPredictors ; 
obj .NumVariables =cgStruct .NumVariables ; 
obj .RespLoc =cgStruct .RespLoc ; 
obj .PredLocs =cgStruct .PredLocs ; 
obj .FormulaTerms =cgStruct .FormulaTerms ; 
end

function design =designMatrix (obj ,Xin )



ifisa (Xin ,'single' )
classToCast ='single' ; 
else
classToCast ='double' ; 
end

resploc =cast (obj .RespLoc ,classToCast ); 
predlocs =cast (obj .PredLocs ,classToCast ); 
terms =cast (obj .FormulaTerms ,classToCast ); 
nterms =size (terms ,1 ); 
defaultModel =sum (sum (terms ))==nterms -1 ...
    &&all (terms (2 :nterms +1 :end)==1 ); 

nvars =obj .NumVariables ; 
npredX =nvars -1 ; 
npreds =obj .NumPredictors ; 
coder .internal .errorIf ((~isfloat (Xin )||~coder .internal .isConst (ismatrix (Xin ))||~ismatrix (Xin )),...
    'stats:classreg:learning:impl:CompactSVMImpl:score:BadX' ); 
sizeNotMatch =(size (Xin ,2 )~=npredX ); 
coder .internal .errorIf (~coder .internal .isConst (size (Xin ,2 ))||sizeNotMatch ,...
    'stats:classreg:regr:TermsRegression:WrongXColumns' ,npredX ); 
predTerms =zeros (nterms ,npreds ,classToCast ); 
fori =1 :npreds 
predTerms (:,i )=terms (:,predlocs (i )); 
end
ifdefaultModel 
linTerms =zeros (size (Xin ,1 ),npreds ,classToCast ); 
fori =1 :npreds 
linTerms (:,i )=Xin (:,predlocs (i )); 
end
design =[ones (size (Xin ,1 ),1 ,classToCast ),linTerms ]; 
else
Xdes =zeros (size (Xin ,1 ),npreds ); 
ifisequal (npreds ,npredX )
Xdes =Xin ; 
else
ind =coder .internal .indexInt (-1 ); 
j =coder .internal .indexInt (1 ); 
whilej <=npreds 
ifresploc <predlocs (j )
ind =j ; 
break; 
end
j =coder .internal .indexPlus (j ,1 ); 
end

whileind ~=-1 &&ind <=npreds 
predlocs (ind )=predlocs (ind )-1 ; 
ind =coder .internal .indexPlus (ind ,1 ); 
end
fori =1 :npreds 
Xdes (:,i )=Xin (:,predlocs (i )); 
end
end
design =designmatrix (Xdes ,predTerms ,coder .const (obj .hasIntercept )); 
end
end
end

methods (Abstract )
[ypred ,yci ]=predict (obj )
ysim =random (obj )
end
methods (Static ,Hidden )
function props =matlabCodegenNontunableProperties (~)
props ={'CoefficientCovariance' ,'DFE' ,'hasIntercept' ,'Coefs' ,...
    'NumVariables' ,'NumPredictors' ,'FormulaTerms' ,'PredLocs' }; 
end
end
methods (Static ,Access =protected )
function cgStruct =codegenStruct (str )%#codegen 




coder .internal .prefer_const (str ); 
coder .inline ('always' ); 

cgStruct .RespLoc =str .RespLoc ; 
cgStruct .PredLocs =str .PredLocs (:); 
cgStruct .NumPredictors =str .NumPredictors ; 
cgStruct .NumVariables =str .NumVariables ; 
coder .internal .assert (isfield (str .Formula ,'Terms' ),...
    'stats:classreg:regr:coder:TermsRegression:MissingFields' ,'Terms' ); 
coder .internal .assert (isfield (str .Formula ,'hasIntercept' ),...
    'stats:classreg:regr:coder:TermsRegression:MissingFields' ,'hasIntercept' ); 
cgStruct .FormulaTerms =str .Formula .Terms ; 
cgStruct .hasIntercept =str .Formula .hasIntercept ; 
cgStruct .Coefs =str .Coefs ; 
cgStruct .CoefficientCovariance =str .CoefficientCovariance ; 
cgStruct .DFE =str .DFE ; 

end
end
end


function validateFields (cgStruct )


coder .inline ('always' ); 

validateattributes (cgStruct .Coefs ,{'double' ,'single' },{'nonempty' ,'column' ,'real' },mfilename ,'Coefficients' ); 
validateattributes (cgStruct .CoefficientCovariance ,{'double' ,'single' },{'nonempty' ,'real' ,'size' ,[size (cgStruct .Coefs ,1 ),size (cgStruct .Coefs ,1 )]},mfilename ,'CoefficientCovariance' ); 
validateattributes (cgStruct .NumPredictors ,{'double' ,'single' },{'nonempty' ,'nonnan' ,'finite' ,'real' ,'positive' ,'scalar' ,'integer' },mfilename ,'NumPredictors' ); 
validateattributes (cgStruct .NumVariables ,{'double' ,'single' },{'nonempty' ,'nonnan' ,'finite' ,'real' ,'positive' ,'scalar' ,'integer' },mfilename ,'NumVariables' ); 
validateattributes (cgStruct .RespLoc ,{'double' ,'single' },{'nonempty' ,'nonnan' ,'finite' ,'real' ,'positive' ,'scalar' ,'integer' ,'<=' ,cgStruct .NumVariables },mfilename ,'RespLoc' ); 
validateattributes (cgStruct .PredLocs ,{'double' ,'single' },{'nonempty' ,'nonnan' ,'finite' ,'real' ,'positive' ,'vector' ,'integer' ,'<=' ,cgStruct .NumVariables ,'numel' ,cgStruct .NumPredictors },mfilename ,'PredLocs' ); 
validateattributes (cgStruct .FormulaTerms ,{'double' ,'single' },{'nonempty' ,'nonnan' ,'finite' ,'real' ,'nonnegative' ,'integer' ,'size' ,[size (cgStruct .Coefs ,1 ),cgStruct .NumVariables ]},mfilename ,'FormulaTerms' ); 
validateattributes (cgStruct .hasIntercept ,{'logical' },{'nonempty' ,'scalar' },mfilename ,'hasIntercept' ); 
validateattributes (cgStruct .DFE ,{'double' ,'single' },{'nonempty' ,'nonnan' ,'finite' ,'scalar' ,'real' ,'positive' ,'integer' },mfilename ,'DFE' ); 

end

function [X ]=designmatrix (data ,predTerms ,includeIntercept )




coder .internal .prefer_const (predTerms ,includeIntercept ); 
[nobs ,nvars ]=size (data ); 
[predrow ,~]=size (predTerms ); 


interceptRow =~any (predTerms ,2 ); 
coder .internal .errorIf (~includeIntercept &&any (interceptRow ),...
    'stats:classreg:regr:modelutils:InterceptAmbiguous' ); 
ifincludeIntercept &&all (~interceptRow )

terms =[zeros (1 ,nvars ); predTerms ]; 
else
terms =predTerms ; 
end

outClass =class (data ); 

X =zeros (nobs ,predrow ,outClass ); 

indices =sum (terms )~=0 ; 
cols2varsMain =diag (indices ); 
forj =1 :predrow 
term =terms (j ,:); 
varsj =find (terms (j ,:)); 
if~any (term )
Xj =ones (nobs ,1 ,outClass ); 
else
colsj =cols2varsMain (varsj (1 ),:); 
ind =findNonZeroIndex (colsj ); 
Xj =data (:,ind ); 
expon =cast (terms (j ,varsj (1 )),outClass ); 
ifexpon >1 
ifsize (Xj ,2 )==1 
Xj =Xj .^expon ; 
else
Xj1 =Xj ; 
fore =2 :expon 
[rep1 ,rep2 ]=allpairs2 (1 :size (Xj1 ,2 ),1 :size (Xj ,2 )); 
Xj =Xj1 (:,rep1 ).*Xj (:,rep2 ); 
end
end
end
fork =2 :length (varsj )
colsjk =cols2varsMain (varsj (k ),:); 
ind =findNonZeroIndex (colsjk ); 
Xjk =data (:,ind ); 
expon =cast (terms (j ,varsj (k )),outClass ); 
ifexpon >1 
ifsize (Xjk ,2 )==1 
Xjk =Xjk .^expon ; 
else
Xjk1 =Xjk ; 
fore =2 :expon 
[rep1 ,rep2 ]=allpairs2 (1 :size (Xjk1 ,2 ),1 :size (Xjk ,2 )); 
Xjk =Xjk1 (:,rep1 ).*Xjk (:,rep2 ); 
end
end
end
[rep1 ,rep2 ]=allpairs2 (1 :size (Xj ,2 ),1 :size (Xjk ,2 )); 
Xj =Xj (:,rep1 ).*Xjk (:,rep2 ); 
end
end
X (:,j )=Xj ; 
end
end



function [rep1 ,rep2 ]=allpairs2 (i ,j )
[rep1 ,rep2 ]=ndgrid (i ,j ); 
rep1 =rep1 (:)' ; 
rep2 =rep2 (:)' ; 
end

function ind =findNonZeroIndex (vector )

ind =zeros (1 ,1 ); 
fori =1 :length (vector )
ifvector (i )~=0 
ind =i ; 
return ; 
end
end
end


