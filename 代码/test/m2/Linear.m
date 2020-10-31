classdef Linear %#codegen 






properties (SetAccess =protected ,GetAccess =public )


Beta ; 


Bias ; 





end
methods (Static ,Hidden ,Abstract )

predictEmptyLinearModel (obj )
end

methods (Access =protected )
function obj =Linear (cgStruct )

coder .internal .prefer_const (cgStruct ); 

validateFields (cgStruct ); 

obj .Bias =cgStruct .Impl .Bias ; %#ok<*MCNPN> 
obj .Beta =cgStruct .Impl .Beta ; 

end

end

methods (Static ,Access =protected )

function obsInRows =extractObsInRows (varargin )

orientation =parseOptionalInputs (varargin {:}); 

obsIn =validateObservationsIn (orientation ); 

obsInRows =strncmpi (obsIn ,'rows' ,1 ); 

end

function posterior =linearPredictEmptyX (Xin ,K ,numPredictors ,bias ,obsInRows )

ifobsInRows 
Dpassed =coder .internal .indexInt (size (Xin ,2 )); 
str ='columns' ; 
else
Dpassed =coder .internal .indexInt (size (Xin ,1 )); 
str ='rows' ; 
end

coder .internal .errorIf (Dpassed ~=numPredictors ,...
    'stats:classreg:learning:classif:ClassificationModel:predictEmptyX:XSizeMismatch' ,numPredictors ,str ); 

ifisa (Xin ,'double' )&&isa (bias ,'single' )
X =single (Xin ); 
else
X =Xin ; 
end

posterior =repmat (coder .internal .nan (1 ,1 ,'like' ,X ),0 ,K ); 
end
end

methods (Hidden ,Access =protected )

function S =score (obj ,Xin ,obsInRows )


coder .internal .prefer_const (obj ); 

numLambda =cast (1 ,'like' ,obj .Bias ); 

ifisa (Xin ,'double' )&&isa (obj .Bias ,'single' )
X =single (Xin ); 
else
X =Xin ; 
end

ifobsInRows 
D =size (X ,2 ); 
str ='columns' ; 
else
D =size (X ,1 ); 
str ='rows' ; 
end
ifisempty (obj .Beta )
S =obj .predictEmptyLinearModel (X ,obj .Bias ,numLambda ); 
else
coder .internal .errorIf (coder .internal .indexInt (D )~=obj .NumPredictors ,...
    'stats:classreg:learning:classif:ClassificationModel:predictEmptyX:XSizeMismatch' ,obj .NumPredictors ,str ); 

ifobsInRows 
S =bsxfun (@plus ,X *obj .Beta ,obj .Bias ); 
else
S =bsxfun (@plus ,(obj .Beta ' *X )' ,obj .Bias ); 
end
end
end

end

methods (Static ,Hidden )
function props =matlabCodegenNontunableProperties (~)
props ={'ObservationsInRows' }; 
end
end
end


function observationsIn =parseOptionalInputs (varargin )




coder .inline ('always' ); 
coder .internal .prefer_const (varargin ); 

params =struct (...
    'ObservationsIn' ,uint32 (0 )); 

popts =struct (...
    'CaseSensitivity' ,false ,...
    'StructExpand' ,true ,...
    'PartialMatching' ,true ); 

optarg =eml_parse_parameter_inputs (params ,popts ,...
    varargin {:}); 
observationsIn =eml_get_parameter_value (...
    optarg .ObservationsIn ,'rows' ,varargin {:}); 

end

function validateFields (InStr )



coder .inline ('always' ); 


validateattributes (InStr .Impl .Bias ,{'numeric' },{'nonnan' ,'finite' ,'nonempty' ,'scalar' ,'real' },mfilename ,'Bias' ); 

if~isempty (InStr .Impl .Beta )
validateattributes (InStr .Impl .Beta ,{'numeric' },{'column' ,'numel' ,InStr .DataSummary .NumPredictors ,'real' },mfilename ,'Beta' ); 
end


end

function ori =validateObservationsIn (orientation )


coder .inline ('always' ); 
coder .internal .prefer_const (orientation ); 
ori =validatestring (orientation ,{'rows' ,'columns' },mfilename ,'ObservationsIn' ); 

end


