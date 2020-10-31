function tf =prefixMatch (string ,target )



ifisempty (string )
tf =false ; 
elseifischar (target )
tf =strncmpi (string ,target ,numel (string )); 
else
tf =any (cellfun (@(t )strncmpi (string ,t ,numel (string )),target )); 
end
end
