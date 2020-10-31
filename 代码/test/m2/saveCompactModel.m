function saveCompactModel (compactObj ,filename )















ifnargin >1 
filename =convertStringsToChars (filename ); 
end

narginchk (2 ,2 ); 

compactStruct =toStruct (compactObj ); %#ok<NASGU> 
save (filename ,'compactStruct' ); 


