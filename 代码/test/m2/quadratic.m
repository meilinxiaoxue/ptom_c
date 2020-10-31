function loss =quadratic (C ,Sfit ,W ,~)



[~,y ]=max (C ,[],2 ); 
[N ,K ]=size (C ); 
Sfit =Sfit (sub2ind ([N ,K ],(1 :N )' ,y )); 
notNaN =~isnan (Sfit ); 
loss =sum (W (notNaN ).*(1 -Sfit (notNaN )).^2 )/sum (W (notNaN )); 

end
