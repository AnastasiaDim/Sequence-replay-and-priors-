clear; clc; close all;

nSubj = 40;

%% =========================================================
% CHOOSE DATASET
% =========================================================
% 'visual' -> sf2_results_rest1eo_mask.mat
% 'motor'  -> sf2_results_rest1eo_mask_motor.mat
datasetType = 'motor';   % change to 'visual' or 'motor'

if strcmpi(datasetType,'motor')
    suffix = '_motor';
else
    suffix = '';
end

%% =========================================================
% SETTINGS
% =========================================================
modes = {'forward','backward'};
avgTypes = {'median'};

condNames = {'rest1eo','inter1','inter2','inter3', ...
             'inter4','inter5','rest2eo'};

titlesTxt = {'Rest Pre','Rest 1','Rest 2','Rest 3', ...
             'Rest 4','Rest 5','Rest Post'};

col_rest = [0 0 0];
col_task = [0 0 0];

%% =========================================================
% LOAD BASELINE FILES AND COMPUTE GLOBAL THRESHOLDS
% =========================================================

% ---------- FORWARD BASELINE ----------
load(sprintf('sf2_baseline%s.mat',suffix),'sf2');

sf_base = sf2;

n = cellfun(@(x) size(x,3), sf_base);
n(n==1) = [];
maxLagBase = min(n);

sf_short = cellfun(@(x) x(1,:,1:maxLagBase), ...
    sf_base(~cellfun(@isempty,sf_base)), 'uni',0);

sf_mat = cell2mat(sf_short);

% permutation distribution
sf_perm_mean = squeeze(max(mean(sf_mat(:,2:end,2:end),1),[],3));
sf_perm_median = squeeze(max(median(sf_mat(:,2:end,2:end),1),[],3));

globalThresh.forward.mean   = prctile(sf_perm_mean,95);
globalThresh.forward.median = prctile(sf_perm_median,95);

clear sf2 sf_base sf_short sf_mat sf_perm_mean sf_perm_median


% ---------- BACKWARD BASELINE ----------
load(sprintf('sb2_baseline%s.mat',suffix),'sb2');

sb_base = sb2;

n = cellfun(@(x) size(x,3), sb_base);
n(n==1) = [];
maxLagBase = min(n);

sb_short = cellfun(@(x) x(1,:,1:maxLagBase), ...
    sb_base(~cellfun(@isempty,sb_base)), 'uni',0);

sb_mat = cell2mat(sb_short);

% permutation distribution
sb_perm_mean = squeeze(max(mean(sb_mat(:,2:end,2:end),1),[],3));
sb_perm_median = squeeze(max(median(sb_mat(:,2:end,2:end),1),[],3));

globalThresh.backward.mean   = prctile(sb_perm_mean,95);
globalThresh.backward.median = prctile(sb_perm_median,95);

clear sb2 sb_base sb_short sb_mat sb_perm_mean sb_perm_median

fprintf('Global thresholds loaded:\\n');
fprintf('Forward mean   : %.5f\\n',globalThresh.forward.mean);
fprintf('Forward median : %.5f\\n',globalThresh.forward.median);
fprintf('Backward mean  : %.5f\\n',globalThresh.backward.mean);
fprintf('Backward median: %.5f\\n',globalThresh.backward.median);

%% =========================================================
% LOOP OVER THE 4 FIGURES
% =========================================================

for m = 1:length(modes)

    for a = 1:length(avgTypes)

        mode = modes{m};
        avgType = avgTypes{a};

        figure;

        % use ONE threshold for the whole figure
        npThresh = globalThresh.(mode).(avgType);

        for k = 1:7

            cond = condNames{k};

            %% -------------------------------------------------
            % LOAD DATA
            % --------------------------------------------------

            if strcmp(mode,'forward')

                fileName = sprintf('sf2_results_%s_mask%s.mat', ...
                    cond, suffix);

                load(fileName,'sf2');
                sf = sf2;

                n = cellfun(@(x) size(x,3), sf);
                n(n==1) = [];
                maxLag = min(n);

                samplerate = 100;
                cTime = (1:maxLag)/samplerate;

                sf_short = cellfun(@(x) x(1,:,1:maxLag), ...
                    sf(~cellfun(@isempty,sf)), 'uni',0);

                data_mat = cell2mat(sf_short);

                ylab = 'Forward replay';

            else

                fileName = sprintf('sb2_results_%s_mask%s.mat', ...
                    cond, suffix);

                load(fileName,'sb2');
                sb = sb2;

                n = cellfun(@(x) size(x,3), sb);
                n(n==1) = [];
                maxLag = min(n);

                samplerate = 100;
                cTime = (1:maxLag)/samplerate;

                sb_short = cellfun(@(x) x(1,:,1:maxLag), ...
                    sb(~cellfun(@isempty,sb)), 'uni',0);

                data_mat = cell2mat(sb_short);

                ylab = 'Backward replay';

            end

            %% Replay values
            dtp = squeeze(data_mat(:,1,:));

            if size(dtp,1) ~= nSubj
                dtp = dtp';
            end

            %% Mean or median
            if strcmp(avgType,'mean')

                center = mean(dtp,1);
                err = std(dtp,0,1)/sqrt(nSubj);

            else

                center = median(dtp,1);
                err = 1.253*std(dtp,0,1)/sqrt(nSubj);

            end

            %% -------------------------------------------------
            % PLOT
            % --------------------------------------------------

            subplot(1,7,k)

            if k == 1 || k == 7
                col = col_rest;
            else
                col = col_task;
            end

            shadedErrorBar(cTime,center,err, ...
                {'color',col,'LineWidth',1},0.8);

            hold on

            % SAME threshold for every subplot in this figure
            plot([min(cTime) max(cTime)], ...
                npThresh*[1 1],'--','color',col,'LineWidth',1);

            title(titlesTxt{k})
            xlabel('lag (s)')
            ylabel(ylab)

            axis square
            box on

            xlim([min(cTime) max(cTime)])
            ylim([-0.03 0.03])

        end

        %% -----------------------------------------------------
        % FIGURE FORMATTING
        % ------------------------------------------------------

        set(gcf,'Color','w')
        set(gcf,'Position',[100 100 1800 300])

        saveName = sprintf('Sequenceness_%s_%s_%s', ...
            upper(mode), upper(avgType), upper(datasetType));

        print(gcf,saveName,'-dpng','-r300');

    end
end

fprintf('Done! Saved 4 figures for %s dataset using GLOBAL baseline thresholds.\\n', datasetType);



%% Load Rest 5 forward replay and calculate mean/SD at 90 ms
load(sprintf('sf2_results_inter4_mask%s.mat',suffix),'sf2');

sf = sf2;

n = cellfun(@(x) size(x,3), sf);
n(n==1) = [];
maxLag = min(n);

sf_short = cellfun(@(x) x(1,:,1:maxLag), ...
    sf(~cellfun(@isempty,sf)), 'uni',0);

data_mat = cell2mat(sf_short);

% Extract sequenceness values
dtp = squeeze(data_mat(:,1,:));

if size(dtp,1) ~= nSubj
    dtp = dtp';
end

% 90 ms lag = location 10
lag90 = dtp(:,10);

% Mean and SD across subjects
mean_rest5_90ms = mean(lag90);
sd_rest5_90ms   = std(lag90);

fprintf('Rest 5 forward replay at 90 ms:\n');
fprintf('Mean = %.6f\n', mean_rest5_90ms);
fprintf('SD   = %.6f\n', sd_rest5_90ms);