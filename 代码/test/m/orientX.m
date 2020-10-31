function [X,varargin] = orientX(X,expectedObsInRows,varargin)

%   Copyright 2015 The MathWorks, Inc.

[obsIn,~,varargin] = ...
    internal.stats.parseArgs({'observationsin'},{'rows'},varargin{:});
obsIn = validatestring(obsIn,{'rows' 'columns'},...
    'classreg.learning.internal.orientX','ObservationsIn');
obsInRows = strcmp(obsIn,'rows');

if expectedObsInRows~=obsInRows
    X = X';
end

end
