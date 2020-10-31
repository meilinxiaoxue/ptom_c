function sOut =statsetToStruct (sIn )












sOut =sIn ; 
sOut .Streams =struct ('Type' ,'' ,'Seed' ,0 ,'NormalTransform' ,'' ); 

fori =1 :numel (sIn .Streams )
randStrmtemp =sIn .Streams {i }; 
sOut .Streams .Type {i }=randStrmtemp .Type ; 
sOut .Streams .Seed (i )=randStrmtemp .Seed ; 
sOut .Streams .NormalTransform {i }=randStrmtemp .NormalTransform ; 
end

sOut .Streams .Type =char (sOut .Streams .Type ); 
sOut .Streams .NormalTransform =char (sOut .Streams .NormalTransform ); 

end