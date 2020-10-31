classdef (AllowedSubclasses ={?classreg .regr .ParametricRegression ,?classreg .regr .CompactTermsRegression ,?NonLinearModel ,?LinearMixedModel ,?GeneralizedLinearMixedModel ,?classreg .regr .LinearLikeMixedModel })CompactParametricRegression <classreg .regr .CompactPredictor 











properties (GetAccess ='public' ,SetAccess ='protected' )







Formula ='' ; 















LogLikelihood =NaN ; 













DFE =NaN ; 










SSE =NaN ; 









SST =NaN ; 











SSR =NaN ; 










CoefficientCovariance =zeros (0 ,0 ); 













CoefficientNames =cell (0 ,1 ); 
end
properties (GetAccess ='protected' ,SetAccess ='protected' )
LogLikelihoodNull =NaN ; 
Coefs =zeros (0 ,1 ); 
end
properties (Dependent ,GetAccess ='public' ,SetAccess ='protected' )










NumCoefficients 












NumEstimatedCoefficients 

























Coefficients 















Rsquared 











































ModelCriterion 
end
properties (Dependent ,GetAccess ='protected' ,SetAccess ='protected' )
CoefSE 
end

methods 
function p =get .NumCoefficients (model )
p =length (model .Coefs ); 
end
function p =get .NumEstimatedCoefficients (model )
p =model .NumObservations -model .DFE ; 
end
function tbl =get .Coefficients (model )
ifmodel .IsFitFromData 
tbl =tstats (model ); 
else
coefs =model .Coefs (:); 
se =sqrt (diag (model .CoefficientCovariance )); 
tbl =table (coefs ,se ,...
    'VariableNames' ,{'Value' ,'SE' },...
    'RowNames' ,model .CoefficientNames ); 
end
end
function rsq =get .Rsquared (model )
rsq =get_rsquared (model ); 
end
function crit =get .ModelCriterion (model )
crit =get_modelcriterion (model ); 
end

function se =get .CoefSE (model )
se =sqrt (diag (model .CoefficientCovariance )); 
end
end

methods (Access ='public' )
function CI =coefCI (model ,alpha )


















ifnargin <2 
alpha =0.05 ; 
end
se =sqrt (diag (model .CoefficientCovariance )); 
delta =se *tinv (1 -alpha /2 ,model .DFE ); 
CI =[(model .Coefs (:)-delta ),(model .Coefs (:)+delta )]; 
end


function [p ,t ,r ]=coefTest (model ,H ,c )


























nc =model .NumCoefficients ; 
ifnargin <2 

H =eye (nc ); 
end
ifnargin <3 
c =zeros (size (H ,1 ),1 ); 
end

[p ,t ,r ]=linhyptest (model .Coefs ,model .CoefficientCovariance ,c ,H ,model .DFE ); 
end
end

methods (Hidden ,Access ='public' )
function [varargout ]=subsref (a ,s )
switchs (1 ).type 
case '()' 
[varargout {1 :nargout }]=subsref @classreg .regr .CompactPredictor (a ,s ); 
case '{}' 
[varargout {1 :nargout }]=subsref @classreg .regr .CompactPredictor (a ,s ); 
case '.' 



propMethodName =s (1 ).subs ; 
ifisequal (propMethodName ,'Rsquared' )
[varargout {1 :nargout }]=lookAhead (s ,@a .get_rsquared ); 
elseifisequal (propMethodName ,'ModelCriterion' )
[varargout {1 :nargout }]=lookAhead (s ,@a .get_modelcriterion ); 
else
[varargout {1 :nargout }]=subsref @classreg .regr .CompactPredictor (a ,s ); 
end
end
end
end


methods (Access ='protected' )
function model =CompactParametricRegression ()
model .PredictorTypes ='numeric' ; 
model .ResponseType ='numeric' ; 
end


function model =noFit (model ,varNames ,coefs ,coefNames ,coefCov )
model =noFit @classreg .regr .CompactPredictor (model ,varNames ); 
model .Coefs =coefs (:); 
ncoefs =length (model .Coefs ); 
ifisempty (coefNames )
model .CoefficientNames =strcat ({'b' },num2str ((1 :ncoefs )' )); 
else
iflength (coefNames )~=ncoefs 
error (message ('stats:classreg:regr:ParametricRegression:BadCoefNameSize' )); 
end
model .CoefficientNames =coefNames (:); 
end

ifnargin <5 
model .CoefficientCovariance =zeros (ncoefs ); 
else
if~isequal (size (coefCov ),[ncoefs ,ncoefs ])
error (message ('stats:classreg:regr:ParametricRegression:BadCovarianceSize' )); 
end
[~,p ]=cholcov (coefCov ); 
ifp >0 
error (message ('stats:classreg:regr:ParametricRegression:BadCovarianceMatrix' )); 
end
model .CoefficientCovariance =coefCov ; 
end
end


function [f ,p ]=fTest (model )

ssr =model .SST -model .SSE ; 
nobs =model .NumObservations ; 
dfr =model .NumEstimatedCoefficients -1 ; 
dfe =nobs -1 -dfr ; 
f =(ssr ./dfr )/(model .SSE /dfe ); 
p =fcdf (1 ./f ,dfe ,dfr ); 
end


function tbl =tstats (model )
tbl =classreg .regr .modelutils .tstats (model .Coefs ,sqrt (diag (model .CoefficientCovariance )),...
    model .NumObservations ,model .CoefficientNames ); 
end
function crit =get_rsquared (model ,type )
stats =struct ('SSE' ,model .SSE ,...
    'SST' ,model .SST ,...
    'DFE' ,model .DFE ,...
    'NumObservations' ,model .NumObservations ,...
    'LogLikelihood' ,model .LogLikelihood ,...
    'LogLikelihoodNull' ,model .LogLikelihoodNull ); 
ifnargin <2 
crit =classreg .regr .modelutils .rsquared (stats ,{'Ordinary' ,'Adjusted' },true ); 
else
crit =classreg .regr .modelutils .rsquared (stats ,type ); 
end
end
function crit =get_modelcriterion (model ,type )
ifnargin <2 
crit =classreg .regr .modelutils .modelcriterion (model ,'all' ,true ); 
else
crit =classreg .regr .modelutils .modelcriterion (model ,type ); 
end
end
end

methods (Abstract ,Access ='protected' )
L =getlogLikelihood (model )
end
methods (Abstract ,Hidden ,Access ='public' )
v =varianceParam (model )
end
end

function b =lookAhead (s ,accessor )
if~isscalar (s )&&isequal (s (2 ).type ,'.' )
subs =s (2 ).subs ; 
ifstrcmp (subs ,'Properties' )
b =accessor (); 
s =s (2 :end); 
else
b =accessor (subs ); 
s =s (3 :end); 
end
else
b =accessor (); 
s =s (2 :end); 
end
if~isempty (s )
b =subsref (b ,s ); 
end
end


