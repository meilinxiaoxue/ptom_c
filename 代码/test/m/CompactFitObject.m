classdef (AllowedSubclasses = {?classreg.regr.FitObject ?classreg.regr.CompactPredictor}) CompactFitObject < classreg.learning.internal.DisallowVectorOps & internal.matlab.variableeditor.VariableEditorPropertyProvider
%FitObject Fitted statistical regression.
%   FitObject is an abstract class representing a fitted regression model.
%   You cannot create instances of this class directly.  You must create
%   a derived class by calling the fit method of a derived class such as
%   LinearModel, GeneralizedLinearModel, or NonLinearModel.
%
%   See also LinearModel, GeneralizedLinearModel, NonLinearModel.

%   Copyright 2011-2015 The MathWorks, Inc.


    properties(GetAccess='public', SetAccess='protected')
%VariableInfo - Information about variables used in the fit.
%   The VariableInfo property is a table providing information about the
%   variables used in the fit. There is one row for each variable. The
%   table contains the following columns:
%
%     Class - the class of the variable ('double', 'cell', 'nominal',
%             etc.).
%     Range - the range of values taken by the variable, either a
%             two-element vector of the form [min,max] for a numeric
%             variable, or a cell or categorical array listing all unique
%             values of the variable for a cell or categorical variable.
%     InModel - the logical value true if the variable is a predictor in
%             the fitted model, or false if it is not.
%     IsCategorical - the logical value true if the variable has a type
%             that is treated as a categorical predictor (such as cell,
%             logical, or categorical) or if it is specified as categorical
%             by the 'Categorical' option to the fit method, or false if is
%             treated as a continuous predictor.
%
%   See also FitObject.
        VariableInfo = table({'double'},{[NaN; NaN]},false,false, ...
                               'VariableNames',{'Class' 'Range' 'InModel'  'IsCategorical'}, ...
                               'RowNames',{'y'});
    end
    properties(GetAccess='protected', SetAccess='protected')
        PredLocs = zeros(1,0);
        RespLoc = 1;
        IsFitFromData = false;
        PredictorTypes = 'numeric'; % or 'mixed'
        ResponseType = 'numeric'; % or 'categorical'
        NumObservations_ = 0;
        IsFitFromTable = true; % false if fit from matrix
    end
    properties(Dependent, GetAccess='public', SetAccess='protected')
%NumVariables - Number of variables used in the fit.
%   The NumVariables property gives the number of variables used in the
%   fit. This is the number of variables in the original dataset/table when the
%   fit is based on a dataset/table, or the total number of columns in the
%   predictor matrix or matrices and response vector when the fit is based
%   on those arrays. It includes variables, if any, that are not used as
%   predictors or as the response.
%
%   See also FitObject.
        NumVariables

%VariableNames - Names of variables used in the fit.
%   The VariableNames property is a cell array of strings containing the
%   names of the variables in the fit.
%
%   If the fit is based on a dataset/table, this property provides the names of
%   the variables in that dataset/table.
%
%   If the fit is based on a predictor matrix or matrices and response
%   vector, this property is taken from the variable names supplied to the
%   fitting function (if any). Otherwise the variables are given default 
%   names.
%
%   See also FitObject.
        VariableNames

%NumPredictors - Number of predictors used in the fit.
%   The NumPredictors property gives the number of variables used as
%   predictors in the fit.
%
%   See also FitObject.
        NumPredictors

%PredictorNames - Names of predictors used in the fit.
%   The PredictorNames property is a cell array of strings containing the
%   names of the variables used as predictors in the fit.
%
%   See also FitObject.
        PredictorNames

%ResponseName - Names of the response.
%   The ResponseName property is a character string giving the name of the
%   variable used as the response in the fit.
%
%   See also FitObject.
        ResponseName

%NumObservations - Number of observations used in the fit.
%   The NumObservations property gives the number of observations used in
%   the fit. This is the number of observations supplied in the original
%   dataset/table or matrix, minus any excluded rows or rows with missing (NaN)
%   values.
%
%   See also FitObject.
        NumObservations
    end
    
    methods % get/set methods
        function n = get.NumVariables(model)
            n = size(model.VariableInfo,1);
        end
        function vnames = get.VariableNames(model)
            vnames = model.VariableInfo.Properties.RowNames;
        end
        function n = get.NumPredictors(model)
            n = length(model.PredictorNames);
        end
        function vnames = get.PredictorNames(model)
            vnames = model.VariableInfo.Properties.RowNames(model.PredLocs);
        end
        function vname = get.ResponseName(model)
            vname = model.VariableInfo.Properties.RowNames{model.RespLoc};
        end
        function n = get.NumObservations(model)
            n = model.NumObservations_;
        end
    end % get/set methods
    
    methods(Abstract, Hidden, Access='public')
        t = title(model);
    end
    methods(Abstract, Hidden, Access='public')
        disp(model)
        val = feval(model,varargin); % requires a modified fnchk if hidden, g701463
    end
    
    methods(Access='protected')
        function model = noFit(model,varNames)
            p = length(varNames) - 1;
            model.PredLocs = 1:p;
            model.RespLoc = p+1;
            viName = varNames;
            viClass = repmat({'double'},p+1,1);
            viRange = repmat({[NaN; NaN]},p+1,1);
            viInModel = [true(p,1); false];
            viIsCategorical = false(p+1,1);
            model.VariableInfo = table(viClass,viRange,viInModel,viIsCategorical, ...
                                     'VariableNames',{'Class' 'Range' 'InModel' 'IsCategorical'}, ...
                                     'RowNames',viName);
            model.Data = table([{zeros(0,p+1)},varNames]);
            model.IsFitFromData = false;
        end
        
        % --------------------------------------------------------------------
        function tf = hasData(model)
            tf = false;
        end
        function tf = fitFromDataset(model)
            tf = false;
        end
        
        % --------------------------------------------------------------------
        function [varName,varNum] = identifyVar(model,var)
            [tf,varName] = internal.stats.isString(var,true); % accept a scalar cellstr
            if tf
                varNum = find(strcmp(varName,model.VariableNames));
                if isempty(varNum)
                    error(message('stats:classreg:regr:FitObject:UnrecognizedName', varName));
                end
            elseif internal.stats.isScalarInt(var,1)
                varNum = var;
                if varNum > model.NumVariables
                    error(message('stats:classreg:regr:FitObject:BadVariableNumber', model.NumVariables));
                end
                varName = model.VariableNames{varNum};
            else
                error(message('stats:classreg:regr:FitObject:BadVariableSpecification'));
            end
        end
                
        % --------------------------------------------------------------------
        function gm = gridVectors2gridMatrices(model,gv)
            p = model.NumPredictors;
            
            if ~(iscell(gv) && isvector(gv) && length(gv) == p)
                error(message('stats:classreg:regr:FitObject:BadGridSize', p));
            elseif ~reconcilePredictorTypes(model,gv)
                error(message('stats:classreg:regr:FitObject:BadGridTypes', p));
            end
            
            if ~all(cellfun(@(x)isnumeric(x)&&isvector(x),gv))
                error(message('stats:classreg:regr:FitObject:NonNumericGrid', p));
            end
            
            if p > 1
                [gm{1:p}] = ndgrid(gv{:});
            else
                gm = gv; % ndgrid would treat this as ndgrid(gv,gv)
            end
        end
        % --------------------------------------------------------------------
        function tf = reconcilePredictorTypes(model,vars) %#ok<INUSD>
            if hasData(model)
                tf = true;
            else
                tf = true;
            end
        end    end % protected
        
    methods(Hidden, Access='public')
        % --------------------------------------------------------------------
        function val = fevalgrid(model,varargin)
            gridMatrices = gridVectors2gridMatrices(model,varargin);
            val = feval(model,gridMatrices{:});
        end
        
        % --------------------------------------------------------------------
        function [varargout] = subsref(a,s)
            switch s(1).type
            case '()'
                error(message('stats:classreg:regr:FitObject:ParenthesesNotAllowed'));
            case '{}'
                error(message('stats:classreg:regr:FitObject:NoCellIndexing'));
            case '.'
                [varargout{1:nargout}] = builtin('subsref',a,s);
            end
        end
        function a = subsasgn(a,s,~)
            switch s(1).type
            case '()'
                error(message('stats:classreg:regr:FitObject:NoParetnthesesAssignment'));
            case '{}'
                error(message('stats:classreg:regr:FitObject:NoCellAssignment'));
            case '.'
                if any(strcmp(s(1).subs,properties(a)))
                    error(message('stats:classreg:regr:FitObject:ReadOnly', s( 1 ).subs, class( a )));
                else
                    error(message('stats:classreg:regr:FitObject:NoMethodProperty', s( 1 ).subs, class( a )));
                end
            end
        end
        
    end % hidden public
    
    methods(Hidden, Static, Access='public')
        function a = empty(varargin) %#ok<STOUT>
            error(message('stats:classreg:regr:FitObject:NoEmptyAllowed'));
        end
    end % hidden static public
    
    methods(Static, Access='protected')
        function opts = checkRobust(robustOpts)
            
            if isequal(robustOpts,'off') || isempty(robustOpts) || isequal(robustOpts,false)
                opts = [];
                return;
            end
            if internal.stats.isString(robustOpts) || isa(robustOpts,'function_handle') || isequal(robustOpts,true)
                if isequal(robustOpts,'on') || isequal(robustOpts,true)
                    wfun = 'bisquare';
                else
                    wfun = robustOpts;
                end
                robustOpts = struct('RobustWgtFun',wfun,'Tune',[]);
            end
            if isstruct(robustOpts)
                % A robust structure must have a weight function. It may
                % have a tuning constant. For pre-defined weight functions,
                % will determine the default weighting function later. For
                % function handles, set the value to 1.
                fn = fieldnames(robustOpts);
                if ~ismember('RobustWgtFun',fn) || isempty(robustOpts.RobustWgtFun)
                    opts = [];
                    return
                end
                if ~ismember('Tune',fn)
                    robustOpts.Tune = [];
                end
                if internal.stats.isString(robustOpts.RobustWgtFun)
                    [opts.RobustWgtFun,opts.Tune] = dfswitchyard('statrobustwfun',robustOpts.RobustWgtFun,robustOpts.Tune);
                    if isempty(opts.Tune)
                        error(message('stats:classreg:regr:FitObject:BadRobustName'));
                    end
                else
                    opts = struct('RobustWgtFun',robustOpts.RobustWgtFun,'Tune',robustOpts.Tune);
                end
            else
                error(message('stats:classreg:regr:FitObject:BadRobustValue'));
            end
        end
    end
    methods(Hidden,Static)
        % ----------------------------------------------------------------------------
        function [varNames,predictorVars,responseVar] = ...
                getVarNames(varNames,predictorVars,responseVar,nx)
            if isempty(varNames)
                % Create varNames from predictorVars and responseVar, supplied or
                % default
                if ~isempty(predictorVars) && (iscell(predictorVars) || ischar(predictorVars))
                    if iscell(predictorVars)
                        predictorVars = predictorVars(:);
                    else
                        predictorVars = cellstr(predictorVars);
                    end
                    if length(predictorVars)~=nx || ...
                            ~internal.stats.isStrings(predictorVars,true)
                        error(message('stats:classreg:regr:FitObject:BadPredNames'));
                    end
                    pnames = predictorVars;
                else
                    pnames = internal.stats.numberedNames('x',1:nx)';
                    if ~isempty(responseVar) && internal.stats.isString(responseVar)
                        pnames = genvarname(pnames,responseVar);
                    end
                    if isempty(predictorVars)
                        predictorVars = pnames;
                    else
                        predictorVars = pnames(predictorVars);
                    end
                end
                if isempty(responseVar)
                    responseVar = genvarname('y',predictorVars);
                end
                varNames = [pnames; {responseVar}];
            else
                if ~internal.stats.isStrings(varNames,true)
                    error(message('stats:classreg:regr:FitObject:BadVarNames'));
                end
                
                % If varNames is given, figure out the others or make sure they are
                % consistent with one another
                if isempty(responseVar) && isempty(predictorVars)
                    % Default is to use the last name for the response
                    responseVar = varNames{end};
                    predictorVars = varNames(1:end-1);
                    return
                end
                
                % Response var must be a name
                if ~isempty(responseVar)
                    [tf,rname] = internal.stats.isString(responseVar,true);
                    if tf
                        responseVar = rname;
                        if ~ismember(responseVar,varNames)
                            error(message('stats:classreg:regr:FitObject:MissingResponse'));
                        end
                    else
                        error(message('stats:classreg:regr:FitObject:BadResponseVar'))
                    end
                end
                
                % Predictor vars must be names or an index
                if ~isempty(predictorVars)
                    [tf,pcell] = internal.stats.isStrings(predictorVars);
                    if tf
                        predictorVars = pcell;
                        if ~all(ismember(predictorVars,varNames))
                            error(message('stats:classreg:regr:FitObject:InconsistentNames'));
                        end
                    elseif isValidIndexVector(varNames,predictorVars)
                        predictorVars = varNames(predictorVars);
                    else
                        error(message('stats:classreg:regr:FitObject:InconsistentNames'))
                    end
                end
                
                % One may still be empty
                if isempty(predictorVars)
                    predictorVars = setdiff(varNames,{responseVar});
                elseif isempty(responseVar)
                    % If predictorVar is given, there should be just the response left
                    responseVar = setdiff(varNames,predictorVars);
                    if isscalar(responseVar)
                        responseVar = responseVar{1};
                    else
                        error(message('stats:classreg:regr:FitObject:AmbiguousResponse'));
                    end
                else
                    if ~ismember({responseVar},varNames) || ...
                            ~all(ismember(predictorVars,varNames)) || ...
                            ismember({responseVar},predictorVars)
                        error(message('stats:classreg:regr:FitObject:InconsistentNames'))
                    end
                end
            end
        end
        function asCat = checkAsCat(isCat,asCat,nvars,haveDataset,VarNames)
            [isVarIndices,isInt] = internal.stats.isIntegerVals(asCat,1,nvars);
            if isVarIndices && isvector(asCat) % var indices
                where = asCat;
                asCat = false(nvars,1);
                asCat(where) = true;
            elseif isInt && isvector(asCat)
                error(message('stats:classreg:regr:FitObject:BadAsCategoricalIndices'));
            elseif internal.stats.isStrings(asCat) % variable names
                [tf,where] = ismember(asCat,VarNames);
                if ~all(tf)
                    error(message('stats:classreg:regr:FitObject:BadAsCategoricalNames'));
                end
                asCat = false(nvars,1);
                asCat(where) = true;
            elseif islogical(asCat) && isvector(asCat)
                if (haveDataset && length(asCat)~=nvars) || ...
                        (~haveDataset && length(asCat)~=nvars-1)
                    error(message('stats:classreg:regr:FitObject:BadAsCategoricalLength'));
                end
                if ~haveDataset
                    asCat = [asCat(:)',false]; % include response as well
                end
            else
                error(message('stats:classreg:regr:FitObject:BadAsCategoricalType'));
            end
            asCat = asCat(:)';
            asCat = (isCat | asCat);
        end
    end % static protected
end


function range = getVarRange(v,asCat,excl)
v(excl,:) = [];
if asCat % create a list of the unique values
    if isa(v,'categorical')
        % For categorical classes, get the values actually present in the
        % data, not the set of possible values.
        range = unique(v(:));
        range = range(~isundefined(range)); % empty if NaNs
            
    else
        % For classes other than categorical, the list of unique values is
        % also the list of possible values.  But get it in the same order as
        % what grp2idx defines for each class.
        [~,~,range] = grp2idx(v); % leaves NaN or '' out of glevels
    end
    if ~ischar(range)
        range = range(:)'; % force a row
    end
elseif isnumeric(v) || islogical(v) % find min and max
    range = [min(v,[],1)  max(v,[],1)]; % ignores NaNs unless all NaNs
else
    range = NaN(1,2);
end
end



function tf = isValidIndexVector(A,idx)
if isempty(idx)
    tf = true;
elseif ~isvector(idx)
    tf = false;
elseif islogical(idx)
    tf = (length(idx) == length(A));
elseif isnumeric(idx)
    tf = all(ismember(idx,1:length(A)));
else
    tf = false;
end
end
