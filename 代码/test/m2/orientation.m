function obsInRows =orientation (varargin )



[obsIn ,~,~]=...
    internal .stats .parseArgs ({'observationsin' },{'rows' },varargin {:}); 
obsIn =validatestring (obsIn ,{'rows' ,'columns' },...
    'classreg.learning.internal.orientation' ,'ObservationsIn' ); 
obsInRows =strcmp (obsIn ,'rows' ); 

end
