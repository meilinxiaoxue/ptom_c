classdef (AllowedSubclasses = {?LinearModel}) CompactLinearModel < classreg.regr.CompactTermsRegression
    %LinearModel Compact fitted multiple linear regression model.
    %
    %   CompactLinearModel methods:
    %       anova - Analysis of variance
    %       coefCI - Coefficient confidence intervals
    %       coefTest - Linear hypothesis test on coefficients
    %       predict - Compute predicted values given predictor values
    %       feval - Evaluate model as a function
    %       random - Generate random response values given predictor values
    %       plotEffects - Plot of main effects of predictors
    %       plotInteraction - Plot of interaction effects of two predictors
    %       plotSlice - Plot of slices through fitted regression surface
    %
    %   LinearModel properties:
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
    %       MSE - Mean squared error (estimate of residual variance)
    %       RMSE - Root mean squared error (estimate of residual standard deviation)
    %       DFE - Degrees of freedom for residuals
    %       SSE - Error sum of squares
    %       SST - Total sum of squares
    %       SSR - Regression sum of squares
    %       Formula - Representation of the model used in this fit
    %       LogLikelihood - Log of likelihood function at coefficient estimates
    %       CoefficientCovariance - Covariance matrix for coefficient estimates
    %       CoefficientNames - Coefficient names
    %       NumCoefficients - Number of coefficients
    %       NumEstimatedCoefficients - Number of estimated coefficients
    %
    %   See also FITLM, LinearModel.
    
    %   Copyright 2011-2017 The MathWorks, Inc.
    
    properties(GetAccess='public',SetAccess='protected')
        
        %MSE - Mean squared error.
        %   The MSE property is the mean squared error. It is an estimate of the
        %   variance of the error term.
        %
        %   See also LinearModel, anova.
        MSE
        
        %Robust - Robust regression results.
        %   If the model was fit using robust regression, the Robust property
        %   is a structure containing information about that fit. If the model was
        %   not fit using robust regression, this property is empty.
        %
        %   The Robust structure contains the following fields:
        %      RobustWgtFun  Weight function used for the fit, default 'bisquare'
        %      Tune          Tuning constant used
        %      Weights       Robust weights used at the final iteration
        %                    (empty for a compact linear model).
        %
        %   See also LinearModel.
        Robust = [];
    end
    properties(GetAccess='protected',SetAccess='protected')
        Qy
        R
        Rtol
        PrivateLogLikelihood
    end
    properties(Dependent=true,GetAccess='public',SetAccess='protected')
        
        %RMSE - Root mean squared error.
        %   The RMSE property is the root mean squared error. It is an estimate of
        %   the standard deviation of the error term.
        %
        %   See also anova.
        RMSE
    end
    
    methods % get/set methods
        function s = get.RMSE(model)
            s = sqrt(model.MSE);
        end
        
        % The following code is removed because it causes a bad interaction with
        % the array editor. As a result, the Diagnostics property does not appear in
        % the array editor view of the LinearModel object. Diagnostics property
        % access from the command line is provided in the subsref method.
        
    end
    
    methods(Hidden=true, Access='public')
        function model = CompactLinearModel(varargin) % modelDef, coefs, ...
            if nargin == 0 % special case
                model.Formula = classreg.regr.LinearFormula;
                return
            end
            error(message('stats:LinearModel:NoConstructor'));
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
        function isComplex = isVariableEditorComplexProp(~,~)
            % Diagnostics property should not be complex
            isComplex = false;
        end
        function isSparse = isVariableEditorSparseProp(~,~)
            % Diagnostics property should not be sparse
            isSparse = false;
        end
        function className = getVariableEditorClassProp(~,~)
            % Diagnostics property in the Variable Editor is table object
            className = 'table';
        end
        function sizeArray = getVariableEditorSize(this,~)
            sizeArray = [size(this.ObservationInfo.Subset,1); 7];
        end
    end
    methods(Hidden = true)
        function s = toStruct(this)
            % toStruct - method for converting model into a struct for codegen
            
            warnState  = warning('query','all');
            warning('off','MATLAB:structOnObject');
            cleanupObj = onCleanup(@() warning(warnState));
            
            s = struct;
            meta = ?classreg.regr.CompactLinearModel;
            props = meta.PropertyList;
            props([props.Dependent] | [props.Constant]) = [];
            % get all properties except propsToExclude; these properties
            % are handled separately
            propsToExclude = {'VariableInfo','Formula','CoefficientNames','Robust'};
            fn = {props.Name};
            for j = 1:length(fn)
                name = fn{j};
                if ~ismember(name,propsToExclude)
                    s.(name) = this.(name);
                end
            end
            % handle excluded properties
            robustStr = this.Robust;
            if ~isempty(robustStr)
                robustStr.RobustWgtFun = func2str(robustStr.RobustWgtFun);
                % CompactLinearModel Weights is empty.
                robustStr.Weights = [];
                s.Robust = robustStr;
            else
                s.Robust = robustStr; 
            end
            s = classreg.regr.coderutils.regrToStruct(s,this);
            s.FromStructFcn = 'classreg.regr.CompactLinearModel.fromStruct';
        end
    end
    methods(Access='public')
        function disp(model)
            %DISP Display a LinearModel.
            %   DISP(LM) displays the LinearModel LM.
            %
            %   See also LinearModel.
            isLoose = strcmp(get(0,'FormatSpacing'),'loose');
            if (isLoose), fprintf('\n'); end
            if isempty(model.Robust)  % non-robust
                fprintf('%s',getString(message('stats:LinearModel:display_CompactLinearRegressionModel')));
            else                      % robust
                fprintf('%s',getString(message('stats:LinearModel:display_CompactLinearRegressionModelrobustFit')));
            end
            
            dispBody(model)
        end
        
        % --------------------------------------------------------------------
        function [varargout] = predict(model,Xpred,varargin)
%             %predict Compute predicted values given predictor values.
            %   YPRED = PREDICT(LM,DS) computes a vector YPRED of predicted values from
            %   the LinearModel LM using predictor variables from the dataset/table DS. DS
            %   must contain all of the predictor variables used to create LM.
            %
            %   YPRED = PREDICT(LM,X), where X is a data matrix with the same number of
            %   columns as the matrix used to create LM, computes predictions using the
            %   values in X.
            %
            %   [YPRED,YCI] = PREDICT(...) also returns the two-column matrix YCI
            %   containing 95% confidence intervals for the predicted values. These are
            %   non-simultaneous intervals for predicting the mean response at the
            %   specified predictor values. The lower limits of the bounds are in
            %   column 1, and the upper limits are in column 2.
            %
            %   [...] = PREDICT(LM,DS,PARAM1,VAL1,PARAM2,VAL2,...) or
            %   [...] = PREDICT(LM,X,PARAM1,VAL1,PARAM2,VAL2,...) specifies one or more
            %   of the following name/value pairs:
            %
            %      'Alpha'        A value between 0 and 1 to specify the confidence
            %                     level as 100(1-ALPHA)%.  Default is 0.05 for 95%
            %                     confidence.
            %      'Simultaneous' Either true for simultaneous bounds, or false (the
            %                     default) for non-simultaneous bounds.
            %      'Prediction'   Either 'curve' (the default) to compute confidence
            %                     intervals for the curve (function value) at X, or
            %                     'observation' for prediction intervals for a new
            %                     observation at X.
            %
            %   Example:
            %      % Create a regression model and use it to compute predictions
            %      % and confidence intervals for the value of the function for
            %      % the first three observations
            %      load carsmall
            %      d = dataset(MPG,Weight);
            %      d.Year = ordinal(Model_Year);
            %      lm = fitlm(d,'MPG ~ Year + Weight + Weight^2')
            %      [fitted,confint] = predict(lm,d(1:3,:))
            %
            %   See also LinearModel, random.
            [varargin{:}] = convertStringsToChars(varargin{:});
            if isa(Xpred,'tall')
                [varargout{1:max(1,nargout)}] = hSlicefun(@model.predict,Xpred,varargin{:});
                return
            end            
            design = designMatrix(model,Xpred);
            [varargout{1:max(1,nargout)}] = predictDesign(model,design,varargin{:});
        end
        
        % --------------------------------------------------------------------
        function ysim = random(model,x)
            %random Generate random response values given predictor values.
            %   YNEW = RANDOM(LM,DS) generates a vector YNEW of random values from
            %   the LinearModel LM using predictor variables from the dataset/table DS.
            %   DS must contain all of the predictor variables used to create LM. The
            %   output YNEW is computed by creating predicted values and adding new
            %   random noise values with standard deviation LM.RMSE.
            %
            %   YNEW = RANDOM(LM,X), where X is a data matrix with the same number of
            %   columns as the matrix used to create LM, generates responses using the
            %   values in X.
            %
            %   Example:
            %      % Plot car MPG as a function of Weight
            %      load carsmall
            %      subplot(1,2,1);
            %      scatter(Weight,MPG)
            %
            %      % Same plot using new random responses from a fitted model
            %      subplot(1,2,2);
            %      lm = fitlm(Weight,MPG,'quadratic');
            %      mrand = random(lm,Weight)
            %      scatter(Weight,mrand)
            %
            %   See also LinearModel, predict, RMSE.
            ypred = predict(model,x);
            ysim = normrnd(ypred,model.RMSE);
        end
        
        function tbl = anova(model,anovatype,sstype)
            %ANOVA Analysis of variance
            %   TBL = ANOVA(LM) displays an analysis of variance (anova) table for the
            %   LinearModel LM. The table displays a 'components' anova with sums of
            %   squares and F tests attributable to each term in the model, except the
            %   constant term.
            %
            %   TBL = ANOVA(LM,'summary') displays a summary anova table with an F test
            %   for the model as a whole. If there are both linear and higher-order
            %   terms, there is also an F test for the higher-order terms as a group.
            %   If there are replications (multiple observations sharing the same
            %   predictor values), there is also an F test for lack-of-fit computed by
            %   decomposing the residual sum of squares into a sum of squares for the
            %   replicated observations and the remaining sum of squares.
            %
            %   TBL = ANOVA(LM,'components',SSTYPE) computes the specified type of sums
            %   of squares. Choices 1-3 give the usual type 1, type 2, or type 3 sums
            %   of squares.  The value 'h' produces sums of squares for a hierarchical
            %   model that is similar to type 2, but with continuous as well as
            %   categorical factors used to determine the hierarchy of terms. The
            %   default is 'h'.
            %
            %   Example:
            %       % Look at a components anova showing all terms
            %       load carsmall
            %       d = dataset(MPG,Weight);
            %       d.Year = ordinal(Model_Year);
            %       lm = LinearModel.fit(d,'MPG ~ Year + Weight + Weight^2')
            %       anova(lm)
            %
            %       % Look at a summary anova showing groups of terms. The nonlinear
            %       % group consists of just the Weight^2 term, so it has the same
            %       % p-value as that term in the previous table. The F statistic
            %       % comparing the residual sum of squares to a "pure error" estimate
            %       % from replicated observations shows no evidence of lack of fit.
            %       anova(lm,'summary')
            %
            %   See also LinearModel.
            
            if nargin < 2
                anovatype = 'components';
            else
                anovatype = convertStringsToChars(anovatype);
                anovatype = internal.stats.getParamVal(anovatype,...
                    {'summary' 'components' 'oldcomponents' 'newcomponents'},'second');
            end
            if nargin<3
                sstype = 'h';
            end            
            sstype = convertStringsToChars(sstype);
            switch(lower(anovatype))
                case 'components'
                    tbl = componentanova(model,sstype);
                case 'oldcomponents'
                    tbl = componentanova(model,sstype,true);
                case 'newcomponents'
                    tbl = componentanova(model,sstype,false);
                case 'summary'
                    tbl = summaryanova(model);
                otherwise
                    error(message('stats:LinearModel:BadAnovaType'));
            end
        end
        % ----------------------
        
        
        function fout = plotSlice(model)
            %plotSlice Plot slices through the fitted regression surface.
            %   plotSlice(LM) creates a new figure containing a series of plots, each
            %   representing a slice through the regression surface predicted by LM.
            %   For each plot, the surface slice is shown as a function of a single
            %   predictor variable, with the other predictor variables held constant.
            %
            %   If there are more than eight predictors, plotSlice selects the first
            %   five of them for plotting. You can use the Predictors menu to control
            %   which predictors are plotted.
            %
            %    Example:
            %      % Make a slice plot for a fitted regression model
            %      load carsmall
            %      d = dataset(MPG,Weight);
            %      d.Year = ordinal(Model_Year);
            %      lm = fitlm(d,'MPG ~ Year + Weight + Weight^2')
            %      plotSlice(lm)
            %
            %   See also LinearModel, predict, RMSE.
            % compactNotAllowed(model,'plotSlice',false);
            f = classreg.regr.modelutils.plotSlice(model);
            if nargout>0
                fout = f;
            end
        end
        function hout = plotEffects(model)
            %plotEffects Plot main effects of each predictor.
            %   plotEffects(LM) produces an effects plot for the predictors in the
            %   LinearModel LM. This plot shows the estimated effect on the response
            %   from changing each predictor value from one value to another. The two
            %   values are chosen to produce a relatively large effect on the response.
            %   This plot enables you to compare the effects of the predictors,
            %   regardless of the scale of the predictor measurements.
            %
            %   Each effect is shown as a circle, with a horizontal bar showing the
            %   confidence interval for the estimated effect. The effect values are
            %   computed from the adjusted response curve, as shown by the
            %   plotAdjustedResponse function.
            %
            %   H = plotEffects(LM) returns a vector H of handles to the lines in the
            %   plot. H(1) is a handle to the line that defines the effect estimates,
            %   and H(J+1) is a handle to the line that defines the confidence interval
            %   for the effect of predictor J.
            %
            %    Example:
            %      % Plot the effects of two predictors in a regression model
            %      load carsmall
            %      d = dataset(MPG,Weight);
            %      d.Year = ordinal(Model_Year);
            %      lm = fitlm(d,'MPG ~ Year + Weight + Weight^2')
            %      plotEffects(lm)
            %
            %      % Verify that plotted effect of Weight matches what we would
            %      % calculate by evaluating the fitted model
            %      feval(lm,4732,'70') - feval(lm,1795,'70')
            %
            %   See also LinearModel, plotAdjustedResponse, plotInteraction.
 
            % Plot requires lower-order terms. These may not be available
            % for compact models created from tall data. They should have
            % been pre-computed for other compact models.
            if ~hasData(model) && ~isHierarchical(model) && ...
                    (isempty(model.TermMeans) || isempty(model.TermMeans.Terms))
                error(message('stats:LinearModel:PlotHierarchy'));
            end
            
            % Plot main effects of each predictor
            [effect,effectSE,effectname] = getEffects(model);
            
            % Plot the results
            y = (1:length(effect))';
            ci = [effect effect] + effectSE*tinv([.025 .975],model.DFE);
            h = plot(effect,y,'bo', ci',[y y]','b-');
            set(h(1),'Tag','estimate');
            set(h(2:end),'Tag','ci');
            xlabel(getString(message('stats:LinearModel:xylabel_MainEffect')));
            set(gca,'YTick',y,'YTickLabel',effectname,'YLim',[.5,max(y)+.5],'YDir','reverse');
            dfswitchyard('vline',gca,0,'LineStyle',':','Color','k');
            
            if nargout>0
                hout = h;
            end
        end
        function hout = plotInteraction(model,var1,var2,ptype)
            %plotInteraction Plot interaction effects of two predictors.
            %   plotInteraction(LM,VAR1,VAR2) creates a plot of the interaction effects
            %   of the predictors VAR1 and VAR2 in the LinearModel LM. This plot shows
            %   the estimated effect on the response from changing each predictor value
            %   from one value to another with the effects of other predictors averaged
            %   out. It also shows the estimated effect with the other predictor fixed
            %   at certain values. The values are chosen to produce a relatively large
            %   effect on the response. This plot enables you to examine whether the
            %   effect of one predictor depends on the value of the other predictor.
            %
            %   Each effect is shown as a circle, with a horizontal bar showing the
            %   confidence interval for the estimated effect. The effect values are
            %   computed from the adjusted response curve, as shown by the
            %   plotAdjustedResponse function.
            %
            %   plotInteraction(LM,VAR1,VAR2,PTYPE) with PTYPE='predictions' shows the
            %   adjusted response curve as a function of VAR2, with VAR1 fixed at
            %   certain values. The default form of the plot is produced with
            %   PTYPE='effects'.
            %
            %   H = plotInteraction(...) returns a vector H of handles to the lines in
            %   the plot.
            %
            %    Example:
            %      % Plot the effect of one predictor in a regression model at
            %      % fixed values of another predictor
            %      load carsmall
            %      d = dataset(MPG,Weight);
            %      d.Year = ordinal(Model_Year);
            %      lm = fitlm(d,'MPG ~ Year + Weight + Weight^2')
            %      subplot(1,2,1)
            %      plotInteraction(lm,'Year','Weight','predictions')
            %
            %      % See how this changes if we add an interaction term
            %      lm = addTerms(lm,'Weight*Year')
            %      subplot(1,2,2)
            %      plotInteraction(lm,'Year','Weight','predictions')
            %
            %   See also LinearModel, plotAdjustedResponse, plotEffects.
            
            %   For a 'predictions' plot, there is one value in H for each curve shown
            %   on the plot. For an 'effects' plot, H(1) is the handle for the main
            %   effects. H(2) is the handle for the confidence interval for the first
            %   main effect, and H(3) is the confidence interval for the second main
            %   effect. The remaining entries in H are handles for the conditional
            %   effects and their confidence intervals. Handles associated with the
            %   main effects have the tag 'main'. Handles associated with conditional
            %   effects at the top and bottom have the tag 'conditional1' and
            %   'conditional2', respectively.
            
            if nargin<4
                ptype = 'effects';
            end
            var1 = convertStringsToChars(var1);
            var2 = convertStringsToChars(var2);
            ptype = convertStringsToChars(ptype);
            
            % Plot requires lower-order terms. These may not be available
            % for compact models created from tall data. They should have
            % been pre-computed for other compact models.
            if ~hasData(model) && ~isHierarchical(model) && ...
                    (isempty(model.TermMeans) || isempty(model.TermMeans.Terms))
                error(message('stats:LinearModel:PlotHierarchy'));
            end
            
            % Plot interaction effects between two predictors
            
            % Get information about terms and predictors
            terminfo = getTermInfo(model);
            [vname1,vnum1] = identifyVar(model,var1);
            [vname2,vnum2] = identifyVar(model,var2);
            
            if isequal(vname1,model.ResponseName) || isequal(vname2,model.ResponseName)
                error(message('stats:LinearModel:ResponseNotAllowed',model.ResponseName))
            elseif isequal(vnum1,vnum2)
                error(message('stats:LinearModel:DifferentPredictors'))
            end
            
            switch(ptype)
                case 'effects'
                    h = plotInteractionEffects(model,vnum1,vnum2,vname1,vname2,terminfo);
                case 'predictions'
                    h = plotInteractionPredictions(model,vnum1,vnum2,vname1,vname2,terminfo);
                otherwise
                    error(message('stats:LinearModel:BadEffectsType'));
            end
            
            if nargout>0
                hout = h;
            end
        end
        
        % ------------------
    end % public

    methods(Access='protected')
        function dispBody(model)
            % Fit the formula string to the command window width
            indent = '    ';
            maxWidth = matlab.desktop.commandwindow.size; maxWidth = maxWidth(1) - 1;
            f = model.Formula;
            fstr = char(f,maxWidth-length(indent));
            disp([indent fstr]);
            
            if ~isnan(model.DFE)
                % Model was estimated, not created directly
                fprintf('%s',getString(message('stats:LinearModel:display_EstimatedCoefficients')));
            else
                fprintf(getString(message('stats:LinearModel:display_Coefficients')));
            end
            disp(model.Coefficients);

            if ~isnan(model.DFE)
                fprintf('%s',getString(message('stats:LinearModel:display_NumObservationsDFE',model.NumObservations,model.DFE)));
            end
            if model.MSE>0 && ~isnan(model.MSE)
                fprintf('%s',getString(message('stats:LinearModel:display_RMSE',num2str(model.RMSE,'%.3g'))));
            end
            if hasConstantModelNested(model) && model.NumPredictors > 0
                rsq = get_rsquared(model,{'ordinary','adjusted'});
                fprintf('%s',getString(message('stats:LinearModel:display_RsquaredAdj',num2str(rsq(1),'%.3g'),num2str(rsq(2),'%.3g'))));
                [f,p] = fTest(model);
                fprintf('%s',getString(message('stats:LinearModel:display_Ftest',num2str(f,'%.3g'),num2str(p,'%.3g'))));
            end
        end

        % --------------------------------------------------------------------
        function L = getlogLikelihood(model)
            sigmaHat = sqrt(model.DFE/model.NumObservations*model.MSE);
            if sigmaHat==0
                % We have a perfect fit, so an infinite log likelihood
                L = Inf;
            else
                n = model.NumObservations;
                L = -(n/2)*log(2*pi) - n*log(sigmaHat) - 0.5*model.SSE/(sigmaHat^2);
                % L = sum(model.w_r .* normlogpdf(model.y_r,muHat_r,sigmaHat));
            end
        end
        
        % --------------------------------------------------------------------
        function ypred = predictPredictorMatrix(model,Xpred)
            % Assume the columns correspond in order to the predictor variables
            ypred = designMatrix(model,Xpred,true) * model.Coefs;
        end
        function [ypred,yCI] = predictDesign(model,design,varargin)
            paramNames = {'Alpha' 'Simultaneous' 'Prediction' 'Confidence'};
            paramDflts = {    .05          false      'curve' .95 };
            [alpha,simOpt,predOpt,conf,supplied] = ...
                internal.stats.parseArgs(paramNames, paramDflts, varargin{:});
            if supplied.Confidence && supplied.Alpha
                error(message('stats:LinearModel:ArgCombination'))
            end
            if supplied.Confidence
                alpha = 1-conf;
            end
            
            predOpt = internal.stats.getParamVal(predOpt,...
                {'curve' 'observation'},'''Prediction''');
            predOpt = strcmpi(predOpt,'observation');
            simOpt = internal.stats.parseOnOff(simOpt,'''Simultaneous''');
            if nargout < 2
                ypred = predci(design,model.Coefs);
            else
                [ypred, yCI] = predci(design,model.Coefs,...
                    model.CoefficientCovariance,model.MSE,...
                    model.DFE,alpha,simOpt,predOpt,model.Formula.HasIntercept);
            end
        end
        function h = plotInteractionPredictions(model,vnum1,vnum2,vname1,vname2,terminfo)
            
            [xdata1,xlabels1] = getInteractionXData(model,vnum1,terminfo);
            [xdata2,xlabels2] = getInteractionXData(model,vnum2,terminfo);
            
            % Get data for grouping variable
            if ~terminfo.isCatVar(vnum1)
                % Define a coarser grid of values
                xdata1 = xdata1([1 51 101]);
                xlabels1 = cellstr(strjust(num2str(xdata1),'left'));
            end
            
            % Get data for variable plotted on X axis
            ngrid2 = length(xdata2);
            if terminfo.isCatVar(vnum2)
                % Compute fitted values for each level of this predictor
                xi2 = (1:ngrid2)';
                plotspec = '-o';
            else
                % Plot line across the grid of values
                xi2 = xdata2;
                plotspec = '-';
            end
            
            y = zeros(ngrid2,length(xdata1));
            xi = [xi2 xi2];
            for j = 1:size(y,2)
                xi(:,1) = xdata1(j);
                y(:,j) = getAdjustedResponse(model,[vnum1 vnum2],xi,terminfo);
            end
            
            h = plot(1,1, xi2,y,plotspec, 'LineWidth',2);
            set(h(1),'LineStyle','none','Marker','none','XData',[],'YData',[]);
            title(sprintf('%s',getString(message('stats:LinearModel:sprintf_InteractionOfAnd',vname1,vname2))));
            xlabel(vname2);
            ylabel(sprintf('%s',getString(message('stats:LinearModel:sprintf_Adjusted',model.ResponseName))));
            legend(h,[vname1; xlabels1(:)]);
            
            if terminfo.isCatVar(vnum2)
                set(gca,'XTick',1:ngrid2,'XTickLabel',xlabels2,'XLim',[0.5,ngrid2+0.5]);
            end
            h(1) = [];  % special line used only to create legend label
        end
        
        function [x,xlabels] = getInteractionXData(model,vnum,terminfo)
            xdata = model.VariableInfo.Range{vnum};
            if terminfo.isCatVar(vnum)
                % Compute fitted values for each level of this predictor
                [~,xlabels] = grp2idx(xdata);
                x = (1:length(xlabels))';
            else
                % Define a grid of values
                x = linspace(min(xdata),max(xdata),101)';
                xlabels = [];
            end
        end
        
        % ------------------
        function h = plotInteractionEffects(model,vnum1,vnum2,vname1,vname2,terminfo)
            [effect,effectSE,effectName,x] = getEffects(model,[vnum1 vnum2],terminfo);
            ci = [effect effect] + effectSE*tinv([.025 .975],model.DFE);
            
            [ceffect1,ceffect1SE,ceffect1Name] = getConditionalEffect(model,vnum1,vnum2,x(1,:)',terminfo);
            ci1 = [ceffect1 ceffect1] + ceffect1SE*tinv([.025 .975],model.DFE);
            
            [ceffect2,ceffect2SE,ceffect2Name] = getConditionalEffect(model,vnum2,vnum1,x(2,:)',terminfo);
            ci2 = [ceffect2 ceffect2] + ceffect2SE*tinv([.025 .975],model.DFE);
            
            % Plot the results
            gap = 2;
            y0 = [1; 2+gap+length(ceffect1)];
            y1 = 1 + (1:length(ceffect1))';
            y2 = 2 + gap + length(ceffect1) + (1:length(ceffect2))';
            y = [y0(1); y1; y0(2); y2];
            allnames = [effectName(1); ceffect1Name; effectName(2);ceffect2Name];
            
            h = plot(effect,y0,'bo', ci',[y0 y0]','b-', 'LineWidth',2,'Tag','main');
            washold = ishold;
            hold on
            h = [h;
                plot(ceffect1,y1,'Color','r','LineStyle','none','Marker','o','Tag','conditional1'); ...
                plot(ci1',[y1 y1]','Color','r','Tag','conditional1'); ...
                plot(ceffect2,y2,'Color','r','LineStyle','none','Marker','o','Tag','conditional2'); ...
                plot(ci2',[y2 y2]','Color','r','Tag','conditional2')];
            if ~washold
                hold off
            end
            title(sprintf('%s',getString(message('stats:LinearModel:sprintf_InteractionOfAnd',vname1,vname2))));
            xlabel(getString(message('stats:LinearModel:xylabel_Effect')));
            set(gca,'YTick',y,'YTickLabel',allnames,'YLim',[.5,max(y)+.5],'YDir','reverse');
            dfswitchyard('vline',gca,0,'LineStyle',':','Color','k');
        end

        function tbl = componentanova(model,sstype,refit)
            
            % Initialize variables for components anova
            nterms = length(model.Formula.TermNames);
            
            iseffects = isequal(model.DummyVarCoding,'effects');
            sstype = getSSType(sstype);
            if nargin<3
                refit = sstype==3 && ~isHierarchical(model) && ~iseffects;
            end
            
            if sstype==3 && refit
                if ~hasData(model) && ~isHierarchical(model)
                    error(message('stats:LinearModel:AnovaHierarchy'));
                end
                
                % Re-do model using the dummy variable coding that we require.
                oldmodel = model;
                formula = sprintf('%s ~ %s',oldmodel.Formula.ResponseName,oldmodel.Formula.LinearPredictor);
                model = LinearModel.fit(oldmodel.Variables,formula,'DummyVarCoding','effects',...
                    'Robust',oldmodel.Robust,'Categorical',oldmodel.VariableInfo.IsCategorical,...
                    'Exclude',~oldmodel.ObservationInfo.Subset,'Weight',oldmodel.ObservationInfo.Weights,...
                    'Intercept',oldmodel.Formula.HasIntercept);
            end
            
            % The SS for a term is the difference in RSS between a model with the term
            % and a model without the term. The specific models depend on sstype.
            allmodels = getComparisonModels(model,sstype);
            [uniquemodels,~,uidx] = unique(allmodels,'rows');
            
            % Fetch some information from the full model up front
            rtol = model.Rtol;
            mse = model.MSE;
            if sstype==3 && ~refit && ~iseffects
                % Need to transform these to be based on effects coding
                [coefs,coefcov,R1,Qy1] = applyEffectsCoding(model);
            else
                % Can get these straight from the model
                R1 = model.R;
                coefs = model.Coefs;
                coefcov = model.CoefficientCovariance;
                Qy1 = model.Qy;
            end
            
            % Find SS and DF for each model
            allSS = zeros(nterms,2);
            allDF = zeros(nterms,2);
            dfx = model.NumObservations - model.DFE;
            for j=1:size(uniquemodels,1)
                [ssModel,dfModel] = getTermSS1(~uniquemodels(j,:),dfx,...
                    R1,mse,coefs,coefcov,Qy1,rtol);
                t = (uidx==j);
                allSS(t) = ssModel;
                allDF(t) = dfModel;
            end
            
            ss = [max(0,diff(allSS,1,2)); model.SSE]; % guard against -eps errors
            df = [      diff(allDF,1,2) ; model.DFE];
            
            % Remove constant, if any
            constTerm = all(model.Formula.Terms==0,2);
            ss(constTerm,:) = [];
            df(constTerm,:) = [];
            
            % Compute remaining columns of the table
            ms = ss ./ df;
            invalidrows = (1:length(ms))' == length(ms);
            f = ms./ms(end);
            pval = fcdf(f,df,df(end),'upper');
            
            % Assemble table
            tbl = table(ss, df, ms, ...
                internal.stats.DoubleTableColumn(f,invalidrows), ...
                internal.stats.DoubleTableColumn(pval,invalidrows), ...
                'VariableNames',{'SumSq' 'DF' 'MeanSq' 'F' 'pValue'}, ...
                'RowNames',[model.Formula.TermNames(~constTerm);'Error']);
        end
        
        % ----------------------------------------------------------------------
        function tbl = summaryanova(model)
            % Create summary anova table with rows
            %
            % 1   Total SS
            % 2   Model SS
            % 3      Linear SS        <--- | These two rows are present only if
            % 4      Nonlinear SS     <--- | the model has interaction or power terms
            % 5   Residual SS
            % 6      Lack-of-fit SS   <--- | These two rows are present only if
            % 7      Pure error SS    <--- | the model has replicates
            
            ss = zeros(7,1);
            df = zeros(7,1);
            keep = true(7,1);
            
            termorder = sum(model.Formula.Terms,2);
            
            % Get information always required
            hasconst = any(termorder==0);
            ss(1) = model.SST;
            df(1) = model.NumObservations - hasconst;
            
            ss(2) = model.SSR;
            dfx = df(1) - model.DFE;
            df(2) = dfx;
            
            ss(5) = model.SSE;
            df(5) = model.DFE;
            
            % If there are nonlinear terms, we can break ssr into pieces
            if sum(termorder>1)>0 && sum(termorder==1)>0
                terminfo = getTermInfo(model);
                nonlincols = ismember(terminfo.designTerms, find(termorder>1));
                [ss(4),df(4)] = getTermSS(model,nonlincols,dfx+hasconst);
                ss(3) = ss(2) - ss(4);
                df(3) = df(2) - df(4);
            else
                keep(3:4) = false;
            end
            
            % If there are replicates, we can break sse into pieces
            [isrep,sspe,dfpe] = getReplicateInfo(model);
            if any(isrep)
                ss(7) = sspe;
                df(7) = dfpe;
                ss(6) = ss(5) - ss(7);
                df(6) = df(5) - df(7);
            else
                keep(6:7) = false;
            end
            
            % Compute MS for each term
            ms = ss ./ df;
            
            % Define error terms for each F test
            invalidrows = [true false false false true false true]';
            mse = [NaN ms(5) ms(5) ms(5) NaN ms(7) NaN]';
            dfe = [NaN df(5) df(5) df(5) NaN df(7) NaN]';
            
            f = ms./mse;
            pval = fcdf(1./f,dfe,df); % 1-fcdf(f,df,dfe)
            
            obsnames = {'Total' 'Model' '. Linear' '. Nonlinear' ...
                'Residual' '. Lack of fit' '. Pure error'};
            tbl = table(ss(keep), df(keep), ms(keep), ...
                internal.stats.DoubleTableColumn(f(keep),invalidrows(keep)), ...
                internal.stats.DoubleTableColumn(pval(keep),invalidrows(keep)), ...
                'VariableNames',{'SumSq' 'DF' 'MeanSq' 'F' 'pValue'}, ...
                'RowNames',obsnames(keep));
        end
        
        function [isrep,sspe,dfpe] = getReplicateInfo(model) %#ok<MANU>
            isrep = false; % can only be done for a full model
            sspe = 0;
            dfpe = 0;
        end
        
        % ----------------------------------------------------------------------
        function allmodels = getComparisonModels(model,sstype)
            terminfo = getTermInfo(model,false);
            termcols = terminfo.designTerms;
            nterms = max(termcols);
            terms = model.Formula.Terms;
            allmodels = false(2*nterms,length(termcols));
            continuous = ~terminfo.isCatVar;
            switch(sstype)
                case 1
                    % Type 1 or sequential sums of squares
                    for j = 1:nterms
                        allmodels(j,:)        = termcols<=j; % with term j
                        allmodels(j+nterms,:) = termcols<j;  % without term j
                    end
                case 3
                    for j = 1:nterms
                        allmodels(j,:)        = true;        % with term j
                        allmodels(j+nterms,:) = termcols~=j; % without term j
                    end
                case {2,'h'}
                    % Strict hierarchical sums of squares
                    for j = 1:nterms
                        % Get vars in this term
                        varsin = terms(j,:);
                        
                        % Take out terms higher than this one
                        out = all(bsxfun(@ge,terms(:,varsin>0),terms(j,varsin>0)),2);
                        
                        % But for type 2, only if they match on all continuous vars
                        if sstype==2
                            out = out & all(bsxfun(@eq,terms(:,continuous),terms(j,continuous)),2);
                        end
                        t = ismember(termcols,find(~out));
                        allmodels(j,:)        = t | termcols==j; % with term j
                        allmodels(j+nterms,:) = t;               % without term j
                    end
            end
        end
        
        % ----------------------------------------------------------------------
        function [ss,df] = getTermSS(model,termcols,dfbefore)
            % Compute SS and DF for term or terms in specific cols. Extract info from
            % model and call computation function.
            [ss,df] = getTermSS1(termcols,dfbefore,model.R,model.MSE,model.Coefs,...
                model.CoefficientCovariance,model.Qy,model.Rtol);
        end
 
        % ----------------------------------------------------------------------
        function [xrow,psmatrix,psflag] = reduceterm(model,vnum,terminfo)
            % Remove variables specified by vnum from all terms, and compute xrow as
            % the mean of the remaining term. Also compute psmatrix as a matrix with
            % one row per vnum value, specifying the corresponding variable's power
            % (continuous) or setting (categorical), and psflag as a logical vector
            % that is 1 if vnum is categorical.
            
            xrow = zeros(size(terminfo.designTerms));
            psmatrix = zeros(length(vnum),length(terminfo.designTerms));
            psflag = terminfo.isCatVar(vnum);
            
            for j=1:size(terminfo.terms,1)
                v = terminfo.terms(j,:);
                tj = terminfo.designTerms==j;
                pwr = v(vnum);
                [~,meanx] = gettermmean(model,v,vnum,terminfo);
                
                if all(pwr==0 | ~psflag)
                    % Special case: removing term doesn't affect term size, because
                    % vnum specifies only continous predictors and categorical ones
                    % that are not part of this term
                    xrow(tj) = meanx;
                    psmatrix(:,tj) = repmat(pwr',1,sum(tj));
                elseif isscalar(vnum) && sum(terminfo.isCatVar(v>0))==sum(psflag)
                    % Special case: vnum specifies the only categorical part of term
                    xrow(tj) = meanx;
                    psmatrix(:,tj) = 2:terminfo.numCatLevels(vnum);
                else
                    % General case: suppose term is A*B*C*D*E and vnum is [D F B].
                    % Here A represents both a categorical predictor and the number of
                    % degrees of freedom for it.
                    isreduced = ismember(find(v>0),vnum);
                    termcatdims = terminfo.numCatLevels(v>0);           % size of ABCDE
                    sz1 = ones(1,max(2,length(termcatdims)));
                    sz1(~isreduced) = max(1,termcatdims(~isreduced)-1); % size of A1C1E
                    sz2 = ones(1,max(2,length(termcatdims)));
                    sz2(isreduced) = max(1,termcatdims(isreduced)-1);   % size of 1B1D1
                    
                    % Propagate mean of reduced term across the full term
                    meanx = reshape(meanx,sz1);                  % shape to A1C1E
                    meanx = repmat(meanx,sz2);                   % replicate to ABCDE
                    xrow(tj) = meanx(:)';
                    
                    % Fill in powers for reduced continuous predictors
                    controws = (pwr>0) & ~psflag;
                    psmatrix(controws,tj) = repmat(pwr(controws),1,sum(tj));
                    
                    % Fill in settings for reduced categorical predictors (DB)
                    catrows = (pwr>0) & psflag;
                    catsettings = 1+fullfact(terminfo.numCatLevels(vnum(catrows))-1)';
                    idx = reshape(1:size(catsettings,2),sz2);
                    idx = repmat(idx,sz1);
                    psmatrix(catrows,tj) = catsettings(:,idx(:));
                end
            end
        end
        
        % ----------------------------------------------------------------------
        function [ok,meanx] = gettermmean(model,v,vnum,terminfo)
            % Get the mean of the design matrix for a term after removing one or more
            % variables from it
            
            % Remove this variable from the term to get a subterm, for example remove B
            % from A*B*C to get A*C
            v(vnum) = 0;
            
            % See if we have this term already, so we will already have means for it
            [ok,row] = ismember(v,terminfo.terms,'rows');
            if ok
                % Typically we have the subterm, so get the pre-computed means
                meanx = terminfo.designMeans(terminfo.designTerms==row);
            elseif ~any(v)
                % constant term
                meanx = 1;
            else
                % We may have pre-computed this term, if the model was compacted
                if isempty(model.TermMeans)
                    ok = false;
                else
                    [ok,row] = ismember(v,model.TermMeans.Terms,'rows');
                end
                
                if ok
                    meanx = model.TermMeans.Means(model.TermMeans.CoefTerm==row);
                else
                    meanx = [];
                end
            end
        end
    end % protected
    methods(Hidden=true, Access='public') % public to allow testing
        function t = title(model)
            strLHS = model.ResponseName;
            strFunArgs = internal.stats.strCollapse(model.Formula.PredictorNames,',');
            t = sprintf( '%s = lm(%s)',strLHS,strFunArgs);
        end
        % --------------------------------------------------------------------
        function v = varianceParam(model)
            v = model.MSE;
        end
        function [fxi,fxiVar] = getAdjustedResponse(model,var,xi,terminfo)
            % Compute adjusted response as a function of a predictor
            
            if nargin<4
                % Get information about terms and predictors
                terminfo = getTermInfo(model);
            end
            if isnumeric(var) % may be scalar or vector
                vnum = var;
            else
                [~,vnum] = identifyVar(model,var);
            end
            
            % Remove this variable from all terms, and get the mean of the
            % remaining term, plus a vector indicating this variable's power
            % (continous) or setting (categorical)
            [xrow,psmatrix,psflag] = reduceterm(model,vnum,terminfo);
            
            % Create a matrix defining linear combinations of the coefficients
            nrows = size(xi,1);
            X = repmat(xrow,nrows,1);
            for k=1:length(psflag)
                if psflag(k)
                    % One row for each level of a categorical predictor; loop over levels
                    for j=1:max(psmatrix(k,:))
                        t = (psmatrix(k,:)==j);
                        if any(t)
                            X(:,t) = bsxfun(@times,X(:,t),(xi(:,k)==j));
                        end
                    end
                else
                    % One row for each grid point; loop over powers of this predictor
                    for j=1:max(psmatrix(k,:))
                        t = (psmatrix(k,:)==j);
                        X(:,t) = bsxfun(@times,X(:,t),xi(:,k).^j);
                    end
                end
            end
            
            % Compute estimated fit and its variance
            fxi = X*model.Coefs;
            if nargout>=2
                fxiVar = X*model.CoefficientCovariance*X';
            end
        end
        function [effects,effectSEs,effectnames,effectXs] = getEffects(model,vars,terminfo)
            % Get the main effect of each specified predictor, computed as the maximum
            % change in adjusted response between two different predictor values.
            
            if nargin<3
                % Get information about terms and predictors
                terminfo = getTermInfo(model);
            end
            if nargin<2
                vars = model.PredictorNames;
            end
            
            npred = length(vars);
            effectnames = cell(npred,1);
            effects = zeros(npred,1);
            effectSEs = zeros(npred,1);
            effectXs = zeros(npred,2);
            
            for j=1:length(vars)
                [vname,vnum] = identifyVar(model,vars(j));
                xdata = model.VariableInfo.Range{vnum};
                
                if terminfo.isCatVar(vnum)
                    % Compute fitted values for each level of this predictor
                    [~,xlabels] = grp2idx(xdata);
                    xi = (1:length(xlabels))';
                else
                    % Define a grid of values
                    xi = linspace(min(xdata),max(xdata),101)';
                end
                
                % Compute adjusted fitted values as a function of this predictor
                [fxi,fxiVar] = getAdjustedResponse(model,vnum,xi,terminfo);
                
                % Compute main effect, its standard error, and its label
                [maxf,maxloc] = max(fxi);
                [minf,minloc] = min(fxi);
                effect = maxf - minf;
                effectSE = sqrt(max(0,fxiVar(minloc,minloc) + fxiVar(maxloc,maxloc) - 2*fxiVar(minloc,maxloc)));
                if terminfo.isCatVar(vnum)
                    effectname = sprintf('%s',getString(message('stats:LinearModel:sprintf_EffectAtoB',vname,xlabels{minloc},xlabels{maxloc})));
                else
                    if minloc>maxloc
                        effect = -effect;
                        temp = minloc;
                        minloc = maxloc;
                        maxloc = temp;
                    end
                    effectname = sprintf('%s',getString(message('stats:LinearModel:sprintf_EffectAtoB',vname,num2str(xi(minloc)),num2str(xi(maxloc)))));
                end
                
                effectX = [xi(minloc), xi(maxloc)];
                
                effects(j) = effect;
                effectnames{j} = effectname;
                effectSEs(j) = effectSE;
                effectXs(j,:) = effectX;
            end
        end
        function [effect,effectSE,effectName] = getConditionalEffect(model,var1,var2,xi1,terminfo)
            % Get effect of v1 conditional on various values of v2. xi1 specifies two
            % values of v1, with the effect defined as the difference in adjusted
            % response between those values. Typically xi1 comes from getEffects.
            
            if nargin<5
                % Get information about terms and predictors
                terminfo = getTermInfo(model);
            end
            [~,vnum1] = identifyVar(model,var1);
            [vname2,vnum2] = identifyVar(model,var2);
            xdata2 = model.VariableInfo.Range{vnum2};
            
            if terminfo.isCatVar(vnum2)
                % Compute fitted values for each level of this predictor
                [~,xlabels2] = grp2idx(xdata2);
                ngrid = length(xlabels2);
                xi2 = (1:ngrid)';
            else
                % Define a grid of values
                ngrid = 3;
                xi2 = linspace(min(xdata2),max(xdata2),ngrid)';
            end
            
            xi = [repmat(xi1(1),ngrid,1) xi2; ...
                repmat(xi1(2),ngrid,1) xi2];
            
            % Compute adjusted fitted values as a function of this
            % predictor
            [fxi,fxiVar] = getAdjustedResponse(model,[vnum1 vnum2],xi,terminfo);
            
            % Compute conditional effect for predictor 1, its standard error, and its label
            effect = fxi(ngrid+1:2*ngrid) - fxi(1:ngrid);
            fxiVarDiag = diag(fxiVar);
            fxiCov = diag(fxiVar(1:ngrid,ngrid+1:2*ngrid));
            effectSE = sqrt(max(fxiVarDiag(1:ngrid) + fxiVarDiag(ngrid+1:2*ngrid) - 2*fxiCov,0));
            if terminfo.isCatVar(vnum2)
                effectName = strcat(sprintf('%s=',vname2),xlabels2(:));
            else
                effectName = {sprintf('%s=%g',vname2,xi2(1)); ...
                    sprintf('%s=%g',vname2,xi2(2)); ...
                    sprintf('%s=%g',vname2,xi2(3))};
            end
        end
    end % hidden public
    
    methods(Static,Hidden)
        function obj = fromStruct(s)
            % Make a CompactLinearModel object from a codegen struct.
            
            
            s = classreg.regr.coderutils.structToRegr(s);
            if ~isempty(s.Robust)
                fh = str2func(s.Robust.RobustWgtFun);
                fhInfo = functions(fh);
                if strcmpi(fhInfo.type,'anonymous')
                    warning(message('stats:classreg:loadCompactModel:LinearModelRobustWgtFunReset'));    
                    s.Robust = [];
                else
                    s.Robust.RobustWgtFun = fh; 
                end
            end
            obj = classreg.regr.CompactLinearModel.make(s);
        end
    end     
    methods(Static, Access='public', Hidden)
        
        function model = make(s)
            model = classreg.regr.CompactLinearModel();
            if isa(s,'struct')
                % Take a struct of field names. This is a hidden method and
                % we rely on the caller to supply all required fields.
                fn = fieldnames(s);
            elseif isa(s,'classreg.regr.CompactLinearModel')
                % Copying one of these or casting a subclass to the parent.
                meta = ?classreg.regr.CompactLinearModel;
                props = meta.PropertyList;
                props([props.Dependent] | [props.Constant]) = [];
                fn = {props.Name};
            end
            for j = 1:length(fn)
                name = fn{j};
                model.(name) = s.(name);
            end
            model.MSE = model.SSE / model.DFE;
            if ~isempty(model.Robust)
                model.Robust.Weights = [];
            end
        end
    end % static public hidden

    methods(Access=private, Static)
        function name = matlabCodegenRedirect(~)
            name = 'classreg.regr.coder.CompactLinearModel';
        end
    end     
    
end

% ----------------------------------------------------------------------------
function [ypred, yci] = predci(X,beta,Sigma,mse,dfe,alpha,sim,pred,hasintercept)

% Compute the predicted values at the new X.
ypred = X * beta;

if nargout > 1 % Calculate confidence interval
    
    if (pred) % prediction interval for new observations
        varpred = sum((X*Sigma) .* X,2) + mse;
    else % confi interval for fitted curve
        varpred = sum((X*Sigma) .* X,2);
    end
    
    if (sim) % simultaneous
        if (pred)
            % For new observations.
            if (hasintercept)
                % Jacobian has constant column.
                sch = length(beta);
            else
                % Need to use a conservative setting.
                sch = length(beta) + 1;
            end
        else
            % For fitted curve.
            sch = length(beta);
        end
        crit = sqrt(sch * finv(1-alpha, sch, dfe));
    else % pointwise
        crit = tinv(1-alpha/2,dfe);
    end
    delta = sqrt(varpred) * crit;
    yci = [ypred-delta ypred+delta];
end
end



function sstype  = getSSType(sstype)
if isscalar(sstype) && isnumeric(sstype) && ismember(sstype,1:3)
    return
end
if isscalar(sstype) && ischar(sstype)
    [tf,loc] = ismember(lower(sstype),'123h');
    if tf
        ok = {1 2 3 'h'};
        sstype = ok{loc};
        return
    end
end
throwAsCaller(MException(message('stats:anovan:BadSumSquares')))
end

function [T,catvars,levels,terms] = getPredictorTable(model)
% Get a table of predictors, with values chosen so that the design matrix
% has full rank and minimal number of rows. This means we must choose
% predictor values so that each term can be estimated. The general idea is
% to start with a base value for each predictor, and introduce new values
% as required by each term.

% Find predictors among the variables originally specified
[~,predLocs] = ismember(model.PredictorNames,model.VariableNames);
nvars = length(predLocs);

% Get model info, for predictors only
catvars = model.VariableInfo.IsCategorical(predLocs);
levels = model.VariableInfo.Range(predLocs);
terms = model.Formula.Terms(:,predLocs);

% Get the df and set of levels to use for each variable. The df is
%    L-1 for a categorical variable with L levels
%    1   for a continuous variable
vardf = ones(nvars,1);
for jVar=1:nvars
    levj = levels{jVar};
    if ~ischar(levj)
        levj = levj(:);
    end
    if catvars(jVar)
        % Degrees of freedom for a categorical term. We already have the
        % set of levels to use.
        vardf(jVar) = size(levj,1)-1;
    else
        % Update the levels to use for this predictor, using enough to
        % estimate the terms in the model. We already know df=1.
        maxpower = max(terms(:,jVar));
        levels{jVar} = linspace(min(levj),max(levj),max(2,maxpower+1))';
    end
end

% Find out the number of degrees of freedom for each term. This is the
% product of the df for each variable contained in it.
nterms = size(terms,1);
termdf = ones(nterms,1);
for kTerm = 1:nterms
    t = terms(kTerm,:)>0;
    termdf(kTerm) = prod(vardf(t));
end
totdf = sum(termdf);

% Create output table
T = table();
for jVar=1:nvars
    levj = levels{jVar};
    if ~ischar(levj)
        levj = levj(:);
    end
    column = repmat(levj(1,:),totdf,1);        % column for this predictor
    nextrow = 1;
    for kTerm = 1:nterms
        dfk = termdf(kTerm);
        allrows = nextrow - 1 + (1:dfk);     % all rows for this term
        tj = terms(kTerm,:);                 % definition for this term
        if tj(jVar)>0
            if catvars(jVar)
                % We started with the first level of each categorical
                % variable. Here we introduce the other levels for all
                % categorical variables involved in this term. Suppose the
                % term is A*B*C*D*E and we are considering C. This term
                % needs all combinations of levels of the categorical
                % predictors, except the first level. Let n(C) be the
                % number of levels of C. Then we need
                %    (n(A)-1)*(n(B)-1) * (n(C)-1) * (n(D)-1)*(n(E)-1)
                % values. The variables below are defined so that
                %    repeat1 is the number of values for A*B
                %    indices is the set of values for C
                %    repeat2 is the number of values for D*E
                % The values are arranged so that A varies fastest, then B,
                % and so on.
                usedvars = tj>0;
                termvardf = vardf;
                termvardf(~usedvars) = 1;
                repeat1 = prod(termvardf(1:jVar-1));
                repeat2 = prod(termvardf(jVar+1:end));
                indices = repmat(2:(1+vardf(jVar)),repeat1,repeat2);
                indices = indices(:);
                column(allrows,:) = levj(indices,:);
            else
                % We started with the lowest level for the constant term
                % and other terms that do not contain this variable. For a
                % term of degree D, use level D+1.
                column(allrows,:) = levj(tj(jVar)+1,:);
            end
        end
        nextrow = nextrow + dfk;
    end
    T.(model.PredictorNames{jVar}) = column; % put column into table
end

end

function [ss,df] = getTermSS1(termcols,dfbefore,R,mse,b,V,Qy,Rtol)
% Compute SS and DF for term or terms in specific cols
if size(R,1)==dfbefore && mse>0
    % This is a full-rank model, so we can compute sums of squares using
    % the coefficient estimates and their covariance.
    b = b(termcols);
    b = b(:);                          % need column vector even if empty
    V = V(termcols,termcols);
    ss = b'*(V\b) * mse;
    df = length(b);
else
    % This is a reduced-rank model with some coefficients artificially set
    % to zero and their variances set to zero. We have to operate on the R
    % matrix to compute the degrees of freedom and sum of squares.
    % If X is n-by-p, this reduces the problem to p-by-p.
    
    % Refactor R so q spans remaining space. df is the number of independent
    % columns. Error SS is the SS from the orthogonal part
    [q,r,~] = qr(R(:,~termcols));
    if isvector(r)
        dfafter = any(r);
    else
        dfafter = sum(abs(diag(r)) > Rtol);
    end
    ss = norm(Qy'*q(:,dfafter+1:end))^2;
    df = dfbefore - dfafter;
end
end

function [coefs,coefcov,R,Qy] = applyEffectsCoding(model)

% Get predictor table suitable for distinguishing term effects
[T,catvars,catlevels,terms] = getPredictorTable(model);

% Get standard design matrix using reference coding
coding = model.DummyVarCoding;
X1 = classreg.regr.modelutils.designmatrix(T,'Model',terms, ...
    'DummyVarCoding',coding, ...
    'CategoricalVars',catvars, ...
    'CategoricalLevels',catlevels);

% Get design matrix using effects coding
X2 = classreg.regr.modelutils.designmatrix(T,'Model',terms, ...
    'DummyVarCoding','effects', ...
    'CategoricalVars',catvars, ...
    'CategoricalLevels',catlevels);

% Get coefficient estimates and covariance matrix for effects coding
H = X2\X1;
coefs = H*model.Coefficients.Estimate;
coefcov = H*model.CoefficientCovariance*H';

if nargout>2
    R = model.R/H;
    Qy = model.Qy;
end
end
        
