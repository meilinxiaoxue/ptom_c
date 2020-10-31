function temp =templateLinear (varargin )














































































ifnargin >0 
[varargin {:}]=convertStringsToChars (varargin {:}); 
end

[type ,learner ,~,extra ]=internal .stats .parseArgs ({'type' ,'learner' },{'' ,'' },varargin {:}); 

doclass =[]; 

if~isempty (type )
type =validatestring (type ,{'classification' ,'regression' },...
    'templateLinear' ,'Type' ); 
doclass =strcmp (type ,'classification' ); 
end

if~isempty (learner )
learner =validatestring (learner ,{'leastsquares' ,'logistic' ,'svm' },...
    'templateLinear' ,'Learner' ); 
else
ifisempty (type )
learner ='svm' ; 
doclass =true ; 
end
end

ifstrncmpi (learner ,'leastsquares' ,length (learner ))
if~isempty (doclass )&&doclass 
error (message ('stats:templateLinear:BadClassificationLearner' )); 
end
temp =RegressionLinear .template ('Learner' ,'leastsquares' ,extra {:}); 
elseifstrncmpi (learner ,'logistic' ,length (learner ))
if~isempty (doclass )&&~doclass 
error (message ('stats:templateLinear:BadRegressionLearner' )); 
end
temp =ClassificationLinear .template ('Learner' ,'logistic' ,extra {:}); 
elseifstrncmpi (learner ,'svm' ,length (learner ))
ifisempty (doclass )||doclass 
temp =ClassificationLinear .template ('Learner' ,'svm' ,extra {:}); 
else
temp =RegressionLinear .template ('Learner' ,'svm' ,extra {:}); 
end
else
error (message ('stats:templateLinear:BadLearner' )); 
end

end
