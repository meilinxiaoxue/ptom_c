classdef CompactTree     %#codegen
    
    %CompactSVM Base class for code generation compatible Tree models 
    % Defined properies and implements functions common to all Tree models
    
    % Copyright 2017 The MathWorks, Inc.
      
    properties (SetAccess=protected,GetAccess=public)


        % The feature variable that is used to cut the variable at a given values.
        CutVar;
        
        % Provides a matrix representing the tree structure. Child nodes for tree nodes.
        Children;
        
        % The class probabilities are the estimated probabilities for each class
        % for a point satisfying the conditions for node I.
        ClassProb;
        
        % Points for splits on continuous predictors.
        CutPoint;
        
        % The PruneList property is an N-element numeric vector with the pruning
        % levels in each node of tree, where N is the number of nodes.
        PruneList;
          
    end    
    methods (Access=protected)
        function obj = CompactTree(cgStruct)
            % COMPACTSVM constructor that takes a struct
            %    representing the CompactClassificationObject as an input
            %    and parses to get SVM parameters.
            
            coder.internal.prefer_const(cgStruct);
            
            % validate struct fields
            validateFields(cgStruct);
            
            obj.CutPoint            = cgStruct.Impl.CutPoint;
            obj.CutVar              = cast(cgStruct.Impl.CutVar,'like',cgStruct.Impl.CutPoint);
            obj.Children            = cast(cgStruct.Impl.Children','like',cgStruct.Impl.CutPoint);
            obj.ClassProb           = cast(cgStruct.Impl.ClassProb,'like',cgStruct.Impl.CutPoint);           
            obj.CutPoint(cgStruct.NanCutPoints) = cast(coder.internal.nan,'like',cgStruct.Impl.CutPoint);
            obj.CutPoint(cgStruct.InfCutPoints) = cast(coder.internal.inf,'like',cgStruct.Impl.CutPoint);            
            obj.PruneList           = cast(cgStruct.Impl.PruneList,'like',cgStruct.Impl.CutPoint);



        end
    end

    methods (Access = protected)


        function n = findNode(obj,X,subtrees)
            
            p = coder.internal.indexInt(size(X,2));
             
             coder.internal.errorIf( ~coder.internal.isConst(p) || p~=obj.NumPredictors,...
                 'stats:classreg:learning:impl:TreeImpl:findNode:BadXSize', obj.NumPredictors);            
            % Call to treeutils findNode to get the nodes for the
            % observations
            n = classreg.learning.coder.treeutils.findNode(X,...
                subtrees,obj.PruneList,...
                obj.Children,obj.CutVar, obj.CutPoint);
        end      
    end
    
    methods (Static, Access = protected)
        
        function posterior = treePredictEmptyX(Xin,K,numPredictors)

            Dpassed = coder.internal.indexInt(size(Xin,2));
            str = 'columns';
            
            coder.internal.errorIf(~coder.internal.isConst(Dpassed) || Dpassed~=numPredictors,...
                'stats:classreg:learning:classif:ClassificationModel:predictEmptyX:XSizeMismatch', numPredictors, str);
            
            posterior = repmat(coder.internal.nan(1,1,'like',Xin),0,K);
        end
        
        function subtrees = extractSubtrees(PruneList,varargin)
            
            % Get subtrees - ParsePV pairs
            subtreesInput = predictParseInputs(varargin{:});
            
            % Check subtrees
            subtrees = classreg.learning.coder.model.CompactTree.processSubtrees(PruneList,subtreesInput);            
        end        
        
        function subtrees = processSubtrees(PruneList,subtreesInput)
            
            % Validate Parsed Inputs
            validateSubtrees(subtreesInput);
            coder.internal.errorIf((~strcmpi(subtreesInput,'all') && ...
                (~isnumeric(subtreesInput) || ~isvector(subtreesInput) ...
                || any(any(subtreesInput<0,2),1) || any(any(diff(subtreesInput,1,1)<0,2),1)...
                || any(any(diff(subtreesInput,1,2)<0,2),1) )),...
                'stats:classreg:learning:impl:TreeImpl:processSubtrees:BadSubtrees');
            
            if isempty(PruneList)
                subtreesisValid = isscalar(subtreesInput) && all(subtreesInput == 0);
                coder.internal.errorIf(~subtreesisValid,...
                    'stats:classreg:learning:impl:TreeImpl:processSubtrees:NoPruningInfo');
                subtrees = cast(subtreesInput,'uint32');
                return;
            else 
                if ischar(subtreesInput)
                    subtreesall = cast(min(PruneList):max(PruneList),'uint32');
                    subtrees = subtreesall;
                else
                    subtrees = subtreesInput; 
                end
                coder.internal.errorIf(subtrees(end)>max(PruneList),...
                    'stats:classreg:learning:impl:TreeImpl:processSubtrees:SubtreesTooBig');
            end
        end        
    end
    
    methods (Static, Hidden)
        function props = matlabCodegenNontunableProperties(~)
            props = {'PruneList'};
        end        
    end  
end

function subtrees = predictParseInputs(varargin)
%PARSEINPUTS Parse optional PV Pairs
%
% Output to this is 'subtrees'

coder.inline('always');
coder.internal.prefer_const(varargin);

params = struct(...
    'Subtrees',     uint32(0));

popts = struct(...
    'CaseSensitivity',  false, ...
    'StructExpand',     true, ...
    'PartialMatching',  true);

optarg      = eml_parse_parameter_inputs(params, popts, varargin{:});
subtrees    = eml_get_parameter_value(optarg.Subtrees, uint32(0), varargin{:});
end


function validateSubtrees(subtrees)
% Validate the fields of SubTrees

coder.inline('always');
coder.internal.prefer_const(subtrees);

if isnumeric(subtrees)
    validateattributes(subtrees,{'double','single','uint32'},...
        {'nonnan','finite','real','nonempty','nonnegative'},mfilename,'subtrees');
else
    coder.internal.assert(coder.internal.isConst(subtrees),...
        'stats:classreg:learning:impl:TreeImpl:processSubtrees:BadSubtrees');
    validateattributes(subtrees,{'char'},...
        {'size',[1 3]},mfilename,'subtrees');
    validatestring(subtrees,{'all'},mfilename,'subtrees');
end
end


function validateFields(cgStruct)
% Validate fields of Struct

coder.inline('always');


% Validate Impl Parameters
validateattributes(cgStruct.Impl.CutVar,{'numeric'},{'nonnan',...
    'nonnegative','finite','integer','nonempty','real'},mfilename,'CutVar');
validateattributes(cgStruct.Impl.Children,{'numeric'},{'nonnan','integer','nonnegative','real'},mfilename,'Children');
if ~isempty(cgStruct.Impl.PruneList)
    validateattributes(cgStruct.Impl.PruneList,{'numeric'},{'nonnan','real',...
        'nonnegative','integer','size',[size(cgStruct.Impl.Children,1),1]},mfilename,'PruneList');
end

end


