function adapter = makeClassificationModelAdapter(obj,varargin)

if  any(cellfun(@(x) istall(x),varargin))
    adapter = internal.stats.bigdata.ClassRegModelTallAdapter(obj);

% No current support for GPU arrays    
%
%elseif any(cellfun(@(x) isa(x,'gpuArray'),varargin))
%    adapter = ClassificationModelGPUAdapter(obj);

else
    adapter = [];
end

end
