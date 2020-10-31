function obj =optimoptionsFromStruct (s ,objType )









commonFieldNames ={'Algorithm' ,'CheckGradients' ,'Display' ,...
    'FiniteDifferenceType' ,'MaxIterations' ,'ObjectiveLimit' ,...
    'OptimalityTolerance' ,'SpecifyObjectiveGradient' }; 

switchobjType 
case 1 



obj =optimoptions ('fminunc' ); 

fminuncFieldNames =[commonFieldNames ,'StepTolerance' ]; 
forc =1 :numel (fminuncFieldNames )
obj .(fminuncFieldNames {c })=s .(fminuncFieldNames {c }); 
end

case 2 


obj =optimoptions ('fmincon' ); 

fminconFieldNames =[commonFieldNames ,'ConstraintTolerance' ,'HessianApproximation' ,...
    'HessianFcn' ,'HonorBounds' ,'ScaleProblem' ,'SpecifyConstraintGradient' ,...
    'SubproblemAlgorithm' ,'UseParallel' ]; 

forc =1 :numel (fminconFieldNames )
obj .(fminconFieldNames {c })=s .(fminconFieldNames {c }); 
end

ifisempty (s .HessianMultiplyFcn )
obj .HessianMultiplyFcn =[]; 
else
obj .HessianMultiplyFcn =str2func (s .HessianMultiplyFcn ); 
end
end



ifisempty (s .OutputFcn )
obj .OutputFcn =[]; 
else
obj .OutputFcn =str2func (s .OutputFcn ); 
end

ifisempty (s .PlotFcn )
obj .PlotFcn =[]; 
else
obj .PlotFcn =str2func (s .PlotFcn ); 
end



ifisnumeric (s .FiniteDifferenceStepSize )
obj .FiniteDifferenceStepSize =s .FiniteDifferenceStepSize ; 
end

ifisnumeric (s .MaxFunctionEvaluations )
obj .MaxFunctionEvaluations =s .MaxFunctionEvaluations ; 
end

end