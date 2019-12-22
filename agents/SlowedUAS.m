classdef SlowedUAS < MultiLaneUAS
    %SLOWEDUAS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        m_desired_speed;
        m_contingency_i = 1;
        m_contingency_is = [];
    end
    
    methods
        function agent = SlowedUAS(ID)
            %SLOWEDUAS Construct an instance of this class
            %   Detailed explanation goes here
            agent = agent@MultiLaneUAS(ID);
            agent.m_desired_speed = agent.m_speed;
        end
        
        function precalculateContingencies(agent, steps)
            agent.m_contingency_is = rand(1,steps);
        end
        
        function chooseAction(agent, action_handle)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            if (agent.m_contingency_i > length(agent.m_contingency_is))
                c_p = rand();
            else
                c_p = agent.m_contingency_is(agent.m_contingency_i);
            end
            if (c_p > 0.95)
                agent.m_speed = 0;
                agent.m_forced_contingency = agent.m_active; 
            else
                agent.m_speed = agent.m_desired_speed;
                agent.m_forced_contingency = false;
            end
            agent.chooseAction@MultiLaneUAS(action_handle);
            agent.m_contingency_i = agent.m_contingency_i + 1;
        end
    end
end

