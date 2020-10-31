classdef (AllowedSubclasses = {?classreg.regr.ParametricRegression}) Predictor < classreg.regr.CompactPredictor & classreg.regr.FitObject
%Predictor Fitted predictive regression model.
%   Predictor is an abstract class representing a fitted regression model
%   for predicting a response as a function of predictor variables.
%   You cannot create instances of this class directly.  You must create
%   a derived class by calling the fit method of a derived class such as
%   LinearModel, GeneralizedLinearModel, or NonLinearModel.
%
%   See also LinearModel, GeneralizedLinearModel, NonLinearModel.

%   Copyright 2011-2017 The MathWorks, Inc.

    properties(Dependent,GetAccess='public',SetAccess='protected',Abstract=true)
%Fitted - Vector of fitted (predicted) values.
%   The Fitted property is a vector providing the response values predicted
%   by the regression model. The fitted values are computed using the
%   predictor values used to fit the model. Use the PREDICT method to
%   compute predictions for other predictor values.
%
%   See also Predictor, Residuals, predict, random.
        Fitted

%Residuals - Residual values.
%   The Residuals property is a table of residuals. It is a table array that
%   has one row for each observation and, depending on the type of
%   regression model, has one or more of the following columns: 
%      Raw           Observed minus predicted response values
%      Pearson       Raw residuals normalized by RMSE
%      Standardized  Internally Studentized residuals based on RMSE
%      Studentized   Externally Studentized residuals based on S2_i
%
%   To obtain any of these columns as a vector, index into the property
%   using dot notation. For example, in the LinearModel LM the ordinary or
%   raw residual vector is
%      r = LM.Residuals.Raw
%
%   See also Predictor, Fitted, predict, random.
        Residuals
    end
    
    methods(Abstract,Access='protected')
        D = get_diagnostics(model,type)
    end
    methods(Access='protected')
        function r = get_residuals(model)
            r = getResponse(model) - predict(model);
        end
        
        function yfit = get_fitted(model)
            compactNotAllowed(model,'Fitted',true);
            yfit = predict(model);
        end
    end
    
    methods(Access = 'public')
        function [AX] = plotPartialDependence(model,features,varargin)
        %PLOTPARTIALDEPENDENCE Partial Dependence Plot for 1-D or 2-D visualization
        %   plotPartialDependence(MODEL,VAR) takes a fitted regression model
        %   MODEL and a predictor variable name VAR, and creates a plot showing
        %   the partial dependence of the response variable on the predictor
        %   variable. The dependence is computed by averaging over the data used in
        %   fitting the model. VAR can be a scalar containing the index of the
        %   predictor, a string scalar or a char array with the predictor
        %   variable name.
        %   
        %   plotPartialDependence(MODEL,VARS) takes VARS as either a cell array
        %   containing two predictor variable names, a string array containing
        %   two predictor variable names or a two-element vector containing
        %   the indices of two predictors, and creates a surface plot showing
        %   the partial dependence of the response on the two predictors.
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
        %      % Partial Dependence Plot of Linear Model
        %      load carsmall
        %      tbl = table(Weight,Cylinders,Origin,MPG);
        %      f = fitlm(tbl);
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
        
        % Data needs to be provided for Compact Models
        if(istable(model.Data))
            defaultData = model.Data(:,model.PredictorNames);
        else
            defaultData = model.Data.X;
        end
        
        % Check inputs with inputParser. This step ensures that the third
        % argument is either a Name-Value pair or data, no other strings/char
        % array allowed.
        p = inputParser;        
        addRequired(p,'Model');
        addRequired(p,'Var');
        addOptional(p,'Data',defaultData); % Default - training data
        addParameter(p,'Conditional',{'none','absolute','centered'});
        addParameter(p,'NumObservationsToSample',0);
        addParameter(p,'ParentAxisHandle',[]);
        addParameter(p,'QueryPoints',[]);
        addParameter(p,'UseParallel',false);
        parse(p,model,features,varargin{:});
        data = p.Results.Data;
        
        %------Parse Data-----------------
        % If third argument is a char, its a parameter name else it is Data
        if(nargin>2 && ~ischar(varargin{1}))
            % Pass everything but the first argument(Data)to compact method
            varargin = varargin(2:end);
        end
        
        % Call the function from regr package
        ax = plotPartialDependence@classreg.regr.CompactPredictor...
            (model,features,data,varargin{:});
        if(nargout > 0)
            AX = ax;
        end
        end
    end
end
