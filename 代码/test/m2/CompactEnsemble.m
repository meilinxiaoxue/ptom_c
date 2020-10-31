classdef CompactEnsemble %#codegen 







properties (GetAccess =public ,SetAccess =protected ,Hidden =true )


Learners ; 


NumTrained ; 


IsCached ; 


LearnerWeights ; 


CombinerClass ; 




UsePredForLearner ; 

end

methods (Access =protected )

function obj =CompactEnsemble (cgStruct )

coder .internal .prefer_const (cgStruct ); 


validateFields (cgStruct ); 


obj .NumTrained =cast (cgStruct .NumTrained ,'uint32' ); 
obj .Learners =cgStruct .Impl .Trained ; 
obj .CombinerClass =cgStruct .Impl .CombinerClass ; 
obj .LearnerWeights =cgStruct .Impl .Combiner .LearnerWeights ; 
obj .IsCached =cgStruct .Impl .Combiner .IsCached ; 
obj .UsePredForLearner =cgStruct .UsePredForLearner ; 


end

function ensemblePredictValidateNumTrained (obj ,X ,T )

coder .internal .prefer_const (obj ); 

classreg .learning .coderutils .checkSupportedNumeric ('X' ,X ,false ,false ); 

coder .internal .errorIf (obj .NumTrained ~=T ,'stats:classreg:learning:ensemble:CompactEnsemble:checkAggregateArgs:BadLogicalIndices' ,T ); 
end

function score =ensemblePredict (obj ,X ,score ,doclass ,classifbybinregr ,classnames ,nonzeroprobclasses ,varargin )




























[N ,D ]=size (X ); 


coder .internal .errorIf (~coder .internal .isConst (D )||D ~=obj .NumPredictors ,...
    'stats:classreg:learning:impl:CompactSVMImpl:score:BadXSize' ,obj .NumPredictors ); 

T =length (fieldnames (obj .Learners )); 

[learnersall ,useobsforlearner ]=parseOptionalInputs (obj ,coder .internal .indexInt (N ),coder .internal .indexInt (T ),varargin {:}); 
validateLearners (learnersall ); 

ifislogical (learnersall )
coder .internal .assert (coder .internal .isConst (isvector (learnersall ))&&isvector (learnersall )&&coder .internal .isConst (length (learnersall )==coder .internal .indexInt (T ))&&length (learnersall )==coder .internal .indexInt (T ),'stats:classreg:learning:ensemble:CompactEnsemble:checkAggregateArgs:BadLogicalIndices' ,coder .internal .indexInt (T )); 
learnerIndices =learnersall (:); 
else
coder .internal .errorIf (any (any (learnersall >obj .NumTrained ,2 ),1 )||any (any (learnersall <1 ,2 ),1 ),'stats:classreg:learning:ensemble:CompactEnsemble:checkAggregateArgs:BadNumericIndices' ,obj .NumTrained ); 
learnerIndices =false (coder .internal .indexInt (T ),1 ); 
learnerIndices (learnersall )=true ; 
end

validateUseObsForLearner (useobsforlearner ); 

coder .internal .errorIf (any (size (useobsforlearner )~=[coder .internal .indexInt (N ),coder .internal .indexInt (T )]),'stats:classreg:learning:ensemble:CompactEnsemble:aggregatePredict:UseObsForIter' ,coder .internal .indexInt (N ),coder .internal .indexInt (T )); 

ifisempty (obj .UsePredForLearner )
usepredforlearner =true (coder .internal .indexInt (D ),coder .internal .indexInt (T )); 
else
usepredforlearner =obj .UsePredForLearner ; 
end

score =classreg .learning .coder .ensembleutils .aggregatePredict (X ,score ,obj .CombinerClass ,obj .Learners ,classifbybinregr ,obj .LearnerWeights ,obj .IsCached ,...
    classnames ,nonzeroprobclasses ,...
    usepredforlearner ,learnerIndices ,useobsforlearner ,doclass ); 
end
end

methods (Static ,Access =protected )

function posterior =ensemblePredictEmptyX (Xin ,K ,numPredictors )


Dpassed =size (Xin ,2 ); 
str ='columns' ; 

coder .internal .errorIf (~coder .internal .isConst (coder .internal .indexInt (Dpassed ))||coder .internal .indexInt (Dpassed )~=numPredictors ,...
    'stats:classreg:learning:classif:ClassificationModel:predictEmptyX:XSizeMismatch' ,numPredictors ,str ); 

posterior =repmat (coder .internal .nan (1 ,1 ),0 ,K ); 
end

end

methods (Static ,Hidden )
function props =matlabCodegenNontunableProperties (~)
props ={'NumTrained' ,'Learners' ,'CombinerClass' ,'UsePredForLearner' }; 
end
end
end

function [learners ,useObsForLearner ]=parseOptionalInputs (obj ,N ,T ,varargin )




coder .inline ('always' ); 
coder .internal .prefer_const (varargin ); 

params =struct (...
    'learners' ,uint32 (0 ),...
    'UseObsForLearner' ,uint32 (0 )); 

popts =struct (...
    'CaseSensitivity' ,false ,...
    'StructExpand' ,true ,...
    'PartialMatching' ,true ); 

optarg =eml_parse_parameter_inputs (params ,popts ,...
    varargin {:}); 
learners =eml_get_parameter_value (...
    optarg .learners ,(1 :obj .NumTrained )' ,varargin {:}); 
useObsForLearner =eml_get_parameter_value (...
    optarg .UseObsForLearner ,true (N ,T ),varargin {:}); 

end


function validateFields (cgStruct )


coder .inline ('always' ); 


validateattributes (cgStruct .NumTrained ,{'double' ,'single' },...
    {'positive' ,'integer' ,'nonnan' ,'finite' ,'real' ,'nonempty' },mfilename ,'NumTrained' ); 



validatestring (cgStruct .Impl .CombinerClass ,{'WeightedSum' ,'WeightedAverage' },mfilename ,'CombinerClass' ); 
validateattributes (cgStruct .Impl .Combiner .LearnerWeights ,{'double' ,'single' },{'nonnegative' ,'nonnan' ,'finite' ,'real' ,'size' ,[cgStruct .NumTrained ,1 ]},mfilename ,'LearnerWeights' ); 
validateattributes (cgStruct .Impl .Combiner .IsCached ,{'logical' },{'size' ,[cgStruct .NumTrained ,1 ]},mfilename ,'IsCached' ); 

if~isempty (cgStruct .UsePredForLearner )
validateattributes (cgStruct .UsePredForLearner ,{'logical' },{'size' ,[cgStruct .DataSummary .NumPredictors ,cgStruct .NumTrained ]},mfilename ,'UsePredForLearner' ); 
end

end

function validateLearners (learners )

ifisnumeric (learners )
validateattributes (learners ,{'double' ,'single' ,'uint32' },{'nonempty' ,'nonnan' ,'finite' ,'integer' ,'real' },mfilename ,'learners' ); 
else
validateattributes (learners ,{'logical' },{'nonempty' ,'nonnan' ,'finite' ,'real' },mfilename ,'learners' ); 
end

end


function validateUseObsForLearner (useobsforlearner )

validateattributes (useobsforlearner ,{'logical' },{'nonempty' },mfilename ,'UseObsForLearner' ); 

end

