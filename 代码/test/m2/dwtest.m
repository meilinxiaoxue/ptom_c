function [p ,stat ]=dwtest (model ,option ,tail )











































compactNotAllowed (model ,'dwtest' ,false ); 
ifnargin <2 
ifmodel .NumObservations <400 
option ='exact' ; 
else
option ='approximate' ; 
end; 
end; 
ifnargin <3 
tail ='both' ; 
end; 

subset =model .ObservationInfo .Subset ; 
r =model .Residuals .Raw (subset ); 
stat =sum (diff (r ).^2 )/sum (r .^2 ); 




pdw =dfswitchyard ('pvaluedw' ,stat ,model .design_r ,option ); 


switchlower (tail )
case 'both' 
p =2 *min (pdw ,1 -pdw ); 
case 'left' 
p =1 -pdw ; 
case 'right' 
p =pdw ; 
end

