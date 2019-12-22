classdef UTM < handle
    %UTM Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        time_step = 0;
        num_UAS = 0;
        UASs;
        action_type;
        percept_type;
        actions;
        percepts;
    end 
    events
        StepTime
        BeforePerceptUpdate
        AfterActionUpdate
    end
    
    methods
        function obj = UTM(action_type, percept_type)
            %UTM Construct an instance of this class
            %   Detailed explanation goes here
            addlistener(obj, "StepTime", @obj.executeTimeStep);
            addlistener(obj, "BeforePerceptUpdate", @obj.updatePercepts);
            addlistener(obj, "AfterActionUpdate", @obj.updateState);
            obj.action_type = action_type;
            obj.percept_type = percept_type;
        end
        
        function registerUAS(obj, UAS)
            obj.UASs = [obj.UASs UAS];
            obj.actions = [obj.actions, obj.action_type()];
            obj.percepts = [obj.percepts, obj.percept_type()];
            obj.num_UAS = obj.num_UAS + 1;
        end

        function time_step = stepTime(obj, delay, steps)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            if steps > 0
                for i = 1:steps
                    obj.time_step = obj.time_step + 1;
                    notify(obj, 'StepTime');
                    if delay < 0
                        disp(['TimeStep: ', num2str(obj.time_step)]);
                        disp('Press any key to continue');
                        pause;
                    elseif delay > 0
                        pause(delay);
                    else
                    end
                end
            else
                warning('steps arg should be positive');
            end
            
            time_step = obj.time_step;
        end
        
        function executeTimeStep(obj,src,evnt)
            notify(obj, 'BeforePerceptUpdate');
            for i=1:length(obj.UASs)
                obj.UASs(i).updateTime();
                obj.UASs(i).ntfyAcceptPercept(obj.percepts(i));
%             end
%             parfor i=1:length(obj.UASs)
                obj.UASs(i).ntfyChooseAction(obj.actions(i));
            end
            notify(obj, 'AfterActionUpdate');
        end
        
        function updatePercepts(obj,src,evnt)
           obj.percepts = 0; 
        end
        
        function updateState(obj,src,evnt)
            obj.actions = 0;
        end
    end
end

