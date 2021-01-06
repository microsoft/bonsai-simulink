%% Thermal Model of a House

% clear;
% close all;
% clc;

%% Initalize Parameters
init_vars

%% Benchmark
initToutdoor = 60;
sim('buildingEnergyManagement')

metric_mae = mean(abs(simout(:, 2) - simout(:, 1)));
disp(['Mean Absolute Error = ', num2str(metric_mae), 'F'])
disp(['Cost = $', num2str(simout(end, 4))]) 

plot_results(tout, simout)

%% Benchmark Hot Day
initToutdoor = 95;
sim('buildingEnergyManagement')

metric_mae = mean(abs(simout(:, 2) - simout(:, 1)));
disp(['Mean Absolute Error = ', num2str(metric_mae), 'F'])
disp(['Cost = $', num2str(simout(end, 4))]) 

plot_results(tout, simout)

%% Benchmark Cold Day
initToutdoor = 35;
sim('buildingEnergyManagement')

metric_mae = mean(abs(simout(:, 2) - simout(:, 1)));
disp(['Mean Absolute Error = ', num2str(metric_mae), 'F'])
disp(['Cost = $', num2str(simout(end, 4))]) 

plot_results(tout, simout)

%% Functions
function [] = plot_results(tout, simout)
    figure('Position',  [100, 100, 600, 800]); 
    hold all

    subplot(4,1,1)
    plot(tout, simout(:, 4),'b','linewidth',2)
    grid, title('Cost'), ylabel('Cost [$]')
    ylim([0 30]); xlim([0 24])

    subplot(4,1,2)
    plot(tout, simout(:, 1),'k--','linewidth',1.5)
    hold on
    plot(tout, simout(:, 2),'b','linewidth',2)
    hold off
    legend('Tset', 'Troom','Location','best')
    ylim([50 95]); xlim([0 24])
    grid, title('Indoor Temperature'), ylabel('Temperature [\circF]')

    subplot(4,1,3)
    plot(tout, simout(:, 3),'k-.','linewidth',1.5)
    hold on
    plot(tout, simout(:, 2),'b','linewidth',2)
    hold off
    legend('Toutdoor', 'Troom','Location','best')
    grid, title('Outdoor Temperature'), ylabel('Temperature [\circF]')
    ylim([15 115]); xlim([0 24])
    
    subplot(4,1,4)
    plot(tout, simout(:, 5),'.b','linewidth',2)
    ylim([1 3]); xlim([0 24])
    yticks([1 2 3])
    title('Action')
    yticklabels({'AC','Heater','Off'})
    xlabel('Hours')
    
    set(findall(gcf,'-property','FontSize'),'FontSize',16)
    set(findobj(gcf,'type','legend'),'FontSize',12);
end
