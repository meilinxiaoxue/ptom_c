classdef CompactSVM     %#codegen
    
    %CompactSVM Base class for code generation compatible SVM models 
    % Defined properties and implements functions common to all SVM models
    
    % Copyright 2017 The MathWorks, Inc.
      
    properties (SetAccess=protected,GetAccess=public)

        %ALPHA Coefficients obtained by solving the dual problem.
        Alpha;
        
        %BETA Coefficients for the primal linear problem.
        Beta;
        
        %BIAS Bias term.
        Bias;
        
        %KERNELPARAMETERS Parameters of the kernel function.
        KernelParameters;
        
        %MU Predictor means.
        Mu;
        
        %SIGMA Predictor standard deviations.
        Sigma;
           
        %SUPPORTVECTORST  Transposed Support Vectors for CompactClassificationSVM
        %   Utilized for score calculation for nonlinear SVM
        SupportVectorsT;
    
    end    
    methods (Access=protected)
        function obj = CompactSVM(cgStruct)
            % COMPACTSVM constructor that takes a struct
            %    representing the CompactClassificationObject as an input
            %    and parses to get SVM parameters.
            
            coder.internal.prefer_const(cgStruct);
            
            % validate struct fields
            validateFields(cgStruct);
            
            obj.Bias                 = cgStruct.Impl.Bias;
            obj.Beta                 = cgStruct.Impl.Beta;
            obj.SupportVectorsT      = coder.const(@transpose,cgStruct.Impl.SupportVectors);
            obj.Mu                   = cgStruct.Impl.Mu;
            obj.Sigma                = cgStruct.Impl.Sigma;
            obj.KernelParameters     = cgStruct.Impl.KernelParameters;

        end
    end
    methods (Static, Hidden, Abstract)
        % abstract methods that need to be implemented by all SVM models
        predictEmptySVMModel(obj)
    end
    methods (Access = protected)
        function X = normalize(obj,X)
            % NORMALIZE normalize incoming test vector with using mu and
            %   sigma
            
            mu = obj.Mu;
            if ~isempty(mu) && ~all(mu==0)
                X = bsxfun(@minus,X,mu);
            end
            
            sigma = obj.Sigma;
            if ~isempty(sigma) && ~all(sigma==1)
                nonzero = sigma > 0;
                if any(nonzero)
                    X(:,nonzero) = bsxfun(@rdivide,X(:,nonzero),sigma(nonzero));
                end
            end
        end

        function S = score(obj,Xin)
            %SCORE Calculate score for each observation.
            
            coder.internal.prefer_const(obj);
  
            bias = obj.Bias;
            if isa(Xin,'double') && isa(bias,'single')
                X = single(Xin);
            else
                X = Xin;
            end
                        
            if isempty(obj.Beta) && isempty(obj.Alpha)
                f = obj.predictEmptySVMModel(X,bias);
            else
                coder.internal.errorIf(~coder.internal.isConst(size(X,2)) || coder.internal.indexInt(size(X,2))~=obj.NumPredictors,...
                    'stats:classreg:learning:impl:CompactSVMImpl:score:BadXSize',obj.NumPredictors);
                
                % Normalize data
                X = obj.normalize(X);
                
                % get kernel score
                f = obj.kernelScore(X);
            end
            S = f;
        end 
        
        function f = kernelScore(obj,X)
            % KERNELSCORE calculate score using specified kernel
            %   built-in kernels are linear, gaussian and polynomial.
            %   Also accepts custom kernel.
            
            % validate kernel scale
            coder.internal.prefer_const(obj);
            validateattributes(obj.KernelParameters.Scale,{'numeric'},{'scalar','real','positive','nonnan'},mfilename,'Scale');
            scale = cast(obj.KernelParameters.Scale,'like',X);
            kernelFcn = obj.KernelParameters.Function;            
            betas     = obj.Beta;
            svT       = obj.SupportVectorsT./scale;
            alphas    = obj.Alpha;
            bias      = obj.Bias;
            
            % if kernelFcn is not linear, polynomial or gaussian(rbf),
            % assume custom kernel
            switch kernelFcn
                
                case 'linear'
                    if isempty(alphas)
                        f = (X/scale)*betas + bias;
                    else
                        innerProduct = classreg.learning.coder.kernel.Linear(svT,X./scale);
                        f = innerProduct*alphas + bias;
                    end
                case 'polynomial'
                    % validate polynomial order
                    validateattributes(obj.KernelParameters.PolyOrder,{'numeric'},{'nonnan','finite','integer','scalar','real','positive'},mfilename,'PolyOrder');
                    order = obj.KernelParameters.PolyOrder;
                    innerProduct = classreg.learning.coder.kernel.Poly(svT,order,X./scale);
                    f = innerProduct*alphas + bias;
                case {'rbf','gaussian'}
                    svInnerProduct = dot(svT,svT);
                    n = size(X,1);
                    f = coder.nullcopy(zeros(coder.internal.indexInt(n),1,'like',X));
                    for i = 1:coder.internal.indexInt(n)
                        innerProduct = classreg.learning.coder.kernel.Gaussian(svT,svInnerProduct,X(i,:)./scale);
                        f(i) = innerProduct*alphas + bias;
                    end
                otherwise %custom kernel
                    kernelFunction = str2func(coder.const(kernelFcn));
                    n = size(X,1);
                    f = coder.nullcopy(zeros(coder.internal.indexInt(n),1,'like',X));
                    for i = 1:coder.internal.indexInt(n)
                        innerProduct = kernelFunction(coder.const(obj.SupportVectorsT'),X(i,:));
                        f(i) = innerProduct'*alphas + bias;
                    end    
            end
        end     
    end
    
    methods (Static, Access = protected)
        function [posterior] = svmPredictEmptyX(Xin,K,numPredictors,bias)
            % svmPredictEmptyX prediction for empty data
            
            
            Dpassed = coder.internal.indexInt(size(Xin,2));
            str = 'columns';

            coder.internal.errorIf(~coder.internal.isConst(Dpassed) || Dpassed ~=numPredictors,...
                'stats:classreg:learning:classif:ClassificationModel:predictEmptyX:XSizeMismatch', numPredictors, str);
            
            if isa(Xin,'double') && isa(bias,'single')
                X = single(Xin);
            else
                X = Xin;
            end
            posterior = repmat(coder.internal.nan('like',X),0,K);
            
        end          
    end
    methods (Static, Hidden)
        function props = matlabCodegenNontunableProperties(~)
            props = {'KernelParameters','SupportVectorsT'};
        end        
    end  
end

function validateFields(InStr)
% validate fields specific to SVM models

coder.inline('always');

% validate Impl parameters
validateattributes(InStr.Impl.Bias,{'numeric'},{'nonnan','finite','nonempty','scalar','real'},mfilename,'Bias');

if ~isempty(InStr.Impl.Alpha)
    validateattributes(InStr.Impl.Alpha,{'numeric'},{'nonnan','column','real'},mfilename,'Alpha');
end

if ~isempty(InStr.Impl.Beta)
    validateattributes(InStr.Impl.Beta,{'numeric'},{'column','numel',InStr.DataSummary.NumPredictors,'real'},mfilename,'Beta');
end

validateattributes(InStr.Impl.SupportVectors,{'numeric'},{'2d','nrows',size(InStr.Impl.Alpha,1),'real'},mfilename,'SupportVectors');

if ~isempty(InStr.Impl.Mu) 
    if ~isempty(InStr.Impl.SupportVectors) % if supportvectors is empty, size must match size(Beta,1)
        validateattributes(InStr.Impl.Mu,{'numeric'},{'size',[1 size(InStr.Impl.SupportVectors,2)],'real'},mfilename,'Mu');
    else
        validateattributes(InStr.Impl.Mu,{'numeric'},{'size',[1 size(InStr.Impl.Beta,1)],'real'},mfilename,'Mu');
    end
end

if ~isempty(InStr.Impl.Sigma) 
    if ~isempty(InStr.Impl.SupportVectors) % if supportvectors is empty, size must match size(Beta,1)
        validateattributes(InStr.Impl.Sigma,{'numeric'},{'size',[1 size(InStr.Impl.SupportVectors,2)],'real'},mfilename,'Sigma');
    else
        validateattributes(InStr.Impl.Sigma,{'numeric'},{'size',[1 size(InStr.Impl.Beta,1)],'real'},mfilename,'Sigma');
    end
end
end


