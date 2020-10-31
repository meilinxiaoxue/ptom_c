function terms =model2terms (modelStr ,nvars ,includeIntercept ,treatAsCategorical )




















































[c ,startLoc ,endLoc ]=regexp (lower (modelStr ),'poly(\d*)' ,'tokens' ); 
polyStr =(isscalar (c )&&(startLoc ==1 )&&(endLoc ==length (modelStr ))); 

ifislogical (nvars )
whichVars =nvars (:)' ; 
nvars =length (whichVars ); 
else
whichVars =true (1 ,nvars ); 
end

ifnargin <3 ,includeIntercept =true ; end
ifnargin <4 ,treatAsCategorical =false (1 ,nvars ); end

ifpolyStr 
powers =str2num (c {1 }{1 }' ); 
nincluded =sum (whichVars ); 
iflength (powers )~=nincluded 
error (message ('stats:classreg:regr:modelutils:BadLength' ,modelStr )); 
end
maxPower =max (powers ); 
ifnvars ==1 
terms =((1 -includeIntercept ):maxPower )' ; 
else

tmp =powers ; powers =zeros (1 ,nvars ); powers (whichVars )=tmp ; 


powers (treatAsCategorical )=max (powers (treatAsCategorical ),1 ); 


powers =arrayfun (@(n )0 :n ,powers ,'UniformOutput' ,false ); 
[powers {1 :nvars }]=ndgrid (powers {:}); 
powers =cellfun (@(c )c (:),powers ,'UniformOutput' ,false ); 
terms =[powers {:}]; 


[sumPowers ,ord ]=sort (sum (terms ,2 )); 
terms =terms (ord ,:); 


terms =terms (sumPowers <=maxPower ,:); 
if~includeIntercept ,terms (1 ,:)=[]; end
end

else
switchlower (modelStr )
case 'constant' ,linear =false ; interactions =false ; quadratic =false ; 
case 'linear' ,linear =true ; interactions =false ; quadratic =false ; 
case 'interactions' ,linear =true ; interactions =true ; quadratic =false ; 
case 'purequadratic' ,linear =true ; interactions =false ; quadratic =true ; 
case 'quadratic' ,linear =true ; interactions =true ; quadratic =true ; 
otherwise
modelStrings ={'constant' ,'linear' ,'interactions' ,'quadratic' ,'purequadratic' ,'poly*' }; 
error (message ('stats:classreg:regr:modelutils:BadModel' ,internal .stats .listStrings (modelStrings ))); 
end

icpt =zeros (includeIntercept ,nvars ); 
iflinear 
linear =eye (nvars ); linear =linear (whichVars ,:); 
else
linear =zeros (0 ,nvars ); 
end
ifinteractions 
[rep1 ,rep2 ]=allpairs (find (whichVars )); 
ninteractions =length (rep1 ); 
interactions =zeros (ninteractions ,nvars ); 
interactions (sub2ind (size (interactions ),1 :ninteractions ,rep1 ))=1 ; 
interactions (sub2ind (size (interactions ),1 :ninteractions ,rep2 ))=1 ; 
else
interactions =zeros (0 ,nvars ); 
end
ifquadratic 
whichQuadraticVars =whichVars &~treatAsCategorical ; 
quadratic =2 *eye (nvars ); quadratic =quadratic (whichQuadraticVars ,:); 
else
quadratic =zeros (0 ,nvars ); 
end

terms =[icpt ; linear ; interactions ; quadratic ]; 
end



function [rep1 ,rep2 ]=allpairs (i ,diag )
ifnargin <2 ||~diag 
[r ,c ]=find (tril (ones (length (i )),-1 )); 
else
[r ,c ]=find (tril (ones (length (i )),0 )); 
end
i =i (:)' ; 
rep1 =i (1 ,c ); 
rep2 =i (1 ,r ); 
