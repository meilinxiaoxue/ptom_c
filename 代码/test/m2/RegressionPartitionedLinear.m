classdef RegressionPartitionedLinear <classreg .learning .partition .CompactRegressionPartitionedModel 








































methods (Hidden )
function this =RegressionPartitionedLinear (...
    X ,Y ,W ,modelParams ,dataSummary ,responseTransform )
this =this @classreg .learning .partition .CompactRegressionPartitionedModel (...
    X ,Y ,W ,modelParams ,dataSummary ,responseTransform ); 
this .CrossValidatedModel ='Linear' ; 
end
end


methods (Access =protected )
function R =response (this )
R =[]; 
pm =this .PartitionedModel ; 
trained =pm .Ensemble .Trained ; 

if~isempty (trained )
X =pm .Ensemble .X ; 




ifpm .Ensemble .ObservationsInRows 
X =X ' ; 
end

L =numel (trained {1 }.Lambda ); 
N =size (X ,2 ); 

R =NaN (N ,L ); 

uofl =~this .PrivGenerator .UseObsForIter ; 

T =numel (trained ); 
fort =1 :T 
idx =uofl (:,t ); 
R (idx ,:)=predict (trained {t },X (:,idx ),...
    'ObservationsIn' ,'columns' ); 
end
end
end

function s =propsForDisp (this ,s )
ifnargin <2 ||isempty (s )
s =struct ; 
else
if~isstruct (s )
error (message ('stats:classreg:learning:Predictor:propsForDisp:BadS' )); 
end
end

s .CrossValidatedModel ='Linear' ; 
s .ResponseName =this .ResponseName ; 
s .NumObservations =this .NumObservations ; 
s .KFold =this .KFold ; 
s .Partition =this .Partition ; 
s .ResponseTransform =this .ResponseTransform ; 
end
end


methods 
function Yhat =kfoldPredict (this )











Yhat =this .PartitionedModel .Ensemble .PrivResponseTransform (this .PrivYhat ); 
end

function err =kfoldLoss (this ,varargin )


































classreg .learning .ensemble .Ensemble .catchUOFL (varargin {:}); 
classreg .learning .FullClassificationRegressionModel .catchWeights (varargin {:}); 
[mode ,folds ,extraArgs ]=checkFoldArgs (this .PartitionedModel ,varargin {:}); 


args ={'lossfun' }; 
defs ={@classreg .learning .loss .mse }; 
funloss =internal .stats .parseArgs (args ,defs ,extraArgs {:}); 


ifstrncmpi (funloss ,'epsiloninsensitive' ,length (funloss ))
ifisempty (this .Trained {1 }.Epsilon )
error (message ('stats:RegressionLinear:loss:UseEpsilonInsensitiveForSVM' )); 
end




funloss =@(Y ,Yfit ,W )classreg .learning .loss .epsiloninsensitive (...
    Y ,Yfit ,W ,this .Trained {1 }.Epsilon ); 
end
funloss =classreg .learning .internal .lossCheck (funloss ,'regression' ); 


yhat =this .PartitionedModel .Ensemble .PrivResponseTransform (this .PrivYhat ); 
L =size (yhat ,2 ); 
y =this .Y ; 
w =this .W ; 


uofl =~this .PrivGenerator .UseObsForIter ; 
ifstrncmpi (mode ,'ensemble' ,length (mode ))
err =NaN (1 ,L ); 
iuse =any (uofl (:,folds ),2 ); 
forl =1 :L 
err (l )=funloss (y (iuse ),yhat (iuse ,l ),w (iuse )); 
end
elseifstrncmpi (mode ,'individual' ,length (mode ))
T =numel (folds ); 
err =NaN (T ,L ); 
fork =1 :T 
t =folds (k ); 
iuse =uofl (:,t ); 
forl =1 :L 
err (k ,l )=funloss (y (iuse ),yhat (iuse ,l ),w (iuse )); 
end
end
else
error (message ('stats:classreg:learning:partition:PartitionedModel:checkFoldArgs:BadMode' )); 
end
end

end

end
