



classdef LinearDiscriminantImpl <classreg .learning .impl .DiscriminantImpl 










properties (GetAccess =public ,SetAccess =protected )
D =[]; 
S =[]; 
V =[]; 
end

properties (GetAccess =protected ,SetAccess =protected )
PrivCalculator =[]; 
end

properties (GetAccess =public ,SetAccess =public ,Hidden =true ,Dependent =true )
SaveMemory ; 
end

properties (GetAccess =public ,SetAccess =protected ,Hidden =true ,Dependent =true )
Calculator ; 
Sigma ; 
InvSigma ; 
LogDetSigma ; 
MinGamma ; 
end

properties (Constant )
AllowedTypes ={'linear' ,'diagLinear' ,'pseudoLinear' }; 
end

methods 
function sm =get .SaveMemory (this )
sm =isempty (this .PrivCalculator ); 
end

function this =set .SaveMemory (this ,sm )
ifsm &&~isempty (this .PrivCalculator )
this .PrivCalculator =[]; 
end
if~sm &&isempty (this .PrivCalculator )
this .PrivCalculator =fetchCalculator (this ); 
end
end

function calc =get .Calculator (this )
ifisempty (this .PrivCalculator )
calc =fetchCalculator (this ); 
else
calc =this .PrivCalculator ; 
end
end

function s =get .Sigma (this )
s =sigma (this .Calculator ,this .D ,this .S ,this .V ); 
end

function s =get .InvSigma (this )
s =invSigma (this .Calculator ); 
end

function logdetsig =get .LogDetSigma (this )
logdetsig =logDetSigma (this .Calculator ,this .D ,this .S ,this .V ); 
end

function mg =get .MinGamma (this )
mg =classreg .learning .impl .LinearDiscriminantImpl .minGamma (size (this .Mu ,2 ),this .S ); 
end
end

methods 

function m =linear (this ,X )
m =linear (this .Calculator ,X ); 
end


function v =quadratic (this ,X1 ,X2 )
v =quadratic (this .Calculator ,X1 ,X2 ); 
end



function m =mahal (this ,K ,X )
m =mahal (this .Calculator ,K ,X ); 
end


function v =linearCoeffs (this ,i ,j )
v =linearCoeffs (this .Calculator ,i ,j ); 
end


function c =constantTerm (this ,i ,j )
c =constantTerm (this .Calculator ,i ,j ); 
end

function delran =deltaRange (this ,gamma )
ifnargin <2 
gamma =this .Gamma ; 
end
r =deltaPredictor (this ,gamma ); 
delran =[min (r (:)),max (r (:))]; 
end

function delpred =deltaPredictor (this ,gamma )
ifnargin <2 ||gamma ==this .Gamma 
calc =this .Calculator ; 
ifisa (calc ,'classreg.learning.impl.RegularizedDiscriminantCalculator' )
delpred =max (abs (calc .CenteredScaledMuOverCorr )); 
else
delpred =max (abs (linear (calc ,this .CenteredMu ))); 
end
else
calc =makeCalculator (...
    this .D ,this .S ,this .V ,gamma ,0 ,this .Mu ,this .BetweenMu ,this .CenteredMu ); 
delpred =max (abs (linear (calc ,this .CenteredMu ))); 
end
end

function nCoeffs =nLinearCoeffs (this ,delta )
if~isnumeric (delta )||~isvector (delta )
error (message ('stats:classreg:learning:impl:LinearDiscriminantImpl:nLinearCoeffs:BadDelta' )); 
end
delta =delta (:); 

Ndelta =numel (delta ); 

p =size (this .Mu ,2 ); 
ifany (delta >0 )
maxDeltaPerPredictor =deltaPredictor (this ); 
nCoeffs =sum (bsxfun (@ge ,maxDeltaPerPredictor ,repmat (delta ,1 ,p )),2 ); 
else
nCoeffs =repmat (p ,1 ,Ndelta ); 
end
end

function this =LinearDiscriminantImpl (type ,d ,s ,v ,gamma ,delta ,mu ,classWeights ,saveMemory )
this =this @classreg .learning .impl .DiscriminantImpl (gamma ,delta ,mu ,classWeights ); 
this .D =d ; 
this .S =s ; 
this .V =v ; 

type =spellCompleteType (type ); 






ifgamma ==0 
[d ,s ,gamma ]=forceType (type ,d ,s ); 
else
allowTypes =allowedTypes (d ,s ,gamma ); 
if~ismember (lower (type ),lower (allowTypes ))
type =forceGamma (size (mu ,2 ),s ,gamma ); 
end
end

this .Type =type ; 
this .Gamma =gamma ; 



if~saveMemory 
this .PrivCalculator =makeCalculator (...
    d ,s ,v ,gamma ,delta ,mu ,this .BetweenMu ,this .CenteredMu ); 
end
end

function this =setType (this ,type )
type =spellCompleteType (type ); 



if~strcmpi (type ,this .Type )
d =this .D ; 
s =this .S ; 


[d ,s ,gamma ]=forceType (type ,d ,s ); 
this .Type =type ; 



ifthis .Gamma ~=gamma 
this .Gamma =gamma ; 
if~isempty (this .PrivCalculator )
this .PrivCalculator =makeCalculator (...
    d ,s ,this .V ,gamma ,this .Delta ,this .Mu ,this .BetweenMu ,this .CenteredMu ); 
end
end
end
end

function this =setGamma (this ,gamma )






ifgamma ~=this .Gamma 
d =this .D ; 
s =this .S ; 




allowTypes =allowedTypes (d ,s ,gamma ); 
if~ismember (this .Type ,allowTypes )
this .Type =forceGamma (size (this .Mu ,2 ),s ,gamma ); 
end

this .Gamma =gamma ; 



if~isempty (this .PrivCalculator )
[d ,s ]=forceType (this .Type ,d ,s ); 
this .PrivCalculator =makeCalculator (...
    d ,s ,this .V ,gamma ,this .Delta ,this .Mu ,this .BetweenMu ,this .CenteredMu ); 
end
end
end












function this =setTypeAndGamma (this ,type ,gamma )
oldCalculator =this .PrivCalculator ; 
this .PrivCalculator =[]; 
this =setType (this ,type ); 
this =setGamma (this ,gamma ); 
if~isempty (oldCalculator )
d =this .D ; 
s =this .S ; 
[d ,s ]=forceType (this .Type ,d ,s ); 
this .PrivCalculator =makeCalculator (...
    d ,s ,this .V ,this .Gamma ,this .Delta ,this .Mu ,this .BetweenMu ,this .CenteredMu ); 
end
end

function this =setDelta (this ,delta )
ifdelta ~=this .Delta 
this .Delta =delta ; 
if~isempty (this .PrivCalculator )




ifdelta >0 &&isa (this .PrivCalculator ,...
    'classreg.learning.impl.RegularizedDiscriminantCalculator' )
this .PrivCalculator .Delta =delta ; 
else
this .PrivCalculator =...
    makeCalculator (...
    this .D ,this .S ,this .V ,this .Gamma ,delta ,...
    this .Mu ,this .BetweenMu ,this .CenteredMu ); 
end
end
end
end
end

methods (Access =protected )


function calc =fetchCalculator (this )
d =this .D ; 
s =this .S ; 
v =this .V ; 

[d ,s ]=forceType (this .Type ,d ,s ); 
gamma =this .Gamma ; 

calc =makeCalculator (...
    d ,s ,v ,gamma ,this .Delta ,this .Mu ,this .BetweenMu ,this .CenteredMu ); 
end
end

methods (Static ,Hidden )
function mingam =minGamma (p ,s )
s =s .^2 ; 
maxs =max (s ); 
ifany (s <p *eps (maxs ))
mingam =p *eps (maxs ); 
else
mingam =0 ; 
end
end

function tf =canBeFull (d ,s ,gamma )
tf =all (d >0 )&&gamma <1 &&...
    (all (s >0 )||gamma >classreg .learning .impl .LinearDiscriminantImpl .minGamma (numel (d ),s )); 
end

function tf =canBePseudo (d ,s ,gamma )
tf =gamma ==0 ; 
end

function tf =canBeDiagonal (d ,s ,gamma )
tf =gamma ==1 ; 
end
end
methods (Hidden )
function s =toStruct (this )

s =struct ; 
s .type =this .Type ; 
s .d =this .D ; 
s .s =this .S ; 
s .v =this .V ; 
s .gamma =this .Gamma ; 
s .delta =this .Delta ; 
s .mu =this .Mu ; 
s .classWeights =this .ClassWeights ; 
s .saveMemory =this .SaveMemory ; 
s .numLinearDiscr =1 ; 
end
end

methods (Static ,Hidden )
function obj =fromStruct (s )

type =s .type ; 
D =s .d ; 
S =s .s ; 
V =s .v ; 
gamma =s .gamma ; 
delta =s .delta ; 
mu =s .mu ; 
classWeights =s .classWeights ; 
saveMemory =s .saveMemory ; 
obj =classreg .learning .impl .LinearDiscriminantImpl (type ,D ,S ,V ,gamma ,delta ,mu ,classWeights ,saveMemory ); 
end
end
end


function [d ,s ,gamma ]=forceFull (d ,s )
gamma =classreg .learning .impl .LinearDiscriminantImpl .minGamma (numel (d ),s ); 
end

function [d ,s ,gamma ]=forcePseudo (d ,s )


d (d ==0 )=Inf ; 
s (s ==0 )=Inf ; 
gamma =0 ; 
end

function [d ,s ,gamma ]=forceDiagonal (d ,s )


d (d ==0 )=Inf ; 
gamma =1 ; 
end

function [d ,s ,gamma ]=forceType (type ,d ,s )
switchlower (type )
case 'linear' 
[d ,s ,gamma ]=forceFull (d ,s ); 
case 'pseudolinear' 
[d ,s ,gamma ]=forcePseudo (d ,s ); 
case 'diaglinear' 
[d ,s ,gamma ]=forceDiagonal (d ,s ); 
end
end

function type =forceGamma (p ,s ,gamma )
mingam =classreg .learning .impl .LinearDiscriminantImpl .minGamma (p ,s ); 
ifgamma ==1 
type ='diagLinear' ; 
elseifgamma <mingam 
error (message ('stats:classreg:learning:impl:LinearDiscriminantImpl:forceGamma:GammaTooSmall' ,sprintf ('%g' ,mingam ))); 
else
type ='linear' ; 
end
end

function types =allowedTypes (d ,s ,gamma )
types ={}; 
ifclassreg .learning .impl .LinearDiscriminantImpl .canBeFull (d ,s ,gamma )
types ={'linear' }; 
end
ifclassreg .learning .impl .LinearDiscriminantImpl .canBePseudo (d ,s ,gamma )
types =[types ,{'pseudoLinear' }]; 
end
ifclassreg .learning .impl .LinearDiscriminantImpl .canBeDiagonal (d ,s ,gamma )
types =[types ,{'diagLinear' }]; 
end
end

function type =spellCompleteType (type )
allowedTypes =classreg .learning .impl .LinearDiscriminantImpl .AllowedTypes ; 
tf =strncmpi (type ,allowedTypes ,length (type )); 
ifsum (tf )~=1 
error (message ('stats:classreg:learning:impl:LinearDiscriminantImpl:spellCompleteType:BadType' ,sprintf (' %s' ,allowedTypes {:}))); 
end
type =allowedTypes {tf }; 
end







function calc =makeCalculator (d ,s ,v ,gamma ,delta ,mu ,betweenMu ,centeredMu )
ifgamma ==1 
ifdelta >0 
calc =classreg .learning .impl .RegularizedDiscriminantCalculator (...
    mu ,1 ./d ,eye (size (mu ,2 )),gamma ,delta ,betweenMu ,centeredMu ); 
else
calc =classreg .learning .impl .DiagonalDiscriminantCalculator (mu ,1 ./d ); 
end
elseifgamma >0 
p =size (mu ,2 ); 
s2 =(1 -gamma )*s .^2 +gamma ; 
ifany (abs (s2 )<p *eps (max (abs (s2 ))))
error (message ('stats:classreg:learning:impl:LinearDiscriminantImpl:makeCalculator:PooledSingular' )); 
end
invCorr =bsxfun (@times ,v ,1 ./s2 ' -1 /gamma )*v ' ; 
invCorr (1 :p +1 :end)=invCorr (1 :p +1 :end)+1 /gamma ; 
calc =classreg .learning .impl .RegularizedDiscriminantCalculator (...
    mu ,1 ./d ,invCorr ,gamma ,delta ,betweenMu ,centeredMu ); 
elseifdelta >0 
invR =bsxfun (@times ,v ,1 ./s ' ); 
invCorr =invR *invR ' ; 
calc =classreg .learning .impl .RegularizedDiscriminantCalculator (...
    mu ,1 ./d ,invCorr ,gamma ,delta ,betweenMu ,centeredMu ); 
else
invR =bsxfun (@times ,v ,1 ./s ' ); 
calc =classreg .learning .impl .CholeskyDiscriminantCalculator (...
    mu ,1 ./d ,invR ); 
end
end
