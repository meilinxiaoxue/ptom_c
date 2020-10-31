function sOut =statsetFromStruct (sIn )








sOut =sIn ; 

[numStreams ,~]=size (sIn .Streams .Type ); 
switchnumStreams 
case 0 
sOut .Streams =cell (0 ,0 ); 

case 1 
sOut .Streams =RandStream (...
    sIn .Streams .Type ,...
    'Seed' ,sIn .Streams .Seed ,...
    'NormalTransform' ,sIn .Streams .NormalTransform ); 

otherwise
sOut .Streams =cell (1 ,numStreams ); 
fori =1 :numStreams 
sOut .Streams {i }=RandStream (...
    strtrim (sIn .Streams .Type (i ,:)),...
    'Seed' ,sIn .Streams .Seed (i ),...
    'NormalTransform' ,strtrim (sIn .Streams .NormalTransform (i ,:))); 
end
end


end