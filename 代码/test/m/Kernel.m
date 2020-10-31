classdef Kernel
%Kernel Linear model after explicit kernel expansion.
%   Kernel is a super class that represents a linear model in a high
%   diemesional space. Original features are mapped using a random
%   transformation T() such that dot(T(X(i,:)),T(X(j,:))) approximates
%   the Gausian kernel.
%
%   Copyright 2017 The MathWorks, Inc.    
    
    properties(Abstract=true,Hidden=true)
        Impl;
    end
    
    properties(GetAccess=public,SetAccess=protected,Hidden=true)
        ModelParams;
    end    
    
    properties(GetAccess=protected,SetAccess=protected)
        FeatureMapper;
    end
    
    properties(GetAccess=protected,SetAccess=protected,Dependent=true)
        Beta;
        Bias;
    end      
    
    properties(GetAccess=public,SetAccess=protected,Dependent=true,Hidden=true)        
        ExpansionDimension; % Property changed name, left it here for compatibility.
    end
     
    properties(GetAccess=public,SetAccess=protected,Dependent=true)        
        %NumExpansionDimensions Number of dimensions.
        %   The NumExpansionDimensions property is a integer representing the
        %   number of dimensions in transformed space after explicity
        %   mapping the predictor matrix.
        %  
        %   See also ClassificationKernel, RegressionKernel.        
        NumExpansionDimensions;
        
        %FittedLoss Fitted loss function.
        %   The FittedLoss property is a string specifying the fitted loss
        %   function.
        %  
        %   See also ClassificationKernel, RegressionKernel.
        FittedLoss;
        
        %Lambda Regularization strength.
        %   The Lambda property is a vector of values used to regularize the
        %   objective function.
        %  
        %   See also ClassificationKernel, RegressionKernel.
        Lambda;
        
        %ModelParameters Model parameters.
        %   The ModelParameters property holds parameters used for training this
        %   model.        
        %  
        %   See also ClassificationKernel, RegressionKernel.
        ModelParameters;
        
        %Regularization Type of regularization.
        %   The Regularization property is a string holding the regularization
        %   type, 'lasso (L1)' or 'ridge (L2)'.
        %  
        %   See also ClassificationKernel, RegressionKernel.
        Regularization;
    end
    
    properties(GetAccess=public,SetAccess=protected)
        %KernelScale Kernel scale.
        %   The KernelScale property is a non negative scalar used to
        %   amplify the Gaussian kernel.
        %  
        %   See also ClassificationKernel, RegressionKernel.        
        KernelScale;
        
        %Learner Type of learning model
        %   The Learner property is a string indicating the type of model
        %   learned, 'svm', 'leastsquares' or 'logistic'.
        %  
        %   See also ClassificationKernel, RegressionKernel.         
        Learner;
    end
    
    methods(Access=protected)
        function this = Kernel()
        end
        
        function s = propsForDisp(this,s)
            if nargin<2 || isempty(s)
                s = struct;
            else
                if ~isstruct(s)
                    error(message('stats:classreg:learning:Predictor:propsForDisp:BadS'));
                end
            end
            s.Learner            = this.Learner;
            if isempty(this.FeatureMapper)
                s.Transformation = '';
            else
                s.Transformation = this.FeatureMapper.t;
            end
            s.NumExpansionDimensions = this.NumExpansionDimensions;
            s.KernelScale        = this.KernelScale;
            s.Lambda             = this.Lambda;
        end
    end
    
    methods
        function beta = get.Beta(this)
            beta = this.Impl.Beta;
        end
        
        function bias = get.Bias(this)
            bias = this.Impl.Bias;
        end
        
        function fl = get.FittedLoss(this)
            fl = this.Impl.LossFunction;
        end
        
        function lambda = get.Lambda(this)
            lambda = this.Impl.Lambda;
        end
        
        function mp = get.ModelParameters(this)
            mp = this.ModelParams;
        end
        
        function r = get.Regularization(this)
            if this.Impl.Ridge
                r = 'ridge (L2)';
            else
                r = 'lasso (L1)';
            end
        end
        
        function ed = get.ExpansionDimension(this)
            if isempty(this.FeatureMapper)
                ed = [];
            else
                ed = this.FeatureMapper.n;
            end
        end
        
        function ed = get.NumExpansionDimensions(this)
            if isempty(this.FeatureMapper)
                ed = [];
            else
                ed = this.FeatureMapper.n;
            end
        end
        
    end
    
    methods(Static,Hidden)
        function [X,Y,W,dataSummary] = prepareDataCR(X,Y,varargin)            
            
            % Preprocessing is almost similar to classreg.learning.Linear
            % except that for kernel model we prefer the predictor matrix
            % arranged by rows (i.e. observations are rows)
            
            % Process input args                      
            [ignoreextra,~,inputArgs] = internal.stats.parseArgs(...
                {'ignoreextraparameters'},{false},varargin{:});

            args = {'weights' 'predictornames' 'responsename' ...
                'categoricalpredictors' 'observationsin'};
            defs = {       []               []             [] ...
                                     []           'rows'};
                                 
            if ignoreextra
                [W,predictornames,responsename,catpreds,obsIn,~,~] = ...
                    internal.stats.parseArgs(args,defs,inputArgs{:});
            else
                [W,predictornames,responsename,catpreds,obsIn] = ...
                    internal.stats.parseArgs(args,defs,inputArgs{:});
            end
            
            % Check input type.
            if ~isfloat(X) || ~ismatrix(X)
                error(message('stats:classreg:learning:FullClassificationRegressionModel:prepareDataCR:BadXType'));
            end
            internal.stats.checkSupportedNumeric('X',X,false,true);
            
            % Check input orientation
            obsIn = validatestring(obsIn,{'rows' 'columns'},...
                'classreg.learning.Linear.prepareDataCR','ObservationsIn');
            obsInRows = strcmp(obsIn,'rows');
            if obsInRows
                X = X';
            end

            % Check input size
            if isempty(X) || isempty(Y)
                error(message('stats:classreg:learning:FullClassificationRegressionModel:prepareDataCR:NoData'));
            end
            N = size(X,2);
            if N~=length(Y)
                error(message('stats:classreg:learning:FullClassificationRegressionModel:prepareDataCR:InputSizeMismatch'));
            end
 
            % Check weights
            if isempty(W)
                W = ones(N,1);
            else
                if ~isfloat(W) || length(W)~=N || ~isvector(W)
                    error(message('stats:classreg:learning:FullClassificationRegressionModel:prepareDataCR:BadW'));
                end
                if any(W<0) || all(W==0)
                    error(message('stats:classreg:learning:FullClassificationRegressionModel:prepareDataCR:NegativeWeights'));
                end
                W = W(:);
            end
            internal.stats.checkSupportedNumeric('Weights',W,true);

            % Get rid of instances that have NaN in any predictor
            t1 = any(isnan(X),1)';
            if all(t1)
                error(message('stats:classreg:learning:FullClassificationRegressionModel:prepareDataCR:NoGoodXData'));
            end
            
            % Get rid of observations with zero weights or NaNs
            t2 = (W==0 | isnan(W));
            t = t1 | t2;
            if all(t)
                error(message('stats:classreg:learning:FullClassificationRegressionModel:prepareDataCR:NoGoodWeights'));
            end
            
            if any(t)
                Y(t)   = [];
                X(:,t) = [];
                W(t)   = [];
                rowsused = ~t;
            else
                rowsused = [];
            end

            % Process predictor names
            D = size(X,1);
            if     isempty(predictornames)
                predictornames = D;
            elseif isnumeric(predictornames)
                if ~(isscalar(predictornames) && predictornames==D)
                    error(message('stats:classreg:learning:FullClassificationRegressionModel:prepareDataCR:BadNumericPredictor', D));
                end
            else
                if ~iscellstr(predictornames)
                    if ~ischar(predictornames)
                        error(message('stats:classreg:learning:FullClassificationRegressionModel:prepareDataCR:BadPredictorType'));
                    end
                    predictornames = cellstr(predictornames);
                end
                if length(predictornames)~=D || length(unique(predictornames))~=D
                    error(message('stats:classreg:learning:FullClassificationRegressionModel:prepareDataCR:PredictorMismatch', D));
                end
            end
            predictornames = predictornames(:)';
            
            % Process response name
            if isempty(responsename)
                responsename = 'Y';
            else
                if ~ischar(responsename)
                    error(message('stats:classreg:learning:FullClassificationRegressionModel:prepareDataCR:BadResponseName'));
                end
            end
                
            % Find categorical predictors
            if ~isempty(catpreds)
                error(message('stats:classreg:learning:Linear:prepareDataCR:CategoricalPredictorsNotSupported'));
            end
            
            % Summarize data
            dataSummary.PredictorNames = predictornames;
            dataSummary.CategoricalPredictors = [];
            dataSummary.ResponseName = responsename;
            dataSummary.VariableRange = cell(1,D);
            dataSummary.TableInput = false;
            dataSummary.RowsUsed = rowsused;
            dataSummary.ObservationsInRows = false; % from now on observations are in columns
            dataSummary.ObservationsWereInRows = obsInRows;
        end
    end
    
end
