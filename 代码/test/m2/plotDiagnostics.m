function hout =plotDiagnostics (model ,plottype ,varargin )





























narginchk (1 ,Inf ); 


ifnargin <2 
plottype ='leverage' ; 
end
internal .stats .plotargchk (varargin {:}); 

alltypes ={'contour' ,'cookd' ,'covratio' ,'dfbetas' ,'dffits' ,'leverage' ,'s2_i' }; 
tf =strncmpi (plottype ,alltypes ,length (plottype )); 
ifsum (tf )~=1 
error (message ('stats:LinearModel:BadDiagnosticsPlotType' )); 
end
plottype =alltypes {tf }; 


h1 =[]; 
h0 =[]; 
linelabels =[]; 

n =model .NumObservations ; 
p =model .NumEstimatedCoefficients ; 

switch(plottype )

case 'contour' 

x =model .Diagnostics .Leverage ; 
y =model .Residuals .Raw ; 
h1 =plot (x ,y ,'rx' ,'LineWidth' ,2 ,varargin {:},'DisplayName' ,'Observations' ); 
ax =ancestor (h1 ,'axes' ); 


xlim =get (ax ,'XLim' ); 
ylim =get (ax ,'YLim' ); 
sigma =varianceParam (model ); 
X =linspace (max (.01 ,xlim (1 )),xlim (2 ),31 ); 
Y =linspace (ylim (1 ),ylim (2 ),30 ); 
Z =bsxfun (@times ,abs (Y )' .^2 ,(X ./(1 -X ).^2 ))/(p *sigma ^2 ); 
washold =ishold (ax ); 
if~washold 
hold (ax ,'on' ); 
end
grey =.7 *[1 ,1 ,1 ]; 
v =getNiceContours (model .Diagnostics .CooksDistance ); 
[C ,h0 ]=contour (ax ,X ,Y ,Z ,v ,'LineStyle' ,':' ,'Color' ,grey ); 
clabel (C ,h0 ,'Color' ,grey ); 
set (h0 ,'DisplayName' ,getString (message ('stats:classreg:regr:modelutils:CooksDistanceContours' ))); 
if~washold 
hold (ax ,'off' ); 
end

xlabel (ax ,getString (message ('stats:classreg:regr:modelutils:xylabel_Leverage' )))
ylabel (ax ,getString (message ('stats:classreg:regr:modelutils:xylabel_Residual' )))
title (ax ,getString (message ('stats:classreg:regr:modelutils:title_CooksDistanceFactorization' )))

case 'cookd' 
y =model .Diagnostics .CooksDistance ; 
subset =model .ObservationInfo .Subset ; 
h1 =plot (y ,'rx' ,'DisplayName' ,getString (message ('stats:classreg:regr:modelutils:xylabel_CooksDistance' )),varargin {:}); 
ax =ancestor (h1 ,'axes' ); 
xlim =get (ax ,'XLim' ); 


yref =3 *mean (y (isfinite (y )&subset )); 
h0 =line (xlim ,[yref ,yref ],'Color' ,'k' ,'LineStyle' ,':' ,'XLimInclude' ,'off' ,'Parent' ,ax ,'DisplayName' ,getString (message ('stats:classreg:regr:modelutils:ReferenceLine' ))); 

xlabel (ax ,getString (message ('stats:classreg:regr:modelutils:xylabel_RowNumber' )))
ylabel (ax ,getString (message ('stats:classreg:regr:modelutils:xylabel_CooksDistance' )))
title (getString (message ('stats:classreg:regr:modelutils:title_CaseOrderPlotOfCooksDistance' )))

case 'covratio' 
y =model .Diagnostics .CovRatio ; 
h1 =plot (y ,'rx' ,'DisplayName' ,getString (message ('stats:classreg:regr:modelutils:xylabel_CovarianceRatio' )),varargin {:}); 
ax =ancestor (h1 ,'axes' ); 
xlim =get (ax ,'XLim' ); 


yref =1 +[-1 ,1 ]*3 *p /n ; 
h0 =line ([xlim ' ; NaN ; xlim ' ],[yref ([1 ,1 ])' ; NaN ; yref ([2 ,2 ])' ],'Color' ,'k' ,'LineStyle' ,':' ,'XLimInclude' ,'off' ,'Parent' ,ax ,'DisplayName' ,getString (message ('stats:classreg:regr:modelutils:ReferenceLine' ))); 

xlabel (ax ,getString (message ('stats:classreg:regr:modelutils:xylabel_RowNumber' )))
ylabel (ax ,getString (message ('stats:classreg:regr:modelutils:xylabel_CovarianceRatio' )))
title (ax ,getString (message ('stats:classreg:regr:modelutils:title_CaseOrderPlotOfCovarianceRatio' )))

case 'dfbetas' 
y =model .Diagnostics .Dfbetas ; 
h1 =plot (y ,'x' ,varargin {:}); 
set (h1 ,{'DisplayName' },model .CoefficientNames ' ); 
ax =ancestor (h1 (1 ),'axes' ); 
xlim =get (ax ,'XLim' ); 


yref =[-1 ,1 ]*3 /sqrt (n ); 
h0 =line ([xlim ' ; NaN ; xlim ' ],[yref ([1 ,1 ])' ; NaN ; yref ([2 ,2 ])' ],'Color' ,'k' ,'LineStyle' ,':' ,'XLimInclude' ,'off' ,'Parent' ,ax ,'DisplayName' ,getString (message ('stats:classreg:regr:modelutils:ReferenceLine' ))); 

xlabel (ax ,getString (message ('stats:classreg:regr:modelutils:xylabel_RowNumber' )))
ylabel (ax ,getString (message ('stats:classreg:regr:modelutils:xylabel_ScaledChangeInCoefficients' )))
title (ax ,getString (message ('stats:classreg:regr:modelutils:title_CaseOrderPlotOfScaledChangeInCoefficients' )))
linelabels =model .CoefficientNames ; 

case 'dffits' 
y =model .Diagnostics .Dffits ; 
h1 =plot (y ,'rx' ,'DisplayName' ,getString (message ('stats:classreg:regr:modelutils:xylabel_ScaledChangeInFit' )),varargin {:}); 
ax =ancestor (h1 ,'axes' ); 
xlim =get (ax ,'XLim' ); 


yref =[-1 ,1 ]*2 *sqrt (p /n ); 
h0 =line ([xlim ' ; NaN ; xlim ' ],[yref ([1 ,1 ])' ; NaN ; yref ([2 ,2 ])' ],'Color' ,'k' ,'LineStyle' ,':' ,'XLimInclude' ,'off' ,'Parent' ,ax ,'DisplayName' ,getString (message ('stats:classreg:regr:modelutils:ReferenceLine' ))); 

xlabel (ax ,getString (message ('stats:classreg:regr:modelutils:xylabel_RowNumber' )))
ylabel (ax ,getString (message ('stats:classreg:regr:modelutils:xylabel_ScaledChangeInFit' )))
title (ax ,getString (message ('stats:classreg:regr:modelutils:title_CaseOrderPlotOfScaledChangeInFit' )))

case 'leverage' 
y =model .Diagnostics .Leverage ; 
h1 =plot (y ,'rx' ,'DisplayName' ,getString (message ('stats:classreg:regr:modelutils:xylabel_Leverage' )),varargin {:}); 
ax =ancestor (h1 ,'axes' ); 
xlim =get (ax ,'XLim' ); 


yref =2 *p /n ; 
h0 =line (xlim ,[yref ,yref ],'Color' ,'k' ,'LineStyle' ,':' ,'XLimInclude' ,'off' ,'Parent' ,ax ,'DisplayName' ,getString (message ('stats:classreg:regr:modelutils:ReferenceLine' ))); 

xlabel (ax ,getString (message ('stats:classreg:regr:modelutils:xylabel_RowNumber' )))
ylabel (ax ,getString (message ('stats:classreg:regr:modelutils:xylabel_Leverage' )))
title (ax ,getString (message ('stats:classreg:regr:modelutils:title_CaseOrderPlotOfLeverage' )))

case 's2_i' 
y =model .Diagnostics .S2_i ; 
h1 =plot (y ,'rx' ,'DisplayName' ,getString (message ('stats:classreg:regr:modelutils:xylabel_LeaveoneoutVariance' )),varargin {:}); 
ax =ancestor (h1 ,'axes' ); 
xlim =get (ax ,'XLim' ); 


yref =model .MSE ; 
h0 =line (xlim ,[yref ,yref ],'Color' ,'k' ,'LineStyle' ,':' ,'XLimInclude' ,'off' ,'Parent' ,ax ,'DisplayName' ,getString (message ('stats:classreg:regr:modelutils:MSE' ))); 
xlabel (ax ,getString (message ('stats:classreg:regr:modelutils:xylabel_RowNumber' )))
ylabel (ax ,getString (message ('stats:classreg:regr:modelutils:xylabel_LeaveoneoutVariance' )))
title (ax ,getString (message ('stats:classreg:regr:modelutils:title_CaseOrderPlotOfLeaveoneoutVariance' )))
end


if~isempty (h1 )
ObsNames =model .ObservationNames ; 
internal .stats .addLabeledDataTip (ObsNames ,h1 ,h0 ,linelabels ); 
end

ifnargout >0 
hout =[h1 (:); h0 (:)]; 
end


function v =getNiceContours (vec )


vec =vec (isfinite (vec )); 
maxval =max (vec ); 

powOfTen =10 ^floor (log10 (maxval )); 
relSize =maxval /powOfTen ; 
ifrelSize <1.5 
v =powOfTen *(1 :6 )/4 ; 
elseifrelSize <2.5 
v =powOfTen *(1 :5 )/2 ; 
elseifrelSize <4 
v =powOfTen *(1 :8 )/2 ; 
elseifrelSize <7.5 
v =powOfTen *(1 :8 ); 
else
v =powOfTen *(1 :5 )*2 ; 
end


