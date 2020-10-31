function M =wnanmean (X ,W )







W (isnan (W ))=0 ; 
W =W (:); 

X =bsxfun (@times ,X ,W ); 
tfnan =isnan (X ); 
X (tfnan )=0 ; 

Wcol =sum (bsxfun (@times ,~tfnan ,W ),1 ); 
M =sum (X ,1 )./Wcol ; 
end
