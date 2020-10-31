function Idx =anyArgPassed (ArgNames ,NVPs )

Defaults =repmat ({[]},1 ,numel (ArgNames )); 
[Values {1 :numel (ArgNames )},setflag ,~]=internal .stats .parseArgs (ArgNames ,Defaults ,NVPs {:}); 
Idx =anyFieldTrue (setflag ); 
end

function Idx =anyFieldTrue (aStruct )
T =struct2table (aStruct ); 
Idx =find (T {1 ,:},1 ); 
end