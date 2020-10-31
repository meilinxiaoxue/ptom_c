function [fxi ,fxiVar ]=getAdjustedResponse (model ,var ,xi ,terminfo )




ifnargin <4 

terminfo =getTermInfo (model ); 
end
ifisnumeric (var )
vnum =var ; 
else
[~,vnum ]=identifyVar (model ,var ); 
end




[xrow ,psmatrix ,psflag ]=reduceterm (model ,vnum ,terminfo ); 


nrows =size (xi ,1 ); 
X =repmat (xrow ,nrows ,1 ); 
fork =1 :length (psflag )
ifpsflag (k )

forj =1 :max (psmatrix (k ,:))
t =(psmatrix (k ,:)==j ); 
ifany (t )
X (:,t )=bsxfun (@times ,X (:,t ),(xi (:,k )==j )); 
end
end
else

forj =1 :max (psmatrix (k ,:))
t =(psmatrix (k ,:)==j ); 
X (:,t )=bsxfun (@times ,X (:,t ),xi (:,k ).^j ); 
end
end
end


fxi =X *model .Coefs ; 
ifnargout >=2 
fxiVar =X *model .CoefficientCovariance *X ' ; 
end



function [xrow ,psmatrix ,psflag ]=reduceterm (model ,vnum ,terminfo )






xrow =zeros (size (terminfo .designTerms )); 
psmatrix =zeros (length (vnum ),length (terminfo .designTerms )); 
psflag =terminfo .isCatVar (vnum ); 

forj =1 :size (terminfo .terms ,1 )
v =terminfo .terms (j ,:); 
tj =terminfo .designTerms ==j ; 
pwr =v (vnum ); 
meanx =gettermmean (v ,vnum ,model ,terminfo ); 

ifall (pwr ==0 |~psflag )



xrow (tj )=meanx ; 
psmatrix (:,tj )=repmat (pwr ' ,1 ,sum (tj )); 
elseifisscalar (vnum )&&sum (terminfo .isCatVar (v >0 ))==sum (psflag )

xrow (tj )=meanx ; 
psmatrix (:,tj )=2 :terminfo .numCatLevels (vnum ); 
else



isreduced =ismember (find (v >0 ),vnum ); 
termcatdims =terminfo .numCatLevels (v >0 ); 
sz1 =ones (1 ,max (2 ,length (termcatdims ))); 
sz1 (~isreduced )=max (1 ,termcatdims (~isreduced )-1 ); 
sz2 =ones (1 ,max (2 ,length (termcatdims ))); 
sz2 (isreduced )=max (1 ,termcatdims (isreduced )-1 ); 


meanx =reshape (meanx ,sz1 ); 
meanx =repmat (meanx ,sz2 ); 
xrow (tj )=meanx (:)' ; 


controws =(pwr >0 )&~psflag ; 
psmatrix (controws ,tj )=repmat (pwr (controws ),1 ,sum (tj )); 


catrows =(pwr >0 )&psflag ; 
catsettings =1 +fullfact (terminfo .numCatLevels (vnum (catrows ))-1 )' ; 
idx =reshape (1 :size (catsettings ,2 ),sz2 ); 
idx =repmat (idx ,sz1 ); 
psmatrix (catrows ,tj )=catsettings (:,idx (:)); 
end
end



function meanx =gettermmean (v ,vnum ,model ,terminfo )





v (vnum )=0 ; 


[ok ,row ]=ismember (v ,terminfo .terms ,'rows' ); 
ifok 

meanx =terminfo .designMeans (terminfo .designTerms ==row ); 
else

ifisempty (model .TermMeans )
ok =false ; 
else
[ok ,row ]=ismember (v ,model .TermMeans .Terms ,'rows' ); 
end

ifok 
meanx =model .TermMeans .Means (model .TermMeans .CoefTerm ==row ); 
else

X =model .Data ; 
ifisstruct (X )
X =X .X ; 
v (end)=[]; 
end
design =classreg .regr .modelutils .designmatrix (X ,'Model' ,v ,'VarNames' ,model .Formula .VariableNames ); 
meanx =mean (design ,1 ); 
end
end
