function [dist ,ignorezeros ]=prepareForPredict (...
    scoretype ,userloss ,defaultloss ,decoding )%#codegen 




coder .internal .errorIf (~ischar (decoding ),...
    'stats:classreg:learning:classif:CompactClassificationECOC:predict:BadDecodingType' ); 

allowedVals ={'LossBased' ,'LossWeighted' }; 
tf =strncmpi (decoding ,allowedVals ,length (decoding )); 
coder .internal .errorIf (sum (tf )~=1 ,...
    'stats:classreg:learning:classif:CompactClassificationECOC:predict:BadDecodingValue' ); 

ignorezeros =tf (2 ); 

coder .internal .errorIf (isempty (defaultloss ),...
    'stats:classreg:learning:classif:CompactClassificationECOC:predict:MustProvideCustomBinaryLoss' ); 

allowedVals ={'hamming' ,'linear' ,'quadratic' ,'exponential' ,'binodeviance' ,'hinge' ,'logit' }; 
tf =strncmpi (userloss ,allowedVals ,length (userloss )); 
coder .internal .errorIf (sum (tf )~=1 ,...
    'stats:classreg:learning:classif:CompactClassificationECOC:predict:BinaryLoss' ); 

userlossStr =allowedVals {tf }; 

coder .internal .errorIf (strcmp (userlossStr ,'quadratic' )&&...
    ~(strcmp (scoretype ,'01' )||strcmp (scoretype ,'probability' )),...
    'stats:classreg:learning:classif:CompactClassificationECOC:predict:QuadraticLossForInfRange' ); 

tf =strncmpi (userlossStr ,{'linear' ,'exponential' ,'binodeviance' ,'hinge' ,'logit' },length (userlossStr )); 
coder .internal .errorIf (sum (tf )==1 &&~strcmp (scoretype ,'inf' ),...
    'stats:classreg:learning:classif:CompactClassificationECOC:predict:BadBinaryLossFor01Range' ,userloss ); 

dist =userlossStr ; 

end
