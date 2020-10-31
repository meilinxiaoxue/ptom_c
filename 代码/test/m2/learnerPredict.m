function [labels ,scores ]=learnerPredict (obj ,X ,obsInRows )
%#codegen 
ifobsInRows 
[labels ,scores ]=predict (obj ,X ); 
else
[labels ,scores ]=predict (obj ,X ,'ObservationsIn' ,'columns' ); 
end