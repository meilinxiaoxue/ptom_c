function D2 = calcDistance(XN,XM,usepdist,makeposIn) %#codegen

%CALCDISTANCE Utility to compute the squared Euclidean distance between rows of XN and XM.
%   D2 = calcDistance(XN,XM,usepdist) takes a N-by-d matrix XN, a M-by-d
%   matrix XM and computes a N-by-M matrix D2 such that:
%
%   D2(i,j) = (XN(i,:) - XM(j,:))*(XN(i,:) - XM(j,:))';
%
%   usepdist is a logical flag. If true, pdist2 is used for distance
%   computations. If false, D2(i,j) is expanded into 3 separate terms and
%   then evaluated. This expansion strategy permits the use of level-3 BLAS
%   but is inaccurate if XN(i,k) or XM(j,k) are large relative to the
%   difference XN(i,k) - XM(j,k). For higher accuracy, usepdist should be
%   true and for higher speed, usepdist should be false. Output D2 is
%   guaranteed to be >= 0.
%
%   D2 = calcDistance(XN,XM,usepdist,makepos) also accepts a logical scalar
%   makepos indicating whether D2 should be forced to be >= 0 or not. If
%   makepos is true, we ensure that elements of D2 are >= 0. Note that
%   theoretically speaking, D2 should be >= 0 but for the BLAS approach,
%   roundoff error can cause D2 to be negative and this could be a problem
%   for certain kernel functions - for example Matern32/Matern52.

%   Copyright 2017 The MathWorks, Inc.

coder.inline('always');

% 1. Is makepos given to us?
if nargin < 4
    % makepos is not given - ensure that D2 >= 0.
    makepos = true;
else
    makepos = makeposIn;
end

% 2. Distance calculation.
if usepdist
    % Directly use pdist.
    %     D2 = (pdist2(XN,XM)).^2;
    D2 = (pdist2(XN,XM,'squaredeuclidean'));
else
    D2 = bsxfun(@plus,bsxfun(@plus,sum(XN.^2,2),-2*XN*XM'),sum(XM.^2,2)');
    if makepos
        D2 = max(0,D2);
    end
end
end