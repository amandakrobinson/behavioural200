function [] = run_pairwise_decoding(subjectnr)

    %% paths
    if isempty(which('cosmo_wtf'))
        addpath('~/CoSMoMVPA/mvpa');
    end

    %% set and check inputfiles
    fn = sprintf('data/derivatives/cosmomvpa/sub-%02i_cosmomvpa.mat',subjectnr);
    assert(exist(fn,'file')>0,sprintf('file not found: %s',fn))

    %% set and check outfile
    outfn = sprintf('results/sub-%02i_rdm.mat',subjectnr);
    if exist(outfn,'file')
        error('Outputfile exists! %s',outfn)
    end

    %% load data
    fprintf('sub-%02i loading\n',subjectnr)
    m1 = matfile(fn);
    ds = m1.ds;

    %% shorten time period of epoch
    timevect = ds.a.fdim.values{2};
    dsb = cosmo_slice(ds,ismember(ds.fa.time,find(timevect>-100&timevect<800)),2);
    dsb = cosmo_dim_prune(dsb);
    clear ds
    
    %% decoding params
    dsb.sa.targets = dsb.sa.stimulusnumber;
    dsb.sa.chunks = dsb.sa.trialnumber;

    nh = cosmo_interval_neighborhood(dsb,'time','radius',0);
    ma = {};
    ma.classifier = @cosmo_classify_lda;
    ma.progress = 0;
    ma.output='accuracy';
    nproc = 8;
    ma.nproc = nproc;

    %% set up pairwise contrasts
    combs = combnk(1:200,2); % do every pair of 200 images
    
    %% loop
    res_cell = cell(1,length(combs));
    c=clock();m='';
    for i=1:length(combs)
        ds = cosmo_slice(dsb,ismember(dsb.sa.stimulusnumber,combs(i,:)));
        ds.sa.targets = double(ds.sa.stimulusnumber==combs(i));
        ma.partitions = cosmo_nfold_partitioner(ds);
        res_cell{i} = cosmo_searchlight(ds,nh,@cosmo_crossvalidation_measure,ma);
        m = cosmo_show_progress(c,i/length(combs),sprintf('%i/%i',i,length(combs)),m);
    end
    
    rdm = cosmo_stack(res_cell);
    rdm.sa.comb = combs;
    rdm.sa.target1 = combs(:,1);
    rdm.sa.target2 = combs(:,2);
    %% save
    save(outfn,'rdm','-v7.3')
end
