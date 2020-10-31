function [Xs ,mu ,sigma ]=standardizeData (X ,cols )

























ifnargin <2 
cols =true (1 ,size (X ,2 )); 
end


mu =mean (X ,1 ); 
sigma =std (X ,0 ,1 ); 
ifany (~cols )
mu (~cols )=0 ; 
sigma (~cols )=1 ; 
end


zeroSigmaIdx =sigma <sqrt (eps (class (X ))); 
mu (zeroSigmaIdx )=0 ; 
sigma (zeroSigmaIdx )=1 ; 


Xs =X ; 
nonZeroSigmaIdx =~zeroSigmaIdx ; 
Xs (:,nonZeroSigmaIdx )=bsxfun (@rdivide ,bsxfun (@minus ,X (:,nonZeroSigmaIdx ),mu (1 ,nonZeroSigmaIdx )),sigma (1 ,nonZeroSigmaIdx )); 


ifnargout >1 
mu =mu ' ; 
sigma =sigma ' ; 
end
end