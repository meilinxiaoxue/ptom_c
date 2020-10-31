classdef ClassLabel 




properties (GetAccess =private ,SetAccess =private )








Type =[]; 


L =[]; 
end

methods 
function this =ClassLabel (Y )
ifischar (Y )
if~ismatrix (Y )&&~isempty (Y )
error (message ('stats:classreg:learning:internal:ClassLabel:ClassLabel:YCharNotMatrix' )); 
end
else
if~isvector (Y )&&~isempty (Y )
error (message ('stats:classreg:learning:internal:ClassLabel:ClassLabel:YNotVector' )); 
end
end
ifisa (Y ,'classreg.learning.internal.ClassLabel' )
this .Type =Y .Type ; 
this .L =Y .L ; 
elseifisa (Y ,'nominal' )
this .Type =0 ; 
this .L =Y (:); 
elseifischar (Y )
this .Type =1 ; 
this .L =Y ; 
elseifiscellstr (Y )||isstring (Y )
this .Type =2 ; 
undef =strcmp ('<undefined>' ,Y ); 
ifany (undef )
Y (undef )={'' }; 
end
this .L =nominal (Y (:)); 
elseifislogical (Y )
this .Type =3 ; 
this .L =Y (:); 
elseifisnumeric (Y )
this .Type =4 ; 
this .L =Y (:); 
elseifisa (Y ,'ordinal' )
this .Type =5 ; 
this .L =nominal (Y (:)); 
elseifisa (Y ,'categorical' )
ifisordinal (Y )
this .Type =7 ; 
else
this .Type =6 ; 
end
this .L =nominal (Y (:)); 
else
error (message ('stats:classreg:learning:internal:ClassLabel:ClassLabel:UnknownType' )); 
end
end
end


methods (Hidden )
function disp (this )
disp (this .L ); 
end

function tf =eq (this ,other )

ifisempty (other )
tf =[]; 
return ; 
end


if~(isa (other ,'classreg.learning.internal.ClassLabel' )...
    ||ischar (other )||iscellstr (other )||islogical (other )...
    ||isnumeric (other )||isa (other ,'categorical' )||isstring (other ))
error (message ('stats:classreg:learning:internal:ClassLabel:eq:BadType' )); 
end


ifthis .Type ==1 
if~ischar (other )&&(~isa (other ,'classreg.learning.internal.ClassLabel' )||other .Type ~=1 )
error (message ('stats:classreg:learning:internal:ClassLabel:eq:OtherNotChar' )); 
end
ifisa (other ,'classreg.learning.internal.ClassLabel' )
other =other .L ; 
end
ifsize (other ,2 )~=size (this .L ,2 )
tf =false (size (this .L ,1 ),1 ); 
return ; 
end
tf =all (bsxfun (@eq ,this .L ,other ),2 ); 
elseifisa (other ,'classreg.learning.internal.ClassLabel' )
ifthis .Type ==other .Type ||...
    ((this .Type ==3 ||this .Type ==4 )...
    &&(other .Type ==3 ||other .Type ==4 ))
tf =this .L ==other .L ; 
else
tf =nominal (this .L )==nominal (other .L ); 
end
elseifislogical (other )
tf =this .L ==other ; 
elseifisnumeric (other )
tf =this .L ==other ; 
else
tf =this .L ==nominal (other ); 
end
end

function [lev ,levelCounts ]=levels (this )


ifthis .Type ==1 
tf =cellfun (@isempty ,cellstr (this .L )); 
[lev ,~,levEnumeration ]=unique (this .L (~tf ,:),'rows' ); 
lev =classreg .learning .internal .ClassLabel (lev ); 
elseifthis .Type ==3 
[n ,~,levEnumeration ]=unique (this .L ); 
lev =classreg .learning .internal .ClassLabel (n ); 
elseifthis .Type ==4 
[n ,~,levEnumeration ]=unique (this .L (~isnan (this .L ))); 
lev =classreg .learning .internal .ClassLabel (n ); 
else
definedInd =~isundefined (this .L ); 
[n ,~,levEnumeration ]=unique (this .L (definedInd )); 
lev =classreg .learning .internal .ClassLabel (n ); 





lev .Type =this .Type ; 
end

ifnargout >1 
levelCounts =accumarray (levEnumeration ,1 ,[numel (lev ),1 ]); 
end
end

function Y =labels (this )


ifthis .Type ==1 
Y =this .L ; 
elseifthis .Type ==2 
Y =cellstr (this .L ); 
tf =strcmp (Y ,'<undefined>' ); 
Y (tf )={'' }; 
elseifthis .Type ==3 
Y =this .L ; 
elseifthis .Type ==4 
Y =this .L ; 
elseifthis .Type ==5 
Y =ordinal (this .L ); 
elseifthis .Type ==6 
Y =categorical (this .L ); 
elseifthis .Type ==7 
Y =categorical (this .L ,'ordinal' ,true ); 
else
Y =this .L ; 
end
end

function tf =ismissing (this )


ifthis .Type ==1 
tf =cellfun (@isempty ,cellstr (this .L )); 
elseifthis .Type ==3 
tf =false (size (this .L )); 
elseifthis .Type ==4 
tf =isnan (this .L ); 
else
tf =isundefined (this .L ); 
end
end

function tf =iscategorical (this )
tf =isa (this .L ,'categorical' ); 
end

function str =cellstr (this )
ifthis .Type ==3 ||this .Type ==4 
str =cellstr (nominal (this .L )); 
else
str =cellstr (this .L ); 
end
end

function str =char (this )
ifthis .Type ==1 
str =this .L ; 
elseifthis .Type ==3 ||this .Type ==4 
str =char (cellstr (this )); 
else
str =char (this .L ); 
end
end

function [varargout ]=subsref (this ,s )

ifstrcmp (s (1 ).type ,'()' )&&isscalar (s )
ifnumel (s (1 ).subs )>1 
error (message ('stats:classreg:learning:internal:ClassLabel:subsref:TooManyIndices' )); 
end
idx =s (1 ).subs {1 }; 
cl =classreg .learning .internal .ClassLabel (this .L (idx ,:)); 
cl .Type =this .Type ; 
[varargout {1 :nargout }]=cl ; 
elseifstrcmp (s (1 ).type ,'.' )
error (message ('stats:classreg:learning:internal:ClassLabel:subsref:PrivateAccess' )); 
else

[varargout {1 :nargout }]=subsref (this .L ,s ); 
end
end

function this =subsasgn (this ,s ,data )
ifisa (data ,'classreg.learning.internal.ClassLabel' )...
    &&isa (this .L ,'nominal' )
this .L =subsasgn (this .L ,s ,data .L ); 

elseifisempty (data )
ifstrcmp (s (1 ).type ,'()' )&&isscalar (s )
ifnumel (s (1 ).subs )>1 
error (message ('stats:classreg:learning:internal:ClassLabel:subsasgn:TooManyIndices' )); 
end
idx =s (1 ).subs {1 }; 
this .L (idx ,:)=[]; 
end

elseifthis .Type ==1 
if~ischar (data )&&...
    (~isa (data ,'classreg.learning.internal.ClassLabel' )||data .Type ~=1 )
error (message ('stats:classreg:learning:internal:ClassLabel:subsasgn:DataNotChar' )); 
end
ifisa (data ,'classreg.learning.internal.ClassLabel' )
data =labels (data ); 
end
ifstrcmp (s (1 ).type ,'()' )&&isscalar (s )
ifnumel (s (1 ).subs )>1 
error (message ('stats:classreg:learning:internal:ClassLabel:subsasgn:TooManyIndices' )); 
end
idx =s (1 ).subs {1 }; 
ifislogical (idx )
N =sum (idx ); 
else
N =numel (idx ); 
end
expsize =[N ,size (this .L ,2 )]; 
if~all (size (data )==expsize )
error (message ('stats:classreg:learning:internal:ClassLabel:subsasgn:CharSizeMismatch' )); 
end
this .L (idx ,:)=data ; 
else
this .L =subsasgn (this .L ,s ,data ); 
end

elseifthis .Type ==3 ||this .Type ==4 
if~islogical (data )&&~isnumeric (data )&&...
    (~isa (data ,'classreg.learning.internal.ClassLabel' )...
    ||(data .Type ~=3 &&data .Type ~=4 ))
error (message ('stats:classreg:learning:internal:ClassLabel:subsasgn:DataNotConvertibleToLogicalOrNumeric' )); 
end
ifisa (data ,'classreg.learning.internal.ClassLabel' )
data =labels (data ); 
end
this .L =subsasgn (this .L ,s ,data ); 

else
this .L =subsasgn (this .L ,s ,nominal (data )); 
end
end

function n =length (this )
n =size (this .L ,1 ); 
end

function n =numel (this )
n =size (this .L ,1 ); 
end

function tf =isempty (this )
tf =isempty (this .L ); 
end

function s =size (this ,dim )
ifnargin <2 
s =[numel (this ),1 ]; 
elseifdim ==1 
s =numel (this ); 
else
s =1 ; 
end
end

function a =vertcat (this ,varargin )
a =this .L ; 
fori =1 :nargin -1 
b =varargin {i }; 
a =vertcat (a ,b .L ); %#ok<AGROW> 
end
a =classreg .learning .internal .ClassLabel (a ); 
a .Type =this .Type ; 
end

function e =end(this ,k ,n )
e =builtin ('end' ,1 :numel (this ),k ,n ); 
end

function [varargout ]=ismember (this ,other )





if~isa (other ,'classreg.learning.internal.ClassLabel' )
error (message ('stats:classreg:learning:internal:ClassLabel:ismember:RhsMustBeClassLabel' )); 
end







N =numel (this ); 
ifN ==numel (other )&&all (this ==other )
varargout {1 }=true (N ,1 ); 
varargout {2 }=(1 :N )' ; 
return ; 
end

ifthis .Type ==1 &&other .Type ==1 
[varargout {1 :nargout }]=ismember (this .L ,other .L ,'rows' ); 
return ; 
end
if(this .Type ==3 ||this .Type ==4 )...
    &&(other .Type ==3 ||other .Type ==4 )
[varargout {1 :nargout }]=ismember (this .L ,other .L ); 
return ; 
end

ifthis .Type >0 &&this .Type <5 
n1 =nominal (this .L ); 
else
n1 =this .L ; 
end
ifother .Type >0 &&other .Type <5 
n2 =nominal (other .L ); 
else
n2 =other .L ; 
end
[varargout {1 :nargout }]=ismember (n1 ,n2 ); 
end

function C =membership (this ,classnames )








ifnargin <2 
classnames =levels (this ); 
elseif~isa (classnames ,'classreg.learning.internal.ClassLabel' )
classnames =levels (classreg .learning .internal .ClassLabel (classnames )); 
end
C =classreg .learning .internal .classCount (classnames ,this ); 
end

function [grp ,grpnames ,grplevels ]=grp2idx (this ,classnames )





ifnargin <2 
classnames =levels (this ); 
elseif~isa (classnames ,'classreg.learning.internal.ClassLabel' )
classnames =levels (classreg .learning .internal .ClassLabel (classnames )); 
end
[~,grp ]=ismember (this ,classnames ); 
grp (grp ==0 )=NaN ; 
ifnargout >1 
grpnames =cellstr (classnames ); 
end
ifnargout >2 
grplevels =classnames ; 
end
end

function a =horzcat (varargin ),throwUndefinedError (); end%#ok<STOUT> 
function a =ctranspose (varargin ),throwUndefinedError (); end%#ok<STOUT> 
function a =transpose (varargin ),throwUndefinedError (); end%#ok<STOUT> 
function a =permute (varargin ),throwUndefinedError (); end%#ok<STOUT> 
function a =reshape (varargin ),throwUndefinedError (); end%#ok<STOUT> 
function a =cat (varargin ),throwUndefinedError (); end%#ok<STOUT> 
end


methods (Static ,Hidden )
function this =loadobj (obj )
ifobj .Type ==3 &&isa (obj .L ,'nominal' )
this =classreg .learning .internal .ClassLabel (obj .L ==nominal (true )); 
else
this =classreg .learning .internal .ClassLabel (obj .L ); 
this .Type =obj .Type ; 
end
end
end
end


function throwUndefinedError ()
error (message ('stats:classreg:learning:internal:ClassLabel:throwUndefinedError' )); 
end

