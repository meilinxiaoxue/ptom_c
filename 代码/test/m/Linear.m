classdef Linear    %#codegen
    
    %Linear Base class for code generation compatible Linear models 
    % Defined properies and implements functions common to all Linear models
    
    % Copyright 2017 The MathWorks, Inc.
    
    properties (SetAccess=protected,GetAccess=public)
        
        %BETA Coefficients for the primal linear problem.
        Beta;
        
        %BIAS Bias term.
        Bias;
        
        %OBSERVATIONSINROWS flag to determine whether observations are
        %given in rows or columns
        %ObservationsInRows;
        
    end
    methods (Static, Hidden, Abstract)
        % abstract methods that need to be implemented by all Linear models
        predictEmptyLinearModel(obj)
    end    
    
    methods (Access=protected)
        function obj = Linear(cgStruct)
            
            coder.internal.prefer_const(cgStruct);
            % validate struct fields
            validateFields(cgStruct);
            
            obj.Bias                 = cgStruct.Impl.Bias; %#ok<*MCNPN>
            obj.Beta                 = cgStruct.Impl.Beta;
            
        end
        
    end

    methods (Static, Access = protected)
        
        function obsInRows = extractObsInRows(varargin)

            orientation = parseOptionalInputs(varargin{:});
            
            obsIn = validateObservationsIn(orientation);
            
            obsInRows = strncmpi(obsIn,'rows',1); %Currently only supports rows and columms;
          
        end     
        
        function posterior = linearPredictEmptyX(Xin,K,numPredictors,bias,obsInRows)
            
            if obsInRows
                Dpassed = coder.internal.indexInt(size(Xin,2));
                str = 'columns';
            else
                Dpassed = coder.internal.indexInt(size(Xin,1));
                str = 'rows';
            end
            
            coder.internal.errorIf(Dpassed~=numPredictors,...
                'stats:classreg:learning:classif:ClassificationModel:predictEmptyX:XSizeMismatch', numPredictors, str);
            
            if isa(Xin,'double') && isa(bias,'single')
                X = single(Xin);
            else
                X = Xin;
            end
            
            posterior = repmat(coder.internal.nan(1,1,'like',X),0,K);
        end        
    end
    
    methods(Hidden, Access = protected)
        
        function S = score(obj,Xin,obsInRows)
            %SCORE Calculate score for each observation.
            
            coder.internal.prefer_const(obj);
   
            numLambda = cast(1,'like',obj.Bias);
            
            if isa(Xin,'double') && isa(obj.Bias,'single')
                X = single(Xin);
            else
                X = Xin;
            end
            
            if obsInRows % Observations comes in rows
                D = size(X,2);
                str = 'columns';
            else% Observations comes in columns
                D = size(X,1);
                str = 'rows';
            end
            if isempty(obj.Beta)
                S = obj.predictEmptyLinearModel(X,obj.Bias,numLambda);
            else
                coder.internal.errorIf(coder.internal.indexInt(D)~=obj.NumPredictors,...
                    'stats:classreg:learning:classif:ClassificationModel:predictEmptyX:XSizeMismatch', obj.NumPredictors, str);
                
                if obsInRows% Observations comes in Rows
                    S = bsxfun(@plus,X*obj.Beta,obj.Bias);  %S = X*betas+bias;
                else % Observations comes in Columns
                    S = bsxfun(@plus,(obj.Beta'*X)',obj.Bias); % S = (betas'*X)'+bias;
                end
            end
        end
        
    end
    
    methods(Static, Hidden)
        function props = matlabCodegenNontunableProperties(~)
            props = {'ObservationsInRows'};
        end
    end
end


function observationsIn = parseOptionalInputs(varargin)
% PARSEOPTIONALINPUTS  Parse optional PV pairs
%
% 'ObservationsIn'

coder.inline('always');
coder.internal.prefer_const(varargin);

params = struct( ...
    'ObservationsIn', uint32(0));

popts = struct( ...
    'CaseSensitivity', false, ...
    'StructExpand',    true, ...
    'PartialMatching', true);

optarg           = eml_parse_parameter_inputs(params, popts, ...
    varargin{:});
observationsIn   = eml_get_parameter_value(...
    optarg.ObservationsIn, 'rows', varargin{:});

end

function validateFields(InStr)
% Validate orientation of observations.


coder.inline('always');

% validate Impl parameters
validateattributes(InStr.Impl.Bias,{'numeric'},{'nonnan','finite','nonempty','scalar','real'},mfilename,'Bias');

if ~isempty(InStr.Impl.Beta)
    validateattributes(InStr.Impl.Beta,{'numeric'},{'column','numel',InStr.DataSummary.NumPredictors,'real'},mfilename,'Beta');
end


end

function ori=validateObservationsIn(orientation)
% Validate orientation of observations.

coder.inline('always');
coder.internal.prefer_const(orientation);
ori = validatestring(orientation,{'rows','columns'},mfilename, 'ObservationsIn');

end


