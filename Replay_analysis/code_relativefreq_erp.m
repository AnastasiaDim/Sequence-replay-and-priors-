%% ERP REPLAY 
%% GRAND AVERAGE ERP
clear;
close all;
clc;

data_path = '/media/uranus/Elements/ANALYSIS/Replay_paper/time_frequency/final_revision/allegati (4)/visual_forward';

n_subjects = 43;
exclude_subjects = [10 29 41];

all_subjects = [];
r = 1;

%% Load all participants

for k = 1:n_subjects

    if ismember(k, exclude_subjects)
        continue
    end

    fprintf('Loading subject %d...\n', k);

    [ALLEEG, EEG, CURRENTSET, ALLCOM] = eeglab;

    dataset = ['sub', num2str(k), '.set'];

    EEG = pop_loadset( ...
        'filename', dataset, ...
        'filepath', data_path);

    % ----------------------------------
    % Average trials within participant
    % ----------------------------------
    subj_average = mean(EEG.data, 3);

    % dimensions:
    % channels x time

    % ----------------------------------
    % Store participant
    % ----------------------------------
    all_subjects(:, :, r) = subj_average;

    % Save channel locations and time
    if r == 1
        chanlocs = EEG.chanlocs;
        times = EEG.times;
    end

    r = r + 1;

end


%% GRAND AVERAGE ACROSS PARTICIPANTS

% dimensions:
% channels x time

grand_average = mean(all_subjects, 3);

fprintf('Grand average size:\n');
disp(size(grand_average));


%% ==========================================
% FIGURE 1: GRAND AVERAGE — ALL CHANNELS
% ===========================================

figure;
plot(times, grand_average', 'LineWidth', 1);

xlabel('Time (ms)');
ylabel('Amplitude (\muV)');
title('Grand-average ERP — all channels');

xline(0, '--');

grid on;
box off;


%% ==========================================
% FIGURE 2: TOPOGRAPHIES EVERY 20 ms
% ===========================================

% Choose the time points you want
topo_times = 0:20:100;

figure;

for i = 1:length(topo_times)

    % Find closest actual EEG time point
    [~, time_idx] = min(abs(times - topo_times(i)));

    subplot(2, 3, i);

    topoplot( ...
        grand_average(:, time_idx), ...
        chanlocs, ...
        'electrodes', 'on');

    title(sprintf('%d ms', round(times(time_idx))));

end

sgtitle('Grand-average scalp topographies');

%% TIME FREQUENCY 
r = 1;   

for k = 1:43

    if k==10 || k==29 || k==41
        continue
    end

    subj = k;

    [ALLEEG EEG CURRENTSET ALLCOM] = eeglab;

    dataset = ['sub', num2str(subj), '.set'];

    EEG = pop_loadset('filename', dataset);
    [ALLEEG, EEG, CURRENTSET] = eeg_store(ALLEEG, EEG, 0);


    %% Split data into pre and post

    data_pre  = EEG.data(:, 1:100, :);
    data_post = EEG.data(:, 101:200, :);



    %% Spectra

    [spectra_pre,freqs] = spectopo(data_pre,0,EEG.srate,'plot','off');
    spectra_pre_abs = 10.^(spectra_pre/10);


    [spectra_post,~] = spectopo(data_post,0,EEG.srate,'plot','off');
    spectra_post_abs = 10.^(spectra_post/10);



    %% Frequency indices

    alphaIdx = find(freqs>10 & freqs<=15);

    betaIdx = find(freqs>15 & freqs<=30);

    % Low gamma
    lowGammaIdx = find(freqs>30 & freqs<=45);

    % High gamma
    highGammaIdx = find(freqs>45 & freqs<=100);

    % Ripple
    rippleIdx1 = find(freqs>100 & freqs<=120);
    rippleIdx2 = find(freqs>120 & freqs<=150);
    rippleIdx = [rippleIdx1 rippleIdx2];



    %% Power extraction

    % Alpha
    alpha_pre  = trapz(spectra_pre_abs(:,alphaIdx),2);
    alpha_post = trapz(spectra_post_abs(:,alphaIdx),2);


    % Beta
    beta_pre  = trapz(spectra_pre_abs(:,betaIdx),2);
    beta_post = trapz(spectra_post_abs(:,betaIdx),2);


    % Low gamma 30-45 Hz
    lowGamma_pre  = trapz(spectra_pre_abs(:,lowGammaIdx),2);
    lowGamma_post = trapz(spectra_post_abs(:,lowGammaIdx),2);


    % High gamma 45-100 Hz
    highGamma_pre  = trapz(spectra_pre_abs(:,highGammaIdx),2);
    highGamma_post = trapz(spectra_post_abs(:,highGammaIdx),2);


    % Ripple 100-150 Hz
    ripple_pre  = trapz(spectra_pre_abs(:,rippleIdx),2);
    ripple_post = trapz(spectra_post_abs(:,rippleIdx),2);



    %% Store

    alpha_1{r} = alpha_pre;
    alpha_2{r} = alpha_post;


    beta_1{r} = beta_pre;
    beta_2{r} = beta_post;


    lowGamma_1{r} = lowGamma_pre;
    lowGamma_2{r} = lowGamma_post;


    highGamma_1{r} = highGamma_pre;
    highGamma_2{r} = highGamma_post;


    ripple_1{r} = ripple_pre;
    ripple_2{r} = ripple_post;


    fprintf('Finished subject %d\n',subj)

    r = r + 1;

end


% After the end of the for loop
save('band_power_results_inter5.mat', ...
    'alpha_1','alpha_2', ...
    'beta_1','beta_2', ...
    'gamma_1','gamma_2', ...
    'ripple_1','ripple_2', ...
    'freqs');


%% Convert cells to matrices (subjects x channels)
alpha_pre_mat  = cell2mat(alpha_1);
alpha_post_mat = cell2mat(alpha_2);

beta_pre_mat   = cell2mat(beta_1);
beta_post_mat  = cell2mat(beta_2);

lowGamma_pre_mat  = cell2mat(lowGamma_1');
lowGamma_post_mat = cell2mat(lowGamma_2');

highGamma_pre_mat  = cell2mat(highGamma_1');
highGamma_post_mat = cell2mat(highGamma_2');

ripple_pre_mat  = cell2mat(ripple_1');
ripple_post_mat = cell2mat(ripple_2');

%% Average across subjects

alpha_pre_avg  = mean(alpha_pre_mat,2);
alpha_post_avg = mean(alpha_post_mat,2);

beta_pre_avg   = mean(beta_pre_mat,2);
beta_post_avg  = mean(beta_post_mat,2);

lowGamma_pre_avg  = mean(lowGamma_pre_mat,2);
lowGamma_post_avg = mean(lowGamma_post_mat,2);

highGamma_pre_avg  = mean(highGamma_pre_mat,2);
highGamma_post_avg = mean(highGamma_post_mat,2);

ripple_pre_avg  = mean(ripple_pre_mat,2);
ripple_post_avg = mean(ripple_post_mat,2);



%% ==============================
% Alpha topography
% ===============================

figure;

subplot(1,3,1)
topoplot(alpha_pre_avg, EEG.chanlocs);
title('Alpha PRE')
colorbar

subplot(1,3,2)
topoplot(alpha_post_avg, EEG.chanlocs);
title('Alpha POST')
colorbar

subplot(1,3,3)
topoplot(alpha_post_avg-alpha_pre_avg, EEG.chanlocs);
title('Alpha POST - PRE')
colorbar



%% ==============================
% Beta topography
% ===============================

figure;

subplot(1,3,1)
topoplot(beta_pre_avg, EEG.chanlocs);
title('Beta PRE')
colorbar

subplot(1,3,2)
topoplot(beta_post_avg, EEG.chanlocs);
title('Beta POST')
colorbar

subplot(1,3,3)
topoplot(beta_post_avg-beta_pre_avg, EEG.chanlocs);
title('Beta POST - PRE')
colorbar



%% ==============================
% Low Gamma 30-45 Hz
% ===============================

figure;

subplot(1,3,1)
topoplot(lowGamma_pre_avg, EEG.chanlocs);
title('Low Gamma PRE (30-45 Hz)')
colorbar

subplot(1,3,2)
topoplot(lowGamma_post_avg, EEG.chanlocs);
title('Low Gamma POST (30-45 Hz)')
colorbar

subplot(1,3,3)
topoplot(lowGamma_post_avg-lowGamma_pre_avg, EEG.chanlocs);
title('Low Gamma POST - PRE')
colorbar



%% ==============================
% High Gamma 45-100 Hz
% ===============================

figure;

subplot(1,3,1)
topoplot(highGamma_pre_avg, EEG.chanlocs);
title('High Gamma PRE (45-100 Hz)')
colorbar

subplot(1,3,2)
topoplot(highGamma_post_avg, EEG.chanlocs);
title('High Gamma POST (45-100 Hz)')
colorbar

subplot(1,3,3)
topoplot(highGamma_post_avg-highGamma_pre_avg, EEG.chanlocs);
title('High Gamma POST - PRE')
colorbar



%% ==============================
% Ripple 100-150 Hz
% ===============================

figure;

subplot(1,3,1)
topoplot(ripple_pre_avg, EEG.chanlocs);
title('Ripple PRE (100-150 Hz)')
colorbar

subplot(1,3,2)
topoplot(ripple_post_avg, EEG.chanlocs);
title('Ripple POST (100-150 Hz)')
colorbar

subplot(1,3,3)
topoplot(ripple_post_avg-ripple_pre_avg, EEG.chanlocs);
title('Ripple POST - PRE')
colorbar



data1 = load("bandpower_averages_inter1.mat")
data2 = load("bandpower_averages_inter2.mat")
data3 = load("bandpower_averages_inter3.mat")
% Load the two recordings
data1 = load('band_power_results_inter4.mat');
data2 = load('band_power_results_inter5.mat');

fields = fieldnames(data1);
nSubj = numel(data1.alpha_1);
fields(strcmp(fields,'freqs')) = [];
for f = 1:numel(fields)

    field = fields{f};

    for p = 1:nSubj

        tmp = cat(2, ...
            data1.(field){p}, ...
            data2.(field){p});

        data_avg.(field){p} = mean(tmp, 2);

    end
end

% Save the averaged data
save('band_power_results_average_motor.mat', '-struct', 'data_avg');