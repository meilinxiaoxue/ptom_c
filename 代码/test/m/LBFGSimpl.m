function Beta = LBFGSimpl(Beta,progressF,verbose,...
                          betaTol,gradTol,iterationlimit,tallPassLimit,...
                          hessianHistorySize,lineSearch,initialStepSize)

%   Copyright 2017 The MathWorks, Inc
if any(isinf(Beta))
    return; % classreg.learning.fsutils.fminlbfgs does not have flow-thru behavior for Inf's
end
if any(isnan(Beta))
    return; % classreg.learning.fsutils.fminlbfgs does not have flow-thru behavior for Nan's
end

if iterationlimit>0 && progressF.DataPass<tallPassLimit
    
    % Non-lazy ObjGra functor as before but LBFGS needs to gather immediately
    objgraF = progressF.NonLazyObjGraFunctor;
    % Output functor is only used to check convergence, as customized
    % display is already within the ObjGra functor
    outputF = makeOutputFun(progressF,betaTol,gradTol,iterationlimit,tallPassLimit);
    
    % Solver options (convergence is handled by outputF and verbosity==1 by objgraF)
    options.TolFun = eps;
    options.TolX = eps;
    options.MaxIter = inf;
    options.GradObj =  'on';
    if verbose>1
        options.Display = 'iter';
    else
        options.Display = 'off';
    end
    
    LBFGSparams = {'Options',options,'Memory',hessianHistorySize, ...
            'LineSearch',lineSearch,'MaxLineSearchIter',100,'OutputFcn',outputF};
        
    if isempty(initialStepSize)
        LBFGSparams(end+1:end+2) = {'Gamma',1};
    else
        LBFGSparams(end+1:end+2) = {'Step',initialStepSize};
    end
    
    % call LBFGS optimizer
    [Beta,~,~,~] = classreg.learning.fsutils.fminlbfgs(objgraF,Beta,LBFGSparams{:});

end

end

function outF = makeOutputFun(progressF,betaTol,gradTol,iterationlimit,tallPassLimit)
progressF.IterationNumber = 0;
progressF.Solver = 'LBFGS';
progressF.PrimalResidual = NaN;
progressF.DualResidual = NaN;
outF = @fcn;
    function stop = fcn(Beta,optimValues,b)
        progressF.Beta = Beta;
        progressF.IterationNumber = optimValues.iteration+1;
        % Check convergence
        stop =  isinf(progressF.ObjectiveValue) || isnan(progressF.ObjectiveValue) || progressF.RelativeChangeBeta<=betaTol || progressF.GradientMagnitude<=gradTol || progressF.IterationNumber>iterationlimit || progressF.DataPass>=tallPassLimit;
    end
end