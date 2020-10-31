function s =structToClassif (s )






s =rmfield (s ,'FromStructFcn' ); 


dataSummary =s .DataSummary ; 

dataSummary =rmfield (dataSummary ,'NumPredictors' ); 

ifischar (dataSummary .PredictorNames )
dataSummary .PredictorNames =cellstr (dataSummary .PredictorNames )' ; 
if~isempty (dataSummary .PredictorNamesLength )
dataSummary .PredictorNames =...
    arrayfun (@(x ,y )x {1 }(1 :y ),...
    dataSummary .PredictorNames ,...
    dataSummary .PredictorNamesLength ,...
    'UniformOutput' ,false ); 
end
D =numel (dataSummary .PredictorNames ); 
else

D =dataSummary .PredictorNames ; 
end
dataSummary =rmfield (dataSummary ,'PredictorNamesLength' ); 

dataSummary .VariableRange =repmat ({[]},1 ,D ); 

s .DataSummary =dataSummary ; 


classSummary =s .ClassSummary ; 



ifclassSummary .ClassNamesType ==int8 (2 )
classSummary .ClassNames =cellstr (classSummary .ClassNames ); 
classSummary .ClassNames =...
    arrayfun (@(x ,y )x {1 }(1 :y ),...
    classSummary .ClassNames ,...
    classSummary .ClassNamesLength ,...
    'UniformOutput' ,false ); 

classSummary .NonzeroProbClasses =cellstr (classSummary .NonzeroProbClasses ); 
classSummary .NonzeroProbClasses =...
    arrayfun (@(x ,y )x {1 }(1 :y ),...
    classSummary .NonzeroProbClasses ,...
    classSummary .NonzeroProbClassesLength ,...
    'UniformOutput' ,false ); 
end

classSummary .ClassNames =...
    classreg .learning .internal .ClassLabel (classSummary .ClassNames ); 
classSummary .NonzeroProbClasses =...
    classreg .learning .internal .ClassLabel (classSummary .NonzeroProbClasses ); 

classSummary =rmfield (classSummary ,'ClassNamesType' ); 
classSummary =rmfield (classSummary ,'ClassNamesLength' ); 
classSummary =rmfield (classSummary ,'NonzeroProbClassesLength' ); 

s .ClassSummary =classSummary ; 


s .ScoreTransform =str2func (s .ScoreTransform ); 


ifisfield (s ,'DefaultLoss' )
s .DefaultLoss =str2func (s .DefaultLoss ); 
end


ifisfield (s ,'LabelPredictor' )
s .LabelPredictor =str2func (s .LabelPredictor ); 
end

end
