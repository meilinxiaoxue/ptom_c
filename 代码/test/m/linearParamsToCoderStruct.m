function s = linearParamsToCoderStruct(s)
% Convert input struct to output struct for codegen

%   Copyright 2016 The MathWorks, Inc.

% Random stream. If not empty, convert to struct.
if ~isempty(s.Stream)
    s.Stream = get(s.Stream);
end

% Solver: convert from cellstr to char
solver = s.Solver;
if ~isrow(solver)
    solver = solver(:)';
end
s.SolverNamesLength = cellfun(@length,solver);
s.SolverNames = char(solver');
s = rmfield(s,'Solver');
end
