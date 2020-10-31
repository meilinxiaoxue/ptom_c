classdef RegressionModel < classreg.learning.Predictor

%   Copyright 2010-2017 The MathWorks, Inc.


    properties(GetAccess=public,SetAccess=protected,Hidden=true)
        PrivResponseTransform = [];
        DefaultLoss = @classreg.learning.loss.mse;
    end
    
    properties(GetAccess=public,SetAccess=public,Dependent=true)
        %RESPONSETRANSFORM Transformation applied to predicted response.
        %   The ResponseTransform property is a string describing how raw response
        %   values predicted by the model are transformed. You can assign a
        %   function handle to this property.
        %
        %   See also classreg.learning.regr.RegressionModel.
        ResponseTransform;
    end
    
    methods
        function ts = get.ResponseTransform(this)
            ts = func2str(this.PrivResponseTransform);
            if strcmp(ts,'classreg.learning.transform.identity')
                ts = 'none';
            end
            idx = strfind(ts,'classreg.learning.transform.');
            if ~isempty(idx)
               ts = ts(1+length('classreg.learning.transform.'):end); 
            end
        end
        
        function this = set.ResponseTransform(this,rt)
            rt = convertStringsToChars(rt);
            this.PrivResponseTransform = ...
                classreg.learning.internal.convertScoreTransform(rt,'handle',1);
        end
    end
    
    methods(Hidden)
        function this = RegressionModel(dataSummary,responseTransform)
            this = this@classreg.learning.Predictor(dataSummary);
            this.PrivResponseTransform = responseTransform;
        end
        
        function [X,Y,W] = prepareDataForLoss(this,X,Y,W,vrange,convertX,obsInRows)
            % Observations in rows?
            if nargin<7 || isempty(obsInRows)
                obsInRows = true;
            end
            
            if istable(X)
                pnames = this.PredictorNames;
            else
                pnames = getOptionalPredictorNames(this);
            end
            
            % Convert to matrix X if necessary
            if convertX
                [X,Y,W] = classreg.learning.internal.table2PredictMatrix(X,Y,W,...
                    vrange,this.CategoricalPredictors,pnames);
            else
                [~,Y,W] = classreg.learning.internal.table2PredictMatrix(X,Y,W,...
                    vrange,this.CategoricalPredictors,pnames);
            end
            
            % Check X
            if (~isnumeric(X) || ~ismatrix(X)) && ~istable(X) && ~isa(X,'dataset')
                error(message('stats:classreg:learning:regr:RegressionModel:prepareDataForLoss:BadXType'));
            end
            
            % Check Y type
            if ~isempty(Y) && (~isfloat(Y) || ~isvector(Y))
                error(message('stats:classreg:learning:regr:RegressionModel:prepareDataForLoss:BadYType'));
            end
            internal.stats.checkSupportedNumeric('Y',Y);
            Y = Y(:);
            N = numel(Y);
            
            % Check size
            if obsInRows
                Npassed = size(X,1);
            else
                Npassed = size(X,2);
            end
            if Npassed~=N
                error(message('stats:classreg:learning:regr:RegressionModel:prepareDataForLoss:SizeXYMismatch'));
            end
            
            % Check weights
            if ~isfloat(W) || ~isvector(W) || length(W)~=N || any(W<0)
                error(message('stats:classreg:learning:regr:RegressionModel:prepareDataForLoss:BadWeights', N));
            end
            internal.stats.checkSupportedNumeric('Weights',W,true);
            W = W(:);
            
            % Remove observations for NaN responses
            t = isnan(Y);
            if any(t) && N>0
                if obsInRows
                    X(t,:) = [];
                else
                    X(:,t) = [];
                end
                Y(t,:) = [];
                W(t,:) = [];
            end
            
            % Normalize weights
            if sum(W)>0
                W = W/sum(W);
            end
            
        end
    end
    
    methods(Access=protected)
        function s = propsForDisp(this,s)
            s = propsForDisp@classreg.learning.Predictor(this,s);
            s.ResponseTransform = this.ResponseTransform;
        end
        
        function yfit = predictEmptyX(this,X)
            D = numel(this.PredictorNames);
            if this.ObservationsInRows
                str = getString(message('stats:classreg:learning:regr:RegressionModel:predictEmptyX:columns'));
                Dpassed = size(X,2);
            else
                Dpassed = size(X,1);
                str = getString(message('stats:classreg:learning:regr:RegressionModel:predictEmptyX:rows'));
            end
            if Dpassed~=D
                error(message('stats:classreg:learning:regr:RegressionModel:predictEmptyX:XSizeMismatch', D, str));
            end
            yfit = NaN(0,1);
        end
        
     end
       
    methods(Access=protected,Abstract=true)
        r = response(this,X,varargin)
    end
    
    methods
        function Yfit = predict(this,X,varargin)
        %PREDICT Predict response of the model.
        %   YFIT=PREDICT(MODEL,X) returns predicted response YFIT for regression
        %   model MODEL and predictors X. X must be a table if MODEL was originally
        %   trained on a table, or a numeric matrix if MODEL was originally trained
        %   on a matrix. If X is a table, it must contain all the predictors used
        %   for training this model. If X is a matrix, it must have P columns,
        %   where P is the number of predictors used for training. YFIT is a vector
        %   of type double with N elements, where N is the number of rows in X.
        %
        %   See also classreg.learning.regr.RegressionModel.

            % Handle input data such as "tall" requiring a special adapter
            adapter = classreg.learning.internal.makeClassificationModelAdapter(this,X);
            if ~isempty(adapter) 
                Yfit = predict(adapter,X,varargin{:});
                return;
            end
        
            % Convert to matrix X if necessary
            if this.TableInput || istable(X)
                vrange = getvrange(this);
                X = classreg.learning.internal.table2PredictMatrix(X,[],[],...
                    vrange,...
                    this.CategoricalPredictors,this.PredictorNames);
            end
            
            % Get the right orientation
            [X,varargin] = classreg.learning.internal.orientX(...
                X,this.ObservationsInRows,varargin{:});
            
            if isempty(X)
                Yfit = predictEmptyX(this,X);
                return;
            end
            
            if any(this.CategoricalPredictors) && strcmp(this.CategoricalVariableCoding,'dummy')
                if ~this.TableInput
                    X = classreg.learning.internal.encodeCategorical(X,this.VariableRange);
                end
                X = classreg.learning.internal.expandCategorical(X,...
                    this.CategoricalPredictors,this.VariableRange);
            end
            Yfit = this.PrivResponseTransform(response(this,X,varargin{:}));
        end
        
        function l = loss(this,X,varargin)
        %LOSS Regression error.
        %   L=LOSS(MODEL,X,Y) returns mean squared error for MODEL computed using
        %   predictors X and observed response Y. X must be a table if MODEL was
        %   originally trained on a table, or a numeric matrix if MODEL was
        %   originally trained on a matrix. If X is a table, it must contain all
        %   the predictors used for training this model. If X is a matrix, it must
        %   have P columns, where P is the number of predictors used for training.
        %   Y must be a vector of floating-point numbers with N elements, where N
        %   is the number of rows in X. Y can be omitted if it appears in the table
        %   X.
        %
        %   L=LOSS(MODEL,X,Y,'PARAM1',val1,'PARAM2',val2,...) specifies optional
        %   parameter name/value pairs:
        %       'LossFun'          - Function handle for loss, or string
        %                            representing a built-in loss function.
        %                            Available loss functions for regression:
        %                            'mse'. If you pass a function handle FUN, LOSS
        %                            calls it as shown below:
        %                               FUN(Y,Yfit,W)
        %                            where Y, Yfit and W are numeric vectors of
        %                            length N. Y is observed response, Yfit is
        %                            predicted response, and W is observation
        %                            weights. Default: 'mse'
        %       'Weights'          - Vector of observation weights. By default the
        %                            weight of every observation is set to 1. The
        %                            length of this vector must be equal to the
        %                            number of rows in X. If X is a table, this
        %                            may be the name of a variable in the table.
        %
        %   See also classreg.learning.regr.RegressionModel,
        %   classreg.learning.regr.RegressionModel/predict.
            [varargin{:}] = convertStringsToChars(varargin{:});
            % Handle input data such as "tall" requiring a special adapter
            adapter = classreg.learning.internal.makeClassificationModelAdapter(this,X,varargin{:});
            if ~isempty(adapter)            
                l = loss(adapter,X,varargin{:});
                return
            end

            [Y,varargin] = classreg.learning.internal.inferResponse(this.ResponseName,X,varargin{:});
            
            % Get observation weights
            obsInRows = classreg.learning.internal.orientation(varargin{:});            
            if obsInRows
                N = size(X,1);
            else
                N = size(X,2);
            end
            args = {                  'lossfun'  'weights'};
            defs = {@classreg.learning.loss.mse  ones(N,1)};
            [funloss,W,~,extraArgs] = ...
                internal.stats.parseArgs(args,defs,varargin{:});
            
            % Prepare data
            [X,Y,W] = prepareDataForLoss(this,X,Y,W,this.VariableRange,false,obsInRows);
            
            % Check input args
            funloss = classreg.learning.internal.lossCheck(funloss,'regression');
            
            % Get predictions
            Yfit = predict(this,X,extraArgs{:});
            
            % Check
            classreg.learning.internal.regrCheck(Y,Yfit(:,1),W);

            % Get loss
            R = size(Yfit,2);
            l = NaN(1,R);
            for r=1:R
                l(r) = funloss(Y,Yfit(:,r),W);
            end
        end
        
        function [AX] = plotPartialDependence(this,features,X,varargin)
        %PLOTPARTIALDEPENDENCE Partial Dependence Plot for 1-D or 2-D visualization
        %   plotPartialDependence(MODEL,VAR,DATA) takes a fitted regression model
        %   MODEL and a predictor variable name VAR, and creates a plot showing
        %   the partial dependence of the response variable on the predictor
        %   variable. The dependence is computed by averaging over the data used in
        %   fitting the model. VAR can be a scalar containing the index of the
        %   predictor or a char array with the predictor variable name. DATA is a 
        %   matrix or table of data to be used in place of the data used in fitting 
        %   the model.
        %   
        %   plotPartialDependence(MODEL,VARS,DATA) takes VARS as either a cell array
        %   containing two predictor variable names, or a two-element vector
        %   containing the indices of two predictors, and creates a surface plot
        %   showing the partial dependence of the response on the two predictors.
        %   DATA is a matrix or table of data to be used in place of the data
        %   used in fitting the model.
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
        narginchk(3,13);

        % Call the function from regr package
        ax = classreg.regr.modelutils.plotPartialDependence(this,...
            features,X,varargin{:});
        if(nargout > 0)
            AX = ax;
        end
        end
    end
end
