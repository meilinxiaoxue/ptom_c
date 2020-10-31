classdef CompactPartitionedModel < classreg.learning.internal.DisallowVectorOps

%   Copyright 2015 The MathWorks, Inc.

    properties(GetAccess=protected,SetAccess=protected)
        PartitionedModel;
        PrivGenerator;
    end
    
    properties(GetAccess=public,SetAccess=protected,Hidden=true)
        ModelParams;
    end
    
    properties(GetAccess=public,SetAccess=protected,Hidden=true,Dependent=true)
        Ensemble;
    end
    
    properties(GetAccess=public,SetAccess=protected)
        %CrossValidatedModel Name of the cross-validated model.
        %   The CrossValidatedModel is a string with the name of the
        %   cross-validated model, for example, 'Tree' for a cross-validated
        %   decision tree.
        %
        %   See also classreg.learning.partition.CompactPartitionedModel.
        CrossValidatedModel;
        
        %NumObservations Number of observations.
        %   The NumObservations property is a numeric positive scalar showing the
        %   number of observations in the training data.
        %
        %   See also classreg.learning.partition.CompactPartitionedModel.
        NumObservations;
        
        %Y Y data used to cross-validate this model.
        %   The Y property is an array of true class labels for classification, or
        %   response values for regression. For classification, Y is of the same
        %   type as the passed-in Y data: a cell array of strings, categorical,
        %   logical, numeric or a character matrix. For regression, Y is a numeric
        %   vector.       
        %
        %   See also classreg.learning.partition.CompactPartitionedModel.
        Y;
        
        %W Weights of observations used to cross-validate this model.
        %   The W property is a numeric vector of size N, where N is the number of
        %   observations.
        %
        %   See also classreg.learning.partition.CompactPartitionedModel.
        W;
    end
    
    properties(GetAccess=public,SetAccess=protected,Dependent=true)
        %PredictorNames Names of predictors used for this model.
        %   The PredictorNames is a cell array of strings with names of predictor
        %   variables, one name per column of X.
        %
        %   See also classreg.learning.partition.CompactPartitionedModel.
        PredictorNames;
        
        %CategoricalPredictors Indices of categorical predictors.
        %   The CategoricalPredictors property is an array with indices of
        %   categorical predictors. The indices are in the range from 1 to the
        %   number of columns in X.
        %
        %   See also classreg.learning.partition.CompactPartitionedModel.
        CategoricalPredictors;

        %ResponseName Name of the response variable.
        %   The ResponseName is a string with the name of the response variable Y.
        %
        %   See also classreg.learning.partition.CompactPartitionedModel.
        ResponseName;
        
        %Trained Compact models trained on cross-validation folds.
        %   The Trained property is a cell array of models trained on
        %   cross-validation folds.        
        %
        %   See also classreg.learning.partition.CompactPartitionedModel.
        Trained;

        %KFold Number of cross-validation folds.
        %   The KFold property is a positive integer showing on how many folds this
        %   model has been cross-validated.
        %
        %   See also classreg.learning.partition.CompactPartitionedModel.
        KFold;
        
        %Partition Data partition used to cross-validate this model.
        %   The Partition property is an object of type cvpartition specifying how
        %   the data are split into cross-validation folds.        
        %
        %   See also classreg.learning.partition.CompactPartitionedModel.
        Partition;
        
        %ModelParameters Cross-validation parameters.
        %   The ModelParameters property holds parameters used for cross-validating
        %   this model.        
        %
        %   See also classreg.learning.partition.CompactPartitionedModel.
        ModelParameters;
    end
    
    methods(Abstract)
        varargout = kfoldPredict(this,varargin)
        err = kfoldLoss(this,varargin)
    end

    methods
        function pnames = get.PredictorNames(this)
            pnames = this.PartitionedModel.PredictorNames;
        end
        
        function catpred = get.CategoricalPredictors(this)
            catpred = this.PartitionedModel.CategoricalPredictors;
        end
        
        function resp = get.ResponseName(this)
            resp = this.PartitionedModel.ResponseName;
        end
        
        function trained = get.Trained(this)
            trained = this.PartitionedModel.Trained;
        end
        
        function kfold = get.KFold(this)
            kfold = this.PartitionedModel.KFold;
        end
        
        function p = get.Partition(this)
            p = this.PrivGenerator.Partition;
        end
        
        function ens = get.Ensemble(this)
            ens = this.PartitionedModel.Ensemble;
        end
        
        function mp = get.ModelParameters(this)
            mp = this.ModelParams;
        end
    end
    
    methods(Access=protected)
        function this = CompactPartitionedModel()
            this = this@classreg.learning.internal.DisallowVectorOps();
        end
        
        function s = propsForDisp(this,s)
            if nargin<2 || isempty(s)
                s = struct;
            else
                if ~isstruct(s)
                    error(message('stats:classreg:learning:partition:PartitionedModel:propsForDisp:BadS'));
                end
            end
            s.CrossValidatedModel   = this.CrossValidatedModel;
            s.PredictorNames        = this.PredictorNames;
            if ~isempty(this.CategoricalPredictors)
                s.CategoricalPredictors = this.CategoricalPredictors;
            end
            s.ResponseName          = this.ResponseName;
            s.NumObservations       = this.NumObservations;
            s.KFold                 = this.KFold;
            s.Partition             = this.Partition;
        end
    end
       
    methods(Hidden)
        function disp(this)
            internal.stats.displayClassName(this);
            
            % Display body
            s = propsForDisp(this,[]);
            disp(s);
            
            internal.stats.displayMethodsProperties(this);
        end
    end
    

end
