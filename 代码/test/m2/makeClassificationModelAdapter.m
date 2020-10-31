function adapter =makeClassificationModelAdapter (obj ,varargin )

ifany (cellfun (@(x )istall (x ),varargin ))
adapter =internal .stats .bigdata .ClassRegModelTallAdapter (obj ); 






else
adapter =[]; 
end

end
