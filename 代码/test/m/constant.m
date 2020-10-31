function out = constant(in,cls)%#codegen

%   Copyright 2017 The MathWorks, Inc.

out = zeros(size(in),'like',in);
N   = size(in,1);
for ii = 1:coder.internal.indexInt(N)
    out(ii,cls) = 1;
end
end