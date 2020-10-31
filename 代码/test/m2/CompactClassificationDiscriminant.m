classdef CompactClassificationDiscriminant <classreg .learning .classif .ClassificationModel 






































properties (GetAccess =public ,SetAccess =public ,Dependent =true )










DiscrimType ; 















Gamma ; 











Delta ; 
end

properties (GetAccess =public ,SetAccess =protected )





















Coeffs =[]; 
end

properties (GetAccess =protected ,SetAccess =protected )
PrivBetweenSigma =[]; 
end

properties (GetAccess =public ,SetAccess =protected ,Dependent =true )





Mu =[]; 


















Sigma ; 








BetweenSigma ; 








LogDetSigma ; 








MinGamma ; 










DeltaPredictor ; 
end

methods (Static =true ,Access =protected )
function [s ,v ,d ]=decompose (sigma )
d =diag (sigma )' ; 
p =numel (d ); 
ifany (d <0 &abs (d )>p *eps (max (d )))
error (message ('stats:classreg:learning:classif:CompactClassificationDiscriminant:decompose:NegativeD' )); 
end
d (d <0 )=0 ; 
d =sqrt (d ); 
badD =d <p *eps (max (d )); 
d (badD )=0 ; 
invD =1 ./d ; 
invD (badD )=0 ; 
sigma =bsxfun (@times ,invD ' ,bsxfun (@times ,sigma ,invD )); 
sigma =(sigma +sigma ' )/2 ; 
[v ,s ]=eig (sigma ); 
s =diag (s ); 
ifany (s <0 &abs (s )>p *eps (max (s )))
error (message ('stats:classreg:learning:classif:CompactClassificationDiscriminant:decompose:NegativeS' )); 
end
s (s <0 )=0 ; 
s =sqrt (s ); 
s (s <p *eps (max (s )))=0 ; 
end
end

methods 
function mu =get .Mu (this )
K =length (this .ClassSummary .ClassNames ); 
P =size (this .Impl .Mu ,2 ); 
mu =NaN (K ,P ); 
[~,Knonempty ]=ismember (this .ClassSummary .NonzeroProbClasses ,...
    this .ClassSummary .ClassNames ); 
mu (Knonempty ,:)=this .Impl .Mu ; 
end

function dt =get .DiscrimType (this )
dt =this .Impl .Type ; 
end

function this =set .DiscrimType (this ,discrimType )
this =setDiscrimType (this ,discrimType ); 
end

function gamma =get .Gamma (this )
gamma =this .Impl .Gamma ; 
end

function delta =get .Delta (this )
delta =this .Impl .Delta ; 
end

function this =set .Gamma (this ,gamma )
this =setGamma (this ,gamma ); 
end

function this =set .Delta (this ,delta )
this =setDelta (this ,delta ); 
end

function logsig =get .LogDetSigma (this )
ifisa (this .Impl ,'classreg.learning.impl.QuadraticDiscriminantImpl' )
K =length (this .ClassSummary .ClassNames ); 
logsig =NaN (K ,1 ); 
[~,Knonempty ]=ismember (this .ClassSummary .NonzeroProbClasses ,...
    this .ClassSummary .ClassNames ); 
logsig (Knonempty )=this .Impl .LogDetSigma ; 
else
logsig =this .Impl .LogDetSigma ; 
end
end

function sig =get .Sigma (this )
ifisa (this .Impl ,'classreg.learning.impl.QuadraticDiscriminantImpl' )
K =length (this .ClassSummary .ClassNames ); 
P =size (this .Impl .Mu ,2 ); 
[~,Knonempty ]=ismember (this .ClassSummary .NonzeroProbClasses ,...
    this .ClassSummary .ClassNames ); 

ifstrcmpi (this .Impl .Type ,'diagquadratic' )
sig =NaN (1 ,P ,K ); 
else
sig =NaN (P ,P ,K ); 
end
sig (:,:,Knonempty )=this .Impl .Sigma ; 
else
sig =this .Impl .Sigma ; 
end
end

function S =get .BetweenSigma (this )

if~isempty (this .PrivBetweenSigma )
S =this .PrivBetweenSigma ; 
return ; 
end




Wj =this .Impl .ClassWeights ; 
centeredMu =this .Impl .CenteredMu ; 
weightedMu =bsxfun (@times ,centeredMu ,sqrt (Wj )); 
Wj =Wj (~isnan (Wj )); 
S =weightedMu ' *weightedMu /(1 -Wj ' *Wj ); 
end

function mingam =get .MinGamma (this )
mingam =this .Impl .MinGamma ; 
end

function delpred =get .DeltaPredictor (this )
delpred =deltaPredictor (this .Impl ); 
end
end

methods (Hidden )

function result =logP (this ,X )
result =logp (this ,X ); 
end
end

methods (Hidden )


function this =setGamma (this ,gamma )
this =setBaseGamma (this ,gamma ); 
end

function this =setDelta (this ,delta ,checkValidity )
ifnargin <3 
checkValidity =true ; 
end
this =setBaseDelta (this ,delta ,checkValidity ); 
end
end

methods 
function [label ,scores ,cost ]=predict (this ,X )


















adapter =classreg .learning .internal .makeClassificationModelAdapter (this ,X ); 
if~isempty (adapter )
[label ,scores ,cost ]=predict (adapter ,X ); 
return ; 
end


vrange =getvrange (this ); 


X =classreg .learning .internal .table2PredictMatrix (X ,[],[],...
    vrange ,this .CategoricalPredictors ,...
    getOptionalPredictorNames (this )); 


ifisempty (X )
[label ,scores ,cost ]=predictEmptyX (this ,X ); 
return ; 
end





logP =score (this ,X ); 


maxLogP =max (logP ,[],2 ); 
P =exp (bsxfun (@minus ,logP ,maxLogP )); 


sumP =nansum (P ,2 ); 
posterior =bsxfun (@times ,P ,1 ./(sumP )); 



[label ,scores ,cost ]=this .LabelPredictor (this .ClassNames ,...
    this .Prior ,this .Cost ,posterior ,this .PrivScoreTransform ); 
end

function M =mahal (this ,X ,varargin )
















[varargin {:}]=convertStringsToChars (varargin {:}); 
adapter =classreg .learning .internal .makeClassificationModelAdapter (this ,X ,varargin {:}); 
if~isempty (adapter )
M =slice (adapter ,@this .mahal ,X ,varargin {:}); 
return 
end


vrange =getvrange (this ); 


X =classreg .learning .internal .table2PredictMatrix (X ,[],[],...
    vrange ,this .CategoricalPredictors ,...
    getOptionalPredictorNames (this )); 

if~isfloat (X )||~ismatrix (X )
error (message ('stats:classreg:learning:classif:CompactClassificationDiscriminant:mahal:BadX' )); 
end

[N ,p ]=size (X ); 

ifp ~=numel (this .PredictorNames )
error (message ('stats:classreg:learning:classif:CompactClassificationDiscriminant:mahal:XPredictorMismatch' ,numel (this .PredictorNames ))); 
end


args ={'classlabels' }; 
defs ={[]}; 
Y =internal .stats .parseArgs (args ,defs ,varargin {:}); 


C =[]; 
if~isempty (Y )
Y =classreg .learning .internal .ClassLabel (Y ); 
C =classreg .learning .internal .classCount (this .ClassSummary .ClassNames ,Y ); 
ifsize (C ,1 )~=N 
error (message ('stats:classreg:learning:classif:CompactClassificationDiscriminant:mahal:MismatchSizeXandY' ,N )); 
end
end



K =length (this .ClassSummary .ClassNames ); 
[~,Knonempty ]=ismember (this .ClassSummary .NonzeroProbClasses ,...
    this .ClassSummary .ClassNames ); 



nanX =any (isnan (X ),2 ); 
X (nanX ,:)=[]; 
mah =NaN (size (X ,1 ),K ); 



mah (:,Knonempty )=mahal (this .Impl ,1 :numel (Knonempty ),X ); 


M =NaN (N ,K ); 
M (~nanX ,:)=mah ; 
if~isempty (C )
M =sum (M .*C ,2 ); 
end
end

function logp =logp (this ,X )












adapter =classreg .learning .internal .makeClassificationModelAdapter (this ,X ); 
if~isempty (adapter )
logp =slice (adapter ,@this .logp ,X ); 
return 
end


vrange =getvrange (this ); 


X =classreg .learning .internal .table2PredictMatrix (X ,[],[],...
    vrange ,this .CategoricalPredictors ,...
    getOptionalPredictorNames (this )); 


logP =score (this ,X ); 


maxLogP =max (logP ,[],2 ); 
P =exp (bsxfun (@minus ,logP ,maxLogP )); 


p =size (X ,2 ); 
logp =log (nansum (P ,2 ))+maxLogP -.5 *p *log (2 *pi ); 
end

function nCoeffs =nLinearCoeffs (this ,delta )














ifnargin <2 
delta =this .Delta ; 
end
nCoeffs =nLinearCoeffs (this .Impl ,delta ); 
end
end

methods (Access =protected )
function this =CompactClassificationDiscriminant (...
    dataSummary ,classSummary ,scoreTransform ,scoreType ,trained )
this =this @classreg .learning .classif .ClassificationModel (...
    dataSummary ,classSummary ,scoreTransform ,scoreType ); 
if~isempty (trained )
this .PrivBetweenSigma =trained .BetweenSigma ; 
this .Impl =trained .Impl ; 
iftrained .FillCoeffs 
this =fillCoeffs (this ); 
this =adjustConstTerms (this ); 
end
end
end

function logP =score (this ,X ,varargin )


mah =mahal (this ,X ); 


prior =this .Prior ; 
logp =bsxfun (@minus ,log (prior )-this .LogDetSigma ' /2 ,mah /2 ); 
logp (:,prior ==0 )=-Inf ; 





[N ,K ]=size (mah ); 
nanX =any (isnan (X ),2 ); 
logP =-Inf (N ,K ); 
logP (~nanX ,:)=logp (~nanX ,:); 
end

function this =setPrior (this ,prior )
this =setPrivatePrior (this ,prior ); 
this =adjustConstTerms (this ); 
end

function this =setCost (this ,cost )
this =setPrivateCost (this ,cost ); 
this =adjustConstTerms (this ); 
end

function this =setBaseDiscrimType (this ,discrimType )
this .Impl =setType (this .Impl ,discrimType ); 
end



function this =setDiscrimType (this ,discrimType )
this =setBaseDiscrimType (this ,discrimType ); 
if~isempty (this .Coeffs )
this =fillCoeffs (this ); 
this =adjustConstTerms (this ); 
end
end

function this =setBaseGamma (this ,gamma )
if~isnumeric (gamma )||~isscalar (gamma )||gamma <0 ||gamma >1 ||isnan (gamma )
error (message ('stats:classreg:learning:classif:CompactClassificationDiscriminant:setBaseGamma:BadGamma' )); 
end
this .Impl =setGamma (this .Impl ,gamma ); 
if~isempty (this .Coeffs )
this =fillCoeffs (this ); 
this =adjustConstTerms (this ); 
end
end

function this =setBaseDelta (this ,delta ,checkValidity )
if~isnumeric (delta )||~isscalar (delta )||delta <0 ||isnan (delta )
error (message ('stats:classreg:learning:classif:CompactClassificationDiscriminant:setBaseDelta:BadDelta' )); 
end
this .Impl =setDelta (this .Impl ,delta ); 





ifcheckValidity &&delta >0 
delrange =deltaRange (this .Impl ); 
ifdelta <delrange (1 )||delta >delrange (2 )
warning (message ('stats:classreg:learning:classif:CompactClassificationDiscriminant:setBaseDelta:DeltaOutOfRange' ,sprintf ('%g' ,delrange (1 )),sprintf ('%g' ,delrange (2 )))); 
end
end
if~isempty (this .Coeffs )
this =fillCoeffs (this ); 
this =adjustConstTerms (this ); 
end
end

function s =propsForDisp (this ,s )
s =propsForDisp @classreg .learning .classif .ClassificationModel (this ,s ); 
s .DiscrimType =this .DiscrimType ; 
s .Mu =this .Mu ; 
s .Coeffs =this .Coeffs ; 
end








function this =adjustConstTerms (this )


ifisempty (this .Coeffs )
return ; 
end


[~,Knonempty ]=ismember (this .ClassSummary .NonzeroProbClasses ,...
    this .ClassSummary .ClassNames ); 
Knonempty =Knonempty (:)' ; 
pairs =combnk (Knonempty ,2 )' ; 
npairs =size (pairs ,2 ); 


prior =this .Prior (Knonempty ); 
cost =this .Cost (Knonempty ,Knonempty ); 


fork =1 :npairs 
i =pairs (1 ,k ); 
j =pairs (2 ,k ); 

this .Coeffs (i ,j ).Const =-constantTerm (this .Impl ,i ,j )...
    +log (prior (i ))-log (prior (j ))...
    +log (cost (i ,j ))-log (cost (j ,i )); 
this .Coeffs (j ,i ).Const =-this .Coeffs (i ,j ).Const ; 
end
end




function this =fillCoeffs (this )
nonzeroclasses =this .ClassSummary .NonzeroProbClasses ; 
K =length (nonzeroclasses ); 
p =numel (this .PredictorNames ); 
[~,Knonempty ]=ismember (nonzeroclasses ,this .ClassSummary .ClassNames ); 
Knonempty =Knonempty (:)' ; 


isquadratic =contains (this .DiscrimType ,'quadratic' ,'IgnoreCase' ,true ); 


s =struct ('DiscrimType' ,this .DiscrimType ,'Const' ,[],'Linear' ,[]); 
ifisquadratic 
s .Quadratic =[]; 
end
coeffs =repmat (s ,K ,K ); 
s .DiscrimType ='' ; 
coeffs (1 :K +1 :end)=s ; 


pairs =combnk (Knonempty ,2 )' ; 
npairs =size (pairs ,2 ); 


C =zeros (1 ,npairs ); 
L =zeros (p ,npairs ); 
if~strcmpi (this .DiscrimType ,'diagquadratic' )
Q =zeros (p ,p ,npairs ); 
else
Q =zeros (1 ,p ,npairs ); 
end

forj =1 :npairs 
i1 =pairs (1 ,j ); 
i2 =pairs (2 ,j ); 
C (j )=constantTerm (this .Impl ,i1 ,i2 ); 
L (:,j )=linearCoeffs (this .Impl ,i1 ,i2 ); 
ifisquadratic 
Q (:,:,j )=quadraticCoeffs (this .Impl ,i1 ,i2 ); 
end
end


fork =1 :npairs 
i =pairs (1 ,k ); 
j =pairs (2 ,k ); 

coeffs (i ,j ).Const =-C (k ); 
coeffs (i ,j ).Linear =L (:,k ); 

coeffs (j ,i ).Const =C (k ); 
coeffs (j ,i ).Linear =-L (:,k ); 

ifisquadratic 
coeffs (i ,j ).Quadratic =Q (:,:,k ); 
coeffs (j ,i ).Quadratic =-Q (:,:,k ); 
end

coeffs (i ,j ).Class1 =labels (nonzeroclasses (i )); 
coeffs (i ,j ).Class2 =labels (nonzeroclasses (j )); 
coeffs (j ,i ).Class1 =labels (nonzeroclasses (j )); 
coeffs (j ,i ).Class2 =labels (nonzeroclasses (i )); 
end

fork =1 :K 
coeffs (k ,k ).Class1 =labels (nonzeroclasses (k )); 
coeffs (k ,k ).Class2 =labels (nonzeroclasses (k )); 
end


this .Coeffs =coeffs ; 
end
end

methods (Static ,Hidden )
function this =loadobj (obj )
ifisempty (obj .Impl )

trained .BetweenSigma =obj .PrivBetweenSigma ; 
trained .FillCoeffs =~isempty (obj .Coeffs ); 
isquadratic =contains (obj .PrivDiscrimType ,'quadratic' ,'IgnoreCase' ,true ); 
ifisquadratic 
trained .Impl =...
    classreg .learning .impl .QuadraticDiscriminantImpl (...
    obj .PrivDiscrimType ,obj .D ,obj .S ,obj .V ,0 ,0 ,obj .Mu ,...
    ones (size (obj .Mu ,1 ),1 ),false ); 
else
trained .Impl =...
    classreg .learning .impl .LinearDiscriminantImpl (...
    obj .PrivDiscrimType ,obj .D ,obj .S ,obj .V ,0 ,0 ,obj .Mu ,...
    ones (size (obj .Mu ,1 ),1 ),false ); 
end
this =classreg .learning .classif .CompactClassificationDiscriminant (...
    obj .DataSummary ,obj .ClassSummary ,obj .PrivScoreTransform ,[],...
    trained ); 
else

this =obj ; 
end
end

function this =makesvd (param ,mu ,s ,v ,d ,classSummary ,dataSummary )

ifcontains (param .DiscrimType ,'linear' ,'IgnoreCase' ,true )
trained .Impl =...
    classreg .learning .impl .LinearDiscriminantImpl (...
    param .DiscrimType ,d ,s ,v ,0 ,0 ,mu ,classSummary .Prior ,false ); 
else
trained .Impl =...
    classreg .learning .impl .QuadraticDiscriminantImpl (...
    param .DiscrimType ,d ,s ,v ,0 ,0 ,mu ,classSummary .Prior ,false ); 
end
trained .BetweenSigma =[]; 
trained .FillCoeffs =param .FillCoeffs ; 
scoreTransform =@classreg .learning .transform .identity ; 

this =classreg .learning .classif .CompactClassificationDiscriminant (...
    dataSummary ,classSummary ,scoreTransform ,[],trained ); 

end
end
methods (Static ,Hidden )
function obj =fromStruct (s )


s .ScoreTransform =s .ScoreTransformFull ; 
s .DefaultLoss =s .DefaultLossFull ; 

s =classreg .learning .coderutils .structToClassif (s ); 


ifcontains (s .DiscrimType ,'quadratic' ,'IgnoreCase' ,true )
impl =classreg .learning .impl .QuadraticDiscriminantImpl .fromStruct (s .Impl ); 
else
impl =classreg .learning .impl .LinearDiscriminantImpl .fromStruct (s .Impl ); 
end

trained =struct ; 
trained .Impl =impl ; 
trained .BetweenSigma =s .BetweenSigma ; 
trained .FillCoeffs =s .FillCoeffs ; 


obj =classreg .learning .classif .CompactClassificationDiscriminant (...
    s .DataSummary ,s .ClassSummary ,s .ScoreTransform ,s .ScoreType ,trained ); 

end
end

methods (Hidden )
function s =toStruct (this )


warnState =warning ('query' ,'all' ); 
warning ('off' ,'MATLAB:structOnObject' ); 
cleanupObj =onCleanup (@()warning (warnState )); 
fh =functions (this .PrivScoreTransform ); 
ifstrcmpi (fh .type ,'anonymous' )
error (message ('stats:classreg:learning:coderutils:classifToStruct:AnonymousFunctionsNotSupported' ,'Score Transform' )); 
end

fh =functions (this .DefaultLoss ); 
ifstrcmpi (fh .type ,'anonymous' )
error (message ('stats:classreg:learning:coderutils:classifToStruct:AnonymousFunctionsNotSupported' ,'Loss' )); 
end


s =classreg .learning .coderutils .classifToStruct (this ); 

s .ScoreTransformFull =s .ScoreTransform ; 
scoretransformfull =strsplit (s .ScoreTransform ,'.' ); 
scoretransform =scoretransformfull {end}; 
s .ScoreTransform =scoretransform ; 



transFcn =['classreg.learning.transform.' ,s .ScoreTransform ]; 
transFcnCG =['classreg.learning.coder.transform.' ,s .ScoreTransform ]; 
ifisempty (which (transFcn ))||isempty (which (transFcnCG ))
s .CustomScoreTransform =true ; 
else
s .CustomScoreTransform =false ; 
end

s .DefaultLossFull =s .DefaultLoss ; 
defaultlossfull =strsplit (s .DefaultLoss ,'.' ); 
defaultloss =defaultlossfull {end}; 
s .DefaultLoss =defaultloss ; 


s .DiscrimType =lower (this .DiscrimType ); 

s .BetweenSigma =this .PrivBetweenSigma ; 
s .FillCoeffs =~isempty (this .Coeffs ); 

try
classreg .learning .internal .convertScoreTransform (this .PrivScoreTransform ,'handle' ,numel (this .ClassSummary .ClassNames )); 
catch me 
rethrow (me ); 
end


s .FromStructFcn ='classreg.learning.classif.CompactClassificationDiscriminant.fromStruct' ; 

impl =this .Impl ; 
s .Impl =toStruct (impl ); 
end
end
methods (Hidden ,Static )
function name =matlabCodegenRedirect (~)
name ='classreg.learning.coder.classif.CompactClassificationDiscriminant' ; 
end
end

end
