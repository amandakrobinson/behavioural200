%% plot
load('results/stats_PCA_RSA.mat')
load('results/behaviour.mat')

stats = stats_pca;

tv = stats.timevect;
targetlabels = fieldnames(stats.results);
co = tab20; %vega10;

%% plot correlations one by one

f=figure(1); clf
f.Resize='off';
f.Position = [f.Position(1:2) 1500 800];

h=[];

smooth=4;

clear a

startplot = [1:4 17:20 33:36];


for t=1:12

    x = [startplot(t) startplot(t)+4];
    a=subplot(12,4,x);hold on
    a.FontSize=22;
    a.YLim=[-.02 .09];
    a.Position(3) = a.Position(3) + .03;
    a.Position(4) = a.Position(4) + .02;

    % chance line
    plot([min(tv) max(tv)],[0 0],'Color',[.7 .7 .7],'HandleVisibility','off')

    % plot correlations and standard error
    s = stats.results.(targetlabels{t});
    mu = movmean(s.mu,smooth);
    se = movmean(s.se,smooth);
    fill([tv fliplr(tv)],[mu-se fliplr(mu+se)],co(t,:),...
        'FaceAlpha',.2,'LineStyle','none');
    h(t) = plot(tv,mu,...
        'DisplayName',targetlabels{t},'Color',co(t,:),...
        'LineWidth',3);
    title(targetlabels{t},'Fontsize',24)
    a.YAxis.FontSize = 16;
    
    if ismember(t,[1 5 9])
        ylabel('Correlation','FontSize',22)
    else
        set(gca,'YTickLabel',{})
    end

    a.YTick = 0:.04:1;
    set(gca,'XTickLabel',{})

    xlim([-100 1000])
end

% bf

for t=1:length(targetlabels)
    a=subplot(12,4,startplot(t)+8);hold on
    a.Position(3) = a.Position(3) + .03;

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

    a.YAxis.FontSize = 16;
    if ismember(t,[1 5 9])
        ylabel('BF','FontSize',22)
    else
        set(gca,'YTickLabel',{})
    end
    if ismember(t,9:12)
        xlabel('Time (ms)')        

    else
        a.XTickLabel = {};
    end
    a.XTickLabelRotation=0;
end


fn = 'figures/FigureSupp_PCA-behaviour_rsa';
set(gcf,'Renderer','painters')
print(gcf,'-dpng','-r500',fn)
im=imread([fn '.png']);
[i,j]=find(mean(im,3)<255);margin=2;
imwrite(im(min(i-margin):max(i+margin),min(j-margin):max(j+margin),:),[fn '.png'],'png');

