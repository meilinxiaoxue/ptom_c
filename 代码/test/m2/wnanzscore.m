function [z ,mu ,sigma ]=wnanzscore (x ,w ,biased )



















ifisequal (x ,[]),z =[]; return ; end


ifnargin <3 
biased =0 ; 
end


mu =classreg .learning .internal .wnanmean (x ,w ); 
sigma =sqrt (classreg .learning .internal .wnanvar (x ,w ,~biased )); 
sigma0 =sigma ; 
sigma0 (sigma0 ==0 )=1 ; 
z =bsxfun (@minus ,x ,mu ); 
z =bsxfun (@rdivide ,z ,sigma0 ); 
end