%% plot behavioural results for 12 tasks

% get data
load('results/behaviour.mat')
tasknames = alldata.tasknames;

tasks = alldata.tasks;
categories = {'aquatic' 'bird' 'human' 'insect' 'mammal'...
    'clothing' 'fruit' 'furniture' 'plants' 'tools'};
catinit = {'aq' 'bi' 'hu' 'in' 'ma' 'cl' 'fr' 'fu' 'pl' 'to'};

%% plot behaviour per task

ylabs = {...
    'Response time (ms)','Response time (ms)',...
    'Proportion chosen','Proportion chosen',...
    'Proportion chosen','Proportion chosen',...
    'Proportion chosen','Proportion chosen',...
    'Proportion chosen','Proportion chosen', ...
    'Perceptual similarity','Perceptual similarity'...
    };
yl = [700 1050; 700 1050; 0 1; 0 1;   ...
     0 1; 0 1; 0 1; ...
     0 1; 0 1; 0 1; ...
     -0.55 .55; -.55 .55];

cmap = zeros(12,3);%brewermap(12,'set3'); % title colours
cols = tab10; % category colours

%% plot
f=figure(1);clf
f.Position = [f.Position(1:2) 1300 1000];
for t= 1:12

    sp=subplot(4,3,t);
    sp.Position(2) = sp.Position(2)-.01;
    hold on
    if t<11
        dat = alldata.(tasks{t}).rawdata;
        mu = mean(dat,2,'omitnan');
        se = std(dat,[],2,'omitnan')/sqrt(size(dat,2));
    else
        mu = alldata.(tasks{t}).mu;
    end

    for a=1:10
        idx = ((a-1)*20+1):((a-1)*20+20);
        plot(idx,mu(idx),'.','Color',cols(a,:),'MarkerSize',10)
        if t<11
            errorbar(idx,mu(idx),se(idx),'Color',cols(a,:),...
                'CapSize',0,'LineStyle','none','HandleVisibility','off');
        end
    end

    ylim(yl(t,:))
    set(gca,'FontSize',16)
    set(gca,'XTick',10:20:200);
    set(gca,'XTickLabel',catinit);
    sp.XAxis.FontSize = 14;
    sp.XAxis.TickLabelRotation = 0;

    ylab=ylabel(ylabs{t});
    ylab.Position(1) = -30;

    ti=title(tasknames{t},'Color',cmap(t,:),'FontSize',18);
    % ti.Units = 'normalized';
    % ti.Position(2) = ti.Position(2) - .25;

    if t == 1
        axP = get(gca,'Position');
        [lh, objh] = legend(categories,'Orientation','horizontal','Location','EastOutside','FontSize',18);
        objhl = findobj(objh, 'type', 'line');
        set(objhl, 'Markersize', 40);
        set(gca, 'Position', axP)
                lh.Position(2) = lh.Position(2)+.02;
        % lh.Box = 'off';
        lh.Units = 'normalized';
        lh.Position(3) = 0.75;                        % width: 90% of figure
        lh.Position(1) = (1 - lh.Position(3))/2+.02;     % centre horizontally
        lh.Position(2) = 0.97;                       % height above figure bottom
        lh.Position(4) = .025;
    end
    if t>9
        xlabel('Stimulus')
        sp.XLabel.FontSize = 16;

    end
end

%%

fn = 'figures/Fig2_behavioural_results';
set(gcf, 'Renderer', 'painters')
print(gcf,'-dpng','-r500',fn)
im=imread([fn '.png']);
[i,j]=find(mean(im,3)<255);margin=0;
imwrite(im(min(i-margin):max(i+margin),min(j-margin):max(j+margin),:),[fn '.png'],'png');
