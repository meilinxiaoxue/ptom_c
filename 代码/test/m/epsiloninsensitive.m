function loss = epsiloninsensitive(Y,Yfit,W,epsilon)
%   Copyright 2015 The MathWorks, Inc.

% Compute epsislon-insensitive loss for SVM regression
% loss is the weighted mean of max(0, abs(Yfit-Y)-epsilon)
notNaN = ~isnan(Yfit);
loss = sum(W(notNaN) .* max(0,abs(Yfit(notNaN)-Y(notNaN))-epsilon)) / sum(W(notNaN));
end
