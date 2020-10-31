function C =wcov (X ,w ,biased )












ifnargin <3 
biased =false ; 
end
w =w (:)/sum (w ); 
Y =bsxfun (@minus ,X ,w ' *X ); 
C =Y ' *bsxfun (@times ,Y ,w ); 

if~biased 
C =C /(1 -w ' *w ); 
end


constCols =~var (X ); 
C (constCols ,:)=0 ; 
C (:,constCols )=0 ; 



C =tril (C )+tril (C ,-1 )' ; 
end














