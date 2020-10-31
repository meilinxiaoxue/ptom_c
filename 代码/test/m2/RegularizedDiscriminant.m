function mah =RegularizedDiscriminant (mah ,nonemptyClassIndices ,X ,sizeX ,invCorr ,invD ,Delta ,betweenMu ,centeredMu )
%#codegen 

coder .inline ('never' ); 
K =numel (nonemptyClassIndices ); 

forjj =1 :coder .internal .indexInt (K )
ind =nonemptyClassIndices (jj ); 
CenteredScaledMu =centeredMu (ind ,:).*invD ; 
CenteredScaledMuOverCorr =CenteredScaledMu .*invCorr (ind ); 
forii =1 :coder .internal .indexInt (sizeX )
if~any (isnan (X (ii ,:)))
standardX =((X (ii ,:)-betweenMu (ind ,:)).*invD ); 
qX =sum ((standardX *invCorr ).*standardX ); 
Mu =CenteredScaledMuOverCorr (ind ,:)' ; 
forkk =1 :coder .internal .indexInt (size (Mu ,1 ))
ifabs (Mu (kk ,ind ))<Delta 
Mu (kk ,ind )=0 ; 
end
end
mah (ii ,ind )=qX -(2 *standardX -CenteredScaledMu )*Mu ; 
end
end
end






