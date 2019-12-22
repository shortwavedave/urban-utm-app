function yk = PIDControl(obj, ykm1, ek, ekm1, ekm2)
    %PICONTROLLER Summary of this function goes 
    %   Detailed explanation goes here
    Kp = obj.m_Kp;
    Kd = obj.m_Kd;
    Ki = obj.m_Ki;
    yk = ek*(Kp + Ki + Kd) - ekm1*(Kp+2*Kd) + ekm2*Kd + ykm1;
end
