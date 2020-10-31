function termNames =terms2names (terms ,varNames )
































[nterms ,nvars ]=size (terms ); 
ifnargin <2 
varNames =strcat ({'x' },num2str ((1 :nvars )' ,'%-d' )); 
end
termNames =cell (nterms ,1 ); 
termOrder =sum (terms ,2 ); 
ifmax (termOrder )==1 

varNumber =terms *(1 :nvars )' ; 
linearTerm =varNumber >0 ; 
termNames (linearTerm )=varNames (varNumber (linearTerm )); 
termNames (~linearTerm )={'(Intercept)' }; 
return 
end
fori =1 :nterms 
iftermOrder (i )==0 
termNames {i }='(Intercept)' ; 
else
termNames {i }='' ; 
varList =find (terms (i ,:)>0 ); 
forj =varList 
ifterms (i ,j )==1 
varNamej =varNames {j }; 
elseiflength (varList )==1 
varNamej =sprintf ('%s^%d' ,varNames {j },terms (i ,j )); 
else
varNamej =sprintf ('(%s^%d)' ,varNames {j },terms (i ,j )); 
end
ifisempty (termNames {i })
termNames {i }=varNamej ; 
else
termNames {i }=[termNames {i },':' ,varNamej ]; 
end
end
end
end

