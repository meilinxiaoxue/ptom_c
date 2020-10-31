function Value = parseArg(ArgName, Args)
    
%   Copyright 2016 The MathWorks, Inc.

[Value, ~, ~] = internal.stats.parseArgs({ArgName}, {[]}, Args{:});
end
