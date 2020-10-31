classdef ClassifByBinaryRegr <...
    classreg .learning .classif .FullClassificationModel &classreg .learning .classif .CompactClassifByBinaryRegr 





methods (Hidden )
function this =ClassifByBinaryRegr (X ,Y ,W ,modelParams ,dataSummary ,classSummary ,scoreTransform )

this =this @classreg .learning .classif .FullClassificationModel (...
    X ,Y ,W ,modelParams ,dataSummary ,classSummary ,scoreTransform ); 
this =this @classreg .learning .classif .CompactClassifByBinaryRegr (...
    dataSummary ,classSummary ,scoreTransform ,[]); 


K =numel (classSummary .ClassNames ); 
ifK >2 
error (message ('stats:classreg:learning:classif:ClassifByBinaryRegr:ClassifByBinaryRegr:NotBinaryProblem' )); 
end


if~isnumeric (this .Y )
error (message ('stats:classreg:learning:classif:ClassifByBinaryRegr:ClassifByBinaryRegr:BadY' )); 
end


this .CompactRegressionLearner =compact (...
    fit (this .ModelParams .RegressionTemplate ,this .X ,this .Y ,'weights' ,this .W )); 
end
end

methods (Access =protected )
function s =propsForDisp (this ,s )
s =propsForDisp @classreg .learning .classif .FullClassificationModel (this ,s ); 
s .CompactRegressionLearner =this .CompactRegressionLearner ; 
end
end

methods 
function cmp =compact (this )
cmp =classreg .learning .classif .CompactClassifByBinaryRegr (...
    this .DataSummary ,this .ClassSummary ,this .PrivScoreTransform ,...
    this .CompactRegressionLearner ); 
end
end

methods (Static )
function this =fit (X ,Y ,varargin )
temp =classreg .learning .FitTemplate .make (...
    'ByBinaryRegr' ,'type' ,'classification' ,varargin {:}); 
this =fit (temp ,X ,Y ); 
end
end

methods (Static ,Hidden )




function [X ,Y ,W ,dataSummary ,classSummary ,scoreTransform ]=prepareData (X ,Y ,varargin )

args ={'classnames' ,'cost' ,'prior' ,'scoretransform' }; 
defs ={[],[],[],[]}; 
[classnames ,cost ,prior ,transformer ,~,crArgs ]=...
    internal .stats .parseArgs (args ,defs ,varargin {:}); 


ifisempty (classnames )
error (message ('stats:classreg:learning:classif:ClassifByBinaryRegr:prepareData:NoClassInfo' )); 
end
classnames =classreg .learning .internal .ClassLabel (classnames ); 
K =length (classnames ); 
ifK >2 
error (message ('stats:classreg:learning:classif:ClassifByBinaryRegr:prepareData:TooManyClasses' )); 
end


if~isnumeric (Y )
error (message ('stats:classreg:learning:classif:ClassifByBinaryRegr:prepareData:BadYType' )); 
end


[X ,Y ,W ,dataSummary ]=...
    classreg .learning .FullClassificationRegressionModel .prepareDataCR (...
    X ,classreg .learning .internal .ClassLabel (Y ),crArgs {:}); 


[X ,Y ,W ,dataSummary .RowsUsed ]=classreg .learning .classif .FullClassificationModel .removeMissingVals (X ,Y ,W ,dataSummary .RowsUsed ); 


Ynum =labels (Y ); 
C =false (numel (Ynum ),K ); 
C (:,1 )=Ynum >0 ; 
ifK >1 
C (:,2 )=Ynum <0 ; 
end
WC =bsxfun (@times ,C ,W ); 
Wj =sum (WC ,1 ); 
ifall (Wj <=0 )
error (message ('stats:classreg:learning:classif:ClassifByBinaryRegr:prepareData:NoClassesWithPositivePrior' )); 
end


prior =classreg .learning .classif .FullClassificationModel .processPrior (...
    prior ,Wj ,classnames ,classnames ); 


cost =classreg .learning .classif .FullClassificationModel .processCost (...
    cost ,prior ,classnames ,classnames ); 




prior =prior /sum (prior ); 
zeroWj =Wj ==0 ; 
W =sum (bsxfun (@times ,WC (:,~zeroWj ),prior (~zeroWj )./Wj (~zeroWj )),2 ); 


classSummary .ClassNames =classnames ; 
classSummary .NonzeroProbClasses =classnames ; 
classSummary .Prior =prior ; 
classSummary .Cost =cost ; 


scoreTransform =...
    classreg .learning .classif .FullClassificationModel .processScoreTransform (transformer ); 
end
end

end
