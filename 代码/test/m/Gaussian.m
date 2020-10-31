function kernelProduct = Gaussian(svT,svInnerProduct,x) %#codegen
% GAUSSIAN function calculating the inner product of support vectors and
%   input vector using Gaussian kernel.

% Copyright 2016 The MathWorks, Inc.

coder.inline('never');

kernelProduct =  bsxfun(@plus,bsxfun(@plus,cast(-2,'like',x)*x*svT,x*x'),svInnerProduct);
kernelProduct = exp(-kernelProduct);



end