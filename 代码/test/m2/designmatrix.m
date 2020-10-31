function [X ,terms ,cols2vars ,cols2terms ,colnames ,termnames ,catnums ]=designmatrix (data ,varargin )



























































































ifisa (data ,'dataset' )
data =dataset2table (data ); 
end

[nobs ,nvars ]=size (data ); 

ifisa (data ,'table' )
isDataset =true ; 

catVars =varfun (@(x )isa (x ,'categorical' )||iscellstr (x )||ischar (x )||islogical (x ),data ,'OutputFormat' ,'uniform' ); 
elseif(isfloat (data )||islogical (data ))&&ismatrix (data )
isDataset =false ; 

catVars =false (1 ,size (data ,2 )); 
elseifisa (data ,'categorical' )
isDataset =false ; 
catVars =true (1 ,size (data ,2 )); 
else
error (message ('stats:classreg:regr:modelutils:BadDataType' )); 
end

paramNames ={'Model' ,'VarNames' ,'PredictorVars' ,'ResponseVar' ,'Intercept' ...
    ,'CategoricalVars' ,'CategoricalLevels' ,'DummyVarCoding' }; 
paramDflts ={'linear' ,[],1 :(nvars -1 ),nvars ,true ...
    ,catVars ,[],{'reference' }}; 
[model ,varNames ,predictorVars ,responseVar ,includeIntercept ,...
    treatAsCategorical ,catLevels ,dummyCoding ,supplied ]=...
    internal .stats .parseArgs (paramNames ,paramDflts ,varargin {:}); 

ifisDataset 
varNames =data .Properties .VariableNames ; 
elseif~supplied .VarNames 
varNames =strcat ({'X' },num2str ((1 :nvars )' ,'%-d' ))' ; 
end



ifsupplied .PredictorVars 
ifisnumeric (predictorVars )
ifany (predictorVars <1 )||any (predictorVars >nvars )
error (message ('stats:classreg:regr:modelutils:BadPredVarsNumeric' )); 
end
elseifisDataset &&internal .stats .isStrings (predictorVars )
[~,predVarInds ]=ismember (predictorVars ,varNames ); 
ifany (predVarInds ==0 )
error (message ('stats:classreg:regr:modelutils:BadPredVarsName' ,predictorVars (predVarInds (1 )))); 
end
predictorVars =predVarInds ; 
else
ifisDataset 
error (message ('stats:classreg:regr:modelutils:BadPredVarsDataset' )); 
else
error (message ('stats:classreg:regr:modelutils:BadPredVarsMatrix' )); 
end
end

if~supplied .ResponseVar 

responseVar =setdiff (1 :nvars ,predictorVars ); 
ifnumel (responseVar )>1 
error (message ('stats:classreg:regr:modelutils:CannotDetermineResponse' )); 
end
end
end



ifsupplied .ResponseVar 
ifisempty (responseVar )

elseifisscalar (responseVar )&&isnumeric (responseVar )
if(responseVar <1 )||(responseVar >nvars )
error (message ('stats:classreg:regr:modelutils:BadResponseNumeric' )); 
end
elseifisDataset &&internal .stats .isString (responseVar )
responseVarIdx =find (strcmp (responseVar ,varNames )); 
ifisempty (responseVarIdx )
error (message ('stats:classreg:regr:modelutils:BadResponseName' ,responseVar )); 
end
responseVar =responseVarIdx ; 
else
ifisDataset 
error (message ('stats:classreg:regr:modelutils:BadResponseDataset' )); 
else
error (message ('stats:classreg:regr:modelutils:BadResponseMatrix' )); 
end
end

if~supplied .PredictorVars 

predictorVars =setdiff (1 :nvars ,responseVar ); 
end
end



if~isscalar (includeIntercept )||~islogical (includeIntercept )
error (message ('stats:classreg:regr:modelutils:BadIntercept' )); 
end


if~islogical (treatAsCategorical )||numel (treatAsCategorical )~=nvars 
error (message ('stats:classreg:regr:modelutils:BadCategorical' )); 
end


ifinternal .stats .isString (model )
whichVars =false (1 ,nvars ); whichVars (predictorVars )=true ; 
terms =classreg .regr .modelutils .model2terms (model ,whichVars ,includeIntercept ,treatAsCategorical ); 

elseifisnumeric (model )&&ismatrix (model )
ifsize (model ,2 )~=nvars 
error (message ('stats:classreg:regr:modelutils:BadModelMatrix' )); 
end
terms =model ; 
interceptRow =find (sum (terms ,2 )==0 ); 
ifsupplied .Intercept &&includeIntercept &&isempty (interceptRow )

terms =[zeros (1 ,nvars ); terms ]; 
elseif~includeIntercept &&~isempty (interceptRow )
error (message ('stats:classreg:regr:modelutils:InterceptAmbiguous' )); 
end
predVarsIn =predictorVars ; 
predictorVars =find (sum (terms ,1 )>0 ); 
ifsupplied .PredictorVars &&~isempty (setxor (predictorVars ,predVarsIn ))
error (message ('stats:classreg:regr:modelutils:PredictorsAmbiguous' )); 
end
if~supplied .ResponseVar 
responseVar =setdiff (1 :nvars ,predictorVars ); 
end

else
error (message ('stats:classreg:regr:modelutils:ModelStringOrMatrix' )); 
end


ifsupplied .DummyVarCoding 
codingStrings ={'full' ,'reference' ,'referencelast' ,'effects' ,'effectsfirst' ,'difference' ,'backwardDifference' ,'ordinal' }; 
[haveStrs ,dummyCoding ]=internal .stats .isStrings (dummyCoding ); 
if~haveStrs 
error (message ('stats:classreg:regr:modelutils:BadDummyCode' )); 
else
fori =1 :length (dummyCoding )
if~isempty (dummyCoding {i })&&~any (strcmpi (dummyCoding {i },codingStrings ))
error (message ('stats:classreg:regr:modelutils:UnrecognizedDummyCode' ,internal .stats .listStrings (codingStrings ))); 
end
end
end
end
ifisscalar (dummyCoding )
dummyCoding =repmat (dummyCoding ,1 ,nvars ); 
dummyCoding (~treatAsCategorical )={'' }; 
end

ifnargout >=7 &&~all (cellfun ('isempty' ,dummyCoding )|strcmp ('full' ,dummyCoding ))
error (message ('stats:classreg:regr:modelutils:FullCodingRequired' )); 
end

ifisDataset 
varClasses =varfun (@class ,data ,'InputVariables' ,predictorVars ,'OutputFormat' ,'cell' ); 
ifany (strcmp ('single' ,varClasses ))
outClass ='single' ; 
else
outClass ='double' ; 
end
elseifisnumeric (data ); 
outClass =class (data ); 
else
outClass ='double' ; 
end




ncolsX =length (predictorVars )+3 *sum (treatAsCategorical (predictorVars )); 
X =zeros (nobs ,ncolsX ,outClass ); 
colnames =cell (1 ,ncolsX ); 
cols2vars =false (nvars ,ncolsX ); 
ncols =0 ; 


nvarlevels =ones (1 ,nvars ); 
forj =predictorVars 
vnamej =varNames {j }; 
ifisDataset 
Xj =data .(vnamej ); 
else
Xj =data (:,j ); 
end
ncolsj =size (Xj ,2 ); 
if~ismatrix (Xj )||ncolsj ==0 
error (message ('stats:classreg:regr:modelutils:NotMatrices' )); 
end


iftreatAsCategorical (j )
ifsupplied .CategoricalLevels 
[Xj ,dummynames ]=dummyVars (dummyCoding {j },Xj ,catLevels {j }); 
else
[Xj ,dummynames ]=dummyVars (dummyCoding {j },Xj ); 
end
ncolsj =size (Xj ,2 ); 
colnamesj =strcat (vnamej ,'_' ,dummynames ); 
nvarlevels (j )=ncolsj ; 


elseifisnumeric (Xj )||islogical (Xj )
colnamesj ={vnamej }; 

ifncolsj >1 
cols =cellstr (num2str ((1 :ncolsj )' ,'%-d' ))' ; 
colnamesj =strcat (vnamej ,'_' ,cols ); 
end
else
ifcatVars (j )
error (message ('stats:classreg:regr:modelutils:CatNotContinuous' )); 
else
error (message ('stats:classreg:regr:modelutils:BadVariableType' )); 
end
end


ifncols +ncolsj >ncolsX 
predVarsLeft =predictorVars (predictorVars >j ); 
ncolsX =ncols +ncolsj +length (predVarsLeft )+3 *sum (treatAsCategorical (predVarsLeft )); 
ifnobs >0 
X (nobs ,ncolsX )=0 ; 
else
X =zeros (0 ,ncolsX ,'like' ,X ); 
end
colnames {ncolsX }='' ; 
cols2vars (nvars ,ncolsX )=0 ; 
end

colsj =(ncols +1 ):(ncols +ncolsj ); 
X (:,colsj )=Xj ; 
colnames (:,colsj )=colnamesj ; 
ncols =ncols +ncolsj ; 


cols2vars (j ,colsj )=true ; 
end

Xmain =X (:,1 :ncols ); 
colnamesMain =colnames (:,1 :ncols ); 
cols2varsMain =cols2vars (:,1 :ncols ); 

nterms =size (terms ,1 ); 
X =zeros (nobs ,0 ,outClass ); 
colnames ={}; 
cols2vars =zeros (nvars ,0 ); 
cols2terms =zeros (1 ,nterms ); 
termnames ={}; 
ifnargout >=7 
catnums =cell (1 ,nterms ); 
end
forj =1 :nterms 
varsj =find (terms (j ,:)); 
ifisempty (varsj )
Xj =ones (nobs ,1 ,outClass ); 
colnames =[colnames ,'(Intercept)' ]; 
cols2vars =[cols2vars ,false (nvars ,1 )]; 
termnames =[termnames ,'(Intercept)' ]; 
else
colsj =cols2varsMain (varsj (1 ),:); 
Xj =Xmain (:,colsj ); 
colnamesj =colnamesMain (colsj ); 
termnamesj =varNames {varsj (1 )}; 
expon =terms (j ,varsj (1 )); 
ifexpon >1 
ifsize (Xj ,2 )==1 
Xj =Xj .^expon ; 
colnamesj =strcat (colnamesj ,'^' ,num2str (expon )); 
termnamesj =strcat (termnamesj ,'^' ,num2str (expon )); 
else
Xj1 =Xj ; 
colnamesj1 =colnamesj ; 
fore =2 :expon 
[rep1 ,rep2 ]=allpairs2 (1 :size (Xj1 ,2 ),1 :size (Xj ,2 )); 
Xj =Xj1 (:,rep1 ).*Xj (:,rep2 ); 
colnamesj =strcat (colnamesj1 (rep1 ),'_' ,colnamesj (rep2 )); 
end
end
end
fork =2 :length (varsj )
colsjk =cols2varsMain (varsj (k ),:); 
Xjk =Xmain (:,colsjk ); 
colnamesjk =colnamesMain (colsjk ); 
termnamesjk =varNames {varsj (k )}; 
expon =terms (j ,varsj (k )); 
ifexpon >1 
ifsize (Xjk ,2 )==1 
Xjk =Xjk .^expon ; 
colnamesjk =strcat (colnamesjk ,'^' ,num2str (expon )); 
termnamesjk =strcat (termnamesjk ,'^' ,num2str (expon )); 
else
Xjk1 =Xjk ; 
colnamesjk1 =colnamesjk ; 
fore =2 :expon 
[rep1 ,rep2 ]=allpairs2 (1 :size (Xjk1 ,2 ),1 :size (Xjk ,2 )); 
Xjk =Xjk1 (:,rep1 ).*Xjk (:,rep2 ); 
colnamesjk =strcat (colnamesjk1 (rep1 ),'_' ,colnamesjk (rep2 )); 
end
end
end
[rep1 ,rep2 ]=allpairs2 (1 :size (Xj ,2 ),1 :size (Xjk ,2 )); 
Xj =Xj (:,rep1 ).*Xjk (:,rep2 ); 
colnamesj =strcat (colnamesj (rep1 ),':' ,colnamesjk (rep2 )); 
termnamesj =[termnamesj ,':' ,termnamesjk ]; 
end
colnames =[colnames ,colnamesj ]; 
termnames =[termnames ,termnamesj ]; 


cols2varsj =false (nvars ,size (Xj ,2 )); 
cols2varsj (varsj ,:)=true ; 
cols2vars =[cols2vars ,cols2varsj ]; 
end
cols2terms (size (X ,2 )+(1 :size (Xj ,2 )))=j ; 
X =[X ,Xj ]; 
ifnargout >=7 &&any (treatAsCategorical (varsj ))
termlevels =nvarlevels (varsj ); 
termlevels =termlevels (treatAsCategorical (varsj )); 
ifall (termlevels >0 )
catnums {j }=fullfact (termlevels ); 
else
catnums {j }=[]; 
end
end
end



function [rep1 ,rep2 ]=allpairs2 (i ,j )
[rep1 ,rep2 ]=ndgrid (i ,j ); 
rep1 =rep1 (:)' ; 
rep2 =rep2 (:)' ; 



function [X ,colnames ]=dummyVars (method ,group ,glevels )

ifnargin <3 ||isempty (glevels )
[gidx ,gn ]=grp2idx (group ); 
ifisa (group ,'categorical' )
uidx =unique (gidx ); 
iflength (uidx )<length (gn )
warning (message ('stats:classreg:regr:modelutils:LevelsNotPresent' )); 
[gidx ,gn ]=grp2idx (removecats (group )); 
end
end
else
[~,gn ,glevels ]=grp2idx (glevels ); 
group =convertVar (group ,glevels ); 
ifischar (group )
[tf ,gidx ]=ismember (group ,glevels ,'rows' ); 
else
[tf ,gidx ]=ismember (group ,glevels ); 
end
gidx (tf ==0 )=NaN ; 
end
ng =length (gn ); 

switchlower (method )
case 'full' 
X0 =eye (ng ); 
colnames =gn ; 
case 'reference' 
X0 =eye (ng ); X0 (:,1 )=[]; 
colnames =gn (2 :end); 
case 'referencelast' 
X0 =eye (ng ,ng -1 ); 
colnames =gn (1 :end-1 ); 
case 'effects' 
X0 =eye (ng ,ng -1 ); 
X0 (end,:)=-1 ; 
colnames =gn (1 :end-1 ); 
case 'effectsfirst' 
X0 =[-ones (1 ,ng -1 ); eye (ng -1 )]; 
colnames =gn (2 :end); 
case 'difference' 
X0 =tril (ones (ng ,ng )); X0 (:,1 )=[]; 
colnames =strcat (gn (2 :end),'_increment' ); 
case 'backwarddifference' 
X0 =triu (ones (ng ,ng )); X0 (:,end)=[]; 
colnames =strcat (gn (1 :end-1 ),'_decrement' ); 
case 'ordinal' 
X0 =tril (ones (ng ))-triu (ones (ng ),1 ); 
X0 (:,1 )=[]; 
colnames =gn (2 :end); 
otherwise
error (message ('stats:classreg:regr:modelutils:UnknownCodingMethod' ,method )); 
end

k =isnan (gidx ); 
ifany (k )
X (k ,1 :size (X0 ,2 ))=NaN ; 
k =~k ; 
X (k ,:)=X0 (gidx (k ),:); 
else
X =X0 (gidx ,:); 
end



function a =convertVar (a ,b )

ifisa (a ,'categorical' )
ifischar (b )||iscell (b )
a =cellstr (a ); 
elseifisa (b ,'categorical' )
[tf ,loc ]=ismember (a ,b ); 
a =matlab .internal .datatypes .defaultarrayLike (size (a ),'Like' ,b ); 
a (tf )=b (loc (tf )); 
else
error (message ('stats:classreg:regr:modelutils:CannotConvert' ,class (a ),class (b ))); 
end
elseifisnumeric (a )||islogical (a )
ifisnumeric (b )||islogical (b )

else
error (message ('stats:classreg:regr:modelutils:CannotConvert' ,class (a ),class (b ))); 
end
elseifiscell (a )||ischar (a )||isstring (a )
ifischar (b )||iscell (b )||isstring (b )

elseifisa (b ,'categorical' )
[tf ,loc ]=ismember (cellstr (a ),b ); 
ifiscell (a )
a =matlab .internal .datatypes .defaultarrayLike (size (a ),'Like' ,b ); 
else
a =matlab .internal .datatypes .defaultarrayLike ([size (a ,1 ),1 ],'Like' ,b ); 
end
a (tf )=b (loc (tf )); 
else
error (message ('stats:classreg:regr:modelutils:CannotConvert' ,class (a ),class (b ))); 
end
else
error (message ('stats:classreg:regr:modelutils:BadPredictorType' )); 
end
