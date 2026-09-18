%% plot
load('results/stats_rsa.mat')
load('results/behaviour.mat')

%reorder tasks
tasknames = alldata.tasknames;

targetlabels = stats.modelnames;
targetlabelsplot = tasknames;

tv = stats.timevect;

%% plot correlations one by one

f=figure(1); clf
f.Resize='off';
f.Position = [f.Position(1:2) 1300 1200];

h=[];

smooth=4;
plotnoise = 0;

clear a

red = [153 36 56];
green = [117, 157, 132];
pink = [247, 171, 175];
navy = [49, 104, 142];

co = [green; green; green; green; ...
    red; red; red; ...
    navy; navy; navy; ...
    pink; pink]/255;


startplot = [1:3 13:15 25:27 37:40];

for t=1:length(targetlabels)

    x = [startplot(t) startplot(t)+3];
    a=subplot(16,3,x);hold on
    a.FontSize=22;
    a.YLim=[-.02 .09];
    a.Position(3) = a.Position(3) + .03;
    a.Position(4) = a.Position(4) + .02;

    % chance line
    plot([min(tv) max(tv)],[0 0],'Color',[.7 .7 .7],'HandleVisibility','off')

    % plot decoding and standard error
    s = stats.results.(targetlabels{t});
    mu = movmean(s.mu,smooth);
    se = movmean(s.se,smooth);
    fill([tv fliplr(tv)],[mu-se fliplr(mu+se)],co(t,:),...
        'FaceAlpha',.2,'LineStyle','none');
    h(t) = plot(tv,mu,...
        'DisplayName',targetlabelsplot{t},'Color',co(t,:),...
        'LineWidth',3);
    title(targetlabelsplot{t},'Fontsize',24)
    a.YAxis.FontSize = 16;
    
    if ismember(t,[1 4 7 10])
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
    a=subplot(16,3,startplot(t)+6);hold on
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
    if ismember(t,[1 4 7 10])
        ylabel('BF','FontSize',22)
    else
        set(gca,'YTickLabel',{})
    end
    if ismember(t,10:12)
        xlabel('Time (ms)')        

    else
        a.XTickLabel = {};
    end
    a.XTickLabelRotation=0;
end


fn = 'figures/Figure5sneural-behaviour_rsa';
set(gcf,'Renderer','painters')
print(gcf,'-dpng','-r500',fn)
im=imread([fn '.png']);
[i,j]=find(mean(im,3)<255);margin=2;
imwrite(im(min(i-margin):max(i+margin),min(j-margin):max(j+margin),:),[fn '.png'],'png');
