function [total_per_second, forced_per_second, num_done] = measureTrace(trace, baduas, uas, plotit)
%MEASURETRACE Summary of this function goes here
%   Detailed explanation goes here
    X = 1;
    Y = 2;
    C = 3;
    F = 4;
    D = 5;
    num_steps = size(trace,1);
    t = (1:num_steps)*0.1;
    total_contigencies = sum(trace(:,:,C),2);
    total_per_second = sum(total_contigencies) / t(end);
    num_uas = length(uas);
    
    good_uas = setdiff(1:num_uas, baduas);
    num_done = sum(sum(trace(:,:,D)));
    forced_contingencies = sum(trace(:,:,F),2);
    forced_per_second = sum(forced_contingencies) / t(end);
%     plot( t, forced_contingencies);
%     hold on;
%     plot(t, total_contigencies, 'r');
%     hold off;
if (plotit)
    subplot(2,1,1);
    bar(t, total_contigencies,'k','LineWidth',1,'EdgeColor','k');
    xlabel('seconds');
    ylabel('contingencies');
    title('Total Contingencies');
    subplot(2,1,2);
    bar(t, forced_contingencies,'k','LineWidth',1,'EdgeColor','k');
    xlabel('seconds');
    ylabel('contingencies');
    title('Forced Contingencies');
end
%     b = bar(t, [forced_contingencies total_contigencies], 'stacked');
%     b(1).FaceColor = 'w';
%     b(1).EdgeColor = 'k';
%     b(1).LineWidth = 1;
%     
%     b(2).FaceColor = 'r';
%     b(2).EdgeColor = 'r';
%     b(2).LineWidth = 1.5;
   
    %bar(t, [forced_contingencies total_contigencies],'FaceColor',[0 .5 .5],'EdgeColor',[0 .9 .9],'LineWidth',1.5)
end

