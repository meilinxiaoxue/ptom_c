function [AX ]=plotPartialDependence (model ,features ,data ,varargin )





























































































narginchk (3 ,13 ); 
features =convertStringsToChars (features ); 
[varargin {:}]=convertStringsToChars (varargin {:}); 


validateattributes (data ,{'single' ,'double' ,'table' },...
    {'nonempty' ,'nonsparse' ,'real' },mfilename ,'Data' ); 


if(istable (data ))
v =varfun (@(x )isnumeric (x )&(issparse (x )||~isreal (x )),data ); 
if(any (v .Variables ))
error (message ('stats:classreg:regr:plotPartialDependence:DataRealNonSparse' )); 
end
end


if(istable (data ))
[~,numNames ]=intersect (model .PredictorNames ,...
    data .Properties .VariableNames ,'stable' ); 
if(length (numNames )~=length (model .PredictorNames ))
error (message ('stats:classreg:regr:plotPartialDependence:FeatsNameMismatch' ))
end
data =data (:,model .PredictorNames ); 
end


if(isa (model ,'classreg.regr.CompactPredictor' )&&~istable (data )&&...
    length (model .PredictorNames )~=(length (model .VariableNames )-1 ))
dataInd =ismember (model .VariableNames ,model .PredictorNames ); 
data =data (:,dataInd ); 
end


if(size (data ,2 )~=length (model .PredictorNames ))
error (message ('stats:classreg:regr:plotPartialDependence:DataNumCols' ))
end


validateattributes (features ,{'numeric' ,'string' ,'char' ,'cell' },...
    {'nonempty' },mfilename ,'Variable Name' ); 


if(iscell (features )||isfloat (features )||isstring (features ))
if(length (features )~=1 &&length (features )~=2 )
error (message ('stats:classreg:regr:plotPartialDependence:NumFeatures' ))
end
end


if(iscellstr (features ))
[~,~,indFeats ]=intersect (features ,model .PredictorNames ,'stable' ); 
if(length (indFeats )~=length (features ))
error (message ('stats:classreg:regr:plotPartialDependence:FeatsNameMismatch' ))
end
elseif(ischar (features )||isstring (features ))
if(ischar (features )&&size (features ,1 )>1 )
error (message ('stats:classreg:regr:plotPartialDependence:FeaturesType' ))
end
[~,~,indFeats ]=intersect (features ,model .PredictorNames ,'stable' ); 
if(isempty (indFeats )||(size (features ,1 )==2 &&length (indFeats )~=2 ))
error (message ('stats:classreg:regr:plotPartialDependence:FeatsNameMismatch' ))
end
elseif(isfloat (features ))
if(~all (ismember (features ,1 :size (data ,2 ))))
error (message ('stats:classreg:regr:plotPartialDependence:SizeFeats' ,size (data ,2 )))
end
indFeats =features ; 
features =model .PredictorNames (indFeats ); 
else
error (message ('stats:classreg:regr:plotPartialDependence:FeaturesType' ))
end

if(isa (model ,'classreg.regr.CompactPredictor' )&&~istable (data )&&...
    length (model .PredictorNames )~=(length (model .VariableNames )-1 ))
Data =zeros (size (data ,1 ),length (model .VariableNames )-1 ); 
Data (:,dataInd )=data ; 
data =Data ; 
D =find (dataInd ); 
indFeats =D (indFeats ); 
end


[useParallel ,conditional ,numObsToSample ,xi ,ax ]=internal .stats .parseArgs (...
    {'UseParallel' ,'Conditional' ,'NumObservationsToSample' ,'QueryPoints' ,...
    'ParentAxisHandle' },{false ,'none' ,0 ,[],[]},varargin {:}); 


validateattributes (useParallel ,{'logical' },{'nonempty' ,'scalar' },...
    mfilename ,'UseParallel' ); 
validateattributes (conditional ,{'char' ,'string' },...
    {'scalartext' ,'nonempty' },mfilename ,'Conditional' ); 
validateattributes (numObsToSample ,{'numeric' },{'nonempty' },...
    mfilename ,'NumObservationsToSample' ); 
validateattributes (xi ,{'double' ,'single' ,'cell' },...
    {'nonsparse' ,'real' },mfilename ,'QueryPoints' ); 




if(numObsToSample <0 ||~(isnumeric (numObsToSample )))
error (message ('stats:classreg:regr:plotPartialDependence:SizeObsSample' ,size (data ,1 )))
elseif(numObsToSample >0 &&numObsToSample <=size (data ,1 ))
data =datasample (data ,numObsToSample ,'Replace' ,false ); 
end




if(isa (model ,'classreg.regr.CompactPredictor' ))
catPredictors =model .VariableInfo .IsCategorical ; 
if(istable (data ))
[~,indPreds ]=intersect (model .VariableNames ,model .PredictorNames ); 
catPredictors =find (catPredictors (indPreds )); 
else
catPredictors =find (catPredictors ); 
end
elseif(isa (model ,'CompactTreeBagger' ))
catPredictors =model .Trees {1 }.CategoricalPredictors ; 
varRange =model .Trees {1 }.VariableRange ; 
else
catPredictors =model .CategoricalPredictors ; 
varRange =model .VariableRange ; 
end




if(isempty (xi ))
[x ,y ]=parseQueryPoints (data ,indFeats ,catPredictors ); 
else
y =[]; 
[~,n ]=size (xi ); 


if(n ~=length (indFeats ))
error (message ('stats:classreg:regr:plotPartialDependence:SizeQueryFeats' ))
end


if(isfloat (xi ))
x =xi (:,1 ); 
if(n ==2 )
y =xi (:,2 ); 
end
elseif(iscell (xi ))
x =xi {1 }; 
if(n ==2 )
y =xi {2 }; 
end


if(~isfloat (x )||~isfloat (y ))
error (message ('stats:classreg:regr:plotPartialDependence:QueryDataType' ))
end
else
error (message ('stats:classreg:regr:plotPartialDependence:QueryDataType' ))
end



[X ,Y ]=parseQueryPoints (data ,indFeats ,catPredictors ); 


if(isempty (x )||ismember (indFeats (1 ),catPredictors )||~isfloat (x ))
x =X ; 
end
if(isempty (y )||(length (indFeats )==2 &&ismember (indFeats (2 ),...
    catPredictors ))||~isfloat (y ))
y =Y ; 
end


if(isfloat (x )&&any (isnan (x )))
x (isnan (x ))=[]; 
end
if(~isempty (y )&&isfloat (y )&&any (isnan (y )))
y (isnan (y ))=[]; 
end



if(istable (data ))
if(isfloat (x ))
x =table (x ); 
x .Properties .VariableNames =...
    data .Properties .VariableNames (indFeats (1 )); 
end
if(~isempty (y )&&isfloat (y ))
y =table (y ); 
y .Properties .VariableNames =...
    data .Properties .VariableNames (indFeats (2 )); 
end
end
end



x =unique (x ); 
if~isempty (y )
y =unique (y ); 
end


if(isempty (ax ))
ax =newplot ; 
end


if(~isa (ax ,'matlab.graphics.axis.Axes' ))
error (message ('stats:classreg:regr:plotPartialDependence:ParentAxes' ,class (ax )))
end


if(isa (model ,'CompactTreeBagger' ))
respName =model .Trees {1 }.ResponseName ; 
else
respName =model .ResponseName ; 
end

ifstrcmp (conditional ,'absolute' )||strcmp (conditional ,'centered' )

if(length (indFeats )~=1 )
error (message ('stats:classreg:regr:plotPartialDependence:CondFeats' ))
end


[pv ,xp ,sc ]=ice (model ,data ,indFeats ,useParallel ,conditional ,x ); 


[ax ]=plotICE (ax ,pv ,xp ,sc ,features ,respName ); 


elseifstrcmp (conditional ,'none' )


if(isa (model ,'classreg.learning.regr.CompactRegressionTree' ))

parDep =pdpTree (model ,indFeats ,useParallel ,x ,y ,catPredictors ,varRange ); 


elseif((isa (model ,'classreg.learning.regr.CompactRegressionEnsemble' )...
    &&ismember (model .LearnerNames ,'Tree' ))||...
    isa (model ,'CompactTreeBagger' ))

parDep =pdpEnsemble (model ,indFeats ,useParallel ,x ,y ,catPredictors ,...
    varRange ); 

else

parDep =pdp (model ,data ,indFeats ,useParallel ,x ,y ); 
end


ax =plotPD (ax ,parDep ,x ,y ,features ,respName ); 
else
error (message ('stats:classreg:regr:plotPartialDependence:CondOptions' ))
end


if(nargout >0 )
AX =ax ; 
end
end


function [x ,y ]=parseQueryPoints (data ,indFeats ,cat )
y =[]; 


if(istable (data )||any (cat ))
x =obtainQueryPts (data (:,indFeats (1 )),ismember (indFeats (1 ),cat )); 
if(length (indFeats )==2 )
y =obtainQueryPts (data (:,indFeats (2 )),ismember (indFeats (2 ),cat )); 
end
else
maxD =max (data (:,indFeats )); 
minD =min (data (:,indFeats )); 
x =linspace (minD (1 ),maxD (1 ))' ; 
if(length (indFeats )==2 )
y =linspace (minD (end),maxD (end))' ; 
end
end
end

function [v ]=obtainQueryPts (data ,cat )

if(istable (data ))
D =data .(data .Properties .VariableNames {1 }); 
else
D =data ; 
end




if((isfloat (data )||(istable (data )&&isfloat (data {1 ,1 })))&&~(cat ))
maxD =max (D ); 
minD =min (D ); 
v =(linspace (minD ,maxD ))' ; 


if(istable (data ))
v =table (v ); 
v .Properties .VariableNames =data .Properties .VariableNames ; 
end
else

v =unique (data ); 
isMiss =ismissing (v ); 
if(any (isMiss ))
indMiss =find (isMiss ); 
v =[v (~isMiss ,1 ); v (indMiss (1 ),1 )]; 
end
end
end


function [parDep ]=pdp (model ,data ,ij ,par ,x ,y )

if(length (ij )==1 )

parDep =zeros (size (x )); 

if(par )
parforidy =1 :size (x ,1 )
X =data ; 
X (:,ij )=x (idy ,1 ); 
parDep (idy )=mean (predict (model ,X ),1 ,'omitnan' ); 
end
else

foridy =1 :size (x ,1 )
data (:,ij )=x (idy ,1 ); 
parDep (idy )=mean (predict (model ,data ),1 ,'omitnan' ); 
end
end
elseif(length (ij )==2 )

parDep =zeros (size (y ,1 ),size (x ,1 )); 


N =size (x ,1 ); 
M =size (y ,1 ); 


ij1 =ij (1 ); 
ij2 =ij (2 ); 

if(par )
parforidx =1 :N 
uni1 =x (idx ,1 ); 
foridy =1 :M 
X =data ; 

X (:,ij1 )=uni1 ; 

X (:,ij2 )=y (idy ,1 ); %#ok<PFBNS> 
parDep (idy ,idx )=mean (predict (model ,X ),1 ,'omitnan' ); 
end
end
else
foridx =1 :N 

data (:,ij1 )=x (idx ,1 ); 
foridy =1 :M 

data (:,ij2 )=y (idy ,1 ); 
parDep (idy ,idx )=mean (predict (model ,data ),1 ,'omitnan' ); 
end
end
end
end
end


function [parDep ]=pdpTree (tree ,ij ,par ,x ,y ,cat ,vrange )

zl =tree .PredictorNames (ij ); 



[IsChosenPredictor ,whichPredictor ]=ismember (tree .CutPredictor ,zl ); 
IsCategoricalCut =strcmp (tree .CutType ,'categorical' ); 



IsBranchNode =tree .IsBranchNode ; 
CutPoint =tree .CutPoint ; 
Children =(tree .Children )-1 ; 
NodeMean =tree .NodeMean ; 
NodeSize =tree .NodeSize ; 
CutCategories =tree .CutCategories (:,1 ); 
IsCatAndChosen =IsChosenPredictor &IsCategoricalCut ; 
IsCatLeft =false (size (IsCatAndChosen )); 


dataX =getVariableRange (x ,ismember (ij (1 ),cat ),ij (1 ),vrange ); 

if(length (ij )==1 )

N =size (dataX ,1 ); 


parDep =zeros (N ,1 ); 


if(par )
parforxIdx =1 :N 
parDep (xIdx )=getPartialDependence (dataX (xIdx ),IsChosenPredictor ,...
    whichPredictor ,IsCategoricalCut ,IsBranchNode ,CutPoint ,...
    Children ,NodeMean ,NodeSize ,CutCategories ,IsCatAndChosen ,IsCatLeft ); 
end
else
forxIdx =1 :N 

parDep (xIdx )=getPartialDependence (dataX (xIdx ),IsChosenPredictor ,...
    whichPredictor ,IsCategoricalCut ,IsBranchNode ,CutPoint ,...
    Children ,NodeMean ,NodeSize ,CutCategories ,IsCatAndChosen ,IsCatLeft ); 
end
end
elseif(length (ij )==2 )

dataY =getVariableRange (y ,ismember (ij (2 ),cat ),ij (2 ),vrange ); 


parDep =zeros (size (dataY ,1 ),size (dataX ,1 )); 


N =size (dataX ,1 ); 
M =size (dataY ,1 ); 

if(par )
parfork =1 :N 
K =dataX (k ); 
J =dataY ; 
forj =1 :M 

parDep (j ,k )=getPartialDependence ([K ,J (j )],IsChosenPredictor ,...
    whichPredictor ,IsCategoricalCut ,IsBranchNode ,...
    CutPoint ,Children ,NodeMean ,NodeSize ,CutCategories ,...
    IsCatAndChosen ,IsCatLeft ); 
end
end
else
J =dataY ; 
fork =1 :N 
K =dataX (k ); 
forj =1 :M 

parDep (j ,k )=getPartialDependence ([K ,J (j )],IsChosenPredictor ,...
    whichPredictor ,IsCategoricalCut ,IsBranchNode ,...
    CutPoint ,Children ,NodeMean ,NodeSize ,CutCategories ,...
    IsCatAndChosen ,IsCatLeft ); 
end
end
end
end
end


function [data ]=getVariableRange (v ,cat ,ij ,vrange )

data =v ; 


if(istable (v ))
if(isfloat (v {1 ,1 })||islogical (v {1 ,1 })||iscategorical (v {1 ,1 }))
data =v .(v .Properties .VariableNames {1 }); 
else
data =table2cell (v ); 
if(iscellstr (data ))

data =strtrim (data ); 
end
end
end



if(cat )

[~,data ]=ismember (data ,vrange {ij }); 



data (data ==0 )=nan ; 
end
end

function [pdVal ]=getPartialDependence (chosenObs ,IsChosenPredictor ,...
    whichPredictor ,IsCategoricalCut ,IsBranchNode ,CutPoint ,Children ,...
    NodeMean ,NodeSize ,CutCategories ,CatIdx ,IsCatLeft )

ifany (CatIdx )

cIdx =find (CatIdx ); 


foridx =1 :size (cIdx )
IsCatLeft (cIdx (idx ))=ismember (...
    chosenObs (whichPredictor (cIdx (idx ))),CutCategories {cIdx (idx )}); 
end
end


pdVal =classreg .regr .modelutils .getParDep (chosenObs ,IsChosenPredictor ,...
    whichPredictor ,IsBranchNode ,Children (:,1 ),Children (:,2 ),CutPoint ,...
    NodeSize ,IsCatLeft ,IsCategoricalCut ,NodeMean ); 
end


function [parDep ]=pdpEnsemble (model ,features ,useParallel ,x ,y ,cat ,vrange )




if(isa (model ,'CompactTreeBagger' ))
nTrees =model .NumTrees ; 
learners =model .Trees ; 
else
nTrees =model .NumTrained ; 
learners =model .Trained ; 
end


parDep =pdpTree (learners {1 },features ,useParallel ,x ,y ,cat ,vrange ); 

if(useParallel )
parforidx =2 :nTrees 

p =pdpTree (learners {idx },features ,useParallel ,x ,y ,cat ,vrange ); 

parDep =parDep +p ; 
end
else
foridx =2 :nTrees 

p =pdpTree (learners {idx },features ,useParallel ,x ,y ,cat ,vrange ); 

parDep =parDep +p ; 
end
end

parDep =parDep /nTrees ; 
end


function [plotPts ,xp ,scatPts ]=ice (model ,data ,features ,par ,conditional ,x )
[m ,~]=size (data ); 


plotPts =zeros (size (x ,1 )+1 ,m ); 
scatPts =zeros (1 ,m ); 
ij =features ; 



if(istable (data )&&(isfloat (data {:,ij })))
xp_sc =data {:,ij }; 
elseif(isfloat (data (:,ij )))
xp_sc =data (:,ij ); 
else


[~,xp_sc ]=ismember (data (:,ij ),x ,'rows' ); 
plotPts =zeros (size (x ,1 ),m ); 
end


D =data (:,ij ); 
if(par )
parforidx =1 :m 

[plotPts (:,idx ),scatPts (idx )]=getIndCondExp (x ,D (idx ,1 ),...
    data (idx ,:),model ,ij ); 
end
else
foridx =1 :m 

[plotPts (:,idx ),scatPts (idx )]=getIndCondExp (x ,D (idx ,1 ),...
    data (idx ,:),model ,ij ); 
end
end


xp .plotPts =x ; 
xp .scatPts =xp_sc ; 




if(strcmp (conditional ,'centered' ))
scatPts =scatPts -plotPts (1 ,:); 
plotPts =plotPts -plotPts (1 ,:); 
end
end


function [pv ,sc ]=getIndCondExp (x ,D ,data ,model ,ij )

if(isfloat (x )||(istable (x )&&isfloat (x {1 ,1 })))
[x ,scIdx ]=sortrows ([x ; D ]); 
scIdx =find (scIdx ==max (scIdx )); 
else
[~,scIdx ]=ismember (D ,x ); 
end

X =repmat (data ,size (x ,1 ),1 ); 
X (:,ij )=x ; 


pv =predict (model ,X ); 
sc =pv (scIdx ); 
end


function [ax ]=plotPD (ax ,parDep ,x ,y ,features ,response )
if(isempty (y ))


if(istable (x )&&isfloat (x {1 ,1 }))
varX =table2array (x ); 

plot (ax ,varX ,parDep ); 
elseif(istable (x ))
xVals =1 :size (x ,1 ); 

plot (ax ,xVals ,parDep ,'o:' ,'MarkerFaceColor' ,'b' ); 
ax .XTick =xVals ; 
ax .XTickLabels =missingToString (x ); 
else

plot (ax ,x ,parDep ); 
end


ax .XLabel .String =features ; 
ax .YLabel .String =response ; 
ax .Title .String ='Partial Dependence Plot' ; 
else

[s1 ,s2 ]=size (parDep ); 



if(istable (x )&&isfloat (x {1 ,1 }))
varX =table2array (x ); 
varX =repmat (varX ' ,s1 ,1 ); 
elseif(istable (x ))
xVals =1 :s2 ; 
varX =repmat (xVals ,s1 ,1 ); 
elseif(isfloat (x ))
varX =repmat (x ' ,s1 ,1 ); 
end


if(istable (y )&&isfloat (y {1 ,1 }))
varY =table2array (y ); 
varY =repmat (varY ,1 ,s2 ); 
elseif(istable (y ))
yVals =(1 :s1 )' ; 
varY =repmat (yVals ,1 ,s2 ); 
elseif(isfloat (y ))
varY =repmat (y ,1 ,s2 ); 
end


if(min (size (varX ))==1 ||min (size (varY ))==1 )
plot3 (ax ,varX ,varY ,parDep ); 
else
surf (ax ,varX ,varY ,parDep ); 
end


ax .XLabel .String =features (1 ); 
ax .YLabel .String =features (2 ); 
ax .ZLabel .String =response ; 
ax .Title .String ='Partial Dependence Plot' ; 



if(istable (x )&&~isfloat (x {1 ,1 }))
ax .XTick =xVals ; 
ax .XTickLabels =missingToString (x ); 
end
if(istable (y )&&~isfloat (y {1 ,1 }))
ax .YTick =yVals ; 
ax .YTickLabels =missingToString (y ); 
end
end
end

function vStr =missingToString (vTab )

idx =ismissing (vTab ); 
vStr =table2cell (vTab ); 
if(any (idx ))
vStr {idx }="missing" ; 
end
vStr =string (vStr ); 
end

function [ax ]=plotICE (ax ,plotPts ,xp ,scatPts ,features ,response )

p =xp .plotPts ; 
s =xp .scatPts ; 



if(isfloat (p )||(istable (p )&&isfloat (p {1 ,1 })))
if(istable (p ))
p =table2array (p ); 
end
p =repmat (p ,1 ,size (plotPts ,2 )); 
p =sort ([p ; s ' ],1 ); 


plot (ax ,p ,plotPts ,'LineWidth' ,0.5 ,'Color' ,[0.5 ,0.5 ,0.5 ]); 
elseif(istable (p ))
xVals =1 :size (p ,1 ); 

plot (ax ,xVals ' ,plotPts ,'LineWidth' ,0.5 ,'Color' ,[0.5 ,0.5 ,0.5 ]); 


ax .XTick =xVals ; 
ax .XTickLabels =string (table2cell (p )); 
p =xVals ' ; 
end

boolHold =ishold (ax ); 

hold (ax ,'on' ); 
scatter (ax ,s ,scatPts ,'MarkerFaceColor' ,[0 ,0 ,0 ]); 


plot (ax ,mean (p ,2 ,'omitnan' ),mean (plotPts ,2 ,'omitnan' ),'LineWidth' ,3 ,...
    'Color' ,[1 ,0 ,0 ]); 
if(~boolHold )
hold (ax ,'off' ); 
end


ax .XLabel .String =features ; 
ax .YLabel .String =response ; 
ax .Title .String ='Individual Conditional Expectation Plot' ; 
end