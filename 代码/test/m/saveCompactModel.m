function saveCompactModel(compactObj,filename)
%SAVECOMPACTMODEL Saves a compact model into a file used for code
% generation. The compact model can be one of: classification model, 
% regression model and nearest neighbor searcher.
%
% SAVECOMPACTMODEL(COMPACTOBJ,FILENAME) saves a compact model as a struct
% in a MAT-file, FILENAME. FILENAME must be a character vector. The compact 
% model can be one of: classification model, regression model and nearest 
% neighbor searcher. This MAT-file can be passed to loadCompactModel for code
% generation. Use the MAT-file, FILENAME to load and construct a compact 
% model at compile-time.
%
% See also LOADCOMPACTMODEL

% Copyright 2016-2017 The MathWorks, Inc.

if nargin > 1
    filename = convertStringsToChars(filename);
end

narginchk(2,2);

compactStruct = toStruct(compactObj); %#ok<NASGU>
save(filename,'compactStruct');


