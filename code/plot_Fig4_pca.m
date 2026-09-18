% PCA summary figure
load('results/behaviour.mat')

tasknames = alldata.tasknames;

labels = tasknames;
pca_r2 = alldata.pca.r2; % 12 task x 12 pc
pcacomps = alldata.pca.pcacomps; % 200 activation x 12 pc
e = alldata.pca.explainedvar;
r = alldata.pca.componentrawcorrs;% 12 task x 12 pc

%% variance explained + task-component correlations
% Panel A: variance per component (bars) with cumulative variance (line)
% Panel B: heatmap of correlations between each task's behaviour and each PC
nPC=12;
col = [0, 0.20, 0.45];

figure(5);clf
set(gcf,'Position',[100 100 1200 750])

% Panel A: variance explained
sp=subplot(2,2,1); hold on

bar(1:nPC, e, 'FaceColor',[.7 .7 .7], 'EdgeColor','none')
yyaxis right
plot(1:nPC, cumsum(e),'-o','Color',col, 'LineWidth',1.5, 'MarkerFaceColor','w')
ylim([0 100])
ylabel('Cumulative variance (%)')
ax = gca;
ax.YAxis(2).Color = col;   % right axis + ticks in navy

yyaxis left
ylabel('Variance explained (%)')
xlabel('Principal component')
xlim([.5 nPC+.5])
set(gca,'XTick',1:nPC,'FontSize',16)
ti=title('Variance explained','FontSize',18);
ti.Units = 'normalized';
ti.Position(2) = ti.Position(2) + .03;
box off

%% Panel B: task x component correlation heatmap
sp2 = subplot(2,2,2);

imagesc(r, [-1 1])                  % signed correlations, symmetric limits
colormap((brewermap([],'RdBu')))             % diverging map centred on zero
c = colorbar;
c.Label.String = 'Correlation with component';
c.Label.FontSize = 16;

set(gca,'YTick',1:12,'YTickLabel',tasknames)
set(gca,'XTick',1:nPC)
sp2.XTickLabelRotation = 0;
xlabel('Principal component')
set(gca,'FontSize',16)

% make yticklabels coloured according to task type
sp2.TickLabelInterpreter = 'tex';

red = [153 36 56];
green = [117, 157, 132];
pink = [247, 171, 175];
navy = [49, 104, 142];
cmap = [green; red; navy; pink]/255;

cats = [1 1 1 1 2 2 2 3 3 3 4 4];


% loop through Y-tick labels and inject the TeX color code
labels = sp2.YTickLabel; 
for i = 1:numel(labels)
    % Pick a color index from our matrix
    r = cmap(cats(i), 1);
    g = cmap(cats(i), 2);
    b = cmap(cats(i), 3);
    
    % Prepend the TeX RGB color tag to the existing text label
    labels{i} = sprintf('\\color[rgb]{%f,%f,%f}%s', r, g, b, labels{i});
end

% 4. Apply the color-coded labels back to the axis
sp2.YTickLabel = labels;

ti=title('Task-component correlations','FontSize',18);
ti.Units = 'normalized';
ti.Position(2) = ti.Position(2) + .03;

axis square

sp.Position(3) = sp.Position(3)-.03;
sp2.Position(1) = sp2.Position(1)+.04;

%% plot PCA component scores across the 200 stimuli (first four components)
% Mirrors Fig2_behavioural_results: same stimulus order, same category colours

categories = {'aquatic' 'bird' 'human' 'insect' 'mammal'...
    'clothing' 'fruit' 'furniture' 'plants' 'tools'};
catinit = {'aq' 'bi' 'hu' 'in' 'ma' 'cl' 'fr' 'fu' 'pl' 'to'};

cols = tab10;   % category colours, as in Fig 2

nPC = 4;
m = max(abs(pcacomps(:,1:nPC)),[],'all')*1.05;   % common across panels

for pc = 1:nPC
    sp=subplot(2,nPC,pc+4);
    hold on

    y = pcacomps(:,pc);

    for a = 1:10
        idx = ((a-1)*20+1):((a-1)*20+20);
        plot(idx,y(idx),'.','Color',cols(a,:),'MarkerSize',10)
    end

    % zero line: makes the sign of each component readable
    plot([0 201],[0 0],'-','Color',[.7 .7 .7],'LineWidth',.5,...
        'HandleVisibility','off')

    ti = title(sprintf('PC %d (%d%% variance)',pc,round(e(pc))),'FontSize',18);
    ti.Units = 'normalized';
    ti.Position(2) = ti.Position(2) + .03;

    if pc==1
        ylabel('Component score')
    else
        set(gca,'YTickLabel',{})
    end
    set(gca,'FontSize',16)
    xlim([0 201])

    % symmetric y-limits so zero sits mid-panel
    ylim([-m m])
    set(gca,'XTick',10:20:200);
    set(gca,'XTickLabel',catinit);
    sp.XAxis.FontSize = 14;
    sp.XAxis.TickLabelRotation = 0;

    ydiff = .08;
    sp.Position = [sp.Position(1) sp.Position(2)+ydiff sp.Position(3)+.025 sp.Position(4)-ydiff]; 

    if pc == 4
        axP = get(gca,'Position');
        [lh, objh] = legend(categories,'Orientation','horizontal','FontSize',16);
        objhl = findobj(objh,'type','line');
        set(objhl,'Markersize',40);
        set(gca,'Position',axP)          % restore axes after legend shrinks them

        % lh.Box = 'off';
        lh.Units = 'normalized';
        lh.Position(3) = 0.8;                        % width: 90% of figure
        lh.Position(1) = (1 - lh.Position(3))/2+.02;     % centre horizontally
        lh.Position(2) = sp.Position(2)-.1;                       % height above figure bottom
    end
end


%% annotate
annotation('textbox',[0.085 .88 .1 .1],...
    'String','A','FontSize',30,'LineStyle','none')

annotation('textbox',[0.51 .88 .1 .1],...
    'String','B','FontSize',30,'LineStyle','none')

annotation('textbox',[0.085 .42 .1 .1],...
    'String','C','FontSize',30,'LineStyle','none')

% save
fn = 'figures/Fig4_pca';
set(gcf,'Renderer','painters')
print(gcf,'-dpng','-r500',fn)
im = imread([fn '.png']);
[i,j] = find(mean(im,3)<255); margin = 2;
imwrite(im(min(i-margin):max(i+margin),min(j-margin):max(j+margin),:),[fn '.png'],'png');

