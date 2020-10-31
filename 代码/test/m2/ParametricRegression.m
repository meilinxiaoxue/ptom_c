classdef (AllowedSubclasses ={?classreg .regr .TermsRegression ,?NonLinearModel ,?LinearMixedModel ,?GeneralizedLinearMixedModel ,?classreg .regr .LinearLikeMixedModel })ParametricRegression <classreg .regr .Predictor &classreg .regr .CompactParametricRegression 











properties (Dependent ,GetAccess ='protected' ,SetAccess ='protected' )


y_r 
w_r 
end

methods 
function y_r =get .y_r (model )
ifisempty (model .WorkingValues )
y_r =create_y_r (model ); 
else
y_r =model .WorkingValues .y_r ; 
end
end
function w_r =get .w_r (model )
ifisempty (model .WorkingValues )
w_r =create_w_r (model ); 
else
w_r =model .WorkingValues .w_r ; 
end
end
end

methods (Hidden ,Access ='public' )
function [varargout ]=subsref (a ,s )
switchs (1 ).type 
case '()' 
[varargout {1 :nargout }]=subsref @classreg .regr .Predictor (a ,s ); 
case '{}' 
[varargout {1 :nargout }]=subsref @classreg .regr .Predictor (a ,s ); 
case '.' 



propMethodName =s (1 ).subs ; 
ifisequal (propMethodName ,'Residuals' )
[varargout {1 :nargout }]=lookAhead (s ,@a .get_residuals ); 
elseifisequal (propMethodName ,'Fitted' )
[varargout {1 :nargout }]=lookAhead (s ,@a .get_fitted ); 
elseifisequal (propMethodName ,'Diagnostics' )
[varargout {1 :nargout }]=lookAhead (s ,@a .get_diagnostics ); 
else
[varargout {1 :nargout }]=subsref @classreg .regr .CompactParametricRegression (a ,s ); 
end
end
end
end


methods (Access ='protected' )


function model =selectObservations (model ,exclude ,missing )
ifnargin <3 
missing =[]; 
end
model =selectObservations @classreg .regr .Predictor (model ,exclude ,missing ); 


model .WorkingValues .y_r =create_y_r (model ); 
model .WorkingValues .w_r =create_w_r (model ); 
end


function model =postFit (model )
model =postFit @classreg .regr .Predictor (model ); 
subset =model .ObservationInfo .Subset ; 
resid_r =get_residuals (model ,'raw' ); 
resid_r =resid_r (subset ); 
yfit_r =predict (model ); 
yfit_r =yfit_r (subset ); 
W_r =model .w_r ; 
sumw =sum (W_r ); 
wtdymean =sum (W_r .*model .y_r )/sumw ; 
model .SSE =sum (W_r .*resid_r .^2 ); 
model .SSR =sum (W_r .*(yfit_r -wtdymean ).^2 ); 
model .SST =sum (W_r .*(model .y_r -wtdymean ).^2 ); 
model .LogLikelihood =getlogLikelihood (model ); 
model .LogLikelihoodNull =logLikelihoodNull (model ); 
end


function y_r =create_y_r (model )
subset =model .ObservationInfo .Subset ; 
y =getResponse (model ); 
y_r =y (subset ); 
end
function w_r =create_w_r (model )
subset =model .ObservationInfo .Subset ; 
w_r =model .ObservationInfo .Weights (subset ); 
end
end

methods (Abstract ,Access ='protected' )
model =fitter (model )
L0 =logLikelihoodNull (model )
end
methods (Abstract ,Static ,Access ='public' )
model =fit (varargin )
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


