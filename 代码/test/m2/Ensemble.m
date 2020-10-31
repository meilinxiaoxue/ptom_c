classdef Ensemble <classreg .learning .ensemble .CompactEnsemble 









properties (GetAccess =public ,SetAccess =protected ,Hidden =true ,Abstract =true )
ModelParams ; 
end

properties (GetAccess =public ,SetAccess =protected ,Dependent =true )





Method ; 








LearnerNames ; 






ReasonForTermination ; 







FitInfo ; 







FitInfoDescription ; 
end

properties (GetAccess =public ,SetAccess =public ,Hidden =true )
Trainable ={}; 
end

methods 
function learners =get .LearnerNames (this )
N =numel (this .ModelParams .LearnerTemplates ); 
learners =cell (1 ,N ); 
forn =1 :N 
temp =this .ModelParams .LearnerTemplates {n }; 
ifstrcmp (temp .Method ,'ByBinaryRegr' )
temp =temp .ModelParams .RegressionTemplate ; 
end
learners {n }=temp .Method ; 
end
end

function meth =get .Method (this )
meth ='' ; 
if~isempty (this .ModelParams )
meth =this .ModelParams .Method ; 
end
end

function r =get .ReasonForTermination (this )
r ='' ; 
if~isempty (this .ModelParams )
r =this .ModelParams .Modifier .ReasonForTermination ; 
end
end

function fi =get .FitInfo (this )
fi =this .ModelParams .Modifier .FitInfo ; 
end

function desc =get .FitInfoDescription (this )
desc =this .ModelParams .Modifier .FitInfoDescription ; 
end
end

methods (Abstract =true )
this =resume (this ,nlearn ,varargin )
end

methods (Static ,Hidden )
function catchUOFL (varargin )
args ={'useobsforlearner' }; 
defs ={[]}; 
[usenfort ,~,~]=internal .stats .parseArgs (args ,defs ,varargin {:}); 
if~isempty (usenfort )
error (message ('stats:classreg:learning:ensemble:Ensemble:catchUOFL:NonEmptyUseObsForLearner' )); 
end
end

function nprint =checkNPrint (varargin )
args ={'nprint' }; 
defs ={'off' }; 
nprint =internal .stats .parseArgs (args ,defs ,varargin {:}); 
end
end

methods (Hidden )
function this =removeLearners (this ,~)
error (message ('stats:classreg:learning:ensemble:Ensemble:removeLearners:Noop' )); 
end
end

methods (Access =protected )
function this =Ensemble ()
this =this @classreg .learning .ensemble .CompactEnsemble ([]); 
end

function s =propsForDisp (this ,s )
s =propsForDisp @classreg .learning .ensemble .CompactEnsemble (this ,s ); 
s .Method =this .Method ; 
s .LearnerNames =this .LearnerNames ; 
s .ReasonForTermination =this .ReasonForTermination ; 
s .FitInfo =this .FitInfo ; 
s .FitInfoDescription =this .FitInfoDescription ; 
end

function [this ,trained ,generator ,modifier ,combiner ]=fitWeakLearners (this ,nlearn ,nprint )



learners =this .ModelParams .LearnerTemplates ; 
generator =this .ModelParams .Generator ; 
modifier =this .ModelParams .Modifier ; 

saveTrainable =this .ModelParams .SaveTrainable ; 

L =numel (learners ); 
trained =this .Trained ; 
T0 =length (trained ); 
T =nlearn *L ; 
trained (end+1 :end+T ,1 )=cell (T ,1 ); 
ifsaveTrainable 
this .Trainable (end+1 :end+T ,1 )=cell (T ,1 ); 
end

generator =reserveFitInfo (generator ,T ); 
modifier =reserveFitInfo (modifier ,T ); 

n =0 ; 
ntrained =T0 ; 
mustTerminate =false ; 

doprint =~isempty (nprint )&&isnumeric (nprint )...
    &&isscalar (nprint )&&nprint >0 ; 
nprint =ceil (nprint ); 

ifdoprint 
fprintf (1 ,'Training %s...\n' ,this .ModelParams .Method ); 
end

whilen <nlearn 

n =n +1 ; 

forl =1 :L 

[generator ,X ,Y ,W ,fitData ,optArgs ]=generate (generator ); 



try
trainableH =fit (learners {l },X ,Y ,'weights' ,W ,optArgs {:}); 
catch me 
warning (me .identifier ,me .message ); 
continue ; 
end
H =compact (trainableH ); 


[modifier ,mustTerminate ,X ,Y ,W ,fitData ]...
    =modifyWithT (modifier ,X ,Y ,W ,H ,fitData ); 


ifmustTerminate 
break; 
end


generator =updateWithT (generator ,X ,Y ,W ,fitData ); 



ntrained =ntrained +1 ; 


trained {ntrained }=H ; 
ifsaveTrainable 
this .Trainable {ntrained }=trainableH ; 
end


ifdoprint 
iffloor (ntrained /nprint )*nprint ==ntrained 
fprintf (1 ,'%s%i\n' ,this .ModelParams .PrintMsg ,ntrained ); 
end
end
end

ifmustTerminate 
break; 
end
end


trained (ntrained +1 :end)=[]; 
ifsaveTrainable 
this .Trainable (ntrained +1 :end)=[]; 
end


combiner =makeCombiner (modifier ); 
end
end

end

