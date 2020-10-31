
function node =findNode (X ,subtrees ,...
    pruneList ,kids ,cutVar ,cutPoint )%#codegen 



numberOfSubtrees =numel (subtrees ); 

numberOfObservations =size (X ,1 ); 
numberOfNodes =size (kids ,2 ); 


node =coder .nullcopy (ones (numberOfObservations ,numberOfSubtrees )); 


forcurrentSubtreeLevel =1 :coder .internal .indexInt (numberOfSubtrees )


forn =1 :coder .internal .indexInt (numberOfObservations )
x =X (n ,:); 
m =cast (1 ,'like' ,node ); 
whilem <=numberOfNodes 
if~isempty (pruneList )
ifpruneList (m )<=subtrees (currentSubtreeLevel )
break; 
end
else
ifcutVar (m )==0 
break; 
end
end

leftChild =cast (kids (1 ,m ),'like' ,node ); 
rightChild =cast (kids (2 ,m ),'like' ,node ); 
ifisnan (x (cutVar (m )))
break; 
else
ifx (cutVar (m ))<cutPoint (m )
m =leftChild ; 
else
m =rightChild ; 
end
end
end
node (n ,currentSubtreeLevel )=m ; 
end
end
end