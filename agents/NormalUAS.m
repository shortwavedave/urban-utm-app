classdef NormalUAS < MultiLaneUAS
    %NormalUAS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties

    end
    
    methods
        function agent = NormalUAS(ID)
            %MULTILANEUAS Construct an instance of this class
            %   Use this function to initialize any instance properties
            agent = agent@MultiLaneUAS(ID);
        end
        
        
        function chooseAction(agent, action_handle)
            % Add code here to choose an action
            
            agent.chooseAction@MultiLaneUAS(action_handle);
        end
        
        function acceptPercept(agent, percept_handle)
            agent.acceptPercept@MultiLaneUAS(percept_handle);
            
            % Add code here to store percepts
        end
    end
end

