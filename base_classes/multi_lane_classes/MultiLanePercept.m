classdef MultiLanePercept < handle
    %MultiLanePercept Class holding perceptual information for each UAS
    %   Construct an object of this class to share information between the
    %   environment and a UAS. There should be one MultiLanePercept
    %   instantiated per UAS in the system. When the UTM calls
    %   updatePercept, this object should be updated with the latest
    %   information. When a UAS calls acceptPercept, it should access the
    %   methods made available by this class. 
    
    properties
        % m_x - (2x1) vector with the position of this UAS [x,y]' 
        m_x = [0 0]';
        
        % m_distances - (1 x numUAS) matrix with the distance of every UAS in 
        %   the system from the UAS that owns this percept. 
        m_distances = [];
        
        % m_positions - (2 x numUAS) matrix with the position of every UAS in 
        %   the system. 
        m_positions = [];
        
        % m_active - (1 x numUAS) boolean vector indicating whether a UAS
        % is active (true) or not (false). Active UAS are present in the
        % lane system.
        m_active = []
        
        m_contingent = 0;
        m_updated = false;
    end
    
    methods
        function obj = MultiLanePercept()
            %MULTILANEPERCEPT Construct an instance of a MultiLanePercept
            %   An opbject of this class holds the current perceptual
            %   information available to a UAS
        end
        
        function position = getPosition(obj)
            %getPosition Get the current position of this UAS according to
            %   the UTM
            %      
            % On output:
            %     position (2x1): Position of this UAS [x,y]'
            % Call:
            %     position = uasPercept.getPosition();
            position = obj.m_x;
        end
        
        function count = getContingencyCount(obj)
            count = obj.m_contingent;
        end
        
        function [position, distance] = getNearestInFront(obj, x0, v0, my_id)
            %getNearestInFront - get the position of the nearest UAS in front
            % of your UAS. Does not return positions that are on top of
            % each other, i.e., assumes there is distance between them.
            %      
            % On input:
            %     x0 (2x1 vector): A vector representing your position [x y]'
            %     v0 (2x1): Vector representing which way you are facing
            %       [vx vy]'
            % On output:
            %     position (2x1): Position of nearest UAS in front. [x,y]'
            %     distance (double): distance to nearest UAS in front
            % Call:
            %     [position, distance] =    uasPercept.getNearestInFront(x, v);
            
            % Replicate the velocity vector in order to perform a dot
            % product.
            arc = 5*pi/180;
            active = obj.m_active(obj.m_active);
            % Remove self from active list
            if ~isempty(active)
                active(my_id) = false;
            end
            active_positions = obj.m_positions(:, active);
%             if ~all(size(obj.m_active) == size(obj.m_distances))
%                 num_missing = max(size(obj.m_active) - size(obj.m_distances));
%                 obj.m_distances = [obj.m_distances inf(1,num_missing)];
%             end
%             active_distances = obj.m_distances(obj.m_active);
            
            if (~isempty(active_positions))
                v0norm = norm(v0);
                v0t = repmat(v0, 1, size(active_positions,2));

                % Get the vector pointing to the other UAS.
                d = active_positions - x0;

                d_norms = sqrt(d(1,:).^2 + d(2,:).^2);

                % dot product, column-wise
                angles = acos( dot(v0t,d,1) ./ (d_norms*v0norm) );
                inFront = (angles < arc); 

                inds = find(inFront);

                [~, i] = min(d_norms(inds));
                uas_i = inds(i);
                position = active_positions(:,uas_i);
                distance = d_norms(uas_i);
            else
                position = inf(size(x0));
                distance = inf;
            end
        end
    end
end

