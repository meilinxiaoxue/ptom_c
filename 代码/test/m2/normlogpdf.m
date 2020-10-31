function y =normlogpdf (x ,mu ,sigma )

















ifnargin <1 
error (message ('stats:normpdf:TooFewInputs' )); 
end
ifnargin <2 
mu =0 ; 
end
ifnargin <3 
sigma =1 ; 
end


sigma (sigma <=0 )=NaN ; 

try
y =-0.5 *(((x -mu )./sigma ).^2 +log (2 *pi ))-log (sigma ); 
catch 
error (message ('stats:normpdf:InputSizeMismatch' )); 
end
end
