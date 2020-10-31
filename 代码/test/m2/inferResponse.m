function [y ,args ]=inferResponse (respname ,x ,varargin )























ifistable (x )||isa (x ,'dataset' )


ifmod (length (varargin ),2 )==0 
varargin =[{respname },varargin ]; 
end
y =varargin {1 }; 
ifinternal .stats .isString (y )&&size (x ,1 )>1 

try
y =x .(y ); 
catch me 
error (message ('stats:classreg:learning:internal:utils:InvalidResponse' ,varargin {1 })); 
end
elseifistable (y )
ifsize (y ,2 )==1 
y =y {:,1 }; 
else
error (message ('stats:classreg:learning:internal:utils:InvalidResponseTable' )); 
end
end
args =varargin (2 :end); 
else

ifisempty (varargin )
error (message ('stats:classreg:learning:internal:utils:MissingResponse' ,respname )); 
end

y =varargin {1 }; 
args =varargin (2 :end); 
end

