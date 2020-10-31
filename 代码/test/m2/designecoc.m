function M =designecoc (K ,dname ,varargin )








































ifnargin >1 
dname =convertStringsToChars (dname ); 
end

ifnargin >2 
[varargin {:}]=convertStringsToChars (varargin {:}); 
end

if~isnumeric (K )||~isscalar (K )||round (K )~=K ||K <1 
error (message ('stats:designecoc:BadK' )); 
end

ifK ==1 
M =1 ; 
return ; 
end

ifK ==2 
M =[-1 ,1 ]' ; 
return ; 
end

allowedVals ={'onevsone' ,'allpairs' ,'onevsall' ,'binarycomplete' ,'ternarycomplete' ...
    ,'ordinal' ,'sparserandom' ,'denserandom' }; 

tf =strncmpi (dname ,allowedVals ,length (dname )); 
Nfound =sum (tf ); 
ifNfound ~=1 
error (message ('stats:designecoc:BadDesignName' ,sprintf (' ''%s''' ,allowedVals {:}))); 
end
dname =allowedVals {tf }; 
ifstrcmp (dname ,'allpairs' )
dname ='onevsone' ; 
end

tf =ismember ({'onevsone' ,'onevsall' ,'binarycomplete' ,'ternarycomplete' ...
    ,'ordinal' ,'sparserandom' ,'denserandom' },dname ); 

args ={'numtrials' }; 
defs ={1e4 }; 
N =internal .stats .parseArgs (args ,defs ,varargin {:}); 

if~isscalar (N )||~isnumeric (N )||N <1 ||N ~=round (N )
error (message ('stats:designecoc:BadNumTrials' )); 
end

iftf (1 )
L =K *(K -1 )/2 ; 
M =zeros (K ,L ); 

l =1 ; 
t =1 ; 
r =K -1 ; 
b =K ; 

fork =1 :K -1 
M (t ,l :r )=+1 ; 
M (t +1 :b ,l :r )=-eye (b -t ); 

l =r +1 ; 
t =t +1 ; 
r =r +K -k -1 ; 
b =t +K -k -1 ; 
end

elseiftf (2 )
M =-ones (K ); 
M (1 :K +1 :end)=+1 ; 

elseiftf (3 )
M =ff2n (K -1 ); 
M (1 ,:)=[]; 
M =[zeros (size (M ,1 ),1 ),M ]; 
M (M ==0 )=-1 ; 
M =-M ' ; 

elseiftf (4 )
M =fullfact (repmat (3 ,1 ,K ))' ; 
M (M ==1 )=-1 ; 
M (M ==2 )=0 ; 
M (M ==3 )=1 ; 
M =clean (M ); 

elseiftf (5 )
M =-ones (K ,K -1 ); 
fork =1 :K -1 
M (k +1 :end,k )=1 ; 
end

elseiftf (6 )
ifK <5 
warning (message ('stats:designecoc:NotEnoughClassesForSparseRandom' )); 
end


distfun =@(y ,M )nansum (1 -bsxfun (@times ,M ,y ),2 )/2 ; 

M =[]; 
maxmindist =-Inf ; 


[~,L ]=log2 (K ); 
L =15 *L ; 




forn =1 :N 
Mtry =rand (K ,L ); 
iminus =Mtry <1 /4 ; 
iplus =Mtry >3 /4 ; 
izero =~(iminus |iplus ); 
Mtry (iminus )=-1 ; 
Mtry (iplus )=+1 ; 
Mtry (izero )=NaN ; 


D =pdist (Mtry ,distfun ); 



mindist =min (D ); 
ifmindist >maxmindist 
M =Mtry ; 
maxmindist =mindist ; 
end
end

M (isnan (M ))=0 ; 

M =clean (M ); 

elseiftf (7 )
ifK <6 
warning (message ('stats:designecoc:NotEnoughClassesForDenseRandom' )); 
end


distfun =@(y ,M )sum (1 -bsxfun (@times ,M ,y ),2 )/2 ; 

M =[]; 
maxmindist =-Inf ; 


[~,L ]=log2 (K ); 
L =10 *L ; 




forn =1 :N 
Mtry =rand (K ,L ); 
iminus =Mtry <1 /2 ; 
iplus =Mtry >1 /2 ; 
Mtry (iminus )=-1 ; 
Mtry (iplus )=+1 ; 


D =pdist (Mtry ,distfun ); 



mindist =min (D ); 
ifmindist >maxmindist 
M =Mtry ; 
maxmindist =mindist ; 
end
end

M =clean (M ); 

end

end


function M =clean (M )

L =size (M ,2 ); 

badcols =false (1 ,L ); 
fori =1 :L 
if~any (M (:,i )==1 )||~any (M (:,i )==-1 )
badcols (i )=true ; 
continue ; 
end

forj =i +1 :L 
ifall (M (:,i )==M (:,j ))||all (M (:,i )==-M (:,j ))
badcols (i )=true ; 
break; 
end
end
end

M (:,badcols )=[]; 
end

