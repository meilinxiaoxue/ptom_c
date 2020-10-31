function [h ,p ,loss1 ,loss2 ]=testckfold (c1 ,c2 ,X1 ,X2 ,varargin )

























































































































































































ifnargin >4 
[varargin {:}]=convertStringsToChars (varargin {:}); 
end

full1 =[]; 
ifisa (c1 ,'classreg.learning.FitTemplate' )
c1 =fillIfNeeded (c1 ,'classification' ); 
elseifisa (c1 ,'classreg.learning.classif.FullClassificationModel' )
full1 =c1 ; 
c1 =classreg .learning .FitTemplate .makeFromModelParams (c1 .ModelParameters ); 
else
error (message ('stats:testckfold:BadClassifierObjectType' ,'C1' )); 
end


full2 =[]; 
ifisa (c2 ,'classreg.learning.FitTemplate' )
c2 =fillIfNeeded (c2 ,'classification' ); 
elseifisa (c2 ,'classreg.learning.classif.FullClassificationModel' )
full2 =c2 ; 
c2 =classreg .learning .FitTemplate .makeFromModelParams (c2 .ModelParameters ); 
else
error (message ('stats:testckfold:BadClassifierObjectType' ,'C2' )); 
end


ntable =sum (istable (X1 )+istable (X2 )); 
ifntable ==1 
error (message ('stats:testckfold:IncompatibleXTypes' )); 
end
dotable =ntable >0 ; 





if~dotable 
if~isempty (full1 )
if~isempty (full1 .CategoricalPredictors )
warning (message ('stats:testckfold:CatPredsInFirstClassifier' )); 
end
end
if~isempty (full2 )
if~isempty (full2 .CategoricalPredictors )
warning (message ('stats:testckfold:CatPredsInSecondClassifier' )); 
end
end
end

yname ='' ; 
argsin =varargin ; 

ifdotable &&~isempty (full1 )&&~isempty (full2 )

if~strcmp (full1 .ResponseName ,full2 .ResponseName )
error (message ('stats:classreg:learning:classif:ClassificationModel:compareHoldout:DifferentResponseNames' )); 
end

Y =classreg .learning .internal .inferResponse (full1 .ResponseName ,X1 ,varargin {:}); 
[Y2 ,argsin ]=classreg .learning .internal .inferResponse (full2 .ResponseName ,X2 ,varargin {:}); 

if~isequal (Y ,Y2 )
error (message ('stats:classreg:learning:classif:ClassificationModel:compareHoldout:DifferentResponseValues' )); 
end

yname =full1 .ResponseName ; 

elseifisempty (argsin )
error (message ('MATLAB:minrhs' )); 

else

Y =argsin {1 }; 
argsin (1 )=[]; 
ifinternal .stats .isString (Y )
ifmod (length (argsin ),2 )==1 



error (message ('stats:testckfold:MissingResponse' )); 

elseif~istable (X1 )||~istable (X2 )
error (message ('stats:testckfold:XNotTableForStringY' )); 

else

try
yname =Y ; 
Y =X1 .(yname ); 
Y2 =X2 .(yname ); 
catch me 
error (message ('stats:classreg:learning:internal:utils:InvalidResponse' ,yname )); 
end
if~isequal (Y ,Y2 )
error (message ('stats:classreg:learning:classif:ClassificationModel:compareHoldout:DifferentResponseValues' )); 
end
end
end
end


Y =classreg .learning .internal .ClassLabel (Y ); 
nonzeroClassNames =levels (Y ); 


N1 =size (X1 ,1 ); 
ifnumel (Y )~=N1 
error (message ('stats:testckfold:PredictorMatrixSizeMismatch' ,'X1' )); 
end

N2 =size (X2 ,1 ); 
ifN1 ~=N2 
error (message ('stats:testckfold:PredictorMatrixSizeMismatch' ,'X2' )); 
end


args ={'classnames' ,'alpha' ,'lossfun' ,'alternative' ,'test' ,'verbose' ...
    ,'x1categoricalpredictors' ,'x2categoricalpredictors' ,'prior' ,'cost' ...
    ,'weights' ,'options' }; 
defs ={'' ,0.05 ,'' ,'unequal' ,'5x2F' ,0 ...
    ,[],[],[],[]...
    ,[],[]}; 
[userClassNames ,alpha ,lossfun ,alternative ,mode ,verbose ,cat1 ,cat2 ,prior ,cost ,...
    W ,paropts ,~,extraArgs ]=internal .stats .parseArgs (args ,defs ,argsin {:}); 



cat =internal .stats .parseArgs ({'CategoricalPredictors' },{[]},extraArgs {:}); 
if~isempty (cat )
error (message ('stats:testckfold:CatPredsNotSupported' )); 
end


ifisempty (W )
W =ones (N1 ,1 ); 
end
ifnumel (W )~=N1 
error (message ('stats:testckfold:WeightSizeMismatch' ,N1 )); 
end
W =W (:); 


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
X1 (unmatchedY ,:)=[]; 
X2 (unmatchedY ,:)=[]; 
W (unmatchedY )=[]; 
nonzeroClassNames (missingC )=[]; 
end
end


Call =classreg .learning .internal .classCount (nonzeroClassNames ,Y ); 
WC =bsxfun (@times ,Call ,W ); 
Wj =sum (WC ,1 ); 


prior =classreg .learning .classif .FullClassificationModel .processPrior (...
    prior ,Wj ,userClassNames ,nonzeroClassNames ); 


cost =classreg .learning .classif .FullClassificationModel .processCost (...
    cost ,prior ,userClassNames ,nonzeroClassNames ); 




prior =prior /sum (prior ); 
W =sum (bsxfun (@times ,WC ,prior ./Wj ),2 ); 



ifisempty (lossfun )
lossfun ='classiferror' ; 
end
lossfun =classreg .learning .internal .lossCheck (lossfun ,'classification' ); 

doclasserr =false ; 
ifisequal (lossfun ,@classreg .learning .loss .classiferror )
doclasserr =true ; 
end
if~doclasserr &&~strcmp (c1 .Method ,c2 .Method )
error (message ('stats:testckfold:BadLossFun' )); 
end



ifdoclasserr &&~isempty (cost )
lossfun =@classreg .learning .loss .mincost ; 
end


if~isscalar (alpha )||~isfloat (alpha )||~isreal (alpha )||isnan (alpha )...
    ||alpha <=0 ||alpha >=1 
error (message ('stats:testckfold:BadAlpha' )); 
end


alternative =validatestring (alternative ,{'unequal' ,'less' ,'greater' },...
    'testckfold' ,'Alternative' ); 



mode =validatestring (mode ,{'5x2t' ,'5x2F' ,'10x10t' },'testckfold' ,'Test' ); 

ifstrcmp (mode ,'5x2F' )&&~strcmp (alternative ,'unequal' )
error (message ('stats:testckfold:BadAlternativeTestCombo' )); 
end


if~isscalar (verbose )||~isnumeric (verbose )||~isreal (verbose )...
    ||verbose <0 ||round (verbose )~=verbose 
error (message ('stats:testckfold:BadVerbose' )); 
end


[useParallel ,RNGscheme ]=...
    internal .stats .parallel .processParallelAndStreamOptions (paropts ,true ); 


ifismember (mode ,{'5x2t' ,'5x2F' })
R =5 ; 
K =2 ; 
else
R =10 ; 
K =10 ; 
end



function [l1 ,l2 ]=loopBody (r ,s )
ifisempty (s )
s =RandStream .getGlobalStream ; 
end

ifverbose >0 
fprintf ('%s\n' ,getString (message ('stats:testckfold:ReportRunProgress' ,r ,R ))); 
end

cvp =cvpartition (Y ,'kfold' ,K ,s ); 

l1 =NaN (1 ,K ); 
l2 =NaN (1 ,K ); 


fork =1 :K 
ifverbose >1 
fprintf ('    %s\n' ,getString (message ('stats:testckfold:ReportFoldProgress' ,k ,K ))); 
end


itrain =training (cvp ,k ); 
itest =test (cvp ,k ); 


ifisempty (yname )

m1 =fit (c1 ,X1 (itrain ,:),Y (itrain ),'categoricalpredictors' ,cat1 ,...
    'cost' ,cost ,'weights' ,W (itrain ),extraArgs {:}); 
m2 =fit (c2 ,X2 (itrain ,:),Y (itrain ),'categoricalpredictors' ,cat2 ,...
    'cost' ,cost ,'weights' ,W (itrain ),extraArgs {:}); 
else

m1 =fit (c1 ,X1 (itrain ,:),yname ,'categoricalpredictors' ,cat1 ,...
    'cost' ,cost ,'weights' ,W (itrain ),extraArgs {:}); 
m2 =fit (c2 ,X2 (itrain ,:),yname ,'categoricalpredictors' ,cat2 ,...
    'cost' ,cost ,'weights' ,W (itrain ),extraArgs {:}); 
end


w =W (itest ); 
y =Y (itest ); 

ifdoclasserr 










Yhat1 =classreg .learning .internal .ClassLabel (predict (m1 ,X1 (itest ,:))); 
Yhat2 =classreg .learning .internal .ClassLabel (predict (m2 ,X2 (itest ,:))); 



C =classreg .learning .internal .classCount (nonzeroClassNames ,y ); 





C1 =classreg .learning .internal .classCount (nonzeroClassNames ,Yhat1 ); 
C2 =classreg .learning .internal .classCount (nonzeroClassNames ,Yhat2 ); 


l1 (k )=lossfun (C ,C1 ,w ,cost ); 
l2 (k )=lossfun (C ,C2 ,w ,cost ); 
else




l1 (k )=loss (m1 ,X1 (itest ,:),y ,'lossfun' ,lossfun ,'weights' ,w ); 
l2 (k )=loss (m2 ,X2 (itest ,:),y ,'lossfun' ,lossfun ,'weights' ,w ); 
end
end
end


[loss1 ,loss2 ]=...
    internal .stats .parallel .smartForSliceout (R ,@loopBody ,useParallel ,RNGscheme ); 





delta =loss1 -loss2 ; 


ifall (abs (delta (:))<100 *eps (loss1 (:)+loss2 (:)))
p =1 ; 
h =false ; 
return ; 
end





switchmode 
case '5x2t' 
mdelta_r =mean (delta ,2 ); 
s2_r =sum (bsxfun (@minus ,delta ,mdelta_r ).^2 ,2 ); 
s2 =sum (s2_r ); 
t =delta (1 ,1 )/sqrt (s2 /5 ); 

switchalternative 
case 'unequal' 
p =2 *tcdf (-abs (t ),5 ); 
case 'less' 

p =tcdf (t ,5 ,'upper' ); 
case 'greater' 

p =tcdf (t ,5 ); 
end

case '5x2F' 
mdelta_r =mean (delta ,2 ); 
s2_r =sum (bsxfun (@minus ,delta ,mdelta_r ).^2 ,2 ); 
s2 =sum (s2_r ); 
F =sum (delta (:).^2 )/(2 *s2 ); 

p =fcdf (F ,10 ,5 ,'upper' ); 

case '10x10t' 
m =mean (delta (:)); 
s2 =var (delta (:)); 
t =m /sqrt (s2 /(K +1 )); 

p =tcdf (t ,K ); 

switchalternative 
case 'unequal' 
p =2 *tcdf (-abs (t ),K ); 
case 'less' 

p =tcdf (t ,K ,'upper' ); 
case 'greater' 

p =tcdf (t ,K ); 
end
end

h =p <alpha ; 

end
