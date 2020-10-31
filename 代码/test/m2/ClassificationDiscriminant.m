classdef ClassificationDiscriminant <...
    classreg .learning .classif .FullClassificationModel &...
    classreg .learning .classif .CompactClassificationDiscriminant 



































































properties (GetAccess =public ,SetAccess =protected ,Dependent =true )







XCentered ; 
end

methods 
function x =get .XCentered (this )
gidx =grp2idx (this .PrivY ,this .ClassSummary .ClassNames ); 
x =this .PrivX -this .Mu (gidx ,:); 
end
end

methods (Static ,Hidden )
function temp =template (varargin )
classreg .learning .FitTemplate .catchType (varargin {:}); 
temp =classreg .learning .FitTemplate .make ('Discriminant' ,'type' ,'classification' ,varargin {:}); 
end

function this =fit (X ,Y ,varargin )

args ={'prior' ,'cost' }; 
defs ={[],[]}; 
[prior ,cost ,~,fitArgs ]=...
    internal .stats .parseArgs (args ,defs ,varargin {:}); 


temp =classreg .learning .FitTemplate .make (...
    'Discriminant' ,'type' ,'classification' ,fitArgs {:}); 
this =fit (temp ,X ,Y ); 


this .LabelPredictor =@classreg .learning .classif .ClassificationModel .minCost ; 


if~isempty (prior )&&~strncmpi (prior ,'empirical' ,length (prior ))
this .Prior =prior ; 
end
if~isempty (cost )
this .Cost =cost ; 
end
end

function this =make (mu ,sigma ,varargin )

if~isnumeric (mu )||~isnumeric (sigma )
error (message ('stats:ClassificationDiscriminant:make:MuSigmaNotNumeric' )); 
end


if~ismatrix (mu )||ndims (sigma )>3 
error (message ('stats:ClassificationDiscriminant:make:MuSigmaBadSize' )); 
end


[K ,p ]=size (mu ); 
ifismatrix (sigma )
if~all (size (sigma )==[p ,p ])
error (message ('stats:ClassificationDiscriminant:make:SizeLDASigmaMismatch' )); 
end
else
if~all (size (sigma )==[p ,p ,K ])
error (message ('stats:ClassificationDiscriminant:make:SizeQDASigmaMismatch' )); 
end
end


ifany (isnan (mu (:)))||any (isnan (sigma (:)))
error (message ('stats:ClassificationDiscriminant:make:MuSigmaWithNaNs' )); 
end


ifismatrix (sigma )
if~all (all (abs (sigma -sigma ' )<p *eps (max (abs (diag (sigma ))))))
error (message ('stats:ClassificationDiscriminant:make:PooledInSigmaNotSymmetric' )); 
end
else
fork =1 :K 
if~all (all (abs (sigma (:,:,k )-sigma (:,:,k )' )<p *eps (max (abs (diag (sigma (:,:,k )))))))
error (message ('stats:ClassificationDiscriminant:make:ClassSigmaNotSymmetric' ,k )); 
end
end
end


args ={'betweensigma' ,'classnames' ,'predictornames' ...
    ,'responsename' ,'prior' ,'cost' ,'fillcoeffs' }; 
defs ={[],[],{}...
    ,'' ,[],[],'on' }; 
[betweenSigma ,classnames ,predictornames ,responsename ,prior ,cost ,fillCoeffs ]=...
    internal .stats .parseArgs (args ,defs ,varargin {:}); 


if~isempty (betweenSigma )
if~isnumeric (betweenSigma )||~ismatrix (betweenSigma )...
    ||~all (size (betweenSigma )==[p ,p ])
error (message ('stats:ClassificationDiscriminant:make:BadBetweenSigma' ,p ,p )); 
end
if~all (all (abs (betweenSigma -betweenSigma ' )<max (K ,p )*eps (max (abs (diag (betweenSigma ))))))
error (message ('stats:ClassificationDiscriminant:make:BetweenSigmaNotSymmetric' )); 
end
betweenSigma =(betweenSigma +betweenSigma ' )/2 ; 
d =eig (betweenSigma ); 
ifany (d <0 &abs (d )>max (K ,p )*eps (max (d )))
error (message ('stats:ClassificationDiscriminant:make:BetweenSigmaNotPosSemiDefinite' )); 
end
d (d <10 *max (K ,p )*eps (max (d )))=0 ; 
r =sum (d >0 ); 
ifr >K -1 
error (message ('stats:ClassificationDiscriminant:make:RankBetweenSigmaTooLarge' ,r ,K -1 ,K )); 
end
end


ifisempty (classnames )
classnames =1 :K ; 
end
classnames =classreg .learning .internal .ClassLabel (classnames ); 
ifnumel (classnames )~=K 
error (message ('stats:ClassificationDiscriminant:make:ClassNamesSizeMismatch' ,K )); 
end


ifisempty (predictornames )
predictornames =classreg .learning .internal .defaultPredictorNames (p ); 
else
if~iscellstr (predictornames )
if~ischar (predictornames )
error (message ('stats:ClassificationDiscriminant:make:BadPredictorType' )); 
end
predictornames =cellstr (predictornames ); 
end
iflength (predictornames )~=p 
error (message ('stats:ClassificationDiscriminant:make:PredictorMismatch' ,p )); 
end
end
predictornames =predictornames (:)' ; 


ifisempty (responsename )
responsename ='Y' ; 
else
if~ischar (responsename )
error (message ('stats:ClassificationDiscriminant:make:BadResponseName' )); 
end
end


if~isempty (prior )&&ischar (prior )...
    &&strncmpi (prior ,'empirical' ,length (prior ))
error (message ('stats:ClassificationDiscriminant:make:EmpiricalPriorNotAllowed' )); 
end
prior =classreg .learning .classif .FullClassificationModel .processPrior (...
    prior ,ones (1 ,K ),classnames ,classnames ); 
prior =prior /sum (prior ); 
cost =classreg .learning .classif .FullClassificationModel .processCost (...
    cost ,prior ,classnames ,classnames ); 


if~ischar (fillCoeffs )||...
    ~(strcmpi (fillCoeffs ,'on' )||strcmpi (fillCoeffs ,'off' ))
error (message ('stats:ClassificationDiscriminant:make:BadFillCoeffs' )); 
end
fillCoeffs =strcmpi (fillCoeffs ,'on' ); 


isquadratic =~ismatrix (sigma ); 
ifisquadratic 
d =zeros (1 ,p ,K ); 
s =cell (K ,1 ); 
v =cell (K ,1 ); 
fork =1 :K 
[s {k },v {k },d (1 ,:,k )]=...
    classreg .learning .classif .CompactClassificationDiscriminant .decompose (sigma (:,:,k )); 
end
discrimType ='quadratic' ; 
ifany (d (:)==0 )
discrimType ='pseudoQuadratic' ; 
else
fork =1 :K 
ifany (s {k }==0 )
discrimType ='pseudoQuadratic' ; 
end
end
end
else
[s ,v ,d ]=classreg .learning .classif .CompactClassificationDiscriminant .decompose (sigma ); 
discrimType ='linear' ; 
ifany (s ==0 )||any (d ==0 )
discrimType ='pseudoLinear' ; 
end
end


dataSummary .PredictorNames =predictornames ; 
dataSummary .CategoricalPredictors =[]; 
dataSummary .ResponseName =responsename ; 
dataSummary .VariableRange ={}; 
dataSummary .TableInput =false ; 
classSummary .ClassNames =classnames ; 
classSummary .NonzeroProbClasses =classnames ; 
classSummary .Prior =prior ; 
classSummary .Cost =cost ; 
scoreTransform =@classreg .learning .transform .identity ; 
ifisquadratic 
trained .Impl =...
    classreg .learning .impl .QuadraticDiscriminantImpl (...
    discrimType ,d ,s ,v ,0 ,0 ,mu ,ones (K ,1 ),false ); 
else
trained .Impl =...
    classreg .learning .impl .LinearDiscriminantImpl (...
    discrimType ,d ,s ,v ,0 ,0 ,mu ,ones (K ,1 ),false ); 
end
trained .BetweenSigma =betweenSigma ; 
trained .FillCoeffs =fillCoeffs ; 
this =classreg .learning .classif .CompactClassificationDiscriminant (...
    dataSummary ,classSummary ,scoreTransform ,[],trained ); 
end
end

methods (Hidden )
function this =ClassificationDiscriminant (X ,Y ,W ,modelParams ,...
    dataSummary ,classSummary ,scoreTransform )

ifnargin ~=7 ||ischar (W )
error (message ('stats:ClassificationDiscriminant:ClassificationDiscriminant:DoNotUseConstructor' )); 
end









if~isempty (dataSummary .CategoricalPredictors )
error (message ('stats:ClassificationDiscriminant:ClassificationDiscriminant:CategPred' )); 
end


if~isfloat (X )
error (message ('stats:ClassificationDiscriminant:ClassificationDiscriminant:BadXType' )); 
end


this =this @classreg .learning .classif .FullClassificationModel (...
    X ,Y ,W ,modelParams ,dataSummary ,classSummary ,scoreTransform ); 
this =this @classreg .learning .classif .CompactClassificationDiscriminant (...
    dataSummary ,classSummary ,scoreTransform ,[],[]); 


discrimType =this .ModelParams .DiscrimType ; 
ifcontains (discrimType ,'linear' ,'IgnoreCase' ,true )
isquadratic =false ; 
else
isquadratic =true ; 
end


classHasWeight =...
    ismember (this .ClassSummary .ClassNames ,this .ClassSummary .NonzeroProbClasses ); 
if~all (classHasWeight )
classname =cellstr (this .ClassSummary .ClassNames (find (~classHasWeight ,1 ))); 
error (message ('stats:ClassificationDiscriminant:ClassificationDiscriminant:ZeroWeightClassNotAllowed' ,classname {1 })); 
end


gidx =grp2idx (this .PrivY ,this .ClassSummary .NonzeroProbClasses ); 
K =numel (this .ClassSummary .NonzeroProbClasses ); 
p =size (this .PrivX ,2 ); 
gmeans =NaN (K ,p ); 
fork =1 :K 
gmeans (k ,:)=classreg .learning .internal .wnanmean (this .PrivX (gidx ==k ,:),this .W (gidx ==k )); 
idxnan =find (isnan (gmeans (k ,:)),1 ); 
if~isempty (idxnan )
classname =cellstr (this .ClassSummary .NonzeroProbClasses (k )); 
error (message ('stats:ClassificationDiscriminant:ClassificationDiscriminant:NaNPredictor' ,idxnan ,classname {1 })); 
end
end



W =this .W ; 
ifisquadratic 
D =zeros (1 ,p ,K ); 
invD =zeros (1 ,p ,K ); 
fork =1 :K 
d =sqrt (classreg .learning .internal .wnanvar (this .PrivX (gidx ==k ,:),W (gidx ==k ),0 )); 
badD =(d <=sum (gidx ==k )*eps (max (d )))|isnan (d ); 
d (badD )=0 ; 
ifstrcmpi (discrimType ,'quadratic' )&&any (d ==0 )
classname =cellstr (this .ClassSummary .ClassNames (k )); 
error (message ('stats:ClassificationDiscriminant:ClassificationDiscriminant:ZeroDiagCovQuad' ,this .PredictorNames {find (d ==0 ,1 )},classname {1 })); 
end
D (1 ,:,k )=d ; 
invD (1 ,:,k )=1 ./d ; 
invD (1 ,badD ,k )=0 ; 
end
else
D =sqrt (classreg .learning .internal .wnanvar (this .PrivX -gmeans (gidx ,:),W ,0 )); 
badD =(D <=numel (W )*eps (max (D )))|isnan (D ); 
D (badD )=0 ; 
ifstrcmpi (discrimType ,'linear' )&&any (D ==0 )
error (message ('stats:ClassificationDiscriminant:ClassificationDiscriminant:ZeroDiagCovLin' ,this .PredictorNames {find (D ==0 ,1 )})); 
end
invD =1 ./D ; 
invD (badD )=0 ; 
end


nanX =any (isnan (this .PrivX ),2 ); 
ifany (nanX )
this .PrivX (nanX ,:)=[]; 
this .PrivY (nanX )=[]; 
this .W (nanX )=[]; 
rowsused =this .DataSummary .RowsUsed ; 
ifisempty (rowsused )
rowsused =~nanX ; 
else
rowsused (rowsused )=~nanX ; 
end
this .DataSummary .RowsUsed =rowsused ; 
end
ifisempty (this .PrivX )
error (message ('stats:ClassificationDiscriminant:ClassificationDiscriminant:NoDataAfterNaNsRemoved' )); 
end
ifany (any (~isfinite (this .PrivX )))
error (message ('stats:ClassificationDiscriminant:ClassificationDiscriminant:InfPredictor' )); 
end


this .W =this .W /sum (this .W ); 


nonzeroClassNames =this .ClassSummary .NonzeroProbClasses ; 
prior =this .ClassSummary .Prior ; 
cost =this .ClassSummary .Cost ; 
ifisempty (cost )
K =numel (nonzeroClassNames ); 
cost =ones (K )-eye (K ); 
end


C =classreg .learning .internal .classCount (nonzeroClassNames ,this .PrivY ); 
WC =bsxfun (@times ,C ,this .W ); 
Wj =sum (WC ,1 ); 
gmeans (Wj ==0 ,:)=[]; 



[this .PrivX ,this .PrivY ,C ,WC ,Wj ,prior ,cost ,nonzeroClassNames ]=...
    classreg .learning .classif .FullClassificationModel .removeZeroPriorAndCost (...
    this .PrivX ,this .PrivY ,C ,WC ,Wj ,prior ,cost ,nonzeroClassNames ); 




prior =prior /sum (prior ); 
WC =bsxfun (@times ,WC ,prior ./Wj ); 
this .W =sum (WC ,2 ); 


W =this .W ; 
Wj =prior ; 
Wj2 =sum (WC .^2 ,1 ); 
gidx =grp2idx (this .PrivY ,nonzeroClassNames ); 
K =numel (Wj ); 


this .ClassSummary =...
    classreg .learning .classif .FullClassificationModel .makeClassSummary (...
    this .ClassSummary .ClassNames ,nonzeroClassNames ,prior ,cost ); 


N =this .NumObservations ; 
ifN <=K &&~isquadratic 
error (message ('stats:ClassificationDiscriminant:ClassificationDiscriminant:TooFewObsForLinear' )); 
end



ifisquadratic 
gsize =sum (C ,1 ); 
idx =find (gsize <2 ,1 ); 
if~isempty (idx )
classname =cellstr (this .ClassSummary .NonzeroProbClasses (idx )); 
error (message ('stats:ClassificationDiscriminant:ClassificationDiscriminant:TooFewObsForQuad' ,classname {1 })); 
end



WC =bsxfun (@rdivide ,WC ,Wj ); 
W =sum (WC ,2 ); 
Wj2 =sum (WC .^2 ,1 ); 
end
C =[]; %#ok<NASGU> 
WC =[]; %#ok<NASGU> 


gamma =this .ModelParams .Gamma ; 
delta =this .ModelParams .Delta ; 












ifisquadratic 
S =cell (K ,1 ); 
V =cell (K ,1 ); 
fork =1 :K 
[~,s ,v ]=svd (bsxfun (@times ,...
    bsxfun (@times ,...
    bsxfun (@minus ,this .PrivX (gidx ==k ,:),gmeans (k ,:)),...
    sqrt (W (gidx ==k ))),...
    invD (1 ,:,k )),'econ' ); 
s =diag (s ); 
bads =abs (s )<max (gsize (k ),p )*eps (max (abs (s ))); 
s (bads )=0 ; 
S {k }=s ; 
biasCorr =sqrt (1 -Wj2 (k )); 
D (1 ,:,k )=D (1 ,:,k )/biasCorr ; 
V {k }=v ; 
end
else
[~,S ,V ]=svd (bsxfun (@times ,bsxfun (@times ,this .PrivX -gmeans (gidx ,:),sqrt (W )),invD ),'econ' ); 
S =diag (S ); 
badS =abs (S )<max (N ,p )*eps (max (abs (S ))); 
S (badS )=0 ; 
biasCorr =sqrt (1 -sum (Wj2 ./Wj )); 
D =D /biasCorr ; 
end























ifisquadratic 
this .Impl =classreg .learning .impl .QuadraticDiscriminantImpl (...
    discrimType ,D ,S ,V ,gamma ,delta ,gmeans ,Wj ' ,this .ModelParams .SaveMemory ); 
else
this .Impl =classreg .learning .impl .LinearDiscriminantImpl (...
    discrimType ,D ,S ,V ,gamma ,delta ,gmeans ,Wj ' ,this .ModelParams .SaveMemory ); 
end


ifthis .ModelParams .FillCoeffs 
this =fillCoeffs (this ); 
this =adjustConstTerms (this ); 
end
end

function this =setGamma (this ,gamma )
this =setBaseGamma (this ,gamma ); 
this .ModelParams .Gamma =this .Impl .Gamma ; 
this .ModelParams .DiscrimType =this .Impl .Type ; 
end

function this =setDelta (this ,delta ,checkValidity )
ifnargin <3 
checkValidity =true ; 
end
this =setBaseDelta (this ,delta ,checkValidity ); 
this .ModelParams .Delta =this .Impl .Delta ; 
this .ModelParams .DiscrimType =this .Impl .Type ; 
end
end

methods (Access =protected )
function s =propsForDisp (this ,s )
s =propsForDisp @classreg .learning .classif .FullClassificationModel (this ,s ); 
s =propsForDisp @classreg .learning .classif .CompactClassificationDiscriminant (this ,s ); 
end

function this =setDiscrimType (this ,mode )



mode =convertStringsToChars (mode ); 
this =setBaseDiscrimType (this ,mode ); 
if~isempty (this .Coeffs )
this =fillCoeffs (this ); 
this =adjustConstTerms (this ); 
end
this .ModelParams .Gamma =this .Impl .Gamma ; 
this .ModelParams .Delta =this .Impl .Delta ; 
this .ModelParams .DiscrimType =this .Impl .Type ; 
end
end

methods 
function partModel =crossval (this ,varargin )





























[varargin {:}]=convertStringsToChars (varargin {:}); 

forbiddenArgs =[classreg .learning .FitTemplate .AllowedBaseFitObjectArgs ...
    ,{'discrimtype' ,'fillcoeffs' }]; 
idxBaseArg =find (ismember (lower (varargin (1 :2 :end)),forbiddenArgs )); 
if~isempty (idxBaseArg )
error (message ('stats:ClassificationDiscriminant:crossval:NoBaseArgs' ,...
    varargin {2 *idxBaseArg -1 })); 
end


args ={'savememory' }; 
defs ={'' }; 
[savememory ,~,extraArgs ]=internal .stats .parseArgs (args ,defs ,varargin {:}); 
if~isempty (savememory )
if~ischar (savememory )||(~strcmpi (savememory ,'on' )&&~strcmpi (savememory ,'off' ))
error (message ('stats:ClassificationDiscriminant:crossval:BadSaveMemory' )); 
end
savememory =strcmpi (savememory ,'on' ); 
end


modelparams =this .ModelParams ; 
modelparams .FillCoeffs =false ; 
if~isempty (savememory )
modelparams .SaveMemory =savememory ; 
end
temp =classreg .learning .FitTemplate .make (this .ModelParams .Method ,...
    'type' ,'classification' ,'scoretransform' ,this .PrivScoreTransform ,...
    'modelparams' ,modelparams ,'CrossVal' ,'on' ,extraArgs {:}); 




partModel =fit (temp ,this .X ,this .Y ,'Weights' ,this .W ,...
    'predictornames' ,this .DataSummary .PredictorNames ,...
    'responsename' ,this .ResponseName ,'classnames' ,this .ClassNames ); 
partModel .ScoreType =this .ScoreType ; 





partModel .Prior =this .Prior ; 
partModel .Cost =this .Cost ; 
end

function cmp =compact (this )









dataSummary =this .DataSummary ; 
dataSummary .RowsUsed =[]; 
trained =struct ('Impl' ,this .Impl ,...
    'BetweenSigma' ,[],'FillCoeffs' ,this .ModelParams .FillCoeffs ); 
cmp =classreg .learning .classif .CompactClassificationDiscriminant (...
    dataSummary ,this .ClassSummary ,...
    this .PrivScoreTransform ,this .PrivScoreType ,trained ); 
end

function [mcr ,gamma ,delta ,npred ]=cvshrink (this ,varargin )
























































































[varargin {:}]=convertStringsToChars (varargin {:}); 

args ={'gamma' ,'NumGamma' ,'delta' ,'NumDelta' ,'Verbose' }; 
defs ={[],10 ,0 ,[],0 }; 
[gamma ,ngamma ,delta ,ndelta ,verbose ,~,extraArgs ]=...
    internal .stats .parseArgs (args ,defs ,varargin {:}); 


if~isnumeric (verbose )||~isscalar (verbose )||verbose <0 
error (message ('stats:ClassificationDiscriminant:cvshrink:BadPrint' )); 
end
verbose =ceil (verbose ); 


[~,partitionArgs ,extraArgs ]=...
    classreg .learning .generator .Partitioner .processArgs (extraArgs {:},'CrossVal' ,'on' ); 
if~isempty (extraArgs )
error (message ('stats:ClassificationDiscriminant:cvshrink:TooManyOptionalArgs' )); 
end

C =classreg .learning .internal .classCount (this .ClassSummary .ClassNames ,this .PrivY ); 
cost =this .Cost ; 


cv =crossval (this ,'savememory' ,'on' ,partitionArgs {:}); 
ifverbose >0 
fprintf (1 ,'%s\n' ,getString (message ('stats:ClassificationDiscriminant:cvshrink_DoneCrossvalidating' ))); 
end
trained =cv .Trained ; 
oot =~cv .ModelParams .Generator .UseObsForIter ; 
T =numel (trained ); 
cv =[]; %#ok<NASGU> 


ifisempty (gamma )
ifisempty (ngamma )||~isnumeric (ngamma )||~isscalar (ngamma )||ngamma <=0 
error (message ('stats:ClassificationDiscriminant:cvshrink:BadNGamma' )); 
end
ngamma =ceil (ngamma ); 
mingam =zeros (T ,1 ); 
fort =1 :T 
mingam (t )=trained {t }.MinGamma ; 
end
mingam =max (mingam ); 
gamma =linspace (mingam ,1 ,ngamma +1 ); 
elseif~isnumeric (gamma )||~isvector (gamma )||any (gamma <0 )||any (gamma >1 )
error (message ('stats:ClassificationDiscriminant:cvshrink:BadGamma' )); 
end
gamma =sort (gamma ); 
Ngamma =numel (gamma ); 
gamma =gamma (:); 


ifisempty (delta )||~isempty (ndelta )
ifisempty (ndelta )||~isnumeric (ndelta )||~isscalar (ndelta )||ndelta <0 
error (message ('stats:ClassificationDiscriminant:cvshrink:BadNDelta' )); 
end
ndelta =ceil (ndelta ); 


delta =zeros (Ngamma ,ndelta +1 ); 
forngam =1 :Ngamma 
maxDelta =max (deltaRange (this .Impl ,gamma (ngam ))); 
delta (ngam ,:)=linspace (0 ,maxDelta ,ndelta +1 ); 
end



delta (:,end)=delta (:,end)+10 *eps (delta (:,end)); 
else
if~isnumeric (delta )||~ismatrix (delta )||any (delta (:)<0 )
error (message ('stats:ClassificationDiscriminant:cvshrink:BadDelta' )); 
end


ifsize (delta ,1 )==1 
delta =repmat (delta ,Ngamma ,1 ); 
else
ifsize (delta ,1 )~=Ngamma 
error (message ('stats:ClassificationDiscriminant:cvshrink:DeltaSizeMismatch' ,Ngamma )); 
end
end
end


Ndelta =size (delta ,2 ); 
K =numel (this .ClassSummary .ClassNames ); 
[N ,p ]=size (this .X ); 
mcr =NaN (Ngamma ,Ndelta ); 


dopred =nargout >3 &&any (delta (:)>0 )...
    &&contains (this .Impl .Type ,'linear' ,'IgnoreCase' ,true ); 
npred =repmat (p ,Ngamma ,Ndelta ); 


forngam =1 :Ngamma 
ifverbose >0 
fprintf (1 ,'%s\n' ,getString (message ('stats:ClassificationDiscriminant:cvshrink_ProcessingGamma' ,ngam ,Ngamma ))); 
end




ifdopred 
this =setGamma (this ,gamma (ngam )); 
end
fort =1 :T 
trained {t }=setGamma (trained {t },gamma (ngam )); 
end









Sfit =NaN (N ,K ,Ndelta ); 
fort =1 :T 
ifverbose >1 
fprintf (1 ,'\t\t %s\n' ,getString (message ('stats:ClassificationDiscriminant:cvshrink_ProcessingFold' ,t ))); 
end
ifany (delta (:)>0 )
oldSaveMemory =trained {t }.Impl .SaveMemory ; 
trained {t }.Impl .SaveMemory =false ; 
end
forndel =1 :Ndelta 
trained {t }=setDelta (trained {t },delta (ngam ,ndel ),false ); 
[~,Sfit (oot (:,t ),:,ndel )]=predict (trained {t },this .X (oot (:,t ),:)); 
end
ifany (delta (:)>0 )
trained {t }.Impl .SaveMemory =oldSaveMemory ; 
end
end





ifdopred 
npred (ngam ,:)=nLinearCoeffs (this ,delta (ngam ,:)); 
end
forndel =1 :Ndelta 
mcr (ngam ,ndel )=classreg .learning .loss .mincost (C ,Sfit (:,:,ndel ),this .W ,cost ); 
end
end
end
end

methods (Static ,Hidden )
function this =loadobj (obj )
ifisempty (obj .Impl )

modelParams =fillDefaultParams (obj .ModelParams ,...
    obj .X ,obj .PrivY ,obj .W ,obj .DataSummary ,obj .ClassSummary ); 
this =ClassificationDiscriminant (obj .X ,obj .PrivY ,obj .W ,...
    modelParams ,obj .DataSummary ,obj .ClassSummary ,...
    obj .PrivScoreTransform ); 
else

this =obj ; 
end
end
end

end
