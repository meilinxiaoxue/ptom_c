function out = rdivideFinite(num,den)
%#codegen
%RDIVIDE local function to calculate reciprocal function for D and S.
% Replaces 1/0 elements with 0.
% In MATLAB implementation, this is achieved by replacing 0 elements in D
% and S by inf, so that 1/inf would become 0.

    out = zeros(size(den),'like',den);
    for ii = 1:coder.internal.indexInt(numel(out))
       if (den(ii) ~= 0)
          out(ii) = num(ii)/den(ii); 
       end
    end
end