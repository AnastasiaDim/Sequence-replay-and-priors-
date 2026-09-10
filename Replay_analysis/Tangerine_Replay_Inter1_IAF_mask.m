clear;
clc;
close all;
eeglab_path = 'PATH_TO_EEGLAB';
data_path = 'PATH_TO_DATA';
mask_path = 'PATH_TO_MASKS';
output_path = 'PATH_TO_OUTPUT';

addpath(eeglab_path);
addpath(data_path);
addpath(mask_path);

load('Hz_Alpha_peak.mat') 
for  i = 1:length(name_sbj)
    if ~isempty(name_sbj{i})
        name_id(i) = str2num(name_sbj{i}(2:end)); 
    end
end


TF = [0 1 0 0 0;0 0 1 0 0; 0 0 0 1 0;0 0 0 0 1; 0 0 0 0 0]; % transition matrix
TR = TF';
figure, 
label_cat = {'Face','Scene','Body','Tool','Scrambled'};
imagesc(TF)
xticks([1:5])
xticklabels(label_cat)
yticks([1:5])
yticklabels(label_cat)

samplerate  = 100;
maxLag = samplerate*0.6; % evaluate time lag up to 600ms

nSubj  = 43; % number of subjects 
nstates = 5;
[~, pInds]  = uperms([1:5],120);
uniquePerms = pInds;
nShuf       = size(uniquePerms,1);
nsensors    = 256;


sf = cell(nSubj,1);  sb = cell(nSubj,1);
sf2 = cell(nSubj,1);  sb2 = cell(nSubj,1);

%% Core function
for iSj = 1:nSubj

    idx_subj   = find(iSj==name_id);
    alpha_subj = freq_peak(idx_subj);

    length_cycle = round(1/alpha_subj,2);
    bins         = samplerate*length_cycle;
    maxLag_subj  = maxLag-mod(maxLag,bins);

    if iSj ==41 || iSj ==10 || iSj == 29
        continue 
    end

    betas   = nan(nsensors, nstates);
    sf{iSj} = nan(1, nShuf, maxLag_subj+1);
    sb{iSj} = nan(1, nShuf, maxLag_subj+1);
      
    sf2{iSj} = nan(1, nShuf, maxLag_subj+1);
    sb2{iSj} = nan(1, nShuf, maxLag_subj+1);
    
    disp(['iSj=' num2str(iSj)])

    

    %faces
    name = ['/data/dimakou/classification/P',num2str(iSj),'_weights_faces.xlsx']
    [num,txt,raw] = xlsread(name);
    tp            = 66;
    betas(:,1)    = num(tp,:);
    inter         = xlsread('/data/dimakou/classification/intercept_scores_faces.xlsx');
    interc        = inter(iSj,:);
    intercepts(1) = interc(tp);

    %scene
    name1 = ['/data/dimakou/classification/P',num2str(iSj),'_weights_scenes.xlsx']
    [num,txt,raw] = xlsread(name1);
    tp = 69;
    betas(:,2) = num(tp,:);
    inter         = xlsread('/data/dimakou/classification/intercept_scores_scenes.xlsx');
    interc        = inter(iSj,:);
    intercepts(2) = interc(tp);

    %body
    name2 = ['/data/dimakou/classification/P',num2str(iSj),'_weights_bodies.xlsx']
    [num,txt,raw] = xlsread(name2);
    tp = 70;
    betas(:,3) = num(tp,:);
    inter         = xlsread('/data/dimakou/classification/intercept_scores_bodies.xlsx');
    interc        = inter(iSj,:);
    intercepts(3) = interc(tp);

    %tool
     name3 = ['/data/dimakou/classification/P',num2str(iSj),'_weights_tools.xlsx']
    [num,txt,raw] = xlsread(name3);
    tp = 70;
    betas(:,4) = num(tp,:);
     inter     = xlsread('/data/dimakou/classification/intercept_scores_tools.xlsx');
     interc        = inter(iSj,:);
     intercepts(4) = interc(tp);

    %scrambled
    name4 = ['/data/dimakou/classification/P',num2str(iSj),'_weights_scr.xlsx']
    [num,txt,raw] = xlsread(name4);
    tp = 70;
    betas(:,5) = num(tp,:);
    inter      = xlsread('/data/dimakou/classification/intercept_scores_scr.xlsx');
    interc        = inter(iSj,:);
    intercepts(5) = interc(tp);
      
    path1=['/data/dimakou/INTER/inter1/']
    name = ['P',num2str(iSj),'_inter1_final.set']
    EEG = pop_loadset('filename',name,'filepath',path1);
    idx_eeg = find(strcmp({EEG.chanlocs(:).type},'EYE'));
    EEG = pop_select(EEG,'nochannel',idx_eeg);
    EEG = pop_resample(EEG,100);
    X   = double(EEG.data)'; 


    
    %% make predictions with trained models
    
    mask = ['P',num2str(iSj),'_mask_inter1.mat']
    load(mask)
    preds = 1./(1+exp(-(X*betas + repmat(intercepts, [size(X,1) 1]))));
    preds_mask = preds;
    preds_mask(idx_mask,:) = 0;
%     figure,
%     subplot(1,2,1),imagesc(preds)
%     subplot(1,2,2),imagesc(preds_mask)

    weights = zeros(size(EEG.data,2),1);
    weights(idx_mask)  = 1;

    sname1 = fullfile(outname,['X_INTER1_P',num2str(iSj),'_.mat']);
    sname2 = fullfile(outname,['X_mask_INTER1_P',num2str(iSj),'_.mat']);

    save(sname1,'preds')
    save(sname2,'preds_mask')
    
    %% calculate sequenceness 
    for iShuf = 1:nShuf
        rp = uniquePerms(iShuf,:);  % use the 30 unique permutations (is.nShuf should be set to 29)
        T1 = TF(rp,rp); T2 = T1'; % backwards is transpose of forwards
        X=preds;
        
        nbins = maxLag_subj+1;

        warning off
        dm=[toeplitz(X(:,1),[zeros(nbins,1)])];
        dm=dm(:,2:end);
       
        for kk=2:nstates
           temp=toeplitz(X(:,kk),[zeros(nbins,1)]);
           temp=temp(:,2:end);
           dm=[dm temp]; 
        end
      
         temp_weights = toeplitz(weights,[zeros(nbins,1)]);
         temp_idx     = find(sum(temp_weights,2));
         temp         = zeros(size(weights));
         temp(temp_idx) = 1;
         dm_weights   = ones(size(weights));
         dm_weights(temp_idx) = 0;
        
%        figure,plot(weights,'*-k'), hold on
%         plot(temp,'o-r')

        warning on
       
        Y=X;       
        betas = nan(nstates*maxLag_subj, nstates);
        betas1 = nan(nstates*maxLag_subj, nstates);
   
      %% GLM: state regression, with other lages       

      for ilag=1:bins
       temp_zinds = (1:bins:nstates*maxLag_subj) + ilag - 1; 
       temp = pinv([dm(:,temp_zinds) ones(length(dm(:,temp_zinds)),1)])*Y;
       temp1 = lscov([dm(:,temp_zinds) ones(length(dm(:,temp_zinds)),1)],Y,dm_weights);
       betas(temp_zinds,:)=temp(1:end-1,:);
       betas1(temp_zinds,:)=temp1(1:end-1,:);   
     end  

       betasnbins64=reshape(betas,[maxLag_subj nstates^2]);
       bbb=pinv([T1(:) T2(:) squash(eye(nstates)) squash(ones(nstates))])*(betasnbins64'); %squash(ones(nstates))

       sf{iSj}(1,iShuf,2:end) = bbb(1,:); 
       sb{iSj}(1,iShuf,2:end) = bbb(2,:); 

       betasnbins642=reshape(betas1,[maxLag_subj nstates^2]);
       bbb2=pinv([T1(:) T2(:) squash(eye(nstates)) squash(ones(nstates))])*(betasnbins642'); %squash(ones(nstates))              
       
       sf2{iSj}(1,iShuf,2:end) = bbb2(1,:); 
       sb2{iSj}(1,iShuf,2:end) = bbb2(2,:); 

      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
      %% Cross-Correlation
%       for iLag=1:maxLag_subj
%           sf2{iSj}(1,iShuf,iLag+1) = sequenceness_Crosscorr(preds, T1, [], iLag);
%           sb2{iSj}(1,iShuf,iLag+1) = sequenceness_Crosscorr(preds, T2, [], iLag);
%       end        
                 
    end
end
save('sf_results_inter1.mat', 'sf');
save('sb_results_inter1.mat', 'sb');

save('sf2_results_inter1_mask.mat', 'sf2');
save('sb2_results_inter1_mask.mat', 'sb2');


for i =1:length(sb)
    n(i)=size(sf{i},3);
end
n(n==1)=[];
maxLag = min(n);

for i = 1:length(sf)
    if ~isempty(sf{i})
        sf_short{i,1} = sf{i}(1,:,1:maxLag);
    end
end
sf = cell2mat(sf_short);

for i = 1:length(sb)
    if ~isempty(sb{i})
        sb_short{i,1} = sb{i}(1,:,1:maxLag);
    end
end
sb = cell2mat(sb_short);

for i = 1:length(sf2)
    if ~isempty(sf2{i})
        sf2_short{i,1} = sf2{i}(1,:,1:maxLag);
    end
end
sf2 = cell2mat(sf2_short);

for i = 1:length(sb2)
    if ~isempty(sb2{i})
        sb2_short{i,1} = sb2{i}(1,:,1:maxLag);
    end
end
sb2 = cell2mat(sb2_short);

cTime  =[1:maxLag]/samplerate; 

%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
figure, 

%% GLM (fwd-bkw)
subplot(2,3,1)
npThresh = squeeze(max(abs(mean(sf(:,2:end,2:end)-sb(:,2:end,2:end),1)),[],3));
npThreshAll = max(npThresh);  
dtp = squeeze(sf(:,1,:)-sb(:,1,:));
shadedErrorBar(cTime, mean(dtp), std(dtp)/sqrt(nSubj)), hold on,
plot([cTime(1) cTime(end)], -npThreshAll*[1 1], 'k--'), plot([cTime(1) cTime(end)], npThreshAll*[1 1], 'k--')
title('GLM: fwd-bkw'), xlabel('lag (ms)'), ylabel('fwd minus bkw sequenceness')

%% GLM (fwd)
subplot(2,3,2)
npThresh = squeeze(max(abs(mean(sf(:,2:end,2:end),1)),[],3));
npThreshAll = max(npThresh);  
dtp = squeeze(sf(:,1,:));
shadedErrorBar(cTime, mean(dtp), std(dtp)/sqrt(nSubj)), hold on,
plot([cTime(1) cTime(end)], -npThreshAll*[1 1], 'k--'), plot([cTime(1) cTime(end)], npThreshAll*[1 1], 'k--')
title('GLM: fwd'), xlabel('lag (ms)'), ylabel('fwd sequenceness')

%% GLM (bkw)
subplot(2,3,3)
npThresh = squeeze(max(abs(mean(sb(:,2:end,2:end),1)),[],3));
npThreshAll = max(npThresh);  
dtp = squeeze(sb(:,1,:));
shadedErrorBar(cTime, mean(dtp), std(dtp)/sqrt(nSubj)), hold on,
plot([cTime(1) cTime(end)], -npThreshAll*[1 1], 'k--'), plot([cTime(1) cTime(end)], npThreshAll*[1 1], 'k--')
title('GLM: bkw'), xlabel('lag (ms)'), ylabel('bkw sequenceness')

%% Cross-Correlation (fwd-bkw)
sf=sf2;
sb=sb2;
subplot(2,3,4)
npThresh = squeeze(max(abs(mean(sf(:,2:end,2:end)-sb(:,2:end,2:end),1)),[],3));
npThreshAll = max(npThresh);  
dtp = squeeze(sf(:,1,:)-sb(:,1,:));
shadedErrorBar(cTime, mean(dtp), std(dtp)/sqrt(nSubj)), hold on,
plot([cTime(1) cTime(end)], -npThreshAll*[1 1], 'k--'), plot([cTime(1) cTime(end)], npThreshAll*[1 1], 'k--')
title('Correlation: fwd-bkw'), xlabel('lag (ms)'), ylabel('fwd minus bkw sequenceness')

%% Cross-Correlation (fwd)
subplot(2,3,5)
npThresh = squeeze(max(abs(mean(sf(:,2:end,2:end),1)),[],3));
npThreshAll = max(npThresh); 
dtp = squeeze(sf(:,1,:));
shadedErrorBar(cTime, mean(dtp), std(dtp)/sqrt(nSubj)), hold on,
plot([cTime(1) cTime(end)], -npThreshAll*[1 1], 'k--'), plot([cTime(1) cTime(end)], npThreshAll*[1 1], 'k--')
title('Correlation: fwd'), xlabel('lag (ms)'), ylabel('fwd sequenceness')

%% Cross-Correlation (bkw)
subplot(2,3,6)
npThresh = squeeze(max(abs(mean(sb(:,2:end,2:end),1)),[],3));
npThreshAll = max(npThresh); 
dtp = squeeze(sb(:,1,:));
shadedErrorBar(cTime, mean(dtp), std(dtp)/sqrt(nSubj)), hold on,
plot([cTime(1) cTime(end)], -npThreshAll*[1 1], 'k--'), plot([cTime(1) cTime(end)], npThreshAll*[1 1], 'k--')
title('Correlation: bkw'), xlabel('lag (ms)'), ylabel('bkw sequenceness')

saveas(gcf,'replay_inter1.png')
