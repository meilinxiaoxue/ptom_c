function hout =plotAdjustedResponse (model ,var ,varargin )































narginchk (2 ,Inf ); 
compactNotAllowed (model ,'plotAdjustedResponse' ,false ); 
internal .stats .plotargchk (varargin {:}); 


terminfo =getTermInfo (model ); 
[xdata ,vname ,vnum ]=getVar (model ,var ); 

if~model .Formula .InModel (vnum )
ifstrcmp (vname ,model .Formula .ResponseName )
error (message ('stats:LinearModel:ResponseNotAllowed' ,vname )); 
else
error (message ('stats:LinearModel:NotPredictor' ,vname )); 
end

elseifterminfo .isCatVar (vnum )

[xdata ,xlabels ]=grp2idx (xdata ); 
nlevels =length (xlabels ); 
xi =(1 :nlevels )' ; 
else

xi =linspace (min (xdata ),max (xdata ))' ; 
nlevels =length (xi ); 
xi =[xi ; xdata ]; 
end



fxi =getAdjustedResponse (model ,vnum ,xi ,terminfo ); 


ifterminfo .isCatVar (vnum )
d =double (xdata ); 
fx (~isnan (d ))=fxi (d (~isnan (d ))); 
fx (isnan (d ))=NaN ; 
fx =fx (:); 
else
fx =fxi (nlevels +1 :end); 
xi =xi (1 :nlevels ); 
fxi =fxi (1 :nlevels ); 
end


resid =model .Residuals .Raw ; 
h =plot (xdata ,fx +resid ,'ro' ,varargin {:}); 
ax =ancestor (h ,'axes' ); 
washold =ishold (ax ); 
if~washold 
hold (ax ,'on' ); 
end
h =[h ; plot (ax ,xi ,fxi ,'b-' )]; 
if~washold 
hold (ax ,'off' ); 
end
set (h (1 ),'Tag' ,'data' ); 
set (h (2 ),'Tag' ,'fit' ); 
legend (ax ,'Adjusted data' ,'Adjusted fit' ,'location' ,'best' ); 
xlabel (ax ,vname ); 
ylabel (ax ,sprintf ('%s' ,getString (message ('stats:LinearModel:sprintf_Adjusted' ,model .ResponseName )))); 
title (ax ,getString (message ('stats:LinearModel:title_AdjustedResponsePlot' )))

ifterminfo .isCatVar (vnum )
set (ax ,'XTick' ,xi ,'XTickLabel' ,xlabels ,'XLim' ,[.5 ,max (xi )+.5 ]); 
end


ObsNames =model .ObservationNames ; 
internal .stats .addLabeledDataTip (ObsNames ,h (1 ),[]); 

ifnargout >0 
hout =h ; 
end
