function [y,args] = inferResponse(respname,x,varargin)
%inferResponse Infer the response values from argument list.
%   [Y,ARGS] = inferResponse(RESPNAME,X,VARARGIN) takes the name RESPNAME
%   of a response used in fitting, a table or matrix X, and other
%   arguments, and returns response values Y and other arguments.
%
%   This utility is used to process arguments in a method that has a
%   calling sequence similar to the following:
%       L=loss(MODEL,X,Y,'PARAM1',val1,'PARAM2',val2,...)
%       L=loss(MODEL,TBL,'PARAM1',val1,'PARAM2',val2,...)
%       L=loss(MODEL,TBL,Y,'PARAM1',val1,'PARAM2',val2,...)
%
%   The first call is the traditional call with matrix and vector inputs.
%   The second call has a table input, and the values of the predictors and
%   response are obtained from the table using the same variable names that
%   were used in the original fit. The third form also obtains the
%   predictor values from the table, but the response values are passed in
%   separately as the third argument.
%
%   On output, Y is the response variable and ARGS is a cell array
%   containing the arguments that the caller should process.

%   Copyright 2015-2017 The MathWorks, Inc.

if istable(x) || isa(x,'dataset')
    % Regularize the syntax. If the response input is missing, insert it as
    % the name of the response used in the fit.
    if mod(length(varargin),2)==0  % even number, only p/v pairs
        varargin = [{respname},varargin];
    end
    y = varargin{1};
    if internal.stats.isString(y) && size(x,1)>1
        % uncommon to specify a different variable name
        try
            y = x.(y);
        catch me
            error(message('stats:classreg:learning:internal:utils:InvalidResponse',varargin{1}));
        end
    elseif istable(y)
        if size(y,2)==1
            y = y{:,1};
        else
            error(message('stats:classreg:learning:internal:utils:InvalidResponseTable'));
        end
    end
    args = varargin(2:end);
else
    % response is required and must be data
    if isempty(varargin)
        error(message('stats:classreg:learning:internal:utils:MissingResponse',respname));
    end
    
    y = varargin{1};
    args = varargin(2:end);
end

