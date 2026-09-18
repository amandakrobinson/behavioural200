%% read im
I={};N={};
for i=1:200
    d=dir(sprintf('stimuli/stim%03i_*',i));
    fn = d(1).name;
    [im,~,alpha]=imread(fullfile(d(1).folder, fn));
    I{i} = im;
    N{i} = fn;
    i
end

%% figure_stimulus_montage

f=figure(1);clf
f.Position = [1 56 1285 710];f.Resize='off';
f.PaperPositionMode='auto';

aw = 40; % image size
left=300;
bottom=20;
bufferw=20;
bufferh=20;
n=20;

% use colours from other plot
% cat1col = [0.2080    0.7187    0.4729];
cat2col = [0.1906    0.4071    0.5561];

catcols = flipud(tab10(10));
% cat3col = [0.2670    0.0049    0.3294];

for i=1:200
    row = (200/n)-ceil(i/n);
    col = mod(i-1,n);
    a = axes('Units','pixels','Position',[left+col*aw+floor(col/4)*bufferw bottom+row*(aw+bufferh) aw aw],'Visible','off');
    a.XLim = [.5 length(I{i})+.5];
    a.YLim = a.XLim;
    
    fp = strsplit(N{i},'_');
    h = imshow(I{i});

    if col==1
         text(-500,mean(a.YLim),fp{3},'Color',catcols(row+1,:),'FontSize',20,'HorizontalAlignment','center','VerticalAlignment','middle') % basic category label
    end
    if mod(col,n)+1==n
        drawnow
    end
end

%%
fn = 'figures/Fig1A_stimuli_montage';
set(gcf, 'Renderer', 'painters')
print(gcf,'-dpng','-r500',fn)
im=imread([fn '.png']);
[i,j]=find(mean(im,3)<255);margin=0;
imwrite(im(min(i-margin):max(i+margin),min(j-margin):max(j+margin),:),[fn '.png'],'png');
