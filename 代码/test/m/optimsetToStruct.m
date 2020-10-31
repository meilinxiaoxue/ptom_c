function sOut = optimsetToStruct(sIn)
% optimsetToStruct - creates a optimset struct that is
% compatible for code generation with MATLAB Coder.

% sOut = optimsetToStruct(sIn) takes a optimset struct, sIn, and converts
% it into a struct compatible with code generation.

%   Copyright 2017 The MathWorks, Inc.

sOut = sIn;

% Convert anonymous function handles to char array
if ~isempty(sIn.OutputFcn)
    sOut.OutputFcn = func2str(sIn.OutputFcn);
end

if ~isempty(sIn.PlotFcns)
    sOut.PlotFcns = func2str(sIn.PlotFcns);
end

if ~isempty(sIn.HessFcn)
    sOut.HessFcn = func2str(sIn.HessFcn);
end

if ~isempty(sIn.HessMult)
    sOut.HessMult = func2str(sIn.HessMult);
end

if ~isempty(sIn.JacobMult)
    sOut.JacobMult = func2str(sIn.JacobMult);
end

end