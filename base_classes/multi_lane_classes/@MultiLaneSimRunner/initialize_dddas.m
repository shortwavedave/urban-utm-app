function baduas = initialize_dddas(obj, utm_hw)
    %METHOD1 Summary of this method goes here
    %   Detailed explanation goes here
    segment_len = 5;
    w = 15;
    obj.m_utm = MultiLaneUTM();

    % Subscribe to percept updates to record the simulation
    addlistener(obj.m_utm, "BeforePerceptUpdate", @obj.recordTrace);

    lanes = ddas_system(segment_len,w);
    obj.m_lanes = lanes;
    obj.m_plot_xlim = [-5,85];
    obj.m_plot_ylim = [-10,10];
    
    s = {'00'};
%     t = { [num2str(segment_len*(w+1)) num2str(segment_len)], ...
%         [num2str(segment_len*(w+1)) num2str(-segment_len)] };
    t = { [num2str(segment_len*(w+1)) num2str(segment_len)] };
    for i = 3:2:w-1
        sn = segment_len*i;
        s = {s{:} [num2str(sn) '0']};
    end
%     s = {'00','150','250','350','450'};
%     t = {'555','55-5'};
    if length(t) == 2
        p = {lanes.getShortestPath(s{1},t{1}), lanes.getShortestPath(s{1},t{2})};
        for i = 1:length(s)
            p1 = [lanes.getShortestPath(s{1},s{i}), lanes.getShortestPath(s{i},t{1})];
            p2 = [lanes.getShortestPath(s{1},s{i}), lanes.getShortestPath(s{i},t{2})];
            p = {p{:} p1 p2};
        end
    else
        p = {lanes.getShortestPath(s{1},t{1})};
        for i = 1:length(s)
            p1 = [lanes.getShortestPath(s{1},s{i}), lanes.getShortestPath(s{i},t{1})];
            p = {p{:} p1};
        end
    end
%     p1 = lanes.getShortestPath('00','305');
%     p1a = [lanes.getShortestPath('00','150'), lanes.getShortestPath('150','305')];
%     p1b = [lanes.getShortestPath('00','250'), lanes.getShortestPath('250','305')];
%     
%     p2 = lanes.getShortestPath('00','30-5');
%     p2a = [lanes.getShortestPath('00','150'), lanes.getShortestPath('150','30-5')];
%     p2b = [lanes.getShortestPath('00','250'), lanes.getShortestPath('250','30-5')];
    
%     p1 = lanes.getShortestPath('00','6010');
%     p1a = [lanes.getShortestPath('00','300'), lanes.getShortestPath('300','6010')];
%     p1b = [lanes.getShortestPath('00','500'),
%     lanes.getShortestPath('500','6010')]; 
%     
%     p2 = lanes.getShortestPath('00','60-10');
%     p2a = [lanes.getShortestPath('00','300'), lanes.getShortestPath('300','60-10')];
%     p2b = [lanes.getShortestPath('00','500'), lanes.getShortestPath('500','60-10')];
    
%     p1 = lanes.getShortestPath('00','12020');
%     p1a = [lanes.getShortestPath('00','600'), lanes.getShortestPath('600','12020')];
%     p1b = [lanes.getShortestPath('00','1000'), lanes.getShortestPath('1000','12020')];
%     
%     p2 = lanes.getShortestPath('00','120-20');
%     p2a = [lanes.getShortestPath('00','600'), lanes.getShortestPath('600','120-20')];
%     p2b = [lanes.getShortestPath('00','1000'), lanes.getShortestPath('1000','120-20')];
    
%     p = {p1,p1a,p1b,p2,p2a,p2b};
    num_uas = 100;
    baduas = randi(100,1,10);

    for i = 1:num_uas
        if (find(baduas == i, 1))
            uas = SlowedUAS(i);
            uas.precalculateContingencies(5000);
        else
            uas = CautiousUAS(i);
        end
        obj.m_uas = [ obj.m_uas, uas ];
        path = p{randi(length(p))};
        uas.setLanePath(path);
        uas.setStartTime(i*utm_hw);
        obj.m_utm.registerUAS(uas)
        obj.m_utm.initUASPosition(uas.ID, uas.m_x);
        obj.m_utm.initUASSpeed(uas.ID, 0);
    end

end

