classdef FeatureSelectionNCARegression <classreg .learning .fsutils .FeatureSelectionNCAModel 

























































properties (Constant ,Hidden )
LossFunctionMSE ='mse' ; 
LossFunctionMAD ='mad' ; 
BuiltInLossFunctions ={FeatureSelectionNCARegression .LossFunctionMSE ,...
    FeatureSelectionNCARegression .LossFunctionMAD }; 
end


properties (GetAccess =public ,SetAccess =protected ,Dependent )



Y ; 
end

properties (GetAccess =public ,SetAccess =protected ,Hidden ,Dependent )



PrivY ; 
end

properties (Hidden )



Impl ; 
end

methods 
function y =get .Y (this )
y =this .PrivY ; 
end

function privY =get .PrivY (this )
privY =this .Impl .PrivY ; 
end
end


methods (Hidden )
function this =FeatureSelectionNCARegression (X ,Y ,varargin )
this =doFit (this ,X ,Y ,varargin {:}); 
end
end


methods 
function ypred =predict (this ,XTest )








isok =FeatureSelectionNCARegression .checkXType (XTest ); 
if~isok 
error (message ('stats:FeatureSelectionNCA:FeatureSelectionNCARegression:BadXType' )); 
end


[M ,P ]=size (XTest ); 


if(P ~=this .NumFeatures )
error (message ('stats:FeatureSelectionNCA:FeatureSelectionNCARegression:BadX' ,this .NumFeatures )); 
end


badrows =any (isnan (XTest ),2 ); 


XTest (badrows ,:)=[]; 


if(isempty (XTest ))
error (message ('stats:FeatureSelectionNCA:FeatureSelectionNCARegression:NoObservationsInX' )); 
end




ypred =nan (M ,1 ); 
computationMode =this .ModelParams .ComputationMode ; 
usemex =strcmpi (computationMode ,classreg .learning .fsutils .FeatureSelectionNCAModel .ComputationModeMex )&&~issparse (XTest ); 
ifusemex 
ypredNotBad =predictNCAMex (this .Impl ,XTest ); 
else
ypredNotBad =predictNCA (this .Impl ,XTest ); 
end
ypred (~badrows )=ypredNotBad ; 
end

function L =loss (this ,XTest ,YTest ,varargin )



























[varargin {:}]=convertStringsToChars (varargin {:}); 


dfltLossFunction =FeatureSelectionNCARegression .LossFunctionMSE ; 

paramNames ={'LossFunction' }; 
paramDflts ={dfltLossFunction }; 
lossType =internal .stats .parseArgs (paramNames ,paramDflts ,varargin {:}); 

lossType =internal .stats .getParamVal (lossType ,this .BuiltInLossFunctions ,'LossFunction' ); 


isok =FeatureSelectionNCARegression .checkXType (XTest ); 
if~isok 
error (message ('stats:FeatureSelectionNCA:FeatureSelectionNCARegression:BadXType' )); 
end


[M ,P ]=size (XTest ); 


if(P ~=this .NumFeatures )
error (message ('stats:FeatureSelectionNCA:FeatureSelectionNCARegression:BadX' ,this .NumFeatures )); 
end


isok =FeatureSelectionNCARegression .checkYType (YTest ); 
if~isok 
error (message ('stats:FeatureSelectionNCA:FeatureSelectionNCARegression:BadYType' )); 
end
YTest =YTest (:); 


if(M ~=length (YTest ))
error (message ('stats:FeatureSelectionNCA:FeatureSelectionNCARegression:BadY' ,M )); 
end


[XTest ,YTest ]=FeatureSelectionNCARegression .removeBadRows (XTest ,YTest ,[]); 
if(isempty (XTest )||isempty (YTest ))
error (message ('stats:FeatureSelectionNCA:FeatureSelectionNCARegression:NoObservationsInXY' )); 
end
MNew =size (XTest ,1 ); 


computationMode =this .ModelParams .ComputationMode ; 
usemex =strcmpi (computationMode ,classreg .learning .fsutils .FeatureSelectionNCAModel .ComputationModeMex )&&~issparse (XTest ); 
ifusemex 
ypred =predictNCAMex (this .Impl ,XTest ); 
else
ypred =predictNCA (this .Impl ,XTest ); 
end


if(strcmpi (lossType ,FeatureSelectionNCARegression .LossFunctionMSE ))
r =ypred -YTest ; 
L =(r ' *r )/MNew ; 
else
r =ypred -YTest ; 
L =sum (abs (r ))/MNew ; 
end
end
end


methods (Hidden )
function s =propsForDisp (this ,s )






s =propsForDisp @classreg .learning .fsutils .FeatureSelectionNCAModel (this ,s ); 


s .Y =this .Y ; 
s .W =this .W ; 
end
end


methods (Hidden )
function [X ,Y ,W ,labels ,labelsOrig ]=setupXYW (~,X ,Y ,W )

X =FeatureSelectionNCARegression .validateX (X ); 


Y =FeatureSelectionNCARegression .validateY (Y ); 


W =FeatureSelectionNCARegression .validateW (W ); 


N =size (X ,1 ); 
if(length (Y )~=N )
error (message ('stats:FeatureSelectionNCA:FeatureSelectionNCARegression:BadYLength' )); 
end

if(length (W )~=N )
error (message ('stats:FeatureSelectionNCA:FeatureSelectionNCARegression:BadWeights' ,N )); 
end


[X ,Y ,W ]=FeatureSelectionNCARegression .removeBadRows (X ,Y ,W ); 


if(isempty (X )||isempty (Y )||isempty (W ))
error (message ('stats:FeatureSelectionNCA:FeatureSelectionNCARegression:NoObservationsInXY' )); 
end



labels =[]; 
labelsOrig =[]; 
end
end


methods (Static ,Hidden )
function Y =validateY (Y )





isok =FeatureSelectionNCARegression .checkYType (Y ); 
if~isok 
error (message ('stats:FeatureSelectionNCA:FeatureSelectionNCARegression:BadYType' )); 
end


Y =Y (:); 
end

function isok =checkYType (Y )

isok =isfloat (Y )&&isreal (Y )&&isvector (Y ); 
end
end
end