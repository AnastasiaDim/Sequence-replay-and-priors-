addpath('/home/uranus/toolboxes/fieldtrip-lite-20250523/fieldtrip-20250523')
ft_defaults
nSubj = length(alpha_1);
nChan = length(alpha_1{1});
for s = 1:nSubj
    beta_1{s} =beta_2{s}(:);   % forces nChan × 1
end
% --- PRE ---
strt_base = [];
strt_base.label = {EEG.chanlocs.labels}';
strt_base.freq  = 1;           % dummy (single frequency)
strt_base.time  = 1;           % dummy (no time dimension)
strt_base.dimord = 'subj_chan_freq_time';

strt_base.powspctrm = zeros(nSubj, nChan, 1, 1);

for s = 1:nSubj
    strt_base.powspctrm(s,:,1,1) = lowGamma_1{s};
end

% --- POST ---
strt_main = strt_base;

for s = 1:nSubj
    strt_main.powspctrm(s,:,1,1) = lowGamma_2{s};
end
%% neighbours
ft_path = '/home/uranus/toolboxes/fieldtrip-lite-20250523/fieldtrip-20250523'
elec       = ft_read_sens(strcat(ft_path,'/template/electrode/GSN-HydroCel-256.sfp'));
 
cfg               = [];
cfg.method        = 'distance';
cfg.neighbourdist = 3;
cfg.feedback      = 'yes';
neighbours        = ft_prepare_neighbours(cfg,elec);




cfg = [];
cfg.latency          = 'all';
cfg.method           = 'montecarlo';
cfg.frequency        = 'all';
cfg.statistic        = 'ft_statfun_depsamplesT';
cfg.correctm         = 'cluster';
cfg.clusteralpha     = 0.05;
cfg.clusterstatistic = 'maxsum';
cfg.minnbchan        = 2;
cfg.tail             = 1;
cfg.clustertail      = 1;
cfg.alpha            = 0.05;
cfg.numrandomization = 5000;
% prepare_neighbours determines what sensors may form clusters
cfg_neighb.method    = 'distance';
cfg.neighbours       = neighbours;

subj = 40;
design = zeros(2,2*subj);
for i = 1:subj
  design(1,i) = i;
end
for i = 1:subj
  design(1,subj+i) = i;
end
design(2,1:subj)        = 1;
design(2,subj+1:2*subj) = 2;

cfg.design   = design;
cfg.uvar     = 1;
cfg.ivar     = 2;

[stat] = ft_freqstatistics(cfg,strt_base,strt_main)


save('stat_avg_time','stat') 

mask1= stat.mask;
sig_electrodes = any(mask1, 2);
mask1_toplot =  find(sig_electrodes == 1);
cluster_id = 1;  % first positive cluster

mask = (stat.posclusterslabelmat == cluster_id);
mask1_toplot =  find(mask == 1);
cluster_id = 2;  % first positive cluster

mask2 = (stat.posclusterslabelmat == cluster_id);
mask2_toplot =  find(mask2 == 1);
mask_overall =[mask1_toplot mask2_toplot]
mask_overall = unique([mask1_toplot(:); mask2_toplot(:)]);

figure
subplot(1,4,1),topoplot(stat.stat,EEG.chanlocs,'electrodes','off','emarker2',{[mask1_toplot],'o','k',1,1})
cmap = getPyPlot_cMap('RdBu_r')
colormap(cmap)
set(gcf, 'Color', 'none');          % remove figure background
set(gca, 'Color', 'none');          % remove axes background

exportgraphics(gcf, 'topo_gammainter1.png', 'BackgroundColor','none', 'Resolution',300);


load('/home/uranus/toolboxes/fieldtrip-lite-20250523/fieldtrip-20250523/template/layout/GSN-HydroCel-256.mat')
% make a plot
cfg = [];
cfg.layout = lay;
cfg.alpha = 0.05;
cfg.parameter='stat';
cfg.zlim = [-5 5];
ft_clusterplot(cfg, stat);

