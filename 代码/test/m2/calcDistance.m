function D2 =calcDistance (XN ,XM ,usepdist ,makeposIn )%#codegen 
























coder .inline ('always' ); 


ifnargin <4 

makepos =true ; 
else
makepos =makeposIn ; 
end


ifusepdist 


D2 =(pdist2 (XN ,XM ,'squaredeuclidean' )); 
else
D2 =bsxfun (@plus ,bsxfun (@plus ,sum (XN .^2 ,2 ),-2 *XN *XM ' ),sum (XM .^2 ,2 )' ); 
ifmakepos 
D2 =max (0 ,D2 ); 
end
end
end