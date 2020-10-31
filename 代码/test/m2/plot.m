function hout =plot (lm ,varargin )

























compactNotAllowed (lm ,'plot' ,false ); 
p =length (lm .PredictorNames ); 
internal .stats .plotargchk (varargin {:}); 

ifp ==0 

h =plotResiduals (lm ,'histogram' ); 
elseifp ==1 

h =plotxy (lm ,varargin {:}); 
else
h =plotAdded (lm ,[],varargin {:}); 
end

ifnargout >0 
hout =h ; 
end

function h =plotxy (lm ,varargin )


col =lm .PredLocs ; 
xname =lm .PredictorNames {1 }; 


xdata =getVar (lm ,col ); 
y =getResponse (lm ); 
ObsNames =lm .ObservationNames ; 

iscat =lm .VariableInfo .IsCategorical (col ); 

ifiscat 

[x ,xlabels ,levels ]=grp2idx (xdata ); 
tickloc =(1 :length (xlabels ))' ; 
ticklab =xlabels ; 
xx =tickloc ; 
else
x =xdata ; 
xx =linspace (min (x ),max (x ))' ; 
levels =xx ; 
end
nlevels =size (levels ,1 ); 



t =isnan (x )|isnan (y ); 
ifany (t )
x (t )=NaN ; 
y (t )=NaN ; 
end


ifisa (lm .Variables ,'dataset' )||isa (lm .Variables ,'table' )

X =lm .Variables (ones (nlevels ,1 ),:); 
X .(xname )=levels (:); 
else

npreds =lm .NumVariables -1 ; 
X =zeros (length (xx ),npreds ); 
X (:,col )=xx ; 
end
[yfit ,yci ]=lm .predict (X ); 
h =plot (x ,y ,'bx' ,varargin {:}); 
ax =ancestor (h ,'axes' ); 
washold =ishold (ax ); 
hold (ax ,'on' )
h =[h ; plot (ax ,xx ,yfit ,'r-' ,xx ,yci ,'r:' )]; 
if~washold 
hold (ax ,'off' )
end

ifiscat 
set (ax ,'XTick' ,tickloc ' ,'XTickLabel' ,ticklab ); 
set (ax ,'XLim' ,[tickloc (1 )-0.5 ,tickloc (end)+0.5 ]); 
end

yname =lm .ResponseName ; 
title (ax ,sprintf ('%s' ,getString (message ('stats:LinearModel:sprintf_AvsB' ,yname ,xname ))),'Interpreter' ,'none' ); 
set (xlabel (ax ,xname ),'Interpreter' ,'none' ); 
set (ylabel (ax ,yname ),'Interpreter' ,'none' ); 
legend (ax ,h (1 :3 ),getString (message ('stats:LinearModel:legend_Data' )),...
    getString (message ('stats:LinearModel:legend_Fit' )),...
    getString (message ('stats:LinearModel:legend_ConfidenceBounds' )),...
    'location' ,'best' )


internal .stats .addLabeledDataTip (ObsNames ,h (1 ),h (2 :end)); 
