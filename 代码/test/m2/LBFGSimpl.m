function Beta =LBFGSimpl (Beta ,progressF ,verbose ,...
    betaTol ,gradTol ,iterationlimit ,tallPassLimit ,...
    hessianHistorySize ,lineSearch ,initialStepSize )


ifany (isinf (Beta ))
return ; 
end
ifany (isnan (Beta ))
return ; 
end

ifiterationlimit >0 &&progressF .DataPass <tallPassLimit 


objgraF =progressF .NonLazyObjGraFunctor ; 


outputF =makeOutputFun (progressF ,betaTol ,gradTol ,iterationlimit ,tallPassLimit ); 


options .TolFun =eps ; 
options .TolX =eps ; 
options .MaxIter =inf ; 
options .GradObj ='on' ; 
ifverbose >1 
options .Display ='iter' ; 
else
options .Display ='off' ; 
end

LBFGSparams ={'Options' ,options ,'Memory' ,hessianHistorySize ,...
    'LineSearch' ,lineSearch ,'MaxLineSearchIter' ,100 ,'OutputFcn' ,outputF }; 

ifisempty (initialStepSize )
LBFGSparams (end+1 :end+2 )={'Gamma' ,1 }; 
else
LBFGSparams (end+1 :end+2 )={'Step' ,initialStepSize }; 
end


[Beta ,~,~,~]=classreg .learning .fsutils .fminlbfgs (objgraF ,Beta ,LBFGSparams {:}); 

end

end

function outF =makeOutputFun (progressF ,betaTol ,gradTol ,iterationlimit ,tallPassLimit )
progressF .IterationNumber =0 ; 
progressF .Solver ='LBFGS' ; 
progressF .PrimalResidual =NaN ; 
progressF .DualResidual =NaN ; 
outF =@fcn ; 
function stop =fcn (Beta ,optimValues ,b )
progressF .Beta =Beta ; 
progressF .IterationNumber =optimValues .iteration +1 ; 

stop =isinf (progressF .ObjectiveValue )||isnan (progressF .ObjectiveValue )||progressF .RelativeChangeBeta <=betaTol ||progressF .GradientMagnitude <=gradTol ||progressF .IterationNumber >iterationlimit ||progressF .DataPass >=tallPassLimit ; 
end
end