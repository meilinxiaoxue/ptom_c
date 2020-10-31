function loss =mse (Y ,Yfit ,W )




notNaN =~isnan (Yfit ); 
loss =sum (W (notNaN ).*(Y (notNaN )-Yfit (notNaN )).^2 )/sum (W (notNaN )); 
end
