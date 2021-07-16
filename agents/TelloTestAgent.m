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
            agent.enableVideo();
            pause(3);
            disp('Launching');
            agent.launch();
            pause(3);
            agent.set_rc_ctrl(0,0,25,25);
            checker_detected = false;
            max_time = 5;
            curr_time = 0;
            conf = 0;
            while (~checker_detected) && (curr_time < max_time)
                [im_pts, board_size, world_pts] = ...
                    ROSAgent.detectCheckerboard(agent.m_curr_view);
                if (~isempty(im_pts))
                    conf = conf + .1;
                    disp(['checkerboard found: ' num2str(conf)]);
                    %checker_detected = true;
                    %imshow(agent.m_curr_view);
                end
                %else
                    pause(0.1);
                    curr_time = curr_time + 0.1;
                %end
            end
            agent.set_rc_ctrl(0,0,0,0);
            pause(1);
            disp('Landing');
            agent.land();
        end
    end
    
    methods (Access = private)
        
    end
end

