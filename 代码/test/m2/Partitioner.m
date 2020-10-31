classdef Partitioner <classreg .learning .generator .Generator 




properties (GetAccess =public ,SetAccess =protected )
KFold =10 ; 
LastProcessedFold =0 ; 
Partition =[]; 
end

methods (Hidden )
function this =Partitioner (X ,Y ,W ,fitData ,cvpart ,type ,kfold ,holdout ,leaveout ,obsInRows )
ifnargin <10 
obsInRows =true ; 
end

this =this @classreg .learning .generator .Generator (X ,Y ,W ,fitData ,obsInRows ); 

iscvpart =~isempty (cvpart ); 
iskfold =~isempty (kfold ); 
isholdout =~isempty (holdout ); 
isleaveout =(ischar (leaveout )&&strcmpi (leaveout ,'on' ))...
    ||(islogical (leaveout )&&leaveout ); 

ifiscvpart +iskfold +isholdout +isleaveout >1 
error (message ('stats:classreg:learning:generator:Partitioner:Partitioner:TooManyCrossvalOptions' )); 
end
if~iscvpart &&~iskfold &&~isholdout &&~isleaveout 
error (message ('stats:classreg:learning:generator:Partitioner:Partitioner:NoCrossvalOptions' )); 
end

ifobsInRows 
N =size (X ,1 ); 
else
N =size (X ,2 ); 
end

ifiscvpart 
if~isa (cvpart ,'cvpartition' )
error (message ('stats:classreg:learning:generator:Partitioner:Partitioner:BadCVpartition' )); 
end
this .KFold =cvpart .NumTestSets ; 
this .Partition =cvpart ; 

elseifiskfold 
if~isnumeric (kfold )||~isscalar (kfold )||kfold <2 
error (message ('stats:classreg:learning:generator:Partitioner:Partitioner:BadKfold' )); 
end
this .KFold =min (kfold ,N ); 
ifstrcmp (type ,'classification' )
this .Partition =cvpartition (labels (Y ),'kfold' ,kfold ); 
else
this .Partition =cvpartition (N ,'kfold' ,kfold ); 
end

elseifisholdout 
if~isnumeric (holdout )||~isscalar (holdout )||holdout <0 ||holdout >1 
error (message ('stats:classreg:learning:generator:Partitioner:Partitioner:BadHoldout' )); 
end
this .KFold =1 ; 
ifstrcmp (type ,'classification' )
this .Partition =cvpartition (labels (Y ),'holdout' ,holdout ); 
else
this .Partition =cvpartition (N ,'holdout' ,holdout ); 
end

elseifisleaveout 
this .KFold =N ; 
this .Partition =cvpartition (N ,'leaveout' ); 
end
end
end

methods (Static )
function [Nfold ,partitionArgs ,otherArgs ,cvpartsize ]=processArgs (varargin )

args ={'cvpartition' ,'crossval' ,'kfold' ,'holdout' ,'leaveout' }; 
defs ={[],'' ,[],[],'' }; 
[cvpart ,crossval ,kfold ,holdout ,leaveout ,~,otherArgs ]=...
    internal .stats .parseArgs (args ,defs ,varargin {:}); 


Nfold =[]; 
partitionArgs ={}; 


if~isempty (crossval )&&~strcmpi (crossval ,'on' )&&~strcmpi (crossval ,'off' )
error (message ('stats:classreg:learning:generator:Partitioner:processArgs:BadCrossval' )); 
end
docv =strcmpi (crossval ,'on' ); 


if~isempty (leaveout )&&~strcmpi (leaveout ,'on' )&&~strcmpi (leaveout ,'off' )
error (message ('stats:classreg:learning:generator:Partitioner:processArgs:BadLeaveout' )); 
end


iscvpart =~isempty (cvpart ); 
iskfold =~isempty (kfold ); 
isholdout =~isempty (holdout ); 
isleaveout =strcmpi (leaveout ,'on' ); 
cvpartsize =[]; 
ifiscvpart +iskfold +isholdout +isleaveout >1 
error (message ('stats:classreg:learning:generator:Partitioner:processArgs:TooManyCrossvalOptions' )); 
end
ifstrcmpi (crossval ,'off' )&&iscvpart +iskfold +isholdout +isleaveout >0 
error (message ('stats:classreg:learning:generator:Partitioner:processArgs:MismatchCrossvalOpts' )); 
end
if~iscvpart &&~docv &&~iskfold &&~isholdout &&~isleaveout 
return ; 
end
ifiscvpart 
if~isa (cvpart ,'cvpartition' )
error (message ('stats:classreg:learning:generator:Partitioner:processArgs:BadCVpartition' )); 
end
cvpartsize =cvpart .NumObservations ; 
Nfold =cvpart .NumTestSets ; 
partitionArgs ={'cvpartition' ,cvpart }; 
end
if~iscvpart &&~iskfold &&~isholdout &&~isleaveout 
iskfold =true ; 
kfold =10 ; 
end
ifiskfold 
if~isnumeric (kfold )||~isscalar (kfold )||kfold <=1 
error (message ('stats:classreg:learning:generator:Partitioner:processArgs:BadKfold' )); 
end
Nfold =ceil (kfold ); 
partitionArgs ={'kfold' ,Nfold }; 
end
ifisholdout 
Nfold =1 ; 
partitionArgs ={'holdout' ,holdout }; 
end
ifisleaveout 
if~strcmpi (leaveout ,'on' )&&~strcmpi (leaveout ,'off' )
error (message ('stats:classreg:learning:generator:Partitioner:processArgs:BadLeaveout' )); 
end
Nfold ='leaveout' ; 
partitionArgs ={'leaveout' ,'on' }; 
end
end
end

methods 
function [this ,X ,Y ,W ,fitData ,optArgs ]=generate (this )
this .LastProcessedFold =this .LastProcessedFold +1 ; 
ifthis .LastProcessedFold >this .KFold 
this .LastProcessedFold =this .LastProcessedFold -this .KFold ; 
end
idx =training (this .Partition ,this .LastProcessedFold ); 

ifthis .ObservationsInRows 
X =this .X (idx ,:); 
else
X =this .X (:,idx ); 
end
Y =this .Y (idx ); 
W =this .W (idx ); 

ifisempty (this .FitData )
fitData =[]; 
else
fitData =this .FitData (idx ,:); 
end
this .LastUseObsForIter =idx ; 
optArgs ={}; 
end

function this =update (this ,~,~,~,~)
end
end

methods (Static ,Hidden )
function [cvpart ,kfold ,holdout ,leaveout ]=getArgsFromCellstr (varargin )
args ={'cvpartition' ,'kfold' ,'holdout' ,'leaveout' }; 
defs ={[],[],[],'off' }; 
[cvpart ,kfold ,holdout ,leaveout ]=...
    internal .stats .parseArgs (args ,defs ,varargin {:}); 
end
end
end

