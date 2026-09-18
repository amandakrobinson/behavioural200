
% run RSA, comparing pairwise decoding accuracy for 200 objects in EEG
% experiment to various online behavioural tasks

% load behavioural tasks
load('results/behaviour.mat')
load('results/stats_rsa.mat','stats')

%% calculate neural-PCA correlations
neuraldat = stats.neuraldat;
noiseceil = stats.noiseceiling;

% make RDM for each PC
for comps = 1:12
    pcardm(:,comps) = pdist(alldata.pca.pcacomps(:,comps));
end

% get neural-PC correlations per participant
for f= 1:size(neuraldat,3)
    fprintf('calculating correlations for participant %d\n',f)
    pca_corrs(:,:,f) = corr(neuraldat(:,:,f),pcardm,'type','Spearman','rows','complete');
end

%% now do stats
fprintf('Computing stats for neural-PCA correlations\n')
stats_pca = struct();
stats_pca.neural_PCA_corrs = pca_corrs;
stats_pca.neuraldat = neuraldat;
stats_pca.noiseceiling = noiseceil;
stats_pca.timevect = stats.timevect;
stats_pca.pca = alldata.pca;

for c = 1:size(pca_corrs,2) % each component
    x = squeeze(pca_corrs(:,c,:))';
    s = struct();
    s.targetname = sprintf('PC%d',c);
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
        s.ppeak(p) = stats_pca.timevect(pp);
    end

    % convert onsets and peaks to time (rather than tp)
    if hit==1
        s.onset = stats_pca.timevect(ot);
    else
        s.onset = NaN;
    end
    s.peak = stats_pca.timevect(peak);

    %
    stats_pca.results.(s.targetname) = s;
    fprintf('%i/%d\n',c,size(pca_corrs,2))
end
stats_pca.format = 'stats.results.pcnum.x';

%% now look at combined variance explained
nP = size(neuraldat,3);
nT = size(neuraldat,2);

% ---- build behavioural predictor RDMs from the PCA components ----
% pcacomps is 200 x 12 (stimulus scores per PC). Turn each into a 200x200
% RDM (euclidean on the 1-D score, vectorised.
pcacomps = alldata.pca.pcacomps;       % 200 x 12
nPC = size(pcacomps,2);
nPairs = size(neuraldat,1);

X = nan(nPairs, nPC);                   % predictor matrix: pair x PC
for pc = 1:nPC
    X(:,pc) = pdist(pcacomps(:,pc));    % 1-D euclidean = |diff|; matches RDM vectorisation
end
X = zscore(X);

% ---- per-timepoint: cross-validated combined R, and noise ceiling ----
combinedR   = nan(nT,nP);   % held-out predicted-vs-actual correlation

for t = 1:nT % for each timepoint
    for f = 1:nP % for each participant
        train = setdiff(1:nP,f); % all but one participant

        % --- neural RDMs ---
        yTrain = mean(neuraldat(:,t,train),3);   % mean neural RDM for all but one pts, training set
        yTest  = neuraldat(:,t,f);               % held-out participant

        % --- combined behavioural fit (cross-validated) ---
        % fit weights on training neural RDM, predict, test on held-out
        good = ~isnan(yTrain) & all(~isnan(X),2);
        b = [ones(sum(good),1) X(good,:)] \ yTrain(good);   % OLS weights
        yhat = [ones(nPairs,1) X] * b;                       % predicted neural RDM
        combinedR(t,f) = corr(yhat, yTest, 'type','Spearman','rows','complete');

        predicted(:,t,f) = yhat;
    end
end

mu_combined = mean(combinedR,2,'omitnan');
frac = mean(combinedR./noiseceil,2,'omitnan');
stats_pca.varianceexplained.total = mu_combined;
stats_pca.varianceexplained.frac = frac;

%%
fprintf('Saving\n')
save('results/stats_PCA_RSA.mat','stats_pca');
fprintf('Done\n')
