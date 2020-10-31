classdef TreeDrawer 





methods (Static )
function fig =setupfigure (doclass )


fig =figure ('IntegerHandle' ,'off' ,'NumberTitle' ,'off' ,...
    'Units' ,'points' ,'PaperPositionMode' ,'auto' ,...
    'MenuBar' ,'figure' ,...
    'Tag' ,'tree viewer' ); 
ax =axes ('Parent' ,fig ,'UserData' ,cell (1 ,4 ),'XLim' ,0 :1 ,'YLim' ,0 :1 ); 


pt =printtemplate ; 
pt .PrintUI =0 ; 
set (fig ,'PrintTemplate' ,pt )

ifdoclass 
figtitle =getString (message ('stats:classregtree:view:ClassificationTreeViewer' )); 
else
figtitle =getString (message ('stats:classregtree:view:RegressionTreeViewer' )); 
end


pos =[0 ,0 ,1 ,1 ]; 
set (ax ,'Visible' ,'off' ,'XLim' ,0 :1 ,'YLim' ,0 :1 ,'Position' ,pos ); 
set (ax ,'Units' ,'points' ); 
apos =get (ax ,'Position' ); 
fpos =get (fig ,'Position' ); 
hframe =uicontrol (fig ,'Units' ,'points' ,'Style' ,'frame' ,...
    'Position' ,[0 ,0 ,1 ,1 ],'Tag' ,'frame' ); 


h =uicontrol (fig ,'units' ,'points' ,'Tag' ,'clicktext' ,...
    'String' ,getString (message ('stats:classregtree:view:ClickToDisplay' )),...
    'style' ,'text' ,'HorizontalAlignment' ,'left' ,'FontWeight' ,'bold' ); 
extent =get (h ,'Extent' ); 
theight =extent (4 ); 
aheight =apos (4 ); 
tbottom =aheight -1.5 *theight ; 
posn =[2 ,tbottom ,150 ,theight ]; 
set (h ,'Position' ,posn ); 
textpos =posn ; 
e =get (h ,'Extent' ); 
ifdoclass 
choices =...
    {getString (message ('stats:classregtree:view:NodeIdentity' )),...
    getString (message ('stats:classregtree:view:NodeVariableRanges' )),...
    getString (message ('stats:classregtree:view:NodeClassMembership' )),...
    getString (message ('stats:classregtree:view:NodeEstimatedProbabilities' ))}; 
else
choices =...
    {getString (message ('stats:classregtree:view:NodeIdentity' )),...
    getString (message ('stats:classregtree:view:NodeVariableRanges' )),...
    getString (message ('stats:classregtree:view:NodeStatistics' ))}; 
end
strlengths =cellfun ('length' ,choices ); 
[~,longest ]=max (strlengths ); 
h =uicontrol (fig ,'units' ,'points' ,'position' ,[0 ,0 ,1 ,1 ],'Tag' ,'clicklist' ,...
    'String' ,choices {longest },'Style' ,'pop' ,'BackgroundColor' ,ones (1 ,3 ),...
    'Callback' ,@classreg .learning .treeutils .TreeDrawer .removelabels ); 
hext =get (h ,'Extent' ); 
posn =[e (1 )+e (3 )+2 ,aheight -1.25 *theight ,hext (3 )+40 ,theight ]; 
set (h ,'Position' ,posn ); 
set (h ,'String' ,choices ); 
set (ax ,'Position' ,[0 ,0 ,apos (3 ),tbottom ]); 
set (fig ,'Toolbar' ,'figure' ,'Name' ,figtitle ,'HandleVisibility' ,'callback' ); 


textpos (1 )=posn (1 )+posn (3 )+10 ; 
h =uicontrol (fig ,'units' ,'points' ,'Tag' ,'magtext' ,'Position' ,textpos ,...
    'String' ,getString (message ('stats:classregtree:view:PlotMagnification' )),...
    'style' ,'text' ,'HorizontalAlignment' ,'left' ,'FontWeight' ,'bold' ); 
e =get (h ,'Extent' ); 
textpos (3 )=e (3 ); 
set (h ,'Position' ,textpos ); 
h =uicontrol (fig ,'units' ,'points' ,'position' ,[0 ,0 ,1 ,1 ],'Tag' ,'maglist' ,...
    'String' ,'x' ,'Style' ,'pop' ,'BackgroundColor' ,ones (1 ,3 ),...
    'Callback' ,@domagnif ); 
adjustcustomzoom (h ,false ); 
hext =get (h ,'Extent' ); 
posn =[textpos (1 )+textpos (3 )+2 ,posn (2 ),hext (3 )+80 ,posn (4 )]; 
set (h ,'Position' ,posn ); 


textpos (1 )=posn (1 )+posn (3 )+10 ; 
h =uicontrol (fig ,'units' ,'points' ,'position' ,textpos ,'Tag' ,'prunelabel' ,...
    'Style' ,'text' ,'HorizontalAlignment' ,'left' ,...
    'FontWeight' ,'bold' ,...
    'String' ,getString (message ('stats:classregtree:view:PruneLevel' ))); 
e =get (h ,'Extent' ); 
textpos (3 )=e (3 ); 
set (h ,'Position' ,textpos ); 

posn (1 )=textpos (1 )+textpos (3 )+5 ; 
posn (2 )=posn (2 )-0.25 *e (4 ); 
posn (3 )=60 ; 
posn (4 )=1.5 *e (4 ); 
textpos (1 )=posn (1 )+3 ; 
textpos (3 )=posn (3 )-6 ; 
uicontrol (fig ,'Style' ,'frame' ,'Units' ,'points' ,'Position' ,posn ,...
    'Tag' ,'pruneframe' ); 
uicontrol (fig ,'units' ,'points' ,'position' ,textpos ,'Tag' ,'prunelev' ,...
    'Style' ,'text' ,'HorizontalAlignment' ,'left' ,...
    'FontWeight' ,'bold' ,'String' ,'1234 of 9999' ); 


fcolor =get (fig ,'Color' ); 
ar =...
    [1 ,1 ,1 ,1 ,1 ,1 ,1 ,1 ,1 ,1 ,1 ,1 ,1 
 1 ,1 ,1 ,1 ,1 ,1 ,1 ,1 ,1 ,1 ,1 ,1 ,1 
 1 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,1 
 1 ,1 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,1 ,1 
 1 ,1 ,1 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,1 ,1 ,1 
 1 ,1 ,1 ,1 ,0 ,0 ,0 ,0 ,0 ,1 ,1 ,1 ,1 
 1 ,1 ,1 ,1 ,1 ,0 ,0 ,0 ,1 ,1 ,1 ,1 ,1 
 1 ,1 ,1 ,1 ,1 ,1 ,0 ,1 ,1 ,1 ,1 ,1 ,1 
 1 ,1 ,1 ,1 ,1 ,1 ,1 ,1 ,1 ,1 ,1 ,1 ,1 
 1 ,1 ,1 ,1 ,1 ,1 ,1 ,1 ,1 ,1 ,1 ,1 ,1 ]; 
ar =repmat (ar ,[1 ,1 ,3 ]); 
ar (:,:,1 )=min (ar (:,:,1 ),fcolor (1 )); 
ar (:,:,2 )=min (ar (:,:,2 ),fcolor (2 )); 
ar (:,:,3 )=min (ar (:,:,3 ),fcolor (3 )); 

posn (1 )=posn (1 )+posn (3 ); 
posn (4 )=posn (4 )/2 ; 
posn (3 )=posn (4 ); 
uicontrol (fig ,'units' ,'points' ,'position' ,posn ,'Tag' ,'prune' ,...
    'CData' ,ar (end:-1 :1 ,:,:),...
    'Style' ,'pushbutton' ,'Callback' ,@growprune ); 
posn (2 )=posn (2 )+posn (4 ); 
uicontrol (fig ,'units' ,'points' ,'position' ,posn ,'Tag' ,'grow' ,...
    'CData' ,ar ,...
    'Style' ,'pushbutton' ,'Callback' ,@growprune ); 

ifposn (1 )+posn (3 )>fpos (3 )
fpos (3 )=posn (1 )+posn (3 ); 
set (fig ,'Position' ,fpos ); 
apos (3 )=fpos (3 ); 
set (ax ,'Position' ,apos ); 
end


lowest =min (posn (2 ),textpos (2 ))-2 ; 
frpos =apos ; 
frpos (4 )=1.1 *(apos (4 )-lowest ); 
frpos (2 )=apos (4 )-frpos (4 ); 
set (hframe ,'Position' ,frpos ); 


h1 =uicontrol (fig ,'Style' ,'slider' ,'Tag' ,'hslider' ,'Visible' ,'off' ,...
    'Units' ,'points' ,'Callback' ,@dopan ); 
p1 =get (h1 ,'Position' ); 
sw =p1 (4 ); 
p1 (1 :2 )=1 ; 
p1 (3 )=fpos (3 )-sw ; 
set (h1 ,'Position' ,p1 ); 
p2 =[fpos (3 )-sw ,sw ,sw ,frpos (2 )-sw ]; 
uicontrol (fig ,'Style' ,'slider' ,'Tag' ,'vslider' ,'Visible' ,'off' ,...
    'Units' ,'points' ,'Position' ,p2 ,'Callback' ,@dopan ); 


hw =findall (fig ,'Type' ,'uimenu' ,'Tag' ,'figMenuWindow' ); 
h0 =uimenu (fig ,'Label' ,getString (message ('stats:classregtree:view:TreeMenu' )),...
    'Position' ,get (hw ,'Position' )); 
uimenu (h0 ,'Label' ,getString (message ('stats:classregtree:view:TreeMenu_ShowFullTree' )),...
    'Position' ,1 ,'Tag' ,'menufull' ,'Checked' ,'on' ,'Callback' ,@domenu ); 
uimenu (h0 ,'Label' ,getString (message ('stats:classregtree:view:TreeMenu_ShowUnprunedNodes' )),...
    'Position' ,2 ,'Tag' ,'menuunpr' ,'Checked' ,'off' ,'Callback' ,@domenu ); 
uimenu (h0 ,'Label' ,getString (message ('stats:classregtree:view:TreeMenu_LabelBranchNodes' )),...
    'Position' ,3 ,'Tag' ,'menubr' ,'Checked' ,'on' ,'Callback' ,@domenu ,'Separator' ,'on' ); 
uimenu (h0 ,'Label' ,getString (message ('stats:classregtree:view:TreeMenu_LabelLeafNodes' )),...
    'Position' ,4 ,'Tag' ,'menuleaf' ,'Checked' ,'on' ,'Callback' ,@domenu ); 

set (fig ,'ResizeFcn' ,@resize ); 
end

function adjustmenu (fig ,helpviewer )



badTags ={'figMenuEdit' ,'figMenuView' ,'figMenuInsert' }; 
h =findall (fig ,'Type' ,'uimenu' ,'Parent' ,fig ); 
tagFun =@(x )get (x ,'Tag' ); 
foundTags =arrayfun (tagFun ,h ,'UniformOutput' ,false ); 
tf =ismember (foundTags ,badTags ); 
delete (h (tf )); 
h (tf )=[]; 



h0 =findall (h ,'Type' ,'uimenu' ,'Tag' ,'figMenuFile' ); 
h1 =findall (h0 ,'Type' ,'uimenu' ,'Parent' ,h0 ); 
badTags ={'printMenu' ,'figMenuFilePrintPreview' }; 
foundTags =arrayfun (tagFun ,h1 ,'UniformOutput' ,false ); 
tf =ismember (foundTags ,badTags ); 
delete (h1 (tf )); 


h0 =findall (h ,'Type' ,'uimenu' ,'Tag' ,'figMenuTools' ); 
h1 =findall (h0 ,'Type' ,'uimenu' ,'Parent' ,h0 ); 
badTags ={'figMenuZoomIn' ,'figMenuZoomOut' ,'figMenuPan' }; 
foundTags =arrayfun (tagFun ,h1 ,'UniformOutput' ,false ); 
tf =ismember (foundTags ,badTags ); 
delete (h1 (~tf )); 


h0 =findall (h ,'Type' ,'uimenu' ,'Tag' ,'figMenuHelp' ); 
h1 =findall (h0 ,'Type' ,'uimenu' ,'Parent' ,h0 ); 
delete (h1 ); 
uimenu (h0 ,'Label' ,getString (message ('stats:classregtree:view:HelpTreeViewer' )),...
    'Position' ,1 ,'Callback' ,helpviewer ); 


h0 =findall (fig ,'Type' ,'uitoolbar' ); 
h1 =findall (h0 ,'Parent' ,h0 ); 
badTags ={'Exploration.Pan' ,'Exploration.ZoomOut' ,'Exploration.ZoomIn' }; 
foundTags =arrayfun (tagFun ,h1 ,'UniformOutput' ,false ); 
tf =ismember (foundTags ,badTags ); 
delete (h1 (~tf )); 
end

function [X ,Y ]=drawtree (tree ,fig ,nodevalue ,varnames ,curlevel ,classnames ,vrange ,condfun )


ax =get (fig ,'CurrentAxes' ); 
splitvar =tree .CutVar ; 
cutpoint =tree .CutPoint ; 
cutcateg =tree .CutCategories ; 
parentnode =tree .Parent ; 
nonroot =parentnode ~=0 ; 


isleaf =splitvar ==0 ; 
[X ,Y ]=layouttree (tree ,isleaf ); 


if~isempty (tree .PruneList )
ifcurlevel ==0 
isbranch =tree .IsBranch ; 
else
isbranch =(tree .PruneList >curlevel ); 
end
else
isbranch =~isleaf ; 
end
ifany (isbranch )
isleaf =false (size (isbranch )); 
c =tree .Children (isbranch ,:); 
c =c (c >0 ); 
isleaf (c )=1 ; 
isleaf =isleaf &~isbranch ; 
else
isleaf =~nonroot ; 
end
pruned =~(isleaf |isbranch ); 

branchnodes =find (isbranch ); 
leafnodes =find (isleaf ); 


p =parentnode (nonroot &~pruned ); 
x =[X (nonroot &~pruned )' ; X (p )' ; NaN +p ' ]; 
y =[Y (nonroot &~pruned )' ; Y (p )' ; NaN +p ' ]; 



axislistener (ax ,false ); 
xlim =get (ax ,'XLim' ); 
ylim =get (ax ,'YLim' ); 
ud =get (ax ,'UserData' ); 
h =plot (X (branchnodes ),Y (branchnodes ),'b^' ,...
    X (leafnodes ),Y (leafnodes ),'b.' ,...
    x (:),y (:),'b-' ,'Parent' ,ax ); 
set (ax ,'UserData' ,ud ,'Visible' ,'on' ,'XLim' ,xlim ,'YLim' ,ylim ); 
set (ax ,'Color' ,'none' ); 
set (ax ,'XTick' ,[]); 
set (ax ,'YTick' ,[]); 
axislistener (ax ,true ); 


t =nonroot &pruned ; 
p =parentnode (t ); 
x =[X (t )' ; X (p )' ; NaN +p ' ]; 
y =[Y (t )' ; Y (p )' ; NaN +p ' ]; 
line ('Parent' ,ax ,'XData' ,X (pruned ),'YData' ,Y (pruned ),'Tag' ,'prunednode' ,...
    'Marker' ,'o' ,'Color' ,[.2 ,.2 ,.2 ],'Linestyle' ,'none' ,'HitTest' ,'off' ,...
    'PickableParts' ,'none' ); 
line ('Parent' ,ax ,'XData' ,x (:),'YData' ,y (:),'Tag' ,'prunedconnection' ,...
    'Marker' ,'none' ,'LineStyle' ,':' ,'Color' ,[.2 ,.2 ,.2 ],'HitTest' ,'off' ,...
    'PickableParts' ,'none' ); 
iflength (h )==3 
set (h (1 ),'ButtonDownFcn' ,@labelpoint ,'Tag' ,'branch' ,'MarkerSize' ,10 ); 
set (h (2 ),'ButtonDownFcn' ,@labelpoint ,'Tag' ,'leaf' ,'MarkerSize' ,20 ); 
set (h (end),'HitTest' ,'off' ,'PickableParts' ,'none' ,'Tag' ,'connection' ); 
else
set (h ,'ButtonDownFcn' ,@labelpoint ,'Tag' ,'leaf' ,'MarkerSize' ,20 ); 
end


if~isempty (classnames )
ctext =classnames (nodevalue (leafnodes )); 
else
ctext =num2str (nodevalue (leafnodes )); 
end

h =findobj (fig ,'Tag' ,'menuleaf' ); 
vis =get (h ,'Checked' ); 
text (X (leafnodes ),Y (leafnodes ),ctext ,'HitTest' ,'off' ,'PickableParts' ,'none' ,'Parent' ,ax ,...
    'VerticalAlignment' ,'top' ,'HorizontalAlignment' ,'center' ,...
    'Tag' ,'leaflabel' ,'Clipping' ,'on' ,'Visible' ,vis ,'Interpreter' ,'none' ); 

lefttext =cell (length (branchnodes ),1 ); 
righttext =cell (length (branchnodes ),1 ); 
forj =1 :length (branchnodes )
k =branchnodes (j ); 

varname =varnames {splitvar (k )}; 
iscont =~isnan (cutpoint (k )); 
ifnargin >=7 &&~isempty (vrange )
ifiscont 
[L ,R ]=condfun (true ,varname ,cutpoint (k ),vrange {splitvar (k )}); 
else
[L ,R ]=condfun (iscont ,varname ,cutcateg (k ,:),vrange {splitvar (k )}); 
end
lefttext {j }=[L ,'   ' ]; 
righttext {j }=['   ' ,R ]; 
else
ifiscont 
lefttext {j }=sprintf ('%s < %g   ' ,varname ,cutpoint (k )); 
righttext {j }=sprintf ('  %s >= %g' ,varname ,cutpoint (k )); 
else
cats =cutcateg {k ,1 }; 
iflength (cats )==1 
lefttext {j }=sprintf ('%s = %s   ' ,varname ,num2str (cats ,'%g ' )); 
else
lefttext {j }=sprintf ('%s %s (%s)   ' ,varname ,getString (message ('stats:classregtree:disp:ElementInSet' )),maketext (cats ,5 )); 
end
cats =cutcateg {k ,2 }; 
iflength (cats )==1 
righttext {j }=sprintf ('   %s = %s' ,varname ,num2str (cats ,'%g ' )); 
else
righttext {j }=sprintf ('   %s %s (%s)' ,varname ,getString (message ('stats:classregtree:disp:ElementInSet' )),maketext (cats ,5 )); 
end
end
end
end

h =findobj (fig ,'Tag' ,'menubr' ); 
vis =get (h ,'Checked' ); 
text (X (branchnodes ),Y (branchnodes ),lefttext ,'HitTest' ,'off' ,'PickableParts' ,'none' ,'Parent' ,ax ,...
    'Tag' ,'branchlabel' ,'Clipping' ,'on' ,'Visible' ,vis ,'Interpreter' ,'none' ,...
    'HorizontalAlignment' ,'right' ); 
text (X (branchnodes ),Y (branchnodes ),righttext ,'HitTest' ,'off' ,'PickableParts' ,'none' ,'Parent' ,ax ,...
    'Tag' ,'branchlabel' ,'Clipping' ,'on' ,'Visible' ,vis ,'Interpreter' ,'none' ,...
    'HorizontalAlignment' ,'left' ); 


doprunegraph (fig ); 


dozoom (fig ); 


layoutfig (fig ); 
end

function updatelevel (fig ,curlevel ,tree )


if~isempty (tree .PruneList )
maxlevel =max (tree .PruneList ); 
else
maxlevel =0 ; 
end
h =findobj (fig ,'Tag' ,'prunelev' ); 
set (h ,'String' ,sprintf ('%s' ,getString (...
    message ('stats:classregtree:view:PruneLevelOneOfMax' ,curlevel ,maxlevel )))); 
e =get (h ,'Extent' ); 
p =get (h ,'Position' ); 
p (3 )=e (3 ); 
set (h ,'Position' ,p ); 
end

function updateenable (fig )


ud =get (fig ,'UserData' ); 
curlevel =ud {7 }; 
fulltree =ud {6 }; 
enableg ='on' ; 
enablep ='on' ; 
ifisempty (fulltree .PruneList )
enableg ='off' ; 
enablep ='off' ; 
else
maxlevel =max (fulltree .PruneList ); 
ifcurlevel >=maxlevel 
enablep ='off' ; 
end
ifcurlevel <=0 
enableg ='off' ; 
end
end
set (findobj (fig ,'tag' ,'prune' ),'Enable' ,enablep ); 
set (findobj (fig ,'tag' ,'grow' ),'Enable' ,enableg ); 
end

function removelabels (varargin )


f =gcbf ; 
delete (findall (f ,'Tag' ,'LinescanMarker' )); 
delete (findall (f ,'Tag' ,'LinescanText' )); 
end
end

end

function [X ,Y ]=layouttree (tree ,isleaf )

n =size (tree .Children ,1 ); 
X =zeros (n ,1 ); 
Y =X ; 
layoutstyle =1 ; 


forj =1 :n 
p =tree .Parent (j ); 
ifp >0 
Y (j )=Y (p )+1 ; 
end
end
iflayoutstyle ==1 




forj =1 :n 
p =tree .Parent (j ); 
ifp ==0 
X (j )=0.5 ; 
else
dx =2 ^-(Y (j )+1 ); 
ifj ==tree .Children (p ,1 )
X (j )=X (p )-dx ; 
else
X (j )=X (p )+dx ; 
end
end
end


leaves =find (isleaf ); 
nleaves =length (leaves ); 
[~,b ]=sort (X (leaves )); 
X (leaves (b ))=(1 :nleaves )/(nleaves +1 ); 


forj =max (Y ):-1 :0 
a =find (~isleaf &Y ==j ); 
c =tree .Children (a ,:); 
X (a )=(X (c (:,1 ))+X (c (:,2 )))/2 ; 
end
else


X (Y ==0 )=0.5 ; 
forj =1 :max (Y )
vis =(Y ==j ); 
invis =(Y ==(j -1 )&isleaf ); 
nvis =sum (vis ); 
nboth =nvis +sum (invis ); 
x =[X (tree .Parent (vis ))+1e-10 *(1 :nvis )' ; X (invis )]; 
[xx ,xidx ]=sort (x ); 
xx (xidx )=1 :nboth ; 
X (vis )=(xx (1 :nvis )/(nboth +1 )); 
end
end

k =max (Y ); 
Y =1 -(Y +0.5 )/(k +1 ); 
end


function growprune (varargin )



h =gcbo ; 
fig =gcbf ; 
ud =get (fig ,'UserData' ); 
varnames =ud {4 }; 
nodevalue =ud {5 }; 
fulltree =ud {6 }; 
curlevel =ud {7 }; 
cnames =ud {8 }; 


prunelist =fulltree .PruneList ; 
ifisequal (get (h ,'Tag' ),'prune' )
curlevel =min (max (prunelist ),curlevel +1 ); 
else
curlevel =max (0 ,curlevel -1 ); 
end


ax =get (fig ,'CurrentAxes' ); 
delete (get (ax ,'Children' )); 
[X ,Y ]=classreg .learning .treeutils .TreeDrawer .drawtree (fulltree ,fig ,nodevalue ,varnames ,curlevel ,cnames ); 


set (fig ,'ButtonDownFcn' ,@classreg .learning .treeutils .TreeDrawer .removelabels ,...
    'UserData' ,{X ,Y ,0 ,varnames ,nodevalue ,fulltree ,curlevel ,cnames }); 

classreg .learning .treeutils .TreeDrawer .updateenable (fig ); 
classreg .learning .treeutils .TreeDrawer .updatelevel (fig ,curlevel ,fulltree ); 
end


function labelpoint (varargin )


h =gcbo ; 
f =gcbf ; 
stype =get (f ,'SelectionType' ); 
if~isequal (stype ,'alt' )&&~isequal (stype ,'extend' )
classreg .learning .treeutils .TreeDrawer .removelabels ; 
end
t =get (h ,'Tag' ); 
ifisequal (t ,'branch' )||isequal (t ,'leaf' )
ud =get (f ,'UserData' ); 
X =ud {1 }; 
Y =ud {2 }; 

varnames =ud {4 }; 
nodevalue =ud {5 }; 
tree =ud {6 }; 
curlevel =ud {7 }; 
cnames =ud {8 }; 

doclass =~isempty (cnames ); 

splitvar =tree .CutVar ; 
cutpoint =tree .CutPoint ; 
cutcateg =tree .CutCategories ; 

if~isempty (tree .PruneList )
ifcurlevel ==0 
isbranch =tree .IsBranch ; 
else
isbranch =(tree .PruneList >curlevel ); 
end
else
isbranch =tree .IsBranch ; 
end


ax =get (f ,'CurrentAxes' ); 
cp =get (ax ,'CurrentPoint' ); 
D =abs (X -cp (1 ,1 ))+abs (Y -cp (1 ,2 )); 
ifisequal (t ,'branch' )
D (~isbranch )=Inf ; 
else
D (isbranch )=Inf ; 
end
[~,node ]=min (D ); 
uih =findobj (f ,'Tag' ,'clicklist' ); 
labeltype =get (uih ,'Value' ); 

ifisequal (labeltype ,4 )&&doclass 

P =tree .ClassProb ; 
txt =getString (message ('stats:classregtree:view:ClassProbabilities' )); 
forj =1 :size (P ,2 )
txt =sprintf ('%s\n%s = %.3g' ,txt ,cnames {j },P (node ,j )); 
end

elseifisequal (labeltype ,3 )&&~doclass 

xbar =nodevalue ; 
Nk =tree .NodeSize (node ); 
ifNk >1 
s =sqrt ((tree .NodeRisk (node )./tree .NodeProb (node )*Nk )/(Nk -1 )); 
txt =sprintf ('N = %d\n%s = %g\n%s = %g' ,...
    Nk ,...
    getString (message ('stats:classregtree:view:TreeNodeMean' )),...
    xbar (node ),...
    getString (message ('stats:classregtree:view:TreeNodeStandardDeviation' )),...
    s ); 
else
txt =sprintf ('N = %d\n%s = %g' ,...
    Nk ,...
    getString (message ('stats:classregtree:view:TreeNodeMean' )),...
    xbar (node )); 
end

elseifisequal (labeltype ,3 )&&doclass 

C =tree .ClassCount ; 
N =tree .NodeSize (node ); 
txt =sprintf ('%s = %d' ,getString (message ('stats:classregtree:view:TotalDataPoints' )),N ); 
forj =1 :size (C ,2 )
txt =sprintf ('%s\n%d %s' ,txt ,C (node ,j ),cnames {j }); 
end

elseifisequal (labeltype ,1 )


if~isequal (t ,'branch' )
ifdoclass 
txt =sprintf ('%s %d (%s)\n%s: %s' ,...
    getString (message ('stats:classregtree:view:TreeNode' )),...
    node ,...
    getString (message ('stats:classregtree:view:TreeLeaf' )),...
    getString (message ('stats:classregtree:view:PredictedClass' )),...
    cnames {nodevalue (node )}); 
else
txt =sprintf ('%s %d (%s)\n%s: %g' ,...
    getString (message ('stats:classregtree:view:TreeNode' )),...
    node ,...
    getString (message ('stats:classregtree:view:TreeLeaf' )),...
    getString (message ('stats:classregtree:view:RegressionPrediction' )),...
    nodevalue (node )); 
end
elseif~isnan (cutpoint (node ))
txt =sprintf ('%s %d (%s)\n%s:  %s < %g' ,...
    getString (message ('stats:classregtree:view:TreeNode' )),...
    node ,...
    getString (message ('stats:classregtree:view:TreeBranch' )),...
    getString (message ('stats:classregtree:view:SplittingRule' )),...
    varnames {splitvar (node )},...
    cutpoint (node )); 
else
cut =cutcateg (node ,:); 
cats =cut {1 }; 
iflength (cats )==1 
txt =sprintf ('%s %d (%s)\n%s:  %s = %s' ,...
    getString (message ('stats:classregtree:view:TreeNode' )),...
    node ,...
    getString (message ('stats:classregtree:view:TreeBranch' )),...
    getString (message ('stats:classregtree:view:SplittingRule' )),...
    varnames {splitvar (node )},...
    num2str (cats ,'%g ' )); 
else
txt =sprintf ('%s %d (%s)\n%s:  %s %s (%s)' ,...
    getString (message ('stats:classregtree:view:TreeNode' )),...
    node ,...
    getString (message ('stats:classregtree:view:TreeBranch' )),...
    getString (message ('stats:classregtree:view:SplittingRule' )),...
    varnames {splitvar (node )},...
    getString (message ('stats:classregtree:disp:ElementInSet' )),...
    maketext (cats ,20 )); 
end
end
elseifisequal (labeltype ,2 )

ifnode ==1 
txt =getString (message ('stats:classregtree:view:RootOfTree' )); 
else

nvars =max (splitvar (:)); 
lims =cell (nvars ,3 ); 
lims (:,1 )={-Inf }; 
lims (:,2 )={Inf }; 
lims (:,3 )=num2cell ((1 :nvars )' ); 
p =tree .Parent (node ); 
c =node ; 
while(p >0 )
leftright =1 +(tree .Children (p ,2 )==c ); 
vnum =splitvar (p ); 
if~isnan (cutpoint (p ))
ifisinf (lims {vnum ,3 -leftright })
lims {vnum ,3 -leftright }=cutpoint (p ); 
end
else
if~iscell (lims {vnum ,1 })
vcut =cutcateg (p ,:); 
lims {vnum ,1 }=vcut (leftright ); 
end
end
c =p ; 
p =tree .Parent (p ); 
end


txt =getString (message ('stats:classregtree:view:AtThisNode' )); 
forj =1 :size (lims ,1 )
L1 =lims {j ,1 }; 
L2 =lims {j ,2 }; 
if~iscell (L1 )&&isinf (L1 )&&isinf (L2 )
continue 
end
vnum =lims {j ,3 }; 

ifiscell (L1 )
cats =L1 {1 }; 
iflength (cats )==1 
txt =sprintf ('%s\n%s = %s' ,txt ,varnames {vnum },num2str (cats ,'%g ' )); 
else
txt =sprintf ('%s\n%s %s (%s)' ,txt ,varnames {vnum },...
    getString (message ('stats:classregtree:disp:ElementInSet' )),...
    maketext (cats ,20 )); 
end
elseifisinf (L1 )
txt =sprintf ('%s\n%s < %g' ,txt ,varnames {vnum },L2 ); 
elseifisinf (L2 )
txt =sprintf ('%s\n%g <= %s' ,txt ,L1 ,varnames {vnum }); 
else
txt =sprintf ('%s\n%g <= %s < %g' ,txt ,L1 ,varnames {vnum },L2 ); 
end
end
end
else
txt ='' ; 
end


if~isempty (txt )
x =X (node ); 
y =Y (node ); 
xlim =get (ax ,'xlim' ); 
ylim =get (ax ,'ylim' ); 
ifx <mean (xlim )
halign ='left' ; 
dx =0.02 ; 
else
halign ='right' ; 
dx =-0.02 ; 
end
ify <mean (ylim )
valign ='bottom' ; 
dy =0.02 ; 
else
valign ='top' ; 
dy =-0.02 ; 
end
h =text (x +dx *diff (xlim ),y +dy *diff (ylim ),txt ,'Interpreter' ,'none' ); 
yellow =[1 ,1 ,.85 ]; 
set (h ,'backgroundcolor' ,yellow ,'margin' ,3 ,'edgecolor' ,'k' ,...
    'HorizontalAlignment' ,halign ,'VerticalAlignment' ,valign ,...
    'tag' ,'LinescanText' ,'ButtonDownFcn' ,@startmovetips ); 
line (x ,y ,'Color' ,yellow ,'Marker' ,'.' ,'MarkerSize' ,20 ,...
    'Tag' ,'LinescanMarker' ); 
end
end
end


function startmovetips (varargin )


f =gcbf ; 
set (f ,'WindowButtonUpFcn' ,@donemovetips ,...
    'WindowButtonMotionFcn' ,@showmovetips ,...
    'Interruptible' ,'off' ,'BusyAction' ,'queue' ); 

o =gcbo ; 
p1 =get (f ,'CurrentPoint' ); 
a =get (f ,'CurrentAxes' ); 
ud =get (a ,'UserData' ); 
ud (1 :2 )={o ,p1 }; 
set (a ,'UserData' ,ud ); 
end


function showmovetips (varargin )

domovetips (0 ,varargin {:}); 
end


function donemovetips (varargin )

domovetips (1 ,varargin {:}); 
end


function domovetips (alldone ,varargin )


f =gcbf ; 
ifalldone 
set (f ,'WindowButtonUpFcn' ,'' ,'WindowButtonMotionFcn' ,'' ); 
end
a =get (f ,'CurrentAxes' ); 
ud =get (a ,'UserData' ); 
o =ud {1 }; 
p1 =ud {2 }; 
p2 =get (f ,'CurrentPoint' ); 
p0 =get (a ,'Position' ); 
pos =get (o ,'Position' ); 
dx =(p2 (1 )-p1 (1 ))*diff (get (a ,'XLim' ))/p0 (3 ); 
dy =(p2 (2 )-p1 (2 ))*diff (get (a ,'YLim' ))/p0 (4 ); 
pos (1 )=pos (1 )+dx ; 
pos (2 )=pos (2 )+dy ; 
set (o ,'Position' ,pos ); 
ud {2 }=p2 ; 
set (a ,'UserData' ,ud ); 
end


function resize (varargin )

layoutfig (gcbf )
end


function layoutfig (f )


set (f ,'Units' ,'points' ); 
fpos =get (f ,'Position' ); 


h =findobj (f ,'Tag' ,'frame' ); 
frpos =get (h ,'Position' ); 
frpos (2 )=fpos (4 )-frpos (4 ); 
frpos (3 )=fpos (3 ); 
set (h ,'Position' ,frpos ); 


tags ={'clicktext' ,'clicklist' ,'magtext' ,'maglist' ...
    ,'pruneframe' ,'prunelabel' ,'prunelev' }; 
mult =[1.6 ,1.35 ,1.6 ,1.35 ...
    ,1.7 ,1.6 ,1.6 ]; 
forj =1 :length (tags )
h =findobj (f ,'Tag' ,tags {j }); 
p =get (h ,'Position' ); 
ifj ==1 ,theight =p (4 ); end
p (2 )=fpos (4 )-mult (j )*theight ; 
set (h ,'Position' ,p ); 
end

h =findobj (f ,'Tag' ,'grow' ); 
p =get (h ,'Position' ); 
p (2 )=frpos (2 )+2 ; 
set (h ,'Position' ,p ); 
h =findobj (f ,'Tag' ,'prune' ); 
p (2 )=p (2 )+p (4 ); 
set (h ,'Position' ,p ); 


hh =findobj (f ,'Tag' ,'hslider' ); 
hv =findobj (f ,'Tag' ,'vslider' ); 
p1 =get (hh ,'Position' ); 
sw =p1 (4 ); 
p1 (3 )=frpos (3 )-sw -1 ; 
set (hh ,'Position' ,p1 ); 
p2 =get (hv ,'Position' ); 
p2 (1 )=frpos (3 )-sw -1 ; 
p2 (4 )=frpos (2 )-sw -1 ; 
set (hv ,'Position' ,p2 ); 
ifisequal (get (hh ,'Visible' ),'off' )
sw =0 ; 
end


h =get (f ,'CurrentAxes' ); 
p =[0 ,sw ,frpos (3 )-sw ,frpos (2 )-sw ]; 
set (h ,'Position' ,p ); 
end


function domenu (varargin )


o =gcbo ; 
f =gcbf ; 
t =get (o ,'Tag' ); 
switch(t )

case {'menufull' ,'menuunpr' }
ischecked =isequal (get (o ,'Checked' ),'on' ); 
isfull =isequal (t ,'menufull' ); 
ifisfull 
dofull =~ischecked ; 
else
dofull =ischecked ; 
end
mfull =findobj (f ,'Type' ,'uimenu' ,'Tag' ,'menufull' ); 
munpr =findobj (f ,'Type' ,'uimenu' ,'Tag' ,'menuunpr' ); 
ifdofull 
set (mfull ,'Checked' ,'on' ); 
set (munpr ,'Checked' ,'off' ); 
else
set (mfull ,'Checked' ,'off' ); 
set (munpr ,'Checked' ,'on' ); 
end
doprunegraph (f ,dofull ); 
dozoom (f ); 


case 'menubr' 
curval =get (o ,'Checked' ); 
ifisequal (curval ,'on' )
set (o ,'Checked' ,'off' ); 
h =findobj (f ,'Type' ,'text' ,'Tag' ,'branchlabel' ); 
set (h ,'Visible' ,'off' ); 
else
set (o ,'Checked' ,'on' ); 
h =findobj (f ,'Type' ,'text' ,'Tag' ,'branchlabel' ); 
set (h ,'Visible' ,'on' ); 
end


case 'menuleaf' 
curval =get (o ,'Checked' ); 
ifisequal (curval ,'on' )
set (o ,'Checked' ,'off' ); 
h =findobj (f ,'Type' ,'text' ,'Tag' ,'leaflabel' ); 
set (h ,'Visible' ,'off' ); 
else
set (o ,'Checked' ,'on' ); 
h =findobj (f ,'Type' ,'text' ,'Tag' ,'leaflabel' ); 
set (h ,'Visible' ,'on' ); 
end
end
end


function doprunegraph (f ,dofull )


a =get (f ,'CurrentAxes' ); 
h1 =findobj (a ,'Type' ,'line' ,'Tag' ,'prunednode' ); 
h2 =findobj (a ,'Type' ,'line' ,'Tag' ,'prunedconnection' ); 


ifnargin <2 
o =findobj (f ,'Type' ,'uimenu' ,'Tag' ,'menufull' ); 
dofull =isequal (get (o ,'Checked' ),'on' ); 
end


ifdofull 
set (h1 ,'Visible' ,'on' ); 
set (h2 ,'Visible' ,'on' ); 
xlim =get (a ,'XLim' ); 
ylim =get (a ,'YLim' ); 
bigxlim =0 :1 ; 
bigylim =0 :1 ; 
else
set (h1 ,'Visible' ,'off' ); 
set (h2 ,'Visible' ,'off' ); 
h1 =findobj (f ,'Type' ,'line' ,'Tag' ,'leaf' ); 
h2 =findobj (f ,'Type' ,'line' ,'Tag' ,'branch' ); 
x1 =get (h1 ,'XData' ); 
y1 =get (h1 ,'YData' ); 
y2 =get (h2 ,'YData' ); 
dx =1 /(1 +length (x1 )); 
ally =sort (unique ([y1 (:); y2 (:)])); 
iflength (ally )>1 
dy =0.5 *(ally (2 )-ally (1 )); 
else
dy =1 -ally ; 
end
xlim =[min (x1 )-dx ,max (x1 )+dx ]; 
ylim =[min (ally )-dy ,max (ally )+dy ]; 
bigxlim =0 :1 ; 
bigylim =[ylim (1 ),1 ]; 
end
axislistener (a ,false ); 
set (a ,'XLim' ,xlim ,'YLim' ,ylim ); 
axislistener (a ,true ); 
hh =findobj (f ,'Tag' ,'hslider' ); 
set (hh ,'UserData' ,bigxlim ); 
hv =findobj (f ,'Tag' ,'vslider' ); 
set (hv ,'UserData' ,bigylim ); 
end


function domagnif (varargin )


f =gcbf ; 
o =gcbo ; 


h =[findobj (f ,'Tag' ,'hslider' ),findobj (f ,'Tag' ,'vslider' )]; 
maglevel =get (o ,'Value' ); 
ifmaglevel ==1 
set (h ,'Visible' ,'off' ); 
else
set (h ,'Visible' ,'on' ); 
end


resize ; 


dozoom (f ); 


ifmaglevel <=4 
adjustcustomzoom (o ,false ); 
end


zoom (f ,'off' ); 
end


function adjustcustomzoom (o ,add )

nchoices =size (get (o ,'String' ),1 ); 
choices ='100%|200%|400%|800%' ; 
if~add &&nchoices ~=4 
set (o ,'String' ,choices ); 
elseifadd &&nchoices ~=5 
choices =[choices ,'|' ,'Custom' ]; 
set (o ,'String' ,choices ); 
end
end


function dozoom (f )


a =get (f ,'CurrentAxes' ); 
hh =findobj (f ,'Tag' ,'hslider' ); 
hv =findobj (f ,'Tag' ,'vslider' ); 
hm =findobj (f ,'Tag' ,'maglist' ); 


bigxlim =get (hh ,'UserData' ); 
bigylim =get (hv ,'UserData' ); 
xlim =get (a ,'XLim' ); 
ylim =get (a ,'YLim' ); 
currx =(xlim (1 )+xlim (2 ))/2 ; 
curry =(ylim (1 )+ylim (2 ))/2 ; 


magfact =[1 ,2 ,4 ,8 ]; 
mag =get (hm ,'Value' ); 
ifmag <=4 
magfact =magfact (mag )*ones (1 ,2 ); 
else
magfact =[diff (bigxlim )/diff (xlim ),diff (bigylim )/diff (ylim )]; 
end
magfact =max (magfact ,1 ); 

ifall (magfact ==1 )
xlim =bigxlim ; 
ylim =bigylim ; 
else
magfact =max (magfact ,1.01 ); 
dx =diff (bigxlim )/magfact (1 ); 
dy =diff (bigylim )/magfact (2 ); 
xval =max (bigxlim (1 ),min (bigxlim (2 )-dx ,currx -dx /2 )); 
xlim =xval +[0 ,dx ]; 
yval =max (bigylim (1 ),min (bigylim (2 )-dy ,curry -dy /2 )); 
ylim =yval +[0 ,dy ]; 
set (hh ,'Min' ,bigxlim (1 ),'Max' ,bigxlim (2 )-dx ,'Value' ,xval ); 
set (hv ,'Min' ,bigylim (1 ),'Max' ,bigylim (2 )-dy ,'Value' ,yval ); 
end
axislistener (a ,false ); 
set (a ,'XLim' ,xlim ,'YLim' ,ylim ); 
axislistener (a ,true ); 
end


function dopan (varargin )


f =gcbf ; 
a =get (f ,'CurrentAxes' ); 
o =gcbo ; 
val =get (o ,'Value' ); 

axislistener (a ,false ); 
ifisequal (get (o ,'Tag' ),'hslider' )
xlim =get (a ,'XLim' ); 
xlim =xlim +(val -xlim (1 )); 
set (a ,'XLim' ,xlim ); 
else
ylim =get (a ,'YLim' ); 
ylim =ylim +(val -ylim (1 )); 
set (a ,'YLim' ,ylim ); 
end
axislistener (a ,true ); 
end


function axislistener (a ,enable )


f =get (a ,'Parent' ); 
ud =get (a ,'UserData' ); 
ifenable 

list1 =addlistener (a ,'XLim' ,'PostSet' ,@(src ,evt )customzoom (f )); 
list2 =addlistener (a ,'YLim' ,'PostSet' ,@(src ,evt )customzoom (f )); 
ud (3 :4 )={list1 ,list2 }; 
else

forj =3 :4 
lstnr =ud {j }; 
if~isempty (lstnr ),delete (lstnr ); end
end
ud (3 :4 )={[]}; 
end
set (a ,'UserData' ,ud ); 
end


function customzoom (f )


a =get (f ,'CurrentAxes' ); 
xlim =get (a ,'XLim' ); 
ylim =get (a ,'YLim' ); 

hh =findobj (f ,'Tag' ,'hslider' ); 
hv =findobj (f ,'Tag' ,'vslider' ); 
hm =findobj (f ,'Tag' ,'maglist' ); 

bigxlim =get (hh ,'UserData' ); 
bigylim =get (hv ,'UserData' ); 
magfact =[1 ,2 ,4 ,8 ]; 



xratio =diff (bigxlim )/diff (xlim ); 
yratio =diff (bigylim )/diff (ylim ); 
standard =abs (xratio -yratio )<=0.02 &abs (xratio -round (xratio ))<=0.02 ...
    &abs (yratio -round (yratio ))<=0.02 ; 
ifstandard 
xratio =round (xratio ); 
standard =ismember (xratio ,magfact ); 
end


ifstandard 
set (hm ,'Value' ,find (magfact ==xratio )); 
adjustcustomzoom (hm ,false ); 
ifxratio ==1 
h =[findobj (f ,'Tag' ,'hslider' ),findobj (f ,'Tag' ,'vslider' )]; 
set (h ,'Visible' ,'off' ); 
end
else
adjustcustomzoom (hm ,true ); 
set (hm ,'Value' ,5 ); 
h =[findobj (f ,'Tag' ,'hslider' ),findobj (f ,'Tag' ,'vslider' )]; 
set (h ,'Visible' ,'on' ); 
end

dozoom (f ); 
end

function txt =maketext (cats ,maxnum )
txt =deblank (sprintf ('%g ' ,cats (1 :min (maxnum ,end)))); 
iflength (cats )>maxnum 
txt =[txt ,'...' ]; 
end
end
