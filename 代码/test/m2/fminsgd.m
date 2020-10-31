function [x ,cause ]=fminsgd (fun ,x0 ,N ,varargin )



























































































































































































































































narginchk (3 ,Inf ); 



isok =isa (fun ,'function_handle' ); 
if(~isok )
error (message ('stats:classreg:learning:fsutils:fminsgd:BadFun' )); 
end


isok =isnumeric (x0 )&&isreal (x0 )&&isvector (x0 ); 
if(~isok )
error (message ('stats:classreg:learning:fsutils:fminsgd:BadX0' )); 
end
x0 =x0 (:); 


isok =internal .stats .isIntegerVals (N ,1 ); 
if(~isok )
error (message ('stats:classreg:learning:fsutils:fminsgd:BadN' )); 
end




dfltTolX =1e-6 ; 
dfltDisplay ='off' ; 
dfltMaxIter =N ; 
dfltGradObj ='off' ; 
dfltoptions =statset ('TolX' ,dfltTolX ,...
    'Display' ,dfltDisplay ,...
    'MaxIter' ,dfltMaxIter ,...
    'GradObj' ,dfltGradObj ); 


dfltMiniBatchSize =min (10 ,N ); 
dfltMaxPasses =1 ; 
dfltLearnFcn =@(k )1 /(k +1 ); 
dfltNumPrint =10 ; 
dfltOutputFcn =[]; 
dfltUpdateFcn =[]; 


names ={'Options' ,'MiniBatchSize' ,'MaxPasses' ,'LearnFcn' ,'NumPrint' ,'OutputFcn' ,'UpdateFcn' }; 
dflts ={dfltoptions ,dfltMiniBatchSize ,dfltMaxPasses ,dfltLearnFcn ,dfltNumPrint ,dfltOutputFcn ,dfltUpdateFcn }; 
[options ,minibatchsize ,maxpasses ,learnfcn ,numprint ,outfun ,updatefun ]=internal .stats .parseArgs (names ,dflts ,varargin {:}); 



if(~isstruct (options ))
error (message ('stats:classreg:learning:fsutils:fminsgd:BadOptions' )); 
end


isok =internal .stats .isIntegerVals (minibatchsize ,1 ,N ); 
if(~isok )
error (message ('stats:classreg:learning:fsutils:fminsgd:BadMiniBatchSize' ,N )); 
end


isok =internal .stats .isIntegerVals (maxpasses ,1 ); 
if(~isok )
error (message ('stats:classreg:learning:fsutils:fminsgd:BadMaxPasses' )); 
end


isok =isa (learnfcn ,'function_handle' ); 
if(~isok )
error (message ('stats:classreg:learning:fsutils:fminsgd:BadLearnFcn' )); 
end


isok =internal .stats .isIntegerVals (numprint ,1 ); 
if(~isok )
error (message ('stats:classreg:learning:fsutils:fminsgd:BadNumPrint' )); 
end


if(~isempty (outfun ))
isok =isa (outfun ,'function_handle' ); 
if(~isok )
error (message ('stats:classreg:learning:fsutils:fminsgd:BadOutputFcn' )); 
end
end


if(~isempty (updatefun ))
isok =isa (updatefun ,'function_handle' ); 
if(~isok )
error (message ('stats:classreg:learning:fsutils:fminsgd:BadUpdateFcn' )); 
end
end




options =statset (dfltoptions ,options ); 


stepTol =options .TolX ; 
maxit =options .MaxIter ; 



if(strcmpi (options .Display ,'off' ))
verbose =false ; 
else
verbose =true ; 
end


if(strcmpi (options .GradObj ,'on' ))
haveGrad =true ; 
else
haveGrad =false ; 
end


[x ,cause ]=doSGD (fun ,x0 ,N ,minibatchsize ,maxpasses ,learnfcn ,outfun ,stepTol ,maxit ,verbose ,haveGrad ,numprint ,updatefun ); 
end


function [x ,cause ]=doSGD (fun ,x0 ,N ,minibatchsize ,maxpasses ,learnfcn ,outfun ,stepTol ,maxit ,verbose ,haveGrad ,numprint ,updatefun )






iter =0 ; 
pass =0 ; 










K =ceil (N /minibatchsize ); 


x =x0 ; 
tau =max (1 ,norm (x0 )); 







favg =0 ; 
infnormgavg =0 ; 
printiter =0 ; 
numprintcalls =0 ; 


found =false ; 














if(isempty (outfun ))
haveOutputFcn =false ; 
else
haveOutputFcn =true ; 
optimValues =struct (); 
end


ifisempty (updatefun )
haveUpdateFcn =false ; 
else
haveUpdateFcn =true ; 
end


normstep =0 ; 


while(not (found ))


obsidx =randperm (N ); 

forj =1 :K 

if(j <K )
Sj =obsidx ((j -1 )*minibatchsize +1 :j *minibatchsize ); 
else
Sj =obsidx ((K -1 )*minibatchsize +1 :N ); 
end



[fmb ,gmb ]=funAndGrad (x ,Sj ,fun ,haveGrad ); 
infnormgmb =max (abs (gmb )); 


if(haveOutputFcn )

if(iter ==0 )
state ='init' ; 
else
state ='iter' ; 
end

optimValues .iteration =iter ; 
optimValues .fval =fmb ; 
optimValues .gradient =gmb ; 
optimValues .stepsize =normstep ; 


stop =callOutputFcn (x ,optimValues ,state ,outfun ); 


if(stop )
found =true ; 
cause =4 ; 
break; 
end
end


eta =learnfcn (iter ); 


if(haveUpdateFcn )
hfcn =makeHFcnForGeneralUpdate (Sj ,fun ,haveGrad ,eta ,x ); 
xnew =updatefun (hfcn ,x ); 
step =xnew -x ; 
else
step =-eta *gmb ; 
end


normstep =norm (step ); 


x =x +step ; 



favg =favg +(fmb -favg )/(printiter +1 ); 
infnormgavg =infnormgavg +(infnormgmb -infnormgavg )/(printiter +1 ); 
printiter =printiter +1 ; 


if(rem (printiter ,numprint )==0 )
if(verbose )
displayConvergenceInfo (pass ,iter ,favg ,infnormgavg ,normstep ,eta ,numprintcalls ); 
numprintcalls =numprintcalls +1 ; 
end
printiter =0 ; 
favg =0 ; 
infnormgavg =0 ; 
end


iter =iter +1 ; 


if(normstep <=stepTol *tau )
found =true ; 
cause =1 ; 
break; 
elseif(iter >=maxit )
found =true ; 
cause =2 ; 
break; 
end
end


pass =pass +1 ; 


if(pass >=maxpasses )
found =true ; 
cause =2 ; 
end


if(haveOutputFcn &&found ==true )
state ='done' ; 

optimValues .iteration =iter ; 
optimValues .fval =fmb ; 
optimValues .gradient =gmb ; 


optimValues .stepsize =normstep ; 

callOutputFcn (x ,optimValues ,state ,outfun ); 
end


if(found ==true &&verbose ==true )
displayFinalConvergenceMessage (normstep ,tau ,stepTol ,cause ); 
end

end
end


function hfcn =makeHFcnForGeneralUpdate (Sj ,fun ,haveGrad ,etak ,xk )



















c =1 /(2 *etak ); 

hfcn =@myf ; 
function [fmb ,gmb ]=myf (x )

[fmb ,gmb ]=funAndGrad (x ,Sj ,fun ,haveGrad ); 


deltax =x -xk ; 


fmb =fmb +c *(deltax ' *deltax ); 
gmb =gmb +deltax /etak ; 
end
end


function displayFinalConvergenceMessage (normstep ,tau ,stepTol ,cause )



















fprintf ('\n' ); 
twonormsStr =['    ' ,getString (message ('stats:classreg:learning:fsutils:fminsgd:FinalConvergenceMessage_TwoNormStep' ))]; 
fprintf (['     ' ,twonormsStr ,' ' ,'%6.3e\n' ],normstep ); 
reltwonormStr =getString (message ('stats:classreg:learning:fsutils:fminsgd:FinalConvergenceMessage_RelTwoNormStep' )); 
fprintf ([reltwonormStr ,' ' ,'%6.3e, ' ,'TolX =' ,' ' ,'%6.3e\n' ],normstep /tau ,stepTol ); 


if(cause ==1 )
fprintf ([getString (message ('stats:classreg:learning:fsutils:fminsgd:Message_StepTolReached' )),'\n' ]); 
elseif(cause ==2 )
fprintf ([getString (message ('stats:classreg:learning:fsutils:fminsgd:Message_IterOrPassLimit' )),'\n' ]); 
elseif(cause ==4 )
fprintf ([getString (message ('stats:classreg:learning:fsutils:fminsgd:Message_StoppedByOutputFcn' )),'\n' ]); 
end
end

function displayConvergenceInfo (pass ,iter ,favg ,infnormgavg ,normstep ,eta ,numprintcalls )





































if(rem (numprintcalls ,20 )==0 )
fprintf ('\n' ); 
fprintf ('|==========================================================================================|\n' ); 
fprintf ('|   PASS   |     ITER     | AVG MINIBATCH | AVG MINIBATCH |   NORM STEP   |    LEARNING    |\n' ); 
fprintf ('|          |              |   FUN VALUE   |   NORM GRAD   |               |      RATE      |\n' ); 
fprintf ('|==========================================================================================|\n' ); 
end


fprintf ('|%9d |%13d |%14.6e |%14.6e |%14.6e |%15.6e |\n' ,pass ,iter ,favg ,infnormgavg ,normstep ,eta ); 
end


function stop =callOutputFcn (x ,optimValues ,state ,outfun )



















stop =outfun (x ,optimValues ,state ); 
end



function [fmb ,gmb ]=funAndGrad (x ,S ,fun ,haveGrad )










if(haveGrad )
[fmb ,gmb ]=fun (x ,S ); 
else
fmb =fun (x ,S ); 
myfun =@(z )fun (z ,S ); 
gmb =classreg .learning .fsutils .Solver .getGradient (myfun ,x ); 
end
end