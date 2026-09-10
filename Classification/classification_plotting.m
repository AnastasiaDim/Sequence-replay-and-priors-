addpath('C:\Users\asus\Desktop\Toolboxes\slanCM\slanCM')
addpath('/home/uranus/Scaricati/eeglab_current/eeglab2025.0.0')
addpath('/home/pnc/Downloads/github_repo')
addpath('/home/uranus/Scaricati/PyColormap4Matlab-master')
addpath('C:\Users\asus\Desktop\Toolboxes\fieldtrip-20220707\fieldtrip-20220707')
addpath('/media/uranus/Elements/ANALYSIS/Replay_paper/Results/visual')
%% making the image on fthe sequence effect of classificaiton accuracy 

data1 = xlsread('accuracy_scores_faces_final.xlsx')
data2 = xlsread('accuracy_scores_scenes_final.xlsx')
data3 = xlsread('accuracy_scores_bodies_final.xlsx')
data4 = xlsread('accuracy_scores_tools_final.xlsx')
data5 = xlsread('accuracy_scores_scr_final.xlsx')
data1 = xlsread('accuracy_scores_face_motor.xlsx')
data2 = xlsread('accuracy_scores_scene_motor.xlsx')
data3 = xlsread('accuracy_scores_body_motor.xlsx')
data4 = xlsread('accuracy_scores_tool_motor.xlsx')
data5 = xlsread('accuracy_scores_scr_motor.xlsx')

[~, time_tools_max] = max(data_tools_vis);
[~, time_scenes_max] = max(data_scenes_vis);
[~, time_body_max] = max(data_body_vis);
[~, time_face_max] = max(data_face_vis);
[~, time_scr_max] = max(data_scr_vis(:,1:80));

[~, time_scr_max] = max(data_scr(1:80));
blue    = [0, 0.4470, 0.7410];
yellow  =  [0.8500, 0.3250, 0.0980];

red     = [0.8500, 0.3250, 0.0980];
green   = [0.4660, 0.6740, 0.1880];
purple  = [0.4940, 0.1840, 0.5560];
cmap = getPyPlot_cMap('RdBu',50); 

time_points1 = -0.499:0.01:0.5 %visual
time_points2 = -0.5:0.01:0.699 %motor
faceColor      = [0.867 0.518 0.322];
bodyColor      = [0.576 0.322 0.263];
scrambledColor = [0.431 0.235 0.380];
sceneColor     = [0.310 0.361 0.604];
toolColor      = [0.373 0.584 0.835];  % neutral grey/white
% Plot the shaded error bars and capture the main line handles
h1 = shadedErrorBar(time_points, mean(data1), std(data1)/sqrt(41), {'color', faceColor, 'LineWidth', 1.5 }, 0.8);
hold on;
h2 = shadedErrorBar(time_points, mean(data2), std(data2)/sqrt(41), {'color',sceneColor , 'LineWidth', 1.5 }, 0.8);
hold on;
h3 = shadedErrorBar(time_points, mean(data3), std(data3)/sqrt(41), {'color', bodyColor, 'LineWidth', 1.5 }, 0.8);
hold on;
h4 = shadedErrorBar(time_points, mean(data4), std(data4)/sqrt(41), {'color',toolColor, 'LineWidth', 1.5 }, 0.8);
hold on;
h5 = shadedErrorBar(time_points, mean(data5), std(data5)/sqrt(41), {'color', scrambledColor, 'LineWidth', 1.5 }, 0.8);

% Add the legend using the main lines only
legend([h1.mainLine, h2.mainLine, h3.mainLine, h4.mainLine, h5.mainLine], {'Face', 'Scene', 'Body', 'Tool', 'Scrambled'}, 'Location', 'best');
% Add horizontal line at y=0
%xline(0, 'k--', 'LineWidth', 1.5,'HandleVisibility', 'off');  % Black dashed line at zero

% Set thick black axes border
%ax = gca;  % Current axes handle
%set(ax, 'LineWidth', 2, 'XColor', 'k', 'YColor', 'k');  % Thicker black border
box on;  % Show full box around plot

% Optional: make ticks more visible
%set(gca, 'FontSize', 12, 'TickDir', 'out');
 xlim([-0.2, max(time_points1)])
  ylim([0.45,0.7])
axis square

%% Seqeunce visual motor 

data1 = xlsread('accuracy_scores_faces_final.xlsx')
data2 = xlsread('accuracy_scores_scenes_final.xlsx')
data3 = xlsread('accuracy_scores_bodies_final.xlsx')
data4 = xlsread('accuracy_scores_tools_final.xlsx')
data5 = xlsread('accuracy_scores_scr_final.xlsx')


 data6 = mean(xlsread('accuracy_scores_face_motor.xlsx'))
 data7 = mean(xlsread('accuracy_scores_scene_motor.xlsx'))
 data8 = mean(xlsread('accuracy_scores_body_motor.xlsx'))
 data9 = mean(xlsread('accuracy_scores_tool_motor.xlsx'))
 data10 = mean(xlsread('accuracy_scores_scr_motor.xlsx'))



data_scenes = mean(data2)
data_body =mean(data3)
data_face = mean(data1)
data_scr = mean(data5)
data_tools = mean(data4)

std_face = std(data1)
std_scene = std(data2)
std_tool = std(data4)
std_body = std(data3)
 std_scr = std(data5)

 all_data = cat(3, data_face, data_body, data_scenes, data_tools, data_scr);
all_data_motor = cat(3, data6, data7, data8, data9, data10);

%% Means
average_timeseries = mean(all_data, 3);
average_timeseries_motor = mean(all_data_motor, 3);

%% SDs
sd_visual = std(all_data, 0, 3);
sd_motor  = std(all_data_motor, 0, 3);

acc = mean(xlsread('accuracy__sequence.xlsx'));
acc_sd = std(xlsread('accuracy__sequence.xlsx'));

%% Normalize means
vis_norm = (average_timeseries - min(average_timeseries)) ./ ...
           (max(average_timeseries)-min(average_timeseries));

seq_norm = (acc - min(acc)) ./ ...
           (max(acc)-min(acc));

motor_norm = (average_timeseries_motor - min(average_timeseries_motor)) ./ ...
             (max(average_timeseries_motor)-min(average_timeseries_motor));


%% Shift motor
meanRT = 0.4;
time_points_motor_shifted = time_points + meanRT;

%% Plot
%% Calculate SEM errors

N_visual = size(all_data, 3);
N_motor  = size(all_data_motor, 3);
N_seq    = size(accuracy_data, 1);

vis_err = sd_visual ./ sqrt(N_visual) ./ ...
          (vis_max - vis_min);

motor_err = sd_motor ./ sqrt(N_motor) ./ ...
            (motor_max - motor_min);

seq_err = acc_sd ./ sqrt(N_seq) ./ ...
          (seq_max - seq_min);
visColor   = [0.20 0.60 0.70];   % turquoise
seqColor   = [0.60 0.45 0.70];   % lavender
motorColor = [0.75 0.60 0.20];   % olive-golddark mustard  % same orange as Faces
h1 = shadedErrorBar(time_points1, vis_norm, vis_err, ...
    {'Color', visColor, 'LineWidth', 1.5}, 0.08);
hold on

h2 = shadedErrorBar(time_points1, seq_norm, seq_err, ...
    {'Color', seqColor, 'LineWidth', 1.5}, 0.08);
hold on

h3 = shadedErrorBar(time_points_motor_shifted, motor_norm, motor_err, ...
    {'Color', motorColor, 'LineWidth', 1.5}, 0.08);

% Remove patch edges
set([h1.patch h2.patch h3.patch], 'EdgeColor', 'none')

xlabel('Time (s)')
ylabel('Normalized Accuracy (0–1)')

legend([h1.mainLine, h2.mainLine, h3.mainLine], ...
       {'Visual Decoding', 'Sequence Decoding', 'Motor Decoding'}, ...
       'Location', 'northwest', ...
       'Box', 'on');

box on
axis square
xlim([-0.1, 0.7])

%% Plotting random versus seqeunce classification 
data11 = xlsread('accuracy_scores_faces_final.xlsx')
data12 = xlsread('accuracy_scores_scenes_final.xlsx')
data13 = xlsread('accuracy_scores_bodies_final.xlsx')
data14 = xlsread('accuracy_scores_tools_final.xlsx')
data15 = xlsread('accuracy_scores_scr_final.xlsx')

data16 = xlsread('accuracy_scores_faces_final_sequence.xlsx')
data17 = xlsread('accuracy_scores_scenes_final_sequence.xlsx')
data18 = xlsread('accuracy_scores_bodies_final_sequence.xlsx')
data19 = xlsread('accuracy_scores_tools_final_sequence.xlsx')
data20 = xlsread('accuracy_scores_scr_final_sequence.xlsx')


data_scenes_randv = mean(data12)
data_body_randv =mean(data13)
data_face_randv = mean(data11)
data_scr_randv = mean(data15)
data_tools_randv = mean(data14)
std_face_randv = std(data11)
std_scene_randv = std(data12)
std_tool_randv = std(data14)
std_body_randv = std(data13)
 std_scr_randv = std(data15)

data_scenes_seqv = mean(data17)
data_body_seqv =mean(data18)
data_face_seqv = mean(data16)
data_scr_seqv = mean(data20)
data_tools_seqv = mean(data19)
std_face_seqv = std(data16)
std_scene_seqv = std(data17)
std_tool_seqv = std(data19)
std_body_seqv = std(data18)
std_scr_seqv = std(data20)

figure;

% Choose a colormap (e.g., 'Spectral') with 15 distinct colors
cmap= getPyPlot_CMap('RdBu',50)

lineWidth = .5;

subplot(3, 5, 1);

plot(time_points1, data_face_randv, 'DisplayName', 'Face_Random', 'Color', cmap(13,:), 'LineWidth', lineWidth);
hold on
plot(time_points1, data_face_seqv, "--",'DisplayName', 'Face_Sequence', 'Color', cmap(13,:), 'LineWidth', lineWidth);
title('Face Visual');
box on;
grid on;
hold on 
% legend('show')
xticks(-0.5:0.25:0.5);


subplot(3, 5, 3);

plot(time_points1, data_scenes_randv, 'DisplayName', 'Scene_Random', 'Color', cmap(25,:), 'LineWidth', lineWidth);
hold on 
plot(time_points1, data_scenes_seqv,"--", 'DisplayName', 'Scene_Sequence', 'Color', cmap(25,:), 'LineWidth', lineWidth);
title('Scene Motor');
box on;
grid on;
hold on 
% legend('show')
%xlim([-0.4, max(time_points)])


subplot(3, 5, 6);
plot(time_points1, data_body_randv, 'DisplayName', 'Body_Random', 'Color', cmap(50,:), 'LineWidth', lineWidth);
hold on
plot(time_points1, data_body_seqv, "--",'DisplayName', 'Body_Sequence', 'Color', cmap(50,:), 'LineWidth', lineWidth);
title('Body Motor');
box on;
grid on;
hold on 
% legend('show')
%xlim([-0.4, max(time_points)])

subplot(3, 5, 9);
plot(time_points1, data_tools_randv, 'DisplayName', 'Tool_Random', 'Color', cmap(1,:), 'LineWidth', lineWidth);
hold on 
plot(time_points1, data_tools_seqv, "--",'DisplayName', 'Tool_Sequence', 'Color', cmap(1,:), 'LineWidth', lineWidth);
title('Tool Visual');
box on;
grid on;
hold on 
% legend('show')
%xticks(-0.5:0.25:0.5);

subplot(3, 5, 13);
plot(time_points1, data_scr_randv, 'DisplayName', 'Scrambled_Random', 'Color', cmap(40,:), 'LineWidth', lineWidth);
hold on 
plot(time_points1, data_scr_seqv,"--", 'DisplayName', 'Scrambled_Sequence', 'Color', cmap(40,:), 'LineWidth', lineWidth);
xlim([-0.5, max(time_points1)])
xticks(-0.5:0.25:0.5);


title('Scrambled Visual');
box on;
grid on;
hold on 

%% Classification weights

hyper_face = zeros(41,256)
hyper_body = zeros(41,256)
hyper_tool = zeros(41,256)
hyprt_scr  = zeros(41,256)
hyper_scene = zeros(41,256)
matrix_similarities = zeros(5,5,41);

hyper_sequence_early =  zeros(41,256)
hyper_sequence_late =  zeros(41,256)


k=1


for id = 1:43
    if id == 10 || id == 41 || id == 29 
        continue 
    end 
id = num2str(id);
data_faces = xlsread(['P',id,'_weights_faces.xlsx'])
data_scenes = xlsread(['P',id,'_weights_scenes.xlsx'])
data_tools  = xlsread(['P',id,'_weights_tools.xlsx'])
data_body = xlsread(['P',id,'_weights_bodies.xlsx'])
data_scrambled = xlsread(['P',id,'_weights_scr.xlsx'])


  data_faces = data_faces(66,:);
  data_scenes = data_scenes(69,:);
  data_body = data_body(70,:);
  data_tools =data_tools(70,:)
  data_scrambled = data_scrambled(70,:)

 hyper_face(k,:) = data_faces
 hyper_body(k,:) = data_body
 hyper_scene(k,:) = data_scenes
 hyper_tool(k,:) = data_tools
 hyper_scrambled(k,:) = data_scrambled



% Concatenate data for each category column-wise (one vector per category)
 data_matrix = [data_faces(:), data_scenes(:), data_body(:), data_tools(:), data_scrambled(:)];

% % Initialize the cosine similarity matrix
 num_categories = size(data_matrix, 2);  % Number of categories (5 in this case)
 cosine_similarity_matrix = zeros(num_categories, num_categories);  % 5x5 matrix
% 
% % Calculate cosine similarity between each pair of categories (column vectors)
for i = 1:num_categories
    for j = 1:num_categories
        % Cosine similarity between i-th and j-th category
        cosine_similarity_matrix(i, j) = dot(data_matrix(:,i), data_matrix(:,j)) / ...
            (norm(data_matrix(:,i)) * norm(data_matrix(:,j)));
    end
end
% 
% % Store 
matrix_similarities(:,:,k) = cosine_similarity_matrix;
% 
% % Plot the cosine similarity matrix
% figure(2);
% imagesc(cosine_similarity_matrix);
% colorbar;
% 
% 
% xticks(1:num_categories);
% yticks(1:num_categories);
% xticklabels({'Face', 'Scene', 'Body', 'Tool'});
% yticklabels({'Face', 'Scene', 'Body', 'Tool'});
% axis square;
% cmap = getPyPlot_cMap('coolwarm'); % Choose a colormap (e.g., 'parula') with 5 distinct colors
% colormap(cmap)
% filename = ['P',id,'cosine_similarity_weights_motor.png']
% saveas(gcf,filename)
 k= k+1;
end 

average_simialrity = mean(matrix_similarities,3);
h= heatmap(average_simialrity)
labels = {'Face', 'Scene', 'Body', 'Tool','Scrambled'}
h.XDisplayLabels = labels;
h.YDisplayLabels = labels;
print(gcf,'cosine_matrix_motor.png','-dpng','-r300')

figure(2);
imagesc(average_simialrity);
colorbar;

xticks(1:num_categories);
yticks(1:num_categories);
xticklabels({'Face', 'Scene', 'Body', 'Tool','Scrambled'});
yticklabels({'Face', 'Scene', 'Body', 'Tool','Scrambled'});
axis square;
cmap = getPyPlot_cMap('RdBu_r'); % i need a colormap meaned at 0
colormap(cmap)
caxis([-0.1,0.1])

hyper_face_avg = mean(hyper_face,1)
hyper_body_avg = mean(hyper_body,1)
hyper_scene_avg = mean(hyper_scene,1)
hyper_tool_avg = mean(hyper_tool,1)
hyper_scrambled_avg = mean(hyper_scrambled,1)
avg_weight = (hyper_face_avg+hyper_body_avg+hyper_scene_avg+hyper_tool_avg+hyper_scrambled_avg) / 5


hyper_seq_early = mean(hyper_sequence_early,1)
hyper_seq_late = mean(hyper_sequence_late,1)

load('/media/uranus/Elements/ANALYSIS/Study_1/Channel_analysis/final_datastes/categorties/chanlocs.mat')

[y,x] = pol2cart(pi*[chanlocs(:).theta]/180,[chanlocs(:).radius]);
Rd = max([chanlocs(:).radius]);
plotrad = min(1.0,max(Rd)*1.02);
plotrad = max(plotrad,0.5);
 
x =  x * 0.5 / plotrad;
y =  y * 0.5 / plotrad;

figure('Position', [100, 100, 1500, 800]); % Adjust figure size as needed

% First subplot
subplot('Position', [0.05, 0.55, 0.3, 0.5]); % [left, bottom, width, height]
topoplot([], chanlocs, 'style', 'blank');
hold on;
scatter(x, y, 120, hyper_face_avg, 'filled');
title('Face'); % Title for the first plot
cmap = getPyPlot_cMap('coolwarm');
caxis([-0.1,0.1])
colormap(cmap);
print(gcf,'scr_motorcolor.png','-dpng','-r300')

% Second subplot
subplot('Position', [0.37, 0.55, 0.3, 0.5]); % [left, bottom, width, height]
topoplot([], chanlocs, 'style', 'blank');
hold on;
scatter(x, y, 120, hyper_scene_avg, 'filled');
title('Scene'); % Title for the second plot
caxis([-0.1,0.1])
colormap(cmap);



% Third subplot
subplot('Position', [0.69, 0.55, 0.3, 0.5]); % [left, bottom, width, height]
topoplot([], chanlocs, 'style', 'blank');
hold on;
scatter(x, y, 120, hyper_body_avg, 'filled');
title('Body'); % Title for the third plot
cmap = getPyPlot_cMap('RdBu_r'); % i need a colormap meaned at 0
colormap(cmap)


% Fourth subplot
subplot('Position', [0.2, 0.05, 0.3, 0.5]); % [left, bottom, width, height]
topoplot([], chanlocs, 'style', 'blank');
hold on;
scatter(x, y, 120, hyper_tool_avg, 'filled');
title('Tool'); % Title for the fourth plot

% Fifth subplot
subplot('Position', [0.52, 0.05, 0.28, 0.5]); % [left, bottom, width, height]
topoplot([], chanlocs, 'style', 'blank');
hold on;
scatter(x, y, 120, hyper_scrambled_avg, 'filled');
title('Scrambled'); % Title for the fifth plot

% Apply colormap
cmap = getPyPlot_cMap('RdBu_r');
colorbar% Choose a colormap (e.g., 'paru') with 5 distinct colors
colormap(cmap);
caxis([-0.2,0.2])


data = rand(1,10)
h = heatmap(data)

cmap = getPyPlot_cMap('GnBu_r');
colorbar% Choose a colormap (e.g., 'paru') with 5 distinct colors
colormap(cmap);
l = {'State 1', 'State 2', 'State 3','State 4','State 5'}
h.XDisplayLabels(l)

