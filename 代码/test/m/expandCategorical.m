function [Xout,catcols] = expandCategorical(X,iscat,vrange)
%expandCategorical Expand a matrix with category numbers to dummy variables.
%   A = expandCategorical(B,ISCAT,VRANGE) takes an input matrix B
%   containing categorical variables coded as category numbers, and returns
%   a matrix A with those columns coded as dummy variables. ISCAT is a
%   logical or integer index vector indicating which columns of B are
%   categorical variable codes. VRANGE is a cell array providing the range
%   of values for each column of B. This function uses only the number of
%   values in VRANGE, not the values themselves.
%
%   [A,catcols] = expandCategorical(B,ISCAT,VRANGE) also returns a logical
%   vector indicating which columns of A represent dummy variables.
%
%   Copyright 2015-2016 The MathWorks, Inc.

% Convert to logical indexing
if ~islogical(iscat)
    iscat = ismember(1:size(X,2),iscat);
end

% Nothing to do if there are no categorical columns
if ~any(iscat)
    Xout = X;
    catcols = false(1,size(X,2));
    return;
end

[N,P] = size(X);

dovrange = nargin>=3 && ~isempty(vrange);
if dovrange
    % Use vrange to determine category counts
    ncats = cellfun(@numel,vrange);
    ncats(~iscat) = 1;
    isord = cellfun(@(v)iscategorical(v)&&isordinal(v),vrange);
else
    % Figure out category counts directly
    ncats = ones(1,P);
    for j=1:P
        if iscat(j)
            x = grp2idx(X(:,j));
            X(:,j) = x;
            ncats(j) = max(x);
        end
    end
    isord = false(1,P);
end
ncats(isord) = ncats(isord)-1; % ordinal coding rather than full
ncatcols = sum(ncats);

Xout = zeros(N,ncatcols,'like',X);

done = 0; % number of columns completed
catcols = false(1,ncatcols);
for j=1:size(X,2);
    if iscat(j)
        % Fill in columns of X with dummy variables
        ncols = ncats(j);

        x = X(:,j);
        if isord(j)
            % Ordinal x, ordinal coding
            dbl = double(x);
            ok = x>0;
            dbl = dbl(ok,:);
            D = NaN(N,ncols,'like',X);
            DSubset = ones(sum(ok),ncols);
            for k=1:ncols
                DSubset(dbl<=k,k) = -1;
            end
            D(ok,:) = DSubset;
        elseif ~dovrange || isempty(x) || (min(x)>0 && ~any(isnan(x)))
            % Typical case, categorical, all X values are in vrange
            D = zeros(N,ncols,'like',X);
            D(sub2ind([N ncols],(1:N)',x)) = 1;
        else
            % Some X values may not be in vrange because they did not
            % appear in training.
            ok = x>0;
            nok = sum(ok);
            D = zeros(N,ncols,'like',X);
            DSubset = zeros(nok,ncols,'like',X);
            DSubset(sub2ind([nok,ncols],(1:nok)',x(ok,:))) = 1;
            D(ok,:) = DSubset;
            D(~ok,:) = NaN;
        end
        
        Xout(:,done+1:done+ncols) = D;
        catcols(done+1:done+ncols) = true;
    else
        % Copy columns of X
        Xout(:,done+1) = X(:,j);
        ncols = 1;
    end
    
    done = done+ncols;
end
end
