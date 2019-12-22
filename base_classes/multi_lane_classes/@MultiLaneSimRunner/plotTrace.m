function plotTrace(obj, period, highlight, record)
    has_highlight = false;
    if nargin < 3
        highlight = [];
        normal = 1:size(obj.trace,2);
    else
        has_highlight = true;
        normal = 1:size(obj.trace,2);
        normal = setdiff(normal, highlight);
    end
    
    if nargin < 4
        record = false;
    end
    
    if record
        v = VideoWriter('test.avi');
        v.Quality = 95;
        v.FrameRate = 45;
        open(v);
    end
    
    obj.m_lanes.plotLanesQuiver();
    trace_len = size(obj.trace, 1);
    X = 1;
    Y = 2;

    xlim(obj.m_plot_xlim);
    ylim(obj.m_plot_ylim);

    
    for i = 1:trace_len
        if (has_highlight)
            xh = obj.trace(i,highlight,X);
            yh = obj.trace(i,highlight,Y);
        end
        xp = obj.trace(i,normal,X);
        yp = obj.trace(i,normal,Y);
        if (i == 1)
            hold on;
            h = scatter(xp,yp,100,'b','LineWidth',2);
            if (has_highlight)
                hh = scatter(xh,yh,100,'r','LineWidth',2);
            end
            axis equal; 
            hold off;
            legend('Lane','UAS');
        else
            set(h,'XData',xp,'YData',yp);
            if (has_highlight)
                set(hh,'XData',xh,'YData',yh);
            end
            
        end
        hold on
        xlim(obj.m_plot_xlim);
        ylim(obj.m_plot_ylim);
        hold off;
        drawnow;
        if record
            frame = getframe(gcf);
            writeVideo(v,frame);
        end
       % pause(period);
    end
    
    if record
        close(v);
    end
end