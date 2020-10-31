function loss =binodeviance (C ,Sfit ,W ,cost )





[~,y ]=max (C ,[],2 ); 
[N ,K ]=size (C ); 
Sfit =Sfit (sub2ind ([N ,K ],(1 :N )' ,y )); 
notNaN =~isnan (Sfit ); 
loss =sum (W (notNaN ).*log (1 +exp (-2 *Sfit (notNaN ))))/sum (W (notNaN )); 
end
