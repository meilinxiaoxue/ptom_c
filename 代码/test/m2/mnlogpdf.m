function y =mnlogpdf (x ,p )




















narginchk (2 ,2 ); 




ifsize (p ,2 )==1 &&size (p ,1 )>1 &&abs (sum (p ,1 )-1 )<=size (p ,1 )*eps (class (p ))
p =p ' ; 
ifsize (x ,2 )==1 &&size (x ,1 )>1 
x =x ' ; 
end
end

[m ,k ]=size (x ); 
ifk <1 
error (message ('stats:mnpdf:NoCategories' )); 
end
n =sum (x ,2 ); 

[mm ,kk ]=size (p ); 
ifkk ~=k 
error (message ('stats:mnpdf:ColSizeMismatch' )); 
elseifmm ==1 
p =repmat (p ,m ,1 ); 
elseifm ==1 
m =mm ; 
x =repmat (x ,m ,1 ); 
n =repmat (n ,m ,1 ); 
elseifmm ~=m 
error (message ('stats:mnpdf:RowSizeMismatch' )); 
end

outClass =superiorfloat (n ,p ); 

xBad =any (x <0 |x ~=round (x ),2 ); 
pBad =any (p <0 |1 <p ,2 )|abs (sum (p ,2 )-1 )>size (p ,2 )*eps (class (p )); 
nBad =n <0 |round (n )~=n ; 

xPos =(x >0 ); 
xlogp =zeros (m ,k ,outClass ); 
xlogp (xPos )=x (xPos ).*log (p (xPos )); 
xlogp =sum (xlogp ,2 ); 


y =-Inf (m ,1 ,outClass ); 

t =~(xBad |pBad |nBad ); 
y (t )=gammaln (n (t ,:)+1 )-sum (gammaln (x (t ,:)+1 ),2 )+xlogp (t ,:); 


y (pBad |nBad )=NaN ; 
end