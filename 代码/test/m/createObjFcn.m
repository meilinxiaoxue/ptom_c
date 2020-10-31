function objFcn = createObjFcn(BOInfo, FitFunctionArgs, Predictors, Response, ...
    ValidationMethod, ValidationVal, Repartition, Verbose)
% Create and return the objective function. If 'Repartition' is false and
% no cvpartition is passed, we first create a cvpartition to be used in all
% function evaluations. The cvp is stored in the workspace of the function
% handle and can be accessed later from the function handle like this:
% f=functions(h);cvp=f.workspace{1}.cvp

%   Copyright 2016-2017 The MathWorks, Inc.

% Create a cvpartition if necessary
if ~Repartition && ~isa(ValidationVal, 'cvpartition')
    [~,PrunedY] = BOInfo.PrepareDataFcn(Predictors, Response, FitFunctionArgs{:}, 'IgnoreExtraParameters', true);
    if BOInfo.IsRegression
        cvp = cvpartition(numel(PrunedY), ValidationMethod, ValidationVal);
    else
        cvp = cvpartition(PrunedY, ValidationMethod, ValidationVal);
    end
    ValidationMethod = 'CVPartition';
    ValidationVal    = cvp;
end
% Return the function handle
objFcn = @theObjFcn;

    function Objective = theObjFcn(XTable)
        % (1) Set up args
        NewFitFunctionArgs = updateArgsFromTable(BOInfo, FitFunctionArgs, XTable);
        % (2) Call fit fcn, suppressing specific warnings
        C = classreg.learning.paramoptim.suppressWarnings();
        PartitionedModel = BOInfo.FitFcn(Predictors, Response, ValidationMethod, ValidationVal, NewFitFunctionArgs{:});
        % (3) Compute kfoldLoss if possible
        if PartitionedModel.KFold == 0
            Objective = NaN;
            if Verbose >= 2
                classreg.learning.paramoptim.printInfo('ZeroFolds');
            end
        else
            if BOInfo.IsRegression
                Objective = log1p(kfoldLoss(PartitionedModel));
            else
                Objective = kfoldLoss(PartitionedModel);
            end
            if ~isscalar(Objective)
                % For cases like fitclinear where the user passes Lambda as a vector.
                Objective = Objective(1);
                if Verbose >= 2
                    classreg.learning.paramoptim.printInfo('ObjArray');
                end
            end
        end
    end
end