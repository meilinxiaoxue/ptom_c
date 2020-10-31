function [W ,exitflag ]=erweight (M ,gamma ,W0 ,Wdist ,verbose )
























[T ,N ]=size (M ); 

ifnargin <3 ||isempty (W0 )
W0 =repmat (1 /N ,N ,1 ); 
else
W0 =W0 /sum (W0 ); 
W0 =W0 (:); 
end

ifnargin <4 ||isempty (Wdist )
Wdist =repmat (1 /N ,N ,1 ); 
else
Wdist =Wdist /sum (Wdist ); 
Wdist =Wdist (:); 
end

ifnargin <5 ||isempty (verbose )
verbose =0 ; 
end

f =1 +log (W0 ./Wdist ); 
W =W0 ; 
invW =1 ./W0 ; 

ifany (isnan (f ))||any (isinf (f ))||any (isnan (invW ))||any (isinf (invW ))
exitflag =-1 ; 
return ; 
end
H =spdiags (invW ,0 ,speye (numel (invW ))); 

options =optimset ('Algorithm' ,'interior-point-convex' ); 
switchverbose 
case 0 
options .Display ='off' ; 
case 1 
options .Display ='final' ; 
case 2 
options .Display ='iter' ; 
otherwise
error (message ('stats:classreg:learning:internal:erweight:BadVerbose' )); 
end
[delta ,~,exitflag ]=quadprog (H ,f ,M ,repmat (gamma ,T ,1 )-M *W0 ,...
    ones (1 ,N ),0 ,-W0 ,1 -W0 ,zeros (N ,1 ),options ); 

ifexitflag <0 
return ; 
end
ifnumel (delta )~=numel (W0 )
exitflag =-1 ; 
return ; 
end

W =W0 +delta ; 

W (W <0 )=0 ; 
W (W >1 )=1 ; 
ifall (W ==0 )||any (isnan (W ))
exitflag =-1 ; 
return ; 
end
W =W /sum (W ); 

end
