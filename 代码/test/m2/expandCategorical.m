function [Xout ,catcols ]=expandCategorical (X ,iscat ,vrange )















if~islogical (iscat )
iscat =ismember (1 :size (X ,2 ),iscat ); 
end


if~any (iscat )
Xout =X ; 
catcols =false (1 ,size (X ,2 )); 
return ; 
end

[N ,P ]=size (X ); 

dovrange =nargin >=3 &&~isempty (vrange ); 
ifdovrange 

ncats =cellfun (@numel ,vrange ); 
ncats (~iscat )=1 ; 
isord =cellfun (@(v )iscategorical (v )&&isordinal (v ),vrange ); 
else

ncats =ones (1 ,P ); 
forj =1 :P 
ifiscat (j )
x =grp2idx (X (:,j )); 
X (:,j )=x ; 
ncats (j )=max (x ); 
end
end
isord =false (1 ,P ); 
end
ncats (isord )=ncats (isord )-1 ; 
ncatcols =sum (ncats ); 

Xout =zeros (N ,ncatcols ,'like' ,X ); 

done =0 ; 
catcols =false (1 ,ncatcols ); 
forj =1 :size (X ,2 ); 
ifiscat (j )

ncols =ncats (j ); 

x =X (:,j ); 
ifisord (j )

dbl =double (x ); 
ok =x >0 ; 
dbl =dbl (ok ,:); 
D =NaN (N ,ncols ,'like' ,X ); 
DSubset =ones (sum (ok ),ncols ); 
fork =1 :ncols 
DSubset (dbl <=k ,k )=-1 ; 
end
D (ok ,:)=DSubset ; 
elseif~dovrange ||isempty (x )||(min (x )>0 &&~any (isnan (x )))

D =zeros (N ,ncols ,'like' ,X ); 
D (sub2ind ([N ,ncols ],(1 :N )' ,x ))=1 ; 
else


ok =x >0 ; 
nok =sum (ok ); 
D =zeros (N ,ncols ,'like' ,X ); 
DSubset =zeros (nok ,ncols ,'like' ,X ); 
DSubset (sub2ind ([nok ,ncols ],(1 :nok )' ,x (ok ,:)))=1 ; 
D (ok ,:)=DSubset ; 
D (~ok ,:)=NaN ; 
end

Xout (:,done +1 :done +ncols )=D ; 
catcols (done +1 :done +ncols )=true ; 
else

Xout (:,done +1 )=X (:,j ); 
ncols =1 ; 
end

done =done +ncols ; 
end
end
