classdef CompactClassificationEnsemble <...
    classreg .learning .classif .ClassificationModel &classreg .learning .ensemble .CompactEnsemble 


































properties (GetAccess =public ,SetAccess =protected ,Hidden =true )







DefaultScore =NaN ; 





PrivContinuousLoss =[]; 







TransformToProbability =[]; 
end

methods (Access =protected )
function this =CompactClassificationEnsemble (...
    dataSummary ,classSummary ,scoreTransform ,scoreType ,...
    usepredforlearner ,defaultScore ,continuousLoss ,...
    transformToProbability )
this =this @classreg .learning .classif .ClassificationModel (...
    dataSummary ,classSummary ,scoreTransform ,scoreType ); 
this =this @classreg .learning .ensemble .CompactEnsemble (usepredforlearner ); 
this .DefaultScore =defaultScore ; 
this .DefaultLoss =@classreg .learning .loss .classiferror ; 
this .LabelPredictor =@classreg .learning .classif .ClassificationModel .maxScore ; 
this .PrivContinuousLoss =continuousLoss ; 
this .TransformToProbability =transformToProbability ; 
end

function s =score (this ,X ,varargin )
vrange =getvrange (this ); 
X =classreg .learning .internal .table2PredictMatrix (X ,[],[],...
    vrange ,this .CategoricalPredictors ,getOptionalPredictorNames (this )); 
s =classreg .learning .ensemble .CompactEnsemble .aggregatePredict (...
    X ,this .Impl .Combiner ,this .Impl .Trained ,...
    this .ClassSummary .ClassNames ,this .ClassSummary .NonzeroProbClasses ,...
    this .DefaultScore ,'usepredforlearner' ,this .UsePredForLearner ,varargin {:}); 
end

function s =propsForDisp (this ,s )
s =propsForDisp @classreg .learning .classif .ClassificationModel (this ,s ); 
s =propsForDisp @classreg .learning .ensemble .CompactEnsemble (this ,s ); 
end

function scoreType =getScoreType (this )
scoreType =getScoreType @classreg .learning .classif .ClassificationModel (this ); 
ifisequal (this .PrivScoreTransform ,this .TransformToProbability )
scoreType ='probability' ; 
end
end

function cl =getContinuousLoss (this )
cl =[]; 
ifisequal (this .PrivScoreTransform ,@classreg .learning .transform .identity )
cl =this .PrivContinuousLoss ; 
elseifisequal (this .PrivScoreTransform ,this .TransformToProbability )
cl =@classreg .learning .loss .quadratic ; 
end
end
end

methods 
function [labels ,scores ]=predict (this ,X ,varargin )





























adapter =classreg .learning .internal .makeClassificationModelAdapter (this ,X ,varargin {:}); 
if~isempty (adapter )
[labels ,scores ]=predict (adapter ,X ,varargin {:}); 
return 
end


ifisempty (X )
ifthis .TableInput ||istable (X )
vrange =getvrange (this ); 
X =classreg .learning .internal .table2PredictMatrix (X ,[],[],...
    vrange ,...
    this .CategoricalPredictors ,this .PredictorNames ); 
end
[labels ,scores ]=predictEmptyX (this ,X ); 
return ; 
end

scores =score (this ,X ,varargin {:}); 
N =size (scores ,1 ); 


scores =this .PrivScoreTransform (scores ); 
notNaN =~all (isnan (scores )|scores ==this .DefaultScore ,2 ); 
[~,cls ]=max (this .Prior ); 
labels =repmat (this .ClassNames (cls ,:),N ,1 ); 
[~,classNum ]=max (scores (notNaN ,:),[],2 ); 
labels (notNaN ,:)=this .ClassNames (classNum ,:); 
end

function m =margin (this ,X ,varargin )





























m =margin @classreg .learning .classif .ClassificationModel (this ,X ,varargin {:}); 
end

function e =edge (this ,X ,varargin )








































adapter =classreg .learning .internal .makeClassificationModelAdapter (this ,X ,varargin {:}); 
if~isempty (adapter )
e =edge (adapter ,X ,varargin {:}); 
return 
end

[Y ,varargin ]=classreg .learning .internal .inferResponse (this .ResponseName ,X ,varargin {:}); 
N =size (X ,1 ); 
args ={'weights' }; 
defs ={ones (N ,1 )}; 
[W ,~,extraArgs ]=internal .stats .parseArgs (args ,defs ,varargin {:}); 

[X ,C ,W ]=prepareDataForLoss (this ,X ,Y ,W ,[],true ,true ); 
e =classreg .learning .ensemble .CompactEnsemble .aggregateLoss (...
    this .NTrained ,X ,C ,W ,this .Cost ,@classreg .learning .loss .classifedge ,...
    this .Impl .Combiner ,@classreg .learning .ensemble .CompactEnsemble .predictOneWithCache ,...
    this .Impl .Trained ,this .ClassSummary .ClassNames ,this .ClassSummary .NonzeroProbClasses ,...
    this .PrivScoreTransform ,this .DefaultScore ,'usepredforlearner' ,this .UsePredForLearner ,...
    extraArgs {:}); 
end

function l =loss (this ,X ,varargin )

























































adapter =classreg .learning .internal .makeClassificationModelAdapter (this ,X ,varargin {:}); 
if~isempty (adapter )
l =loss (adapter ,X ,varargin {:}); 
return 
end

[Y ,varargin ]=classreg .learning .internal .inferResponse (this .ResponseName ,X ,varargin {:}); 
N =size (X ,1 ); 
args ={'lossfun' ,'weights' }; 
defs ={this .DefaultLoss ,ones (N ,1 )}; 
[funloss ,W ,~,extraArgs ]=...
    internal .stats .parseArgs (args ,defs ,varargin {:}); 

[X ,C ,W ]=prepareDataForLoss (this ,X ,Y ,W ,[],true ,true ); 
l =classreg .learning .ensemble .CompactEnsemble .aggregateLoss (...
    this .NTrained ,X ,C ,W ,this .Cost ,funloss ,...
    this .Impl .Combiner ,@classreg .learning .ensemble .CompactEnsemble .predictOneWithCache ,...
    this .Impl .Trained ,this .ClassSummary .ClassNames ,this .ClassSummary .NonzeroProbClasses ,...
    this .PrivScoreTransform ,this .DefaultScore ,'usepredforlearner' ,this .UsePredForLearner ,...
    extraArgs {:}); 
end

function [varargout ]=predictorImportance (this ,varargin )


















[varargout {1 :nargout }]=predictorImportance (this .Impl ,varargin {:}); 
end
end

methods (Hidden )

function s =toStruct (this )


warnState =warning ('query' ,'all' ); 
warning ('off' ,'MATLAB:structOnObject' ); 
cleanupObj =onCleanup (@()warning (warnState )); 
fh =functions (this .PrivScoreTransform ); 
ifstrcmpi (fh .type ,'anonymous' )
error (message ('stats:classreg:learning:coderutils:classifToStruct:AnonymousFunctionsNotSupported' ,'Score Transform' )); 
end

fh =functions (this .DefaultLoss ); 
ifstrcmpi (fh .type ,'anonymous' )
error (message ('stats:classreg:learning:coderutils:classifToStruct:AnonymousFunctionsNotSupported' ,'Loss' )); 
end


try
classreg .learning .internal .convertScoreTransform (this .PrivScoreTransform ,'handle' ,numel (this .ClassSummary .ClassNames )); 
catch me 
rethrow (me ); 
end


s =classreg .learning .coderutils .classifToStruct (this ); 

s .ScoreTransformFull =s .ScoreTransform ; 
scoretransformfull =strsplit (s .ScoreTransform ,'.' ); 
scoretransform =scoretransformfull {end}; 
s .ScoreTransform =scoretransform ; 



transFcn =['classreg.learning.transform.' ,s .ScoreTransform ]; 
transFcnCG =['classreg.learning.coder.transform.' ,s .ScoreTransform ]; 
ifisempty (which (transFcn ))||isempty (which (transFcnCG ))
s .CustomScoreTransform =true ; 
else
s .CustomScoreTransform =false ; 
end

s .DefaultLossFull =s .DefaultLoss ; 
defaultlossfull =strsplit (s .DefaultLoss ,'.' ); 
defaultloss =defaultlossfull {end}; 
s .DefaultLoss =defaultloss ; 

try
classreg .learning .internal .lossCheck (s .DefaultLoss ,'classification' ); 
catch me 
rethrow (me ); 
end


s .FromStructFcn ='classreg.learning.classif.CompactClassificationEnsemble.fromStruct' ; 


trained =this .Trained ; 
L =numel (trained ); 

ifL ==0 
error (message ('stats:classreg:learning:classif:CompactClassificationEnsemble:toStruct:EmptyModelNotSupported' )); 
end

trained_struct =struct ; 

ifisa (trained {1 },'classreg.learning.classif.CompactClassifByBinaryRegr' )
s .ClassifByBinRegr =true ; 
else
s .ClassifByBinRegr =false ; 
end


forj =1 :L 
fname =['Learner_' ,num2str (j )]; 
ifisempty (trained {j })
trained_struct .(fname )=trained {j }; 
else
ifs .ClassifByBinRegr 
classifByBinRegrStruct =classreg .learning .coderutils .classifToStruct (trained {j }); 
trained_struct .(fname )=trained {j }.CompactRegressionLearner .toStruct ; 
trained_struct .(fname ).classifByBinRegrStruct =classifByBinRegrStruct ; 
trained_struct .(fname ).classifByBinRegrStruct .FromStructFcn ='classreg.learning.classif.CompactClassifByBinaryRegr.fromStruct' ; 
else
trained_struct .(fname )=trained {j }.toStruct ; 
end
end
end

s .NumTrained =L ; 
s .Impl .Trained =trained_struct ; 
s .UsePredForLearner =this .UsePredForLearner ; 
s .Impl .Combiner =struct ('LearnerWeights' ,this .Impl .Combiner .LearnerWeights ,'IsCached' ,this .Impl .Combiner .IsCached ); 
combinerClassFull =class (this .Impl .Combiner ); 
combinerClassList =strsplit (combinerClassFull ,'.' ); 
combinerClass =combinerClassList {end}; 
s .Impl .CombinerClass =combinerClass ; 
s .DefaultScore =this .DefaultScore ; 
s .DefaultScoreType =this .DefaultScoreType ; 
s .TransformToProbability =[]; 
s .PrivContinuousLoss =[]; 
if~isempty (this .TransformToProbability )
s .TransformToProbability =func2str (this .TransformToProbability ); 
end
if~isempty (this .PrivContinuousLoss )
s .PrivContinuousLoss =func2str (this .PrivContinuousLoss ); 
end

end


function this =setLearnersPrior (this ,prior )
trained =this .Impl .Trained ; 













isknn =@(obj )isa (obj ,'ClassificationKNN' ); 
ifany (cellfun (isknn ,trained ))
error (message ('stats:classreg:learning:classif:CompactClassificationEnsemble:setLearnersPrior:Noop' )); 
end



ifischar (prior )&&strncmpi (prior ,'uniform' ,numel (prior ))
T =length (trained ); 
fort =1 :T 
K =numel (trained {t }.ClassSummary .ClassNames ); 
trained {t }.Prior =ones (1 ,K )/K ; 
end
this .Impl .Trained =trained ; 

elseifnumel (prior (:))==numel (this .Prior )
T =length (trained ); 
fort =1 :T 
[~,loc ]=ismember (trained {t }.ClassSummary .ClassNames ,...
    this .ClassSummary .ClassNames ); 
trained {t }.Prior =prior (loc ); 
end
this .Impl .Trained =trained ; 
end

this =setPrivatePrior (this ,prior ); 
end

function this =setLearnersCost (this ,cost )


ifisequal (size (cost ),size (this .Cost ))
trained =this .Impl .Trained ; 
T =length (trained ); 
fort =1 :T 
[~,loc ]=ismember (trained {t }.ClassSummary .ClassNames ,...
    this .ClassSummary .ClassNames ); 
trained {t }.Cost =cost (loc ,loc ); 
end
this .Impl .Trained =trained ; 
end
this =setPrivateCost (this ,cost ); 
end
end
methods (Static =true ,Hidden =true )
function obj =fromStruct (s )


s .ScoreTransform =s .ScoreTransformFull ; 
s .DefaultLoss =s .DefaultLossFull ; 
s =classreg .learning .coderutils .structToClassif (s ); 


L =s .NumTrained ; 
trained =cell (L ,1 ); 

forj =1 :L 
fname =['Learner_' ,num2str (j )]; 
trained_struct =s .Impl .Trained .(fname ); 
if~isempty (trained_struct )
fcn =str2func (trained_struct .FromStructFcn ); 
ifs .ClassifByBinRegr 
classifByBinRegrStruct =trained_struct .classifByBinRegrStruct ; 
classifByBinRegrStruct =classreg .learning .coderutils .structToClassif (classifByBinRegrStruct ); 
trained_struct =rmfield (trained_struct ,'classifByBinRegrStruct' ); 
crl =fcn (trained_struct ); 
trained {j }=crl ; 
crlStruct =struct ('DataSummary' ,classifByBinRegrStruct .DataSummary ,'ClassSummary' ,classifByBinRegrStruct .ClassSummary ,...
    'ScoreTransform' ,classifByBinRegrStruct .ScoreTransform ,'crl' ,trained {j }); 
trained {j }=classreg .learning .classif .CompactClassifByBinaryRegr .fromStruct (crlStruct ); 
else
trained {j }=fcn (trained_struct ); 
end
else
trained {j }=trained_struct ; 
end
end
transformToProbability =[]; 
continuousLoss =[]; 
if~isempty (s .TransformToProbability )
transformToProbability =str2func (s .TransformToProbability ); 
end
if~isempty (s .PrivContinuousLoss )
continuousLoss =str2func (s .PrivContinuousLoss ); 
end




obj =classreg .learning .classif .CompactClassificationEnsemble (...
    s .DataSummary ,s .ClassSummary ,s .ScoreTransform ,s .ScoreType ,...
    s .UsePredForLearner ,s .DefaultScore ,continuousLoss ,transformToProbability ); 

learnerweights =s .Impl .Combiner .LearnerWeights ; 
combinerClassFull =['classreg.learning.combiner.' ,s .Impl .CombinerClass ]; 
combinerClass =str2func (combinerClassFull ); 
combiner =combinerClass (learnerweights ); 
impl =classreg .learning .impl .CompactEnsembleImpl (trained ,combiner ); 
obj .DefaultScoreType =s .DefaultScoreType ; 
obj .Impl =impl ; 

end
end

methods (Hidden ,Static )
function name =matlabCodegenRedirect (~)
name ='classreg.learning.coder.classif.CompactClassificationEnsemble' ; 
end
end
end
