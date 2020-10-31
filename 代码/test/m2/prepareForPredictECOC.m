function [dist ,isbuiltindist ,ignorezeros ,doquadprog ]=prepareForPredictECOC (...
    scoretype ,doposterior ,postmethod ,userloss ,defaultloss ,decoding ,numfits )




ifdoposterior 
if~strcmp (scoretype ,'probability' )
error (message ('stats:classreg:learning:classif:CompactClassificationECOC:predict:CannotFitProbabilities' )); 
end
end


if~ischar (decoding )
error (message ('stats:classreg:learning:classif:CompactClassificationECOC:predict:BadDecodingType' )); 
end
allowedVals ={'LossBased' ,'LossWeighted' }; 
tf =strncmpi (decoding ,allowedVals ,length (decoding )); 
ifsum (tf )~=1 
error (message ('stats:classreg:learning:classif:CompactClassificationECOC:predict:BadDecodingValue' )); 
end
ignorezeros =tf (2 ); 


doquadprog =[]; 
ifdoposterior 
if~ischar (postmethod )
error (message ('stats:classreg:learning:classif:CompactClassificationECOC:predict:BadPosteriorMethodType' )); 
end
allowedVals ={'QP' ,'KL' }; 
tf =strncmpi (postmethod ,allowedVals ,length (postmethod )); 
ifsum (tf )~=1 
error (message ('stats:classreg:learning:classif:CompactClassificationECOC:predict:BadPosteriorMethodValue' )); 
end
doquadprog =tf (1 ); 
end


ifdoposterior 
if~isempty (numfits )&&...
    (~isscalar (numfits )||~isnumeric (numfits )...
    ||numfits ~=round (numfits )||numfits <0 )
error (message ('stats:classreg:learning:classif:CompactClassificationECOC:predict:BadNumKLInitializationsType' )); 
end
ifdoquadprog &&numfits >0 
error (message ('stats:classreg:learning:classif:CompactClassificationECOC:predict:BadNumKLInitializationsValue' )); 
end
end


if~isa (userloss ,'function_handle' )
ifisempty (defaultloss )
error (message ('stats:classreg:learning:classif:CompactClassificationECOC:predict:MustProvideCustomBinaryLoss' )); 
end

allowedVals ={'hamming' ,'linear' ,'quadratic' ,'exponential' ,'binodeviance' ,'hinge' ,'logit' }; 
tf =strncmpi (userloss ,allowedVals ,length (userloss )); 
ifsum (tf )~=1 
error (message ('stats:classreg:learning:classif:CompactClassificationECOC:predict:BinaryLoss' )); 
end
userloss =allowedVals {tf }; 

ifstrcmp (userloss ,'quadratic' )&&...
    ~(strcmp (scoretype ,'01' )||strcmp (scoretype ,'probability' ))
error (message ('stats:classreg:learning:classif:CompactClassificationECOC:predict:QuadraticLossForInfRange' )); 
end

ifismember (userloss ,{'linear' ,'exponential' ,'binodeviance' ,'hinge' ,'logit' })...
    &&~strcmp (scoretype ,'inf' )
error (message ('stats:classreg:learning:classif:CompactClassificationECOC:predict:BadBinaryLossFor01Range' ,userloss )); 
end
end


ifisa (userloss ,'function_handle' )
dist =userloss ; 
isbuiltindist =false ; 

else

switchuserloss 
case 'hamming' 
switchscoretype 
case 'inf' 
dist =@(M ,f )nanmean (1 -sign (bsxfun (@times ,M ,f )),2 )/2 ; 
case {'01' ,'probability' }
dist =@(M ,f )nanmean (1 -sign (bsxfun (@times ,M ,2 *f -1 )),2 )/2 ; 
end
case 'linear' 
dist =@(M ,f )nanmean (1 -bsxfun (@times ,M ,f ),2 )/2 ; 
case 'quadratic' 
dist =@(M ,f )nanmean ((1 -bsxfun (@times ,M ,2 *f -1 )).^2 ,2 )/2 ; 
case 'exponential' 
dist =@(M ,f )nanmean (exp (-bsxfun (@times ,M ,f )),2 )/2 ; 
case 'binodeviance' 
dist =@(M ,f )nanmean (log (1 +exp (-2 *bsxfun (@times ,M ,f ))),2 )/(2 *log (2 )); 
case 'hinge' 
dist =@(M ,f )nanmean (max (0 ,1 -bsxfun (@times ,M ,f )),2 )/2 ; 
case 'logit' 
dist =@(M ,f )nanmean (log (1 +exp (-bsxfun (@times ,M ,f ))),2 )/(2 *log (2 )); 
end

isbuiltindist =true ; 
end

end
