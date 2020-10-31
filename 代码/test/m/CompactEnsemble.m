classdef CompactEnsemble %#codegen
    
    %CompactEnsemble Base class for code generation compatible Ensemble models 
    % Defined properties and implements functions common to all Ensemble models
    
    % Copyright 2017 The MathWorks, Inc.
    
    
    properties(GetAccess=public,SetAccess=protected,Hidden=true)
           
        %LEARNERS Weak learners.
        Learners;
        
        %NUMTRAINED Number of weak learners.
        NumTrained;
        
        %ISCACHED  Cached matrix for learners.
        IsCached;
        
        %LEARNERWEIGHTS  Weights for weak learners.
        LearnerWeights;
             
        %COMBINERCLASS Class of the Combiner.
        CombinerClass;
        
        %USEOREDFORLEARNER Logical matrix indicating which predictors are
        %to be used for each learner
        % all true for any method except subspace
        UsePredForLearner;

    end
    
    methods(Access=protected)
        
        function obj = CompactEnsemble(cgStruct)
            
            coder.internal.prefer_const(cgStruct);
            
            % validate struct fields
            validateFields(cgStruct);
            
            % Assign all the required variables from cgStruct           
            obj.NumTrained = cast(cgStruct.NumTrained,'uint32');
            obj.Learners = cgStruct.Impl.Trained;
            obj.CombinerClass = cgStruct.Impl.CombinerClass;
            obj.LearnerWeights = cgStruct.Impl.Combiner.LearnerWeights;
            obj.IsCached = cgStruct.Impl.Combiner.IsCached;
            obj.UsePredForLearner = cgStruct.UsePredForLearner;
            
   
        end
        
        function ensemblePredictValidateNumTrained(obj,X,T)
            
            coder.internal.prefer_const(obj);
            
            classreg.learning.coderutils.checkSupportedNumeric('X',X,false,false);

            coder.internal.errorIf(obj.NumTrained~=T  ,'stats:classreg:learning:ensemble:CompactEnsemble:checkAggregateArgs:BadLogicalIndices',T);
        end       

        function score = ensemblePredict(obj,X,score,doclass,classifbybinregr,classnames,nonzeroprobclasses,varargin)      
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

            [N,D] = size(X);
            
            % Using same error from CompactSVM.
            coder.internal.errorIf( ~coder.internal.isConst(D) || D~=obj.NumPredictors,...
                 'stats:classreg:learning:impl:CompactSVMImpl:score:BadXSize', obj.NumPredictors); 
             
            T = length(fieldnames(obj.Learners));
            % Parse PV pairs and validate
            [learnersall, useobsforlearner] = parseOptionalInputs(obj,coder.internal.indexInt(N),coder.internal.indexInt(T),varargin{:});            
            validateLearners(learnersall);
            
            if islogical(learnersall)
                coder.internal.assert(coder.internal.isConst(isvector(learnersall)) && isvector(learnersall) && coder.internal.isConst(length(learnersall)==coder.internal.indexInt(T)) && length(learnersall)==coder.internal.indexInt(T)  ,'stats:classreg:learning:ensemble:CompactEnsemble:checkAggregateArgs:BadLogicalIndices',coder.internal.indexInt(T));  
                learnerIndices = learnersall(:);
            else
                coder.internal.errorIf(any(any(learnersall > obj.NumTrained,2),1) || any(any(learnersall < 1,2),1)  ,'stats:classreg:learning:ensemble:CompactEnsemble:checkAggregateArgs:BadNumericIndices',obj.NumTrained);
                learnerIndices = false(coder.internal.indexInt(T),1);
                learnerIndices(learnersall) = true;
            end
            
            validateUseObsForLearner(useobsforlearner);
            
            coder.internal.errorIf(any(size(useobsforlearner) ~= [coder.internal.indexInt(N),coder.internal.indexInt(T)]),'stats:classreg:learning:ensemble:CompactEnsemble:aggregatePredict:UseObsForIter',coder.internal.indexInt(N),coder.internal.indexInt(T));
            
            if isempty(obj.UsePredForLearner)
                usepredforlearner = true(coder.internal.indexInt(D),coder.internal.indexInt(T));
            else
                usepredforlearner = obj.UsePredForLearner;
            end

            score = classreg.learning.coder.ensembleutils.aggregatePredict(X,score,obj.CombinerClass,obj.Learners,classifbybinregr,obj.LearnerWeights,obj.IsCached,...
                classnames,nonzeroprobclasses,...
                usepredforlearner,learnerIndices,useobsforlearner,doclass);         
        end
    end
    
    methods (Static, Access = protected)

        function posterior = ensemblePredictEmptyX(Xin,K,numPredictors)
            % ensemblePredictEmptyX prediction for empty data
            
            Dpassed = size(Xin,2);
            str = 'columns';
            
            coder.internal.errorIf(~coder.internal.isConst(coder.internal.indexInt(Dpassed)) || coder.internal.indexInt(Dpassed)~=numPredictors,...
                'stats:classreg:learning:classif:ClassificationModel:predictEmptyX:XSizeMismatch', numPredictors, str);
            
            posterior = repmat(coder.internal.nan(1,1),0,K);
        end
        
    end
     
    methods(Static, Hidden)
        function props = matlabCodegenNontunableProperties(~)
            props = {'NumTrained','Learners','CombinerClass','UsePredForLearner'};
        end
    end
end

function [learners,useObsForLearner] = parseOptionalInputs(obj,N,T,varargin)
% PARSEOPTIONALINPUTS  Parse optional PV pairs
%
% 'learners', 'UseObsForLearner'

coder.inline('always');
coder.internal.prefer_const(varargin);

params = struct( ...
    'learners', uint32(0), ...
    'UseObsForLearner',     uint32(0));

popts = struct( ...
    'CaseSensitivity', false, ...
    'StructExpand',    true, ...
    'PartialMatching', true);

optarg           = eml_parse_parameter_inputs(params, popts, ...
    varargin{:});
learners   = eml_get_parameter_value(...
    optarg.learners, (1:obj.NumTrained)', varargin{:});
useObsForLearner         = eml_get_parameter_value(...
    optarg.UseObsForLearner,true(N,T), varargin{:});

end


function validateFields(cgStruct)
% Validate fields specific to Ensemble models

coder.inline('always');

% Validate NumTrained
validateattributes(cgStruct.NumTrained,{'double','single'},...
    {'positive','integer','nonnan','finite','real','nonempty'},mfilename,'NumTrained');


% Validate Impl Parameters
validatestring(cgStruct.Impl.CombinerClass,{'WeightedSum','WeightedAverage'},mfilename,'CombinerClass');
validateattributes(cgStruct.Impl.Combiner.LearnerWeights,{'double','single'},{'nonnegative','nonnan','finite','real','size',[cgStruct.NumTrained,1]},mfilename,'LearnerWeights');
validateattributes(cgStruct.Impl.Combiner.IsCached,{'logical'},{'size',[cgStruct.NumTrained,1]},mfilename,'IsCached');

if ~isempty(cgStruct.UsePredForLearner)
    validateattributes(cgStruct.UsePredForLearner,{'logical'},{'size',[cgStruct.DataSummary.NumPredictors,cgStruct.NumTrained]},mfilename,'UsePredForLearner');
end

end

function validateLearners(learners)
% Validate Learners input 
if isnumeric(learners)
    validateattributes(learners,{'double','single','uint32'},{'nonempty','nonnan','finite','integer','real'},mfilename,'learners');
else
    validateattributes(learners,{'logical'},{'nonempty','nonnan','finite','real'},mfilename,'learners');
end

end


function validateUseObsForLearner(useobsforlearner)
% Validate UseObsForLearner input 
validateattributes(useobsforlearner,{'logical'},{'nonempty'},mfilename,'UseObsForLearner');

end

