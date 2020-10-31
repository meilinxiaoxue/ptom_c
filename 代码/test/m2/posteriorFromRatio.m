function Phat =posteriorFromRatio (M ,R ,W ,verbose ,doquadprog ,T ,useParallel ,RNGscheme )























ifnargin <3 
W =ones (1 ,size (R ,2 )); 
end

ifnargin <4 
verbose =0 ; 
end

ifnargin <5 
doquadprog =false ; 
end

ifdoquadprog &&isempty (ver ('Optim' ))
error (message ('stats:classreg:learning:classif:CompactClassificationECOC:posteriorFromRatio:NeedOptim' )); 
end

K =size (M ,1 ); 
N =size (R ,1 ); 

Mminus =M ; 
Mminus (M ~=-1 )=0 ; 
Mplus =M ; 
Mplus (M ~=+1 )=0 ; 

ifverbose >0 
fprintf ('%s\n' ,getString (message ('stats:classreg:learning:classif:CompactClassificationECOC:posteriorFromRatio:ComputingPosteriorProbs' ))); 
end

function p =loopBodyQP (n ,~)
p =NaN (1 ,K ); 

r =R (n ,:); 

igood =~isnan (r ); 
if~any (igood )
return ; 
end

Q =bsxfun (@times ,Mminus (:,igood ),r (igood ))+...
    bsxfun (@times ,Mplus (:,igood ),1 -r (igood )); 
H =Q *Q ' ; 
[p ,~,exitflag ]=quadprog (H ,zeros (K ,1 ),[],[],ones (1 ,K ),1 ,zeros (K ,1 ),ones (K ,1 ),[],opts ); 

ifexitflag ~=1 
warning (message ('stats:classreg:learning:classif:CompactClassificationECOC:posteriorFromRatio:QuadprogFails' ,n )); 
end

p =p ' ; 
end


function p =loopBodyKL (n ,s )
ifisempty (s )
s =RandStream .getGlobalStream ; 
end

p =NaN (1 ,K ); 

r =R (n ,:); 

igood =~isnan (r ); 
if~any (igood )
return ; 
end

phat =zeros (T +2 ,K ); 
dist =zeros (T +2 ,1 ); 
p0 =rand (s ,T ,K ); 
p0 =bsxfun (@rdivide ,p0 ,sum (p0 ,2 )); 


fort =1 :T 
[phat (t ,:),dist (t )]=...
    minimizeKL (r (igood ),Mminus (:,igood ),Mplus (:,igood ),W (igood ),p0 (t ,:)' ); 
end


[phat (T +1 ,:),dist (T +1 )]=...
    minimizeKL (r (igood ),Mminus (:,igood ),Mplus (:,igood ),W (igood ),repmat (1 /K ,K ,1 )); 


[phat (T +2 ,:),dist (T +2 )]=...
    minimizeKL (r (igood ),Mminus (:,igood ),Mplus (:,igood ),W (igood )); 


[~,tmin ]=min (dist ); 
p =phat (tmin ,:); 
end

ifdoquadprog 
opts =optimoptions (@quadprog ,...
    'Algorithm' ,'interior-point-convex' ,'Display' ,'off' ); 

Phat =internal .stats .parallel .smartForSliceout (N ,@loopBodyQP ,useParallel ); 

else

Phat =internal .stats .parallel .smartForSliceout (N ,@loopBodyKL ,useParallel ,RNGscheme ); 

end

end


function [p ,dist ]=minimizeKL (r ,Mminus ,Mplus ,W ,p0 )

ifnargin <5 
K =size (Mminus ,1 ); 

M =Mminus +Mplus ; 
M (M ==-1 )=0 ; 
p =lsqnonneg (M ' ,r ' ); 

doquit =false ; 
ifall (p ==0 )
p =repmat (1 /K ,K ,1 ); 
doquit =true ; 
elseifsum (p >0 )==1 
p (p >0 )=1 ; 
doquit =true ; 
end

ifdoquit 
rhat =sum (bsxfun (@times ,Mplus ,p )); 
rhat =rhat ./(rhat -sum (bsxfun (@times ,Mminus ,p ))); 
dist =KLdistance (r ,rhat ,W ); 
return ; 
end

p =max (p ,100 *eps ); 
p =p /sum (p ); 
p (p >1 )=1 ; 
else
p =p0 ; 
end

rhat =sum (bsxfun (@times ,Mplus ,p )); 
rhat =rhat ./(rhat -sum (bsxfun (@times ,Mminus ,p ))); 

dist =KLdistance (r ,rhat ,W ); 

delta =Inf ; 

iter =1 ; 

whiledelta >1e-6 &&iter <=1000 
iter =iter +1 ; 

numer =sum (bsxfun (@times ,Mplus ,W .*r )-bsxfun (@times ,Mminus ,W .*(1 -r )),2 ); 
denom =sum (bsxfun (@times ,Mplus ,W .*rhat )-bsxfun (@times ,Mminus ,W .*(1 -rhat )),2 ); 

i =denom <=0 &numer >0 ; 
ifany (i )
p (i )=1 ; 
p (~i )=0 ; 
else
j =denom >0 ; 
p (j )=p (j ).*numer (j )./denom (j ); 
p (~j )=0 ; 
end

p =max (p ,100 *eps ); 
p =p /sum (p ); 

rhat =sum (bsxfun (@times ,Mplus ,p )); 
rhat =rhat ./(rhat -sum (bsxfun (@times ,Mminus ,p ))); 

distnew =KLdistance (r ,rhat ,W ); 

delta =dist -distnew ; 

dist =distnew ; 
end

end


function dist =KLdistance (r ,rhat ,w )

i =r >100 *eps ; 
dist =sum (w (i ).*r (i ).*log (r (i )./rhat (i ))); 

i =1 -r >100 *eps ; 
dist =dist +sum (w (i ).*(1 -r (i )).*log ((1 -r (i ))./(1 -rhat (i )))); 

end
