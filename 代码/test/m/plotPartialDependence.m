function [AX] = plotPartialDependence(model,features,data,varargin)
%PLOTPARTIALDEPENDENCE Partial Dependence Plot for 1-D or 2-D visualization
%   plotPartialDependence(MODEL,VAR,DATA) takes a fitted regression model
%   MODEL and a predictor variable name VAR, and creates a plot showing
%   the partial dependence of the response variable on the predictor
%   variable. The dependence is computed by averaging over the data used in
%   fitting the model. VAR can be a scalar containing the index of the
%   predictor, a string scalar or a char array with the predictor variable
%   name. DATA is a matrix or table of data to be used in place of the data
%   used in fitting the model.
%   
%   plotPartialDependence(MODEL,VARS,DATA) takes VARS as either a cell
%   array containing two predictor variable names, a string array
%   containing two predictor variable names or a two-element vector
%   containing the indices of two predictors, and creates a surface plot
%   showing the partial dependence of the response on the two predictors.
%   DATA is a matrix or table of data to be used in place of the data used
%   in fitting the model.
%
%   AX = plotPartialDependence(...) returns a handle AX to the axes of the
%   plot.
%
%   PLOTPARTIALDEPENDENCE(..., 'PARAM1', val1, 'PARAM2', val2, ...)
%   specifies optional parameter name/value pairs.
%
%      'Conditional'                'none' (default) to specify a
%                                   partial dependence plot (no conditioning),
%                                   'absolute' to specify an ICE individual
%                                   conditional expectation plot, or 'centered'
%                                   to or an ICE plot with centered data.
%
%      'NumObservationsToSample'    an integer K specifying the number
%                                   of rows to sample at random from the dataset
%                                   (either the DATA input or the training data
%                                   from the MODEL). Default is to use all rows.
%
%      'QueryPoints'                The points XI at which to calculate
%                                   the partial dependence. When the second
%                                   input VAR is a single predictor, XI is a
%                                   column vector of values for that predictor.
%                                   When the second inputs VARS is two
%                                   predictors, XI is a 1x2 cell array
%                                   containing a separate vector for each
%                                   predictor. Default is 100 values equally
%                                   spaced across the range of the predictor.
%
%      'UseParallel'                true to specify that the averaging
%                                   calculations are to be done in parallel
%                                   (using parfor), or false (default) to
%                                   specify that they should not.
%
%      'ParentAxisHandle'           plots Partial Dependence into the
%                                   axes with handle specified by the
%                                   corresponding value ax.
%
%   Examples:
%      % Partial Dependence Plot of Regression Tree
%      load carsmall
%      tbl = table(Weight,Cylinders,Origin,MPG);
%      f = fitrtree(tbl,'MPG');
%
%      plotPartialDependence(f,'Weight');
%      plotPartialDependence(f,{'Weight','Origin'});
%      plotPartialDependence(f,[1,3]);
%
%      % Obtain optional output Axes handle
%      ax = plotPartialDependence(f,1);
%
%      % With additional Data
%      load carbig
%      tbl2 = table(Weight,Cylinders,Origin);
%      plotPartialDependence(f,'Weight',tbl2);
%      plotPartialDependence(f,1,tbl2);
%
%      % With optional name-value pairs
%      plotPartialDependence(f,1,tbl2,'NumObservationsToSample',100);
%      plotPartialDependence(f,1,tbl2,'UseParallel',true);
%      plotPartialDependence(f,1,tbl2,'UseParallel',true,'Conditional','none');
%      
%      % Plot the Individual Conditional Expectation
%      plotPartialDependence(f,1,tbl2,'Conditional','absolute');
%
%      % Provide alternative query points
%      xi = linspace(min(Weight),max(Weight))';
%      plotPartialDependence(f,1,'QueryPoints',xi);
%      
%      xi = cell(1,2);
%      xi{1} = linspace(min(Weight),max(Weight))';
%      xi{2} = linspace(min(Cylinders),max(Cylinders))';
%      plotPartialDependence(f,[1,2],'QueryPoints',xi);

%   Copyright 2017 The MathWorks, Inc.

%-------Check number of inputs----
narginchk(3,13);
features = convertStringsToChars(features);
[varargin{:}] = convertStringsToChars(varargin{:}); 

%------------Check Data----------------
validateattributes(data,{'single','double','table'},...
    {'nonempty','nonsparse','real'},mfilename,'Data');

% Validate non-sparse and real for tables
if(istable(data))
    v = varfun(@(x) isnumeric(x) & (issparse(x) || ~isreal(x)) ,data);
    if(any(v.Variables))
        error(message('stats:classreg:regr:plotPartialDependence:DataRealNonSparse'));
    end
end

% Remove response variable if table
if(istable(data))
    [~,numNames] = intersect(model.PredictorNames,...
        data.Properties.VariableNames,'stable');
    if(length(numNames) ~= length(model.PredictorNames))
        error(message('stats:classreg:regr:plotPartialDependence:FeatsNameMismatch'))
    end
    data = data(:,model.PredictorNames);
end

% For Linear Models data and PredictorNames might be of different sizes
if(isa(model,'classreg.regr.CompactPredictor') && ~istable(data) &&...
         length(model.PredictorNames) ~= (length(model.VariableNames)-1))
    dataInd = ismember(model.VariableNames,model.PredictorNames);
    data = data(:,dataInd);
end

% Columns of input data must be equal to number of predictors
if(size(data,2) ~= length(model.PredictorNames))
    error(message('stats:classreg:regr:plotPartialDependence:DataNumCols'))
end

%--------------Parse Features---------------------
validateattributes(features,{'numeric','string','char','cell'},...
    {'nonempty'},mfilename,'Variable Name');

% Length of features can be either 1 or 2
if(iscell(features) || isfloat(features) || isstring(features))
    if(length(features)~= 1 && length(features)~= 2)
        error(message('stats:classreg:regr:plotPartialDependence:NumFeatures'))
    end
end

% Features can be cell arrays, char vectors or doubles, parse accordingly
if(iscellstr(features))
    [~,~,indFeats] = intersect(features,model.PredictorNames,'stable');
    if(length(indFeats) ~= length(features))
        error(message('stats:classreg:regr:plotPartialDependence:FeatsNameMismatch'))
    end
elseif(ischar(features) || isstring(features))
    if(ischar(features) && size(features,1) > 1)
        error(message('stats:classreg:regr:plotPartialDependence:FeaturesType'))
    end
    [~,~,indFeats] = intersect(features,model.PredictorNames,'stable');
    if(isempty(indFeats) || (size(features,1)==2 && length(indFeats)~=2))
        error(message('stats:classreg:regr:plotPartialDependence:FeatsNameMismatch'))
    end
elseif(isfloat(features))
    if(~all(ismember(features,1:size(data,2))))
        error(message('stats:classreg:regr:plotPartialDependence:SizeFeats',size(data,2)))
    end
    indFeats = features;
    features = model.PredictorNames(indFeats);
else
    error(message('stats:classreg:regr:plotPartialDependence:FeaturesType'))
end

if(isa(model,'classreg.regr.CompactPredictor') && ~istable(data) &&...
         length(model.PredictorNames) ~= (length(model.VariableNames)-1))
    Data = zeros(size(data,1),length(model.VariableNames)-1);
    Data(:,dataInd) = data;
    data = Data;
    D = find(dataInd);
    indFeats = D(indFeats);
end

%-------- Parse Name-Value pairs--------------
[useParallel, conditional, numObsToSample, xi, ax] = internal.stats.parseArgs(...
    {'UseParallel','Conditional','NumObservationsToSample','QueryPoints',...
    'ParentAxisHandle'},{false,'none',0,[],[]},varargin{:});

%------------Check Name-Value Pairs----------------
validateattributes(useParallel,{'logical'},{'nonempty','scalar'},...
    mfilename,'UseParallel');
validateattributes(conditional,{'char','string'},...
    {'scalartext','nonempty'},mfilename,'Conditional');
validateattributes(numObsToSample,{'numeric'},{'nonempty'},...
    mfilename,'NumObservationsToSample');
validateattributes(xi,{'double','single','cell'},...
    {'nonsparse','real'},mfilename,'QueryPoints');


% ------------NumObservationsToSample -------------------
% If NumObservationsToSample == 0 or > size(data,1), do nothing
if (numObsToSample <0 || ~(isnumeric(numObsToSample)))
    error(message('stats:classreg:regr:plotPartialDependence:SizeObsSample',size(data,1)))
elseif(numObsToSample > 0 && numObsToSample <= size(data,1))
    data = datasample(data,numObsToSample,'Replace',false);
end

%---------Check for Categorical Variables-----------
% Linear/NonLinear Models do not have model.CategoricalPredictors field
% CompactTreeBagger has CategoricalPredictors stored in its learners
if(isa(model,'classreg.regr.CompactPredictor'))
    catPredictors = model.VariableInfo.IsCategorical;   
    if(istable(data))
        [~,indPreds] = intersect(model.VariableNames,model.PredictorNames);
        catPredictors = find(catPredictors(indPreds));
    else
        catPredictors = find(catPredictors);
    end
elseif(isa(model,'CompactTreeBagger'))
    catPredictors = model.Trees{1}.CategoricalPredictors;
    varRange = model.Trees{1}.VariableRange;
else
    catPredictors = model.CategoricalPredictors;
    varRange = model.VariableRange;
end

% ---------Parse QueryPoints - xi-------------------
% When the user does not provide query points
% Query points can only be floating point numbers
if(isempty(xi))
    [x,y] = parseQueryPoints(data,indFeats,catPredictors);
else % User supplied query points
    y = [];
    [~,n] = size(xi);
    
    % Compare columns of query points and features
    if(n ~= length(indFeats))
        error(message('stats:classreg:regr:plotPartialDependence:SizeQueryFeats'))
    end
    
    % Split user supplied query points into x and y to conform with above syntax
    if(isfloat(xi))
        x = xi(:,1);
        if(n == 2)
            y = xi(:,2);
        end
    elseif(iscell(xi))
        x = xi{1};
        if(n == 2)
            y = xi{2};
        end
        
        % Cell contents must be numeric
        if (~isfloat(x) || ~isfloat(y))
            error(message('stats:classreg:regr:plotPartialDependence:QueryDataType'))
        end
    else
        error(message('stats:classreg:regr:plotPartialDependence:QueryDataType'))
    end
    
    % Obtain query points from training data, if user does not provide query
    % points for one variable, overwrite it with default query points
    [X,Y] = parseQueryPoints(data,indFeats,catPredictors);

    % Populate empty query points or overwrite if input points are categorical 
    if(isempty(x) || ismember(indFeats(1),catPredictors) || ~isfloat(x))
        x = X;
    end     
    if(isempty(y) || (length(indFeats)==2 && ismember(indFeats(2),...
            catPredictors)) || ~isfloat(y))
        y = Y;
    end
    
    % Remove NaNs
    if(isfloat(x) && any(isnan(x)))
        x(isnan(x)) = [];
    end
    if(~isempty(y) && isfloat(y) && any(isnan(y)))
        y(isnan(y)) = [];
    end
    
    % Convert query points to table if data is tabular for convenience of
    % tabular assignment in PD computation functions
    if(istable(data))
        if(isfloat(x))
            x = table(x);
            x.Properties.VariableNames =...
                data.Properties.VariableNames(indFeats(1));
        end
        if(~isempty(y) && isfloat(y))
           y = table(y);
           y.Properties.VariableNames =...
                data.Properties.VariableNames(indFeats(2));
        end 
    end
end

% Obtain sorted unique query points, linspace would duplicate 100 points if 
% one enters the same number as min and max.
x = unique(x);
if~isempty(y)
    y = unique(y);
end

% If parent is not provided call newplot to get current axes or make a new one 
if(isempty(ax))
    ax = newplot;
end

% 'Parent' must be an Axes object 
if(~isa(ax,'matlab.graphics.axis.Axes'))
    error(message('stats:classreg:regr:plotPartialDependence:ParentAxes',class(ax)))
end

% Obtain ResponseName for plotting
if(isa(model,'CompactTreeBagger'))
    respName = model.Trees{1}.ResponseName;
else
    respName = model.ResponseName;
end
% ----------Compute Individual Conditional Expectation---------
if strcmp(conditional,'absolute') || strcmp(conditional,'centered')
    % ICE can only be computed for one feature in one call
    if(length(indFeats) ~= 1)
        error(message('stats:classreg:regr:plotPartialDependence:CondFeats'))
    end
    
    % Call to computation routine ice
    [pv,xp,sc] = ice(model,data,indFeats,useParallel,conditional,x);
    
    % Plot ICE results
    [ax] = plotICE(ax,pv,xp,sc,features,respName);
    
% ----------Compute Partial Dependence---------    
elseif strcmp(conditional,'none')% Call the partial dependence functions
    
    % Call special tree algorithm if model is a tree 
     if(isa(model,'classreg.learning.regr.CompactRegressionTree'))
        
         parDep = pdpTree(model,indFeats,useParallel,x,y,catPredictors,varRange);
     
     % Call Wrapper for Ensembles of Trees
     elseif((isa(model,'classreg.learning.regr.CompactRegressionEnsemble')...
             && ismember(model.LearnerNames,'Tree')) ||...
             isa(model,'CompactTreeBagger'))
         
         parDep = pdpEnsemble(model,indFeats,useParallel,x,y,catPredictors,...
             varRange);
     
     else % Otherwise call algorithm which uses the predict method
         % This includes Ensembles of non-tree weak learners
         parDep = pdp(model,data,indFeats,useParallel,x,y);
    end
    
    % Plot PD results
    ax = plotPD(ax,parDep,x,y,features,respName);
else
    error(message('stats:classreg:regr:plotPartialDependence:CondOptions'))
end

% Populate the function output arguments(if requested)
if(nargout > 0)
    AX = ax;
end
end

%--------------Parsing subfunctions-------------
function [x,y] = parseQueryPoints(data,indFeats,cat)
y = [];
% If data is a float, obtain min and max values and call linspace.
% For categorical xi, obtain unique xi values
if(istable(data) || any(cat))
    x = obtainQueryPts(data(:,indFeats(1)),ismember(indFeats(1),cat));    
    if(length(indFeats) == 2)
        y = obtainQueryPts(data(:,indFeats(2)),ismember(indFeats(2),cat));
    end
else %Data is matrix of doubles and neither of the features is categorical
    maxD = max(data(:,indFeats));
    minD = min(data(:,indFeats));
    x = linspace(minD(1),maxD(1))';
    if(length(indFeats) == 2)
        y = linspace(minD(end),maxD(end))';
    end
end
end

function [v] = obtainQueryPts(data,cat)
% Index into table to avoid indexing multiple times afterwards
if(istable(data))
    D = data.(data.Properties.VariableNames{1});
else
    D = data;
end

% For numeric data type (not including numeric data specified as categorical 
% predictor) create 100 linspace points. For non-numeric/categorical data obtain
% unique values
if((isfloat(data) || (istable(data) && isfloat(data{1,1}))) && ~(cat)) 
    maxD = max(D);
    minD = min(D);
    v = (linspace(minD,maxD))';
    
    % Convert back to table if originally a table
    if(istable(data))
        v = table(v);
        v.Properties.VariableNames = data.Properties.VariableNames;
    end
else % Obtain unique values for non-numeric or categorical variables
    % unique does not combine <missing> values. Keep just 1 <missing> value
    v = unique(data);
    isMiss = ismissing(v);
    if(any(isMiss))
        indMiss = find(isMiss);
        v = [v(~isMiss,1);v(indMiss(1),1)];
    end
end
end

%----------- Partial Dependence Computation function----------
function [parDep] = pdp(model,data,ij,par,x,y)
% 1-D PD
if(length(ij) == 1) 
    % Pre-allocate output array
    parDep = zeros(size(x));
    
    if(par)% UseParallel
        parfor idy = 1:size(x,1)
            X = data; % This assignment is necessary for parfor loops
            X(:,ij) = x(idy,1);
            parDep(idy) = mean(predict(model,X),1,'omitnan');
        end
    else
        % Compute PD serially
        for idy = 1:size(x,1)
            data(:,ij) = x(idy,1);
            parDep(idy) = mean(predict(model,data),1,'omitnan');
        end
    end
elseif(length(ij) == 2) % 2-D PD   
    % Pre-allocate output array
    parDep = zeros(size(y,1),size(x,1));
    
    % Obtain sizes for loops
    N = size(x,1);
    M = size(y,1);
    
    % Index into features here for faster parfor computation
    ij1 = ij(1); 
    ij2 = ij(2);
        
    if(par)        
        parfor idx = 1:N
            uni1 = x(idx,1);
            for idy = 1:M
                X = data; % Needs to be done for parfor
                % 1st predictor variable
                X(:,ij1)   = uni1;
                % 2nd predictor variable
                X(:,ij2) = y(idy,1); %#ok<PFBNS>
                parDep(idy,idx) = mean(predict(model,X),1,'omitnan');
            end
        end
    else
        for idx = 1:N
            % 1st predictor variable
            data(:,ij1) = x(idx,1);
            for idy = 1:M
                % 2nd predictor variable
                data(:,ij2) = y(idy,1);
                parDep(idy,idx) = mean(predict(model,data),1,'omitnan');
            end
        end
    end
end
end

%----------Special-Tree Partial Dependence----------------
function [parDep] = pdpTree(tree,ij,par,x,y,cat,vrange)
% Obtain names of chosen variable(s)
zl = tree.PredictorNames(ij);

% Compute logical arrays to pass to mex file instead of passing cell arrays
% Check which nodes have predictor(s)in the target set and for categorical
[IsChosenPredictor,whichPredictor] = ismember(tree.CutPredictor,zl);
IsCategoricalCut = strcmp(tree.CutType,'categorical');

% Obtain tree fields to reduce computation time in repeatedly accessing    
% fields in sub-functions, i.e. avoid sending entire tree to subfunctions
IsBranchNode = tree.IsBranchNode;
CutPoint = tree.CutPoint;
Children = (tree.Children)-1; % Reduce indices by 1 MATLAB -> C
NodeMean = tree.NodeMean;
NodeSize = tree.NodeSize;
CutCategories = tree.CutCategories(:,1);
IsCatAndChosen = IsChosenPredictor & IsCategoricalCut;
IsCatLeft = false(size(IsCatAndChosen)); 

% Convert non-numeric or categorical to numeric
dataX = getVariableRange(x,ismember(ij(1),cat),ij(1),vrange);

if(length(ij) == 1)
    % Obtain size
    N = size(dataX,1);
    
    % Initialize Partial Dependence matrix
    parDep = zeros(N,1); 
    
    % Iterate over values of parameter in target set
    if(par)
        parfor xIdx = 1:N              
             parDep(xIdx) = getPartialDependence(dataX(xIdx),IsChosenPredictor,...
                 whichPredictor,IsCategoricalCut,IsBranchNode,CutPoint,...
                 Children,NodeMean,NodeSize,CutCategories,IsCatAndChosen,IsCatLeft);
        end
    else        
        for xIdx = 1:N
            % Traverse nodes and assign weights
            parDep(xIdx) = getPartialDependence(dataX(xIdx),IsChosenPredictor,...
                whichPredictor,IsCategoricalCut,IsBranchNode,CutPoint,...
                Children,NodeMean,NodeSize,CutCategories,IsCatAndChosen,IsCatLeft);
        end
    end
elseif(length(ij) == 2)
    % Check for Query Points (y), x have been computed above
    dataY = getVariableRange(y,ismember(ij(2),cat),ij(2),vrange);
    
    % Initialize PD matrix
    parDep = zeros(size(dataY,1),size(dataX,1));
    
    % Iterate to find partial dependence
    N = size(dataX,1);
    M = size(dataY,1);
    
    if(par)
        parfor k = 1:N
            K = dataX(k);
            J = dataY; % need this to speed parfor up
            for j = 1:M
                % Traverse nodes, assign weights and get PD
                parDep(j,k) = getPartialDependence([K,J(j)],IsChosenPredictor,...
                    whichPredictor,IsCategoricalCut,IsBranchNode,...
                    CutPoint,Children,NodeMean,NodeSize,CutCategories,...
                    IsCatAndChosen,IsCatLeft);
            end
        end
    else
        J = dataY;
        for k = 1:N
            K = dataX(k);
            for j = 1:M
                % Traverse nodes, assign weights and get PD
                parDep(j,k) = getPartialDependence([K,J(j)],IsChosenPredictor,...
                    whichPredictor,IsCategoricalCut,IsBranchNode,...
                    CutPoint,Children,NodeMean,NodeSize,CutCategories,...
                    IsCatAndChosen,IsCatLeft);
            end
        end
    end
end
end

%--------Special-Tree Sub-functions---------
function [data] = getVariableRange(v, cat, ij, vrange)
% v can be either a table(with doubles) or a doubles matrix
data = v;

% Index into table column
if(istable(v))
    if (isfloat(v{1,1}) || islogical(v{1,1}) || iscategorical(v{1,1}))
        data = v.(v.Properties.VariableNames{1});
    else
        data = table2cell(v);
        if(iscellstr(data))
            % Need to do this as Variable Range contains trimmed strings
            data = strtrim(data);
        end
    end
end
% If this feature is a categorical obtain indices from training data 
% Convert non-numeric/categorical to numeric for comparison with CutCategories
% which has numeric indices
if(cat)
    % Compare data against variable range
    [~,data] = ismember(data,vrange{ij});
    
    % If unknown category, set data value to NaN
    % This is handled in getParDep()
    data(data==0) = nan;
end
end

function [pdVal] = getPartialDependence(chosenObs,IsChosenPredictor,...
    whichPredictor,IsCategoricalCut,IsBranchNode,CutPoint,Children,...
    NodeMean,NodeSize,CutCategories,CatIdx,IsCatLeft)
% If categorical, identify the child node to traverse (Left or Right)
if any(CatIdx)
    % Find Categorical Nodes
    cIdx = find(CatIdx);
    
    % Traverse all categorical nodes
    for idx = 1:size(cIdx)
        IsCatLeft(cIdx(idx)) = ismember(...
            chosenObs(whichPredictor(cIdx(idx))),CutCategories{cIdx(idx)});
    end
end

% Call the Partial Dependence computation function
pdVal = classreg.regr.modelutils.getParDep(chosenObs,IsChosenPredictor,...
    whichPredictor,IsBranchNode,Children(:,1),Children(:,2),CutPoint,...
    NodeSize,IsCatLeft,IsCategoricalCut,NodeMean);
end

%----------Ensemble of Trees - Wrapper Function---------------
function [parDep] =  pdpEnsemble(model,features,useParallel,x,y,cat,vrange)
% Wrapper function for Partial Dependence Plot algorithm with input 
% model as an Ensemble of Trees

% Obtain CompactTrees from Ensembles
if(isa(model,'CompactTreeBagger'))
    nTrees = model.NumTrees;
    learners = model.Trees;
else
    nTrees = model.NumTrained;
    learners = model.Trained;
end

% Initialize
parDep = pdpTree(learners{1},features,useParallel,x,y,cat,vrange);

if(useParallel)
    parfor idx = 2:nTrees
        % Call pdpTree function
        p = pdpTree(learners{idx},features,useParallel,x,y,cat,vrange);
        % Sum over all trees
        parDep = parDep + p;
    end
else
    for idx = 2:nTrees
        % Call pdpTree function
        p = pdpTree(learners{idx},features,useParallel,x,y,cat,vrange);
        % Sum over all trees
        parDep = parDep + p;
    end
end
% Average over all trees
parDep = parDep/nTrees;
end

%--------ICE Function-----------------------------
function [plotPts,xp,scatPts] = ice(model,data,features,par,conditional,x)
[m,~] = size(data);

% Initialize
plotPts = zeros(size(x,1)+1,m);
scatPts = zeros(1,m);
ij = features;

% Index into numeric data and convert non-numeric data to numeric for scatter
% points to be plotted
if(istable(data)&&(isfloat(data{:,ij})))
    xp_sc = data{:,ij};
elseif(isfloat(data(:,ij)))
    xp_sc = data(:,ij);
else % Non-numeric -> obtain indices of variables
    % Obtain numeric indices of data with respect to query points(x)
    % These will be the abscissa values for scatter points
    [~,xp_sc] = ismember(data(:,ij),x,'rows');
    plotPts = zeros(size(x,1),m);
end

% Get column of data
D = data(:,ij);
if(par)
    parfor idx = 1 : m
        % Call ICE subfunction to compute predictions
        [plotPts(:,idx),scatPts(idx)] = getIndCondExp(x,D(idx,1),...
            data(idx,:),model,ij);
    end    
else
    for idx = 1 : m
        % Call ICE subfunction to compute predictions
        [plotPts(:,idx),scatPts(idx)] = getIndCondExp(x,D(idx,1),...
            data(idx,:),model,ij);
    end
end

% Populate output struct for abscissa values
xp.plotPts = x;
xp.scatPts = xp_sc;

% Obtain the Centered ICE plot by removing level effects
% Paper mentions that best results may be obtained by subtracting the 
% minimum or maximum value (using min here)
if(strcmp(conditional,'centered'))
    scatPts = scatPts - plotPts(1,:);
    plotPts = plotPts - plotPts(1,:);
end
end

%------------------ICE Subfunction------------------
function [pv,sc] = getIndCondExp(x,D,data,model,ij)
% Include(concatenate) scatter point in call to predict
if(isfloat(x) || (istable(x) && isfloat(x{1,1})))
    [x,scIdx] = sortrows([x;D]);
    scIdx = find(scIdx == max(scIdx));
else
    [~,scIdx] = ismember(D,x);
end
% Re-order the data matrix 
X = repmat(data,size(x,1),1);
X(:,ij) = x;

% Call the predict method
pv = predict(model,X);
sc = pv(scIdx);
end

%------------Plot functions-------------
function [ax] = plotPD(ax,parDep,x,y,features,response)
if(isempty(y)) % Plot 1-D
    % Calling plot separately to prevent XTickLabels overwrite
    % Convert inputs to double
    if(istable(x) && isfloat(x{1,1}))
        varX = table2array(x);
        % Call Plot
        plot(ax,varX,parDep);
    elseif(istable(x)) % Non-numeric data 
        xVals = 1:size(x,1);
        % Call Plot
        plot(ax,xVals,parDep,'o:','MarkerFaceColor','b');
        ax.XTick = xVals;
        ax.XTickLabels = missingToString(x);
    else
        % Numeric data matrix
        plot(ax,x,parDep);
    end
     
    % Update axes fields
    ax.XLabel.String = features;
    ax.YLabel.String = response;
    ax.Title.String = 'Partial Dependence Plot';
else % Plot 2-D
    % Obtain sizes
    [s1,s2] = size(parDep);
    
    % Convert X variable to double so that we can plot it
    % Use repmat to create a grid
    if(istable(x) && isfloat(x{1,1}))
        varX = table2array(x);
        varX = repmat(varX',s1,1);
    elseif(istable(x))
        xVals = 1:s2;
        varX = repmat(xVals,s1,1);
    elseif(isfloat(x))
        varX = repmat(x',s1,1);
    end

   % Convert Y variable to double, use repmat to create a grid
   if(istable(y) && isfloat(y{1,1}))
        varY = table2array(y);
        varY = repmat(varY,1,s2);
   elseif(istable(y))
        yVals = (1:s1)';          
        varY = repmat(yVals,1,s2);
   elseif(isfloat(y))
        varY = repmat(y,1,s2);
   end
   
   % Call surf or plot3(when plotting scalars or 1-D vectors)
   if(min(size(varX))==1 || min(size(varY))==1)
       plot3(ax,varX,varY,parDep);
   else
       surf(ax,varX,varY,parDep);
   end
   
   % Update axes fields
   ax.XLabel.String = features(1);
   ax.YLabel.String = features(2);
   ax.ZLabel.String = response;
   ax.Title.String = 'Partial Dependence Plot';
   
   % Update X and Y Tick info, this needs to be done afterwards as plot
   % overwrites these values/labels
   if(istable(x) && ~isfloat(x{1,1}))
       ax.XTick = xVals;
       ax.XTickLabels = missingToString(x); 
   end
   if(istable(y) && ~isfloat(y{1,1}))
       ax.YTick = yVals;
       ax.YTickLabels = missingToString(y);
   end
end
end

function vStr = missingToString(vTab)
% Change <missing> to "missing"
idx = ismissing(vTab);
vStr = table2cell(vTab);
if(any(idx))
    vStr{idx} = "missing";
end
vStr = string(vStr);
end

function [ax] = plotICE(ax,plotPts,xp,scatPts,features,response)
% Obtain abscissa values for line and scatter plots
p = xp.plotPts;
s = xp.scatPts;

% Convert inputs to double in order to plot them
% Calling plot separately to prevent XTickLabels overwrite
if(isfloat(p) || (istable(p) && isfloat(p{1,1})))
    if(istable(p))
        p = table2array(p);
    end
    p = repmat(p,1,size(plotPts,2));
    p = sort([p;s'],1);
    
    % Call plot on ICE data
    plot(ax,p,plotPts,'LineWidth',0.5,'Color',[0.5,0.5,0.5]);
elseif(istable(p)) % Non-numeric Data
    xVals = 1:size(p,1);
    % Call plot on ICE data
    plot(ax,xVals',plotPts,'LineWidth',0.5,'Color',[0.5,0.5,0.5]);
    
    % Update TickLabels which will otherwise be overwritten by plot
    ax.XTick = xVals;
    ax.XTickLabels = string(table2cell(p));
    p = xVals';    
end

boolHold = ishold(ax);
% Call scatter on ICE data
hold(ax,'on');
scatter(ax,s,scatPts,'MarkerFaceColor',[0 0 0]);

% Call plot for Partial Dependence (mean of ICE plots)
plot(ax,mean(p,2,'omitnan'),mean(plotPts,2,'omitnan'),'LineWidth',3,...
    'Color',[1,0,0]);
if(~boolHold)
    hold(ax,'off');
end

% Populate axes labels
ax.XLabel.String = features;
ax.YLabel.String = response;
ax.Title.String = 'Individual Conditional Expectation Plot';
end