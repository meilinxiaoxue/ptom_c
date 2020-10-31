classdef CompactRegressionModel < classreg.learning.coder.CompactPredictor %#codegen
    %CompactRegressionModel Base class for code generation compatible supervised 
    % learning regression models
    
    % Copyright 2017 The MathWorks, Inc.
    
    properties (SetAccess=protected,GetAccess=public)
        
        %RESPONSETRANSFORM Response Transform function.
        ResponseTransform;
    end
    methods (Abstract)
        % abstract methods that all supervised learning models should
        % implement
        predict(obj)
    end
    methods (Abstract, Hidden, Access = protected)
        predictEmptyX(obj)
    end     
    methods (Access=protected)
        function obj = CompactRegressionModel(cgStruct)
            
            coder.internal.prefer_const(cgStruct);
            % call base class constructor
            obj@classreg.learning.coder.CompactPredictor(cgStruct);
            
            % validate struct fields
            validateFields(cgStruct);
            obj = obj.setResponseTransform(cgStruct);
        end
    end
    methods (Access = protected)
        function obj = setResponseTransform(obj,cgStruct)
            % setResponseTransform - method to set the response transform
            coder.internal.prefer_const(cgStruct);
            if cgStruct.CustomResponseTransform
                obj.ResponseTransform = str2func(cgStruct.ResponseTransformFull);
            else
                if strcmpi(cgStruct.ResponseTransform,'identity')
                    obj.ResponseTransform = [];
                else
                    obj.ResponseTransform = str2func(['classreg.learning.coder.transform.' cgStruct.ResponseTransform]);
                end
            end
        end
    end
    methods(Static, Hidden)
        function props = matlabCodegenNontunableProperties(~)
            propstemp = classreg.learning.coder.CompactPredictor.matlabCodegenNontunableProperties;
            props = ['ResponseTransform',propstemp]; 
        end
    end
end

function validateFields(InStr)
% validate fields common to all Regression models
coder.inline('always');

validateattributes(InStr.ResponseTransformFull,{'char'},{'nonempty','row'},mfilename,'ResponseTransform');
validateattributes(InStr.ResponseTransform,{'char'},{'nonempty','row'},mfilename,'ResponseTransform');
validateattributes(InStr.CustomResponseTransform,{'logical'},{'nonempty','scalar'},mfilename,'CustomResponseTransform');

end