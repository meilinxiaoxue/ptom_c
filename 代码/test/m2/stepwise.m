function model =stepwise (X ,varargin )







[X ,y ,haveDataset ,otherArgs ]=LinearModel .handleDataArgs (X ,varargin {:}); 


paramNames ={'Intercept' ,'PredictorVars' ,'ResponseVar' ,'Weights' ,'Exclude' ,'CategoricalVars' ...
    ,'VarNames' ,'Lower' ,'Upper' ,'Criterion' ,'PEnter' ,'PRemove' ,'NSteps' ,'Verbose' }; 
paramDflts ={true ,[],[],[],[],[],[],'constant' ,'interactions' ,'SSE' ,[],[],Inf ,1 }; 


ifisempty (otherArgs )
start ='constant' ; 
else
arg1 =otherArgs {1 }; 
ifmod (length (otherArgs ),2 )==1 
start =arg1 ; 
otherArgs (1 )=[]; 
elseifinternal .stats .isString (arg1 )&&...
    any (strncmpi (arg1 ,paramNames ,length (arg1 )))

start ='constant' ; 
end
end

[intercept ,predictorVars ,responseVar ,weights ,exclude ,asCatVar ,...
    varNames ,lower ,upper ,crit ,penter ,premove ,nsteps ,verbose ,supplied ]=...
    internal .stats .parseArgs (paramNames ,paramDflts ,otherArgs {:}); 

[penter ,premove ]=classreg .regr .TermsRegression .getDefaultThresholds (crit ,penter ,premove ); 

if~isscalar (verbose )||~ismember (verbose ,0 :2 )
error (message ('stats:LinearModel:BadVerbose' )); 
end




if~supplied .ResponseVar &&(classreg .regr .LinearFormula .isTermsMatrix (start )||classreg .regr .LinearFormula .isModelAlias (start ))
ifisa (lower ,'classreg.regr.LinearFormula' )
responseVar =lower .ResponseName ; 
supplied .ResponseVar =true ; 
else
ifinternal .stats .isString (lower )&&~classreg .regr .LinearFormula .isModelAlias (lower )
lower =LinearModel .createFormula (supplied ,lower ,X ,...
    predictorVars ,responseVar ,intercept ,varNames ,haveDataset ); 
responseVar =lower .ResponseName ; 
supplied .ResponseVar =true ; 
elseifisa (upper ,'classreg.regr.LinearFormula' )
responseVar =upper .ResponseName ; 
supplied .ResponseVar =true ; 
else
ifinternal .stats .isString (upper )&&~classreg .regr .LinearFormula .isModelAlias (upper )
upper =LinearModel .createFormula (supplied ,upper ,X ,...
    predictorVars ,responseVar ,intercept ,varNames ,haveDataset ); 
responseVar =upper .ResponseName ; 
supplied .ResponseVar =true ; 
end
end
end
end

if~isa (start ,'classreg.regr.LinearFormula' )
ismodelalias =classreg .regr .LinearFormula .isModelAlias (start ); 
start =LinearModel .createFormula (supplied ,start ,X ,...
    predictorVars ,responseVar ,intercept ,varNames ,haveDataset ); 
else
ismodelalias =false ; 
end

if~isa (lower ,'classreg.regr.LinearFormula' )
ifclassreg .regr .LinearFormula .isModelAlias (lower )
ifsupplied .PredictorVars 
lower ={lower ,predictorVars }; 
end
end
lower =classreg .regr .LinearFormula (lower ,start .VariableNames ,start .ResponseName ,start .HasIntercept ,start .Link ); 
end
if~isa (upper ,'classreg.regr.LinearFormula' )
ifclassreg .regr .LinearFormula .isModelAlias (upper )
ifsupplied .PredictorVars 
upper ={upper ,predictorVars }; 
end
end
upper =classreg .regr .LinearFormula (upper ,start .VariableNames ,start .ResponseName ,start .HasIntercept ,start .Link ); 
end

ifisa (X ,'table' )
isNumVar =varfun (@isnumeric ,X ,'OutputFormat' ,'uniform' ); 
isNumVec =isNumVar &varfun (@isvector ,X ,'OutputFormat' ,'uniform' ); 
isCatVec =varfun (@internal .stats .isDiscreteVec ,X ,'OutputFormat' ,'uniform' ); 
isValidVar =isNumVec |isCatVec ; 
ifany (~isValidVar )
[start ,isRs ]=removeBadVars (start ,isValidVar ); 
[lower ,isRl ]=removeBadVars (lower ,isValidVar ); 
[upper ,isRu ]=removeBadVars (upper ,isValidVar ); 
ifisRs ||isRl ||isRu 
warning (message ('stats:classreg:regr:modelutils:BadVariableType' )); 
end
end
end



nvars =size (X ,2 ); 
ifhaveDataset 
isCat =varfun (@internal .stats .isDiscreteVar ,X ,'OutputFormat' ,'uniform' ); 
else
isCat =[repmat (internal .stats .isDiscreteVar (X ),1 ,nvars ),internal .stats .isDiscreteVar (y )]; 
nvars =nvars +1 ; 
end
if~isempty (asCatVar )
isCat =classreg .regr .FitObject .checkAsCat (isCat ,asCatVar ,nvars ,haveDataset ,start .VariableNames ); 
end
ifany (isCat )
start =removeCategoricalPowers (start ,isCat ,ismodelalias ); 
lower =removeCategoricalPowers (lower ,isCat ,ismodelalias ); 
upper =removeCategoricalPowers (upper ,isCat ,ismodelalias ); 
end

ifhaveDataset 
model =LinearModel .fit (X ,start .Terms ,'ResponseVar' ,start .ResponseName ,...
    'Weights' ,weights ,'Exclude' ,exclude ,'CategoricalVars' ,asCatVar ,'RankWarn' ,false ); 
else
model =LinearModel .fit (X ,y ,start .Terms ,'ResponseVar' ,start .ResponseName ,...
    'Weights' ,weights ,'Exclude' ,exclude ,'CategoricalVars' ,asCatVar ,...
    'VarNames' ,start .VariableNames ,'RankWarn' ,false ); 
end

model .Steps .Start =start ; 
model .Steps .Lower =lower ; 
model .Steps .Upper =upper ; 
model .Steps .Criterion =crit ; 
model .Steps .PEnter =penter ; 
model .Steps .PRemove =premove ; 
model .Steps .History =[]; 

model =stepwiseFitter (model ,nsteps ,verbose ); 
checkDesignRank (model ); 
end
