classdef CompactClassificationModel <classreg .learning .coder .CompactPredictor %#codegen 





properties (SetAccess =protected ,GetAccess =public )


ClassNames ; 




ClassNamesType ; 


ClassNamesLength ; 



ScoreTransform ; 


Prior ; 



NonzeroProbClasses ; 




Cost ; 

end
methods (Abstract )


predict (obj )
end
methods (Abstract ,Hidden ,Access =protected )
predictEmptyX (obj )
end
methods (Access =protected )
function obj =CompactClassificationModel (cgStruct )

coder .internal .prefer_const (cgStruct ); 

obj @classreg .learning .coder .CompactPredictor (cgStruct ); 

validateFields (cgStruct ); 
obj .ClassNamesType =cgStruct .ClassSummary .ClassNamesType ; 
obj .ClassNames =cgStruct .ClassSummary .ClassNames ; 
obj .ClassNamesLength =coder .internal .indexInt (cgStruct .ClassSummary .ClassNamesLength ); 
obj .NonzeroProbClasses =cgStruct .ClassSummary .NonzeroProbClasses ; 
obj =obj .setScoreTransform (cgStruct ); 

end
end

methods (Access =protected )
function obj =setScoreTransform (obj ,cgStruct )

coder .internal .prefer_const (cgStruct ); 

ifisfield (cgStruct ,'CustomScoreTransform' )
ifcgStruct .CustomScoreTransform 
obj .ScoreTransform =str2func (cgStruct .ScoreTransformFull ); 
else
ifstrcmpi (cgStruct .ScoreTransform ,'identity' )
obj .ScoreTransform =[]; 
else
obj .ScoreTransform =str2func (['classreg.learning.coder.transform.' ,cgStruct .ScoreTransform ]); 
end
end
else
obj .ScoreTransform =[]; 
end
end

function obj =setCost (obj ,strCost ,castVar )


coder .internal .prefer_const (strCost ); 
K =size (obj .ClassNames ,1 ); 
ifisempty (strCost )
cost =ones (K ,'like' ,castVar )-eye (K ,'like' ,castVar ); 
else
cost =zeros (K ,'like' ,castVar ); 
[~,pos ]=ismember (obj .NonzeroProbClasses ,...
    obj .ClassNames ,'rows' ); 
cost (pos ,pos )=cast (strCost ,'like' ,castVar ); 
forii =1 :coder .internal .indexInt (K )
unmatched =false ; 
forjj =1 :coder .internal .indexInt (numel (pos ))
if(ii ==pos (jj ))
unmatched =true ; 
break; 
end
end
ifunmatched 
ifcoder .target ('MATLAB' )
cost (:,ii )=NaN ; 
else
cost (:,ii )=coder .internal .nan ; 
end
end
end
cost (1 :K +1 :end)=0 ; 
end
obj .Cost =cost ; 
end

function [labels ,cost ,classnum ]=maxScore (obj ,scores )


classNamesType =obj .ClassNamesType ; 
classNames =obj .ClassNames ; 
classNamesLength =obj .ClassNamesLength ; 
prior =obj .Prior ; 

N =size (scores ,1 ); 
notNaN =~all (isnan (scores ),2 ); 
[~,cls ]=max (prior ); 
classnum =coder .internal .nan (coder .internal .indexInt (N ),1 ,'like' ,scores ); 
cost =coder .internal .nan (N ,size (obj .Cost ,2 ),'like' ,scores ); 
foridx =1 :coder .internal .indexInt (numel (notNaN ))
ifnotNaN (idx )
[~,classnum (idx )]=max (scores (idx ,:),[],2 ); 
cost (idx ,:)=obj .Cost (:,cast (classnum (idx ),'uint32' )); 
end
end
ifclassreg .learning .coderutils .iscellarray (classNamesType )



labelsInit =classNames (cls ,:); 
labels =repmat ({labelsInit (1 :classNamesLength (cls ))},N ,1 ); 
foridx =1 :coder .internal .indexInt (numel (notNaN ))
ifnotNaN (idx )

labels {idx ,1 }=classNames (cast (classnum (idx ),'uint32' ),1 :classNamesLength (cast (classnum (idx ),'uint32' ))); 

end
end

else
labels =repmat (classNames (cls ,:),N ,1 ); 
foridx =1 :coder .internal .indexInt (numel (notNaN ))
ifnotNaN (idx )
labels (idx ,:)=classNames (cast (classnum (idx ),'uint32' ),:); 
end
end
end
end

function [labels ,classnum ,cost ,scores ]=minCost (obj ,scores )



classNamesType =obj .ClassNamesType ; 
classNames =obj .ClassNames ; 
classNamesLength =obj .ClassNamesLength ; 
prior =obj .Prior ; 
cost =scores *obj .Cost ; 
N =size (scores ,1 ); 
[~,cls ]=max (prior ); 
classnum =coder .nullcopy (zeros (coder .internal .indexInt (N ),1 ,'like' ,scores )); 
foridx =1 :coder .internal .indexInt (N )
[~,classnum (idx )]=min (cost (idx ,:),[],2 ); 
end
ifclassreg .learning .coderutils .iscellarray (classNamesType )
labelsInit =classNames (cls ,:); 
labels =repmat ({labelsInit (1 :classNamesLength (cls ))},N ,1 ); 
foridx =1 :coder .internal .indexInt (N )
labels {idx ,1 }=classNames (cast (classnum (idx ),'uint32' ),1 :classNamesLength (cast (classnum (idx ),'uint32' ))); 
end
else
labels =repmat (classNames (cls ,:),N ,1 ); 
foridx =1 :coder .internal .indexInt (N )
labels (idx ,:)=classNames (cast (classnum (idx ),'uint32' ),:); 
end
end
if~isempty (obj .ScoreTransform )
scores =obj .ScoreTransform (scores ); 
end
end
end

methods (Static ,Hidden )
function props =matlabCodegenNontunableProperties (~)
propstemp =classreg .learning .coder .CompactPredictor .matlabCodegenNontunableProperties ; 
propstemp2 ={'ClassNamesType' }; 
props =[propstemp ,propstemp2 ]; 
end

end
end

function validateFields (InStr )

coder .inline ('always' ); 

validateattributes (InStr .ClassSummary .ClassNamesLength ,{'numeric' },{'2d' ,'ncols' ,1 ,'integer' ,'real' ,'nonnegative' },mfilename ,'ClassNamesLength' ); 
validateattributes (InStr .ClassSummary .ClassNames ,{'numeric' ,'char' ,'logical' },{'2d' ,'nrows' ,size (InStr .ClassSummary .ClassNamesLength ,1 ),'real' },mfilename ,'ClassNames' ); 
validateattributes (InStr .ClassSummary .ClassNamesType ,{'int8' },{'scalar' ,'real' ,'<' ,int8 (3 ),'nonnegative' },mfilename ,'ClassNamesType' ); 
if~isscalar (InStr .ClassSummary .Prior )
validateattributes (InStr .ClassSummary .Prior ,{'numeric' },{'row' ,'real' ,'nonnegative' },mfilename ,'Prior' ); 
validateattributes (InStr .ClassSummary .NonzeroProbClasses ,{class (InStr .ClassSummary .ClassNames )},{'size' ,[size (InStr .ClassSummary .Prior ,2 ),size (InStr .ClassSummary .ClassNames ,2 )],'real' },mfilename ,'NonzeroProbClasses' ); 
else
validateattributes (InStr .ClassSummary .Prior ,{'numeric' },{'real' ,'positive' },mfilename ,'Prior' ); 
validateattributes (InStr .ClassSummary .NonzeroProbClasses ,{class (InStr .ClassSummary .ClassNames )},{'size' ,[1 ,InStr .ClassSummary .NonzeroProbClassesLength ],'real' },mfilename ,'NonzeroProbClasses' ); 
end

validateattributes (InStr .ScoreTransform ,{'char' },{'nonempty' ,'row' },mfilename ,'ScoreTransform' ); 

ifisfield (InStr ,'CustomScoreTransform' )
validateattributes (InStr .ScoreTransformFull ,{'char' },{'nonempty' ,'row' },mfilename ,'ScoreTransform' ); 
validateattributes (InStr .CustomScoreTransform ,{'logical' },{'nonempty' ,'scalar' },mfilename ,'CustomScoreTransform' ); 
end

end