classdef featureMapper < handle
    % FEATUREMAPPER is a class that implements a random transformation X->Z
    % where the Gramm matix of Z, Z'*Z, approximates a scaled Gaussian Kernel
    % n/2*G(X,X) as the size(Z,2)>>size(X,2). FEATUREMAPPER employs n random
    % basis functions using the Fast-Food approach prescribed below, but using
    % instead the Fast Walsh-Hadamard transform rather than matrix products.
    %
    %   Z = [cos(X*NU) sin(X*NU)]
    %
    %        NU = [nu_1 nu_2 ... nu_(n/d)]
    %
    %        nu_i = diag(S(:,i))*H*diag(G(:,i))*PM*H*diag(B(:,i)) ./ (sigma*sqrt(d))
    %
    %        PM = accumarray(1:d,P(:,i),1)
    %
    %  where
    %
    %    X   m x d      input samples
    %    sigma 1x1      kernel scale
    %    G   d x n/2/d  randn(d,n/2/d)                              (Gaussian scaling matrix)
    %    S   d x n/2/d  random('nakagami',d/2,d,[d,n/2/d])./sqrt(d) (Scaling matrix)
    %    B   d x n/2/d  each column is randsample([-1 1],d,true)    (Binary Scaling Matrix)
    %    P   d x n/2/d  each column is randsample(d,d)              (Permutation)
    %    H   d x d      hadamard(d) (Hadamard matrix)
    %
    %  In the actual implementation d (the number of input predictors) is not
    %  restricted to be a power of 2 and n (the number of output predictors) is
    %  not restricted to be a multiple of 2*d.
    %
    %  Example:
    %      sigma = 40;
    %      FM = featureMapper(size(X,2),1000);
    %      Z = map(FM,X,sigma);
    
    %   Copyright 2015-2017 The MathWorks, Inc.
    
    %[1] Le,Q., Sarlos,T. and Somola,A. "Fastfood" Approximating Kernel
    %    Expansions in Loglinear Time", Proceedings of The 30th International
    %    Conference on Machine Learning. ICML 2013.
    %[2] Rahimi, A. and Recht, B. "Random features for largescale", Proceedings
    %    of Advances in Neural Information Processing Systems 20, NIPS 2007.
    
    properties (SetAccess='private')
        rs   % Saved RandomStream
        d    % Number of input features
        n    % Number of basis functions (new features)
        o    % Haddamard order
        b    % Number of required Haddamard blocks
        isCompact = true; % when true, all random matrices are empty, reducing memory footprint
        P    % d x n/2/d  each column is randsample(d,d) (Permutation)
        B    % d x n/2/d  each column is randsample([-1 1],d,true) (Binary Scaling Matrix)
        G    % d x n/2/d  randn(d,n/2/d) (Gaussian scaling matrix)
        S    % d x n/2/d  random('nakagami',d/2,d,[d,n/2/d])./sqrt(d) (Scaling matrix)
        W    % Used for Kitchen Sinks Trasformation
        t    % String with the default transformation
    end
    methods
        function this = featureMapper(rs_or_d,d_or_n,n_or_t,unused_or_t)
            % Constructor
            if nargin<4
                rs = RandStream.getGlobalStream;
                d  = rs_or_d;
                n  = d_or_n;
                t = n_or_t;
            else
                rs = rs_or_d;
                d  = d_or_n;
                n = n_or_t;
                t  = unused_or_t;
            end
            if ~(isscalar(d) && isnumeric(d) && (d==round(d)) && (d >= 0))
                error(message('stats:classreg:learning:rkeutils:BadNumberInputFeatures'));
            end
            if ~(isscalar(n) && isnumeric(n) && (n==round(n)) && (n >= 0))
                error(message('stats:classreg:learning:rkeutils:BadExpansionDim'));
            end
            if ~isa(rs,'RandStream') && ~isempty(rs)
                error(message('stats:classreg:learning:rkeutils:InvalidRandStream'));
            end
            this.n = n;                      % Number of basis functions (new features)
            this.d = d;                      % Number of input features
            this.o = 2.^ceil(log2(this.d));  % Haddamard order
            this.b = ceil(this.n/2/this.o);  % Number of required Haddamard blocks
            this.rs = getRandStreamState(rs);% Saves the type and state of the random stream
            this.t = t;
            for i =1:this.b
                rand(rs,[this.o.*this.o,1]); % Move rng
            end
        end
        function Z = map(this,X,sigma)
            if strcmpi(this.t,'fastfood')
                if isa(X,'single')
                    % fwhtmex supports only double
                    Z = single(sqrt(2./this.n) .* mapff(this,double(X),sigma));    
                else
                    Z = sqrt(2./this.n) .* mapff(this,X,sigma);
                end
            elseif strcmpi(this.t,'kitchensinks')
                Z = sqrt(2./this.n) .* mapks(this,X,sigma);
            else
                Z = X;
            end
        end
        function compact(this)
            % Removes transformation matrices from memory
            this.isCompact = true;
            this.P = [];
            this.B = [];
            this.G = [];
            this.S = [];
            this.W = [];
        end
        function Z = mapff(this,X,sigma)
            % Maps using a mex/tbb implementation of the Fast Food
            % prescription.
            validateXsigma(this,X,sigma)
            if this.isCompact
                sampleMatrices(this);
            end
            Z = classreg.learning.rkeutils.fwhtmex(X,this.S,this.G,this.B,this.P,sigma,this.n);
        end
        function Z = mapks(this,X,sigma)
            % Maps using the Kitchen Sinks prescription [2].
            validateXsigma(this,X,sigma)
            if isempty(this.W)
                oldrs = RandStream.getGlobalStream;
                prs = makePrivateRandStream(this);
                RandStream.setGlobalStream(prs);
                this.W = randn(this.d,this.n/2);
                RandStream.setGlobalStream(oldrs);
            end
            Xnu = (X * this.W) .* (sqrt(2)./sigma);
            Z = [cos(Xnu) sin(Xnu)];
        end
        function Z = mapfwht(this,X,sigma)
            % Maps using a Matlab  implemetation of the Fast Discrete
            % Walsh-Hadamard Transform, which in turn is used to implement
            % the Fast Food prescription [1].
            % Note 1: This method is only provided to corroborate the results
            % of classreg.learning.rkeutils.fwhtmex, generally only the MAP
            % or the MAPKS methods should be used.
            % Note 2: PofC only implemented for whole blocks
            validateXsigma(this,X,sigma)
            if this.isCompact
                sampleMatrices(this);
            end
            assert(this.d == this.o ) % PofC only implemented for whole blocks
            assert(this.n == (2*this.b*this.o)) % PofC only implemented for whole blocks
            m = size(X,1);
            BT = this.B.*sqrt(2)./(sigma.*sqrt(this.o));
            Z = zeros(m,this.o,this.b,2);
            for i = 1:this.b
                T(:,this.P(:,i)) = fwh(X,this.S(:,i),this.G(:,i));
                Xnu = fwh(T,[],BT(:,i));
                Z(:,:,i,1) = cos(Xnu);
                Z(:,:,i,2) = sin(Xnu);
            end
            Z = reshape(Z,m,this.n);
        end
        function Z = mapwht(this,X,sigma,H)
            % Maps using matrix multiplication to implement Discrete
            % Walsh-Hadamard Transform which in turn is to to implement the
            % Fast Food prescrition.
            % Note 1: This method is only provided to corroborate the results
            % of classreg.learning.rkeutils.fwhtmex, generally only the MAP
            % or the MAPKS methods should be used.
            % Note 2: PofC only implemented for whole blocks
            validateXsigma(this,X,sigma)
            if this.isCompact
                sampleMatrices(this);
            end
            assert(this.d == this.o ) % PofC only implemented for whole blocks
            assert(this.n == (2*this.b*this.o)) % PofC only implemented for whole blocks
            m = size(X,1);
            BT = this.B.*sqrt(2)./(sigma.*sqrt(this.o));
            Z = zeros(m,this.o,this.b,2);
            for i = 1:this.b
                Xnu = X * bsxfun(@times,((this.S(:,i)*this.G(:,i)').*H) * H(this.P(:,i),:),BT(:,i)');
                Z(:,:,i,1) = cos(Xnu);
                Z(:,:,i,2) = sin(Xnu);
            end
            Z = reshape(Z,m,this.n);
        end
    end
    methods (Access='private')
        function rs = makePrivateRandStream(this)
            rs = RandStream.create(this.rs.Type,...
                'NormalTransform',this.rs.NormalTransform,...
                'NumStreams',this.rs.NumStreams,...
                'StreamIndices',this.rs.StreamIndex,...
                'Seed',this.rs.Seed);
            rs.Antithetic = this.rs.Antithetic;
            rs.FullPrecision = this.rs.FullPrecision;
            rs.Substream = this.rs.Substream;
            rs.State = this.rs.State;
        end
        function this = sampleMatrices(this)
            % Sample the Random data that will be used in the Fast Food
            % prescription [1].
            oldrs = RandStream.getGlobalStream;
            prs = makePrivateRandStream(this);
            RandStream.setGlobalStream(prs);
            this.P = cell(1,this.b);
            this.B = cell(1,this.b);
            this.G = cell(1,this.b);
            this.S = cell(1,this.b);
            for i = 1:this.b
                this.P{i} = randsample(this.o,this.o);
                this.B{i} = randsample([-1 1],this.o,true)';
                this.G{i} = randn(1,this.o);
                this.S{i} = random('nakagami',this.o/2,this.o,[this.o,1])./(sqrt(sum(this.G{i}(:).^2)));
            end
            this.B = cell2mat(this.B);
            this.S = cell2mat(this.S);
            this.G = cell2mat(this.G')';
            this.P = uint64(cell2mat(this.P));
            this.isCompact = false;
            RandStream.setGlobalStream(oldrs);
        end
        function validateXsigma(this,X,sigma)
            assert(size(X,2)==this.d)
            assert(isnumeric(X))
            assert(isfloat(X))
            assert(ismatrix(X))
            assert(isreal(X))
            assert(isscalar(sigma))
            assert(isreal(sigma))
        end
    end
end

function RS = getRandStreamState(rs)
RS.Type = rs.Type;
RS.Seed = rs.Seed;
RS.NumStreams = rs.NumStreams;
RS.StreamIndex = rs.StreamIndex;
RS.State = rs.State;
RS.Substream = rs.Substream;
RS.NormalTransform = rs.NormalTransform;
RS.Antithetic = rs.Antithetic;
RS.FullPrecision = rs.FullPrecision;
end

function X = fwh(X,A,B)
% Implements X*diag(A)*H*diag(B) where X is m*x, H is the oxo Hadamard
% matrix and A and B are ox1.
o = size(X,2);
if nargin>1 && ~isempty(A)
    X = bsxfun(@times,X,A');
end
h = rem(uint64(0):uint64(o-1),2)==0;
for l = 1:log2(o)
    X = [X(:,h)+X(:,~h) X(:,h)-X(:,~h)];
end
if nargin>2 && ~isempty(B)
    X = bsxfun(@times,X,B');
end
end


