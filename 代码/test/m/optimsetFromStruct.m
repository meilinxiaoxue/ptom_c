function sOut = optimsetFromStruct(sIn)
% optimsetFromStruct - reconstructs an optimset struct from the 
% codegen-compatible.

% sOut = optimsetFromStruct(sIn) takes a codegen-compatible struct, sIn,
% and reconstructs an optimset struct.

%   Copyright 2017 The MathWorks, Inc.

sOut = sIn;

if ~isempty(sIn.OutputFcn)
    sOut.OutputFcn = str2func(sIn.OutputFcn);
end

if ~isempty(sIn.PlotFcns)
    sOut.PlotFcns = str2func(sIn.PlotFcns);
end

if ~isempty(sIn.HessFcn)
    sOut.HessFcn = str2func(sIn.HessFcn);
end

if ~isempty(sIn.HessMult)
    sOut.HessMult = str2func(sIn.HessMult);
end

if ~isempty(sIn.JacobMult)
    sOut.JacobMult = str2func(sIn.JacobMult);
end

end