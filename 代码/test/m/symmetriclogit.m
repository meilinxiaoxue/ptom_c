function out = symmetriclogit(in)%#codegen

%   Copyright 2016-2017 The MathWorks, Inc.

out = coder.nullcopy(zeros(size(in),'like',in));

for i = 1:numel(in)
        out(i) = 2*(1/(1+exp(-in(i))))-1;
end

end
