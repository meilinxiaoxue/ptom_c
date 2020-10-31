classdef NaiveBayesParams <classreg .learning .modelparams .ModelParams 










properties 
DistributionNames =[]; 
Kernel =[]; 
Support =[]; 
Width =[]; 
end

properties (Constant ,Access =protected )
LegalDistNames ={'kernel' ,'mvmn' ,'normal' }; 
LegalSupportNames ={'unbounded' ,'positive' }; 
LegalKernelNames ={'box' ,'epanechnikov' ,'normal' ,'triangle' }; 
LegalCatDistNames ={'mvmn' }; 
DefaultCatDistName ='mvmn' ; 
DefaultNumDistName ='normal' ; 
DefaultKernel ='normal' ; 
DefaultSupport ='unbounded' ; 
DefaultWidth =NaN ; 
end

methods (Access =protected )
function this =NaiveBayesParams (DistributionNames ,Kernel ,Support ,Width )
this =this @classreg .learning .modelparams .ModelParams ('NaiveBayes' ,'classification' ); 
this .DistributionNames =DistributionNames (:)' ; 
this .Kernel =Kernel ; 
this .Support =Support ; 
this .Width =Width ; 
end
end

methods (Static ,Hidden )
function [holder ,extraArgs ]=make (~,varargin )

args ={'DistributionNames' ,'Kernel' ,'Support' ,'Width' }; 
defs =cell (1 ,length (args )); 
[distributionNames ,kernel ,support ,width ,~,extraArgs ]...
    =internal .stats .parseArgs (args ,defs ,varargin {:}); 


holder =classreg .learning .modelparams .NaiveBayesParams (...
    distributionNames ,kernel ,support ,width ); 
end
end

methods (Hidden )
function this =fillDefaultParams (this ,~,~,~,dataSummary ,classSummary )
this =checkDistributionNames (this ,numDims (dataSummary ),dataSummary ); 
this =checkKernelArgs (this ,numClasses (classSummary ),numDims (dataSummary )); 
end
end

methods (Access =protected )
function this =checkDistributionNames (this ,NumDims ,dataSummary )
ifisempty (this .DistributionNames )
ifany (dataSummary .CategoricalPredictors )
this .DistributionNames =repmat ({this .DefaultNumDistName },1 ,NumDims ); 
this .DistributionNames (dataSummary .CategoricalPredictors )={this .DefaultCatDistName }; 
else
this .DistributionNames =this .DefaultNumDistName ; 
end
end
ifischar (this .DistributionNames )
ifstrcmpi (this .DistributionNames ,'mn' )
ifany (dataSummary .CategoricalPredictors )
error (message ('stats:classreg:learning:modelparams:NaiveBayesParams:NaiveBayesParams:MnAndCategorical' )); 
end
this .DistributionNames ='mn' ; 
else
[this .DistributionNames ,s ]=checkAndCompleteString (this .DistributionNames ,this .LegalDistNames ,3 ); 
ifisempty (this .DistributionNames )
error (message ('stats:classreg:learning:modelparams:NaiveBayesParams:NaiveBayesParams:DistributionNameUnknown' ,s )); 
end
end

DistCell =repmat ({this .DistributionNames },1 ,NumDims ); 
if~all (strcmpi (DistCell (dataSummary .CategoricalPredictors ),this .LegalCatDistNames ))
error (message ('stats:classreg:learning:modelparams:NaiveBayesParams:NaiveBayesParams:DistributionNameNotCat' )); 
end
elseifiscell (this .DistributionNames )
iflength (this .DistributionNames )~=NumDims 
error (message ('stats:classreg:learning:modelparams:NaiveBayesParams:NaiveBayesParams:DistributionNameBadLength' )); 
end
if~all (cellfun (@ischar ,this .DistributionNames ))
error (message ('stats:classreg:learning:modelparams:NaiveBayesParams:NaiveBayesParams:DistributionNameBadType' )); 
end
ifany (strcmpi ('mn' ,this .DistributionNames ))
error (message ('stats:classreg:learning:modelparams:NaiveBayesParams:NaiveBayesParams:MnInCellarray' )); 
end
ford =1 :NumDims 
[this .DistributionNames {d },s ]=checkAndCompleteString (this .DistributionNames {d },this .LegalDistNames ,3 ); 
ifisempty (this .DistributionNames {d })
error (message ('stats:classreg:learning:modelparams:NaiveBayesParams:NaiveBayesParams:DistributionNameUnknown' ,s )); 
end
end

if~all (strcmpi (this .DistributionNames (dataSummary .CategoricalPredictors ),this .LegalCatDistNames ))
error (message ('stats:classreg:learning:modelparams:NaiveBayesParams:NaiveBayesParams:DistributionNameNotCat' )); 
end
else
error (message ('stats:classreg:learning:modelparams:NaiveBayesParams:NaiveBayesParams:DistributionNameBadType' )); 
end
end

function this =checkKernelArgs (this ,NumClasses ,NumDims )
KernelDims =kernelDims (this .DistributionNames ,NumDims ); 
ifany (KernelDims )

ifisempty (this .Kernel )
this .Kernel =this .DefaultKernel ; 
end
ifisempty (this .Support )
this .Support =this .DefaultSupport ; 
end
ifisempty (this .Width )
this .Width =this .DefaultWidth ; 
end

this =checkKernel (this ,KernelDims ,NumDims ); 
this =checkSupport (this ,KernelDims ,NumDims ); 
this =checkWidth (this ,KernelDims ,NumClasses ,NumDims ); 
elseif~isempty (this .Kernel )
error (message ('stats:classreg:learning:modelparams:NaiveBayesParams:NaiveBayesParams:KernelArgButNoKernelDist' )); 
elseif~isempty (this .Support )
error (message ('stats:classreg:learning:modelparams:NaiveBayesParams:NaiveBayesParams:SupportArgButNoKernelDist' )); 
elseif~isempty (this .Width )
error (message ('stats:classreg:learning:modelparams:NaiveBayesParams:NaiveBayesParams:WidthArgButNoKernelDist' )); 
end
end

function this =checkKernel (this ,KernelDims ,NumDims )
if~isempty (this .Kernel )
ifischar (this .Kernel )
[this .Kernel ,s ]=checkAndCompleteString (this .Kernel ,this .LegalKernelNames ,3 ); 
ifisempty (this .Kernel )
error (message ('stats:classreg:learning:modelparams:NaiveBayesParams:NaiveBayesParams:KernelUnknown' ,s )); 
end
elseifiscell (this .Kernel )

iflength (this .Kernel )~=NumDims 
error (message ('stats:classreg:learning:modelparams:NaiveBayesParams:NaiveBayesParams:KernelBadLength' )); 
end

if~all (cellfun (@ischar ,this .Kernel (KernelDims )))
error (message ('stats:classreg:learning:modelparams:NaiveBayesParams:NaiveBayesParams:KernelBadType' )); 
end

ford =1 :NumDims 
ifKernelDims (d )
[this .Kernel {d },s ]=checkAndCompleteString (this .Kernel {d },this .LegalKernelNames ,3 ); 
ifisempty (this .Kernel {d })
error (message ('stats:classreg:learning:modelparams:NaiveBayesParams:NaiveBayesParams:KernelUnknown' ,s )); 
end
end
end
else
error (message ('stats:classreg:learning:modelparams:NaiveBayesParams:NaiveBayesParams:KernelBadType' )); 
end
end
end

function this =checkSupport (this ,KernelDims ,NumDims )
if~isempty (this .Support )
ifischar (this .Support )
[this .Support ,s ]=checkAndCompleteString (this .Support ,this .LegalSupportNames ,3 ); 
ifisempty (this .Support )
error (message ('stats:classreg:learning:modelparams:NaiveBayesParams:NaiveBayesParams:SupportUnknown' ,s )); 
end
elseifisnumeric (this .Support )&&length (this .Support )==2 
ifthis .Support (1 )>=this .Support (2 )
error (message ('stats:classreg:learning:modelparams:NaiveBayesParams:NaiveBayesParams:SupportBadOrder' )); 
end
elseifiscell (this .Support )

iflength (this .Support )~=NumDims 
error (message ('stats:classreg:learning:modelparams:NaiveBayesParams:NaiveBayesParams:SupportBadLength' )); 
end

ford =1 :NumDims 
ifKernelDims (d )
ifischar (this .Support {d })
[this .Support {d },s ]=checkAndCompleteString (this .Support {d },this .LegalSupportNames ,3 ); 
ifisempty (this .Support {d })
error (message ('stats:classreg:learning:modelparams:NaiveBayesParams:NaiveBayesParams:SupportUnknown' ,s )); 
end
elseifisnumeric (this .Support {d })&&length (this .Support {d })==2 
ifthis .Support {d }(1 )>=this .Support {d }(2 )
error (message ('stats:classreg:learning:modelparams:NaiveBayesParams:NaiveBayesParams:SupportBadOrder' )); 
end
else
error (message ('stats:classreg:learning:modelparams:NaiveBayesParams:NaiveBayesParams:SupportEntryBadType' )); 
end
end
end
else
error (message ('stats:classreg:learning:modelparams:NaiveBayesParams:NaiveBayesParams:SupportBadType' )); 
end
end
end

function this =checkWidth (this ,KernelDims ,NumClasses ,NumDims )
if~isempty (this .Width )
w =this .Width ; 

if~isnumeric (w )
error (message ('stats:classreg:learning:modelparams:NaiveBayesParams:NaiveBayesParams:WidthBadType' )); 
end


ifisscalar (w )
w =repmat (w ,NumClasses ,NumDims ); 
elseifall (size (w )==[NumClasses ,1 ])
w =repmat (w ,1 ,NumDims ); 
elseifall (size (w )==[1 ,NumDims ])
w =repmat (w ,NumClasses ,1 ); 
elseifall (size (w )==[NumClasses ,NumDims ])
else
error (message ('stats:classreg:learning:modelparams:NaiveBayesParams:NaiveBayesParams:WidthBadSize' )); 
end



kW =w (:,KernelDims ); 
kW =kW (~isnan (kW )); 
if~all (kW (:)>0 )
error (message ('stats:classreg:learning:modelparams:NaiveBayesParams:NaiveBayesParams:WidthNotPositive' )); 
end
end
end
end
end

function N =numClasses (classSummary )
N =numel (classSummary .ClassNames ); 
end

function N =numDims (dataSummary )


ifiscell (dataSummary .PredictorNames )
N =numel (dataSummary .PredictorNames ); 
else
N =dataSummary .PredictorNames ; 
end
end

function [StringOut ,StringIn ]=checkAndCompleteString (StringIn ,LegalStrings ,PrefixLength )




i =find (strncmpi (StringIn ,LegalStrings ,PrefixLength ),1 ,'first' ); 
ifisempty (i )
StringOut =[]; 
else
StringOut =LegalStrings {i }; 
end
end

function KernelDims =kernelDims (DistributionNames ,NumDims )


ifischar (DistributionNames )
DistributionNames =repmat ({DistributionNames },1 ,NumDims ); 
end
KernelDims =strcmpi ('kernel' ,DistributionNames ); 
end