function Phat = posteriorFromRatio(M,R,W,verbose,doquadprog,T,useParallel,RNGscheme)
%POSTERIORFROMRATIO Compute posterior probabilities given their ratios.
%   P=POSTERIORFROMRATIO(M,R) returns an N-by-K matrix of estimated class
%   posterior probabilities for indicator matrix M of size K-by-L for K
%   classes and L classifiers and matrix of posterior ratios R of size
%   N-by-L for N observations. Element R(n,l) gives the ratio of the
%   posterior probability of the positive class at observation n for
%   learner l over the total posterior probability of the positive and
%   negative classes at observation n for learner l. For observation n,
%   posterior probabilities P(n,:) are estimated by solving a QP problem.
%   You must pass M as a matrix filled with 0, +1 and -1.
%
%   P=POSTERIORFROMRATIO(M,R,W,VERBOSE,DOQP,USEPARALLEL) accepts
%       W           - Row-vector of total data weights for learners with L
%                     elements.
%       VERBOSE     - Verbosity flag, 0 or 1.
%       DOQP        - Logical flag. If true, solve the least-squares
%                     problem by QUADPROG; if false, minimize the
%                     Kullback-Leibler divergence.
%       USEPARALLEL - Logical flag. If true, use parallel computing.
%       RNGSCHEME   - RNG scheme

%   Copyright 2015 The MathWorks, Inc.

if nargin<3
    W = ones(1,size(R,2));
end

if nargin<4
    verbose = 0;
end

if nargin<5
    doquadprog = false;
end

if doquadprog && isempty(ver('Optim'))
    error(message('stats:classreg:learning:classif:CompactClassificationECOC:posteriorFromRatio:NeedOptim'));
end

K = size(M,1);
N = size(R,1);

Mminus        = M;
Mminus(M~=-1) = 0;
Mplus         = M;
Mplus(M~=+1)  = 0;

if verbose>0
    fprintf('%s\n',getString(message('stats:classreg:learning:classif:CompactClassificationECOC:posteriorFromRatio:ComputingPosteriorProbs')));
end

    function p = loopBodyQP(n,~)        
        p = NaN(1,K);
        
        r = R(n,:);
        
        igood = ~isnan(r);
        if ~any(igood)
            return;
        end
        
        Q = bsxfun(@times,Mminus(:,igood),r(igood)) + ...
            bsxfun(@times,Mplus(:,igood),1-r(igood));
        H = Q*Q'; % K-by-K
        [p,~,exitflag] = quadprog(H,zeros(K,1),[],[],ones(1,K),1,zeros(K,1),ones(K,1),[],opts);
        
        if exitflag~=1
            warning(message('stats:classreg:learning:classif:CompactClassificationECOC:posteriorFromRatio:QuadprogFails',n));
        end
        
        p = p';
    end


    function p = loopBodyKL(n,s)
        if isempty(s)
            s = RandStream.getGlobalStream;
        end

        p = NaN(1,K);
        
        r = R(n,:);
        
        igood = ~isnan(r);
        if ~any(igood)
            return;
        end

        phat = zeros(T+2,K);
        dist = zeros(T+2,1);
        p0 = rand(s,T,K);
        p0 = bsxfun(@rdivide,p0,sum(p0,2));
        
        % Random initialization
        for t=1:T
            [phat(t,:),dist(t)] = ...
                minimizeKL(r(igood),Mminus(:,igood),Mplus(:,igood),W(igood),p0(t,:)');
        end
        
        % Uniform initial estimates
        [phat(T+1,:),dist(T+1)] = ...
            minimizeKL(r(igood),Mminus(:,igood),Mplus(:,igood),W(igood),repmat(1/K,K,1));

        % Built-in estimates based on approximate lsqnonneg solution
        [phat(T+2,:),dist(T+2)] = ...
            minimizeKL(r(igood),Mminus(:,igood),Mplus(:,igood),W(igood));
        
        % Best solution
        [~,tmin] = min(dist);
        p = phat(tmin,:);
    end

if doquadprog % Solve the QP problem
    opts = optimoptions(@quadprog,...
        'Algorithm','interior-point-convex','Display','off');
    
    Phat = internal.stats.parallel.smartForSliceout(N,@loopBodyQP,useParallel);
        
else          % Minimize KL divergence
    
    Phat = internal.stats.parallel.smartForSliceout(N,@loopBodyKL,useParallel,RNGscheme);
    
end

end


function [p,dist] = minimizeKL(r,Mminus,Mplus,W,p0)

if nargin<5
    K = size(Mminus,1);
    
    M = Mminus + Mplus;
    M(M==-1) = 0;
    p = lsqnonneg(M',r');
    
    doquit = false;
    if     all(p==0)
        p = repmat(1/K,K,1);
        doquit = true;
    elseif sum(p>0)==1
        p(p>0) = 1;
        doquit = true;
    end
    
    if doquit
        rhat = sum(bsxfun(@times,Mplus,p));
        rhat = rhat ./ (rhat - sum(bsxfun(@times,Mminus,p)));        
        dist = KLdistance(r,rhat,W);
        return;
    end
    
    p = max(p,100*eps);
    p = p/sum(p);
    p(p>1) = 1;
else
    p = p0;
end

rhat = sum(bsxfun(@times,Mplus,p));
rhat = rhat ./ (rhat - sum(bsxfun(@times,Mminus,p)));

dist = KLdistance(r,rhat,W);

delta = Inf;

iter = 1;

while delta>1e-6 && iter<=1000
    iter = iter + 1;
    
    numer = sum(    bsxfun(@times,Mplus,W.*r) -    bsxfun(@times,Mminus,W.*(1-r)), 2 );
    denom = sum( bsxfun(@times,Mplus,W.*rhat) - bsxfun(@times,Mminus,W.*(1-rhat)), 2 );
    
    i = denom<=0 & numer>0;
    if any(i)
        p(i) = 1;
        p(~i) = 0;
    else
        j = denom>0;
        p(j) = p(j) .* numer(j)./denom(j);
        p(~j) = 0;
    end
    
    p = max(p,100*eps);
    p = p/sum(p);
    
    rhat = sum(bsxfun(@times,Mplus,p));
    rhat = rhat ./ (rhat - sum(bsxfun(@times,Mminus,p)));
    
    distnew = KLdistance(r,rhat,W);
    
    delta = dist - distnew;
    
    dist = distnew;
end

end


function dist = KLdistance(r,rhat,w)

i = r   > 100*eps;
dist = sum( w(i).* r(i).*log(r(i)./rhat(i)) );

i = 1-r > 100*eps;
dist = dist + sum( w(i).*(1-r(i)).*log((1-r(i))./(1-rhat(i))) );

end
