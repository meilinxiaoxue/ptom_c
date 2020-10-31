function out = invlogit(in)%#codegen

%   Copyright 2016-2017 The MathWorks, Inc.

out = coder.nullcopy(zeros(size(in),'like',in));
for i = 1:coder.internal.indexInt(numel(in))
    if in(i) == 0
        out(i) = -coder.internal.inf;
    elseif in(i) == 1
        out(i) = coder.internal.inf;
    elseif  isnan(in(i))
        out(i) = coder.internal.nan;
    else
        out(i) = log(in(i)/(1-in(i)));
    end
end

end
