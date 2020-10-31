function converted =convertScoreTransform (st ,to ,K )




switchto 
case 'handle' 
ifisa (st ,'function_handle' )
converted =st ; 
elseifischar (st )
ifstrcmpi (st ,'none' )
converted =@classreg .learning .transform .identity ; 
else
converted =str2func (['classreg.learning.transform.' ,st (:)' ]); 
end
else
error (message ('stats:classreg:learning:internal:convertScoreTransform:BadType' )); 
end
try
converted (zeros (1 ,K )); 
catch me 
error (message ('stats:classreg:learning:internal:convertScoreTransform:BadTransform' ,me .message )); 
end
case 'string' 
converted =func2str (st ); 
ifstrcmp (converted ,'classreg.learning.transform.identity' )
converted ='none' ; 
end
idx =strfind (converted ,'classreg.learning.transform.' ); 
if~isempty (idx )
converted =converted (1 +length ('classreg.learning.transform.' ):end); 
end
end
end
