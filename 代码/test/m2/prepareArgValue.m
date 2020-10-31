function out =prepareArgValue (elt )






ifisequal (elt ,'true' )
out =true ; 
elseifisequal (elt ,'false' )
out =false ; 
elseifiscategorical (elt )
out =char (elt ); 
else
out =elt ; 
end
end