function s =regrToStruct (obj )








dataSummary =obj .DataSummary ; 
dataSummary .RowsUsed =[]; 
dataSummary .PredictorNamesLength =[]; 
ifisnumeric (dataSummary .PredictorNames )
dataSummary .NumPredictors =dataSummary .PredictorNames ; 
else
pnames =dataSummary .PredictorNames ; 
dataSummary .NumPredictors =numel (pnames ); 
dataSummary .PredictorNamesLength =cellfun (@length ,pnames ); 
dataSummary .PredictorNames =char (pnames ); 
end

if~isempty (dataSummary .CategoricalPredictors )
error (message ('stats:classreg:learning:coderutils:classifToStruct:CategoricalPredictorsNotSupported' )); 
end



dataSummary =rmfield (dataSummary ,'VariableRange' ); 


s .DataSummary =dataSummary ; 


s .ResponseTransform =func2str (obj .PrivResponseTransform ); 


end

