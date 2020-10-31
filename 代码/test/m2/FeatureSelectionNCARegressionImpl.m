classdef FeatureSelectionNCARegressionImpl <classreg .learning .fsutils .FeatureSelectionNCAImpl 




properties (Dependent )
Y ; 
end

properties 
PrivY ; 
end


methods 
function y =get .Y (this )
y =this .PrivY ; 
end
end


methods 
function this =FeatureSelectionNCARegressionImpl (X ,privY ,privW ,modelParams )


this =this @classreg .learning .fsutils .FeatureSelectionNCAImpl (X ,privW ,modelParams ); 
this .PrivY =privY ; 
end
end


methods 
function fun =makeObjectiveFunctionForMinimizationMex (this )


Xt =this .PrivX ' ; 
y =this .PrivY ; 












robustLoss =this .ModelParams .LossFunction ; 
if(isa (robustLoss ,'function_handle' ))
lossID =robustLoss ; 
else
switchlower (robustLoss )
case lower (classreg .learning .fsutils .FeatureSelectionNCAModel .RobustLossL1 )
lossID =classreg .learning .fsutils .FeatureSelectionNCAModel .L1_LOSS ; 

case lower (classreg .learning .fsutils .FeatureSelectionNCAModel .RobustLossL2 )
lossID =classreg .learning .fsutils .FeatureSelectionNCAModel .L2_LOSS ; 

case lower (classreg .learning .fsutils .FeatureSelectionNCAModel .RobustLossEpsilonInsensitive )
lossID =classreg .learning .fsutils .FeatureSelectionNCAModel .EPSILON_INSENSITIVE_LOSS ; 

otherwise
error (message ('stats:FeatureSelectionNCA:FeatureSelectionNCARegression:BadLossFunctionRegression' )); 
end
end


epsilon =this .ModelParams .Epsilon ; 














fun =makeRegularizedObjectiveFunctionForMinimizationRobustMex (this ,Xt ,y ,lossID ,epsilon ); 
end

function fun =makeObjectiveFunctionForMinimization (this )


Xt =this .PrivX ' ; 
y =this .PrivY ; 










robustLoss =this .ModelParams .LossFunction ; 
if(isa (robustLoss ,'function_handle' ))
lossFcn =robustLoss ; 
else
switchlower (robustLoss )
case lower (classreg .learning .fsutils .FeatureSelectionNCAModel .RobustLossL1 )
lossFcn =@(yi ,yj )abs (bsxfun (@minus ,yi ,yj ' )); 

case lower (classreg .learning .fsutils .FeatureSelectionNCAModel .RobustLossL2 )
lossFcn =@(yi ,yj )(bsxfun (@minus ,yi ,yj ' )).^2 ; 

case lower (classreg .learning .fsutils .FeatureSelectionNCAModel .RobustLossEpsilonInsensitive )
epsilon =this .ModelParams .Epsilon ; 
lossFcn =@(yi ,yj )max (0 ,abs (bsxfun (@minus ,yi ,yj ' ))-epsilon ); 

otherwise
error (message ('stats:FeatureSelectionNCA:FeatureSelectionNCARegression:BadLossFunctionRegression' )); 
end
end
















fun =makeRegularizedObjectiveFunctionForMinimizationRobust (this ,Xt ,y ,lossFcn ); 
end
end


methods 
function effobswts =effectiveObservationWeights (this ,obswts ,~)

N =this .NumObservations ; 


sumobswts =sum (obswts ); 
if(sumobswts ~=N )
effobswts =obswts *N /sumobswts ; 
else
effobswts =obswts ; 
end
end
end


methods (Hidden )
function ypred =predictNCA (this ,XTest )









XTest =applyStandardizationToXTest (this ,XTest ); 


M =size (XTest ,1 ); 



w =mean (this .FeatureWeights ,2 ); 
sigma =this .ModelParams .LengthScale ; 
obswts =this .PrivObservationWeights ' ; 



XTest =XTest ' ; 
XTrain =(this .PrivX )' ; 


yTrain =this .PrivY ; 


ypred =zeros (M ,1 ); 

fori =1 :M 

xi =XTest (:,i ); 






dist =abs (bsxfun (@minus ,XTrain ,xi )); 




wtdDist =sum (bsxfun (@times ,dist ,w .^2 ),1 ); 
wtdDist =wtdDist -min (wtdDist ); 


pij =obswts .*exp (-wtdDist /sigma ); 
pij =pij /sum (pij ); 


ypred (i )=pij *yTrain ; 
end
end

function ypred =predictNCAMex (this ,XTest )









XTest =applyStandardizationToXTest (this ,XTest ); 


M =size (XTest ,1 ); 



w =mean (this .FeatureWeights ,2 ); 
sigma =this .ModelParams .LengthScale ; 
obswts =this .PrivObservationWeights ; 



XTest =XTest ' ; 
XTrain =(this .PrivX )' ; 


yTrain =this .PrivY ; 


[P ,N ]=size (XTrain ); 
C =NaN ; 
doclass =false ; 





if(isa (XTest ,'double' ))
convertToDoubleFcn =@(x )full (classreg .learning .fsutils .FeatureSelectionNCAModel .convertToDouble (x )); 

XTrain =convertToDoubleFcn (XTrain ); 
yTrain =convertToDoubleFcn (yTrain ); 
P =convertToDoubleFcn (P ); 
N =convertToDoubleFcn (N ); 
M =convertToDoubleFcn (M ); 
C =convertToDoubleFcn (C ); 
sigma =convertToDoubleFcn (sigma ); 
w =convertToDoubleFcn (w ); 
obswts =convertToDoubleFcn (obswts ); 
else
convertToSingleFcn =@(x )full (classreg .learning .fsutils .FeatureSelectionNCAModel .convertToSingle (x )); 

XTrain =convertToSingleFcn (XTrain ); 
yTrain =convertToSingleFcn (yTrain ); 
P =convertToSingleFcn (P ); 
N =convertToSingleFcn (N ); 
M =convertToSingleFcn (M ); 
C =convertToSingleFcn (C ); 
sigma =convertToSingleFcn (sigma ); 
w =convertToSingleFcn (w ); 
obswts =convertToSingleFcn (obswts ); 
end


ypred =classreg .learning .fsutils .predict (XTrain ,yTrain ,P ,N ,XTest ,M ,C ,sigma ,w ,doclass ,obswts ); 
end
end

end

