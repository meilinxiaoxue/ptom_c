classdef FeatureSelectionNCAClassificationImpl <classreg .learning .fsutils .FeatureSelectionNCAImpl 




properties (Dependent )
Y ; 
ClassNames ; 
end

properties 
PrivY ; 
YLabels ; 
YLabelsOrig ; 
end


methods 
function y =get .Y (this )
yid =this .PrivY ; 
y =this .YLabelsOrig (yid ,:); 
end

function cn =get .ClassNames (this )
cn =this .YLabels ; 
end
end


methods 
function this =FeatureSelectionNCAClassificationImpl (X ,privY ,privW ,modelParams ,yLabels ,yLabelsOrig )


this =this @classreg .learning .fsutils .FeatureSelectionNCAImpl (X ,privW ,modelParams ); 
this .PrivY =privY ; 
this .YLabels =yLabels ; 
this .YLabelsOrig =yLabelsOrig ; 
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
case lower (classreg .learning .fsutils .FeatureSelectionNCAModel .RobustLossMisclassError )
lossID =classreg .learning .fsutils .FeatureSelectionNCAModel .MISCLASS_LOSS ; 

otherwise
error (message ('stats:FeatureSelectionNCA:FeatureSelectionNCAClassification:BadLossFunctionClassification' )); 
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
case lower (classreg .learning .fsutils .FeatureSelectionNCAModel .RobustLossMisclassError )
lossFcn =@(yi ,yj )-double (bsxfun (@eq ,yi ,yj ' )); 

otherwise
error (message ('stats:FeatureSelectionNCA:FeatureSelectionNCAClassification:BadLossFunctionClassification' )); 
end
end
















fun =makeRegularizedObjectiveFunctionForMinimizationRobust (this ,Xt ,y ,lossFcn ); 
end
end


methods 
function effobswts =effectiveObservationWeights (this ,obswts ,prior )











N =this .NumObservations ; 
R =length (this .YLabels ); 


if(internal .stats .isString (prior ))

switchlower (prior )
case lower (classreg .learning .fsutils .FeatureSelectionNCAModel .PriorUniform )
classProbs =ones (R ,1 ); 

case lower (classreg .learning .fsutils .FeatureSelectionNCAModel .PriorEmpirical )

w1 =obswts (1 ); 
if(all (obswts ==w1 ))
effobswts =obswts /w1 ; 
return ; 
end

classProbs =accumarray (this .PrivY ,ones (N ,1 ),[R ,1 ]); 

otherwise
error (message ('stats:FeatureSelectionNCA:FeatureSelectionNCAClassification:BadPriorString' )); 
end
else


classProbs =prior .ClassProbs ; 
classNames =prior .ClassNames ; 

[tf ,loc ]=ismember (this .YLabels ,classNames ); 
isok =all (tf ); 
if~isok 
error (message ('stats:FeatureSelectionNCA:FeatureSelectionNCAClassification:BadPriorStruct' )); 
end








classProbs =classProbs (loc ); 
end


sumClassProbs =sum (classProbs ); 
if(sumClassProbs ==0 )
error (message ('stats:FeatureSelectionNCA:FeatureSelectionNCAClassification:AllZeroPriorProbs' )); 
end
classProbs =classProbs /sumClassProbs ; 


effobswts =obswts ; 
fork =1 :R 
idxk =(this .PrivY ==k ); 
wk =obswts (idxk ); 
effobswts (idxk )=classProbs (k )*(wk /sum (wk )); 
end


effobswts =effobswts *N /sum (effobswts ); 
end
end


methods (Hidden )
function postprobs =predictNCAMex (this ,XTest )














XTest =applyStandardizationToXTest (this ,XTest ); 


M =size (XTest ,1 ); 
C =length (this .YLabels ); 



w =mean (this .FeatureWeights ,2 ); 
sigma =this .ModelParams .LengthScale ; 
obswts =this .PrivObservationWeights ; 



XTest =XTest ' ; 
XTrain =(this .PrivX )' ; 


yidTrain =this .PrivY ; 


[P ,N ]=size (XTrain ); 
doclass =true ; 





if(isa (XTest ,'double' ))
convertToDoubleFcn =@(x )full (classreg .learning .fsutils .FeatureSelectionNCAModel .convertToDouble (x )); 

XTrain =convertToDoubleFcn (XTrain ); 
yidTrain =convertToDoubleFcn (yidTrain ); 
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
yidTrain =convertToSingleFcn (yidTrain ); 
P =convertToSingleFcn (P ); 
N =convertToSingleFcn (N ); 
M =convertToSingleFcn (M ); 
C =convertToSingleFcn (C ); 
sigma =convertToSingleFcn (sigma ); 
w =convertToSingleFcn (w ); 
obswts =convertToSingleFcn (obswts ); 
end


postprobs =classreg .learning .fsutils .predict (XTrain ,yidTrain ,P ,N ,XTest ,M ,C ,sigma ,w ,doclass ,obswts ); 


postprobs =postprobs ' ; 
end

function postprobs =predictNCA (this ,XTest )













XTest =applyStandardizationToXTest (this ,XTest ); 


M =size (XTest ,1 ); 
C =length (this .YLabels ); 



w =mean (this .FeatureWeights ,2 ); 
sigma =this .ModelParams .LengthScale ; 
obswts =this .PrivObservationWeights ' ; 



XTest =XTest ' ; 
XTrain =(this .PrivX )' ; 


yidTrain =this .PrivY ; 


postprobs =zeros (C ,M ); 

fori =1 :M 

xi =XTest (:,i ); 






dist =abs (bsxfun (@minus ,XTrain ,xi )); 




wtdDist =sum (bsxfun (@times ,dist ,w .^2 ),1 ); 
wtdDist =wtdDist -min (wtdDist ); 


pij =obswts .*exp (-wtdDist /sigma ); 
pij =pij /sum (pij ); 












postprobs (1 :max (yidTrain ),i )=accumarray (yidTrain ,pij ); 
end


postprobs =postprobs ' ; 
end
end

end

