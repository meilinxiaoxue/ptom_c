% Copyright 2016 The MathWorks, Inc.
function node = findNode(X, subtrees, ...
    pruneList, kids, cutVar, cutPoint) %#codegen
%FINDNODE Summary of this function goes here
%   Detailed explanation goes here

numberOfSubtrees = numel(subtrees);

numberOfObservations = size(X,1); % get the number of observations present
numberOfNodes = size(kids, 2); % Get number of nodes in this tree

%node = coder.nullcopy(ones(numberOfObservations, numberOfSubtrees,'like',cutPoint));
node = coder.nullcopy(ones(numberOfObservations, numberOfSubtrees));
%node = ones(numberOfObservations, numberOfSubtrees,'like',X);
% Iterate over all the subtrees
for currentSubtreeLevel = 1:coder.internal.indexInt(numberOfSubtrees)
    % Iterate over all observations to assign the required node number based on
    % the new tree.
    for n = 1:coder.internal.indexInt(numberOfObservations)
        x = X(n,:);
        m = cast(1,'like',node);
        while m<=numberOfNodes
            if ~isempty(pruneList)
                if pruneList(m)<=subtrees(currentSubtreeLevel)
                    break;
                end
            else
                if cutVar(m)==0
                    break;
                end
            end
            
            leftChild = cast(kids(1,m),'like',node);
            rightChild = cast(kids(2,m),'like',node);
            if isnan(x(cutVar(m)))
                break;
            else
                if x(cutVar(m))<cutPoint(m)
                    m = leftChild;
                else
                    m = rightChild;
                end
            end
        end
        node(n,currentSubtreeLevel) = m;
    end
end
end