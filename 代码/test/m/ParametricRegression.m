classdef (AllowedSubclasses = {?classreg.regr.TermsRegression, ?NonLinearModel, ?LinearMixedModel, ?GeneralizedLinearMixedModel, ?classreg.regr.LinearLikeMixedModel}) ParametricRegression < classreg.regr.Predictor & classreg.regr.CompactParametricRegression
%ParametricRegression Fitted statistical parametric regression.
%   ParametricRegression is an abstract class representing a fitted
%   parametric regression model. You cannot create instances of this class
%   directly.  You must create a derived class by calling the fit method of
%   a derived class such as LinearModel, GeneralizedLinearModel, or
%   NonLinearModel.
%
%   See also LinearModel, GeneralizedLinearModel, NonLinearModel.

%   Copyright 2011-2015 The MathWorks, Inc.    

    properties(Dependent,GetAccess='protected',SetAccess='protected')
         % "Working" values - created and saved during fit, but subject to
        % being cleared out and recreated when needed
        y_r % reduced, i.e. y(Subset)
        w_r % reduced and not normalized, i.e. Weights(Subset)
    end
    
    methods % get/set methods
        function y_r = get.y_r(model)
            if isempty(model.WorkingValues)
                y_r = create_y_r(model);
            else
                y_r = model.WorkingValues.y_r;
            end
        end
        function w_r = get.w_r(model)
            if isempty(model.WorkingValues)
                w_r = create_w_r(model);
            else
                w_r = model.WorkingValues.w_r;
            end
        end
    end % get/set methods
    
    methods(Hidden,Access='public') 
        function [varargout] = subsref(a,s)
            switch s(1).type
                case '()'
                    [varargout{1:nargout}] = subsref@classreg.regr.Predictor(a,s);
                case '{}'
                    [varargout{1:nargout}] = subsref@classreg.regr.Predictor(a,s);
                case '.'
                    % Look ahead so that references such as fit.Residuals.Response do not
                    % require creating all of fit.Residuals.  Let the built-in handle other
                    % properties.
                    propMethodName = s(1).subs;
                    if isequal(propMethodName,'Residuals')
                        [varargout{1:nargout}] = lookAhead(s,@a.get_residuals);
                    elseif isequal(propMethodName,'Fitted')
                        [varargout{1:nargout}] = lookAhead(s,@a.get_fitted);
                    elseif isequal(propMethodName,'Diagnostics')
                        [varargout{1:nargout}] = lookAhead(s,@a.get_diagnostics);
                    else
                        [varargout{1:nargout}] = subsref@classreg.regr.CompactParametricRegression(a,s);
                    end
            end
        end
    end % hidden public
            

    methods(Access='protected')

        % --------------------------------------------------------------------
        function model = selectObservations(model,exclude,missing)
            if nargin < 3
                missing = [];
            end
            model = selectObservations@classreg.regr.Predictor(model,exclude,missing);
            
            % Populate the y_r and w_r fields in the WorkingValues structure
            model.WorkingValues.y_r = create_y_r(model);
            model.WorkingValues.w_r = create_w_r(model);
        end
            
        % --------------------------------------------------------------------
        function model = postFit(model)
            model = postFit@classreg.regr.Predictor(model);
            subset = model.ObservationInfo.Subset;
            resid_r = get_residuals(model,'raw');
            resid_r = resid_r(subset);
            yfit_r = predict(model);
            yfit_r = yfit_r(subset);
            W_r = model.w_r;
            sumw = sum(W_r);
            wtdymean = sum(W_r.*model.y_r) / sumw;
            model.SSE = sum(W_r .* resid_r.^2);
            model.SSR = sum(W_r .* (yfit_r - wtdymean).^2);
            model.SST = sum(W_r .* (model.y_r - wtdymean).^2);
            model.LogLikelihood = getlogLikelihood(model);
            model.LogLikelihoodNull = logLikelihoodNull(model);
        end
        
        % --------------------------------------------------------------------
        function y_r = create_y_r(model)
            subset = model.ObservationInfo.Subset;
            y = getResponse(model);
            y_r = y(subset);
        end
        function w_r = create_w_r(model)
            subset = model.ObservationInfo.Subset;
            w_r = model.ObservationInfo.Weights(subset);
        end
    end % protected
    
    methods(Abstract, Access='protected')
        model = fitter(model)% subclass-specific fitting algorithm, must fill in Coefs, CoefficientCovariance, and DFE
        L0 = logLikelihoodNull(model)
    end % protected
    methods(Abstract, Static, Access='public')
        model = fit(varargin)
    end % public
end

function b = lookAhead(s,accessor)
if ~isscalar(s) && isequal(s(2).type,'.')
    subs = s(2).subs;
    if strcmp(subs,'Properties')
        b = accessor(); % a table array with non-variable reference
        s = s(2:end);
    else
        b = accessor(subs); % a vector
        s = s(3:end);
    end
else
    b = accessor(); % a table array
    s = s(2:end);
end
if ~isempty(s)
    b = subsref(b,s); 
end
end


