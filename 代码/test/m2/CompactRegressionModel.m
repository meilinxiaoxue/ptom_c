classdef CompactRegressionModel <classreg .learning .coder .CompactPredictor %#codegen 





properties (SetAccess =protected ,GetAccess =public )


ResponseTransform ; 
end
methods (Abstract )


predict (obj )
end
methods (Abstract ,Hidden ,Access =protected )
predictEmptyX (obj )
end
methods (Access =protected )
function obj =CompactRegressionModel (cgStruct )

coder .internal .prefer_const (cgStruct ); 

obj @classreg .learning .coder .CompactPredictor (cgStruct ); 


validateFields (cgStruct ); 
obj =obj .setResponseTransform (cgStruct ); 
end
end
methods (Access =protected )
function obj =setResponseTransform (obj ,cgStruct )

coder .internal .prefer_const (cgStruct ); 
ifcgStruct .CustomResponseTransform 
obj .ResponseTransform =str2func (cgStruct .ResponseTransformFull ); 
else
ifstrcmpi (cgStruct .ResponseTransform ,'identity' )
obj .ResponseTransform =[]; 
else
obj .ResponseTransform =str2func (['classreg.learning.coder.transform.' ,cgStruct .ResponseTransform ]); 
end
end
end
end
methods (Static ,Hidden )
function props =matlabCodegenNontunableProperties (~)
propstemp =classreg .learning .coder .CompactPredictor .matlabCodegenNontunableProperties ; 
props =['ResponseTransform' ,propstemp ]; 
end
end
end

function validateFields (InStr )

coder .inline ('always' ); 

validateattributes (InStr .ResponseTransformFull ,{'char' },{'nonempty' ,'row' },mfilename ,'ResponseTransform' ); 
validateattributes (InStr .ResponseTransform ,{'char' },{'nonempty' ,'row' },mfilename ,'ResponseTransform' ); 
validateattributes (InStr .CustomResponseTransform ,{'logical' },{'nonempty' ,'scalar' },mfilename ,'CustomResponseTransform' ); 

end