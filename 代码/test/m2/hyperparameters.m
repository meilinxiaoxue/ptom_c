function VariableDescriptions =hyperparameters (FitFunctionName ,varargin )

























































ifnargin >0 
FitFunctionName =convertStringsToChars (FitFunctionName ); 
end

ifnargin >1 
[varargin {:}]=convertStringsToChars (varargin {:}); 
end

narginchk (3 ,4 ); 
switchFitFunctionName 
case {'fitcecoc' ,'fitcensemble' ,'fitrensemble' }
ifnargin ~=4 
classreg .learning .paramoptim .err ('NarginEnsemble' ); 
else
Predictors =varargin {1 }; 
Response =varargin {2 }; 
Learners =varargin {3 }; 
BOInfo =classreg .learning .paramoptim .BayesoptInfo .makeBayesoptInfo (FitFunctionName ,...
    Predictors ,Response ,{'Learners' ,Learners }); 
end
case {'fitcdiscr' ,'fitcknn' ,'fitclinear' ,'fitcnb' ,'fitcsvm' ,...
    'fitctree' ,'fitrgp' ,'fitrlinear' ,'fitrsvm' ,'fitrtree' }
ifnargin ~=3 
classreg .learning .paramoptim .err ('NarginNonEnsemble' ); 
else
Predictors =varargin {1 }; 
Response =varargin {2 }; 
BOInfo =classreg .learning .paramoptim .BayesoptInfo .makeBayesoptInfo (FitFunctionName ,...
    Predictors ,Response ,{}); 
end
otherwise
classreg .learning .paramoptim .err ('UnknownFitFcn' ,FitFunctionName ); 
end
VariableDescriptions =BOInfo .AllVariableDescriptions ; 
end
