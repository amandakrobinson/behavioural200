%% plot
load('results/stats_PCA_RSA.mat')
load('results/behaviour.mat')

stats = stats_pca;

tv = stats.timevect;
targetlabels = fieldnames(stats.results);


%% plot correlations overlaid
co = brewermap(5, 'Set2');

f=figure(2); clf
f.Resize='off';
f.Position = [f.Position(1:2) 800 800];

h=[];

smooth=4;

clear a

a=subplot(7,1,1:3);hold on
a.FontSize=22;
a.YLim=[-.02 .22];

% chance line
plot([min(tv) max(tv)],[0 0],'Color',[.7 .7 .7],'HandleVisibility','off')
plot(tv,movmean(mean(stats.noiseceiling,2),smooth),'Color','k','LineWidth',2)
plot(tv,movmean(stats.varianceexplained.total,smooth),'Color',[.5 .5 .5],'LineWidth',3)

for t = 1:4
    % plot correlations and standard error
    s = stats.results.(targetlabels{t});
    mu = movmean(s.mu,smooth);
    se = movmean(s.se,smooth);
    fill([tv fliplr(tv)],[mu-se fliplr(mu+se)],co(t,:),...
        'FaceAlpha',.2,'LineStyle','none','HandleVisibility','off');
    h(t) = plot(tv,mu,...
        'DisplayName',targetlabels{t},'Color',co(t,:),...
        'LineWidth',3);
end
legend({'Noise ceiling' 'all PCs combined' 'PC1' 'PC2' 'PC3' 'PC4'},'Box','off')
ylabel('Correlation')
a.YTick = 0:.05:1;
set(gca,'XTickLabel',{})

xlim([-100 1000])


% bf

for t=1:4
    a=subplot(7,1,3+t);hold on
    a.FontSize=22;
    s = stats.results.(targetlabels{t});
    plot(tv,1+0*tv,'k-');
    co3 = [.5 .5 .5;1 1 1;co(t,:)];
    idx = [s.bf<1/10,1/10<s.bf & s.bf<10,s.bf>10]';
    for i=1:3
        x = tv(idx(i,:));
        y = s.bf(idx(i,:));
        if ~isempty(x)
            stem(x,y,'Marker','o','Color',.6*[1 1 1],'BaseValue',1,'MarkerSize',5,'MarkerFaceColor',co3(i,:),'Clipping','off');
            plot(x,y,'o','Color',.6*[1 1 1],'MarkerSize',5,'MarkerFaceColor',co3(i,:),'Clipping','off');
        end
    end
    a.YScale='log';
    ylim([10.^(-3) 10.^5])
    a.YTick = 10.^([-4 0 4]);
    a.XTick = 0:200:1000;
    xlim([-100 1000])

    ylabel('BF','FontSize',22)
    if t==4
        xlabel('Time (ms)')
    end
    a.XTickLabelRotation=0;
end

%%
fn = 'figures/Figure6_PCA-behaviour_rsa_overlaid';
set(gcf,'Renderer','painters')
print(gcf,'-dpng','-r500',fn)
im=imread([fn '.png']);
[i,j]=find(mean(im,3)<255);margin=2;
imwrite(im(min(i-margin):max(i+margin),min(j-margin):max(j+margin),:),[fn '.png'],'png');
