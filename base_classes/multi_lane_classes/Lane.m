classdef Lane < handle
    %LANE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        x0
        xf
        m_x0str
        m_xfstr
        vn
        m_id;
        m_graph;
    end
    
    methods
        function obj = Lane(x0, xf)
            %LANE Construct an instance of this class
            %   Detailed explanation goes here
            
            % Flip them to the correct orientation
            if size(x0,2) > size(x0,1)
                x0 = x0';
            end
            
            if size(xf,2) > size(xf,1)
                xf = xf';
            end
            
            obj.x0 = x0;
            obj.xf = xf;
            obj.vn = (xf-x0)/norm(xf-x0);
        end
        
        function x0 = getStart(obj)
           x0 = obj(1).x0; 
        end
        
        function inLane = isInLane(obj, x)
            inLane = norm(x-obj.x0) < norm(obj.xf-obj.x0);
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
        
        function digr = getDigraph(obj)
            s = {};
            t = {};
            weights = zeros(1,length(obj));
            for i = 1:length(obj)
                l = obj(i);
                s{i} = l.m_x0str;
                t{i} = l.m_xfstr;
                weights(i) = norm(l.xf-l.x0);
            end
            digr = digraph(s,t,weights);
        end
        
        function [xi, lane_i] = getNextPosition(obj,x0,speed,T,lane_i)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            xi = x0 + speed*obj(lane_i).vn*T;
            if ~obj(lane_i).isInLane(xi)
                if length(obj) > lane_i
                    %xi1 = obj(lane_i).xf - x0;
                    xdif = xi - obj(lane_i).xf;
                    lane_i = lane_i + 1;
                    xi = obj(lane_i).x0 + norm(xdif)*obj(lane_i).vn;
                else
                    xi = obj(lane_i).xf;
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
                x = [obj(i).x0(1) obj(i).xf(1)];
                y = [obj(i).x0(2) obj(i).xf(2)];
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
                x = obj(i).x0(1);
                y = obj(i).x0(2);
                v = obj(i).xf - obj(i).x0;
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
        
        function ph = plotLanesDigraph(obj,h)
            G = obj.getDigraph;
            x = zeros(2,G.numnodes);
            for i = 1:G.numnodes
                nodeName = G.Nodes.Name{i};
                % Find the coordinate for this node
                for j = 1:length(obj)
                    if (strcmp(obj(j).m_x0str, nodeName))
                        x(:,i) = obj(j).x0;
                        break;
                    elseif (strcmp(obj(j).m_xfstr, nodeName))
                        x(:,i) = obj(j).xf;
                        break;
                    end
                end
            end
            if nargin < 2
                ph = plot(G,'XData',x(1,:)','YData',x(2,:)','EdgeLabel',G.Edges.Weight);
            else
                ph = plot(h,G,'XData',x(1,:)','YData',x(2,:)','EdgeLabel',G.Edges.Weight);
            end
        end
    end
end

