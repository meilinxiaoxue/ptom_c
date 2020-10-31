function e =classifedge (C ,Sfit ,W ,cost )





m =classreg .learning .loss .classifmargin (C ,Sfit ); 


notNaN =~isnan (m ); 
e =sum (W (notNaN ).*m (notNaN ))/sum (W (notNaN )); 
end
