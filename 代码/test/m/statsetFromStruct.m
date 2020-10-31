function sOut = statsetFromStruct(sIn)
% statsetFromStruct - creates a statset struct from the input struct.

% sOut = statsetFromStruct(sIn) takes a code generation-compatible struct
% and converts it into a statset struct by reconstructing the Streams
% field.

%   Copyright 2017 The MathWorks, Inc.

sOut = sIn;

[numStreams,~] = size(sIn.Streams.Type);
switch numStreams
    case 0
        sOut.Streams = cell(0,0);
        
    case 1
        sOut.Streams = RandStream(...
            sIn.Streams.Type,...
            'Seed',sIn.Streams.Seed,...
            'NormalTransform',sIn.Streams.NormalTransform);
        
    otherwise
        sOut.Streams = cell(1,numStreams);
        for i = 1:numStreams
            sOut.Streams{i} = RandStream(...
                strtrim(sIn.Streams.Type(i,:)),...
                'Seed',sIn.Streams.Seed(i),...
                'NormalTransform',strtrim(sIn.Streams.NormalTransform(i,:)));
        end
end


end