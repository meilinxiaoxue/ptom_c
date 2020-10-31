classdef ByBinaryRegrParams <classreg .learning .modelparams .ModelParams 








properties 
RegressionTemplate =[]; 
end

methods (Access =protected )
function this =ByBinaryRegrParams (regtmp )
this =this @classreg .learning .modelparams .ModelParams ('ByBinaryRegr' ,'classification' ); 
this .RegressionTemplate =regtmp ; 
end
end

methods (Static ,Hidden )
function [holder ,extraArgs ]=make (type ,varargin )

args ={'learner' }; 
defs ={[]}; 
[regtmp ,~,extraArgs ]=...
    internal .stats .parseArgs (args ,defs ,varargin {:}); 


if~isempty (regtmp )&&~isa (regtmp ,'classreg.learning.FitTemplate' )
error (message ('stats:classreg:learning:modelparams:ByBinaryRegrParams:make:LearnerNotFitTemplate' )); 
end
if~isempty (regtmp )&&~strcmp (regtmp .Type ,'regression' )
error (message ('stats:classreg:learning:modelparams:ByBinaryRegrParams:make:LearnerNotForRegression' )); 
end


holder =classreg .learning .modelparams .ByBinaryRegrParams (regtmp ); 
end
end

methods (Hidden )
function this =fillDefaultParams (this ,X ,Y ,W ,dataSummary ,classSummary )
ifisempty (this .RegressionTemplate )
this .RegressionTemplate =classreg .learning .FitTemplate .make (...
    'Tree' ,'type' ,'regression' ,'minleaf' ,5 ); 
end
end
end

end
