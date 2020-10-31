function [dist,isbuiltindist,ignorezeros,doquadprog] = prepareForPredictECOC(...
    scoretype,doposterior,postmethod,userloss,defaultloss,decoding,numfits)

%   Copyright 2015 The MathWorks, Inc.

% Can compute posterior probabilities?
if doposterior
    if ~strcmp(scoretype,'probability')
        error(message('stats:classreg:learning:classif:CompactClassificationECOC:predict:CannotFitProbabilities'));
    end
end

% Use weighted averaging?
if ~ischar(decoding)
    error(message('stats:classreg:learning:classif:CompactClassificationECOC:predict:BadDecodingType'));
end
allowedVals = {'LossBased' 'LossWeighted'};
tf = strncmpi(decoding,allowedVals,length(decoding));
if sum(tf)~=1
    error(message('stats:classreg:learning:classif:CompactClassificationECOC:predict:BadDecodingValue'));
end
ignorezeros = tf(2);

% Use QP to fit probabilities?
doquadprog = [];
if doposterior
    if ~ischar(postmethod)
        error(message('stats:classreg:learning:classif:CompactClassificationECOC:predict:BadPosteriorMethodType'));
    end
    allowedVals = {'QP' 'KL'};
    tf = strncmpi(postmethod,allowedVals,length(postmethod));
    if sum(tf)~=1
        error(message('stats:classreg:learning:classif:CompactClassificationECOC:predict:BadPosteriorMethodValue'));
    end
    doquadprog = tf(1);
end

% How many extra attempts for KL fitting?
if doposterior
    if ~isempty(numfits) && ...
            (~isscalar(numfits) || ~isnumeric(numfits) ...
            || numfits~=round(numfits) || numfits<0)
        error(message('stats:classreg:learning:classif:CompactClassificationECOC:predict:BadNumKLInitializationsType'));
    end
    if doquadprog && numfits>0
        error(message('stats:classreg:learning:classif:CompactClassificationECOC:predict:BadNumKLInitializationsValue'));
    end
end

% Make sure loss makes sense
if ~isa(userloss,'function_handle')
    if isempty(defaultloss)
        error(message('stats:classreg:learning:classif:CompactClassificationECOC:predict:MustProvideCustomBinaryLoss'));
    end
    
    allowedVals = {'hamming' 'linear' 'quadratic' 'exponential' 'binodeviance' 'hinge' 'logit'};
    tf = strncmpi(userloss,allowedVals,length(userloss));
    if sum(tf)~=1
        error(message('stats:classreg:learning:classif:CompactClassificationECOC:predict:BinaryLoss'));
    end
    userloss = allowedVals{tf};
    
    if strcmp(userloss,'quadratic') && ...
            ~(strcmp(scoretype,'01') || strcmp(scoretype,'probability'))
        error(message('stats:classreg:learning:classif:CompactClassificationECOC:predict:QuadraticLossForInfRange'));
    end
    
    if ismember(userloss,{'linear' 'exponential' 'binodeviance' 'hinge' 'logit'}) ...
            && ~strcmp(scoretype,'inf')
        error(message('stats:classreg:learning:classif:CompactClassificationECOC:predict:BadBinaryLossFor01Range',userloss));
    end
end

% Make a function for loss
if isa(userloss,'function_handle')
    dist = userloss;
    isbuiltindist = false;

else
    % M is a matrix and f is a row-vector
    switch userloss
        case 'hamming'
            switch scoretype
                case 'inf'
                    dist = @(M,f) nanmean( 1 - sign(bsxfun(@times,M,f)), 2 )/2;
                case {'01' 'probability'}
                    dist = @(M,f) nanmean( 1 - sign(bsxfun(@times,M,2*f-1)), 2)/2;
            end
        case 'linear'       % range must be 'inf'
            dist = @(M,f) nanmean( 1 - bsxfun(@times,M,f), 2 )/2;
        case 'quadratic'    % range must be '01' or 'probability'
            dist = @(M,f) nanmean( (1 - bsxfun(@times,M,2*f-1) ).^2, 2 )/2;
        case 'exponential'  % range must be 'inf'
            dist = @(M,f) nanmean( exp( -bsxfun(@times,M,f) ), 2 )/2;
        case 'binodeviance' % range must be 'inf'
            dist = @(M,f) nanmean(log( 1 + exp(-2*bsxfun(@times,M,f)) ),2)/(2*log(2));
        case 'hinge'        % range must be 'inf'
            dist = @(M,f) nanmean( max(0, 1-bsxfun(@times,M,f) ), 2 )/2;
        case 'logit' % range must be 'inf'
            dist = @(M,f) nanmean(log( 1 + exp(-bsxfun(@times,M,f)) ),2)/(2*log(2));
    end
    
    isbuiltindist = true;
end

end
