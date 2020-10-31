classdef (Sealed )RepeatedMeasuresModel <matlab .mixin .CustomDisplay &classreg .learning .internal .DisallowVectorOps 







































properties (Hidden ,Constant )
SeparateMeans ='separatemeans' ; 
OrthogonalContrasts ='orthogonalcontrasts' ; 
MeanResponse ='meanresponse' ; 
end
properties (GetAccess =public ,SetAccess =private )





BetweenDesign 







DFE 
end
properties (Access =public )




















WithinModel =RepeatedMeasuresModel .SeparateMeans 
end
properties (Dependent )





WithinDesign 
end
properties (Dependent ,SetAccess =private )








BetweenModel 






ResponseNames 






WithinFactorNames 






BetweenFactorNames 




















Coefficients 














Covariance 














DesignMatrix 
end
properties (Access =private )
ResponseColumns 
Mauchly 
Epsilon 
TermAverages 
IsCat 
VariableRange 
WithinDesign_ 
Terms 
Missing 
X 
Y 
B 
Cov 
CoefNames 
CoefTerms 
TermNames 
Formula 
end



methods 
function tbl =grpstats (this ,grp ,stats )








































ifnargin <3 
stats ={'mean' ,'std' }; 
elseif~iscell (stats )
stats =convertStringsToChars (stats ); 
if~iscell (stats )
stats ={stats }; 
end
end
grouped =~(nargin <2 ||isempty (grp )); 
ifgrouped 
[grp ,iswithin ]=getgroup (this ,grp ); 
else
grp =[]; 
end
grp =convertStringsToChars (grp ); 




yname =genvarname ('y_' ,this .BetweenDesign .Properties .VariableNames ); 
timename =genvarname ('time' ,this .BetweenDesign .Properties .VariableNames ); 
tbl =this .BetweenDesign ; 
dstacked =stack (tbl ,this .ResponseColumns ,'newdatavar' ,yname ,'indexv' ,timename ); 

ifgrouped 

ny =sum (this .ResponseColumns ); 
nsubjects =size (tbl ,1 ); 
wrows =repmat ((1 :ny )' ,nsubjects ,1 ); 
dstacked =[dstacked ,this .WithinDesign (wrows ,grp (iswithin ))]; 
end


tbl =grpstats (dstacked ,grp ,stats ,'datavar' ,yname ); 




nstats =length (stats ); 
statNames =cell (1 ,nstats ); 
forj =1 :nstats 
statNames {j }=char (stats {j }); 
end
statNames (strcmp ('gname' ,statNames ))=[]; 
nstats =length (statNames ); 
vnames =tbl .Properties .VariableNames ; 
vnames {end-nstats }='GroupCount' ; 
vnames (end-nstats +1 :end)=statNames ; 
tbl .Properties .VariableNames =vnames ; 
tbl .Properties .RowNames ={}; 
end

function [tbl ,A ,C ,D ]=manova (this ,varargin )










































[varargin {:}]=convertStringsToChars (varargin {:}); 
okargs ={'By' ,'WithinModel' }; 
defaults ={'' ,this .WithinModel }; 
[by ,withinmodel ]=internal .stats .parseArgs (okargs ,defaults ,varargin {:}); 
ifstrcmp (withinmodel ,RepeatedMeasuresModel .OrthogonalContrasts )
error (message ('stats:fitrm:NoOrthogonalManova' )); 
end


[C ,wnames ]=makeTestC (this ,withinmodel ,true ,this .WithinDesign ,true ); 


ifisempty (by )

[A ,bnames ]=makeTestA (this ); 
else

[A ,bnames ]=makeTestABy (this ,by ); 
end


Beta =this .Coefficients {:,:}; 
SSE =this .DFE *this .Cov ; 
tbl =manovastats (this .X ,A ,Beta ,C ,0 ,SSE ,bnames ,wnames ); 
tbl .Properties .Description =getString (message ('stats:fitrm:TableDescrManova' )); 
D =0 ; 
end

function tbl =coeftest (this ,A ,C ,D )



















nx =size (this .X ,2 ); 
ny =size (this .Y ,2 ); 
checkMatrix ('A' ,A ,[],nx ); 
checkMatrix ('C' ,C ,ny ,[]); 
ifnargin <4 
D =0 ; 
else
checkMatrix ('D' ,D ,size (A ,1 ),size (C ,2 )); 
end

Beta =this .Coefficients {:,:}; 
SSE =this .DFE *this .Cov ; 
tbl =fourstats (this .X ,A ,Beta ,C ,D ,SSE ); 
end

function tbl =mauchly (this ,C )





































ifnargin <2 
tbl =this .Mauchly ; 
else
if~iscell (C )
C ={C }; 
end
Xmat =this .X ; 
ny =size (this .Y ,2 ); 
forj =1 :numel (C )
Cj =C {j }; 
checkMatrix ('C' ,Cj ,ny ,[]); 
tbl (j ,:)=mauchlyTest (this .Cov ,size (Xmat ,1 ),rank (Xmat ),Cj ); 
end
end
end

function tbl =epsilon (this ,C )





































ifnargin <2 
tbl =this .Epsilon ; 
else
if~iscell (C )
C ={C }; 
end
Xmat =this .X ; 
ny =size (this .Y ,2 ); 
forj =1 :numel (C )
Cj =C {j }; 
checkMatrix ('C' ,Cj ,ny ,[]); 
[~,tbl (j ,:)]=mauchlyTest (this .Cov ,size (Xmat ,1 ),rank (Xmat ),Cj ); 
end
end
end

function [tbl ,Q ]=anova (this ,varargin )

















































[varargin {:}]=convertStringsToChars (varargin {:}); 
okargs ={'WithinModel' }; 
defaults ={RepeatedMeasuresModel .MeanResponse }; 
wm =internal .stats .parseArgs (okargs ,defaults ,varargin {:}); 
ifisempty (wm )
wm =RepeatedMeasuresModel .MeanResponse ; 
end

ny =size (this .Y ,2 ); 
d =this .BetweenDesign (~this .Missing ,:); 
yname =genvarname ('y' ,this .BetweenDesign .Properties .VariableNames ); 
newformula =sprintf ('%s ~ %s' ,yname ,this .Formula .LinearPredictor ); 
ifisnumeric (wm )


checkMatrix ('WithinModel' ,wm ,ny ,[]); 
Q =wm ; 
contrastNames =textscan (sprintf ('Contrast%d\n' ,1 :size (Q ,2 )),'%s' ); 
contrastNames =contrastNames {1 }; 
else


[C ,contrastNames ]=makeTestC (this ,wm ,false ); 
Q =bsxfun (@rdivide ,C ,sqrt (sum (C .^2 ,1 ))); 
end
tbl =contrastanova (d ,newformula ,this .Y *Q ,contrastNames ,false ,yname ); 
tbl .Properties .Description =getString (message ('stats:fitrm:TableDescrAnova' )); 
end

function [tbl ,A ,C ,D ]=ranova (this ,varargin )






























































[varargin {:}]=convertStringsToChars (varargin {:}); 
okargs ={'WithinModel' }; 
defaults ={RepeatedMeasuresModel .SeparateMeans }; 
wm =internal .stats .parseArgs (okargs ,defaults ,varargin {:}); 
ifisempty (wm )
wm =RepeatedMeasuresModel .SeparateMeans ; 
elseifisnumeric (wm )
checkMatrix ('WithinModel' ,wm ,size (this .Y ,2 ),[]); 
end

ifisempty (this .WithinDesign )||size (this .WithinDesign ,2 )>1 
timename =genvarname ('Time' ,this .BetweenDesign .Properties .VariableNames ); 
else
timename =this .WithinDesign .Properties .VariableNames {1 }; 
end


[A ,Anames ]=makeTestA (this ); 
[C ,Cnames ]=makeTestC (this ,wm ,true ,[],true ); 
D =0 ; 

ifiscell (C )
dscell =cell (size (C )); 
nc =numel (C ); 
na =numel (Anames ); 
rownames =cell (nc *(na +1 ),1 ); 
baserow =0 ; 
forj =1 :numel (C )
tblj =ranovastats (this ,C {j },A ,Anames ,D ,Cnames {j }); 
rownames (baserow +(1 :na +1 ),:)=tblj .Properties .RowNames ; 
dscell {j }=tblj ; 
baserow =baserow +na +1 ; 
end
tbl =vertcat (dscell {:}); 
tbl .Properties .RowNames =rownames ; 
else
tbl =ranovastats (this ,C ,A ,Anames ,D ,timename ); 
end
end

function hout =plot (this ,varargin )






























[varargin {:}]=convertStringsToChars (varargin {:}); 
markers ={'s' ,'o' ,'*' ,'x' ,'+' ,'d' ,'^' ,'v' ,'>' ,'<' ,'p' ,'h' }; 
okargs ={'Group' ,'Marker' ,'Color' ,'LineStyle' }; 
defaults ={'' ,markers ,'' ,{'-' }}; 
[group ,markers ,cmap ,styles ]=...
    internal .stats .parseArgs (okargs ,defaults ,varargin {:}); 
w =this .WithinDesign ; 
if~isempty (w )&&size (w ,2 )==1 ...
    &&varfun (@(x )isnumeric (x ),w ,'OutputFormat' ,'uniform' )
x =w {:,1 }; 
xticks =[]; 
else
x =(1 :size (this .Y ,2 )); 
xticks =x ; 
end

grouped =~isempty (group ); 
[ngroups ,grpidx ,grpname ]=makegroup (group ,this ); 
[cmap ,markers ,styles ]=regularizePlotArgs (cmap ,markers ,styles ,ngroups ); 
newplot ; 
h =[]; 
hleg =[]; 
forj =1 :ngroups 
idx =grpidx ==j ; 
jcolor =1 +mod (j -1 ,size (cmap ,1 )); 
jmarker =1 +mod (j -1 ,numel (markers )); 
jstyle =1 +mod (j -1 ,numel (styles )); 
hj =line (x ,this .Y (idx ,:)' ,'Color' ,cmap (jcolor ,:),...
    'Marker' ,markers {jmarker },'LineStyle' ,styles {jstyle }); 
h =[h ; hj ]; %#ok<AGROW> 
hleg =[hleg ; hj (1 )]; %#ok<AGROW> 
end
ifgrouped 
legend (hleg ,grpname ,'Location' ,'best' )
end
xlim =get (gca ,'XLim' ); 
dx =diff (xlim )/20 ; 
set (gca ,'XLim' ,[xlim (1 )-dx ,xlim (2 )+dx ])
if~isempty (xticks )
set (gca ,'XTick' ,xticks ); 
end
ifnargout >0 
hout =h ; 
end
end

function hout =plotprofile (this ,x ,varargin )































x =convertStringsToChars (x ); 
[varargin {:}]=convertStringsToChars (varargin {:}); 
okargs ={'Group' ,'Marker' ,'Color' ,'LineStyle' }; 
defaults ={{},{'o' },'' ,{'-' }}; 
[group ,markers ,cmap ,styles ]=...
    internal .stats .parseArgs (okargs ,defaults ,varargin {:}); 

if~internal .stats .isString (x ,false )||~isVariable (this ,x )
error (message ('stats:fitrm:ValueMustBeFactor' ,'X' )); 
end
x =char (x ); 
ifiscell (group )
group =group (:)' ; 
vars =[{x },group ]; 
else
vars ={x ,group }; 
end


m =margmean (this ,vars ); 
m =sortrows (m ,fliplr (vars )); 


xvals =m .(x ); 
ifischar (xvals )
xvals =cellstr (xvals ); 
end
[ux ,~,uidx ]=unique (xvals ,'stable' ); 
nx =length (ux ); 
xloc =1 :nx ; 
if~isnumeric (xvals )
xvals =uidx ; 
end

ifisempty (group )

h =plot (xvals ,m .Mean ,'o-' ); 
else

nrows =size (m ,1 ); 
R =nx ; 
C =nrows /R ; 
means =reshape (m .Mean ,[R ,C ]); 
h =plot (xvals (1 :nx ),means ,'o-' ); 
ifiscell (group )
gvals =cell (size (group )); 
forj =1 :numel (group )
gvals {j }=m .(group {j }); 
end
[~,~,gcell ]=internal .stats .mgrp2idx (fliplr (gvals )); 
gcell =fliplr (gcell ); 
GN =gcell (:,1 ); 
forj =2 :size (gcell ,2 ); 
GN =strcat (GN ,',' ,gcell (:,j )); 
end
varnames =sprintf ('%s,' ,group {:}); 
varnames (end)=[]; 
else
gvals =m .(group ); 
[~,GN ]=grp2idx (gvals ); 
varnames =group ; 
end
forj =1 :length (h )
set (h (j ),'DisplayName' ,sprintf ('%s=%s' ,varnames ,GN {j }))
end
legend ('Location' ,'best' ); 
end
[cmap ,markers ,styles ]=regularizePlotArgs (cmap ,markers ,styles ,length (h )); 
forj =1 :length (h )
jcolor =1 +mod (j -1 ,size (cmap ,1 )); 
jmarker =1 +mod (j -1 ,numel (markers )); 
jstyle =1 +mod (j -1 ,numel (styles )); 
set (h (j ),'Color' ,cmap (jcolor ,:),...
    'Marker' ,markers {jmarker },'LineStyle' ,styles {jstyle }); 
end

ifisa (ux ,'categorical' )
set (gca ,'XTick' ,xloc ,'XTickLabel' ,char (ux )); 
end



xmin =min (xvals ); 
xmax =max (xvals ); 
dx =(xmax -xmin )/20 ; 
set (gca ,'XLim' ,[xmin -dx ,xmax +dx ])
xlabel (x ); 
ylabel (getString (message ('stats:fitrm:EstimatedMarginalMeans' ))); 

ifnargout >0 
hout =h ; 
end
end

function ds =margmean (this ,grp ,varargin )
























grp =convertStringsToChars (grp ); 
[varargin {:}]=convertStringsToChars (varargin {:}); 
okargs ={'Alpha' }; 
defaults ={0.05 }; 
alpha =...
    internal .stats .parseArgs (okargs ,defaults ,varargin {:}); 
checkAlpha (alpha ); 



[grp ,iswithin ]=getgroup (this ,grp ,true ); 


[A ,Bff ,~,cap ]=emmMakeA (this ,grp ,iswithin ); 


[C ,Wff ]=emmMakeC (this ,grp ,iswithin ); 


[mn ,se ]=meanCalculate (this ,A ,C ); 


ds =emmMakeDataset (Bff ,Wff ,grp ,mn (:),se (:),this .DFE ,alpha ); 
ds .Properties .Description =sprintf ('%s\n%s' ,...
    getString (message ('stats:fitrm:EstimatedMarginalMeans' )),cap ); 
end

function [ypred ,yci ]=predict (this ,ds ,varargin )



















































[varargin {:}]=convertStringsToChars (varargin {:}); 
okargs ={'Alpha' ,'WithinDesign' ,'WithinModel' }; 
defaults ={0.05 ,this .WithinDesign ,this .WithinModel }; 
[alpha ,withindesign ,withinmodel ,setflag ]=...
    internal .stats .parseArgs (okargs ,defaults ,varargin {:}); 
checkAlpha (alpha ); 
ifisa (withindesign ,'dataset' )
withindesign =dataset2table (withindesign ); 
elseifisrow (withindesign )&&~istable (withindesign )&&numel (this .ResponseNames )>1 
withindesign =withindesign (:); 
end



ifnargin <2 
A =this .X ; 
else
ifisa (ds ,'dataset' )
ds =dataset2table (ds ); 
elseif~isa (ds ,'table' )
error (message ('stats:fitrm:TableRequired2' )); 
end
[terms ,iscat ,vrange ]=dataset2terms (this ,ds ); 
A =classreg .regr .modelutils .designmatrix (ds ,...
    'Model' ,terms ,...
    'DummyVarCoding' ,'effects' ,...
    'CategoricalVars' ,iscat ,...
    'CategoricalLevels' ,vrange ); 
end

ifisempty (withindesign )||strcmp (withinmodel ,RepeatedMeasuresModel .SeparateMeans )
if~isempty (withindesign )&&setflag .WithinDesign 

warning (message ('stats:fitrm:WithinDesignIgnored' )); 
end
C =eye (size (this .B ,2 )); 
else


[withindesign ,time ]=verifyWithinDesign (this ,withinmodel ,withindesign ); 
switch(withinmodel )
case RepeatedMeasuresModel .OrthogonalContrasts 

W =fliplr (vander (time (:))); 
[Q ,R ]=qr (W ,0 ); 


ny =size (W ,2 ); 
V =ones (numel (withindesign ),ny ); 
forj =2 :ny 
V (:,j )=withindesign .^(j -1 ); 
end
otherwise
W =makeTestC (this ,withinmodel ,false ,this .WithinDesign ); 
[Q ,R ]=qr (W ,0 ); 
V =makeTestC (this ,withinmodel ,false ,withindesign ); 
end



C =Q /R ' *V ' ; 
end
[ypred ,yse ]=meanCalculate (this ,A ,C ); 
ypred =ypred ' ; 
yse =yse ' ; 
width =yse *-tinv (alpha /2 ,this .DFE ); 
yci =cat (3 ,ypred -width ,ypred +width ); 
end

function ysim =random (this ,varargin )



















ifnargin >2 
error (message ('MATLAB:TooManyInputs' ))
end
ymean =predict (this ,varargin {:}); 
ysim =mvnrnd (ymean ,this .Cov ); 
end

function tbl =multcompare (this ,var ,varargin )

































var =convertStringsToChars (var ); 
[varargin {:}]=convertStringsToChars (varargin {:}); 
okargs ={'Alpha' ,'ComparisonType' ,'By' }; 
defaults ={0.05 ,'tukey-kramer' ,{}}; 
[alpha ,ctype ,by ]=...
    internal .stats .parseArgs (okargs ,defaults ,varargin {:}); 
checkAlpha (alpha ); 


[var ,iswithin ]=getgroup (this ,var ,true ); 
if~isscalar (iswithin )
error (message ('stats:fitrm:ValueMustBeVar' ,'VAR' )); 
end
isby =~isempty (by ); 
ifisby 
[by ,bywithin ]=getgroup (this ,by ,true ); 
if~isscalar (bywithin )
error (message ('stats:fitrm:ValueMustBeVar' ,'''By''' )); 
elseifismember (by ,var )
error (message ('stats:fitrm:ByNotDistinct' )); 
end
var =[by ,var ]; 
iswithin =[bywithin ,iswithin ]; 
end



[A ,Anames ,Alevels ]=emmMakeA (this ,var ,iswithin ); 
[C ,Cnames ,Clevels ]=emmMakeC (this ,var ,iswithin ); 
ifiswithin (end)
numGroups =Clevels (end); 
[C ,diffNames ]=diffmatrix (C ' ,Cnames ,numGroups ); 
C =C ' ; 
else
numGroups =Alevels (end); 
[A ,diffNames ]=diffmatrix (A ,Anames ,numGroups ); 
end
reorder =[]; 
ifisby 
ifiswithin (end)&&~isempty (Anames )

numA =size (Anames ,1 ); 
numDiff =size (diffNames ,1 ); 
rows =repmat ((1 :numA )' ,1 ,numDiff )' ; 
diffNames =[Anames (rows (:),:),repmat (diffNames ,numA ,1 )]; 
elseif~iswithin (end)&&~isempty (Cnames )

numC =size (Cnames ,1 ); 
numDiff =size (diffNames ,1 ); 
rows =repmat ((1 :numC )' ,1 ,numDiff )' ; 
diffNames =[Cnames (rows (:),:),repmat (diffNames ,numC ,1 )]; 
numResults =size (diffNames ,1 ); 
ifnumC >0 
reorder =reshape (1 :numResults ,numC ,numResults /numC )' ; 
reorder =reorder (:); 
end
end
end


[mn ,se ]=meanCalculate (this ,A ,C ); 
mn =mn (:); 
se =se (:); 
t =mn ./se ; 
df =this .DFE ; 


[crit ,pval ]=internal .stats .getcrit (ctype ,alpha ,df ,numGroups ,t ); 


width =se *crit ; 
results =[mn ,se ,pval ,mn -width ,mn +width ]; 
if~isempty (reorder )
results =results (reorder ,:); 
end
tbl =[diffNames ,...
    array2table (results ,...
    'VariableNames' ,{'Difference' ,'StdErr' ,'pValue' ,'Lower' ,'Upper' })]; 

end
end


methods 
function this =set .WithinDesign (this ,w )


if~isempty (w )
ny =size (this .Y ,2 ); 
oldnames =this .BetweenDesign .Properties .VariableNames ; 
check =true ; 
ifisa (w ,'dataset' )
w =dataset2table (w ); 
elseif~isa (w ,'table' )
ifisrow (w )&&ny >1 
w =w (:); 
end
ifiscolumn (w )
varnames ={'Time' }; 
else
varnames =internal .stats .numberedNames ('w' ,1 :size (w ,2 )); 
end
varnames =matlab .lang .makeUniqueStrings (varnames ,oldnames ); 
if~ismatrix (w )
error (message ('stats:fitrm:WithinMatrix' )); 
end
w =array2table (w ,'VariableNames' ,varnames ); 
check =false ; 
end
ifsize (w ,1 )~=ny 
error (message ('stats:fitrm:WithinBadLength' ,size (w ,1 ),ny )); 
end
ifcheck &&any (ismember (w .Properties .VariableNames ,oldnames ))
error (message ('stats:fitrm:WithinBadNames' )); 
end
w .Properties .RowNames =this .ResponseNames ; 
ifany (any (ismissing (w )))
error (message ('stats:fitrm:NoMissing' ,'WithinDesign' )); 
end
end
this .WithinDesign_ =w ; 
end
function wd =get .WithinDesign (this )
wd =this .WithinDesign_ ; 
end
function this =set .WithinModel (this ,w )
w =convertStringsToChars (w ); 
if~isempty (w )&&~(ischar (w )&&ismember (w ,{RepeatedMeasuresModel .SeparateMeans ,RepeatedMeasuresModel .OrthogonalContrasts }))
makeTestC (this ,w ); 
end
this .WithinModel =w ; 
end
function w =get .WithinFactorNames (this )
ifisempty (this .WithinDesign )
w ={}; 
else
w =this .WithinDesign .Properties .VariableNames ; 
end
end
function w =get .BetweenModel (this )
w =this .Formula .LinearPredictor ; 
end
function w =get .BetweenFactorNames (this )
factorCols =any (this .Terms ,1 ); 
w =this .BetweenDesign .Properties .VariableNames (factorCols ); 
end
function w =get .ResponseNames (this )
w =this .BetweenDesign .Properties .VariableNames (this .ResponseColumns ); 
end
function c =get .Covariance (this )
rnames =this .ResponseNames ; 
c =array2table (this .Cov ,'VariableNames' ,rnames ,'RowNames' ,rnames ); 
c .Properties .Description =getString (message ('stats:fitrm:EstimatedCovariance' )); 
end
function c =get .Coefficients (this )
rnames =this .ResponseNames ; 
cnames =this .CoefNames ; 
c =array2table (this .B ,'VariableNames' ,rnames ,'RowNames' ,cnames ); 
c .Properties .Description =getString (message ('stats:fitrm:CoefficientEstimates' )); 
end
function c =get .DesignMatrix (this )
c =this .X ; 
end
end


methods (Static ,Hidden )
function this =fit (ds ,model ,varargin )




okargs ={'WithinDesign' ,'WithinModel' }; 
defaults ={'' ,RepeatedMeasuresModel .SeparateMeans }; 
[withindesign ,withinmodel ]=...
    internal .stats .parseArgs (okargs ,defaults ,varargin {:}); 

ifisa (ds ,'dataset' )
ds =dataset2table (ds ); 
elseif~isa (ds ,'table' )
error (message ('stats:fitrm:TableRequired' )); 
end



this =RepeatedMeasuresModel (); 
varNames =ds .Properties .VariableNames ; 
formula =classreg .regr .MultivariateLinearFormula (model ,varNames ); 
responseCols =names2cols (formula .ResponseName ,varNames ); 
f =@(var )isvector (var )&&isnumeric (var )&&isreal (var ); 
ok =varfun (f ,ds ,'InputVariables' ,responseCols ,'OutputFormat' ,'uniform' ); 
if~all (ok )
responseCols =find (responseCols ); 
bad =varNames (responseCols (~ok )); 
error (message ('stats:fitrm:BadResponse' ,bad {1 })); 
end


missing =findMissing (ds ,formula .Terms ,responseCols ); 

this .ResponseColumns =responseCols ; 
Ymat =ds {~missing ,responseCols }; 



iscat =varfun (@internal .stats .isDiscreteVar ,ds ,'OutputFormat' ,'uniform' ); 
nvars =size (ds ,2 ); 
vrange =cell (nvars ,1 ); 
fori =1 :nvars 
vrange {i }=getVarRange (ds .(varNames {i }),iscat (i ),missing ); 
end



[Xmat ,terms ,~,coefTerms ,coefNames ,termNames ]...
    =classreg .regr .modelutils .designmatrix (ds (~missing ,:),...
    'Model' ,formula .Terms ,...
    'DummyVarCoding' ,'effects' ,...
    'CategoricalVars' ,iscat ,...
    'CategoricalLevels' ,vrange ); 
ifrank (Xmat )<size (Xmat ,2 )
error (message ('stats:fitrm:NotFullRank' )); 
end

ifany (any (terms (:,responseCols )))
factorCols =any (terms ,1 ); 
bad =varNames (responseCols &factorCols ); 
error (message ('stats:fitrm:ResponseAndPredictor' ,bad {1 })); 
end



opt .RECT =true ; 
Bmat =linsolve (Xmat ,Ymat ,opt ); 

Resid =Ymat -Xmat *Bmat ; 
dfe =size (Xmat ,1 )-size (Xmat ,2 ); 
Covar =(Resid ' *Resid )/dfe ; 



this .TermAverages =calcTermAverages (ds ,Xmat ,formula .Terms ,coefTerms ,iscat ); 

this .X =Xmat ; 
this .Y =Ymat ; 
this .Missing =missing ; 
this .B =Bmat ; 
this .Cov =Covar ; 
this .CoefNames =coefNames ; 
this .CoefTerms =coefTerms ; 
this .TermNames =termNames ; 
this .Formula =formula ; 
this .BetweenDesign =ds ; 
this .IsCat =iscat ; 
this .VariableRange =vrange ; 
this .DFE =dfe ; 
this .Terms =terms ; 


[this .Mauchly ,this .Epsilon ]=mauchlyTest (this .Cov ,size (Xmat ,1 ),rank (Xmat )); 

ifisempty (withindesign )
withindesign =1 :size (Ymat ,2 ); 
end
this .WithinDesign =withindesign ; 
this .WithinModel =withinmodel ; 
end
end


methods (Access =protected )
function this =RepeatedMeasuresModel ()
end
function [mn ,se ]=meanCalculate (this ,A ,C )




mn =(A *this .B *C )' ; 


ifnargout >=2 
S =this .Cov ; 
XtX =this .X ' *this .X ; 
se =sqrt (sum (A .*(XtX \A ' )' ,2 )*sum (C ' .*(S *C )' ,2 )' )' ; 
end
end
function tbl =ranovastats (this ,C ,Acell ,Anames ,D ,timename )
Beta =this .Coefficients {:,:}; 
XX =this .DesignMatrix ; 
[N ,k ]=size (XX ); 



[C ,~]=qr (C ,0 ); 
E =(N -k )*C ' *this .Covariance {:,:}*C ; 


r =size (C ,2 ); 
nterms =numel (Acell ); 
dfe =(N -k )*r ; 
DF =[ones (nterms ,1 ); dfe ]; 
SumSq =[zeros (nterms ,1 ); trace (E )]; 
MeanSq =SumSq ./DF ; 
F =MeanSq /MeanSq (end); 
pValue =.5 *ones (nterms +1 ,1 ); 
pValueGG =.5 *ones (nterms +1 ,1 ); 
pValueHF =.5 *ones (nterms +1 ,1 ); 
pValueLB =.5 *ones (nterms +1 ,1 ); 
Eps =epsilon (this ,C ); 
forj =1 :nterms 
A =Acell {j }; 
s =size (A ,1 ); 



H =makeH (A ,Beta ,C ,D ,XX ); 


SumSq (j )=trace (H ); 
DF (j )=s *r ; 
MeanSq (j )=SumSq (j )/DF (j ); 
F (j )=MeanSq (j )/MeanSq (end); 
[pValue (j ),pValueGG (j ),pValueHF (j ),pValueLB (j )]...
    =pValueCorrections (F (j ),DF (j ),dfe ,Eps ); 
end
absent =((1 :nterms +1 )' ==nterms +1 ); 

tbl =table (SumSq ,DF ,MeanSq ); 
tbl .F =internal .stats .DoubleTableColumn (F ,absent ); 
tbl .pValue =internal .stats .DoubleTableColumn (pValue ,absent ); 
tbl .pValueGG =internal .stats .DoubleTableColumn (pValueGG ,absent ); 
tbl .pValueHF =internal .stats .DoubleTableColumn (pValueHF ,absent ); 
tbl .pValueLB =internal .stats .DoubleTableColumn (pValueLB ,absent ); 

if~isequal (timename ,'(Intercept)' )
Anames =strcat (Anames ,':' ,timename ); 
errorname =sprintf ('%s(%s)' ,'Error' ,timename ); 
else
errorname ='Error' ; 
end
tbl .Properties .RowNames =[Anames ,errorname ]; 
end
function [grp ,iswithin ]=getgroup (this ,grp ,catonly )
[tf ,grp ]=internal .stats .isStrings (grp ); 
if~tf 
error (message ('stats:fitrm:GroupingNotCell' )); 
end
[tf ,iswithin ,isbetween ,bloc ]=isVariable (this ,grp ); 
if~all (tf )
bad =grp (~(iswithin |isbetween )); 
error (message ('stats:fitrm:GroupingNotRecognized' ,bad {1 })); 
end
ifnargin >=3 &&catonly 
iscat =this .IsCat ; 
ifany (~iscat (bloc (isbetween )))
error (message ('stats:fitrm:GroupingNotCategorical' )); 
end
end
end
function [tf ,iswithin ,isbetween ,bloc ]=isVariable (this ,var )
iswithin =ismember (var ,this .WithinFactorNames ); 
[isbetween ,bloc ]=ismember (var ,this .BetweenDesign .Properties .VariableNames ); 
isresponse =ismember (var ,this .ResponseNames ); 
isbetween (isresponse )=false ; 
tf =(iswithin |isbetween ); 
end
function [withindesign ,time ]=verifyWithinDesign (this ,withinmodel ,withindesign )
time =[]; 
oldw =this .WithinDesign ; 
switch(withinmodel )
case RepeatedMeasuresModel .OrthogonalContrasts 

ifsize (oldw ,2 )~=1 
error (message ('stats:fitrm:NoTimeProperty' )); 
end
time =oldw {:,1 }; 
if~(isnumeric (time )&&isvector (time )&&isreal (time ))
error (message ('stats:fitrm:NoTimeProperty' )); 
end


ifsize (withindesign ,2 )~=1 
error (message ('stats:fitrm:NoTimeArgument' )); 
end
ifistable (withindesign )
withindesign =withindesign {:,1 }; 
end
if~(isnumeric (withindesign )&&isvector (withindesign )&&isreal (withindesign ))
error (message ('stats:fitrm:NoTimeArgument' )); 
end
withindesign =withindesign (:); 
otherwise
[ok ,withindesign ]=verifyDesign (oldw ,withindesign ); 
if~ok 
error (message ('stats:fitrm:IncompatibleWithinDesign' )); 
end
end
end


function group =getPropertyGroups (~)

titles =cell (3 ,1 ); 
titles {1 }=sprintf ('%s:' ,getString (message ('stats:fitrm:DisplayBetween' ))); 
plist1 ={'BetweenDesign' ,'ResponseNames' ,'BetweenFactorNames' ,'BetweenModel' }; 

titles {2 }=sprintf ('%s:' ,getString (message ('stats:fitrm:DisplayWithin' ))); 
plist2 ={'WithinDesign' ,'WithinFactorNames' ,'WithinModel' }; 

titles {3 }=sprintf ('%s:' ,getString (message ('stats:fitrm:DisplayEstimates' ))); 
plist3 ={'Coefficients' ,'Covariance' }; 


ifmatlab .internal .display .isHot 
forj =1 :3 
titles {j }=sprintf ('<strong>%s</strong>' ,titles {j }); 
end
end

group (1 )=matlab .mixin .util .PropertyGroup (plist1 ,titles {1 }); 
group (2 )=matlab .mixin .util .PropertyGroup (plist2 ,titles {2 }); 
group (3 )=matlab .mixin .util .PropertyGroup (plist3 ,titles {3 }); 
end
end
end


function missing =findMissing (t ,terms ,responseCols )

useCols =any (terms ,1 ); 
useCols (responseCols )=true ; 
missing =any (ismissing (t (:,useCols )),2 ); 
end

function ds =emmMakeDataset (Bff ,Wff ,grp ,m ,se ,dfe ,alpha )


ifisempty (Bff )
ds =Wff ; 
elseifisempty (Wff )
ds =Bff ; 
else
nb =size (Bff ,1 ); 
nw =size (Wff ,1 ); 
Brows =kron ((1 :nb )' ,ones (nw ,1 )); 
Wrows =repmat ((1 :nw )' ,nb ,1 ); 
ds =[Bff (Brows ,:),Wff (Wrows ,:)]; 
end
ds =ds (:,grp ); 

t =-tinv (alpha /2 ,dfe ); 
ds .Mean =m ; 
ds .StdErr =se ; 
ds .Lower =m -t *se ; 
ds .Upper =m +t *se ; 

ds =sortrows (ds ,grp ); 
end

function [X ,termnames ]=getTermAverage (this ,termNums )
iscat =this .IsCat ; 
savedAverages =this .TermAverages ; 


terms =this .Formula .Terms ; 
terms (:,iscat )=0 ; 
[~,loc ]=ismember (terms ,savedAverages {1 },'rows' ); 


termAverages =savedAverages {2 }(loc )' ; 

coefTerms =this .CoefTerms ; 
coefTerms =coefTerms (ismember (coefTerms ,termNums )); 
X =termAverages (coefTerms ); 

ifnargout >=2 
termnames =classreg .regr .modelutils .terms2names (savedAverages {1 },this .Formula .VariableNames ); 
termnames =termnames (loc (coefTerms )); 
end
end

function cols =names2cols (str ,varNames )
ranges =textscan (str ,'%s' ,'delimiter' ,' ,' ,'MultipleDelimsAsOne' ,true ); 
ranges =ranges {1 }; 
cols =false (1 ,length (varNames )); 
forj =1 :length (ranges )
range =ranges {j }; 
loc =find (range =='-' ); 
ifisempty (loc )
cols (strcmp (range ,varNames ))=true ; 
else
loc1 =find (strcmp (range (1 :loc -1 ),varNames )); 
loc2 =find (strcmp (range (loc +1 :end),varNames )); 
cols (min (loc1 ,loc2 ):max (loc1 ,loc2 ))=true ; 
end
end
end

function range =getVarRange (v ,asCat ,excl )
v (excl ,:)=[]; 
ifasCat 
ifisa (v ,'categorical' )


range =unique (v (:)); 
range =range (~isundefined (range )); 

else



[~,~,range ]=grp2idx (v ); 

end
if~ischar (range )
range =range (:)' ; 
end
elseifisnumeric (v )||islogical (v )
range =[min (v ,[],1 ),max (v ,[],1 )]; 
else
range =NaN (1 ,2 ); 
end
end

function ds =manovastats (X ,A ,B ,C ,D ,SSE ,varargin )






ifnargin <5 
D =0 ; 
end

if~iscell (A )
A ={A }; 
end
if~iscell (C )
C ={C }; 
end
na =numel (A ); 
nc =numel (C ); 

dscell =cell (na ,nc ); 
fork =1 :na 
forj =1 :nc 
dscell {k ,j }=fourstats (X ,A {k },B ,C {j },D ,SSE ); 
end
end
ifna *nc >1 
ds =combinemanovatables (dscell ,varargin {:}); 
else
ds =dscell {1 }; 
end
end

function ds =fourstats (X ,A ,B ,C ,D ,SSE )




[H ,q ]=makeH (A ,B ,C ,D ,X ); 


E =C ' *SSE *C ; 

checkHE (H ,E ); 

p =rank (E +H ); 
s =min (p ,q ); 
v =size (X ,1 )-rank (X ); 
ifp ^2 +q ^2 >5 
t =sqrt ((p ^2 *q ^2 -4 )/(p ^2 +q ^2 -5 )); 
else
t =1 ; 
end
u =(p *q -2 )/4 ; 
r =v -(p -q +1 )/2 ; 
m =(abs (p -q )-1 )/2 ; 
n =(v -p -1 )/2 ; 




lam =eig (H ,E ); 
mask =(lam <0 )&(lam >-100 *eps (max (abs (lam )))); 
lam (mask )=0 ; 
L_df1 =p *q ; 
L_df2 =r *t -2 *u ; 
ifisreal (lam )&&all (lam >=0 )&&L_df2 >0 
L =prod (1 ./(1 +lam )); 
else
L =NaN ; 
L_df2 =max (0 ,L_df2 ); 
end
L1 =L ^(1 /t ); 
L_F =((1 -L1 )/L1 )*(r *t -2 *u )/(p *q ); 
L_rsq =1 -L1 ; 




theta =eig (H ,H +E ); 
V =sum (theta ); 
ifs >V 
V_F =((2 *n +s +1 )/(2 *m +s +1 ))*V /(s -V ); 
V_rsq =V /s ; 
else
V_F =NaN ; 
V_rsq =NaN ; 
end
V_df1 =s *(2 *m +s +1 ); 
V_df2 =s *(2 *n +s +1 ); 




ifisreal (lam )&&all (lam >=0 )
U =sum (lam ); 
else
U =NaN ; 
n (n <0 )=NaN ; 
end
b =(p +2 *n )*(q +2 *n )/(2 *(2 *n +1 )*(n -1 )); 
c =(2 +(p *q +2 )/(b -1 ))/(2 *n ); 
ifn >0 
U_F =(U /c )*(4 +(p *q +2 )/(b -1 ))/(p *q ); 
else
U_F =U *2 *(s *n +1 )/(s ^2 *(2 *m +s +1 )); 
end
U_rsq =U /(U +s ); 
U_df1 =s *(2 *m +s +1 ); 
U_df2 =2 *(s *n +1 ); 





ifisempty (lam )
R =NaN ; 
else
R =max (lam ); 
end
r =max (p ,q ); 
R_F =R *(v -r +q )/r ; 
R_rsq =R /(1 +R ); 
R_df1 =r ; 
R_df2 =v -r +q ; 



Statistic =categorical ({'Pillai' ,'Wilks' ,'Hotelling' ,'Roy' }' ); 
Value =[V ; L ; U ; R ]; 
F =[V_F ; L_F ; U_F ; R_F ]; 
RSquare =[V_rsq ; L_rsq ; U_rsq ; R_rsq ]; 
df1 =[V_df1 ; L_df1 ; U_df1 ; R_df1 ]; 
df2 =[V_df2 ; L_df2 ; U_df2 ; R_df2 ]; 
ds =table (Statistic ,Value ,F ,RSquare ,df1 ,df2 ); 
ds .pValue =fcdf (F ,df1 ,df2 ,'upper' ); 
end

function [tbl ,B ]=contrastanova (d ,formula ,Y ,Ynames ,drop ,yname )
ifnargin <5 
drop =false ; 
end
ifnargin <6 
yname ='y' ; 
end

ny =size (Y ,2 ); 
C =cell (1 ,ny ); 
B =zeros (0 ,ny ); 
forj =1 :ny 
d .(yname )=Y (:,j ); 
lm =LinearModel .fit (table2dataset (d ),formula ,'DummyVarCoding' ,'effects' ); 
C {j }=anovawithconstant (lm ); 
b =lm .Coefficients .Estimate ; 
B (1 :length (b ),j )=b ; 
end
ifdrop 
C (1 )=[]; 
Ynames (1 )=[]; 
end
tbl =combinemanovatables (C ,{},Ynames ); 
end

function a =anovawithconstant (lm )


a =anova (lm ,'components' ,3 ); 
ifisa (a ,'dataset' )
a =dataset2table (a ); 
end


p0 =lm .Coefficients .pValue (1 ); 
f0 =lm .Coefficients .tStat (1 )^2 ; 
mse =a .MeanSq (end); 
ms0 =f0 *mse ; 
ss0 =ms0 ; 


a =a ([1 :end,end],:); 
a .Properties .RowNames {end}='constant' ; 
a .SumSq (end)=ss0 ; 
a .DF (end)=1 ; 
a .MeanSq (end)=ms0 ; 
a .F (end)=f0 ; 
a .pValue (end)=p0 ; 


a =a ([end,1 :end-1 ],:); 


n =size (a ,1 ); 
absent =(1 :n )' ==n ; 
a .F =internal .stats .DoubleTableColumn (a .F ,absent ); 
a .pValue =internal .stats .DoubleTableColumn (a .pValue ,absent ); 
end

function D =combinemanovatables (C ,bnames ,wnames )








first =C {1 }; 
nr =size (first ,1 ); 
ifnargin <2 ||isempty (bnames )
bnames =first .Properties .RowNames ; 
nr =1 ; 
nb =size (first ,1 ); 
else
nb =length (bnames ); 
end
ifnargin <3 ||isempty (wnames )
wnames ={'Within' }; 
end
nw =length (wnames ); 


B =numel (C ); 
D2 =repmat (C {1 },nw ,1 ); 
numrows =size (C {1 },1 ); 
fork =2 :B 
base =numrows *(k -1 ); 
D2 (base +(1 :numrows ),:)=C {k }; 
end


wnames =wnames (:); 
t =repmat (1 :numel (wnames ),nr *nb ,1 ); 
t =t (:); 
Within =categorical (wnames (t )); 
D1 =table (Within ); 


Between =repmat (bnames (:)' ,nr ,nw ); 
Between =categorical (Between (:)); 
D1 .Between =Between ; 


ifismember ('Within' ,D2 .Properties .VariableNames )
D2 .Within =[]; 
end
D =[D1 ,D2 ]; 


D .Properties .RowNames ={}; 


classes =varfun (@(v ){class (v )},first ,'OutputFormat' ,'uniform' ); 
dtccol =find (strcmp ('internal.stats.DoubleTableColumn' ,classes )); 
if~isempty (dtccol )
vnames =first .Properties .VariableNames ; 
absent =first .(vnames {dtccol (1 )}).absent ; 
absent =repmat (absent ,nr *nw ,1 ); 
forj =1 :length (dtccol )
vname =D .Properties .VariableNames {dtccol (j )+2 }; 
D .(vname )=internal .stats .DoubleTableColumn (D .(vname ),absent ); 
end
end
end

function [str ,epsilon ]=mauchlyTest (S ,n ,rx ,C )


p =size (S ,1 ); 
d =p -1 ; 


ifnargin <4 
C =triu (ones (p ,d )); 
C (2 :p +1 :end)=-(1 :d ); 
s =sqrt (2 *cumsum (1 :d )); 
C =bsxfun (@rdivide ,C ,s ); 
else
[C ,~]=qr (C ,0 ); 
end
d =size (C ,2 ); 






lam =eig (C ' *S *C ); 
lam =max (0 ,real (lam )); 
avglam =sum (lam )/d ; 
W =prod (lam /avglam ); 


ifnargout >=2 
Uncorrected =1 ; 
ifisempty (lam )
GreenhouseGeisser =1 ; 
HuynhFeldt =1 ; 
LowerBound =1 ; 
else
LowerBound =1 /d ; 
GreenhouseGeisser =min (1 ,max (LowerBound ,...
    sum (lam )^2 /(d *sum (lam .^2 )))); 





HuynhFeldt =min (1 ,max (LowerBound ,...
    ((n -rx +1 )*d *GreenhouseGeisser -2 )/(d *(n -rx )-d ^2 *GreenhouseGeisser ))); 
end
epsilon =table (Uncorrected ,GreenhouseGeisser ,HuynhFeldt ,LowerBound ); 
end



nr =n -rx ; 
dd =1 -(2 *d ^2 +d +2 )/(6 *d *nr ); 
ChiStat =-log (W )*dd *nr ; 
DF =max (0 ,d *(d +1 )/2 -1 ); 
p1 =chi2cdf (ChiStat ,DF ,'upper' ); 

pValue =p1 ; 








str =table (W ,ChiStat ,DF ,pValue ); 
end

function [pUnc ,pGG ,pHF ,pLB ]=pValueCorrections (F ,df ,dfe ,Epsilon )


pUnc =fcdf (F ,df ,dfe ,'upper' ); 


e =Epsilon .GreenhouseGeisser (1 ); 
pGG =fcdf (F ,e *df ,e *dfe ,'upper' ); 

e =Epsilon .HuynhFeldt (1 ); 
pHF =fcdf (F ,e *df ,e *dfe ,'upper' ); 

e =Epsilon .LowerBound (1 ); 
pLB =fcdf (F ,e *df ,e *dfe ,'upper' ); 
end

function [ngroups ,grpidx ,grpname ]=makegroup (group ,this )
ifisempty (group )
ngroups =1 ; 
nsubjects =size (this .X ,1 ); 
grpidx =ones (nsubjects ,1 ); 
grpname ={}; 
return 
end

[tf ,gvars ]=internal .stats .isStrings (group ); 
if~tf 
error (message ('stats:fitrm:GroupingNotCell' ))
end
if~all (ismember (gvars ,this .BetweenDesign .Properties .VariableNames ))
error (message ('stats:fitrm:GroupingNotBetween' ))
end
groups =cell (1 ,length (gvars )); 
forj =1 :length (gvars )
gj =this .BetweenDesign .(gvars {j }); 
groups {j }=gj (~this .Missing ,:); 
end
[grpidx ,~,grpvals ]=internal .stats .mgrp2idx (groups ); 
ngroups =size (grpvals ,1 ); 
grpname =cell (ngroups ,1 ); 
fork =1 :ngroups 
grpname {k }=sprintf ('%s=%s' ,gvars {1 },grpvals {k ,1 }); 
end
forj =2 :length (gvars )
fork =1 :ngroups 
grpname {k }=sprintf ('%s, %s=%s' ,grpname {k },gvars {j },grpvals {k ,j }); 
end
end
end

function c =calcTermAverages (ds ,Xmat ,terms ,termCols ,iscat )


contterms =terms ; 
contterms (:,iscat )=0 ; 
contterms =unique (contterms ,'rows' ); 

[tf ,loc ]=ismember (contterms ,terms ,'rows' ); 
averages =zeros (size (contterms ,1 ),1 ); 



ifany (~tf )
Zmat =classreg .regr .modelutils .designmatrix (ds ,'Model' ,contterms (~tf ,:)); 
end


Zcol =0 ; 
forj =1 :numel (tf )
iftf (j )
termloc =loc (j ); 
avg =mean (Xmat (:,termloc ==termCols )); 
else
Zcol =Zcol +1 ; 
avg =mean (Zmat (:,Zcol )); 
end
averages (j )=avg ; 
end
c ={contterms ,averages }; 
end

function [ff ,nlevels ]=makeFullFactorial (design )
ngroups =size (design ,2 ); 
nlevels =zeros (1 ,ngroups ); 
levels =cell (1 ,ngroups ); 
grp =design .Properties .VariableNames ; 
forj =1 :ngroups 
gj =design .(grp {j }); 
ifischar (gj )
gj =cellstr (gj ); 
end
u =unique (gj ); 
levels {j }=u ; 
nlevels (j )=size (u ,1 ); 
end
ifngroups >0 
indexdesign =fliplr (fullfact (fliplr (nlevels ))); 
end
ff =table (); 
forj =1 :ngroups 
ff .(grp {j })=levels {j }(indexdesign (:,j ),:); 
end
end

function [C ,Cnames ]=makeTestC (this ,model ,celloutput ,dsin ,numok )












ifnargin <3 
celloutput =true ; 
end
ifnargin <4 ||isempty (dsin )
dsin =this .WithinDesign ; 
end
ifnargin <5 
numok =false ; 
end
ny =size (this .Y ,2 ); 
ifnumok &&isnumeric (model )
C =model ; 
checkMatrix ('WithinModel' ,C ,ny ,[]); 
Cnames ={getString (message ('stats:fitrm:SpecifiedContrast' ))}; 
celloutput =false ; 
elseifisequal (model ,RepeatedMeasuresModel .SeparateMeans )

C =eye (ny -1 ,ny ); 
C (ny :ny :end)=-1 ; 
C =C ' ; 
Cnames ={'Constant' }; 
celloutput =false ; 
elseifisequal (model ,RepeatedMeasuresModel .MeanResponse )
C =ones (ny ,1 )/sqrt (ny ); 
Cnames ={'Constant' }; 
celloutput =false ; 
elseifisequal (model ,RepeatedMeasuresModel .OrthogonalContrasts )
W =dsin ; 
ifsize (W ,2 )~=1 ||~varfun (@isnumeric ,W ,'OutputFormat' ,'uniform' )
error (message ('stats:fitrm:NotNumericFactor' )); 
end
timename =W .Properties .VariableNames {1 }; 
time =W .(timename ); 
W =fliplr (vander (time (:))); 
[C ,~]=qr (W ); 
Cnames =cell (1 ,ny ); 
Cnames {1 }='Constant' ; 
Cnames {2 }=timename ; 
forj =2 :ny -1 
Cnames {j +1 }=sprintf ('%s^%d' ,timename ,j ); 
end

else
ds =this .WithinDesign ; 
yname =genvarname ('y' ,ds .Properties .VariableNames ); 
vnames =[ds .Properties .VariableNames ,{yname }]; 
ifischar (model )
try
formula =classreg .regr .LinearFormula ([yname ,' ~ ' ,model ],vnames ); 
catch ME 
ME =addCause (MException (message ('stats:fitrm:BadWithinModel' )),ME ); 
throw (ME ); 
end
else
error (message ('stats:fitrm:BadWithinModel' )); 
end

varNames =ds .Properties .VariableNames ; 
if~all (ismember (varNames ,dsin .Properties .VariableNames ))
error (message ('stats:fitrm:BadWithinModel' )); 
else
dsin =dsin (:,varNames ); 
end
iscat =varfun (@internal .stats .isDiscreteVar ,ds ,'OutputFormat' ,'uniform' ); 
nvars =size (ds ,2 ); 
vrange =cell (nvars ,1 ); 
excl =[]; 
fori =1 :nvars 
vrange {i }=getVarRange (ds .(varNames {i }),iscat (i ),excl ); 
end

terms =formula .Terms (:,1 :end-1 ); 
[C ,~,~,termcols ,Cnames ,TermNames ]=classreg .regr .modelutils .designmatrix (dsin ,...
    'Model' ,terms ,...
    'DummyVarCoding' ,'effects' ,...
    'CategoricalVars' ,iscat ,...
    'CategoricalLevels' ,vrange ); 
end
ifcelloutput 
termsize =accumarray (termcols ' ,1 ); 
C =mat2cell (C ,size (C ,1 ),termsize ); 
Cnames =TermNames ; 
end
end

function [A ,bnames ]=makeTestA (this )
ncoefs =length (this .CoefTerms ); 
termsize =accumarray (this .CoefTerms ' ,1 ); 
A =mat2cell (eye (ncoefs ),termsize ); 
bnames =this .TermNames ; 
end

function [A ,bnames ]=makeTestABy (this ,by )
if~internal .stats .isString (by )||~ismember (by ,this .BetweenFactorNames )
error (message ('stats:fitrm:ByNotBetween' ))
end


byvar =this .BetweenDesign .(by ); 
byvar =byvar (~this .Missing ,:); 
ifischar (byvar )
byvar =cellstr (byvar ); 
end
[~,vnum ]=ismember (by ,this .BetweenDesign .Properties .VariableNames ); 
ifthis .IsCat (vnum )
u =this .VariableRange {vnum }; 
ifischar (u )
u =cellstr (u ); 
end
else
u =unique (byvar ); 
end
A =cell (length (u ),1 ); 
bnames =cell (length (u ),1 ); 
forj =1 :length (u )
ifiscell (u )
uj =u {j }; 
rows =strcmp (uj ,byvar ); 
else
uj =u (j ); 
rows =byvar ==uj ; 
end
A {j }=mean (this .X (rows ,:),1 ); 
ifisnumeric (uj )||islogical (uj )
uj =num2str (uj ); 
else
uj =char (uj ); 
end
bnames {j }=sprintf ('%s=%s' ,by ,uj ); 
end
end

function [Xnew ,Bff ,nlevels ,cap ]=emmMakeA (this ,grp ,iswithin )

[~,vnums ]=ismember (grp (~iswithin ),this .BetweenDesign .Properties .VariableNames ); 
[~,order ]=sort (vnums ); 
[Bff ,nlevels ]=makeFullFactorial (this .BetweenDesign (~this .Missing ,grp (~iswithin ))); 
Bvars =ismember (this .BetweenDesign .Properties .VariableNames ,grp ); 


iscat =this .IsCat ; 
othercat =find (iscat ); 
bnames =this .BetweenDesign .Properties .VariableNames ; 
othercat (ismember (bnames (othercat ),grp ))=[]; 



terms =this .Formula .Terms ; 
temp =any (terms (:,othercat ),2 )' ; 
keepTerms =find (~temp ); 



catpart =terms (keepTerms ,:); 
catpart (:,~iscat )=0 ; 
ifisempty (Bff )
X1mat =1 ; 
else
X1mat =classreg .regr .modelutils .designmatrix (Bff (:,order ),...
    'Model' ,catpart (:,Bvars ),...
    'DummyVarCoding' ,'effects' ,...
    'CategoricalVars' ,iscat (Bvars ),...
    'CategoricalLevels' ,this .VariableRange (Bvars )); 
end


[X2row ,avgNames ]=getTermAverage (this ,keepTerms ); 
Xnew =zeros (size (X1mat ,1 ),size (this .X ,2 )); 
Xnew (:,ismember (this .CoefTerms ,keepTerms ))=bsxfun (@times ,X1mat ,X2row ); 


covariates =~strcmp (avgNames ,'(Intercept)' ); 
ifany (covariates )
cap =strcat (avgNames (covariates ),'=' ,num2str (X2row (covariates )' ,'%-g' )); 
cap =sprintf (', %s' ,cap {:}); 
cap =getString (message ('stats:fitrm:MeansComputedWith' ,cap (3 :end))); 
else
cap ='' ; 
end
end

function [M ,Wff ,nlevels ]=emmMakeC (this ,grp ,iswithin )
if~any (iswithin )
ny =size (this .B ,2 ); 
M =ones (ny ,1 )/ny ; 
Wff =[]; 
nlevels =1 ; 
else
[Wff ,nlevels ]=makeFullFactorial (this .WithinDesign (:,grp (iswithin ))); 
w =this .WithinDesign ; 
cols =ismember (this .WithinFactorNames ,grp ); 
[tf ,loc ]=ismember (w (:,cols ),Wff ); 
ifany (~tf )
error (message ('stats:fitrm:CombinationsMissing' )); 
end
M =zeros (size (w ,1 ),size (Wff ,1 )); 
forj =1 :size (Wff ,1 )
t =(loc ==j ); 
M (:,j )=t /sum (t ); 
end
end
end

function [terms ,iscat ,vrange ]=dataset2terms (this ,ds )


rmvars =this .BetweenDesign .Properties .VariableNames ; 
terms =this .Formula .Terms ; 
iscat =this .IsCat ; 
vrange =this .VariableRange ; 


dsvars =ds .Properties .VariableNames ; 
ifisequal (dsvars ,rmvars )
if~verifyDesign (this .BetweenDesign ,ds ); 
error (message ('stats:fitrm:IncompatibleBetweenDesign' )); 
end
return 
end


bfvars =this .BetweenFactorNames ; 
[ok ,dsidx ]=ismember (bfvars ,dsvars ); 
if~all (ok )
vname =bfvars (~ok ); 
error (message ('stats:fitrm:BetweenFactorMissing' ,vname {1 })); 
end
[~,rmidx ]=ismember (bfvars ,rmvars ); 
nvars =size (ds ,2 ); 
if~verifyDesign (this .BetweenDesign (:,rmidx ),ds (:,dsidx )); 
error (message ('stats:fitrm:IncompatibleBetweenDesign' )); 
end


newterms =zeros (size (terms ,1 ),nvars ); 
newterms (:,dsidx )=terms (:,rmidx ); 
terms =newterms ; 

newcat =false (nvars ,1 ); 
newcat (dsidx )=iscat (rmidx ); 
iscat =newcat ; 

newrange =repmat (vrange (1 ),nvars ,1 ); 
newrange (dsidx )=vrange (rmidx ); 
vrange =newrange ; 
end

function D =alldiff (n )




D =fliplr (fullfact ([n ,n ])); 
D (D (:,1 )==D (:,2 ),:)=[]; 
end

function [D ,Dnames ]=diffmatrix (A ,Anames ,numGroups )



ifnargin <3 
numGroups =size (A ,1 ); 
end
numBy =size (A ,1 )/numGroups ; 
pairs =alldiff (numGroups ); 
one =pairs (:,1 ); 
two =pairs (:,2 ); 
ifnumBy >1 
one =bsxfun (@plus ,one ,numGroups *(0 :numBy -1 )); 
one =one (:); 
two =bsxfun (@plus ,two ,numGroups *(0 :numBy -1 )); 
two =two (:); 
end
D =A (one ,:)-A (two ,:); 

varnames =Anames .Properties .VariableNames {end}; 
first =Anames (one ,end); 
first .Properties .VariableNames ={[varnames ,'_1' ]}; 
second =Anames (two ,end); 
second .Properties .VariableNames ={[varnames ,'_2' ]}; 
Dnames =[Anames (one ,1 :end-1 ),first ,second ]; 
end

function [cmap ,markers ,styles ]=regularizePlotArgs (cmap ,markers ,styles ,ngroups )
ifnargin <4 
ngroups =1 ; 
end
ifisempty (cmap )
cmap =lines (ngroups ); 
else
cmap =internal .stats .colorStringToRGB (cmap ); 
end
ifischar (markers )
markers ={markers }; 
end
ifischar (styles )
styles ={styles }; 
end
end

function checkAlpha (alpha )
if~isscalar (alpha )||~isnumeric (alpha )||~isreal (alpha )...
    ||~isfinite (alpha )||alpha <=0 ||alpha >=1 
throwAsCaller (MException (message ('stats:fitrm:BadAlpha' )))
end
end

function checkMatrix (name ,A ,rows ,cols ,okscalar )



msg =[]; 

ifany (any (isnan (A )))
msg =message ('stats:fitrm:NoMissing' ,name ); 
end

checkA =isempty (rows ); 
checkC =isempty (cols ); 


ifcheckA 
if~isnumeric (A )||~ismatrix (A )||size (A ,2 )~=cols 
msg =message ('stats:fitrm:MatrixWithCols' ,name ,cols ); 
elseifany (all (A ==0 ,2 ))
msg =message ('stats:fitrm:BadAMatrix' ); 
end
elseifcheckC 
if~isnumeric (A )||~ismatrix (A )||size (A ,1 )~=rows 
msg =message ('stats:fitrm:MatrixWithRows' ,name ,rows ); 
end
else
if~isnumeric (A )||~(isscalar (A )||isequal (size (A ),[rows ,cols ]))
ifnargin <5 ||okscalar 
msg =message ('stats:fitrm:MatrixWithSize' ,name ,rows ,cols ); 
else
msg =message ('stats:fitrm:MatrixWithSizeNoScalar' ,name ,rows ,cols ); 
end
end
end
if~isempty (msg )
throwAsCaller (MException (msg )); 
end

if(checkA ||checkC )&&rank (A )<min (size (A ))
error (message ('stats:fitrm:RankDefA' ,name )); 
end
end

function [H ,q ]=makeH (A ,B ,C ,D ,X )

d =A *B *C -D ; 
[~,RX ]=qr (X ,0 ); 
XA =A /RX ; 
Z =XA *XA ' ; 
H =d ' *(Z \d ); 

ifnargout >=2 
q =rank (Z ); 
end
end

function checkHE (H ,E )
msg =[]; 
if~all (all (isfinite (H )))
msg =message ('stats:fitrm:BadHMatrix' ); 
elseif~all (all (isfinite (E )))
msg =message ('stats:fitrm:BadEMatrix' ); 
end
if~isempty (msg )
throwAsCaller (MException (msg )); 
end
end

function [ok ,new ]=verifyDesign (old ,new )
oldnum =varfun (@(x )isnumeric (x ),old ,'OutputFormat' ,'uniform' ); 
ok =false ; 
if~istable (new )

ifsize (new ,2 )~=length (oldnum )||~all (oldnum )||~ismatrix (new )||~isnumeric (new )
ok =false ; 
return 
end
new =array2table (new ,'VariableNames' ,old .Properties .VariableNames ); 
else

oldclass =varfun (@(v ){class (v )},old ,'OutputFormat' ,'uniform' ); 
newclass =varfun (@(v ){class (v )},new ,'OutputFormat' ,'uniform' ); 
ifisequal (oldclass ,newclass )
ok =true ; 
return 
end
ifnumel (oldclass )~=numel (newclass )
return 
end


forj =1 :numel (oldclass )
ifisequal (oldclass {j },newclass {j })
continue 
end
vold =old {:,j }; 
ifisa (vold ,'categorical' )
vnew =new {:,j }; 
ifisa (vnew ,'categorical' )...
    ||(ismatrix (vnew )&&ischar (vnew ))...
    ||iscellstr (vnew )
continue 
end
end
return ; 
end
end
ok =true ; 
return 
end
