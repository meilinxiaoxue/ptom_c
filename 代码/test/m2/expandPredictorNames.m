function n =expandPredictorNames (pnames ,vrange )












if~isempty (vrange )
ncats =max (1 ,cellfun (@numel ,vrange )); 
else
ncats =1 ; 
end

ifall (ncats <=1 )

n =pnames ; 
else
n =cell (1 ,sum (ncats )); 
done =0 ; 
forj =1 :length (ncats )
pnj =pnames {j }; 
vrj =vrange {j }; 
ifisnumeric (vrj )||islogical (vrj )
vrj =strtrim (cellstr (num2str (vrj (:)))); 
elseifiscategorical (vrj )
isord =isordinal (vrj ); 
vrj =categories (vrj ); 
ifisord 
vrj =vrj (2 :end); 
end
end

ifncats (j )==1 

n {done +1 }=pnj ; 
else

fork =1 :length (vrj )
n {done +k }=sprintf ('%s_%s' ,pnj ,vrj {k }); 
end
end
done =done +length (vrj ); 
end
iflength (n )>done 
n =n (1 :done ); 
end
end
end
