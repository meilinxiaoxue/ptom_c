function [Xout,Y,vrange,wastable,args] = table2FitMatrix(X,Y,varargin)
%table2FitMatrix Convert table data to matrix data for fitting.
%    [X,Y,VRANGE,WASTABLE,ARGS] = table2FitMatrix(X,Y,...) takes data X and
%    additional arguments, and returns a data matrix X, response vector Y,
%    a cell array VRANGE of variable ranges, boolean flag WASTABLE
%    indicating table input, and additional arguments to be processed by
%    the caller.
%
%    The first input X may be a table or matrix. The second input may be a
%    vector of response values, the name of the variable in table X that is
%    the response, or a formula the defines the response and predictors to
%    be used from X.
%
%    The additional arguments may be one or more of the following
%    name/value pairs:
%       'ResponseName'     Name of the response variable
%       'Weights'          Vector of weights or name of the variable to be
%                          used as weights
%       'PredictorNames'   Cell array of predictor names
%       'CategoricalPredictors' - Variables to be treated as categorical,
%                          specified either as a cell array of variable
%                          names, or an integer or logical index vector
%       'OrdinalIsCategorical' - true if ordinals should be treated as
%                          categorical; default true
%
%    The OrdinalIsCategorical parameter is for this function only and is
%    not passed into the ARGS output. Any name/value pairs with names not
%    matching the ones listed above are passed unchanged into the ARGS
%    output.

%   Copyright 2015-2017 The MathWorks, Inc.

args = varargin;
% Extract the input arguments that are related to table processing
pnames = {'ResponseName' 'Weights' 'PredictorNames' 'CategoricalPredictors' 'OrdinalIsCategorical'};
[ResponseName,ResponseIndex,WeightsName,WeightsIndex,...
 PredictorNames,PredictorIndex,CategoricalPredictors,CategoricalIndex,...
 OrdinalIsCategorical,OrdinalIsCategoricalIndex] = ...
      processArgs(pnames,args);
args = removeArg(OrdinalIsCategoricalIndex,args);
if ~isempty(ResponseName) && ~internal.stats.isString(ResponseName)
    error(message('stats:classreg:learning:internal:utils:BadResponseName'));
end

% For user convenience, accept a dataset in place of a table
if isa(X,'dataset')
    X = dataset2table(X);
end
wastable = istable(X);
if ~wastable
    vrange = {};
    Xout = X;
    return
end
VarNames = X.Properties.VariableNames;

% Get the weights and update args
if ~isempty(WeightsName)
    if internal.stats.isString(WeightsName)
        WeightsName = resolveName('WeightsName',WeightsName,'',true,VarNames);
        W = X.(WeightsName);
        args = updateArgs('WeightsName',W,WeightsIndex,args);
    else
        WeightsName = '';  % no name, vector already in arg list
    end
end

% Y may be a vector of response values, the name of a variable in the table
% X, or a formula involving names of variables in X. Deal with the names
% first
[FormulaResponseName,FormulaPredictorNames] = processFormula(VarNames,Y);

% Get the Y response data
if ~isempty(Y)
    if internal.stats.isString(Y)
        % Given by name, make sure the args reflect the chosen name
        ResponseName = resolveName('ResponseName',ResponseName,FormulaResponseName,false,VarNames);
        args = updateArgs('ResponseName',ResponseName,ResponseIndex,args);
        Y = X.(ResponseName);
    elseif istable(Y)
        % Given as table, extract the single response variable
        if width(Y)~=1
            error(message('stats:classreg:learning:internal:utils:TableResponse'));
        end
        ResponseName = Y.Properties.VariableNames{1}; % ignore parameter value
        args = updateArgs('ResponseName',ResponseName,ResponseIndex,args);
        Y = Y{:,1};
    elseif ~isempty(ResponseName)  % already checked this is a string above
        % Given by value, error if the name matches a table value as this is ambiguous
        if ismember(ResponseName,VarNames)
            error(message('stats:classreg:learning:internal:utils:AmbiguousResponse',ResponseName));
        end
    end
end

PredictorNames = resolveName('PredictorNames',PredictorNames,FormulaPredictorNames,true,VarNames,true);
if isempty(PredictorNames)
    PredictorNames = VarNames;
    if ~isempty(ResponseName) || ~isempty(WeightsName)
        PredictorNames = setdiff(PredictorNames,{ResponseName,WeightsName},'stable');
    end
end
args = updateArgs('PredictorNames',PredictorNames,PredictorIndex,args);

if ismember(ResponseName,PredictorNames)
    error(message('stats:classreg:learning:internal:utils:ResponseIsPredictor'))
end

if isequal(CategoricalPredictors,'all')
    CategoricalPredictors = PredictorNames;
end

[Xout,vrange,CategoricalPredictors] = makeXMatrix(X,PredictorNames,CategoricalPredictors,OrdinalIsCategorical);
args = updateArgs('CategoricalPredictors',CategoricalPredictors,CategoricalIndex,args);
end

function idx = makeCategoricalIndex(CategoricalPredictors,PredictorNames)
% Make a logical index vector locating the categorical predictors
p = numel(PredictorNames);
idx = CategoricalPredictors;
if isempty(CategoricalPredictors)
    idx = false(1,p);
elseif islogical(CategoricalPredictors)
    if numel(idx)~=p || ~isvector(idx)
        error(message('stats:classreg:learning:internal:utils:CategoricalBadLogical',p))
    end
elseif internal.stats.isStrings(CategoricalPredictors)
    tf = ismember(CategoricalPredictors,PredictorNames);
    if ~all(tf)
        error(message('stats:classreg:learning:internal:utils:CategoricalNotPredictor'))
    end
    idx = ismember(PredictorNames,CategoricalPredictors);
elseif isvector(idx) && isnumeric(idx) && all(idx==round(idx)) && numel(idx)==numel(unique(idx))
    if any(idx<1) || any(idx>p)
        error(message('stats:classreg:learning:FullClassificationRegressionModel:prepareDataCR:BadCatPredIntegerIndex', p));
    else
        idx = ismember(1:p,idx);
    end
else
    error(message('stats:classreg:learning:internal:utils:BadCategorical'))
end
end

function [Xout,vrange,catidx] = makeXMatrix(X,PredictorNames,CategoricalPredictors,OrdinalIsCategorical)
% Make a design matrix
catidx = makeCategoricalIndex(CategoricalPredictors,PredictorNames);
waslogical = islogical(CategoricalPredictors);

n = size(X,1);
p = numel(PredictorNames);

if isempty(OrdinalIsCategorical)
    OrdinalIsCategorical = true;
end

vrange = cell(1,p);
Xout = zeros(n,p);
for j=1:p
    % This converts each categorical variable to a set of group numbers,
    % and creates a set of group values to put into vrange
    pname = PredictorNames{j};
    x = X.(pname);
    if internal.stats.isDiscreteVec(x)
        % Variable must be categorical based on its type. Error if it is
        % explicitly specified as not categorical.
        if waslogical && ~catidx(j)
            error(message('stats:classreg:learning:internal:utils:CategoricalConflict',pname));
        end
    end
    if ischar(x)
        % The char type is converted to cellstr, not maintained as char
        x = cellstr(x);
    elseif iscellstr(x) || isstring(x)
        % Regularize string values as the categorical function would do
        x = strtrim(x);
    elseif iscell(x)
        error(message('stats:classreg:learning:internal:utils:BadVariableType',pname))
    end
    if ~iscolumn(x)
        error(message('stats:classreg:learning:internal:utils:BadVariableSize',pname))
    end
    if  islogical(x) || iscell(x) || isstring(x) || ...
            (iscategorical(x) && (OrdinalIsCategorical || ~isordinal(x)))
        % These variables must be treated as categorical
        catidx(j) = true;
    end
    if catidx(j) || iscategorical(x)
        % Get a vrange entry for x, and convert x to group numbers
        [vrj,~,x] = unique(x);  % vrange entry is unique values
        if isnumeric(vrj) && any(isnan(vrj))
            % For numeric variables, NaN values are missing
            vrj(isnan(vrj)) = [];
            x(x>length(vrj)) = NaN;
        elseif iscategorical(vrj) && any(isundefined(vrj))
            % For categorical variables, undefined categories are missing
            vrj(isundefined(vrj)) = [];
            x(x>length(vrj)) = NaN;
        elseif iscellstr(vrj)
            % For cellstr variables, empty strings are missing, but they
            % are not sorted to the end so update the group numbers
            empties = cellfun('isempty',vrj);
            newvrj = sort(vrj(~empties,:));
            [~,newx] = ismember(vrj,newvrj);
            x = newx(x);
            vrj = newvrj;
            x(x==0) = NaN;
        end
        vrange{j} = vrj;
    end
    if ~isnumeric(x) && ~islogical(x)
        error(message('stats:classreg:learning:internal:utils:BadVariableType',pname))
    end
    Xout(:,j) = x;
end
end


function ArgName = resolveName(ParameterName,ArgName,FormulaName,emptyok,VarNames,wantcell)
if nargin<6
    wantcell = false;
end
if isempty(ArgName)
    if isempty(FormulaName) && ~emptyok
        error(message('stats:classreg:learning:internal:utils:MissingArg',ParameterName))
    end
    ArgName = FormulaName;
elseif ~isempty(FormulaName)
    if ~all(strcmp(FormulaName,ArgName))
        error(message('stats:classreg:learning:internal:utils:ConflictingArg',ParameterName))
    end
end
if ischar(ArgName) && (wantcell || ~isrow(ArgName))
    ArgName = cellstr(ArgName);
end
if ~isempty(ArgName) && (   ~internal.stats.isStrings(ArgName) ...
                         || ~all(ismember(ArgName,VarNames)) ...
                         || (iscell(ArgName) && numel(ArgName)~=numel(unique(ArgName))))
    error(message('stats:classreg:learning:internal:utils:InvalidArg',ParameterName))
end
end

function args = updateArgs(ParameterName,ArgName,ArgIndex,args)
if ~isempty(ArgName)
    if ArgIndex>0
        args{ArgIndex} = ArgName;
    else
        args(end+1:end+2) = {ParameterName,ArgName};
    end
end
end
function args = removeArg(ArgIndex,args)
if ArgIndex>0
    args(ArgIndex-1:ArgIndex) = [];
end
end

% -------------
function [FormulaResponseName,FormulaPredictorNames] = processFormula(VarNames,Y)
% Get response and predictor information from the formula input
if isvarname(Y)                                   % fitxxx(tbl, 'y')
    FormulaResponseName = Y;
    FormulaPredictorNames = {};
elseif internal.stats.isString(Y)                 % fitxxx(tbl, 'y~x1+x2')
    formula = classreg.regr.LinearFormula(Y,VarNames);
    termorder = sum(formula.Terms,2);
    if any(termorder>1)
       error(message('stats:classreg:learning:internal:utils:LinearOnly'))
    end
    FormulaResponseName = formula.ResponseName;
    FormulaPredictorNames = formula.PredictorNames;
else                                              % fitxxx(tbl, y)
    FormulaResponseName = '';
    FormulaPredictorNames = {};
end
end

% -----------
function [varargout] = processArgs(pnames,args)
% Find the locations and values for selected parameter names
n = numel(pnames);
varargout = cell(1,2*n);
for j=1:n
    varargout{2*j-1} = '';    % empty value for this arg
    varargout{2*j} = 0;       % no location for this arg
end

for j=1:2:length(args)-1
    pname = args{j};
    if internal.stats.isString(pname)
        argnum = find(strncmpi(pname,pnames,length(pname)));
        if isscalar(argnum)
            varargout{2*argnum-1} = args{j+1};
            varargout{2*argnum} = j+1;
        end
    end
end
end

