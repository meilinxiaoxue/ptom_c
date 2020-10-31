function vloss = loss(scoreType,dist,M,pscore) %#codegen
%LOSS  Loss function.

%   Copyright 2016 The MathWorks, Inc.

N = size(pscore,1);

K = size(M,1);
vloss = repmat(coder.internal.nan('like',pscore),N,K);
for k=1:K
    vloss(:,k) = localvloss(scoreType,dist,M(k,:),pscore);
end

end

function vloss = localvloss(scoreType,userloss,M,f)

switch userloss
    case 'hamming'
        if strcmp(scoreType, 'inf')
            vloss = nanmean( 1 - sign(bsxfun(@times,M,f)), 2 )/2;
        else
            % {'01' 'probability'}
            vloss = nanmean( 1 - sign(bsxfun(@times,M,2*f-1)), 2)/2;
        end
    case 'linear'       % range must be 'inf'
        vloss = nanmean( 1 - bsxfun(@times,M,f), 2 )/2;
    case 'quadratic'    % range must be '01' or 'probability'
        vloss = nanmean( (1 - bsxfun(@times,M,2*f-1) ).^2, 2 )/2;
    case 'exponential'  % range must be 'inf'
        vloss = nanmean( exp( -bsxfun(@times,M,f) ), 2 )/2;
    case 'binodeviance' % range must be 'inf'
        vloss = nanmean(log( 1 + exp(-2*bsxfun(@times,M,f)) ),2)/(2*log(2));
    case 'hinge'        % range must be 'inf'
        vloss = nanmean( max(0, 1-bsxfun(@times,M,f) ), 2 )/2;
    case 'logit' % range must be 'inf'
        vloss = nanmean(log( 1 + exp(-bsxfun(@times,M,f)) ),2)/(2*log(2));
end
end
