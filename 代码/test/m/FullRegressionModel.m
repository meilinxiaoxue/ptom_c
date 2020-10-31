classdef FullRegressionModel < ...
        classreg.learning.FullClassificationRegressionModel & classreg.learning.regr.RegressionModel
%FullRegressionModel Full regression model.
%   FullRegressionModel is the super class for full regression
%   models represented by objects storing the training data. This class is
%   derived from RegressionModel.
%
%   See also classreg.learning.regr.RegressionModel.

%   Copyright 2010-2017 The MathWorks, Inc.


    properties(GetAccess=public,SetAccess=protected,Dependent=true)
        %Y Observed response used to train this model.
        %   The Y property is a vector of type double.
        %
        %   See also classreg.learning.regr.FullRegressionModel.
        Y;
    end
    
    methods
        function y = get.Y(this)
            y = this.PrivY;
        end
    end
        
    methods(Access=protected)
        function this = FullRegressionModel(X,Y,W,modelParams,dataSummary,responseTransform)
            this = this@classreg.learning.FullClassificationRegressionModel(...
                dataSummary,X,Y,W,modelParams);
            this = this@classreg.learning.regr.RegressionModel(dataSummary,responseTransform);
            this.ModelParams = fillIfNeeded(modelParams,X,Y,W,dataSummary,[]);
        end
        
        function s = propsForDisp(this,s)
            s = propsForDisp@classreg.learning.regr.RegressionModel(this,s);
            s = propsForDisp@classreg.learning.FullClassificationRegressionModel(this,s);
        end
    end
    
    methods
        function partModel = crossval(this,varargin)
        %CROSSVAL Cross-validate this model.
        %   CVMODEL=CROSSVAL(MODEL) builds a partitioned model CVMODEL from model
        %   MODEL represented by a full object for regression. You can then
        %   assess the predictive performance of this model on cross-validated data
        %   using methods and properties of CVMODEL. By default, CVMODEL is built
        %   using 10-fold cross-validation on the training data.
        %
        %   CVMODEL=CROSSVAL(MODEL,'PARAM1',val1,'PARAM2',val2,...) specifies
        %   optional parameter name/value pairs:
        %      'KFold'      - Number of folds for cross-validation, a numeric
        %                     positive scalar; 10 by default.
        %      'Holdout'    - Holdout validation uses the specified
        %                     fraction of the data for test, and uses the rest of
        %                     the data for training. Specify a numeric scalar
        %                     between 0 and 1.
        %      'Leaveout'   - If 'on', use leave-one-out cross-validation.
        %      'CVPartition' - An object of class CVPARTITION; empty by default. If
        %                      a CVPARTITION object is supplied, it is used for
        %                      splitting the data into subsets.
        %
        %   See also classreg.learning.regr.FullRegressionModel,
        %   cvpartition,
        %   classreg.learning.partition.RegressionPartitionedModel.
            [varargin{:}] = convertStringsToChars(varargin{:});
            idxBaseArg = find(ismember(varargin(1:2:end),...
                classreg.learning.FitTemplate.AllowedBaseFitObjectArgs));
            if ~isempty(idxBaseArg)
                error(message('stats:classreg:learning:regr:FullRegressionModel:crossval:NoBaseArgs', varargin{ 2*idxBaseArg - 1 }));
            end
            temp = classreg.learning.FitTemplate.make(this.ModelParams.Method,...
                'type','regression','responsetransform',this.PrivResponseTransform,...
                'modelparams',this.ModelParams,'CrossVal','on',varargin{:});
            partModel = fit(temp,this.X,this.Y,'Weights',this.W,...
                'predictornames',this.PredictorNames,'categoricalpredictors',this.CategoricalPredictors,...
                'responsename',this.ResponseName);
        end
        
        function [varargout] = resubPredict(this,varargin)
            [varargin{:}] = convertStringsToChars(varargin{:});
            classreg.learning.FullClassificationRegressionModel.catchWeights(varargin{:});
            [varargout{1:nargout}] = predict(this,this.X,varargin{:});
        end
        
        function [varargout] = resubLoss(this,varargin)
            [varargin{:}] = convertStringsToChars(varargin{:});
            classreg.learning.FullClassificationRegressionModel.catchWeights(varargin{:});
            [varargout{1:nargout}] = ...
                loss(this,this.X,this.Y,'Weights',this.W,varargin{:});
        end
        
        function [AX] = plotPartialDependence(this,features,varargin)
        %PLOTPARTIALDEPENDENCE Partial Dependence Plot for 1-D or 2-D visualization
        %   plotPartialDependence(MODEL,VAR) takes a fitted regression model
        %   MODEL and a predictor variable name VAR, and creates a plot showing
        %   the partial dependence of the response variable on the predictor
        %   variable. The dependence is computed by averaging over the data used in
        %   fitting the model. VAR can be a scalar containing the index of the
        %   predictor or a char array with the predictor variable name.
        %   
        %   plotPartialDependence(MODEL,VARS) takes VARS as either a cell array
        %   containing two predictor variable names, or a two-element vector
        %   containing the indices of two predictors, and creates a surface plot
        %   showing the partial dependence of the response on the two predictors.
        %
        %   plotPartialDependence(...,DATA) specifies the data to be used for
        %   averaging. DATA is a matrix or table of data to be used in place of the
        %   data used in fitting the model.
        %
        %   AX = plotPartialDependence(...) returns a handle AX to the axes of the
        %   plot.
        %
        %   PLOTPARTIALDEPENDENCE(..., 'PARAM1', val1, 'PARAM2', val2, ...)
        %   specifies optional parameter name/value pairs.
        %      'Conditional'                'none' (default) to specify a
        %                                   partial dependence plot (no
        %                                   conditioning), 'absolute' to specify
        %                                   an ICE individual conditional
        %                                   expectation plot, or 'centered' to
        %                                   or an ICE plot with centered data.
        %
        %      'NumObservationsToSample'    an integer K specifying the number
        %                                   of rows to sample at random from the
        %                                   dataset (either the DATA input or
        %                                   the training data from the MODEL).
        %                                   Default is to use all rows.
        %
        %      'QueryPoints'                The points XI at which to calculate
        %                                   the partial dependence. When the
        %                                   second input VAR is a single
        %                                   predictor, XI is a column vector of
        %                                   values for that predictor. When the
        %                                   second inputs VARS is two
        %                                   predictors, XI is a 1x2 cell array
        %                                   containing a separate vector for
        %                                   each predictor. Default is 100
        %                                   values equally spaced across the
        %                                   range of the predictor.
        %
        %      'UseParallel'                true to specify that the averaging
        %                                   calculations are to be done in
        %                                   parallel (using parfor), or false
        %                                   (default) to specify that they
        %                                   should not.
        %
        %      'ParentAxisHandle'           plots Partial Dependence into the
        %                                   axes with handle specified by the
        %                                   corresponding value ax.
        %
        %   Examples:
        %      % Partial Dependence Plot of Regression Tree
        %      load carsmall
        %      tbl = table(Weight,Cylinders,Origin,MPG);
        %      f = fitrtree(tbl,'MPG');
        %
        %      plotPartialDependence(f,'Weight');
        %      plotPartialDependence(f,{'Weight','Origin'});
        %      plotPartialDependence(f,[1,3]);
        %
        %      % Obtain optional output Axes handle
        %      ax = plotPartialDependence(f,1);
        %
        %      % With additional Data
        %      load carbig
        %      tbl2 = table(Weight,Cylinders,Origin);
        %      plotPartialDependence(f,'Weight',tbl2);
        %      plotPartialDependence(f,1,tbl2);
        %
        %      % With optional name-value pairs
        %      plotPartialDependence(f,1,tbl2,'NumObservationsToSample',100);
        %      plotPartialDependence(f,1,tbl2,'UseParallel',true);
        %      plotPartialDependence(f,1,tbl2,'UseParallel',true,'Conditional','none');
        %      
        %      % Plot the Individual Conditional Expectation
        %      plotPartialDependence(f,1,tbl2,'Conditional','absolute');
        %
        %      % Provide alternative query points
        %      xi = linspace(min(Weight),max(Weight))';
        %      plotPartialDependence(f,1,'QueryPoints',xi);
        %      
        %      xi = cell(1,2);
        %      xi{1} = linspace(min(Weight),max(Weight))';
        %      xi{2} = linspace(min(Cylinders),max(Cylinders))';
        %      plotPartialDependence(f,[1,2],'QueryPoints',xi);

        %-------Check number of inputs----
        narginchk(2,13);
        features = convertStringsToChars(features);
        [varargin{:}] = convertStringsToChars(varargin{:});

        % Check inputs with inputParser. This step ensures that the third
        % argument is either a Name-Value pair or data, no other strings/char
        % array allowed.
        p = inputParser;        
        addRequired(p,'Model');
        addRequired(p,'Var');
        addOptional(p,'Data',this.X); % Default - training data
        addParameter(p,'Conditional',{'none','absolute','centered'});
        addParameter(p,'NumObservationsToSample',0);
        addParameter(p,'ParentAxisHandle',[]);
        addParameter(p,'QueryPoints',[]);
        addParameter(p,'UseParallel',false);
        parse(p,this,features,varargin{:});
        X = p.Results.Data;
        
        %------Parse Data-----------------
        % If third argument is a char, its a parameter name else it is Data
        if(nargin>2 && ~ischar(varargin{1}))
            % Pass everything but the first argument(Data)to compact method
            varargin = varargin(2:end);
        end
        
        % Call the function from regr package
        ax = plotPartialDependence@classreg.learning.regr.RegressionModel...
            (this,features,X,varargin{:});
        if(nargout > 0)
            AX = ax;
        end
        end
    end

    methods(Static,Hidden)
        function [X,Y,W,dataSummary,responseTransform] = prepareData(X,Y,varargin)
            [X,Y,vrange,wastable,varargin] = classreg.learning.internal.table2FitMatrix(X,Y,varargin{:});
            
            % Process input args
            args = {'responsetransform'};
            defs = {                 []};
            [transformer,~,crArgs] = ...
                internal.stats.parseArgs(args,defs,varargin{:});
            
            % Pre-process
            [X,Y,W,dataSummary] = ...
                classreg.learning.FullClassificationRegressionModel.prepareDataCR(...
                X,Y,crArgs{:},'VariableRange',vrange,'TableInput',wastable);
            if ~isfloat(X)
                error(message('stats:classreg:learning:regr:FullRegressionModel:prepareData:BadXType'));
            end

            % Check Y type
            if ~isfloat(Y) || ~isvector(Y)
                error(message('stats:classreg:learning:regr:FullRegressionModel:prepareData:BadYType'));
            end
            internal.stats.checkSupportedNumeric('Y',Y,true);
            Y = Y(:);
            
           [X,Y,W,dataSummary.RowsUsed] = classreg.learning.regr.FullRegressionModel.removeNaNs(X,Y,W,dataSummary.RowsUsed);
      
            % Renormalize weights
           W = W/sum(W);

            % Make output response transformation
           responseTransform = ...
                classreg.learning.regr.FullRegressionModel.processResponseTransform(transformer);
        end
        
        function [X,Y,W,rowsused] = removeNaNs(X,Y,W,rowsused,obsInRows)
            t = isnan(Y);
            if any(t)
                Y(t) = [];
                if nargin<5 || obsInRows
                    X(t,:) = [];
                else
                    X(:,t) = [];
                end
                W(t) = [];
                if isempty(rowsused)
                    rowsused = ~t;
                else
                    rowsused(rowsused) = ~t;
                end
            end
            if isempty(X)
                error(message('stats:classreg:learning:regr:FullRegressionModel:prepareData:NoGoodYData'));
            end
        end
            
        function responseTransform = processResponseTransform(transformer)
            if isempty(transformer)
                responseTransform = @classreg.learning.transform.identity;
            elseif ischar(transformer)
                if strcmpi(transformer,'none')
                    responseTransform = @classreg.learning.transform.identity;
                else
                    responseTransform = str2func(['classreg.learning.transform.' transformer(:)']);
                end
            else
                if ~isa(transformer,'function_handle')
                    error(message('stats:classreg:learning:regr:FullRegressionModel:prepareData:BadResponseTransformation'));
                end
                responseTransform = transformer;
            end
            
        end
    end
end
