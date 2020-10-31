function m =classifmargin (C ,Sfit )










[N ,K ]=size (C ); 

ifK ==1 
m =NaN (N ,1 ); 
return ; 
end

[~,trueC ]=max (C ,[],2 ); 
m =zeros (N ,1 ,'like' ,Sfit ); 
fork =1 :K 
trueK =false (K ,1 ); 
trueK (k )=true ; 
idx =trueC ==k ; 
m (idx )=Sfit (idx ,trueK )-max (Sfit (idx ,~trueK ),[],2 ); 
end
end
