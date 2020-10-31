function hfcn =makeBasisFunction (str )




























ifinternal .stats .isString (str )
import classreg.learning.modelparams.GPParams ; 
switchlower (str )
case lower (GPParams .BasisNone )
hfcn =@(X )zeros (size (X ,1 ),0 ); 
case lower (GPParams .BasisConstant )
hfcn =@(X )ones (size (X ,1 ),1 ); 
case lower (GPParams .BasisLinear )
hfcn =@(X )[ones (size (X ,1 ),1 ),X ]; 
case lower (GPParams .BasisPureQuadratic )
hfcn =@(X )[ones (size (X ,1 ),1 ),X ,X .^2 ]; 
otherwise
hfcn =[]; 
end
elseifisa (str ,'function_handle' )
hfcn =str ; 
else
hfcn =[]; 
end
end