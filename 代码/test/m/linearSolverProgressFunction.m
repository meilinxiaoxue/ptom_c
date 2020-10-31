
%   Copyright 2016 The MathWorks, Inc.

classdef linearSolverProgressFunction < handle & matlab.mixin.Copyable
    % Utility class to capture and report the progress of the algorithms in
    % classreg.learning.linearutils. Use linearSolverProgressFunction to
    % wrap the objective function being minimized. Progress is reported
    % every time the objective function is evaluated (i.e. every pass of
    % the tall data).
    properties (SetAccess = private)
        ObjGraFunction
        ValidationFlag
        ResidualFlag
        VerboseFlag
        HistoryFlag
        hClientfun
        ObjectiveValue = NaN;
        GradientMagnitude = Inf;
        VerboseCounter = 0;
        DataPass = 0;
        Time0
        ElapsedTime
        History = struct('ObjectiveValue',[],'GradientMagnitude',[],'Solver',[],'IterationNumber',[],'DataPass',[],'RelativeChangeBeta',[],'PrimalResidual',[],'DualResidual',[],'ElapsedTime',[],'ValidationLoss',[]);
    end
    properties (SetAccess = private)
        LazyObjGraFunctor 
        NonLazyObjGraFunctor
    end
    properties
        Solver = '';
        Beta 
        IterationNumber = 0;
        PrimalResidual = NaN;
        DualResidual = NaN;
        RelativeChangeBeta = Inf;
        ValidationLoss = Inf;
    end
    properties (Transient)
        
    end
    methods
        function this = linearSolverProgressFunction(funtionHandle,doValidation,doResidual,doVerbose,keepHist,clientfun)
            this.Beta = NaN;
            this.ValidationFlag = doValidation;
            this.VerboseFlag = doVerbose;
            this.HistoryFlag = keepHist;
            this.ResidualFlag = doResidual;
            this.ObjGraFunction = funtionHandle;
            this.hClientfun = clientfun;
            this.Time0 = clock;
            this.NonLazyObjGraFunctor = @fcn;            
            this.LazyObjGraFunctor = @fcn_;

            function [obj,gra] = fcn(Beta)
                % Non-lazy ObjGra functor, used in LBFGS.
                [obj,gra] = this.ObjGraFunction(Beta);
                [obj,gra] = gather(obj,gra);
                updateAndShowProgress(this,obj,gra,Beta);
                gra = gra';
            end
            function [obj,gra] = fcn_(Beta)
                % Lazy ObjGra functor, used in ADMM.
                [obj,gra] = this.ObjGraFunction(Beta);
                if istall(obj)
                    [obj,gra] = this.hClientfun(@(a,b) updateAndShowProgress(this,a,b,Beta),hGetValueImpl(obj),hGetValueImpl(gra));
                    obj = tall(obj);
                    gra = tall(gra);
                else % Non-tall case
                    updateAndShowProgress(this,obj,gra,Beta);
                end
            end
        end
       
        function [obj,gra] = updateAndShowProgress(this,obj,gra,Beta)
            updateProgress(this,obj,gra,Beta);
            if this.HistoryFlag
                updateHistory(this) 
            end
            if this.VerboseFlag
                showProgress(this);
            end
        end

        function updateHistory(this) 
            this.History.ObjectiveValue(end+1) = this.ObjectiveValue;
            this.History.GradientMagnitude(end+1) = this.GradientMagnitude;
            this.History.IterationNumber(end+1) = this.IterationNumber;
            this.History.DataPass(end+1) = this.DataPass;
            this.History.RelativeChangeBeta(end+1) = this.RelativeChangeBeta;
            this.History.PrimalResidual(end+1) = this.PrimalResidual;
            this.History.DualResidual(end+1) = this.DualResidual;
            this.History.ValidationLoss(end+1) = this.ValidationLoss;
            this.History.ElapsedTime(end+1) = this.ElapsedTime;
            switch this.Solver
                case 'ADMM'
                    this.History.Solver(end+1) = 1;
                case 'LBFGS'
                    this.History.Solver(end+1) = 2;
                otherwise
                    this.History.Solver(end+1) = 0;
            end
        end
            
        function updateProgress(this,obj,gra,Beta)
            this.DataPass = this.DataPass + 1;
            this.ElapsedTime = etime(clock,this.Time0);
            beta_mag = sqrt(Beta'*Beta);
            dbeta_mag = sqrt(sum((Beta-this.Beta).^2))/beta_mag;
            this.ObjectiveValue = obj;
            this.GradientMagnitude = sqrt(sum(gra.^2));
            this.RelativeChangeBeta = dbeta_mag;
        end
        
        function showProgress(this)
            if this.DataPass>0
                if ~rem(this.VerboseCounter,20)
                   if this.VerboseCounter==0
                       fprintf('\n');
                   end
                   printHeader(this);
                end
                if this.ValidationFlag
                    if this.ResidualFlag
                        fprintf('| %6s | %5i / %5i| %13e | %13e | %13e | %13e | %13e | %13e |\n',this.Solver,this.IterationNumber,this.DataPass,this.ObjectiveValue,this.GradientMagnitude,this.RelativeChangeBeta,this.ValidationLoss,this.PrimalResidual,this.DualResidual);
                    else
                        fprintf('| %6s | %5i / %5i| %13e | %13e | %13e | %13e |\n',this.Solver,this.IterationNumber,this.DataPass,this.ObjectiveValue,this.GradientMagnitude,this.RelativeChangeBeta,this.ValidationLoss);
                    end
                else
                    if this.ResidualFlag
                        fprintf('| %6s | %5i / %5i | %13e | %13e | %13e | %13e | %13e |\n',this.Solver,this.IterationNumber,this.DataPass,this.ObjectiveValue,this.GradientMagnitude,this.RelativeChangeBeta,this.PrimalResidual,this.DualResidual);
                    else
                        fprintf('| %6s | %5i / %5i | %13e | %13e | %13e |\n',this.Solver,this.IterationNumber,this.DataPass,this.ObjectiveValue,this.GradientMagnitude,this.RelativeChangeBeta);
                    end
                end
                this.VerboseCounter = this.VerboseCounter + 1;
            end
        end
            
        function printHeader(this)
            if this.ValidationFlag
                if this.ResidualFlag
                    fprintf('|========================================================================================================================|\n');
                    fprintf('| Solver | Iteration  /  |   Objective   |   Gradient    | Beta relative |  Validation   |Primal residual| Dual residual |\n');
                    fprintf('|        | Data Pass     |               |   magnitude   |    change     |    Loss       |   magnitude   |   magnitude   |\n');
                    fprintf('|========================================================================================================================|\n');
                else
                    fprintf('|========================================================================================|\n');
                    fprintf('| Solver | Iteration  /  |   Objective   |   Gradient    | Beta relative |  Validation   |\n');
                    fprintf('|        | Data Pass     |               |   magnitude   |    change     |    Loss       |\n');
                    fprintf('|========================================================================================|\n');
                end
            else
                if this.ResidualFlag
                    fprintf('|========================================================================================================|\n');
                    fprintf('| Solver | Iteration  /  |   Objective   |   Gradient    | Beta relative |Primal residual| Dual residual |\n');
                    fprintf('|        | Data Pass     |               |   magnitude   |    change     |   magnitude   |   magnitude   |\n');
                    fprintf('|========================================================================================================|\n');
                else
                    fprintf('|=========================================================================\n');
                    fprintf('| Solver | Iteration  /  |   Objective   |   Gradient    | Beta relative |\n');
                    fprintf('|        | Data Pass     |               |   magnitude   |    change     |\n');
                    fprintf('|=========================================================================\n');
                end
            end
        end
        
        function printLastLine(this)
            if this.ValidationFlag
                if this.ResidualFlag
                    fprintf('|========================================================================================================================|\n');
                else
                    fprintf('|========================================================================================|\n');
                end
            else
                if this.ResidualFlag
                    fprintf('|========================================================================================================|\n');
                else
                    fprintf('|========================================================================|\n');
                end
                
            end
        end
    end
    
end
