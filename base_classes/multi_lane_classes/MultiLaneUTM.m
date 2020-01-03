classdef MultiLaneUTM < UTM
    %MULTILANEUTM Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        m_lane_system
        m_node_tbl
        % m_state - The state of the environment and UTM.
        % A structure containing anything that describes the state of the
        % system. In particular, positions_k, the current positions of
        % every UAS.
        m_state
        
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
        
        function registerUAS(utm, UAS)
            %registerUAS - Register a UAS with the UTM system
            utm.registerUAS@UTM(UAS);
            UAS.m_sample_per = utm.m_sample_per;
            UAS.m_utm = utm;
        end
        
        function node_table = getNodeTable(utm)
            node_table = utm.m_node_tbl;
        end
        
        function preAllocateState(utm, num_uas)
            pos_struct = zeros(2,num_uas);
            
            if isfield(utm.m_state,'positions_km1')
                utm.m_state.positions_k = [utm.m_state.positions_k, pos_struct];
            else
                utm.m_state.positions_k = pos_struct;
            end
                
            if isfield(utm.m_state,'positions_km1')
                utm.m_state.positions_km1 = [utm.m_state.positions_km1, pos_struct];
            else
                utm.m_state.pos0itions_km1 = pos_struct;
            end
            
            if isfield(utm.m_state, 'positions_km2')
                utm.m_state.positions_km2 = [utm.m_state.positions_km2, pos_struct];
            else
                utm.m_state.positions_km2 = pos_struct;
            end
            
            if isfield(utm.m_state, 'active')
                utm.m_state.active = [utm.m_state.active; false(num_uas, 1)];
            else
                utm.m_state.active = false(num_uas, 1);
            end
            
            if isfield(utm.m_state, 'actions_km1')
                utm.m_state.actions_km1 = [utm.m_state.actions_km1 pos_struct];
            else
                utm.m_state.actions_km1 = pos_struct;
            end
        end
        
        function initUASPosition(utm, UAS_ID, position)
            %initUASPosition - Initialize the position of a UAS
            utm.m_state.positions_k(:,UAS_ID) = position;
            utm.m_state.positions_km1(:,UAS_ID) = position;
            utm.m_state.positions_km2(:,UAS_ID) = position;
            utm.m_state.active(UAS_ID) = false;
        end
        
        function initUASSpeed(obj, UAS_ID, accel)
            obj.actions(UAS_ID).setAccel(accel);
            obj.m_state.actions_km1(:,UAS_ID) = accel;
        end
        
        function updatePercepts(utm,~,~) 
            active = utm.m_state.active;
            positions = utm.m_state.positions_k(:,active);
            num_contingencies = [utm.UASs(active).m_forced_contingency];
            active_percepts = utm.percepts(active);
            for uas_i = 1:length(active_percepts)
                active_percepts(uas_i).m_x = positions(:,uas_i);
                active_percepts(uas_i).m_positions = positions;
                active_percepts(uas_i).m_active = utm.m_state.active;
                active_percepts(uas_i).m_contingent = num_contingencies;
            end
        end  
        
        function updateState(obj,~,~)
            obj.m_state.active = [obj.actions.m_active]';
            active = obj.m_state.active;
            K = obj.m_sample_per*obj.m_sample_per*0.5;
            accels = [obj.actions.m_accel];
            active_accels = accels(:,active);
            u = active_accels + ...
                obj.m_state.actions_km1(:,active);
            
            obj.m_state.positions_k(:,active) = K*u ...
                + 2*obj.m_state.positions_km1(:,active) - ...
                obj.m_state.positions_km2(:,active);

            obj.m_state.positions_km2(:,active) = ...
                obj.m_state.positions_km1(:,active);
            obj.m_state.positions_km1(:,active) = ...
                obj.m_state.positions_k(:,active);
            obj.m_state.actions_km1(:,active) = active_accels;
            
        end
    end
end

