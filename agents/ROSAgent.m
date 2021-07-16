
classdef ROSAgent < handle
    %ROSAGENT Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        m_id
        
        m_battery = 0 % percent
        m_velocity = [-1 -1 -1]' % m/s
        m_r_loc = [-1 -1 -1]' % location relative to mission pad
        m_orient = [0 0 0]' % yaw, pitch, roll
        m_height = 0 % probably cm
        m_accel = [0 0 0]' % m/s^2
        m_mid = -1 % mission pad id
        
        m_node
        m_msg
        
        m_cmd
        m_curr_view
        m_vid_player
        m_log_en = true
        m_cam_params
    end
    
    properties (SetAccess = private)
        m_vid_listener
        m_frame_listener
        m_cam_plot_listener
        
        m_bat_sub
        m_vel_sub
        m_loc_sub
        m_cmd_pub
        m_im_sub
        m_mid_sub
        m_orient_sub
        m_height_sub
        m_accel_sub
        
        m_frame_cnt = 0
        m_frame_capture_en = false
        m_frames
        m_skipped_frames = 0
        m_num_frames = 0 
        m_frame_rate_div = 0
        m_im_rate
        m_im_timer
        m_cam_fig
        m_cam_handle
        m_initialized = false;
        m_heartbeat_timer
        m_image_transforms = {}
    end
    
    events
        ViewUpdated
        ROSInitialized
    end
    
    methods
        function agent = ROSAgent(id)
            %ROSAGENT Construct an instance of this class
            %   Detailed explanation goes here
            agent.m_id = id;
            if agent.ros_online()
                agent.init_agent();
                disp('Agent Initialized');
                notify(agent,'ROSInitialized');
                agent.m_initialized = true;
            else
                disp('ROS Server not detected');
                disp('Checking again in 2 seconds');
                t = timer;
                t.StartDelay = 2;
                t.TimerFcn = @agent.startLoop;
                start(t)
            end
        end
        
        function init_agent(agent)
            id = agent.m_id;
            agent.m_node = ros2node(['/agents/' num2str(id)]);
            
            agent.m_bat_sub = ros2subscriber(agent.m_node,...
                ['/' num2str(id) '/' 'battery_state'], ...
                @agent.handleBatteryState);
            
            agent.m_vel_sub = ros2subscriber(agent.m_node,...
                ['/' num2str(id) '/' 'velocity'], ...
                @agent.handleVelocityState);
            
            agent.m_accel_sub = ros2subscriber(agent.m_node,...
                ['/' num2str(id) '/' 'accel'], ...
                @agent.handleAccelState);
            
            agent.m_mid_sub = ros2subscriber(agent.m_node,...
                ['/' num2str(id) '/' 'mid'], ...
                @agent.handleMidState);
            
            agent.m_height_sub = ros2subscriber(agent.m_node,...
                ['/' num2str(id) '/' 'height'], ...
                @agent.handleHeightState);
            
            agent.m_orient_sub = ros2subscriber(agent.m_node,...
                ['/' num2str(id) '/' 'orient'], ...
                @agent.handleOrientState);
            
            agent.m_loc_sub = ros2subscriber(agent.m_node,...
                ['/' num2str(id) '/' 'r_loc'], @agent.handlePosState);
            
            agent.m_im_sub = ros2subscriber(agent.m_node,...
                ['/' num2str(id) '/' 'image_raw'], @agent.handleImage);
            
            agent.m_cmd_pub = ros2publisher(agent.m_node,...
                ['/' num2str(id) '/' 'cmd'], "std_msgs/String", ...
                "History", "keeplast", "Depth",20, ...
                "Reliability","reliable");
            
            agent.m_cmd = ros2message("std_msgs/String");
            agent.m_cam_params = load('camParams.mat').camParams;
        end
        
        function startLoop(agent, ~, ~)
            if agent.ros_online()
                agent.init_agent();
                disp('Agent Initialized');
                notify(agent,'ROSInitialized');
                agent.m_initialized = true;
            else
                disp('ROS Server not detected');
                disp('Checking again in 2 seconds');
                t = timer;
                t.StartDelay = 2;
                t.TimerFcn = @agent.startLoop;
                start(t)
            end
        end
        
        function online = ros_online(agent)
            topics = ros2('topic','list');
            sf = strfind(topics,agent.m_id);
            online = false;
            num_topics = length(topics);
            for i = 1:num_topics
                online = ~isempty(sf{i});
                if online
                    break;
                end
            end
        end
        
        function addImageTransform(agent, transform_fn)
            agent.m_image_transforms = [agent.m_image_transforms(:), ...
                {transform_fn}];
        end
        
        function tfs = getImageTransforms(agent)
            tfs = agent.m_image_transforms;
        end
        
        function deleteImageTransforms(agent, idx)
            agent.m_image_transforms(idx) = [];
        end
        
        function launch(agent)
            agent.m_cmd.data = 'takeoff';
            agent.m_cmd_pub.send(agent.m_cmd);
        end
        
        function land(agent)
            agent.m_cmd.data = 'land';
            agent.m_cmd_pub.send(agent.m_cmd);
        end
        
        function set_rc_ctrl(agent, lf, fb, ud, y)
            % “lf” = left/right (-100-100)
            % “fb” = forward/backward (-100-100)
            % “ud” = up/down (-100-100)
            % “y” = yaw (-100-100)
            if (lf < -100 || lf > 100) ...
                || (fb < -100 || fb > 100) ...
                || (ud < -100 || ud > 100)...
                || (y < -100 || y > 100)
                error('inputs must be between -100 and 100 inclusive');
            end
            agent.m_cmd.data = ['rc ', num2str(round(lf)), ' ', ...
                 num2str(round(fb)), ' ',  num2str(round(ud)), ' ', ...
                  num2str(round(y))];
            agent.m_cmd_pub.send(agent.m_cmd);
        end
        
        function set_mdir(agent, x)
            % 0 - downward only
            % 1 - forward only
            % 2 - both
            agent.m_cmd.data = ['mdirection ' num2str(round(x))];
            agent.m_cmd_pub.send(agent.m_cmd);
        end
        
        function set_mid_detect(agent, tf)
            if tf
                agent.m_cmd.data = ['mon'];
            else
                agent.m_cmd.data = ['moff'];
            end
            agent.m_cmd_pub.send(agent.m_cmd);
        end
        
        function up(agent, z_cm)
            if z_cm < 20 || z_cm > 500
                error('z_cm must be between 20 and 500 inclusive');
            end
            agent.m_cmd.data = ['up ' num2str(round(z_cm))];
            agent.m_cmd_pub.send(agent.m_cmd);
        end
        
        function down(agent, z_cm)
            if z_cm < 20 || z_cm > 500
                error('z_cm must be between 20 and 500 inclusive');
            end
            agent.m_cmd.data = ['down ' num2str(round(z_cm))];
            agent.m_cmd_pub.send(agent.m_cmd);
        end
        
        function left(agent, x_cm)
            if x_cm < 20 || x_cm > 500
                error('x_cm must be between 20 and 500 inclusive');
            end
            agent.m_cmd.data = ['left ' num2str(round(x_cm))];
            agent.m_cmd_pub.send(agent.m_cmd);
        end
        
        function right(agent, x_cm)
            if x_cm < 20 || x_cm > 500
                error('x_cm must be between 20 and 500 inclusive');
            end
            agent.m_cmd.data = ['right ' num2str(round(x_cm))];
            agent.m_cmd_pub.send(agent.m_cmd);
        end
        
        function forward(agent, x_cm)
            if x_cm < 20 || x_cm > 500
                error('x_cm must be between 20 and 500 inclusive');
            end
            agent.m_cmd.data = ['forward ' num2str(round(x_cm))];
            agent.m_cmd_pub.send(agent.m_cmd);
        end
        
        function back(agent, x_cm)
            if x_cm < 20 || x_cm > 500
                error('x_cm must be between 20 and 500 inclusive');
            end
            agent.m_cmd.data = ['back ' num2str(round(x_cm))];
            agent.m_cmd_pub.send(agent.m_cmd);
        end
        
        function cw(agent, x_cm)
            if x_cm < 20 || x_cm > 500
                error('x_cm must be between 20 and 500 inclusive');
            end
            agent.m_cmd.data = ['cw ' num2str(round(x_cm))];
            agent.m_cmd_pub.send(agent.m_cmd);
        end
        
        function ccw(agent, x_cm)
            if x_cm < 20 || x_cm > 500
                error('x_cm must be between 20 and 500 inclusive');
            end
            agent.m_cmd.data = ['ccw ' num2str(round(x_cm))];
            agent.m_cmd_pub.send(agent.m_cmd);
        end
        
        function flip_left(agent)
            agent.m_cmd.data = 'flip l';
            agent.m_cmd_pub.send(agent.m_cmd);
        end
        
        function flip_right(agent)
            agent.m_cmd.data = 'flip r';
            agent.m_cmd_pub.send(agent.m_cmd);
        end
        
        function flip_forward(agent)
            agent.m_cmd.data = 'flip f';
            agent.m_cmd_pub.send(agent.m_cmd);
        end
        
        function flip_back(agent)
            agent.m_cmd.data = 'flip b';
            agent.m_cmd_pub.send(agent.m_cmd);
        end
        
        function handleBatteryState(agent, msg)
            agent.m_battery = msg.data;
        end
        
        function enableVideo(agent)
            agent.m_vid_player = vision.VideoPlayer;
            agent.m_vid_listener = ...
                    addlistener(agent, 'ViewUpdated', @agent.vidCallback);
        end
        
        function disableVideo(agent)
            delete(agent.m_vid_listener);
        end
        
        function frames = getCapturedFrames(agent)
            frames = agent.m_frames;
        end
        
        function captureFrames(agent, num_frames, rate_div)
            if (rate_div < 1)
                rate_div = 1;
                warning('rate_div must be a positive integer - defaulting');
            end
            if (~agent.m_frame_capture_en)
                disp('Capturing Frames...');
                agent.m_frames = struct('cdata',[],'colormap',[]);
                agent.m_num_frames = num_frames;
                agent.m_frame_rate_div = rate_div;
                agent.m_frame_capture_en = true;
                agent.m_frame_cnt = 1;
                agent.m_frames(num_frames) = ...
                    struct('cdata',[],'colormap',[]);
                agent.m_frame_listener = addlistener(agent, ...
                    'ViewUpdated', @agent.framesCallback);
            end
            %disp(['CB Called - ' num2str(agent.m_skipped_frames)]);
            if (mod(agent.m_skipped_frames, round(rate_div)) == 0)
                %disp('Recording Frame');
                agent.m_skipped_frames = agent.m_skipped_frames + 1;
                if (agent.m_frame_cnt <= num_frames)
                    %disp('Not Done');
                    agent.m_frames(agent.m_frame_cnt) = ...
                        im2frame(agent.m_curr_view);
                    agent.m_frame_cnt = agent.m_frame_cnt + 1; 
                else
                    delete(agent.m_frame_listener);
                    agent.m_frame_capture_en = false;
                    agent.m_skipped_frames = 0;
                    disp('Frame Capture Completed');
                end
            else
                agent.m_skipped_frames = agent.m_skipped_frames + 1;
            end
        end
        
        function handleImage(agent, msg)
            %disp(msg.data);
            if (~isempty(agent.m_im_timer))
                agent.m_im_rate = 1 / toc(agent.m_im_timer);
            end
            agent.m_im_timer = tic;
            agent.m_curr_view = permute(reshape(msg.data, ...
                [3 msg.width msg.height]),[3 2 1]);
            notify(agent,'ViewUpdated');
        end
        
        function handleVelocityState(agent, msg)
            agent.m_velocity = [msg.x msg.y msg.z]';
        end
        
        function handleOrientState(agent, msg)
            % pitch, yaw, roll
            agent.m_orient = [msg.x msg.y msg.z]';
        end
        
        function handleHeightState(agent, msg)
            agent.m_height = msg.data;
        end
        
        function handleAccelState(agent, msg)
            agent.m_accel = [msg.x msg.y msg.z]';
        end
        
        function handleMidState(agent, msg)
            agent.m_mid = msg.data;
        end
        
        function handlePosState(agent, msg)    
            agent.m_r_loc = [msg.x msg.y msg.z]';
        end
        
        function enableCamPlot(agent)
            agent.m_cam_plot_listener = addlistener(agent, ...
                    'ViewUpdated', @agent.handleCamPlotUpdate);
        end
        
        function disableCamPlot(agent)
            delete(agent.m_cam_plot_listener);
        end
        
        function enableHeartbeat(agent)
            agent.m_heartbeat_timer = timer('TimerFcn', ...
                @(x,y)agent.set_rc_ctrl(0,0,0,0), ...
                'StartDelay', 5, ...
                'Period', 5, ...
                'TasksToExecute', inf, ...
                'ExecutionMode', 'fixedRate');
            start(agent.m_heartbeat_timer);
        end
        
        function disableHeartbeat(agent)
            delete(agent.m_heartbeat_timer);
        end
        
        function handleCamPlotUpdate(agent, ~, ~)
            im = agent.m_curr_view;
            [im_pts, board_size, world_pts] = ROSAgent.detectCheckerboard(im);
            if (~isempty(im_pts))
                [cam_orient, cam_pos, ~] = ROSAgent.getCamPosition(...
                    agent.m_cam_params, im, im_pts, world_pts);
                if ~isempty(agent.m_cam_fig)
                    %axes = axes('Parent', agent.m_cam_fig);
                    ROSAgent.plotCamera(cam_pos, cam_orient, ...
                        agent.m_cam_handle);
                else
                    agent.m_cam_fig = figure;
                    ROSAgent.plotCheckerPts(world_pts);
                    hold on;
                    agent.m_cam_handle = ROSAgent.plotCamera(cam_pos,...
                        cam_orient);
                    set(gca,'CameraUpVector',[0 1 0]);
                    hold off;
                    grid on;
                    axis equal;
                    axis auto;
                    xlabel('X (mm)');
                    ylabel('Y (mm)');
                    zlabel('Z (mm)');
                end
            end
        end
        
        function delete(agent)
            delete(agent.m_bat_sub);
            delete(agent.m_vel_sub);
            delete(agent.m_loc_sub);
            delete(agent.m_cmd_pub);
            delete(agent.m_im_sub);
            delete(agent.m_mid_sub);
            delete(agent.m_orient_sub);
            delete(agent.m_height_sub);
            delete(agent.m_accel_sub);
            delete(agent.m_bat_sub);
            delete(agent.m_node);
        end
    end 
    
    methods (Static)
        function cam_params = getCamParams(frames)
            height = 720;
            width = 960;
            colors = 3;
            square_size = 21;
            num_frames = length(frames);
            
            images(height, width, colors, num_frames) = uint8(0);
            for i = 1:num_frames
                im = frame2im(frames(i));
                images(:,:,:,i) = im;
            end
            [image_points, board_size, ~] = ...
                detectCheckerboardPoints(images);
            
            image_size = [height, width];
            world_points = generateCheckerboardPoints(board_size, ...
                square_size);
            cam_params = estimateCameraParameters(image_points, ...
                world_points, 'ImageSize', image_size);
        end
        
        function h = plotCheckerPts(world_pts)
            h = plot3(world_pts(:,1),world_pts(:,2),...
                zeros(size(world_pts, 1),1),'*');
            hold on;
            plot3(0,0,0,'g*');
            hold off;
        end
        
        function cam = plotCamera(pos, orient, cam)
            if nargin < 3
                cam = plotCamera('Location',pos,'Orientation',orient,...
                    'Opacity',0,'Size',20,'AxesVisible', true); 
            else
                cam.Orientation = orient;
                cam.Location = pos;
                drawnow;
            end
        end
        
        function [cam_orient, cam_pos, u_im] = getCamPosition(cam_params, ...
                im, im_pts, world_pts)
            [u_im, new_origin] = undistortImage(im, cam_params, ...
                'OutputView', 'full');
            % Adjust the imagePoints so that they are expressed in the 
            % coordinate system  used in the original image, before it was 
            % undistorted.  This adjustment makes it compatible with the 
            % cameraParameters object computed for the original image.
            image_points = im_pts + new_origin;
            
            % Compute rotation and translation of the camera.
            [R, t] = extrinsics(image_points, world_pts, cam_params);
            [cam_orient, cam_pos] = extrinsicsToCameraPose(R, t);
        end
        
        function [im_pts, board_size, world_pts] = detectCheckerboard(im)
            squareSize = 21; % in millimeters
            % Detect the checkerboard corners in the images.
            [im_pts, board_size] = detectCheckerboardPoints(im);
            if (~isempty(im_pts))
                % Generate the world coordinates of the checkerboard corners in 
                % the pattern-centric coordinate system, with the upper-left 
                % corner at (0,0).
                world_pts = generateCheckerboardPoints(board_size, squareSize); 
            else
                world_pts = [];
            end
        end
    end
    
    methods (Access = 'private')
        function vidCallback(agent, ~, ~)
            im = agent.m_curr_view;
            for i = 1:length(agent.m_image_transforms)
                im = agent.m_image_transforms{i}(im);
            end
            step(agent.m_vid_player, im);
        end
        
        function framesCallback(agent, ~, ~)
            agent.captureFrames(agent.m_num_frames, agent.m_frame_rate_div);
        end
    end
end

