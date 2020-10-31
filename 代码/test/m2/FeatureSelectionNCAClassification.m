classdef FeatureSelectionNCAClassification <classreg .learning .fsutils .FeatureSelectionNCAModel 































































properties (Constant ,Hidden )
LossFunctionMSEProb ='quadratic' ; 
LossFunctionMisclassErr ='classiferror' ; 
BuiltInLossFunctions ={FeatureSelectionNCAClassification .LossFunctionMSEProb ,...
    FeatureSelectionNCAClassification .LossFunctionMisclassErr }; 
end


properties (GetAccess =public ,SetAccess =protected ,Dependent )





Y ; 









ClassNames ; 
end

properties (GetAccess =public ,SetAccess =protected ,Hidden ,Dependent )




PrivY ; 





YLabels ; 







YLabelsOrig ; 
end

properties (Hidden )



Impl ; 
end

methods 
function y =get .Y (this )
yid =this .PrivY ; 
y =this .YLabelsOrig (yid ,:); 
end

function cn =get .ClassNames (this )
cn =this .YLabels ; 
end

function privY =get .PrivY (this )
privY =this .Impl .PrivY ; 
end

function yLabels =get .YLabels (this )
yLabels =this .Impl .YLabels ; 
end

function yLabelsOrig =get .YLabelsOrig (this )
yLabelsOrig =this .Impl .YLabelsOrig ; 
end
end


methods (Hidden )
function this =FeatureSelectionNCAClassification (X ,Y ,varargin )
this =doFit (this ,X ,Y ,varargin {:}); 
end
end


methods 
function [labels ,postprobs ,classnames ]=predict (this ,XTest )












isok =FeatureSelectionNCAClassification .checkXType (XTest ); 
if~isok 
error (message ('stats:FeatureSelectionNCA:FeatureSelectionNCAClassification:BadXType' )); 
end


[M ,P ]=size (XTest ); 


if(P ~=this .NumFeatures )
error (message ('stats:FeatureSelectionNCA:FeatureSelectionNCAClassification:BadX' ,this .NumFeatures )); 
end


badrows =any (isnan (XTest ),2 ); 


XTest (badrows ,:)=[]; 


if(isempty (XTest ))
error (message ('stats:FeatureSelectionNCA:FeatureSelectionNCAClassification:NoObservationsInX' )); 
end






C =length (this .YLabels ); 
postprobs =nan (M ,C ,class (XTest )); 
computationMode =this .ModelParams .ComputationMode ; 
usemex =strcmpi (computationMode ,classreg .learning .fsutils .FeatureSelectionNCAModel .ComputationModeMex )&&~issparse (XTest ); 
ifusemex 
postprobs (~badrows ,:)=predictNCAMex (this .Impl ,XTest ); 
else
postprobs (~badrows ,:)=predictNCA (this .Impl ,XTest ); 
end


[~,id ]=max (postprobs (~badrows ,:),[],2 ); 



allid =ones (M ,1 ); 
allid (~badrows )=id ; 


labels =this .YLabelsOrig (allid ,:); 


classnames =this .YLabels ; 
end

function err =loss (this ,XTest ,YTest ,varargin )









































[varargin {:}]=convertStringsToChars (varargin {:}); 


dfltLossFunction =FeatureSelectionNCAClassification .LossFunctionMisclassErr ; 

paramNames ={'LossFunction' }; 
paramDflts ={dfltLossFunction }; 
lossType =internal .stats .parseArgs (paramNames ,paramDflts ,varargin {:}); 

lossType =internal .stats .getParamVal (lossType ,this .BuiltInLossFunctions ,'LossFunction' ); 


isok =FeatureSelectionNCAClassification .checkXType (XTest ); 
if~isok 
error (message ('stats:FeatureSelectionNCA:FeatureSelectionNCAClassification:BadXType' )); 
end


[M ,P ]=size (XTest ); 


if(P ~=this .NumFeatures )
error (message ('stats:FeatureSelectionNCA:FeatureSelectionNCAClassification:BadX' ,this .NumFeatures )); 
end



[isok ,yidTest ]=encodeCategorical (this ,YTest ); 
if~isok 
error (message ('stats:FeatureSelectionNCA:FeatureSelectionNCAClassification:BadYType' )); 
end
yidTest =yidTest (:); 





if(any (isnan (yidTest )))
error (message ('stats:FeatureSelectionNCA:FeatureSelectionNCAClassification:BadYLevels' )); 
end


if(M ~=length (yidTest ))
error (message ('stats:FeatureSelectionNCA:FeatureSelectionNCAClassification:BadY' ,M )); 
end


[XTest ,yidTest ]=FeatureSelectionNCAClassification .removeBadRows (XTest ,yidTest ,[]); 
if(isempty (XTest )||isempty (yidTest ))
error (message ('stats:FeatureSelectionNCA:FeatureSelectionNCAClassification:NoObservationsInXY' )); 
end
MNew =size (XTest ,1 ); 





computationMode =this .ModelParams .ComputationMode ; 
usemex =strcmpi (computationMode ,classreg .learning .fsutils .FeatureSelectionNCAModel .ComputationModeMex )&&~issparse (XTest ); 
ifusemex 
probs =predictNCAMex (this .Impl ,XTest ); 
else
probs =predictNCA (this .Impl ,XTest ); 
end

if(strcmpi (lossType ,FeatureSelectionNCAClassification .LossFunctionMisclassErr ))




[~,yidPred ]=max (probs ,[],2 ); 
misclasserr =sum (yidPred ~=yidTest )/MNew ; 
err =misclasserr ; 
else





idx =sub2ind (size (probs ),(1 :MNew )' ,yidTest ); 
probs (idx )=probs (idx )-1 ; 
L =mean (sum (probs .^2 ,2 )); 
err =L ; 
end
end
end


methods (Hidden )
function s =propsForDisp (this ,s )






s =propsForDisp @classreg .learning .fsutils .FeatureSelectionNCAModel (this ,s ); 


s .Y =this .Y ; 
s .W =this .W ; 
s .ClassNames =this .ClassNames ; 
end
end


methods (Hidden )
function [X ,yid ,W ,labels ,labelsOrig ]=setupXYW (this ,X ,Y ,W )
if(isempty (this .Impl ))



X =FeatureSelectionNCAClassification .validateX (X ); 


[yid ,labels ,labelsOrig ]=FeatureSelectionNCAClassification .validateY (Y ); 


W =FeatureSelectionNCAClassification .validateW (W ); 


N =size (X ,1 ); 
if(length (yid )~=N )
error (message ('stats:FeatureSelectionNCA:FeatureSelectionNCAClassification:BadYLength' )); 
end

if(length (W )~=N )
error (message ('stats:FeatureSelectionNCA:FeatureSelectionNCAClassification:BadWeights' ,N )); 
end


[X ,yid ,W ]=FeatureSelectionNCAClassification .removeBadRows (X ,yid ,W ); 


if(isempty (X )||isempty (yid )||isempty (W ))
error (message ('stats:FeatureSelectionNCA:FeatureSelectionNCAClassification:NoObservationsInXY' )); 
end


else



X =FeatureSelectionNCAClassification .validateX (X ); 



isok =FeatureSelectionNCAClassification .checkYType (Y ); 
if~isok 
error (message ('stats:FeatureSelectionNCA:FeatureSelectionNCAClassification:BadYType' )); 
end


[isok ,yid ]=encodeCategorical (this ,Y ); 
if~isok 
error (message ('stats:FeatureSelectionNCA:FeatureSelectionNCAClassification:BadYType' )); 
end
yid =yid (:); 
if(any (isnan (yid )))
error (message ('stats:FeatureSelectionNCA:FeatureSelectionNCAClassification:BadYLevels' )); 
end


W =FeatureSelectionNCAClassification .validateW (W ); 


N =size (X ,1 ); 
if(length (yid )~=N )
error (message ('stats:FeatureSelectionNCA:FeatureSelectionNCAClassification:BadYLength' )); 
end

if(length (W )~=N )
error (message ('stats:FeatureSelectionNCA:FeatureSelectionNCAClassification:BadWeights' ,N )); 
end


[X ,yid ,W ]=FeatureSelectionNCAClassification .removeBadRows (X ,yid ,W ); 


if(isempty (X )||isempty (yid )||isempty (W ))
error (message ('stats:FeatureSelectionNCA:FeatureSelectionNCAClassification:NoObservationsInXY' )); 
end



labels =this .YLabels ; 
labelsOrig =this .YLabelsOrig ; 
end
end

function [isok ,yidTestNew ]=encodeCategorical (this ,YTest )

isok =FeatureSelectionNCAClassification .checkYType (YTest ); 
if~isok 
yidTestNew =[]; 
return ; 
end




[yidTest ,labelsTest ]=grp2idx (YTest ); 


yidTestNew =nan (size (yidTest )); 



[~,loc ]=ismember (labelsTest ,this .YLabels ); 







M =length (labelsTest ); 
forj =1 :M 
k =loc (j ); 
if(k ~=0 )
yidTestNew (yidTest ==j )=k ; 
end
end
end
end


methods (Static ,Hidden )
function [yid ,labels ,labelsOrig ]=validateY (Y )

















isok =FeatureSelectionNCAClassification .checkYType (Y ); 
if~isok 
error (message ('stats:FeatureSelectionNCA:FeatureSelectionNCAClassification:BadYType' )); 
end



[yid ,labels ,labelsOrig ]=grp2idx (Y ); 
yid =yid (:); 
labels =labels (:); 
end

function isok =checkYType (Y )


isok1 =isvector (Y )&&(isa (Y ,'categorical' )||islogical (Y )||(isnumeric (Y )&&isreal (Y ))||iscellstr (Y )); 



isok2 =ischar (Y )&&ismatrix (Y ); 


isok =isok1 ||isok2 ; 
end
end
end