function X = encodeCategorical(X,vrange)
%encodeCategorical Encode categorical columns into group numbers.
%    XOUT = encodeCategorical(XIN,VRANGE) accepts an input data matrix XIN
%    and a VariableRange cell array VRANGE, and returns an output data
%    matrix XOUT. For each column in XIN that has an entry in the VRANGE
%    array, the corresponding column in XOUT is the group number.

%   Copyright 2015 The MathWorks, Inc.
for j=1:size(X,2)
    if ~isempty(vrange{j})
        [~,x] = ismember(X(:,j),vrange{j});
        x(x==0) = NaN;
        X(:,j) = x;
    end
end