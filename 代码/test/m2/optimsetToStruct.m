function sOut =optimsetToStruct (sIn )








sOut =sIn ; 


if~isempty (sIn .OutputFcn )
sOut .OutputFcn =func2str (sIn .OutputFcn ); 
end

if~isempty (sIn .PlotFcns )
sOut .PlotFcns =func2str (sIn .PlotFcns ); 
end

if~isempty (sIn .HessFcn )
sOut .HessFcn =func2str (sIn .HessFcn ); 
end

if~isempty (sIn .HessMult )
sOut .HessMult =func2str (sIn .HessMult ); 
end

if~isempty (sIn .JacobMult )
sOut .JacobMult =func2str (sIn .JacobMult ); 
end

end