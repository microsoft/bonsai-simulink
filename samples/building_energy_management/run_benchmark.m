%% Thermal Model of a House

clear;
close all;
clc;

%% Initalize Parameters

n_rooms =  1;
nWindows_room1 = 6;
nWindows_room2 = 6;
nWindows_room3 = 6;

init_vars

%% Benchmark

initToutdoor = 60;
disp('~~~~Normal Day~~~~')

sim('buildingEnergyManagement.slx')
for i = 1:n_rooms
    mae(simout(:, i+1), simout(:, 1), i);
end
disp(['Cost = $', num2str(round(simout(end, 7), 2))])
fprintf('\n')

plot_results(tout, simout, 'Benchmark on Normal Day', n_rooms)

input('Press ''Enter'' to continue...','s');
fprintf('\n')

%% Benchmark Hot Day


initToutdoor = 95;
disp('~~~~Hot Day~~~~')

sim('buildingEnergyManagement.slx')

for i = 1:n_rooms
    mae(simout(:, i+1), simout(:, 1), i);
end
disp(['Cost = $', num2str(round(simout(end, 7), 2))])
fprintf('\n')

plot_results(tout, simout, 'Benchmark on Hot Day', n_rooms)

input('Press ''Enter'' to continue...','s');
fprintf('\n')

%% Benchmark Cold Day

initToutdoor = 35; %[F]
disp('~~~~Cold Day~~~~')

sim('buildingEnergyManagement.slx')

for i = 1:n_rooms
    mae(simout(:, i+1), simout(:, 1), i);
end
disp(['Cost = $', num2str(round(simout(end, 7), 2))])
fprintf('\n')

plot_results(tout, simout, 'Benchmark on Cold Day', n_rooms)

input('Press ''Enter'' to continue...','s');
fprintf('\n')

%% Vary Windows with 1 Room for Normal Day

n_rooms =  1;
disp('~~~~Vary # of Windows for 1 Room~~~~')

figure
for n_windows = 1:length(linspace(1, 12, 12))
    nWindows_room1 = n_windows;
    init_vars
    disp(['nWindows_room1 = ', num2str(n_windows)])
    
    initToutdoor = 60;
    sim('buildingEnergyManagement.slx')

    for i = 1:n_rooms
        metric_mae = mae(simout(:, i+1), simout(:, 1), i);
    end
    disp(['Cost = $', num2str(round(simout(end, 7), 2))])
    fprintf('\n')
    yyaxis left
    scatter(n_windows, simout(end, 7), 'filled')
    ylabel('cost [$]')
    yyaxis right
    scatter(n_windows, metric_mae, 'filled')
    ylabel('Tin mean absolute error [K]')
    hold on
end
hold off
xlabel('number of windows')
fprintf('\n')

input('Press ''Enter'' to continue...','s');
fprintf('\n')

%% Vary Windows with 3 Room for Normal Day

n_rooms =  3;
disp('~~~~Vary Windows with 3 Rooms for Normal Day~~~~')

nWindows_room1 = 3;
nWindows_room2 = 6;
nWindows_room3 = 12;

initToutdoor = 60;
sim('buildingEnergyManagement.slx')

for i = 1:n_rooms
    mae(simout(:, i+1), simout(:, 1), i);
end
disp(['Cost = $', num2str(round(simout(end, 7), 2))]) 

plot_results(tout, simout, 'Vary Windows with 3 Rooms for Normal Day', n_rooms)
fprintf('\n')

input('Press ''Enter'' to continue...','s');
fprintf('\n')

%% Vary Windows with 3 Room for Hot Day

n_rooms =  3;
disp('~~~~Vary Windows with 3 Rooms for Hot Day~~~~')

nWindows_room1 = 3;
nWindows_room2 = 6;
nWindows_room3 = 12;

initToutdoor = 95;
sim('buildingEnergyManagement.slx')

for i = 1:n_rooms
    mae(simout(:, i+1), simout(:, 1), i);
end
disp(['Cost = $', num2str(round(simout(end, 7), 2))]) 

plot_results(tout, simout, 'Vary Windows with 3 Rooms for Hot Day', n_rooms)
fprintf('\n')

input('Press ''Enter'' to continue...','s');
fprintf('\n')

%% Vary Windows with 3 Room for Cold Day

n_rooms =  3;
disp('~~~~Vary Windows with 3 Rooms for Cold Day~~~~')

nWindows_room1 = 3;
nWindows_room2 = 6;
nWindows_room3 = 12;

initToutdoor = 35;
sim('buildingEnergyManagement.slx')

for i = 1:n_rooms
    mae(simout(:, i+1), simout(:, 1), i);
end
disp(['Cost = $', num2str(round(simout(end, 7), 2))]) 

plot_results(tout, simout, 'Vary Windows with 3 Rooms for Cold Day', n_rooms)
fprintf('\n')

%% Return values to default

n_rooms =  1;
nWindows_room1 = 6;
nWindows_room2 = 6;
nWindows_room3 = 6;

init_vars

%% Functions

function [] = plot_results(tout, simout, info, n_rooms)
    figure('Position', [100, 100, 600, 800])
    sgtitle(info)
    
    subplot(411)
    plot(tout, simout(:, 7), 'b', 'linewidth',1.5)
    grid, title('Cost'), ylabel('Cost [$]')

    subplot(412)
    plot(tout, simout(:, 1),'--k','linewidth',1.5)
    hold on
    plot(tout, simout(:, 2), 'b', 'linewidth',1.5)
    if n_rooms ~= 1
        plot(tout, simout(:, 3), 'r', 'linewidth',1.5)
        plot(tout, simout(:, 4), 'm', 'linewidth',1.5)
        legend('Tset', 'Troom1', 'Troom2', 'Troom3')
    else
        legend('Tset', 'Troom1')
    end
    hold off
    grid, title(''), ylabel('Temp [\circF]')

    subplot(413)
    plot(tout, simout(:, 6),'--k','linewidth',1.5)
    hold on
    plot(tout, simout(:, 2), 'b', 'linewidth',1.5)
    if n_rooms ~= 1
        plot(tout, simout(:, 3), 'r', 'linewidth',1.5)
        plot(tout, simout(:, 4), 'm', 'linewidth',1.5) 
        legend('Toutdoor', 'Troom1', 'Troom2', 'Troom3')
    else
        legend('Toutdoor', 'Troom1')
    end
    hold off
    grid, title(''), ylabel('Temp [\circF]')
    
    subplot(414)
    plot(tout, simout(:, 9),'.b')
    grid, title('Action')
    xlabel('Hours')
    ylim([1 3]); yticks([1 2 3]); yticklabels({'AC','Heat','Off'})
    
    set(findall(gcf,'-property','FontSize'),'FontSize',12)
    set(findobj(gcf,'type','legend'),'FontSize',12);
end

function [metric_mae] = mae(set, actual, roomnum)
    metric_mae = mean(abs(actual - set));
    disp(['Mean Absolute Error for Room ', num2str(roomnum),' = ', num2str(metric_mae), 'F'])
end