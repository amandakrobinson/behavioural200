
% run RSA, comparing pairwise decoding accuracy for 200 objects in EEG
% experiment to various online behavioural tasks

% load behavioural tasks
load('results/behaviour.mat')

%% collate neural data

files = dir('results/p*_200_results.mat');

for f= 1:length(files)
    
    load(sprintf('results/%s',files(f).name))
    
    neuraldat(:,:,f) = rdm.samples;
end

%% calculate noise ceiling and neural-behaviour correlations
for f= 1:size(neuraldat,3)
    fprintf('calculating correlations for participant %d\n',f)
    idx = setdiff(1:size(neuraldat,3),f);
    for t= 1:size(neuraldat,2)
        noiseceil(t,f) = corr(neuraldat(:,t,f),mean(neuraldat(:,t,idx),3),'type','Spearman','rows','complete');
    end
    model_corrs(:,:,f) = corr(neuraldat(:,:,f),alldata.taskRDMs,'type','Spearman','rows','complete');
end

%% now do stats
fprintf('Computing stats for neural-behaviour correlations\n')
stats = struct();
stats.neural_beh_corrs = model_corrs;
stats.models = alldata.taskRDMs;
stats.noiseceiling = noiseceil;
stats.neuraldat = neuraldat;
stats.timevect = timevect;
stats.modelnames = alldata.tasks;

for c = 1:size(model_corrs,2)
    x = squeeze(model_corrs(:,c,:))';
    s = struct();
    s.targetname = stats.modelnames{c};
    s.n = size(x,1);
    s.mu = mean(x);
    s.mu_all = x;
    s.se = std(x)./sqrt(s.n);
    h0mean = 0;

    % calculate bayesfactors
    s.bf = bayesfactor_R_wrapper(x',...
        'returnindex',2,'verbose',false,'args',sprintf('mu=%d,rscale="medium",nullInterval=c(-0.5,0.5)',h0mean));

    %% calculate onsets and peaks
    fprintf('Calculating onsets for %s\n',s.targetname)

    % group mean onset & peak
    [hit,ot] = max(movmean(s.bf>10,[0 2])==1); % onset 3 consecutive tp BF>10
    [~,peak] = max(s.mu); % peak

    % peak per person
    for p = 1:size(s.mu_all,1)
        [~,pp] = max(s.mu_all(p,:)); % peak
        s.ppeak(p) = stats.timevect(pp);
    end

    % convert onsets and peaks to time (rather than tp)
    if hit==1
        s.onset = stats.timevect(ot);
    else
        s.onset = NaN;
    end
    s.peak = stats.timevect(peak);

    %% calculate onsets and peaks by bootstrapping
    fprintf('Calculating bootstrapped onsets for %s\n',s.targetname)

    rng(1);
    nboot = 1000;
    n = size(s.mu_all,1);
    bootidx = randi(n, n, nboot);          % n x nboot, sampling with replacement

    x = NaN(n,nboot*length(timevect));
    for i = 1:nboot
        idx = ((i-1)*length(timevect)+1):(i*length(timevect));
        x(:,idx) = s.mu_all(bootidx(:,i),:);
    end

    tic
    b = bayesfactor_R_wrapper(x', 'returnindex',2,'verbose',false, ...
        'args','mu=0,rscale="medium",nullInterval=c(-0.5,0.5)');
    s.bf_boot = reshape(b, [], nboot);      % timepoints x nboot

    fprintf('boostrap BFs done\n')
    toc

    % get onsets and peaks per bootstrap
    onset_boot = nan(1,nboot); peak_boot = nan(1,nboot);
    searchidx = find(stats.timevect >= 50);
    for bb = 1:nboot
        bfwin = s.bf_boot(searchidx,bb);
        [hit, ot] = max(movmean(bfwin>10,[0 2])==1);
        if hit==1, onset_boot(bb) = searchidx(ot); end
        [~, peak_boot(bb)] = max(mean(s.mu_all(bootidx(:,bb),:),1));
    end

    % convert onsets and peaks to time (rather than tp)
    s.onsetboot = nan(1,nboot);
    valid = ~isnan(onset_boot);
    s.onsetboot(valid) = stats.timevect(onset_boot(valid));    
    s.onset_validfrac = mean(~isnan(onset_boot));   % report proportion of onsets there were

    if sum(valid)==0
        s.onsetci=[NaN NaN];
    else
        ci = prctile(onset_boot(valid),[2.5 97.5]);
        s.onsetci = stats.timevect([floor(ci(1)) ceil(ci(2))]);
    end

    % convert peak number to times
    s.peakboot = stats.timevect(peak_boot);        
    peakci = prctile(peak_boot,[2.5 97.5]);
    s.peakci = stats.timevect([floor(peakci(1)) ceil(peakci(2))]); % make conservative using floor and ceil

    fprintf('Onsets done\n')

    stats.results.(s.targetname) = s;
    fprintf('%i/%d\n',c,size(model_corrs,2))
end
stats.format = 'stats.results.modelname.x';

%%
fprintf('Saving\n')
save('results/stats_rsa.mat','stats');
fprintf('Done\n')
