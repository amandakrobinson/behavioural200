
function run_preprocessing

if isempty(which('eeglab'))
    addpath('~/Dropbox/MATLAB/eeglab2021.1')
end
eeglab('nogui')

%% get files
fol = './';

rawfiles = dir(sprintf('%s/data/*/*/*run-01_eeg.vhdr',fol));

% get id
partid = cell(length(rawfiles),1);
for f= 1:length(rawfiles)
    name = strsplit(rawfiles(f).name,{'_' '-'});
    partid{f} = name{2};
end

%% run preprocessing
for p = 1:length(rawfiles)
    
    fprintf('Processing %s...\n',partid{p})
    
    %% load data
    EEG = pop_loadbv(rawfiles(p).folder,rawfiles(p).name);
    EEG = eeg_checkset(EEG);
    
    %% preprocess data
    
    % add Cz channel and re-reference, adding Cz back into dataset
    EEG=pop_chanedit(EEG, 'append',63,'changefield',{64 'labels' 'Cz'},'setref',{'' 'Cz'});
    Czloc = struct('labels',{'Cz'},'type',{''},'theta',{0},'radius',{0},'X',{5.2047e-15},'Y',{0},'Z',{85},'sph_theta',{0},'sph_phi',{90},'sph_radius',{85},'urchan',{64},'ref',{''},'datachan',{0});
    EEG = pop_reref( EEG, [],'refloc',Czloc);
    EEG = eeg_checkset(EEG);
    
    % high pass filter
    EEG = pop_eegfiltnew(EEG, 0.1,[]);
    
    % low pass filter
    EEG = pop_eegfiltnew(EEG, [],100);
    
    % downsample
    EEG = pop_resample(EEG, 250);
    EEG = eeg_checkset(EEG);
    
    %% create epochs
    
    % fix rogue event
    if EEG.event(3).latency-EEG.event(2).latency > 300
        EEG.event(2).type = 'rogue';
    end
    
    EEG = pop_epoch(EEG, {'E  1'}, [-.2 1]);
    EEG = eeg_checkset(EEG);
    
    %% get eventinfo
    eventsfntsv = sprintf('%s/data/sub-%s/eeg/sub-%s_task-rsvp_run-01_events.tsv',fol,partid{p},partid{p});
    eventlist = tdfread(eventsfntsv);
    
    %% get trial indices to use

    % check all good with trial numbers
    if length(eventlist.onset)~=size(EEG.data,3)
        fprintf('Trial mismatch participant %s\n',partid{p})
        continue
    end
 
    % interpolate bad electrodes
    [~, badidx] = pop_rejchan(EEG, 'elec',[1:64] ,'threshold',5,'norm','on','measure','kurt');
    EEG = eeg_interp(EEG,badidx,'spherical');
    EEG.etc.badelecs = badidx;
    EEG = eeg_checkset(EEG);
    
%     % find bad trials
%     [~, idx_thresh] = pop_eegthresh(EEG,1,[1:64] ,-1000,1000,-0.2,0.996,0,0)
%     EEG.etc.badtrials = idx_thresh;
    
    %% save epochs
    pop_saveset(EEG,sprintf('data/derivatives/eeglab/sub-%s_task-rsvp_epochs.set',partid{p}))
    save(sprintf('data/derivatives/eeglab/sub-%s_task-rsvp_epochs.set',partid{p}),'EEG','-v7.3')
    
end

end
