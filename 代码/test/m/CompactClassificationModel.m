classdef CompactClassificationModel < classreg.learning.coder.CompactPredictor %#codegen
    %CompactClassificationModel Base class for code generation compatible
    % supervised learning classification models
    
    % Copyright 2017 The MathWorks, Inc.
    
    properties (SetAccess=protected,GetAccess=public)
        
        %CLASSNAMES Names of classes in Y.
        ClassNames;
        
        %CLASSNAMESTYPE Integer value that encodes the data type of ClassNames
        %  isnumeric(labels) || islogical(labels) || ischar(labels) - int8(1)
        %  iscellstr(labels) - int8(2)
        ClassNamesType;
        
        %CLASSNAMESLENGTH Length of each entry in ClassNames
        ClassNamesLength;
        
        
        %SCORETRANSFORM Score Transform function.
        ScoreTransform;
        
        %PRIOR Prior class probabilities.
        Prior;
        
        %NONZEROPROBCLASSES Nonzero Probability Classes
        %   Utilized for selecting classnames with nonzero probability
        NonzeroProbClasses;
        
        % COST Square matrix, where Cost(i,j) is the cost of classifying a point into class j if its true class is i.
        % The order of the rows and columns of Cost corresponds to the order of the classes in ClassNames.
        % The number of rows and columns in Cost is the number of unique classes in the response.
        Cost;
        
    end
    methods (Abstract)
        % abstract methods that all supervised learning models should
        % implement
        predict(obj)
    end
    methods (Abstract, Hidden, Access = protected)
        predictEmptyX(obj)
    end     
    methods (Access=protected)
        function obj = CompactClassificationModel(cgStruct)
            
            coder.internal.prefer_const(cgStruct);
            % call base class constructor
            obj@classreg.learning.coder.CompactPredictor(cgStruct);
            
            validateFields(cgStruct);
            obj.ClassNamesType       = cgStruct.ClassSummary.ClassNamesType;
            obj.ClassNames           = cgStruct.ClassSummary.ClassNames;
            obj.ClassNamesLength     = coder.internal.indexInt(cgStruct.ClassSummary.ClassNamesLength);
            obj.NonzeroProbClasses   = cgStruct.ClassSummary.NonzeroProbClasses;
            obj                      = obj.setScoreTransform(cgStruct);

        end
    end
    
    methods (Access = protected)
        function obj = setScoreTransform(obj,cgStruct)
            % setScoreTransform - set the score transform
            coder.internal.prefer_const(cgStruct);
            % check to see if CustomScoreTransform is a field. Needed for 2016b Compatibility
            if isfield(cgStruct,'CustomScoreTransform')
                if cgStruct.CustomScoreTransform
                    obj.ScoreTransform = str2func(cgStruct.ScoreTransformFull);
                else
                    if strcmpi(cgStruct.ScoreTransform,'identity')
                        obj.ScoreTransform = [];
                    else
                        obj.ScoreTransform = str2func(['classreg.learning.coder.transform.' cgStruct.ScoreTransform]);
                    end
                end
            else
                obj.ScoreTransform = [];
            end
        end
        
        function obj = setCost(obj,strCost,castVar)
            % assignCost - method to calculate the cost of classification.
            % Cost field of incoming struct is used to calculate
            coder.internal.prefer_const(strCost);
            K = size(obj.ClassNames,1);
            if isempty(strCost)
                cost = ones(K,'like',castVar) - eye(K,'like',castVar);
            else
                cost = zeros(K,'like',castVar);
                [~,pos] = ismember(obj.NonzeroProbClasses,...
                    obj.ClassNames,'rows');
                cost(pos,pos) = cast(strCost,'like',castVar);
                for ii = 1:coder.internal.indexInt(K)
                   unmatched = false;
                   for jj = 1:coder.internal.indexInt(numel(pos))
                       if (ii==pos(jj))
                           unmatched = true;
                           break;
                       end
                   end
                   if unmatched
                      if coder.target('MATLAB')
                        cost(:,ii) = NaN;
                      else
                        cost(:,ii) = coder.internal.nan;
                      end
                   end
                end
                cost(1:K+1:end) = 0;
            end
            obj.Cost = cost;
        end
        
        function [labels,cost,classnum] = maxScore(obj,scores)
            % maxScore - label prediction method using maximum score
            
            classNamesType   = obj.ClassNamesType;
            classNames       = obj.ClassNames;
            classNamesLength = obj.ClassNamesLength;
            prior            = obj.Prior;
            
            N        = size(scores,1);
            notNaN   = ~all(isnan(scores),2);
            [~,cls]  = max(prior);
            classnum = coder.internal.nan(coder.internal.indexInt(N),1,'like',scores);
            cost             = coder.internal.nan(N,size(obj.Cost,2),'like',scores);
            for idx = 1:coder.internal.indexInt(numel(notNaN))
                if notNaN(idx)
                    [~,classnum(idx)] = max(scores(idx,:),[],2);
                    cost(idx,:) = obj.Cost(:,cast(classnum(idx),'uint32'));
                end
            end
            if classreg.learning.coderutils.iscellarray(classNamesType)
                % Assumes that the classnames are of the same size. If
                % classnames were of different sizes, they will have
                % trailing spaces which must be removed.
                labelsInit = classNames(cls,:);
                labels = repmat({labelsInit(1:classNamesLength(cls))},N,1);
                for idx = 1:coder.internal.indexInt(numel(notNaN))
                    if notNaN(idx)
                        % Remove trailing spaces in the labels
                        labels{idx,1} = classNames(cast(classnum(idx),'uint32'),1:classNamesLength(cast(classnum(idx),'uint32')));
                        
                    end
                end
                
            else
                labels = repmat(classNames(cls,:),N,1);
                for idx = 1:coder.internal.indexInt(numel(notNaN))
                    if notNaN(idx)
                        labels(idx,:) = classNames(cast(classnum(idx),'uint32'),:);
                    end
                end
            end
        end
        
        function [labels,classnum,cost,scores] = minCost(obj,scores)
            % minCost - label prediction method using minimum cost to
            % classify
            
            classNamesType   = obj.ClassNamesType;
            classNames       = obj.ClassNames;
            classNamesLength = obj.ClassNamesLength;
            prior            = obj.Prior;
            cost             = scores*obj.Cost;
            N                = size(scores,1);
            [~,cls]          = max(prior);
            classnum         = coder.nullcopy(zeros(coder.internal.indexInt(N),1,'like',scores));
            for idx = 1:coder.internal.indexInt(N)
                [~,classnum(idx)] = min(cost(idx,:),[],2);
            end
            if classreg.learning.coderutils.iscellarray(classNamesType)
                labelsInit = classNames(cls,:);
                labels = repmat({labelsInit(1:classNamesLength(cls))},N,1);
                for idx = 1:coder.internal.indexInt(N)
                    labels{idx,1} = classNames(cast(classnum(idx),'uint32'),1:classNamesLength(cast(classnum(idx),'uint32')));
                end
            else
                labels = repmat(classNames(cls,:),N,1);
                for idx = 1:coder.internal.indexInt(N)
                    labels(idx,:) = classNames(cast(classnum(idx),'uint32'),:);
                end
            end
            if ~isempty(obj.ScoreTransform)
                scores = obj.ScoreTransform(scores);
            end              
        end
    end
    
    methods(Static, Hidden)
        function props = matlabCodegenNontunableProperties(~)
            propstemp = classreg.learning.coder.CompactPredictor.matlabCodegenNontunableProperties;
            propstemp2 = {'ClassNamesType'};
            props = [propstemp ,propstemp2];
        end
        
    end
end

function validateFields(InStr)
% validate fields common to all Classification models
coder.inline('always');

validateattributes(InStr.ClassSummary.ClassNamesLength,{'numeric'},{'2d','ncols',1,'integer','real','nonnegative'},mfilename,'ClassNamesLength');
validateattributes(InStr.ClassSummary.ClassNames,{'numeric','char','logical'},{'2d','nrows',size(InStr.ClassSummary.ClassNamesLength,1),'real'},mfilename,'ClassNames');
validateattributes(InStr.ClassSummary.ClassNamesType,{'int8'},{'scalar','real','<',int8(3),'nonnegative'},mfilename,'ClassNamesType');
if ~isscalar(InStr.ClassSummary.Prior)
    validateattributes(InStr.ClassSummary.Prior,{'numeric'},{'row','real','nonnegative'},mfilename,'Prior'); %'size',[1,size(InStr.ClassSummary.NonzeroProbClassesLength,1)]
    validateattributes(InStr.ClassSummary.NonzeroProbClasses,{class(InStr.ClassSummary.ClassNames)},{'size',[size(InStr.ClassSummary.Prior,2),size(InStr.ClassSummary.ClassNames,2)],'real'},mfilename,'NonzeroProbClasses');
else
    validateattributes(InStr.ClassSummary.Prior,{'numeric'},{'real','positive'},mfilename,'Prior');
    validateattributes(InStr.ClassSummary.NonzeroProbClasses,{class(InStr.ClassSummary.ClassNames)},{'size',[1,InStr.ClassSummary.NonzeroProbClassesLength],'real'},mfilename,'NonzeroProbClasses');
end

validateattributes(InStr.ScoreTransform,{'char'},{'nonempty','row'},mfilename,'ScoreTransform');
% check to see if CustomScoreTransform is a field. Needed for 2016b Compatibility
if isfield(InStr,'CustomScoreTransform')
    validateattributes(InStr.ScoreTransformFull,{'char'},{'nonempty','row'},mfilename,'ScoreTransform');
    validateattributes(InStr.CustomScoreTransform,{'logical'},{'nonempty','scalar'},mfilename,'CustomScoreTransform');
end

end