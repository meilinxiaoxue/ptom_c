classdef CompactRegressionEnsemble <  classreg.learning.coder.model.CompactEnsemble...
                                    & classreg.learning.coder.regr.CompactRegressionModel 
    
    %#codegen
    
    %CompactRegressionEnsemble Compact regression ensemble.
    %   CompactRegressionEnsemble is a set of trained weak learner models.
    %   It can predict ensemble response for new data by aggregating
    %   predictions from its weak learners.
    
    %   Copyright 2017 The MathWorks, Inc.
    
    
    methods(Access=protected)
        
        function obj = CompactRegressionEnsemble(cgStruct)
            
            coder.internal.prefer_const(cgStruct);

            % call base class constructors
            obj@classreg.learning.coder.regr.CompactRegressionModel(cgStruct);
            obj@classreg.learning.coder.model.CompactEnsemble(cgStruct); 
   
        end
        
    end
    
    methods
        function score = predict(obj,X,varargin)
            %PREDICT Predict response of the ensemble.
            %   [LABEL,SCORE]=PREDICT(ENS,X) returns predicted class labels and scores
            %   for classification ensemble and predictors X. X must be a table if ENS
            %   was originally trained on a table, or a numeric matrix if ENS was
            %   originally trained on a matrix. If X is a table, it must contain all
            %   the predictors used for training this model. If X is a matrix, it must
            %   have P columns, where P is the number of predictors used for training.
            %   Classification labels LABEL have the same type as Y used for training.
            %   Scores SCORE are an N-by-K numeric matrix for N observations and K
            %   classes. High score value indicates that an observation likely comes
            %   from this class.
            %
            %   [LABEL,SCORE]=PREDICT(ENS,X,'PARAM1',val1,'PARAM2',val2,...) specifies
            %   optional parameter name/value pairs:
            %       'useobsforlearner' - Logical matrix of size N-by-NumTrained, where
            %                            N is the number of observations in X and
            %                            NumTrained is the number of weak learners.
            %                            This matrix specifies what learners in the
            %                            ensemble are used for what observations. By
            %                            default, all elements of this matrix are set
            %                            to true.
            %       'learners'         - Indices of weak learners in the ensemble
            %                            ranging from 1 to NumTrained. Only these
            %                            learners are used for making predictions. By
            %                            default, all learners are used.
            %
            %   See also CompactClassificationEnsemble.
            narginchk(2,Inf)
            coder.internal.prefer_const(obj);
            obj.validateX(X);           
            T = length(fieldnames(obj.Learners));
            
            ensemblePredictValidateNumTrained(obj,X,coder.internal.indexInt(T));
            
            % Get scores from the implementation
            if isempty(X)
                score = predictEmptyX(obj,X);
                return;
            end          
           
            [N,~] = size(X);

            doclass = false; 
            score = coder.internal.nan(coder.internal.indexInt(N),1);
            score = ensemblePredict(obj,X,score,doclass,[],[],[],varargin{:});
            
            % Transform scores   
            if ~isempty(obj.ResponseTransform)
                score = obj.ResponseTransform(score);
            end

            
        end
    end
    
    methods(Hidden, Access = protected)
        function yfit = predictEmptyX(obj,X)
        % PREDICTEMPTYX predict for empty data
            numPredictors = obj.NumPredictors; 
            yfit = classreg.learning.coder.model.CompactEnsemble.ensemblePredictEmptyX(X,1,numPredictors);
        end
    end    

    methods (Static)
        function obj = fromStruct(cgStruct)
            %FROMSTRUCT  Construct a SVM model from struct.
            %    OBJ = FROMSTRUCT(CGSTRUCT) constructs a
            %    classreg.learning.coder.CompactClassificationEnsemble object
            %    from a struct created using toStruct().
            
            coder.internal.prefer_const(cgStruct);
            coder.inline('always');
            obj = classreg.learning.coder.regr.CompactRegressionEnsemble(cgStruct);
        end
    end
    
    methods(Static, Hidden)
        function props = matlabCodegenNontunableProperties(~)
            propstemp1 = classreg.learning.coder.regr.CompactRegressionModel.matlabCodegenNontunableProperties;
            propstemp2 = classreg.learning.coder.model.CompactEnsemble.matlabCodegenNontunableProperties;
            props = [propstemp1,propstemp2];
        end
    
        function out = matlabCodegenToRedirected(obj)
            % static method to return equivalent the target
            % MCOS instance class i.e. this class object,
            % for the given source MCOS instance.
            tt = toStruct(obj);
            out = classreg.learning.coder.regr.CompactRegressionEnsemble.fromStruct(coder.const(tt));   
        end  
        
    end
   

end





