function initialize_example(obj)
    %METHOD1 Summary of this method goes here
    %   Detailed explanation goes here

    obj.m_utm = MultiLaneUTM();

    % Subscribe to percept updates to record the simulation
    addlistener(obj.m_utm, "BeforePerceptUpdate", @obj.recordTrace);

    num_uas = 10;

    L1 = Lane([0 5], [5 5]);
    L2a = Lane([5 5], [10 10]);
    L2b = Lane([5 5], [10 0]);
    L3a = Lane([10 10], [15 5]);
    L3b = Lane([10 0], [15 5]);
    L4 = Lane([15 5], [20 5]);
    L5 = Lane([20,5], [20,10]);
    obj.m_lanes = [L1 L2a L2b L3a L3b L4 L5];
    lane_set1 = [L1 L2a L3a L4 L5];
    lane_set2 = [L1 L2b L3b L4 L5];

    for i = 1:num_uas
        if (i == 1)
            uas = SlowedUAS(i);
        else
            uas = MultiLaneUAS(i);
        end
        obj.m_uas = [ obj.m_uas, uas ];
        if (rand() > 0.5)
            uas.setLanePath(lane_set1);
        else
            uas.setLanePath(lane_set2);
        end
        uas.setStartTime(i*2);
        obj.m_utm.registerUAS(uas)
        obj.m_utm.initUASPosition(uas.ID, uas.m_x);
        obj.m_utm.initUASSpeed(uas.ID, 0);
    end

end

