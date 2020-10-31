function D2 = calcDistanceARD(XN,XM,usepdist,makepos,r)
%CALCDISTANCEARD Utility to compute feature-wise squared Euclidean distance between rows of XN and XM.
%   D2 = calcDistanceARD(XN,XM,usepdist) takes a N-by-d matrix XN, a M-by-d 
%   matrix XM and computes a N-by-M-by-d matrix D2 such that:
%
%   D2(i,j,r) = (XN(i,r) - XM(j,r))*(XN(i,r) - XM(j,r))
%
%   If usepdist is true then pdist2 is used for computations, otherwise, D2
%   is computed by expansion into 3 separate terms which permits the use of
%   level-3 BLAS. Set usepdist to true for higher accuracy and set usepdist
%   to false for higher speed. The output D2 is guaranteed to be >= 0.
%
%   D2 = calcDistanceARD(XN,XM,usepdist,makepos) accepts a logical scalar
%   makepos indicating whether D2 should be forced to be >= 0. Note that in
%   theory, D2 should always be >= 0 but the BLAS computation can sometimes
%   result in D2 that is negative due to roundoff error. It is important to
%   ensure that D2 is >= 0 for certain kernel functions like Matern32. If
%   makepos is true then we ensure that D2 is >= 0.
%
%   D2 = calcDistanceARD(XN,XM,usepdist,makepos,r) where r is an integer
%   between 1 and d returns a N-by-M matrix D2 computed using only the r th
%   feature.
%
%   D2(i,j) = (XN(i,r) - XM(j,r))*(XN(i,r) - XM(j,r))
    
%   Copyright 2014-2015 The MathWorks, Inc.

    % 1. Is makepos given to us?
    if nargin < 4
        % makepos is not given - ensure that D2 >= 0.
        makepos = true;
    end

    % 2. Is r given to us?
    if nargin < 5
        % r not supplied.
        [N,d]  = size(XN);
        M      = size(XM,1);
        D2     = zeros(N,M,d);
        
        for r = 1:d
            D2(:,:,r) = classreg.learning.gputils.calcDistance(XN(:,r),XM(:,r),usepdist,makepos);
        end
    else
        % r supplied.
        D2 = classreg.learning.gputils.calcDistance(XN(:,r),XM(:,r),usepdist,makepos);
    end
end