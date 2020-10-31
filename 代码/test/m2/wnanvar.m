function V =wnanvar (X ,W ,bias )










W (isnan (W ))=0 ; 
W =W (:); 

M =classreg .learning .internal .wnanmean (X ,W ); 

X =bsxfun (@times ,bsxfun (@minus ,X ,M ).^2 ,W ); 
tfnan =isnan (X ); 
X (tfnan )=0 ; 

Wcol =sum (bsxfun (@times ,~tfnan ,W ),1 ); 

V =sum (X ,1 )./Wcol ; 

ifsize (X ,1 )>1 &&bias 
Wcol2 =sum (bsxfun (@times ,~tfnan ,W .^2 ),1 ); 
V =sum (X ,1 )./(Wcol -Wcol2 ./Wcol ); 
end
end
