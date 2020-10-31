classdef MajorityUndersampler <classreg .learning .generator .Generator 




properties (GetAccess =public ,SetAccess =protected )


C =[]; 


NumSmallest =[]; 



RatioToSmallest =[]; 
end

methods (Hidden )
function this =MajorityUndersampler (X ,Y ,W ,fitData ,classnames ,ratioToSmallest )
this =this @classreg .learning .generator .Generator (X ,Y ,W ,fitData ); 

this .C =classreg .learning .internal .classCount (classnames ,Y ); 
K =numel (classnames ); 


sumC =sum (this .C ,1 ); 
sumC (sumC ==0 )=[]; 
ifisempty (sumC )
error (message ('stats:classreg:learning:generator:MajorityUndersampler:MajorityUndersampler:AllClassesEmpty' )); 
end
this .NumSmallest =min (sumC ); 

ifisempty (ratioToSmallest )||strcmpi (ratioToSmallest ,'default' )
this .RatioToSmallest =ones (1 ,K ); 
else
if~isnumeric (ratioToSmallest )||~isvector (ratioToSmallest )...
    ||any (ratioToSmallest <0 )||all (ratioToSmallest ==0 )
error (message ('stats:classreg:learning:generator:MajorityUndersampler:MajorityUndersampler:BadRatioToSmallest' )); 
end
ifisscalar (ratioToSmallest )
this .RatioToSmallest =repmat (ratioToSmallest ,1 ,K ); 
else
ifnumel (ratioToSmallest )~=K ...
    ||any (isnan (ratioToSmallest ))||any (isinf (ratioToSmallest ))
error (message ('stats:classreg:learning:generator:MajorityUndersampler:MajorityUndersampler:RatioToSmallestNaNorInf' ,K )); 
end
this .RatioToSmallest =ratioToSmallest (:)' ; 
end
end
end
end

methods (Static )
function [dorus ,undersamplerArgs ,otherArgs ]=processArgs (varargin )
args ={'ratioToSmallest' }; 
defs ={[]}; 
[ratioToSmallest ,~,otherArgs ]=...
    internal .stats .parseArgs (args ,defs ,varargin {:}); 
dorus =~isempty (ratioToSmallest ); 
undersamplerArgs ={}; 
ifdorus 
undersamplerArgs ={'ratioToSmallest' ,ratioToSmallest }; 
end
end
end

methods 
function [this ,X ,Y ,W ,fitData ,optArgs ]=generate (this )

K =size (this .C ,2 ); 
NumPerClass =sum (this .C ,1 ); 
NumToSample =ceil (this .NumSmallest *this .RatioToSmallest ); 
NumToSample (NumPerClass ==0 )=0 ; 



idx =zeros (sum (NumToSample ),1 ); 
idxbegin =1 ; 
fork =1 :K 
ifNumToSample (k )>0 
idxk =find (this .C (:,k )); 
ifNumPerClass (k )~=NumToSample (k )
ifNumPerClass (k )<NumToSample (k )
replaceArgs ={'replace' ,true }; 
else
replaceArgs ={'replace' ,false }; 
end
idxk =datasample (idxk ,NumToSample (k ),...
    'weights' ,this .W (idxk ),replaceArgs {:}); 
end
idx (idxbegin :idxbegin +NumToSample (k )-1 )=idxk ; 
idxbegin =idxbegin +NumToSample (k ); 
end
end



idx =idx (randperm (numel (idx ))); 
this .LastUseObsForIter =idx ; 


X =this .X (idx ,:); 
Y =this .Y (idx ); 
W =ones (numel (idx ),1 ); 
fitData =this .FitData (idx ,:); 
optArgs ={}; 
end

function this =update (this ,X ,Y ,W ,fitData )
this .X =X ; 
this .Y =Y ; 
this .W =W ; 
this .FitData =fitData ; 
end
end

methods (Static ,Hidden )
function ratioToSmallest =getArgsFromCellstr (varargin )
args ={'ratioToSmallest' }; 
defs ={[]}; 
ratioToSmallest =internal .stats .parseArgs (args ,defs ,varargin {:}); 
end
end

end
