classdef CompactRegressionPartitionedModel < classreg.learning.partition.CompactPartitionedModel

%   Copyright 2015 The MathWorks, Inc.    
    
    properties(GetAccess=protected,SetAccess=protected)
        PrivYhat;
    end
    
    properties(GetAccess=public,SetAccess=public,Dependent=true)
        %ResponseTransform Transformation applied to predicted regression response.
        %   The ResponseTransform property is a string describing how raw
        %   regression response predicted by the model is transformed. You can
        %   assign a function handle or one of the following strings to this
        %   property: 'none', 'doublelogit', 'identity', 'invlogit', 'ismax',
        %   'logit', 'sign', 'symmetricismax', 'symmetriclogit', and 'symmetric'.
        %   You can use either 'identity' or 'none' for the identity
        %   transformation.
        %
        %   See also classreg.learning.partition.CompactRegressionPartitionedModel
        ResponseTransform;
    end
       
    methods
        function rt = get.ResponseTransform(this)
            rt = this.PartitionedModel.ResponseTransform;
        end
        
        function this = set.ResponseTransform(this,rt)
            this.PartitionedModel.ResponseTransform = rt;
        end        
    end
    
    
    methods(Access=protected)
        function s = propsForDisp(this,s)
            s = propsForDisp@classreg.learning.partition.CompactPartitionedModel(this,s);
            s.ResponseTransform = this.ResponseTransform;
        end
    end
    
    
    methods(Hidden)
        function this = CompactRegressionPartitionedModel(...
                X,Y,W,modelParams,dataSummary,responseTransform)
            this = this@classreg.learning.partition.CompactPartitionedModel();
            
            pm = classreg.learning.partition.RegressionPartitionedModel(...
                X,Y,W,modelParams,dataSummary,responseTransform);
            
            % Need to fill this.PartitionedModel here to make the response
            % method work.
            this.PartitionedModel = pm;

            if dataSummary.ObservationsInRows
                this.NumObservations = size(pm.Ensemble.X,1);
            else
                this.NumObservations = size(pm.Ensemble.X,2);
            end
            this.PrivGenerator = pm.Ensemble.ModelParams.Generator;
            
            this.PrivYhat = response(this);
            
            this.Y = pm.Ensemble.Y;
            this.W = pm.Ensemble.W;
            
            this.ModelParams = pm.Ensemble.ModelParams;

            this.PartitionedModel = compactPartitionedModel(pm);   
        end
    end
    
    
    methods(Access=protected,Abstract=true)
        r = response(this)
    end
        
end
