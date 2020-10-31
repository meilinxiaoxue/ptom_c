function out = step(in,lo,hi,p)%#codegen

%   Copyright 2017 The MathWorks, Inc.

out = zeros(size(in),'like',in);
N   = size(in,1);
for ii = 1:coder.internal.indexInt(N)
    s = in(ii,2);
    if s>hi
       out(ii,2) = 1;
    elseif  s<lo
       out(ii,1) = 1; 
    else
        out(ii,1) = 1-p;
        out(ii,2) = p;
    end
end
end