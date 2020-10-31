classdef SubspaceSampler <classreg .learning .generator .Generator 




properties (GetAccess =public ,SetAccess =protected )
PredictorNames ={}; 
NPredToSample =[]; 
Exhaustive =[]; 
NumAllCombinations =[]; 
CategoricalPredictors =[]; 
end

methods (Hidden )
function this =SubspaceSampler (X ,Y ,W ,fitData ,predictorNames ,npredtosample ,exhaustive ,catpreds )
this =this @classreg .learning .generator .Generator (X ,Y ,W ,fitData ); 

D =size (X ,2 ); 
ifisnumeric (predictorNames )
predictorNames =classreg .learning .internal .defaultPredictorNames (predictorNames ); 
end
if~iscellstr (predictorNames )||numel (predictorNames )~=D 
error (message ('stats:classreg:learning:generator:SubspaceSampler:SubspaceSampler:BadPredictorNames' ,D )); 
end
this .PredictorNames =predictorNames ; 

if~isnumeric (npredtosample )||~isscalar (npredtosample )...
    ||isnan (npredtosample )||npredtosample <=0 ||npredtosample >D 
error (message ('stats:classreg:learning:generator:SubspaceSampler:SubspaceSampler:BadNPredToSample' ,D )); 
end
this .NPredToSample =ceil (npredtosample ); 

if~islogical (exhaustive )||~isscalar (exhaustive )
error (message ('stats:classreg:learning:generator:SubspaceSampler:SubspaceSampler:BadExhaustive' )); 
end
this .Exhaustive =exhaustive ; 

ifexhaustive 
this .NumAllCombinations =nchoosek (size (this .X ,2 ),npredtosample ); 
end
this .CategoricalPredictors =catpreds ; 
end
end

methods (Static )
function [dosubspace ,subspaceArgs ,otherArgs ]=processArgs (varargin )

args ={'subspace' ,'npredtosample' ,'exhaustive' }; 
defs ={false ,[],false }; 
[dosubspace ,npredtosample ,exhaustive ,~,otherArgs ]=...
    internal .stats .parseArgs (args ,defs ,varargin {:}); 


if~islogical (dosubspace )||~isscalar (dosubspace )
error (message ('stats:classreg:learning:generator:SubspaceSampler:processArgs:BadSubspace' )); 
end
if~islogical (exhaustive )||~isscalar (exhaustive )
error (message ('stats:classreg:learning:generator:SubspaceSampler:processArgs:BadExhaustive' )); 
end
subspaceArgs ={}; 


ifisempty (npredtosample )
ifdosubspace 
subspaceArgs ={'npredtosample' ,1 ,'exhaustive' ,exhaustive }; 
end
else
if~isnumeric (npredtosample )||~isscalar (npredtosample )...
    ||isnan (npredtosample )||npredtosample <=0 
error (message ('stats:classreg:learning:generator:SubspaceSampler:processArgs:BadNPredToSample' )); 
end
dosubspace =true ; 
subspaceArgs ={'npredtosample' ,npredtosample ,'exhaustive' ,exhaustive }; 
end
end
end

methods (Access =protected )
function this =reservePredForIter (this )
ifthis .Exhaustive 
D =size (this .X ,2 ); 
nPredToSample =this .NPredToSample ; 
nLearn =this .NumAllCombinations ; 
ifthis .MaxT ~=nLearn 
error (message ('stats:classreg:learning:generator:SubspaceSampler:reservePredForIter:BadMaxT' ,nPredToSample ,nLearn )); 
end
idx =combnk (1 :D ,nPredToSample ); 
this .PrivUsePredForIter (1 :D ,1 :this .MaxT )=false ; 
forn =1 :nLearn 
this .PrivUsePredForIter (idx (n ,:),n )=true ; 
end
else
this =reservePredForIter @classreg .learning .generator .Generator (this ); 
end
end
end

methods 
function [this ,X ,Y ,W ,fitData ,optArgs ]=generate (this )

[N ,D ]=size (this .X ); 

ifthis .Exhaustive 



idxpred =find (this .PrivUsePredForIter (:,this .T +1 )); 
this .LastUsePredForIter =idxpred ; 
else


nUsed =sum (this .UsePredForIter ,2 ); 
nUsed =nUsed -min (nUsed ); 
npredtosample =this .NPredToSample ; 
beta =npredtosample /D ; 
weights =beta .^nUsed ; 





idxpred =sort (datasample (1 :D ,npredtosample ,'replace' ,false ,'weights' ,weights )); 


this .LastUsePredForIter =idxpred ; 
end
X =this .X (:,idxpred ); 
Y =this .Y ; 
W =this .W ; 
fitData =this .FitData ; 
idxobs =1 :N ; 


this .LastUseObsForIter =idxobs ; 


pnames =this .PredictorNames (idxpred ); 
catpred =find (ismember (idxpred ,this .CategoricalPredictors )); 
optArgs ={'predictornames' ,pnames ,'CategoricalPredictors' ,catpred }; 
end

function this =update (this ,X ,Y ,W ,fitData )
end
end

methods (Static ,Hidden )
function [npredtosample ,exhaustive ]=getArgsFromCellstr (varargin )
args ={'npredtosample' ,'exhaustive' }; 
defs ={[],false }; 
[npredtosample ,exhaustive ]=...
    internal .stats .parseArgs (args ,defs ,varargin {:}); 
end
end
end
