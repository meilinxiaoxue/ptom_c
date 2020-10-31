function f =plotSlice (fitobj )









[xname ,xused ,yname ,xlims ,iscat ,catlabels ,xfit ,xsettings ]=getXInfo (fitobj ); 


plotdata =isscalar (xname )&&isa (fitobj ,'classreg.regr.FitObject' ); 

modname =getString (message ('stats:classreg:regr:modelutils:dlg_PredictionSlicePlot' )); 
slicefig =figure ('Units' ,'Normalized' ,'Interruptible' ,'on' ,'Position' ,[0.05 ,0.35 ,0.90 ,0.5 ],...
    'NumberTitle' ,'off' ,'IntegerHandle' ,'off' ,...
    'MenuBar' ,'figure' ,...
    'Name' ,modname ,'Tag' ,'slicefig' ,'ToolBar' ,'none' ); 
fixMenus (slicefig ); 

ud =fillFigure (slicefig ,xlims ,iscat ,catlabels ,fitobj ,xsettings ,xfit ,plotdata ,xname ,xused ,yname ); 


setconf (slicefig ,ud .simflag ,ud .obsflag ,ud .confflag ); 

set (slicefig ,'UserData' ,ud ,'HandleVisibility' ,'callback' ,...
    'BusyAction' ,'queue' ,...
    'WindowButtonDownFcn' ,@downFun ,...
    'WindowButtonUpFcn' ,@upFun ,...
    'WindowButtonMotionFcn' ,@(varargin )motionFun ('up' ,varargin {:})); 


iflength (xused )>8 
xused (6 :end)=[]; 
applyAxesSelections (slicefig ,xused )
end

ifnargout >0 
f =slicefig ; 
end


function ud =fillFigure (slicefig ,xlims ,iscat ,catlabels ,fitobj ,xsettings ,xfit ,plotdata ,xname ,xused ,yname ,ud )

ifnargin <12 

ud .simflag =1 ; 
ud .obsflag =0 ; 
ud .confflag =1 ; 
end


slice_axes =makeAxes (slicefig ,xused ,xlims ,iscat ,catlabels ); 
fitline =plotFit (slice_axes ,xused ,fitobj ,xsettings ,xfit ,iscat ,xlims ,plotdata ,ud ); 
[ymin ,ymax ]=updateYAxes (slice_axes ); 


reference_line =updateRefLine ([],slice_axes ,xused ,xsettings ,ymin ,ymax ,(ymin +ymax )/2 ); 


[x_field ,y_field ]=makeUIcontrols (slicefig ,xname ,xused ,yname ,iscat ,catlabels ); 


ud =makeUserData (xfit ,xsettings ,xused ,fitline ,reference_line ,slice_axes ,...
    iscat ,catlabels ,fitobj ,xlims ,x_field ,y_field ,xname ,yname ,plotdata ,ud ); 


[newy ,newyci ]=predictionsPlusError (xsettings ,fitobj ,ud ); 
updateRefLine (reference_line ,slice_axes ,xused ,xsettings ,ymin ,ymax ,newy ); 


setYField (newy ,newyci ,ud ); 
foraxnum =1 :length (xused )
setXField (axnum ,xsettings (xused (axnum )),ud ); 
end


function editFun (axnum ,tgt ,~)
slicefig =ancestor (tgt ,'figure' ); 
ud =get (slicefig ,'Userdata' ); 
prednum =ud .xused (axnum ); 

if~ud .iscat (prednum )

val =get (ud .x_field (axnum ),'String' ); 
cx =str2double (val ); 
xl =ud .xlims (:,prednum ); 
ifisnan (cx )||cx <xl (1 )||cx >xl (2 )
setXField (axnum ,ud .xsettings (prednum ),ud ); 
warndlg (sprintf ('%s' ,getString (message ('stats:classreg:regr:modelutils:dlg_InvalidOrNotInRange' ,val ))),...
    getString (message ('stats:classreg:regr:modelutils:dlg_SlicePlot' )),'modal' ); 
return 
end
end


ud =updateplot (slicefig ,ud ,axnum ); 
set (slicefig ,'Userdata' ,ud ); 


function [y ,yci ]=predictionsPlusError (x ,fitobj ,ud )


nx =size (x ,1 ); 


in =fitobj .Formula .InModel ; 
vi =fitobj .VariableInfo ; 
d =table ; 
vn =vi .Properties .RowNames ; 
cols =find (in ); 
forj =1 :length (cols )
vnum =cols (j ); 
value =vi {vnum ,'Range' }{1 }(1 ); 
newdj =repmat (value ,nx ,1 ); 
ifvi .IsCategorical (vnum )
range =vi .Range {cols (j )}; 
fork =1 :nx 
catnum =round (x (k ,j )); 
ifiscell (range )
newdj (k ,1 )=range (catnum )' ; 
elseifischar (range )
row =range (catnum ,:); 
newdj (k ,:)=' ' ; 
newdj (k ,1 :length (row ))=row ; 
else
newdj (k ,1 )=range (catnum ); 
end
end
else
newdj =x (:,j ); 
end
d .(vn {cols (j )})=newdj ; 
end



args ={}; 
ifud .simflag 
args (end+(1 :2 ))={'Simultaneous' ,true }; 
end
ifud .obsflag 
args (end+(1 :2 ))={'Prediction' ,'observation' }; 
end


[y ,yci ]=predict (fitobj ,d ,args {:}); 



function [x_field ,y_field ]=makeUIcontrols (slicefig ,xname ,xused ,yname ,iscat ,catlabels )
fcolor =get (slicefig ,'Color' ); 
yfieldp =[.01 ,.45 ,.10 ,.04 ]; 
y_field (1 )=uicontrol (slicefig ,'Style' ,'text' ,'Units' ,'normalized' ,...
    'Position' ,yfieldp +[0 ,.14 ,0 ,0 ],'String' ,'' ,...
    'ForegroundColor' ,'k' ,'BackgroundColor' ,fcolor ,'Tag' ,'y1' ); 

y_field (2 )=uicontrol (slicefig ,'Style' ,'text' ,'Units' ,'normalized' ,...
    'Position' ,yfieldp +[0 ,0 ,0 ,.04 ],'String' ,'' ,...
    'ForegroundColor' ,'k' ,'BackgroundColor' ,fcolor ,'Tag' ,'y2' ); 

uicontrol (slicefig ,'Style' ,'Pushbutton' ,'Units' ,'pixels' ,...
    'Position' ,[20 ,10 ,100 ,25 ],'Callback' ,'close' ,'String' ,getString (message ('stats:classreg:regr:modelutils:uicontrol_Close' )),'Tag' ,'close' ); 

uicontrol (slicefig ,'Style' ,'text' ,'Units' ,'normalized' ,...
    'Position' ,yfieldp +[0 ,0.21 ,0 ,.04 ],'BackgroundColor' ,fcolor ,...
    'ForegroundColor' ,'k' ,'String' ,yname ,'Tag' ,'yname' ); 

n =length (xused ); 
x_field =zeros (1 ,n ); 
foraxnum =1 :n 
prednum =xused (axnum ); 
xfieldp =[.18 +(axnum -0.5 )*.80 /n -0.5 *min (.5 /n ,.15 ),.09 ,min (.5 /n ,.15 ),.07 ]; 
xtextp =[.18 +(axnum -0.5 )*.80 /n -0.5 *min (.5 /n ,.18 ),.02 ,min (.5 /n ,.18 ),.05 ]; 
uicontrol (slicefig ,'Style' ,'text' ,'Units' ,'normalized' ,...
    'Position' ,xtextp ,'BackgroundColor' ,fcolor ,...
    'ForegroundColor' ,'k' ,'String' ,xname {prednum },'Tag' ,sprintf ('xname%d' ,axnum )); 

tag =sprintf ('xval%d' ,axnum ); 
ifiscat (prednum )
x_field (axnum )=uicontrol (slicefig ,'Style' ,'popup' ,'Units' ,'normalized' ,...
    'Position' ,xfieldp ,'String' ,catlabels {prednum },'Tag' ,tag ,...
    'BackgroundColor' ,'white' ,'CallBack' ,@(varargin )editFun (axnum ,varargin {:})); 
else
x_field (axnum )=uicontrol (slicefig ,'Style' ,'edit' ,'Units' ,'normalized' ,...
    'Position' ,xfieldp ,'String' ,'' ,'Tag' ,tag ,...
    'BackgroundColor' ,'white' ,'CallBack' ,@(varargin )editFun (axnum ,varargin {:})); 
end
end


function ud =updateplot (slicefig ,ud ,axnum )


slice_axes =ud .slice_axes ; 
xused =ud .xused ; 
xsettings =ud .xsettings ; 
fitline =ud .fitline ; 
reference_line =ud .reference_line ; 
n =length (slice_axes ); 


ifnargin <3 
axnum =ud .last_axes ; 
end
xrow =xsettings ; 
if~isempty (axnum )
prednum =xused (axnum ); 
cx =getXField (axnum ,ud ); 
xrow (prednum )=cx ; 
end
[cy ,cyci ]=predictionsPlusError (xrow ,ud .fitobj ,ud ); 


if~isempty (axnum )
xsettings (prednum )=cx ; 
end

ud .xsettings =xsettings ; 

foraxnum =1 :n 
prednum =xused (axnum ); 
xline =getXLine (xsettings ,prednum ,ud .xfit {prednum },ud .iscat ,ud .xlims ); 
[yfit ,yci ]=predictionsPlusError (xline ,ud .fitobj ,ud ); 

if~ud .confflag 


yci (:)=NaN ; 
end
set (slice_axes (axnum ),'YLimMode' ,'auto' ); 
set (fitline (1 ,axnum ),'YData' ,yfit ); 
set (fitline (2 ,axnum ),'YData' ,yci (:,1 )); 
set (fitline (3 ,axnum ),'YData' ,yci (:,2 )); 
end

[ymin ,ymax ]=updateYAxes (slice_axes ); 
updateRefLine (reference_line ,slice_axes ,xused ,xsettings ,ymin ,ymax ,cy ); 

ud .last_axes =[]; 
set (slicefig ,'UserData' ,ud ); 

setYField (cy ,cyci ,ud ); 



function axnum =findaxes (fig ,allaxes ,~,eventData )

axnum =[]; 
h =eventData .HitObject ; 
ifh ==fig 
return 
end
h =ancestor (h ,'axes' ); 
ifisempty (h )
return 
end
axnum =find (allaxes ==h ,1 ); 


function downFun (varargin )
slicefig =gcbf ; 
ud =get (slicefig ,'Userdata' ); 
set (slicefig ,'WindowButtonMotionFcn' ,@(varargin )motionFun ('down' ,varargin {:})); 

axnum =findaxes (slicefig ,ud .slice_axes ,varargin {:}); 
ifisempty (axnum )
return 
end
ud .last_axes =axnum ; 
set (slicefig ,'Pointer' ,'crosshair' ); 

cp =get (ud .slice_axes (axnum ),'CurrentPoint' ); 
cx =cp (1 ,1 ); 
prednum =ud .xused (axnum ); 
[xrow ,cx ]=getXLine (ud .xsettings ,prednum ,cx ,ud .iscat ,ud .xlims ); 
ud .xsettings (prednum )=cx ; 
[cy ,cyci ]=predictionsPlusError (xrow ,ud .fitobj ,ud ); 

set (slicefig ,'Userdata' ,ud ); 

setXField (axnum ,cx ,ud ); 

set (ud .reference_line (axnum ,1 ),'XData' ,cx *ones (2 ,1 )); 
set (ud .reference_line (axnum ,2 ),'YData' ,[cy ,cy ]); 

setYField (cy ,cyci ,ud ); 

set (slicefig ,'WindowButtonUpFcn' ,@upFun ); 


function motionFun (flag ,varargin )
slicefig =gcbf ; 
ud =get (slicefig ,'Userdata' ); 
axnum =findaxes (slicefig ,ud .slice_axes ,varargin {:}); 
ifisempty (axnum )
return 
end
xrange =get (ud .slice_axes (axnum ),'XLim' ); 
newx =getXField (axnum ,ud ); 
maxx =xrange (2 ); 
minx =xrange (1 ); 
n =size (ud .x_field ,2 ); 

ifisequal (flag ,'up' )

ifn >1 
yn =zeros (n ,1 ); 
foridx =1 :n 
y =get (ud .reference_line (idx ,2 ),'Ydata' ); 
yn (idx )=y (1 ); 
end

ifany (yn ~=yn (1 ))
upFun (varargin {:}); 
end
end

cursorstate =get (slicefig ,'Pointer' ); 
cp =get (ud .slice_axes (axnum ),'CurrentPoint' ); 
cx =cp (1 ,1 ); 
fuzz =0.02 *(maxx -minx ); 
online =cx >newx -fuzz &cx <newx +fuzz ; 
ifonline &&strcmp (cursorstate ,'arrow' )
cursorstate ='crosshair' ; 
elseif~online &&strcmp (cursorstate ,'crosshair' )
cursorstate ='arrow' ; 
end
set (slicefig ,'Pointer' ,cursorstate ); 

else
if~isequal (ud .last_axes ,axnum )
return ; 
end
cp =get (ud .slice_axes (axnum ),'CurrentPoint' ); 

cx =cp (1 ,1 ); 
[xrow ,cx ]=getXLine (ud .xsettings ,ud .xused (axnum ),cx ,ud .iscat ,ud .xlims ); 
[cy ,cyci ]=predictionsPlusError (xrow ,ud .fitobj ,ud ); 

setXField (axnum ,cx ,ud ); 

set (ud .reference_line (axnum ,1 ),'XData' ,repmat (cx ,2 ,1 )); 
set (ud .reference_line (axnum ,2 ),'YData' ,[cy ,cy ]); 

setYField (cy ,cyci ,ud ); 
end


function upFun (varargin )
slicefig =gcbf ; 
set (slicefig ,'WindowButtonMotionFcn' ,@(varargin )motionFun ('up' ,varargin {:})); 

ud =get (slicefig ,'Userdata' ); 
n =size (ud .x_field ,2 ); 
p =get (slicefig ,'CurrentPoint' ); 
axnum =floor (1 +n *(p (1 )-0.18 )/.80 ); 

lk =ud .last_axes ; 
ifisempty (lk )
return 
end

xrange =ud .xlims (:,lk ); 
ifaxnum <lk 
setXField (lk ,xrange (1 ),ud ); 
elseifaxnum >lk 
setXField (lk ,xrange (2 ),ud ); 
end

updateplot (slicefig ,ud ); 



function [xname ,xused ,yname ,xlims ,iscat ,catlabels ,xfit ,xsettings ]=getXInfo (fitobj )
yname =sprintf ('%s' ,getString (message ('stats:classreg:regr:modelutils:sprintf_Predicted' ,fitobj .ResponseName ))); 
xname =fitobj .PredictorNames ; 
xused =1 :length (xname ); 

varinfo =fitobj .VariableInfo ; 
inmodel =fitobj .Formula .InModel ; 
catlabels =varinfo .Range (inmodel ); 
iscat =varinfo .IsCategorical (inmodel ); 
n =length (iscat ); 
xlims =ones (2 ,n ); 

xfit =cell (1 ,n ); 
forprednum =1 :n 
range =catlabels {prednum }; 
ifiscat (prednum )
ifislogical (range )
labeltext ={'false' ; 'true' }; 
elseifisnumeric (range )
labeltext =num2str (range (:)); 
else
labeltext =char (range ); 
end
catlabels {prednum }=labeltext ; 
nlevels =size (labeltext ,1 ); 
xlims (2 ,prednum )=nlevels ; 
xfit {prednum }=1 :nlevels ; 
else
xlims (:,prednum ,:)=range (:); 
xfit {prednum }=linspace (range (1 ),range (2 ),41 ); 
end
end

xrange =diff (xlims ); 
minx =xlims (1 ,:); 

xsettings =minx +xrange /2 ; 
xsettings (iscat )=round (xsettings (iscat )); 




function [xline ,xnew ]=getXLine (xsettings ,prednum ,xfit ,iscat ,xlims )
xlim =xlims (:,prednum ); 

xnew =max (xlim (1 ),min (xlim (2 ),xfit )); 
ifiscat (prednum )
xnew =round (xnew ); 
end

xline =xsettings (ones (length (xnew ),1 ),:); 
xline (:,prednum )=xnew ; 



function x =getXField (axnum ,ud )
ifud .iscat (ud .xused (axnum ))
x =get (ud .x_field (axnum ),'Value' ); 
else
val =get (ud .x_field (axnum ),'String' ); 
x =str2double (val ); 
end



function setXField (axnum ,x ,ud )
ifud .iscat (ud .xused (axnum ))
set (ud .x_field (axnum ),'Value' ,x ); 
else
val =num2str (x ); 
set (ud .x_field (axnum ),'String' ,val ); 
end



function setYField (y ,yci ,ud )
set (ud .y_field (1 ),'String' ,num2str (double (y ))); 
set (ud .y_field (2 ),'String' ,sprintf ('[%g, %g]' ,yci )); 




function fixMenus (slicefig )


menus =findall (slicefig ,'type' ,'uimenu' ); 
tags =get (menus ,'Tag' ); 
removethese =ismember (tags ,{'figMenuTools' ,'figMenuInsert' ,'figMenuView' ,'figMenuEdit' }); 
delete (menus (removethese )); 


menus =findall (slicefig ,'type' ,'uimenu' ); 
menu =findall (menus ,'flat' ,'Tag' ,'figMenuFile' ); 
submenus =findall (menus ,'flat' ,'Parent' ,menu ); 
tags =get (submenus ,'Tag' ); 
removethese =ismember (tags ,{'figMenuFileExportSetup' ,'figMenuFilePreferences' ,...
    'figMenuFileSaveWorkspaceAs' ,'figMenuFileImportData' ,'figMenuGenerateCode' ,...
    'figMenuFileSaveAs' ,'figMenuFileSave' ,'figMenuUpdateFileNew' }); 
delete (submenus (removethese )); 
submenus (removethese )=[]; 
openmenu =findall (submenus ,'flat' ,'Tag' ,'figMenuOpen' ); 
delete (openmenu )


f =uimenu ('Label' ,getString (message ('stats:classreg:regr:modelutils:label_Bounds' )),'Position' ,2 ,'UserData' ,'conf' ); 
uimenu (f ,'Label' ,getString (message ('stats:classreg:regr:modelutils:label_Simultaneous' )),...
    'Callback' ,@doBoundsMenu ,'UserData' ,'simul' ,'Tag' ,'boundsSimultaneous' ); 
uimenu (f ,'Label' ,getString (message ('stats:classreg:regr:modelutils:label_NonSimultaneous' )),...
    'Callback' ,@doBoundsMenu ,'UserData' ,'nonsimul' ,'Tag' ,'boundsNonsimultaneous' ); 
uimenu (f ,'Label' ,getString (message ('stats:classreg:regr:modelutils:label_Curve' )),'Separator' ,'on' ,...
    'Callback' ,@doBoundsMenu ,'UserData' ,'curve' ,'Tag' ,'boundsCurve' ); 
uimenu (f ,'Label' ,getString (message ('stats:classreg:regr:modelutils:label_Observation' )),...
    'Callback' ,@doBoundsMenu ,'UserData' ,'observation' ,'Tag' ,'boundsObservation' ); 
uimenu (f ,'Label' ,getString (message ('stats:classreg:regr:modelutils:label_NoBounds' )),'Separator' ,'on' ,...
    'Callback' ,@doBoundsMenu ,'UserData' ,'none' ,'Tag' ,'boundsNone' ); 


f =uimenu ('Label' ,getString (message ('stats:classreg:regr:modelutils:label_Predictors' )),'Position' ,3 ,'UserData' ,'predictors' ); 
uimenu (f ,'Label' ,getString (message ('stats:classreg:regr:modelutils:label_Select' )),'Callback' ,@(varargin )SelectPredictors (varargin {:})); 

function SelectPredictors (tgt ,~)
slicefig =ancestor (tgt ,'figure' ); 
ud =get (slicefig ,'UserData' ); 

n =length (ud .xsettings ); 
list =cell (n ,1 ); 
forprednum =1 :n 
xname =ud .xname {prednum }; 
xval =ud .xsettings (prednum ); 
ifud .iscat (prednum )
labels =ud .catlabels {prednum }; 
ifiscell (labels )
xstring =labels {xval }; 
elseifisvector (labels )
xstring =labels (xval ); 
else
xstring =labels (xval ,:); 
end
else
xstring =num2str (xval ); 
end
list {prednum }=sprintf ('%s (%s)' ,xname ,xstring ); 
end

[selection ,ok ]=listdlg ('ListString' ,list ,'InitialValue' ,ud .xused ,...
    'PromptString' ,getString (message ('stats:classreg:regr:modelutils:dlg_SlicePlot' ))); 

if~ok 
return 
end

applyAxesSelections (slicefig ,selection ); 



function applyAxesSelections (slicefig ,xused )

clearFigure (slicefig ); 
ud =get (slicefig ,'UserData' ); 

xlims =ud .xlims ; 
iscat =ud .iscat ; 
catlabels =ud .catlabels ; 
fitobj =ud .fitobj ; 
xsettings =ud .xsettings ; 
xfit =ud .xfit ; 

plotdata =ud .plotdata ; 
xname =ud .xname ; 
yname =ud .yname ; 

ud =fillFigure (slicefig ,xlims ,iscat ,catlabels ,fitobj ,xsettings ,xfit ,plotdata ,xname ,xused ,yname ,ud ); 
set (slicefig ,'UserData' ,ud ); 



function clearFigure (slicefig )
ud =get (slicefig ,'UserData' ); 
delete (ud .slice_axes )
delete (findall (slicefig ,'type' ,'uicontrol' ))


function doBoundsMenu (tgt ,~)


menu =tgt ; 
action =get (menu ,'UserData' ); 
slicefig =ancestor (menu ,'figure' ); 
ud =get (slicefig ,'UserData' ); 

switch(action )
case 'simul' ,ud .simflag =1 ; 
case 'nonsimul' ,ud .simflag =0 ; 
case 'curve' ,ud .obsflag =0 ; 
case 'observation' ,ud .obsflag =1 ; 
case 'none' ,ud .confflag =~ud .confflag ; 
end


setconf (slicefig ,ud .simflag ,ud .obsflag ,ud .confflag ); 
updateplot (slicefig ,ud ); 


function setconf (slicefig ,simul ,obs ,confflag )
ma =get (findall (slicefig ,'Type' ,'uimenu' ,'UserData' ,'conf' ),'Children' ); 
set (ma ,'Checked' ,'off' ); 


offon ={'off' ,'on' }; 
set (findobj (ma ,'flat' ,'Type' ,'uimenu' ,'UserData' ,'simul' ),'Checked' ,offon {1 +simul }); 
set (findobj (ma ,'flat' ,'Type' ,'uimenu' ,'UserData' ,'nonsimul' ),'Checked' ,offon {2 -simul }); 


offon ={'off' ,'on' }; 
set (findobj (ma ,'flat' ,'Type' ,'uimenu' ,'UserData' ,'observation' ),'Checked' ,offon {1 +obs }); 
set (findobj (ma ,'flat' ,'Type' ,'uimenu' ,'UserData' ,'curve' ),'Checked' ,offon {2 -obs }); 


set (findobj (ma ,'flat' ,'Type' ,'uimenu' ,'UserData' ,'none' ),'Checked' ,offon {2 -confflag }); 


function slice_axes =makeAxes (slicefig ,xused ,xlims ,iscat ,catlabels )
n =length (xused ); 
slice_axes =zeros (n ,1 ); 

foraxnum =1 :n 

axisp =[.18 +(axnum -1 )*.80 /n ,.22 ,.80 /n ,.68 ]; 

prednum =xused (axnum ); 
slice_axes (axnum )=axes ('Parent' ,slicefig ); 
set (slice_axes (axnum ),'XLim' ,xlims (:,prednum )+iscat (prednum )*[-.25 ; .25 ],'Box' ,'on' ,'NextPlot' ,'add' ,...
    'Position' ,axisp ,'GridLineStyle' ,'none' ); 
ifaxnum >1 
set (slice_axes (axnum ),'Yticklabel' ,[]); 
end
ifiscat (prednum )
xlab =catlabels {prednum }; 
set (slice_axes (axnum ),'XTick' ,1 :length (xlab ),'XTickLabel' ,char (xlab )); 
end
end


function [ymin ,ymax ]=updateYAxes (slice_axes )


set (slice_axes ,'YLimMode' ,'auto' ); 

n =length (slice_axes ); 
yextremes =zeros (n ,2 ); 
foraxnum =1 :n 
yextremes (axnum ,:)=get (slice_axes (axnum ),'YLim' ); 
end

ymin =min (yextremes (:,1 )); 
ymax =max (yextremes (:,2 )); 

set (slice_axes ,'YLim' ,[ymin ,ymax ]); 


function reference_line =updateRefLine (reference_line ,slice_axes ,xused ,xsettings ,ymin ,ymax ,newy )

ifisempty (reference_line )

n =length (slice_axes ); 
reference_line =zeros (n ,2 ); 
foraxnum =1 :n 
prednum =xused (axnum ); 
xlimits =get (slice_axes (axnum ),'XLim' ); 
reference_line (axnum ,1 )=plot ([xsettings (prednum ),xsettings (prednum )],[ymin ,ymax ],'--' ,'Parent' ,slice_axes (axnum )); 
reference_line (axnum ,2 )=plot (xlimits ,[newy ,newy ],':' ,'Parent' ,slice_axes (axnum )); 
end


set (reference_line (:),'XLimInclude' ,'off' ,'YLimInclude' ,'off' ); 
else
n =size (reference_line ,1 ); 
foraxnum =1 :n 
prednum =xused (axnum ); 
set (reference_line (axnum ,1 ),'XData' ,[xsettings (prednum ),xsettings (prednum )],'YData' ,[ymin ,ymax ]); 
set (reference_line (axnum ,2 ),'YData' ,[newy ,newy ]); 
end
end


function ud =makeUserData (xfit ,xsettings ,xused ,fitline ,reference_line ,slice_axes ,...
    iscat ,catlabels ,fitobj ,xlims ,x_field ,y_field ,xname ,yname ,plotdata ,ud )
ud .texthandle =[]; 

ud .xfit =xfit ; 
ud .xsettings =xsettings ; 
ud .xused =xused ; 
ud .fitline =fitline ; 
ud .reference_line =reference_line ; 
ud .last_axes =[]; 
ud .slice_axes =slice_axes ; 
ud .iscat =iscat ; 
ud .catlabels =catlabels ; 
ud .fitobj =fitobj ; 
ud .x_field =x_field ; 
ud .y_field =y_field ; 
ud .xname =xname ; 
ud .yname =yname ; 
ud .plotdata =plotdata ; 

ud .xlims =xlims ; 



function fitline =plotFit (slice_axes ,xused ,fitobj ,xsettings ,xfit ,iscat ,xlims ,plotdata ,ud )

n =length (slice_axes ); 
fitline =zeros (3 ,n ); 

foraxnum =1 :n 

prednum =xused (axnum ); 
ifplotdata 
ydata =fitobj .Variables .(fitobj .ResponseName ); 
ifisa (fitobj ,'GeneralizedLinearModel' )&&...
    strcmpi (fitobj .Distribution .Name ,'binomial' )
ifsize (ydata ,2 )==2 
n =ydata (:,2 ); 
else
n =fitobj .ObservationInfo .BinomSize ; 
end
ydata =ydata (:,1 )./n ; 
end
xdata =fitobj .Variables .(fitobj .PredictorNames {1 }); 
line (xdata ,ydata (:,1 ),'Linestyle' ,'none' ,'Marker' ,'o' ,'Parent' ,slice_axes (axnum )); 
end


xline =getXLine (xsettings ,prednum ,xfit {prednum },iscat ,xlims ); 
[yfit ,yci ]=predictionsPlusError (xline ,fitobj ,ud ); 


ifiscat (prednum )
cml ='go-' ; 
else
cml ='g-' ; 
end
fitline (1 :3 ,axnum )=plot (xline (:,prednum ),yfit ,cml ,...
    xline (:,prednum ),yci (:,1 ),'r:' ,...
    xline (:,prednum ),yci (:,2 ),'r:' ,...
    'Parent' ,slice_axes (axnum )); 
end
