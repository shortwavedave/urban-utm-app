classdef MultiLaneUAS < UAS
    %MULTILANEUAS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        m_x = [0 0]' % The current position of this UAS 
        m_lane_path = []; % The path of the UAS, specified by lane objects
        m_sample_per = 0.1; % The system sample period (set by UTM)
        m_speed = 1;  % The desired speed
        m_lane_i = 1; % The current lane
        m_closest_pos = []; % The position of the closest UAS in front
        m_closest_dist = 0; % The distance to the closest UAS in front
        m_headway = 3; % The minimum headway before velocity control kicks in
        m_active = false; % whether the UAS is active in the lane system
        m_contingency = false; % Whether the UAS is in a contingency mode
        m_forced_contingency = false; % Whether a contingency was forced
        m_num_contingent = 0; % The number of contingent UAS in the system
        m_done = false; % Whether the UAS has completed its mission
        m_utm % The UTM this UAS is registered with
        
        % Trajectory properties
        m_next_x = [0 0]';
        m_start_time = 0;
        
        % PID properties 
        % -0.0115   53.6162    0.0002
%         m_Kp = 1; % Proportional Gain
%         m_Ki = .001; % Integral Gain
%         m_Kd = 40; % Derivative Gain
        m_Kp = -0.0115; % Proportional Gain
        m_Ki = 0.0002; % Integral Gain
        m_Kd = 53.6162; % Derivative Gain
        m_ek = [0 0]'; % Error between current and desired position at next step
        m_ekm1 = [0 0]'; % m_ek at (k-1) step
        m_ekm2 = [0 0]'; % m_ek at (k-2) step
        m_yk = [0 0]'; % current acceleration input
        m_ykm1 = [0 0]'; % m_yk at (k-1) step
    end
    
    methods
        function obj = MultiLaneUAS(ID)
            %MULTILANEUAS Construct an instance of this class
            %   Detailed explanation goes here
            obj = obj@UAS(ID);
        end
        
        function utm = getUtm(utm)
            utm = utm.m_utm;
        end
        
        function setSpeed(uas, speed)
            uas.m_speed = speed;
        end
        
        function speed = getSpeed(uas)
            speed = uas.m_speed;
        end
        
        function lane_path = getShortestPath(uas, x0, xf)
           utm = uas.m_utm;
           lane_system = utm.m_lane_system;
           lane_path = lane_system.getShortestPath(x0, xf);
        end
        
        function launch_nodes = getLaunchNodes(uas)
            utm = uas.getUtm();
            node_table = utm.getNodeTable();
            node_types = node_table{:, {'Type'}}; 
            nodes = node_table{:, {'ID'}}; 
            launch_nodes = nodes(node_types == 'launch');
        end
        
        function land_nodes = getLandNodes(uas)
            utm = uas.getUtm();
            node_table = utm.getNodeTable();
            node_types = node_table{:, {'Type'}}; 
            nodes = node_table{:, {'ID'}}; 
            land_nodes = nodes(node_types == 'land');
        end
        
        function setPosition(uas, position)
            uas.m_x = position;
        end
        
        function will_be_active = getWillBeActive(uas)
            [active, ~] = uas.getIsActive();
            will_be_active = active && (~uas.m_active);
        end
        
        function [active, done] = getIsActive(uas)
            if(~uas.m_done)
                last_lane_i = length(uas.m_lane_path);
                started = (uas.m_time_step*uas.m_sample_per > uas.m_start_time);
                if ~isempty(uas.m_lane_path)
                    not_done = (norm(uas.m_x - uas.m_lane_path(last_lane_i).m_xf) > .5);
                else
                    not_done = true;
                end
                active = started && not_done;
                done = ~not_done;
            else
                active = false;
                done = true;
            end
        end
        
        function setStartTime(obj, time)
           obj.m_start_time = time; 
        end
        
        function setLanePath(obj, L)
            obj.m_lane_path = L;
            obj.m_x = L.getStart();
            obj.m_next_x = obj.m_x;
        end
        
        function setHeadway(obj, hdwy)
            obj.m_headway = hdwy;
        end
        
        yk = PIDControl(obj, ykm1, ek, ekm1, ekm2)
        
        chooseAction(obj, action_handle)
        
        function acceptPercept(uas, percept_handle)
%             [active, ~] = uas.getIsActive();
            if uas.m_active
                uas.m_x = percept_handle.getPosition();
                uas.m_num_contingent = percept_handle.getContingencyCount();
                if ~isempty(uas.m_lane_path)
                   v0 = uas.m_lane_path(uas.m_lane_i).vn;
                   [uas.m_closest_pos, uas.m_closest_dist] = ...
                       percept_handle.getNearestInFront(uas.m_x, v0, uas.ID);
                end
            end
        end
    end
end

