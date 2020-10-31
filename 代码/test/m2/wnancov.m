function C =wnancov (X ,w ,biased )













ifnargin <3 
biased =false ; 
end

nanrows =any (isnan (X ),2 )|isnan (w ); 
ifany (nanrows )
X =X (~nanrows ,:); 
w =w (~nanrows ); 
end
C =classreg .learning .internal .wcov (X ,w ,biased ); 
end

