function s =classifToStruct (obj )








dataSummary =obj .DataSummary ; 

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




classSummary =obj .ClassSummary ; 
classnames =labels (classSummary .ClassNames ); 
nonzeroclasses =labels (classSummary .NonzeroProbClasses ); 

if~strcmp (class (classnames ),class (nonzeroclasses ))
error (message ('stats:classreg:learning:coderutils:classifToStruct:MismatchedClassTypes' )); 
end

classnamesType =labelType (classnames ); 

ifclassnamesType ==int8 (1 )
classnamesLength =ones (size (classnames ,1 ),1 ); 
ifischar (classnames )
nonzeroclassesLength =size (nonzeroclasses ,2 ); 
else
nonzeroclassesLength =ones (size (nonzeroclasses ,1 ),1 ); 
end

elseifclassnamesType ==int8 (2 )
classnamesLength =cellfun (@length ,classnames ); 
classnames =char (classnames ); 
nonzeroclassesLength =cellfun (@length ,nonzeroclasses ); 
nonzeroclasses =char (nonzeroclasses ); 
end

classSummary .ClassNames =classnames ; 
classSummary .NonzeroProbClasses =nonzeroclasses ; 
classSummary .ClassNamesType =classnamesType ; 
classSummary .ClassNamesLength =classnamesLength ; 
classSummary .NonzeroProbClassesLength =nonzeroclassesLength ; 


s .ClassSummary =classSummary ; 


s .ScoreTransform =func2str (obj .PrivScoreTransform ); 


s .ScoreType =obj .PrivScoreType ; 


s .DefaultLoss =func2str (obj .DefaultLoss ); 


s .LabelPredictor =func2str (obj .LabelPredictor ); 


s .DefaultScoreType =obj .DefaultScoreType ; 

end


function t =labelType (labels )
ifisnumeric (labels )||islogical (labels )||ischar (labels )
t =int8 (1 ); 
elseifiscellstr (labels )
t =int8 (2 ); 
else
error (message ('stats:classreg:learning:coderutils:classifToStruct:CategoricalLabelsNotSupported' )); 
end
end
