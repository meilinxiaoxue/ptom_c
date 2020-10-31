function ds =datasetcopier (ds ,D )




props =D .Properties ; 

vn =props .VarNames ; 
forj =1 :length (vn )
vnj =vn {j }; 
ds .(vnj )=D .(vnj ); 
end

fn =fields (props ); 
forj =1 :length (fn )
fnj =fn {j }; 
ds .Properties .(fnj )=D .Properties .(fnj ); 
end
