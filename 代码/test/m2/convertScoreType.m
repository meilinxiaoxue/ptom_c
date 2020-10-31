function st =convertScoreType (st )



if~ischar (st )
error (message ('stats:classreg:learning:internal:convertScoreType:BadScoreType' )); 
end

allowed ={'probability' ,'01' ,'inf' ,'unknown' ,'none' }; 
tf =strncmpi (st ,allowed ,length (st )); 
ifsum (tf )~=1 
error (message ('stats:classreg:learning:internal:convertScoreType:BadScoreValue' ,sprintf (' ''%s''' ,allowed {:}))); 
end

st =allowed {tf }; 
ifstrcmp (st ,'unknown' )||strcmp (st ,'none' )
st =[]; 
end

end
