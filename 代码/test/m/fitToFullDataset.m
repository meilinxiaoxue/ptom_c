function [varargout] = fitToFullDataset(XTable, BOInfo, FitFunctionArgs, Predictors, Response)
    
%   Copyright 2016 The MathWorks, Inc.

    NewFitFunctionArgs = updateArgsFromTable(BOInfo, FitFunctionArgs, XTable);
    [varargout{1:nargout}] = BOInfo.FitFcn(Predictors, Response, NewFitFunctionArgs{:});
end
