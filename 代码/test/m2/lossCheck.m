function funloss =lossCheck (funloss ,type )




ifischar (funloss )
ifstrcmp (type ,'classification' )
allowed ={'binodeviance' ,'classifedge' ,'classiferror' ...
    ,'exponential' ,'mincost' ,'hinge' ,'quadratic' ,'logit' }; 
elseifstrcmp (type ,'regression' )
allowed ={'mse' }; 
else
allowed ={}; 
end
idx =find (strncmpi (funloss ,allowed ,length (funloss ))); 
ifisempty (idx )||~isscalar (idx )
error (message ('stats:classreg:learning:internal:lossCheck:BadFunlossString' )); 
end
funloss =str2func (['classreg.learning.loss.' ,allowed {idx }]); 
elseif~isa (funloss ,'function_handle' )
error (message ('stats:classreg:learning:internal:lossCheck:BadFunlossType' )); 
end
end
