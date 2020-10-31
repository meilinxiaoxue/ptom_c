function out = symmetricismax(in)%#codegen

%   Copyright 2016-2017 The MathWorks, Inc.
[N,K] = size(in);
if coder.internal.indexInt(K) == 1
    out = ones(coder.internal.indexInt(N),coder.internal.indexInt(K),'like',in);
    return;
else
    out = -1*ones(coder.internal.indexInt(N),coder.internal.indexInt(K),'like',in);
end

for n=1:coder.internal.indexInt(N)
    inmax = in(n,1);
    inmaxind = coder.internal.indexInt(1);
    for k = 2:coder.internal.indexInt(K)
        if in(n,k)> inmax
            inmax = in(n,k);
            inmaxind = coder.internal.indexInt(k);
        end
    end
    out(n,inmaxind) = 1; 
end
end

