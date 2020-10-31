function C =classCount (expectedY ,observedY )











K =length (expectedY ); 
N =length (observedY ); 
C =false (N ,K ); 

[tf ,grp ]=ismember (observedY ,expectedY ); 
if~all (tf )
idx =find (~tf ,1 ,'first' ); 
ifisa (observedY ,'classreg.learning.internal.ClassLabel' )...
    ||isa (observedY ,'categorical' )||iscellstr (observedY )
str =char (observedY (idx )); 
else
str =num2str (observedY (idx ,:)); 
end
ifisa (observedY ,'classreg.learning.internal.ClassLabel' )
cls =class (labels (observedY )); 
else
cls =class (observedY ); 
end
error (message ('stats:classreg:learning:internal:classCount:UnknownClass' ,str ,cls )); 
end

C (sub2ind ([N ,K ],(1 :N )' ,grp ))=true ; 
end
