function e =mincost (C ,Sfit ,W ,cost )





ifisempty (cost )
K =size (C ,2 ); 
cost =ones (K )-eye (K ); 
end


if~any (cost (:))
e =0 ; 
return ; 
end


expcost =Sfit *cost ; 


notNaN =~all (isnan (expcost ),2 ); 
[~,y ]=max (C (notNaN ,:),[],2 ); 
[~,yfit ]=min (expcost (notNaN ,:),[],2 ); 
W =W (notNaN ,:); 


e =sum (cost (sub2ind (size (cost ),y ,yfit )).*W )/sum (W ); 

end
