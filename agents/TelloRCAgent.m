classdef TelloRCAgent < ROSAgent
    %TELLORCAGENT Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        m_update_per = 1 % seconds
        m_cmd_queue = [0 0 0 0]; % left/right, front/back, up/down, yaw
        m_null_cmd = [0 0 0 0];
    end
    
    properties (SetAccess = private)
        m_ctrl_timer; % the timer that runs the control queue
%         m_pressed_key = '0';
        m_ctrl_en = true;
    end
    
    methods
        function agent = TelloRCAgent(id)
            %TELLORCAGENT Construct an instance of this class
            %   Detailed explanation goes here
            agent = agent@ROSAgent(id);
            addlistener(agent, 'ROSInitialized', @agent.init_cb);
            if agent.m_initialized
                notify(agent, 'ROSInitialized');
            end
        end
        
        function init_cb(agent, ~, ~)
            agent.m_ctrl_timer = timer('TimerFcn', ...
                @(x,y)agent.run_ctrl_q, ...
                'StartDelay', 0, ...
                'Period', agent.m_update_per, ...
                'TasksToExecute', inf, ...
                'ExecutionMode', 'fixedRate');
            agent.m_ctrl_timer.start();
        end
        
        function setCommand(agent, cmd)
            %[left/right, front/back, up/down, yaw];
            agent.m_cmd_queue = cmd;
        end
        
        function setCmdFromKeys(agent, key)
            switch key
                case '0'
                    agent.setCommand(agent, [0 0 0 0])
                case 'uparrow'
                    agent.setCommand(agent.m_cmd_queue + [0 10 0 0])
                case 'downarrow'
                    agent.setCommand(agent.m_cmd_queue + [0 -10 0 0])
                case 'leftarrow'
                    agent.setCommand(agent.m_cmd_queue + [-10 0 0 0])
                case 'rightarrow'
                    agent.setCommand(agent.m_cmd_queue + [10 0 0 0])
                case 'a'
                    agent.setCommand(agent.m_cmd_queue + [0 0 0 -10])
                case 'd'
                    agent.setCommand(agent.m_cmd_queue + [0 0 0 10])
                case 'w'
                    agent.setCommand(agent.m_cmd_queue + [0 0 10 0])
                case 'z'
                    agent.setCommand(agent.m_cmd_queue + [0 0 -10 0])
                case 'o'
                    agent.setCommand([0 0 0 0]);
                    pause(0.5);
                    agent.m_ctrl_en = false;
                    agent.launch();
                    disp('Launching');
                    pause(5);
                    agent.m_ctrl_en = true;
                case 'l'
                    agent.setCommand([0 0 0 0]);
                    pause(0.5)
                    agent.m_ctrl_en = false;
                    agent.land();
                    disp('Landing');
                    pause(10);
                    agent.m_ctrl_en = true;
                otherwise
                    agent.setCommand([0 0 0 0])
            end
            agent.m_cmd_queue
            
        end
        
        function takeCommand(agent)
            f = figure;
            set(f,'KeyPressFcn',@(H,E) agent.setCmdFromKeys(E.Key));
        end
        
        function run_ctrl_q(agent)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            if agent.m_ctrl_en
                lr = agent.m_null_cmd(1);
                fb = agent.m_null_cmd(2);
                ud = agent.m_null_cmd(3);
                y = agent.m_null_cmd(4);

                if (~isempty(agent.m_cmd_queue))
                    lr = agent.m_cmd_queue(1);
                    fb = agent.m_cmd_queue(2);
                    ud = agent.m_cmd_queue(3);
                    y = agent.m_cmd_queue(4);
                end
                agent.set_rc_ctrl(lr,fb,ud,y);
            end
        end
    end
end

