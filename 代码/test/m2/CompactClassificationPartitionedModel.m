classdef CompactClassificationPartitionedModel <classreg .learning .partition .CompactPartitionedModel 



properties (GetAccess =protected ,SetAccess =protected )
PrivC ; 
PrivScore ; 
end

properties (GetAccess =public ,SetAccess =protected ,Dependent =true )





ClassNames ; 
end

properties (GetAccess =public ,SetAccess =public ,Dependent =true )






Cost ; 





Prior ; 











ScoreTransform ; 
end

properties (GetAccess =public ,SetAccess =public ,Dependent =true ,Hidden =true )
ScoreType ; 
DefaultLoss ; 
LabelPredictor ; 
end

properties (GetAccess =public ,SetAccess =protected ,Dependent =true ,Hidden =true )
ContinuousLoss ; 
end

methods 
function cn =get .ClassNames (this )
cn =this .PartitionedModel .ClassNames ; 
end

function cost =get .Cost (this )
cost =this .PartitionedModel .Cost ; 
end

function this =set .Cost (this ,cost )
this .PartitionedModel .Cost =cost ; 
end

function prior =get .Prior (this )
prior =this .PartitionedModel .Prior ; 
end

function this =set .Prior (this ,prior )
this .PartitionedModel .Prior =prior ; 
end

function st =get .ScoreTransform (this )
st =this .PartitionedModel .ScoreTransform ; 
end

function this =set .ScoreTransform (this ,st )
this .PartitionedModel .ScoreTransform =st ; 
end

function st =get .ScoreType (this )
st =this .PartitionedModel .ScoreType ; 
end

function this =set .ScoreType (this ,st )
this .PartitionedModel .ScoreType =st ; 
end

function loss =get .DefaultLoss (this )
loss =this .PartitionedModel .DefaultLoss ; 
end

function this =set .DefaultLoss (this ,loss )
this .PartitionedModel .DefaultLoss =loss ; 
end

function pred =get .LabelPredictor (this )
pred =this .PartitionedModel .LabelPredictor ; 
end

function this =set .LabelPredictor (this ,pred )
this .PartitionedModel .LabelPredictor =pred ; 
end

function loss =get .ContinuousLoss (this )
loss =this .PartitionedModel .ContinuousLoss ; 
end
end


methods (Access =protected )
function s =propsForDisp (this ,s )
s =propsForDisp @classreg .learning .partition .CompactPartitionedModel (this ,s ); 
cnames =this .ClassNames ; 
ifischar (cnames )
s .ClassNames =cnames ; 
else
s .ClassNames =cnames ' ; 
end
s .ScoreTransform =this .ScoreTransform ; 
end
end


methods (Hidden )
function this =CompactClassificationPartitionedModel (X ,Y ,W ,modelParams ,...
    dataSummary ,classSummary ,scoreTransform )
this =this @classreg .learning .partition .CompactPartitionedModel (); 

pm =classreg .learning .partition .ClassificationPartitionedModel (...
    X ,Y ,W ,modelParams ,dataSummary ,classSummary ,scoreTransform ); 



this .PartitionedModel =pm ; 

ifdataSummary .ObservationsInRows 
this .NumObservations =size (pm .Ensemble .X ,1 ); 
else
this .NumObservations =size (pm .Ensemble .X ,2 ); 
end
this .PrivGenerator =pm .Ensemble .ModelParams .Generator ; 

this .PrivScore =score (this ); 

this .PrivC =classreg .learning .internal .classCount (...
    pm .Ensemble .ClassSummary .ClassNames ,pm .Ensemble .PrivY ); 

this .Y =pm .Ensemble .Y ; 
this .W =pm .Ensemble .W ; 

this .ModelParams =pm .Ensemble .ModelParams ; 

this .PartitionedModel =compactPartitionedModel (pm ); 
end
end


methods (Abstract )
m =kfoldMargin (this ,varargin )
end

methods (Access =protected ,Abstract =true )
s =score (this )
end


methods 
function e =kfoldEdge (this ,varargin )
e =kfoldLoss (this ,'LossFun' ,@classreg .learning .loss .classifedge ,varargin {:}); 
end
end

end
