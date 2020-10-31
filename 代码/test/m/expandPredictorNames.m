function n = expandPredictorNames(pnames,vrange)
%EXPANDPREDICTORNAMES Expand predictor names to represent categorical levels.
%   N = EXPANDPREDICTORNAMES(PNAMES,VRANGE) takes a cell array PNAMES
%   containing P predictor names, an a cell array VRANGE whos Jth value
%   contains the set of levels of the Jth predictor if that predictor is
%   categorical. It returns a cell array of all expanded predictor names.
%   For instance, if X1 is a continuous predictor and X2 is a categorical
%   predictor taking the values A,B,C, then the inputs and outputs are:
%
%      PNAMES = {'X1' 'X2'}
%      VRANGE = {[], {'A' 'B' 'C'}}
%      N      = {'X1' 'X2_A' 'X2_B' 'X2_C'}

if ~isempty(vrange)
    ncats = max(1,cellfun(@numel,vrange));
else
    ncats = 1; % empty means no categorical predictors
end

if all(ncats<=1)
    % No expanded predictor names, just regular predictor names
    n = pnames;
else
    n = cell(1,sum(ncats));
    done = 0;
    for j=1:length(ncats)
        pnj = pnames{j};
        vrj = vrange{j};
        if isnumeric(vrj) || islogical(vrj)
            vrj = strtrim(cellstr(num2str(vrj(:))));
        elseif iscategorical(vrj)
            isord = isordinal(vrj);
            vrj = categories(vrj);
            if isord
                vrj = vrj(2:end);
            end
        end
                
        if ncats(j)==1
            % Use predictor name for non-categorical predictors
            n{done+1} = pnj;
        else
            % Append categorical level to each categorical name
            for k=1:length(vrj)
                n{done+k} = sprintf('%s_%s',pnj,vrj{k});
            end
        end
        done = done + length(vrj);
    end
    if length(n)>done
        n = n(1:done);
    end
end
end
