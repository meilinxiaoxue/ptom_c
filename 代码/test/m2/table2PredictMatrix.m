function [Xout ,Yout ,W ]=table2PredictMatrix (X ,Y ,WeightsName ,vrange ,CategoricalPredictors ,pnames )


















n =size (X ,1 ); 
W =ones (n ,1 ); 

ifisa (X ,'dataset' )
X =dataset2table (X ); 
end

if~istable (X )

Yout =Y ; 
if~isempty (WeightsName )
W =WeightsName ; 
end
else

VarNames =X .Properties .VariableNames ; 


Yout =resolveName ('Y' ,Y ,VarNames ,X ); 


if~isempty (WeightsName )
W =resolveName ('Weights' ,WeightsName ,VarNames ,X ); 
end
end


Xout =makeXMatrix (X ,CategoricalPredictors ,vrange ,pnames ); 
end


function Xout =makeXMatrix (X ,CategoricalPredictors ,vrange ,PredictorNames )
ifisempty (CategoricalPredictors )&&~istable (X )
Xout =X ; 
return 
end
[n ,p ]=size (X ); 
ifistable (X )
ifisnumeric (PredictorNames )
p =PredictorNames ; 
PredictorNames =strcat ({'x' },strjust (num2str ((1 :p )' ),'left' )); 
else
p =numel (PredictorNames ); 
end
end
isCat =ismember (1 :p ,CategoricalPredictors ); 

Xout =zeros (n ,p ); 
pname ='' ; 
forj =1 :p 
ifistable (X )
pname =PredictorNames {j }; 
try
x =X .(pname ); 
catch me 
error (message ('stats:classreg:learning:internal:utils:MissingPredictors' ,pname )); 
end
else
x =X (:,j ); 
end
if~isempty (vrange )&&(isCat (j )||~isempty (vrange {j }))
ifischar (x )
x =cellstr (x ); 
end
vrj =vrange {j }; 
ifiscategorical (vrj )&&isordinal (vrj )&&iscategorical (x )
x =cellstr (x ); 
end
try
[~,x ]=ismember (x ,vrange {j }); 
catch 
x ='bad' ; 
end
end
if~isnumeric (x )&&~islogical (x )
ifistable (X )
error (message ('stats:classreg:learning:internal:utils:BadVariableType' ,pname ))
else
error (message ('stats:classreg:learning:internal:utils:BadColumnType' ,j ))
end
end
if~iscolumn (x )
error (message ('stats:classreg:learning:internal:utils:BadVariableSize' ,pname ))
end
Xout (:,j )=x ; 
end
end

function ArgName =resolveName (ParameterName ,ArgName ,VarNames ,X )
if~isempty (ArgName )&&internal .stats .isString (ArgName )

ifismember (ArgName ,VarNames )
ArgName =X .(ArgName ); 
elseifsize (X ,1 )>1 

error (message ('stats:classreg:learning:internal:utils:InvalidArg' ,ParameterName ))
end
end
end

