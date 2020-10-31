function compactObj =loadCompactModel (filename )%#codegen 















coder .inline ('always' ); 
narginchk (1 ,1 ); 

matFile =coder .load (filename ); 



isValidMATFile =isfield (matFile ,'compactStruct' )||isfield (matFile ,'classificationStruct' ); 

coder .internal .errorIf (~isValidMATFile ,...
    'stats:classreg:loadCompactModel:UnsupportedStructForCodegen' ); 

ifisfield (matFile ,'compactStruct' )
compactObj =classreg .coderutils .structToModel (matFile .compactStruct ); 
else
compactObj =classreg .coderutils .structToModel (matFile .classificationStruct ); 
end
