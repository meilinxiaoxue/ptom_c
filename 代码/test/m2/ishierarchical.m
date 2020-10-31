function [isHier ,missing ]=ishierarchical (terms ,isCat )




isHier =true ; 


termorder =sum (terms ,2 ); 
missing =zeros (0 ,size (terms ,2 )); 
ifall (termorder <=1 )

if~any (termorder ==0 )
ifany (isCat (any (terms >0 ,1 )))
isHier =false ; 
end
missing =zeros (1 ,size (terms ,2 )); 
end
else
forj =1 :size (terms ,2 )
ifany (terms (:,j ))

notj =terms (terms (:,j )>0 ,:); 
notj (:,j )=0 ; 
notj =setdiff (notj ,terms ,'rows' ); 
if~isempty (notj )

missing =union (missing ,notj ,'rows' ); 


ifisCat (j )
isHier =false ; 
end
end
end
end
end