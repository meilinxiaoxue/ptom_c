function Beta =ADMMimpl (X ,Y ,W ,Beta ,rho ,lambda ,doridge ,...
    chunkMap ,Wk ,maxChunkSize ,hfixedchunkfun ,...
    betaTol ,gradTol ,admmIterations ,tallPassLimit ,progressF ,verbose ,...
    lossfun_ADMMLBFGS ,betaTol_ADMMLBFGS ,gradTol_ADMMLBFGS ,...
    iterationlimit_ADMMLBFGS ,doridge_ADMMLBFGS ,...
    hessianHistorySize_ADMMLBFGS ,dowolfe_ADMMLBFGS ,doBias_ADMMLBFGS ,...
    FM ,expType ,sigma )

ifnargin <26 
expType ='none' ; 
FM =[]; 
sigma =[]; 
end



dbeta_mag =Inf ; 
g_mag =Inf ; 
iter =0 ; 
N_chunks =double (chunkMap .Count ); 

UK =zeros (N_chunks ,numel (Beta )); 




objgraF_ =progressF .LazyObjGraFunctor ; 

ifadmmIterations <=1 
progressF .Solver ='INIT' ; 
else
progressF .Solver ='ADMM' ; 
end


doClass =0 ; 
if~iscell (lossfun_ADMMLBFGS )
ifany (strcmp (lossfun_ADMMLBFGS ,{'hinge' ,'logit' }))
doClass =2 ; 
end
end



whiletrue 


ifdbeta_mag <=betaTol ||g_mag <=gradTol ||iter >=admmIterations ||progressF .DataPass >=tallPassLimit 
break
end

iter =iter +1 ; 

[~,gra_ ]=objgraF_ (Beta ); 



[chunkIDs ,temp1 ,temp2 ]=hfixedchunkfun (@(info ,x ,y ,w )...
    chunkBetaUpdateFun (info ,x ,y ,w ,lossfun_ADMMLBFGS ,Beta ,...
    chunkMap ,UK ,rho *(iter >1 ),...
    betaTol_ADMMLBFGS ,gradTol_ADMMLBFGS ,iterationlimit_ADMMLBFGS (min (iter ,2 )),...
    max (0 ,verbose -1 ),...
    doridge_ADMMLBFGS ,...
    hessianHistorySize_ADMMLBFGS ,dowolfe_ADMMLBFGS ,doBias_ADMMLBFGS ,...
    FM ,expType ,sigma ,doClass ),...
    maxChunkSize ,{[],[],[],[]},X ,Y ,W ); 

[chunkIDs ,temp1 ,temp2 ,gra ]=gather (chunkIDs ,temp1 ,temp2 ,gra_ ); 


BetaK (cellfun (@(x )chunkMap (x ),chunkIDs ),:)=[temp2 ,temp1 ]; 



Beta_old =Beta ; 
progressF .Beta =Beta ; 

Beta =(Wk ' *(BetaK +UK ))' ; 

ifdoridge 
ifiter >1 

Beta (2 :end)=Beta (2 :end)./(1 +lambda ./rho ./N_chunks ); 
end
else
error (message ('stats:tall:fitclinear:LassoNotSuported' ))
end


RK =BetaK -Beta ' ; 
UK =UK +RK ; 


g_mag =sqrt (sum (gra .^2 )); 
RK_squared_mag =sum (RK .^2 ,2 ); 
r_mag =sqrt (sum (RK_squared_mag )); 
s_mag =sqrt (sum ((rho .*(Beta -Beta_old )).^2 )); 
beta_mag =sqrt (Beta ' *Beta ); 
dbeta_mag =sqrt (sum ((Beta -Beta_old ).^2 ))/beta_mag ; 
progressF .Solver ='ADMM' ; 
progressF .IterationNumber =iter ; 
progressF .PrimalResidual =r_mag ; 
progressF .DualResidual =s_mag ; 
end

end

function [hasFinished ,id ,betad ,biasd ]=chunkBetaUpdateFun (...
    info ,x ,y ,w ,lossfun ,Beta ,...
    chunkMap ,UK ,rho ,...
    betaTol ,gradTol ,iterationlimit ,...
    verbose ,doridge ,...
    historysize ,dowolfe ,fitbias ,...
    FM ,expType ,sigma ,doClass )

hasFinished =info .IsLastChunk ; 
id ={sprintf ('P%dC%d' ,info .PartitionId ,info .FixedSizeChunkID )}; 

ifisempty (x )

Beta (:)=0 ; 
biasd =Beta (1 ); 
betad =Beta (2 :end)' ; 
return ; 
end

k =chunkMap (id {1 }); 
U =UK (k ,:)' ; 




ifdowolfe 
lineSearchType ='weakwolfe' ; 
else
lineSearchType ='backtrack' ; 
end


ifiscell (lossfun )
epsilon =lossfun {2 }; 
lossfun =lossfun {1 }; 
else
epsilon =[]; 
end


ifstrcmpi (expType ,'none' )
xm =x ; 
else
xm =map (FM ,x ,sigma ); 
end

obj .Impl =classreg .learning .impl .LinearImpl .make (doClass ,...
    Beta (2 :end)-U (2 :end),Beta (1 )-U (1 ),...
    xm ' ,y ,w ./sum (w ),...
    lossfun ,...
    doridge ,...
    0 ,...
    [],...
    [],...
    [],...
    [],...
    [],...
    {'lbfgs' },...
    betaTol ,...
    gradTol ,...
    1e-6 ,...
    [],...
    [],...
    [],[],[],...
    iterationlimit ,...
    [],...
    fitbias ,...
    false ,...
    epsilon ,...
    historysize ,...
    lineSearchType ,...
    rho ,...
    [],...
    verbose ); 

biasd =obj .Impl .Bias ; 
betad =obj .Impl .Beta (:)' ; 



end
