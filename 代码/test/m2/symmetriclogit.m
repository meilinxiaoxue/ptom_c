function out =symmetriclogit (in )%#codegen 



out =coder .nullcopy (zeros (size (in ),'like' ,in )); 

fori =1 :numel (in )
out (i )=2 *(1 /(1 +exp (-in (i ))))-1 ; 
end

end
