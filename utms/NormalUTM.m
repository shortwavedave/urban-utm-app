classdef NormalUTM < MultiLaneUTM
    %MULTILANEUTM Summary of this class goes here
    %   Detailed explanation goes here
    
    properties

    end
    
    methods
        function utm = NormalUTM(action_type, percept_type)
            %MULTILANEUTM Construct an instance of this class
            if nargin == 0
                action_type = @MultiLaneAction;
                percept_type = @MultiLanePercept;
            end
            utm = utm@MultiLaneUTM(action_type, percept_type);
        end
        
    end
end

