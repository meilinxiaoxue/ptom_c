function D2 =calcDistanceARD (XN ,XM ,usepdist ,makepos ,r )



























ifnargin <4 

makepos =true ; 
end


ifnargin <5 

[N ,d ]=size (XN ); 
M =size (XM ,1 ); 
D2 =zeros (N ,M ,d ); 

forr =1 :d 
D2 (:,:,r )=classreg .learning .gputils .calcDistance (XN (:,r ),XM (:,r ),usepdist ,makepos ); 
end
else

D2 =classreg .learning .gputils .calcDistance (XN (:,r ),XM (:,r ),usepdist ,makepos ); 
end
end