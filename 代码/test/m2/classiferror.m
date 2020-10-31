function e =classiferror (C ,Sfit ,W ,~)




ifsize (C ,2 )==1 
e =0 ; 
return ; 
end


notNaN =~all (isnan (Sfit ),2 ); 
[~,y ]=max (C (notNaN ,:),[],2 ); 
[~,yfit ]=max (Sfit (notNaN ,:),[],2 ); 
W =W (notNaN ,:); 
e =sum ((y ~=yfit ).*W )/sum (W ); 
end
