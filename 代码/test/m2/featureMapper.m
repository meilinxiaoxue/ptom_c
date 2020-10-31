classdef featureMapper <handle 









































properties (SetAccess ='private' )
rs 
d 
n 
o 
b 
isCompact =true ; 
P 
B 
G 
S 
W 
t 
end
methods 
function this =featureMapper (rs_or_d ,d_or_n ,n_or_t ,unused_or_t )

ifnargin <4 
rs =RandStream .getGlobalStream ; 
d =rs_or_d ; 
n =d_or_n ; 
t =n_or_t ; 
else
rs =rs_or_d ; 
d =d_or_n ; 
n =n_or_t ; 
t =unused_or_t ; 
end
if~(isscalar (d )&&isnumeric (d )&&(d ==round (d ))&&(d >=0 ))
error (message ('stats:classreg:learning:rkeutils:BadNumberInputFeatures' )); 
end
if~(isscalar (n )&&isnumeric (n )&&(n ==round (n ))&&(n >=0 ))
error (message ('stats:classreg:learning:rkeutils:BadExpansionDim' )); 
end
if~isa (rs ,'RandStream' )&&~isempty (rs )
error (message ('stats:classreg:learning:rkeutils:InvalidRandStream' )); 
end
this .n =n ; 
this .d =d ; 
this .o =2 .^ceil (log2 (this .d )); 
this .b =ceil (this .n /2 /this .o ); 
this .rs =getRandStreamState (rs ); 
this .t =t ; 
fori =1 :this .b 
rand (rs ,[this .o .*this .o ,1 ]); 
end
end
function Z =map (this ,X ,sigma )
ifstrcmpi (this .t ,'fastfood' )
ifisa (X ,'single' )

Z =single (sqrt (2 ./this .n ).*mapff (this ,double (X ),sigma )); 
else
Z =sqrt (2 ./this .n ).*mapff (this ,X ,sigma ); 
end
elseifstrcmpi (this .t ,'kitchensinks' )
Z =sqrt (2 ./this .n ).*mapks (this ,X ,sigma ); 
else
Z =X ; 
end
end
function compact (this )

this .isCompact =true ; 
this .P =[]; 
this .B =[]; 
this .G =[]; 
this .S =[]; 
this .W =[]; 
end
function Z =mapff (this ,X ,sigma )


validateXsigma (this ,X ,sigma )
ifthis .isCompact 
sampleMatrices (this ); 
end
Z =classreg .learning .rkeutils .fwhtmex (X ,this .S ,this .G ,this .B ,this .P ,sigma ,this .n ); 
end
function Z =mapks (this ,X ,sigma )

validateXsigma (this ,X ,sigma )
ifisempty (this .W )
oldrs =RandStream .getGlobalStream ; 
prs =makePrivateRandStream (this ); 
RandStream .setGlobalStream (prs ); 
this .W =randn (this .d ,this .n /2 ); 
RandStream .setGlobalStream (oldrs ); 
end
Xnu =(X *this .W ).*(sqrt (2 )./sigma ); 
Z =[cos (Xnu ),sin (Xnu )]; 
end
function Z =mapfwht (this ,X ,sigma )







validateXsigma (this ,X ,sigma )
ifthis .isCompact 
sampleMatrices (this ); 
end
assert (this .d ==this .o )
assert (this .n ==(2 *this .b *this .o ))
m =size (X ,1 ); 
BT =this .B .*sqrt (2 )./(sigma .*sqrt (this .o )); 
Z =zeros (m ,this .o ,this .b ,2 ); 
fori =1 :this .b 
T (:,this .P (:,i ))=fwh (X ,this .S (:,i ),this .G (:,i )); 
Xnu =fwh (T ,[],BT (:,i )); 
Z (:,:,i ,1 )=cos (Xnu ); 
Z (:,:,i ,2 )=sin (Xnu ); 
end
Z =reshape (Z ,m ,this .n ); 
end
function Z =mapwht (this ,X ,sigma ,H )







validateXsigma (this ,X ,sigma )
ifthis .isCompact 
sampleMatrices (this ); 
end
assert (this .d ==this .o )
assert (this .n ==(2 *this .b *this .o ))
m =size (X ,1 ); 
BT =this .B .*sqrt (2 )./(sigma .*sqrt (this .o )); 
Z =zeros (m ,this .o ,this .b ,2 ); 
fori =1 :this .b 
Xnu =X *bsxfun (@times ,((this .S (:,i )*this .G (:,i )' ).*H )*H (this .P (:,i ),:),BT (:,i )' ); 
Z (:,:,i ,1 )=cos (Xnu ); 
Z (:,:,i ,2 )=sin (Xnu ); 
end
Z =reshape (Z ,m ,this .n ); 
end
end
methods (Access ='private' )
function rs =makePrivateRandStream (this )
rs =RandStream .create (this .rs .Type ,...
    'NormalTransform' ,this .rs .NormalTransform ,...
    'NumStreams' ,this .rs .NumStreams ,...
    'StreamIndices' ,this .rs .StreamIndex ,...
    'Seed' ,this .rs .Seed ); 
rs .Antithetic =this .rs .Antithetic ; 
rs .FullPrecision =this .rs .FullPrecision ; 
rs .Substream =this .rs .Substream ; 
rs .State =this .rs .State ; 
end
function this =sampleMatrices (this )


oldrs =RandStream .getGlobalStream ; 
prs =makePrivateRandStream (this ); 
RandStream .setGlobalStream (prs ); 
this .P =cell (1 ,this .b ); 
this .B =cell (1 ,this .b ); 
this .G =cell (1 ,this .b ); 
this .S =cell (1 ,this .b ); 
fori =1 :this .b 
this .P {i }=randsample (this .o ,this .o ); 
this .B {i }=randsample ([-1 ,1 ],this .o ,true )' ; 
this .G {i }=randn (1 ,this .o ); 
this .S {i }=random ('nakagami' ,this .o /2 ,this .o ,[this .o ,1 ])./(sqrt (sum (this .G {i }(:).^2 ))); 
end
this .B =cell2mat (this .B ); 
this .S =cell2mat (this .S ); 
this .G =cell2mat (this .G ' )' ; 
this .P =uint64 (cell2mat (this .P )); 
this .isCompact =false ; 
RandStream .setGlobalStream (oldrs ); 
end
function validateXsigma (this ,X ,sigma )
assert (size (X ,2 )==this .d )
assert (isnumeric (X ))
assert (isfloat (X ))
assert (ismatrix (X ))
assert (isreal (X ))
assert (isscalar (sigma ))
assert (isreal (sigma ))
end
end
end

function RS =getRandStreamState (rs )
RS .Type =rs .Type ; 
RS .Seed =rs .Seed ; 
RS .NumStreams =rs .NumStreams ; 
RS .StreamIndex =rs .StreamIndex ; 
RS .State =rs .State ; 
RS .Substream =rs .Substream ; 
RS .NormalTransform =rs .NormalTransform ; 
RS .Antithetic =rs .Antithetic ; 
RS .FullPrecision =rs .FullPrecision ; 
end

function X =fwh (X ,A ,B )


o =size (X ,2 ); 
ifnargin >1 &&~isempty (A )
X =bsxfun (@times ,X ,A ' ); 
end
h =rem (uint64 (0 ):uint64 (o -1 ),2 )==0 ; 
forl =1 :log2 (o )
X =[X (:,h )+X (:,~h ),X (:,h )-X (:,~h )]; 
end
ifnargin >2 &&~isempty (B )
X =bsxfun (@times ,X ,B ' ); 
end
end


