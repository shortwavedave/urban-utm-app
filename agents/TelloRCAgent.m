classdef TelloRCAgent < ROSAgent
    %TELLORCAGENT Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        m_cmd_q = [0 0 0 0];
        m_cmd_per = 0.1;
        m_timer_obj;
    end
    
    methods
        function agent = TelloRCAgent(id)
            %TELLORCAGENT Construct an instance of this class
            %   Detailed explanation goes here
            agent = agent@ROSAgent(id);
        end
        
        function setControl(agent, ctrl)
            % setControl - set the current control on the UAS
            % ctrl - 1x4 array with elements:
            %           ctrl(1): [-100,100]: (-right, +left) 
            %           ctrl(2): [-100,100]: (-back, +forward) 
            %           ctrl(3): [-100,100]: (-down, +up) 
            %           ctrl(4): [-100,100]: (-cw, +ccw) 
            agent.m_cmd_q = ctrl; 
        end
        
        function startCmdThread(agent)
            agent.m_timer_obj = timer('StartDelay', 0, 'Period', ...
                agent.m_cmd_per, 'TasksToExecute', inf, ...
                'ExecutionMode', 'fixedRate');
            agent.m_timer_obj.TimerFcn = @agent.cmd_thread;
            start(agent.m_timer_obj);
        end
        
        function stopCmdThread(agent)
            delete(agent.m_timer_obj);
        end
        
        function cmd_thread(agent, ~, ~)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            lf = agent.m_cmd_q(1);
            fb = agent.m_cmd_q(2);
            ud = agent.m_cmd_q(3);
            y = agent.m_cmd_q(4);
            agent.set_rc_ctrl(lf, fb, ud, y);
        end
    end
end

