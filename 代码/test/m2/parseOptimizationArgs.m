function [IsOptimizing ,RemainingArgs ]=parseOptimizationArgs (Args )



[OptimizeHyperparameters ,~,~,RemainingArgs ]=internal .stats .parseArgs (...
    {'OptimizeHyperparameters' ,'HyperparameterOptimizationOptions' },{[],[]},Args {:}); 
IsOptimizing =~isempty (OptimizeHyperparameters )&&~isPrefixEqual (OptimizeHyperparameters ,'none' ); 
end

function tf =isPrefixEqual (thing ,targetString )
tf =~isempty (thing )&&ischar (thing )&&strncmpi (thing ,targetString ,length (thing )); 
end