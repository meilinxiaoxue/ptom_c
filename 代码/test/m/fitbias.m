function bias = fitbias(lossfun,y,F,w,epsilon)
%fitbias Fit bias of a supervised model.
%   BIAS=FITBIAS(LOSSFUN,Y,F,W,EPSILON) estimates bias between model
%   predictions F and observed responses Y using observation weights W for
%   models fitted by minimizing loss LOSSFUN. Pass LOSSFUN as a string, one
%   of: 'logit', 'hinge', 'mse' or 'epsiloninsensitive'. Pass Y as a
%   column-vector of floating-point values. Pass F as an N-by-L
%   floating-point matrix for N observations (elements in Y) and L models.
%   Pass W as a floating-point vector with N elements. Pass EPSILON as a
%   floating-point non-negative scalar (this parameter only has effect for
%   the 'epsiloninsensitive' loss).
%
%   For classification models ('logit' or 'hinge' loss), the bias estimate
%   is found by locating a threshold on classification score for which
%   maximal accuracy is attained. For least squares ('mse' loss), the bias
%   estimate is found by weighted averaging of the difference between F and
%   Y. For SVM regression ('epsiloninsensitive' loss), the bias estimate is
%   found by taking a weighted median of the difference between F and Y
%   ignoring values satisfying |F-Y|<=EPSILON.

%   Copyright 2015 The MathWorks, Inc.

if nargin<5
    epsilon = [];
end

L = size(F,2);

bias = NaN(1,L,'like',y);

w = w/sum(w);

switch lossfun
    case 'logit'
        yset = [-1 1];
    case 'hinge'
        yset = [-1 1];
    case 'mse'
        bias = w'*bsxfun(@minus,y,F);
        return;
    case 'epsiloninsensitive'
        if isempty(epsilon)
            error(message('stats:classreg:learning:linearutils:EpsilonNotSpecified'));
        end
        
        D = bsxfun(@minus,y,F);
        
        for i=1:L
            d = D(:,i);
            [d,idx] = sort(d);
            havenoloss = abs(d)<=epsilon;
            d(havenoloss)   = [];
            idx(havenoloss) = [];
            if isempty(idx)
                bias(i) = 0;
                continue;
            end
            
            W = cumsum(w(idx));
            W = W./W(end);
            iAbove05 = find( W > 0.5, 1 );
            if     isempty(iAbove05)
                bias(i) = NaN;
            elseif iAbove05==1
                bias(i) = d(iAbove05);
            elseif W(iAbove05-1)==0.5
                bias(i) = d(iAbove05-1);
            else
                bias(i) = (d(iAbove05) + d(iAbove05-1))/2;
            end
        end
        
        return;
    otherwise
        error(message('stats:classreg:learning:linearutils:BadLossFunctionName',lossfun));
end

smin = min( F(y==yset(2),:) );
smax = max( F(y==yset(1),:) );

for i=1:L
    % Classes do not overlap
    if smin(i) >= smax(i)
        bias(i) = -(smin(i) + smax(i))/2;
        continue;
    end
    
    % Classes do overlap
    f = F(:,i);
    idx = f>=smin(i) & f<=smax(i);
    
    [accu,~,thre] = perfcurve(y(idx),f(idx),1,'xcrit','accu','weights',w(idx));
    
    [~,imax] = max(accu);
    bias(i) = -thre(imax);
end

end
