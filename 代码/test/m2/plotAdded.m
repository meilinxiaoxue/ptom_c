function hout =plotAdded (model ,cnum ,varargin )








































compactNotAllowed (model ,'plotAdded' ,false ); 
internal .stats .plotargchk (varargin {:}); 


sub =model .ObservationInfo .Subset ; 
stats .source ='stepwisefit' ; 
stats .B =model .Coefs ; 
stats .SE =model .CoefSE ; 
stats .dfe =model .DFE ; 
stats .covb =model .CoefficientCovariance ; 

stats .yr =model .Residuals .Raw (sub ); 
stats .wasnan =~sub ; 
stats .wts =get_CombinedWeights_r (model ); 
stats .mse =model .MSE ; 
[~,p ]=size (model .Design ); 


terminfo =getTermInfo (model ); 
constrow =find (all (terminfo .terms ==0 ,2 ),1 ); 
ifisempty (constrow )
constrow =NaN ; 
end
ncoefs =length (model .Coefs ); 
ifnargin <2 ||isempty (cnum )

cnum =find (terminfo .designTerms ~=constrow ); 
end
ifisrow (cnum )&&ischar (cnum )
termnum =find (strcmp (model .Formula .TermNames ,cnum )); 
ifisscalar (termnum )
cnum =find (terminfo .designTerms ==termnum ); 
else
cnum =find (strcmp (model .CoefficientNames ,cnum )); 
if~isscalar (cnum )
error (message ('stats:LinearModel:BadCoefficientName' )); 
end
end
elseifisempty (cnum )||~isvector (cnum )||~all (ismember (cnum ,1 :ncoefs ))
error (message ('stats:LinearModel:BadCoefficientNumber' )); 
end
cnum =sort (cnum ); 
if~isscalar (cnum )&&any (diff (cnum )==0 )
error (message ('stats:LinearModel:RepeatedCoeffients' )); 
end


y =getResponse (model ); 
h =addedvarplot (model .Design (sub ,:),y (sub ),cnum ,true (1 ,p ),stats ,[],false ,varargin {:}); 


ax =ancestor (h (1 ),'axes' ); 
ylabel (ax ,sprintf ('%s' ,getString (message ('stats:LinearModel:sprintf_Adjusted' ,model .ResponseName ))),'Interpreter' ,'none' ); 
tcols =terminfo .designTerms (cnum ); 
ifisscalar (cnum )
thetitle =sprintf ('%s' ,getString (message ('stats:LinearModel:title_AddedVariablePlotFor' ,model .CoefficientNames {cnum }))); 
thexlabel =sprintf ('%s' ,getString (message ('stats:LinearModel:sprintf_Adjusted' ,model .CoefficientNames {cnum }))); 
elseif~any (tcols ==constrow )&&length (cnum )==ncoefs -1 
thetitle =getString (message ('stats:LinearModel:title_AddedVariablePlotModel' )); 
thexlabel =getString (message ('stats:LinearModel:xylabel_AdjustedWholeModel' )); 
elseifall (tcols ==tcols (1 ))&&length (tcols )==sum (terminfo .designTerms ==tcols (1 ))

thetitle =sprintf ('%s' ,getString (message ('stats:LinearModel:title_AddedVariablePlotFor' ,model .Formula .TermNames {tcols (1 )}))); 
thexlabel =sprintf ('%s' ,getString (message ('stats:LinearModel:sprintf_Adjusted' ,model .Formula .TermNames {tcols (1 )}))); 
else
thetitle =getString (message ('stats:LinearModel:title_AddedVariablePlotTerms' )); 
thexlabel =getString (message ('stats:LinearModel:xylabel_AdjustedSpecifiedTerms' )); 
end
title (ax ,thetitle ,'Interpreter' ,'none' ); 
xlabel (ax ,thexlabel ,'Interpreter' ,'none' ); 


ObsNames =model .ObservationNames ; 
internal .stats .addLabeledDataTip (ObsNames ,h (1 ),h (2 :end)); 

ifnargout >0 
hout =h ; 
end
