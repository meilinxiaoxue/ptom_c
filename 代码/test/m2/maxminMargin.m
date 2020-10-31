function [alpha ,maxminM ,exitflag ]=maxminMargin (M ,alphaBounds ,alpha0 ,verbose )

























[N ,T ]=size (M ); 

ifnargin <2 ||isempty (alphaBounds )
alphaBounds =[0 ,1 ]; 
end

ifnargin <3 ||isempty (alpha0 )
alpha0 =repmat (1 /T ,T ,1 ); 
else
alpha0 =alpha0 /sum (alpha0 ); 
alpha0 =alpha0 (:); 
end

ifnargin <4 ||isempty (verbose )
verbose =0 ; 
end


ifverbose >0 
minM =min (M *alpha0 ); 
maxM =max (M *alpha0 ); 
fprintf ('%s\n' ,getString (message ('stats:classreg:learning:internal:maxminMargin:MarginsBefore' ,...
    minM ,maxM ))); 
end


A =[-M ,ones (N ,1 )]; 
b =zeros (N ,1 ); 
f =[zeros (T ,1 ); -1 ]; 
Aeq =[ones (1 ,T ),0 ]; 
beq =1 ; 
lb =[repmat (alphaBounds (1 ),T ,1 ); T *min (M (:))]; 
ub =[repmat (alphaBounds (2 ),T ,1 ); T *max (M (:))]; 
x0 =[alpha0 ; 1 ]; 
options =optimset ('Algorithm' ,'interior-point' ); 
switchverbose 
case 0 
options .Display ='off' ; 
case 1 
options .Display ='final' ; 
case 2 
options .Display ='iter' ; 
otherwise
error (message ('stats:classreg:learning:internal:maxminMargin:BadVerbose' )); 
end
[alpha ,~,exitflag ]=linprog (f ,A ,b ,Aeq ,beq ,lb ,ub ,x0 ,options ); 


maxminM =lb (end); 
ifexitflag <0 
return ; 
end
ifisempty (alpha )
exitflag =-1 ; 
return ; 
end
maxminM =alpha (end); 
alpha (end)=[]; 


alpha (alpha <0 )=0 ; 
alpha (alpha >1 )=1 ; 
ifall (alpha ==0 )||any (isnan (alpha ))
exitflag =-1 ; 
return ; 
end
alpha =alpha /sum (alpha ); 


ifverbose >0 
minM =min (M *alpha ); 
maxM =max (M *alpha ); 
fprintf ('%s\n' ,getString (message ('stats:classreg:learning:internal:maxminMargin:MarginsAfter' ,...
    sprintf ('%g' ,minM ),sprintf ('%g' ,maxM )))); 
end
end
