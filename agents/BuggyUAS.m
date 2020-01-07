 classdef BuggyUAS < NormalUAS
    %BuggyUAS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        m_rand = [];
        m_rand_i = 0;
        m_contingency_per_sec = 1/15;
        m_contingency_per_step;
        m_preallocate_rand = 1000;
        m_desired_speed = 1;
    end
    
    methods
        function uas = BuggyUAS(ID)
            %MULTILANEUAS Construct an instance of this class
            %   Use this function to initialize any instance properties
            uas = uas@NormalUAS(ID);
            uas.m_rand = rand(1, uas.m_preallocate_rand);
            uas.m_contingency_per_step = ...
                uas.m_contingency_per_sec * uas.m_sample_per;
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
            
            if (uas.m_active)
                uas.m_rand_i = uas.m_rand_i + 1;
                if (uas.m_rand_i > uas.m_preallocate_rand)
                    uas.m_rand_i = 1;
                    uas.m_rand = rand(1,uas.m_preallocate_rand);
                end

                if (uas.m_rand(uas.m_rand_i) < uas.m_contingency_per_step)
                    uas.setSpeed(0);
                else
                    uas.setSpeed(uas.m_desired_speed);
                end
            end
            
            uas.chooseAction@NormalUAS(action_handle);
        end
        
        function acceptPercept(agent, percept_handle)
            agent.acceptPercept@NormalUAS(percept_handle);
            
            % Add code here to store percepts
        end
    end
end

