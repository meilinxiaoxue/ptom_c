classdef (Sealed =true )LinearFormula <classreg .regr .FormulaProcessor 



properties (Constant ,GetAccess ='protected' )
rules ={
 '  Formula          = (Response Spaces "~" Spaces)? LinearPredictor' 
 '+ Response         = LinkFunction / ResponseVar' 
 '+ LinkFunction     = LinkName "(" Spaces ResponseVar Spaces ")" / PowerLink' 
 '  PowerLink        = "power" "(" Spaces ResponseVar Spaces "," Spaces Expon Spaces ")"' 
 '  ResponseVar      = Name' 
 '+ LinearPredictor  = Sum / Zero' 
 '  Sum              = Augend (Spaces (Addend / Subend))*' 
 '- Augend           = Conditional / Subend' 
 '+ Addend           = "+" Spaces Conditional' 
 '+ Subend           = "-" Spaces Conditional' 
 
 '  Conditional      = Product' 
 '  Product          = Inside (Spaces "*" Spaces Inside)*' 
 '  Inside           = Interaction (Spaces "/" Spaces PredictorVar)?' 
 '  Interaction      = Power (Spaces ":" Spaces Power)*' 
 '  Power            = Predictor ("^" Integer)?' 
 
 '- Predictor        = "(" Spaces Sum Spaces ")" / AllElse / PredictorVar / Intercept' 
 
 '  LinkName         = Name' 
 
 
 '  PredictorVar     = Name' 
 '- Name             = [A-Za-z_] [A-Za-z0-9_]*' 
 
 '  Expon            = [0-9]+ ( "." [0-9]+ )' 
 '  Integer          = [0-9]+' 
 '  Intercept        = "1"' 
 '  Zero             = "0"' 
 ['  AllElse          = "' ,classreg .regr .FormulaProcessor .allElseStr ,'"' ]
 '- Spaces           = (" ")*' 
 }; 
p =internal .stats .PEG (classreg .regr .LinearFormula .rules ); 
irules =rulemap (classreg .regr .LinearFormula .p ); 
end
properties (Access ='protected' )
isMultivariate =false ; 
end

methods (Access ='public' )
function f =LinearFormula (varargin )
f =f @classreg .regr .FormulaProcessor (varargin {:}); 
end
end
end
