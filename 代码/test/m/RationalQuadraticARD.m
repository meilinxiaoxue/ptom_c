classdef RationalQuadraticARD < classreg.learning.gputils.Kernel
%RationalQuadraticARD A class that defines the rational quadratic kernel with a separate length scale per predictor.
%
%   RationalQuadraticARD properties:
%       Name          - Name of the kernel function.
%       Theta         - Vector of unconstrained parameters for this kernel function.
%       NumParameters - Length of vector Theta.
%
%   RationalQuadraticARD methods:
%       makeFromTheta                    - Create object from Theta.
%       summary                          - Get information about this kernel.
%       setTheta                         - Set Theta.
%       makeKernelAsFunctionOfTheta      - Make kernel as function of Theta given XN and XM.
%       makeDiagKernelAsFunctionOfTheta  - Make diagonal of kernel as function of Theta given XN.
%       makeKernelAsFunctionOfXNXM       - Make kernel as function of XN and XM given Theta.
%       makeDiagKernelAsFunctionOfXN     - Make diagonal of kernel as function of XN given Theta.

%   Copyright 2014-2016 The MathWorks, Inc.

    properties(Constant)
        %NAME - Name of the kernel function.
        %   NAME is a string representing the kernel function.
        Name = classreg.learning.modelparams.GPParams.RationalQuadraticARD;              
    end
    
    properties(GetAccess=public,SetAccess=protected)
        %THETA - Unconstrained parameter vector for the kernel function.
        %   THETA is a vector of unconstrained parameters for the kernel
        %   function. The RationalQuadraticARD kernel can be parameterized
        %   in terms of the positive quantities sigmaL, sigmaF, and alpha:
        %
        %       sigmaL  = d-by-1 length scale vector
        %       alpha   = Rational quadratic exponent
        %       sigmaF  = Multiplier of the exp term
        %
        %   where d = number of predictors.
        %
        %   The unconstrained parameterization THETA is defined as:
        %       THETA(1:d) = log(sigmaL)
        %       THETA(d+1) = log(alpha)
        %       THETA(d+2) = log(sigmaF)
        Theta;
        
        %NUMPARAMETERS - Length of THETA vector.
        NumParameters;
        
        %CUSTOMFCN - Custom kernel function.
        %   Does not apply to the RationalQuadraticARD kernel.
        CustomFcn = [];          
    end
    
    properties
        %USEPDIST - Logical flag indicating whether pdist2 should be used
        %   for squared Euclidean distance computations.
        UsePdist = false;
        
        %TINY - A scalar indicating the smallest value that elements of
        %   sigmaL, sigmaF, and alpha can take.
        Tiny = 1e-6;        
    end
    
    methods       
        function this = setTheta(this,theta)
        %setTheta - Set the value of Theta.
        %   this = setTheta(this,theta) takes a (d+2)-by-1 vector theta and
        %   returns an updated object with this.Theta set to theta.
            this.Theta = theta;
        end
    end
    
    
    % Constructing from THETA.
    methods(Access=protected)
        function this = RationalQuadraticARD()            
        end        
    end
    methods(Static)        
        function this = makeFromTheta(theta)
        %makeFromTheta - Make RationalQuadraticARD kernel function.
        %   this = makeFromTheta(Theta) takes a (d+2)-by-1 vector Theta
        %   where d is the number of predictors and returns a
        %   RationalQuadraticARD kernel object. Theta is related to
        %   length scale sigmaL, multiplier of exp term sigmaF, and
        %   rational quadratic exponent alpha like this:
        %
        %       Theta(1:d) = log(sigmaL)
        %       Theta(d+1) = log(alpha)
        %       Theta(d+2) = log(sigmaF)
        
            this               = classreg.learning.gputils.RationalQuadraticARD();
            this.Theta         = theta;
            this.NumParameters = length(theta);
        end
    end
        
    % Getting kernel parameter Information.
    methods      
        function params = summary(this)
        %SUMMARY - Returns information about this kernel function.
        %   params = SUMMARY(this) returns a struct with three fields:
        %
        %       Name                 - Name of the kernel function.
        %       KernelParameters     - Vector of kernel parameters.
        %       KernelParameterNames - Names associated with elements of KernelParameters.
        %
        %   As an example, for RationalQuadraticARD with 2 predictors,
        %   params struct has these fields:
        %
        %       Name                 = 'ARDRationalQuadratic'
        %       KernelParameters     = [1,2;3;4]
        %       KernelParameterNames = {'LengthScale1','LengthScale2','AlphaRQ','SigmaF'}     
        
            params                      = struct();
            params.Name                 = this.Name;
            
            theta                       = this.Theta;
            d                           = length(theta) - 2;                    
            params.KernelParameters     = exp(theta);
            KernelParameterNames = cell(d+2,1);
            for i = 1:d
                KernelParameterNames{i} = ['LengthScale',num2str(i)];
            end
            KernelParameterNames{d+1} = 'AlphaRQ';
            KernelParameterNames{d+2} = 'SigmaF';
            
            params.KernelParameterNames = KernelParameterNames;
        end
    end
            
    methods
        function kfcn = makeKernelAsFunctionOfTheta(this,XN,XM,usecache)
        %makeKernelAsFunctionOfTheta - Evalulate kernel for fixed XN and XM.
        %   kfcn = makeKernelAsFunctionOfTheta(this,XN,XM,usecache) returns 
        %   a function handle kfcn that can be called like this:
        %
        %   [KNM,DKNM] = kfcn(ThetaNew)
        %
        %   where
        %
        %   o ThetaNew is some new value of Theta.
        %   o KNM  = K(XN,XM | ThetaNew).
        %   o DKNM = A function handle that accepts an integer i such that 
        %            DKNM(i) is the derivative of K(XN,XM | Theta) w.r.t. 
        %            Theta(i) evaluated at ThetaNew.
        %
        %   usecache is a logical flag. If usecache is true the squared
        %   Euclidean distance matrix is cached for faster evaluation of
        %   KNM and DKNM at a higher memory cost.        
        
            % 1. Precompute distance matrix if usecache is true. If XN is
            % N-by-d, XM is M-by-d then D2 below is N-by-M-by-d for ARD. Do
            % not force D2 to be >= 0 for the RationalQuadraticARD kernel.
            usepdist = this.UsePdist;
            makepos  = false;
            if usecache
                D2 = classreg.learning.gputils.calcDistanceARD(XN,XM,usepdist,makepos);
            end
        
            % 2. Get smallest allowable value for components of sigmaL and
            % sigmaF.
            tiny = this.Tiny;
            
            % 3. Define kfcn.
            kfcn = @f;
            function [KNM,DKNM] = f(theta)
            % NOTE: theta is such that:
            % theta(1:d) = log(sigmaL)
            % theta(d+1) = log(alpha)
            % theta(d+2) = log(sigmaF)
            % d = number of predictors or variables
            
                % 3.1 Transform theta into sigmaL, sigmaF, and alpha.
                % Ensure that sigmaL, sigmaF, and alpha do not become
                % really small.
                d      = length(theta) - 2;
                sigmaL = exp(theta(1:d));
                alpha  = exp(theta(d+1));
                sigmaF = exp(theta(d+2));
                
                sigmaL = max(sigmaL,tiny);
                alpha  = max(alpha,tiny);
                sigmaF = max(sigmaF,tiny);
                
                % 3.2 Compute KNM with or without cache.
                if usecache
                    sigmaL3D = reshape(sigmaL,1,1,d);
                    KNM = sum(bsxfun(@rdivide,D2,sigmaL3D.^2),3);                    
                else
                    KNM = classreg.learning.gputils.calcDistance(XN(:,1)/sigmaL(1),XM(:,1)/sigmaL(1),usepdist,makepos);
                    for r = 2:d
                        KNM = KNM + classreg.learning.gputils.calcDistance(XN(:,r)/sigmaL(r),XM(:,r)/sigmaL(r),usepdist,makepos);
                    end
                end
                
                % In order to keep calculation accuracy even when alpha is
                % large, take the logarithm of the entire equation in order
                % take advantage of the accurary of log1p.  Then, transform
                % the answer back by using the exp function.
                D2SUM = KNM;
                basem1 = D2SUM./(2*alpha);
                KNM = (2.*log(sigmaF))+(-alpha.*log1p(basem1));
                KNM = exp(KNM);
                
                % 3.3 Get DKNM if needed.
                if nargout < 2
                    return;
                end
                
                % For the derivatives, calculation accuracy is not as
                % impacted by alpha being large.  This is because terms
                % that use alpha do not exponentiate as in the kernel 
                % function itself.  For example, 1e16./(1+eps/2) may have a 
                % small amount of precision error, but (1+eps/2).^1e16 will
                % have the small amount of precision error magnified
                % greatly due to repeated multiplication.
                DKNM = @derf;
                function DKNMr = derf(r)
                    if ( r == d+1)
                        DKNMr = KNM.*(D2SUM./(2*(1+basem1))-alpha*log1p(basem1));
                    elseif ( r == d+2 )
                        DKNMr = 2*KNM;
                    else
                        if usecache
                            DKNMr = (KNM./(1+basem1)).*(D2(:,:,r)/(sigmaL(r)^2));
                        else
                            DKNMr = (KNM./(1+basem1)).*(classreg.learning.gputils.calcDistance(XN(:,r)/sigmaL(r),XM(:,r)/sigmaL(r),usepdist,makepos));
                        end
                    end
                end

            end
            
        end
        
        function kfcn = makeDiagKernelAsFunctionOfTheta(this,XN,usecache) %#ok<INUSD>
        %makeDiagKernelAsFunctionOfTheta - Evaluate diagonal of kernel for fixed XN.
        %   kfcn = makeDiagKernelAsFunctionOfTheta(this,XN,usecache) returns 
        %   a function handle kfcn that can be called like this:
        %
        %   [diagKNN,DdiagKNN] = kfcn(ThetaNew)
        %
        %   where
        %
        %   o ThetaNew is some new value of Theta.
        %   o diagKNN  = diagonal of K(XN,XN | ThetaNew).
        %   o DdiagKNN = A function handle that accepts an integer i such 
        %                that DdiagKNN(i) is the derivative of the diagonal
        %                of K(XN,XN | Theta) w.r.t. Theta(i) evaluated at 
        %                ThetaNew. 
        %
        %   usecache has no effect in this function because we exploit the
        %   structure of the kernel directly.
    
            % 1. Get N and some reusable quantities.
            N  = size(XN,1);
            eN = ones(N,1);
            zN = zeros(N,1);
            
            % 2. Get smallest allowable value for components of sigmaL and
            % sigmaF.
            tiny = this.Tiny;
            
            % 3. Make kfcn.
            kfcn = @f;
            function [diagKNN,DdiagKNN] = f(theta)
            % NOTE: theta is such that:
            % theta(1:d) = log(sigmaL)
            % theta(d+1) = log(alpha)
            % theta(d+2) = log(sigmaF)
            % d = number of predictors or variables      
                
                % 3.1 Compute diagKNN and ensure that sigmaF is not too
                % small.
                d       = length(theta) - 2;
                sigmaF  = exp(theta(d+2));
                sigmaF  = max(sigmaF,tiny);
                diagKNN = (sigmaF^2)*eN;
                
                % 3.2 Compute DdiagKNN if needed.
                if nargout < 2
                    return;
                end
                
                DdiagKNN = @derf;
                function DdiagKNNr = derf(r)
                    if ( r == d+2 )
                        DdiagKNNr = 2*diagKNN;                        
                    else
                        DdiagKNNr = zN;
                    end
                end
            end
        
        end

        function kfcn = makeKernelAsFunctionOfXNXM(this,theta)
        %makeKernelAsFunctionOfXNXM - Evaluate kernel for fixed Theta.
        %   kfcn = makeKernelAsFunctionOfXNXM(this,Theta) returns a function 
        %   handle kfcn that can be called like this:
        %
        %   KNM = kfcn(XN,XM)
        %
        %   o XN  = N-by-d matrix
        %   o XM  = M-by-d matrix
        %   o KNM = N-by-M kernel matrix K(XN,XM | Theta).        
            
            % NOTE: theta is such that:
            % theta(1:d) = log(sigmaL)
            % theta(d+1) = log(alpha)
            % theta(d+2) = log(sigmaF)
            % d = number of predictors or variables
            
            % 1. Get sigmaL, sigmaF, and alpha from theta. Ensure that
            % sigmaL, sigmaF, and alpha do not become too small. Don't
            % need to force the output of calcDistance to be >= 0 for the
            % RationalQuadraticARD kernel.
            d        = length(theta) - 2;            
            sigmaL   = exp(theta(1:d));
            alpha    = exp(theta(d+1));
            sigmaF   = exp(theta(d+2));
            tiny     = this.Tiny;
            sigmaL   = max(sigmaL,tiny);
            alpha    = max(alpha,tiny);
            sigmaF   = max(sigmaF,tiny);
            usepdist = this.UsePdist;
            makepos  = false;
            
            % 2. Make kfcn.
            kfcn = @f;
            function KNM = f(XN,XM)              
                % 2.1 Compute normalized Euclidean distances.             
                KNM = classreg.learning.gputils.calcDistance(XN(:,1)/sigmaL(1),XM(:,1)/sigmaL(1),usepdist,makepos);
                for r = 2:d
                    KNM = KNM + classreg.learning.gputils.calcDistance(XN(:,r)/sigmaL(r),XM(:,r)/sigmaL(r),usepdist,makepos);
                end
                
                % 2.2 Find the complete kernel.
                % In order to keep calculation accuracy even when alpha is
                % large, take the logarithm of the entire equation in order
                % take advantage of the accurary of log1p.  Then, transform
                % the answer back by using the exp function.
                KNM = KNM./(2*alpha);
                KNM = (2.*log(sigmaF))+(-alpha.*log1p(KNM));
                KNM = exp(KNM);
            end
    
        end

        function kfcn = makeDiagKernelAsFunctionOfXN(this,theta)
        %makeDiagKernelAsFunctionOfXN - Evaluate diagonal of kernel for fixed Theta.
        %   kfcn = makeDiagKernelAsFunctionOfXN(this,Theta) returns a function 
        %   handle kfcn that can be called like this:
        %
        %   diagKNN = kfcn(XN)
        %
        %   o XN      = N-by-d matrix
        %   o diagKNN = diagonal of K(XN,XN | Theta).
        
            % NOTE: theta is such that:
            % theta(1:d) = log(sigmaL)
            % theta(d+1) = log(alpha)
            % theta(d+2) = log(sigmaF)
            % d = number of predictors or variables
            
            % 1. Get sigmaF from theta. Ensure that sigmaF is not too
            % small.
            d      = length(theta) - 2;            
            sigmaF = exp(theta(d+2));
            tiny   = this.Tiny;
            sigmaF = max(sigmaF,tiny);
            
            % 2. Make kfcn.
            kfcn = @f;
            function diagKNN = f(XN)                
                N       = size(XN,1);
                diagKNN = (sigmaF^2)*ones(N,1);
            end
        
        end
        
    end              
    
end