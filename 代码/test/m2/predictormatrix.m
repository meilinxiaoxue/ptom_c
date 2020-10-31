function [X ,cols2vars ,gnames ,glevels ]=predictormatrix (data ,varargin )





















































ifisa (data ,'dataset' )
data =dataset2table (data ); 
end

[nobs ,nvars ]=size (data ); 
varnames =data .Properties .VariableNames ; 

catVars =varfun (@(x )isa (x ,'categorical' )||iscellstr (x )||ischar (x )||islogical (x ),data ,'OutputFormat' ,'uniform' ); 

paramNames ={'predictorvars' ,'responsevar' ,'categoricalvars' }; 
paramDflts ={1 :(nvars -1 ),nvars ,catVars }; 
[predictorVars ,responseVar ,treatAsCategorical ,supplied ]=...
    internal .stats .parseArgs (paramNames ,paramDflts ,varargin {:}); 

haveDataset =isa (data ,'table' ); 



ifsupplied .predictorvars 
ifisnumeric (predictorVars )
ifany (predictorVars <1 )||any (predictorVars >nvars )
error (message ('stats:classreg:regr:modelutils:BadPredVarsNumeric' )); 
end
elseifislogical (predictorVars )
iflength (predictorVars )~=nvars 
error (message ('stats:classreg:regr:modelutils:BadPredVarsLogical' )); 
end
predictorVars =find (predictorVars ); 
elseifhaveDataset &&internal .stats .isStrings (predictorVars )
[~,predVarInds ]=ismember (predictorVars ,varnames ); 
ifany (predVarInds ==0 )
ind0 =find (predVarInds ==0 ,1 ,'first' ); 
error (message ('stats:classreg:regr:modelutils:BadPredVarsName' ,predictorVars {ind0 })); 
end
predictorVars =predVarInds ; 
else
ifhaveDataset 
error (message ('stats:classreg:regr:modelutils:BadPredVarsDataset' )); 
else
error (message ('stats:classreg:regr:modelutils:BadPredVarsMatrix' )); 
end
end

if~supplied .responsevar 

responseVar =setdiff (1 :nvars ,predictorVars ); 
ifnumel (responseVar )>1 
error (message ('stats:classreg:regr:modelutils:CannotDetermineResponse' )); 
end
end
end



ifsupplied .responsevar 
ifisempty (responseVar )

elseifisscalar (responseVar )&&isnumeric (responseVar )
if(responseVar <1 )||(responseVar >nvars )
error (message ('stats:classreg:regr:modelutils:BadResponseNumeric' )); 
end
elseifhaveDataset &&internal .stats .isString (responseVar )
responseVarIdx =find (strcmp (responseVar ,varnames )); 
ifisempty (responseVarIdx )
error (message ('stats:classreg:regr:modelutils:BadResponseName' ,responseVar )); 
end
responseVar =responseVarIdx ; 
else
ifhaveDataset 
error (message ('stats:classreg:regr:modelutils:BadResponseDataset' )); 
else
error (message ('stats:classreg:regr:modelutils:BadResponseMatrix' )); 
end
end

if~supplied .predictorvars 

predictorVars =setdiff (1 :nvars ,responseVar ); 
elseif~isempty (intersect (responseVar ,predictorVars ))
error (message ('stats:classreg:regr:modelutils:SamePredictorResponse' )); 
end
end

ifany (varfun (@ndims ,data ,'InputVariables' ,predictorVars ,'OutputFormat' ,'uniform' )~=2 )
error (message ('stats:classreg:regr:modelutils:TwoDimVariable' )); 
end

varClasses =varfun (@class ,data ,'InputVariables' ,predictorVars ,'OutputFormat' ,'cell' ); 
charVars =strcmp ('char' ,varClasses ); 

ncols =varfun (@(x )size (x ,2 ),data ,'InputVariables' ,predictorVars ,'OutputFormat' ,'uniform' ); 
ncols (charVars )=1 ; 

ifstrcmp ('single' ,varClasses )
outClass ='single' ; 
else
outClass ='double' ; 
end
sumncols =sum (ncols ); 
X =zeros (nobs ,sumncols ,outClass ); 
cols2vars =zeros (nvars ,sumncols ); 
gnames =cell (1 ,sumncols ); 
glevels =cell (1 ,sumncols ); 
k =0 ; 
forj =1 :length (predictorVars )
Xj =data .(varnames {predictorVars (j )}); 
kk =k +(1 :ncols (j )); 
iftreatAsCategorical (j )
[X (:,kk ),gnames {kk },glevels {kk }]=grp2idx (Xj ); 
elseifisnumeric (Xj )||islogical (Xj )
X (:,kk )=Xj ; 
else
ifcatVars (j )
error (message ('stats:classreg:regr:modelutils:CatNotContinuous' )); 
else
error (message ('stats:classreg:regr:modelutils:BadVariableType' )); 
end
end
cols2vars (j ,kk )=1 ; 
k =k +ncols (j ); 
end
