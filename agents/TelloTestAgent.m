classdef TelloTestAgent < ROSAgent
    %TELLOTESTAGENT Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        
    end
    
    methods
        function agent = TelloTestAgent(id)
            %TELLOTESTAGENT Construct an instance of this class
            %   Detailed explanation goes here
            agent = agent@ROSAgent(id);
            addlistener(agent, 'ROSInitialized', @agent.init_cb);
            if agent.m_initialized
                notify(agent, 'ROSInitialized');
            end
        end
        
        function init_cb(agent, ~, ~)
            agent.run_ccw_test();
        end
        
        function data = run_ccw_test(agent)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            disp('Launching');
            agent.launch();
            pause(10);
            disp('Landing');
            agent.land();
        end
    end
end

