function vloss =loss (scoreType ,dist ,M ,pscore )%#codegen 




N =size (pscore ,1 ); 

K =size (M ,1 ); 
vloss =repmat (coder .internal .nan ('like' ,pscore ),N ,K ); 
fork =1 :K 
vloss (:,k )=localvloss (scoreType ,dist ,M (k ,:),pscore ); 
end

end

function vloss =localvloss (scoreType ,userloss ,M ,f )

switchuserloss 
case 'hamming' 
ifstrcmp (scoreType ,'inf' )
vloss =nanmean (1 -sign (bsxfun (@times ,M ,f )),2 )/2 ; 
else

vloss =nanmean (1 -sign (bsxfun (@times ,M ,2 *f -1 )),2 )/2 ; 
end
case 'linear' 
vloss =nanmean (1 -bsxfun (@times ,M ,f ),2 )/2 ; 
case 'quadratic' 
vloss =nanmean ((1 -bsxfun (@times ,M ,2 *f -1 )).^2 ,2 )/2 ; 
case 'exponential' 
vloss =nanmean (exp (-bsxfun (@times ,M ,f )),2 )/2 ; 
case 'binodeviance' 
vloss =nanmean (log (1 +exp (-2 *bsxfun (@times ,M ,f ))),2 )/(2 *log (2 )); 
case 'hinge' 
vloss =nanmean (max (0 ,1 -bsxfun (@times ,M ,f )),2 )/2 ; 
case 'logit' 
vloss =nanmean (log (1 +exp (-bsxfun (@times ,M ,f ))),2 )/(2 *log (2 )); 
end
end
