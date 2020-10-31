function s =structToRegr (s )






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


s .ResponseTransform =str2func (s .ResponseTransform ); 


ifisfield (s ,'DefaultLoss' )
s .DefaultLoss =str2func (s .DefaultLoss ); 
end


ifisfield (s ,'LabelPredictor' )
s .LabelPredictor =str2func (s .LabelPredictor ); 
end

end
