classdef CompactRegressionEnsemble <classreg .learning .coder .model .CompactEnsemble ...
    &classreg .learning .coder .regr .CompactRegressionModel 

%#codegen 









methods (Access =protected )

function obj =CompactRegressionEnsemble (cgStruct )

coder .internal .prefer_const (cgStruct ); 


obj @classreg .learning .coder .regr .CompactRegressionModel (cgStruct ); 
obj @classreg .learning .coder .model .CompactEnsemble (cgStruct ); 

end

end

methods 
function score =predict (obj ,X ,varargin )



























narginchk (2 ,Inf )
coder .internal .prefer_const (obj ); 
obj .validateX (X ); 
T =length (fieldnames (obj .Learners )); 

ensemblePredictValidateNumTrained (obj ,X ,coder .internal .indexInt (T )); 


ifisempty (X )
score =predictEmptyX (obj ,X ); 
return ; 
end

[N ,~]=size (X ); 

doclass =false ; 
score =coder .internal .nan (coder .internal .indexInt (N ),1 ); 
score =ensemblePredict (obj ,X ,score ,doclass ,[],[],[],varargin {:}); 


if~isempty (obj .ResponseTransform )
score =obj .ResponseTransform (score ); 
end


end
end

methods (Hidden ,Access =protected )
function yfit =predictEmptyX (obj ,X )

numPredictors =obj .NumPredictors ; 
yfit =classreg .learning .coder .model .CompactEnsemble .ensemblePredictEmptyX (X ,1 ,numPredictors ); 
end
end

methods (Static )
function obj =fromStruct (cgStruct )





coder .internal .prefer_const (cgStruct ); 
coder .inline ('always' ); 
obj =classreg .learning .coder .regr .CompactRegressionEnsemble (cgStruct ); 
end
end

methods (Static ,Hidden )
function props =matlabCodegenNontunableProperties (~)
propstemp1 =classreg .learning .coder .regr .CompactRegressionModel .matlabCodegenNontunableProperties ; 
propstemp2 =classreg .learning .coder .model .CompactEnsemble .matlabCodegenNontunableProperties ; 
props =[propstemp1 ,propstemp2 ]; 
end

function out =matlabCodegenToRedirected (obj )



tt =toStruct (obj ); 
out =classreg .learning .coder .regr .CompactRegressionEnsemble .fromStruct (coder .const (tt )); 
end

end


end





