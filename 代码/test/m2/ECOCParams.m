classdef ECOCParams <classreg .learning .modelparams .ModelParams 













properties 
BinaryLearners ='' ; 
Coding =[]; 
FitPosterior =[]; 
Options =[]; 
VerbosityLevel =[]; 
end

methods (Access =protected )
function this =ECOCParams (learners ,coding ,doposterior ,paropts ,verbose )
this =this @classreg .learning .modelparams .ModelParams ('ECOC' ,'classification' ); 
this .BinaryLearners =learners ; 
this .Coding =coding ; 
this .FitPosterior =doposterior ; 
this .Options =paropts ; 
this .VerbosityLevel =verbose ; 
end
end

methods (Static ,Hidden )
function [holder ,extraArgs ]=make (type ,varargin )%#ok<INUSL> 
args ={'learners' ,'coding' ,'fitposterior' ,'options' ,'verbose' }; 
defs ={'' ,'' ,[],[],[]}; 
[learners ,M ,doposterior ,paropts ,verbose ,~,extraArgs ]=...
    internal .stats .parseArgs (args ,defs ,varargin {:}); 

if~isempty (learners )
if~ischar (learners )...
    &&~isa (learners ,'classreg.learning.FitTemplate' )...
    &&~iscell (learners )
error (message ('stats:classreg:learning:modelparams:ECOCParams:make:BadLearners' )); 
end
ifischar (learners )
learners =classreg .learning .FitTemplate .make (learners ,'type' ,'classification' ); 
end
ifiscell (learners )
f =@(x )isa (x ,'classreg.learning.FitTemplate' ); 
isgood =cellfun (f ,learners ); 
if~all (isgood )
error (message ('stats:classreg:learning:modelparams:ECOCParams:make:BadCellArrayLearners' )); 
end
end
end

if~isempty (M )
ifischar (M )
allowedVals ={'onevsone' ,'allpairs' ,'onevsall' ,'binarycomplete' ,'ternarycomplete' ...
    ,'ordinal' ,'sparserandom' ,'denserandom' }; 
tf =strncmpi (M ,allowedVals ,length (M )); 
Nfound =sum (tf ); 
ifNfound ~=1 
error (message ('stats:classreg:learning:modelparams:ECOCParams:make:BadCodingName' )); 
end
M =allowedVals {tf }; 
ifstrcmp (M ,'allpairs' )
M ='onevsone' ; 
end
else
if~isfloat (M )||~ismatrix (M )||~isreal (M )
error (message ('stats:classreg:learning:modelparams:ECOCParams:make:BadCodingType' )); 
end

vals =unique (M (:)); 
ifnumel (vals )>3 ||any (vals ~=-1 &vals ~=0 &vals ~=1 )
error (message ('stats:classreg:learning:modelparams:ECOCParams:make:BadCodingElements' )); 
end

L =size (M ,2 ); 
forl =1 :L 
if~any (M (:,l )==-1 )
error (message ('stats:classreg:learning:modelparams:ECOCParams:make:CodingColumnWithoutNegOne' ,l )); 
end
if~any (M (:,l )==1 )
error (message ('stats:classreg:learning:modelparams:ECOCParams:make:CodingColumnWithoutPosOne' ,l )); 
end
end

fori =1 :L -1 
forj =i +1 :L 
ifall (M (:,i )==M (:,j ))||all (M (:,i )==-M (:,j ))
error (message ('stats:classreg:learning:modelparams:ECOCParams:make:CodingHasIdenticalColumns' ,i ,j )); 
end
end
end

[tf ,i ,j ]=isconnected (M ); 
if~tf 
fprintf ('%s\n' ,getString (message ('stats:classreg:learning:modelparams:ECOCParams:make:CodingHasInseparableRows' ))); 
forn =1 :numel (i )
fprintf ('     %5i     %5i\n' ,i (n ),j (n )); 
end
error (message ('stats:classreg:learning:modelparams:ECOCParams:make:DisconnectedCoding' )); 
end
end
end

if~isempty (doposterior )
doposterior =internal .stats .parseOnOff (doposterior ,'FitPosterior' ); 
end

if~isempty (paropts )&&~isstruct (paropts )
error (message ('stats:classreg:learning:modelparams:ECOCParams:make:BadOptions' )); 
end

ifislogical (verbose )
verbose =double (verbose ); 
end
if~isempty (verbose )&&...
    (~isscalar (verbose )||~isfloat (verbose )...
    ||verbose <0 ||isnan (verbose ))
error (message ('stats:classreg:learning:modelparams:ECOCParams:make:BadVerbose' )); 
end

holder =classreg .learning .modelparams .ECOCParams (...
    learners ,M ,doposterior ,paropts ,verbose ); 
end
end

methods (Hidden )
function this =fillDefaultParams (this ,X ,Y ,W ,dataSummary ,classSummary )%#ok<INUSL> 




ifisempty (this .BinaryLearners )
templates =templateSVM ; 
else
templates =this .BinaryLearners ; 
end

ifisscalar (templates )&&~iscell (templates )
templates ={templates }; 
end

L =numel (templates ); 


lambda =cell (L ,1 ); 

forl =1 :L 
learner =templates {l }; 

learner =fillIfNeeded (learner ,'classification' ); 

learner =setBaseArg (learner ,'predictornames' ,dataSummary .PredictorNames ); 
learner =setBaseArg (learner ,'categoricalpredictors' ,dataSummary .CategoricalPredictors ); 
learner =setBaseArg (learner ,'responsename' ,dataSummary .ResponseName ); 
ifdataSummary .ObservationsInRows 
learner =setBaseArg (learner ,'ObservationsIn' ,'rows' ); 
else
learner =setBaseArg (learner ,'ObservationsIn' ,'columns' ); 
end

switchlearner .Method 
case 'Discriminant' 
ifisempty (learner .ModelParams .FillCoeffs )
learner .ModelParams .FillCoeffs =false ; 
end
ifisempty (learner .ModelParams .DiscrimType )
learner .ModelParams .DiscrimType ='pseudoLinear' ; 
end

case 'SVM' 
ifisempty (learner .ModelParams .SaveSupportVectors )&&...
    (isempty (learner .ModelParams .KernelFunction )||...
    strcmp (learner .ModelParams .KernelFunction ,'linear' ))
learner .ModelParams .SaveSupportVectors =false ; 
end

case 'Linear' 
if~isempty (learner .ModelParams .ValidationX )
error (message ('stats:classreg:learning:modelparams:ECOCParams:fillDefaultParams:LinearValidationDataNotSupported' )); 
end
lambda {l }=learner .ModelParams .Lambda ; 

end

templates {l }=learner ; 
end

ifisscalar (templates )
templates =templates {1 }; 
end

this .BinaryLearners =templates ; 


f =@(z )isempty (z )||ischar (z )||(isnumeric (z )&&isscalar (z )); 
isone =cellfun (f ,lambda ); 
if~all (isone )
ifany (isone )
error (message ('stats:classreg:learning:modelparams:ECOCParams:fillDefaultParams:LinearLambdaSizeMismatch' )); 
end

try
cell2mat (lambda ); 
catch 
error (message ('stats:classreg:learning:modelparams:ECOCParams:fillDefaultParams:LinearLambdaSizeMismatch' )); 
end
end




ifisempty (this .Coding )
this .Coding ='onevsone' ; 
elseifisnumeric (this .Coding )
M =this .Coding ; 

K =numel (classSummary .ClassNames ); 
ifsize (M ,1 )~=K 
error (message ('stats:classreg:learning:modelparams:ECOCParams:fillDefaultParams:BadNumRowsInM' ,K )); 
end

zeroclass =sum (M ~=0 ,2 )==0 ; 
ifany (zeroclass )
k =find (zeroclass ,1 ,'first' ); 
s =cellstr (classSummary .ClassNames (k )); 
error (message ('stats:classreg:learning:modelparams:ECOCParams:fillDefaultParams:ZeroRowInM' ,s {:},k )); 
end

fori =1 :K -1 
forj =i +1 :K 
ifall (M (i ,:)==M (j ,:))
s1 =cellstr (classSummary .ClassNames (i )); 
s2 =cellstr (classSummary .ClassNames (j )); 
error (message ('stats:classreg:learning:modelparams:ECOCParams:fillDefaultParams:IdenticalRowsInM' ,i ,j ,s1 {:},s2 {:})); 
end
end
end
end

ifisempty (this .FitPosterior )
this .FitPosterior =false ; 
end

ifisempty (this .Options )
this .Options =statset ('parallel' ); 
end

ifisempty (this .VerbosityLevel )
this .VerbosityLevel =0 ; 
end
end
end

end







function [tf ,i ,j ]=isconnected (M )

K =size (M ,1 ); 

F =eye (K )==1 ; 

fork =1 :K 
lookAt =k ; 
lookedAt =[]; 

Mreduced =M ; 





while~isempty (lookAt )


[newk ,Mreduced ]=findConnectedClasses (Mreduced ,lookAt (1 )); 

F (k ,newk )=true ; 


lookedAt =unique ([lookedAt ,lookAt (1 )]); 
lookAt (1 )=[]; 

tf =ismember (newk ,lookedAt ); 
newk (tf )=[]; 

lookAt =unique ([lookAt ,newk ]); 
end
end

tf =all (all (F |F ' )); 

ifnargout >1 
iftf 
i =[]; 
j =[]; 
else
idx =find (~(F |F ' )); 
[i ,j ]=ind2sub ([K ,K ],idx ); 
keep =i <j ; 
i =i (keep ); 
j =j (keep ); 
end
end

end







function [klist ,M ]=findConnectedClasses (M ,k )
klist =[]; 

idxnonzero =find (M (k ,:)); 

forn =1 :numel (idxnonzero )
idxcol =idxnonzero (n ); 
elem =M (k ,idxcol ); 
newk =find (M (:,idxcol )==-elem ); 
klist =unique ([klist ,newk (:)' ]); 
end

M (:,idxnonzero )=[]; 

end
