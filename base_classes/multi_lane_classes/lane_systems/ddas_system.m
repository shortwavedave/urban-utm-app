function lane_sys = ddas_system(segment_len, w)
%DDAS_SYSTEM Summary of this function goes here
%   Detailed explanation goes here
    %segment_len = 10;
    %w = 10;
    lane_sys = [];
    
    X0 = 1;
    Xf = 2;
    right = segment_len*[[0,0]', [1,0]'];
    up = segment_len*[[0,0]', [0,1]'];
    down = segment_len*[[0,0]', [0,-1]'];
    hi = 1;
    vi = 2;
    
    function ls = horiz(t)
        mr = right + t;
        tr = right + t + segment_len*[1, 1]';
        br = right + t + segment_len*[1, -1]'; 
        
        l3 = Lane( mr(:,X0), mr(:,Xf) );
        l3.m_id = hi;
        l3.m_x0str = ( [num2str(mr(1,X0)), num2str(mr(2,X0))] );
        l3.m_xfstr = ( [num2str(mr(1,Xf)), num2str(mr(2,Xf))] );
        hi = hi + 2;
        
        l4 = Lane( tr(:,X0), tr(:,Xf) );
        l4.m_id = hi;
        l4.m_x0str = ( [num2str(tr(1,X0)), num2str(tr(2,X0))] );
        l4.m_xfstr = ( [num2str(tr(1,Xf)), num2str(tr(2,Xf))] );
        hi = hi + 2;
        
        l5 = Lane( br(:,X0), br(:,Xf) );
        l5.m_id = hi;
        l5.m_x0str = ( [num2str(br(1,X0)), num2str(br(2,X0))] );
        l5.m_xfstr = ( [num2str(br(1,Xf)), num2str(br(2,Xf))] );
        hi = hi + 2;
        
        ls = [ l3 l4 l5 ];
    end

    function ls = s1(t)
        u = up + t + [segment_len, 0]';
        d = down + t + [segment_len, 0]';
        
        l1 = Lane( u(:,X0), u(:,Xf) );
        l1.m_id = vi;
        l1.m_x0str = ( [num2str(u(1,X0)), num2str(u(2,X0))] );
        l1.m_xfstr = ( [num2str(u(1,Xf)), num2str(u(2,Xf))] );
        vi = vi + 2;
        
        l2 = Lane( d(:,X0), d(:,Xf) );
        l2.m_id = vi;
        l2.m_x0str = ( [num2str(d(1,X0)), num2str(d(2,X0))] );
        l2.m_xfstr = ( [num2str(d(1,Xf)), num2str(d(2,Xf))] );
        vi = vi + 2;
        
        h = horiz(t);
        
        ls = [ l1 l2 h];
    end

    function ls = s2(t)       
        u = [up(:,Xf),up(:,X0)] + t + [segment_len, 0]';
        d = [down(:,Xf),down(:,X0)] + t + [segment_len, 0]';

        l1 = Lane( u(:,X0), u(:,Xf) );
        l1.m_id = vi;
        l1.m_x0str = ( [num2str(u(1,X0)), num2str(u(2,X0))] );
        l1.m_xfstr = ( [num2str(u(1,Xf)), num2str(u(2,Xf))] );
        vi = vi + 2;
        
        l2 = Lane( d(:,X0), d(:,Xf) );
        l2.m_id = vi;
        l2.m_x0str = ( [num2str(d(1,X0)), num2str(d(2,X0))] );
        l2.m_xfstr = ( [num2str(d(1,Xf)), num2str(d(2,Xf))] );
        vi = vi + 2;
        
        h = horiz(t);
        
        ls = [ l1 l2 h];
    end
    
    % Make the main box
    t = [0 0]';
    for wi = 1:w
        if ( mod(wi,2) == 1 )
            ls = s1(t);
        else
            ls = s2(t);
        end
        t = t + [segment_len, 0]';
        lane_sys = [lane_sys, ls];
    end
    
end

