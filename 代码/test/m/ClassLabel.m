classdef ClassLabel
    
%   Copyright 2010-2017 The MathWorks, Inc.


    properties(GetAccess=private,SetAccess=private)
        % 0 = nominal
        % 1 = char
        % 2 = cellstr
        % 3 = logical
        % 4 = numeric
        % 5 = ordinal
        % 6 = categorical
        % 7 = ordinal categorical
        Type = [];
        
        % Nominal array or char matrix with class labels
        L = [];
    end
    
    methods
        function this = ClassLabel(Y)
            if ischar(Y)
                if ~ismatrix(Y) && ~isempty(Y)
                    error(message('stats:classreg:learning:internal:ClassLabel:ClassLabel:YCharNotMatrix'));
                end
            else
                if ~isvector(Y) && ~isempty(Y)
                    error(message('stats:classreg:learning:internal:ClassLabel:ClassLabel:YNotVector'));
                end
            end
            if     isa(Y,'classreg.learning.internal.ClassLabel')
                this.Type = Y.Type;
                this.L = Y.L;
            elseif isa(Y,'nominal')
                this.Type = 0;
                this.L = Y(:);
            elseif ischar(Y)
                this.Type = 1;
                this.L = Y;
            elseif iscellstr(Y) || isstring(Y)
                this.Type = 2;
                undef = strcmp('<undefined>',Y);
                if any(undef)
                    Y(undef) = {''};
                end
                this.L = nominal(Y(:));
            elseif islogical(Y)
                this.Type = 3;
                this.L = Y(:);
            elseif isnumeric(Y)
                this.Type = 4;
                this.L = Y(:);
            elseif isa(Y,'ordinal')
                this.Type = 5;
                this.L = nominal(Y(:));
            elseif isa(Y,'categorical')
                if isordinal(Y)
                    this.Type = 7;
                else
                    this.Type = 6;
                end
                this.L = nominal(Y(:));
            else
                error(message('stats:classreg:learning:internal:ClassLabel:ClassLabel:UnknownType'));
            end
        end        
    end
    
    
    methods(Hidden)
        function disp(this)
            disp(this.L);
        end
        
        function tf = eq(this,other)
            % Empty?
            if isempty(other)
                tf = [];
                return;
            end
            
            % Check type
            if ~( isa(other,'classreg.learning.internal.ClassLabel') ...
                    || ischar(other) || iscellstr(other) || islogical(other) ...
                    || isnumeric(other) || isa(other,'categorical') || isstring(other))
                error(message('stats:classreg:learning:internal:ClassLabel:eq:BadType'));
            end
            
            % Compare chars only to chars
            if this.Type==1
                if ~ischar(other) && (~isa(other,'classreg.learning.internal.ClassLabel') || other.Type~=1)
                    error(message('stats:classreg:learning:internal:ClassLabel:eq:OtherNotChar'));
                end
                if isa(other,'classreg.learning.internal.ClassLabel')
                    other = other.L;
                end
                if size(other,2)~=size(this.L,2)
                    tf = false(size(this.L,1),1);
                    return;
                end
                tf = all(bsxfun(@eq,this.L,other),2);
            elseif isa(other,'classreg.learning.internal.ClassLabel')
                if this.Type==other.Type || ...
                        ((this.Type==3 || this.Type==4) ...
                        && (other.Type==3 || other.Type==4)) % mix logicals and numerics
                    tf = this.L==other.L;
                else
                    tf = nominal(this.L)==nominal(other.L);
                end
            elseif islogical(other)
                tf = this.L==other;
            elseif isnumeric(other)
                tf = this.L==other;                
            else
                tf = this.L==nominal(other);
            end
        end

        function [lev, levelCounts] = levels(this)
        %LEVELS Return non-empty levels for this categorical variable.
        
            if     this.Type==1
                tf = cellfun(@isempty, cellstr(this.L));
                [lev,~,levEnumeration] = unique(this.L(~tf,:),'rows');
                lev = classreg.learning.internal.ClassLabel(lev);
            elseif this.Type==3
                [n,~,levEnumeration] = unique(this.L);
                lev = classreg.learning.internal.ClassLabel(n);
            elseif this.Type==4
                [n,~,levEnumeration] = unique(this.L(~isnan(this.L)));
                lev = classreg.learning.internal.ClassLabel(n);
            else
                definedInd = ~isundefined(this.L);
                [n,~,levEnumeration] = unique(this.L(definedInd));
                lev = classreg.learning.internal.ClassLabel(n);
                % An alternative way of removing missing levels would be to
                % call droplevels in constructor, subsref and subsasgn.
                % Then we could use getlevels here. The present way is
                % deemed more efficient.
                %lev = classreg.learning.internal.ClassLabel(getlevels(this.L));
                lev.Type = this.Type;
            end

            if nargout > 1
                levelCounts = accumarray(levEnumeration, 1, [numel(lev),1]);
            end
        end
        
        function Y = labels(this)
        %LABELS Convert categorical variable to its original type.
            
            if     this.Type==1
                Y = this.L;
            elseif this.Type==2
                Y = cellstr(this.L);
                tf = strcmp(Y,'<undefined>');
                Y(tf) = {''};
            elseif this.Type==3
                Y = this.L;
            elseif this.Type==4
                Y = this.L;
            elseif this.Type==5
                Y = ordinal(this.L);
            elseif this.Type==6
                Y = categorical(this.L);
            elseif this.Type==7
                Y = categorical(this.L,'ordinal',true);
            else
                Y = this.L;
            end
        end
        
        function tf = ismissing(this)
        %ISMISSING Return a logical vector with 'true' for missing values.
            
            if     this.Type==1
                tf = cellfun(@isempty, cellstr(this.L));
            elseif this.Type==3
                tf = false(size(this.L));
            elseif this.Type==4
                tf = isnan(this.L);
            else
                tf = isundefined(this.L);
            end
        end
        
        function tf = iscategorical(this)
            tf = isa(this.L,'categorical');
        end
        
        function str = cellstr(this)
            if this.Type==3 || this.Type==4
                str = cellstr(nominal(this.L));
            else
                str = cellstr(this.L);
            end
        end
        
        function str = char(this)
            if     this.Type==1
                str = this.L;
            elseif this.Type==3 || this.Type==4
                str = char(cellstr(this));
            else
                str = char(this.L);
            end
        end
        
        function [varargout] = subsref(this,s)
            % Dispatch
            if     strcmp(s(1).type,'()') && isscalar(s)
                if numel(s(1).subs)>1
                    error(message('stats:classreg:learning:internal:ClassLabel:subsref:TooManyIndices'));
                end
                idx = s(1).subs{1};
                cl = classreg.learning.internal.ClassLabel(this.L(idx,:));
                cl.Type = this.Type;
                [varargout{1:nargout}] = cl;
            elseif strcmp(s(1).type,'.')
                error(message('stats:classreg:learning:internal:ClassLabel:subsref:PrivateAccess'));
            else
                % Return subsref to nominal
                [varargout{1:nargout}] = subsref(this.L,s);
            end
        end

        function this = subsasgn(this,s,data)
            if     isa(data,'classreg.learning.internal.ClassLabel') ...
                    && isa(this.L,'nominal')
                this.L = subsasgn(this.L,s,data.L);
                
            elseif isempty(data)
                if strcmp(s(1).type,'()') && isscalar(s)
                    if numel(s(1).subs)>1
                        error(message('stats:classreg:learning:internal:ClassLabel:subsasgn:TooManyIndices'));
                    end
                    idx = s(1).subs{1};
                    this.L(idx,:) = [];
                end
                
            elseif this.Type==1
                if ~ischar(data) && ...
                        (~isa(data,'classreg.learning.internal.ClassLabel') || data.Type~=1)
                    error(message('stats:classreg:learning:internal:ClassLabel:subsasgn:DataNotChar'));
                end
                if isa(data,'classreg.learning.internal.ClassLabel')
                    data = labels(data);
                end
                if strcmp(s(1).type,'()') && isscalar(s)
                    if numel(s(1).subs)>1
                        error(message('stats:classreg:learning:internal:ClassLabel:subsasgn:TooManyIndices'));
                    end
                    idx = s(1).subs{1};
                    if islogical(idx)
                        N = sum(idx);
                    else
                        N = numel(idx);
                    end
                    expsize = [N size(this.L,2)];
                    if ~all(size(data)==expsize)
                        error(message('stats:classreg:learning:internal:ClassLabel:subsasgn:CharSizeMismatch'));
                    end
                    this.L(idx,:) = data;
                else
                    this.L = subsasgn(this.L,s,data);
                end
                    
            elseif this.Type==3 || this.Type==4
                if ~islogical(data) && ~isnumeric(data) && ...
                        ( ~isa(data,'classreg.learning.internal.ClassLabel') ...
                        || (data.Type~=3 && data.Type~=4) )
                    error(message('stats:classreg:learning:internal:ClassLabel:subsasgn:DataNotConvertibleToLogicalOrNumeric'));
                end
                if isa(data,'classreg.learning.internal.ClassLabel')
                    data = labels(data);
                end
                this.L = subsasgn(this.L,s,data);
                
            else
                this.L = subsasgn(this.L,s,nominal(data));
            end
        end
        
        function n = length(this)
            n = size(this.L,1);
        end
        
        function n = numel(this)
            n = size(this.L,1);
        end
        
        function tf = isempty(this)
            tf = isempty(this.L);
        end
        
        function s = size(this,dim)
            if nargin<2
                s = [numel(this) 1];
            elseif dim==1
                s = numel(this);
            else
                s = 1;
            end
        end
        
        function a = vertcat(this,varargin)            
            a = this.L;
            for i=1:nargin-1
                b = varargin{i};
                a = vertcat(a,b.L); %#ok<AGROW>
            end
            a = classreg.learning.internal.ClassLabel(a);
            a.Type = this.Type;
        end
        
        function e = end(this,k,n)
            e = builtin('end',1:numel(this),k,n);
        end
        
        function [varargout] = ismember(this,other)
        %ISMEMBER Find labels that are included in the other list.
        %   This method has the same signature as ISMEMBER function in MATLAB.
        %   Labels in THIS and OTHER generally must be of the same type but can be
        %   of different types if matching these types is provided by NOMINAL                   
        
            if ~isa(other,'classreg.learning.internal.ClassLabel')
                error(message('stats:classreg:learning:internal:ClassLabel:ismember:RhsMustBeClassLabel'));
            end
            
            % This is to bypass the overhead incurred by ismember on the
            % native types. The eq operator for ClassLabel works if the rhs
            % is a ClassLabel object or any of the 6 supported types.
            % ClassLabel/ismember only works if the rhs is a ClassLabel
            % object. This is why I test if the rhs is a ClassLabel object
            % first.
            N = numel(this);
            if N==numel(other) && all(this==other)
                varargout{1} = true(N,1);
                varargout{2} = (1:N)';
                return;
            end
            
            if this.Type==1 && other.Type==1
                [varargout{1:nargout}] = ismember(this.L,other.L,'rows');
                return;
            end
            if (this.Type==3 || this.Type==4) ...
                    && (other.Type==3 || other.Type==4)
                [varargout{1:nargout}] = ismember(this.L,other.L);
                return;
            end
            
            if this.Type>0 && this.Type<5
                n1 = nominal(this.L);
            else
                n1 = this.L;
            end
            if other.Type>0 && other.Type<5
                n2 = nominal(other.L);
            else
                n2 = other.L;
            end
            [varargout{1:nargout}] = ismember(n1,n2);
        end
        
        function C = membership(this,classnames)
        %MEMBERSHIP Class membership matrix.
        %   This method returns an N-by-K logical matrix for N labels and K levels.
        %   By default, levels for these labels are assumed. You can pass you
        %   levels through CLASSNAMES. Labels in THIS and CLASSNAMES are generally
        %   expected to be of the same type. For exceptions, see ISMEMBER method.
        %   If you pass CLASSNAMES as an object of type ClassLabel, MEMBERSHIP uses
        %   the class order specified in CLASSNAMES.
            
            if     nargin<2
                classnames = levels(this);
            elseif ~isa(classnames,'classreg.learning.internal.ClassLabel')
                classnames = levels(classreg.learning.internal.ClassLabel(classnames));
            end
            C = classreg.learning.internal.classCount(classnames,this);
        end
        
        function [grp,grpnames,grplevels] = grp2idx(this,classnames)
        %GRP2IDX Group to index.
        %   This methods has the same signature as the GRP2IDX function. If you
        %   pass CLASSNAMES as an object of type ClassLabel, MEMBERSHIP uses
        %   the class order specified in CLASSNAMES.
            
            if     nargin<2
                classnames = levels(this);
            elseif ~isa(classnames,'classreg.learning.internal.ClassLabel')
                classnames = levels(classreg.learning.internal.ClassLabel(classnames));
            end
            [~,grp] = ismember(this,classnames);
            grp(grp==0) = NaN;
            if nargout>1
                grpnames = cellstr(classnames);
            end
            if nargout>2
                grplevels = classnames;
            end
        end
        
        function a = horzcat(varargin),    throwUndefinedError(); end %#ok<STOUT>
        function a = ctranspose(varargin), throwUndefinedError(); end %#ok<STOUT>
        function a = transpose(varargin),  throwUndefinedError(); end %#ok<STOUT>
        function a = permute(varargin),    throwUndefinedError(); end %#ok<STOUT>
        function a = reshape(varargin),    throwUndefinedError(); end %#ok<STOUT>
        function a = cat(varargin),        throwUndefinedError(); end %#ok<STOUT>
    end

    
    methods(Static,Hidden)
        function this = loadobj(obj)
            if obj.Type==3 && isa(obj.L,'nominal')
                this = classreg.learning.internal.ClassLabel(obj.L==nominal(true));
            else
                this = classreg.learning.internal.ClassLabel(obj.L);
                this.Type = obj.Type;
            end
        end
    end
end
    
    
function throwUndefinedError()
error(message('stats:classreg:learning:internal:ClassLabel:throwUndefinedError'));
end

