function objFcn =createObjFcn (BOInfo ,FitFunctionArgs ,Predictors ,Response ,...
    ValidationMethod ,ValidationVal ,Repartition ,Verbose )









if~Repartition &&~isa (ValidationVal ,'cvpartition' )
[~,PrunedY ]=BOInfo .PrepareDataFcn (Predictors ,Response ,FitFunctionArgs {:},'IgnoreExtraParameters' ,true ); 
ifBOInfo .IsRegression 
cvp =cvpartition (numel (PrunedY ),ValidationMethod ,ValidationVal ); 
else
cvp =cvpartition (PrunedY ,ValidationMethod ,ValidationVal ); 
end
ValidationMethod ='CVPartition' ; 
ValidationVal =cvp ; 
end

objFcn =@theObjFcn ; 

function Objective =theObjFcn (XTable )

NewFitFunctionArgs =updateArgsFromTable (BOInfo ,FitFunctionArgs ,XTable ); 

C =classreg .learning .paramoptim .suppressWarnings (); 
PartitionedModel =BOInfo .FitFcn (Predictors ,Response ,ValidationMethod ,ValidationVal ,NewFitFunctionArgs {:}); 

ifPartitionedModel .KFold ==0 
Objective =NaN ; 
ifVerbose >=2 
classreg .learning .paramoptim .printInfo ('ZeroFolds' ); 
end
else
ifBOInfo .IsRegression 
Objective =log1p (kfoldLoss (PartitionedModel )); 
else
Objective =kfoldLoss (PartitionedModel ); 
end
if~isscalar (Objective )

Objective =Objective (1 ); 
ifVerbose >=2 
classreg .learning .paramoptim .printInfo ('ObjArray' ); 
end
end
end
end
end