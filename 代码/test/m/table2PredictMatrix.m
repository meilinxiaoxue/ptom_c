function [Xout,Yout,W] = table2PredictMatrix(X,Y,WeightsName,vrange,CategoricalPredictors,pnames)
%table2PredictMatrix Convert table data to matrix data for predicting.
%   [X,Y,W] = table2PredictMatrix(X,Y,W,VRANGE,CATPRED,PNAMES) takes data
%   in either table or matrix form and returns data in matrix form so that
%   predictions can be made. X is a matrix of predictors or a table of all
%   variables. Y is a response vector or the name of the response variable
%   in the table. W is empty, a weights vector, or the name of the weights
%   vector in the table. VRANGE is a cell array of the range of values of
%   each predictor used in fitting. PNAMES is a cell array of predictor
%   variable names and is not used if X is a matrix. CATPRED is a vector
%   of the indices of the predictors that are categorical. On output, X is
%   a matrix, Y is a vector, and W is either empty or a vector.
%
%   This function insures that the coding of the predictors is compatible
%   with the model created by fitting.

%   Copyright 2015-2017 The MathWorks, Inc.

% For user convenience, accept a dataset in place of a table
n = size(X,1);
W = ones(n,1);

if isa(X,'dataset')
    X = dataset2table(X);
end

if ~istable(X)
    % Get Y and weights as passed in
    Yout = Y;
    if ~isempty(WeightsName)
        W = WeightsName;
    end
else
    % Possibly get Y and weights from table
    VarNames = X.Properties.VariableNames;
    
    % Get the response
    Yout = resolveName('Y',Y,VarNames,X);
    
    % Get the weights
    if ~isempty(WeightsName)
        W = resolveName('Weights',WeightsName,VarNames,X);
    end
end

% Create X matrix with categorical variables decoded
Xout = makeXMatrix(X,CategoricalPredictors,vrange,pnames);
end


function Xout = makeXMatrix(X,CategoricalPredictors,vrange,PredictorNames)
if isempty(CategoricalPredictors) && ~istable(X)
    Xout = X;
    return
end
[n,p] = size(X);
if istable(X)
    if isnumeric(PredictorNames)
        p = PredictorNames;
        PredictorNames = strcat({'x'},strjust(num2str((1:p)'),'left'));
    else
        p = numel(PredictorNames);
    end
end
isCat = ismember(1:p,CategoricalPredictors);

Xout = zeros(n,p);
pname = '';
for j=1:p
    if istable(X)
        pname = PredictorNames{j};
        try
            x = X.(pname);
        catch me
            error(message('stats:classreg:learning:internal:utils:MissingPredictors',pname));
        end
    else
        x = X(:,j);
    end
    if ~isempty(vrange) && (isCat(j) || ~isempty(vrange{j}))
        if ischar(x)
            x = cellstr(x);
        end
        vrj = vrange{j};
        if iscategorical(vrj) && isordinal(vrj) && iscategorical(x)
            x = cellstr(x);  % need to forget the x ordering
        end
        try
            [~,x] = ismember(x,vrange{j});
        catch
            x = 'bad';
        end
    end
    if ~isnumeric(x) && ~islogical(x)
        if istable(X)
            error(message('stats:classreg:learning:internal:utils:BadVariableType',pname))
        else
            error(message('stats:classreg:learning:internal:utils:BadColumnType',j))
        end
    end
    if ~iscolumn(x)
        error(message('stats:classreg:learning:internal:utils:BadVariableSize',pname))
    end
    Xout(:,j) = x;
end
end

function ArgName = resolveName(ParameterName,ArgName,VarNames,X)
if ~isempty(ArgName) && internal.stats.isString(ArgName)
    % Response may have been specified as a string
    if ismember(ArgName,VarNames)
        ArgName = X.(ArgName);
    elseif size(X,1)>1
        % Response may be a single-row char when X has a single row
        error(message('stats:classreg:learning:internal:utils:InvalidArg',ParameterName))
    end
end
end

