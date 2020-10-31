function [isHier,missing] = ishierarchical(terms,isCat)
%ISHIERARCHICAL Determine if model is hierarchical and find missing terms.
    
 %   Copyright 2016 The MathWorks, Inc.

isHier = true;

% Look for any sub-terms that are not in the model
termorder = sum(terms,2);
missing = zeros(0,size(terms,2));
if all(termorder<=1)
    % Linear model, easy to check
    if ~any(termorder==0)
        if any(isCat(any(terms>0,1)))
            isHier = false;
        end
        missing = zeros(1,size(terms,2));
    end
else
    for j=1:size(terms,2)
        if any(terms(:,j))
            % Remove this variable from term, see if we have that
            notj = terms(terms(:,j)>0,:);
            notj(:,j) = 0;
            notj = setdiff(notj,terms,'rows');
            if ~isempty(notj)
                % Add missing term
                missing = union(missing,notj,'rows');
                
                % Hierarchy issue if removed variable is categorical
                if isCat(j)
                    isHier = false;
                end
            end
        end
    end
end