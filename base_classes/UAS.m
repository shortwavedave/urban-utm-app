classdef UAS < handle & matlab.mixin.Heterogeneous
    %UAS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        ID;
        m_time_step = 0;
    end
    
    methods
        function obj = UAS(ID)
            %UAS Construct an instance of this class
            %   Detailed explanation goes here
            obj.ID = ID;
        end
    end
    
    methods(Access=public, Abstract)
        chooseAction(obj, action_handle)

        acceptPercept(obj, percept_handle)
    end
    
    methods(Sealed)
        function updateTime(obj)
           obj.m_time_step = obj.m_time_step + 1;
        end
        
        function ntfyChooseAction(obj, action_handle)
            obj.chooseAction(action_handle);
        end
        
        function ntfyAcceptPercept(obj, percept_handle)
            obj.acceptPercept(percept_handle);
        end
    end
end

