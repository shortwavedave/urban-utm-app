function chooseAction(obj, action_handle)
    % Remain active as long as you are operating beyond the start time and
    % you have not reached near your end position.
    last_lane_i = length(obj.m_lane_path);
    started = (obj.m_time_step*obj.m_sample_per > obj.m_start_time);
    not_done = (norm(obj.m_x - obj.m_lane_path(last_lane_i).xf) > .5);
    active = started && not_done;
    % Make the speed zero if it's not time to start yet
    if (active)
        % Make everyone know the UAS is active in the lane system 
        action_handle.activate();
        obj.m_active = true;
        % Set the speed to the desired amount
        speed = obj.m_speed;
        obj.m_contingency = false;
        % Check distance to next vehicle
        if (~isempty(obj.m_closest_pos))
            % Estimate of distance traveled during next time step
            dist_to_next = obj.m_speed * obj.m_sample_per;
            if dist_to_next > (obj.m_closest_dist - obj.m_headway)
                % The next step is expected to violate headway, so modify
                % the speed.
                obj.m_contingency = true;
                d = (obj.m_closest_dist - obj.m_headway);
                speed = max(d / obj.m_sample_per, 0);
            end
        end
    else
        if (~not_done)
            obj.m_done = true;
        end
        action_handle.deactivate();
        obj.m_active = false;
        speed = 0;
    end
    
    % Get the next position along the lane path based on the
    % desired speed.
    [x, obj.m_lane_i] = ...
        obj.m_lane_path.getNextPosition(obj.m_next_x, speed, ...
        obj.m_sample_per, obj.m_lane_i);

    obj.m_next_x = x;

    % Calculate the control
    obj.m_ek = x - obj.m_x;
    obj.m_yk = ...
        obj.PIDControl(obj.m_ykm1, obj.m_ek, obj.m_ekm1, obj.m_ekm2);

    obj.m_ekm2 = obj.m_ekm1;
    obj.m_ekm1 = obj.m_ek;
    obj.m_ykm1 = obj.m_yk;

    action_handle.setAccel(obj.m_yk);
end

