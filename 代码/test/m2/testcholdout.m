function [h ,p ,err1 ,err2 ]=testcholdout (Yhat1 ,Yhat2 ,Y ,varargin )















































































































ifnargin >0 
Yhat1 =convertStringsToChars (Yhat1 ); 
end

ifnargin >1 
Yhat2 =convertStringsToChars (Yhat2 ); 
end

ifnargin >2 
Y =convertStringsToChars (Y ); 
end

ifnargin >3 
[varargin {:}]=convertStringsToChars (varargin {:}); 
end

Y =classreg .learning .internal .ClassLabel (Y ); 
Y1 =classreg .learning .internal .ClassLabel (Yhat1 ); 
Y2 =classreg .learning .internal .ClassLabel (Yhat2 ); 
nonzeroClassNames =levels (Y ); 


N1 =numel (Y1 ); 
ifnumel (Y )~=N1 
error (message ('stats:testcholdout:ClassLabelSizeMismatch' ,'Yhat1' )); 
end

N2 =numel (Y2 ); 
ifN1 ~=N2 
error (message ('stats:testcholdout:ClassLabelSizeMismatch' ,'Yhat2' )); 
end


args ={'alpha' ,'alternative' ,'test' ,'classnames' ,'cost' ,'costtest' }; 
defs ={0.05 ,'unequal' ,'' ,'' ,[],'likelihood' }; 

[alpha ,alternative ,mode ,userClassNames ,cost ,costtest ]=...
    internal .stats .parseArgs (args ,defs ,varargin {:}); 


if~isscalar (alpha )||~isfloat (alpha )||~isreal (alpha )||isnan (alpha )...
    ||alpha <=0 ||alpha >=1 
error (message ('stats:testcholdout:BadAlpha' )); 
end


fitcost =false ; 
if~isempty (cost )
fitcost =true ; 
end


alternative =validatestring (alternative ,{'unequal' ,'less' ,'greater' },...
    'testcholdout' ,'Alternative' ); 



ifisempty (mode )
iffitcost 
mode ='asymptotic' ; 
else
mode ='midp' ; 
end
end

mode =validatestring (mode ,{'asymptotic' ,'exact' ,'midp' },...
    'testcholdout' ,'Test' ); 

if~(strcmp (mode ,'asymptotic' )&&strcmp (alternative ,'unequal' ))&&fitcost 
error (message ('stats:testcholdout:BadCostAlternativeTestCombo' )); 
end


costtest =validatestring (costtest ,{'likelihood' ,'chisquare' },...
    'testcholdout' ,'CostTest' ); 


t =ismissing (Y ); 
ifall (t )
error (message ('stats:testcholdout:AllObservationsHaveMissingTrueLabels' )); 
end
ifany (t )
Y (t )=[]; 
Y1 (t )=[]; 
Y2 (t )=[]; 
end


ifisempty (userClassNames )


userClassNames =nonzeroClassNames ; 
else
userClassNames =classreg .learning .internal .ClassLabel (userClassNames ); 



missingC =~ismember (userClassNames ,nonzeroClassNames ); 
ifall (missingC )
error (message ('stats:classreg:learning:classif:FullClassificationModel:prepareData:ClassNamesNotFound' )); 
end



missingC =~ismember (nonzeroClassNames ,userClassNames ); 
ifany (missingC )
unmatchedY =ismember (Y ,nonzeroClassNames (missingC )); 
Y (unmatchedY )=[]; 
Y1 (unmatchedY )=[]; 
Y2 (unmatchedY )=[]; 
nonzeroClassNames (missingC )=[]; 
end
end


N =numel (Y ); 
K =numel (nonzeroClassNames ); 

iffitcost 


cost =classreg .learning .classif .FullClassificationModel .processCost (...
    cost ,ones (1 ,K ),userClassNames ,nonzeroClassNames ); 


C =classreg .learning .internal .classCount (nonzeroClassNames ,Y ); 




C1 =false (N ,K ); 
fork =1 :K 
C1 (:,k )=ismember (Y1 ,nonzeroClassNames (k )); 
end

C2 =false (N ,K ); 
fork =1 :K 
C2 (:,k )=ismember (Y2 ,nonzeroClassNames (k )); 
end


err1 =mean (sum ((C *cost ).*C1 ,2 )); 
err2 =mean (sum ((C *cost ).*C2 ,2 )); 


Mobs =zeros (K ,K ,K ); 
fori =1 :K 
forj =1 :K 
fork =1 :K 
Mobs (i ,j ,k )=sum (Y1 ==nonzeroClassNames (i )...
    &Y2 ==nonzeroClassNames (j )&Y ==nonzeroClassNames (k )); 
end
end
end


[~,~,p ]=fitCellCounts (Mobs ,cost ,costtest ); 

else


good1 =Y1 ==Y ; 
good2 =Y2 ==Y ; 


err1 =mean (~good1 ); 
err2 =mean (~good2 ); 


n01 =sum (~good1 &good2 ); 
n10 =sum (good1 &~good2 ); 



ifn01 ==0 &&n10 ==0 
h =false ; 
p =1 ; 
return ; 
end

ifn01 ==n10 &&strcmp (alternative ,'unequal' )
h =false ; 
p =1 ; 
return ; 
end


switchmode 
case 'asymptotic' 
switchalternative 
case 'unequal' 
p =chi2cdf ((n01 -n10 )^2 /(n01 +n10 ),1 ,'upper' ); 
case 'less' 
p =normcdf ((n10 -n01 )/sqrt (n01 +n10 )); 
case 'greater' 
p =normcdf ((n01 -n10 )/sqrt (n01 +n10 )); 
end

case 'exact' 
switchalternative 
case 'unequal' 
p =2 *binocdf (min (n01 ,n10 ),n01 +n10 ,0.5 ); 
case 'less' 
p =binocdf (n10 ,n01 +n10 ,0.5 ); 
case 'greater' 
p =binocdf (n01 ,n01 +n10 ,0.5 ); 
end

case 'midp' 
switchalternative 
case 'unequal' 
p =2 *binocdf (min (n01 ,n10 )-1 ,n01 +n10 ,0.5 )+...
    binopdf (min (n01 ,n10 ),n01 +n10 ,0.5 ); 
case 'less' 

p =binocdf (n10 -1 ,n01 +n10 ,0.5 )+0.5 *binopdf (n10 ,n01 +n10 ,0.5 ); 
case 'greater' 

p =binocdf (n01 -1 ,n01 +n10 ,0.5 )+0.5 *binopdf (n01 ,n01 +n10 ,0.5 ); 
end

end


end


h =p <alpha ; 

end


function [Mhat ,chisqval ,pval ]=fitCellCounts (Mobs ,C ,costtest )










K =size (C ,1 ); 


if~isfloat (Mobs )||(ndims (Mobs )~=3 &&~isscalar (Mobs ))||any (size (Mobs )~=K )...
    ||any (Mobs (:)<0 )||any (round (Mobs (:))~=Mobs (:))
error (message ('stats:testcholdout:BadMatrixOfCellCounts' ,K ,K ,K )); 
end


if~isfloat (C )||~ismatrix (C )||any (size (C )~=K )...
    ||any (C (1 :K +1 :end)~=0 )||any (C (:)<0 )
error (message ('stats:testcholdout:BadCostMatrix' )); 
end


ifall (C (:)==0 )
Mhat =Mobs +1 ; 
chisqval =0 ; 
pval =1 ; 
return ; 
end



cost1 =zeros (K ^3 ,1 ); 
cost2 =zeros (K ^3 ,1 ); 

fork =1 :K 
a1 =repmat (C (k ,:)' ,1 ,K ); 
a2 =repmat (C (k ,:),K ,1 ); 
idx =(k -1 )*K ^2 +1 :k *K ^2 ; 
cost1 (idx )=a1 (:); 
cost2 (idx )=a2 (:); 
end



dcost =cost1 -cost2 ; 


Mobs =Mobs (:); 


Mobs =Mobs +1 ; 






switchcosttest 
case 'likelihood' 

N =sum (Mobs ); 



maxdcost =max (abs (dcost )); 
maxlambda =N /maxdcost ; 
maxlambda =maxlambda *(1 -eps (class (maxlambda ))); 
lims =[-maxlambda ,maxlambda ]; 


f =@(lambda )Mobs ' *(dcost ./(N +lambda *dcost )); 
try
lambda =fzero (f ,lims ); 
catch me 
error (message ('stats:testcholdout:FzeroFails' ,me .message )); 
end


lamdcost =lambda *dcost /N ; 
Mhat =Mobs ./(1 +lamdcost ); 


chisqval =2 *Mobs ' *log1p (lamdcost ); 

case 'chisquare' 


ifisempty (ver ('Optim' ))
error (message ('stats:testcholdout:NeedOptimForChisquareTest' )); 
end


beq =0 ; 


indicator =ones (K ^3 ,1 ); 

fork =1 :K 
ibegin =(k -1 )*K ^2 +1 ; 
iend =k *K ^2 ; 
indicator (ibegin :K +1 :iend )=0 ; 
end

H =diag (sparse (2 *indicator ./Mobs )); 

f =-2 *indicator ; 


opts =optimoptions (@quadprog ,'Display' ,'none' ); 


[Mhat ,~,exitflag ]=quadprog (H ,f ,[],[],dcost ' ,beq ,[],[],[],opts ); 

ifexitflag ~=1 
warning (message ('stats:testcholdout:BadExitFlagFromQuadprog' ,exitflag )); 
end


chisqval =sum (indicator .*(Mhat -Mobs ).^2 ./Mobs ); 
end


Mhat =reshape (Mhat ,K ,K ,K ); 


pval =chi2cdf (chisqval ,1 ,'upper' ); 

end

