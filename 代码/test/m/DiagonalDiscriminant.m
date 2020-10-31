function mah = DiagonalDiscriminant(mah,nonemptyClassIndices,X,sizeX,Mu,invD)
%#codegen

coder.inline('never');
K = numel(nonemptyClassIndices);

for jj = 1:coder.internal.indexInt(K)
    ind = nonemptyClassIndices(jj);
    for ii = 1:coder.internal.indexInt(sizeX)
        if ~any(isnan(X(ii,:)))
            A = ((X(ii,:)-Mu(ind,:)).*invD);
            mah(ii,ind) = sum(A.*A);
        end
    end
end

end

