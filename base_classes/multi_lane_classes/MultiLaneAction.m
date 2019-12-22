classdef MultiLaneAction < handle
    %MULTILANEACTION Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        m_accel = [0 0]';
        m_active = false;
    end
    
    methods
        function obj = MultiLaneAction()
            %MULTILANEACTION Construct an instance of this class
            %   Detailed explanation goes here
            
        end
        
        function setAccel(obj, accel)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            obj.m_accel = accel;
        end
        
        function activate(obj)
            obj.m_active = true;
        end
        
        function deactivate(obj)
            obj.m_active = false;
        end
    end
end

