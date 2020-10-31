function Beta = ADMMimpl(X,Y,W,Beta,rho,lambda,doridge,...
    chunkMap,Wk,maxChunkSize,hfixedchunkfun,...
    betaTol,gradTol,admmIterations,tallPassLimit,progressF,verbose,...
    lossfun_ADMMLBFGS,betaTol_ADMMLBFGS,gradTol_ADMMLBFGS,...
    iterationlimit_ADMMLBFGS, doridge_ADMMLBFGS,...
    hessianHistorySize_ADMMLBFGS,dowolfe_ADMMLBFGS,doBias_ADMMLBFGS,...
    FM,expType,sigma)

if nargin<26
    expType = 'none';
    FM = [];
    sigma = [];
end

%   Copyright 2017 The MathWorks, Inc

dbeta_mag = Inf;
g_mag = Inf;
iter = 0;
N_chunks = double(chunkMap.Count);

UK = zeros(N_chunks,numel(Beta));   % Residuals at each chunk (bias included)

% Evaluate objective function on initial values, note output is lazy, i.e.
% actual computation is deferred, so pass over data will be combined with the
% Beta update in the ADMM algorithm.
objgraF_ = progressF.LazyObjGraFunctor;

if admmIterations<=1
    progressF.Solver = 'INIT';
else
    progressF.Solver = 'ADMM';
end

% detect if it is classification or regression
doClass = 0; %regression
if ~iscell(lossfun_ADMMLBFGS)  % when epsilon is given it is augmented to the lossfun
    if any(strcmp(lossfun_ADMMLBFGS,{'hinge','logit'}))
        doClass = 2; %binary classification (one class is not supported)
    end
end
            

%%%%%%%%%%%%%%%%%%%%%%%%%%% ADMM FIT %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
while true
    
    %%%%%%%%%%%%%%%%%%%%%%% CHECK CONVERGENCE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if dbeta_mag<=betaTol || g_mag<=gradTol || iter>=admmIterations || progressF.DataPass>=tallPassLimit
        break
    end
    
    iter = iter + 1;
    
    [~,gra_] = objgraF_(Beta);
    
    %%%%%%%%%%%%%%%%%%%%%%% LOCAL BETA UPDATE (BetaK) %%%%%%%%%%%%%%%%%%%%%
    
    [chunkIDs,temp1,temp2] = hfixedchunkfun( @(info,x,y,w)  ...
        chunkBetaUpdateFun(info,x,y,w,lossfun_ADMMLBFGS,Beta,...
        chunkMap,UK,rho*(iter>1),...
        betaTol_ADMMLBFGS,gradTol_ADMMLBFGS,iterationlimit_ADMMLBFGS(min(iter,2)),...
        max(0,verbose-1),...
        doridge_ADMMLBFGS,...
        hessianHistorySize_ADMMLBFGS,dowolfe_ADMMLBFGS,doBias_ADMMLBFGS,...
        FM,expType,sigma,doClass), ...
        maxChunkSize, {[],[],[],[]}, X,Y,W);
    
    [chunkIDs,temp1,temp2,gra] = gather(chunkIDs,temp1,temp2,gra_); % get obj and gra for older Beta in the same data pass
    
    
    BetaK(cellfun(@(x) chunkMap(x),chunkIDs),:) = [temp2 temp1];
    
    %%%%%%%%%%%%%%%%%%%%%%%%% GLOBAL BETA UPDATE (Beta) %%%%%%%%%%%%%%%%%%%
    
    Beta_old = Beta; % will use a copy for later to check for convergence
    progressF.Beta = Beta;
    
    Beta = (Wk'*(BetaK+UK))'; % weighted mean
    % Apply regularization
    if doridge
        if iter>1 % do not regularize on the warm step
            % Regularize coefficients but not the bias
            Beta(2:end) = Beta(2:end)./(1+lambda./rho./N_chunks);
        end
    else % L1
        error(message('stats:tall:fitclinear:LassoNotSuported'))
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%% DUAL VARIABLE UPDATE (UK) %%%%%%%%%%%%%%%%%%%
    RK = BetaK-Beta';   % Primal residual
    UK = UK + RK;
    
    %%%%%%%%%%%%%%%%%%%%%%% CONVERGENCE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    g_mag = sqrt(sum(gra.^2));
    RK_squared_mag = sum(RK.^2,2);
    r_mag = sqrt(sum(RK_squared_mag));            % Primal residual magnitude
    s_mag = sqrt(sum((rho.*(Beta-Beta_old)).^2)); % Dual residual magnitude
    beta_mag = sqrt(Beta'*Beta);
    dbeta_mag = sqrt(sum((Beta-Beta_old).^2))/beta_mag; % Relative change in Beta
    progressF.Solver = 'ADMM';
    progressF.IterationNumber = iter;
    progressF.PrimalResidual = r_mag;
    progressF.DualResidual = s_mag;
end

end

function [hasFinished,id,betad,biasd] = chunkBetaUpdateFun(...
    info,x,y,w,lossfun,Beta,...
    chunkMap,UK,rho,...
    betaTol,gradTol,iterationlimit,...
    verbose,doridge,...
    historysize,dowolfe,fitbias,...
    FM,expType,sigma,doClass)

hasFinished = info.IsLastChunk;
id = {sprintf('P%dC%d',info.PartitionId,info.FixedSizeChunkID)};

if isempty(x)
    % Setting all coefficients to 0 as they will be averaged with weight 0 anyways
    Beta(:) = 0;
    biasd = Beta(1);
    betad = Beta(2:end)';
    return;
end

k = chunkMap(id{1});
U = UK(k,:)';

% Set lineSearchType
% Not that currently we only support 'weakwolfe', setting line search to
% 'backtrack' is intended only exploratory work.
if dowolfe
    lineSearchType = 'weakwolfe';
else
    lineSearchType = 'backtrack';
end

% Get epsilon if loss is 'epsiloninsensitive'
if iscell(lossfun)
    epsilon = lossfun{2};
    lossfun = lossfun{1};
else
    epsilon = [];
end

% Expansion
if strcmpi(expType,'none')
    xm = x;
else
    xm = map(FM,x,sigma);
end

obj.Impl = classreg.learning.impl.LinearImpl.make(doClass,...
    Beta(2:end)-U(2:end),Beta(1)-U(1),...
    xm',y,w./sum(w),...
    lossfun,...
    doridge,...
    0,...   % Lambda
    [],...  % PassLimit
    [],...  % BatchLimit
    [],...  % NumCheckConvergence
    [],...  % BatchIndex
    [],...  % BatchSize
    {'lbfgs'},...
    betaTol,...
    gradTol,...
    1e-6,... % DeltaGradientTolerance
    [],...   % LearnRate
    [],...   % OptimizeLearnRate
    [],[],[],... % Validation
    iterationlimit,...
    [],...   % TruncationPeriod,...
    fitbias,... % FitBias
    false,... % PostFitBias
    epsilon,... % Epsilon
    historysize,... % hessian History Size
    lineSearchType,... % Line search
    rho, ... % Consensus
    [],... % Stream
    verbose);

biasd = obj.Impl.Bias;
betad = obj.Impl.Beta(:)';



end
