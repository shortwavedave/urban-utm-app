classdef Lane < handle
    %LANE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        m_x0
        m_xf
        m_x0str
        m_xfstr
        vn
        m_id;
        m_graph;
        m_roi;
        m_listeners = []
    end
    
    events
      NodeChanged
      NodeChanging
    end
    
    methods
        function lane = Lane(x0, xf)
            %LANE Construct an instance of this class
            %   Detailed explanation goes here
            if (nargin > 0)
                lane.setEndpoints(x0, xf);
            end
        end
        
        function setEndpoints(lane, x0, xf)
            % Flip them to the correct orientation
            if size(x0,2) > size(x0,1)
                x0 = x0';
            end

            if size(xf,2) > size(xf,1)
                xf = xf';
            end

            lane.m_x0 = x0;
            lane.m_xf = xf;
            lane.vn = (xf-x0)/norm(xf-x0);
        end
        
        function s = getSumOfDegrees(lane, node_id)
            in_d = lane.m_graph.indegree(node_id);
            out_d = lane.m_graph.outdegree(node_id);
            s = in_d + out_d;
        end
        
        function id = getUniqueNodeId(~)
            id = char(java.util.UUID.randomUUID);
        end
        
        function handleRoiMove(lane, src, evt)
            evname = evt.EventName;
            %disp(['ROI for lane: ' num2str(lane.m_id)]);
            %v = evt.CurrentPosition - evt.PreviousPosition; 
              
            switch(evname)
                case{'MovingROI'}
                    % Move the node
                    %lane.m_x0 = lane.m_x0 + v(1,:)';
                    %lane.m_xf = lane.m_x0 + v(2,:)';
                    notify(lane, 'NodeChanging');
                case{'ROIMoved'}
                    v = evt.CurrentPosition - [lane.m_x0'; lane.m_xf'];
                    lane.m_x0 = lane.m_x0 + v(1,:)';
                    lane.m_xf = lane.m_xf + v(2,:)';
                    
                    if (norm(v(1,:)) > 0) && ...
                            (lane.getSumOfDegrees(lane.m_x0str) > 1)
                        lane.m_x0str = lane.getUniqueNodeId();
                    end
                    
                    if (norm(v(2,:)) > 0) && ...
                            (lane.getSumOfDegrees(lane.m_xfstr) > 1)
                        lane.m_xfstr = lane.getUniqueNodeId();
                    end
                    disp("Notifying nodechanged");
                    notify(lane, 'NodeChanged');
            end
        end
        
        function m_x0 = getStart(obj)
           m_x0 = obj(1).m_x0; 
        end
        
        function m_x0str = getStartNode(obj)
           m_x0str = obj(1).m_x0str; 
        end
        
        function inLane = isInLane(obj, x)
            inLane = norm(x-obj.m_x0) < norm(obj.m_xf-obj.m_x0);
        end
        
        function lanes = getShortestPath(obj, x0_node, xf_node)
            G = obj.getDigraph();
            P = G.shortestpath(x0_node, xf_node);
            lanes = [];
            for i = 1:length(P)-1
                lanes = [lanes obj.getLaneFromNodes(P(i),P(i+1))];
            end
        end
        
        function lane = getLaneFromNodes(obj, x0_node, xf_node)
            for i = 1:length(obj)
                if (strcmp(obj(i).m_x0str, x0_node) ...
                        && strcmp(obj(i).m_xfstr, xf_node))
                    lane = obj(i);
                end
            end
        end
        
        function lanes = getOutLanesFromNode(obj, x0_node)
            lanes = [];
            for i = 1:length(obj)
                if strcmp(obj(i).m_x0str, x0_node)
                    lanes = [lanes obj(i)];
                end
            end
        end
        
        function lanes_out = getLanesByID(lanes_in, ids)
            lanes_out = [];
            for i = 1:length(ids)
                for j = 1:length(lanes_in)
                    if (lanes_in(j).m_id == ids(i))
                        lanes_out = [lanes_out lanes_in(j)];
                        break;
                    end
                end
            end
        end
        
        function digr = getDigraph(lanes)
            s = {};
            t = {};
            weights = zeros(1,length(lanes));
            for i = 1:length(lanes)
                l = lanes(i);
                s{i} = l.m_x0str;
                t{i} = l.m_xfstr;
                weights(i) = norm(l.m_xf-l.m_x0);
            end
            digr = digraph(s,t,weights);
            for i = 1:length(lanes)
                l = lanes(i);
                l.m_graph = digr;
            end
        end
        
        function [xi, lane_i] = getNextPosition(obj,m_x0,speed,T,lane_i)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            xi = m_x0 + speed*obj(lane_i).vn*T;
            if ~obj(lane_i).isInLane(xi)
                if length(obj) > lane_i
                    %xi1 = obj(lane_i).m_xf - m_x0;
                    xdif = xi - obj(lane_i).m_xf;
                    lane_i = lane_i + 1;
                    xi = obj(lane_i).m_x0 + norm(xdif)*obj(lane_i).vn;
                else
                    xi = obj(lane_i).m_xf;
                end
            end
        end
        
        function plotLanes(obj, h)
            if (nargin < 2)
                hold on;
            else
                hold(h, 'on');
            end
            for i = 1:length(obj)
                x = [obj(i).m_x0(1) obj(i).m_xf(1)];
                y = [obj(i).m_x0(2) obj(i).m_xf(2)];
                if nargin < 2
                    plot(x, y, '-ok');
                else
                    plot(h, x, y, '-ok');
                end
            end
            if (nargin < 2)
                hold off;
            else
                hold(h, 'off');
            end
        end
        
        function plotLanesQuiver(obj,h)
            if (nargin < 2)
                hold on;
            else
                hold(h, 'on');
            end
            for i = 1:length(obj)
                x = obj(i).m_x0(1);
                y = obj(i).m_x0(2);
                v = obj(i).m_xf - obj(i).m_x0;
                vx = v(1);
                vy = v(2);
                
                if ~isempty(obj(i).m_id)
                    tx = x + vx/2 + abs(0.1*vy);
                    ty = y + vy/2 + abs(0.1*vx);
                    if nargin < 2
                        text(tx,ty,['L-', num2str(obj(i).m_id)]);  
                    else
                        text(h,tx,ty,['L-', num2str(obj(i).m_id)]); 
                    end
                end
                if nargin < 2
                    quiver(x,y,vx,vy,'ok', 'ShowArrowHead', 'on');
                else
                    quiver(h,x,y,vx,vy,'ok', 'ShowArrowHead', 'on');
                end
            end
            if (nargin < 2)
                hold off;
            else
                hold(h, 'off');
            end
        end
        
        function highlightLanes(lanes, plot_handle, lane_ids)
            num_s = length(lane_ids);
            num_t = num_s;
            s = cell(1,num_s);
            t = cell(1,num_t);
            h_lanes = lanes.getLanesByID(lane_ids);
            for i = 1:length(h_lanes)
                s(i) = {h_lanes(i).m_x0str};
                t(i) = {h_lanes(i).m_xfstr};
            end
            highlight(plot_handle, s, t);
        end
        
        function highlightNodes(~, plot_handle, node_ids)
            highlight(plot_handle, node_ids);
        end
        
        function pos = getNodePositions(lanes, x_str)
            pos = zeros(size(x_str,1),2);
            for i = 1:size(x_str,1)
                for j = 1:length(lanes)
                    if (strcmp(lanes(j).m_x0str, x_str(i)))
                        pos(i,:) = lanes(j).m_x0';
                        break;
                    elseif (strcmp(lanes(j).m_xfstr, x_str(i)))
                        pos(i,:) = lanes(j).m_xf';
                        break;
                    end
                end
            end
        end
        
        function ph = plotLanesDigraph(obj,h,callback)
            G = obj.getDigraph;
            x = zeros(2,G.numnodes);
            for i = 1:G.numnodes
                nodeName = G.Nodes.Name{i};
                % Find the coordinate for this node for plotting the
                % correct position
                for j = 1:length(obj)
                    if (strcmp(obj(j).m_x0str, nodeName))
                        x(:,i) = obj(j).m_x0;
                        break;
                    elseif (strcmp(obj(j).m_xfstr, nodeName))
                        x(:,i) = obj(j).m_xf;
                        break;
                    end
                end
            end
            if nargin < 2
                ph = plot(G,'XData',x(1,:)','YData',x(2,:)','EdgeLabel',...
                    G.Edges.Weight);
            elseif nargin < 3
                ph = plot(h,G,'XData',x(1,:)','YData',x(2,:)','EdgeLabel',...
                    G.Edges.Weight);
            else
                ph = plot(h,G,'XData',x(1,:)','YData',x(2,:)','EdgeLabel',...
                    G.Edges.Weight,'ButtonDownFcn', callback);
            end
        end
    end
end

