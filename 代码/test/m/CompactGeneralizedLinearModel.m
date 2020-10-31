classdef (AllowedSubclasses = {?GeneralizedLinearModel,}) ...
        CompactGeneralizedLinearModel < classreg.regr.CompactTermsRegression
    %CompactGeneralizedLinearModel Compact generalized linear regression model.
    %
    %   CompactGeneralizedLinearModel methods:
    %       coefCI - Coefficient confidence intervals
    %       coefTest - Linear hypothesis test on coefficients
    %       devianceTest - Analysis of deviance
    %       predict - Compute predicted values given predictor values
    %       feval - Evaluate model as a function
    %       random - Generate random response values given predictor values
    %       plotSlice - Plot slices through the fitted regression surface
    %
    %   CompactGeneralizedLinearModel properties:
    %       Coefficients - Coefficients and related statistics
    %       Rsquared - R-squared and adjusted R-squared
    %       ModelCriterion - AIC and other model criteria
    %       ResponseName - Name of response
    %       PredictorNames - Names of predictors
    %       NumPredictors - Number of predictors
    %       NumVariables - Number of variables used in fit
    %       VariableNames - Names of variables used in fit
    %       VariableInfo - Information about variables used in the fit
    %       NumObservations - Number of observations in the fit
    %       DFE - Degrees of freedom for error
    %       SSE - Error sum of squares
    %       SST - Total sum of squares
    %       SSR - Regression sum of squares
    %       Formula - Representation of the model used in this fit
    %       LogLikelihood - Log of likelihood function at coefficient estimates
    %       CoefficientCovariance - Covariance matrix for coefficient estimates
    %       CoefficientNames - Coefficient names
    %       NumCoefficients - Number of coefficients
    %       NumEstimatedCoefficients - Number of estimated coefficients
    %       Distribution - Distribution of the response
    %       Link - Link relating the distribution parameters to the predictors
    %       Dispersion - Theoretical or estimated dispersion parameter
    %       DispersionEstimated - Flag indicating if Dispersion was estimated
    %       Deviance - Deviance of the fit
    %
    %   See also FITGLM, STEPWISEGLM, LinearModel, NonLinearModel.
    
    %   Copyright 2011-2017 The MathWorks, Inc.
    
    
    properties(GetAccess='public',SetAccess='protected')
        %Dispersion Parameter defining the variance of the response.
        %    The value of the Dispersion property depends on the Distribution of
        %    the model. For a normal distribution, the Dispersion is the mean
        %    squared error of the residuals. For other distributions, the
        %    Dispersion multiplies the variance function for the distribution.
        %
        %    For example, the variance function for the binomial distribution is
        %    P*(1-P)/N where P is the probability parameter and N is the sample
        %    size parameter. If the Dispersion parameter is near 1, then the
        %    variance of the data appears to agree with the theoretical variance of
        %    the binomial distribution. If the Dispersion parameter is larger than
        %    1, the data are said to be overdispersed relative to the binomial
        %    distribution.
        %
        %    See also GeneralizedLinearModel, DispersionEstimated.
        Dispersion = 0;
        
        %DispersionEstimated Estimated dispersion used to estimate standard errors.
        %    The DispersionEstimated property is true if the Dispersion parameter
        %    is used in computing standard errors for the coefficients, or false if
        %    it is not. This property can be false only for the binomial and
        %    Poisson distributions.
        %
        %    See also GeneralizedLinearModel, Dispersion.
        DispersionEstimated = false;
        
        %Deviance Deviance of the fit.
        %    The Deviance property is the deviance of the fit, which is equal to
        %    -2 times the log likelihood.
        %
        %    The deviance is useful for comparing two models when one is a special
        %    case of the other. The difference D between the deviance of the two
        %    models is -2 times the log of the likelihood ratio. Asymptotically, D
        %    has a chi-square distribution with degrees of freedom V equal to the
        %    number of parameters that are estimated in one model but fixed
        %    (typically at 0) in the other. The p-value for this test is
        %    1-chi2cdf(D,V).
        %
        %    See also GeneralizedLinearModel, NumEstimatedCoefficients, chi2cdf.
        Deviance = NaN;
        
    end
    properties(GetAccess='protected',SetAccess='protected')
        DistributionName = 'normal';
        DevianceNull = NaN;
        PrivateLogLikelihood = [];
    end
    properties(Dependent,GetAccess='public',SetAccess='protected')
        %Distribution Response distribution and related information.
        %    The Distribution property is a structure providing the name and other
        %    characteristics of the distribution of the response. This structure
        %    has three fields:
        %
        %        Name             Name of the distribution; one of 'normal',
        %                         'binomial', 'poisson', 'gamma', or 'inverse gamma'.
        %        DevianceFunction Function that computes the components of the
        %                         deviance as a function of the fitted parameter
        %                         values and the response values.
        %        VarianceFunction Function that computes the theoretical variance
        %                         for the distribution as a function of the fitted
        %                         parameter values. When the DispersionEstimated
        %                         parameter is true, the Dispersion parameter
        %                         multiplies the variance function in the
        %                         computation of the coefficient standard errors.
        %
        %    See also GeneralizedLinearModel, Link, Dispersion, DispersionEstimated.
        Distribution
        
        %Link Link between the distribution parameter and predictor values.
        %    The Link property is a structure providing the name and other
        %    characteristics of the link function. The link is a function F that
        %    links the distribution parameter MU to the fitted linear combination
        %    XB of the predictors:  F(MU) = XB.  The structure has four fields:
        %
        %        Name             Name of the link function, or '' if the link is
        %                         specified as functions rather than by name.
        %        LinkFunction     The function that defines F.
        %        DevianceFunction Derivative of F.
        %        VarianceFunction Inverse of F.
        %
        %    See also GeneralizedLinearModel, Distribution.
        Link
    end
    
    methods % get/set methods
        function D = get.Distribution(model)
            name = model.DistributionName;
            [devFun,varFun] = getDistributionFunctions(name);
            D.Name = name;
            D.DevianceFunction = devFun;
            D.VarianceFunction = varFun;
        end
        function link = get.Link(model)
            [linkFun,dlinkFun,ilinkFun] = dfswitchyard('stattestlink',model.Formula.Link,class(model.Coefs));
            if internal.stats.isString(model.Formula.Link)
                link.Name = model.Formula.Link;
            elseif isnumeric(model.Formula.Link)
                link.Name = sprintf('%g',model.Formula.Link);
            else
                link.Name = '';
            end
            link.Link = linkFun;
            link.Derivative = dlinkFun;
            link.Inverse = ilinkFun;
        end
        
        % The following code is removed because it causes a bad interaction with
        % the array editor. As a result, the Diagnostics propety does not appear in
        % the array editor view of the LinearModel object. Diagnostics property
        % access from the command line is provided in the subsref method.
        
        %         function D = get.Diagnostics(model)
        %             D = get_diagnostics(model);
        %         end
    end % get/set methods
    
    methods(Hidden=true, Access='public')
        function model = CompactGeneralizedLinearModel(varargin)
            if nargin == 0 % special case
                model.Formula = classreg.regr.LinearFormula;
                return
            end
            error(message('stats:GeneralizedLinearModel:NoConstructor'));
        end
        
        % Implementation of VariableEditorPropertyProvider to customize
        % the display of properties in the Variable Editor
        function isVirtual = isVariableEditorVirtualProp(~,~)
            % Return true for the Diagnostics property to enable the
            % Variable Editor to derive the Diagnostics property display
            % without actually accessing the Diagnostics property
            % (which may cause memory overflows).
            isVirtual = false;
        end
    end
    methods(Static, Access='public', Hidden)
        function model = make(s)
            model = classreg.regr.CompactGeneralizedLinearModel();
            if isa(s,'struct')
                % Take a struct of field names. This is a hidden method and
                % we rely on the caller to supply all required fields.
                fn = fieldnames(s);
            elseif isa(s,'classreg.regr.CompactGeneralizedLinearModel')
                % Copying one of these or casting a subclass to the parent.
                meta = ?classreg.regr.CompactGeneralizedLinearModel;
                props = meta.PropertyList;
                props([props.Dependent] | [props.Constant]) = [];
                fn = {props.Name};
            end
            for j = 1:length(fn)
                name = fn{j};
                model.(name) = s.(name);
            end
            model.LogLikelihood = s.PrivateLogLikelihood;
        end
    end % static public hidden
    methods(Access='public')
        
        % --------------------------------------------------------------------
        function disp(model)
            %DISP Display a CompactGeneralizedLinearModel.
            %   DISP(GLM) displays the CompactGeneralizedLinearModel GLM.
            %
            %   See also CompactGeneralizedLinearModel.
            isLoose = strcmp(get(0,'FormatSpacing'),'loose');
            if (isLoose), fprintf('\n'); end
            fprintf(getString(message('stats:GeneralizedLinearModel:display_CompactGLM')));
            
            dispBody(model)
        end
        
        % --------------------------------------------------------------------
        function [varargout] = predict(model,Xpred,varargin)
            %predict Compute predicted values given predictor values.
            %   YPRED = PREDICT(GLM,DS) computes a vector YPRED of predicted values
            %   from the GeneralizedLinearModel GLM using predictor variables from the
            %   dataset/table DS. DS must contain all of the predictor variables used to
            %   create GLM.
            %
            %   YPRED = PREDICT(GLM,X), where X is a data matrix with the same number
            %   of columns as the matrix used to create GLM, computes predictions using
            %   the values in X.
            %
            %   [YPRED,YCI] = PREDICT(...) also returns the two-column matrix YCI
            %   containing 95% confidence intervals for the predicted values. These are
            %   non-simultaneous intervals for predicting the mean response at the
            %   specified predictor values. The lower limits of the bounds are in
            %   column 1, and the upper limits are in column 2.
            %
            %   [...] = PREDICT(GLM,DS,PARAM1,VAL1,PARAM2,VAL2,...) or
            %   [...] = PREDICT(GLM,X,PARAM1,VAL1,PARAM2,VAL2,...) specifies one or more
            %   of the following name/value pairs:
            %
            %      'Alpha'        A value between 0 and 1 to specify the confidence
            %                     level as 100(1-ALPHA)%.  Default is 0.05 for 95%
            %                     confidence.
            %      'Simultaneous' Either true for simultaneous bounds, or false (the
            %                     default) for non-simultaneous bounds.
            %      'BinomialSize' The value of the binomial N parameter for each
            %                     row in DS or X. May be a vector or scalar. The
            %                     default value 1 produces YPRED values that are
            %                     predicted proportions. This parameter is used only
            %                     if GLM is fit to a binomial distribution.
            %      'Offset'       Value of the offset for each row in DS or X. May be
            %                     a vector or scalar. The offset is used as an
            %                     additional predictor with a coefficient value
            %                     fixed at 1.0.
            %
            %   Example:
            %      % Fit a logistic model, and compute predicted probabilities and
            %      % confidence intervals for the first three observations
            %      load hospital
            %      formula = 'Smoker ~ Age*Weight*Sex - Age:Weight:Sex';
            %      glm = fitglm(hospital,formula,'distr','binomial')
            %      [ypred,confint] = predict(glm,hospital(1:3,:))
            %
            %   See also GeneralizedLinearModel, random.
            [varargin{:}] = convertStringsToChars(varargin{:});
            if isa(Xpred,'tall')
                [varargout{1:max(1,nargout)}] = hSlicefun(@model.predict,Xpred,varargin{:});
                return
            end
            
            design = designMatrix(model,Xpred);
            offset = 0;
            
            paramNames = {'BinomialSize' 'Confidence' 'Simultaneous' 'Alpha' 'Offset'};
            paramDflts = {           []          .95          false  0.05    offset};
            [Npred,conf,simOpt,alpha,offset,supplied] = ...
                internal.stats.parseArgs(paramNames, paramDflts, varargin{:});
            if supplied.Confidence && supplied.Alpha
                error(message('stats:GeneralizedLinearModel:PredictArgCombination', 'Confidence', 'Alpha'))
            end
            if supplied.Alpha
                conf = 1-alpha;
            end
            
            if supplied.BinomialSize && ~isempty(Npred) && ~strcmpi(model.DistributionName,'Binomial')
                error(message('stats:GeneralizedLinearModel:NotBinomial'));
            end
            if strcmpi(model.DistributionName,'binomial')
                if supplied.BinomialSize
                    binomSizePV = {'Size' Npred};
                else
                    binomSizePV = {'Size' ones(size(design,1),1)};
                end
            else
                binomSizePV = {};
            end
            
            if nargout < 2
                ypred = glmval(model.Coefs,design,model.Formula.Link,'Constant','off','Offset',offset,binomSizePV{:});
                varargout = {ypred};
            else
                [R,sigma] = corrcov(model.CoefficientCovariance);
                stats = struct('se',sigma, 'coeffcorr',R, ...
                    'dfe',model.DFE, 's',model.Dispersion, 'estdisp',model.DispersionEstimated);
                [ypred,dylo,dyhi] = ...
                    glmval(model.Coefs,design,model.Formula.Link,stats,'Constant','off', ...
                    'Confidence',conf,binomSizePV{:},'simul',simOpt,'Offset',offset);
                yCI = [ypred-dylo ypred+dyhi];
                varargout = {ypred yCI};
            end
        end
        
        % --------------------------------------------------------------------
        function ysim = random(model,ds,varargin)
            %random Generate random response values given predictor values.
            %   YNEW = RANDOM(GLM,DS) generates a vector YNEW of random values from the
            %   GeneralizedLinearModel GLM using predictor variables from the
            %   dataset/table DS. DS must contain all of the predictor variables used to create GLM.
            %   The output YNEW is computed by creating predicted values and generating
            %   response values from the fitted distribution.
            %
            %   YNEW = RANDOM(GLM,X), where X is a data matrix with the same number of
            %   columns as the matrix used to create GLM, generates responses using the
            %   values in X.
            %
            %   For binomial and Poisson fits, the YNEW values are generated with the
            %   specified distribution. There is no adjustment for any estimated
            %   dispersion.
            %
            %   YNEW = RANDOM(GLM,DS,PARAM1,VAL1,PARAM2,VAL2,...) or
            %   YNEW = RANDOM(GLM,X,PARAM1,VAL1,PARAM2,VAL2,...) specifies one or more
            %   of the following name/value pairs:
            %
            %      'BinomialSize' The value of the binomial N parameter for each
            %                     row in DS or X. May be a vector or scalar. The
            %                     default value is 1. This parameter is used only
            %                     if GLM is fit to a binomial distribution.
            %      'Offset'       Value of the offset for each row in DS or X. May be
            %                     a vector or scalar. The offset is used as an
            %                     additional predictor with a coefficient value
            %                     fixed at 1.0.
            %
            %   Example:
            %      % Generate some Poisson data
            %      x = 2 + randn(100,1);
            %      mu = exp(1 + x/2);
            %      y = poissrnd(mu);
            %      subplot(1,2,1)
            %      scatter(x,y)
            %
            %      % Fit a regression model and generate new random response values
            %      % from that model
            %      glm = fitglm(x,y,'y ~ x1','distr','poisson')
            %      y2 = random(glm,x);
            %      subplot(1,2,2)
            %      scatter(x,y2)
            %
            %   See also GeneralizedLinearModel, predict, Dispersion.
            
            [varargin{:}] = convertStringsToChars(varargin{:});
            
            paramNames = {'BinomialSize' 'Offset'};
            paramDflts = {           1      0};
            [N,offset,supplied] = ...
                internal.stats.parseArgs(paramNames, paramDflts, varargin{:});
            varargin = {'Offset',offset};
            if supplied.BinomialSize && ~isequal(N,1)
                varargin(end+1:end+2) = {'BinomialSize' 1};
            end
            if strcmpi(model.DistributionName,'binomial')
                % Compute predicted probabilities, use N parameter later
                if isempty(N)
                    N = 1;
                elseif ~isscalar(N) && numel(N)~=size(ds,1)
                    error(message('stats:GeneralizedLinearModel:RandomNSize', size(ds,1)))
                end
            end
            ypred = predict(model,ds,varargin{:});
            switch lower(model.DistributionName)
                case 'binomial'
                    if any(strcmpi(model.VariableInfo.Class{model.RespLoc},{'nominal','ordinal','categorical'}))
                        % Categorical responses
                        if N~=1
                            error(message('stats:GeneralizedLinearModel:BadBinomialSize'))
                        else
                            a = model.VariableInfo.Range(model.RespLoc);
                            b = a{:};
                            y = binornd(N,ypred);
                            y1(y==0) = b(1,1);
                            y1(y==1) = b(1,2);
                            y1 = y1';
                            ysim=y1;
                        end
                    else
                        ysim = binornd(N,ypred);
                    end
                    
                case 'gamma'
                    ysim = gamrnd(1./model.Dispersion,ypred.*model.Dispersion);
                case 'inverse gaussian'
                    ysim = random('inversegaussian',ypred,1./model.Dispersion);
                case 'normal'
                    ysim = normrnd(ypred,sqrt(model.Dispersion));
                case 'poisson'
                    ysim = poissrnd(ypred);
            end
        end
        
        % --------------------------------------------------------------------
        function tbl = devianceTest(model)
            %devianceTest Analysis of deviance
            %   TBL = devianceTest(GLM) displays an analysis of deviance table for the
            %   GeneralizedLinearModel GLM. The table displays a test of whether the
            %   fitted model fits significantly better than a constant model.
            %
            %   Example:
            %      % Generate some Poisson data
            %      x = 2 + randn(100,1);
            %      mu = exp(1 + x/2);
            %      y = poissrnd(mu);
            %
            %      % Fit a regression model and examine the significance of the fit
            %      glm = fitglm(x,y,'y ~ x1','distr','poisson')
            %      devianceTest(glm)
            %
            %   See also GeneralizedLinearModel.
            dev = [model.DevianceNull; model.Deviance];
            dfe = [model.NumObservations-1; model.DFE];
            dfr = model.NumEstimatedCoefficients - 1;
            
            if model.DispersionEstimated
                statName = 'FStat';
                stat = max(0,-diff(dev)) ./ (dfr * model.Dispersion); % F statistic
                p = fcdf(1./stat,dfe(2),dfr); % fpval(fstat,dfr,dfe);
            else
                statName = 'chi2Stat';
                stat = max(0,-diff(dev)); % chi-sqared statistic
                p = gammainc(stat/2,dfr/2,'upper'); % chi2pval(chi2stat,dfr);
            end
            
            if ~hasConstantModelNested(model)
                warning(message('stats:GeneralizedLinearModel:NoIntercept'));
            end
            
            f0 = model.Formula; f0.Terms = zeros(1,model.NumVariables);
            tbl = table(dev, ...
                dfe, ...
                internal.stats.DoubleTableColumn([NaN; stat],[true; false]), ...
                internal.stats.DoubleTableColumn([NaN; p],[true; false]), ...
                'VariableNames',{'Deviance' 'DFE' statName 'pValue'}, ...
                'RowNames',{char(f0,40) char(model.Formula,40)});
            tbl.Properties.DimensionNames = {'Fits' 'Variables'};
        end
        
        function fout = plotSlice(model)
            %plotSlice Plot slices through the fitted regression surface.
            %   plotSlice(GLM) creates a new figure containing a series of plots, each
            %   representing a slice through the regression surface predicted by GLM.
            %   For each plot, the surface slice is shown as a function of a single
            %   predictor variable, with the other predictor variables held constant.
            %
            %   If the model GLM includes an offset term, that term is set to 0 in
            %   computing the regression surface.
            %
            %   See also GeneralizedLinearModel, predict.
            
            f = classreg.regr.modelutils.plotSlice(model);
            
            % This model doesn't support bounds for a new observation, so
            % disable the menu items that select that
            h1 = findobj(f, 'Tag','boundsCurve');
            h2 = findobj(f, 'Tag','boundsObservation');
            set([h1 h2],'Enable','off');
            
            if nargout>0
                fout = f;
            end
        end
    end % public
    
    methods(Hidden=true)
        % --------------------------------------------------------------------
        function t = title(model)
            strLHS = linkstr(model.Formula.Link,model.ResponseName);
            strFunArgs = internal.stats.strCollapse(model.Formula.PredictorNames,',');
            t = sprintf('%s = glm(%s)',strLHS,strFunArgs);
        end
        % --------------------------------------------------------------------
        function v = varianceParam(model)
            v = model.Dispersion;
        end
        
        function s = toStruct(this)
        % toStruct - method for converting model into a struct for codegen
        
            warnState  = warning('query','all');
            warning('off','MATLAB:structOnObject');
            cleanupObj = onCleanup(@() warning(warnState));
            
            
            s = struct;
            meta = ?classreg.regr.CompactGeneralizedLinearModel;
            props = meta.PropertyList;
            props([props.Dependent] | [props.Constant]) = [];
            % get all properties except propsToExclude; these properties
            % are handled separately
            propsToExclude = {'VariableInfo','Formula','CoefficientNames'};
            fn = {props.Name};
            for j = 1:length(fn)
                name = fn{j};
                if ~ismember(name,propsToExclude)
                    s.(name) = this.(name);
                end
            end
            s.LogLikelihood = this.PrivateLogLikelihood;
            % handle excluded properties
            s = classreg.regr.coderutils.regrToStruct(s,this);
            s.FromStructFcn = 'classreg.regr.CompactGeneralizedLinearModel.fromStruct'; 
        end
    end
    methods(Static,Hidden)
        function obj = fromStruct(s)
            % Make a CompactGeneralizedLinearModel object from a codegen struct.

             s = classreg.regr.coderutils.structToRegr(s);
             obj = classreg.regr.CompactGeneralizedLinearModel.make(s);
        
        end
    end    
    methods(Access='protected')
        function dispBody(model)
            % Fit the formula string to the command window width
            indent = '    ';
            maxWidth = matlab.desktop.commandwindow.size; maxWidth = maxWidth(1) - 1;
            f = model.Formula;
            if strcmpi(model.DistributionName,'Binomial') && ...
               any(strcmpi(model.VariableInfo.Class{model.RespLoc},{'nominal','ordinal','categorical'}))
                a = model.VariableInfo.Range(model.RespLoc);
                b = a{:};
                y = char(b(1,2));
                responseName = ['P(',model.ResponseName,'=''',y,''')'];
                respstr = linkstr(model.Formula.Link,responseName);
                fstr = [respstr,' ~ ',model.Formula.LinearPredictor];
            else
                fstr = char(f,maxWidth-length(indent));
            end
            disp([indent fstr]);
            fprintf('%s',getString(message('stats:GeneralizedLinearModel:display_Distribution',indent,model.DistributionName)));
            
            if model.IsFitFromData
                fprintf('%s',getString(message('stats:GeneralizedLinearModel:display_EstimatedCoefficients')));
                disp(model.Coefficients);
                fprintf('%s',getString(message('stats:GeneralizedLinearModel:display_NumObsDFE',model.NumObservations,model.DFE)));
                if model.DispersionEstimated
                    fprintf('%s',getString(message('stats:GeneralizedLinearModel:display_EstimatedDispersion',num2str(model.Dispersion,'%.3g'))));
                else
                    fprintf('%s',getString(message('stats:GeneralizedLinearModel:display_Dispersion',num2str(model.Dispersion,'%.3g'))));
                end
                if hasConstantModelNested(model) && model.NumPredictors > 0
                    d = devianceTest(model);
                    if model.DispersionEstimated
                        fprintf('%s',getString(message('stats:GeneralizedLinearModel:display_FTest',num2str(d.FStat(2),'%.3g'),num2str(d.pValue(2),'%.3g'))));
                    else
                        fprintf('%s',getString(message('stats:GeneralizedLinearModel:display_ChiTest',num2str(d.chi2Stat(2),'%.3g'),num2str(d.pValue(2),'%.3g'))));
                    end
                end
            else
                fprintf('%s',getString(message('stats:GeneralizedLinearModel:display_Coefficients')));
                if any(model.Coefficients.SE > 0)
                    disp(model.Coefficients(:,{'Value' 'SE'}));
                else
                    disp(model.Coefficients(:,{'Value'}));
                end
                if model.Dispersion > 0
                    fprintf('\n%s',getString(message('stats:GeneralizedLinearModel:display_Dispersion',num2str(model.Dispersion,'%.3g'))));
                end
            end
        end
        
        function L = getlogLikelihood(model)
            L = model.PrivateLogLikelihood;
        end
        
        function tbl = tstats(model)
            if model.DispersionEstimated
                nobs = model.NumObservations;
            else
                nobs = Inf;
            end
            tbl = classreg.regr.modelutils.tstats(model.Coefs,sqrt(diag(model.CoefficientCovariance)), ...
                nobs,model.CoefficientNames);
        end
        
        
        %         % --------------------------------------------------------------------
        %         function binomSize_r = create_binomSize_r(model)
        %             binomSize_r = model.ObservationInfo.BinomSize(model.ObservationInfo.Subset);
        %         end
        %
        % --------------------------------------------------------------------
        function ypred = predictPredictorMatrix(model,Xpred)
            % Assume the columns correspond in order to the predictor variables
            design = designMatrix(model,Xpred,true);
            ypred = glmval(model.Coefs,design,model.Formula.Link,'Constant','off');
        end
        
        
        % -------------------- pass throughs to modelutils -------------------
        function crit = get_rsquared(model,type)
            stats = struct('SSE',model.SSE, ...
                'SST',model.SST, ...
                'DFE',model.DFE, ...
                'NumObservations',model.NumObservations, ...
                'LogLikelihood',model.LogLikelihood, ...
                'LogLikelihoodNull',model.LogLikelihoodNull, ...
                'Deviance',model.Deviance, ...
                'DevianceNull',model.DevianceNull);
            if nargin < 2
                crit = classreg.regr.modelutils.rsquared(stats,'all',true);
            else
                crit = classreg.regr.modelutils.rsquared(stats,type);
            end
        end
    end % protected

    %-----------------------------------------------------------------------
    methods(Access=private, Static)
        function name = matlabCodegenRedirect(~)
            name = 'classreg.regr.coder.CompactGeneralizedLinearModel';
        end
    end    
    
    
end


%-------------------------------------------------------------------------
function str = linkstr(link,responseName)
switch lower(link)
    case 'identity',   str = sprintf('%s',responseName);
    case {'inverse' 'reciprocal'}, str = sprintf('1/%s',responseName);
    case 'log',        str = sprintf('log(%s)',responseName);
    case 'logit',      str = sprintf('logit(%s)',responseName);
    case 'probit',     str = sprintf('probit(%s)',responseName);
    case 'loglog',     str = sprintf('log(-log(%s))',responseName);
    case 'comploglog', str = sprintf('log(-log(1-%s))',responseName);
    otherwise
        if isnumeric(link)
            str = sprintf('(%s)^%d',responseName,link);
        else
            str = sprintf('CustomLink(%s)',responseName);
        end
end
end


% ----------------------------------------------------------------------------

function [devFun,varFun] = getDistributionFunctions(name)
switch lower(name)
    case 'normal'
        devFun = @(mu,y) (y - mu).^2;
        varFun = @(mu) ones(size(mu),class(mu));
    case 'binomial'
        devFun = @(mu,y,N) 2*N.*(y.*log((y+(y==0))./mu) + (1-y).*log((1-y+(y==1))./(1-mu)));
        varFun = @(mu,N) mu.*(1-mu) ./ N;
    case 'poisson'
        devFun = @(mu,y) 2*(y .* (log((y+(y==0)) ./ mu)) - (y - mu));
        varFun = @(mu) mu;
    case 'gamma'
        devFun = @(mu,y) 2*(-log(y ./ mu) + (y - mu) ./ mu);
        varFun = @(mu) mu.^2;
    case 'inverse gaussian'
        devFun = @(mu,y) ((y - mu)./mu).^2 ./  y;
        varFun = @(mu) mu.^3;
end
end
