classdef NormalUTM < MultiLaneUTM
    %MULTILANEUTM Summary of this class goes here
    %   Detailed explanation goes here
    
    properties

    end
    
    methods
        function utm = NormalUTM()
            %MULTILANEUTM Construct an instance of this class
            utm = utm@MultiLaneUTM(@MultiLaneAction, @MultiLanePercept);
        end
        
    end
end

