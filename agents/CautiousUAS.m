classdef CautiousUAS < MultiLaneUAS
    %SLOWEDUAS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        m_desired_speed;
    end
    
    methods
        function obj = CautiousUAS(ID)
            %SLOWEDUAS Construct an instance of this class
            %   Detailed explanation goes here
            obj = obj@MultiLaneUAS(ID);
            obj.m_desired_speed = obj.m_speed;
        end
        
        function chooseAction(agent, action_handle)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            if (agent.m_num_contingent > 2)
                agent.m_speed = agent.m_desired_speed - 1 ;
            else
                agent.m_speed = agent.m_desired_speed;
            end
            agent.chooseAction@MultiLaneUAS(action_handle);
        end
    end
end

