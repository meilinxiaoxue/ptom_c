function tf = observationsInColumns(Args)
% Return true iff the Args contain the 'ObservationsIn' name with the
% 'columns' value. Use partial matching of the legal values.
[passed, ~, ~] = internal.stats.parseArgs({'ObservationsIn'}, {'notpassed'}, Args{:});
if isequal(passed, 'notpassed')
    tf = false;
else
    RepairedString = bayesoptim.parseArgValue(passed, {'rows','columns'});
    tf = isequal(RepairedString, 'columns');
end
end
