function lscore =loopBodyPredict (X ,outDataType ,trained ,idx ,obsInRows ,verbose )%#codegen 





coder .inline ('always' ); 
coder .internal .prefer_const (obsInRows ); 
coder .extrinsic ('getString' ,'message' ); 

ifverbose >1 
fprintf ('%s\n' ,getString (message ('stats:classreg:learning:classif:CompactClassificationECOC:localScore:ProcessingLearner' ,idx ))); 
end

ifobsInRows 
N =coder .internal .indexInt (size (X ,1 )); 
else
N =coder .internal .indexInt (size (X ,2 )); 
end

ifisempty (trained )
lscore =repmat (coder .internal .nan ('like' ,outDataType ),N ,1 ); 
else
obj =classreg .coderutils .structToModel (trained ); 
[~,s ]=classreg .learning .coderutils .ecoc .learnerPredict (obj ,X ,obsInRows ); 
lscore =s (:,2 ); 
end
end
