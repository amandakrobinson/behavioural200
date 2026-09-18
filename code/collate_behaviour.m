
%% analyse data from online reaction time experiment for different tasks
% collate and save per-stimulus data for RT and response from 12 tasks

redocollate = 1; % collate raw data again?
exclude = 200; % exclude participants with median RT below this

% read data from online task
% get median RTs for each image condition
categories = {'aquatic' 'bird' 'human' 'insect' 'mammal'...
    'clothing' 'fruit' 'furniture' 'plants' 'tools'};

load('code/stimnames.mat')
stimuli = cellfun(@(x) strsplit(x, '.'), stims, 'UniformOutput', false);
stimuli = vertcat(stimuli{:});
stimuli = stimuli(1:2:end,1);

% order of tasks
alltasks = {'detection' 'inversion' 'colour' 'curviness' 'familiarity'...
    'animacy' 'size' ...
    'human_is' 'human_looks' 'human_thinks'};

alltasknames = {'Detection' 'Orientation' 'Colourfulness' 'Curvature' 'Familiarity'...
    'Animacy' 'Real-world size' ...
    'Human similarity' 'Human appearance' 'Human experience'...
    'Similarity' 'Similarity (speeded)'};

%% collate raw data
if redocollate
    stimrt=struct();stimacc=struct();taskrt=struct();

    %% two mouse tracking sessions
    for fn = 1:2

        fns = dir(sprintf('data/mouse-exp%d/data/mouse-exp%d*.csv',fn,fn));
        subnr = 0;
        for f=1:numel(fns) % for each participant (file name)

            fn = fullfile(fns(f).folder,fns(f).name);
            TS = readtable(fn);

            if height(TS)<2400
                continue
            end

            ntrials = sum(strcmp(TS.test_part,'image_presentation'));

            if ntrials == 1200
                subnr = subnr+1;

                if ~isa(TS.rt,'double')
                    TS.rt = str2double(TS.rt);
                end

                fprintf('file %d\n',f)

                if ~isa(TS.button_pressed,'double')
                    TS.button_pressed = str2double(TS.button_pressed);
                end

                TS = TS(strcmp(TS.test_part,'image_presentation'),:);

                tasks = unique(TS.task_name); % analyse each task separately

                for t = 1:length(tasks)

                    TSt = TS(strcmp(TS.task_name,tasks{t}),:); % data for that task
                    if median(TSt.rt,'omitnan')<exclude
                        taskrt.(tasks{t})(subnr) = nan;
                        stimrt.(tasks{t})(:,subnr) = nan;
                        stimacc.(tasks{t})(:,subnr) = nan;
                        continue
                    end
                    
                    % get two stimuli presented on each trial
                    stimt=[];
                    for r = 1:height(TSt)
                        stimt(r,:) = str2num(TSt.stims{r})';
                    end

                    for s = 1:200 % for each stim
                        stimnum = s-1;
                        idx_L = find(stimt(:,1)==stimnum); % trials with that stimulus on left
                        idx_R = find(stimt(:,2)==stimnum); % trials with that stim on left

                        % median rts for trials with that stimulus
                        stimrt.(tasks{t})(s,subnr) = median(TSt.rt([idx_L; idx_R]),'omitnan');

                        % proportion of trials that stim was chosen as response                                              press = [TSt.button_pressed(idx_L) == 0;  TSt.button_pressed(idx_R) == 1];
                        press = [TSt.button_pressed(idx_L) == 0;  TSt.button_pressed(idx_R) == 1];
                        stimacc.(tasks{t})(s,subnr) = mean(press,'omitnan');

                    end
                    taskrt.(tasks{t})(subnr) = median(TSt.rt,'omitnan');

                end
            end
        end
    end

    %% now do animacy and size 2AFC
    fn = dir('data/animacysize/alldata.csv');

    fn = fullfile(fn.folder,fn.name);
    TS = readtable(fn);

    tasks2afc = unique(TS.questiontype);

    for t = 1:length(tasks2afc)
        T_t = TS(strcmp(TS.questiontype,tasks2afc{t}),:);
        subnrs = unique(T_t.subjectnr);

        x=0;
        for pnum = 1:length(subnrs)
            TSt = T_t(T_t.subjectnr==subnrs(pnum),:);
            if median(TSt.rt,'omitnan')<exclude
                continue
            end
            x=x+1;
            for s = 1:200 % for each stim
                idx = find(TSt.stimnumber(:,1)==s);

                % rt
                stimrt.(tasks2afc{t})(s,x) = TSt.rt(TSt.stimnumber==s);

                % proportion chosen
                stimacc.(tasks2afc{t})(s,x) = TSt.choice_num(TSt.stimnumber==s);

            end
            taskrt.(tasks2afc{t})(x) = median(TSt.rt,'omitnan');
        end
    end

    %% now do humanness

    tasknames = {'is' 'looks' 'thinks'};
    for t = 1:length(tasknames)
        stimacc.(['human_' tasknames{t}]) = [];
        stimrt.(['human_' tasknames{t}]) = [];
    end

    fns = dir('data/humanness/data/2020_*.csv');

    for f=1:numel(fns) % for each participant (file name)

        fn = fullfile(fns(f).folder,fns(f).name);
        TS = readtable(fn);

        if height(TS)<2400
            continue
        end

        ntrials = sum(strcmp(TS.test_part,'trial'));

        if ntrials > 1200
            TS = TS(strcmp(TS.test_part,'trial'),:);

            fprintf('file %d\n',f)

            tasks = unique(TS.question); % analyse each task separately
            etask = tasknames([contains(tasks,tasknames{1}) contains(tasks,tasknames{2}) contains(tasks,tasknames{3})]);
            for t = 1:length(tasks)

                TSt = TS(strcmp(TS.question,tasks{t}),:); % data for that task
                
                rtmed = median(TSt.rt,'omitnan');
                if rtmed<exclude
                    continue
                end

                pnum = size(stimrt.(['human_' etask{t}]),2)+1;

                for s = 1:200 % for each stim
                    stimname = stimuli{s};
                    idx_L = find(contains(TSt.stimL,stimname)); % trials with that stimulus on left
                    idx_R = find(contains(TSt.stimR,stimname));  % trials with that stim on left

                    % median rts for trials with that stimulus
                    stimrt.(['human_' etask{t}])(s,pnum) = median(TSt.rt([idx_L; idx_R]),'omitnan');

                    % proportion of trials that stim was chosen as response
                    press = [contains(TSt.key_press(idx_L),'70');  contains(TSt.key_press(idx_R),'74')]; % 70 is left, 74 is right
                    stimacc.(['human_' etask{t}])(s,pnum) = mean(press,'omitnan');

                end
                taskrt.(['human_' etask{t}])(pnum) = rtmed;

            end
        end
    end

    %% now do similarity/odd-one-out tasks
    stims = strcat(stimuli,'.jpg');

    % read similarity data from different tasks
    simtasks = {'similarity' 'similarity_speeded'};
    simdat = struct();
    for s = 1:length(simtasks)
        fns = dir(['data/similarity/' simtasks{s} '/200*.csv']);

        subnr = 0;                  
        RDMcounts_all = [];RDMsum_all=[];

        for f=1:numel(fns)
            fn = fullfile(fns(f).folder,fns(f).name);
            TS = readtable(fn);
            if size(TS,1)>6 % more than 6 lines in the file
                TS = TS(strcmp(TS.test_part,'triplet'),:);
                if size(TS,1) == 400 % if contains 400 trials (whole experiment), add to group
                    if ~isa(TS.rt,'double')
                        TS.rt = str2double(TS.rt);
                    end
                    rtmed = median(TS.rt,'omitnan');
                    if rtmed<exclude
                        fprintf('median rt too short, exluding\n')
                        continue
                    end

                    subnr = subnr+1;
                    TS.subjectnr(:) = subnr;
                    
                    if ~isa(TS.button_pressed,'double')
                        TS.button_pressed = str2double(TS.button_pressed);
                    end

                    % T = [T; TS];
                    % collate RT per stimulus
                    for st = 1:200
                        stimname = stimuli{st};
                        idx = find(contains(TS.stim0,stimname)|contains(TS.stim1,stimname)|contains(TS.stim2,stimname));
                        % median rts for trials with that stimulus
                        stimrt.(simtasks{s})(st,subnr) = median(TS.rt(idx),'omitnan');
                    end
                    taskrt.(simtasks{s})(subnr) = median(TS.rt,'omitnan');
                    % fprintf('file %i/%i done\n',f,numel(fns));
                
                    % now do RDM for this participant
                    [~,TS.stim0number]=ismember(TS.stim0,stims);
                    [~,TS.stim1number]=ismember(TS.stim1,stims);
                    [~,TS.stim2number]=ismember(TS.stim2,stims);

                    allcombs = [TS.stim0number TS.stim1number TS.stim2number];
                    choice = TS.button_pressed;
                    RDMsum = zeros(200,200);
                    RDMcounts = zeros(200,200);

                    for i=1:numel(choice)
                        % for every choice, add 1 to the similarity of the two items that were
                        % not the odd-one-out (three choices were coded as 0, 1, 2)
                        v = allcombs(i,(0:2)~=choice(i));
                        RDMsum(v(1),v(2)) = RDMsum(v(1),v(2))+1;
                        RDMsum(v(2),v(1)) = RDMsum(v(2),v(1))+1;
                        % add 1 to the counts of all items compared, to compute the mean later
                        for v = combnk(allcombs(i,:),2)'
                            RDMcounts(v(1),v(2)) = RDMcounts(v(1),v(2))+1;
                            RDMcounts(v(2),v(1)) = RDMcounts(v(2),v(1))+1;
                        end
                    end
                
                    RDMsum_all = cat(3,RDMsum_all,RDMsum);
                    RDMcounts_all = cat(3,RDMcounts_all,RDMcounts);
                else
                    fprintf('file %i/%i not enough trials\n',f,numel(fns));
                end
            else
                fprintf('file %i/%i not enough trials\n',f,numel(fns));
            end
        end % end collation of that task

        fprintf('create RDM\n')
        RDMsum_group = sum(RDMsum_all,3);
        RDMcounts_group = sum(RDMcounts_all,3);
        RDMmean = 1 - RDMsum_group./RDMcounts_group;

        simdat.(simtasks{s}).alldat.sum = RDMsum_all;
        simdat.(simtasks{s}).alldat.counts = RDMcounts_all;
        simdat.(simtasks{s}).RDM = RDMmean;
    end

    %% save
    save('results/behaviour.mat','stimrt','stimacc','taskrt')

else
    load('results/behaviour.mat')
end


%% collate data for the right measure and make RDMs

measuretype = {'RT' 'response'};
measure = [1 1 2 2 2 ...
    2 2 ...
    2 2 2 ...
    ]; % 1 is rt, 2 is response

% create RDMs
fprintf('create RDMs\n')

rdms=[];dat=[];alldata = struct();

for t = 1:length(alltasks) % 10 tasks (not including triplet)
    if measure(t) == 1
        taskdata = stimrt.(alltasks{t});
    else
        taskdata = stimacc.(alltasks{t});
    end
    alldata.(alltasks{t}).rawdata = taskdata;
    
    dat(:,t) = mean(taskdata,2,'omitnan');
    rdms(:,t) = pdist(dat(:,t),'euclidean');
    alldata.(alltasks{t}).mu = dat(:,t);
    alldata.(alltasks{t}).rdm = rdms(:,t);
end

%% append similarity/triplet data
% two tasks: similarity and similarity speeded

% similarity speeded RDM
Yt = simdat.similarity_speeded.RDM;
Yt(eye(size(Yt))==1)=0;
dat_speeded = squareform(Yt)';

% similarity untimed
Yut = simdat.similarity.RDM;
Yut(eye(size(Yut))==1)=0;
dat_ut = squareform(Yut)';

rdms(:,end+1) = dat_ut;
rdms(:,end+1) = dat_speeded;
n=length(alltasks);
alltasks((n+1):(n+2)) = {'similarity' 'similarity_speeded'};

% add to alldata struct
alldata.similarity.rdm = dat_ut;
alldata.similarity.data = simdat.similarity.alldat;

alldata.similarity_speeded.rdm = dat_speeded;
alldata.similarity_speeded.data = simdat.similarity_speeded.alldat;

% now make 1D representation of triplet data, aligned to each other
rng(1);
startmod = zscore(mean(dat,2));

% get 1D MDS
trip_ut = mdscale(squareform(dat_ut),1,'Start',startmod);
trip_speeded = mdscale(squareform(dat_speeded),1,'Start',trip_ut);

% force animate-positive using the known animate/inanimate split
animate = contains(stimuli,'animate') & ~contains(stimuli,'inanimate');
if mean(trip_ut(animate)) < mean(trip_ut(~animate)), trip_ut = -trip_ut; end
if mean(trip_speeded(animate))  < mean(trip_speeded(~animate)),  trip_speeded  = -trip_speeded;  end

alldata.similarity.mu = trip_ut;
alldata.similarity_speeded.mu = trip_speeded;

dat(:,11:12) = [trip_ut trip_speeded];


%% collate all
alldata.stimrt = stimrt;
alldata.stimacc = stimacc;
alldata.taskrt = taskrt; 
alldata.taskRDMs = rdms;
alldata.tasks = alltasks;
alldata.tasknames = alltasknames;
alldata.meantaskdat = dat;
alldata.stimuli = stimuli;

%% now assess reliability in behaviour
% get split half correlations for all tasks except triplet

tasks = alldata.tasks;

for t = 1:10
    raw = alldata.(tasks{t}).rawdata;   % 200 x nP
    nP = size(raw,2); % number of participants

    rng(1);
    nperm = 1000;
    r = nan(nperm,1);
    for i = 1:nperm
        idx = randperm(nP);
        h1 = idx(1:floor(nP/2));
        h2 = idx(floor(nP/2)+1:end);
        m1 = mean(raw(:,h1), 2, 'omitnan');   % 200x1 mean profile, half 1
        m2 = mean(raw(:,h2), 2, 'omitnan');   % 200x1 mean profile, half 2
        r(i) = corr(m1, m2, 'rows','complete', 'type','Spearman');
    end
    splithalf = mean(r);
    % Spearman-Brown correction (split-half underestimates full-sample reliability)
    reliability = 2*splithalf / (1 + splithalf);
    fprintf('%s: split-half r = %.3f, Spearman-Brown = %.3f\n', tasks{t},splithalf, reliability);
    alldata.(tasks{t}).reliability.r = splithalf;
    alldata.(tasks{t}).reliability.rSpearmanBrown = reliability;
end

nperm = 10;

for s = 1:2 % similarity tasks
    
    datsum = simdat.(simtasks{s}).alldat.sum;
    datcounts = simdat.(simtasks{s}).alldat.counts;
    nP = size(datsum,3); % number of participants
    startmod = alldata.(simtasks{s}).mu;

    rng(1);
    r = nan(nperm,1);
    for i = 1:nperm
        idx = randperm(nP);
        h1 = idx(1:floor(nP/2));
        h2 = idx(floor(nP/2)+1:end);

        rdm1 = sum(datsum(:,:,h1),3)./sum(datcounts(:,:,h1),3);  
        rdm1(eye(size(rdm1))==1)=0;
        trip1 = mdscale(squareform(rdm1),1,'Start',startmod);

        rdm2 = sum(datsum(:,:,h2),3)./sum(datcounts(:,:,h2),3);  
        rdm2(eye(size(rdm2))==1)=0;
        trip2 = mdscale(squareform(rdm2),1,'Start',trip1);

        r(i) = corr(trip1,trip2, 'rows','complete', 'type','Spearman');
        fprintf('Perm %d done: rho=%d\n',i,r(i))
    end
    splithalf = mean(abs(r));
    % Spearman-Brown correction (split-half underestimates full-sample reliability)
    reliability = 2*splithalf / (1 + splithalf);
    fprintf('%s: split-half r = %.3f, Spearman-Brown = %.3f\n', simtasks{s},splithalf, reliability);
    alldata.(simtasks{s}).reliability.r = splithalf;
    alldata.(simtasks{s}).reliability.rSpearmanBrown = reliability;
end

%% NOW DO PCA ON TASK SCORES 200x1 for each task

% run PCA on behaviour 12 task models
dat = alldata.meantaskdat;

% zscore data
for r = 1:size(dat,2)
    m=dat(:,r);
    dat_z(:,r) = (m - mean(m))/std(m);
end

[~,pcacomps,~,~,e] = pca(dat_z);

% correlate with each original data
for pc = 1:size(pcacomps,2) % each pca component

    [pct_rsa(:,pc),ptvals(:,pc)] = corr(pcacomps(:,pc),dat,'type','Spearman','rows','complete');
end

r2 = pct_rsa.^2;

alldata.pca.pcacomps = pcacomps;
alldata.pca.componentrawcorrs = pct_rsa;
alldata.pca.componentrawcorrspvals = ptvals;
alldata.pca.r2 = r2;
alldata.pca.explainedvar = e;

save('results/behaviour.mat','alldata','stimrt','stimacc','taskrt')%'stimrt','stimacc','taskrt','rdms','alltasks','alltasknames','dat')