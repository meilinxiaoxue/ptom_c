classdef CompactTree %#codegen 






properties (SetAccess =protected ,GetAccess =public )



CutVar ; 


Children ; 



ClassProb ; 


CutPoint ; 



PruneList ; 

end
methods (Access =protected )
function obj =CompactTree (cgStruct )




coder .internal .prefer_const (cgStruct ); 


validateFields (cgStruct ); 

obj .CutPoint =cgStruct .Impl .CutPoint ; 
obj .CutVar =cast (cgStruct .Impl .CutVar ,'like' ,cgStruct .Impl .CutPoint ); 
obj .Children =cast (cgStruct .Impl .Children ' ,'like' ,cgStruct .Impl .CutPoint ); 
obj .ClassProb =cast (cgStruct .Impl .ClassProb ,'like' ,cgStruct .Impl .CutPoint ); 
obj .CutPoint (cgStruct .NanCutPoints )=cast (coder .internal .nan ,'like' ,cgStruct .Impl .CutPoint ); 
obj .CutPoint (cgStruct .InfCutPoints )=cast (coder .internal .inf ,'like' ,cgStruct .Impl .CutPoint ); 
obj .PruneList =cast (cgStruct .Impl .PruneList ,'like' ,cgStruct .Impl .CutPoint ); 



end
end

methods (Access =protected )


function n =findNode (obj ,X ,subtrees )

p =coder .internal .indexInt (size (X ,2 )); 

coder .internal .errorIf (~coder .internal .isConst (p )||p ~=obj .NumPredictors ,...
    'stats:classreg:learning:impl:TreeImpl:findNode:BadXSize' ,obj .NumPredictors ); 


n =classreg .learning .coder .treeutils .findNode (X ,...
    subtrees ,obj .PruneList ,...
    obj .Children ,obj .CutVar ,obj .CutPoint ); 
end
end

methods (Static ,Access =protected )

function posterior =treePredictEmptyX (Xin ,K ,numPredictors )

Dpassed =coder .internal .indexInt (size (Xin ,2 )); 
str ='columns' ; 

coder .internal .errorIf (~coder .internal .isConst (Dpassed )||Dpassed ~=numPredictors ,...
    'stats:classreg:learning:classif:ClassificationModel:predictEmptyX:XSizeMismatch' ,numPredictors ,str ); 

posterior =repmat (coder .internal .nan (1 ,1 ,'like' ,Xin ),0 ,K ); 
end

function subtrees =extractSubtrees (PruneList ,varargin )


subtreesInput =predictParseInputs (varargin {:}); 


subtrees =classreg .learning .coder .model .CompactTree .processSubtrees (PruneList ,subtreesInput ); 
end

function subtrees =processSubtrees (PruneList ,subtreesInput )


validateSubtrees (subtreesInput ); 
coder .internal .errorIf ((~strcmpi (subtreesInput ,'all' )&&...
    (~isnumeric (subtreesInput )||~isvector (subtreesInput )...
    ||any (any (subtreesInput <0 ,2 ),1 )||any (any (diff (subtreesInput ,1 ,1 )<0 ,2 ),1 )...
    ||any (any (diff (subtreesInput ,1 ,2 )<0 ,2 ),1 ))),...
    'stats:classreg:learning:impl:TreeImpl:processSubtrees:BadSubtrees' ); 

ifisempty (PruneList )
subtreesisValid =isscalar (subtreesInput )&&all (subtreesInput ==0 ); 
coder .internal .errorIf (~subtreesisValid ,...
    'stats:classreg:learning:impl:TreeImpl:processSubtrees:NoPruningInfo' ); 
subtrees =cast (subtreesInput ,'uint32' ); 
return ; 
else
ifischar (subtreesInput )
subtreesall =cast (min (PruneList ):max (PruneList ),'uint32' ); 
subtrees =subtreesall ; 
else
subtrees =subtreesInput ; 
end
coder .internal .errorIf (subtrees (end)>max (PruneList ),...
    'stats:classreg:learning:impl:TreeImpl:processSubtrees:SubtreesTooBig' ); 
end
end
end

methods (Static ,Hidden )
function props =matlabCodegenNontunableProperties (~)
props ={'PruneList' }; 
end
end
end

function subtrees =predictParseInputs (varargin )




coder .inline ('always' ); 
coder .internal .prefer_const (varargin ); 

params =struct (...
    'Subtrees' ,uint32 (0 )); 

popts =struct (...
    'CaseSensitivity' ,false ,...
    'StructExpand' ,true ,...
    'PartialMatching' ,true ); 

optarg =eml_parse_parameter_inputs (params ,popts ,varargin {:}); 
subtrees =eml_get_parameter_value (optarg .Subtrees ,uint32 (0 ),varargin {:}); 
end


function validateSubtrees (subtrees )


coder .inline ('always' ); 
coder .internal .prefer_const (subtrees ); 

ifisnumeric (subtrees )
validateattributes (subtrees ,{'double' ,'single' ,'uint32' },...
    {'nonnan' ,'finite' ,'real' ,'nonempty' ,'nonnegative' },mfilename ,'subtrees' ); 
else
coder .internal .assert (coder .internal .isConst (subtrees ),...
    'stats:classreg:learning:impl:TreeImpl:processSubtrees:BadSubtrees' ); 
validateattributes (subtrees ,{'char' },...
    {'size' ,[1 ,3 ]},mfilename ,'subtrees' ); 
validatestring (subtrees ,{'all' },mfilename ,'subtrees' ); 
end
end


function validateFields (cgStruct )


coder .inline ('always' ); 



validateattributes (cgStruct .Impl .CutVar ,{'numeric' },{'nonnan' ,...
    'nonnegative' ,'finite' ,'integer' ,'nonempty' ,'real' },mfilename ,'CutVar' ); 
validateattributes (cgStruct .Impl .Children ,{'numeric' },{'nonnan' ,'integer' ,'nonnegative' ,'real' },mfilename ,'Children' ); 
if~isempty (cgStruct .Impl .PruneList )
validateattributes (cgStruct .Impl .PruneList ,{'numeric' },{'nonnan' ,'real' ,...
    'nonnegative' ,'integer' ,'size' ,[size (cgStruct .Impl .Children ,1 ),1 ]},mfilename ,'PruneList' ); 
end

end


