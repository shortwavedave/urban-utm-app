classdef MultiLaneSimRunner < handle
    %MULTILANESIMRUNNER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        m_lanes
        m_uas
        m_utm
        m_time_step = 0;
        m_sample_per = 0.1;
        m_time = 0;
        trace = [];
        m_uas_config;
        m_plot_xlim = [-5,25]
        m_plot_ylim = [-5,15]
        m_h_axis
        m_h_pos_plot
        m_plot_step_listener
    end
    
    events
        StepTaken
    end
    
    methods
        function obj = MultiLaneSimRunner()
            %MULTILANESIMRUNNER Construct an instance of this class
            %   Detailed explanation goes here
            
        end
        
        initialize_example(obj)
        
        baduas = initialize_dddas(obj, utm_hw)
        
        function initialize_from_gui(sim_runner...
                , utm_selected...     % The selected UTM class name
                , tbl_UAS_Data...     % The table containing the desired mix of UAS types
                , percept_selected... % The selected percept class
                , action_selected...  % The selected action class
                , lane_sys...         % The lane system
                , node_table...       % The node configuration
            )
            sim_runner.m_time_step = 0;
            action_handle = str2func(action_selected);
            percept_handle = str2func(percept_selected);
            sim_runner.m_utm = feval(utm_selected, action_handle, ...
                percept_handle);
            sim_runner.m_utm.m_node_tbl = node_table;
            sim_runner.m_lanes = lane_sys;
            sim_runner.m_utm.m_lane_system = lane_sys;
            sim_runner.m_uas_config = tbl_UAS_Data;
        end
        
        function generateUAS(sim_runner, steps)
            %UAS_Type,Color,Time Dist.,Period,Start Dist.,Start Nodes
            % Time dist is constant or poisson, with rate
            % start dist is round robin or uniform for start nodes
            num_uas_types = size(sim_runner.m_uas_config, 1);
            total_time = steps*sim_runner.m_sample_per;
            
            for i = 1:num_uas_types
                uas_type = sim_runner.m_uas_config{i,{'UAS_Type'}};
                time_dist = sim_runner.m_uas_config{i,{'Time Dist.'}};
                sec_per_uas = sim_runner.m_uas_config{i,{'Period'}};
                start_dist = sim_runner.m_uas_config{i,{'Start Dist.'}};
                launch_nodes = sim_runner.m_uas_config{i,{'Start Nodes'}};
                launch_positions = ...
                    sim_runner.m_lanes.getNodePositions(launch_nodes);
                
                uas_per_step = (1/sec_per_uas) * sim_runner.m_sample_per;
                steps_per_uas = sec_per_uas / sim_runner.m_sample_per;
                cur_step = sim_runner.m_time_step;
                step_vec = cur_step:cur_step+steps-1;
                event = zeros(length(step_vec), 1);
                    
                if (time_dist == 'constant')
                    event( mod(step_vec, steps_per_uas) == 0 ) = 1;
                elseif (time_dist == 'poisson')
                    event( rand(size(event)) < uas_per_step ) = 1;
                end
                
                event_steps = find(event == 1);
                
                start_node_pos = zeros(length(event_steps),2);
                launch_lanes = [];
                if (start_dist == 'round-robin')
                    for j = 1:length(event_steps)
                        node_i = mod(j-1,length(launch_nodes)) + 1;
                        start_node_pos(j,:) = ...
                            launch_positions(node_i , :);
                        x0_node = launch_nodes(node_i);
                        launch_lane = sim_runner.m_lanes...
                            .getOutLanesFromNode(x0_node);
                        launch_lanes = [launch_lanes launch_lane(1)];
                    end
                elseif (start_dist == 'uniform')
                    start_node_pos = launch_positions(randi(length(launch_nodes), ...
                        1, length(event_steps)), :);
                end
                
                for event_step_i = 1:length(event_steps)
                    event_step = event_steps(event_step_i);
                    launch_position = start_node_pos(event_step_i, :)';
                    launch_lane = launch_lanes(event_step_i);
                    uas = feval(uas_type{:}, length(sim_runner.m_uas) + 1);
                    sim_runner.m_uas = [ sim_runner.m_uas, uas ];
                    uas.setStartTime(event_step*sim_runner.m_sample_per);
                    uas.setPosition(launch_position);
                    uas.setLanePath(launch_lane);
                    sim_runner.m_utm.registerUAS(uas);
                    sim_runner.m_utm.initUASPosition(uas.ID, launch_position);
                    sim_runner.m_utm.initUASSpeed(uas.ID, [0 0]');
                end
            end
        end
        
        function num_uas = getExpectedUas(sim_runner, steps)
            periods = sim_runner.m_uas_config{:,{'Period'}};
            rates = 1 ./ periods;
            total_rate = sum(rates);
            num_uas = ceil(total_rate * sim_runner.m_sample_per * steps);
        end
        
        function runSim(sim_runner, steps)
            expectedUas = sim_runner.getExpectedUas(steps);
            if (expectedUas > 0)
                sim_runner.m_utm.preAllocateState(expectedUas);
            end
            sim_runner.generateUAS(steps);
            for i = 1:steps
                sim_runner.m_time_step = sim_runner.m_time_step + 1;
                sim_runner.m_time = sim_runner.m_time_step * ...
                    sim_runner.m_sample_per;
                sim_runner.m_utm.stepTime(0,1);
                notify(sim_runner, 'StepTaken');
            end
        end
        
        function enablePlotSteps(sim_runner, h_axis)
            sim_runner.m_h_axis = h_axis;
            sim_runner.m_plot_step_listener = ...
                addlistener(sim_runner, 'StepTaken', ...
                @sim_runner.handlePlotStep);
        end
        
        function disablePlotSteps(sim_runner)
            delete(sim_runner.m_plot_step_listener);
        end
        
        function handlePlotStep(sim_runner, src, evt)
            if isempty(sim_runner.m_h_pos_plot)
                sim_runner.m_h_pos_plot = ...
                    sim_runner.plotPositions(sim_runner.m_h_axis);
            else
                h = sim_runner.m_h_pos_plot;
                sim_runner.m_h_pos_plot = ...
                    sim_runner.plotPositions(sim_runner.m_h_axis, h);
            end
        end
        
        function h_out = plotPositions(sim_runner, h_axis, h_in)
            active = sim_runner.m_utm.m_state.active;
            x_ind = 1;
            y_ind = 2;
            x_pos = sim_runner.m_utm.m_state.positions_k(x_ind,active);
            y_pos = sim_runner.m_utm.m_state.positions_k(y_ind,active);
            if nargin < 3
                hold(h_axis, 'on');
                h_out = scatter(h_axis, x_pos, y_pos);
                hold(h_axis, 'off');
            else
                h_out = h_in;
                set(h_in,'XData',x_pos,'YData',y_pos);
            end
        end
       
        function recordTrace(obj, src, ~)
            X = 1;
            Y = 2;
            C = 3;
            F = 4;
            D = 5;
            obj.trace(src.time_step, :, X) = src.m_state.positions_k(X,:);
            obj.trace(src.time_step, :, Y) = src.m_state.positions_k(Y,:);
            obj.trace(src.time_step, :, C) = [src.UASs.m_contingency];
            obj.trace(src.time_step, :, F) = [src.UASs.m_forced_contingency];
            obj.trace(src.time_step, :, D) = [src.UASs.m_done];
            obj.trace(src.time_step, ~[src.UASs.m_active], X) = nan;
        end
        
        plotTrace(obj, period, highlight, record)
    end
end

