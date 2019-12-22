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
        
        % Trajectory properties
        m_next_x = [0 0]';
        m_start_time = 0;
        
        % PID properties 
        m_Kp = 1; % Proportional Gain
        m_Ki = .001; % Integral Gain
        m_Kd = 40; % Derivative Gain
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
        
        function acceptPercept(obj, percept_handle)
           obj.m_x = percept_handle.getPosition();
           obj.m_num_contingent = percept_handle.getContingencyCount();
           v0 = obj.m_lane_path(obj.m_lane_i).vn;
           [obj.m_closest_pos, obj.m_closest_dist] = ...
               percept_handle.getNearestInFront(obj.m_x, v0);
        end
    end
end

