function regrCheck (Y ,Yfit ,W )





iflength (Y )~=length (Yfit )
error (message ('stats:classreg:learning:internal:regrCheck:LengthYandYfitMismatch' )); 
end
if~isvector (Y )||~isvector (Yfit )
error (message ('stats:classreg:learning:internal:regrCheck:BadDims' )); 
end


if~isnumeric (Y )
error (message ('stats:classreg:learning:internal:regrCheck:BadY' )); 
end
if~isnumeric (Yfit )
error (message ('stats:classreg:learning:internal:regrCheck:BadYfit' )); 
end


if~isfloat (W )||~isvector (W )||length (W )~=length (Y )||any (W <0 )
error (message ('stats:classreg:learning:internal:regrCheck:BadWeights' ,length (Y ))); 
end
end
