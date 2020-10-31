classdef (AllowedSubclasses = {?classreg.regr.Predictor, ?classreg.regr.CompactParametricRegression}) CompactPredictor < classreg.regr.CompactFitObject
%CompactPredictor Compact predictive regression model.

%   Copyright 2011-2017 The MathWorks, Inc.

    methods(Abstract, Access='public')
        ypred = predict(model,varargin)
        ysim = random(model,varargin)
    end
    
    methods(Abstract, Access='protected')
        % The predict method would normally take a dataset/table array or a matrix
        % containing all variables.  This method exists to allow prediction
        % with a matrix that contains only the required predictor variables
        % without blowing it up to contain all the variables only to then pull
        % it apart to get the design matrix.
        ypred = predictPredictorMatrix(model,Xpred);
    end
    
    methods(Hidden, Access='public')
        function yPred = predictGrid(model,varargin)
            % Prediction over a grid, works only for numeric predictors
            gridMatrices = gridVectors2gridMatrices(model,varargin);
            outSize = size(gridMatrices{1});
            gridCols = cellfun(@(x) x(:), gridMatrices,'UniformOutput',false);
            predData = table(gridCols{:},'VariableNames',model.PredictorNames);
            yPred = predict(model,predData);
            yPred = reshape(yPred,outSize);
        end
    end
       
    methods(Access='public')
        function yPred = feval(model,varargin)
%FEVAL Evaluate model as a function
%    YPRED = FEVAL(M,X1,X2,...Xp) computes an array YPRED of predicted
%    values from the regression model M using predictor values X1, X2, ...,
%    Xp, where P is the number of predictors in M.  Each X argument must be
%    the same size, and must have the same type as the corresponding
%    predictor variable. The size of the YPRED output is the same as the
%    common size of the X inputs.
%
%    YPRED = FEVAL(M,DS) or YPRED = FEVAL(M,X) accepts a dataset/table DS or
%    matrix X containing values of all of the predictors.
%
%    The PREDICT method can compute confidence bounds as well as predicted
%    values. The M.Fitted property provides predicted values using the
%    predictor values used to fit M.
%
%    Example:
%       % Fit model to car data; superimpose fitted cuves on scatter plot
%       load carsmall
%       d = dataset(MPG,Weight);
%       d.Year = ordinal(Model_Year);
%       lm = fitlm(d,'MPG ~ Year + Weight + Weight^2')
%       w = linspace(min(d.Weight),max(d.Weight))';
%       gscatter(d.Weight, d.MPG, d.Year);
%       line(w, feval(lm,w,'70'), 'Color','r')
%       line(w, feval(lm,w,'76'), 'Color','g')
%       line(w, feval(lm,w,'82'), 'Color','b')
%       
%    See also Fitted, predict, LinearModel, GeneralizedLinearModel, NonlinearModel.

            npreds = model.NumPredictors;
            if isa(varargin{1},'dataset')
                varargin{1} = dataset2table(varargin{1});
            end
            if nargin-1 == npreds && ...% separate predictor variable arguments
               ~(nargin==2 && isa(varargin{1},'table'))
                predArgs = varargin;
                
                % Get common arg length considering possible scalar
                % expansion
                sizeOut = [1 1];
                for i = 1:length(predArgs)
                    thisarg = predArgs{i};
                    if ischar(thisarg)
                        if size(thisarg,1)~=1
                            sizeOut = [size(thisarg,1),1];
                            break
                        end
                    else
                        if ~isscalar(thisarg)
                            sizeOut = size(thisarg);
                            break
                        end
                    end
                end
                
                % Get args as cols, expanding scalars as needed
                asCols = predArgs;
                for i = 1:length(predArgs)
                    thisarg = predArgs{i};
                    if ischar(thisarg)
                        thisarg = cellstr(thisarg);
                    end
                    if isscalar(thisarg)
                        thisarg = repmat(thisarg,sizeOut);
                    elseif ~isequal(size(predArgs{i}),sizeOut)
                        error(message('stats:classreg:regr:Predictor:InputSizeMismatch'));
                    end
                    asCols{i} = thisarg(:);
                end
                
                % Evaluate model on predictors as columns, then resize
                Xpred = table(asCols{:},'VariableNames',model.PredictorNames);
                yPred = reshape(predict(model,Xpred),sizeOut);
            elseif nargin == 2 
                predVars = varargin{1};
                if isa(predVars,'table')
                    yPred = predict(model,predVars);
                else % single predictor variable matrix
                    if size(predVars,2) ~= npreds
                        error(message('stats:classreg:regr:Predictor:BadNumColumns', npreds));
                    end
                    yPred = predictPredictorMatrix(model,predVars);
                end
            else
                error(message('stats:classreg:regr:Predictor:BadNumInputs', npreds, npreds));
            end
        end
        
        function [AX] = plotPartialDependence(model,features,data,varargin)
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
        %      % Partial Dependence Plot of Compact Linear Model
        %      load carsmall
        %      tbl = table(Weight,Cylinders,Origin,MPG);
        %      f = fitlm(tbl);
        %      f = compact(f);
        %
        %      plotPartialDependence(f,'Weight',tbl);
        %      plotPartialDependence(f,{'Weight','Origin'},tbl);
        %      plotPartialDependence(f,[1,3],tbl);
        %
        %      % Obtain optional output Axes handle
        %      ax = plotPartialDependence(f,1,tbl);
        %
        %      % With optional name-value pairs
        %      plotPartialDependence(f,1,tbl,'NumObservationsToSample',100);
        %      plotPartialDependence(f,1,tbl,'UseParallel',true);
        %      plotPartialDependence(f,1,tbl,'UseParallel',false,'Conditional','none');
        %      
        %      % Plot the Individual Conditional Expectation
        %      plotPartialDependence(f,1,tbl,'Conditional','absolute');
        %
        %      % Provide alternative query points
        %      xi = linspace(min(Weight),max(Weight))';
        %      plotPartialDependence(f,1,tbl,'QueryPoints',xi);
        %      
        %      xi = cell(1,2);
        %      xi{1} = linspace(min(Weight),max(Weight))';
        %      xi{2} = linspace(min(Cylinders),max(Cylinders))';
        %      plotPartialDependence(f,[1,2],tbl,'QueryPoints',xi);

        %-------Check number of inputs----
        narginchk(3,13);
        
        % Call the function from regr package
        ax = classreg.regr.modelutils.plotPartialDependence(model,...
            features,data,varargin{:});
        if(nargout > 0)
            AX = ax;
        end
        end
    end
end
