function tf =observationsInColumns (Args )


[passed ,~,~]=internal .stats .parseArgs ({'ObservationsIn' },{'notpassed' },Args {:}); 
ifisequal (passed ,'notpassed' )
tf =false ; 
else
RepairedString =bayesoptim .parseArgValue (passed ,{'rows' ,'columns' }); 
tf =isequal (RepairedString ,'columns' ); 
end
end
