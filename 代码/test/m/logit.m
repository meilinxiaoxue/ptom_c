function out = logit(in)%#codegen

%   Copyright 2016-2017 The MathWorks, Inc.

out = coder.nullcopy(zeros(size(in),'like',in));

for i = 1:numel(in)
        out(i) = 1/(1+exp(-in(i)));
end

end
