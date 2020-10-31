classdef (Abstract )LinearLikeMixedModel <classreg .regr .ParametricRegression 










properties (Constant =true ,Hidden =true )


AllowedDummyVarCodings ={'reference' ,'referencelast' ,'effects' ,...
    'full' ,'difference' ,'backwardDifference' }; 



AllowedCovariancePatterns ={classreg .regr .lmeutils .covmats .CovarianceMatrix .TYPE_FULL ,...
    classreg .regr .lmeutils .covmats .CovarianceMatrix .TYPE_FULLCHOLESKY ,...
    classreg .regr .lmeutils .covmats .CovarianceMatrix .TYPE_DIAGONAL ,...
    classreg .regr .lmeutils .covmats .CovarianceMatrix .TYPE_ISOTROPIC ,...
    classreg .regr .lmeutils .covmats .CovarianceMatrix .TYPE_COMPSYMM ,...
    classreg .regr .lmeutils .covmats .CovarianceMatrix .TYPE_FIXEDWEIGHTS ,...
    classreg .regr .lmeutils .covmats .CovarianceMatrix .TYPE_PATTERNED }; 
end


properties (Access ={?classreg .regr .LinearLikeMixedModel })




y 











FixedInfo 






















RandomInfo 
























GroupingInfo 




slme 
end


methods (Access ={?classreg .regr .LinearLikeMixedModel })

function y =extractResponse (model ,ds )





responseName =model .Formula .ResponseName ; 
y =ds .(responseName ); 


assertThat (isnumeric (y )&isreal (y )&isvector (y ),'stats:LinearMixedModel:BadResponseVar' ,responseName ); 

end

function FixedInfo =extractFixedInfo (model ,ds )














[FixedInfo .X ,FixedInfo .XColNames ,FixedInfo .XCols2Terms ]=...
    createDesignMatrix (model ,ds ,model .Formula .FELinearFormula ); 

end

function RandomInfo =extractRandomInfo (model ,ds )














R =length (model .Formula .RELinearFormula ); 
RandomInfo .Z =cell (R ,1 ); 
RandomInfo .ZColNames =cell (R ,1 ); 
RandomInfo .q =zeros (R ,1 ); 
fori =1 :R 
[RandomInfo .Z {i },RandomInfo .ZColNames {i },~]=...
    createDesignMatrix (model ,ds ,model .Formula .RELinearFormula {i }); 
RandomInfo .q (i )=size (RandomInfo .Z {i },2 ); 
end

end

function GroupingInfo =extractGroupingInfo (model ,ds )




























R =length (model .Formula .RELinearFormula ); 
G =cell (R ,1 ); 
GNames =cell (R ,1 ); 
fori =1 :R 

interactionVars =model .Formula .GroupingVariableNames {i }; 


[G {i },GNames {i }]=...
    model .makeInteractionVar (ds ,interactionVars ); 
end


Gid =cell (R ,1 ); 
GidLevelNames =cell (R ,1 ); 
lev =zeros (R ,1 ); 
fori =1 :R 
[Gid {i },GidLevelNames {i }]=grp2idx (G {i }); 
lev (i )=length (GidLevelNames {i }); 

end


GroupingInfo .R =R ; 
GroupingInfo .G =G ; 
GroupingInfo .GNames =GNames ; 
GroupingInfo .Gid =Gid ; 
GroupingInfo .GidLevelNames =GidLevelNames ; 
GroupingInfo .lev =lev ; 

end

function Psi =makeCovarianceMatrix (model )











R =model .GroupingInfo .R ; 
covariancepattern =model .CovariancePattern ; 
assert (R ==length (covariancepattern )); 
mat =cell (R ,1 ); 
fori =1 :R 




ifislogical (covariancepattern {i })
mat {i }=classreg .regr .lmeutils .covmats .CovarianceMatrix .createCovariance (classreg .regr .lmeutils .covmats .CovarianceMatrix .TYPE_PATTERNED ,...
    model .RandomInfo .q (i ),'Name' ,model .GroupingInfo .GNames {i },...
    'VariableNames' ,model .RandomInfo .ZColNames {i },'CovariancePattern' ,covariancepattern {i }); 
else
mat {i }=classreg .regr .lmeutils .covmats .CovarianceMatrix .createCovariance (covariancepattern {i },...
    model .RandomInfo .q (i ),'Name' ,model .GroupingInfo .GNames {i },...
    'VariableNames' ,model .RandomInfo .ZColNames {i }); 
end

end


if(R ==0 )
Psi =classreg .regr .lmeutils .covmats .BlockedCovariance ({classreg .regr .lmeutils .covmats .FullCovariance (0 )},1 ); 
else
Psi =classreg .regr .lmeutils .covmats .BlockedCovariance (mat ,model .GroupingInfo .lev ); 
end

end

function ZsColNames =makeSparseZNames (model )













































































































ZColNames =model .RandomInfo .ZColNames ; 
q =model .RandomInfo .q ; 
lev =model .GroupingInfo .lev ; 
GNames =model .GroupingInfo .GNames ; 
Gid =model .GroupingInfo .Gid ; 
GidLevelNames =model .GroupingInfo .GidLevelNames ; 
qlev =q .*lev ; 


R =length (Gid ); 












ZsColNames =table (cell (0 ,1 ),cell (0 ,1 ),cell (0 ,1 ),'VariableNames' ,{'Group' ,'Level' ,'Name' }); 


forr =1 :R 
groupname =repmat (GNames (r ),qlev (r ),1 ); 
levelname =repmat (GidLevelNames {r }' ,q (r ),1 ); 
levelname =levelname (:); 
name =repmat (ZColNames {r }' ,lev (r ),1 ); 

ZsColNames =[ZsColNames ; table (groupname ,levelname ,name ,...
    'VariableNames' ,{'Group' ,'Level' ,'Name' })]; %#ok<AGROW> 
end






end

function ZsColNames =makeSparseZNamesOLD (model )













































































































ZColNames =model .RandomInfo .ZColNames ; 
q =model .RandomInfo .q ; 
lev =model .GroupingInfo .lev ; 
GNames =model .GroupingInfo .GNames ; 
Gid =model .GroupingInfo .Gid ; 
GidLevelNames =model .GroupingInfo .GidLevelNames ; 


R =length (Gid ); 












ZsColNames =table (cell (0 ,1 ),cell (0 ,1 ),cell (0 ,1 ),'VariableNames' ,{'Group' ,'Level' ,'Name' }); 


forr =1 :R 

fork =1 :lev (r )

groupname =cell (q (r ),1 ); 
groupname (1 :q (r ))=GNames (r ); 


levelname =cell (q (r ),1 ); 
levelname (1 :q (r ))=GidLevelNames {r }(k ); 


name =ZColNames {r }' ; 


ZsColNames =[ZsColNames ; table (groupname ,levelname ,name ,...
    'VariableNames' ,{'Group' ,'Level' ,'Name' })]; %#ok<AGROW> 
end
end

end

function X =fixedEffectsDesign (model )







subset =model .ObservationInfo .Subset ; 
N =length (subset ); 


P =model .slme .p ; 


X =NaN (N ,P ); 


X (subset ,:)=model .FixedInfo .X ; 

end

function [Z ,gnames ]=randomEffectsDesign (model ,gnumbers )













































ifnargin ==1 
gnumbers =[]; 
end


R =model .GroupingInfo .R ; 



subset =model .ObservationInfo .Subset ; 
N =length (subset ); 

ifisempty (gnumbers )


gnumbers =(1 :R )' ; 
else

gnumbers =model .validateGNumbers (gnumbers ,R ); 
end


ifR ==0 
Z =sparse (N ,0 ); 
gnames ={}; 
return ; 
end


lev =model .GroupingInfo .lev ; 
q =model .RandomInfo .q ; 


qlev =q .*lev ; 



idx =[]; 
gnames =cell (length (gnumbers ),1 ); 
forr =1 :length (gnumbers )


k =gnumbers (r ); 



gnames {r }=model .GroupingInfo .GNames {k }; 







offset =sum (qlev (1 :(k -1 ))); 
cols =offset +1 :offset +qlev (k ); 



idx =[idx ,cols ]; %#ok<AGROW>       

end



Zr =model .slme .Z (:,idx ); 


Z =sparse (N ,size (Zr ,2 )); 


Z (subset ,:)=Zr ; 

end

function [X ,XColNames ,XCols2Terms ]=createDesignMatrix (model ,ds ,F )












ifisa (ds ,'dataset' )
ds =dataset2table (ds ); 
end

tf =ismember (model .PredictorNames ,ds .Properties .VariableNames ); 
if~all (tf )
error (message ('stats:classreg:regr:TermsRegression:MissingVariable' )); 
end


[tf ,varLocs ]=ismember (ds .Properties .VariableNames ,model .VariableNames ); 
if~all (tf )



ds =ds (:,tf ); 
end
varLocs =varLocs (tf ); 


terms =F .Terms ; 


assert (isequal (F .VariableNames ,model .VariableNames )|...
    isequal (F .VariableNames ,model .VariableNames ' )); 


[X ,~,~,XCols2Terms ,XColNames ]...
    =classreg .regr .modelutils .designmatrix (ds ,'Model' ,terms (:,varLocs ),...
    'DummyVarCoding' ,model .DummyVarCoding ,...
    'CategoricalVars' ,model .VariableInfo .IsCategorical (varLocs ),...
    'CategoricalLevels' ,model .VariableInfo .Range (varLocs )); 

end

end


methods (Abstract ,Access ={?classreg .regr .LinearLikeMixedModel })

np =getTotalNumberOfParameters (model ); 

end


methods (Static ,Access ='protected' )

function [G ,GName ]=makeInteractionVar (ds ,interactionVars )









ifisa (ds ,'dataset' )
ds =dataset2table (ds ); 
end


assert (iscellstr (interactionVars )); 



assert (all (ismember (interactionVars ,ds .Properties .VariableNames ))); 



k =length (interactionVars ); 
ifk >=1 
G =nominal (ds .(interactionVars {1 })); 
GName =interactionVars {1 }; 
fori =2 :k 
G =G .*nominal (ds .(interactionVars {i })); 
GName =[GName ,':' ,interactionVars {i }]; %#ok<AGROW> 
end
else
G =[]; 
GName =[]; 
end


G =removecats (G ); 

end

function newgid =reorderGroupIDs (gid ,names ,newnames )















assert (internal .stats .isIntegerVals (gid ,1 ,Inf )); 
assert (isvector (gid )); 
ifsize (gid ,1 )==1 
gid =gid ' ; 
end


assert (iscellstr (names )&isvector (names )); 
ifsize (names ,1 )==1 
names =names ' ; 
end
assert (iscellstr (newnames )&isvector (newnames )); 
ifsize (newnames ,1 )==1 
newnames =newnames ' ; 
end





[~,newintid ]=ismember (names ,newnames ); 


newgid =NaN (size (gid )); 
forj =1 :length (newintid )

k =newintid (j ); 
ifk ~=0 
newgid (gid ==j )=k ; 
end
end

end

function tf =isMatrixNested (Xsmall ,Xbig )






assert (isnumeric (Xsmall )&isreal (Xsmall )&ismatrix (Xsmall )); 
assert (isnumeric (Xbig )&isreal (Xbig )&ismatrix (Xbig )); 


assert (size (Xsmall ,1 )==size (Xbig ,1 )); 








[Nbig ,qbig ]=size (Xbig ); 
if(Nbig ==qbig )
Xbig (Nbig +1 ,:)=0 ; 
Xsmall (Nbig +1 ,:)=0 ; 
end


warnState =warning ('query' ,'all' ); 
warning ('off' ,'MATLAB:nearlySingularMatrix' ); 
warning ('off' ,'MATLAB:illConditionedMatrix' ); 
warning ('off' ,'MATLAB:singularMatrix' ); 
warning ('off' ,'MATLAB:rankDeficientMatrix' ); 
cleanupObj =onCleanup (@()warning (warnState )); 
GHat =Xbig \Xsmall ; 


Xsmall_recon =Xbig *GHat ; 


err =max (max (abs (Xsmall -Xsmall_recon ))); 


if(isempty (err )||err <=sqrt (eps (class (Xbig )))*max (size (Xbig )))
tf =true ; 
else
tf =false ; 
end

end

function tf =isMatrixNestedOLD (Xsmall ,Xbig )






assert (isnumeric (Xsmall )&isreal (Xsmall )&ismatrix (Xsmall )); 
assert (isnumeric (Xbig )&isreal (Xbig )&ismatrix (Xbig )); 


assert (size (Xsmall ,1 )==size (Xbig ,1 )); 


Xbig =full (Xbig ); 



Qbig =orth (Xbig ); 



Xsmall_recon =Qbig *(Qbig ' *Xsmall ); 


err =max (abs (Xsmall (:)-Xsmall_recon (:))); 


if(isempty (err )||err <=sqrt (eps (class (Xbig )))*max (size (Xbig )))
tf =true ; 
else
tf =false ; 
end

end

function lrt =standardLRT (smallModel ,bigModel ,smallModelName ,bigModelName )


































lrt =table (); 


modelName =cell (2 ,1 ); 
modelName {1 }=smallModelName ; 
modelName {2 }=bigModelName ; 
lrt .Model =nominal (modelName ); 


DF =zeros (2 ,1 ); 
DF (1 )=getTotalNumberOfParameters (smallModel ); 
DF (2 )=getTotalNumberOfParameters (bigModel ); 
lrt .DF =DF ; 


smallModelCrit =smallModel .ModelCriterion ; 
bigModelCrit =bigModel .ModelCriterion ; 


AIC =zeros (2 ,1 ); 
AIC (1 )=smallModelCrit .AIC ; 
AIC (2 )=bigModelCrit .AIC ; 
lrt .AIC =AIC ; 


BIC =zeros (2 ,1 ); 
BIC (1 )=smallModelCrit .BIC ; 
BIC (2 )=bigModelCrit .BIC ; 
lrt .BIC =BIC ; 


LogLik =zeros (2 ,1 ); 
LogLik (1 )=smallModelCrit .LogLikelihood ; 
LogLik (2 )=bigModelCrit .LogLikelihood ; 
lrt .LogLik =LogLik ; 


LRatio =zeros (2 ,1 ); 
LRatio (1 )=0 ; 
LRatio (2 )=2 *(LogLik (2 )-LogLik (1 )); 
LRatioAbsent =[true ; false ]; 
lrt .LRStat =internal .stats .DoubleTableColumn (LRatio ,LRatioAbsent ); 


deltaDF =zeros (2 ,1 ); 
deltaDF (1 )=0 ; 
deltaDF (2 )=DF (2 )-DF (1 ); 
deltaDFAbsent =[true ; false ]; 
lrt .deltaDF =internal .stats .DoubleTableColumn (deltaDF ,deltaDFAbsent ); 


pValue =zeros (2 ,1 ); 
pValue (1 )=0 ; 
pValue (2 )=1 -chi2cdf (LRatio (2 ),deltaDF (2 )); 
pValueAbsent =[true ; false ]; 
lrt .pValue =internal .stats .DoubleTableColumn (pValue ,pValueAbsent ); 


ttl =getString (message ('stats:LinearMixedModel:Title_LRT' )); 
lrt =classreg .regr .lmeutils .titleddataset (lrt ,ttl ); 

end

function tds =removeTitle (tds )






ifisa (tds ,'classreg.regr.lmeutils.titleddataset' )
tds =settitle (tds ,'' ); 
end

end

function str =formatBold (str )




iffeature ('hotlinks' )
str =['<strong>' ,str ,'</strong>' ]; 
end

end

function [haveDataset ,ds ,X ,Z ,G ,otherArgs ]=handleDatasetOrMatrixInput (varargin )

















assert (length (varargin )>=1 ); 


ifisa (varargin {1 },'dataset' )
varargin {1 }=dataset2table (varargin {1 }); 
end
haveDataset =isa (varargin {1 },'table' ); 


ifhaveDataset ==true 
ds =varargin {1 }; 
X =[]; 
Z =[]; 
G =[]; 
otherArgs =varargin (2 :end); 
else
nargs =length (varargin ); 
switchnargs 
case 1 

ds =[]; 
X =varargin {1 }; 
Z =[]; 
G =[]; 
otherArgs =varargin (2 :end); 
case 2 

ds =[]; 
X =varargin {1 }; 
Z =varargin {2 }; 
G =[]; 
otherArgs =varargin (3 :end); 
case 3 

ds =[]; 
X =varargin {1 }; 
Z =varargin {2 }; 
G =varargin {3 }; 
otherArgs =varargin (4 :end); 
otherwise

ds =[]; 
X =varargin {1 }; 
Z =varargin {2 }; 




ifinternal .stats .isString (varargin {3 })&&rem (length (varargin (4 :end)),2 )==1 
G =[]; 
otherArgs =varargin (3 :end); 
else
G =varargin {3 }; 
otherArgs =varargin (4 :end); 
end
end
end

end

end


methods (Static ,Access ='public' ,Hidden =true )

function Zs =makeSparseZ (Z ,q ,lev ,Gid ,N )

















































































































qlev =q .*lev ; 



R =length (Gid ); 
if(R ==0 )
Zs =sparse (N ,0 ); 
return ; 
end



rowidx =cell (sum (lev ),1 ); 
colidx =rowidx ; 
validx =rowidx ; 

count =1 ; 
forr =1 :R 





Gid {r }(isnan (Gid {r }))=lev (r )+1 ; 











vals =(1 :N )' ; 
[subs ,I ]=sortrows (Gid {r }); 
idxr =accumarray (subs ,vals (I ),[],@(x ){x }); 
lenidxr =length (idxr ); 
iflenidxr <lev (r )

idxr (lenidxr +1 :lev (r ))={zeros (0 ,1 )}; 
end

fork =1 :lev (r )


idx =idxr {k }; 

ifisempty (idx )
rowidx {count }=zeros (0 ,1 ); 
colidx {count }=zeros (0 ,1 ); 
validx {count }=zeros (0 ,1 ); 
else
offset =sum (qlev (1 :(r -1 )))+(k -1 )*q (r ); 

































































row =idx ; 
col =offset +1 :offset +q (r ); 
nrow =length (row ); 
ncol =length (col ); 

row =repmat (row ,1 ,ncol ); 
col =repmat (col ,nrow ,1 ); 
val =Z {r }(idx ,:); 

row =row (:); 
col =col (:); 
val =val (:); 

rowidx {count }=row ; 
colidx {count }=col ; 
validx {count }=val ; 
end

count =count +1 ; 

end
end


rowidx =cell2mat (rowidx ); 
colidx =cell2mat (colidx ); 
validx =cell2mat (validx ); 
Zs =sparse (rowidx ,colidx ,validx ,N ,sum (qlev )); 






end

function Zs =makeSparseZOLD (Z ,q ,lev ,Gid ,N )




















































































































qlev =q .*lev ; 


R =length (Gid ); 






Zs =sparse (N ,sum (qlev )); 


forr =1 :R 

fork =1 :lev (r )

idx =(Gid {r }==k ); 
offset =sum (qlev (1 :(r -1 )))+(k -1 )*q (r ); 
Zs (idx ,offset +1 :offset +q (r ))=Z {r }(idx ,:); %#ok<SPRIX>                                                 
end
end

end

end


methods (Static ,Access ='protected' )

function covariancepattern =...
    validateCovariancePattern (covariancepattern ,R ,Q )


























assert (R >=0 &internal .stats .isScalarInt (R )); 



assert (internal .stats .isIntegerVals (Q ,0 ,Inf )&length (Q )==R ); 


ifR ==0 
if~isempty (covariancepattern )
warning (message ('stats:LinearMixedModel:IgnoreCovariancePattern' )); 
end
covariancepattern ={}; 
return ; 
end




singlestring =internal .stats .isString (covariancepattern ); 
singlelogical =islogical (covariancepattern )&ismatrix (covariancepattern ); 
singledouble =isnumeric (covariancepattern )&ismatrix (covariancepattern ); 
ifsinglestring ||singlelogical ||singledouble 
covariancepattern ={covariancepattern }; 
end


ifR >1 

assertThat (iscell (covariancepattern ),'stats:LinearMixedModel:BadCovariancePattern_vector' ,num2str (R )); 
assertThat (length (covariancepattern )==R ,'stats:LinearMixedModel:BadCovariancePattern_vector' ,num2str (R )); 
else

assertThat (iscell (covariancepattern ),'stats:LinearMixedModel:BadCovariancePattern_scalar' ,num2str (R )); 
assertThat (length (covariancepattern )==R ,'stats:LinearMixedModel:BadCovariancePattern_scalar' ,num2str (R )); 
end



fori =1 :R 
doubleinput =isnumeric (covariancepattern {i })&ismatrix (covariancepattern {i }); 

ifdoubleinput 
covariancepattern {i }=logical (covariancepattern {i }); 
end

stringinput =internal .stats .isString (covariancepattern {i }); 
logicalinput =islogical (covariancepattern {i })&ismatrix (covariancepattern {i }); 

ifstringinput 
ifQ (i )==0 
covariancepattern {i }=internal .stats .getParamVal ('FullCholesky' ,classreg .regr .LinearLikeMixedModel .AllowedCovariancePatterns ,'CovariancePattern' ); 
else
covariancepattern {i }=internal .stats .getParamVal (covariancepattern {i },classreg .regr .LinearLikeMixedModel .AllowedCovariancePatterns ,'CovariancePattern' ); 
end
elseiflogicalinput 

assertThat (all (size (covariancepattern {i })==[Q (i ),Q (i )]),'stats:LinearMixedModel:BadCovariancePatternElement_logical' ,num2str (i ),num2str (Q (i ))); 
else

assertThat (false ,'stats:LinearMixedModel:BadCovariancePatternElement' ,num2str (i )); 
end
end


ifsize (covariancepattern ,1 )==1 
covariancepattern =covariancepattern ' ; 
end

end

function exclude =validateExclude (exclude ,N )

















assert (N >=0 &internal .stats .isScalarInt (N )); 


isintegervec =internal .stats .isIntegerVals (exclude ,1 ,N ); 


islogicalvec =isvector (exclude )&islogical (exclude )...
    &length (exclude )==N ; 



assertThat (isintegervec |islogicalvec ,'stats:LinearMixedModel:BadExclude' ,num2str (N ),num2str (N )); 


ifsize (exclude ,1 )==1 
exclude =exclude ' ; 
end

end

function dummyvarcoding =validateDummyVarCoding (dummyvarcoding )












dummyvarcoding =internal .stats .getParamVal (dummyvarcoding ,...
    classreg .regr .LinearLikeMixedModel .AllowedDummyVarCodings ,'DummyVarCoding' ); 

end

function alpha =validateAlpha (alpha )













assertThat (isnumeric (alpha )&isreal (alpha )&isscalar (alpha ),'stats:LinearMixedModel:BadAlpha' ); 
assertThat (alpha >=0 &alpha <=1 ,'stats:LinearMixedModel:BadAlpha' ); 

end

function tf =validateLogicalScalar (tf ,msgID )












assert (internal .stats .isString (msgID )); 


ifisscalar (tf )
ifisnumeric (tf )
if(tf ==1 )
tf =true ; 
elseif(tf ==0 )
tf =false ; 
end
end
assertThat (islogical (tf ),msgID ); 
else
error (message (msgID )); 
end

end

function wantconditional =validateConditional (wantconditional )












wantconditional =...
    classreg .regr .LinearLikeMixedModel .validateLogicalScalar (wantconditional ,'stats:LinearMixedModel:BadConditional' ); 

end

function wantsimultaneous =validateSimultaneous (wantsimultaneous )












wantsimultaneous =...
    classreg .regr .LinearLikeMixedModel .validateLogicalScalar (wantsimultaneous ,'stats:LinearMixedModel:BadSimultaneous' ); 

end

function designtype =validateDesignType (designtype )











designtype =internal .stats .getParamVal (designtype ,...
    {'Fixed' ,'Random' },'DESIGNTYPE' ); 

end

function H =validateFEContrast (H ,p )












assert (p >=0 &internal .stats .isScalarInt (p )); 



assertThat (isnumeric (H )&isreal (H )&ismatrix (H )&size (H ,2 )==p ,'stats:LinearMixedModel:BadFEContrast' ,num2str (p )); 

end

function c =validateTestValue (c ,M )












assert (M >=0 &internal .stats .isScalarInt (M )); 



assertThat (isnumeric (c )&isreal (c )&isvector (c ),'stats:LinearMixedModel:BadTestValue' ,num2str (M )); 
ifsize (c ,1 )==1 
c =c ' ; 
end
assertThat (all (size (c )==[M ,1 ]),'stats:LinearMixedModel:BadTestValue' ,num2str (M )); 

end

function K =validateREContrast (K ,M ,q )












assert (M >=0 &internal .stats .isScalarInt (M )); 
assert (q >=0 &internal .stats .isScalarInt (q )); 



assertThat (isnumeric (K )&isreal (K )&ismatrix (K ),'stats:LinearMixedModel:BadREContrast' ,num2str (M ),num2str (q )); 
assertThat (all (size (K )==[M ,q ]),'stats:LinearMixedModel:BadREContrast' ,num2str (M ),num2str (q )); 

end

function gnumbers =validateGNumbers (gnumbers ,R )












assert (R >=0 &internal .stats .isScalarInt (R )); 



assertThat (isnumeric (gnumbers )&isreal (gnumbers )&isvector (gnumbers ),'stats:LinearMixedModel:BadGNumbers' ,num2str (R )); 
assertThat (internal .stats .isIntegerVals (gnumbers ,1 ,R ),'stats:LinearMixedModel:BadGNumbers' ,num2str (R )); 

end

function X =validateMatrix (X ,XName ,N ,P )













switchnargin 
case 1 

XName ='X' ; 
N =[]; 
P =[]; 
case 2 

N =[]; 
P =[]; 
case 3 

P =[]; 
end


if~isempty (N )
assert (N >=0 &internal .stats .isScalarInt (N )); 
end
if~isempty (P )
assert (P >=0 &internal .stats .isScalarInt (P )); 
end


assert (internal .stats .isString (XName )); 



ifislogical (X )&&ismatrix (X )
X =double (X ); 
end
assertThat (isnumeric (X )&isreal (X )&ismatrix (X ),'stats:LinearMixedModel:MustBeMatrix' ,XName ); 


if~isempty (N )

assertThat (size (X ,1 )==N ,'stats:LinearMixedModel:MustHaveRows' ,XName ,num2str (N )); 
end


if~isempty (P )

assertThat (size (X ,2 )==P ,'stats:LinearMixedModel:MustHaveCols' ,XName ,num2str (P )); 
end

end

function G =validateGroupingVar (G ,GName ,N )















switchnargin 
case 1 

GName ='G' ; 
N =[]; 
case 2 

N =[]; 
end


if~isempty (N )
assert (N >=0 &internal .stats .isScalarInt (N )); 
end


assert (internal .stats .isString (GName )); 


isdiscreteG =internal .stats .isDiscreteVar (G ); 
isnumericG =isnumeric (G )&isreal (G )&isvector (G ); 



assertThat (isdiscreteG |isnumericG ,'stats:LinearMixedModel:BadGroupingVar' ,GName ); 


ifsize (G ,1 )==1 &&~ischar (G )
G =G ' ; 
end


if~isempty (N )

assertThat (size (G ,1 )==N ,'stats:LinearMixedModel:BadLength' ,GName ,num2str (N )); 
end

end

function C =validateCellVectorOfStrings (C ,CName ,P ,mustbeunique )















switchnargin 
case 1 

CName ='C' ; 
P =[]; 
mustbeunique =false ; 
case 2 

P =[]; 
mustbeunique =false ; 
case 3 

mustbeunique =false ; 
end


[~,C ]=internal .stats .isStrings (C ,false ); 
C =classreg .regr .LinearLikeMixedModel .validateCellVector (C ,CName ,P ); 


assert (isscalar (mustbeunique )&islogical (mustbeunique )); 



assertThat (iscellstr (C ),'stats:LinearMixedModel:MustBeCellVectorOfStrings' ,CName ); 


ifmustbeunique ==true 
n1 =length (C ); 
n2 =length (unique (C )); 

assertThat (n1 ==n2 ,'stats:LinearMixedModel:MustBeCellVectorOfStrings_unique' ,CName ); 
end

end

function S =validateString (S ,SName )









assert (internal .stats .isString (SName )); 



assertThat (internal .stats .isString (S ),'stats:LinearMixedModel:MustBeString' ,SName ); 

end

function C =validateCellVector (C ,CName ,R )











switchnargin 
case 1 

CName ='C' ; 
R =[]; 
case 2 

R =[]; 
end


assert (internal .stats .isString (CName )); 


if~isempty (R )
assert (R >=0 &internal .stats .isScalarInt (R )); 
end



assertThat (iscell (C )&isvector (C ),'stats:LinearMixedModel:MustBeCellVector' ,CName ); 


ifsize (C ,1 )==1 
C =C ' ; 
end


if~isempty (R )

assertThat (length (C )==R ,'stats:LinearMixedModel:MustBeCellVector_length' ,CName ,num2str (R )); 
end

end

function ds =validateDataset (ds ,dsName ,dsref )
















assert (internal .stats .isString (dsName )); 

ifisa (dsref ,'dataset' )
dsref =dataset2table (dsref ); 
end
ifisa (ds ,'dataset' )
ds =dataset2table (ds ); 
end

assert (isa (dsref ,'table' )); 



assertThat (isa (ds ,'table' ),'stats:LinearMixedModel:MustBeDataset' ,dsName ); 


varnames_dsref =dsref .Properties .VariableNames ; 
varnames_ds =ds .Properties .VariableNames ; 
[tf ,idx ]=ismember (varnames_dsref ,varnames_ds ); 



assertThat (all (tf ),'stats:LinearMixedModel:Dataset_missingvarnames' ,dsName ); 


forj =1 :length (idx )
k =idx (j ); 
ifk ~=0 

class_ds =class (ds .(varnames_ds {k })); 
class_dsref =class (dsref .(varnames_dsref {j })); 

assertThat (isequal (class_ds ,class_dsref ),'stats:LinearMixedModel:Dataset_incorrectclass' ,varnames_ds {k },dsName ); 
end
end

end

function obj =validateObjectClass (obj ,objName ,className )











assert (internal .stats .isString (objName )); 
assert (internal .stats .isString (className )); 



assertThat (isa (obj ,className ),'stats:LinearMixedModel:BadClass' ,objName ,className ); 

end

function checknesting =validateCheckNesting (checknesting )












checknesting =...
    classreg .regr .LinearLikeMixedModel .validateLogicalScalar (checknesting ,'stats:LinearMixedModel:BadCheckNesting' ); 

end

end


methods (Static ,Abstract ,Access ='protected' )

fitmethod =validateFitMethod (fitmethod ); 
w =validateWeights (w ,N ); 
[optimizer ,optimizeroptions ]=validateOptimizerAndOptions (optimizer ,optimizeroptions ); 
startmethod =validateStartMethod (startmethod ); 
dfmethod =validateDFMethod (dfmethod ); 
residualtype =validateResidualType (residualtype ); 
verbose =validateVerbose (verbose ); 
checkhessian =validateCheckHessian (checkhessian ); 

checkNestingRequirement (smallModel ,bigModel ,smallModelName ,bigModelName ,isSimulatedTest ); 

end


methods (Access ='public' )

function [feci ,reci ]=coefCI (model ,varargin )
















































[varargin {:}]=convertStringsToChars (varargin {:}); 

dfltDFMethod ='Residual' ; 
dfltAlpha =0.05 ; 


paramNames ={'DFMethod' ,'Alpha' }; 
paramDflts ={dfltDFMethod ,dfltAlpha }; 


[dfmethod ,alpha ]...
    =internal .stats .parseArgs (paramNames ,paramDflts ,varargin {:}); 


dfmethod =model .validateDFMethod (dfmethod ); 
alpha =model .validateAlpha (alpha ); 


fetable =fixedEffects (model .slme ,alpha ,dfmethod ); 
feci =[fetable .Lower ,fetable .Upper ]; 


ifnargout >1 

retable =randomEffects (model .slme ,alpha ,dfmethod ); 
reci =[retable .Lower ,retable .Upper ]; 

end

end






















































































































function [P ,F ,DF1 ,DF2 ]=coefTest (model ,H ,c ,varargin )




























































[varargin {:}]=convertStringsToChars (varargin {:}); 

dfltREContrast =[]; 
dfltDFMethod ='Residual' ; 


paramNames ={'REContrast' ,'DFMethod' }; 
paramDflts ={dfltREContrast ,dfltDFMethod }; 


[K ,dfmethod ]=...
    internal .stats .parseArgs (paramNames ,paramDflts ,varargin {:}); 


p =model .slme .p ; 
q =model .slme .q ; 

ifnargin <2 





H =eye (p ); 

interceptTermIdx =...
    find (all (model .Formula .FELinearFormula .Terms ==0 ,2 )); 

ifisscalar (interceptTermIdx )
interceptCoeffIdx =...
    model .FixedInfo .XCols2Terms ==interceptTermIdx ; 

H (interceptCoeffIdx ,:)=[]; 
end
end

ifnargin <3 


c =zeros (size (H ,1 ),1 ); 
end


H =model .validateFEContrast (H ,p ); 
M =size (H ,1 ); 
c =model .validateTestValue (c ,M ); 
dfmethod =model .validateDFMethod (dfmethod ); 



ifisempty (K )

[P ,F ,DF1 ,DF2 ]=betaFTest (model .slme ,H ,c ,dfmethod ); 
else

K =model .validateREContrast (K ,M ,q ); 

[P ,F ,DF1 ,DF2 ]=betaBFTest (model .slme ,H ,K ,c ,dfmethod ); 
end

end

end


methods (Access ='public' )

function [D ,gnames ]=designMatrix (model ,designtype ,gnumbers )




























































narginchk (1 ,3 ); 
switchnargin 
case 1 
designtype ='Fixed' ; 
gnumbers =[]; 
case 2 
gnumbers =[]; 
end


designtype =convertStringsToChars (designtype ); 
designtype =model .validateDesignType (designtype ); 


switchlower (designtype )
case 'fixed' 
D =fixedEffectsDesign (model ); 
gnames =[]; 
case 'random' 
[D ,gnames ]=randomEffectsDesign (model ,gnumbers ); 
end

end

function [beta ,betanames ,fetable ]=fixedEffects (model ,varargin )





















































[varargin {:}]=convertStringsToChars (varargin {:}); 

dfltDFMethod ='Residual' ; 
dfltAlpha =0.05 ; 


paramNames ={'DFMethod' ,'Alpha' }; 
paramDflts ={dfltDFMethod ,dfltAlpha }; 


[dfmethod ,alpha ]...
    =internal .stats .parseArgs (paramNames ,paramDflts ,varargin {:}); 


dfmethod =model .validateDFMethod (dfmethod ); 
alpha =model .validateAlpha (alpha ); 


beta =model .slme .betaHat ; 


ifnargout >1 
betanames =table (model .FixedInfo .XColNames ' ,'VariableNames' ,{'Name' }); 
end



ifnargout >2 
fetable =fixedEffects (model .slme ,alpha ,dfmethod ); 



fetable =[betanames ,fetable ]; 



ttl =getString (message ('stats:LinearMixedModel:Title_fetable' ,dfmethod ,num2str (alpha ))); 
fetable =classreg .regr .lmeutils .titleddataset (fetable ,ttl ); 
end

end

function [b ,bnames ,retable ]=randomEffects (model ,varargin )





































































[varargin {:}]=convertStringsToChars (varargin {:}); 

dfltDFMethod ='Residual' ; 
dfltAlpha =0.05 ; 


paramNames ={'DFMethod' ,'Alpha' }; 
paramDflts ={dfltDFMethod ,dfltAlpha }; 


[dfmethod ,alpha ]...
    =internal .stats .parseArgs (paramNames ,paramDflts ,varargin {:}); 


dfmethod =model .validateDFMethod (dfmethod ); 
alpha =model .validateAlpha (alpha ); 


b =model .slme .bHat ; 


ifnargout >1 
bnames =model .RandomInfo .ZsColNames ; 
end



ifnargout >2 
retable =randomEffects (model .slme ,alpha ,dfmethod ); 




retable =[bnames ,retable ]; 



ttl =getString (message ('stats:LinearMixedModel:Title_retable' ,dfmethod ,num2str (alpha ))); 
retable =classreg .regr .lmeutils .titleddataset (retable ,ttl ); 
end

end

function [PSI ,mse ,covtable ]=covarianceParameters (model ,varargin )


















































[varargin {:}]=convertStringsToChars (varargin {:}); 

dfltAlpha =0.05 ; 


paramNames ={'Alpha' ,'WantCIs' }; 
paramDflts ={dfltAlpha ,true }; 


[alpha ,wantCIs ]=internal .stats .parseArgs (paramNames ,paramDflts ,varargin {:}); 


alpha =model .validateAlpha (alpha ); 
assert (isscalar (wantCIs )&islogical (wantCIs )); 


R =model .GroupingInfo .R ; 


mse =(model .slme .sigmaHat )^2 ; 


PSI =cell (R ,1 ); 
fork =1 :R 



matk =model .slme .Psi .Matrices {k }; 
Lk =getLowerTriangularCholeskyFactor (matk ); 



PSI {k }=mse *(Lk *Lk ' ); 
end


ifnargout >2 







tbl =covarianceParameters (model .slme ,alpha ,wantCIs ); 











ifR >=1 
names =getCanonicalParameterNames (model .slme .Psi ); 
else
names =cell (0 ,1 ); 
end





















covtable =cell (R +1 ,1 ); 
offset =0 ; 
fork =1 :R 


matk =model .slme .Psi .Matrices {k }; 
startk =offset +1 ; 
endk =offset +matk .NumParametersExcludingSigma ; 
idxk =startk :endk ; 


covtable {k }=[names {k },tbl (idxk ,:)]; 





ttl =getString (message ('stats:LinearMixedModel:Title_covtable' ,model .slme .Psi .Matrices {k }.Type )); 
covtable {k }=classreg .regr .lmeutils .titleddataset (covtable {k },ttl ); 


offset =endk ; 
end





ifisequal (class (model ),'GeneralizedLinearMixedModel' )
res_std_name ='sqrt(Dispersion)' ; 
else
res_std_name ='Res Std' ; 
end
covtable {R +1 }=[classreg .regr .lmeutils .titleddataset ({'Error' ,'Group' },{{res_std_name },'Name' }),...
    classreg .regr .lmeutils .titleddataset (tbl (end,:))]; 
covtable {R +1 }.Group =char (covtable {R +1 }.Group ); 
end

end

function hout =plotResiduals (model ,plottype ,varargin )













































ifnargin <2 
plottype ='histogram' ; 
end
plottype =convertStringsToChars (plottype ); 
[varargin {:}]=convertStringsToChars (varargin {:}); 

dfltResidualType ='Raw' ; 


paramNames ={'ResidualType' }; 
paramDflts ={dfltResidualType }; 


[residualtype ,~,args ]...
    =internal .stats .parseArgs (paramNames ,paramDflts ,varargin {:}); 


varargin =args ; 


residualtype =model .validateResidualType (residualtype ); 


internal .stats .plotargchk (varargin {:}); 


f =classreg .regr .modelutils .plotResiduals (model ,plottype ,'ResidualType' ,residualtype ,varargin {:}); 
ifnargout >0 
hout =f ; 
end

end

function stats =anova (model ,varargin )















































[varargin {:}]=convertStringsToChars (varargin {:}); 


dfltDFMethod ='Residual' ; 


paramNames ={'DFMethod' }; 
paramDflts ={dfltDFMethod }; 


dfmethod ...
    =internal .stats .parseArgs (paramNames ,paramDflts ,varargin {:}); 


dfmethod =model .validateDFMethod (dfmethod ); 


termnames =model .Formula .FELinearFormula .TermNames ; 
ifsize (termnames ,1 )==1 
termnames =termnames ' ; 
end
nterms =length (model .Formula .FELinearFormula .TermNames ); 










I =eye (model .slme .p ); 
P =zeros (nterms ,1 ); 
F =zeros (nterms ,1 ); 
DF1 =zeros (nterms ,1 ); 
DF2 =zeros (nterms ,1 ); 

fork =1 :nterms 

termkcols =(model .FixedInfo .XCols2Terms ==k ); 


L =I (termkcols ,:); 
e =zeros (size (L ,1 ),1 ); 
[P (k ),F (k ),DF1 (k ),DF2 (k )]=...
    betaFTest (model .slme ,L ,e ,dfmethod ); 
end


stats =table (termnames ,F ,DF1 ,DF2 ,P ,'VariableNames' ,{'Term' ,'FStat' ,'DF1' ,...
    'DF2' ,'pValue' }); 








ttl =getString (message ('stats:LinearMixedModel:Title_anova' ,dfmethod )); 
stats =classreg .regr .lmeutils .titleddataset (stats ,ttl ); 

end

end


methods (Abstract ,Access ='public' )

yfit =fitted (model ,varargin ); 
res =residuals (model ,varargin ); 
table =compare (model ,altmodel ,varargin ); 
Y =response (model ); 

end

end

function assertThat (condition ,msgID ,varargin )





if~condition 

try
msg =message (msgID ,varargin {:}); 
catch 

error (message ('stats:LinearMixedModel:BadMsgID' ,msgID )); 
end

ME =MException (msg .Identifier ,getString (msg )); 
throwAsCaller (ME ); 
end

end
