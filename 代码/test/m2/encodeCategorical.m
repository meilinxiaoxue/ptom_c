function X =encodeCategorical (X ,vrange )







forj =1 :size (X ,2 )
if~isempty (vrange {j })
[~,x ]=ismember (X (:,j ),vrange {j }); 
x (x ==0 )=NaN ; 
X (:,j )=x ; 
end
end