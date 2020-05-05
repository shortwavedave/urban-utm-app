classdef TelloBDIAgent < TelloRCAgent
    %TELLOBDIAGENT Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        faceDetector
    end
    
    methods
        function agent = TelloBDIAgent(id)
            %TELLOBDIAGENT Construct an instance of this class
            %   Detailed explanation goes here
            agent = agent@TelloRCAgent(id);
            addlistener(agent, 'ROSInitialized', @agent.initBdi);
            if agent.m_initialized
                agent.initBdi()
            end
            
            agent.faceDetector = AgentFaceDetector();
            agent.addImageTransform(@(im) agent.faceDetector.overlayDetect(im));
        end
        
        
        function initBdi(agent, ~, ~)
        end
        
    end
end

