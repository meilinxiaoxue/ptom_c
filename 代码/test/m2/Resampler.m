classdef Resampler <classreg .learning .generator .Generator 




properties (GetAccess =public ,SetAccess =protected )
FResample =1 ; 
Replace =true ; 
end

methods (Hidden )
function this =Resampler (X ,Y ,W ,fitData ,fresample ,replace )
this =this @classreg .learning .generator .Generator (X ,Y ,W ,fitData ); 

if~isnumeric (fresample )||~isscalar (fresample )...
    ||fresample <=0 ||fresample >1 
error (message ('stats:classreg:learning:generator:Resampler:Resampler:BadFResample' )); 
end

if~islogical (replace )&&~ischar (replace )
error (message ('stats:classreg:learning:generator:Resampler:Resampler:BadReplace' )); 
end
ifislogical (replace )
if~isscalar (replace )
error (message ('stats:classreg:learning:generator:Resampler:Resampler:LogicalReplaceNotScalar' )); 
end
else
if~strcmpi (replace ,'on' )&&~strcmpi (replace ,'off' )
error (message ('stats:classreg:learning:generator:Resampler:Resampler:StrReplaceNotOnOff' )); 
end
replace =strcmpi (replace ,'on' ); 
end

this .FResample =fresample ; 
this .Replace =replace ; 
end
end

methods (Static )
function [dobag ,sampleArgs ,otherArgs ]=processArgs (varargin )

args ={'resample' ,'fresample' ,'replace' }; 
defs ={'' ,[],'' }; 
[resample ,fresample ,replace ,~,otherArgs ]=...
    internal .stats .parseArgs (args ,defs ,varargin {:}); 


dobag =false ; 
sampleArgs ={}; 


if~isempty (resample )&&~strcmpi (resample ,'on' )&&~strcmpi (resample ,'off' )
error (message ('stats:classreg:learning:generator:Resampler:processArgs:BadResample' ))
end
resample =strcmpi (resample ,'on' ); 


isfresample =~isempty (fresample ); 
isreplace =~isempty (replace ); 
if~resample &&~isfresample &&~isreplace 

return ; 
end


dobag =true ; 
if~isfresample 
fresample =1 ; 
end
if~isreplace 
replace ='on' ; 
end
sampleArgs ={'fresample' ,fresample ,'replace' ,replace }; 
end
end

methods 
function [this ,X ,Y ,W ,fitData ,optArgs ]=generate (this )
N =size (this .X ,1 ); 
M =ceil (N *this .FResample ); 
ifthis .Replace 
idx =randsample (N ,M ,this .Replace ,this .W ); 
W =ones (M ,1 ); 
else
idx =randsample (N ,M ,this .Replace ); 
W =this .W (idx ); 
end
X =this .X (idx ,:); 
Y =this .Y (idx ); 
ifisempty (this .FitData )
fitData =[]; 
else
fitData =this .FitData (idx ,:); 
end
this .LastUseObsForIter =idx ; 
optArgs ={}; 
end

function this =update (this ,X ,Y ,W ,fitData )
idx =this .LastUseObsForIter ; 
N =numel (idx ); 
ifN ~=size (X ,1 )||N ~=numel (Y )||N ~=numel (W )
error (message ('stats:classreg:learning:generator:Resampler:update:BadSizeOfXYW' )); 
end
this .X (idx ,:)=X ; 
this .Y (idx )=Y ; 
Wtot =sum (this .W (idx )); 
ifthis .Replace 
this .W (idx )=this .W (idx ).*W ; 
else
this .W (idx )=W (:); 
end
this .W (idx )=this .W (idx )*Wtot /sum (this .W (idx )); 
if~isempty (this .FitData )
this .FitData (idx ,:)=fitData ; 
end
end
end

methods (Static ,Hidden )
function [fresample ,replace ]=getArgsFromCellstr (varargin )
args ={'fresample' ,'replace' }; 
defs ={1 ,'on' }; 
[fresample ,replace ]=internal .stats .parseArgs (args ,defs ,varargin {:}); 
end
end
end

