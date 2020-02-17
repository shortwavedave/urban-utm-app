classdef TelloTestAgent < TelloRCAgent
    %TELLOTESTAGENT Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        
    end
    
    methods
        function agent = TelloTestAgent(id)
            %TELLOTESTAGENT Construct an instance of this class
            %   Detailed explanation goes here
            agent = agent@TelloRCAgent(id);
            addlistener(agent, 'ROSInitialized', @agent.init_cb);
            if agent.m_initialized
                notify(agent, 'ROSInitialized');
            end
        end
        
        function init_cb(agent, ~, ~)
            %agent.run_ccw_test();
        end
        
        function data = run_ccw_test(agent)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            disp('Launching');
            agent.launch();
            pause(5);
            agent.setControl([0 0 0 20]);
            conf = 0;
            for i = 1:50
                [im_pts, ~, ~] = ...
                    agent.detectCheckerboard(agent.m_curr_view);
                if (isempty(im_pts))
                    if conf > 0
                        conf = conf - 1;
                    else
                        conf = 0;
                    end
                else
                    conf = conf + 1;
                end
                if (conf > 10)
                    disp('Found checkerboard');
                end
                pause(0.1);
            end
            agent.setControl([0 0 0 0]);
            disp('Landing');
            agent.land();
        end
    end
end

