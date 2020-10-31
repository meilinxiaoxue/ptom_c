classdef FullClassificationRegressionModel < classreg.learning.Predictor
%FullClassificationRegressionModel Full classification or regression model.
%   FullClassificationRegressionModel is the super class for full
%   classification or regression models represented by objects storing the
%   training data.

%   Copyright 2010-2017 The MathWorks, Inc.


    properties(GetAccess=public,SetAccess=protected,Dependent=true)
        %X X data used to train this model.
        %   The X property contains the predictor values. It is a table for a model
        %   trained on a table, or a numeric matrix for a model trained on a
        %   matrix. It has size N-by-P, where N is the number of rows and P is the
        %   number of predictor variables or columns in the training data.
        %
        %   See also classreg.learning.FullClassificationRegressionModel, NumObservations, RowsUsed.
        X;

        %ROWSUSED Rows used in fitting.
        %   The RowsUsed property is a logical vector indicating which rows of the
        %   original X data were used in fitting. This property may be empty if all
        %   rows were used.
        %
        %   See also classreg.learning.FullClassificationRegressionModel.
        RowsUsed = [];
    end
        
    properties(GetAccess=public,SetAccess=protected,Hidden=true)
        ModelParams = [];
    end
    
    properties(GetAccess=public,SetAccess=protected)
        %W Weights of observations used to train this model.
        %   The W property is a numeric vector of size N, where N is the
        %   number of observations. The sum of weights is 1.
        %
        %   See also classreg.learning.FullClassificationRegressionModel.
        W = [];
    end
       
    properties(GetAccess=public,SetAccess=protected,Dependent=true,Hidden=true)
        NObservations;
    end

    properties(GetAccess=public,SetAccess=protected,Hidden=true)
        PrivX = [];
        PrivY = [];
    end
    
    properties(GetAccess=public,SetAccess=protected,Dependent=true)
        %MODELPARAMETERS Model parameters.
        %   The ModelParameters property holds parameters used for training this
        %   model.
        %
        %   See also classreg.learning.FullClassificationRegressionModel.
        ModelParameters = [];

        %NUMOBSERVATIONS Number of observations.
        %   The NumObservations property is a numeric scalar holding the number of
        %   observations in the training data.
        %
        %   See also classreg.learning.FullClassificationRegressionModel.
        NumObservations;
    end
    
    properties(SetAccess=private)
        %HyperparameterOptimizationResults Results of hyperparameter optimization.
        %   If model hyperparameters were optimized during fitting, this
        %   property holds an object.
        %
        %   See also classreg.learning.FullClassificationRegressionModel.
        HyperparameterOptimizationResults = [];
    end
    
    methods
        function x = get.X(this)
            x = getX(this);
            
            % Decode categorical variables into original values
            if this.TableInput
                t = array2table(x,'VariableNames',this.PredictorNames);
                for j=1:size(x,2)
                    vrj = this.VariableRange{j};
                    newx = decodeX(x(:,j),vrj);
                    t.(this.PredictorNames{j}) = newx;
                end
                x = t;
            elseif ~isempty(this.VariableRange) && isequal(this.CategoricalVariableCoding,'dummy')
                for j=1:size(x,2)
                    vrj = this.VariableRange{j};
                    if ~isempty(vrj)
                        newx = decodeX(x(:,j),vrj);
                        x(:,j) = newx;
                    end
                end
            end
        end
        
        function this = set.X(this,x)
            this.PrivX = x;
        end
        
        function mp = get.ModelParameters(this)
            mp = this.ModelParams;
        end
        
        function n = get.NumObservations(this)
            n = size(getX(this),1);
        end
        
        function n = get.NObservations(this)
            n = this.NumObservations;
        end

        function ru = get.RowsUsed(this)
            try
                ru = this.DataSummary.RowsUsed;
            catch
                ru = []; % field may be missing for old saved object
            end
        end
        function this = set.RowsUsed(this,ru)
            this.DataSummary.RowsUsed = ru;
        end
    end

    methods(Abstract,Static)
        obj = fit(X,Y,varargin)
    end
    
    methods(Abstract)
        cmp = compact(this)
        partModel = crossval(this,varargin)
    end
    
    methods(Access=protected)
        function x = getX(this)
            x = this.PrivX;
        end                
    end
    
    methods(Access=protected)
        function this = FullClassificationRegressionModel(dataSummary,X,Y,W,modelParams)
            this = this@classreg.learning.Predictor(dataSummary);
            this.PrivX = X;
            this.PrivY = Y;
            this.W = W;
            this.ModelParams = modelParams;
        end
        
        function s = propsForDisp(this,s)
            s = propsForDisp@classreg.learning.Predictor(this,s);
            s.NumObservations = this.NumObservations;
            if ~isempty(this.HyperparameterOptimizationResults)
                s.HyperparameterOptimizationResults = this.HyperparameterOptimizationResults;
            end
        end
    end
    
    methods(Static,Hidden)
        function [X,Y,W,dataSummary] = prepareDataCR(X,Y,varargin)
            % Process input args                      
            [ignoreextra,~,inputArgs] = internal.stats.parseArgs(...
                {'ignoreextraparameters'},{false},varargin{:});
                      
            args = {'weights' 'predictornames' 'responsename' ...
                'categoricalpredictors' 'variablerange' 'tableinput' ...
                'observationsin'};
            defs = {       []               []             [] ...
                                     []              {}        false ...
                          'rows'};

            if ignoreextra
                [W,predictornames,responsename,catpreds,vrange,wastable,obsIn,~,~] = ...
                    internal.stats.parseArgs(args,defs,inputArgs{:});
            else
                [W,predictornames,responsename,catpreds,vrange,wastable,obsIn] = ...
                    internal.stats.parseArgs(args,defs,inputArgs{:});
            end
            
            % Check input type.
            %
            % Require numeric X but not necessarily floating-point X.
            % Floating-point X is required by FullRegressionModel.
            %
            % FullClassificationModel does not require floating-point X.
            % The only example of non-floating-point data is
            % ClassificationKNN with user-supplied distance function.
            % inarsky 10/24/2012
            if ~isnumeric(X) || ~ismatrix(X)
                error(message('stats:classreg:learning:FullClassificationRegressionModel:prepareDataCR:BadXType'));
            end
            
            % Check input orientation
            obsIn = validatestring(obsIn,{'rows' 'columns'},...
                'classreg.learning.FullClassificationRegressionModel:prepareDataCR','ObservationsIn');
            obsInRows = strcmp(obsIn,'rows');
            
            % Check input size
            if isempty(X) || isempty(Y)
                error(message('stats:classreg:learning:FullClassificationRegressionModel:prepareDataCR:NoData'));
            end
            if obsInRows
                N = size(X,1);
            else
                N = size(X,2);
            end
            if N~=length(Y)
                error(message('stats:classreg:learning:FullClassificationRegressionModel:prepareDataCR:InputSizeMismatch'));
            end
 
            % Check weights and normalize to 1
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

            % Get rid of instances that have NaN's in all predictors
            if obsInRows
                t1 = all(isnan(X),2);
            else
                t1 = all(isnan(X),1)';
            end
            if all(t1)
                error(message('stats:classreg:learning:FullClassificationRegressionModel:prepareDataCR:NoGoodXData'));
            end
            
            % Get rid of observations with zero weights or NaNs
            t2 = (W==0 | isnan(W));
            t = t1|t2;
            if all(t)
                error(message('stats:classreg:learning:FullClassificationRegressionModel:prepareDataCR:NoGoodWeights'));
            end
            
            if any(t)
                Y(t) = [];
                if obsInRows
                    X(t,:) = [];
                else
                    X(:,t) = [];
                end
                W(t) = [];
                rowsused = ~t;
            else
                rowsused = [];
            end

            % Process predictor names
            if obsInRows
                D = size(X,2);
            else
                D = size(X,1);
            end
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
            if isnumeric(catpreds) % indices of categorical predictors
                catpreds = ceil(catpreds);
                if any(catpreds<1) || any(catpreds>D)
                    error(message('stats:classreg:learning:FullClassificationRegressionModel:prepareDataCR:BadCatPredIntegerIndex', D));
                end
            elseif islogical(catpreds)
                if length(catpreds)~=D
                    error(message('stats:classreg:learning:FullClassificationRegressionModel:prepareDataCR:BadCatPredLogicalIndex', D));
                end
                idx = 1:D;
                catpreds = idx(catpreds);
            elseif ischar(catpreds) && strcmpi(catpreds,'all')
                catpreds = 1:D;
            else
                if ~ischar(catpreds) && ~iscellstr(catpreds)
                    error(message('stats:classreg:learning:FullClassificationRegressionModel:prepareDataCR:BadCatVarType'));
                end
                if ~iscellstr(catpreds)
                    catpreds = cellstr(catpreds);
                end
                if isnumeric(predictornames)
                    error(message('stats:classreg:learning:FullClassificationRegressionModel:prepareDataCR:CharCatVarWithoutVarNames'));
                end
                [tf,pos] = ismember(catpreds,predictornames);
                if any(~tf)
                    error(message('stats:classreg:learning:FullClassificationRegressionModel:prepareDataCR:BadCatVarName', ...
                        catpreds{ find( ~tf, 1, 'first' ) }));
                end
                catpreds = pos;
            end
            
            if ~wastable
                vrange = cell(1,D);
                iscat = false(1,D);
                iscat(catpreds) = true;
                for k=1:D
                    if iscat(k)
                        if obsInRows
                            x = X(:,k);
                        else
                            x = X(k,:)';
                        end
                        vrk = unique(x);
                        vrange{k} = vrk(~isnan(vrk));
                    end
                end
            end
            
            % Summarize data
            if isempty(catpreds)
                catpreds = [];  % avoid 1-by-0 display
            end
            dataSummary.PredictorNames = predictornames;
            dataSummary.CategoricalPredictors = catpreds;
            dataSummary.ResponseName = responsename;
            dataSummary.VariableRange = vrange;
            dataSummary.TableInput = wastable;
            dataSummary.RowsUsed = rowsused;
            dataSummary.ObservationsInRows = obsInRows;
        end
        
        function catchWeights(varargin)
            args = {'weights'};
            defs = {       []};
            [w,~,~] = internal.stats.parseArgs(args,defs,varargin{:});
            if ~isempty(w)
                error(message('stats:classreg:learning:FullClassificationRegressionModel:catchWeights:NonEmptyWeights'));
            end
        end

    end
    
    methods(Hidden)
        function this = setParameterOptimizationResults(this, Results)
            this.HyperparameterOptimizationResults = Results;
        end
    end
end

function newx = decodeX(oldx,vr)
% Decode a column of X using the variable range and group numbers
if isempty(vr)
    newx = oldx;
else
    ok = oldx>0 & ~isnan(oldx);
    if all(ok) 
        newx = vr(oldx);
    else
        newx(ok,:) = vr(oldx(ok));
        if iscategorical(newx)
            missing = '<undefined>';
        elseif isfloat(newx)
            missing = NaN;
        elseif iscell(newx)
            missing = {''};
        elseif ischar(newx)
            missing = ' ';
        end
        newx(~ok,:) = missing;
    end
end
end
