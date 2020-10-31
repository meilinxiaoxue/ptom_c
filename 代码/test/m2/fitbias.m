function bias =fitbias (lossfun ,y ,F ,w ,epsilon )





















ifnargin <5 
epsilon =[]; 
end

L =size (F ,2 ); 

bias =NaN (1 ,L ,'like' ,y ); 

w =w /sum (w ); 

switchlossfun 
case 'logit' 
yset =[-1 ,1 ]; 
case 'hinge' 
yset =[-1 ,1 ]; 
case 'mse' 
bias =w ' *bsxfun (@minus ,y ,F ); 
return ; 
case 'epsiloninsensitive' 
ifisempty (epsilon )
error (message ('stats:classreg:learning:linearutils:EpsilonNotSpecified' )); 
end

D =bsxfun (@minus ,y ,F ); 

fori =1 :L 
d =D (:,i ); 
[d ,idx ]=sort (d ); 
havenoloss =abs (d )<=epsilon ; 
d (havenoloss )=[]; 
idx (havenoloss )=[]; 
ifisempty (idx )
bias (i )=0 ; 
continue ; 
end

W =cumsum (w (idx )); 
W =W ./W (end); 
iAbove05 =find (W >0.5 ,1 ); 
ifisempty (iAbove05 )
bias (i )=NaN ; 
elseifiAbove05 ==1 
bias (i )=d (iAbove05 ); 
elseifW (iAbove05 -1 )==0.5 
bias (i )=d (iAbove05 -1 ); 
else
bias (i )=(d (iAbove05 )+d (iAbove05 -1 ))/2 ; 
end
end

return ; 
otherwise
error (message ('stats:classreg:learning:linearutils:BadLossFunctionName' ,lossfun )); 
end

smin =min (F (y ==yset (2 ),:)); 
smax =max (F (y ==yset (1 ),:)); 

fori =1 :L 

ifsmin (i )>=smax (i )
bias (i )=-(smin (i )+smax (i ))/2 ; 
continue ; 
end


f =F (:,i ); 
idx =f >=smin (i )&f <=smax (i ); 

[accu ,~,thre ]=perfcurve (y (idx ),f (idx ),1 ,'xcrit' ,'accu' ,'weights' ,w (idx )); 

[~,imax ]=max (accu ); 
bias (i )=-thre (imax ); 
end

end
