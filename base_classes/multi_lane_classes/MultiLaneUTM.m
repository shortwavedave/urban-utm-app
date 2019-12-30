classdef MultiLaneUTM < UTM
    %MULTILANEUTM Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        m_lane_system;
        
        % m_state - The state of the environment and UTM.
        % A structure containing anything that describes the state of the
        % system. In particular, positions_k, the current positions of
        % every UAS.
        m_state;
        
        m_sample_per = 0.1; % The sample period of the system, in seconds.
    end
    
    methods
        function obj = MultiLaneUTM(action_type, percept_type)
            %MULTILANEUTM Construct an instance of this class
            if nargin == 0
                action_type = @MultiLaneAction;
                percept_type = @MultiLanePercept;
            end
            obj = obj@UTM(action_type, percept_type); 
        end
        
        function registerUAS(obj, UAS)
            %registerUAS - Register a UAS with the UTM system
            obj.registerUAS@UTM(UAS);
            UAS.m_sample_per = obj.m_sample_per;
        end
        
        function initUASPosition(obj, UAS_ID, position)
            %initUASPosition - Initialize the position of a UAS
            obj.m_state.positions_k(:,UAS_ID) = position;
            obj.m_state.positions_km1(:,UAS_ID) = position;
            obj.m_state.positions_km2(:,UAS_ID) = position;
            obj.m_state.distances = squareform(pdist(obj.m_state.positions_k'));
            obj.m_state.active(UAS_ID) = false;
        end
        
        function initUASSpeed(obj, UAS_ID, accel)
            obj.actions(UAS_ID).setAccel(accel);
            obj.m_state.actions_km1 = 0;
        end
        
        function updatePercepts(obj,~,~)
            positions = [obj.m_state.positions_k];
            num_contingencies = [obj.UASs.m_forced_contingency];
            for uas_i = 1:obj.num_UAS
                obj.percepts(uas_i).m_x = positions(:,uas_i);
                obj.percepts(uas_i).m_positions = positions;
                obj.percepts(uas_i).m_distances = obj.m_state.distances(uas_i,:);
                obj.percepts(uas_i).m_active = obj.m_state.active;
                obj.percepts(uas_i).m_contingent = num_contingencies;
            end
        end  
        
        function updateState(obj,~,~)
            obj.m_state.active = [obj.actions.m_active]';
            K = obj.m_sample_per*obj.m_sample_per*0.5;
            u = [obj.actions.m_accel] + obj.m_state.actions_km1;
            
            obj.m_state.positions_k = K*u ...
                + 2*obj.m_state.positions_km1 - obj.m_state.positions_km2;

            obj.m_state.positions_km2 = obj.m_state.positions_km1;
            obj.m_state.positions_km1 = obj.m_state.positions_k;
            obj.m_state.actions_km1 = [obj.actions.m_accel];
            
            obj.m_state.distances = squareform(pdist(obj.m_state.positions_k'));
        end
    end
end

