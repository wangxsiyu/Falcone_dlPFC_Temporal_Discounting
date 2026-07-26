animalNames = string(plt.custom_vars.name_monkeys(1:2));
analysisWindow = [-500 500];
nConditions = 9;
nComponents = 3;
smoothingWidth = 5;
lowValueColor = 'RSred';
middleValueColor = 'yellow';
highValueColor = 'RSgreen';
viewAngles = [-136.936071, 31.433679; ...
               -20.021, 18.2995];

assert(numel(go) >= numel(animalNames), ...
    'The GO data must contain both animals.');

drop = plt.custom_vars.drop;
delay = plt.custom_vars.delay;
timeat = go{1}.time_at;
tid_pca = timeat >= 0 & timeat <= 1000;
tid_display = timeat >= analysisWindow(1) & ...
    timeat <= analysisWindow(2);
%% compute population trajectory
pc = cell(1, 2);
dvs = cell(1, 2);
for ai = 1:2
    cs = go{ai}.cells;
    gs = W.arrayfun(@(x)go{ai}.games{x}, ...
        go{ai}.info_cells.gameID)';
    nc = length(cs);
    av = cell(1, nc);
    dv = cell(1, nc);
    for ci = 1:nc
        c = cs{ci};
        g = gs{ci};
        assert(ismember('DV_overall', ...
            g.Properties.VariableNames), ...
            'Run the behavioral DV computation before this figure.');
        av{ci} = W.cond_average( ...
            c, g.condition, 1:nConditions);
        dv{ci} = W.cond_average( ...
            g.DV_overall, g.condition, 1:nConditions);
    end
    dvs{ai} = mean(vertcat(dv{:}));

    % Find population activity for each condition.
    pp = W.cell_transpose(W.cell_NxMK2KxMN( ...
        W.cell_transpose(av)));

    % Find PCA space from the unsmoothed mean trajectories.
    tpp = W.cellfun(@(x)x(:, tid_pca), pp);
    alld = horzcat(tpp{:});
    pcinfo = W.pca(alld');

    % Project the unsmoothed full trajectories into the PCA space.
    pc{ai} = W.cellfun(@(x) ...
        W.pca_project(pcinfo, x', 10), pp);
end

% Use Monkey T's DV ordering and color scale for both animals.
referenceDV = dvs{2};
[~, legendOrder] = sort(referenceDV);
colorAnchors = [min(referenceDV), ...
    referenceDV(legendOrder(ceil(nConditions/2))), ...
    max(referenceDV)];
conditionColors = W.arrayfun(@(x) ...
    plt.interpolatecolors( ...
    {lowValueColor, middleValueColor, highValueColor}, ...
    colorAnchors, x), referenceDV);

%% Figure
plt.figure(1, 2, 'is_title', 'all', ...
    'pixel_w', 470, 'pixel_h', 430, ...
    'gapW_custom', [0.7 0 5]);
pcaAxes = gobjects(numel(animalNames), 1);
for animalIndex = 1:numel(animalNames)
    plt.ax(1, animalIndex);
    pcaAxes(animalIndex) = gca;
    x = cell(1, nComponents);
    for componentIndex = 1:nComponents
        x{componentIndex} = W.cellfun_vertcat(@(x) ...
            W.smooth1d([], ...
            x(tid_display, componentIndex)', smoothingWidth), ...
            pc{animalIndex});
    end
    plt.plot3(x{1}, x{2}, x{3}, ...
        'color', conditionColors);

    xlabel('PC1');
    ylabel('PC2');
    zlabel('PC3');
    title(animalNames(animalIndex));
    text(-0.15, 1.08, char('A' + animalIndex - 1), ...
        'Units', 'normalized', ...
        'FontSize', gca().FontSize + 5, ...
        'HorizontalAlignment', 'left', ...
        'VerticalAlignment', 'bottom', ...
        'Clipping', 'off');
    view(viewAngles(animalIndex, :));
    grid off;
    box off;
    axis vis3d;
    set(gca, 'Color', 'none');
end

% Put the shared legend in a small independent axes immediately to the
% right of Monkey T. It therefore cannot resize either PCA axes.
rightAxesUnits = pcaAxes(2).Units;
pcaAxes(2).Units = 'normalized';
rightAxesPosition = pcaAxes(2).Position;
pcaAxes(2).Units = rightAxesUnits;
legendLeft = rightAxesPosition(1) + rightAxesPosition(3) + 0.015;
legendAxes = axes(gcf, ...
    'Units', 'normalized', ...
    'Position', [legendLeft, rightAxesPosition(2), ...
    max(0.98 - legendLeft, 0.10), rightAxesPosition(4)], ...
    'Visible', 'off');
axes(legendAxes);
hold on;
axis off;
legendHandles = gobjects(nConditions, 1);
legendLabels = strings(nConditions, 1);
for legendIndex = 1:nConditions
    conditionIndex = legendOrder(legendIndex);
    legendHandles(legendIndex) = plot(nan, nan, ...
        'Color', conditionColors{conditionIndex}, ...
        'LineWidth', 1.5);
    legendLabels(legendIndex) = sprintf( ...
        '%g drops, %gs delay', ...
        drop(conditionIndex), delay(conditionIndex));
end
legend(legendHandles, legendLabels, ...
    'Location', 'west', 'Box', 'off');
plt.update('Geometry PCA');
