function loss =epsiloninsensitive (Y ,Yfit ,W ,epsilon )




notNaN =~isnan (Yfit ); 
loss =sum (W (notNaN ).*max (0 ,abs (Yfit (notNaN )-Y (notNaN ))-epsilon ))/sum (W (notNaN )); 
end
