classdef ClassificationNaiveBayes <...
    classreg .learning .classif .FullClassificationModel &classreg .learning .classif .CompactClassificationNaiveBayes 
























































properties (GetAccess =protected ,SetAccess =protected )


PrivW =[]; 
end

methods (Hidden )
function this =ClassificationNaiveBayes (X ,Y ,W ,modelParams ,...
    dataSummary ,classSummary ,scoreTransform )
this =this @classreg .learning .classif .FullClassificationModel (...
    X ,Y ,W ,modelParams ,dataSummary ,classSummary ,scoreTransform ); 
this =this @classreg .learning .classif .CompactClassificationNaiveBayes (...
    dataSummary ,classSummary ,scoreTransform ,[],[],[],[]); 



this .DistributionNames =this .ModelParameters .DistributionNames ; 
ifischar (this .DistributionNames )&&~strcmp ('mn' ,this .DistributionNames )
this .DistributionNames =repmat ({this .DistributionNames },1 ,this .NumDims ); 
end




mvmns =find (strcmp ('mvmn' ,this .DistributionNames )); 
ifany (~ismember (mvmns ,this .CategoricalPredictors ))
warning (message ('stats:ClassificationNaiveBayes:ClassificationNaiveBayes:SomeMvmnNotCat' )); 
this .DataSummary .CategoricalPredictors =union (this .CategoricalPredictors (:)' ,mvmns ); 
end


this .PrivW =W ; 


this .CategoricalLevels =findCategoricalLevels (this .DistributionNames ,this .PrivX ); 


if~all (strcmp (this .DistributionNames ,'mvmn' ))&&~isfloat (this .PrivX )
internal .stats .checkSupportedNumeric ('X' ,this .PrivX ); 
end
ifstrcmp (this .DistributionNames ,'mn' )


this .DistributionParameters =fitMNDist (this ); 
else
this .DistributionParameters =fitNonMNDists (this ); 
end
end
end

methods 
function cmp =compact (this )








dataSummary =this .DataSummary ; 
dataSummary .RowsUsed =[]; 
cmp =classreg .learning .classif .CompactClassificationNaiveBayes (...
    dataSummary ,this .ClassSummary ,this .PrivScoreTransform ,this .PrivScoreType ,...
    this .DistributionNames ,this .DistributionParameters ,this .CategoricalLevels ); 
end
end

methods (Static ,Hidden )

function this =fit (X ,Y ,varargin )
temp =classreg .learning .FitTemplate .make (...
    'NaiveBayes' ,'type' ,'classification' ,varargin {:}); 
this =fit (temp ,X ,Y ); 
end


function temp =template (varargin )
temp =classreg .learning .FitTemplate .make (...
    'NaiveBayes' ,'type' ,'classification' ,varargin {:}); 
end
function [X ,Y ,W ,dataSummary ,classSummary ,scoreTransform ]=...
    prepareData (X ,Y ,varargin )
[X ,Y ,W ,dataSummary ,classSummary ,scoreTransform ]=...
    prepareData @classreg .learning .classif .FullClassificationModel (X ,Y ,varargin {:},'OrdinalIsCategorical' ,true ); 
end
end


methods (Access =protected )

function this =setPrior (this ,prior )
this =setPrior @classreg .learning .classif .CompactClassificationNaiveBayes (this ,prior ); 

C =classreg .learning .internal .classCount (this .ClassSummary .ClassNames ,this .PrivY ); 
WC =bsxfun (@times ,C ,this .PrivW ); 
Wj =sum (WC ,1 ); 
gt0 =Wj >0 ; 
this .W =sum (bsxfun (@times ,WC ,this .Prior (gt0 )./Wj (gt0 )),2 ); 
end

function distParams =fitMNDist (this )

classreg .learning .classif .CompactClassificationNaiveBayes .checkMNData (this .PrivX ); 
distParams =cell (this .NumClasses ,this .NumDims ); 
badRows =~isfinite (sum (this .PrivX ,2 )); 
ifany (badRows )
X =this .PrivX (~badRows ,:); 
W =this .W (~badRows ); 
Y =this .PrivY (~badRows ); 
else
X =this .PrivX ; 
W =this .W ; 
Y =this .PrivY ; 
end
ClassCount =classreg .learning .internal .classCount (this .ClassSummary .ClassNames ,Y ); 
WCC =W .*ClassCount ; 
f =(sum (ClassCount )./sum (WCC ))' ; 
WCCX =WCC ' *X ; 
posteriorWtdCounts =1 +f .*WCCX ; 
posteriorProbs =posteriorWtdCounts ./sum (posteriorWtdCounts ,2 ); 
forc =1 :this .NumClasses 
ifthis .NonzeroProbClasses (c )
distParams (c ,:)=num2cell (posteriorProbs (c ,:)); 
else
distParams (c ,:)={[]}; 
end
end
end

function distParams =fitNonMNDists (this )






NoDataCombos =findNoDataCombos (this ); 

ifany (NoDataCombos (:))
[row ,col ]=find (NoDataCombos ); 
fprintf ('  %14s   %14s\n' ,'Class Name' ,'Predictor Name' ); 
forn =1 :numel (col )
fprintf ('  %14s   %14s\n' ,...
    char (this .ClassSummary .ClassNames (row (n ))),this .PredictorNames {col (n )}); 
end
error (message ('stats:ClassificationNaiveBayes:ClassificationNaiveBayes:NoDataForUniFit' )); 
end
ClassCount =classreg .learning .internal .classCount (this .ClassSummary .ClassNames ,this .PrivY ); 
distParams =cell (this .NumClasses ,this .NumDims ); 
forc =1 :this .NumClasses 
ifthis .NonzeroProbClasses (c )
ford =1 :this .NumDims 

cRows =ClassCount (:,c ); 
x =this .PrivX (cRows ,d ); 
w =this .W (cRows ); 

nanRows =isnan (x ); 
x (nanRows )=[]; 
w (nanRows )=[]; 

ifstrcmp (this .DistributionNames {d },'normal' )&&var (x )==0 
error (message ('stats:ClassificationNaiveBayes:ClassificationNaiveBayes:ZeroVarianceForUniFit' ,...
    char (this .ClassSummary .ClassNames (c )),this .PredictorNames {d })); 
end

[Kernel ,Support ,Width ]=getKernelInputParams (this ,c ,d ); 

distParams {c ,d }=fitUnivariateDist (x ,w ,this .DistributionNames {d },...
    Kernel ,Support ,Width ,this .CategoricalLevels {d }); 
end
else
distParams (c ,:)={[]}; 
end
end
end

function NoDataCombos =findNoDataCombos (this )
NoDataCombos =false (this .NumClasses ,this .NumDims ); 
ClassCount =classreg .learning .internal .classCount (this .ClassSummary .ClassNames ,this .PrivY ); 
forc =1 :this .NumClasses 
ifthis .NonzeroProbClasses (c )
ford =1 :this .NumDims 

cRows =ClassCount (:,c ); 
x =this .PrivX (cRows ,d ); 

nanRows =isnan (x ); 
x (nanRows )=[]; 

NoDataCombos (c ,d )=isempty (x ); 
end
end
end
end

function L =examplesInClass (this ,Y ,classNum )


L =ismember (Y ,this .ClassSummary .ClassNames (classNum )); 
end

function [Kernel ,Support ,Width ]=getKernelInputParams (this ,c ,d )

kernelDims =this .KernelDims ; 
ifisempty (kernelDims )||~kernelDims (d )
Kernel =[]; 
Support =[]; 
Width =[]; 
else
MP =this .ModelParameters ; 

ifischar (MP .Kernel )
Kernel =MP .Kernel ; 
else
Kernel =MP .Kernel {d }; 
end

ifisnumeric (MP .Support )||ischar (MP .Support )
Support =MP .Support ; 
else
Support =MP .Support {d }; 
end

ifisscalar (MP .Width )
Width =MP .Width ; 
elseifsize (MP .Width ,1 )==1 
Width =MP .Width (d ); 
elseifsize (MP .Width ,2 )==1 
Width =MP .Width (c ); 
else
Width =MP .Width (c ,d ); 
end
end
end


function s =propsForDisp (this ,s )
s =propsForDisp @classreg .learning .classif .FullClassificationModel (this ,s ); 
s =propsForDisp @classreg .learning .classif .CompactClassificationNaiveBayes (this ,s ); 
end

end

end



function categoricalLevels =findCategoricalLevels (DistributionNames ,X )




D =size (X ,2 ); 
categoricalLevels =cell (1 ,D ); 
ifany (strcmp ('mvmn' ,DistributionNames ))
ford =1 :D 
ifstrcmp ('mvmn' ,DistributionNames {d })
nanRows =isnan (X (:,d )); 
categoricalLevels {d }=unique (X (~nanRows ,d )); 
end
end
end
end

function distParams =fitUnivariateDist (x ,w ,distName ,kernel ,support ,width ,categoricalLevels )




w =w /sum (w ); 

switchdistName 
case 'kernel' 
ifisnan (width )
width =[]; 
end
distParams =prob .KernelDistribution .fit (x ,...
    'frequency' ,w *length (w ),...
    'kernel' ,kernel ,'support' ,support ,'width' ,width ); 
case 'mvmn' 

posteriorCounts =ones (length (categoricalLevels ),1 ); 
[~,levelIndices ]=ismember (x ,categoricalLevels ); 
ifany (levelIndices )
wCounts =accumarray (levelIndices ,w ,size (categoricalLevels ))*length (levelIndices ); 
posteriorCounts =posteriorCounts +wCounts ; 
end
distParams =posteriorCounts /sum (posteriorCounts ); 
case 'normal' 


mu =x ' *w ; 
sigma =sqrt (classreg .learning .internal .wnanvar (x ,w ,1 )); 
distParams =[mu ; sigma ]; 
end
end

