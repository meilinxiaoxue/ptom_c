function [varargout ]=fitToFullDataset (XTable ,BOInfo ,FitFunctionArgs ,Predictors ,Response )



NewFitFunctionArgs =updateArgsFromTable (BOInfo ,FitFunctionArgs ,XTable ); 
[varargout {1 :nargout }]=BOInfo .FitFcn (Predictors ,Response ,NewFitFunctionArgs {:}); 
end
