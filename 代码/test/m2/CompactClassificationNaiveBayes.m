classdef CompactClassificationNaiveBayes <classreg .learning .classif .ClassificationModel 

































properties (GetAccess =public ,SetAccess =protected )



















DistributionNames =[]; 











































DistributionParameters =[]; 







CategoricalLevels =[]; 
end

properties (GetAccess =public ,SetAccess =protected ,Dependent =true )




Kernel 









Support 




Width 
end

properties (GetAccess =protected ,SetAccess =protected ,Dependent =true )

KernelDims 


NonzeroProbClasses 
end

properties (Hidden ,Dependent =true )

NumClasses 
NumDims 


NClasses 
NDims 
end

methods 
function [labels ,posterior ,cost ]=predict (this ,X ,varargin )















adapter =classreg .learning .internal .makeClassificationModelAdapter (this ,X ); 
if~isempty (adapter )
[labels ,posterior ,cost ]=predict (adapter ,X ); 
return ; 
end


vrange =getvrange (this ); 
X =classreg .learning .internal .table2PredictMatrix (X ,[],[],...
    vrange ,this .CategoricalPredictors ,getOptionalPredictorNames (this )); 


ifisempty (X )
[labels ,posterior ,cost ]=predictEmptyX (this ,X ); 
return ; 
end


scores =score (this ,X ,varargin {:}); 
posterior =internal .stats .softmax (scores ,2 ); 


MaxScores =max (scores ,[],2 ,'includenan' ); 
NegInfRows =isinf (MaxScores )&MaxScores <0 ; 
posterior (NegInfRows ,:)=repmat (this .Prior ,sum (NegInfRows ),1 ); 


[labels ,posterior ,cost ]=this .LabelPredictor (this .ClassNames ,...
    this .Prior ,this .Cost ,posterior ,this .PrivScoreTransform ); 
end

function L =logp (this ,X )











adapter =classreg .learning .internal .makeClassificationModelAdapter (this ,X ); 
if~isempty (adapter )
L =slice (adapter ,@this .logp ,X ); 
return 
end


vrange =getvrange (this ); 
X =classreg .learning .internal .table2PredictMatrix (X ,[],[],...
    vrange ,this .CategoricalPredictors ,getOptionalPredictorNames (this )); 



[S ,wasnan ]=score (this ,X ); 
L =internal .stats .logsumexp (S ,2 ); 


L (wasnan )=NaN ; 
end


function N =get .NumClasses (this )
N =numel (this .ClassSummary .ClassNames ); 
end

function N =get .NumDims (this )
N =numel (this .PredictorNames ); 
end

function N =get .NClasses (this )

N =this .NumClasses ; 
end

function N =get .NDims (this )

N =this .NumDims ; 
end

function K =get .Kernel (this )



ifstrcmp (this .DistributionNames ,'mn' )
K =[]; 
else
K =cell (1 ,this .NumDims ); 
kernelDims =this .KernelDims ; 
row =find (cellfun (@(p )~isempty (p ),this .DistributionParameters (:,1 )),1 ,'first' ); 
K (kernelDims )=cellfun (@(p )p .Kernel ,this .DistributionParameters (row ,kernelDims ),'UniformOutput' ,false ); 
end
end

function S =get .Support (this )



ifstrcmp (this .DistributionNames ,'mn' )
S =[]; 
else
S =cell (1 ,this .NumDims ); 
kernelDims =this .KernelDims ; 
row =find (cellfun (@(p )~isempty (p ),this .DistributionParameters (:,1 )),1 ,'first' ); 
S (kernelDims )=cellfun (@(p )p .Support .range ,this .DistributionParameters (row ,kernelDims ),'UniformOutput' ,false ); 
end
end

function W =get .Width (this )



ifstrcmp (this .DistributionNames ,'mn' )
W =[]; 
else
W =NaN (this .NumClasses ,this .NumDims ); 
nonemptyKernelCells =repmat (this .KernelDims ,this .NumClasses ,1 )&cellfun (@(p )~isempty (p ),this .DistributionParameters ); 
W (nonemptyKernelCells )=cellfun (@(p )double (p .BandWidth ),this .DistributionParameters (nonemptyKernelCells )); 
end
end

function L =get .KernelDims (this )

L =strcmp ('kernel' ,this .DistributionNames ); 
end

function L =get .NonzeroProbClasses (this )

L =ismember (this .ClassSummary .ClassNames ,this .ClassSummary .NonzeroProbClasses ); 
end
end

methods (Hidden )

function result =logP (this ,X )
result =logp (this ,X ); 
end
end

methods (Static ,Access =protected )
function checkMNData (X )


X =X (:); 
ifany (isfinite (X )&(X <0 |floor (X )~=X ))
error (message ('stats:ClassificationNaiveBayes:ClassificationNaiveBayes:BadDataForMN' )); 
end
end
end

methods (Access =protected )

function this =CompactClassificationNaiveBayes (dataSummary ,classSummary ,scoreTransform ,scoreType ,...
    DistributionNames ,DistributionParameters ,CategoricalLevels )
this =this @classreg .learning .classif .ClassificationModel (dataSummary ,classSummary ,scoreTransform ,scoreType ); 

this .DistributionNames =DistributionNames ; 
this .DistributionParameters =DistributionParameters ; 
this .CategoricalLevels =CategoricalLevels ; 
end


function [logPxc ,wasnan ]=score (this ,X )









ifnargout >=2 
wasnan =any (isnan (X ),2 ); 
end

if~isfloat (X )||~ismatrix (X )
error (message ('stats:ClassificationNaiveBayes:ClassificationNaiveBayes:BadX' )); 
end

ifsize (X ,2 )~=this .NumDims 
error (message ('stats:ClassificationNaiveBayes:ClassificationNaiveBayes:BadXSize' ,this .NumDims )); 
end

logPxc =zeros (size (X ,1 ),this .NumClasses ); 


ifischar (this .DistributionNames )&&strcmp (this .DistributionNames ,'mn' )
classreg .learning .classif .CompactClassificationNaiveBayes .checkMNData (X ); 
forc =1 :this .NumClasses 
ifthis .NonzeroProbClasses (c )
logPxc (:,c )=classreg .learning .internal .mnlogpdf (X ,cell2mat (this .DistributionParameters (c ,:)))...
    +log (this .Prior (c )); 
else

logPxc (:,c )=-Inf ; 
end
end
else

catlevels =this .CategoricalLevels ; 
forc =1 :this .NumClasses 
ifthis .NonzeroProbClasses (c )
logPxdgc =zeros (size (X ,1 ),this .NumDims ); 
ford =1 :this .NumDims 
logPxdgc (:,d )=univariateLogP (X (:,d ),this .DistributionNames {d },...
    this .DistributionParameters {c ,d },catlevels {d }); 
end

logPxc (:,c )=nansum (logPxdgc ,2 )+log (this .Prior (c )); 
else

logPxc (:,c )=-Inf ; 
end
end
end
end


function this =setPrior (this ,prior )
this =setPrivatePrior (this ,prior ); 
end

function this =setCost (this ,cost )
this =setPrivateCost (this ,cost ); 
end


function s =propsForDisp (this ,s )
s =propsForDisp @classreg .learning .classif .ClassificationModel (this ,s ); 
s .DistributionNames =this .DistributionNames ; 
s .DistributionParameters =this .DistributionParameters ; 
ifany (strcmp ('mvmn' ,this .DistributionNames ))
s .CategoricalLevels =this .CategoricalLevels ; 
end
ifany (this .KernelDims )
s .Kernel =this .Kernel ; 
s .Support =this .Support ; 
s .Width =this .Width ; 
end
end
end

methods (Static ,Access ='public' ,Hidden )

function this =make (dataSummary ,classSummary ,...
    DistributionNames ,DistributionParameters ,CategoricalLevels )

scoreTransform =@classreg .learning .transform .identity ; 

this =classreg .learning .classif .CompactClassificationNaiveBayes (...
    dataSummary ,classSummary ,scoreTransform ,[],...
    DistributionNames ,DistributionParameters ,CategoricalLevels ); 

end
end

end



function logPx =univariateLogP (x ,DistName ,DistParams ,categoricalLevels )


switchDistName 
case 'kernel' 
logPx =log (DistParams .pdf (x )); 
case 'mvmn' 
logPx =-Inf (size (x )); 
logPx (isnan (x ))=NaN ; 
[found ,levelIDs ]=ismember (x ,categoricalLevels ); 
logPx (found )=log (DistParams (levelIDs (found ))); 
case 'normal' 
logPx =classreg .learning .internal .normlogpdf (x ,DistParams (1 ),DistParams (2 )); 
end
end
