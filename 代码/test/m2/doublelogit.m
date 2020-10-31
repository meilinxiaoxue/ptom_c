function out =doublelogit (in )%#codegen 



out =coder .nullcopy (zeros (size (in ),'like' ,in )); 

fori =1 :numel (in )
out (i )=1 /(1 +exp (-2 *in (i ))); 
end
