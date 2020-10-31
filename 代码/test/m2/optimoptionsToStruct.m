function s =optimoptionsToStruct (obj ,objType )










s =struct ; 
commonFieldNames ={'Algorithm' ,'CheckGradients' ,'Display' ,'FiniteDifferenceStepSize' ,...
    'FiniteDifferenceType' ,'MaxFunctionEvaluations' ,'MaxIterations' ,'ObjectiveLimit' ,...
    'OptimalityTolerance' ,'SpecifyObjectiveGradient' ,'TypicalX' }; 

switchobjType 
case 1 



fminuncFieldNames =[commonFieldNames ,'StepTolerance' ]; 
forc =1 :numel (fminuncFieldNames )
s .(fminuncFieldNames {c })=obj .(fminuncFieldNames {c }); 
end

case 2 



fminconFieldNames =[commonFieldNames ,'ConstraintTolerance' ,'HessianApproximation' ,...
    'HessianFcn' ,'HonorBounds' ,'ScaleProblem' ,'SpecifyConstraintGradient' ,...
    'SubproblemAlgorithm' ,'UseParallel' ]; 

forc =1 :numel (fminconFieldNames )
s .(fminconFieldNames {c })=obj .(fminconFieldNames {c }); 
end

ifisempty (obj .HessianMultiplyFcn )
s .HessianMultiplyFcn =[]; 
else
s .HessianMultiplyFcn =func2str (obj .HessianMultiplyFcn ); 
end
end

ifisempty (obj .OutputFcn )
s .OutputFcn =[]; 
else
s .OutputFcn =func2str (obj .OutputFcn ); 
end

ifisempty (obj .PlotFcn )
s .PlotFcn =[]; 
else
s .PlotFcn =func2str (obj .PlotFcn ); 
end

end