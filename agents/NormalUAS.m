classdef NormalUAS < MultiLaneUAS
    %NormalUAS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties

    end
    
    methods
        function uas = NormalUAS(ID)
            %MULTILANEUAS Construct an instance of this class
            %   Use this function to initialize any instance properties
            uas = uas@MultiLaneUAS(ID);
        end
        
        
        function chooseAction(uas, action_handle)
            % Add code here to choose an action
            will_be_active = uas.getWillBeActive();
            
            if will_be_active
                land_nodes = uas.getLandNodes();
                launch = uas.m_lane_path.getStartNode();
                land = land_nodes(randi(length(land_nodes)));
                lane_path = uas.getShortestPath(launch, land{:});
                
                uas.m_lane_path = lane_path;
            end
            
            uas.chooseAction@MultiLaneUAS(action_handle);
        end
        
        function acceptPercept(uas, percept_handle)
            uas.acceptPercept@MultiLaneUAS(percept_handle);
            
            % Add code here to store percepts
        end
    end
end

