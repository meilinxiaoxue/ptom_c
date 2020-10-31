function sOut = statsetToStruct(sIn)
% statsetToStruct - creates a statset that is
% compatible for code generation with MATLAB Coder.

% sOut = statsetToStruct(sIn) takes a statset structure sIn and converts 
% the Streams field to a struct compatilble with code generation. 
% The Streams field can contain a single RandStream object or a cell array 
% of RandStream objects. For each RandStream object, only Type, Seed and 
% NormalTransform properties are retained, whcih are sufficient for 
% reconstructing the objects.

%   Copyright 2017 The MathWorks, Inc.

sOut = sIn;
sOut.Streams = struct('Type','','Seed',0,'NormalTransform','');

for i = 1:numel(sIn.Streams)
    randStrmtemp = sIn.Streams{i};
    sOut.Streams.Type{i} = randStrmtemp.Type;
    sOut.Streams.Seed(i) = randStrmtemp.Seed;
    sOut.Streams.NormalTransform{i} = randStrmtemp.NormalTransform;
end

sOut.Streams.Type = char(sOut.Streams.Type);
sOut.Streams.NormalTransform = char(sOut.Streams.NormalTransform);

end