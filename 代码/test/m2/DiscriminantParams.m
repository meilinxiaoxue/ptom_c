classdef DiscriminantParams <classreg .learning .modelparams .ModelParams 
















properties (Constant =true ,GetAccess =public ,Hidden =true )
AllowedDiscrimTypes ={'linear' ,'quadratic' ...
    ,'diagLinear' ,'diagQuadratic' ,'pseudoLinear' ,'pseudoQuadratic' }; 
end

properties 
DiscrimType ='' ; 
Gamma =[]; 
Delta =[]; 
FillCoeffs =[]; 
SaveMemory =[]; 
end

methods (Access =protected )
function this =DiscriminantParams (mode ,gamma ,delta ,fillcoeffs ,savememory )
this =this @classreg .learning .modelparams .ModelParams ('Discriminant' ,'classification' ); 
this .DiscrimType =mode ; 
this .Gamma =gamma ; 
this .Delta =delta ; 
this .FillCoeffs =fillcoeffs ; 
this .SaveMemory =savememory ; 
end
end

methods (Static ,Hidden )
function [holder ,extraArgs ]=make (type ,varargin )

args ={'discrimtype' ,'gamma' ,'delta' ,'fillcoeffs' ,'savememory' }; 
defs ={'' ,[],[],[],[]}; 
[mode ,gamma ,delta ,fillcoeffs ,savememory ,~,extraArgs ]=...
    internal .stats .parseArgs (args ,defs ,varargin {:}); 


allowed =classreg .learning .modelparams .DiscriminantParams .AllowedDiscrimTypes ; 
if~isempty (mode )
if~ischar (mode )
error (message ('stats:classreg:learning:modelparams:DiscriminantParams:make:DiscrimTypeNotChar' )); 
end
tf =strncmpi (mode ,allowed ,length (mode )); 
ifsum (tf )~=1 
error (message ('stats:classreg:learning:modelparams:DiscriminantParams:make:BadDiscrimType' ,sprintf (' %s' ,allowed {:}))); 
end
mode =allowed {tf }; 
end


if~isempty (gamma )&&(~isnumeric (gamma )||~isscalar (gamma )||gamma <0 ||gamma >1 )
error (message ('stats:classreg:learning:modelparams:DiscriminantParams:make:BadGamma' )); 
end


if~isempty (delta )&&(~isnumeric (delta )||~isscalar (delta )||delta <0 )
error (message ('stats:classreg:learning:modelparams:DiscriminantParams:make:BadDelta' )); 
end


if~isempty (fillcoeffs )
if~ischar (fillcoeffs )||(~strcmpi (fillcoeffs ,'on' )&&~strcmpi (fillcoeffs ,'off' ))
error (message ('stats:classreg:learning:modelparams:DiscriminantParams:make:BadFillCoeffs' )); 
end
fillcoeffs =strcmpi (fillcoeffs ,'on' ); 
end


if~isempty (savememory )
if~ischar (savememory )||(~strcmpi (savememory ,'on' )&&~strcmpi (savememory ,'off' ))
error (message ('stats:classreg:learning:modelparams:DiscriminantParams:make:BadSaveMemory' )); 
end
savememory =strcmpi (savememory ,'on' ); 
end


holder =classreg .learning .modelparams .DiscriminantParams (mode ,gamma ,delta ,fillcoeffs ,savememory ); 
end
end

methods (Hidden )
function this =fillDefaultParams (this ,X ,Y ,W ,dataSummary ,classSummary )
ifisempty (this .DiscrimType )
this .DiscrimType ='linear' ; 
end
ifisempty (this .Gamma )
this .Gamma =0 ; 
end
ifisempty (this .Delta )
this .Delta =0 ; 
end
ifisempty (this .FillCoeffs )
this .FillCoeffs =true ; 
end
ifisempty (this .SaveMemory )
this .SaveMemory =false ; 
end
end
end

end
