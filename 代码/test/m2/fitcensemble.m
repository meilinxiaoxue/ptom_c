function obj =fitcensemble (X ,Y ,varargin )



























































































































































internal .stats .checkNotTall (upper (mfilename ),0 ,X ,Y ,varargin {:}); 

ifnargin >1 
Y =convertStringsToChars (Y ); 
end

ifnargin >2 
[varargin {:}]=convertStringsToChars (varargin {:}); 
end

[IsOptimizing ,RemainingArgs ]=classreg .learning .paramoptim .parseOptimizationArgs (varargin ); 
ifIsOptimizing 
obj =classreg .learning .paramoptim .fitoptimizing ('fitcensemble' ,X ,Y ,varargin {:}); 
else
Names ={'Method' ,'NumLearningCycles' ,'Learners' }; 
Defaults ={[],100 ,[]}; 
[Method ,NumLearningCycles ,Learners ,~,RemainingArgs ]=internal .stats .parseArgs (...
    Names ,Defaults ,RemainingArgs {:}); 
if~isempty (Learners )
checkLearners (Learners ); 
end
ifisempty (Method )
Method =chooseDefaultMethod (Learners ,X ,Y ,RemainingArgs ); 
else
checkMethod (Method ); 
end
ifisempty (Learners )
Learners =chooseDefaultLearners (Method ); 
end
ifisBoostingMethod (Method )
Learners =setTreeDefaultsIfAny (Learners ); 
end
obj =fitensemble (X ,Y ,Method ,NumLearningCycles ,Learners ,...
    RemainingArgs {:},'Type' ,'classification' ); 
end
end

function checkMethod (Method )
if~ischar (Method )
error (message ('stats:fitensemble:MethodNameNotChar' )); 
end
if~any (strncmpi (Method ,classreg .learning .ensembleModels (),length (Method )))
error (message ('stats:fitensemble:BadMethod' ,Method )); 
end
end

function checkLearners (Learners )
if~(ischar (Learners )||isa (Learners ,'classreg.learning.FitTemplate' )||...
    iscell (Learners )&&all (cellfun (@(Tmp )isa (Tmp ,'classreg.learning.FitTemplate' ),Learners )))
error (message ('stats:fitensemble:BadLearners' )); 
end
end

function Method =chooseDefaultMethod (Learners ,X ,Y ,NVPs )
ifonlyLearnerTypes (Learners ,{'knn' ,'discriminant' })
Method ='Subspace' ; 
elseifallLearnerTypes (Learners ,{'tree' ,'discriminant' })
ifnumClasses (X ,Y ,NVPs )>2 
Method ='AdaboostM2' ; 
else
Method ='AdaBoostM1' ; 
end
else

ifnumClasses (X ,Y ,NVPs )>2 
Method ='AdaboostM2' ; 
else
Method ='LogitBoost' ; 
end
end
end

function tf =isBoostingMethod (Method )
tf =ischar (Method )&&~isempty (strfind (lower (Method ),'boost' )); 
end

function tf =onlyLearnerTypes (Learners ,Types )

ifisempty (Learners )
tf =false ; 
elseifischar (Learners )
tf =ismember (lower (Learners ),Types ); 
elseifisa (Learners ,'classreg.learning.FitTemplate' )
tf =ismember (lower (Learners .Method ),Types ); 
elseifiscell (Learners )
tf =all (cellfun (@(Template )ismember (lower (Template .Method ),Types ),...
    Learners )); 
else
tf =false ; 
end
end

function tf =allLearnerTypes (Learners ,RequiredTypes )

ifisempty (Learners )
tf =false ; 
elseifischar (Learners )
tf =all (ismember (RequiredTypes ,lower (Learners ))); 
elseifisa (Learners ,'classreg.learning.FitTemplate' )
tf =all (ismember (RequiredTypes ,lower (Learners .Method ))); 
elseifiscell (Learners )
tf =all (ismember (RequiredTypes ,cellfun (@(Template )lower (Template .Method ),Learners ,'UniformOutput' ,false ))); 
else
tf =false ; 
end
end

function Learners =chooseDefaultLearners (Method )
ifischar (Method )&&isequal (lower (Method ),'subspace' )
Learners ='KNN' ; 
else
Learners ='Tree' ; 
end
end

function N =numClasses (X ,Y ,NVPs )
[ClassNamesPassed ,~,~]=internal .stats .parseArgs ({'ClassNames' },{[]},NVPs {:}); 
ifisempty (ClassNamesPassed )
[~,Y ]=classreg .learning .internal .table2FitMatrix (X ,Y ,NVPs {:}); 
N =numel (levels (classreg .learning .internal .ClassLabel (Y ))); 
else
N =numel (levels (classreg .learning .internal .ClassLabel (ClassNamesPassed ))); 
end
end

function Learners =setTreeDefaultsIfAny (Learners )

ifischar (Learners )&&isequal (lower (Learners ),'tree' )
Learners =templateTree ('MaxNumSplits' ,10 ); 
elseifisa (Learners ,'classreg.learning.FitTemplate' )
Learners =defaultMaxNumSplitsIfTemplateTree (Learners ,10 ); 
elseifiscell (Learners )&&all (cellfun (@(Tmp )isa (Tmp ,'classreg.learning.FitTemplate' ),Learners ))
Learners =cellfun (@(Tmp )defaultMaxNumSplitsIfTemplateTree (Tmp ,10 ),...
    Learners ,'UniformOutput' ,false ); 
end
end

function Tmp =defaultMaxNumSplitsIfTemplateTree (Tmp ,value )
ifisequal (lower (Tmp .Method ),'tree' )
Tmp =fillIfNeeded (Tmp ,'classification' ); 
ifisempty (getInputArg (Tmp ,'MaxSplits' ))
Tmp =setInputArg (Tmp ,'MaxSplits' ,value ); 
end
end
end
