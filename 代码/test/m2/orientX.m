function [X ,varargin ]=orientX (X ,expectedObsInRows ,varargin )



[obsIn ,~,varargin ]=...
    internal .stats .parseArgs ({'observationsin' },{'rows' },varargin {:}); 
obsIn =validatestring (obsIn ,{'rows' ,'columns' },...
    'classreg.learning.internal.orientX' ,'ObservationsIn' ); 
obsInRows =strcmp (obsIn ,'rows' ); 

ifexpectedObsInRows ~=obsInRows 
X =X ' ; 
end

end
