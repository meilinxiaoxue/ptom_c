function t =tstats (coefs ,se ,nobs ,coefnames )






















if~internal .stats .isScalarInt (nobs ,0 )
error (message ('stats:classreg:regr:modelutils:BadNumObs' )); 
end

coefs =coefs (:); 
ncoefs =numel (coefs ); 
se =se (:); 
ifnumel (se )~=ncoefs 
error (message ('stats:classreg:regr:modelutils:CoefSEDifferentLength' )); 
end

ifnargin <4 
coefnames =internal .stats .numberedNames ('b' ,1 :ncoefs ); 
elseif~internal .stats .isStrings (coefnames )
error (message ('stats:classreg:regr:modelutils:BadCoeffNames' )); 
elseifnumel (coefnames )~=ncoefs 
error (message ('stats:classreg:regr:modelutils:BadCoeffNameLength' )); 
end

dfe =max (0 ,nobs -ncoefs ); 
tstat =coefs ./se ; 
p =2 *tcdf (-abs (tstat ),dfe ); 
t =table (coefs ,se ,tstat ,p ,...
    'VariableNames' ,{'Estimate' ,'SE' ,'tStat' ,'pValue' },...
    'RowNames' ,coefnames ); 
