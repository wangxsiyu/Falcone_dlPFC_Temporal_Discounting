yp = W.load('../../TempData/projections_YP');
projections = yp.projections;
basePs = yp.basePs;
%% Figure 1: primary population-projection results
animalNames = string(plt.custom_vars.name_monkeys(1:2));
colorNames = ["Yellow", "Purple"];
yellowColor = [0.90 0.65 0.05];
purpleColor = [0.55 0.25 0.72];
xticks = [-250:250:1000];
xlims = [min(xticks), max(xticks)];
windowi = 5;
plt.figure(4, 2, 'is_title', 'all', ...
    'gapW_custom', [0.7 0 1.2]);
for animalIndex = 1:numel(animalNames)
    projection = projections{1, animalIndex};
    bp = basePs{animalIndex};
    analysisConditions = 1:9;
    timeAt = go{1}.time_at;
    nTimes = length(timeAt);

    % Absolute, baseline-corrected value projections across all nine cues.
    plt.ax(1, animalIndex);
    hold on;
    yellowValue = reshape(projection(windowi, analysisConditions, 1, :), ...
        numel(analysisConditions), nTimes);
    purpleValue = reshape(projection(windowi, analysisConditions, 2, :), ...
        numel(analysisConditions), nTimes);
    [av, se] = W.avse(yellowValue);
    max1 = av + se;
    plt.plot(timeAt, av, se, 'shade', 'color', yellowColor);
    [av, se] = W.avse(purpleValue);
    max2 = av + se;
    plt.plot(timeAt, av, se, 'shade', 'color', purpleColor);
    maxt = max([max1; max2]);
    [~, pval] = ttest(yellowValue - purpleValue);
    tid = pval < 0.05 & timeAt <= 500 & timeAt >= -250;
    plt.dashX(0);
    plt.dashY(0, [-1 1]);
    plt.sigstar(timeAt(tid), maxt(tid) + 0.01, pval(tid), 'dx', 0)

    plt.setfig_ax('xlabel', 'Time from GO cue onset (ms)', ...
        'xlim', xlims, 'xtick', xticks, 'ylabel', 'Value-axis projection', ...
        'title', sprintf('%s', animalNames(animalIndex)));
    if animalIndex == 2
        plt.setfig_ax('legend', {'Yellow', 'Purple'}, ...
            'legloc', 'SE');
    end

    plt.ax(2, animalIndex);
    tid = timeAt < 250 & timeAt > 0;
    avY = mean(yellowValue(:, tid), 2)';
    avP = mean(purpleValue(:, tid), 2)';
    [tav, tse] = W.avse([avY', avP']);
    [~, pp] = ttest(avP' - avY');
    plt.plot([], tav, tse, 'bar', 'color', {yellowColor, purpleColor}, 'individualcolor', true);
    plt.setfig_ax('ylim', [-0.4, 0.5], 'xtick', 1:2, 'xticklabel', {'Yellow', 'Purple'}, ...
        'ylabel', {'\Delta activity on value-axis', '250ms after - before go signal'})
    plt.sigstar(1.5, 0.4, pp);

    plt.ax(3, animalIndex);
    projection = projections{3, animalIndex};
    hold on;
    v1 = reshape(projection(windowi, 1, :), ...
        1, nTimes);
    v2 = reshape(projection(windowi, 2, :), ...
        1, nTimes);
    plt.plot(timeAt, v1, [], 'shade', 'color', yellowColor);
    plt.plot(timeAt, v2, [], 'shade', 'color', purpleColor);
    
    plt.setfig_ax('xlabel', 'Time from GO cue onset (ms)', ...
        'xlim', xlims, 'xtick', xticks, 'ylabel', 'Value-axis projection', ...
        'title', sprintf('%s', animalNames(animalIndex)));
    if animalIndex == 2
        plt.setfig_ax('legend', {'Reject', 'Accept'}, ...
            'legloc', 'SE');
    end
    plt.ax(4, animalIndex);
    projection = projections{2, animalIndex};
    hold on;
    v1 = reshape(projection(windowi, 1, :), ...
        1, nTimes);
    v2 = reshape(projection(windowi, 2, :), ...
        1, nTimes);
    plt.plot(timeAt, v1, [], 'shade', 'color', yellowColor);
    plt.plot(timeAt, v2, [], 'shade', 'color', purpleColor);
    
    plt.setfig_ax('xlabel', 'Time from GO cue onset (ms)', ...
        'xlim', xlims, 'xtick', xticks, 'ylabel', 'Value-axis projection', ...
        'title', sprintf('%s', animalNames(animalIndex)));
    if animalIndex == 2
        plt.setfig_ax('legend', {'Yellow', 'Purple'}, ...
            'legloc', 'SE');
    end

end
plt.addABCs('ABCDEF');
plt.update('YP population projection GO');