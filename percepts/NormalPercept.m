classdef NormalPercept < MultiLanePercept
    %NormalPercept Class holding perceptual information for each UAS
    %   Construct an object of this class to share information between the
    %   environment and a UAS. There should be one MultiLanePercept
    %   instantiated per UAS in the system. When the UTM calls
    %   updatePercept, this object should be updated with the latest
    %   information. When a UAS calls acceptPercept, it should access the
    %   methods made available by this class. 
    
    properties

    end
    
    methods
        function percept = NormalPercept()
            %MULTILANEPERCEPT Construct an instance of a MultiLanePercept
            %   An opbject of this class holds the current perceptual
            %   information available to a UAS
            percept = percept@MultiLanePercept();
        end
        
    end
end

