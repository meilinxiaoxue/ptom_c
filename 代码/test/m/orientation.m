function obsInRows = orientation(varargin)

%   Copyright 2015 The MathWorks, Inc.

[obsIn,~,~] = ...
    internal.stats.parseArgs({'observationsin'},{'rows'},varargin{:});
obsIn = validatestring(obsIn,{'rows' 'columns'},...
    'classreg.learning.internal.orientation','ObservationsIn');
obsInRows = strcmp(obsIn,'rows');

end
