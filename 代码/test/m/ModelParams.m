classdef ModelParams < classreg.learning.internal.DisallowVectorOps ...
        & matlab.mixin.CustomDisplay
%ModelParams Super class for learning model parameters (before training).
    
%   Copyright 2010-2015 The MathWorks, Inc.

    properties(SetAccess=private,GetAccess=public)
        %VERSION Version number.
        %   The Version property is an integer specifying the version of this
        %   ModelParams object. It can be set only in the ModelParams constructor.
        %   This property is not hidden because the LOADOBJ method relies on the
        %   FIELDNAMES function, and hidden properties are not visible to
        %   FIELDNAMES. The value of this property should be kept in sync with the
        %   value returned by the static expectedVersion method. If you change
        %   properties of a derived ModelParams class (such as SVMParams), you need
        %   to:
        %       - Increment the version number of that derived class by 1.
        %       - Modify the constructor of the derived class to pass the new
        %         version to the ModelParams constructor.
        %       - Modify the static expectedVersion method of the derived class to
        %         return the new version.
        %       - Modify the LOADOBJ method of the derived class to handle the
        %         changed properties.
        Version = [];
    end

    properties(SetAccess=protected,GetAccess=public)
        Method = ''; % name of the method such as, for example, 'Tree'
        Type = ''; % classification or regression
    end
    
    properties(SetAccess=public,GetAccess=public,Hidden=true)
        Filled = false;% Have all arguments been filled?
    end

    methods(Abstract,Static,Hidden)
        [holder,extraArgs] = make(type,varargin)
    end

    methods(Abstract,Hidden)
        this = fillDefaultParams(this,X,Y,W,dataSummary,classSummary)
    end

    methods(Access=protected)
        function header = getHeader(~)
            header = '';
        end
        
        function this = ModelParams(method,type,version)
            this = this@classreg.learning.internal.DisallowVectorOps();
            this.Method = method;
            this.Type   = type;
            if nargin>2
                this.Version = version;
            else
                this.Version = classreg.learning.modelparams.ModelParams.expectedVersion();
            end
        end
    end
    
    methods(Static,Hidden)
        function v = expectedVersion()
        %EXPECTEDVERSION Expected version number.
        %   V=classreg.learning.modelparams.ModelParams.expectedVersion() returns
        %   the most recent version number for this class definition. The output
        %   should kept in sync with the value of the Version property. If you
        %   change properties of a derived ModelParams class (such as SVMParams),
        %   you need to:
        %       - Increment the version number of that derived class by 1.
        %       - Modify the constructor of the derived class to pass the new
        %         version to the ModelParams constructor.
        %       - Modify the static expectedVersion method of the derived class to
        %         return the new version.
        %       - Modify the LOADOBJ method of the derived class to handle the
        %         changed properties.
        
            v = 1;
        end
    end

    methods(Hidden)
%         function this = fillIfNeeded(this,X,Y,W,dataSummary,classSummary)
%             % original
%             if ~isfilled(this)
%                 this = fillDefaultParams(this,X,Y,W,dataSummary,classSummary);
%             end
%             this.Filled = true;
%         end

        function this = fillIfNeeded(this,X,Y,W,dataSummary,classSummary)
            % Modified 2/28/14
            if ~this.Filled
                this = fillDefaultParams(this,X,Y,W,dataSummary,classSummary);
            end
            this.Filled = true;
        end
        
        function tf = isfilled(this)
            % Filled already?
            if this.Filled
                tf = true;
                return;
            end
            
            % Check if there are any empty properties
            props = properties(this);
            tf = false;
            for i=1:length(props)
                if isempty(this.(props{i}))
                    return;
                end
            end
            tf = true;
        end
        
        function s = toStruct(this)
            warning('off','MATLAB:structOnObject');
            s = struct(this);
            warning('on','MATLAB:structOnObject');
            s = rmfield(s,'Version');
            s = rmfield(s,'Filled');
        end
    end

end
