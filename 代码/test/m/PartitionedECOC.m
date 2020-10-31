classdef PartitionedECOC < classreg.learning.internal.DisallowVectorOps

%   Copyright 2015 The MathWorks, Inc.

    properties(GetAccess=public,SetAccess=protected,Hidden=true,Abstract=true)
        Ensemble;
    end
    
    properties(GetAccess=public,SetAccess=protected,Abstract=true)
        NumObservations;
        BinaryY;
    end
    
    properties(GetAccess=public,SetAccess=protected,Dependent=true)
        %BINARYLOSS Default binary loss function for prediction.
        %   The BinaryLoss property is a string specifying the default function for
        %   computing loss incurred by each binary learner.
        %
        %   See also classreg.learning.partition.PartitionedECOC, kfoldPredict.
        BinaryLoss;
        
        %CODINGMATRIX Coding matrix.
        %   If the same coding matrix is used across all folds, the CodingMatrix
        %   property is a K-by-L matrix for K classes and L binary learners. Its
        %   elements take values -1, 0 or +1. If element (I,J) of this matrix is
        %   -1, class I is included in the negative class for binary learner J; if
        %   this element is +1, class I is included in the positive class for
        %   binary learner J; and if this element is 0, class I is not used for
        %   training binary learner J.
        %
        %   If the coding matrix varies across the folds, the CodingMatrix property
        %   is empty. In this case, use the Trained property to get the coding
        %   matrix for each fold. For example, OBJ.Trained{1}.CodingMatrix returns
        %   the coding matrix in the first fold of the cross-validated ECOC model
        %   OBJ.
        %
        %   See also classreg.learning.partition.PartitionedECOC, BinaryY.
        CodingMatrix;
    end
    
    methods
        function this = PartitionedECOC()
        end
        
        function bl = get.BinaryLoss(this)
            learners = this.Ensemble.Trained;
            T = numel(learners);
            if T==0
                bl = '';
                return;
            end
            for t=1:T
                if ~isempty(learners{t})
                    bl = learners{t}.BinaryLoss;
                    return;
                end
            end
        end
        
        function M = get.CodingMatrix(this)
            M = [];
            learners = this.Ensemble.Trained;
            T = numel(learners);
            
            if T==0
                return;
            end
            
            M1 = [];
            
            for t=1:T
                if ~isempty(learners{t})
                    M = learners{t}.CodingMatrix;
                    [~,pos] = ismember(this.Ensemble.ClassSummary.ClassNames,...
                        learners{t}.ClassSummary.ClassNames);
                    M = M(pos,:);
                    
                    if isempty(M1)
                        M1 = M;
                    else
                        if ~isequal(M1,M)
                            M = [];
                            return;
                        end
                    end
                end
            end            
        end
    end

end