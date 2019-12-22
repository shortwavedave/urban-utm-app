classdef MultiLaneSimRunner < handle
    %MULTILANESIMRUNNER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        m_lanes
        m_uas
        m_utm
        trace = [];
        m_plot_xlim = [-5,25]
        m_plot_ylim = [-5,15]
    end
    
    methods
        function obj = MultiLaneSimRunner()
            %MULTILANESIMRUNNER Construct an instance of this class
            %   Detailed explanation goes here
            
        end
        
        initialize(obj)
        
        baduas = initialize_dddas(obj, utm_hw)
        
        function runSim(obj, steps)
            obj.m_utm.stepTime(0,steps);
        end
        
        function recordTrace(obj, src, ~)
            X = 1;
            Y = 2;
            C = 3;
            F = 4;
            D = 5;
            obj.trace(src.time_step, :, X) = src.m_state.positions_k(X,:);
            obj.trace(src.time_step, :, Y) = src.m_state.positions_k(Y,:);
            obj.trace(src.time_step, :, C) = [src.UASs.m_contingency];
            obj.trace(src.time_step, :, F) = [src.UASs.m_forced_contingency];
            obj.trace(src.time_step, :, D) = [src.UASs.m_done];
            obj.trace(src.time_step, ~[src.UASs.m_active], X) = nan;
        end
        
        plotTrace(obj, period, highlight, record)
    end
end

