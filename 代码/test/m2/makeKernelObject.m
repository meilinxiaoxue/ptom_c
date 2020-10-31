function [theta0 ,kernel ,isbuiltin ]=makeKernelObject (kFcn ,kParams )



















































































ifinternal .stats .isString (kFcn )
import classreg.learning.modelparams.GPParams ; 
switchlower (kFcn )
case lower (GPParams .Exponential )
theta0 =log (kParams ); 
kernel =classreg .learning .gputils .Exponential .makeFromTheta (theta0 ); 
isbuiltin =true ; 
case lower (GPParams .SquaredExponential )
theta0 =log (kParams ); 
kernel =classreg .learning .gputils .SquaredExponential .makeFromTheta (theta0 ); 
isbuiltin =true ; 
case lower (GPParams .Matern32 )
theta0 =log (kParams ); 
kernel =classreg .learning .gputils .Matern32 .makeFromTheta (theta0 ); 
isbuiltin =true ; 
case lower (GPParams .Matern52 )
theta0 =log (kParams ); 
kernel =classreg .learning .gputils .Matern52 .makeFromTheta (theta0 ); 
isbuiltin =true ; 
case lower (GPParams .RationalQuadratic )
theta0 =log (kParams ); 
kernel =classreg .learning .gputils .RationalQuadratic .makeFromTheta (theta0 ); 
isbuiltin =true ; 
case lower (GPParams .ExponentialARD )
theta0 =log (kParams ); 
kernel =classreg .learning .gputils .ExponentialARD .makeFromTheta (theta0 ); 
isbuiltin =true ; 
case lower (GPParams .SquaredExponentialARD )
theta0 =log (kParams ); 
kernel =classreg .learning .gputils .SquaredExponentialARD .makeFromTheta (theta0 ); 
isbuiltin =true ; 
case lower (GPParams .Matern32ARD )
theta0 =log (kParams ); 
kernel =classreg .learning .gputils .Matern32ARD .makeFromTheta (theta0 ); 
isbuiltin =true ; 
case lower (GPParams .Matern52ARD )
theta0 =log (kParams ); 
kernel =classreg .learning .gputils .Matern52ARD .makeFromTheta (theta0 ); 
isbuiltin =true ; 
case lower (GPParams .RationalQuadraticARD )
theta0 =log (kParams ); 
kernel =classreg .learning .gputils .RationalQuadraticARD .makeFromTheta (theta0 ); 
isbuiltin =true ; 
otherwise
theta0 =[]; 
kernel =[]; 
isbuiltin =false ; 
end
elseifisa (kFcn ,'function_handle' )
theta0 =kParams ; 
kernel =classreg .learning .gputils .CustomKernel .makeFromTheta (theta0 ,kFcn ); 
isbuiltin =false ; 
else
theta0 =[]; 
kernel =[]; 
isbuiltin =false ; 
end
end
