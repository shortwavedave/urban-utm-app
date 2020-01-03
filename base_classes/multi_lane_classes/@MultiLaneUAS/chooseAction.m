function chooseAction(uas, action_handle)
    % Remain active as long as you are operating beyond the start time and
    % you have not reached near your end position.
    if (~uas.m_done)
        [active, done] = uas.getIsActive();
        uas.m_done = done;
        % Make the speed zero if it's not time to start yet
        if (active)
            % Make everyone know the UAS is active in the lane system 
            action_handle.activate();
            uas.m_active = true;
            % Set the speed to the desired amount
            speed = uas.m_speed;
            uas.m_contingency = false;
            % Check distance to next vehicle
            if (~isempty(uas.m_closest_pos))
                % Estimate of distance traveled during next time step
                dist_to_next = uas.m_speed * uas.m_sample_per;
                if dist_to_next > (uas.m_closest_dist - uas.m_headway)
                    % The next step is expected to violate headway, so modify
                    % the speed.
                    uas.m_contingency = true;
                    d = (uas.m_closest_dist - uas.m_headway);
                    speed = max(d / uas.m_sample_per, 0);
                end
            end

            if ~isempty(uas.m_lane_path)
                % Get the next position along the lane path based on the
                % desired speed.
                [x, uas.m_lane_i] = ...
                    uas.m_lane_path.getNextPosition(uas.m_next_x, speed, ...
                    uas.m_sample_per, uas.m_lane_i);
            else
                x = uas.m_x;
            end
            uas.m_next_x = x;

            % Calculate the control
            uas.m_ek = x - uas.m_x;
            uas.m_yk = ...
                uas.PIDControl(uas.m_ykm1, uas.m_ek, uas.m_ekm1, uas.m_ekm2);

            uas.m_ekm2 = uas.m_ekm1;
            uas.m_ekm1 = uas.m_ek;
            uas.m_ykm1 = uas.m_yk;

            action_handle.setAccel(uas.m_yk);
        else
            action_handle.deactivate();
            uas.m_active = false;
        end
    end
end

