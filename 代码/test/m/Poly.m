function kernelProduct = Poly(svT,order,x) %#codegen
% POLY function calculating the inner product of support vectors and
%   input vector using Polynomial kernel.

% Copyright 2016 The MathWorks, Inc.

coder.inline('never');
kernelProduct = x*svT+cast(1,'like',x);
temp = kernelProduct;
for i = 1 : order-1
    kernelProduct = kernelProduct.*temp;
end

end