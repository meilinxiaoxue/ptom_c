function out = sign(in)%#codegen

%   Copyright 2016-2017 The MathWorks, Inc.

out = coder.nullcopy(zeros(size(in),'like',in));

for i = 1:numel(in)
    if in(i) < 0
        out(i) = -1;
    elseif in(i) > 0
        out(i) = 1;
    else
        out(i) = 0;
    end
end
