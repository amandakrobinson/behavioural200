%% tabulate onsets and peaks for neural-behaviour correlations
load('results/stats_rsa.mat')
load('results/behaviour.mat')

%reorder tasks
taskidx = [11:12 6:7 1 4 3 5 2 8:10];
models = stats.modelnames(taskidx);
%update task labels 
tasknames = models;
tasknames(1:2) = {'Similarity','Similarity (speeded)'};
tasknames(4) = {'Real-world size'};
tasknames(6:7) = {'Curvature' 'Colourfulness'};
tasknames(9:12) = {'Orientation' 'Human similarity' 'Human appearance' 'Human experience'};


%% get onsets and peaks for each hemi 

allinfo=struct();
for m = 1:length(models)

    s = stats.results.(models{m});

    allinfo.Model(m,1) = tasknames(m);
    allinfo.Onset(m,1) = s.onset;
    allinfo.Onset_lowCI(m,1) = s.onsetci(1);
    allinfo.Onset_highCI(m,1) = s.onsetci(2);
    allinfo.NBF10(m,1) = sum(s.bf>10);
    allinfo.Peak(m,1) = s.peak;
    allinfo.Peak_lowCI(m,1) = s.peakci(1);
    allinfo.Peak_highCI(m,1) = s.peakci(2);
    allinfo.PeakCorr(m,1) = max(s.mu);
    allinfo.PropNoise(m,1) = max(s.mu)/mean(stats.noiseceiling(stats.timevect==s.peak,:))*100;
end

allinfo = struct2table(allinfo);

save('results/onsets_peaks.mat','allinfo');





