%% Plot Figure 3: RDMs, MDS, RTs
% plot RDMs per task
% plot relationship between tasks
% plot reaction times

%% load behaviour

load('results/behaviour.mat')
tasknames = alldata.tasknames;
tasks = alldata.tasks;
taskrt = alldata.taskrt;
rdms = alldata.taskRDMs;

categories = {'aquatic' 'bird' 'human' 'insect' 'mammal'...
    'clothing' 'fruit' 'furniture' 'plants' 'tools'};

fprintf('create embedding\n')
taskRDMdist = 1-abs(corr(rdms,'type','Spearman','Rows','complete'));
fprintf('embedding done\n')

red = [153 36 56];
green = [117, 157, 132];
pink = [247, 171, 175];
navy = [49, 104, 142];

cmap = [green; red; navy; pink]/255;
cats = [1 1 1 1 2 2 2 3 3 3 4 4];

%% plot RDMs
figure(1);clf;
set(gcf,'Position',[1 1 1000 1200],'Resize','off')

for t= 1:length(tasks)

    s=subplot(5,4,t);
    s.Position(3:4) = s.Position(3:4)+.01;
    imagesc(squareform(rdms(:,t)))
    set(gca,'FontSize',14)
    if t==9
        set(gca,'YTick',10:20:200)
        set(gca,'YTickLabels',categories)
        set(gca,'XTick',10:20:200)
        set(gca,'XTickLabels',categories)
    else
        set(gca,'YTick',[])
        set(gca,'XTick',[])
    end
   
    t=title(sprintf('%s',tasknames{t}),'Color',cmap(cats(t),:),'Fontsize',17);
    t.Position(2) = t.Position(2) - 10;
    colormap viridis
    % axis off
    axis square

end

%% plot task MDS embedding

sb = subplot(5,5,[16 17 21 22]);
sb.Position(2) = sb.Position(2)-.03;
rng(1)
X1 = mdscale(taskRDMdist,2,'Start','random','Replicates',10);
hold on
X=X1;
for t = 1:size(X,1)
    plot(X(t,1),X(t,2),'.','MarkerSize',20,'Color',cmap(cats(t),:))

    if ismember(t,[6 7 8 9])
        text(X(t,1),X(t,2)-.04,tasknames{t},'FontSize',12,'Color',cmap(cats(t),:),'HorizontalAlignment', 'center')
    else
        text(X(t,1),X(t,2)+.045,tasknames{t},'FontSize',12,'Color',cmap(cats(t),:),'HorizontalAlignment', 'center')
    end

end
axis square
set(gca,'XTick',[])
set(gca,'YTick',[])
set(gca,'FontSize',18)
xlim([-.69 .69])
ylim([-.4 .75])

% Get the current axes object
ax = gca;
set(gca,'Position',[ax.Position(1) ax.Position(2)+.03 ax.Position(3) ax.Position(4)+.03])
sb2pos = tightPosition(ax);

%% plot RTs

tasknames(8:10) = {'Human-sim','Human-app','Human-exp'};
for t = 1:length(tasks)
    dat = taskrt.(tasks{t});
    meantask(t) = mean(dat);
end
[~,i] = sort(meantask);


sp=subplot(5,5,[18:20 23:25]);
sp.Position(2) = sp.Position(2)-.03;
hold on
for t = 1:length(tasks)
    dat = taskrt.(tasks{i(t)});
    mu = mean(dat);
    se = std(dat)/sqrt(length(dat));
    distributionPlot({dat},'xValues',t,'xNames',tasknames{i(t)},...
        'xyOri','flipped','showMM',0,'histOpt',1,'color',cmap(cats(i(t)),:))
    plot([mu-se mu+se],[t t],'k')
    plot(mu,t,'.k','MarkerSize',10)
    text(-670,t-.1,tasknames{i(t)},'FontSize',12,'Color',cmap(cats(i(t)),:),'HorizontalAlignment', 'left')

end
xlim([-700 3000])
set(gca,'YDir','reverse')
set(gca,'FontSize',16)
xlabel('Response time (ms)')
set(gca,'YTick',[])
pos= get(gca,'Position');

set(gca,'Position',[pos(1) sb2pos(2) pos(3) sb2pos(4)])


%% annotate
annotation('textbox',[0.09 .865 .1 .1],...
    'String','A','FontSize',30,'LineStyle','none')

annotation('textbox',[0.09 .32 .1 .1],...
    'String','B','FontSize',30,'LineStyle','none')

annotation('textbox',[0.42 .32 .1 .1],...
    'String','C','FontSize',30,'LineStyle','none')

%% save
fn = './figures/Fig3_taskrelationships';
set(gcf, 'Renderer', 'painters')
print(gcf,'-dpng','-r500',fn)
im=imread([fn '.png']);
[i,j]=find(mean(im,3)<255);margin=1;
imwrite(im(max(1,min(i)-margin):min(size(im,1),max(i)+margin), ...
           max(1,min(j)-margin):min(size(im,2),max(j)+margin),:), ...
           [fn '.png'],'png');


