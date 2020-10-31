function obj =fitrensemble (X ,Y ,varargin )












































































































internal .stats .checkNotTall (upper (mfilename ),0 ,X ,Y ,varargin {:}); 

ifnargin >1 
Y =convertStringsToChars (Y ); 
end

ifnargin >2 
[varargin {:}]=convertStringsToChars (varargin {:}); 
end

[IsOptimizing ,RemainingArgs ]=classreg .learning .paramoptim .parseOptimizationArgs (varargin ); 
ifIsOptimizing 
obj =classreg .learning .paramoptim .fitoptimizing ('fitrensemble' ,X ,Y ,varargin {:}); 
else
Names ={'Method' ,'NumLearningCycles' ,'Learners' }; 
Defaults ={'LSBoost' ,100 ,'Tree' }; 
[Method ,NumLearningCycles ,Learners ,~,RemainingArgs ]=...
    internal .stats .parseArgs (Names ,Defaults ,RemainingArgs {:}); 
checkLearners (Learners ); 
checkMethod (Method ); 
ifisBoostingMethod (Method )
Learners =setTreeDefaultsIfAny (Learners ); 
end
obj =fitensemble (X ,Y ,Method ,NumLearningCycles ,Learners ,RemainingArgs {:},...
    'Type' ,'regression' ); 
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

function tf =isBoostingMethod (Method )
tf =ischar (Method )&&~isempty (strfind (lower (Method ),'boost' )); 
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
Tmp =fillIfNeeded (Tmp ,'regression' ); 
ifisempty (getInputArg (Tmp ,'MaxSplits' ))
Tmp =setInputArg (Tmp ,'MaxSplits' ,value ); 
end
end
end
